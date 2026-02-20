import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'repository/care_record_repository.dart';
import 'view/app_theme.dart';
import 'view/home_screen.dart';
import 'viewmodel/care_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(const OsewaApp());
}

class OsewaApp extends StatelessWidget {
  const OsewaApp({super.key});

  @override
  Widget build(final BuildContext context) {
    // ③ DI: Data → Logic の順で依存を組み立てる
    //   Widget 層は ViewModel だけ知っていれば十分で
    //   Repository の存在を意識しなくてよい
    return ChangeNotifierProvider<CareViewModel>(
      create: (_) => CareViewModel(InMemoryCareRecordRepository()),
      child: MaterialApp(
        title: 'おせわきろく',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
