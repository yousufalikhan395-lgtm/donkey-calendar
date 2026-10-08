import 'package:flutter/material.dart';

/// Donkey Calendar light theme — soft pastel greens, white cards,
/// deep-green ink. Fresh start, separate identity from Donkey Chat.
class AppColors {
  static const bgTop = Color(0xFFDCE9FA);
  static const bgMid = Color(0xFFDFF1E4);
  static const bgBottom = Color(0xFFF2F7F0);
  static const bg = Color(0xFFEAF3EC);

  static const surface = Colors.white;
  static const surface2 = Color(0xFFE7F2EA);
  static const text = Color(0xFF21302A);
  static const muted = Color(0xFF7C8C84);
  static const accent = Color(0xFF25935B);
  static const accentDark = Color(0xFF1E4A3A);
  static const onAccent = Colors.white;
  static const line = Color(0xFFE0E9E3);
  static const accentSoft = Color(0xFFDDF0E2);
  static const accentGlow = Color(0x6625935B);

  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMid, bgBottom],
  );

  static const cardShadow = [
    BoxShadow(color: Color(0x14304A3C), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

class CategoryStyle {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  const CategoryStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  static const academic = CategoryStyle(
    label: 'Academic', bg: Color(0xFFE3EAFB), fg: Color(0xFF3B5BBF), icon: Icons.quiz_outlined);
  static const coding = CategoryStyle(
    label: 'Coding', bg: Color(0xFFD8F0E0), fg: Color(0xFF1E7A46), icon: Icons.code_rounded);
  static const exam = CategoryStyle(
    label: 'Exam', bg: Color(0xFFFBE2D9), fg: Color(0xFFBC4A2C), icon: Icons.school_outlined);
  static const assignment = CategoryStyle(
    label: 'Assignment', bg: Color(0xFFE9E1FA), fg: Color(0xFF6848BE), icon: Icons.assignment_outlined);
  static const personal = CategoryStyle(
    label: 'Personal', bg: Color(0xFFFBEDD2), fg: Color(0xFF9A6A1D), icon: Icons.person_outline_rounded);
  static const other = CategoryStyle(
    label: 'Other', bg: Color(0xFFE7EBE9), fg: Color(0xFF5F6F67), icon: Icons.event_outlined);

  static const Map<String, CategoryStyle> all = {
    'academic': academic,
    'coding': coding,
    'exam': exam,
    'assignment': assignment,
    'personal': personal,
    'other': other,
  };

  static CategoryStyle of(String? category) =>
      all[category?.toLowerCase().trim()] ?? other;

  static String normalize(String? category) {
    final c = category?.toLowerCase().trim() ?? '';
    return all.containsKey(c) ? c : 'other';
  }

  static List<String> get names => all.keys.toList();
}

/// Uppercased, letter-spaced eyebrow label.
TextStyle eyebrowStyle(BuildContext context, {Color? color}) => TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      height: 1.4,
      fontWeight: FontWeight.w500,
      letterSpacing: 2,
      color: color ?? AppColors.muted,
    );

/// Instrument Serif italic accent.
const TextStyle serifEm = TextStyle(
  fontFamily: 'InstrumentSerif',
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w400,
  color: AppColors.accent,
);

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accentDark,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.line,
    error: Color(0xFFBC4A2C),
    onError: Colors.white,
  );

  final textTheme = const TextTheme(
    displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 30,
        height: 1.1,
        letterSpacing: -1.0,
        fontWeight: FontWeight.w700,
        color: AppColors.text),
    headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        height: 1.2,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
        color: AppColors.text),
    titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w700,
        color: AppColors.text),
    titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
        color: AppColors.text),
    bodyLarge: TextStyle(
        fontFamily: 'Inter', fontSize: 16, height: 1.55, color: AppColors.text),
    bodyMedium: TextStyle(
        fontFamily: 'Inter', fontSize: 14.5, height: 1.5, color: AppColors.text),
    bodySmall: TextStyle(
        fontFamily: 'Inter', fontSize: 13, height: 1.45, color: AppColors.muted),
    labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.text),
    labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        color: AppColors.muted),
  ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
    borderSide: BorderSide(color: AppColors.line),
  );
  const inputBorderFocused = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
    borderSide: BorderSide(color: AppColors.accent, width: 1.4),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.text, size: 22),
      titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          letterSpacing: -0.3,
          fontWeight: FontWeight.w700,
          color: AppColors.text),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.accentDark,
      contentTextStyle: textTheme.bodyMedium?.copyWith(fontSize: 14, color: Colors.white),
      actionTextColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.line),
      ),
      titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 19),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.text,
      iconColor: AppColors.muted,
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.accentSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.accentDark : AppColors.muted)),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.accentDark : AppColors.muted,
          size: 24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorderFocused,
      errorBorder: inputBorder,
      focusedErrorBorder: inputBorder,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: AppColors.accentSoft,
        disabledForegroundColor: AppColors.muted,
        textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide.none,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.muted),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.selected) ? AppColors.accent : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: AppColors.muted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.selected) ? Colors.white : AppColors.muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.accent : AppColors.line),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accentSoft,
      selectionHandleColor: AppColors.accent,
    ),
  );
}
