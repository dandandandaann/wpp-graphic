package com.danielfd.whatsapp_infographic

import android.content.Intent
import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.HashMap
import java.io.File
import kotlin.text.*


class MainActivity : FlutterActivity() {
    private var sharedData = HashMap<String, String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        // Handle intent when app is initially opened
        handleSendIntent(getIntent())

        MethodChannel(getFlutterView(), "app.channel.shared.data").setMethodCallHandler(
                object : MethodCallHandler {
                    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                        if (call.method.contentEquals("getSharedData")) {
                            result.success(sharedData)
                            sharedData.clear()
                        }
                    }
                }
        )
    }

    override fun onNewIntent(intent: Intent) {
        // Handle intent when app is resumed
        super.onNewIntent(intent)
        handleSendIntent(intent)
    }

    private fun handleSendIntent(intent: Intent) {
        var action = intent.getAction()
        var type = intent.getType()


        // We only care about sharing intent that contain plain text
        // if (action == Intent.ACTION_SEND && type != null) {
        if (action != null && type == "text/*") {
            for (i in 0 until intent.clipData.itemCount) {
                val uri = intent.clipData.getItemAt(i).uri
                if (!uri.toString().contains("export_chat"))
                    continue

                val inputStream = contentResolver.openInputStream(uri)
                val data = ByteArray(1024)
                var bytesRead = inputStream!!.read(data)

                var chatContent = StringBuilder()
                while (bytesRead != -1) {
                    chatContent.append(String(data))
                    bytesRead = inputStream.read(data)
                }

                sharedData.put("fileName", intent.getStringExtra(Intent.EXTRA_STREAM))
                sharedData.put("text", chatContent.toString())

                return
            }
        }
    }
}