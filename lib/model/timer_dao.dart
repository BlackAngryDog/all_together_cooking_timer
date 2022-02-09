import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_list.dart';
import 'package:flutterfire_ui/database.dart';

class TimerDao {
  final DatabaseReference _timerRef =
      FirebaseDatabase.instance.ref().child('timers');

  void saveTimer(TimerItem item) {
    _timerRef.push().set(item.toJson());
  }

  Query getTimerQuery() {
    return _timerRef.orderByChild('name');
  }
}
