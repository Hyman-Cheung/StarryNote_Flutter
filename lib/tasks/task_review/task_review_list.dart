import 'package:flutter/material.dart';
import 'package:notes_taking_app/database/data/label_data.dart';
import 'package:notes_taking_app/database/manager/label_manager.dart';
import 'package:notes_taking_app/database/manager/task_manager.dart';
import 'package:notes_taking_app/database/manager/task_review_manager.dart';
import 'package:notes_taking_app/tasks/task_review/add_task_review.dart';
import '../../database/db_helper.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/custom_search_bar.dart';

// A class for displaying the task review list:
class TaskReviewList extends StatefulWidget {
  // Field:
  final int taskId;
  final Function(String, String, int, Offset) switchToPage;
  final Function closeDrawerDialog;

  // Constructor:
  TaskReviewList({
    required this.taskId,
    required this.switchToPage,
    required this.closeDrawerDialog,
  });

  @override
  TaskReviewListState createState() => TaskReviewListState();

  // A function to show the pop-up window:
  void showPopup(BuildContext context) {
    showDialog(
      barrierDismissible: false, // Prevents dismissal when tapping outside
      context: context,
      builder: (BuildContext context) => TaskReviewList(
        taskId: taskId,
        switchToPage: switchToPage,
        closeDrawerDialog: closeDrawerDialog,
      ),
    );
  }
}

class TaskReviewListState extends State<TaskReviewList> {
  late Future<List<Map<String, dynamic>>> futureTaskReviewItems;
  late List<Map<String, dynamic>> taskReviewItems = [];
  late List<Map<String, dynamic>> filteredItems = [];
  TextEditingController searchController = TextEditingController();
  late String taskName = "";
  final DBHelper dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();

    // Initialize and filter task review items for specific task:
    _loadTaskReviews();

    // Get the task name for displaying:
    getTaskById(widget.taskId).then((task) {
      if (task != null) {
        setState(() {
          taskName = task['taskName'] ?? 'Task ${widget.taskId}';
        });
      }
    });

    searchController.addListener(_filterItems);
  }

  // Load task reviews with review labels for the current task
  Future<void> _loadTaskReviews() async {
    futureTaskReviewItems = TaskReviewManager.instance.getData();

    futureTaskReviewItems.then((value) async {
      List<Map<String, dynamic>> reviewTaskReviews = [];

      for (var review in value) {
        // Only include reviews for the current task:
        if (review['taskId'] == widget.taskId) {
          // Get the associated review label:
          var label =
              await LabelManager.instance.getDataById(review['labelId']);
          if (label != null && label['labelType'] == LabelType.review.name) {
            // Get the hierarchy path for this label
            final notebookName =
                await dbHelper.readNotebookNamebyId(label['notebookId']);
            final sectionName =
                await dbHelper.readSectionNamebyId(label['sectionId']);
            final pageName = await dbHelper.readPageNamebyId(label['pageId']);

            final path = 'from $notebookName/$sectionName/$pageName';

            var reviewWithLabel = Map<String, dynamic>.from(review);
            reviewWithLabel.addAll({
              'name': label['name'],
              'priority': label['priority'],
              'pageId': label['pageId'],
              'sectionId': label['sectionId'],
              'notebookId': label['notebookId'],
              'position_x': label['position_x'],
              'position_y': label['position_y'],
              'hierarchyPath': path, // Add the hierarchy path
            });
            reviewTaskReviews.add(reviewWithLabel);
          }
        }
      }

      setState(() {
        // Update the filteredItems and taskReviewItems:
        filteredItems = reviewTaskReviews;
        taskReviewItems = reviewTaskReviews;
        // Sorts the list according to the priority and datetime:
        filteredItems = _sort(filteredItems);
        taskReviewItems = _sort(taskReviewItems);
      });
    });
  }

  // Show dialog to add new task reviews
  Future<void> _showAddTaskReviewDialog(BuildContext context) async {
    try {
      final notebooks = await dbHelper.getNotebooks();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AddTaskReview(
          notebooks: notebooks,
          taskId: widget.taskId,
        ),
      );

      if (result == true) {
        // Refresh the list if reviews were added
        _loadTaskReviews();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notebooks: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      child: Padding(
        padding: EdgeInsets.all(23),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: 650,
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _showAddTaskReviewDialog(context),
                      tooltip: 'Add new task reviews',
                    ),
                    Text(
                      'Task Review List ($taskName)',
                      style: TextStyle(
                        height: 3,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close))
                  ],
                ),
              ),
              CustomSearchBar(
                  controller: searchController,
                  labelText: 'Search by review item name'),
              Expanded(
                child: ClipRect(
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = filteredItems[index];
                      return Dismissible(
                        background: Container(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.delete, color: Colors.black),
                        ),
                        key: UniqueKey(),
                        confirmDismiss: (DismissDirection direction) async {
                          return await ConfirmationDialog.show(
                              context,
                              'Are you sure you want to delete this task review?',
                              'Cancel',
                              'Delete',
                              true);
                        },
                        onDismissed: (DismissDirection direction) {
                          setState(() {
                            Map<String, dynamic> itemToDelete = item;
                            taskReviewItems.remove(itemToDelete);
                            filteredItems.removeAt(index);
                            TaskReviewManager.instance.delete(itemToDelete);
                          });
                        },
                        direction: DismissDirection.endToStart,
                        child: ListTile(
                          title: Text(
                            item['name'],
                            style: TextStyle(color: _analysisColor(item)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            item['hierarchyPath'] ??
                                'from Unknown/Unknown/Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            // Close the dialog:
                            Navigator.of(context).pop();
                            Offset labelPosition =
                                Offset(item['position_x'], item['position_y']);
                            // switch to selected label's page and move view position to label's position
                            widget.switchToPage(
                                item['pageId'],
                                item['sectionId'],
                                item['notebookId'],
                                labelPosition);
                            widget.closeDrawerDialog();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sorts the list according to the priority and datetime:
  List<Map<String, dynamic>> _sort(List<Map<String, dynamic>> originalList) {
    List<Map<String, dynamic>> list = List.from(originalList);

    list.sort((a, b) {
      int priorityA = int.parse(a['priority'].toString());
      int priorityB = int.parse(b['priority'].toString());

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      DateTime dateTimeA = DateTime.parse(a['createAt']);
      DateTime dateTimeB = DateTime.parse(b['createAt']);
      return dateTimeA.compareTo(dateTimeB);
    });

    return list;
  }

  Color _analysisColor(Map<String, dynamic> item) {
    int itemPriority = int.parse(item['priority'].toString());
    if (itemPriority == 0) {
      return Colors.red;
    } else if (itemPriority == 1) {
      return Colors.orange;
    }
    return Colors.black;
  }

  // Function to filter items based on search input:
  void _filterItems() {
    setState(() {
      filteredItems = taskReviewItems
          .where((item) => item['name']
              .toString()
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Get task details:
  Future<Map<String, dynamic>?> getTaskById(int taskId) async {
    return await TaskManager.instance.getDataById(taskId);
  }
}
