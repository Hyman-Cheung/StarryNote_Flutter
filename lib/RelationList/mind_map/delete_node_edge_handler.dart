//======================================================================================================
// delete_node_edge_handler.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';
import '../Data_Model/node_and_edge.dart';

class DeleteNodeEdgeHandler {
  // Track the selected node and edge for delete button
  static MindMapNode? selectedNodeForDelete;
  static MindMapEdge? selectedEdgeForDelete;
  static List<MindMapNode> nodesToDelete = [];
  static List<MindMapEdge> edgesToDelete = [];

  // Show the delete confirmation dialog
  static void showDeleteConfirmationDialog(
      BuildContext context,
      List<MindMapNode> nodes,
      List<MindMapEdge> edges,
      dynamic item,
      int relationID,
      Function() onDelete,
      Function() onChangesMade,
      Function(List<MindMapNode>, List<MindMapEdge>) passItemsToDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(item is MindMapNode ? "Delete Node" : "Delete Edge"),
          content: Text(
            item is MindMapNode
                ? "Are you sure you want to delete '${item.title}'?"
                : "Are you sure you want to delete the edge between '${item.from.title}' and '${item.to.title}'?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (item is MindMapNode) {
                  // Add node to the list for deletion
                  nodesToDelete.add(item);
                  // Delete the node from the list
                  nodes.remove(item);

                  // Remove all edges connected to the node
                  edges.removeWhere((edge) {
                    // Check if the edge's 'from' or 'to' node matches the deleted node
                    if (edge.from == item || edge.to == item) {
                      edgesToDelete.add(edge); // Add edge to the list
                      return true; // Remove edge from the list
                    }
                    return false;
                  });
                } else if (item is MindMapEdge) {
                  // Add node to the list for deletion
                  edgesToDelete.add(item);
                  // Remove the selected edge
                  edges.remove(item);
                }
                // Call onDelete to refresh the UI
                onDelete();

                // Notify the parent widget that changes were made
                onChangesMade(); // Set isChanges = true
                passItemsToDelete(nodesToDelete, edgesToDelete);

                selectedNodeForDelete = null; // Clear the selected node
                selectedEdgeForDelete = null; // Clear the selected edge
                Navigator.of(context).pop();
              },
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
