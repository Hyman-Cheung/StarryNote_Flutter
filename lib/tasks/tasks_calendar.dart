import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '/tasks/task_dialog.dart';
import '/tasks/tasks_provider.dart';
import 'package:intl/intl.dart';
import '/widgets/prompt.dart';

// A class for showing dialog with calendar:
class TasksCalendar extends StatefulWidget {
  final Function(String, String, int, Offset) switchToPage;

  const TasksCalendar({
    required this.switchToPage,
    Key? key,
  }) : super(key: key);

  @override
  TasksCalendarState createState() => TasksCalendarState();

  // A function for showing dialog with calendar:
  void showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => TasksCalendar(
        switchToPage: switchToPage,
      ),
    );
  }
}

// A class for generating a dialog with calendar:
class TasksCalendarState extends State<TasksCalendar> {
  // Initialize state and is called when the state object is created:
  @override
  void initState() {
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();
    // Delete expired data and refresh tasks:
    Provider.of<TaskProvider>(context, listen: false)
        .deleteExpiredDataAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    // A dialog for showing calendar:
    return Dialog(
      backgroundColor: Colors.white,
      child: CalendarWidget(
        switchToPage: widget.switchToPage,
      ),
    );
  }
}

// A class for creating and handling calendar:
class CalendarWidget extends StatelessWidget {
  final Function(String, String, int, Offset) switchToPage;

  const CalendarWidget({
    required this.switchToPage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Padding(
          padding: EdgeInsets.all(23),
          child: SizedBox(
            width: 1000, // Set the width of the dialog
            height: 400, // Set the height of the dialog
            // Calendar:
            child: TableCalendar(
              // Focused Day (Current Date):
              focusedDay: taskProvider.focusedDay,
              // Range of calendar days：
              firstDay: taskProvider.firstDay,
              lastDay: taskProvider.lastDay,
              // Add event (for adding tasks into the sepcific day):
              // Receives a DateTime object (day) and returns a list of events for that day //
              eventLoader: (day) =>
                  taskProvider.tasks[day] ??
                  [], // Returns the value on its left if that value is not null
              // Marked as selected in the calendar:
              /* 
                Checks if the current day (day) being evaluated in the calendar is the same as the selected date,
                if they are the same, the day is marked as selected in the calendar 
              */
              selectedDayPredicate: (day) =>
                  isSameDay(taskProvider.selectedDate, day),
              // An action after selecting the sepcific day:
              onDaySelected: (selectedDay, focusedDay) {
                // Update the selected day and focused day (current day):
                taskProvider.selectedDate = selectedDay;
                taskProvider.focusedDay = focusedDay;
                // Check whether the selectedDay is passed:
                if ((selectedDay.add(Duration(days: 1)))
                    .isBefore(DateTime.now())) {
                  // Show the prompt:
                  Prompt.show(context,
                      'The day you selected has passed and you cannot add tasks to it!');
                } else {
                  // Show the task dialog:
                  _showTaskDialog(context);
                }
              },
              calendarBuilders: CalendarBuilders(
                // Set the sunday as red color
                dowBuilder: (context, day) {
                  if (day.weekday == DateTime.sunday) {
                    final text = DateFormat.E().format(day);
                    return Center(
                      child: Text(
                        text,
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return null;
                },
                // If the date contains one or more tasks, put a tag on the date:
                markerBuilder: (context, sDate, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      // The position of the tag:
                      bottom: 1,
                      // Call the function to generate tag:
                      child: _buildEventsMarker(
                          sDate,
                          events,
                          taskProvider.getTasksBeforeAndOnSelectedDate(
                              sDate)), // Get all tasks before and on selected date
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Create a tag with the number of tasks:
  Widget _buildEventsMarker(
      DateTime sDate, List events, List tasksBeforeAndOnSelectedDate) {
    return Container(
      decoration: BoxDecoration(
        // Shape of the tag:
        shape: BoxShape.circle,
        // Color of the tag:
        color: _analysisColor(sDate,
            tasksBeforeAndOnSelectedDate), // Get color according to the workload between selectedDate and current date
      ),
      // Size of the tag:
      width: 16.0,
      height: 16.0,
      // Content on the tag:
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  // A function for analysing the color according the workload between selectedDate and current date:
  Color _analysisColor(
      DateTime selectedDate, List tasksBeforeAndOnSelectedDate) {
    int difference = selectedDate.difference(DateTime.now()).inDays + 1;
    var workload = difference / tasksBeforeAndOnSelectedDate.length;
    // Print the selectedDate and it's workload(for debug):
    print(
        'The workload before ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}: $workload');
    // Return the color according the workload between selectedDate and current date:
    if (workload >= 0 && workload < 1) {
      // Return red if user have more than 1 task for each day:
      return Colors.red;
    } else if (workload >= 1 && workload < 3) {
      // Return orange if user have one to two days for each task:
      return Colors.orange;
    } else if (workload >= 3 && workload < 5) {
      // Return green if user have three to four days for each task:
      return Colors.green;
    } else {
      // Return black if user have more than five days for each task:
      return Colors.black;
    }
  }

  // A function for showing the dialog with task list:
  void _showTaskDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false, // Prevents dismissal when tapping outside
      context: context,
      builder: (context) {
        return TaskDialog(
          switchToPage: switchToPage,
          closeDrawerDialog: () => Navigator.pop(context),
        );
      },
    );
  }
}
