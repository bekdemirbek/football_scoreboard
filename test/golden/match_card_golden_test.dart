import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/core/app_theme.dart';
import 'package:football_scoreboard/features/matches/widgets/match_card.dart';
import 'package:football_scoreboard/models/match.dart';

void main() {
  testWidgets('MatchCard golden — finished match with favorite star', (
    tester,
  ) async {
    final match = Match(
      id: '1',
      homeTeam: 'Arsenal FC',
      awayTeam: 'Chelsea FC',
      homeScore: 2,
      awayScore: 1,
      status: 'FINISHED',
      league: 'Premier Lig',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: 340,
              child: MatchCard(match: match, hasFavorite: true, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MatchCard),
      matchesGoldenFile('goldens/match_card_finished.png'),
    );
  });

  testWidgets('MatchCard golden — live match', (tester) async {
    final match = Match(
      id: '2',
      homeTeam: 'Galatasaray SK',
      awayTeam: 'Fenerbahçe SK',
      homeScore: 1,
      awayScore: 1,
      status: "63'",
      league: 'Süper Lig',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: 340,
              child: MatchCard(match: match, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MatchCard),
      matchesGoldenFile('goldens/match_card_live.png'),
    );
  });
}
