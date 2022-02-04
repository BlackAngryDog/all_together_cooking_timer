import 'package:all_together_cooking_timer/main.dart';
import 'package:all_together_cooking_timer/utils/format_duration.dart';
import 'package:all_together_cooking_timer/utils/notification_manager.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

enum CookStatus { waiting, cooking, resting, finished }

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

      NotificationManager.displayUpdate(title, getNextTimerEvent());
      status = nextStatus;
/*
      FlutterRingtonePlayer.play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        looping: false, // Android only - API >= 28
        volume: 0.1, // Android only - API >= 28
        asAlarm: false, // Android only - all APIs
      );

 */

    }
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
    if (_elapsed < _totalTime - restTime) return CookStatus.resting;
    return CookStatus.finished;
  }

  //TODO - notify start, turn and rest events.
}
