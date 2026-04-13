import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/models/notation_list_item.dart';
import '../../data/repositories/notation_repository.dart';
import '../../data/services/notation_service.dart';
import 'notation_editor_page.dart';

class NotationSearchPage extends StatefulWidget {
  const NotationSearchPage({
    super.key,
    required this.notationRepository,
    required this.authRepository,
    required this.onToggleTheme,
  });

  final NotationRepository notationRepository;
  final AuthRepository authRepository;
  final Future<void> Function() onToggleTheme;

  @override
  State<NotationSearchPage> createState() => _NotationSearchPageState();
}

class _NotationSearchPageState extends State<NotationSearchPage> {
  final _searchController = TextEditingController();
  static const _searchDebounce = Duration(milliseconds: 260);
  Timer? _searchDebounceTimer;

  List<NotationListItem> _notations = const [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _activeNotationId;
  int _searchNonce = 0;
  bool _isHandlingUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _triggerSearch();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, _triggerSearch);
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _triggerSearch() async {
    final nonce = ++_searchNonce;
    final query = _searchController.text.trim();

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.notationRepository.searchByTitle(query);
      if (!mounted || nonce != _searchNonce) {
        return;
      }

      setState(() {
        _notations = result;
      });
    } on NotationException catch (error) {
      if (!mounted || nonce != _searchNonce) {
        return;
      }

      if (error.isUnauthorized) {
        await _handleUnauthorizedSession();
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted && nonce == _searchNonce) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _openNotation(NotationListItem notation) async {
    setState(() {
      _activeNotationId = notation.notationId;
    });

    try {
      final details = await widget.notationRepository.getById(
        notation.notationId,
      );
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotationEditorPage(
            notationId: notation.notationId,
            notationRepository: widget.notationRepository,
            authRepository: widget.authRepository,
            onToggleTheme: widget.onToggleTheme,
            initialNotation: details,
          ),
        ),
      );

      if (mounted) {
        await _triggerSearch();
      }
    } on NotationException catch (error) {
      if (error.isUnauthorized) {
        await _handleUnauthorizedSession();
        return;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _activeNotationId = null;
        });
      }
    }
  }

  Future<bool> _deleteNotation(String notationId) async {
    try {
      await widget.notationRepository.deleteNotation(notationId);
      return true;
    } on NotationException catch (error) {
      if (error.isUnauthorized) {
        await _handleUnauthorizedSession();
        return false;
      }

      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    }
  }

  Future<void> _handleUnauthorizedSession() async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;
    await widget.authRepository.clearSession();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(
          authRepository: widget.authRepository,
          onThemeChanged: (_) {},
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
    final inputOutline = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE7DDD0);
    final tileBackground = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFFFFFFF);
    final secondaryTextColor = isDark
        ? const Color(0xFFACACAC)
        : const Color(0xFF7A746D);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Voltar',
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: inputOutline),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText: 'Buscar por titulo',
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_isSearching)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _triggerSearch();
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              splashRadius: 18,
                              tooltip: 'Limpar',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _buildContent(tileBackground, inputOutline, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    Color tileBackground,
    Color outlineColor,
    ThemeData theme,
  ) {
    if (_errorMessage != null) {
      return Center(
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
              onPressed: _triggerSearch,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_notations.isEmpty && !_isSearching) {
      return Center(
        child: Text(
          'Nenhuma anotacao encontrada.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _notations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notation = _notations[index];
        final isOpening = _activeNotationId == notation.notationId;

        return Dismissible(
          key: ValueKey('search-notation-${notation.notationId}'),
          direction: isOpening
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: const SizedBox.shrink(),
          secondaryBackground: const _DeleteSwipeBackground(),
          confirmDismiss: (_) => _deleteNotation(notation.notationId),
          onDismissed: (_) {
            setState(() {
              _notations = _notations
                  .where((item) => item.notationId != notation.notationId)
                  .toList();
            });
          },
          child: Material(
            color: tileBackground,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isOpening ? null : () => _openNotation(notation),
              child: Ink(
                decoration: BoxDecoration(
                  color: tileBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: outlineColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          notation.title.isEmpty
                              ? 'Sem titulo'
                              : notation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      isOpening
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeleteSwipeBackground extends StatelessWidget {
  const _DeleteSwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x14E53935),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x66E53935)),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFFD32F2F),
        size: 22,
      ),
    );
  }
}
