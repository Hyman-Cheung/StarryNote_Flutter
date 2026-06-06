class TaskReviewData {
  // Felids:
  final int taskReviewId;
  final String createAt;
  final String lastEditTime;
  final int taskId;
  final int labelId;

  // Costructor:
  TaskReviewData(
      {required this.taskReviewId,
      required this.createAt,
      required this.lastEditTime,
      required this.taskId,
      required this.labelId});
  // A method for maping ithe object to the database format:
  Map<String, dynamic> toMap() {
    return {
      'id': taskReviewId,
      'createAt': createAt,
      'lastEditTime': lastEditTime,
      'taskId': taskId,
      'labelId': labelId,
    };
  }

  // To String Method:
  @override
  String toString() {
    return 'TaskData{id: $taskReviewId, createAt: $createAt, lastEditTime: $lastEditTime, taskId: $taskId, labelId: $labelId}';
  }
}
