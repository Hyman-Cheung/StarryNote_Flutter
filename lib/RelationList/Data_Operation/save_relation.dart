import '../Data_Model/node_and_edge.dart'; // Import your models (MindMapNode, MindMapEdge)
import '../../database/db_helper.dart';    // Import your DBHelper2 class
import 'package:flutter/material.dart';

class SaveRelation {
  final List<MindMapNode> nodes;
  final List<MindMapEdge> edges;
  final List<MindMapNode> nodesToAdd;
  final List<MindMapNode> nodesToDelete;  // List of nodes marked for deletion
  final List<MindMapEdge> edgesToDelete;  // List of edges marked for deletion

  SaveRelation({
    required this.nodes,
    required this.edges,
    required this.nodesToAdd,
    required this.nodesToDelete,
    required this.edgesToDelete,
  });

  // Save nodes, edges, and handle deletions
  Future<void> save() async {
    try {
      final db = await DBHelper.getDatabase(); // Get the database instance

      debugPrint(nodes.toString());
      debugPrint(edges.toString());

      // Start a database transaction to ensure data consistency
      print("Starting a new database transaction");
      await db.transaction((txn) async {
        // Handle node deletions
        for (MindMapNode node in nodesToDelete) {
          // Delete the node from the database
          print("Deleting a node");
          await DBHelper().deleteMindMapNodeWithTransaction(node.id, txn);

          print("Deleting edges associated with the node");
          // Delete the edges associated with the node
          await DBHelper().deleteMindMapEdgeByNodesWithTransaction(node.id, txn);
        }

        // Handle edge deletions
        for (MindMapEdge edge in edgesToDelete) {
          print("Deleting a edge");
          // Delete the edge from the database
          await DBHelper().deleteMindMapEdgeWithTransaction(edge.id, txn);
        }

        // Save nodes
        for (MindMapNode node in nodesToAdd) {
            print("Inserting a node");
            // Insert the new node into the database
            await DBHelper().insertMindMapNodeWithTransaction(node, txn);
        }

        // update nodes
        for (MindMapNode node in nodes) {
          print("Updating a node");
          // Update the existing node in the database
          await DBHelper().updateMindMapNodeWithTransaction(node, txn);
        }

        // Save edges (new)
        for (MindMapEdge edge in edges) {
          if (edge.id == 0) {
            print("Adding a edge");
            await DBHelper().insertMindMapEdgeWithTransaction(edge, txn);
          }
        }
      });

      // Provide user feedback for successful saving
      print("Mind map saved successfully!");
    } catch (e) {
      // Handle any errors during the save operation
      print("Error saving mind map: $e");
    }
  }
}