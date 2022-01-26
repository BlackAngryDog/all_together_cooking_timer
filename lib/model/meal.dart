import 'dart:async';

import 'package:all_together_cooking_timer/model/ingredient.dart';

class Meal {
  List<Ingredient> _ingredients = [];
  List<Ingredient> get ingredients => _ingredients;

  Stopwatch _timer = Stopwatch();

  void addIngredient(Ingredient item) {
    _ingredients.add(item);
  }

  Duration getTotalTime() {
    Duration t = Duration.zero;

    for (Ingredient ingredient in _ingredients) {
      t += ingredient.totalTime;
    }

    return t;
  }

  Duration getTotalTimeLeft() {
    return _timer.elapsed - getTotalTime();
  }

  void StartTimer(Function(Meal _meal) callBack) {
    _timer.start();

    Timer.periodic(const Duration(microseconds: 100), (Timer timer) {
      // THROW UPDATE
      print(_timer.elapsed.toString());
      callBack(this);
      if (_timer.elapsed > getTotalTime()) {
        timer.cancel();
        print('timer finished');
      }
    });
  }
}
