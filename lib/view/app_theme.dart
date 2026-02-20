import 'package:flutter/material.dart';

import '../model/care_type.dart';

/// UI 定数（Color, ThemeData）
///
/// abstract final でインスタンス化・継承を禁止。
abstract final class AppTheme {
  static const Color primaryPink = Color(0xFFE91E8C);
  static const Color bgPink = Color(0xFFFFF0F5);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPink,
          primary: primaryPink,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      );
}

/// CareType → Color（View 専用、Model 層に Color を持ち込まない）
extension CareTypeColor on CareType {
  Color get color => switch (this) {
        CareType.feeding => const Color(0xFFE91E8C),
        CareType.sleep => const Color(0xFF7C4DFF),
        CareType.diaper => const Color(0xFFFF6D00),
      };
}
