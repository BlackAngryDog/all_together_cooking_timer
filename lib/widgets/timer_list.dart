import 'dart:async';

import 'package:all_together_cooking_timer/main.dart';
import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/pages/add_timer_page.dart';
import 'package:all_together_cooking_timer/pages/timer_alert_page.dart';
import 'package:all_together_cooking_timer/pages/timer_list_page.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';
import 'package:all_together_cooking_timer/widgets/timer_list_view.dart';
import 'package:flutter/material.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';

class TimerHome extends StatefulWidget {
  final TimerGroup _currMeal;

  const TimerHome(this._currMeal, {Key? key}) : super(key: key);

  @override
  TimerHomeState createState() => TimerHomeState();
}

class TimerHomeState extends State<TimerHome> {
  String _timer = '00:00:00';
  bool _sfxOpen = false;

  late StreamSubscription streamSubscription;

  @override
  void initState() {
    super.initState();

    streamSubscription = timerGroupUpdateEvent.stream.listen((event) {
      timerUpdate(event);
    });

    timerUpdate(widget._currMeal);
  }

  void timerUpdate(TimerGroup meal) {
    setState(() {
      _timer = FormatDuration.format(meal.getTotalTimeLeft());
    });

    if (SoundManager.isPlaying && !_sfxOpen) {
      openSoundPlaying();
      _sfxOpen = true;
    }

    if (_sfxOpen == true && !SoundManager.isPlaying) _sfxOpen = false;
    return;
    NotificationManager.displayProgress(
      "Cooking",
      _timer,
      widget._currMeal.getProgress(),
    );
  }

  void _onDeletePressed(TimerItem timer) {
    setState(() {
      // TODO - add new time or update timer
      widget._currMeal.removeTimer(timer);
      //timerUpdate(widget._currMeal);
    });
  }

  void onTimerAdded(TimerItem newTimer) {
    widget._currMeal.addTimer(newTimer);
    //timerUpdate(widget._currMeal);
  }

  void editItemPressed(BuildContext ctx, TimerItem timer) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTimerPage(
                timer,
                group: widget._currMeal,
              )),
    );
    /*
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: EditTimer(onTimerAdded, timer),
            ),
            onTap: () {},
            behavior: HitTestBehavior.opaque,
          );
        });

     */
  }

  void openSoundPlaying() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TimerAlert(widget._currMeal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Card(
            elevation: 8,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget._currMeal.title),
                  Text(
                    _timer,
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  // TODO : get time to next action
                  Text("Up next: ${widget._currMeal.getNextAction()}")
                ],
              ),
            ),
          ),
          const Divider(
            height: 20,
            thickness: 1,
            indent: 40,
            endIndent: 40,
            color: Colors.lightBlue,
          ),
          Container(
            height: 400,
            child: widget._currMeal.ingredients.isEmpty
                ? Text("No Data")
                : ListView.builder(
                    itemBuilder: (ctx, index) {
                      return TimerListView(widget._currMeal,
                          widget._currMeal.ingredients[index]);
                    },
                    itemCount: widget._currMeal.ingredients.length,
                  ),
          ),
          const Divider(
            height: 20,
            thickness: 1,
            indent: 40,
            endIndent: 40,
            color: Colors.lightBlue,
          ),
        ],
      ),
    );
  }
}
