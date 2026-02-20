import 'package:flutter_test/flutter_test.dart';
import 'package:osewa_pro/model/care_record.dart';
import 'package:osewa_pro/model/care_type.dart';
import 'package:osewa_pro/model/summary_stats.dart';

void main() {
  final fixedNow = DateTime(2024, 6, 15, 12, 0, 0);

  CareRecord rec(String id, CareType type, {DateTime? time, int? mins}) =>
      CareRecord(
        id: id,
        type: type,
        time: time ?? fixedNow,
        durationMinutes: mins,
      );

  group('todayCount', () {
    test('今日の件数が種別ごとに正しく集計される', () {
      final records = [
        rec('1', CareType.feeding),
        rec('2', CareType.feeding),
        rec('3', CareType.sleep),
      ];
      final stats = SummaryStats.fromRecords(records, now: fixedNow);

      expect(stats.todayCount[CareType.feeding], 2);
      expect(stats.todayCount[CareType.sleep],   1);
      expect(stats.todayCount[CareType.diaper],  0);
    });

    test('昨日の記録は今日のカウントに含まれない', () {
      final yesterday = fixedNow.subtract(const Duration(days: 1));
      final records = [
        rec('1', CareType.feeding, time: yesterday),
        rec('2', CareType.feeding),  // 今日
      ];
      final stats = SummaryStats.fromRecords(records, now: fixedNow);

      expect(stats.todayCount[CareType.feeding], 1);
    });

    test('記録が空なら全カウントが 0', () {
      final stats = SummaryStats.fromRecords([], now: fixedNow);

      for (final t in CareType.values) {
        expect(stats.todayCount[t], 0,
            reason: '${t.label} のカウントが 0 であること');
      }
    });
  });

  group('todayTotalMinutes', () {
    test('授乳の合計時間が正しく計算される', () {
      final records = [
        rec('1', CareType.feeding, mins: 15),
        rec('2', CareType.feeding, mins: 20),
      ];
      final stats = SummaryStats.fromRecords(records, now: fixedNow);

      expect(stats.todayTotalMinutes[CareType.feeding], 35);
    });

    test('durationMinutes が null の記録は合計に含まれない', () {
      final records = [
        rec('1', CareType.feeding, mins: 10),
        rec('2', CareType.feeding),  // null
      ];
      final stats = SummaryStats.fromRecords(records, now: fixedNow);

      expect(stats.todayTotalMinutes[CareType.feeding], 10);
    });
  });

  group('sleepTotalLabel', () {
    test('90分は"1時間30分"', () {
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.sleep, mins: 90)],
        now: fixedNow,
      );
      expect(stats.sleepTotalLabel, '1時間30分');
    });

    test('45分は"45分"', () {
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.sleep, mins: 45)],
        now: fixedNow,
      );
      expect(stats.sleepTotalLabel, '45分');
    });

    test('睡眠記録がなければ"-"', () {
      final stats = SummaryStats.fromRecords([], now: fixedNow);
      expect(stats.sleepTotalLabel, '-');
    });
  });

  group('elapsedLabel (static, 時刻固定)', () {
    // factory 生成時に now を渡すことで、テスト中に時刻が変わらない

    test('null → "まだなし"', () {
      final stats = SummaryStats.fromRecords([], now: fixedNow);
      expect(stats.elapsedLabel[CareType.feeding], 'まだなし');
    });

    test('30秒前 → "たった今"', () {
      final last = fixedNow.subtract(const Duration(seconds: 30));
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.feeding, time: last)],
        now: fixedNow,
      );
      expect(stats.elapsedLabel[CareType.feeding], 'たった今');
    });

    test('45分前 → "45分前"', () {
      final last = fixedNow.subtract(const Duration(minutes: 45));
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.feeding, time: last)],
        now: fixedNow,
      );
      expect(stats.elapsedLabel[CareType.feeding], '45分前');
    });

    test('1時間30分前 → "1時間30分前"', () {
      final last = fixedNow.subtract(const Duration(hours: 1, minutes: 30));
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.sleep, time: last)],
        now: fixedNow,
      );
      expect(stats.elapsedLabel[CareType.sleep], '1時間30分前');
    });

    test('2日前 → "2日前"', () {
      final last = fixedNow.subtract(const Duration(days: 2));
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.diaper, time: last)],
        now: fixedNow,
      );
      expect(stats.elapsedLabel[CareType.diaper], '2日前');
    });
  });

  group('lastTime', () {
    test('最新の記録時刻が返る（recordsは新しい順前提）', () {
      final early = fixedNow.subtract(const Duration(hours: 3));
      final late_ = fixedNow.subtract(const Duration(hours: 1));
      final records = [
        rec('2', CareType.feeding, time: late_),   // 新しい順で先頭
        rec('1', CareType.feeding, time: early),
      ];
      final stats = SummaryStats.fromRecords(records, now: fixedNow);

      expect(stats.lastTime[CareType.feeding], late_);
    });

    test('該当種別の記録がなければ null', () {
      final stats = SummaryStats.fromRecords(
        [rec('1', CareType.diaper)],
        now: fixedNow,
      );
      expect(stats.lastTime[CareType.feeding], isNull);
    });
  });
}
