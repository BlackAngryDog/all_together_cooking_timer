import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_list.dart';

class TimerDao {
  final DatabaseReference _timerRef =
      FirebaseDatabase.instance.reference().child('timers');

  void saveMessage(TimerItem item) {
    _timerRef.push().set(item.toJson());
  }

  Query getTimerQuery() {
    return _timerRef;
  }

  FirebaseList getList() {
    return FirebaseList(
      query: getTimerQuery(),
    );
  }
}
