import 'package:notes_taking_app/database/manager/task_review_manager.dart';
import '../../RelationList/Data_Operation/db_ops.dart';
import '../data/label_data.dart';
import '../manager/database_helper.dart';
import 'package:flutter/material.dart';

class LabelManager {
  // Create the DatabaseHelper object for accessing the methods to interact with the database:
  final dbHelper = DatabaseHelper.getInstance('label_table');

  // Private Constructor to reate instance:
  LabelManager._privateConstructor();
  static final LabelManager instance = LabelManager._privateConstructor();

  // Add data:
  Future<LabelData> insert(
      String name,
      LabelType labelType,
      String description,
      Offset position,
      int priority,
      String pageId,
      String sectionId,
      int notebookId) async {
    try {
      // Get the last id from the table
      int? lastRowId = await dbHelper.getLastRowId();
      print('Last id from the table: $lastRowId');

      // Check if lastRowId is null and set id accordingly
      int id = (lastRowId ?? 0) + 1;

      // Create the data object
      String createAt = DateTime.now().toString(); // Current time
      var label = LabelData(
          id: id,
          labelType: labelType,
          name: name,
          description: description,
          position: position,
          priority: priority,
          createAt: createAt,
          lastEditTime: createAt,
          pageId: pageId,
          sectionId: sectionId,
          notebookId: notebookId);

      // Insert the data
      await dbHelper.insert(label.toMap());
      print('Inserted label: ${label.toMap()}');
      print('--- inserted ---');
      return label;
    } catch (e) {
      print('Error inserting data: $e');
      rethrow; // Propagates the error to the caller
    }
  }

  //******************** Query ********************//
  /* 
  Future represents a potential value or error that will be available at some point in the future. 
  It is used to handle asynchronous operations, allowing your program to continue running 
  while waiting for the result of an operation that takes time to complete, such as fetching data 
  from a database or making a network request.
  */
  // Get all the data from the table:
  Future<List<Map<String, dynamic>>> getData() async {
    final rows = await dbHelper.queryAllRows();
    return rows;
  }

  // Display all the data on the console:
  void query(String labelType) async {
    final rows = await dbHelper.queryAllRows();

    print('Query Result:');
    for (var row in rows) {
      if (row['labelType'] == labelType) {
        print(row);
      }
    }
    print('--- Query ended ---');
  }

  // Get data by id:
  Future<Map<String, dynamic>?> getDataById(int id) async {
    return await dbHelper.getRowById(id);
  }

  // Get data by pageId:
  Future<List<LabelData>> getLabelDataByPageId(String pageId) async {
    final rows = await dbHelper.queryAllRows();

    // Filter rows by pageId
    List<LabelData> labelDataList = rows
        .where((row) => row['pageId'] == pageId)
        .map((row) => LabelData(
            id: row['id'],
            labelType:
                LabelType.values.firstWhere((e) => e.name == row['labelType']),
            name: row['name'],
            description: row['description'],
            priority: int.parse(row['priority'].toString()),
            position: Offset(row['position_x'], row['position_y']),
            createAt: row['createAt'],
            lastEditTime: row['lastEditTime'],
            pageId: row['pageId'],
            sectionId: row['sectionId'],
            notebookId: row['notebookId']))
        .toList();

    return labelDataList;
  }

  //******************** Update ********************//
  // Update:
  void update(int id, LabelType labelType, String name, String description,
      int priority) async {
    // Last edit time:
    String lastEditTime = DateTime.now().toString(); // Current time
    // Get the 'createAt' of the selected item:
    Map<String, dynamic>? labelItem =
        await dbHelper.getRowById(id); // Get all the item data
    String createAt =
        labelItem!['createAt']; // Get the 'createAt' of the selected item
    // Get back the position:
    Offset position = Offset(
      (labelItem['position_x'] as num).toDouble(),
      (labelItem['position_y'] as num).toDouble(),
    );
    // Get back pageId:
    String pageId = labelItem['pageId'];
    // Get back sectiond:
    String sectionId = labelItem['sectionId'];
    // Get back notebookId:
    int notebookId = labelItem['notebookId'];
    // Assign new data:
    var reviewList = LabelData(
        id: id,
        labelType: labelType,
        name: name,
        description: description,
        position: position,
        priority: priority,
        createAt: createAt,
        lastEditTime: lastEditTime,
        pageId: pageId,
        sectionId: sectionId,
        notebookId: notebookId);
    dbHelper.update(reviewList.toMap());
    print('--- Updated ---');
  }

  //******************** Delete ********************//
  // Delete  data from the table:
  void delete(Map<String, dynamic> item) async {
    final id = item['id']; // Get the id from the received item
    print('$id');
    dbHelper.delete(id!);
    // Delete task review item from database:
    TaskReviewManager.instance.deleteTaskReviewItemByLabelId(id);
    // delete associated nodes
    List<int> nodesToDelete = [];
    nodesToDelete = await deleteNodesAssociatedwithLabel(id);
    for (int nodeID in nodesToDelete) {
      deleteEdgeByNodes(nodeID);
    }

    print('--- Deleted ---');
  }

  // Delete data by id:
  void deleteById(int id) async {
    print('$id');
    dbHelper.delete(id);
    // Delete task review item from database:
    TaskReviewManager.instance.deleteTaskReviewItemByLabelId(id);
    print('--- Deleted ---');
  }

  // Delete last data from the table:
  void deleteLast() async {
    final id = await dbHelper.queryRowCount(); // Get the last id from the table
    dbHelper.delete(id!);
    // Delete task review item from database:
    TaskReviewManager.instance.deleteTaskReviewItemByLabelId(id);
    print('--- Deleted ---');
  }
}
