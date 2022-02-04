import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';
import 'package:all_together_cooking_timer/widgets/timer_list.dart';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import 'package:flutter/material.dart';

import 'model/timer_group.dart';

void main() {
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
      home: const MyHomePage(title: 'All Together - Cooking Timer'),
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
  final TimerGroup _currMeal = TimerGroup();
  final timerHomeKey = GlobalKey<TimerHomeState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    _currMeal.addTimer(TimerItem(
        "Sausages", const Duration(minutes: 1, seconds: 0), Duration.zero));
    _currMeal.addTimer(TimerItem(
        "Chips",
        const Duration(minutes: 0, seconds: 15),
        const Duration(minutes: 0, seconds: 15)));

    NotificationManager.initNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    NotificationManager.isInForeground = state == AppLifecycleState.resumed;
    //print("app is in F G ${MyHomePage.isInForeground}");
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _initState() {
    //FlutterRingtonePlayer.playNotification();
  }

/*
  void selectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
    );
  }
*/
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
                        timerHomeKey.currentState!.addItemPressed(
                          context,
                          TimerItem('_title', Duration.zero, Duration.zero),
                        );
                      }
                    }),
                  },
                  tooltip: 'Increment',
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
