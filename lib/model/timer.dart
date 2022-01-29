enum CookStatus { waiting, cooking, resting }

class TimerItem {
  Duration get totalTime {
    return runTime + restTime;
  }

  CookStatus status = CookStatus.waiting;

  String title;

  Duration runTime = Duration.zero;
  Duration restTime = Duration.zero;

  Duration _delayStart = Duration.zero;
  get delayStart => _delayStart;

  Duration _totalTime = Duration.zero;
  Duration _elapsed = Duration.zero;

  TimerItem(this.title, this.runTime, this.restTime);

  num get remainingTime => 0;

  void ShowTime() {
    print(totalTime);
  }

  void setDelay(Duration totalTime) {
    _totalTime = totalTime;
    _delayStart = totalTime - (runTime + restTime);
    print(
        "$title starts in $delayStart as total is $totalTime - ${runTime + restTime}");
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
        return "Resting : ${(_delayStart + runTime + restTime) - _elapsed}";
        break;
    }
  }

  CookStatus _getState() {
    CookStatus state = _elapsed < _delayStart
        ? CookStatus.waiting
        : _elapsed > _totalTime - restTime
            ? CookStatus.resting
            : CookStatus.cooking;
    return state;
  }

  //TODO - work out start delay;
  //TODO - notify start, turn and rest events.
}
