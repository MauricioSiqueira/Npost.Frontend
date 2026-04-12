import 'package:flutter/material.dart';

import '../core/session/session_manager.dart';
import '../features/auth/data/datasources/local/auth_local_data_source.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'theme/app_theme.dart';

class NpostApp extends StatefulWidget {
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
  State<NpostApp> createState() => _NpostAppState();
}

class _NpostAppState extends State<NpostApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _restoreSessionAndTheme();
  }

  Future<void> _restoreSessionAndTheme() async {
    final session = await widget._authRepository.restoreSession();
    if (session == null) {
      return;
    }

    _themeMode = session.darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _toggleTheme() async {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isCurrentlyDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && brightness == Brightness.dark);
    final nextDarkMode = !isCurrentlyDark;
    final previousThemeMode = _themeMode;

    setState(() {
      _themeMode = nextDarkMode ? ThemeMode.dark : ThemeMode.light;
    });

    try {
      final savedDarkMode = await widget._authRepository.updateThemePreference(
        nextDarkMode,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _themeMode = savedDarkMode ? ThemeMode.dark : ThemeMode.light;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _themeMode = previousThemeMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Npost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: FutureBuilder(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (widget._authRepository.currentSession != null) {
            return HomePage(
              authRepository: widget._authRepository,
              onToggleTheme: _toggleTheme,
            );
          }

          return LoginPage(
            authRepository: widget._authRepository,
            onThemeChanged: (darkMode) {
              setState(() {
                _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
              });
            },
            onToggleTheme: _toggleTheme,
          );
        },
      ),
    );
  }
}
