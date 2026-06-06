import 'package:flutter/material.dart';
import 'package:notes_taking_app/tasks/task_review/task_review_list.dart';
import 'package:provider/provider.dart';
import '/database/manager/notification_manager.dart';
import '/database/manager/task_manager.dart';
import 'notification/notification_service.dart';
import '/tasks/tasks_provider.dart';
import '/widgets/confirmation_dialog.dart';
import '/widgets/custom_dropdown_button.dart';
import '/widgets/custom_text_field.dart';
import '/widgets/date_picker.dart';
import '/widgets/items_list.dart';
import '/widgets/prompt.dart';
import '/widgets/switch_button.dart';
import '/widgets/time_picker.dart';
import 'package:timezone/data/latest.dart' as tz;

// A class for adding task information:
class ShowTask extends StatefulWidget {
  final Function(String, String, int, Offset) switchToPage;
  final Function closeDrawerDialog;
  final Map<String, dynamic> taskItem;
  ShowTask({
    required this.taskItem,
    required this.switchToPage,
    required this.closeDrawerDialog,
  });
  @override
  ShowTaskState createState() => ShowTaskState();
}

// A class for creating a pop-up winow to add tasking information:
class ShowTaskState extends State<ShowTask> {
  // Some variables for holding the data from the pop-up window:
  final TextEditingController taskControllerTaskName = TextEditingController();
  final TextEditingController taskControllerTaskVenue = TextEditingController();
  final TextEditingController taskControllerTaskTime = TextEditingController();
  final TextEditingController taskControllerTaskDescription =
      TextEditingController();
  int taskPriority = 0;
  int tid = 0;
  // Some variables for notification:
  DateTime scheduledDate = DateTime.now().add(const Duration(minutes: 1));
  bool isRepeating = false;
  Duration? repeatInterval = Duration(minutes: 1);
  TextEditingController notificationDateTime = TextEditingController();
  DateTime? notificationDate = DateTime.now();
  TimeOfDay? notificationTime = TimeOfDay.now();
  // Some variables for detecting whether the task data are edited:
  String initialTaskName = '';
  String initialTaskVenue = '';
  String initialTaskTime = '';
  String initialTaskDescription = '';
  int initialTaskPriority = 0;
  bool initialIsRepeating = false;
  Duration? initialRepeatInterval = Duration(minutes: 1);
  String initialNotificationDateTime = '';
  // A variable for changing the reonly mode to editing mode:
  bool readOnly = true;
// Initialize the NotificationService：
  NotificationService notificationService = NotificationService();
  // Initialize state and is called when tshe state object is created:
  @override
  void initState() {
    print('********* initState *********');
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();
    // Initialize timezone data:
    tz.initializeTimeZones();
    // Initialize notification service:
    _initializeNotificationService();
    // Update the state of the variables and assign the data to them:
    setState(() {
      // Get the seleted task:
      final task = widget.taskItem;
      // Avoid the task item is empty:
      if (task.isNotEmpty) {
        // ********** Get and update the task data **********//
        tid = task['id'];
        taskControllerTaskTime.text = task['taskTime'];
        taskControllerTaskName.text = task['taskName'];
        taskControllerTaskVenue.text = task['taskVenue'];
        taskControllerTaskDescription.text = task['taskDescription'];
        taskPriority = task['taskPriority'];
        isRepeating = (task['isRepeating'] == 1)
            ? true
            : false; // Get the bool according to task['isRepeating']
        // Get and update the early reminder date:
        _getEarlyReminder(this.context, task).then((er) {
          notificationDateTime.text = er;
          // For detecting whether the Notification Date Time are edited:
          initialNotificationDateTime = notificationDateTime.text;
        });
        // Get and update the repeat interval:
        _getInterval(task).then((ri) {
          setState(() {
            print(
                'repeatInterval(before update) in initState(): $repeatInterval');
            repeatInterval = ri;
            // For detecting whether the Repeat Interval are edited:
            initialRepeatInterval = repeatInterval;
            print(
                'repeatInterval(after update) in initState(): $repeatInterval');
          });
        });
        // ********** Get the backup task data for detecting whether the task data are edited ********** //
        initialTaskTime = taskControllerTaskTime.text;
        initialTaskName = taskControllerTaskName.text;
        initialTaskVenue = taskControllerTaskVenue.text;
        initialTaskDescription = taskControllerTaskDescription.text;
        initialTaskPriority = taskPriority;
        initialIsRepeating = isRepeating;
      }
    });
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();
  }

