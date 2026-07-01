import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/scorer.dart';
import '../../models/standing.dart';
import '../../providers/api_providers.dart';
import '../../widgets/screen_header.dart';
import '../matches/widgets/league_selector.dart';
import '../matches/widgets/team_badge.dart';
import '../quiz/quiz_start_view.dart';

class GamesPage extends ConsumerStatefulWidget {
  const GamesPage({super.key});

  @override
  ConsumerState<GamesPage> createState() => _GamesPageState();
}

enum _GameKind { standings, topScorer, quiz }

class _GamesPageState extends ConsumerState<GamesPage> {
  _GameKind _kind = _GameKind.standings;

  String _labelOf(_GameKind kind) => switch (kind) {
    _GameKind.standings => 'Sıralama',
    _GameKind.topScorer => 'Gol Kralı',
    _GameKind.quiz => 'Quiz',
  };

  @override
  Widget build(BuildContext context) {
    final selectedLeague = ref.watch(selectedGamesLeagueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            const ScreenHeader(title: 'Oyunlar'),
            const SizedBox(height: 16),
            SegmentedTabs<_GameKind>(
              items: const [
                _GameKind.standings,
                _GameKind.topScorer,
                _GameKind.quiz,
              ],
              selected: _kind,
              labelOf: _labelOf,
              onSelected: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: 12),
            // Lig seçimi yalnızca lig-temelli oyunlarda gösterilir.
            if (_kind != _GameKind.quiz) ...[
              LeagueSelector(
                selectedLeague: selectedLeague,
                onLeagueSelected: (l) =>
                    ref.read(selectedGamesLeagueProvider.notifier).select(l),
              ),
              const SizedBox(height: 18),
            ],
            switch (_kind) {
              _GameKind.standings => _StandingsGame(
                leagueId: selectedLeague.id ?? '',
              ),
              _GameKind.topScorer => _TopScorerGame(
                leagueId: selectedLeague.id ?? '',
              ),
              _GameKind.quiz => const QuizStartView(),
            },
          ],
        ),
      ),
    );
  }
}

// ─── Oyun 1: Sıralama Tahmini ────────────────────────────────────────────────────

class _StandingsGame extends ConsumerStatefulWidget {
  const _StandingsGame({required this.leagueId});
  final String leagueId;

  @override
  ConsumerState<_StandingsGame> createState() => _StandingsGameState();
}

class _StandingsGameState extends ConsumerState<_StandingsGame> {
  List<String> _order = [];
  String? _orderLeagueId;
  bool _showResult = false;

