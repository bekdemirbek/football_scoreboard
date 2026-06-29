import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/core/app_theme.dart';
import 'package:football_scoreboard/features/matches/widgets/matches_header.dart';

void main() {
  testWidgets('match header shows app title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SafeArea(child: MatchesHeader())),
      ),
    );

    expect(find.text('MAÇKART'), findsOneWidget);
  });
}
