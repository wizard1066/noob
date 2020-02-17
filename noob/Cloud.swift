//
//  iCloud.swift
//  noob
//
//  Created by localadmin on 17.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import Foundation
import CloudKit

class Cloud: NSObject {

  var publicDB:CKDatabase!

  func fuck() {
    publicDB = CKContainer.default().publicCloudDatabase
  }

  func getDirectory() {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async {
                          print("error",error)
                        }
                        return
                      }
                      guard let results = results else { return }
                      for result in results {
                        print("results ",result)
                      }
    }
  }

}
