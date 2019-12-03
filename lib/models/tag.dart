class Tag {
  final int id;
  final String name;

  Tag({this.id, this.name: ''});

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
    id: map['id'],
    name: map['name'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };

  @override
  String toString() {
    return 'Tag{id: $id, name: $name}';
  }
}