  // A function for nitializing notification service:
  Future<void> _initializeNotificationService() async {
    await notificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    // pop-up winow to add tasking information:
    return Dialog(
      backgroundColor: Colors.white,
      // Padding of the dailog:
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Padding(
            padding: EdgeInsets.all(20),
            child: ConstrainedBox(
              // Set the fixed size of the dialog:
              constraints: BoxConstraints(
                  maxWidth: 650, maxHeight: 600, minWidth: 650, minHeight: 600),
              child: Column(
                children: [
                  Container(
                    // The border below the title:
                    decoration: BoxDecoration(
                        border: Border(
                      bottom: BorderSide(color: Colors.black, width: 3),
                    )),
                    child: Row(
                      // Center the title and left the button:
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // The Done button for comfirming the task information
                            TextButton(
                              // An action after clicking the done button:
                              onPressed: () => {
                                setState(() {
                                  // If readOnly is true, user can click the 'Edit' button to turn readOnly to false (Allow user to edit):
                                  if (readOnly) {
                                    readOnly = false;
                                  }
                                  // When readOnly is false, user can click the 'Done' button to update the data:
                                  else {
                                    // To check whether the task name is empty:
                                    if (taskControllerTaskName.text
                                        .trim()
                                        .isEmpty) {
                                      // Show the prompt:
                                      Prompt.show(context,
                                          'Please enter the topic name!');
                                    } else {
                                      // update the data from the database file:
                                      _updateTask(
                                          context,
                                          tid,
                                          taskProvider.selectedDate.toString(),
                                          taskControllerTaskTime.text,
                                          taskControllerTaskName.text,
                                          taskControllerTaskVenue.text,
                                          taskControllerTaskDescription.text,
                                          taskPriority,
                                          isRepeating
                                              ? 1
                                              : 0); // Get the int(0 or 1) according to isRepeating variable
                                      // Update the state of all Inital data:
                                      _updateInitalData();
                                    }
                                  }
                                })
                              },
                              // Change button color when above button:
                              style: TextButton.styleFrom(
                                  overlayColor:
                                      readOnly ? Colors.black : Colors.amber),
                              child: Text(
                                // If readOnly is true, the text button will change to "Edit", otherwise it will change to "Done":
                                readOnly ? 'Edit' : 'Done',
                                // Button style:
                                style: TextStyle(
                                    // If readOnly is true, the text button will change to black color, otherwise it will change to amber color:
                                    color:
                                        readOnly ? Colors.black : Colors.amber,
                                    fontSize: 20),
                              ),
                            ),
                            SizedBox(width: readOnly ? 8 : 1),
                            // Show task review list :
                            IconButton(
                                onPressed: _showTaskReviewLisiDialog,
                                icon: Icon(Icons.menu_book)),
                          ],
                        ),
                        // Title:
                        Text(
                          'Task Information',
                          // Title style:
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            // Width space (to make the title to center):
                            SizedBox(
                              width: 35,
                            ), // Close button(X):
                            IconButton(
                                onPressed: () async {
                                  _comfirmationAndSave(
                                      context, taskProvider.selectedDate);
                                },
                                icon: Icon(Icons.close))
                          ],
                        )
                      ],
                    ),
                  ),
                  // ********** The content below the title **********//
                  Expanded(
                      child: SingleChildScrollView(
                          child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text bar for entering task name:
                        CustomTextField(
                          controller: taskControllerTaskName,
                          labelText: 'Task Name',
                          maxLines: 1,
                          readOnly: readOnly,
                          icon: Icon(null),
                          onTap: () {},
                        ),
                        // Space:
                        SizedBox(height: 30),
                        // Time Picker for selecting time:
                        CustomTextField(
                            controller: taskControllerTaskTime,
                            labelText: 'Time',
                            maxLines: 1,
                            readOnly: true,
                            icon: Icon(Icons.access_time),
                            onTap: () async {
                              TimeOfDay? taskTime = await TimePicker()
                                  .selectTime(context, readOnly);
                              // Check if the widget is still mounted:
                              if (mounted) {
                                taskControllerTaskTime.text =
                                    taskTime!.format(this.context);
                              }
                            }),
                        // Space:
                        SizedBox(height: 30),
                        // Text bar for entering task venue:
                        CustomTextField(
                          controller: taskControllerTaskVenue,
                          labelText: 'Venue',
                          maxLines: 1,
                          readOnly: readOnly,
                          icon: Icon(null),
                          onTap: () {},
                        ),
                        // Space:
                        SizedBox(height: 30),
                        // Text bar for entering task description:
                        CustomTextField(
                          controller: taskControllerTaskDescription,
                          labelText: 'Description',
                          maxLines: 13,
                          readOnly: readOnly,
                          icon: Icon(null),
                          onTap: () {},
                        ),
                        // Space:
                        SizedBox(height: 30),
                        // Task Priority
                        CustomDropdownButton(
                            title: 'Priority: ',
                            value: taskPriority,
                            items: ItemsList().priorityItems,
                            // If readOnly is true, users cannot edit the DropdownButton, otherwise they cannot edit
                            readOnly: readOnly,
                            onChanged: (newPriority) {
                              setState(() {
                                taskPriority = newPriority!;
                              });
                            }),
                        // Space:
                        SizedBox(height: 30),
                        // A switch button to choose whether sent the notification repeatly:
                        SwitchButton(
                            title: 'Repeating Reminder',
                            readOnly: readOnly,
                            isSelected: isRepeating,
                            onChanged: (newState) {
                              setState(() {
                                isRepeating = newState;
                              });
                            }),
                        //Space:
                        SizedBox(height: 30),
                        // If user selectes the Repeating Reminder, shows the dropdown button for them to select interval type:
                        if (isRepeating)
                          CustomDropdownButton(
                            title: 'Select Interval',
                            value: repeatInterval,
                            items: ItemsList().intervalItems,
                            readOnly: readOnly,
                            onChanged: (newInterval) {
                              setState(() {
                                // Check whether the Inerval type in Valid and update the state of repeatInterval:
                                if (_validIntervalType(
                                    taskProvider.selectedDate, newInterval)) {
                                  repeatInterval = newInterval;
                                }
                              });
                            },
                          ),
                        // If user didn't selectes the Repeating Reminder, shows the text bar for them to select reminder date and time (one-time reminder):
                        if (!isRepeating)
                          CustomTextField(
                            controller: notificationDateTime,
                            labelText: 'Early Reminder',
                            maxLines: 1,
                            readOnly: readOnly,
                            icon: Icon(Icons.notifications_on_outlined),
                            onTap: () {
                              _selectNotificationDate(context, readOnly);
                            },
                          ),
                        // Space:
                        SizedBox(height: 30),
                      ],
                    ),
                  ))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // A function to show DatePicker and Time TimePicker:
  Future<void> _selectNotificationDate(
      BuildContext context, bool readOnly) async {
    // Select date:
    notificationDate = await DatePicker().selectDate(this.context, readOnly);
    // Check if the widget is still mounted before using the context:
    if (!mounted) return;
    // Select time:
    notificationTime = await TimePicker().selectTime(this.context, readOnly);
    // Check if the widget is still mounted before using the context:
    if (!mounted) return;
    // Combide the date and time:
    setState(() {
      scheduledDate = DateTime(
        notificationDate!.year,
        notificationDate!.month,
        notificationDate!.day,
        notificationTime!.hour,
        notificationTime!.minute,
      );
      // Get the text format of date and time:
      notificationDateTime.text =
          '${notificationDate!.year}/${notificationDate!.month}/${notificationDate!.day}   ${notificationTime!.format(context)}';
    });
  }

