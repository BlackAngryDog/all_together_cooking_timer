import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:all_together_cooking_timer/firebase_config.dart';
import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/pages/timer_list_page.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/widgets/timer_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterfire_ui/auth.dart';
import 'model/timer_group.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
final ReceivePort port = ReceivePort();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        name: 'att', options: DefaultFirebaseConfig.platformOptions);
  } else {
    Firebase.app();
  }

  FirebaseDatabase.instance.goOnline();

  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );

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
            GoogleProviderConfiguration(
              clientId:
                  '755183037009-8an2dsurj1fb0lsl3er6eadv29a5e9v7.apps.googleusercontent.com',
            ),
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

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          _finishedLoading
              ? TimerHome(_currMeal, key: timerHomeKey)
              : SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
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
    );
  }
}
