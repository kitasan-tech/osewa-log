import 'care_type.dart';

/// 1件のおせわ記録（イミュータブル値オブジェクト）
final class CareRecord {
  final String id;
  final CareType type;
  final DateTime time;
  final int? durationMinutes;
  final String? memo;

  const CareRecord({
    required this.id,
    required this.type,
    required this.time,
    this.durationMinutes,
    this.memo,
  });

  CareRecord copyWith({
    String? id,
    CareType? type,
    DateTime? time,
    int? durationMinutes,
    String? memo,
  }) =>
      CareRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        time: time ?? this.time,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        memo: memo ?? this.memo,
      );

  @override
  bool operator ==(Object other) => other is CareRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CareRecord(id: $id, type: $type, time: $time, '
      'durationMinutes: $durationMinutes, memo: $memo)';
}