  //
  void _showTaskReviewLisiDialog() {
    showDialog(
        barrierDismissible: false, // Prevents dismissal when tapping outside
        context: context,
        builder: (Context) {
          return TaskReviewList(
            taskId: widget.taskItem['id'],
            switchToPage: widget.switchToPage,
            closeDrawerDialog: () {
              Navigator.of(context).pop(); // Close the TaskReviewList dialog
              widget.closeDrawerDialog(); // Close the parent ShowTask dialog
            },
          );
        });
  }

  // Check whether the Inerval type in Valid:
  bool _validIntervalType(DateTime taskDate, Duration newInterval) {
    int difference =
        taskDate.add(Duration(days: 1)).difference(DateTime.now()).inMinutes;
    int intervalMinutes = newInterval.inMinutes;

    if (difference > intervalMinutes) {
      return true;
    } else {
      String errorMessage;

      if (intervalMinutes == 1) {
        errorMessage =
            'The duration between now and task date is smaller than 1 minute, please choose a valid interval type!';
      } else if (intervalMinutes == Duration(days: 1).inMinutes) {
        errorMessage =
            'The duration between now and task date is smaller than 1 day, please choose a valid interval type!';
      } else if (intervalMinutes == Duration(days: 7).inMinutes) {
        errorMessage =
            'The duration between now and task date is smaller than 1 week, please choose a valid interval type!';
      } else {
        errorMessage =
            'The duration between now and task date is smaller than 1 month, please choose a valid interval type!';
      }

      Prompt.show(this.context, errorMessage);
      return false;
    }
  }

