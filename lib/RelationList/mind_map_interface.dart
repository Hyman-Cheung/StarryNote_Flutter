//======================================================================================================
// mind_map_interface.dart
//======================================================================================================

/*
  Interactive mind map interface incorporating with builders and other helper class.
*/

import 'package:flutter/material.dart';
import 'Data_Model/relation_model.dart';
import 'mind_map/mind_map_builder.dart'; // Main widget that renders the mind map visualization
import 'mind_map/delete_node_edge_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import './Data_Operation/save_relation.dart'; // Handles saving changes to database
import 'Data_Model/node_and_edge.dart'; // Contains data models for nodes and edges

/// This widget displays the mind map interface for a given relation.
/// It includes an "Edit" button at the top left and a "Close" button at the top right.
class MindMapInterface extends StatefulWidget {
  final Relation relation; // The relation data this mind map represents
  final Function closeDrawerDialog;
  final Function switchToPage;
  const MindMapInterface(
      {Key? key,
      required this.relation,
      required this.closeDrawerDialog,
      required this.switchToPage})
      : super(key: key);

  @override
  _MindMapInterfaceState createState() => _MindMapInterfaceState();
}

class _MindMapInterfaceState extends State<MindMapInterface> {
  // State Management Variables
  bool isEditing = false; // This will track if we're in "edit" mode
  bool hasChanges = false; // This will track if there are any unsaved changes

  // Data Collections
  List<MindMapNode> nodes = []; // Current nodes in the mind map
  List<MindMapEdge> edges = []; // Current edges/connections in the mind map

  // Change Tracking
  List<MindMapNode> nodesToAdd = []; // Nodes pending addition to database
  List<MindMapNode> nodesToDelete = []; // Nodes marked for deletion
  List<MindMapEdge> edgesToDelete = []; // Edges marked for deletion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with Edit and Close buttons
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        leading: IconButton(
          // Dynamic button that toggles between Edit/Done states
          icon: isEditing
              ? Text('Done',
                  style: TextStyle(
                      color: Colors.black)) // Show "Done" text when editing
              : Icon(Icons.edit,
                  color: Colors.black), // Show edit icon when not editing
          onPressed: () {
            setState(() {
              isEditing = !isEditing; // Toggle between edit and done
              if (!isEditing) {
                // Clear the selected node when switching back to view mode
                DeleteNodeEdgeHandler.selectedNodeForDelete = null;
                DeleteNodeEdgeHandler.selectedEdgeForDelete = null;
                // Reset linking state when exiting edit mode
              }
            });
          },
        ),
        title: Text(
          "Mind Map: ${widget.relation.title}",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          // Save Button (only enabled when hasChanges=true)
          IconButton(
            icon: Icon(Icons.save,
                color:
                    hasChanges ? Colors.black : Colors.black.withOpacity(0.5)),
            onPressed: hasChanges
                ? () {
                    saveChanges(); // Call the saveChanges function when the save button is pressed
                  }
                : null, // Disable the button if there are no changes
          ),
          // Close Button (checks for unsaved changes)
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () async {
              if (hasChanges) {
                await _showSaveExitDialog(); // Show confirmation if unsaved changes
              }
              Navigator.pop(context);
            },
          ),
        ],
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[300],
      body: Center(
        // Main mind map visualization component
        child: MindMapBuilder(
          relationID: widget.relation.relationID,
          isEditing: isEditing,

          // Callbacks for change tracking:
          onChangesMade: () => setState(() => hasChanges = true),
          onNodesChanged: (updatedNodes) =>
              setState(() => nodes = updatedNodes),
          onEdgesChanged: (updatedEdges) =>
              setState(() => edges = updatedEdges),
          onNodesAdded: (addedNodes) => setState(() => nodesToAdd = addedNodes),
          onNodesDeleted: (deletedNodes) =>
              setState(() => nodesToDelete = deletedNodes),
          onEdgesDeleted: (deletedEdges) =>
              setState(() => edgesToDelete = deletedEdges),

          closeRelationListDialog: () => Navigator.pop(context),
          closeDrawerDialog: widget.closeDrawerDialog,
          switchToPage: widget.switchToPage,
        ),
      ),
    );
  }

  /* Persists all changes to database including:
      - New nodes
      - Modified nodes/edges
      - Deleted nodes/edges
  */
  Future<void> saveChanges() async {
    try {
      await SaveRelation(
        nodes: nodes, // The list of nodes
        edges: edges, // The list of edges
        nodesToAdd: nodesToAdd,
        nodesToDelete: nodesToDelete,
        edgesToDelete: edgesToDelete,
      ).save();

      setState(() {
        hasChanges = false; // Reset change tracker after successful save

        // Clear pending changes collections
        nodesToAdd = [];
        nodesToDelete = [];
        edgesToDelete = [];
      });

      // Show feedback after saving (using a toast for now)
      Fluttertoast.showToast(
        msg: "Mind map saved successfully!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 2,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // Show an error message if saving fails
      Fluttertoast.showToast(
        msg: "Failed to save mind map. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print("Error while saving mind map: $e");
    }
  }

  // Method to show the confirmation dialog when trying to exit without saving
  Future<void> _showSaveExitDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Unsaved Changes"),
          content: Text(
              "You have unsaved changes. Do you want to save them before exiting?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't save, just exit
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () async {
                await saveChanges(); // Save the changes and exit
                Navigator.of(context).pop(true);
              },
              child:
                  Text("Save and Exit", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        );
      },
    );
  }
}
