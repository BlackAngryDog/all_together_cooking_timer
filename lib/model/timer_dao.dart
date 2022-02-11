import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimerDao {
  final DatabaseReference _timerRef =
      FirebaseDatabase.instance.ref().child('timers');

  void saveTimer(TimerItem item) {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("timers/${getUserID()}");
    if (item.id != null) {
      ref.update({
        item.id as String: item.toJson(),
      });
    } else {
      ref.push().set(item.toJson());
    }
  }

  Query getTimerQuery() {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("timers/${getUserID()}");
    return ref.orderByChild('title');
  }

  String getUserID() {
    String uid = 'default';
    if (FirebaseAuth.instance.currentUser != null &&
        FirebaseAuth.instance.currentUser?.uid != null) {
      uid = FirebaseAuth.instance.currentUser?.uid as String;
    }
    return uid;
  }
}
