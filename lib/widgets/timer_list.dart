import 'package:all_together_cooking_timer/main.dart';
import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';
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

  void timerUpdate(TimerGroup meal) {
    setState(() {
      _timer = FormatDuration.format(meal.getTotalTimeLeft());
    });

    if (SoundManager.isPlaying && !_sfxOpen) {
      openSoundPlaying();
      _sfxOpen = true;
    }

    if (_sfxOpen == true && !SoundManager.isPlaying) _sfxOpen = false;

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
    });
  }

  void onTimerAdded(TimerItem newTimer) {
    widget._currMeal.addTimer(newTimer);
    timerUpdate(widget._currMeal);
  }

  void addItemPressed(BuildContext ctx, TimerItem timer) {
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
  }

  void openSoundPlaying() {
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
              child: TextButton(
                  child: const Text('Dismiss'),
                  onPressed: () {
                    SoundManager.stop();
                    Navigator.of(context).pop();
                  }),
            ),
            onTap: () {
              SoundManager.stop();
              Navigator.of(context).pop();
            },
            behavior: HitTestBehavior.opaque,
          );
        });
  }

  void testSheet() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
        backgroundColor: Colors.black,
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'Enter your address',
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: TextField(
                      decoration: InputDecoration(hintText: 'adddrss'),
                      autofocus: true,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ));
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
                      return Card(
                        child: ListTile(
                          title: Text(
                            widget._currMeal.ingredients[index].title,
                          ),
                          subtitle: Text(
                            widget._currMeal.ingredients[index].getTimerText(),
                          ),
                          trailing: widget._currMeal.hasStarted
                              ? Visibility(
                                  visible: widget
                                      ._currMeal.ingredients[index].paused,
                                  child: IconButton(
                                    onPressed: () {
                                      widget._currMeal.ingredients[index]
                                          .resume();
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                  ),
                                )
                              : Visibility(
                                  visible: !widget._currMeal.hasStarted,
                                  child: SizedBox(
                                    width: 100,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            addItemPressed(
                                              ctx,
                                              widget
                                                  ._currMeal.ingredients[index],
                                            );
                                          },
                                          icon: const Icon(Icons.timer),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _onDeletePressed(
                                              widget
                                                  ._currMeal.ingredients[index],
                                            );
                                          },
                                          icon: const Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      );
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
