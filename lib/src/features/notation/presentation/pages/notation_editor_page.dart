import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/notation_details.dart';
import '../../data/repositories/notation_repository.dart';
import '../../data/services/notation_service.dart';

class NotationEditorPage extends StatefulWidget {
  const NotationEditorPage({
    super.key,
    required this.notationId,
    required this.notationRepository,
    this.initialNotation,
  });

  final String notationId;
  final NotationRepository notationRepository;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final navigator = Navigator.of(context);
        await _flushPendingSave();
        if (mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
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
