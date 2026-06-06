import '../data/task_review_data.dart';
import 'database_helper.dart';

class TaskReviewManager {
  // Create the DatabaseHelper object for accessing the methods to interact with the database:
  final dbHelper = DatabaseHelper.getInstance('task_review_table');

  // Private Constructor to create instance:
  TaskReviewManager._privateConstructor();
  static final TaskReviewManager instance =
      TaskReviewManager._privateConstructor();

  // Add data:
  Future<Map<String, dynamic>?> insert(int taskId, int labelId) async {
    try {
      // Get the last id from the table
      int? lastRowId = await dbHelper.getLastRowId();
      print('Last id from the table: $lastRowId');

      // Check if lastRowId is null and set id accordingly
      int taskReviewId = (lastRowId ?? 0) + 1;

      // Create the data object
      String createAt = DateTime.now().toString(); // Current time
      var taskReview = TaskReviewData(
          taskReviewId: taskReviewId,
          createAt: createAt,
          lastEditTime: createAt,
          taskId: taskId,
          labelId: labelId);

      // Insert the data
      await dbHelper.insert(taskReview.toMap());
      print('--- inserted ---');
      return taskReview.toMap(); // Return the task review as a map
    } catch (e) {
      print('Error inserting data: $e');
      return null;
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
  void query() async {
    final rows = await dbHelper.queryAllRows();

    print('Query Result:');
    for (var row in rows) {
      print(row);
    }
    print('--- Query ended ---');
  }

  // Get data by id:
  Future<Map<String, dynamic>?> getDataById(int id) async {
    return await dbHelper.getRowById(id);
  }

  // Get data objects:
  Future<List<TaskReviewData>> getObjects() async {
    List<Map<String, dynamic>> rItems = await getData();
    return List.generate(rItems.length, (i) {
      return TaskReviewData(
          taskReviewId: rItems[i]['id'],
          createAt: rItems[i]['createAt'],
          lastEditTime: rItems[i]['lastEditTime'],
          taskId: rItems[i]['taskId'],
          labelId: rItems[i]['labelId']);
    });
  }

  // Get new id:
  Future<int> getNewId() async {
    // Get the last id from the table
    int? lastRowId = await dbHelper.getLastRowId();
    print('Last id from the table: $lastRowId');

    // Check if lastRowId is null and set id accordingly
    int newId = (lastRowId ?? 0) + 1;
    return newId;
  }

  //******************** Delete ********************//
  // Delete data from the table:
  void delete(Map<String, dynamic> item) async {
    final id = item['id']; // Get the id from the received item
    print('$id');
    dbHelper.delete(id!);
    print('--- Deleted ---');
  }

  // Delete last data from the table:
  void deleteLast() async {
    final id = await dbHelper.queryRowCount(); // Get the last id from the table
    dbHelper.delete(id!);
    print('--- Deleted ---');
  }

  // Deletr task review item by label id:
  Future<void> deleteTaskReviewItemByLabelId(int labelId) async {
    final rItems = await getObjects();
    for (var rItem in rItems) {
      if (rItem.labelId == labelId) {
        delete(rItem.toMap());
      }
    }
  }

  // ******************* Check *******************//
  // Check whether the label exiting in task review list:
  Future<bool> labelExist(int labelId) async {
    try {
      final rItems = await getObjects();
      return rItems.any((rItem) => rItem.labelId == labelId);
    } catch (e) {
      print('Error checking label existence: $e');
      return false; // Assume label doesn't exist if there's an error
    }
  }
}
