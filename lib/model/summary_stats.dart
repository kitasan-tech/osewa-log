import 'care_record.dart';
import 'care_type.dart';

/// 集計結果（イミュータブル値オブジェクト）
///
/// factory生成時に now を受け取ることで、
/// テスト時に時刻を完全固定できる設計を維持する。
final class SummaryStats {
  // ① コンストラクタをクラスの先頭に配置（sort_constructors_first）
  const SummaryStats._({
    required this.todayCount,
    required this.todayTotalMinutes,
    required this.lastTime,
    required this.elapsedLabel,
  });

  factory SummaryStats.fromRecords(
    final List<CareRecord> records, {
    required final DateTime now,
  }) {
    // ① final + 型を明示（型推論に頼らない）
    final List<CareRecord> today = records
        .where((final CareRecord r) => _isSameDay(r.time, now))
        .toList();

    final Map<CareType, int> counts = Map<CareType, int>.fromEntries(
      CareType.values.map((final CareType t) => MapEntry<CareType, int>(
            t,
            today.where((final CareRecord r) => r.type == t).length,
          )),
    );

    final Map<CareType, int> totalMins = Map<CareType, int>.fromEntries(
      CareType.values.map((final CareType t) {
        final int mins = today
            .where(
              (final CareRecord r) =>
                  r.type == t && r.durationMinutes != null,
            )
            .fold(
              0,
              (final int sum, final CareRecord r) =>
                  sum + r.durationMinutes!,
            );
        return MapEntry<CareType, int>(t, mins);
      }),
    );

    final Map<CareType, DateTime?> last =
        Map<CareType, DateTime?>.fromEntries(
      CareType.values.map((final CareType t) {
        final Iterable<CareRecord> hits =
            records.where((final CareRecord r) => r.type == t);
        return MapEntry<CareType, DateTime?>(
            t, hits.isEmpty ? null : hits.first.time);
      }),
    );

    final Map<CareType, String> elapsed =
        Map<CareType, String>.fromEntries(
      CareType.values.map(
        (final CareType t) =>
            MapEntry<CareType, String>(t, _elapsedLabel(last[t], now)),
      ),
    );

    return SummaryStats._(
      todayCount: counts,
      todayTotalMinutes: totalMins,
      lastTime: last,
      elapsedLabel: elapsed,
    );
  }

  final Map<CareType, int> todayCount;
  final Map<CareType, int> todayTotalMinutes;
  final Map<CareType, DateTime?> lastTime;
  final Map<CareType, String> elapsedLabel;

  // ① 戻り値型を明示
  static bool _isSameDay(final DateTime a, final DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _elapsedLabel(
    final DateTime? last,
    final DateTime now,
  ) {
    if (last == null) return 'まだなし';
    final Duration diff = now.difference(last);
    if (diff.inSeconds < 60) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) {
      return '${diff.inHours}時間${diff.inMinutes % 60}分前';
    }
    return '${diff.inDays}日前';
  }

  String get sleepTotalLabel {
    final int mins = todayTotalMinutes[CareType.sleep] ?? 0;
    if (mins == 0) return '-';
    final int h = mins ~/ 60;
    final int m = mins % 60;
    return h > 0 ? '$h時間$m分' : '$m分';
  }
}
