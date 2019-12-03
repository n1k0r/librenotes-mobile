import 'package:librenotes/screens/auth_screen.dart';
import 'package:librenotes/screens/edit_note_screen.dart';
import 'package:librenotes/screens/notes_screen.dart';

final initialRoute = 'auth';
final routes = {
  'auth': (context) => AuthScreen(),
  'notes': (context) => NotesScreen(),
  'notes/edit': (context) => EditNoteScreen(),
};
