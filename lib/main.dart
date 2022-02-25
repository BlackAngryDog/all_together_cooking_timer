import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:all_together_cooking_timer/TestForground.dart';
import 'package:all_together_cooking_timer/firebase_config.dart';
import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/pages/timer_list_page.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';
import 'package:all_together_cooking_timer/widgets/timer_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutterfire_ui/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/timer_group.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
final ReceivePort port = ReceivePort();
const batteryChannel =
    MethodChannel('com.blackAngryDog.allTogetherTimer/battery');

//void main() => runApp(const ExampleApp());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        name: 'att', options: DefaultFirebaseConfig.platformOptions);
  } else {
    Firebase.app();
  }
  // FacebookSdk.sdkInitialize();
  FirebaseDatabase.instance.goOnline();

  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );

  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "flutter_background example app",
    notificationText:
        "Background notification for keeping the example app running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'ic_launcher',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  bool success =
      await FlutterBackground.initialize(androidConfig: androidConfig);
  //FlutterBackground.enableBackgroundExecution();
  runApp(const MyApp());
  int helloAlarmID = 0;
}

void printHello() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
  //NotificationManager.displayDelayedFullscreen(
  //    Duration(seconds: 20), "test wakup", "test wakup message");

  NotificationManager.displayFullscreen("test", "update");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static int currElapsedSeconds = 0;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'QuickSand',
        textTheme: ThemeData.light().textTheme.copyWith(
              headline6: TextStyle(
                fontFamily: 'QuickSand',
                fontSize: 6,
                fontWeight: FontWeight.bold,
              ),
              bodyText1: TextStyle(
                fontFamily: 'QuickSand',
                fontSize: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey)
            .copyWith(
                primary: Colors.blueGrey[300],
                secondary: Colors.teal[200],
                brightness: Brightness.light),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not signed in
        if (!snapshot.hasData) {
          return const SignInScreen(providerConfigs: [
            EmailProviderConfiguration(),
          ]);
        }

        // Render your application if authenticated
        return const MyHomePage(title: 'All Together - Cooking Timer');
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  TimerGroup _currMeal = TimerGroup();
  final timerHomeKey = GlobalKey<TimerHomeState>();

  bool _finishedLoading = false;

  @override
  void initState() {
    super.initState();

    // Register for events from the background isolate. These messages will
    // always coincide with an alarm firing.
    port.listen((_) async => await _incrementCounter());

    WidgetsBinding.instance!.addObserver(this);

    loadData();

    NotificationManager.initNotifications();
  }

  Future<void> _incrementCounter() async {
    NotificationManager.displayFullscreen("test", "increment");
  }

  // The background
  static SendPort? uiSendPort;

  // The callback for our alarm
  static Future<void> callback() async {
    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);

    NotificationManager.displayFullscreen("test", "callback");
  }

  Future<void> loadData() async {
    var data = await TimerDao().getTimerGroupQuery().get();
    var dataList = data.children.toList();

    _currMeal = dataList.isEmpty
        ? TimerGroup()
        : TimerGroup.fromJson(
            dataList.first.key, dataList.first.value as Map<dynamic, dynamic>);

    await _currMeal.loadTimers();
    await _currMeal.loadState();

    timerGroupOnAddedEvent.stream.listen((event) {
      setState(() {
        TimerDao().saveTimerGroup(_currMeal);
      });
    });

    setState(() {
      _finishedLoading = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    bool nextState = state == AppLifecycleState.resumed;

    // TODO - CAN I ADD AND CANCEL NOTIFICATIONS HERE TO STOP POPUPS WHILE APP OPEN
    if (nextState) {
      NotificationManager.stopAllNotifications();
    } else if (!nextState && NotificationManager.isInForeground) {
      _currMeal.initialiseNotifications();
    }

    //print('state = ${state.toString()}');
    //NotificationManager.stopAllNotifications();
    //NotificationManager.displayDelayedFullscreen(const Duration(seconds: 20),
    //   "wake app", "tap to wake ${state.toString()}");

    NotificationManager.isInForeground = nextState;

    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  String _batteryLevel = 'Unknown battery level.';
  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await batteryChannel.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return WillStartForegroundTask(
      onWillStart: () async {
        // Return whether to start the foreground service.
        await FlutterForegroundTask.saveData(
            key: "total_time", value: _currMeal.getTotalTime().inSeconds);
        await FlutterForegroundTask.saveData(
            key: "curr_elapsed", value: _currMeal.elapsed.inSeconds);

        return _currMeal.isRunning;
      },
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: '0',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        priority: NotificationPriority.DEFAULT,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        autoRunOnBoot: true,
        allowWifiLock: false,
      ),
      printDevLog: false,
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(_batteryLevel),
        ),
        body: Column(
          children: [
            _finishedLoading
                ? TimerHome(_currMeal, key: timerHomeKey)
                : SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height / 2,
                    child: Center(child: CircularProgressIndicator())),
          ],
        ),
        floatingActionButton: Card(
          elevation: 55,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: FloatingActionButton(
                    onPressed: () => timerHomeKey.currentState!.editItemPressed(
                      context,
                      TimerItem('_title', Duration.zero, Duration.zero),
                    ),
                    tooltip: 'Increment',
                    child: const Icon(
                      Icons.add,
                    ),
                    heroTag: "btn1",
                  ),
                ),
                SizedBox(
                  width: 65,
                  height: 65,
                  child: FloatingActionButton(
                    onPressed: () => {
                      setState(() {
                        // DeviceApps.openAppSettings(
                        //    'com.blackAngryDog.allTogetherTimer');
                        // _getBatteryLevel();
                        if (_currMeal.isFinished) {
                          _currMeal.restartTimer();
                        } else if (!_currMeal.isRunning) {
                          _currMeal.StartTimer();
                        } else {
                          _currMeal.pauseTimer();
                        }
                      }),
                    },
                    tooltip: 'Start',
                    child: _currMeal.isRunning
                        ? (_currMeal.isFinished
                            ? const Icon(Icons.restart_alt_rounded)
                            : const Icon(Icons.pause))
                        : const Icon(Icons.play_arrow),
                    heroTag: "btn2",
                  ),
                ),
                Visibility(
                  visible: !_currMeal.isRunning,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: FloatingActionButton(
                    onPressed: () => {
                      setState(() {
                        if (_currMeal.hasStarted) {
                          _currMeal.restartTimer();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TimerSelector(_currMeal)),
                          );
                        }
                      }),
                    },
                    tooltip: 'Increment',
                    heroTag: "btn3",
                    child: _currMeal.hasStarted
                        ? const Icon(Icons.restart_alt_rounded)
                        : const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  // The callback function should always be a top-level function.

}