  // A function to get the early reminder date:
  Future<String> _getEarlyReminder(BuildContext context, task) async {
    print('**************** Get Early Reminder ****************');
    List<Map<String, dynamic>> notifications =
        await NotificationManager.instance.getData();
    DateTime earlyReminder = DateTime.now();
    // Check whether the user selected the one-time reminder:
    if (task['isRepeating'] == 0) {
      for (var notification in notifications) {
        print('notification tid(${notification['taskId']}): tid($tid)');
        // If the task id from task table and task id from notification table is match, return the early reminder date and time:
        if (notification['taskId'] == tid) {
          earlyReminder = DateTime.parse(notification['scheduledDate']);
          if (!context.mounted) {
            return '';
          }
          // Get the early reminder time:
          String earlyReminderTime =
              TimeOfDay.fromDateTime(earlyReminder).format(context);
          // Return the early reminder date and time:
          print(
              'Reminder date and time: ${earlyReminder.day}-${earlyReminder.month}-${earlyReminder.year}  $earlyReminderTime');
          print('********** Get Early Reminder (end) **********\n\n\n');
          return '${earlyReminder.day}-${earlyReminder.month}-${earlyReminder.year}  $earlyReminderTime ';
        }
      }
      // Return notthing, if did not find the matched task id:
      print('********** Get Early Reminder (end) **********\n\n\n');
      return '';
    }
    // Return notthing, if user did ont selecte the one-time reminder:
    print('********** Get Early Reminder (end) **********\n\n\n');
    return '';
  }

