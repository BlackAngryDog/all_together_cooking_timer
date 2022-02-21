import 'dart:async';

import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';
import 'package:flutter/material.dart';

class TimerAlert extends StatefulWidget {
  final TimerGroup _currMeal;
  const TimerAlert(this._currMeal, {Key? key}) : super(key: key);

  @override
  _TimerAlertState createState() => _TimerAlertState();
}

class _TimerAlertState extends State<TimerAlert> {
  late Stream stream;
  late String nextTime;
  late String nextEvent;

  late StreamSubscription streamSubscription;

  @override
  void initState() {
    super.initState();

    streamSubscription = timerGroupUpdateEvent.stream.listen((event) {
      updateTime();
    });
    updateTime();
  }

  void updateTime() {
    setState(() {
      nextEvent = widget._currMeal.getNextAction();
      nextTime = widget._currMeal.getNextActionTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                nextEvent,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                nextTime,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              TextButton(
                  child: const Text('Dismiss'),
                  onPressed: () {
                    SoundManager.stop();
                    streamSubscription.cancel();
                    Navigator.of(context).pop();
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
