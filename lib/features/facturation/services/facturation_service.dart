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
    final payload = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (q != null && q.isNotEmpty) 'search': q,
      if (status != 'all') 'status': status,
      if (dateStart != null && dateStart.isNotEmpty) 'dateStart': dateStart,
      if (dateEnd != null && dateEnd.isNotEmpty) 'dateEnd': dateEnd,
      if (amountMin != null && amountMin.isNotEmpty) 'amountMin': amountMin,
      if (amountMax != null && amountMax.isNotEmpty) 'amountMax': amountMax,
    };

    final res = await http
        .post(
          Uri.parse(ApiConstants.getClientInvoices),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Erreur API ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawData = (body['invoices'] as List?) ?? (body['data'] as List?) ?? [];
    final invoices = rawData
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total =
        int.tryParse(body['total']?.toString() ?? '') ?? invoices.length;

    return {'invoices': invoices, 'total': total};
  }

  Future<int> createDraft({
    required String clientName,
    required String month,
    required double totalHt,
  }) async {
    final payload = {
      'client_name': clientName,
      'month': month,
      'total_ht': totalHt,
    };

    final res = await http
        .post(
          Uri.parse(ApiConstants.saveInvoiceDraft),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Erreur API ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception((body['error'] ?? 'Erreur création brouillon').toString());
    }

    return int.tryParse(body['draft_id']?.toString() ?? '') ?? 0;
  }
}