  // A function to get the repeate interval date:
  Future<Duration?> _getInterval(task) async {
    print('**************** Get Interva ****************');
    List<Map<String, dynamic>> notifications =
        await NotificationManager.instance.getData();
    String intervalType = '';
    // Check whether the user selected the repeating reminder:
    if (task['isRepeating'] == 1) {
      for (var notification in notifications) {
        // If the task id from task table and task id from notification table is match, get interval type and  return related duration:
        if (notification['taskId'] == tid) {
          // Get the interval type:
          intervalType = notification['intervalType'];
          print('intervalType: $intervalType');
          // Return the Duration according to the intervalType:
          switch (intervalType) {
            case 'Every Minute':
              print('********** Get Interva (end) **********\n\n\n');
              return Duration(minutes: 1);
            case 'Daily':
              print('********** Get Interva (end) **********\n\n\n');
              return Duration(days: 1);
            case 'Weekly':
              print('********** Get Interva (end) **********\n\n\n');
              return Duration(days: 7);
            case 'Monthly':
              print('********** Get Interva (end) **********\n\n\n');
              return Duration(days: 30);
            default:
              print('********** Get Interva (end) **********\n\n\n');
              return Duration(minutes: 1); // Default to minutes
          }
        }
      }
      print('********** Get Interva (end) **********\n\n\n');
      return Duration(
          minutes: 1); // Return minutes if did not find the matched task id
    }
    print('********** Get Interva (end) **********\n\n\n');
    return Duration(
        minutes:
            1); // Return minutes if user did ont selecte the repeate reminder
  }

  // Update the data from the pop-up window:
  void _updateTask(
      BuildContext context,
      int tid,
      String tDate,
      String tTime,
      String tName,
      String tVenue,
      String tDescription,
      int tPriority,
      int isRepeatingInt) async {
    // Update the data from the database:
    final updatedTask = await TaskManager.instance.update(tid, tDate, tTime,
        tName, tVenue, tDescription, tPriority, isRepeatingInt);
    // Check if the widget is still mounted before using the context
    if (!context.mounted) return;

    // Update the data from task provider:
    if (updatedTask != null) {
      Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
    }

    // A function for updating the notifications with specific task id:
    _updateNotifications(tid, DateTime.parse(tDate), tTime, tName, tVenue,
        isRepeatingInt, updatedTask);
  }

  // A funtion for updating notifications with specific task id:
  void _updateNotifications(int tid, DateTime tDate, String tTime, String tName,
      String tVenue, int isRepeatingInt, task) {
    // Delete and cancel all the notifications with specific task id:
    NotificationService().deleteNotifications(tid);
    // Set the early reminder when user choose the repeating reminder:
    if (isRepeatingInt == 1) {
      // Set the repeating reminder:
      scheduledDate = tDate;
      _setReminder(tDate, tTime, tName, tVenue, task?['id']);
    }
    // Set the early reminder when user choose the one-time reminder:
    if (notificationDateTime.text.isNotEmpty) {
      // Set the early reminder:
      _setReminder(tDate, tTime, tName, tVenue, task?['id']);
    }
  }

  // A function for setting early reminder:
  Future<void> _setReminder(DateTime taskDate, String taskTime, String taskName,
      String taskVenue, int tid) async {
    // Generate notification id:s
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Merge date and time:
    final notificationDate = taskTime.isNotEmpty
        ? '${taskDate.day}-${taskDate.month}-${taskDate.year}($taskTime)'
        : '${taskDate.day}-${taskDate.month}-${taskDate.year}';
    // The notification body:
    final notificationTitle = 'You have to review your notes!';
    final notificationBody = taskVenue.isNotEmpty
        ? 'Task Name: $taskName \n Task Date: $notificationDate \n Venue: $taskVenue'
        : 'Task Name: $taskName \n Task Date: $notificationDate';
    // Schedule the notification:
    await notificationService.scheduleNotification(
        id: id,
        title: notificationTitle,
        body: notificationBody,
        scheduledDate: scheduledDate,
        isRepeating: isRepeating,
        repeatInterval: repeatInterval,
        taskId: tid);
  }

