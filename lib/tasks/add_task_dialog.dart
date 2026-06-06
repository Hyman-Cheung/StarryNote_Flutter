import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/manager/task_manager.dart';
import 'notification/notification_service.dart';
import '../tasks/tasks_provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/custom_dropdown_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker.dart';
import '../widgets/items_list.dart';
import '../widgets/prompt.dart';
import '../widgets/switch_button.dart';
import '../widgets/time_picker.dart';
import 'package:timezone/data/latest.dart' as tz;

// A class for adding task information:
class AddTaskDialog extends StatefulWidget {
  @override
  AddTaskDialogState createState() => AddTaskDialogState();
}

// A class for creating a pop-up winow to add tasking information:
class AddTaskDialogState extends State<AddTaskDialog> {
  // Some variables for holding the data from the pop-up window:
  final TextEditingController taskControllerTaskName = TextEditingController();
  final TextEditingController taskControllerTaskVenue = TextEditingController();
  final TextEditingController taskControllerTaskTime = TextEditingController();
  final TextEditingController taskControllerTaskDescription =
      TextEditingController();
  int taskPriority = 0;
  // Some variables for notification:
  DateTime scheduledDate = DateTime.now().add(const Duration(minutes: 1));
  bool isRepeating = false;
  Duration? repeatInterval = Duration(minutes: 1);
  TextEditingController notificationTextController = TextEditingController();
  DateTime? notificationDate = DateTime.now();
  TimeOfDay? notificationTime = TimeOfDay.now();
  // Initialize the NotificationService：
  NotificationService notificationService = NotificationService();
  // Initialize state and is called when the state object is created:
  @override
  void initState() {
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();
    // Initialize timezone data:
    tz.initializeTimeZones();
    // Initialize notification service:
    _initializeNotificationService();
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
                        // The Done button for comfirming the task information
                        TextButton(
                          // Call the function to store the data into database file:
                          onPressed: () => {
                            if (taskControllerTaskName.text.trim().isEmpty)
                              {
                                // Show the prompt:
                                Prompt.show(
                                    context, 'Please enter the task name!')
                              }
                            else
                              {
                                // Store the data into database file and task provider:
                                _storeTask(
                                    context,
                                    taskProvider.selectedDate,
                                    taskControllerTaskTime.text,
                                    taskControllerTaskName.text,
                                    taskControllerTaskVenue.text,
                                    taskControllerTaskDescription.text,
                                    taskPriority,
                                    isRepeating
                                        ? 1
                                        : 0), // Get the int(0 or 1) according to isRepeating variable
                              }
                          },
                          // Change button color when above button:
                          style:
                              TextButton.styleFrom(overlayColor: Colors.amber),
                          child: Text(
                            'Done',
                            // Button style:
                            style: TextStyle(color: Colors.amber, fontSize: 20),
                          ),
                        ),
                        // Title:
                        Text(
                          'Add Task',
                          // Title style:
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        // Close button(X):
                        IconButton(
                            onPressed: () async {
                              // Show comfirmation message to ask user saving data:
                              _comfirmationAndSave(
                                  context, taskProvider.selectedDate);
                            },
                            icon: Icon(Icons.close))
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
                          readOnly: false,
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
                              TimeOfDay? taskTime =
                                  await TimePicker().selectTime(context, false);
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
                          readOnly: false,
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
                          readOnly: false,
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
                            readOnly: false,
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
                            readOnly: false,
                            isSelected: isRepeating,
                            onChanged: (newState) {
                              setState(() {
                                // Update the state of the switch button:
                                isRepeating = newState;
                                // Empty the notificationTextController (The notification date on the text bar):
                                notificationTextController.text = '';
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
                            readOnly: false,
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
                            controller: notificationTextController,
                            labelText: 'Early Reminder',
                            maxLines: 1,
                            readOnly: true,
                            icon: Icon(Icons.notifications_on_outlined),
                            onTap: () {
                              _selectNotificationDate(context);
                            },
                          )
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
  Future<void> _selectNotificationDate(BuildContext context) async {
    // Select date:
    notificationDate = await DatePicker().selectDate(this.context, false);
    // Check if the widget is still mounted before using the context:
    if (!mounted) return;
    // Select time:
    notificationTime = await TimePicker().selectTime(this.context, false);
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
      notificationTextController.text =
          '${notificationDate!.day}-${notificationDate!.month}-${notificationDate!.year}   ${notificationTime!.format(context)}';
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

      Prompt.show(context, errorMessage);
      return false;
    }
  }

  // Store the data from the pop-up window:
  void _storeTask(
      BuildContext context,
      DateTime tDate,
      String tTime,
      String tName,
      String tVenue,
      String tDescription,
      int tPriority,
      int isRepeatingInt) async {
    // Store the task information into the database file and assign it to a variable:
    final task = await TaskManager.instance.insert(tDate.toString(), tTime,
        tName, tVenue, tDescription, tPriority, isRepeatingInt);

    // Check if the widget is still mounted before using the context:
    if (!context.mounted) return;

    // Add the task information into Task Provider:
    if (task != null) {
      Provider.of<TaskProvider>(context, listen: false).addTask(task);
    }
    // Close the window:
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    // Set the early reminder when user choose the repeating reminder:
    if (isRepeatingInt == 1) {
      // Set the repeating reminder:
      scheduledDate = tDate;
      _setReminder(tDate, tTime, tName, tVenue, task?['id']);
    }
    // Set the early reminder when user choose the one-time reminder:
    if (notificationTextController.text.isNotEmpty) {
      // Set the early reminder:
      _setReminder(tDate, tTime, tName, tVenue, task?['id']);
    }
  }

  // A function for setting early reminder:
  Future<void> _setReminder(DateTime taskDate, String taskTime, String taskName,
      String taskVenue, int tid) async {
    // Generate notification id:
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
    // Check if the widget is still mounted before using the context:
    if (mounted) {
      // Up date the state of the notification data:
      setState(() {
        scheduledDate = DateTime.now().add(const Duration(minutes: 1));
        isRepeating = false;
        repeatInterval = null;
      });
    }
  }

  // A function for closing the dailog and showing the comfirmation message:
  void _comfirmationAndSave(BuildContext context, DateTime selectedDate) async {
    print('********** Comfirmation And Save **********');
    // Check whether the user has entered any task information:
    if (taskControllerTaskName.text.isNotEmpty ||
        taskControllerTaskTime.text.isNotEmpty ||
        taskControllerTaskVenue.text.isNotEmpty ||
        taskControllerTaskDescription.text.isNotEmpty ||
        notificationTextController.text.isNotEmpty ||
        taskPriority != 0 ||
        repeatInterval != Duration(minutes: 1) ||
        isRepeating) {
      // If user has not entered any task information, ask whether the user want to save it:
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
          // Store the data into database file and task provider and set up the notification:
          _storeTask(
              context,
              selectedDate,
              taskControllerTaskTime.text,
              taskControllerTaskName.text,
              taskControllerTaskVenue.text,
              taskControllerTaskDescription.text,
              taskPriority,
              isRepeating ? 1 : 0);
        } else {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // If task name is empty, show the prompt:
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
      // If user did not enter any data, Close the dialog:
      Navigator.of(context).pop();
    }
    print('********** Comfirmation And Save (end)**********\n\n\n');
  }
}
