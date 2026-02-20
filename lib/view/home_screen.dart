import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/care_viewmodel.dart';
import 'app_theme.dart';
import 'widgets/quick_record_bar.dart';
import 'widgets/record_list.dart';
import 'widgets/summary_view.dart';
import 'widgets/today_summary_bar.dart';

/// ③ Widget 層: ホーム画面
///
/// 描画のみ。ビジネスロジックは持たない。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final int tabIndex =
        context.select<CareViewModel, int>(
      (final CareViewModel vm) => vm.selectedTabIndex,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgPink,
      appBar: AppBar(
        title: const Text(
          '🍼 おせわきろく',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              tabIndex == 0
                  ? Icons.bar_chart_rounded
                  : Icons.list_rounded,
            ),
            onPressed: () => context
                .read<CareViewModel>()
                .selectTab(tabIndex == 0 ? 1 : 0),
            tooltip: tabIndex == 0 ? 'サマリーを見る' : '一覧を見る',
          ),
        ],
      ),
      body: Column(
        children: [
          const QuickRecordBar(),
          const TodaySummaryBar(),
          const SizedBox(height: 4),
          Expanded(
            child:
                tabIndex == 0 ? const RecordList() : const SummaryView(),
          ),
        ],
      ),
    );
  }
}
