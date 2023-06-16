package vn.vihat.omicall.omicallsdk

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.requestPermissions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import vn.vihat.omicall.omicallsdk.constants.*
import vn.vihat.omicall.omicallsdk.state.CallState
import vn.vihat.omicall.omicallsdk.video_call.FLLocalCameraFactory
import vn.vihat.omicall.omicallsdk.video_call.FLRemoteCameraFactory
import vn.vihat.omicall.omisdk.OmiAccountListener
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiListener
import vn.vihat.omicall.omisdk.service.NotificationService
import vn.vihat.omicall.omisdk.utils.OmiSDKUtils
import vn.vihat.omicall.omisdk.utils.OmiStartCallStatus
import vn.vihat.omicall.omisdk.utils.SipServiceConstants
import java.util.*

/** OmicallsdkPlugin */
class OmicallsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener, OmiListener {

    private lateinit var channel: MethodChannel
    private var activity: FlutterActivity? = null
    private var applicationContext: Context? = null
    private val mainScope = CoroutineScope(Dispatchers.Main)

    override fun incomingReceived(callerId: Int?, phoneNumber: String?, isVideo: Boolean?) {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(
                CALL_STATE_CHANGED, mapOf(
                    "isVideo" to isVideo,
                    "status" to CallState.incoming.value,
                    "callerNumber" to phoneNumber,
                )
            )
        }
    }

    override fun networkHealth(stat: Map<String, *>, quality: Int) {
        channel.invokeMethod(CALL_QUALITY, mapOf(
            "quality" to quality,
            "stat" to stat,
        ))
    }

    override fun onCallEnd(callInfo: MutableMap<String, Any?>, statusCode: Int) {
        callInfo["status"] = CallState.disconnected.value
        channel.invokeMethod(CALL_STATE_CHANGED, callInfo)
    }

    override fun onCallEstablished(
        callerId: Int,
        phoneNumber: String?,
        isVideo: Boolean?,
        startTime: Long,
        transactionId: String?,
    ) {
        Handler().postDelayed({
            Log.d("aaaa", transactionId ?: "")
            channel.invokeMethod(
                CALL_STATE_CHANGED, mapOf(
                    "callerNumber" to phoneNumber,
                    "status" to CallState.confirmed.value,
                    "isVideo" to isVideo,
                    "transactionId" to transactionId,
                )
            )
        }, 500)
        Log.d("omikit", "onCallEstablished: ")
    }

    override fun onConnecting() {
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "status" to CallState.connecting.value,
                "isVideo" to NotificationService.isVideo,
                "callerNumber" to "",
            )
        )
    }

    override fun onHold(isHold: Boolean) {
    }

    override fun onMuted(isMuted: Boolean) {
        channel.invokeMethod(
            MUTED, mapOf(
                "isMuted" to isMuted,
            )
        )
        Log.d("omikit", "onMuted: $isMuted")
    }

    override fun onOutgoingStarted(callerId: Int, phoneNumber: String?, isVideo: Boolean?) {
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "status" to CallState.calling.value,
                "isVideo" to isVideo,
                "callerNumber" to "",
            )
        )
    }

    override fun onRinging(callerId: Int, transactionId: String?) {
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "status" to CallState.early.value,
                "isVideo" to NotificationService.isVideo,
                "callerNumber" to "",
            )
        )
    }

    override fun onSwitchBoardAnswer(sip: String) {
        channel.invokeMethod(
            SWITCHBOARD_ANSWER, mapOf(
                "sip" to sip,
            )
        )
    }

    override fun onVideoSize(width: Int, height: Int) {

    }

    private val accountListener = object : OmiAccountListener {
        override fun onAccountStatus(online: Boolean) {
            Log.d("aaa", "Account status $online")
        }
    }


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "omicallsdk")
        channel.setMethodCallHandler(this)
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "omicallsdk/local_camera_view",
                FLLocalCameraFactory(flutterPluginBinding.binaryMessenger)
            )
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "omicallsdk/remote_camera_view",
                FLRemoteCameraFactory(flutterPluginBinding.binaryMessenger)
            )
        OmiClient(applicationContext!!)
        OmiClient.instance.addCallStateListener(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "action") {
            handleAction(call, result)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleAction(call: MethodCall, result: Result) {
        val data = call.arguments as HashMap<String, Any>
        val dataOmi = data["data"] as HashMap<String, Any>
        when (data["actionName"]) {
            START_SERVICES -> {
                OmiClient.instance.addAccountListener(accountListener)
                result.success(true)
            }
            GET_INITIAL_CALL -> {
                val callInfo = OmiClient.instance.getCurrentCallInfo()
                result.success(callInfo)
            }
            CONFIG_NOTIFICATION -> {
                val notificationIcon = dataOmi["notificationIcon"] as? String
                val prefix = dataOmi["prefix"] as? String
                val incomingBackgroundColor = dataOmi["incomingBackgroundColor"] as? String
                val incomingAcceptButtonImage = dataOmi["incomingAcceptButtonImage"] as? String
                val incomingDeclineButtonImage = dataOmi["incomingDeclineButtonImage"] as? String
                val prefixMissedCallMessage = dataOmi["prefixMissedCallMessage"] as? String
                val backImage = dataOmi["backImage"] as? String
                val userImage = dataOmi["userImage"] as? String
                val userNameKey = dataOmi["userNameKey"] as? String
                val channelId = dataOmi["channelId"] as? String
                OmiClient.instance.configPushNotification(
                    notificationIcon = notificationIcon ?: "",
                    prefix = prefix ?: "Cuộc gọi tới từ: ",
                    incomingBackgroundColor = incomingBackgroundColor ?: "#FFFFFFFF",
                    incomingAcceptButtonImage = incomingAcceptButtonImage ?: "join_call",
                    incomingDeclineButtonImage = incomingDeclineButtonImage ?: "hangup",
                    backImage = backImage ?: "ic_back",
                    userImage = userImage ?: "calling_face",
                    prefixMissedCallMessage = prefixMissedCallMessage ?: "Cuộc gọi nhỡ từ",
                    userNameKey = userNameKey ?: "",
                    channelId = channelId ?: "",
                    ringtone = null,
                )
                result.success(true)
            }
            INIT_CALL_USER_PASSWORD -> {
                val userName = dataOmi["userName"] as? String
                val password = dataOmi["password"] as? String
                val realm = dataOmi["realm"] as? String
                val host = dataOmi["host"] as? String
                val isVideo = dataOmi["isVideo"] as? Boolean
                if (userName != null && password != null && realm != null && host != null) {
                    OmiClient.register(
                        userName,
                        password,
                        realm,
                        isVideo ?: true,
                        host,
                    )
                }
                requestPermission(isVideo ?: true)
                result.success(true)
            }
            INIT_CALL_API_KEY -> {
                mainScope.launch {
                    var loginResult = false
                    val usrName = dataOmi["fullName"] as? String
                    val usrUuid = dataOmi["usrUuid"] as? String
                    val apiKey = dataOmi["apiKey"] as? String
                    val isVideo = dataOmi["isVideo"] as? Boolean
                    withContext(Dispatchers.Default) {
                        try {
                            if (usrName != null && usrUuid != null && apiKey != null) {
                                loginResult = OmiClient.registerWithApiKey(
                                    apiKey = apiKey,
                                    userName = usrName,
                                    uuid = usrUuid,
                                    isVideo ?: true,
                                )
                            }
                        } catch (_: Throwable) {

                        }
                    }
                    requestPermission(isVideo ?: true)
                    result.success(loginResult)
                }
            }
            GET_INITIAL_CALL -> {
                result.success(false)
            }
            UPDATE_TOKEN -> {
                mainScope.launch {
                    val deviceTokenAndroid = dataOmi["fcmToken"] as String
                    withContext(Dispatchers.Default) {
                        try {
                            OmiClient.instance.updatePushToken(
                                "",
                                deviceTokenAndroid,
                            )
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(true)
                }
            }
            START_CALL -> {
                val phoneNumber = dataOmi["phoneNumber"] as String
                val isVideo = dataOmi["isVideo"] as Boolean
                val startCallResult = OmiClient.instance.startCall(phoneNumber, isVideo)
                result.success(startCallResult.value)
            }
            JOIN_CALL -> {
                OmiClient.instance.pickUp()
                result.success(true)
            }
            END_CALL -> {
                val callInfo = OmiClient.instance.hangUp()
                result.success(callInfo)
            }
            TOGGLE_MUTE -> {
                mainScope.launch {
                    var newStatus: Boolean? = null
                    withContext(Dispatchers.Default) {
                        try {
                            newStatus = OmiClient.instance.toggleMute()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(newStatus)
                    channel.invokeMethod(MUTED, newStatus)
                }
            }
            TOGGLE_SPEAK -> {
                val newStatus = OmiClient.instance.toggleSpeaker()
                result.success(newStatus)
                channel.invokeMethod(SPEAKER, newStatus)
            }
            REGISTER -> {}
            SEND_DTMF -> {
                val character = dataOmi["character"] as String
                var characterCode: Int? = character.toIntOrNull()
                if (character == "*") {
                    characterCode = 10
                }
                if (character == "#") {
                    characterCode = 11
                }
                if (characterCode != null) {
                    OmiClient.instance.sendDtmf(characterCode)
                }
                result.success(true)
            }
            SWITCH_CAMERA -> {
                OmiClient.instance.switchCamera()
                channel.invokeMethod(CAMERA_STATUS, true)
            }
            TOGGLE_VIDEO -> {
                OmiClient.instance.toggleCamera()
            }
            INPUTS -> {
                val inputs = OmiClient.instance.getAudioInputs()
                val allAudios = inputs.map {
                    mapOf(
                        "name" to it.first,
                        "id" to it.second,
                    )
                }.toTypedArray()
                result.success(allAudios)
            }
            OUTPUTS -> {
                val inputs = OmiClient.instance.getAudioOutputs()
                val allAudios = inputs.map {
                    mapOf(
                        "name" to it.first,
                        "id" to it.second,
                    )
                }.toTypedArray()
                result.success(allAudios)
            }
            SET_INPUT -> {

            }

            SET_OUTPUT -> {

            }
            START_CALL_WITH_UUID -> {
                mainScope.launch {
                    var callResult : OmiStartCallStatus? = null
                    withContext(Dispatchers.Default) {
                        try {
                            val uuid = dataOmi["usrUuid"] as String
                            val isVideo = dataOmi["isVideo"] as Boolean
                            callResult =
                                OmiClient.instance.startCallWithUuid(
                                    uuid = uuid,
                                    isVideo = isVideo
                                )
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult?.value ?: 0)
                }
            }
            LOG_OUT -> {
                ///implement later
                mainScope.launch {
                    withContext(Dispatchers.Default) {
                        try {
                            OmiClient.instance.logout()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(true)
                }
            }
            GET_CURRENT_USER -> {
                mainScope.launch {
                    var callResult: Any? = null
                    withContext(Dispatchers.Default) {
                        try {
                            callResult = OmiClient.instance.getCurrentUser()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult)
                }
            }
            GET_GUEST_USER -> {
                mainScope.launch {
                    var callResult: Any? = null
                    withContext(Dispatchers.Default) {
                        try {
                            callResult = OmiClient.instance.getIncomingCallUser()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult)
                }
            }
            GET_USER_INFO -> {
                mainScope.launch {
                    var callResult: Any? = null
                    withContext(Dispatchers.Default) {
                        try {
                            val phone = dataOmi["phone"] as String
                            callResult = OmiClient.instance.getUserInfo(phone)
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult)
                }
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        OmiClient.instance.removeCallStateListener(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    companion object {
        fun onDestroy() {
//            OmiClient.instance.disconnect()
        }

        fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray,
            act: FlutterActivity,
        ) {
            OmiSDKUtils.handlePermissionRequest(requestCode, permissions, grantResults, act)
        }
    }

    private fun requestPermission(isVideo: Boolean) {
        var permissions = arrayOf(
            Manifest.permission.USE_SIP,
            Manifest.permission.CALL_PHONE,
            Manifest.permission.MODIFY_AUDIO_SETTINGS,
            Manifest.permission.RECORD_AUDIO,
        )
        if (isVideo) {
            permissions = permissions.plus(Manifest.permission.CAMERA)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions = permissions.plus(Manifest.permission.POST_NOTIFICATIONS)
        }
        requestPermissions(
            activity!!,
            permissions,
            0,
        )
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if (intent.hasExtra(SipServiceConstants.PARAM_NUMBER)) {
            //do your Stuff
            channel.invokeMethod(
                CLICK_MISSED_CALL,
                mapOf(
                    "callerNumber" to intent.getStringExtra(SipServiceConstants.PARAM_NUMBER),
                    "isVideo" to intent.getBooleanExtra(SipServiceConstants.PARAM_IS_VIDEO, false),
                ),
            )
        }
        return false
    }
}
