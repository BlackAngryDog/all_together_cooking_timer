import 'dart:async';
import 'dart:convert';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

// to Control our Stream
StreamController timerGroupUpdateEvent =
    StreamController<TimerGroup>.broadcast();
// this is our stream

StreamController timerGroupOnAddedEvent =
    StreamController<TimerGroup>.broadcast();

class TimerGroup {
  String title = "Timer Group";

  String? id;
  List<String> _timersIds = [];
  List<TimerItem> _ingredients = [];
  List<TimerItem> get ingredients => _ingredients;
  //Stream stream = timerGroupUpdateEvent.stream;

  DateTime _dateTime = DateTime.now();
  //final StreamController<int> updateStream = StreamController<int>.broadcast();

  TimerGroup();

  Duration get elapsed => getElapsedTime();

  //Function(TimerGroup _meal)? _callBack;

  //Function()? onTimerAdded;

  bool _isRunning = false;
  bool get isRunning => _isRunning;
  bool get isFinished {
    return getTotalTimeLeft() <= Duration.zero;
  }

  bool get hasStarted {
    return elapsed > Duration.zero;
  }

  Future<void> loadTimers() async {
    for (var key in _timersIds) {
      addTimer(await TimerDao().getTimer(key));
    }
  }

  Future<void> loadState() async {
    // TODO - work out how to delay display until data loaded and update when paused.
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    final int startTime = (prefs.getInt('start_time') ?? 0);

    _isRunning = prefs.getBool('is_running') ?? false;
    _dateTime = startTime == 0
        ? DateTime.now()
        : DateTime.fromMicrosecondsSinceEpoch(startTime);

    // INCREMENT ELAP

    for (TimerItem i in _ingredients) {
      await i.loadState();
    }
    if (_isRunning) {
      // UPDATE FOR MISSED TIME
      _updateTick();
      StartTimer();
    }
  }

  Future<void> saveState() async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    prefs.setBool('is_running', _isRunning);
    prefs.setInt(
        'start_time', !_isRunning ? 0 : _dateTime.microsecondsSinceEpoch);

    for (TimerItem i in _ingredients) {
      await i.saveState();
    }
  }

  void addTimer(TimerItem item) {
    // TODO - consider adding async load funtion that accepts a key for persistance rather than init function.
    if (_ingredients.where((i) => i.id == item.id).isEmpty) {
      _ingredients.add(item);
    }
    sortTimers();
    timerGroupOnAddedEvent.add(this);
  }

  void removeTimer(TimerItem timer) {
    _ingredients.removeWhere((t) => t.id == timer.id);
    sortTimers();
    timerGroupOnAddedEvent.add(this);
  }

  void sortTimers() {
    // Sort items by duration, assign start delay
    _ingredients.sort((a, b) => b.totalRunTime.compareTo(a.totalRunTime));
    Duration max = getTotalTime();
    for (TimerItem i in _ingredients) {
      i.setDelay(max);
    }
    //
    onUpdate();
  }

  int getProgress() {
    int total = getTotalTime().inMilliseconds;
    if (total == 0) return 0;
    return ((elapsed.inMilliseconds / total) * 100).round();
  }

  Duration getTotalTime() {
    return _ingredients.isEmpty ? Duration.zero : _ingredients[0].totalRunTime;
  }

  Duration getElapsedTime() {
    return _ingredients.isEmpty ? Duration.zero : _ingredients[0].elapsed;
  }

  Duration getTotalTimeLeft() {
    return getTotalTime() - elapsed;
  }

  String getNextAction() {
    // Work out what action is coming next and return action and duration
    List<TimerItem> nextTimers = List<TimerItem>.from(_ingredients);

    //GET NEXT ACTION BY SHORTEST DURATION TO NEXT EVENT
    nextTimers.sort((a, b) => a.getNextTime().compareTo(b.getNextTime()));

    String nextText =
        nextTimers.isEmpty ? "" : nextTimers[0].getNextTimerEvent();

    return nextText;
  }

  String getNextActionTime() {
    // Work out what action is coming next and return action and duration
    List<TimerItem> nextTimers = List<TimerItem>.from(_ingredients);

    //GET NEXT ACTION BY SHORTEST DURATION TO NEXT EVENT
    nextTimers.sort((a, b) => a.getNextTime().compareTo(b.getNextTime()));

    String nextText = nextTimers.isEmpty
        ? ""
        : FormatDuration.format(nextTimers[0].getNextTime());

    return nextText;
  }

  Future<void> StartTimer() async {
    //_callBack = callBack;
    _isRunning = true;
    // TODO - will need to save state so can resume with correct time
    NotificationManager.displayDelayedFullscreen(
        getTotalTimeLeft(), "FINISHED", "FINISHED");
    //NotificationManager.displayUpdate("update ticker", "update", this);
    _dateTime = DateTime.now();
    for (TimerItem i in _ingredients) {
      i.startTimer();
    }
    _updateTick();

    // TODO : Build List of notification times and schedule - should all notifications be handled by the group
    // _initialiseNotifications();

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!_isRunning) {
        timer.cancel();
        _isRunning = false;
        return;
      }

      // THROW UPDATE
      _updateTick();

      if (elapsed > getTotalTime()) {
        timer.cancel();
        _isRunning = false;
      }
    });
  }

  void _updateTick() {
    Duration increment = DateTime.now().difference(_dateTime);
    for (TimerItem i in _ingredients) {
      i.updateTimer(increment);
    }
    _dateTime = DateTime.now();
    saveState();
    onUpdate();
  }

  void _initialiseNotifications() {
    NotificationManager.stopAllNotifications();

    if (!isRunning) return;
    // CREATE MAP OF EVENTs AND DURATIONS
    List<TimerEvent> events = [];
    for (TimerItem timer in _ingredients) {
      // BUILD EVENT LIST
      events.addAll(timer.getEvents());
    }
    // SORT & FILTER EVENT LIST AND COMBINE

    // SCHEDULE EVENTS
    for (TimerEvent event in events) {
      // BUILD EVENT LIST
      NotificationManager.displayDelayedFullscreen(event.eventTime,
          event.item.title, "${event.eventName}  ${event.item.title}");
    }
    NotificationManager.displayDelayedFullscreen(
        getTotalTimeLeft(), "FINISHED", "All FINISHED");
  }

  void pauseTimer() {
    for (TimerItem i in _ingredients) {
      i.stopTimer();
    }
    // _callBack!(this);
    _isRunning = false;
    saveState();
    NotificationManager.stopAllNotifications();
    SoundManager.stop();
    onUpdate();
  }

  void restartTimer() {
    for (TimerItem i in _ingredients) {
      i.resetTimer();
    }

    sortTimers();
    // _callBack!(this);
    _isRunning = false;
    saveState();
    NotificationManager.stopAllNotifications();
    SoundManager.stop();
    onUpdate();
  }

  void onUpdate() {
    timerGroupUpdateEvent.add(this);
  }

  // PERSISTANCE

  TimerGroup.fromJson(String? key, Map<dynamic, dynamic> json)
      : id = key,
        title = json['title'] as String,
        _timersIds =
            (jsonDecode(json['timers']) as List<dynamic>).cast<String>();

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'timers':
            jsonEncode(_ingredients.map((entry) => "${entry.id}").toList()),
      };

  bool hasTimer(TimerItem timer) {
    return _ingredients.where((element) => timer.id == element.id).isNotEmpty;
  }

  void initialiseNotifications() {
    _initialiseNotifications();
  }
}
