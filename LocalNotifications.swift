//
//  LocalNotifications.swift
//  noob
//
//  Created by localadmin on 14.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit

class LocalNotifications: NSObject {
  func doNotification() {
    UNUserNotificationCenter.current().getNotificationSettings { (settings) in
      let status = settings.authorizationStatus
      if status == .denied || status == .notDetermined {
        DispatchQueue.main.async(execute: {
          print("What the foobar, notifcation permissions ",status)
        })
      }
      let content = UNMutableNotificationContent()
      content.title = "What, where, when, how"
      content.body = "No it cannot be true"
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4.0, repeats: false)
      let id = "nil"
      let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(request) {(error) in
        print("error ",error)
      }
    }
  }
}
