class NotificationData {
  // Felids:
  final int notificationId;
  final String notificationTitle;
  final String notificationBody;
  final String scheduledDate;
  final String intervalType;
  final String createAt;
  final String lastEditTime;
  final int taskId;

  // Costructor:
  NotificationData(
      {required this.notificationId,
      required this.notificationTitle,
      required this.notificationBody,
      required this.scheduledDate,
      required this.intervalType,
      required this.createAt,
      required this.lastEditTime,
      required this.taskId});
  // A method for maping ithe object to the database format:
  Map<String, dynamic> toMap() {
    return {
      'id': notificationId,
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'scheduledDate': scheduledDate,
      'intervalType': intervalType,
      'createAt': createAt,
      'lastEditTime': lastEditTime,
      'taskId': taskId
    };
  }

  // To String Method:
  @override
  String toString() {
    return 'NotificationData{id: $notificationId, notificationTitle: $notificationTitle, notificationBody: $notificationBody, scheduledDate: $scheduledDate, intervalType: $intervalType, createAt: $createAt, lastEditTime: $lastEditTime, taskId: $taskId}';
  }
}
