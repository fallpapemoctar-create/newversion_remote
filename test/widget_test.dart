// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:newversionami/app.dart';
import 'package:newversionami/core/services/auth_service.dart';

void main() {
  testWidgets('AMI app smoke test', (WidgetTester tester) async {
    final auth = AuthService();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: auth,
        child: const AmiApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Non connecté → écran de login affiché
    expect(find.text('Connexion'), findsOneWidget);
  });
}
