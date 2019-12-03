import 'package:flutter/material.dart';
import 'package:librenotes/providers/settings.dart';
import 'package:librenotes/providers/storage.dart';
import 'package:librenotes/providers/sync.dart';
import 'package:librenotes/routes.dart';
import 'package:librenotes/styles/themes.dart';
import 'package:provider/provider.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (_) => Settings()),
        ChangeNotifierProvider(builder: (_) => Storage()),
        ChangeNotifierProvider(builder: (_) => Sync()),
      ],
      child: Consumer<Settings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'LibreNotes',
            theme: settings.dark ? dark : light,
            initialRoute: initialRoute,
            routes: routes,
          );
        },
      )
    );
  }
}
