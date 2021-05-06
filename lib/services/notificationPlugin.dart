import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';

class NotificationPlugin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var initializationSettings;
  //object fro notifications
  final BehaviorSubject<RecievedNotification> didReceiveNotificationSubject =
      BehaviorSubject<RecievedNotification>();

  NotificationPlugin._() {
    init();
  }

  void init() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isIOS) {
      _requestIOSPermission();
    }
    initializePlatformSpecifics();
  }

  //this function is only for android not for the ios
  _requestIOSPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        .requestPermissions(
          alert: false,
          badge: true,
          sound: true,
        );
  }

  //initalize the platforms
  initializePlatformSpecifics() {
    var initializationSettingsAndroid = AndroidInitializationSettings(
      'codex_logo',
    );
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // your call back to the UI
        RecievedNotification receivedNotification = RecievedNotification(
            id: id, title: title, body: body, payload: payload);
        didReceiveNotificationSubject.add(receivedNotification);
      },
    );
    initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) async {
        print("___ oayload is $payload");
      },
    );
  }

  //listen to the notifications
  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceiveNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  //on notification clicking
  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
      onNotificationClick(payload);
    });
  }

  Future<void> showNotification() async {
    var testTime = DateTime.now().add(Duration(seconds: 5));
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      "CHANNEL_DESCRIPTION",
      importance: Importance.Max,
      priority: Priority.High,
      playSound: true,
      timeoutAfter: 5000,
      sound: RawResourceAndroidNotificationSound("a_long_cold_sting"),
      styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails(
      sound: "a_long_cold_sting",
    );
    var platformChannelSpecifics =
        NotificationDetails(androidChannelSpecifics, iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Test Title',
      'Test Body', //null
      testTime, platformChannelSpecifics,
      payload: 'New Payload',
    );
  }

  Future<void> repeatNotification(
    int id,
    String title,
    String description,
  ) async {
    //print("called");
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID 3',
      'CHANNEL_NAME 3',
      "CHANNEL_DESCRIPTION 3",
      sound: RawResourceAndroidNotificationSound("a_long_cold_sting"),
      importance: Importance.Max,
      priority: Priority.High,
      styleInformation: DefaultStyleInformation(true, true),
      timeoutAfter: 5000,
    );
    var iosChannelSpecifics = IOSNotificationDetails(
      sound: "a_long_cold_sting",
    );
    var platformChannelSpecifics =
        NotificationDetails(androidChannelSpecifics, iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      '$title',
      '$description',
      RepeatInterval.EveryMinute,
      platformChannelSpecifics,
      payload: 'Test Payload',
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin
        .cancel(id)
        .then((value) => print("alarm removed succusfully"));
  }

  Future<bool> setAlarm(int hour, int minute, String alarmName,
      String alarmDescription, int id) async {
    try {
      var time = Time(
        hour,
        minute,
        0,
      );
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'repeatDailyAtTime channel id',
        'repeatDailyAtTime channel name',
        'repeatDailyAtTime description',
        sound: RawResourceAndroidNotificationSound("a_long_cold_sting"),
        importance: Importance.Max,
        priority: Priority.High,
        styleInformation: DefaultStyleInformation(true, true),
        timeoutAfter: 60000,
      );
      var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        sound: "a_long_cold_sting",
        presentSound: true,
      );
      var platformChannelSpecifics = NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.showDailyAtTime(
        id, // has to change
        '$alarmName',
        '$alarmDescription',
        time,
        platformChannelSpecifics,
      );
      print("alarm added sucussfully");
      return true;
    } catch (e) {
      print("Set alarm failed $e");
      return false;
    }
  }

  Future<bool> setRemainder(int hour, int minute, String alarmName,
      String alarmDescription, int id, DateTime t) async {
    try {
      var time = Time(
        hour,
        minute,
        0,
      );
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'repeatDailyAtTime channel id',
        'repeatDailyAtTime channel name',
        'repeatDailyAtTime description',
        sound: RawResourceAndroidNotificationSound("a_long_cold_sting"),
        importance: Importance.Max,
        priority: Priority.High,
        styleInformation: DefaultStyleInformation(true, true),
        timeoutAfter: 60000,
      );
      var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        sound: "a_long_cold_sting",
        presentSound: true,
      );
      var platformChannelSpecifics = NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.schedule(
          id, // has to change
          '$alarmName',
          '$alarmDescription',
          t,
          platformChannelSpecifics,
          payload: "My Alarm");
      print("alarm added sucussfully");
      return true;
    } catch (e) {
      print("Set alarm failed $e");
      return false;
    }
  }
}

NotificationPlugin notificationPlugin = NotificationPlugin._();

class RecievedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  RecievedNotification({this.id, this.title, this.body, this.payload});
}
