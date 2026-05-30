import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/mission_model.dart';

class MissionsService {
  /// Missions paginées via le DataTable endpoint (toutes missions)
  Future<Map<String, dynamic>> getDataTable({
    int page = 1,
    int pageSize = 50,
    String? q,
    int? clientId,
    String? dateStart,
    String? dateEnd,
    int? missionStatus,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (q != null && q.isNotEmpty) 'q': q,
      if (clientId != null) 'clientId': clientId.toString(),
      'dateStart': ?dateStart,
      'dateEnd': ?dateEnd,
      if (missionStatus != null) 'missionStatus': missionStatus.toString(),
    };
    final uri = Uri.parse(ApiConstants.getMissionsDataTable)
        .replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erreur serveur');
    final data = json.decode(response.body) as Map<String, dynamic>;
    final list = (data['missions'] as List? ?? [])
        .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'missions': list, 'total': data['total'] ?? 0};
  }

  /// Missions d'un interprète spécifique
  Future<List<MissionModel>> getByInterprete(int interpreteId) async {
    final response = await http.post(
      Uri.parse(ApiConstants.getMissionsByInterpreter),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'interpreter_id': interpreteId}),
    );
    if (response.statusCode != 200) throw Exception('Erreur serveur');
    final data = json.decode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    return list.map((e) => MissionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Liste des interprètes avec nb missions (pour le dashboard)
  Future<List<Map<String, dynamic>>> getTabMissions() async {
    final response = await http.get(Uri.parse(ApiConstants.getTabMissions));
    if (response.statusCode != 200) throw Exception('Erreur serveur');
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> add(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.addMission),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) throw Exception('Erreur ajout mission');
  }

  Future<void> update(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.updateMission),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) throw Exception('Erreur mise à jour mission');
  }

  Future<void> delete(int id) async {
    final response = await http.post(
      Uri.parse(ApiConstants.deleteMission),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id}),
    );
    final result = json.decode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) throw Exception('Erreur suppression mission');
  }
}
