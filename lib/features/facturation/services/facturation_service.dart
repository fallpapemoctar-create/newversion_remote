import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/invoice_model.dart';

class FacturationService {
  Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int pageSize = 30,
    String? q,
    String status = 'all',
    String? dateStart,
    String? dateEnd,
    String? amountMin,
    String? amountMax,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': pageSize.toString(),
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != 'all') 'status': status,
      if (dateStart != null && dateStart.isNotEmpty) 'date_start': dateStart,
      if (dateEnd != null && dateEnd.isNotEmpty) 'date_end': dateEnd,
      if (amountMin != null && amountMin.isNotEmpty) 'amount_min': amountMin,
      if (amountMax != null && amountMax.isNotEmpty) 'amount_max': amountMax,
    };

    final uri = Uri.parse(ApiConstants.getClientInvoices)
        .replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Erreur API ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawData = (body['data'] as List?) ?? [];
    final invoices = rawData
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total =
        int.tryParse(body['total']?.toString() ?? '') ?? invoices.length;

    return {'invoices': invoices, 'total': total};
  }
}
