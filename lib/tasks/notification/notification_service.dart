import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../database/manager/notification_manager.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Initialization:
  Future<void> init() async {
    print('********** Initialization **********');
    // Android initialization:
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // IOS initialization:
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    // Combine details for both platforms:
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    // Initialize the plugin：
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );
    // Create notification channel for Android:
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel_id',
      'Reminders',
      description: 'Channel for reminder notifications',
      importance: Importance.high,
    );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    // Request permissions at initialization:
    await _requestPermissions();
    print('Notification service initialized');
    print('********** Initialization (end) **********\n\n\n');
  }

  // Request notification permission :
  Future<void> _requestPermissions() async {
    print('********** Request notification **********');
    print(
        'Notification permission status: ${await Permission.notification.status}');
    if (await Permission.notification.isDenied) {
      print('Requesting POST_NOTIFICATIONS permission...');
      await Permission.notification.request();
    }

    // Request exact alarm permission (Android 12+):
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    print('Exact alarm permission status: $alarmStatus');
    // When the user denied access to the requested feature:
    if (alarmStatus.isDenied) {
      print('Requesting SCHEDULE_EXACT_ALARM permission...');
      // Request the user for access to this [Permission], if access hasn't already been grant access before.
      final status = await Permission.scheduleExactAlarm.request();
      // If the user denied access to the requested feature:
      if (status.isDenied || status.isPermanentlyDenied) {
        print('Exact alarm permission denied. Opening settings...');
        // Returns [true] if the app settings page could be opened, otherwise [false].
        await openAppSettings();
        print('Please enable "Alarms & Reminders" in app settings.');
      } else {
        print('Exact alarm permission granted.');
      }
    }
    print('********** Request notification (end) **********\n\n\n');
  }

  // Get the current status of the given [Permission]:
  Future<bool> _canScheduleExactAlarms() async {
    final status = await Permission.scheduleExactAlarm.status;

    print(
        'Can schedule exact alarms (based on permission status): ${status.isGranted}');
    return status.isGranted;
  }

  // Scheduling and showing the notification:
  Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledDate,
      required bool isRepeating,
      required Duration? repeatInterval,
      required int taskId}) async {
    print('********** Schedule Notification **********');
    // Android Notification Details:
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'Notes-taking',
      'Notes-taking',
      importance: Importance.high,
      priority: Priority.high,
    );

    print('Notification service initialized Android Notification Details');
    // IOS-specific details:
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    print('Notification service initialized IOS Notification Details');
    // Combine details for both platforms:
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    // Constructs a [TZDateTime] instance from scheduled date in the specific time zones:
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    // Get the current status of the given [Permission]:
    final canUseExact = await _canScheduleExactAlarms();
    // Get the schedule mode according to the status of the given [Permission]:
    final scheduleMode = canUseExact
        ? AndroidScheduleMode
            .exactAllowWhileIdle // The notification should be scheduled to be shown at the exact time specified
        : AndroidScheduleMode
            .inexact; // The notification should be scheduled to be shown at at roughly specified time

    print('Scheduling with mode: $scheduleMode');
    // When user choosing Repeating Reminder(isRepeating) and repeat interval is not null:
    if (isRepeating && repeatInterval != null) {
      print('Setting up repeating reminder');
      // Constructs a [TZDateTime] instance with current date:
      final now = tz.TZDateTime.now(tz.local);
      // Assign the current date to startDate:
      tz.TZDateTime startDate = now;
      // Get the number of notifications:
      final numOfNotifications =
          _getNumOfNotfications(repeatInterval, tzScheduledDate, now);
      // Limit to 50:
      final limitedNotifications = numOfNotifications.clamp(1, 50);
      print('Number of notifications (limit 50): $limitedNotifications');
      // Schedule repeating notifications:
      for (int i = 1; i <= limitedNotifications; i++) {
        // The date of sending notification:
        final nextTime = startDate.add(repeatInterval * i);
        print(
            'Attempting to schedule - id:${id + i}, title: $title, body: $body, nextTime: $nextTime');
        // Schedules a notification to be shown at the specified date:
        try {
          await _notificationsPlugin.zonedSchedule(
            id + i,
            title,
            body,
            nextTime,
            notificationDetails,
            androidScheduleMode: scheduleMode,
            payload: 'Repeating Reminder #$i',
            matchDateTimeComponents: DateTimeComponents.time,
          );
          print('Scheduled reminder ${id + i} at $nextTime');
          // Store the notification data:
          _storeNotification(id + i, title, body, nextTime,
              _getIntervalType(repeatInterval), taskId);
        } catch (e) {
          print('Failed to schedule ${id + i}: $e');
          if (e is PlatformException &&
              e.code == 'exact_alarms_not_permitted') {
            print('Falling back to inexact scheduling for ${id + i}...');
            await _notificationsPlugin.zonedSchedule(
              id + i,
              title,
              body,
              nextTime,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexact,
              payload: 'Repeating Reminder #$i (Fallback)',
            );
            // Store the notification data:
            _storeNotification(id + i, title, body, nextTime,
                _getIntervalType(repeatInterval), taskId);
            print('Scheduled inexact reminder ${id + i} at $nextTime');
          } else {
            rethrow;
          }
        }
      }
    } else {
      // When user did not choose the repeating notifications:
      // Just print out the worring message, when the scheduled date is before current date:
      if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Scheduled date is in the past, cannot schedule');
        return;
      }

      print(
          'Attempting to schedule one-time - id:$id, title: $title, body: $body, time: $tzScheduledDate');
      // Schedules a notification to be shown at the specified date:
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: 'One-time Reminder',
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        print('Scheduled one-time reminder $id at $tzScheduledDate');
        // Store the notification data:
        _storeNotification(id, title, body, tzScheduledDate,
            _getIntervalType(repeatInterval), taskId);
      } catch (e) {
        print('Failed to schedule one-time notification: $e');
        if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
          print('Falling back to inexact scheduling...');
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tzScheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            payload: 'One-time Reminder (Fallback)',
          );
          print('Scheduled inexact one-time reminder $id at $tzScheduledDate');
          // Store the notification data:
          _storeNotification(id, title, body, tzScheduledDate,
              _getIntervalType(repeatInterval), taskId);
        } else {
          rethrow;
        }
      }
    }
    print('********** Schedule Notification (end) **********\n\n\n');
  }

  // A function to get the number of notifications:
  dynamic _getNumOfNotfications(
      Duration repeatInterval, DateTime tzScheduledDate, DateTime now) {
    dynamic numOfNotifications;
    if (repeatInterval == Duration(minutes: 1)) {
      numOfNotifications = tzScheduledDate.difference(now).inMinutes;
    } else if (repeatInterval == Duration(days: 1)) {
      numOfNotifications = tzScheduledDate.difference(now).inDays;
    } else if (repeatInterval == Duration(days: 7)) {
      numOfNotifications = (tzScheduledDate.difference(now).inDays) / 7;
    } else {
      numOfNotifications = (tzScheduledDate.difference(now).inDays) / 30;
    }
    return numOfNotifications;
  }

  // A function for getting interval type according the repeatInterval(Duration):
  String? _getIntervalType(repeatInterval) {
    if (repeatInterval == Duration(minutes: 1)) {
      return "Every Minute";
    } else if (repeatInterval == Duration(days: 1)) {
      return "Daily";
    } else if (repeatInterval == Duration(days: 7)) {
      return "Weekly";
    } else if (repeatInterval == Duration(days: 30)) {
      return "Monthly";
    } else {
      return null;
    }
  }

