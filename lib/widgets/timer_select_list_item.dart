import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../pages/add_timer_page.dart';

class TimerSelectListItem extends StatefulWidget {
  final TimerItem _timer;
  final TimerGroup _currMeal;

  const TimerSelectListItem(this._timer, this._currMeal, {Key? key})
      : super(key: key);

  @override
  _TimerSelectListItemState createState() => _TimerSelectListItemState();
}

class _TimerSelectListItemState extends State<TimerSelectListItem> {
  void editItemPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTimerPage(
                widget._timer,
                group: widget._currMeal,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        child: ListTile(
          title: Text(widget._timer.title),
          subtitle: Text(
            widget._timer.getTimerText(),
          ),
          trailing: SizedBox(
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
                Checkbox(
                  checkColor: Colors.white,
                  value: widget._currMeal.hasTimer(widget._timer),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true)
                        widget._currMeal.addTimer(widget._timer);
                      else {
                        widget._currMeal.removeTimer(widget._timer);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        //widget._currMeal.addTimer(widget._timer);
        //Navigator.pop(context);
      },
    );
  }
}
