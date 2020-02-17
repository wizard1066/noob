//
//  AppDelegate.swift
//  noob
//
//  Created by localadmin on 14.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import UserNotifications
import AVKit
import MediaPlayer
import AudioToolbox


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .badge, .sound])
  }
  
  func application(_ application: UIApplication,
  didReceiveRemoteNotification userInfo: [AnyHashable : Any],
     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     debugPrint("Received: \(userInfo)")
   
//     do {
//         let audioSession = AVAudioSession.sharedInstance()
//         var volume: Float?
//
//         try audioSession.setActive(true)
//         volume = audioSession.outputVolume
//         print("vol ",volume)
//         MPVolumeView.setVolume(0.1)
//     } catch {
//         print("Error Setting Up Audio Session")
//     }
    completionHandler(.newData)
  }
  
  func application(_ application: UIApplication,
                   didFailToRegisterForRemoteNotificationsWithError error: Error) {
      // The token is not currently available.
      print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
//      self.disableRemoteNotificationFeatures()
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    registerForNotifications()
    
//    if #available(iOS 13.0, *) {
//      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .announcement, .criticalAlert, .provisional]) { (granted, error) in
//        if error != nil {
//          // display error
//        }
//      }
//    } else {
//      // Fallback on earlier versions
//    }
    return true
  }
  
  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
  
  func registerForNotifications() {
    
    let center  = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
      //          center.requestAuthorization(options: [.provisional]) { (granted, error) in
      if error == nil{
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
  }

  
  func application( _ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("Device Token: \n\(token)\n")
  }
  
  


}

extension MPVolumeView {
  static func setVolume(_ volume: Float) {
    let volumeView = MPVolumeView()
    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
      slider?.value = volume
    }
  }
}
