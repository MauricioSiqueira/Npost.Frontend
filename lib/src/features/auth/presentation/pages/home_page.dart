import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import '../../../notation/data/models/notation_list_item.dart';
import '../../../notation/data/repositories/notation_repository.dart';
import '../../../notation/data/services/notation_service.dart';
import '../../../notation/presentation/pages/notation_editor_page.dart';
import '../../../notation/presentation/pages/notation_search_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.authRepository,
    required this.onToggleTheme,
  });

  final AuthRepository authRepository;
  final Future<void> Function() onToggleTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final NotationRepository _notationRepository;

  bool _isLoggingOut = false;
  bool _isHandlingUnauthorized = false;
  bool _isCreatingNotation = false;
  String? _activeNotationId;
  late Future<List<NotationListItem>> _notationsFuture;

  @override
  void initState() {
    super.initState();
    _notationRepository = NotationRepository(
      authRepository: widget.authRepository,
      notationService: const NotationService(),
    );
    _notationsFuture = _fetchNotations();
  }

  Future<List<NotationListItem>> _fetchNotations() async {
    try {
      return await _notationRepository.getList();
    } on NotationException catch (error) {
      if (error.isUnauthorized) {
        await _handleUnauthorizedSession();
        return const [];
      }

      rethrow;
    }
  }

  Future<void> _reloadNotations() async {
    final future = _fetchNotations();
    setState(() {
      _notationsFuture = future;
    });
    await future;
  }

  Future<void> _openNotation(String notationId) async {
    setState(() {
      _activeNotationId = notationId;
    });

    try {
      final notation = await _notationRepository.getById(notationId);
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotationEditorPage(
            notationId: notationId,
            notationRepository: _notationRepository,
            initialNotation: notation,
          ),
        ),
      );

      if (mounted) {
        await _reloadNotations();
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

  Future<void> _createNotation() async {
    setState(() {
      _isCreatingNotation = true;
    });

    try {
      final created = await _notationRepository.createNotation(
        title: 'Exemplo',
        content: '',
      );
      final notation = await _notationRepository.getById(created.notationId);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotationEditorPage(
            notationId: notation.notationId,
            notationRepository: _notationRepository,
            initialNotation: notation,
          ),
        ),
      );

      if (mounted) {
        await _reloadNotations();
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
          _isCreatingNotation = false;
        });
      }
    }
  }

  Future<void> _openSearchPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotationSearchPage(
          notationRepository: _notationRepository,
          authRepository: widget.authRepository,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );

    if (mounted) {
      await _reloadNotations();
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    AuthException? error;
    try {
      await widget.authRepository.logout();
    } on AuthException catch (caught) {
      error = caught;
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (error != null && !error.isUnauthorized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }

    _openLoginPage();
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

    _openLoginPage();
  }

  void _openLoginPage() {
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
    final session = widget.authRepository.currentSession;
    final displayName = session?.userName.isNotEmpty == true
        ? session!.userName
        : 'Usuario';
    final email = session?.email ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFFFFFFF);
    final pillColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF6F1E8);
    final outlineColor = isDark
        ? const Color(0xFF353535)
        : const Color(0xFFE7DDD0);
    final secondaryTextColor = isDark
        ? const Color(0xFFACACAC)
        : const Color(0xFF7A746D);
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
    final userInitial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : 'U';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _isCreatingNotation ? null : _createNotation,
        backgroundColor: surfaceColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outlineColor),
        ),
        child: _isCreatingNotation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.1),
              )
            : const Icon(Icons.edit_outlined),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Row(
            children: [
              _TopIconButton(
                tooltip: 'Pesquisar anotacoes',
                onTap: () {
                  _openSearchPage();
                },
                icon: Icons.search_rounded,
                surfaceColor: pillColor,
                outlineColor: outlineColor,
                iconColor: theme.colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PopupMenuButton<_UserMenuAction>(
                          enabled: !_isLoggingOut,
                          tooltip: 'Menu do usuario',
                          color: surfaceColor,
                          surfaceTintColor: surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: outlineColor),
                          ),
                          position: PopupMenuPosition.under,
                          onSelected: (value) {
                            if (value == _UserMenuAction.logout) {
                              _logout();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<_UserMenuAction>(
                              enabled: false,
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: secondaryTextColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem<_UserMenuAction>(
                              value: _UserMenuAction.logout,
                              child: Row(
                                children: [
                                  if (_isLoggingOut)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.logout, size: 18),
                                  const SizedBox(width: 10),
                                  const Text('Logoff'),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: pillColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: outlineColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: outlineColor,
                                  child: Text(
                                    userInitial,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.keyboard_arrow_down_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _TopIconButton(
                        tooltip: isDark ? 'Tema claro' : 'Tema escuro',
                        onTap: () {
                          widget.onToggleTheme();
                        },
                        icon: isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        surfaceColor: pillColor,
                        outlineColor: outlineColor,
                        iconColor: theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Suas anotacoes', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<NotationListItem>>(
                      future: _notationsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          final exception = snapshot.error;
                          if (exception is NotationException &&
                              exception.isUnauthorized) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _handleUnauthorizedSession();
                            });

                            return const SizedBox.shrink();
                          }

                          final message = exception is NotationException
                              ? exception.message
                              : 'Nao foi possivel carregar as anotacoes.';

                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _reloadNotations,
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          );
                        }

                        final notations = snapshot.data ?? const [];
                        if (notations.isEmpty) {
                          return Center(
                            child: Text(
                              'Voce ainda nao possui anotacoes.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: notations.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notation = notations[index];
                            final isOpening =
                                _activeNotationId == notation.notationId;

                            return Material(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: isOpening
                                    ? null
                                    : () => _openNotation(notation.notationId),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
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
                                            style: titleStyle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        isOpening
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.chevron_right_rounded,
                                                size: 20,
                                                color: secondaryTextColor,
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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

enum _UserMenuAction { logout }

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    required this.surfaceColor,
    required this.outlineColor,
    required this.iconColor,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;
  final Color surfaceColor;
  final Color outlineColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
