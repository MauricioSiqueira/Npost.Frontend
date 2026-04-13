import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/services/auth_service.dart';
import '../models/notation_details.dart';
import '../models/notation_list_item.dart';
import '../services/notation_service.dart';

class NotationRepository {
  NotationRepository({
    required AuthRepository authRepository,
    required NotationService notationService,
  }) : _authRepository = authRepository,
       _notationService = notationService;

  final AuthRepository _authRepository;
  final NotationService _notationService;

  Future<List<NotationListItem>> getList() {
    return _withAuthRetry(
      () => _notationService.getList(_authRepository.authorizationHeaders),
    );
  }

  Future<List<NotationListItem>> searchByTitle(String titleQuery) {
    return _withAuthRetry(
      () => _notationService.searchByTitle(
        titleQuery,
        _authRepository.authorizationHeaders,
      ),
    );
  }

  Future<NotationDetails> getById(String notationId) {
    return _withAuthRetry(
      () => _notationService.getById(
        notationId,
        _authRepository.authorizationHeaders,
      ),
    );
  }

  Future<NotationDetails> createNotation({
    required String title,
    required String content,
  }) {
    return _withAuthRetry(
      () => _notationService.createNotation(
        title: title,
        content: content,
        headers: _authRepository.authorizationHeaders,
      ),
    );
  }

  Future<NotationDetails> updateNotation({
    required String notationId,
    required String title,
    required String content,
  }) {
    return _withAuthRetry(
      () => _notationService.updateNotation(
        notationId: notationId,
        title: title,
        content: content,
        headers: _authRepository.authorizationHeaders,
      ),
    );
  }

  Future<void> deleteNotation(String notationId) {
    return _withAuthRetry(
      () => _notationService.deleteNotation(
        notationId,
        _authRepository.authorizationHeaders,
      ),
    );
  }

  Future<T> _withAuthRetry<T>(Future<T> Function() operation) async {
    final canUseCurrentToken = await _authRepository.ensureValidAccessToken();
    if (!canUseCurrentToken) {
      throw const NotationException(
        'Sessao expirada. Faca login novamente.',
        isUnauthorized: true,
      );
    }

    try {
      return await operation();
    } on NotationException catch (error) {
      if (!error.isUnauthorized) {
        rethrow;
      }

      final refreshed = await _tryRefreshAfterUnauthorized();
      if (!refreshed) {
        rethrow;
      }

      return operation();
    }
  }

  Future<bool> _tryRefreshAfterUnauthorized() async {
    try {
      return await _authRepository.tryRefreshSession();
    } on AuthException catch (error) {
      throw NotationException(error.message);
    }
  }
}
