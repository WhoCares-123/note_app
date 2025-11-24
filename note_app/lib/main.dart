import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:note_app/providers/note_provider.dart';
import 'package:note_app/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // open the box used by StorageService only if not already open
  if (!Hive.isBoxOpen('note_app_box')) {
    await Hive.openBox('note_app_box');
  }
  // debug marker to confirm this main.dart is used in the built APK
  debugPrint('NOTE_APP_MAIN_LOADED');
  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteProvider(),
      child: Consumer<NoteProvider>(builder: (context, prov, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'All-in-One Notes',
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.indigo,
            floatingActionButtonTheme:
                FloatingActionButtonThemeData(backgroundColor: Colors.indigo),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.tealAccent,
            floatingActionButtonTheme:
                FloatingActionButtonThemeData(backgroundColor: Colors.tealAccent),
          ),
          themeMode: prov.isDark ? ThemeMode.dark : ThemeMode.light,
          home: HomePage(),
        );
      }),
    );
  }
}
