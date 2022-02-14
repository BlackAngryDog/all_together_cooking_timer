import 'dart:async';
import 'dart:convert';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';

class TimerGroup {
  String title = "Timer Group";

  String? id;
  List<String> _timersIds = [];
  List<TimerItem> _ingredients = [];
  List<TimerItem> get ingredients => _ingredients;

  TimerGroup() {
    loadTimers();
  }

  Duration get elapsed => getElapsedTime();

  Function(TimerGroup _meal)? _callBack;

  Function()? onTimerAdded;

  bool _isRunning = false;
  bool get isRunning => _isRunning;
  bool get isFinished {
    return getTotalTimeLeft() <= Duration.zero;
  }

  bool get hasStarted {
    return elapsed > Duration.zero;
  }

  Future<void> loadTimers() async {
    for (var key in _timersIds) {
      addTimer(await TimerDao().getTimer(key));
    }
  }

  void addTimer(TimerItem item) {
    // TODO - consider adding async load funtion that accepts a key for persistance rather than init function.
    if (!_ingredients.contains(item)) {
      _ingredients.add(item);
    }
    onTimerAdded!();
    updateTimers();
  }

  void removeTimer(TimerItem timer) {
    _ingredients.removeWhere((t) => t.id == timer.id);
    onTimerAdded!();
    updateTimers();
  }

  void updateTimers() {
    // Sort items by duration, assign start delay
    _ingredients.sort((a, b) => b.totalTime.compareTo(a.totalTime));
    Duration max = getTotalTime();
    for (TimerItem i in _ingredients) {
      i.setDelay(max);
    }
  }

  int getProgress() {
    int total = getTotalTime().inMilliseconds;

    return ((elapsed.inMilliseconds / total) * 100).round();
  }

  Duration getTotalTime() {
    return _ingredients.isEmpty ? Duration.zero : _ingredients[0].totalTime;
  }

  Duration getElapsedTime() {
    return _ingredients.isEmpty ? Duration.zero : _ingredients[0].elapsed;
  }

  Duration getTotalTimeLeft() {
    return getTotalTime() - elapsed;
  }

  String getNextAction() {
    // Work out what action is coming next and return action and duration
    List<TimerItem> nextTimers = List<TimerItem>.from(_ingredients);

    //GET NEXT ACTION BY SHORTEST DURATION TO NEXT EVENT
    nextTimers.sort((a, b) => a.getNextTime().compareTo(b.getNextTime()));

    String nextText =
        nextTimers.isEmpty ? "" : nextTimers[0].getNextTimerEvent();

    return nextText;
  }

  void StartTimer(Function(TimerGroup _meal)? callBack) {
    _callBack = callBack;
    _isRunning = true;

    for (TimerItem i in _ingredients) {
      i.startTimer();
    }
    _updateTimers();

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!_isRunning) {
        timer.cancel();
        _isRunning = false;
        return;
      }

      // THROW UPDATE
      _updateTimers();

      if (elapsed > getTotalTime()) {
        timer.cancel();
        _isRunning = false;
      }
    });
  }

  void _updateTimers() {
    for (TimerItem i in _ingredients) {
      i.updateTimer();
    }
    _callBack!(this);
  }

  void pauseTimer() {
    for (TimerItem i in _ingredients) {
      i.stopTimer();
    }
    _callBack!(this);
    _isRunning = false;
    SoundManager.stop();
  }

  void restartTimer() {
    for (TimerItem i in _ingredients) {
      i.resetTimer();
    }
    updateTimers();
    _callBack!(this);
    _isRunning = false;
    SoundManager.stop();

    print(toJson());
  }

  // PERSISTANCE

  TimerGroup.fromJson(String? key, Map<dynamic, dynamic> json)
      : id = key,
        title = json['title'] as String,
        _timersIds =
            (jsonDecode(json['timers']) as List<dynamic>).cast<String>();

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'timers':
            jsonEncode(_ingredients.map((entry) => "${entry.id}").toList()),
      };

  bool hasTimer(TimerItem timer) {
    return _ingredients.where((element) => timer.id == element.id).isNotEmpty;
  }
}
