//======================================================================================================
// link_node_with_edge.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';
import '../Data_Model/node_and_edge.dart';

class LinkNodeWithEdgeHandler {
  // Helper method to check if two nodes are already connected to each other
  static bool isNodeConnected(
      List<MindMapEdge> edges, MindMapNode? node1, MindMapNode? node2) {
    return edges.any((edge) =>
        (edge.from == node1 && edge.to == node2) ||
        (edge.from == node2 && edge.to == node1));
  }

  // Show the link confirmation dialog
  static Future<void> showLinkConfirmationDialog(
    BuildContext context,
    MindMapNode sourceNode,
    MindMapNode targetNode,
    int relationID,
    List<MindMapEdge> edges,
    Function() onLink,
    Function() onChangesMade,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Link Node"),
          content: Text(
              "Are you sure you want to link '${sourceNode.title}' to '${targetNode.title}'?"),
          actions: [
            TextButton(
              onPressed: () async {
                await linkNodeToAnotherNode(
                    relationID, sourceNode, targetNode, edges, onChangesMade);
                onLink(); // Trigger UI refresh after the dialog closes
                Navigator.of(context).pop();
              },
              child: Text("Yes", style: TextStyle(color: Colors.indigo)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // Link the node to another node (simplified logic)
  static Future<void> linkNodeToAnotherNode(
      int relationID,
      MindMapNode selectedNode,
      MindMapNode targetNode,
      List<MindMapEdge> edges,
      Function() onChangesMade) async {
    // Create a new edge and add it
    MindMapEdge newEdge = MindMapEdge(
        id: 0, relationID: relationID, from: selectedNode, to: targetNode);
    edges.add(newEdge); // Add the new edge
    print("adding new node: $newEdge");
    // Notify the parent widget that changes were made
    onChangesMade(); // Set isChanges = true
  }
}
