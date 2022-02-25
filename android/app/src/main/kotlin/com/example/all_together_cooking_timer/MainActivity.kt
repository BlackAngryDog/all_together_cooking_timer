package com.blackAngryDog.allTogetherTimer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.AsyncTask
import android.app.ActivityManager
import android.content.Context


class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.blackAngryDog.allTogetherTimer/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->

            if (true) {
                GetWeatherTask(this).execute();

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

                if (processInfo.processName == packageName && processInfo.importance == 100) {
                    println("APP IS RUNNING");
                    return true;
                }else{
                    println("APP IS NOT RUNNING " + processInfo.pid);
                    moveToFront();
                    //activityManager.moveTaskToFront(processInfo.pid, ActivityManager.MOVE_TASK_WITH_HOME);
                }
            }
        }
        return false
    }


    protected fun moveToFront() {

            val activityManager: ActivityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val recentTasks: List<RunningTaskInfo> = activityManager.getRunningTasks(Integer.MAX_VALUE)
            for (i in 0 until recentTasks.size()) {
                Log.d("Executed app", ("Application executed : "
                        + recentTasks[i].baseActivity.toShortString()
                        ) + "\t\t ID: " + recentTasks[i].id.toString() + "")
                // bring to front
                if (recentTasks[i].baseActivity.toShortString().indexOf("yourproject") > -1) {
                    activityManager.moveTaskToFront(recentTasks[i].id, ActivityManager.MOVE_TASK_WITH_HOME)
                }
            }

    }

    class GetWeatherTask(activity:MainActivity) : AsyncTask<Unit, Unit, String>() {


        var activity: MainActivity = activity;
        override fun doInBackground(vararg params: Unit?): String? {
            println("hello ")
            Thread.sleep(15000)
            return null
        }



        override fun onPostExecute(result: String?) {
            super.onPostExecute(result)
            //val intent = Intent(context, ChangePasswordActivity::class.java)
            //intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            //context.startActivity(intent)
            if (activity.isAppRunning(activity, "com.blackAngryDog.allTogetherTimer")) {
                println("APP IS RUNNING")
                return
            };
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
