import 'package:flutter/material.dart';
import '/database/manager/task_manager.dart';
import 'notification/notification_service.dart';
import '/tasks/add_task_dialog.dart';
import 'package:provider/provider.dart';
import '/tasks/show_task.dart';
import '/tasks/tasks_provider.dart';
import '/widgets/confirmation_dialog.dart';
import '/widgets/custom_search_bar.dart';

// A class for showing the task items:
class TaskDialog extends StatefulWidget {
  final Function(String, String, int, Offset) switchToPage;
  final Function closeDrawerDialog;

  const TaskDialog({
    required this.switchToPage,
    required this.closeDrawerDialog,
    Key? key,
  }) : super(key: key);

  @override
  TaskDialogState createState() => TaskDialogState();
}

class TaskDialogState extends State<TaskDialog> {
  // Define a TextEditingController for the search bar:
  TextEditingController searchController = TextEditingController();
  // Variable to store the search query:
  String searchQuery = '';

  // Initialize state and is called when the state object is created:
  @override
  void initState() {
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();
    // Listen for changes in the search bar text:
    searchController.addListener(() {
      setState(() {
        // Get or update the content from the searchController:
        searchQuery = searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks:
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // The background color of the dialog:
      backgroundColor: Colors.white,
      // Set the padding of the dialog:
      child: Padding(
          padding: EdgeInsets.all(23),
          child:
              Consumer<TaskProvider>(builder: (context, taskProvider, child) {
            // Get the tasks of the selected date:
            final tasks = taskProvider.tasks[taskProvider.selectedDate] ?? [];
            // Sort the tasks:
            final sortedTasks = _sort(tasks);
            // Filter tasks based on the search query:
            var filteredTasks = _filterItems(sortedTasks);
            // Sort the tasks:
            filteredTasks = _sort(filteredTasks);
            return ConstrainedBox(
              // Set the fixed size of the pop-up window:
              constraints: BoxConstraints(
                  maxHeight: 600, maxWidth: 650, minHeight: 600, minWidth: 650),
              child: Column(
                children: [
                  Container(
                    // The border below the title:
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 3),
                      ),
                    ),
                    child: Row(
                      // Center the title and left the button:
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Add button for adding task:
                        IconButton(
                          onPressed: () => _showAddTaskDialog(context),
                          icon: Icon(
                            Icons.add,
                            color: Colors.black,
                          ),
                        ),
                        // Title of the dialog:
                        Text(
                          'Tasks (${taskProvider.selectedDate.day}/${taskProvider.selectedDate.month}/${taskProvider.selectedDate.year})',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                        // Close button(X):
                        IconButton(
                            onPressed: () async {
                              // Close the dialog:
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.close))
                      ],
                    ),
                  ),
                  // Add a search bar below the title :
                  CustomSearchBar(
                    controller: searchController,
                    labelText: 'Search by task name',
                  ),
                  // Show the task items:
                  Expanded(
                    // ClipRect can prevent the items from overflowing:
                    child: ClipRRect(
                      // Show the items list which enables users to dismiss it by swiping:
                      child: ListView.builder(
                        // Padding of the task items:
                        padding: EdgeInsets.all(10),
                        // The number of items:
                        itemCount: filteredTasks.length,
                        // Build the items list:
                        itemBuilder: (BuildContext context, int index) {
                          // An action after swiping the item:
                          return Dismissible(
                            key: UniqueKey(),
                            background: Container(
                              // Only show the delete icon to the right of the item:
                              alignment: Alignment.centerRight,
                              // Show the delete icon when swiping the item:
                              child: Icon(Icons.delete, color: Colors.black),
                            ),
                            // Show the dialog to confirm the deletion after swiping the item:
                            confirmDismiss: (DismissDirection direction) async {
                              bool? confirmed = await ConfirmationDialog.show(
                                  context,
                                  'Are you sure you want to delete this item?',
                                  'Cancel',
                                  'Delete',
                                  true);
                              // If true delete the data, else keep the data
                              return confirmed ?? false;
                            },
                            // What to do when the user deletes the item:
                            onDismissed: (DismissDirection direction) {
                              // Get the task to be deleted:
                              final task = taskProvider.getTask(index);
                              // Check if the task is not null before deleting:
                              if (task != null) {
                                // Remove the task from the provider:
                                taskProvider.removeTask(index);
                                // Delete the task from the database:
                                TaskManager.instance.delete(task);
                                // Delete and cancel all the notifications with specific task id:
                                NotificationService()
                                    .deleteNotifications(task['id']);
                              }
                            },
                            // Only allow swiping to the left:
                            direction: DismissDirection.endToStart,
                            // Display the items' content:
                            child: ListTile(
                              title: Text(
                                filteredTasks[index]['taskName'],
                                style: TextStyle(
                                    // Get the color according to item's priority:
                                    color:
                                        _analysisColor(filteredTasks[index])),
                              ),
                              onTap: () {
                                _showTaskDialog(
                                    context, filteredTasks[index], index);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          })),
    );
  }

  // A function that shows the dialog box for adding a new task:
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false, // Prevents dismissal when tapping outside
      context: context,
      builder: (context) {
        return AddTaskDialog();
      },
    );
  }

  // A function that shows the dialog box with selected task information:
  void _showTaskDialog(
      BuildContext context, Map<String, dynamic> t, int index) {
    showDialog(
      barrierDismissible: false, // Prevents dismissal when tapping outside
      context: context,
      builder: (context) {
        return ShowTask(
          taskItem: t,
          switchToPage: widget.switchToPage,
          closeDrawerDialog: () {
            Navigator.of(context).pop(); // Close the TaskReviewList dialog
            widget.closeDrawerDialog(); // Close the parent ShowTask dialog
          },
        );
      },
    );
  }

  // Return the color according to item's priority:
  Color _analysisColor(Map<String, dynamic>? item) {
    int itemPriority =
        int.tryParse(item?['taskPriority']?.toString() ?? '2') ?? 2;
    if (itemPriority == 0) {
      return Colors.red;
    } else if (itemPriority == 1) {
      return Colors.orange;
    }
    return Colors.black; // Default color for other priorities
  }

  // Sorts the list according to the priority and datetime:
  List<Map<String, dynamic>> _sort(List<Map<String, dynamic>> originalList) {
    // Create a new modifiable list from the original list:
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.from(originalList);

    list.sort((a, b) {
      // Safely parse taskPriority, defaulting to 2 if missing or invalid
      int priorityA = int.tryParse(a['taskPriority']?.toString() ?? '2') ?? 2;
      int priorityB = int.tryParse(b['taskPriority']?.toString() ?? '2') ?? 2;

      // Compare priorities first, ascending order:
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // Safely parse createAt, defaulting to the current time if missing or invalid
      DateTime dateTimeA =
          DateTime.tryParse(a['createAt']?.toString() ?? '') ?? DateTime.now();
      DateTime dateTimeB =
          DateTime.tryParse(b['createAt']?.toString() ?? '') ?? DateTime.now();

      // If priorities are the same, compare the dates:
      return dateTimeA.compareTo(dateTimeB); // Ascending order by date
    });

    return list;
  }

  // Function to filter items based on search input:
  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    return items.where((item) {
      // Convert all the item names to string and lower case:
      final itemName = item['taskName']?.toString().toLowerCase() ?? '';
      // Checks if the string contains the search text:
      return itemName.contains(
          searchQuery.toLowerCase()); // Convert the searchQuery to lower case
    }).toList(); // Finally, canvert all the names to a list
  }
}
