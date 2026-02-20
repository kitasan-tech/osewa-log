import '../model/care_record.dart';
import '../model/care_type.dart';

// ==============================================================
// ③ Data 層: Repository
//
// ViewModel は「この抽象インタフェース」にだけ依存する。
// 実装（InMemory / SharedPreferences / Firestore）は差し替え可能。
//
// CareViewModel が直接持っていた責務をここに移動：
//   - DateTime.now() による現在時刻の取得
//   - millisecondsSinceEpoch による ID 生成
//   - memo のトリム処理（データ整合性 = Data層の責務）
// ==============================================================

/// おせわ記録の CRUD を定義するリポジトリインタフェース
abstract interface class CareRecordRepository {
  // ① コンストラクタ相当の位置に配置（interface なので factory を先頭に）

  /// 全記録を新しい順で返す（不変リスト）
  List<CareRecord> getAll();

  /// 記録を追加し、追加後の不変リストを返す
  List<CareRecord> add({
    required CareType type,
    int? durationMinutes,
    String? memo,
  });

  /// 指定 id の記録を削除し、削除後の不変リストを返す
  List<CareRecord> delete(final String id);
}

// ==============================================================
// InMemory 実装（デモ・テスト用）
// ==============================================================

/// インメモリ実装（アプリ終了でデータが消えるデモ用）
final class InMemoryCareRecordRepository implements CareRecordRepository {
  // ① コンストラクタを先頭に配置
  InMemoryCareRecordRepository();

  final List<CareRecord> _store = [];

  @override
  List<CareRecord> getAll() => List<CareRecord>.unmodifiable(_store);

  @override
  List<CareRecord> add({
    required final CareType type,
    final int? durationMinutes,
    final String? memo,
  }) {
    // ID生成・現在時刻・memo整形はここで完結（ViewModel に漏らさない）
    final String? trimmed = memo?.trim();
    final CareRecord record = CareRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      time: DateTime.now(),
      durationMinutes: durationMinutes,
      memo: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _store.insert(0, record);
    return List<CareRecord>.unmodifiable(_store);
  }

  @override
  List<CareRecord> delete(final String id) {
    _store.removeWhere((final CareRecord r) => r.id == id);
    return List<CareRecord>.unmodifiable(_store);
  }
}
