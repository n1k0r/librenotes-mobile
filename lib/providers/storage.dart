import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:librenotes/models/note.dart';
import 'package:librenotes/models/tag.dart';
import 'package:librenotes/services/cache.dart';

class Storage with ChangeNotifier {
  static final Storage _instance = Storage._init();

  Cache cache = Cache();

  List<Note> _notes = [];
  List<Tag> _tags = [];

  get notes => UnmodifiableListView(_notes);
  get tags => UnmodifiableListView(_tags);

  factory Storage() => _instance;

  Storage._init() {
    reload();
  }

  reload() async {
    _tags = await cache.tags();
    _notes = await cache.notes();
    notifyListeners();
  }

  void addNote(Note note) async {
    int id = await cache.insertNote(note);

    _notes.add(Note(
      id: id,
      created: note.created,
      tags: note.tags,
      text: note.text,
    ));
    notifyListeners();
  }

  void saveNote(Note note) {
    int index = _notes.indexWhere((second) => second.id == note.id);

    _notes[index] = note;
    notifyListeners();

    cache.updateNote(note);
  }

  void deleteNote(int id) {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();

    cache.deleteNote(id);
  }

  Tag getTag(int id) {
    return _tags.firstWhere(
      (tag) => tag.id == id,
      orElse: () => null,
    );
  }

  void addTag(Tag tag) async {
    int id = await cache.insertTag(tag);

    _tags.add(Tag(
      id: id,
      name: tag.name,
    ));
    notifyListeners();
  }

  void saveTag(Tag tag) {
    int index = _tags.indexWhere((second) => second.id == tag.id);

    _tags[index] = tag;
    notifyListeners();

    cache.updateTag(tag);
  }

  void deleteTag(int id) {
    for (var i = 0; i < _notes.length; i++) {
      Note note = _notes[i];
      if (note.tags.contains(id)) {
        _notes[i] = Note(
          id: id,
          created: note.created,
          tags: note.tags.where((tag) => tag != id).toList(),
          text: note.text,
        );
      }
    }
    _tags.removeWhere((tag) => tag.id == id);
    notifyListeners();

    cache.deleteTag(id);
  }
}
