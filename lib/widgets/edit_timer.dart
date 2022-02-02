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
    setState(() {
      widget.item.runTime = time;
    });
  }

  showPickerNumber(BuildContext context) {
    Picker(
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
        hideHeader: false,
        height: 300,
        itemExtent: 20,
        magnification: 3,
        textAlign: TextAlign.start,
        title: Text("Please Select"),
        selectedTextStyle: TextStyle(color: Colors.blue),
        onConfirm: (Picker picker, List value) {
          print(value.toString());
          print(picker.getSelectedValues());
        }).showModal(context);
  }

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
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 25),
          child: TextFormField(
            decoration: InputDecoration(hintText: 'adddrss'),
            autofocus: false,
            controller: titleController,
          ),
        ),

        /*Container(
      height: 100,
      child: CupertinoTimerPicker(
        initialTimerDuration: widget.item.runTime,
        mode: CupertinoTimerPickerMode.hms,
        onTimerDurationChanged: (Duration value) {
          widget.item.runTime = value;
          // TODO - update duration for timer (how to link which duration is setting)
        },
      ),
    ),
    PickerWidget(
      data: Picker(
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
          hideHeader: false,
          title: Text("Please Select"),
          itemExtent: 2,
          selectedTextStyle: TextStyle(color: Colors.blue),
          onConfirm: (Picker picker, List value) {
            print(value.toString());
            print(picker.getSelectedValues());
          }),
      child: Text("chils"),
    ),

     */
        TextButton(
          onPressed: () {
            //_showTimerPicker(widget.item.runTime);
            //showPickerNumber(context);
            _showTimerPicker(widget.item.runTime,
                (Duration duration) => {widget.item.runTime = duration});
          },
          child: Text('Cook Time ${widget.item.runTime}'),
        ),
        TextButton(
          onPressed: () {
            _showTimerPicker(widget.item.restTime,
                (Duration duration) => {widget.item.restTime = duration});
          },
          child: Text('Rest Time ${widget.item.restTime}'),
        ),
        TextButton(
          onPressed: _onSubmit,
          child: Text('Finish'),
        ),
      ],
    );
  }
}
