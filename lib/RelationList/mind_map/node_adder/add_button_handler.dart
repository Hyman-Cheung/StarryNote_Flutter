//======================================================================================================
// add_button_handler.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';
import '../../Data_Model/node_and_edge.dart'; // Import MindMapNode and MindMapEdge

class AddButtonHandler {
  // Method to check if the tap is close to any existing node
  static bool isTapNearNode(Offset tapPosition, List<MindMapNode> nodes) {
    const double nodeRadius = 30.0;
    const double threshold = 32.0; // Define a threshold for the tap area

    for (var node in nodes) {
      double distance = (node.position - tapPosition).distance;
      if (distance < threshold + nodeRadius) {
        return true; // Tap is near a node
      }
    }
    return false; // Tap is not near any node
  }

  // Method to check if the tap is near any edge
  static bool isTapNearEdge(Offset tapPosition, List<MindMapEdge> edges) {
    const double edgeThreshold = 30.0; // Adjust this value to define how close the tap must be to an edge

    for (var edge in edges) {
      double distanceToEdge = _distanceToLineSegment(edge.from.position, edge.to.position, tapPosition);
      if (distanceToEdge < edgeThreshold) {
        return true;
      }
    }
    return false;
  }

  // Calculate distance between a point and a line segment
  static double _distanceToLineSegment(Offset p1, Offset p2, Offset point) {
    double lineLength = (p2 - p1).distance;
    if (lineLength == 0.0) return (point - p1).distance;
    double t = ((point - p1).dx * (p2 - p1).dx + (point - p1).dy * (p2 - p1).dy) / (lineLength * lineLength);
    t = t.clamp(0.0, 1.0);
    Offset projection = p1 + (p2 - p1) * t;
    return (point - projection).distance;
  }
}