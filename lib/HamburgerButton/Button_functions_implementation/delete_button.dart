//======================================================================================================
// delete_button.dart
//======================================================================================================

/*
  To provide implementation for the delete_button.
  Delete button is used to delete notebook/section/page.
  When a notebook is deleted, its content will also be deleted.
  This is similar to as when deleting sections.
*/

import 'package:flutter/material.dart';
import '../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart'; // Import the database operations file
import '../../RelationList/Data_Operation/db_ops.dart';

import '../../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';

class DeleteButton {
  // Show confirmation dialog for deletion
  static void showConfirmationDialog(
      BuildContext context, List<dynamic> editItems, Function refreshUI) {
    if (editItems != []) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Confirm Deletion",
                style: TextStyle(
                    color: Colors.black) // Set title text color to black
                ),
            content: Text("Are you sure you want to delete the selected items?",
                style: TextStyle(
                    color: Colors.black) // Set content text color to black
                ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // Close the dialog without doing anything
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ), // Button text color
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  deleteSelectedItems(context, editItems,
                      refreshUI); // Call the delete function
                },
                style: TextButton.styleFrom(overlayColor: Colors.black),
                child: Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        // Show warning dialog when no items are selected for deletion
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("No items selected"),
            content: Text("Please select items to delete."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  // Delete selected items (Notebooks, Sections, Pages)
  static void deleteSelectedItems(
      BuildContext context, List<dynamic> editItems, Function refreshUI) async {
    List<int> nodesToDelete = [];
    // Delete all selected notebooks
    for (var item in editItems) {
      if (item is Notebook) {
        await deleteNotebook(
            item.notebook_id); // Call the delete function for the notebook
        nodesToDelete =
            await deleteNodesAssociatedwithNotebook(item.notebook_id);
      } else if (item is Section) {
        await deleteSection(
            item.sectionId); // Call the delete function for the section
        nodesToDelete = await deleteNodesAssociatedwithSection(item.sectionId);
      } else if (item is NotePage) {
        await deletePage(item.pageId); // Call the delete function for the page
        nodesToDelete = await deleteNodesAssociatedwithPage(item.pageId);
      }
      for (int nodeID in nodesToDelete) {
        deleteEdgeByNodes(nodeID);
      }
    }

    // Refresh the UI after deletion
    refreshUI();
  }
}
