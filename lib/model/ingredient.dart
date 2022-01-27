enum CookStatus { waiting, cooking, resting }

class Ingredient {
  Duration get totalTime {
    return _time + _rest;
  }

  CookStatus status = CookStatus.waiting;

  final String _title;
  get title => _title;

  final Duration _time;
  final Duration _rest;
  Duration _delayStart = Duration.zero;
  get delayStart => _delayStart;

  Duration _totalTime = Duration.zero;
  Duration _elapsed = Duration.zero;

  Ingredient(this._title, this._time, this._rest);

  num get remainingTime => 0;

  void ShowTime() {
    print(totalTime);
  }

  void setDelay(Duration totalTime) {
    _totalTime = totalTime;
    _delayStart = totalTime - (_time + _rest);
    print(
        "$title starts in $delayStart as total is $totalTime - ${_time + _rest}");
  }

  void updateTimer(Duration currTime) {
    _elapsed = currTime;
    // TODO - set state and fire evens on state changed

    CookStatus nextStatus = _getState();
    if (nextStatus != status) {
      // TODO - trigger event

      status = nextStatus;
    }
  }

  String getTimerText() {
    switch (status) {
      case CookStatus.waiting:
        return "Time to Start : ${_delayStart - _elapsed}";
        break;
      case CookStatus.cooking:
        return "Cooking : ${(_delayStart + _time) - _elapsed}";
        break;
      case CookStatus.resting:
        return "Resting : ${(_delayStart + _time + _rest) - _elapsed}";
        break;
    }
  }

  CookStatus _getState() {
    CookStatus state = _elapsed < _delayStart
        ? CookStatus.waiting
        : _elapsed > _totalTime - _rest
            ? CookStatus.resting
            : CookStatus.cooking;
    return state;
  }

  //TODO - work out start delay;
  //TODO - notify start, turn and rest events.
}
