import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/care_record.dart';
import '../../model/care_type.dart';
import '../../viewmodel/care_viewmodel.dart';
import '../app_theme.dart';

/// 記録一覧（日付グループ化 + スワイプ削除）
class RecordList extends StatelessWidget {
  const RecordList({super.key});

  @override
  Widget build(final BuildContext context) {
    return Consumer<CareViewModel>(
      builder: (
        final BuildContext _,
        final CareViewModel vm,
        final Widget? __,
      ) {
        if (!vm.hasRecords) return const _EmptyState();
        return _GroupedListView(vm: vm);
      },
    );
  }
}

// ==============================================================
// ② _GroupedListView
// RecordList.build が 60 行を超えないよう切り出した Widget
// ==============================================================

class _GroupedListView extends StatelessWidget {
  const _GroupedListView({required this.vm});

  final CareViewModel vm;

  /// フラットインデックス → (_ItemKind, date?, record?) に解決する
  ///
  /// ① prefer_final_locals: アルゴリズム上 remaining だけ mutable が必要。
  ///   このメソッドに局所化することで、他の変数はすべて final を維持する。
  _ListItem _resolveItem(
    final List<DateTime> dates,
    final Map<DateTime, List<CareRecord>> grouped,
    final int index,
  ) {
    // ignore: prefer_final_locals - ループカウンタのため意図的に mutable
    int remaining = index;
    for (final DateTime date in dates) {
      if (remaining == 0) return _ListItem.header(date);
      remaining--;
      final List<CareRecord> items = grouped[date] ?? const [];
      if (remaining < items.length) return _ListItem.record(items[remaining]);
      remaining -= items.length;
    }
    return _ListItem.empty;
  }

  @override
  Widget build(final BuildContext context) {
    final Map<DateTime, List<CareRecord>> grouped = vm.groupedByDate;
    final List<DateTime> dates = grouped.keys.toList()
      ..sort((final DateTime a, final DateTime b) => b.compareTo(a));

    final int itemCount = dates.fold(
      0,
      (final int sum, final DateTime d) => sum + 1 + (grouped[d]?.length ?? 0),
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      itemBuilder: (final BuildContext _, final int index) {
        final _ListItem item = _resolveItem(dates, grouped, index);
        return switch (item.kind) {
          _ItemKind.header => _DateHeader(date: item.date!),
          _ItemKind.record => _RecordTile(
              record: item.record!,
              onDelete: () => vm.deleteRecord(item.record!.id),
            ),
          _ItemKind.empty => const SizedBox.shrink(),
        };
      },
    );
  }
}

// ==============================================================
// ① library_private_types_in_public_api 対応
//
// _ItemKind / _ListItem はこのファイル内部のみで使う private 型。
// public な Widget API（_GroupedListView のコンストラクタ等）には
// 露出させていない。
// ==============================================================

enum _ItemKind { header, record, empty }

/// ListView のフラットアイテムを表す値オブジェクト（内部専用）
final class _ListItem {
  // ① コンストラクタを先頭に
  const _ListItem._({required this.kind, this.date, this.record});

  factory _ListItem.header(final DateTime date) =>
      _ListItem._(kind: _ItemKind.header, date: date);

  factory _ListItem.record(final CareRecord record) =>
      _ListItem._(kind: _ItemKind.record, record: record);

  static const _ListItem empty = _ListItem._(kind: _ItemKind.empty);

  final _ItemKind kind;
  final DateTime? date;
  final CareRecord? record;
}

// ==============================================================
// サブ Widget
// ==============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(final BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👶', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'まだ記録がありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '上のボタンで記録してみましょう',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(final BuildContext context) {
    final DateTime now = DateTime.now();
    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final String formatted = DateFormat('M月d日 (E)', 'ja').format(date);
    final String label = isToday ? '今日 $formatted' : formatted;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.onDelete});

  final CareRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(final BuildContext context) => Dismissible(
        key: ValueKey<String>(record.id),
        direction: DismissDirection.endToStart,
        background: const _DeleteBackground(),
        onDismissed: (_) => onDelete(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              _TypeIcon(type: record.type),
              const SizedBox(width: 12),
              Expanded(child: _RecordInfo(record: record)),
              _TimeLabel(time: record.time),
            ],
          ),
        ),
      );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(final BuildContext context) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      );
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final CareType type;

  @override
  Widget build(final BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: type.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(type.emoji, style: const TextStyle(fontSize: 24)),
        ),
      );
}

class _RecordInfo extends StatelessWidget {
  const _RecordInfo({required this.record});

  final CareRecord record;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                record.type.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: record.type.color,
                  fontSize: 15,
                ),
              ),
              if (record.durationMinutes case final int mins) ...[
                const SizedBox(width: 6),
                _DurationBadge(minutes: mins, color: record.type.color),
              ],
            ],
          ),
          if (record.memo case final String memo) ...[
            const SizedBox(height: 2),
            Text(
              memo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.minutes, required this.color});

  final int minutes;
  final Color color;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            '$minutes分',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.time});

  final DateTime time;

  @override
  Widget build(final BuildContext context) => Text(
        DateFormat('HH:mm').format(time),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      );
}
