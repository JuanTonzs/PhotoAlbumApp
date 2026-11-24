import 'package:frontend/MenuScreen.dart';
import 'package:frontend/Themes/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp( {super.key} );


  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuScreen(), //Untick this after
      // home: VinylHomeWidget(),
      theme: buildAlbumTheme(),
    );
  }
}
