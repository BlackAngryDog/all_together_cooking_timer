import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_list.dart';
import 'package:flutterfire_ui/database.dart';

class TimerDao {
  final DatabaseReference _timerRef =
      FirebaseDatabase.instance.ref().child('timers');

  final String userID = "0001";

  void saveTimer(TimerItem item) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("timers/$userID");
    ref.push().set(item.toJson());
  }

  Query getTimerQuery() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("timers/$userID");
    return ref.orderByChild('name');
  }
}