void startCallback() async {
  // The setTaskHandler function must be called to handle the task in the background.
  /* final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  int secondsElapsed = prefs.getInt('elapsed') ?? 0;*/
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  int updateCount = 0;
  int secondsElapsed = 0;
  int totalTime = 0;
  late DateTime startTime;

  late Duration elapsed = Duration.zero;
  late Duration total = Duration.zero;

  // static const batteryChannel =
  //    MethodChannel('com.blackAngryDog.allTogetherTimer/battery');

  bool hasPlayedSound = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    final int time = (prefs.getInt('start_time') ?? 0);

    startTime =
        time == 0 ? DateTime.now() : DateTime.fromMicrosecondsSinceEpoch(time);
    secondsElapsed = prefs.getInt('elapsed') ?? 0;

    totalTime =
        await FlutterForegroundTask.getData<int>(key: "total_time") ?? 0;
    elapsed = Duration(seconds: secondsElapsed);
    total = Duration(seconds: totalTime);
    // WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    Duration increment = timestamp.difference(startTime);
    //elapsed += increment;
    int progress = total.inMilliseconds == 0
        ? 0
        : (((elapsed + increment).inMilliseconds / total.inMilliseconds) * 100)
            .round();

    String notificationText =
        FormatDuration.format(total - (elapsed + increment));

    //notificationText = group?.getTotalTimeLeft()?.toString()!

    FlutterForegroundTask.updateService(
        notificationTitle: 'AllTogetherTimer',
        notificationText: notificationText);

    // Send data to the main isolate.
    sendPort?.send(timestamp);
    // TODO - PLAY SOUNDS - ON EVENTS?
    print("progresssss : $progress ${SoundManager.isPlaying}");
    if (!hasPlayedSound && !SoundManager.isPlaying && progress >= 100) {
      SoundManager.play();
      hasPlayedSound = true;
      //DeviceApps.openApp('com.blackAngryDog.allTogetherTimer');
      //FlutterForegroundTask.wakeUpScreen();
    }
    // TODO SETUP BUTTONS - HIDE?
  }

  void onButtonPressed(String id) async {
    print("stop : ");
    SoundManager.stop();
    hasPlayedSound = true;
    FlutterForegroundTask.stopService();

    // Intent intent = Intent;

    //   ..action = 'android.intent.action.VIEW'
    //  ..url = 'http://flutter.io/';
    //activity.startActivity(intent);

    final result = await batteryChannel.invokeMethod('getBatteryLevel');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    SoundManager.stop();
    await FlutterForegroundTask.clearAllData();
  }
}

void updateCallback() {
  FlutterForegroundTask.setTaskHandler(SecondTaskHandler());
}

class SecondTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
        notificationTitle: 'SecondTaskHandler',
        notificationText: timestamp.toString());

    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
