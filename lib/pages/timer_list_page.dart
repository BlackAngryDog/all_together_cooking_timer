import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/pages/add_timer_page.dart';
import 'package:all_together_cooking_timer/widgets/timer_select_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/database.dart';

class TimerSelector extends StatelessWidget {
  final TimerGroup _currMeal;
  const TimerSelector(this._currMeal, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Select Active Timers"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              // TODO - ADD NEW TIMER PAGE
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddTimerPage(
                        TimerItem('', Duration.zero, Duration.zero))),
              );
            },
          )
        ],
      ),
      body: Container(
        child: FirebaseDatabaseListView(
          query: TimerDao().getTimerQuery(),
          itemBuilder: (context, snapshot) {
            TimerItem timer = TimerItem.fromJson(
                snapshot.key, snapshot.value as Map<dynamic, dynamic>);
            bool isChecked = _currMeal.hasTimer(timer);
            return TimerSelectListItem(timer, _currMeal);
          },
        ),
      ),
    );
  }
}

/*

 */
