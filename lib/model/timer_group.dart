import 'dart:async';
import 'dart:convert';

import 'package:all_together_cooking_timer/main.dart';
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
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

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
    _elapsed = Duration(milliseconds: prefs.getInt('_elapsed') ?? 0);
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
    prefs.setInt('_elapsed', _elapsed.inMilliseconds);
    prefs.setInt(
        'start_time', !_isRunning ? 0 : _dateTime.microsecondsSinceEpoch);

    for (TimerItem i in _ingredients) {
      await i.saveState();
    }
    // GLOBAL FOR FOREGROUND
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
    _ingredients.sort((a, b) =>
        b.isStandAlone ? 1 : b.totalCookTime.compareTo(a.totalCookTime));
    Duration max = getTotalTime();
    for (TimerItem i in _ingredients) {
      i.setDelay(max);
    }
    //
    onUpdate();
  }

  void extendTimer(TimerItem timer, Duration amount) {
    // TODO - Add time - just extend cooking time?

    // get currtime left
    Duration currTimer = getTotalTimeLeft();

    MapEntry<String, Duration> nextState = timer.getCurrentState();
    if (nextState.key == 'Cook') {
      timer.run_times[nextState.key] =
          (timer.run_times[nextState.key] ?? Duration.zero) + amount;
    } else {
      return;
    }

    if (timer.isStandAlone) return;

    Duration offset = getTotalTimeLeft() - currTimer;
    print("offset is $offset from $currTimer to ${getTotalTimeLeft()}");

    for (TimerItem otherTimer in _ingredients) {
      if (timer == otherTimer || otherTimer.isStandAlone) continue;

      nextState = otherTimer.getCurrentState();
      if (nextState.key == "Waiting" || nextState.key == "Prep") {
        // CHECK IF REDUCTION IS GOING TO CUT INTO COOKING TIME.
        Duration os = amount;
        // TODO - Use wait left equation to check offset (how to handle prep) ?
        print(
            "other trt is ${otherTimer.totalRunTime + os} cook time is ${otherTimer.totalCookTime}");
        if (otherTimer.totalRunTime + os <= otherTimer.totalCookTime) {
          print("SKIPPING TO PREP");
          os = -(otherTimer.delayStart - elapsed);
        }
        otherTimer.delayStart += os;
        //} else {
        //  otherTimer.run_times["Rest"] = (otherTimer.run_times["Rest"] ?? Duration.zero) + offset;
      }
    }
    // _ingredients.sort((a, b) => b.totalRunTime.compareTo(a.totalRunTime));
  }

  void skipTimer(TimerItem timer) {
    // TODO - Can standalone skip ?
    if (timer.canSkip) {
      MapEntry<String, Duration> nextState = timer.getCurrentState();
      Duration offset = nextState.value - elapsed;

      // remove offset from curr state
      Duration currTimer = getTotalTimeLeft();

      offset = (timer.delayStart + (timer.run_times["Prep"] ?? Duration.zero)) -
          elapsed;
      print("Skipping $offset");
      timer.delayStart = elapsed;
      timer.run_times["Prep"] = Duration.zero;

      if (timer.isStandAlone) return;

      // TODO : Can we shuffle other items forward and bring cooking time down - then pass offset down to timer rest

      // TODO - ONLY SKIP THIS IF THE SKIIPED ITEM REDUCES OVERALL TIME (GET OFFSET AD A REDUCTION IN TOTAL TIME!)
      for (TimerItem otherTimer in _ingredients) {
        if (timer == otherTimer || otherTimer.isStandAlone) continue;

        nextState = otherTimer.getCurrentState();
        if (nextState.key == "Waiting") {
          // TOdo - should I only be skipping items with longer waits (i.e. waiting on this)
          print("Skipping other $offset");

          if (otherTimer.delayStart >= offset)
            otherTimer.delayStart -= offset;
          else
            otherTimer.delayStart = Duration.zero; // TODO - MIN CHECK?;

        }
      }
    }
    // Todo - Send update notifications.
  }

  int getProgress() {
    int total = getTotalTime().inMilliseconds;
    if (total == 0) return 0;
    return ((elapsed.inMilliseconds / total) * 100).round();
  }

  Duration getTotalTime() {
    Duration maxTime = Duration.zero;

    if (_ingredients.isEmpty) return maxTime;

    for (TimerItem i in _ingredients) {
      if (i.isStandAlone) continue;

      Duration runtime = i.totalCookTime;
      if (maxTime < runtime) maxTime = runtime;
    }

    return maxTime;
  }

  Duration getElapsedTime() {
    return _elapsed;
  }

  Duration getTotalTimeLeft() {
    // print('total time is ${getTotalTime()} elaps is $elapsed');
    return getTotalTime() - elapsed;
  }

  String getNextAction() {
    // Work out what action is coming next and return action and duration
    List<TimerItem> nextTimers = List<TimerItem>.from(_ingredients);
    nextTimers.removeWhere((element) => element.isStandAlone);
    //GET NEXT ACTION BY SHORTEST DURATION TO NEXT EVENT
    nextTimers.sort((a, b) => a.getNextTime().compareTo(b.getNextTime()));

    String nextText =
        nextTimers.isEmpty ? "" : nextTimers[0].getNextTimerEvent();

    return nextText;
  }

  String getNextActionTime() {
    // Work out what action is coming next and return action and duration
    List<TimerItem> nextTimers = List<TimerItem>.from(_ingredients);
    nextTimers.removeWhere((element) => element.isStandAlone);
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
    _elapsed += increment;

    for (TimerItem i in _ingredients) {
      i.updateTimer(increment);
    }
    _dateTime = DateTime.now();
    //MyApp.currElapsedSeconds = elapsed.inSeconds;
    //print(MyApp.currElapsedSeconds);
    saveState();

    if (!SoundManager.isPlaying && getProgress() >= 0) {
      //SoundManager.play();
    }

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
    events.sort((a, b) => a.eventTime.compareTo(b.eventTime));

    // SCHEDULE EVENTS
    for (var i = 0; i < events.length; i++) {
      // BUILD EVENT LIST
      TimerEvent event = events[i];
      Duration? timeToNext = i < events.length - 1
          ? events[i + 1].eventTime - event.eventTime
          : null;

      NotificationManager.displayDelayedFullscreen(event.eventTime,
          event.item.title, "${event.eventName}  ${event.item.title}",
          timeout: timeToNext);
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
    _elapsed = Duration.zero;
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
