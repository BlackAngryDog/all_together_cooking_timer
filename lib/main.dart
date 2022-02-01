import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';
import 'package:all_together_cooking_timer/widgets/timer_list.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  final TimerGroup _currMeal = TimerGroup();
  final timerHomeKey = GlobalKey<TimerHomeState>();

  _MyHomePageState() {
    _initState();
  }

  void _initState() {
    _currMeal.addTimer(TimerItem(
        "Sausages", const Duration(minutes: 1, seconds: 0), Duration.zero));
    _currMeal.addTimer(TimerItem(
        "Chips",
        const Duration(minutes: 0, seconds: 15),
        const Duration(minutes: 0, seconds: 15)));
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: TimerHome(_currMeal, key: timerHomeKey),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Visibility(
            visible: !_currMeal.isRunning,
            child: FloatingActionButton(
              onPressed: () => timerHomeKey.currentState!.addItemPressed(
                context,
                TimerItem('_title', Duration.zero, Duration.zero),
              ),
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ),
          FloatingActionButton(
            onPressed: () => {
              setState(() {
                if (!_currMeal.isRunning) {
                  _currMeal.StartTimer(timerHomeKey.currentState!.timerUpdate);
                } else {
                  _currMeal.PauseTimer();
                }
              }),
            },
            tooltip: 'Start',
            child: _currMeal.isRunning
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
