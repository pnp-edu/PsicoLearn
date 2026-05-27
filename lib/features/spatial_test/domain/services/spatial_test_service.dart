import 'package:psicolearn/features/spatial_test/data/repositories/spatial_repository.dart';
import 'package:psicolearn/features/spatial_test/domain/models/spatial_question.dart';
import 'package:psicolearn/core/services/storage_service.dart';

class SpatialTestService {
  final StorageService _storage;
  static const String _keyFailedSpatial = 'failed_spatial_questions';
  static const String _keyBestSpatialScore = 'best_spatial_score';

  SpatialTestService(this._storage);

  List<SpatialQuestion> getQuestions() => SpatialRepository.preguntas;
  
  Future<void> trackError(int questionId) async {
    List<String> failures = _storage.getStringList(_keyFailedSpatial) ?? [];
    if (!failures.contains(questionId.toString())) {
      failures.add(questionId.toString());
      await _storage.setStringList(_keyFailedSpatial, failures);
    }
  }

  Future<List<SpatialQuestion>> getFailedQuestions() async {
    final failedIds = (_storage.getStringList(_keyFailedSpatial) ?? [])
        .map((e) => int.parse(e))
        .toList();
    if (failedIds.isEmpty) return [];
    return SpatialRepository.preguntas.where((q) => failedIds.contains(q.id)).toList();
  }

  Future<void> setBestScore(int score) async {
    final currentBest = getBestScore();
    if (score > currentBest) {
      await _storage.setInt(_keyBestSpatialScore, score);
    }
  }

  int getBestScore() => _storage.getInt(_keyBestSpatialScore) ?? 0;
}
