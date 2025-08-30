import 'package:flutter/widgets.dart';

Widget dynamicRowColumn({
  double maxWidth = 600,
  required List<Widget> children,
}) {
  if (maxWidth > 600) {
    return Row(children: children);
  } else {
    return Column(children: children);
  }
}
