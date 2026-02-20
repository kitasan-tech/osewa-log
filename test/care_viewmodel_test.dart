import 'package:flutter_test/flutter_test.dart';

import 'package:osewa_pro/model/care_record.dart';
import 'package:osewa_pro/model/care_type.dart';
import 'package:osewa_pro/repository/care_record_repository.dart';
import 'package:osewa_pro/viewmodel/care_viewmodel.dart';

// ==============================================================
// テスト用 Repository スタブ
//
// InMemoryCareRecordRepository そのものをテストで使えるが、
// スタブを用意することで「ViewModel だけをテストする」
// ユニットテストの境界を明確にする。
// ==============================================================
final class _StubRepository implements CareRecordRepository {
  final List<CareRecord> _store;
  _StubRepository([final List<CareRecord>? initial])
      : _store = initial ?? [];

  @override
  List<CareRecord> getAll() => List<CareRecord>.unmodifiable(_store);

  @override
  List<CareRecord> add({
    required final CareType type,
    final int? durationMinutes,
    final String? memo,
  }) {
    final String? trimmed = memo?.trim();
    _store.insert(
      0,
      CareRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        time: DateTime.now(),
        durationMinutes: durationMinutes,
        memo: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      ),
    );
    return List<CareRecord>.unmodifiable(_store);
  }

  @override
  List<CareRecord> delete(final String id) {
    _store.removeWhere((final CareRecord r) => r.id == id);
    return List<CareRecord>.unmodifiable(_store);
  }
}

// テスト用レコード生成ヘルパー
CareRecord _rec(
  final String id,
  final CareType type, {
  final DateTime? time,
  final int? durationMinutes,
}) =>
    CareRecord(
      id: id,
      type: type,
      time: time ?? DateTime.now(),
      durationMinutes: durationMinutes,
    );

