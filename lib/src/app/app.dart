import 'package:flutter/material.dart';

import '../core/session/session_manager.dart';
import '../features/auth/data/datasources/local/auth_local_data_source.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'theme/app_theme.dart';

class NpostApp extends StatelessWidget {
  NpostApp({super.key, AuthRepository? authRepository})
    : _authRepository =
          authRepository ??
          AuthRepository(
            authService: const AuthService(),
            localDataSource: AuthLocalDataSource(),
            sessionManager: SessionManager(),
          );

  final AuthRepository _authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Npost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: FutureBuilder(
        future: _authRepository.restoreSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_authRepository.currentSession != null) {
            return HomePage(authRepository: _authRepository);
          }

          return LoginPage(authRepository: _authRepository);
        },
      ),
    );
  }
}
