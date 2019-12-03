import 'package:flutter/material.dart';
import 'package:librenotes/models/note.dart';
import 'package:librenotes/models/tag.dart';
import 'package:librenotes/providers/settings.dart';
import 'package:librenotes/providers/storage.dart';
import 'package:librenotes/providers/sync.dart';
import 'package:librenotes/widgets/note_card.dart';
import 'package:librenotes/widgets/tag_dialog.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String version = 'version unknown';

  Settings settings;
  Storage storage;

  int selectedTag;

  bool search = false;
  String searchText = '';

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then(
      (PackageInfo packageInfo) {
        setState(() {
          version = 'v${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }
    );
  }

  @override
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);
    storage = Provider.of<Storage>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: search ? TextField(
          autofocus: true,
          onChanged: _onSearchTextChanged,
        ) : Text('Notes'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              search ? Icons.cancel : Icons.search
            ),
            onPressed: _onSearch,
          ),
        ],
      ),
      drawer: search ? null : _getDrawer(),
      body: _getBody(),
      floatingActionButton: search ? null : _getFloatingActionButton(),
    );
  }

  _onSearch() {
    setState(() {
      search = !search;
      if (search) {
        searchText = '';
      }
    });
  }

  _onSearchTextChanged(String value) {
    setState(() {
      searchText = value;
    });
  }

  _getDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Icon(
                Icons.event_note,
                color: Theme.of(context).accentColor,
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            title: Text('All notes'),
            trailing: selectedTag == null ? Icon(Icons.check) : null,
            onTap: () => _selectTag(null),
          ),
          for (var tag in storage.tags)
            ListTile(
              title: Text(tag.name),
              trailing: selectedTag == tag.id ? Icon(Icons.check) : null,
              onTap: () => _selectTag(tag),
              onLongPress: () => _editTag(tag),
            ),
          Divider(),
          SwitchListTile(
            title: Text('Dark Theme'),
            value: settings.dark,
            secondary: Icon(Icons.lightbulb_outline),
            onChanged: _onThemeSwitch,
          ),
          ListTile(
            title: Text('Log out'),
            leading: Icon(Icons.exit_to_app),
            onTap: _onLogout,
          ),
          Divider(),
          ListTile(
            title: Text('Visit app page'),
            leading: Icon(Icons.info_outline),
            onTap: () {},
          ),
          ListTile(
            title: Text(
              version,
              textAlign: TextAlign.end,
            ),
            enabled: false,
          ),
        ],
      ),
    );
  }

  _selectTag(Tag tag) {
    setState(() {
      selectedTag = tag?.id;
    });
  }

  _editTag(Tag tag) {
    showDialog(
      context: context,
      builder: (_) {
        return TagDialog(tag: tag);
      },
    );
  }

  _onThemeSwitch(bool value) async {
    settings.dark = value;
  }

  _onLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log out'),
          content: Text('All unsynchronized data will be lost.'),
          actions: <Widget>[
            FlatButton(
              child: Text('CLOSE'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('LOG OUT'),
              onPressed: () {
                Sync().logout();
                Navigator.pushReplacementNamed(context, 'auth');
              },
            ),
          ],
        );
      }
    );
  }

  _getFloatingActionButton() {
    return FloatingActionButton(
      child: Icon(Icons.add),
      foregroundColor: Colors.white,
      onPressed: () {
          Navigator.pushNamed(context, 'notes/edit');
      },
    );
  }

  Future<void> _onRefresh() async {
    bool result = await Sync().sync();
    if (!result) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Synchronization error',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  _getBody() {
    List<Note> notes = List.from(storage.notes);

    if (selectedTag != null) {
      notes = notes.where(
        (note) => note.tags.contains(selectedTag)
      ).toList();
    }

    if (search) {
      notes = notes.where(
        (note) => search ? note.text.toLowerCase().contains(searchText.toLowerCase()) : true
      ).toList();
    }

    notes.sort(
      (Note first, Note second) => first.created.compareTo(second.created)
    );

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: notes.length > 0 ? ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          var pos = notes.length - 1 - index;
          return _buildNoteItem(context, notes[pos]);
        },
      ) : SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          child: Center(
            child: Text('No notes', style: Theme.of(context).textTheme.display1),
          ),
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).viewPadding.top - kToolbarHeight,
        ),
      ),
    );
  }

  _buildNoteItem(context, Note note) {
    return Dismissible(
      key: Key(note.id.toString()),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8, top: 8, right: 8),
              child: NoteCard(
                note: note,
                onTap: () {
                  Navigator.pushNamed(context, 'notes/edit', arguments: note);
                },
              ),
            ),
          ),
        ],
      ),
      onDismissed: (direction) {
        setState(() {
          storage.deleteNote(note.id);
        });

        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Note removed')));
      },
    );
  }
}
