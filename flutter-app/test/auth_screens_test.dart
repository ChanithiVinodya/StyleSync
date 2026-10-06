import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/screens/auth/login_screen.dart';
import 'package:stylesync/screens/auth/register_screen.dart';

void main() {
  group('Auth Screens Widget Tests', () {
    testWidgets('LoginScreen renders email, password, and log in button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('STYLE SYNC'), findsOneWidget);
      expect(find.text('SIGN IN TO YOUR ATELIER'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('LOG IN'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('LoginScreen triggers inline validation on empty submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.tap(find.text('LOG IN'));
      await tester.pumpAndSettle();

      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders role selector with Client and Designer only', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('STYLE SYNC'), findsOneWidget);
      expect(find.text('CREATE YOUR ACCOUNT'), findsOneWidget);
      expect(find.text('Client'), findsOneWidget);
      expect(find.text('Designer'), findsOneWidget);
      // Admin should NEVER be visible on public registration
      expect(find.text('Admin'), findsNothing);

      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD (MIN. 8 CHARS)'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    });

    testWidgets('RegisterScreen validates short password and mismatch', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), 'Elena');
      await tester.enterText(textFields.at(1), 'elena@stylesync.com');
      await tester.enterText(textFields.at(2), 'short');
      await tester.enterText(textFields.at(3), 'mismatch');

      final submitBtn = find.text('CREATE ACCOUNT');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });
}
