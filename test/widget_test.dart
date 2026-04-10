import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:npost/src/core/session/auth_session.dart';
import 'package:npost/src/core/session/session_manager.dart';
import 'package:npost/src/app/app.dart';
import 'package:npost/src/features/auth/data/datasources/local/auth_local_data_source.dart';
import 'package:npost/src/features/auth/data/repositories/auth_repository.dart';
import 'package:npost/src/features/auth/data/services/auth_service.dart';

void main() {
  testWidgets('renders login page instead of default counter app', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      NpostApp(
        authRepository: AuthRepository(
          authService: const AuthService(),
          localDataSource: _InMemoryAuthLocalDataSource(),
          sessionManager: SessionManager(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Flutter Demo Home Page'), findsNothing);
  });
}

class _InMemoryAuthLocalDataSource extends AuthLocalDataSource {
  AuthSession? _session;

  @override
  Future<void> saveSession(
    AuthSession session, {
    required bool persistSession,
  }) async {
    _session = session;
  }

  @override
  Future<AuthSession?> readSession() async {
    return _session;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}
