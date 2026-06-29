import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_team.dart';
import '../models/football_league.dart';
import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/standing.dart';
import '../models/team.dart';
import '../services/api_football_service.dart';
import '../services/api_service.dart';

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

final matchesProvider = AsyncNotifierProvider<MatchesNotifier, List<Match>>(
  MatchesNotifier.new,
);

class MatchesNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() {
    final selectedDate = ref.watch(selectedMatchDateProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);

    return ref
        .read(apiServiceProvider)
        .fetchMatches(date: selectedDate, league: selectedLeague);
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

final teamMatchesProvider =
    FutureProvider.family<List<Match>, String>((ref, teamId) {
      return ref.read(apiServiceProvider).fetchTeamMatches(teamId);
    });
