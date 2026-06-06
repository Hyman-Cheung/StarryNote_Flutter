//======================================================================================================
// relation_list_menu.dart
//======================================================================================================

/*
  Create a dialog to list all the relation, allow renaming and deleting, and allow access to the mind map.
*/

import 'package:flutter/material.dart';
import 'package:notes_taking_app/RelationList/Data_Model/relation_model.dart';
import './Data_Operation/db_ops.dart';
import 'mind_map_interface.dart'; // Import the mind map interface

// Dialog that displays and manages a list of relations with edit/delete options
class RelationListDialog extends StatefulWidget {
  final Function closeDrawerDialog;
  final Function switchToPage;
  RelationListDialog({required this.closeDrawerDialog, required this.switchToPage});
  @override
  _RelationListDialogState createState() => _RelationListDialogState();
}

class _RelationListDialogState extends State<RelationListDialog> {
  // List of relations fetched from the database
  List<Relation> relations = []; // Stores all relations fetched from DB
  TextEditingController _controller =
      TextEditingController(); // For editing relation names

  @override
  void initState() {
    super.initState();
    _loadRelationsList(); // Load data when widget initializes
  }

  // Fetch relations from the database and updates the UI
  Future<void> _loadRelationsList() async {
    relations = await readRelations(); // Fetch relations from the database
    setState(() {}); // Refresh UI with the updated list
  }

  // Method to show a dialog for editing a relation
  void _editRelation(int index) {
    _controller.text = relations[index].title; // Pre-fill with current name
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // White background for the dialog
          title: Text(
            "Edit Relation",
            style: TextStyle(color: Colors.black), // Black text for the title
          ),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Enter new name for the relation",
              hintStyle: TextStyle(color: Colors.black), // Black hint text
              enabledBorder: UnderlineInputBorder(
                // Inactive state
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                // Active state (when selected)
                borderSide: BorderSide(color: Colors.indigo, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without saving
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black), // Black text for button
              ),
            ),
            TextButton(
              onPressed: () async {
                // Update the relation in the database
                await updateRelationTitle(
                  relationID: relations[index].relationID,
                  title: _controller.text,
                );
                _loadRelationsList(); // Reload the relations list
                _controller.clear(); // Clear the input field
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.indigo), // Black text for button
              ),
            )
          ],
        );
      },
    );
  }

  // Method to show a warning dialog before deleting a relation
  void _showDeleteWarning(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // White background for the dialog
          title: Text(
            "Are you sure?",
            style: TextStyle(color: Colors.black), // Black text for the title
          ),
          content: Text(
            "Do you really want to delete this relation?",
            style: TextStyle(
                color: Colors.black), // Black text for the warning message
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without deleting
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                    color: Colors.black), // Black text for cancel button
              ),
            ),
            TextButton(
              onPressed: () async {
                await deleteRelation(
                    relations[index].relationID); // Delete the relation
                _loadRelationsList(); // Reload the relations list
                Navigator.pop(context); // Close the confirmation dialog
              },
              child: Text(
                "Delete",
                style: TextStyle(
                    color: Colors.red), // Black text for delete button
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // White background for the dialog
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Relation List",
            style: TextStyle(color: Colors.black), // Black text for the title
          ),
        ],
      ),
      content: Padding(
        padding: EdgeInsets.all(23),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 600, maxHeight: 650, minWidth: 600, minHeight: 650),
          child: Container(
            // The border below the title:
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.black,
                  width: 3,
                ),
              ),
            ),
            width: double.maxFinite, // Takes maximum available width
            child: SingleChildScrollView(
              child: ClipRect(
                // Optimized list rendering for better performance
                child: ListView.builder(
                  // Padding of the task items:
                  padding: EdgeInsets.all(10),
                  shrinkWrap: true, // Fits content height
                  physics:
                      NeverScrollableScrollPhysics(), // Disables nested scrolling
                  itemCount: relations.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      // When tapped, navigate to the mind map interface.
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MindMapInterface(relation: relations[index], closeDrawerDialog: widget.closeDrawerDialog, switchToPage: widget.switchToPage,),
                          ),
                        );
                      },
                      title: Text(
                        relations[index].title,
                        style: TextStyle(
                            color: Colors.black), // Black text for list items
                      ),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min, // Minimizes icon row space
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit,
                                color: Colors.black), // Black icon
                            onPressed: () => _editRelation(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.black), // Black icon
                            onPressed: () => _showDeleteWarning(
                                index), // Show delete confirmation
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            "Close",
            style:
                TextStyle(color: Colors.black), // Black text for Close button
          ),
        ),
      ],
    );
  }
}
