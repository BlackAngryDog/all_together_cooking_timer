import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/pages/add_timer_page.dart';
import 'package:flutter/material.dart';

class TimerListView extends StatelessWidget {
  final TimerGroup _currMeal;
  final TimerItem _timer;

  const TimerListView(this._currMeal, this._timer, {Key? key})
      : super(key: key);

  void editItemPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTimerPage(
                _timer,
                group: _currMeal,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          _timer.title,
        ),
        subtitle: Text(
          _timer.getTimerText(),
        ),
        trailing: _currMeal.hasStarted
            ? SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        _currMeal.skipTimer(_timer);
                      },
                      icon: const Icon(Icons.fast_forward),
                    ),
                    IconButton(
                      onPressed: () {
                        _currMeal.extendTimer(_timer, Duration(minutes: 1));
                      },
                      icon: const Icon(Icons.add),
                    ),
                    Visibility(
                      visible: _timer.paused,
                      child: IconButton(
                        onPressed: () {
                          _timer.resume();
                        },
                        icon: const Icon(Icons.play_arrow),
                      ),
                    ),
                  ],
                ),
              )
            : Visibility(
                visible: !_currMeal.hasStarted,
                child: SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          editItemPressed(
                            context,
                          );
                        },
                        icon: const Icon(Icons.timer),
                      ),
                      IconButton(
                        onPressed: () {
                          _currMeal.removeTimer(_timer);
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
