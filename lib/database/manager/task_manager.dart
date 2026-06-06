import '../data/task_data.dart';
import 'database_helper.dart';

class TaskManager {
  // Create the DatabaseHelper object for accessing the methods to interact with the database:
  final dbHelper = DatabaseHelper.getInstance('task_table');

  // Private Constructor to reate instance:
  TaskManager._privateConstructor();
  static final TaskManager instance = TaskManager._privateConstructor();

  // Add data:
  Future<Map<String, dynamic>?> insert(
      String tDate,
      String tTime,
      String tName,
      String tVenue,
      String tDescription,
      int tPriority,
      int isRepeating) async {
    try {
      // Get the last id from the table
      int? lastRowId = await dbHelper.getLastRowId();
      print('Last id from the table: $lastRowId');

      // Check if lastRowId is null and set id accordingly
      int tId = (lastRowId ?? 0) + 1;

      // Create the data object
      String createAt = DateTime.now().toString(); // Current time
      var task = TaskData(
          taskid: tId,
          taskDate: tDate,
          taskTime: tTime,
          taskName: tName,
          taskVenue: tVenue,
          taskDescription: tDescription,
          taskPriority: tPriority,
          isRepeating: isRepeating,
          createAt: createAt,
          lastEditTime: createAt);

      // Insert the data
      await dbHelper.insert(task.toMap());
      print('--- inserted ---');
      return task.toMap(); // Return the task as a map
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

  // Get new id:
  Future<int> getNewId() async {
    // Get the last id from the table
    int? lastRowId = await dbHelper.getLastRowId();
    print('Last id from the table: $lastRowId');

    // Check if lastRowId is null and set id accordingly
    int newId = (lastRowId ?? 0) + 1;
    return newId;
  }

  //******************** Update ********************//
  // Update:
  Future<Map<String, dynamic>?> update(
      int tId,
      String tDate,
      String tTime,
      String tName,
      String tVenue,
      String tDescription,
      int tPriority,
      int isRepeating) async {
    // Last edit time:
    String lastEditTime = DateTime.now().toString(); // Current time
    // Get the 'createAt' of the selected item:
    Map<String, dynamic>? taskItem =
        await dbHelper.getRowById(tId); // Get all the item data
    String createAt =
        taskItem!['createAt']; // Get the 'createAt' of the selected item
    // Assign new data:
    var updatedTask = TaskData(
        taskid: tId,
        taskDate: tDate,
        taskTime: tTime,
        taskName: tName,
        taskVenue: tVenue,
        taskDescription: tDescription,
        taskPriority: tPriority,
        isRepeating: isRepeating,
        createAt: createAt,
        lastEditTime: lastEditTime);
    dbHelper.update(updatedTask.toMap());
    print('--- Updated ---');
    return updatedTask.toMap();
  }

  //******************** Delete ********************//
  // Delete data from the table:
  void delete(Map<String, dynamic> item) async {
    final id = item['id']; // Get the id from the received item
    print('$id');
    dbHelper.delete(id!);
    print('--- Deleted ---');
  }

  // Delete exprired data:
  Future<bool> deleteExpiredData() async {
    try {
      final tasks = await dbHelper.queryAllRows();
      for (var task in tasks) {
        try {
          DateTime taskDate = DateTime.parse(task['taskDate']);
          if (taskDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
            await dbHelper.delete(task['id']);
            print('Deleted task ID: ${task['id']}');
          }
        } catch (e) {
          print('Error deleting task ${task['id']}: $e');
        }
      }
      return true;
    } catch (e) {
      print('Error querying tasks: $e');
      return false;
    }
  }

  // Delete last data from the table:
  void deleteLast() async {
    final id = await dbHelper.queryRowCount(); // Get the last id from the table
    dbHelper.delete(id!);
    print('--- Deleted ---');
  }
}
