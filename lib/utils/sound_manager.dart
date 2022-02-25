import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class SoundManager {
  static bool isPlaying = false;

  static void play() {
    print("play shound");
    isPlaying = true;
    FlutterRingtonePlayer.play(
      android: AndroidSounds.alarm,
      ios: IosSounds.glass,
      looping: true, // Android only - API >= 28
      volume: 1, // Android only - API >= 28
      asAlarm: true, // Android only - all APIs
    );
  }

  static void stop() {
    isPlaying = false;
    FlutterRingtonePlayer.stop();
  }
}
