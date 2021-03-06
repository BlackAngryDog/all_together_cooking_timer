import 'dart:ffi';

import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/model/timer_dao.dart';
import 'package:all_together_cooking_timer/model/timer_group.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddTimerPage extends StatefulWidget {
  //final Function(TimerItem timer) onAddTimer;
  final TimerItem item;
  final TimerGroup? group;

  const AddTimerPage(this.item, {Key? key, this.group}) : super(key: key);

  @override
  _AddTimerPageState createState() => _AddTimerPageState();
}

class _AddTimerPageState extends State<AddTimerPage> {
  late TextEditingController titleController;

  late Duration originalTime;
  late Duration originalRest;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.item.title);
    originalTime = widget.item.runTime;
    originalRest = widget.item.restTime;
  }

  //void initState() {
  // titleController = TextEditingController(text: item.title);
  //}

  void _onSubmit() {
    widget.item.title = titleController.text;
    TimerDao().saveTimer(widget.item);
    //onAddTimer(item);
    widget.group?.addTimer(widget.item);
    Navigator.of(context).pop();
  }

  void _onCancel() {
    widget.item.runTime = originalTime;
    widget.item.restTime = originalRest;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: TextFormField(
                  decoration: InputDecoration(hintText: 'Name'),
                  controller: titleController,
                ),
                trailing: Checkbox(
                  checkColor: Colors.white,
                  value: widget.item.isStandAlone,
                  onChanged: (bool? value) {
                    setState(() {
                      widget.item.isStandAlone = value == true;
                    });
                  },
                ),
              ),
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
