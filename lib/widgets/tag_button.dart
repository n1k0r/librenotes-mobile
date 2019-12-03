import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:librenotes/widgets/tag.dart';

class TagButton extends StatelessWidget {
  final String name;
  final Function onTap;

  const TagButton({@required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tag(
      name: name,
      onTap: onTap,
      color: Theme.of(context).buttonColor,
    );
  }
}
