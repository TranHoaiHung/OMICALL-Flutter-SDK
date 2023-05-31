import Flutter
import UIKit
import CallKit
import AVFoundation
import PushKit
import UserNotifications
import OmiKit

public class SwiftOmikitPlugin: NSObject, FlutterPlugin {

  @objc public static var instance: SwiftOmikitPlugin!
  private var channel: FlutterMethodChannel!

  public static func register(with registrar: FlutterPluginRegistrar) {
      if (instance == nil) {
          instance = SwiftOmikitPlugin()
      }
      instance!.channel = FlutterMethodChannel(name: "omicallsdk", binaryMessenger: registrar.messenger())
      registrar.addMethodCallDelegate(instance, channel: instance!.channel)
      let localFactory = FLLocalCameraFactory(messenger: registrar.messenger())
      registrar.register(localFactory, withId: "omicallsdk/local_camera_view")
      let remoteFactory = FLRemoteCameraFactory(messenger: registrar.messenger())
      registrar.register(remoteFactory, withId: "omicallsdk/remote_camera_view")
      registrar.addApplicationDelegate(instance)
  }


  func sendEvent(_ event: String, _ body: [String : Any]) {
      DispatchQueue.main.async {[weak self] in
          guard let self = self else { return }
          self.channel.invokeMethod(event, arguments: body)
      }
  }
    
  func sendCameraEvent() {
      let cameraStatus = CallManager.shareInstance().videoManager?.isCameraOn ?? false
      channel.invokeMethod(VIDEO, arguments: cameraStatus)
  }
    
  func sendMuteStatus() {
      if let call = CallManager.shareInstance().getAvailableCall() {
          if let isMuted = call.muted as? Bool {
              channel.invokeMethod(MUTED, arguments: isMuted)
          }
      }
  }
    
  func sendSpeakerStatus() {
      channel.invokeMethod(SPEAKER, arguments: CallManager.shareInstance().isSpeaker)
  }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if(call.method != "action") {
          return
      }
      print("\(call.arguments)")
      guard  let data =  call.arguments as? [String:Any] else  {
          return
      }
      print("\(data["data"])")
      guard let dataOmi = data["data"] as? [String:Any] else {
          return
      }
      print("\(data["actionName"])")
      guard let action = data["actionName"] as? String else {
          return
      }

      switch(action) {
      case START_SERVICES:
          CallManager.shareInstance().registerNotificationCenter()
          result(true)
          break
      case CONFIG_NOTIFICATION:
          CallManager.shareInstance().configNotification(data: dataOmi)
          result(true)
          break
      case UPDATE_TOKEN:
          CallManager.shareInstance().updateToken(params: dataOmi)
          result(true)
          break
      case INIT_CALL_API_KEY:
          let value = CallManager.shareInstance().initWithApiKeyEndpoint(params: dataOmi)
          result(value)
          break
      case INIT_CALL_USER_PASSWORD:
          let value = CallManager.shareInstance().initWithUserPasswordEndpoint(params: dataOmi)
          result(value)
          break
      case GET_INITIAL_CALL:
          if let call = CallManager.shareInstance().getAvailableCall() {
              let data : [String: Any] = [
                  "callerNumber" : call.callerNumber,
                  "status": call.lastStatus,
                  "muted": call.muted,
                  "speaker": call.speaker,
                  "isVideo": call.isVideo
              ]
              result(data)
          } else {
              result(false)
          }
          break
      case START_CALL:
          let phoneNumber = dataOmi["phoneNumber"] as! String
          var isVideo = false
          if let isVideoCall = dataOmi["isVideo"] as? Bool {
              isVideo = isVideoCall
          }
          CallManager.shareInstance().startCall(phoneNumber, isVideo: isVideo) { callResult in
              self.sendMuteStatus()
              result(callResult)
          }
          break
      case END_CALL:
          let callInfo = CallManager.shareInstance().endAvailableCall()
          result(callInfo)
          break
      case TOGGLE_MUTE:
          CallManager.shareInstance().toggleMute()
          sendMuteStatus()
          if let call = CallManager.init().getAvailableCall() {
              result(call.muted)
          }
          break
      case TOGGLE_SPEAK:
          CallManager.shareInstance().toogleSpeaker()
          sendSpeakerStatus()
          if let call = CallManager.init().getAvailableCall() {
              result(call.speaker)
          }
          break
      case SEND_DTMF:
          CallManager.shareInstance().sendDTMF(character: dataOmi["character"] as! String)
          result(true)
          break
      case SWITCH_CAMERA:
          CallManager.shareInstance().switchCamera()
          result(true)
          break
      case CAMERA_STATUS:
          let status = CallManager.shareInstance().getCameraStatus()
          result(status)
          break
      case TOGGLE_VIDEO:
          let _ = CallManager.shareInstance().toggleCamera()
          sendCameraEvent()
          result(true)
          break
      case INPUTS:
          let inputs = CallManager.shareInstance().inputs()
          result(inputs)
          break
      case OUTPUTS:
          let outputs = CallManager.shareInstance().outputs()
          result(outputs)
          break
      case SET_OUTPUT:
          let id = dataOmi["id"] as! String
          CallManager.shareInstance().setOutput(id: id)
          result(true)
          break
      case SET_INPUT:
          let id = dataOmi["id"] as! String
          CallManager.shareInstance().setInput(id: id)
          result(true)
          break
      case JOIN_CALL:
          CallManager.shareInstance().joinCall()
          result(true)
      case START_CALL_WITH_UUID:
          let uuid = dataOmi["usrUuid"] as! String
          var isVideo = false
          if let isVideoCall = dataOmi["isVideo"] as? Bool {
              isVideo = isVideoCall
          }
          let callResult = CallManager.shareInstance().startCallWithUuid(uuid, isVideo: isVideo) { callResult in
              self.sendMuteStatus()
              result(callResult)
          }
          break
      case LOG_OUT:
          CallManager.shareInstance().logout()
          result(true)
          break
      case REGISTER_VIDEO_EVENT:
          CallManager.shareInstance().registerVideoEvent()
          result(true)
          break
      case REMOVE_VIDEO_EVENT:
          CallManager.shareInstance().removeVideoEvent()
          result(true)
          break
      case GET_CURRENT_USER:
          CallManager.shareInstance().getCurrentUser { data in
              result(data)
          }
          break
      case GET_GUEST_USER:
          CallManager.shareInstance().getGuestUser { data in
              result(data)
          }
          break
      case GET_USER_INFO:
          let phone = dataOmi["phone"] as! String
          CallManager.shareInstance().getUserInfo(phone: phone) { data in
              result(data)
          }
          break
      default:
          break
      }

  }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let callerNumer = userInfo["callerNumber"] as? String, let isVideo = userInfo["isVideo"] as? Bool {
            channel.invokeMethod(CLICK_MISSED_CALL, arguments: [
                "callerNumber": callerNumer,
                "isVideo": isVideo,
            ])
            completionHandler()
        }
    }
}

@objc public extension FlutterAppDelegate {
    func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                break
            case .denied:
                break
            case .notDetermined:
                center.delegate = self
                center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                    if (granted) {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            default: break
            }
        }
    }

}

