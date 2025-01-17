import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:modern_art_app/data/database.dart';
import 'package:modern_art_app/lang/localization.dart';
import 'package:modern_art_app/ui/pages/main_page.dart';
import 'package:provider/provider.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // get back camera
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error ${e.code}\nError msg: ${e.description}');
  }
  // init settings
  await Settings.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();
    return MultiProvider(
      providers: [
        Provider(create: (_) => db.artistsDao),
        Provider(create: (_) => db.artworksDao),
        Provider(create: (_) => db.viewingsDao),
        Provider(create: (_) => db),
      ],
      child: MaterialApp(
        // can specify app locale here explicitly
        // locale: AppLocalizations.languages.keys.first,
        localizationsDelegates: const [
          // Custom localization delegate, gen. by flutter_sheet_localization lib
          AppLocalizationsDelegate(),
          // Built-in localization of basic text for Material widgets
          GlobalMaterialLocalizations.delegate,
          // Built-in localization for text direction LTR/RTL
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: localizedLabels.keys.toList(),
        localeResolutionCallback: (locale, supportedLocales) {
          /// Algorithm for determining which locale to choose for the app; the
          /// algorithm used is very simple, just checking the languageCode, and
          /// defaulting to the first locale (en) if the required locale is not
          /// included in supportedLocales. See the following for more info:
          /// - https://api.flutter.dev/flutter/widgets/WidgetsApp/localeResolutionCallback.html
          /// - https://flutter.dev/docs/development/accessibility-and-localization/internationalization
          /// - https://resocoder.com/2019/06/01/flutter-localization-the-easy-way-internationalization-with-json/
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          // if locale is not supported, fall back to English
          return supportedLocales.first;
        },
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: MainPage(cameras: cameras),
      ),
    );
  }
}
