import 'package:all_together_cooking_timer/main.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';

enum CookStatus { waiting, cooking, resting, finished }

class TimerItem {
  Duration get totalTime {
    return runTime + restTime;
  }

  CookStatus status = CookStatus.waiting;

  String id = '';
  String title;

  Duration runTime = Duration.zero;
  Duration restTime = Duration.zero;

  Duration _delayStart = Duration.zero;
  get delayStart => _delayStart;

  Duration _totalTime = Duration.zero;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  DateTime _dateTime = DateTime.now();

  TimerItem(this.title, this.runTime, this.restTime);

  num get remainingTime => 0;

  bool paused = false;
  bool isStandAlone = false;

  // PERSISTANCE
  TimerItem.fromJson(Map<dynamic, dynamic> json)
      : id = json['id'] as String,
        title = json['title'] as String,
        runTime = Duration(seconds: json['runTime']),
        restTime = Duration(seconds: json['restTime']);

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'id': id,
        'title': title,
        'runTime': runTime.inSeconds,
        'restTime': restTime.inSeconds,
      };

  void ShowTime() {
    print(totalTime);
  }

  void setDelay(Duration totalTime) {
    if (isStandAlone) {
      _delayStart = Duration.zero;
      paused = true;
      return;
    }
    paused = false;
    _totalTime = totalTime;
    _delayStart = totalTime - (runTime + restTime);
    print(
        "$title starts in $delayStart as total is $totalTime - ${runTime + restTime}");
  }

  void startTimer() {
    _dateTime = DateTime.now();

    Duration timeToStart = _delayStart - _elapsed;
    Duration timeToEnd = _delayStart + runTime - _elapsed;

    if (timeToStart > Duration.zero) {
      NotificationManager.displayDelayedFullscreen(
          _delayStart - _elapsed, title, "Start $title");
    }

/*
    if (timeToStart > Duration.zero) {
      NotificationManager.displayDelayedFullscreen(
          _delayStart - _elapsed, title, "Start $title");
    }
    if (timeToEnd > Duration.zero) {
      NotificationManager.displayDelayedFullscreen(
          _delayStart + runTime - _elapsed, title, "End $title");
    }
*/
  }

  void stopTimer() {
    // TODO - STOP ONLY FOR THIS TIMER ID!
    NotificationManager.stopAllNotifications();
  }

  void resetTimer() {
    NotificationManager.stopAllNotifications();
    _elapsed = Duration.zero;
    _delayStart = Duration.zero;
  }

  void updateTimer() {
    Duration increment = DateTime.now().difference(_dateTime);
    if (!paused) _elapsed += increment;
    _dateTime = DateTime.now();

    // TODO - set state and fire evens on state changed

    CookStatus nextStatus = _getState();
    if (nextStatus != status) {
      // TODO - trigger event

      // TODO - pause this timer if set to do so and show continue button.
      //if (nextStatus == CookStatus.cooking) {
      //  paused = true;
      //  return;
      //}

      NotificationManager.displayUpdate(title, getNextTimerEvent());
      status = nextStatus;
      // TODO - WORK OUT HOW TO LOOP SOUND UNTIL STOPPED
      SoundManager.play();

      print(
          'setup notification - ${getNextTime()}, $title, ${getNextTimerEvent()}');
      // DISPATCH UPDATE FOR NEXT STATE
      NotificationManager.displayDelayedFullscreen(
          getNextTime(), title, getNextTimerEvent());
    }
  }

  void resume() {
    paused = false;
    status = _getState();
    SoundManager.stop();
  }

  String getTimerText() {
    if (_elapsed == Duration.zero) {
      String delay = _delayStart > Duration.zero
          ? 'Delay : ${FormatDuration.format(_delayStart)}, '
          : "";
      String cook = "Cook time : ${FormatDuration.format(runTime)}, ";
      String rest = restTime > Duration.zero
          ? "Rest : ${FormatDuration.format(restTime)}, "
          : "";

      return delay + cook + rest;
    }

    switch (status) {
      case CookStatus.waiting:
        return "Time to Start : ${FormatDuration.format(_delayStart - _elapsed)}";
      case CookStatus.cooking:
        return "Cooking : ${FormatDuration.format((_delayStart + runTime) - _elapsed)}";
      case CookStatus.resting:
        return "Resting : ${FormatDuration.format((_delayStart + runTime + restTime) - _elapsed)}";
      default:
        return "Finished";
    }
  }

  String getNextTimerEvent() {
    switch (status) {
      case CookStatus.waiting:
        return "Start Cooking $title in ${FormatDuration.format(_delayStart - _elapsed)}";
      case CookStatus.cooking:
        return "Stop Cooking $title in  : ${FormatDuration.format((_delayStart + runTime) - _elapsed)}";
      case CookStatus.resting:
        return "Rest $title for: ${FormatDuration.format((_delayStart + runTime + restTime) - _elapsed)}";
      default:
        return "Finished $title";
    }
  }

  Duration getNextTime() {
    CookStatus nextState = getNextStatus();
    switch (status) {
      case CookStatus.waiting:
        return _delayStart - _elapsed;
      case CookStatus.cooking:
        return (_delayStart + runTime) - _elapsed;
      case CookStatus.resting:
        return (_delayStart + runTime + restTime) - _elapsed;
      default:
        return _elapsed; // NOT SURE ABOUT THIS RETURN!?

    }
  }

  CookStatus getNextStatus() {
    if (_elapsed == Duration.zero)
      return _delayStart == Duration.zero
          ? CookStatus.cooking
          : CookStatus.waiting;

    if (_elapsed < _delayStart) return CookStatus.cooking;
    if (_elapsed > _delayStart && _elapsed < _totalTime - restTime)
      return CookStatus.resting;

    return CookStatus.finished;
  }

  CookStatus _getState() {
    if (_elapsed < _delayStart) return CookStatus.waiting;
    if (_elapsed > _delayStart && _elapsed < _totalTime - restTime)
      return CookStatus.cooking;
    if (_elapsed < _totalTime) return CookStatus.resting;
    return CookStatus.finished;
  }

  //TODO - notify start, turn and rest events.

}
