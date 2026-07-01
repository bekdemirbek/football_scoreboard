import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_team.dart';
import '../models/football_league.dart';
import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/scorer.dart';
import '../models/standing.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/team.dart';
import '../models/team_squad.dart';
import '../services/api_football_service.dart';
import '../services/api_service.dart';
import '../services/quiz_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  const apiKey = String.fromEnvironment('FOOTBALL_DATA_API_KEY');
  const baseUrl = String.fromEnvironment(
    'FOOTBALL_DATA_BASE_URL',
    defaultValue: 'https://api.football-data.org/v4',
  );
  const proxyUrl = String.fromEnvironment('API_PROXY_URL');

  return ApiService(apiKey: apiKey, baseUrl: baseUrl, proxyUrl: proxyUrl);
});

final apiFootballServiceProvider = Provider<ApiFootballService>((ref) {
  const apiKey = String.fromEnvironment('API_FOOTBALL_KEY');
  const proxyUrl = String.fromEnvironment('API_PROXY_URL');

  return ApiFootballService(apiKey: apiKey, proxyUrl: proxyUrl);
});

final matchDetailProvider = FutureProvider.family<MatchDetail, Match>((
  ref,
  match,
) {
  return ref.read(apiFootballServiceProvider).fetchMatchDetail(match: match);
});

final selectedMatchDateProvider =
    NotifierProvider<SelectedMatchDateNotifier, DateTime>(
      SelectedMatchDateNotifier.new,
    );

class SelectedMatchDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final selectedLeagueProvider =
    NotifierProvider<SelectedLeagueNotifier, FootballLeague>(
      SelectedLeagueNotifier.new,
    );

class SelectedLeagueNotifier extends Notifier<FootballLeague> {
  @override
  FootballLeague build() {
    return footballLeagues.firstWhere(
      (league) => league.id == 'PL',
      orElse: () => footballLeagues.first,
    );
  }

  void selectLeague(FootballLeague league) {
    state = league;
  }
}

final selectedStandingsLeagueProvider =
    NotifierProvider<SelectedStandingsLeagueNotifier, FootballLeague>(
      SelectedStandingsLeagueNotifier.new,
    );

class SelectedStandingsLeagueNotifier extends Notifier<FootballLeague> {
  @override
  FootballLeague build() {
    return footballLeagues.firstWhere(
      (league) => league.id == 'PL',
      orElse: () => footballLeagues.firstWhere((league) => league.id != null),
    );
  }

  void selectLeague(FootballLeague league) {
    if (league.id == null) return;
    state = league;
  }
}

/// Ekran içi arama metni (takım/oyuncu filtreleme). Boş = filtre yok.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final matchesSearchProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
final standingsSearchProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
final scorersSearchProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final matchesProvider = AsyncNotifierProvider<MatchesNotifier, List<Match>>(
  MatchesNotifier.new,
);

class MatchesNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() {
    final selectedDate = ref.watch(selectedMatchDateProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);
    final service = ref.read(apiServiceProvider);

    if (selectedLeague.id == 'ALL') {
      return service.fetchMatchesAllLeagues(
        date: selectedDate,
        leagues: footballLeagues,
      );
    }

