import 'dart:async';

import 'package:all_together_cooking_timer/model/timer.dart';

class TimerGroup {
  List<TimerItem> _ingredients = [];
  List<TimerItem> get ingredients => _ingredients;

  final Stopwatch _timer = Stopwatch();
  Timer _runTimer = Timer(Duration.zero, () {});

  bool get isRunning => _timer.isRunning;

  void addTimer(TimerItem item) {
    if (!_ingredients.contains(item)) {
      _ingredients.add(item);
    }

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

  Duration getTotalTime() {
    /*
    Duration t = Duration.zero;

    for (Ingredient ingredient in _ingredients) {
      t += ingredient.totalTime;
    }
    */
    //return max time from first item as sorted to be highest
    return _ingredients[0].totalTime;
  }

  Duration getTotalTimeLeft() {
    return _timer.elapsed - getTotalTime();
  }

  void StartTimer(Function(TimerGroup _meal) callBack) {
    _timer.start();
    print("start");
    Timer.periodic(const Duration(microseconds: 100), (Timer timer) {

      if (!_timer.isRunning) {
        timer.cancel();
        return;
      }

      // THROW UPDATE
      for (TimerItem i in _ingredients) {
        i.updateTimer(_timer.elapsed);
      }

      callBack(this);
      if (_timer.elapsed > getTotalTime()) {
        timer.cancel();
      }

    });
  }

  void PauseTimer() {
    _timer.stop();
  }

  void StopTimer() {
    _timer.stop();
    _timer.reset();

  }
}
