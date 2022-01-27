import 'dart:async';

import 'package:all_together_cooking_timer/model/ingredient.dart';

class Meal {
  List<Ingredient> _ingredients = [];
  List<Ingredient> get ingredients => _ingredients;

  final Stopwatch _timer = Stopwatch();

  void addIngredient(Ingredient item) {
    _ingredients.add(item);

    updateTimers();
  }

  void updateTimers() {
    // Sort items by duration, assign start delay
    _ingredients.sort((a, b) => b.totalTime.compareTo(a.totalTime));
    Duration max = getTotalTime();
    for (Ingredient i in _ingredients) {
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

  void StartTimer(Function(Meal _meal) callBack) {
    _timer.reset();
    _timer.start();

    Timer.periodic(const Duration(microseconds: 100), (Timer timer) {
      // THROW UPDATE

      for (Ingredient i in _ingredients) {
        i.updateTimer(_timer.elapsed);
      }

      callBack(this);
      if (_timer.elapsed > getTotalTime()) {
        timer.cancel();
        print('timer finished');
      }
    });
  }
}
