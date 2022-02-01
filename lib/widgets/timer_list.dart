import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';
import 'package:flutter/material.dart';

class TimerHome extends StatefulWidget {
  final TimerGroup _currMeal;

  const TimerHome(this._currMeal, {Key? key}) : super(key: key);

  @override
  TimerHomeState createState() => TimerHomeState();
}

class TimerHomeState extends State<TimerHome> {
  String _timer = '00:00:00';

  void timerUpdate(TimerGroup meal) {
    setState(() {
      _timer = FormatDuration.format(meal.getTotalTimeLeft());
    });
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
        context: ctx,
        builder: (_) {
          return GestureDetector(
            child: EditTimer(onTimerAdded, timer),
            onTap: () {},
            behavior: HitTestBehavior.opaque,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    addItemPressed(
                                      ctx,
                                      widget._currMeal.ingredients[index],
                                    );
                                  },
                                  icon: const Icon(Icons.timer),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _onDeletePressed(
                                      widget._currMeal.ingredients[index],
                                    );
                                  },
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: widget._currMeal.ingredients.length,
                  ),
          )
        ],
      ),
    );
  }
}
