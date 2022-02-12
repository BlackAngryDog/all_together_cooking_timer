import 'dart:ffi';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddTimerPage extends StatefulWidget {
  //final Function(TimerItem timer) onAddTimer;
  final TimerItem item;

  const AddTimerPage(this.item, {Key? key}) : super(key: key);

  @override
  _AddTimerPageState createState() => _AddTimerPageState();
}

class _AddTimerPageState extends State<AddTimerPage> {
  late TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.item.title);
  }

  //void initState() {
  // titleController = TextEditingController(text: item.title);
  //}

  void _showTimerPicker(
      Duration duration, Function(Duration duration)? updateTimer) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: MediaQuery.of(context).copyWith().size.height * 0.3,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    height:
                        MediaQuery.of(context).copyWith().size.height * 0.15,
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
                ),
                TextButton(
                  onPressed: () {
                    //_onSetTime(duration, "any");
                    setState(() {
                      updateTimer!(duration);
                    });

                    Navigator.of(context).pop();
                  },
                  child: Text("Finished"),
                ),
              ],
            ),
          );
        });
  }

  void _onSubmit() {
    widget.item.title = titleController.text;
    TimerDao().saveTimer(widget.item);
    //onAddTimer(item);
    Navigator.of(context).pop();
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: InputDecoration(hintText: 'Name'),
              controller: titleController,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Cooking Time',
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).copyWith().size.height * 0.15,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child: CupertinoTimerPicker(
                  initialTimerDuration: widget.item.runTime,
                  onTimerDurationChanged: (Duration value) {
                    widget.item.runTime = value;
                    // TODO - update duration for timer (how to link which duration is setting)
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Rest Time',
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).copyWith().size.height * 0.15,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child: CupertinoTimerPicker(
                  initialTimerDuration: widget.item.restTime,
                  onTimerDurationChanged: (Duration value) {
                    widget.item.restTime = value;
                    // TODO - update duration for timer (how to link which duration is setting)
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    _onSubmit();
                  },
                  child: Text(
                    'Finish',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _onCancel();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
