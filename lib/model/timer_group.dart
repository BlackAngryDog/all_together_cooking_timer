import 'dart:async';
import 'dart:convert';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:all_together_cooking_timer/utils/sound_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

// to Control our Stream
StreamController timerGroupEventStream =
    StreamController<TimerGroup>.broadcast();
// this is our stream

class TimerGroup {
  String title = "Timer Group";

  String? id;
  List<String> _timersIds = [];
  List<TimerItem> _ingredients = [];
  List<TimerItem> get ingredients => _ingredients;
  Stream stream = timerGroupEventStream.stream;

  DateTime _dateTime = DateTime.now();
  //final StreamController<int> updateStream = StreamController<int>.broadcast();

  TimerGroup();

  Duration get elapsed => getElapsedTime();

  //Function(TimerGroup _meal)? _callBack;

  Function()? onTimerAdded;

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
    bool _running = await _getDate() != null;
    if (_running) StartTimer();
  }

  void addTimer(TimerItem item) {
    // TODO - consider adding async load funtion that accepts a key for persistance rather than init function.
    if (!_ingredients.contains(item)) {
      _ingredients.add(item);
    }
    onTimerAdded!();
    updateTimers();
  }

  void removeTimer(TimerItem timer) {
    _ingredients.removeWhere((t) => t.id == timer.id);
    onTimerAdded!();
    updateTimers();
  }

  void updateTimers() {
    // Sort items by duration, assign start delay
    _ingredients.sort((a, b) => b.totalTime.compareTo(a.totalTime));
    Duration max = getTotalTime();
    for (TimerItem i in _ingredients) {
      i.setDelay(max);
    }
    _onUpdate();
  }

  int getProgress() {
    int total = getTotalTime().inMilliseconds;
    if (total == 0) return 0;
    return ((elapsed.inMilliseconds / total) * 100).round();
  }

  Duration getTotalTime() {
    return _ingredients.isEmpty ? Duration.zero : _ingredients[0].totalTime;
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

  Future<DateTime?> _getDate() async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    final int startTime = (prefs.getInt('start_time') ?? 0);
    print('start time = $startTime');
    return startTime == 0
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(startTime);
  }

  Future<void> _saveDate(DateTime? time) async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    prefs.setInt('start_time', time == null ? 0 : time.microsecondsSinceEpoch);
  }

  Future<void> StartTimer() async {
    //_callBack = callBack;
    _isRunning = true;

    _dateTime = await _getDate() ?? DateTime.now();

    // TODO - will need to save state so can resume with correct time
    NotificationManager.setNotification(getTotalTime(), "FINISHED", "FINISHED");
    NotificationManager.displayUpdate("update ticker", "update", this);

    for (TimerItem i in _ingredients) {
      i.startTimer();
    }
    _updateTimers();

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!_isRunning) {
        timer.cancel();
        _isRunning = false;
        return;
      }

      // THROW UPDATE
      _updateTimers();

      if (elapsed > getTotalTime()) {
        timer.cancel();
        _isRunning = false;
      }
    });
  }

  void _updateTimers() {
    Duration increment = DateTime.now().difference(_dateTime);
    for (TimerItem i in _ingredients) {
      i.updateTimer(increment);
    }
    _dateTime = DateTime.now();
    if (_isRunning) _saveDate(_dateTime);
    _onUpdate();
  }

  void pauseTimer() {
    for (TimerItem i in _ingredients) {
      i.stopTimer();
    }
    // _callBack!(this);
    _isRunning = false;
    SoundManager.stop();
    _onUpdate();
  }

  void restartTimer() {
    for (TimerItem i in _ingredients) {
      i.resetTimer();
    }

    updateTimers();
    // _callBack!(this);
    _isRunning = false;
    _saveDate(null);
    SoundManager.stop();
    _onUpdate();
    print(toJson());
  }

  void _onUpdate() {
    timerGroupEventStream.add(this);
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
    for (TimerItem i in _ingredients) {
      i.initialiseNotification();
    }
  }
}
