import 'package:flutter/material.dart';
import 'package:librenotes/models/tag.dart';
import 'package:librenotes/providers/storage.dart';
import 'package:provider/provider.dart';

class TagDialog extends StatefulWidget {
  final Tag tag;

  const TagDialog({Key key, this.tag}) : super(key: key);

  @override
  _TagDialogState createState() => _TagDialogState();
}

class _TagDialogState extends State<TagDialog> {
  TextEditingController _tagTextController = TextEditingController();

  Storage storage;

  String addTagDialogError;

  @override
  void initState() {
    super.initState();

    _tagTextController.text = widget.tag?.name;
  }

  @override
  void didChangeDependencies() {
    storage = Provider.of<Storage>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'New tag' : 'Edit tag'),
      content: TextField(
        autofocus: true,
        controller: _tagTextController,
        decoration: InputDecoration(
          hintText: 'Tag',
          errorText: addTagDialogError,
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text(widget.tag == null ? 'ADD' : 'SAVE'),
          onPressed: () {
            if (_tagTextController.text.isEmpty) {
              setState(() {
                addTagDialogError = 'Tag can not be empty';
              });
              return;
            }

            if (widget.tag == null) {
              storage.addTag(
                Tag(
                  name: _tagTextController.text
                )
              );
            } else {
              storage.saveTag(
                Tag(
                  id: widget.tag.id,
                  name: _tagTextController.text,
                )
              );
            }

            Navigator.of(context).pop();
          },
        ),
        if (widget.tag != null)
        FlatButton(
          child: Text('DELETE'),
          textColor: Colors.redAccent,
          onPressed: () {
            storage.deleteTag(widget.tag.id);

            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
