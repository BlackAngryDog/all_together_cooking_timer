import 'package:all_together_cooking_timer/main.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CookStatus { waiting, cooking, resting, finished }

class TimerItem {
  Duration get totalTime {
    return runTime + restTime;
  }

  CookStatus status = CookStatus.waiting;

  String? id;
  String title;

  Duration runTime = Duration.zero;
  Duration restTime = Duration.zero;

  Duration _delayStart = Duration.zero;
  get delayStart => _delayStart;

  Duration _totalTime = Duration.zero;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  TimerItem(this.title, this.runTime, this.restTime);

  num get remainingTime => 0;

  bool paused = false;
  bool isStandAlone = false;

  // PERSISTANCE
  TimerItem.fromJson(String? key, Map<dynamic, dynamic> json)
      : id = key,
        title = json['title'] as String,
        runTime = Duration(seconds: json['runTime']),
        restTime = Duration(seconds: json['restTime']);

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'runTime': runTime.inSeconds,
        'restTime': restTime.inSeconds,
      };

  void ShowTime() {
    print(totalTime);
  }

  Future<void> loadState() async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    _elapsed = Duration(microseconds: prefs.getInt('elapsed') ?? 0);
    //final int startTime = (prefs.getInt('start_time') ?? 0);
  }

  Future<void> saveState() async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    prefs.setInt('elapsed', _elapsed.inMicroseconds);
    //final int startTime = (prefs.getInt('start_time') ?? 0);
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
    Duration timeToStart = _delayStart - _elapsed;
    Duration timeToEnd = _delayStart + runTime - _elapsed;
/*
    if (timeToStart > Duration.zero) {
      NotificationManager.displayDelayedFullscreen(
          _delayStart - _elapsed, title, "Start $title");
    }
*/
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

  void updateTimer(Duration increment) {
    // update based on time since last tick
    if (!paused) _elapsed += increment;

    // check status update
    CookStatus nextStatus = _getState();

    // Trigger event to activate X seconds before actual event
    Duration timeToNextEvent = getNextTime() - elapsed;
    // TODO : Create prewarn global setting
    int prewarnSeconds = -10;
    if (timeToNextEvent.inSeconds == prewarnSeconds) SoundManager.play();

    if (nextStatus != status) {
      // TODO - pause this timer if set to do so and show continue button.
      //if (nextStatus == CookStatus.cooking) {
      //  paused = true;
      //  return;
      //}

      // NotificationManager.displayUpdate(title, getNextTimerEvent());
      status = nextStatus;

      // DISPATCH UPDATE FOR NEXT STATE

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

  void initialiseNotification() {
    return;
    // CALLED WHEN APP GOES INTO BACKGROUND STATE
    // TODO - RETURN A LIST OF EVENT TIMES TO SEND AS NOTIFICATIONS (NEED TO COMBINE DUPLICATES)
    Duration timeToStart = _delayStart - _elapsed;
    Duration timeToEnd = _delayStart + runTime - _elapsed;

    if (timeToStart > Duration.zero) {
      NotificationManager.displayDelayedFullscreen(
          _delayStart - _elapsed, title, "Start $title");
    }
    if (timeToEnd > Duration.zero) {
      NotificationManager.displayDelayedFullscreen(
          _delayStart + runTime - _elapsed, title, "End $title");
    }

    //NotificationManager.displayDelayedFullscreen(
    //    getNextTime(), title, getNextTimerEvent());
  }
}
