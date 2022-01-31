import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';
import 'package:flutter/material.dart';

class TimerHome extends StatefulWidget {
  final TimerGroup _currMeal;

  const TimerHome(this._currMeal, {Key? key}) : super(key: key);

  @override
  TimerHomeState createState() => TimerHomeState();
}

class TimerHomeState extends State<TimerHome> {
  String _timer = '';

  void timerUpdate(TimerGroup meal) {
    setState(() {
      _timer = meal.getTotalTimeLeft().toString();
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
    setState(() {
      // TODO - add new time or update timer
      _timer = widget._currMeal.getTotalTimeLeft().toString();
    });
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
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
