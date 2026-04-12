import '../../../auth/data/repositories/auth_repository.dart';
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
    return _notationService.getList(_authRepository.authorizationHeaders);
  }

  Future<NotationDetails> getById(String notationId) {
    return _notationService.getById(
      notationId,
      _authRepository.authorizationHeaders,
    );
  }

  Future<NotationDetails> createNotation({
    required String title,
    required String content,
  }) {
    return _notationService.createNotation(
      title: title,
      content: content,
      headers: _authRepository.authorizationHeaders,
    );
  }

  Future<NotationDetails> updateNotation({
    required String notationId,
    required String title,
    required String content,
  }) {
    return _notationService.updateNotation(
      notationId: notationId,
      title: title,
      content: content,
      headers: _authRepository.authorizationHeaders,
    );
  }
}
