import 'package:flutter/foundation.dart';

import '../model/care_record.dart';
import '../model/care_type.dart';
import '../model/summary_stats.dart';
import '../repository/care_record_repository.dart';

// ==============================================================
// ③ Logic 層: ViewModel
//
// 責務：
//   - UI 状態（selectedTabIndex）の管理
//   - Repository 経由での CRUD 実行
//   - View が必要な加工済みデータの提供（groupedByDate, summaryStats）
//
// 持たない責務（Repository に委譲）：
//   - DateTime.now() / ID 生成
//   - memo のトリム処理
// ==============================================================

class CareViewModel extends ChangeNotifier {
  // ① コンストラクタをクラスの先頭に配置（sort_constructors_first）
  CareViewModel(this._repository);

  /// テスト用ファクトリ
  ///
  /// Repository を差し替えることでテストデータを注入する。
  /// @visibleForTesting により本番コードからの誤用を防ぐ。
  @visibleForTesting
  factory CareViewModel.forTest(final CareRecordRepository repository) =>
      CareViewModel(repository);

  final CareRecordRepository _repository;

  // ① List は final で宣言し、Repository から受け取るたびに再代入
  List<CareRecord> _records = [];
  int _selectedTabIndex = 0;

  // groupedByDate のキャッシュ（_records 変更時のみ再計算）
  Map<DateTime, List<CareRecord>>? _groupedCache;

  // ---------- 公開プロパティ ----------

  List<CareRecord> get records => _records;
  int get selectedTabIndex => _selectedTabIndex;
  bool get hasRecords => _records.isNotEmpty;

  SummaryStats get summaryStats =>
      SummaryStats.fromRecords(_records, now: DateTime.now());

  /// 今日の種別カウント（O(1)）
  int todayCount(final CareType type) =>
      summaryStats.todayCount[type] ?? 0;

  /// 日付グループ Map（キャッシュ付き）
  ///
  /// 値リストも unmodifiable にして外部変更を完全に防ぐ。
  Map<DateTime, List<CareRecord>> get groupedByDate {
    if (_groupedCache != null) return _groupedCache!;

    final Map<DateTime, List<CareRecord>> mutable = {};
    for (final CareRecord r in _records) {
      final DateTime key =
          DateTime(r.time.year, r.time.month, r.time.day);
      (mutable[key] ??= []).add(r);
    }

    // ① 型を明示（型推論に頼らない）
    final Map<DateTime, List<CareRecord>> immutable = {
      for (final MapEntry<DateTime, List<CareRecord>> e in mutable.entries)
        e.key: List<CareRecord>.unmodifiable(e.value),
    };
    return _groupedCache =
        Map<DateTime, List<CareRecord>>.unmodifiable(immutable);
  }

  // ---------- コマンド ----------

  void addRecord({
    required final CareType type,
    final int? durationMinutes,
    final String? memo,
  }) {
    _records = _repository.add(
      type: type,
      durationMinutes: durationMinutes,
      memo: memo,
    );
    _invalidateCache();
    notifyListeners();
  }

  void deleteRecord(final String id) {
    _records = _repository.delete(id);
    _invalidateCache();
    notifyListeners();
  }

  void selectTab(final int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    notifyListeners();
  }

  // ---------- private ----------

  void _invalidateCache() => _groupedCache = null;
}