void main() {
  late CareViewModel vm;
  late _StubRepository repo;

  setUp(() {
    repo = _StubRepository();
    vm = CareViewModel(repo);
  });

  // ============================================================
  group('初期状態', () {
    test('records が空', () {
      expect(vm.records, isEmpty);
      expect(vm.hasRecords, isFalse);
    });

    test('selectedTabIndex == 0', () {
      expect(vm.selectedTabIndex, 0);
    });

    test('groupedByDate が空', () {
      expect(vm.groupedByDate, isEmpty);
    });
  });

  // ============================================================
  group('addRecord', () {
    test('記録が追加される', () {
      vm.addRecord(type: CareType.feeding);

      expect(vm.records.length, 1);
      expect(vm.records.first.type, CareType.feeding);
    });

    test('新しい記録が先頭になる', () {
      vm.addRecord(type: CareType.feeding);
      vm.addRecord(type: CareType.diaper);

      expect(vm.records.first.type, CareType.diaper);
      expect(vm.records.last.type, CareType.feeding);
    });

    test('durationMinutes が保存される', () {
      vm.addRecord(type: CareType.sleep, durationMinutes: 30);

      expect(vm.records.first.durationMinutes, 30);
    });

    test('空白のみの memo は null になる', () {
      vm.addRecord(type: CareType.diaper, memo: '   ');

      expect(vm.records.first.memo, isNull);
    });

    test('memo の前後スペースがトリムされる', () {
      vm.addRecord(type: CareType.feeding, memo: '  たくさん  ');

      expect(vm.records.first.memo, 'たくさん');
    });

    test('addRecord で notifyListeners が呼ばれる', () {
      int count = 0;
      vm.addListener(() => count++);

      vm.addRecord(type: CareType.feeding);

      expect(count, 1);
    });

    test('追加後に groupedByDate キャッシュが更新される', () {
      final Map<DateTime, List<CareRecord>> before = vm.groupedByDate;
      vm.addRecord(type: CareType.feeding);
      final Map<DateTime, List<CareRecord>> after = vm.groupedByDate;

      expect(before, isEmpty);
      expect(after, isNotEmpty);
    });
  });

  // ============================================================
  group('deleteRecord', () {
    test('指定 ID の記録が削除される', () {
      vm.addRecord(type: CareType.feeding);
      final String id = vm.records.first.id;

      vm.deleteRecord(id);

      expect(vm.records, isEmpty);
    });

    test('存在しない ID を指定しても例外が出ない', () {
      vm.addRecord(type: CareType.feeding);

      expect(() => vm.deleteRecord('no-such-id'), returnsNormally);
      expect(vm.records.length, 1);
    });

    test('複数件のうち 1 件だけ削除される', () {
      vm.addRecord(type: CareType.feeding);
      vm.addRecord(type: CareType.sleep);
      vm.addRecord(type: CareType.diaper);
      final String targetId = vm.records[1].id;

      vm.deleteRecord(targetId);

      expect(vm.records.length, 2);
      expect(vm.records.any((final CareRecord r) => r.id == targetId), isFalse);
    });

    test('delete で notifyListeners が呼ばれる', () {
      vm.addRecord(type: CareType.feeding);
      final String id = vm.records.first.id;
      int count = 0;
      vm.addListener(() => count++);

      vm.deleteRecord(id);

      expect(count, 1);
    });
  });

  // ============================================================
  group('selectTab', () {
    test('タブが切り替わる', () {
      vm.selectTab(1);
      expect(vm.selectedTabIndex, 1);
    });

    test('同じタブを再選択しても notify されない', () {
      int count = 0;
      vm.addListener(() => count++);

      vm.selectTab(0);

      expect(count, 0);
    });

    test('別タブに切り替えると notify される', () {
      int count = 0;
      vm.addListener(() => count++);

      vm.selectTab(1);

      expect(count, 1);
    });
  });

  // ============================================================
  group('groupedByDate', () {
    test('同じ getter を 2 回呼んでも同一オブジェクト（キャッシュ）', () {
      vm.addRecord(type: CareType.feeding);
      final Map<DateTime, List<CareRecord>> first = vm.groupedByDate;
      final Map<DateTime, List<CareRecord>> second = vm.groupedByDate;

      expect(identical(first, second), isTrue);
    });

    test('削除後にキャッシュが無効化される', () {
      vm.addRecord(type: CareType.feeding);
      final Map<DateTime, List<CareRecord>> before = vm.groupedByDate;

      vm.deleteRecord(vm.records.first.id);
      final Map<DateTime, List<CareRecord>> after = vm.groupedByDate;

      expect(identical(before, after), isFalse);
      expect(after, isEmpty);
    });

    test('異なる日付の記録が別グループになる', () {
      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final _StubRepository testRepo = _StubRepository([
        _rec('y1', CareType.feeding, time: yesterday),
        _rec('t1', CareType.sleep),
      ]);
      final CareViewModel testVm = CareViewModel.forTest(testRepo);
      testVm.addRecord(type: CareType.feeding); // 今日

      // Repository に直接入れた昨日分 + addRecord の今日分 = 2グループ
      // ※ スタブの _store に直接入れた記録は ViewModel には反映されないので
      //   forTest で初期化済みの repository を使う別パターン
      final _StubRepository initRepo = _StubRepository([
        _rec('y1', CareType.feeding, time: yesterday),
      ]);
      final CareViewModel vmWithYesterday = CareViewModel.forTest(initRepo);
      vmWithYesterday.addRecord(type: CareType.sleep); // 今日

      expect(vmWithYesterday.groupedByDate.length, 2);
    });
  });

  // ============================================================
  group('不変性', () {
    test('records は外部から変更できない', () {
      vm.addRecord(type: CareType.feeding);
      final List<CareRecord> external = vm.records;

      expect(
        () => (external as dynamic).add(null),
        throwsUnsupportedError,
      );
    });

    test('groupedByDate の値リストも外部から変更できない', () {
      vm.addRecord(type: CareType.feeding);
      final Map<DateTime, List<CareRecord>> grouped = vm.groupedByDate;
      final List<CareRecord> items = grouped.values.first;

      expect(
        () => (items as dynamic).add(null),
        throwsUnsupportedError,
      );
    });
  });
}
