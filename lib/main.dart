import 'package:all_together_cooking_timer/model/timer.dart';
import 'package:all_together_cooking_timer/widgets/edit_timer.dart';

import 'package:flutter/material.dart';

import 'model/timer_group.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _timer = '';

  final TimerGroup _currMeal = TimerGroup();

  _MyHomePageState() {
    _initState();
  }

  void _initState() {
    _currMeal.addTimer(TimerItem(
        "Sausages", const Duration(minutes: 1, seconds: 0), Duration.zero));
    _currMeal.addTimer(TimerItem(
        "Chips",
        const Duration(minutes: 0, seconds: 15),
        const Duration(minutes: 0, seconds: 15)));
  }

  void _incrementCounter() {
    _currMeal.StartTimer(_timerUpdate);
    print("est");
    setState(() {
      _counter--;
    });
  }

  void _timerUpdate(TimerGroup meal) {
    setState(() {
      _timer = meal.getTotalTimeLeft().toString();
    });
  }

  void _addItemPressed(BuildContext ctx, TimerItem timer) {
    showModalBottomSheet(
        context: ctx,
        builder: (_) {
          return GestureDetector(
            child: EditTimer(_onTimerAdded, timer),
            onTap: () {},
            behavior: HitTestBehavior.opaque,
          );
        });
  }

  void _onDeletePressed(TimerItem timer) {
    setState(() {
      // TODO - add new time or update timer
      _currMeal.removeTimer(timer);
    });
  }

  void _onTimerAdded(TimerItem newTimer) {
    _currMeal.addTimer(newTimer);
    setState(() {
      // TODO - add new time or update timer
      _timer = _currMeal.getTotalTimeLeft().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
              '$_timer',
              style: Theme.of(context).textTheme.headline4,
            ),
            Container(
              height: 400,
              child: _currMeal.ingredients.isEmpty
                  ? Text("No Data")
                  : ListView.builder(
                      itemBuilder: (ctx, index) {
                        return Card(
                          child: ListTile(
                            title: Text(
                              _currMeal.ingredients[index].title,
                            ),
                            subtitle: Text(
                              _currMeal.ingredients[index].getTimerText(),
                            ),
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _addItemPressed(
                                        ctx,
                                        _currMeal.ingredients[index],
                                      );
                                    },
                                    icon: const Icon(Icons.timer),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _onDeletePressed(
                                        _currMeal.ingredients[index],
                                      );
                                    },
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: _currMeal.ingredients.length,
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Visibility(
            visible: !_currMeal.isRunning,
            child: FloatingActionButton(
              onPressed: () => _addItemPressed(
                context,
                TimerItem('_title', Duration.zero, Duration.zero),
              ),
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ),
          FloatingActionButton(
            onPressed: () => {
              if (!_currMeal.isRunning)
                {_currMeal.StartTimer(_timerUpdate)}
              else
                {_currMeal.PauseTimer()}
            },
            tooltip: 'Start',
            child: _currMeal.isRunning
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