  void _ensureOrder(List<Standing> standings, PredictionState? prediction) {
    if (_orderLeagueId == widget.leagueId && _order.isNotEmpty) return;
    final saved = prediction?.standings[widget.leagueId];
    final names = standings.map((s) => s.teamName).toList();
    if (saved != null && saved.toSet().containsAll(names.toSet())) {
      _order = List<String>.from(saved);
    } else {
      // Gerçek sıralamayı vermeyelim ki tahmin anlamlı olsun:
      // başlangıçta alfabetik dizilir, kullanıcı kendi sıralamasını kurar.
      _order = names
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    _orderLeagueId = widget.leagueId;
    _showResult = false;
  }

  @override
  Widget build(BuildContext context) {
    final standingsAsync = ref.watch(gamesStandingsProvider);
    final predictionAsync = ref.watch(predictionsProvider);

    return standingsAsync.when(
      loading: () => const _GameLoading(),
      error: (e, _) => _GameError(message: e.toString()),
      data: (standings) {
        if (standings.isEmpty) {
          return const _GameInfo(message: 'Bu lig için sıralama verisi yok.');
        }
        _ensureOrder(standings, predictionAsync.value);

        final actualRank = <String, int>{
          for (final s in standings) s.teamName: s.rank,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GameTitleCard(
              icon: Icons.format_list_numbered_rounded,
              title: 'Sezon sonu sıralamasını tahmin et',
              subtitle:
                  'Takımları sürükleyip kendi tahminini oluştur, sonra '
                  'güncel sıralamayla puanını gör.',
            ),
            const SizedBox(height: 14),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _order.removeAt(oldIndex);
                  _order.insert(newIndex, item);
                  _showResult = false;
                });
              },
              itemBuilder: (context, index) {
                final name = _order[index];
                return _ReorderTeamTile(
                  key: ValueKey(name),
                  index: index,
                  position: index + 1,
                  name: name,
                  showResult: _showResult,
                  actualRank: actualRank[name],
                );
              },
            ),
            const SizedBox(height: 14),
            if (_showResult)
              _StandingsScoreCard(order: _order, actualRank: actualRank),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(predictionsProvider.notifier)
                          .saveStandings(widget.leagueId, _order);
                      if (context.mounted) {
                        setState(() => _showResult = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tahminin kaydedildi 👍'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Kaydet & Puanla'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReorderTeamTile extends StatelessWidget {
  const _ReorderTeamTile({
    super.key,
    required this.index,
    required this.position,
    required this.name,
    required this.showResult,
    required this.actualRank,
  });

  final int index;
  final int position;
  final String name;
  final bool showResult;
  final int? actualRank;

  @override
  Widget build(BuildContext context) {
    final diff = (actualRank == null) ? null : (actualRank! - position).abs();
    final Color resultColor = diff == null
        ? AppColors.textMuted
        : diff == 0
        ? AppColors.accentGreen
        : diff <= 2
        ? AppColors.goldColor
        : AppColors.liveRed;

    return Container(
      key: ValueKey('wrap_$name'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.cardBorder),
        color: AppColors.cardBg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$position',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TeamBadge(teamName: name, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showResult && actualRank != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                diff == 0 ? 'Tam isabet' : 'Gerçek: $actualRank',
                style: TextStyle(
                  color: resultColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_handle_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsScoreCard extends StatelessWidget {
  const _StandingsScoreCard({required this.order, required this.actualRank});

  final List<String> order;
  final Map<String, int> actualRank;

  @override
  Widget build(BuildContext context) {
    var score = 0;
    var exact = 0;
    for (var i = 0; i < order.length; i++) {
      final real = actualRank[order[i]];
      if (real == null) continue;
      final diff = (real - (i + 1)).abs();
      if (diff == 0) {
        score += 3;
        exact++;
      } else if (diff == 1) {
        score += 2;
      } else if (diff == 2) {
        score += 1;
      }
    }
    final max = order.length * 3;
    final pct = max == 0 ? 0 : (score / max * 100).round();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppGradients.greenGlow,
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.cardBg,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$score / $max puan',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$exact tam isabet · %$pct doğruluk',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ShaderMask(
              shaderCallback: (b) => AppGradients.greenGlow.createShader(b),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Oyun 2: Gol Kralı Tahmini ───────────────────────────────────────────────────

class _TopScorerGame extends ConsumerWidget {
  const _TopScorerGame({required this.leagueId});
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorersAsync = ref.watch(gamesScorersProvider);
    final predictionAsync = ref.watch(predictionsProvider);

    return scorersAsync.when(
      loading: () => const _GameLoading(),
      error: (e, _) => _GameError(message: e.toString()),
      data: (scorers) {
        if (scorers.isEmpty) {
          return const _GameInfo(message: 'Bu lig için gol verisi yok.');
        }

        final picked = predictionAsync.value?.topScorer[leagueId];
        final currentLeader = scorers.first;

        // Gol sayısı/sıra gösterilmez ve liste alfabetik dizilir ki güncel
        // lider belli olmasın — gerçek bir tahmin olsun.
        final displayScorers = [...scorers]
          ..sort(
            (a, b) => a.playerName.toLowerCase().compareTo(
              b.playerName.toLowerCase(),
            ),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GameTitleCard(
              icon: Icons.sports_soccer_rounded,
              title: 'Sezonun gol kralını tahmin et',
              subtitle:
                  'Aday oyunculardan birini seç. Gol sayıları gizli — '
                  'bilgine güven! Seçince tahminin nasıl gidiyor görürsün.',
            ),
            const SizedBox(height: 14),
            if (picked != null)
              _TopScorerResultCard(
                picked: picked,
                scorers: scorers,
                currentLeaderName: currentLeader.playerName,
              ),
            if (picked != null) const SizedBox(height: 14),
            for (final scorer in displayScorers)
              _ScorerPickTile(
                scorer: scorer,
                selected: scorer.playerName == picked,
                onTap: () => ref
                    .read(predictionsProvider.notifier)
                    .saveTopScorer(leagueId, scorer.playerName),
              ),
          ],
        );
      },
    );
  }
}

class _TopScorerResultCard extends StatelessWidget {
  const _TopScorerResultCard({
    required this.picked,
    required this.scorers,
    required this.currentLeaderName,
  });

  final String picked;
  final List<Scorer> scorers;
  final String currentLeaderName;

  @override
  Widget build(BuildContext context) {
    final pickedScorer = scorers
        .where((s) => s.playerName == picked)
        .cast<Scorer?>()
        .firstWhere((_) => true, orElse: () => null);
    final isLeading = picked == currentLeaderName;
    final rank = pickedScorer?.rank;

    final color = isLeading ? AppColors.accentGreen : AppColors.goldColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            isLeading ? Icons.verified_rounded : Icons.trending_up_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tahminin: $picked',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLeading
                      ? 'Şu an lider! 🏆'
                      : rank != null
                      ? 'Şu an $rank. sırada'
                      : 'Şu an ilk listede değil',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorerPickTile extends StatelessWidget {
  const _ScorerPickTile({
    required this.scorer,
    required this.selected,
    required this.onTap,
  });

  final Scorer scorer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.accentGreen : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
          color: selected
              ? AppColors.accentGreen.withValues(alpha: 0.08)
              : AppColors.cardBg,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            TeamBadge(teamName: scorer.teamName, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scorer.playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    scorer.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.accentGreen : AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ortak küçük parçalar ────────────────────────────────────────────────────────

class _GameTitleCard extends StatelessWidget {
  const _GameTitleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardBgRaised, AppColors.cardBg],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.header,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameLoading extends StatelessWidget {
  const _GameLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _GameError extends StatelessWidget {
  const _GameError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return _GameInfo(message: message);
  }
}

class _GameInfo extends StatelessWidget {
  const _GameInfo({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
