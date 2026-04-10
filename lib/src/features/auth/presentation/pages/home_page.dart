import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authRepository.logout();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginPage(authRepository: widget.authRepository),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.authRepository.currentSession;
    final displayName = session?.userName.isNotEmpty == true
        ? session!.userName
        : 'Usuario';

    return Scaffold(
      appBar: AppBar(title: const Text('Npost')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Home', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text(
                  'Bem-vindo, $displayName. Esta e uma pagina inicial ilustrativa apos o login.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoggingOut ? null : _logout,
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Logoff'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
