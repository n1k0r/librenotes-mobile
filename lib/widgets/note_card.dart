import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:librenotes/models/note.dart';
import 'package:librenotes/providers/storage.dart';
import 'package:librenotes/widgets/tag.dart';
import 'package:provider/provider.dart';

class NoteCard extends StatelessWidget {
  static const textStyle = TextStyle(fontSize: 16);
  static const timeStyle = TextStyle(fontSize: 12, color: Colors.grey);

  final Note note;
  final Function onTap;

  const NoteCard({@required this.note, this.onTap});

  String _getDate() {
    return DateFormat(
      'MMM d HH:m'
    ).format(note.created);
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<Storage>(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                note.text,
                style: textStyle,
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        for (var tag_id in note.tags)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Tag(name: storage.getTag(tag_id).name),
                        ),
                      ],
                    ),
                    Text(
                      _getDate(),
                      style: timeStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
