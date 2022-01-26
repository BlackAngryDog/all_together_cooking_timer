class Ingredient {
  Duration get totalTime {
    return _time + _rest;
  }

  final String _title;
  get title => _title;

  final Duration _time;
  final Duration _rest;

  Ingredient(this._title, this._time, this._rest);

  num get remainingTime => 0;

  void ShowTime() {
    print(totalTime);
  }
}
