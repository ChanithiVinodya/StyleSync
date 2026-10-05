import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:stylesync/main.dart';
import 'package:stylesync/providers/auth/auth_provider.dart';
import 'package:stylesync/providers/auth/auth_state.dart';
import 'package:stylesync/routes.dart';
import 'package:stylesync/screens/home/home_screen.dart';
import 'package:stylesync/services/auth/auth_models.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState.authenticated(
      user: const AuthUser(
        id: 'usr-1',
        name: 'Jane Doe',
        email: 'jane@example.com',
        role: UserRole.client,
      ),
      token: 'mock-jwt-token',
    );
  }
}


// Transparent 1x1 PNG for mocking network images in tests
final List<int> _kTransparentImage = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];


class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomeScreen renders navigation bar and module tabs', (tester) async {
    await HttpOverrides.runZoned(
      () async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          legacy_provider.MultiProvider(
            providers: [
              legacy_provider.ChangeNotifierProvider(create: (_) => AppStateProvider()),
            ],
            child: const ProviderScope(
              child: MaterialApp(
                home: HomeScreen(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Home'), findsWidgets);
        expect(find.text('Designers'), findsWidgets);
        expect(find.text('Requests'), findsWidgets);
        expect(find.text('Quotes'), findsWidgets);
        expect(find.text('Progress'), findsWidgets);

        // Verify Categories and Styles section headers
        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Styles'), findsOneWidget);
        expect(find.text('Find designers who match your taste'), findsOneWidget);

        // Verify initial visible style cards in horizontal list
        expect(find.text('Modern Minimalist'), findsOneWidget);
        expect(find.text('Scandinavian'), findsOneWidget);
        expect(find.text('Industrial'), findsOneWidget);
      },
      createHttpClient: (context) => _MockHttpClient(),
    );
  });

  testWidgets('Tapping a style card pre-applies style filter and navigates to Designers', (tester) async {
    await HttpOverrides.runZoned(
      () async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          legacy_provider.MultiProvider(
            providers: [
              legacy_provider.ChangeNotifierProvider(create: (_) => AppStateProvider()),
            ],
            child: const ProviderScope(
              child: MaterialApp(
                home: HomeScreen(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Tap the Scandinavian style card
        final scandinavianCard = find.text('Scandinavian');
        expect(scandinavianCard, findsOneWidget);
        await tester.tap(scandinavianCard);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Should switch to Designers screen and show active removable chip
        expect(find.text('Interior Designers'), findsOneWidget);
        expect(find.text('Style: Scandinavian'), findsOneWidget);
      },
      createHttpClient: (context) => _MockHttpClient(),
    );
  });

  testWidgets('Tapping a category card navigates to New Request with roomType prefilled', (tester) async {
    await HttpOverrides.runZoned(
      () async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          legacy_provider.MultiProvider(
            providers: [
              legacy_provider.ChangeNotifierProvider(create: (_) => AppStateProvider()),
            ],
            child: ProviderScope(
              overrides: [
                authProvider.overrideWith(() => _FakeAuthNotifier()),
              ],
              child: const MaterialApp(
                onGenerateRoute: AppRoutes.onGenerateRoute,
                home: HomeScreen(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Tap the Living Room category card
        final livingRoomCard = find.text('Living Room');
        expect(livingRoomCard, findsOneWidget);
        await tester.tap(livingRoomCard);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify it navigated to New Request placeholder screen
        expect(find.text('New Request / Upload Photos'), findsOneWidget);
        expect(find.text('Coming soon — build owned by Student 2'), findsOneWidget);
      },
      createHttpClient: (context) => _MockHttpClient(),
    );
  });
}

