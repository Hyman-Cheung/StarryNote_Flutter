//======================================================================================================
// db_ops.dart
//======================================================================================================

/*
  Provide abstract functions for implementing different features (such as buttons).
*/

import '../../database/db_helper.dart';
import '../Data_Model/Notebook_DataModel.dart'; // Import Notebook data model
import '../Data_Model/Section_DataModel.dart'; // Import Section data model
import '../Data_Model/Page_DataModel.dart'; // Import Page data model

final dbHelper = DBHelper();

// Insert a notebook (ID auto-generated)
Future<void> addNotebookToDB(String name) async {
  final newNotebook = Notebook(
    notebook_id: 0, // The database will auto-assign an ID
    title: name,
    create_at: DateTime.now(),
    // user_id: 1,
    last_editTime: DateTime.now(),
    // relations: [],
    // studyList: [],
  );

  int id = await dbHelper.insertNotebook(newNotebook);
  print('Notebook inserted with ID: $id');
}

// Insert a Section into a specific notebook
Future<void> addSectionToDB(String name, int notebookID) async {
  final newSection = Section(
    sectionId: '',
    title: name,
    createAt: DateTime.now(),
    lastEditTime: DateTime.now(),
    notebookId: notebookID,
    // relations: 0,
  );

  int id = await dbHelper.insertSection(newSection);
  print('Section inserted with ID: $id');
}

// Insert a Page into a specific section
Future<void> addPageToDB(String name, String sectionID) async {
  final newPage = NotePage(
    pageId: '',
    title: name,
    createAt: DateTime.now(),
    lastEditTime: DateTime.now(),
    sectionId: sectionID,
    notebookId: 1, // will be reassigned base on sectionID
    // relations: 0,
    // questionList: /* to be filled in (don't remove the comma) */,
  );

  await dbHelper.insertPage(newPage);
}

// Fetch all Notebooks
Future<List<Notebook>> fetchNotebooks() async {
  return await DBHelper().getNotebooks(); // Ensure this function returns a list
}

// Fetch a notebook by ID
Future<Notebook> fetchNotebookById(int notebookId) async {
  List<Notebook> notebooks = await dbHelper.getNotebooks();
  final notebook = notebooks.firstWhere((n) => n.notebook_id == notebookId,
      orElse: () => throw Exception('Notebook not found'));
  return notebook;
}

// Fetch all sections inside a notebook by its ID
Future<List<Section>> fetchSectionsByNotebookId(int notebookId) async {
  return await DBHelper().getSectionsFromNotebookId(notebookId);
}

// Fetch a section by its ID
Future<Section> fetchSectionById(String sectionId) async {
  return await DBHelper().getSectionsFromId(sectionId);
}

// Fetch all pages inside a section by its ID
Future<List<NotePage>> fetchPagesBySectionId(String sectionId) async {
  return await DBHelper().getPagesFromSectionId(sectionId);
}

// Fetch a page by its ID
Future<NotePage> fetchPageById(String pageID) async {
  return await DBHelper().getPageFromId(pageID);
}

// Delete a notebook
Future<void> deleteNotebook(int id) async {
  await dbHelper.deleteNotebook(id);
  print('Deleted Notebook with ID: $id');
}

// Delete a section
Future<void> deleteSection(String id) async {
  await dbHelper.deleteSection(id);
  print('Deleted Section with ID: $id');
}

// Delete a page
Future<void> deletePage(String id) async {
  await dbHelper.deletePage(id);
  print('Deleted Page with ID: $id');
}

// Get the title of a notebook
Future<String> getNotebookName(int id) async {
  return await dbHelper.readNotebookNamebyId(id);
}

// Get the title of a section
Future<String> getSectionName(String id) async {
  return await dbHelper.readSectionNamebyId(id);
}

// Get the title of a page
Future<String> getPageName(String id) async {
  return await dbHelper.readPageNamebyId(id);
}
