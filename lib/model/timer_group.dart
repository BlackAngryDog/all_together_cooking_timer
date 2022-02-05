import 'dart:async';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';

class TimerGroup {
  String title = "Timer Group";

  List<TimerItem> _ingredients = [];
  List<TimerItem> get ingredients => _ingredients;

  //final Stopwatch _timer = Stopwatch();

  DateTime _startTime = DateTime.now();

  Timer _runTimer = Timer(Duration.zero, () {});

  Duration elapsed = Duration.zero;

  Function(TimerGroup _meal)? _callBack;

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
    //_timer.start();
    _startTime = DateTime.now();
    _callBack = callBack;
    _isRunning = true;
    print("start");

    for (TimerItem i in _ingredients) {
      i.startTimer();
    }

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
    elapsed = DateTime.now().difference(_startTime);

    for (TimerItem i in _ingredients) {
      i.updateTimer(elapsed);
    }

    _callBack!(this);
  }

  void pauseTimer() {
    for (TimerItem i in _ingredients) {
      i.stopTimer();
    }
    _isRunning = false;
    //_timer.stop();
  }

  void restartTimer() {
    for (TimerItem i in _ingredients) {
      i.stopTimer();
    }
    //_timer.stop();
    //_timer.reset();
    _isRunning = false;
    _updateTimers();
  }
}