// A function for storing notification:
  void _storeNotification(int nid, String nTitle, String nBody,
      DateTime scheduledDate, String? intervalType, int tid) {
    NotificationManager.instance.insert(
        nid, nTitle, nBody, scheduledDate.toString(), intervalType!, tid);
  }

// A function for canceling the notification:
  Future<void> _cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
    print('Cancelled Notification: $id');
  }

  // A function for deleting and cancel all the notifications with specific task id:
  void deleteNotifications(int tid) async {
    print('********** Delete Notifications **********');
    print('------ The following notifications are deleted and canceled------');
    // Get all the notification data:
    final notifications = await NotificationManager.instance.getData();
    for (var notification in notifications) {
      // Check whether the specific task id matchs the task id from the notification table:
      if (notification['taskId'] == tid) {
        // Delete the notification data from the database:
        NotificationManager.instance.delete(notification);
        // Cancel the notification from the device:
        _cancelReminder(notification['id']);
        print('Task id: $tid    notification id: ${notification['id']}');
      }
    }
    print('********** Delete Notifications (end)**********\n\n\n');
  }
}

// Seting:
/* 
  Android:
    1 From android/app/build.gradle.kte:
      1.1 Change the ndkVersion = flutter.ndkVersion to compileSdk = 35:
        android {
          namespace = "com.example.label_and_calendar"
          compileSdk = flutter.compileSdkVersion
          compileSdk = 35
          }

      1.2 Chenge the content of compileOptions{}:
        compileOptions {
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        }

      1.3 Chenge the content of kotlinOptions{}:
        kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
        } 
      
      1.4 Change the content of defaultConfig{} (only change targetSdk, versionCode,and versionName):
      defaultConfig {
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
      1.5 Add flowing code below the flutter {source = "../.."}:
        dependencies {
            coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") 
            implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.20")
        }

    2. From android/app/src/main/AndroidManifest.xml:
      2.1 Add flowing code below <manifest xmlns:android="http://schemas.android.com/apk/res/android">: 
        <uses-permission android:name="android.permission.INTERNET"/>
        <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
        <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        <uses-permission android:name="android.permission.VIBRATE"/>
        <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
      2.2 Add flowing code below </activity>:
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false"/>
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>

  IOS:
    1 From ios/Runner/Info.plist:
      1.1 Add flowing code below the <dict>:
        <key>NSUserNotificationsUsageDescription</key>
        <string>This app needs to send you notifications</string>
*/
