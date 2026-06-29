import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class MatchesDateStrip extends StatelessWidget {
  const MatchesDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onCalendarPressed,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onCalendarPressed;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);

    final items = [
      (label: 'Dün', sub: _weekday(base.subtract(const Duration(days: 1)).weekday), date: base.subtract(const Duration(days: 1))),
      (label: 'Bugün', sub: _dayNum(base), date: base),
      (label: 'Yarın', sub: _weekday(base.add(const Duration(days: 1)).weekday), date: base.add(const Duration(days: 1))),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _DatePill(
              label: items[i].label,
              sub: items[i].sub,
              selected: _isSameDay(items[i].date, selectedDate),
              onTap: () => onDateSelected(items[i].date),
            ),
          ),
          const SizedBox(width: 8),
        ],
        _CalendarPill(onTap: onCalendarPressed),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekday(int wd) {
    return switch (wd) {
      1 => 'Pzt',
      2 => 'Sal',
      3 => 'Çar',
      4 => 'Per',
      5 => 'Cum',
      6 => 'Cmt',
      _ => 'Paz',
    };
  }

  String _dayNum(DateTime d) => '${d.day}/${d.month}';
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ac.headerGradientStart, ac.headerGradientEnd],
                )
              : null,
          color: selected ? null : ac.unselectedPill,
          border: Border.all(
            color: selected
                ? ac.headerGradientStart.withValues(alpha: 0.0)
                : ac.cardBorder,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.4 : 0.25),
                    blurRadius: 14,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: selected ? Colors.white : ac.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.75)
                    : ac.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              child: Text(sub),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarPill extends StatelessWidget {
  const _CalendarPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: ac.unselectedPill,
          border: Border.all(color: ac.cardBorder),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          color: primary,
          size: 20,
        ),
      ),
    );
  }
}
