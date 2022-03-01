package com.blackAngryDog.allTogetherTimer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.AsyncTask
import android.app.ActivityManager
//import android.app.ActivityManager.RunningAppProcessInfo

import android.content.Context


class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.blackAngryDog.allTogetherTimer/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->

            if (true) {
                var delay = call.argument<Int?>("time_left") ?: 0;
                println("APP CALLED DELEY $delay");
                StartAppTask(this, delay).execute();

               // FlutterActivity.createDefaultIntent(this)

                /*
                val am: AlarmManager = con.getSystemService(Context.ALARM_SERVICE) as AlarmManager

                val futureDate = Date(Date().getTime() + 86400000)
                futureDate.setHours(8)
                futureDate.setMinutes(0)
                futureDate.setSeconds(0)
                val intent = Intent(con, MyAppReciever::class.java)

                val sender: PendingIntent = PendingIntent.getBroadcast(con, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
                am.set(AlarmManager.RTC_WAKEUP, futureDate.getTimeInMillis(), sender)


                startActivity(
                        FlutterActivity
                                .withNewEngine()
                                .initialRoute("/")
                                .build(this)
                )


                result.success(50);

                val batteryLevel = 100;

                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }


                 */

            } else {
                result.notImplemented()
            }
        }

    }

    public fun isAppRunning(context: MainActivity, packageName: String): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.runningAppProcesses?.apply {
            for (processInfo in this) {

                if (processInfo.processName == packageName) {
                    println("APP IMPORTANCE ${processInfo.importance}");
                    if (processInfo.importance == 100) {
                        println("APP IS RUNNING - DO NOTHING");
                    } else {
                        processInfo
                        println("APP IS NOT RUNNING ");
                        activityManager.moveTaskToFront(context.getTaskId(), ActivityManager.MOVE_TASK_WITH_HOME);
                        //moveToFront();
                        //activityManager.moveTaskToFront(processInfo.pid, ActivityManager.MOVE_TASK_WITH_HOME);
                    }
                }
            }
        }
        return false
    }


    class StartAppTask(activity:MainActivity, delay:Int?) : AsyncTask<Unit, Unit, String>() {

        var activity: MainActivity = activity;
        var delay: Int =  delay ?: 0 ;
        override fun doInBackground(vararg params: Unit?): String? {
            println("start background thread - delay  " + delay);
            Thread.sleep(delay.toLong()*1000);
            return null
        }

        override fun onPostExecute(result: String?) {
            super.onPostExecute(result)
            println("check app running state");
            activity.isAppRunning(activity, "com.blackAngryDog.allTogetherTimer");
            return;
            activity.startActivity(
                    FlutterActivity
                            .withNewEngine()
                            .initialRoute("/")
                            .build(activity)
            )
        }



    }


/*
    private fun getBatteryLevel(): void {
        startActivity(
                FlutterActivity
                        .withNewEngine()
                        .initialRoute("/")
                        .build(this)
        )
    }

 */
/*
    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }

        return batteryLevel
    }


 */
    /*
       override fun onCreate(savedInstanceState: Bundle?) {
           super.onCreate(savedInstanceState)

           GeneratedPluginRegistrant.registerWith(this)

           MethodChannel(flutterEngine?.dartExecutor, "newOrder").setMethodCallHandler { call, result ->
              // if (call.method == "pushScreen") {
                   startActivity(
                           FlutterActivity
                                   .withNewEngine()
                                   .initialRoute("/TestPage")
                                   .build(this)
                   )
              // }
           }



    }
            */

}
