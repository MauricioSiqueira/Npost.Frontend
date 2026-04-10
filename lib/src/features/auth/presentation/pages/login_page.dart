import 'package:flutter/material.dart';

import '../../data/dtos/login_request_dto.dart';
import '../../data/dtos/login_response_dto.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _loginErrorMessage;
  LoginResponseDto? _loginResponse;

  bool get _canSubmit {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_isSubmitting;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
    final session = widget.authRepository.currentSession;
    if (session != null) {
      _loginResponse = LoginResponseDto(
        userName: session.userName,
        jwt: session.jwt,
      );
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFormChanged);
    _passwordController.removeListener(_onFormChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    setState(() {
      _loginErrorMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loginErrorMessage = null;
    });

    try {
      final output = await widget.authRepository.login(
        LoginRequestDto(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
        persistSession: _rememberMe,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loginResponse = output;
        _loginErrorMessage = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bem-vindo, ${output.userName}.')));
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loginErrorMessage = error.isInvalidCredentials
            ? 'Email ou senha incorretos'
            : error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 54,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 22),
                        Text('Login', style: theme.textTheme.headlineLarge),
                        const SizedBox(height: 10),
                        Text(
                          'Enter your email and password to log in',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'Email'),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Informe seu email.';
                            }
                            if (!email.contains('@')) {
                              return 'Informe um email valido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return 'Informe sua senha.';
                            }
                            if (password.length < 6) {
                              return 'A senha deve ter ao menos 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Remember me',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password ?'),
                            ),
                          ],
                        ),
                        if (_loginErrorMessage != null) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _loginErrorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text('Log In'),
                        ),
                        if (_loginResponse != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.primary.withAlpha(60),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario autenticado',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Nome: ${_loginResponse!.userName}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JWT: ${_maskJwt(_loginResponse!.jwt)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.dividerColor.withAlpha(80),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Or login with',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.dividerColor.withAlpha(80),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              semanticLabel: 'Google login',
                            ),
                            _SocialButton(
                              icon: Icons.facebook_rounded,
                              semanticLabel: 'Facebook login',
                            ),
                            _SocialButton(
                              icon: Icons.apple_rounded,
                              semanticLabel: 'Apple login',
                            ),
                            _SocialButton(
                              icon: Icons.phone_iphone_rounded,
                              semanticLabel: 'Phone login',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: theme.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => SignUpPage(
                                      authRepository: widget.authRepository,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskJwt(String jwt) {
    if (jwt.length <= 14) {
      return jwt;
    }

    return '${jwt.substring(0, 10)}...${jwt.substring(jwt.length - 4)}';
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Container(
        width: 58,
        height: 44,
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
