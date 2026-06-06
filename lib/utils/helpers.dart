import 'package:flutter/material.dart';
import '../database/data/label_data.dart';

Color getLabelColor(LabelType type) {
  switch (type) {
    case LabelType.concept:
      return Colors.blue;
    case LabelType.question:
      return const Color.fromARGB(255, 200, 19, 19);
    case LabelType.review:
      return const Color.fromARGB(255, 242, 230, 2);
  }
}

IconData getLabelIcon(LabelType type) {
  switch (type) {
    case LabelType.concept:
      return Icons.polyline_outlined;
    case LabelType.question:
      return Icons.question_mark;
    case LabelType.review:
      return Icons.star_border_purple500_sharp;
  }
}

Offset transformGlobalToScene(
    Offset globalPosition, GlobalKey interactiveViewerKey) {
  final RenderBox renderBox =
      interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
  final Matrix4 transform =
      (interactiveViewerKey.currentState as TransformationController).value;
  final Offset localPosition = renderBox.globalToLocal(globalPosition);
  final double translateX = transform.getTranslation().x;
  final double translateY = transform.getTranslation().y;
  final double scale = transform.getMaxScaleOnAxis();
  return Offset(
    (localPosition.dx - translateX) / scale,
    (localPosition.dy - translateY) / scale,
  );
}
