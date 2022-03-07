import 'dart:convert';

import 'package:all_together_cooking_timer/main.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CookStatus { waiting, cooking, resting, finished }

class TimerEvent {
  final String eventName;
  final TimerItem item;
  final Duration eventTime;
  TimerEvent(this.eventName, this.item, this.eventTime);
}

class TimerItem {
  final List<String> mapKey = ["Prep", "Cook", "Rest"];

  Map<String, Duration> times = {};
  Map<String, Duration> run_times = {};

  CookStatus status = CookStatus.waiting;

  String? id;
  String title;

  Duration get runTime => run_times["Cook"] ?? Duration.zero;

  get canSkip {
    MapEntry<String, Duration> nextState = getCurrentState();
    return nextState.key == "Waiting" || nextState.key == "Prep";
  }

  get canExtend {
    MapEntry<String, Duration> nextState = getCurrentState();
    return nextState.key == "Cooking";
  }

  set runTime(Duration value) {
    times["Cook"] = value;
    initRunTimer();
  }

  Duration get restTime => run_times["Rest"] ?? Duration.zero;
  set restTime(Duration value) {
    times["Rest"] = value;
    initRunTimer();
  }

  Duration _delayStart = Duration.zero;
  Duration get delayStart => _delayStart;
  set delayStart(Duration value) {
    _delayStart = value;
  }

  Duration _totalTime = Duration.zero;

  String _currStateName = "";
  Duration _offset = Duration.zero;
  Duration _elapsed = Duration.zero;

  Duration get elapsed {
    //if (_currStateName == 'Rest')
    //   return _elapsed - _offset;
    //else
    return _elapsed;
  }

  //num get remainingTime => 0;

  Duration get totalCookTime {
    Duration value = Duration.zero;
    for (Duration d in run_times.values) {
      value += d;
    }
    return value;
  }

  Duration get totalRunTime {
    return totalCookTime + delayStart;
  }

  bool paused = false;
  bool isStandAlone = false;

  TimerItem(this.title, runTime, restTime) {
    times["Prep"] = const Duration(seconds: 15);
    times["Cook"] = runTime;
    times["Rest"] = restTime;
    initRunTimer();
  }

