import 'dart:io';
import 'dart:math';

import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationManager {
  static Duration reminderTime = Duration(seconds: 10);

  static Future<void> initNotifications() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    const MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectedNotification);

    bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<NotificationAppLaunchDetails?> getNotificationsDetails() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        !kIsWeb && Platform.isLinux
            ? null
            : await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails();

    return notificationAppLaunchDetails;
    //String initialRoute = HomePage.routeName;
    //if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    //  selectedNotificationPayload = notificationAppLaunchDetails!.payload;
    //  initialRoute = SecondPage.routeName;
    // }
  }

  static void onSelectedNotification(String? payload) {
    print('received notification $payload');
  }

  static int channel = 1;
  static bool isInForeground = true;

  static Future<void> displayProgress(
      String title, String body, int _percent) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (isInForeground) {
      //await flutterLocalNotificationsPlugin.cancel(0);
      // return;
    }

    //

    // if (isInForeground) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bad1',
      'progress',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: false,
      sound: null,
      ongoing: true,
      maxProgress: 100,
      progress: _percent,
      showProgress: true,
      onlyAlertOnce: true,
      icon: null,
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  static Future<void> displayUpdate(
      String title, String body, TimerGroup group) async {
    //return;
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    // await flutterLocalNotificationsPlugin.cancel(0);
    // if (isInForeground) {
    //  await flutterLocalNotificationsPlugin.cancel(0);
    //   return;
    // }
    //if (!isInForeground) {
    //displayFullscreen(title, body);

    //  }

    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));

    var whenTime = tz.TZDateTime.now(tz.local).add(group.getTotalTime());
    //var whenTime = DateTime.now().add(group.getTotalTime());
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('bad2', 'update',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            playSound: true,
            fullScreenIntent: true,
            ongoing: true,
            usesChronometer: true,
            when: whenTime.millisecondsSinceEpoch,
            showWhen: true,
            icon: null);
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin
        .show(1, title, body, platformChannelSpecifics, payload: 'item x');
  }

  static Future<void> displayFullscreen(String title, String message) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    print("setting notification for $title to $message");

    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
    channel++;
    await flutterLocalNotificationsPlugin.zonedSchedule(
        channel,
        title,
        message,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: 1)),
        NotificationDetails(
            android: AndroidNotificationDetails(
          'full screen channel id',
          'full screen channel name',
          channelDescription: 'full screen channel description',
          priority: Priority.high,
          importance: Importance.high,
          fullScreenIntent: true,
          groupKey: "delayed",
          groupAlertBehavior: GroupAlertBehavior.all,
          setAsGroupSummary: true,
          showWhen: false,
        )),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  static Future<int> displayDelayedFullscreen(
      Duration delay, String title, String message) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    print(
        "setting notification for $title to $message in ${FormatDuration.format(delay)}");

    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));

    var whenTime = tz.TZDateTime.now(tz.local).add(delay);
    // delay = delay - reminderTime;
    var fireTime = tz.TZDateTime.now(tz.local).add(delay);

    channel++;
    await flutterLocalNotificationsPlugin.zonedSchedule(
        channel,
        title,
        message,
        fireTime,
        NotificationDetails(
            android: AndroidNotificationDetails(
          'full screen channel id',
          'full screen channel name',
          channelDescription: 'full screen channel description',
          priority: Priority.high,
          importance: Importance.high,
          fullScreenIntent: false,
          groupKey: "delayed",
          groupAlertBehavior: GroupAlertBehavior.all,
          setAsGroupSummary: true,
          showWhen: false,
          when: whenTime.millisecondsSinceEpoch,
        )),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);

    return channel;
  }

  static void stopAllNotifications() {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.cancelAll();
  }

  static setNotification(Duration delay, String title, String message) async {
    int helloAlarmID = 0; //channel++;
    print('set timer');

    displayDelayedFullscreen(delay, title, message);
    return;
  }

  static void printHello() {
    final DateTime now = DateTime.now();
    NotificationManager.displayFullscreen("test", "update");
  }

  static void dispatchUpdate() {
    final DateTime now = DateTime.now();
    NotificationManager.displayProgress("test", "update", 50);
  }
}
