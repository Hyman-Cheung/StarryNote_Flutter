import 'package:flutter/material.dart';
import '/database/manager/task_manager.dart';

// A class for handling calendar status:
class TaskProvider with ChangeNotifier {
  // Range of calendar days：
  DateTime firstDay = DateTime.now()
      .subtract(Duration(days: 365 * 30)); // 30 years before today
  DateTime lastDay =
      DateTime.now().add(Duration(days: 365 * 30)); // 30 years after today

  // Focused day:
  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;

  // Selected day:
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Tasks:
  Map<DateTime, List<Map<String, dynamic>>> _tasks = {};
  Map<DateTime, List<Map<String, dynamic>>> get tasks => _tasks;

  // Update _selectedDate:
  set selectedDate(DateTime date) {
    _selectedDate = date;
    // Notifies all the listeners (widgets) that are dependent on this ChangeNotifier to rebuild and update their UI with the latest data of _selectedDate:
    notifyListeners();
  }

  // Update _focusedDay:
  set focusedDay(DateTime date) {
    _focusedDay = date;
    // Notifies all the listeners (widgets) that are dependent on this ChangeNotifier to rebuild and update their UI with the latest data of _focusedDay:
    notifyListeners();
  }

  // Get tasks before and on selected date:
  List<Map<String, dynamic>> getTasksBeforeAndOnSelectedDate(DateTime sDate) {
    List<Map<String, dynamic>> tasksBeforeAndOnSelectedDate = [];

    _tasks.forEach((date, tasks) {
      if (date.isBefore(sDate) || isSameDay(date, sDate)) {
        tasksBeforeAndOnSelectedDate.addAll(tasks);
      }
    });
    // Print the number of task before and on selected date(for debug):
    print(
        'Number of task before and on ${sDate.day}/${sDate.month}/${sDate.year} : ${tasksBeforeAndOnSelectedDate.length}');
    return tasksBeforeAndOnSelectedDate;
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Add a task in sepcific date:
  void addTask(Map<String, dynamic> task) {
    // Check whether the _tasks does not have a list associated with the _selectedDate key in the _tasks map:
    if (_tasks[_selectedDate] == null) {
      // If it doesn't, create a new empty list and assign it to _tasks[_selectedDate]:
      _tasks[_selectedDate] = [];
    }
    // Add the new task to the list associated with the _selectedDate key in the _tasks map:
    _tasks[_selectedDate]?.add(task);
    // Notifies all the listeners (widgets) that are dependent on this ChangeNotifier to rebuild and update their UI with the latest data of _tasks:
    notifyListeners();
  }

  // Update task information:
  void updateTask(Map<String, dynamic> updatedTask) {
    for (var i = 0; i < _tasks[_selectedDate]!.length; i++) {
      if (_tasks[_selectedDate]![i]['id'] == updatedTask['id']) {
        _tasks[_selectedDate]![i] = updatedTask;
      }
    }
    // Notify UI to rebuild with the loaded tasks:
    notifyListeners();
  }

  // Remove a task in sepcific date:
  void removeTask(int index) {
    // Remove a task from the list associated with the _selectedDate key in the _tasks map.
    _tasks[_selectedDate]?.removeAt(index);
    // Notifies all the listeners (widgets) that are dependent on this ChangeNotifier to rebuild and update their UI with the latest data of _tasks:
    notifyListeners();
  }

  // Get task in specific date by index:
  Map<String, dynamic>? getTask(int index) {
    // Check if the selected date has tasks:
    if (_tasks[_selectedDate] != null && _tasks[_selectedDate]!.isNotEmpty) {
      // Ensure the index is within bounds:
      if (index >= 0 && index < _tasks[_selectedDate]!.length) {
        // Return the task at the specified index:
        return _tasks[_selectedDate]![index];
      }
    }
    // Return null if no task is found at the index:
    return null;
  }

  // Load and update tasks from Database:
  void loadTasksFromDatabase() async {
    // Clear all the tasks from tasks provider:
    clearAllTasks();
    // Get the data from database file:
    final rows = await TaskManager.instance.getData();
    // Convert rows into a Map of DateTime and task lists:
    for (var row in rows) {
      DateTime taskDate = DateTime.parse(row['taskDate']); // Parse date
      // Check whether the _tasks does not have a list associated with the taskDate key in the _tasks map:
      if (_tasks[taskDate] == null) {
        // If it doesn't, create a new empty list and assign it to _tasks[taskDate]:
        _tasks[taskDate] = [];
      }
      // Add task to the respective date:
      _tasks[taskDate]?.add(row);
    }
    // Notify UI to rebuild with the loaded tasks:
    notifyListeners();
  }

  // Clear all the tasks from tasks provider:
  void clearAllTasks() async {
    _tasks.clear(); // Clear the entire map
    notifyListeners(); // Notify listeners to refresh the UI
  }

  // Delete expired data and refresh tasks:
  void deleteExpiredDataAndRefresh() async {
    await TaskManager.instance
        .deleteExpiredData(); // Await asynchronous deletion
    loadTasksFromDatabase(); // Call directly, no return value used
    notifyListeners(); // Notify listeners directly
  }
}
