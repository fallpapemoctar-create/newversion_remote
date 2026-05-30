import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const _userKey = 'auth_user';
  static const _rightsKey = 'auth_rights';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw != null) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        final rights = prefs.getStringList(_rightsKey) ?? [];
        _currentUser = UserModel.fromJson({...map, 'rights': rights});
      } catch (_) {
        await logout();
      }
    }
  }

  Future<UserModel> login(String login, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'login': login, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur (${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Identifiants incorrects');
    }

    final user = UserModel.fromJson({
      ...data['user'] as Map<String, dynamic>,
      'rights': data['rights'] ?? [],
    });

    _currentUser = user;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode({
      'id': user.id,
      'prenom': user.prenom,
      'nom': user.nom,
      'login': user.login,
    }));
    await prefs.setStringList(_rightsKey, user.rights);

    return user;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_rightsKey);
  }
}
