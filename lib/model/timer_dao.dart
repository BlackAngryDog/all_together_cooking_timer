import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimerDao {
  //final DatabaseReference _timerRef =
  //    FirebaseDatabase.instance.ref().child('timers');

  void saveTimer(TimerItem item) {
    // TODO - CHECK IF TIMER WITH SAME NAME ALREADY IN DB

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

  void saveTimerGroup(TimerGroup item) {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("timerGroup/${getUserID()}");
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
    return ref;
  }

  Query getTimerGroupQuery() {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("timerGroup/${getUserID()}");
    return ref;
  }

  Future<TimerItem> getTimer(String key) async {
    Query ref = FirebaseDatabase.instance.ref('timers/${getUserID()}/$key');
    DatabaseEvent event = await ref.once();
    if (event.snapshot.value == null)
      return TimerItem('', Duration.zero, Duration.zero);
    return TimerItem.fromJson(
        key, event.snapshot.value as Map<dynamic, dynamic>);
  }

  Future<TimerGroup> getTimerGroup(String key) async {
    Query ref = FirebaseDatabase.instance.ref('timerGroup/${getUserID()}/$key');
    DatabaseEvent event = await ref.once();
    if (event.snapshot.value == null) return TimerGroup();
    return TimerGroup.fromJson(
        key, event.snapshot.value as Map<dynamic, dynamic>);
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
