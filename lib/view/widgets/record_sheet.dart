import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/care_type.dart';
import '../../viewmodel/care_viewmodel.dart';
import '../app_theme.dart';

// ==============================================================
// ③ Widget 層: RecordSheet
//
// ① Linter 対応：
//   - static show() の戻り値型を Future<void> で明示
//   - _submit() は同期処理のみ。Navigator.pop() 後の
//     ScaffoldMessenger 参照を「pop前に保持」して
//     use_build_context_synchronously を回避
//   - TextEditingController を StatefulWidget で管理・dispose
//   - 全パラメータ・変数に型を明示
//
// ② build() が 60 行を超えないよう private Widget に分割
// ==============================================================

class RecordSheet extends StatefulWidget {
  // ① コンストラクタを先頭に
  const RecordSheet({super.key, required this.type});

  final CareType type;

  /// BottomSheet を開く静的ラッパー
  ///
  /// 呼び出し元で `unawaited_futures` が起きないよう
  /// 戻り値型 Future<void> を明示する。
  /// 呼び出し元では `unawaited(RecordSheet.show(...))` または
  /// void コールバック内から呼ぶこと。
  static Future<void> show(
    final BuildContext context,
    final CareType type,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RecordSheet(type: type),
      );

  @override
  State<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<RecordSheet> {
  // ① late final で初期化遅延 + 再代入不可
  late final TextEditingController _memoCtrl;
  int? _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _memoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  /// 記録を保存してシートを閉じる（同期処理のみ）
  ///
  /// ① use_build_context_synchronously 対応：
  ///   Navigator.pop() の前に ScaffoldMessenger を変数に保持する。
  ///   こうすることで pop 後も messenger への参照が有効なまま使える。
  void _submit() {
    // pop 前に messenger を保持（context の有効性を維持）
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);
    final CareType type = widget.type;

    context.read<CareViewModel>().addRecord(
          type: type,
          durationMinutes: _selectedMinutes,
          memo: _memoCtrl.text,
        );

    Navigator.of(context).pop();

    // pop 後でも保持済み messenger は安全に使える
    messenger.showSnackBar(
      SnackBar(
        content: Text('${type.emoji} ${type.label}を記録しました'),
        backgroundColor: type.color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ② build() を 60 行以内に収めるため子 Widget に委譲
  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetTitle(type: widget.type),
              const SizedBox(height: 24),
              if (widget.type != CareType.diaper) ...[
                _MinutePicker(
                  type: widget.type,
                  selected: _selectedMinutes,
                  onChanged: (final int? m) =>
                      setState(() => _selectedMinutes = m),
                ),
                const SizedBox(height: 16),
              ],
              _MemoField(
                controller: _memoCtrl,
                accentColor: widget.type.color,
              ),
              const SizedBox(height: 24),
              _SubmitButton(type: widget.type, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// サブ Widget（各 build が 60 行未満になるよう分割）
// ==============================================================

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.type});

  final CareType type;

  @override
  Widget build(final BuildContext context) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              '${type.label}を記録',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: type.color,
              ),
            ),
          ],
        ),
      );
}

class _MinutePicker extends StatelessWidget {
  const _MinutePicker({
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  final CareType type;
  final int? selected;
  final ValueChanged<int?> onChanged;

  static const List<int> _options = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('時間（分）'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            // ② Wrap 内のアイテム生成を _MinuteChip に切り出し（ネスト削減）
            children: _options
                .map(
                  (final int min) => _MinuteChip(
                    minutes: min,
                    isSelected: selected == min,
                    color: type.color,
                    onTap: () => onChanged(selected == min ? null : min),
                  ),
                )
                .toList(),
          ),
        ],
      );
}

/// ② _MinutePicker から切り出した個別チップ Widget
class _MinuteChip extends StatelessWidget {
  const _MinuteChip({
    required this.minutes,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$minutes分',
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
}

class _MemoField extends StatelessWidget {
  const _MemoField({
    required this.controller,
    required this.accentColor,
  });

  final TextEditingController controller;
  final Color accentColor;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('メモ（任意）'),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '気になったことなど...',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.type,
    required this.onPressed,
  });

  final CareType type;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: type.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '記録する',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 13,
        ),
      );
}
