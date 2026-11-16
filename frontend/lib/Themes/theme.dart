import 'package:material_ui/material_ui.dart';


ThemeData buildAlbumTheme() {
  const squareBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
    side: BorderSide(color: Colors.white, width: 2),
  );


  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.white, width: 2),
  );


  final dayForeground = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.selected) ? Colors.black : Colors.white,
  );

  final dayBackground = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.transparent,
  );


  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Omori',
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,  
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      shape: squareBorder,
      elevation: 0
    ),


    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: squareBorder,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        shape: squareBorder
      ),
    ),


    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black,
      labelStyle: TextStyle(color: Colors.white),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.white, width: 3),
      ),
    ),


    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: squareBorder,
      headerBackgroundColor: Colors.black,
      headerForegroundColor: Colors.white,
      dividerColor: Colors.white,
      dayForegroundColor: dayForeground,
      dayBackgroundColor: dayBackground,
      todayForegroundColor: dayForeground,
      todayBackgroundColor: dayBackground,
      todayBorder: const BorderSide(color: Colors.white),
      yearForegroundColor: dayForeground,
      yearBackgroundColor: dayBackground,
      dayShape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
    ),

  
  );
  
}