import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/dtos/signup_request_dto.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );
  static const List<_CountryDialCode> _countryCodes = [
    _CountryDialCode(flag: '🇧🇷', label: 'BR', dialCode: '+55'),
    _CountryDialCode(flag: '🇺🇸', label: 'US', dialCode: '+1'),
    _CountryDialCode(flag: '🇵🇹', label: 'PT', dialCode: '+351'),
    _CountryDialCode(flag: '🇦🇷', label: 'AR', dialCode: '+54'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedBirthDate;
  _CountryDialCode _selectedCountryCode = _countryCodes.first;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _submitErrorMessage;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  Iterable<TextEditingController> get _controllers => [
    _firstNameController,
    _lastNameController,
    _emailController,
    _birthDateController,
    _phoneController,
    _passwordController,
    _confirmPasswordController,
  ];

  bool get _canSubmit {
    return _controllers.every(
          (controller) => controller.text.trim().isNotEmpty,
        ) &&
        !_isSubmitting;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onFormChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _onFormChanged() {
    if (_submitErrorMessage == null) {
      return;
    }

    setState(() {
      _submitErrorMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = null;
    });

    try {
      await widget.authRepository.signUp(
        SignUpRequestDto(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          birthDate: _selectedBirthDate!,
          phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSuccess = true;
      });
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submitErrorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _goBackToLogin() {
    Navigator.of(context).pop();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate =
        _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecione a data de nascimento',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedBirthDate = pickedDate;
      _birthDateController.text = _formatDate(pickedDate);
      _submitErrorMessage = null;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 28.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _goBackToLogin,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildPanel(theme, constraints.maxHeight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPanel(ThemeData theme, double availableHeight) {
    if (_isSuccess) {
      return _SignUpSuccessPanel(
        email: _emailController.text.trim(),
        onBackToLogin: _goBackToLogin,
      );
    }

    final compactSpacing = availableHeight < 780;
    final fieldGap = compactSpacing ? 8.0 : 12.0;
    final sectionGap = compactSpacing ? 14.0 : 20.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Sign Up',
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionGap),
              Text(
                'Create an account to continue!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: sectionGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      hintText: 'Nome',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return 'Informe o nome.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      hintText: 'Sobrenome',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return 'Informe o sobrenome.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldGap),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Informe o email.';
                  }
                  if (!_emailRegex.hasMatch(email)) {
                    return 'Informe um email valido.';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              _buildDateField(
                controller: _birthDateController,
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return 'Informe a data de nascimento.';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              _buildPhoneField(
                theme,
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isEmpty) {
                    return 'Informe o celular.';
                  }
                  if (digits.length != 11) {
                    return 'Informe um celular com 11 digitos.';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Senha',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
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
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) {
                    return 'Informe a senha.';
                  }
                  if (!_passwordRegex.hasMatch(password)) {
                    return 'Use 8+ caracteres com maiuscula, minuscula, numero e especial.';
                  }
                  if (_confirmPasswordController.text.isNotEmpty &&
                      password != _confirmPasswordController.text) {
                    return 'As senhas nao coincidem.';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirmar senha',
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  final confirmPassword = value ?? '';
                  if (confirmPassword.isEmpty) {
                    return 'Confirme a senha.';
                  }
                  if (!_passwordRegex.hasMatch(confirmPassword)) {
                    return 'A confirmacao deve atender a regra da senha.';
                  }
                  if (confirmPassword != _passwordController.text) {
                    return 'As senhas nao coincidem.';
                  }
                  return null;
                },
              ),
              SizedBox(height: sectionGap),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Register'),
                ),
              ),
              SizedBox(height: sectionGap),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: _goBackToLogin,
                      child: Text(
                        'Login',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_submitErrorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _submitErrorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        errorMaxLines: 3,
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: _selectBirthDate,
      decoration: const InputDecoration(
        hintText: 'Data de nascimento',
        suffixIcon: Icon(Icons.calendar_month_rounded),
        errorMaxLines: 3,
      ),
      validator: validator,
    );
  }

  Widget _buildPhoneField(
    ThemeData theme, {
    required FormFieldValidator<String> validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_CountryDialCode>(
              value: _selectedCountryCode,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              borderRadius: BorderRadius.circular(14),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCountryCode = value;
                });
              },
              selectedItemBuilder: (context) {
                return _countryCodes.map((country) {
                  return Center(
                    child: Text(
                      '${country.flag} ${country.dialCode}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList();
              },
              items: _countryCodes.map((country) {
                return DropdownMenuItem<_CountryDialCode>(
                  value: country,
                  child: Text(
                    '${country.flag} ${country.label} ${country.dialCode}',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _phoneController,
            hintText: 'Celular',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: const [_PhoneNumberTextInputFormatter()],
            validator: validator,
          ),
        ),
      ],
    );
  }
}

class _PhoneNumberTextInputFormatter extends TextInputFormatter {
  const _PhoneNumberTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = _format(truncated);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) {
      return '';
    }
    if (digits.length <= 2) {
      return '($digits';
    }
    if (digits.length <= 7) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    }
    if (digits.length <= 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    return digits;
  }
}

class _CountryDialCode {
  const _CountryDialCode({
    required this.flag,
    required this.label,
    required this.dialCode,
  });

  final String flag;
  final String label;
  final String dialCode;
}

class _SignUpSuccessPanel extends StatelessWidget {
  const _SignUpSuccessPanel({required this.email, required this.onBackToLogin});

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Conta criada com sucesso',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 14),
            Text(
              'Enviaremos um email de confirmacao de criacao de conta para $email.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique essa caixa de entrada para concluir a ativacao.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackToLogin,
                child: const Text('Voltar ao login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
