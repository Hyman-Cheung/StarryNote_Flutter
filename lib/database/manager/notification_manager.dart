import '../data/notification_data.dart';
import 'database_helper.dart';

class NotificationManager {
  // Create the DatabaseHelper object for accessing the methods to interact with the database:
  final dbHelper = DatabaseHelper.getInstance('notification_table');

  // Private Constructor to reate instance:
  NotificationManager._privateConstructor();
  static final NotificationManager instance =
      NotificationManager._privateConstructor();

  // Add data:
  Future<Map<String, dynamic>?> insert(int nId, String nTitle, String nBody,
      String scheduledDate, String intervalType, int tid) async {
    try {
      // Create the data object
      String createAt = DateTime.now().toString(); // Current time
      var notification = NotificationData(
          notificationId: nId,
          notificationTitle: nTitle,
          notificationBody: nBody,
          scheduledDate: scheduledDate,
          intervalType: intervalType,
          createAt: createAt,
          lastEditTime: createAt,
          taskId: tid);

      // Insert the data
      await dbHelper.insert(notification.toMap());
      print('--- inserted ---');
      return notification.toMap(); // Return the notification as a map
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
  Future<Map<String, dynamic>?> update(int nId, String nTitle, String nBody,
      String scheduledDate, String intervalType, int tid) async {
    // Last edit time:
    String lastEditTime = DateTime.now().toString(); // Current time
    // Get the 'createAt' of the selected item:
    Map<String, dynamic>? notificationItem =
        await dbHelper.getRowById(nId); // Get all the item data
    String createAt = notificationItem![
        'createAt']; // Get the 'createAt' of the selected item
    // Assign new data:
    var updatedNotification = NotificationData(
        notificationId: nId,
        notificationTitle: nTitle,
        notificationBody: nBody,
        scheduledDate: scheduledDate,
        intervalType: intervalType,
        createAt: createAt,
        lastEditTime: lastEditTime,
        taskId: tid);
    dbHelper.update(updatedNotification.toMap());
    print('--- Updated ---');
    return updatedNotification.toMap();
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
      final notifications = await dbHelper.queryAllRows();
      for (var notification in notifications) {
        try {
          DateTime scheduledDate =
              DateTime.parse(notification['scheduledDate']);
          if (scheduledDate
              .isBefore(DateTime.now().subtract(Duration(days: 1)))) {
            await dbHelper.delete(notification['id']);
            print('Deleted notification ID: ${notification['id']}');
          }
        } catch (e) {
          print('Error deleting notification ${notification['id']}: $e');
        }
      }
      return true;
    } catch (e) {
      print('Error querying notifications: $e');
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
