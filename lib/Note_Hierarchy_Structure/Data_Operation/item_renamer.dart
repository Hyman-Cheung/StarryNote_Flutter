//======================================================================================================
// item_renamer.dart
//======================================================================================================

/*
  Provide abstract functions for renaming notebook/section/page/label as well as the associated nodes.
*/

import '../../database/data/label_data.dart';
import '../../database/db_helper.dart';
import '../../database/manager/label_manager.dart';

final dbHelper = DBHelper();

// Rename a notebook
Future<void> renameNotebook(int id, String newTitle) async {
  await dbHelper.renameNotebook(id, newTitle);
  await dbHelper.renameNotebookNode(id, newTitle);
}

// Rename a section
Future<void> renameSection(String id, String newTitle) async {
  await dbHelper.renameSection(id, newTitle);
  await dbHelper.renameSectionNode(id, newTitle);
}

// Rename a page
Future<void> renamePage(String id, String newTitle) async {
  await dbHelper.renamePage(id, newTitle);
  await dbHelper.renamePageNode(id, newTitle);
}

// Rename a label
Future<void> renameLabel(int id, String newTitle) async {
  final map = await LabelManager.instance.getDataById(id);
  LabelManager.instance.update(
    id,
    LabelType.values.firstWhere((e) => e.name == map!['labelType']),
    newTitle,
    map!['description'],
    int.parse(map['priority'].toString()),
  );
  await dbHelper.renameLabelNode(id, newTitle);
}
