import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String name;
  final Color color;
  final Function onTap;

  const Tag({@required this.name, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    var tagColor = color ?? Theme.of(context).backgroundColor;

    return Card(
      margin: EdgeInsets.zero,
      color: tagColor,
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(name),
        ),
      ),
    );
  }
}
