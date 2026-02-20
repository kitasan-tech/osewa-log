import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/care_type.dart';
import '../../viewmodel/care_viewmodel.dart';
import '../app_theme.dart';

/// 今日の種別ごとカウントを横並び表示するバー
class TodaySummaryBar extends StatelessWidget {
  const TodaySummaryBar({super.key});

  @override
  Widget build(final BuildContext context) {
    return Selector<CareViewModel, Map<CareType, int>>(
      selector: (
        final BuildContext _,
        final CareViewModel vm,
      ) =>
          {
            for (final CareType t in CareType.values) t: vm.todayCount(t),
          },
      builder: (
        final BuildContext _,
        final Map<CareType, int> counts,
        final Widget? __,
      ) =>
          Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const _TodayLabel(),
            for (final (int index, CareType type)
                in CareType.values.indexed) ...[
              if (index > 0) const _VerticalDivider(),
              _CountCell(type: type, count: counts[type] ?? 0),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayLabel extends StatelessWidget {
  const _TodayLabel();

  @override
  Widget build(final BuildContext context) => const Expanded(
        child: Column(
          children: [
            Text('今日', style: TextStyle(fontSize: 11, color: Colors.grey)),
            SizedBox(height: 2),
            Text(
              'TODAY',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}

class _CountCell extends StatelessWidget {
  const _CountCell({required this.type, required this.count});

  final CareType type;
  final int count;

  @override
  Widget build(final BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              '$count回',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: count > 0 ? type.color : Colors.grey[400],
              ),
            ),
            Text(
              type.label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(final BuildContext context) =>
      Container(width: 1, height: 40, color: Colors.grey[200]);
}
