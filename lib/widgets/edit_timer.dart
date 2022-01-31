import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';

class EditTimer extends StatefulWidget {
  final Function(TimerItem timer) onAddTimer;
  final TimerItem item;

  const EditTimer(this.onAddTimer, this.item, {Key? key}) : super(key: key);

  @override
  _EditTimerState createState() => _EditTimerState();
}

class _EditTimerState extends State<EditTimer> {
  late TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.item.title);
  }

  void _onSubmit() {
    print(widget.item.runTime);

    widget.item.title = titleController.text;

    widget.onAddTimer(widget.item);
    Navigator.of(context).pop();
  }

  void _onSetTime(Duration time, String type) {
    // TODO - setup which time - maybe 2 funcs ?
    widget.item.runTime = time;
  }

  showPickerNumber(BuildContext context) {
    Picker(
        squeeze: 1,
        adapter: NumberPickerAdapter(data: [
          NumberPickerColumn(
            begin: 0,
            end: 12,
            suffix: Text(' h'),
          ),
          NumberPickerColumn(
            begin: 0,
            end: 60,
            suffix: Text(' m'),
          ),
          NumberPickerColumn(
            begin: 0,
            end: 60,
            suffix: Text(' s'),
          ),
        ]),
        hideHeader: true,
        title: Text("Please Select"),
        selectedTextStyle: TextStyle(color: Colors.blue),
        onConfirm: (Picker picker, List value) {
          print(value.toString());
          print(picker.getSelectedValues());
        }).showModal(context);
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
                )
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
          TextFormField(
            decoration: const InputDecoration(labelText: 'Name'),
            controller: titleController,
            keyboardType: TextInputType.datetime,
          ),
          CupertinoTimerPicker(
            initialTimerDuration: widget.item.runTime,
            onTimerDurationChanged: (Duration value) {
              widget.item.runTime = value;
              // TODO - update duration for timer (how to link which duration is setting)
            },
          ),
          TextButton(
            onPressed: () {
              //_showTimerPicker(widget.item.runTime);
              showPickerNumber(context);
            },
            child: Text('Cook Time ${widget.item.runTime}'),
          ),
          TextButton(
            onPressed: () {
              _showTimerPicker(widget.item.restTime);
            },
            child: Text('Rest Time ${widget.item.restTime}'),
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
