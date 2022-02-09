import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:flutter/material.dart';

class TimerListView extends StatelessWidget {
  final TimerGroup _currMeal;
  final int index;

  final Function(int index) onEdit;
  final Function(int index) onDelete;

  const TimerListView(this._currMeal, this.index, this.onEdit, this.onDelete,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          _currMeal.ingredients[index].title,
        ),
        subtitle: Text(
          _currMeal.ingredients[index].getTimerText(),
        ),
        trailing: _currMeal.hasStarted
            ? Visibility(
                visible: _currMeal.ingredients[index].paused,
                child: IconButton(
                  onPressed: () {
                    _currMeal.ingredients[index].resume();
                  },
                  icon: const Icon(Icons.play_arrow),
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
                          onEdit(index);
                        },
                        icon: const Icon(Icons.timer),
                      ),
                      IconButton(
                        onPressed: () {
                          onDelete(index);
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
