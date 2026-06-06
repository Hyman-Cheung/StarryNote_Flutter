import 'package:flutter/material.dart';
import 'package:notes_taking_app/label/label_list.dart';
import '../../RelationList/relation_list_menu.dart';
import '../../database/data/label_data.dart'; // Import any necessary dependencies

// Function to build the top navigation bar with buttons
Widget buildTopBar(
    BuildContext context,
    bool isEditMode,
    int notebookId,
    Function toggleEditMode,
    Function closeDrawerDialog,
    Function(String, String, int, Offset)
        switchToPage // function to switch to clicked label's page
    ) {
  return Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceBetween, // Aligns buttons on both sides
    children: [
      Row(
        children: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return RelationListDialog(closeDrawerDialog: closeDrawerDialog, switchToPage: switchToPage,); // Show the Relation List dialog
                },
              );
            },
            child: Text("Relation List",
                style: TextStyle(fontSize: 14, color: Colors.black)),
          ), // Button for Relation List
          showListButton(notebookId, context, switchToPage, closeDrawerDialog),
          // Button for Study List
        ],
      ),
      isEditMode
          ? TextButton(
              onPressed: () => toggleEditMode(), // Exits edit mode when pressed
              child: Text("Done",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            )
          : IconButton(
              icon: Icon(Icons.more_vert), // Shows an options menu button
              onPressed: () =>
                  toggleEditMode(), // Enters edit mode when pressed
            ),
    ],
  );
}

// Widget to conditionally display the Question List and Study List buttons
Widget showListButton(
  int notebookId,
  BuildContext context,
  Function(String, String, int, Offset) switchToPage,
  Function closeDrawerDialog,
) {
  if (notebookId != 0) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.quiz),
          onPressed: () {
            LabelList(
              labelType: LabelType.question,
              notebookId: notebookId,
              switchToPage: switchToPage,
              closeDrawerDialog: closeDrawerDialog,
            ).showPopup(context);
          },
        ), // Button for Question List
        IconButton(
          icon: Icon(Icons.menu_book),
          onPressed: () {
            LabelList(
              labelType: LabelType.review,
              notebookId: notebookId,
              switchToPage: switchToPage,
              closeDrawerDialog: closeDrawerDialog,
            ).showPopup(context);
          },
        ), // Button for Study List
      ],
    );
  } else {
    return SizedBox();
  }
}
