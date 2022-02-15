import 'package:all_together_cooking_timer/firebase_config.dart';
import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/pages/timer_list_page.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/widgets/timer_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'model/timer_group.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        name: 'att', options: DefaultFirebaseConfig.platformOptions);
  } else {
    Firebase.app();
  }

  FirebaseDatabase.instance.goOnline();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    loadData();

    NotificationManager.initNotifications();
  }

  Future<void> loadData() async {
    var data = await TimerDao().getTimerGroupQuery().get();
    var dataList = data.children.toList();

    _currMeal = dataList.isEmpty
        ? TimerGroup()
        : TimerGroup.fromJson(
            dataList.first.key, dataList.first.value as Map<dynamic, dynamic>);

    _currMeal.loadTimers();
    _currMeal.onTimerAdded = () {
      setState(() {
        TimerDao().saveTimerGroup(_currMeal);
      });
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    bool nextState = state == AppLifecycleState.resumed;

    // TODO - CAN I ADD AND CANCEL NOTIFICATIONS HERE TO STOP POPUPS WHILE APP OPEN
    //if (nextState) {
    //  NotificationManager.stopAllNotifications();
    //} else if (!nextState && NotificationManager.isInForeground) {
    //  _currMeal.initialiseNotifications();
    //}

    print('state = ${state.toString()}');
    NotificationManager.stopAllNotifications();
    NotificationManager.displayDelayedFullscreen(const Duration(seconds: 10),
        "wake app", "tap to wake ${state.toString()}");

    NotificationManager.isInForeground = nextState;
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    print("disposed");
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
          TimerHome(_currMeal, key: timerHomeKey),
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
                  onPressed: () => timerHomeKey.currentState!.addItemPressed(
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
                        _currMeal.StartTimer(
                            timerHomeKey.currentState!.timerUpdate);
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
