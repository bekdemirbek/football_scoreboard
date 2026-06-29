import 'match_event.dart';
import 'match_lineup.dart';
import 'match_statistic.dart';

class MatchDetail {
  const MatchDetail({
    required this.available,
    this.reason,
    this.events = const [],
    this.homeLineup,
    this.awayLineup,
    this.statRows = const [],
    this.apiHomeTeamId,
    this.apiAwayTeamId,
  });

  final bool available;
  final String? reason;
  final List<MatchEvent> events;
  final TeamLineup? homeLineup;
  final TeamLineup? awayLineup;
  final List<MatchStatRow> statRows;
  final int? apiHomeTeamId;
  final int? apiAwayTeamId;

  bool get hasLineups =>
      homeLineup != null &&
      awayLineup != null &&
      (homeLineup!.startXI.isNotEmpty || awayLineup!.startXI.isNotEmpty);
  bool get hasEvents => events.isNotEmpty;
  bool get hasStats => statRows.isNotEmpty;
  bool get hasAnyData => hasLineups || hasEvents || hasStats;

  List<MatchEvent> get goals =>
      events.where((e) => e.isGoal).toList(growable: false);

  bool isHomeEvent(MatchEvent event) =>
      apiHomeTeamId != null && event.teamId == apiHomeTeamId;

  factory MatchDetail.unavailable(String reason) =>
      MatchDetail(available: false, reason: reason);
}
