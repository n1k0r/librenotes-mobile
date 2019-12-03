import 'dart:typed_data';

import 'package:librenotes/models/note.dart';
import 'package:librenotes/models/tag.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class Cache {
  static final Cache _instance = Cache._init();

  Future<Database> database;
  Future<bool> firstOpen;
  bool _created = false;

  factory Cache() => _instance;

  Cache._init() {
    database = openDatabase(
      'cache.db',
      version: 1,
      onCreate: _onCreate,
    );

    firstOpen = _getFirstOpen();
  }

  Future<bool> _getFirstOpen() async {
    await database;
    return _created;
  }

  _onCreate(Database db, int version) {
    _created = true;

    db.execute('''
      CREATE TABLE tag (
        id INTEGER PRIMARY KEY,
        uuid BLOB NOT NULL UNIQUE,
        updated DATETIME NOT NULL,
        deleted BOOL,
        name VARCHAR(255)
      )
    ''');
    db.execute('''
      CREATE TABLE note (
        id INTEGER PRIMARY KEY,
        uuid BLOB NOT NULL UNIQUE,
        created DATETIME,
        updated DATETIME NOT NULL,
        deleted BOOL NOT NULL,
        txt TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE notes_tag (
        note_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (note_id, tag_id)
      )
    ''');
  }

  insertDebugData() async {
    await insertTag(Tag(name: 'TODO'));
    await insertTag(Tag(name: 'Work'));
    await insertTag(Tag(name: 'Study'));

    await insertNote(Note(text: 'Update project roadmap', tags: [1, 2, 3]));
    await insertNote(Note(text: 'Buy cookies 🍪🍪🍪'));
    await insertNote(Note(text: 'Read Flutter docs!\nhttps://flutter.dev/docs', tags: [2]));
  }

  String _getUpdateTime() {
    return DateTime.now().toUtc().toIso8601String();
  }

  Future<Map<int, List<int>>> getNotesTags(List notes) async {
    final db = await database;

    final notesTags = await db.query('notes_tag');

    Map<int, List<int>> tags = {};
    for (var note in notes) {
      tags[note['id']] = [];
    }

    for (var notes_tag in notesTags) {
      final note = notes_tag['note_id'];
      final tag = notes_tag['tag_id'];

      tags[note].add(tag);
    }

    return tags;
  }

  Future<Map<int, List<String>>> getNotesTagsUUIDs(List notes) async {
    final db = await database;

    final tags = await db.query('tag');
    final notesTags = await db.query('notes_tag');

    Map<int, List<String>> result = {};
    for (var note in notes) {
      result[note['id']] = [];
    }

    for (var notes_tag in notesTags) {
      final note = notes_tag['note_id'];
      final tag = tags.firstWhere((tag) => tag['id'] == notes_tag['tag_id']);

      result[note]?.add(
        Uuid().unparse(tag['uuid'])
      );
    }

    return result;
  }

  Future<List<Note>> notes() async {
    final db = await database;

    final notes = await db.query(
      'note',
      where: 'deleted = 0',
    );

    Map<int, List<int>> tags = await getNotesTags(notes);

    return List.generate(notes.length, (i) {
      Map<String, dynamic> map = Map.from(notes[i]);
      map['tags'] = tags[map['id']];
      return Note.fromMap(map);
    });
  }

  Future<int> insertNote(Note note, {String uuid}) async {
    if (note.id != null) {
      throw FormatException('ID of Note model have to be equal to null on insert');
    }

    final db = await database;

    var map = note.toMap();
    map['uuid'] = Uint8List(16);
    if (uuid == null) {
      Uuid().v4buffer(map['uuid']);
    } else {
      Uuid().parse(uuid, buffer: map['uuid']);
    }
    map['updated'] = _getUpdateTime();
    map['deleted'] = false;

    List<int> tags = map['tags'];
    map.remove('tags');

    int id = await db.insert('note', map);
    for (var tag in tags) {
      db.insert('notes_tag', {'note_id': id, 'tag_id': tag});
    }

    return id;
  }

  Future<bool> updateNote(Note note) async {
    final db = await database;

    var map = note.toMap();
    map['updated'] = _getUpdateTime();

    List<int> tags = map['tags'];
    map.remove('tags');

    await db.delete(
      'notes_tag',
      where: 'note_id = ?',
      whereArgs: [note.id],
    );

    for (var tag in tags) {
      db.insert('notes_tag', {'note_id': note.id, 'tag_id': tag});
    }

    int result = await db.update(
      'note',
      map,
      where: 'id = ?',
      whereArgs: [note.id],
    );
    return result != 0;
  }

  Future<bool> deleteNote(int id) async {
    final db = await database;

    await db.delete(
      'notes_tag',
      where: 'note_id = ?',
      whereArgs: [id],
    );

    int result = await db.update(
      'note',
      {
        'created': null,
        'updated': _getUpdateTime(),
        'deleted': true,
        'txt': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return result != 0;
  }

  Future<List<Map<String, dynamic>>> getSyncNotes(DateTime lastSync) async {
    final db = await database;

    List notes;
    if (lastSync != null) {
      notes = await db.query(
        'note',
        where: 'datetime(updated) > datetime(?)',
        whereArgs: [lastSync.toIso8601String()],
      );
    } else {
      notes = await db.query('note');
    }

    Map<int, List<String>> tags = await getNotesTagsUUIDs(notes);

    return notes.map(
      (note) => note['deleted'] != 0 ? {
        'uuid': Uuid().unparse(note['uuid']),
        'deleted': true,
      } : {
        'uuid': Uuid().unparse(note['uuid']),
        'created': note['created'],
        'text': note['txt'],
        'tags': tags[note['id']],
      }
    ).toList();
  }

  Future<Note> getNoteByUUID(String uuid, {deleted: false}) async {
    final db = await database;

    String uuidFormatted = uuid.replaceAll('-', '').toUpperCase();
    final row = await db.query(
      'note',
      where: 'deleted = 0 AND hex(uuid) = ?',
      whereArgs: [uuidFormatted],
    );

    if (row.length == 1) {
      return Note.fromMap(row[0]);
    }
    return null;
  }

  Future<void> applyNotes(List notes) async {
    for (var note in notes) {
      int id = (await getNoteByUUID(note['uuid']))?.id;

      if (note.containsKey('deleted') && note['deleted']) {
        if (id == null) {
          continue;
        }
        deleteNote(id);
      } else {
        List<String> src = List<String>.from(note['tags']);
        Iterable<Future<int>> futureTags = src.map(
          (uuid) async => (await getTagByUUID(uuid)).id
        );
        List<int> tags = await Future.wait(futureTags);

        if (id != null) {
          updateNote(
            Note(
              id: id,
              tags: tags,
              text: note['text'],
            ),
          );
        } else {
          insertNote(
            Note(
              created: DateTime.parse(note['created']),
              tags: tags,
              text: note['text'],
            ),
            uuid: note['uuid'],
          );
        }
      }
    }
  }

  Future<List<Tag>> tags() async {
    final db = await database;
    final tags = await db.query(
      'tag',
      where: 'deleted = 0',
    );

    return List.generate(tags.length, (i) {
      return Tag.fromMap(tags[i]);
    });
  }

  Future<int> insertTag(Tag tag, {String uuid}) async {
    if (tag.id != null) {
      throw FormatException('ID of Tag model have to be equal to null on insert');
    }

    final db = await database;

    var map = tag.toMap();
    map['uuid'] = Uint8List(16);
    if (uuid == null) {
      Uuid().v4buffer(map['uuid']);
    } else {
      Uuid().parse(uuid, buffer: map['uuid']);
    }
    map['updated'] = _getUpdateTime();
    map['deleted'] = false;

    int id = await db.insert('tag', map);
    return id;
  }

  Future<bool> updateTag(Tag tag) async {
    final db = await database;

    int result = await db.update(
      'tag',
      {
        ...tag.toMap(),
        'updated': _getUpdateTime(),
      },
      where: 'id = ?',
      whereArgs: [tag.id],
    );
    return result != 0;
  }

  Future<bool> deleteTag(int id) async {
    final db = await database;

    await db.delete(
      'notes_tag',
      where: 'tag_id = ?',
      whereArgs: [id],
    );

    int result = await db.update(
      'tag',
      {
        'updated': _getUpdateTime(),
        'deleted': true,
        'name': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return result != 0;
  }

  Future<Tag> getTagByUUID(String uuid, {deleted: false}) async {
    final db = await database;

    String uuidFormatted = uuid.replaceAll('-', '').toUpperCase();
    final row = await db.query(
      'tag',
      where: 'deleted = 0 AND hex(uuid) = ?',
      whereArgs: [uuidFormatted],
    );

    if (row.length == 1) {
      return Tag.fromMap(row[0]);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSyncTags(DateTime lastSync) async {
    final db = await database;

    List tags;
    if (lastSync != null) {
      tags = await db.query(
        'tag',
        where: 'datetime(updated) > datetime(?)',
        whereArgs: [lastSync.toIso8601String()],
      );
    } else {
      tags = await db.query('tag');
    }

    return tags.map(
      (tag) => {
        'uuid': Uuid().unparse(tag['uuid']),
        if (tag['deleted'] != 0)
        'deleted': true,
        if (tag['deleted'] == 0)
        'name': tag['name'],
      }
    ).toList();
  }

  Future<void> applyTags(List tags) async {
    for (var tag in tags) {
      int id = (await getTagByUUID(tag['uuid']))?.id;

      if (tag.containsKey('deleted') && tag['deleted']) {
        if (id == null) {
          continue;
        }
        deleteTag(id);
      } else {
        if (id != null) {
          updateTag(
            Tag(
              id: id,
              name: tag['name'],
            ),
          );
        } else {
          insertTag(
            Tag(
              name: tag['name'],
            ),
            uuid: tag['uuid'],
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> getSyncData(DateTime lastSync) async {
    lastSync = lastSync?.toUtc();

    return {
      'tags': await getSyncTags(lastSync),
      'notes': await getSyncNotes(lastSync),
    };
  }

  Future<void> applyData(Map<String, dynamic> data) async {
    await applyTags(data['tags']);
    await applyNotes(data['notes']);
  }

  Future<void> clear() async {
    final db = await database;

    await db.delete('notes_tag');
    await db.delete('tag');
    await db.delete('note');
  }
}
