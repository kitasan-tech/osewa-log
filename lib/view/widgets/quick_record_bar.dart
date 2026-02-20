import 'package:flutter/material.dart';

import '../../model/care_type.dart';
import '../app_theme.dart';
import 'record_sheet.dart';

// ==============================================================
// ③ Widget 層: QuickRecordBar
//
// ① unawaited_futures 対応：
//   GestureDetector.onTap は VoidCallback（void を要求する）。
//   RecordSheet.show() は Future<void> を返すため、
//   void 関数でラップして「待機しないことを意図的に宣言」する。
// ==============================================================

class QuickRecordBar extends StatelessWidget {
  const QuickRecordBar({super.key});

  @override
  Widget build(final BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            for (final (int index, CareType type)
                in CareType.values.indexed) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  type: type,
                  // void 関数でラップ → unawaited_futures を明示的に回避
                  onTap: () => _openSheet(context, type),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// BottomSheet を開く（結果を待つ必要がないため void で宣言）
  ///
  /// Future<void> を onTap に直接渡すと `unawaited_futures` が発生する。
  /// この void メソッドでラップすることで、
  /// 「待機しないことが意図的である」ことをコードで表現する。
  void _openSheet(final BuildContext context, final CareType type) {
    // ignore: discarded_futures - 意図的に await しない
    RecordSheet.show(context, type);
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.type,
    required this.onTap,
  });

  final CareType type;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: type.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: type.color.withOpacity(0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(
                  type.label,
                  style: TextStyle(
                    color: type.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
