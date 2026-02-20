import 'package:flutter_test/flutter_test.dart';
import 'package:osewa_pro/model/care_record.dart';
import 'package:osewa_pro/model/care_type.dart';

void main() {
  group('CareRecord', () {
    final base = CareRecord(
      id: 'test-001',
      type: CareType.feeding,
      time: DateTime(2024, 6, 15, 8, 0),
      durationMinutes: 15,
      memo: 'よく飲んだ',
    );

    test('copyWith で一部フィールドだけ変更できる', () {
      final updated = base.copyWith(durationMinutes: 20);

      expect(updated.id,              base.id);
      expect(updated.type,            base.type);
      expect(updated.durationMinutes, 20);
      expect(updated.memo,            base.memo);
    });

    test('copyWith に何も渡さなければ元の値が保たれる', () {
      final copy = base.copyWith();

      expect(copy.id,              base.id);
      expect(copy.durationMinutes, base.durationMinutes);
      expect(copy.memo,            base.memo);
    });

    test('同じ id は等価', () {
      final a = CareRecord(id: 'x', type: CareType.sleep,   time: DateTime.now());
      final b = CareRecord(id: 'x', type: CareType.diaper,  time: DateTime.now());

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('異なる id は非等価', () {
      final a = CareRecord(id: 'a', type: CareType.feeding, time: DateTime.now());
      final b = CareRecord(id: 'b', type: CareType.feeding, time: DateTime.now());

      expect(a, isNot(equals(b)));
    });

    test('toString に id と type が含まれる', () {
      final s = base.toString();
      expect(s, contains('test-001'));
      expect(s, contains('feeding'));
    });
  });

  group('CareType enum コンストラクタ', () {
    // enum コンストラクタで宣言した値が正しいことを確認
    test('label が正しい', () {
      expect(CareType.feeding.label, '授乳');
      expect(CareType.sleep.label,   '睡眠');
      expect(CareType.diaper.label,  'おむつ');
    });

    test('emoji が正しい', () {
      expect(CareType.feeding.emoji, '🍼');
      expect(CareType.sleep.emoji,   '😴');
      expect(CareType.diaper.emoji,  '💩');
    });

    test('values の順序が変わっていない', () {
      expect(CareType.values, [
        CareType.feeding,
        CareType.sleep,
        CareType.diaper,
      ]);
    });
  });
}
