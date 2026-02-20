# おせわきろく Flutter開発セッション まとめ

## 概要

ベネッセ「まいにちのたまひよ」アプリの育児記録機能をFlutterで実装。  
ポートフォリオ用デモアプリとして、段階的にリファクタリングを重ねた。

---

## フェーズ1: 初回実装（シンプル版）

**方針**
- Flutter初心者向けに `lib/main.dart` 1ファイル完結
- 状態管理は `StatefulWidget + setState` のみ
- データ保存はメモリのみ（デモ用）

**実装機能**
- 授乳 / 睡眠 / おむつ のワンタップ記録
- ModalBottomSheet による時間・メモ入力
- 今日のカウント表示
- 左スワイプ削除（Dismissible）
- サマリービュー（合計時間・前回経過時間）

**依存パッケージ**
```
intl
```

---

## フェーズ2: MVVMリファクタリング

**指摘した問題点**
- Model / ViewModel / View が1ファイルに混在
- ビジネスロジック（集計・グルーピング）がWidget内に直書き
- `CareTypeExt` にUI依存（`Color`）が混入 → テスト不可
- `setState` がViewModel相当を兼務

**対応**

| 層 | ファイル | 役割 |
|---|---|---|
| Model | `care_type.dart` / `care_record.dart` / `summary_stats.dart` | データ構造・集計ロジック |
| ViewModel | `care_viewmodel.dart` | 状態管理・CRUD |
| View | `home_screen.dart` / `widgets/` | 描画のみ |

**主な設計判断**
- `CareType` の `Color` を View層の `AppTheme` に移動（Model汚染を防ぐ）
- `SummaryStats.fromRecords(now: testNow)` で時刻を外部注入 → テスタブル
- `records` を `List.unmodifiable()` で公開
- `Selector<CareViewModel, T>` で必要な部分だけ再描画

**依存パッケージ追加**
```
provider
```

---

## フェーズ3: 10年選手レベルへのリファクタリング

**指摘した問題点（9件）**

| # | 問題 | 深刻度 |
|---|---|---|
| 1 | `_TypeIcon` の型が `dynamic` | 🔴 致命的 |
| 2 | `deleteRecord` に未使用変数 `removed` | 🔴 警告放置 |
| 3 | `TextEditingController` の dispose 忘れ | 🔴 メモリリーク |
| 4 | `todayCount` が O(n²) | 🟡 パフォーマンス |
| 5 | `groupedByDate` が getter で毎回再生成 | 🟡 パフォーマンス |
| 6 | `elapsedLabel` getter が `DateTime.now()` を実行時呼び出し | 🟡 テスト不可 |
| 7 | `SummaryStats` フィールドが個別宣言でスケールしない | 🟡 拡張性なし |
| 8 | BottomSheet ロジックが別Widgetに混在 | 🟡 責務分離違反 |
| 9 | `enum` の `switch` 羅列 | 🟡 冗長 |

**主な修正**

```dart
// ① dynamic → CareType（型安全）
final CareType type;  // 旧: final dynamic type

// ② groupedByDate キャッシュ
Map<DateTime, List<CareRecord>>? _groupedCache;
// _records 変更時のみ再計算

// ③ enum コンストラクタで宣言的定義
enum CareType {
  feeding('授乳', '🍼'),
  sleep('睡眠', '😴'),
  diaper('おむつ', '💩');
  const CareType(this.label, this.emoji);
}

// ④ SummaryStats を Map<CareType, T> に統一
final Map<CareType, int> todayCount;  // 旧: feedingCount, sleepCount, diaperCount...
```

---

## フェーズ4: 静的解析・アーキテクチャ完成版

### ① analysis_options.yaml 新設

```yaml
analyzer:
  errors:
    unawaited_futures: error
    use_build_context_synchronously: error
    always_declare_return_types: error
linter:
  rules:
    prefer_final_locals: true
    sort_constructors_first: true
    library_private_types_in_public_api: true
```

**各ルールへの対応**

| ルール | 対応内容 |
|---|---|
| 戻り値型明示 | 全メソッド・getter に型を明示 |
| 変数をfinal | 全ローカル変数・パラメータに `final` |
| Future待機忘れ | `void _openSheet()` でラップし意図を宣言 |
| コンストラクタ先頭 | `const` コンストラクタを忘れていたクラスに追加 |
| publicAPIにprivate型禁止 | `_SummaryRow(CareType?)` の nullable 廃止 → `_TypeSummaryRow` / `_TotalSummaryRow` に分離 |
| 非同期後のBuildContext | `pop()` 前に `ScaffoldMessenger` を変数に保持 |

### ② 60行制限

全 `build()` メソッドが60行以内であることを機械的に検証済み。

| 対応箇所 | 切り出し内容 |
|---|---|
| `SummaryView` | `_SummaryListView` に移動、三重三項を `_subLabel()` に抽出 |
| `_MinutePicker` | チップ1個を `_MinuteChip` Widget に分離 |
| `RecordList` | `_GroupedListView` に移動、インデックス解決を `_resolveItem()` に抽出 |

### ③ Widget / Logic / Data の3層分離

```
lib/
├── model/          ← データ構造・集計ロジック（純粋Dart）
├── repository/     ← Data層（新設）
│   └── abstract interface CareRecordRepository
│   └── InMemoryCareRecordRepository（差し替え可能）
├── viewmodel/      ← Logic層（Repositoryの抽象に依存）
└── view/           ← UI層（ViewModelだけを知る）
```

**ViewModel から Repository に移した責務**

```dart
// 旧: ViewModel が直接持っていた
id: DateTime.now().millisecondsSinceEpoch.toString(),
time: DateTime.now(),
memo: trimmed?.isEmpty == true ? null : trimmed,

// 新: Repository.add() の中で完結
// → テスト時は StubRepository で制御できる
```

---

## テスト構成（最終版）

| ファイル | 対象 | テスト数 |
|---|---|---|
| `care_record_test.dart` | Model（copyWith・等価性・enum） | 10件 |
| `summary_stats_test.dart` | ビジネスロジック（集計・経過時間） | 13件 |
| `care_viewmodel_test.dart` | ViewModel（CRUD・キャッシュ・不変性） | 約20件 |

**テスト設計の工夫**
- `SummaryStats.fromRecords(now: fixedNow)` で時刻固定
- `_StubRepository` でViewModel単体テストの境界を明確化
- `groupedByDate` の値リストも `unmodifiable` であることを検証

---

## 最終的なファイル構成

```
osewa_pro/
├── analysis_options.yaml
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── model/
│   │   ├── care_type.dart
│   │   ├── care_record.dart
│   │   └── summary_stats.dart
│   ├── repository/
│   │   └── care_record_repository.dart
│   ├── viewmodel/
│   │   └── care_viewmodel.dart
│   └── view/
│       ├── app_theme.dart
│       ├── home_screen.dart
│       └── widgets/
│           ├── quick_record_bar.dart
│           ├── today_summary_bar.dart
│           ├── record_sheet.dart
│           ├── record_list.dart
│           └── summary_view.dart
└── test/
    ├── care_record_test.dart
    ├── summary_stats_test.dart
    └── care_viewmodel_test.dart
```

---

## 技術スタック

| 技術 | 用途 |
|---|---|
| Flutter 3.x / Dart 3.3+ | UIフレームワーク |
| provider ^6.1.2 | DI・ChangeNotifier接続 |
| intl ^0.19.0 | 日付フォーマット（日本語） |
| flutter_lints ^4.0.0 | 静的解析ベースルール |
| flutter_test | 単体テスト |
