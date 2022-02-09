import 'dart:async';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';

class TimerGroup {
  String title = "Timer Group";

  List<TimerItem> _ingredients = [];
  List<TimerItem> get ingredients => _ingredients;

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

  void addTimer(TimerItem item) {
    if (!_ingredients.contains(item)) {
      _ingredients.add(item);
    }
    onTimerAdded!();
    updateTimers();
  }

  void removeTimer(TimerItem timer) {
    _ingredients.removeWhere((t) => t == timer);
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
    return _ingredients[0].totalTime;
  }

  Duration getElapsedTime() {
    return _ingredients[0].elapsed;
  }

  Duration getTotalTimeLeft() {
    return getTotalTime() - elapsed;
  }

  String getNextAction() {
    // TODO : Work out what action is coming next and return action and duration
    List<TimerItem> nextTimers = List<TimerItem>.from(_ingredients);
    //GET NEXT ACTION BY SHORTEST DURATION TO NEXT EVENT
    nextTimers.sort((a, b) => a.getNextTime().compareTo(b.getNextTime()));

    /*
    print('-----');
    for (TimerItem i in nextTimers) {
      print('Debug ${i.getNextTimerEvent()} next time ${i.getNextTime()}');
    }
    */
    String nextText = nextTimers[0].getNextTimerEvent();

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
  }
}