  // A function for closing the dailog and showing the comfirmation message:
  void _comfirmationAndSave(BuildContext context, DateTime taskDate) async {
    print('********** Comfirmation And Save **********');
    // Check whether the data are edited:
    if (initialTaskTime != taskControllerTaskTime.text ||
        initialTaskName != taskControllerTaskName.text ||
        initialTaskVenue != taskControllerTaskVenue.text ||
        initialTaskDescription != taskControllerTaskDescription.text ||
        initialTaskPriority != taskPriority ||
        initialIsRepeating != isRepeating ||
        initialNotificationDateTime != notificationDateTime.text ||
        initialRepeatInterval != repeatInterval) {
      print('--- Task Time ---');
      print(
          'initialTaskTime: $initialTaskTime \n taskControllerTaskTime.text: ${taskControllerTaskTime.text}');
      print('--- Task Name ---');
      print(
          'initialTaskName: $initialTaskName \n taskControllerTaskName.text: ${taskControllerTaskName.text}');
      print('--- Task Venue ---');
      print(
          'initialTaskVenue: $initialTaskVenue \n taskControllerTaskVenue.text: ${taskControllerTaskVenue.text}');
      print('--- Task Description ---');
      print(
          'initialTaskDescription: $initialTaskDescription \n taskControllerTaskDescription.text: ${taskControllerTaskDescription.text}');
      print('--- Task Priority ---');
      print(
          'initialTaskPriority: $initialTaskPriority \n taskPriority: $taskPriority');
      print('--- Is Repeating ---');
      print(
          'initialIsRepeating: $initialIsRepeating \n isRepeating: $isRepeating');
      print('--- Repeat Interval ---');
      print(
          'initialRepeatInterval: $initialRepeatInterval \n repeatInterval: $repeatInterval');
      print('--- Notification DateTime ---');
      print(
          '$initialNotificationDateTime \n notificationDateTime.text: ${notificationDateTime.text}');
      // If the task data are edited, ask whether the user want to save it:
      bool? confirmed = await ConfirmationDialog.show(
          context,
          'Do you want to save the content about your task?',
          'Don\'t save',
          'Save',
          false);
      // When user click save:
      if (confirmed ?? false) {
        // If user want to save the data, check whether the name is empty:
        if (taskControllerTaskName.text.isNotEmpty) {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // update the data from the database file and update the notification:
          _updateTask(
              context,
              tid,
              taskDate.toString(),
              taskControllerTaskTime.text,
              taskControllerTaskName.text,
              taskControllerTaskVenue.text,
              taskControllerTaskDescription.text,
              taskPriority,
              isRepeating ? 1 : 0);
          // Update the state of all Inital data:
          _updateInitalData();
        } else {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // If the task name is empty, show the prompt:
          Prompt.show(context, 'Please enter the task name!');
        }
      }
      // When user click Close button(X):
      else if (confirmed ?? true) {
        // Do nothing...
      }
      // When user click don't save:
      else {
        // Check if the widget is still mounted before using the context:
        if (!context.mounted) {
          return;
        }
        // Close the dialog when user click don't save:
        Navigator.of(context).pop();
      }
    } else {
      // If no task data is edited, Close the dialog:
      Navigator.of(context).pop();
    }
    print('********** Comfirmation And Save (end) **********\n\n\n');
  }

  // Update the state of all Inital data:
  void _updateInitalData() {
    setState(() {
      readOnly = !readOnly;
      initialTaskTime = taskControllerTaskTime.text;
      initialTaskName = taskControllerTaskName.text;
      initialTaskVenue = taskControllerTaskVenue.text;
      initialTaskDescription = taskControllerTaskDescription.text;
      initialTaskPriority = taskPriority;
      initialIsRepeating = isRepeating;
      initialNotificationDateTime = notificationDateTime.text;
      initialRepeatInterval = repeatInterval;
    });
  }
}
