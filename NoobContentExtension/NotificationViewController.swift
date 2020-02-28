//
//  NotificationViewController.swift
//  NoobContentExtension
//
//  Created by localadmin on 28.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    var content = UNMutableNotificationContent()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
      self.label!.text = notification.request.content.body
      content = notification.request.content.mutableCopy() as! UNMutableNotificationContent
      
    }

}
