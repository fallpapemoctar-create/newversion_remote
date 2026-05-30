import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/interprete_model.dart';

class InterpretesService {
  Future<List<InterpreteModel>> getAll({String? q}) async {
    final uri = Uri.parse(ApiConstants.getInterpretes)
        .replace(queryParameters: {if (q != null && q.isNotEmpty) 'q': q});
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erreur serveur');
    final body = json.decode(response.body);
    final list = body is List ? body : (body['data'] as List? ?? []);
    return list.map((e) => InterpreteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InterpreteModel> add(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.addInterprete),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Erreur ajout');
    }
    // Re-fetch to get the full model
    final list = await getAll();
    return list.firstWhere((i) => i.id == (result['id'] as int));
  }

  Future<void> update(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.updateInterprete),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Erreur mise à jour');
    }
  }

  Future<void> delete(int id) async {
    final response = await http.post(
      Uri.parse(ApiConstants.deleteInterprete),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id}),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Erreur suppression');
    }
  }
}
