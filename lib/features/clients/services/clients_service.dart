import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/client_model.dart';

class ClientsService {
  Future<List<ClientModel>> getAll({String? q, bool activeOnly = true}) async {
    final uri = Uri.parse(ApiConstants.getClients).replace(queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      'active_only': activeOnly ? '1' : '0',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erreur serveur');
    final data = json.decode(response.body) as Map<String, dynamic>;
    final list = data['clients'] as List? ?? [];
    return list.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClientModel> add(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.addClient),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Erreur ajout client');
    }
    return ClientModel.fromJson(result['company'] as Map<String, dynamic>);
  }

  Future<ClientModel> update(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.updateClient),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Erreur mise à jour client');
    }
    return ClientModel.fromJson(result['company'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final response = await http.post(
      Uri.parse(ApiConstants.deleteClient),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id}),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Erreur suppression client');
    }
  }
}
