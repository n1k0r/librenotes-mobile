import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:librenotes/widgets/tag.dart';

class ToggleTag extends StatelessWidget {
  final String name;
  final bool active;
  final Function onTap;

  const ToggleTag({@required this.name, this.active: false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tag(
      name: name,
      onTap: onTap,
      color: active ? Theme.of(context).accentColor : Theme.of(context).backgroundColor,
    );
  }
}
