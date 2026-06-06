//======================================================================================================
// edge_rendering_utility.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';
import 'delete_node_edge_handler.dart';
import '../Data_Model/node_and_edge.dart';

class EdgeRenderingUtility extends CustomPainter {
  final List<MindMapEdge> edges;
  final BuildContext context;
  bool isEditing;
  final TransformationController transformationController;

  EdgeRenderingUtility(this.edges, this.context, this.isEditing, this.transformationController);

  @override
  void paint(Canvas canvas, Size size) {
    Paint edgePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // Draw edges (relations between nodes)
    for (var edge in edges) {
      canvas.drawLine(edge.from.position, edge.to.position, edgePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
  
  // Handle the tap detection on each edge
  @override
  bool hitTest(Offset position) {
    // Check if the tap is on an edge
    for (var edge in edges) {
      final double distance = _distanceToLine(position, edge.from.position, edge.to.position);
      debugPrint("$distance");
      if (distance < 5) { // Check if the tap is close enough to the edge
        if (isEditing) {
          // Select the edge for deletion in edit mode
          DeleteNodeEdgeHandler.selectedEdgeForDelete = edge;
          (context as Element).markNeedsBuild(); // Force a rebuild
        }
        return true; // Indicate that the tap was handled
      }
    }

    // If no node or edge was tapped, clear the selection
    if (isEditing) {
      DeleteNodeEdgeHandler.selectedEdgeForDelete = null;
      (context as Element).markNeedsBuild(); // Force a rebuild
    }

    return false; // Indicate that the tap was not handled
  }

  // Helper function to calculate the distance from a point to a line
  double _distanceToLine(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return (point - start).distance;
    }
    final t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSquared;
    final projection = Offset(start.dx + t * dx, start.dy + t * dy);
    return (point - projection).distance;
  }
}