  // PERSISTANCE
  TimerItem.fromJson(String? key, Map<dynamic, dynamic> json)
      : id = key,
        title = json['title'] as String,
        isStandAlone = json['isStandAlone'] ?? false,
        times = json['times'] != null
            ? Map<String, Duration>.from(
                jsonDecode(json['times']).map((String name, dynamic seconds) {
                return MapEntry(name, Duration(seconds: seconds));
              }))
            : <String, Duration>{};

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'isStandAlone': isStandAlone,
        'times': jsonEncode(times.map((String name, Duration duration) {
          return MapEntry(name, duration.inSeconds);
        })),
      };

  void ShowTime() {}

  Future<void> loadState() async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    prefs.setInt('elapsed', 0);
    _elapsed = Duration(seconds: prefs.getInt('elapsed') ?? 0);
  }

  Future<void> saveState() async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;

    prefs.setInt('elapsed', _elapsed.inSeconds);
  }

  void initRunTimer() {
    for (String key in times.keys) {
      run_times[key] = times[key] ?? Duration.zero;
    }
  }

  void setDelay(Duration totalTime) {
    if (isStandAlone) {
      _delayStart = Duration.zero;
      paused = true;
      return;
    }
    paused = false;
    _totalTime = totalTime;
    _delayStart = totalTime - totalRunTime;

    // TODO - IMPLEMENT SETTES AND GETTERS
    times["Prep"] = Duration(seconds: 15);
    initRunTimer();
    //times["Cook"] = runTime;
    //times["Rest"] = restTime;

    print(
        "$title starts in $delayStart as total is $totalTime - ${runTime + restTime}");
  }

  void startTimer() {
    print("start Timer");
  }

  List<TimerEvent> getEvents() {
    List<TimerEvent> events = [];
    Duration prewarn = const Duration(seconds: 10);
    Duration timeToStart = _delayStart - elapsed - prewarn;
    Duration timeToEndCook = _delayStart + runTime - elapsed - prewarn;

    if (timeToStart > Duration.zero) {
      events.add(TimerEvent("Start", this, timeToStart));
    }

    if (timeToEndCook > Duration.zero) {
      events.add(TimerEvent("Finish", this, timeToEndCook));
    }
    return events;
  }

  void stopTimer() {
    // TODO - STOP ONLY FOR THIS TIMER ID!
    //NotificationManager.stopAllNotifications();
  }

  void resetTimer() {
    //NotificationManager.stopAllNotifications();
    _elapsed = Duration.zero;
    _offset = Duration.zero;
    _delayStart = Duration.zero;
    initRunTimer();
  }

  void updateTimer(Duration increment) {
    // update based on time since last tick
    if (!paused) _elapsed += increment;

    // check status update
    CookStatus nextStatus = _getState();

    // Trigger event to activate X seconds before actual event
    Duration timeToNextEvent = getNextTime() - elapsed;
    // TODO : Create prewarn global setting
    // TODO - how to get if SFX alert needs to play and bug with when!
    int prewarnSeconds = -10;
    Duration prewarn = const Duration(seconds: 10);
    Duration timeToStart = (_delayStart - elapsed);
    Duration timeToEndCook = (_delayStart + runTime - elapsed);
    Duration timeToEndRest = _delayStart + runTime + restTime - elapsed;
/*
    if (timeToStart > Duration.zero &&
        timeToStart < prewarn &&
        !SoundManager.isPlaying) SoundManager.play();
    if (timeToEndCook > Duration.zero &&
        timeToEndCook < prewarn &&
        !SoundManager.isPlaying) SoundManager.play();
    if (timeToEndRest > Duration.zero &&
        timeToEndRest < prewarn &&
        !SoundManager.isPlaying) SoundManager.play();
*/
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

  MapEntry<String, Duration> getCurrentState() {
    if (elapsed == Duration.zero)
      return MapEntry<String, Duration>(
          "Total Time", totalRunTime - _delayStart);

    if (elapsed >= totalRunTime)
      return MapEntry<String, Duration>("Finished", totalRunTime);

    Duration value = _delayStart;
    for (String key in mapKey) {
      Duration nextValue = run_times[key] ?? Duration.zero;
      if (elapsed > value && elapsed < value + nextValue)
        return MapEntry<String, Duration>(key, value + nextValue);
      value += nextValue;
    }

    return MapEntry<String, Duration>("Waiting", _delayStart);
  }

  Duration getCurrentStart() {
    for (Duration d in run_times.values) {
      d += _delayStart;
      if (elapsed > d) return d;
    }
    return _delayStart;
  }

  Duration getCurrentEnd() {
    for (Duration d in run_times.values) {
      d += _delayStart;
      if (elapsed < d) return d;
    }
    return Duration.zero;
  }

  String getTimerText() {
    MapEntry<String, Duration> currState = getCurrentState();
    return 'State : ${currState.key} Time : ${FormatDuration.format(currState.value - elapsed)}';
    return 'start ${FormatDuration.format(getCurrentStart())} end ${FormatDuration.format(getCurrentEnd())}';

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
        return "Start Cooking $title in ${FormatDuration.format(_delayStart - elapsed)}";
      case CookStatus.cooking:
        return "Stop Cooking $title in  : ${FormatDuration.format((_delayStart + runTime) - elapsed)}";
      case CookStatus.resting:
        return "Rest $title for: ${FormatDuration.format((_delayStart + runTime + restTime) - elapsed)}";
      default:
        return "Finished $title";
    }
  }

  Duration getNextTime() {
    CookStatus nextState = getNextStatus();
    switch (status) {
      case CookStatus.waiting:
        return _delayStart - elapsed;
      case CookStatus.cooking:
        return (_delayStart + runTime) - elapsed;
      case CookStatus.resting:
        return (_delayStart + runTime + restTime) - elapsed;
      default:
        return elapsed; // NOT SURE ABOUT THIS RETURN!?

    }
  }

  CookStatus getNextStatus() {
    if (elapsed == Duration.zero)
      return _delayStart == Duration.zero
          ? CookStatus.cooking
          : CookStatus.waiting;

    if (elapsed < _delayStart) return CookStatus.cooking;
    if (elapsed > _delayStart && elapsed < _totalTime - restTime)
      return CookStatus.resting;

    return CookStatus.finished;
  }

  CookStatus _getState() {
    if (elapsed < _delayStart) return CookStatus.waiting;
    if (elapsed > _delayStart && elapsed < _totalTime - restTime)
      return CookStatus.cooking;
    if (elapsed < _totalTime) return CookStatus.resting;
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
