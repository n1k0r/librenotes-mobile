class Note {
  final int id;
  final DateTime created;
  final List<int> tags;
  final String text;

  Note({this.id, DateTime created, List<int> tags, this.text: ''}) :
    this.created = created ?? DateTime.now(),
    this.tags = List.unmodifiable(tags ?? []);

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    created: DateTime.parse(map['created']),
    tags: List.unmodifiable(map['tags'] ?? []),
    text: map['txt'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'created': created.toIso8601String(),
    'tags': tags,
    'txt': text,
  };

  @override
  String toString() {
    String truncText = text.length > 20 ? '${text.substring(0, 20)}...' : text;
    return 'Note{id: $id, created: $created, tags: $tags, text: $truncText}';
  }
}
