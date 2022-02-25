package com.blackAngryDog.allTogetherTimer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.blackAngryDog.allTogetherTimer/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->

            if (true) {
               // FlutterActivity.createDefaultIntent(this)


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


            } else {
                result.notImplemented()
            }
        }

    }
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
