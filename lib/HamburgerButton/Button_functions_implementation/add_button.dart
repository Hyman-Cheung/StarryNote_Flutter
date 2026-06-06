//======================================================================================================
// add_button.dart
//======================================================================================================

/*
  To provide implementation for the add button.
  Add button is used to add notebook/section/page.
*/

import 'package:flutter/material.dart';
import '../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart'; // Import db_ops.dart for database functions

// Function to add a notebook
Future<void> addNotebook(BuildContext context) async {
  // Add a new notebook with default name
  await addNotebookToDB("New Notebook");
}

// Function to add a section
Future<void> addSection(BuildContext context, int notebookId) async {
  // Add a new section with default name
  await addSectionToDB("New Section", notebookId);
}

// Function to add a page
Future<void> addPage(BuildContext context, String sectionId) async {
  // Add a new page with default name
  await addPageToDB("New Page", sectionId);
}