    return service.fetchMatches(date: selectedDate, league: selectedLeague);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final standingsProvider =
    AsyncNotifierProvider<StandingsNotifier, List<Standing>>(
      StandingsNotifier.new,
    );

class StandingsNotifier extends AsyncNotifier<List<Standing>> {
  @override
  Future<List<Standing>> build() {
    final league = ref.watch(selectedStandingsLeagueProvider);
    return ref.read(apiServiceProvider).fetchStandings(leagueId: league.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final knockoutMatchesProvider =
    AsyncNotifierProvider<KnockoutMatchesNotifier, List<Match>>(
      KnockoutMatchesNotifier.new,
    );

class KnockoutMatchesNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() async {
    final league = ref.watch(selectedStandingsLeagueProvider);
    final standings = await ref.watch(standingsProvider.future);
    final groups = standings.map((s) => s.group).whereType<String>().toSet();

    // Only group-stage tournaments (e.g. World Cup) have a knockout bracket;
    // skip the extra full-season request for plain league tables.
    if (groups.length < 2) return const [];

    return ref
        .read(apiServiceProvider)
        .fetchKnockoutMatches(leagueId: league.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(
  TeamsNotifier.new,
);

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() {
    return ref.read(apiServiceProvider).fetchTeams();
  }
}

final favoriteTeamsProvider =
    AsyncNotifierProvider<FavoriteTeamsNotifier, List<FavoriteTeam>>(
      FavoriteTeamsNotifier.new,
    );

class FavoriteTeamsNotifier extends AsyncNotifier<List<FavoriteTeam>> {
  static const _storageKey = 'favorite_teams_v2';

  @override
  Future<List<FavoriteTeam>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    return FavoriteTeam.listFromPrefs(raw);
  }

  Future<void> toggle(FavoriteTeam team) async {
    final current = List<FavoriteTeam>.from(state.value ?? await build());
    final idx = current.indexWhere((t) => t == team);
    if (idx >= 0) {
      current.removeAt(idx);
    } else {
      current.add(team);
    }

    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, FavoriteTeam.listToPrefs(current));
  }

  bool isFavorite(FavoriteTeam team) => state.value?.contains(team) ?? false;

  bool isFavoriteByName(String name) =>
      state.value?.any((t) => t.name == name) ?? false;
}

final teamMatchesProvider = FutureProvider.family<List<Match>, String>((
  ref,
  teamId,
) {
  return ref.read(apiServiceProvider).fetchTeamMatches(teamId);
});

final teamSquadProvider = FutureProvider.family<TeamSquad, String>((
  ref,
  teamId,
) {
  return ref.read(apiServiceProvider).fetchSquad(teamId);
});

// ─── Scorers ───────────────────────────────────────────────────────────────────

final selectedScorersLeagueProvider =
    NotifierProvider<SelectedScorersLeagueNotifier, FootballLeague>(
      SelectedScorersLeagueNotifier.new,
    );

class SelectedScorersLeagueNotifier extends Notifier<FootballLeague> {
  @override
  FootballLeague build() => footballLeagues.firstWhere(
    (l) => l.id == 'PL',
    orElse: () => footballLeagues.first,
  );

  void selectLeague(FootballLeague league) {
    if (league.id == null) return;
    state = league;
  }
}

/// Gol krallığı / Asist krallığı sıralama modu.
enum ScorerSortMode { goals, assists }

final scorerSortModeProvider =
    NotifierProvider<ScorerSortModeNotifier, ScorerSortMode>(
      ScorerSortModeNotifier.new,
    );

class ScorerSortModeNotifier extends Notifier<ScorerSortMode> {
  @override
  ScorerSortMode build() => ScorerSortMode.goals;

  void select(ScorerSortMode mode) => state = mode;
}

final scorersProvider = AsyncNotifierProvider<ScorersNotifier, List<Scorer>>(
  ScorersNotifier.new,
);

class ScorersNotifier extends AsyncNotifier<List<Scorer>> {
  @override
  Future<List<Scorer>> build() {
    final league = ref.watch(selectedScorersLeagueProvider);
    return ref.read(apiServiceProvider).fetchScorers(leagueId: league.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

// ─── Oyunlar (tahmin) ────────────────────────────────────────────────────────────

/// Oyunlar sekmesinin kendi lig seçimi (diğer sekmeleri etkilemez).
final selectedGamesLeagueProvider =
    NotifierProvider<SelectedGamesLeagueNotifier, FootballLeague>(
      SelectedGamesLeagueNotifier.new,
    );

class SelectedGamesLeagueNotifier extends Notifier<FootballLeague> {
  @override
  FootballLeague build() => footballLeagues.firstWhere(
    (l) => l.id == 'PL',
    orElse: () => footballLeagues.first,
  );

  void select(FootballLeague league) {
    if (league.id == null) return;
    state = league;
  }
}

final gamesStandingsProvider = FutureProvider<List<Standing>>((ref) {
  final league = ref.watch(selectedGamesLeagueProvider);
  return ref.read(apiServiceProvider).fetchStandings(leagueId: league.id);
});

final gamesScorersProvider = FutureProvider<List<Scorer>>((ref) {
  final league = ref.watch(selectedGamesLeagueProvider);
  return ref.read(apiServiceProvider).fetchScorers(leagueId: league.id);
});

/// Kullanıcının tahminleri (yerel, shared_preferences).
/// standings: ligId → tahmini takım sıralaması (isim listesi)
/// topScorer: ligId → tahmini gol kralı oyuncu adı
class PredictionState {
  const PredictionState({this.standings = const {}, this.topScorer = const {}});

  final Map<String, List<String>> standings;
  final Map<String, String> topScorer;

  PredictionState copyWith({
    Map<String, List<String>>? standings,
    Map<String, String>? topScorer,
  }) {
    return PredictionState(
      standings: standings ?? this.standings,
      topScorer: topScorer ?? this.topScorer,
    );
  }
}

final predictionsProvider =
    AsyncNotifierProvider<PredictionsNotifier, PredictionState>(
      PredictionsNotifier.new,
    );

class PredictionsNotifier extends AsyncNotifier<PredictionState> {
  static const _key = 'predictions_v1';

  @override
  Future<PredictionState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const PredictionState();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final standings = <String, List<String>>{};
      final standingsRaw = map['standings'];
      if (standingsRaw is Map) {
        standingsRaw.forEach((k, v) {
          if (v is List) {
            standings[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
      }
      final topScorer = <String, String>{};
      final topRaw = map['topScorer'];
      if (topRaw is Map) {
        topRaw.forEach((k, v) => topScorer[k.toString()] = v.toString());
      }
      return PredictionState(standings: standings, topScorer: topScorer);
    } catch (_) {
      return const PredictionState();
    }
  }

  Future<void> _persist(PredictionState next) async {
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({'standings': next.standings, 'topScorer': next.topScorer}),
    );
  }

  Future<void> saveStandings(String leagueId, List<String> order) async {
    final current = state.value ?? const PredictionState();
    final updated = Map<String, List<String>>.from(current.standings)
      ..[leagueId] = order;
    await _persist(current.copyWith(standings: updated));
  }

  Future<void> saveTopScorer(String leagueId, String player) async {
    final current = state.value ?? const PredictionState();
    final updated = Map<String, String>.from(current.topScorer)
      ..[leagueId] = player;
    await _persist(current.copyWith(topScorer: updated));
  }
}

// ─── Futbol Quiz ──────────────────────────────────────────────────────────────────

final quizServiceProvider = Provider<QuizService>((ref) => QuizService());

/// Aktif quiz turunun durumu (sorular, ilerleme, skor, süre başlangıcı).
class QuizState {
  const QuizState({
    this.isLoading = false,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.selectedIndex,
    this.isFinished = false,
    this.startTime,
    this.result,
  });

  final bool isLoading;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final int? selectedIndex; // null = bu soruya henüz cevap verilmedi
  final bool isFinished;
  final DateTime? startTime;
  final QuizResult? result; // tur bitince doldurulur

  bool get hasAnswered => selectedIndex != null;
  int get total => questions.length;
  bool get hasQuestions => questions.isNotEmpty;
  QuizQuestion? get currentQuestion =>
      hasQuestions ? questions[currentIndex] : null;

  QuizState copyWith({
    bool? isLoading,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    int? selectedIndex,
    bool clearSelected = false,
    bool? isFinished,
    DateTime? startTime,
    QuizResult? result,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedIndex: clearSelected
          ? null
          : (selectedIndex ?? this.selectedIndex),
      isFinished: isFinished ?? this.isFinished,
      startTime: startTime ?? this.startTime,
      result: result ?? this.result,
    );
  }
}

final quizControllerProvider = NotifierProvider<QuizNotifier, QuizState>(
  QuizNotifier.new,
);

class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState();

  /// Yeni bir tur başlatır: havuzdan rastgele sorular çekip süreyi başlatır.
  Future<void> start({int questionCount = 10}) async {
    state = const QuizState(isLoading: true);
    final questions = await ref
        .read(quizServiceProvider)
        .buildQuiz(count: questionCount);
    state = QuizState(questions: questions, startTime: DateTime.now());
  }

  void selectAnswer(int index) {
    final question = state.currentQuestion;
    if (state.hasAnswered || question == null) return; // çift cevaba izin verme
    final isCorrect = index == question.correctIndex;
    state = state.copyWith(
      selectedIndex: index,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  /// Sonraki soruya geçer; son soruysa turu bitirip sonucu kaydeder.
  Future<void> next() async {
    if (!state.hasAnswered) return;
    final isLast = state.currentIndex + 1 >= state.total;
    if (!isLast) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelected: true,
      );
      return;
    }

    final elapsed = state.startTime == null
        ? Duration.zero
        : DateTime.now().difference(state.startTime!);
    final result = QuizResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      correctCount: state.score,
      totalQuestions: state.total,
      elapsed: elapsed,
      playedAt: DateTime.now(),
    );
    state = state.copyWith(isFinished: true, result: result);
    await ref.read(quizLeaderboardProvider.notifier).addResult(result);
  }
}

final quizLeaderboardProvider =
    AsyncNotifierProvider<QuizLeaderboardNotifier, List<QuizResult>>(
      QuizLeaderboardNotifier.new,
    );

class QuizLeaderboardNotifier extends AsyncNotifier<List<QuizResult>> {
  static const _key = 'quiz_leaderboard_v1';
  static const _limit = 20;

  @override
  Future<List<QuizResult>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final results = <QuizResult>[];
    for (final entry in raw) {
      try {
        results.add(
          QuizResult.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (_) {
        // bozuk kayıt atlanır
      }
    }
    results.sort(_compare);
    return results.take(_limit).toList();
  }

  Future<void> addResult(QuizResult result) async {
    // build() henüz tamamlanmadıysa mevcut (kaydedilmiş) listeyi bekle ki
    // üzerine yazıp eski skorları kaybetmeyelim.
    final existing = await future;
    final current = List<QuizResult>.from(existing)..add(result);
    current.sort(_compare);
    final trimmed = current.take(_limit).toList();

    state = AsyncData(trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      trimmed.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  /// Önce doğru sayısı (yüksek→düşük), eşitlikte süre (kısa→uzun).
  static int _compare(QuizResult a, QuizResult b) {
    final byScore = b.correctCount.compareTo(a.correctCount);
    if (byScore != 0) return byScore;
    return a.elapsed.compareTo(b.elapsed);
  }
}
