/// おせわの種類
///
/// UI依存（Color）は持たない。View層の AppTheme が担当する。
enum CareType {
  feeding('授乳', '🍼'),
  sleep('睡眠', '😴'),
  diaper('おむつ', '💩');

  // enum コンストラクタで label/emoji を宣言的に定義
  // → switch文の羅列を排除し、追加時の書き忘れをコンパイルエラーで防ぐ
  const CareType(this.label, this.emoji);

  final String label;
  final String emoji;
}
