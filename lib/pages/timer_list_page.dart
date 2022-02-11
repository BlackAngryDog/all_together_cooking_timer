import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:all_together_cooking_timer/pages/add_timer_page.dart';
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
        title: Text("Select"),
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
            print(snapshot.value);
            TimerItem timer = TimerItem.fromJson(
                snapshot.key, snapshot.value as Map<dynamic, dynamic>);
            return GestureDetector(
              child: Card(
                child: ListTile(
                  title: Text(timer.title),
                  subtitle: Text(
                    timer.getTimerText(),
                  ),
                  trailing: TextButton(
                    child: Text("update"),
                    onPressed: () {
                      timer.runTime += const Duration(minutes: 1);
                      TimerDao().saveTimer(timer);
                    },
                  ),
                ),
              ),
              onTap: () {
                _currMeal.addTimer(timer);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}

/*

 */
