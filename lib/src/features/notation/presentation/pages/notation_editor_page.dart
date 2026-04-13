import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/home_page.dart';
import '../../data/models/notation_details.dart';
import '../../data/repositories/notation_repository.dart';
import '../../data/services/notation_service.dart';

class NotationEditorPage extends StatefulWidget {
  const NotationEditorPage({
    super.key,
    required this.notationId,
    required this.notationRepository,
    required this.authRepository,
    required this.onToggleTheme,
    this.initialNotation,
  });

  final String notationId;
  final NotationRepository notationRepository;
  final AuthRepository authRepository;
  final Future<void> Function() onToggleTheme;
  final NotationDetails? initialNotation;

  @override
  State<NotationEditorPage> createState() => _NotationEditorPageState();
}

class _NotationEditorPageState extends State<NotationEditorPage>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  static const _autoSaveDelay = Duration(milliseconds: 900);

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCreatingNotation = false;
  bool _isDirty = false;
  bool _saveQueued = false;
  bool _hasLoadedInitialValue = false;
  String? _errorMessage;
  String? _lastSavedTitle;
  String? _lastSavedContent;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController.addListener(_onEditorChanged);
    _contentController.addListener(_onEditorChanged);
    _loadNotation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _titleController.removeListener(_onEditorChanged);
    _contentController.removeListener(_onEditorChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_flushPendingSave());
    }
  }

  Future<void> _loadNotation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notation =
          widget.initialNotation ??
          await widget.notationRepository.getById(widget.notationId);

      _titleController.text = notation.title;
      _contentController.text = notation.content;
      _lastSavedTitle = notation.title;
      _lastSavedContent = notation.content;
      _hasLoadedInitialValue = true;
      _isDirty = false;
    } on NotationException catch (error) {
      _errorMessage = error.message;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onEditorChanged() {
    if (_isLoading || !_hasLoadedInitialValue) {
      return;
    }

    final hasChanges =
        _titleController.text != (_lastSavedTitle ?? '') ||
        _contentController.text != (_lastSavedContent ?? '');
    _isDirty = hasChanges;
    _errorMessage = null;

    _autoSaveTimer?.cancel();
    if (!hasChanges) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _autoSaveTimer = Timer(_autoSaveDelay, () {
      unawaited(_saveNotation());
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _flushPendingSave() async {
    _autoSaveTimer?.cancel();
    await _saveNotation();
  }

  Future<void> _saveNotation() async {
    if (_isLoading || !_isDirty) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text;
    if (title.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Informe um titulo para a anotacao.';
        });
      } else {
        _errorMessage = 'Informe um titulo para a anotacao.';
      }
      return;
    }

    if (_isSaving) {
      _saveQueued = true;
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await widget.notationRepository.updateNotation(
        notationId: widget.notationId,
        title: title,
        content: content,
      );

      _lastSavedTitle = updated.title;
      _lastSavedContent = updated.content;
      _isDirty =
          _titleController.text != updated.title ||
          _contentController.text != updated.content;

      if (!mounted) {
        return;
      }
    } on NotationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }

      if (_saveQueued) {
        _saveQueued = false;
        await _saveNotation();
      }
    }
  }

  Future<void> _createAnotherNotation() async {
    if (_isCreatingNotation) {
      return;
    }

    setState(() {
      _isCreatingNotation = true;
      _errorMessage = null;
    });

    try {
      await _flushPendingSave();

      final created = await widget.notationRepository.createNotation(
        title: 'Exemplo',
        content: '',
      );
      final notation = await widget.notationRepository.getById(
        created.notationId,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => NotationEditorPage(
            notationId: notation.notationId,
            notationRepository: widget.notationRepository,
            authRepository: widget.authRepository,
            onToggleTheme: widget.onToggleTheme,
            initialNotation: notation,
          ),
        ),
      );
    } on NotationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingNotation = false;
        });
      }
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          authRepository: widget.authRepository,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pillColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF6F1E8);
    final outlineColor = isDark
        ? const Color(0xFF353535)
        : const Color(0xFFE7DDD0);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _flushPendingSave();
        if (mounted) {
          _goToHome();
        }
      },
      child: Scaffold(
        floatingActionButton: Tooltip(
          message: 'Nova anotacao',
          child: Material(
            color: pillColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _isCreatingNotation ? null : _createAnotherNotation,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor),
                ),
                child: Center(
                  child: _isCreatingNotation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                ),
              ),
            ),
          ),
        ),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              await _flushPendingSave();
              if (mounted) {
                _goToHome();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && !_hasLoadedInitialValue
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadNotation,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _titleController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(70),
                                  ],
                                  style: theme.textTheme.headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'Titulo',
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _contentController,
                                    expands: true,
                                    minLines: null,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.5,
                                    ),
                                    decoration: const InputDecoration(
                                      alignLabelWithHint: true,
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
