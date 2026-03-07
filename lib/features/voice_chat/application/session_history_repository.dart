import '../domain/entities/daily_challenge.dart';
import '../domain/entities/daily_challenge_history.dart';
import '../domain/entities/practice_session_record.dart';

abstract class SessionHistoryRepository {
  Future<void> saveSession(PracticeSessionRecord session);

  Future<List<PracticeSessionRecord>> getSessions();

  Future<DailyChallenge> getDailyChallenge();

  Future<DailyChallengeHistory> getDailyChallengeHistory();

  Future<void> markDailyChallengeCompleted({required String dateKey});
}
