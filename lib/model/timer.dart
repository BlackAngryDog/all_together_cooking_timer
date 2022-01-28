enum CookStatus { waiting, cooking, resting }

class TimerItem {
  Duration get totalTime {
    return runTime + _rest;
  }

  CookStatus status = CookStatus.waiting;

  final String _title;
  get title => _title;

  Duration runTime = Duration.zero;

  final Duration _rest;
  Duration _delayStart = Duration.zero;
  get delayStart => _delayStart;

  Duration _totalTime = Duration.zero;
  Duration _elapsed = Duration.zero;

  TimerItem(this._title, this.runTime, this._rest);

  num get remainingTime => 0;

  void ShowTime() {
    print(totalTime);
  }

  void setDelay(Duration totalTime) {
    _totalTime = totalTime;
    _delayStart = totalTime - (runTime + _rest);
    print(
        "$title starts in $delayStart as total is $totalTime - ${runTime + _rest}");
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
        return "Cooking : ${(_delayStart + runTime) - _elapsed}";
        break;
      case CookStatus.resting:
        return "Resting : ${(_delayStart + runTime + _rest) - _elapsed}";
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
