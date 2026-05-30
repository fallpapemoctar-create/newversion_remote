import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.loadSession();

  runApp(
    ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: const AmiApp(),
    ),
  );
}
