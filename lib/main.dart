import 'package:note_app/main.dart' as note_app;

Future<void> main() async {
  // call the real app's main (note_app/main.dart) so building/installing
  // from the root folder launches the intended note_app.
  await note_app.main();
}
