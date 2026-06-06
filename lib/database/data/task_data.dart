class TaskData {
  // Felids:
  final int taskid;
  final String taskDate;
  final String taskTime;
  final String taskName;
  final String taskVenue;
  final String taskDescription;
  final int taskPriority;
  final int isRepeating;
  final String createAt;
  final String lastEditTime;

  // Costructor:
  TaskData(
      {required this.taskid,
      required this.taskDate,
      required this.taskTime,
      required this.taskName,
      required this.taskVenue,
      required this.taskDescription,
      required this.taskPriority,
      required this.isRepeating,
      required this.createAt,
      required this.lastEditTime});
  // A method for maping ithe object to the database format:
  Map<String, dynamic> toMap() {
    return {
      'id': taskid,
      'taskDate': taskDate,
      'taskTime': taskTime,
      'taskName': taskName,
      'taskVenue': taskVenue,
      'taskDescription': taskDescription,
      'taskPriority': taskPriority,
      'isRepeating': isRepeating,
      'createAt': createAt,
      'lastEditTime': lastEditTime
    };
  }

  // To String Method:
  @override
  String toString() {
    return 'TaskData{id: $taskid, taskDate: $taskDate, taskTime: $taskTime, taskName: $taskName, taskVenue: $taskVenue, taskDescription: $taskDescription, taskPriority: $taskPriority, isRepeating: $isRepeating, createAt: $createAt, lastEditTime: $lastEditTime}';
  }
}
