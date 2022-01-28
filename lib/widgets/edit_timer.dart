import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EditTimer extends StatefulWidget {
  final Function(TimerItem timer) onAddTimer;
  final TimerItem item;

  const EditTimer(this.onAddTimer, this.item, {Key? key}) : super(key: key);

  @override
  _EditTimerState createState() => _EditTimerState();
}

class _EditTimerState extends State<EditTimer> {
  void _onSubmit() {
    print(widget.item.runTime);
    widget.onAddTimer(widget.item);
    Navigator.of(context).pop();
  }

  void _onSetTime(Duration time, String type) {
    widget.item.runTime = time;
  }

  void _showTimerPicker(Duration duration) {
    showCupertinoModalPopup(
        context: context,
        builder: (BuildContext builder) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: MediaQuery.of(context).copyWith().size.height * 0.25,
                  width: double.infinity,
                  color: Colors.white,
                  child: CupertinoTimerPicker(
                    initialTimerDuration: duration,
                    onTimerDurationChanged: (Duration value) {
                      duration = value;
                      // TODO - update duration for timer (how to link which duration is setting)
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _onSetTime(duration, "any");
                    Navigator.of(context).pop();
                  },
                  child: Text('Finished'),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
          child: Column(
        children: [
          TextButton(
            onPressed: () {
              _showTimerPicker(widget.item.runTime);
            },
            child: Text('Pick Time'),
          ),
          TextButton(
            onPressed: _onSubmit,
            child: Text('Finish'),
          ),
        ],
      )),
    );
  }
}
