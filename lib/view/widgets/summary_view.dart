import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/care_record.dart';
import '../../model/care_type.dart';
import '../../model/summary_stats.dart';
import '../../viewmodel/care_viewmodel.dart';
import '../app_theme.dart';

// ==============================================================
// ③ Widget 層: SummaryView
//
// ① Linter 対応：
//   - _TechBadgeCard に const コンストラクタを追加（sort_constructors_first）
//   - _SummaryRow の CareType? nullable 設計を廃止
//     → CareType 用と "合計行" 用の 2 クラスに分離
//     （public API に曖昧な nullable を持たせない）
//
// ② 60行対応：
//   - SummaryView.build の Consumer 内で三重三項演算子になっていた
//     sub ラベル計算を _subLabel() private メソッドに切り出し
// ==============================================================

class SummaryView extends StatelessWidget {
  const SummaryView({super.key});

  @override
  Widget build(final BuildContext context) {
    return Consumer<CareViewModel>(
      builder: (
        final BuildContext _,
        final CareViewModel vm,
        final Widget? __,
      ) {
        if (!vm.hasRecords) return const _NoRecordsMessage();
        return _SummaryListView(vm: vm);
      },
    );
  }
}

// ② 60行を超えるため切り出し
class _SummaryListView extends StatelessWidget {
  const _SummaryListView({required this.vm});

  final CareViewModel vm;

  /// 今日のまとめカードの sub ラベルを返す
  ///
  /// ② 三重三項をメソッドに切り出してネストを排除
  String? _subLabel(final CareType t, final SummaryStats stats) {
    final int mins = stats.todayTotalMinutes[t] ?? 0;
    if (mins == 0) return null;
    return switch (t) {
      CareType.sleep => stats.sleepTotalLabel,
      CareType.feeding => '合計 ${mins}分',
      CareType.diaper => null,
    };
  }

  @override
  Widget build(final BuildContext context) {
    final SummaryStats stats = vm.summaryStats;
    final int total = vm.records.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(
          title: '今日のまとめ',
          icon: Icons.today,
          rows: CareType.values
              .map(
                (final CareType t) => _TypeSummaryRow(
                  type: t,
                  value: '${stats.todayCount[t] ?? 0}回',
                  sub: _subLabel(t, stats),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: '前回からの経過時間',
          icon: Icons.timer_outlined,
          rows: CareType.values
              .map(
                (final CareType t) => _TypeSummaryRow(
                  type: t,
                  value: stats.elapsedLabel[t] ?? 'まだなし',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: '総記録数',
          icon: Icons.history,
          rows: [
            ...CareType.values.map(
              (final CareType t) => _TypeSummaryRow(
                type: t,
                value:
                    '${vm.records.where((final CareRecord r) => r.type == t).length}回',
              ),
            ),
            // ① _SummaryRow から専用クラスに分離（nullable 廃止）
            _TotalSummaryRow(value: '$total回'),
          ],
        ),
        const SizedBox(height: 12),
        const _TechBadgeCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _NoRecordsMessage extends StatelessWidget {
  const _NoRecordsMessage();

  @override
  Widget build(final BuildContext context) => const Center(
        child: Text(
          '記録がまだありません',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<Widget> rows;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(title: title, icon: icon),
              const Divider(height: 16),
              ...rows,
            ],
          ),
        ),
      );
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Icon(icon, color: AppTheme.primaryPink, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPink,
              fontSize: 13,
            ),
          ),
        ],
      );
}

/// ① CareType 行専用（nullable を持たない型安全な設計）
class _TypeSummaryRow extends StatelessWidget {
  const _TypeSummaryRow({
    required this.type,
    required this.value,
    this.sub,
  });

  final CareType type;
  final String value;
  final String? sub;

  @override
  Widget build(final BuildContext context) => _SummaryRowLayout(
        emoji: type.emoji,
        label: type.label,
        value: value,
        valueColor: type.color,
        sub: sub,
      );
}

/// ① 合計行専用（CareType に依存しない）
class _TotalSummaryRow extends StatelessWidget {
  const _TotalSummaryRow({required this.value});

  final String value;

  @override
  Widget build(final BuildContext context) => _SummaryRowLayout(
        emoji: '📊',
        label: '合計',
        value: value,
        valueColor: Colors.grey,
      );
}

/// 行レイアウトの共通 Widget（_TypeSummaryRow / _TotalSummaryRow が使う）
class _SummaryRowLayout extends StatelessWidget {
  const _SummaryRowLayout({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
    this.sub,
  });

  final String emoji;
  final String label;
  final String value;
  final Color valueColor;
  final String? sub;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _TechBadgeCard extends StatelessWidget {
  // ① コンストラクタを先頭に（sort_constructors_first）
  const _TechBadgeCard();

  @override
  Widget build(final BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF9C27B0).withOpacity(0.2),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.code, color: Color(0xFF9C27B0), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'ポートフォリオ用デモ',
                    style: TextStyle(
                      color: Color(0xFF9C27B0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Flutter / Dart\n'
                '• MVVM + Repository パターン\n'
                '• analysis_options.yaml による静的解析\n'
                '• prefer_final_locals / always_declare_return_types\n'
                '• unawaited_futures / use_build_context_synchronously\n'
                '• sort_constructors_first / library_private_types_in_public_api',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF555555),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
}
