import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/pages/add_timer_page.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4,
      child: ListTile(
        title: Text(
          _timer.title,
        ),
        subtitle: Text(
          _timer.getTimerText(),
        ),
        trailing: _currMeal.hasStarted
            ? SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Visibility(
                      visible: _timer.canSkip,
                      child: IconButton(
                        onPressed: () {
                          _currMeal.skipTimer(_timer);
                        },
                        icon: const Icon(Icons.fast_forward),
                      ),
                    ),
                    Visibility(
                      visible: _timer.canExtend,
                      child: IconButton(
                        onPressed: () {
                          _currMeal.extendTimer(_timer, Duration(minutes: -1));
                        },
                        icon: const Icon(Icons.arrow_left),
                      ),
                    ),
                    Visibility(
                      visible: _timer.canExtend,
                      child: IconButton(
                        onPressed: () {
                          _currMeal.extendTimer(_timer, Duration(minutes: 1));
                        },
                        icon: const Icon(Icons.arrow_right),
                      ),
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
