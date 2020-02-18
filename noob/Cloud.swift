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
  var privateDB: CKDatabase!

  override init() {
    publicDB = CKContainer.default().publicCloudDatabase
    privateDB = CKContainer.default().privateCloudDatabase
  }
  
  func search(name: String) {
      print("searching ",name)
    let predicate = NSPredicate(format: "name = %@", name)
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
                      if results.count == 0 {
                        print("no name ",name)
                      }
    }
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
  
  func saveRec(name: String, key:String) {
    let record = CKRecord(recordType: "directory")
    record.setObject(name as CKRecordValue, forKey: "name")
    record.setObject(key as CKRecordValue, forKey: "key")
    let modifyRecordsOperation = CKModifyRecordsOperation(
        recordsToSave: [record],
        recordIDsToDelete: nil)

        modifyRecordsOperation.modifyRecordsCompletionBlock =
        { records, recordIDs, error in
            if let err = error {
                print("error ",error)
//                self.notifyUser("Save Error", message:
//                    err.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    print("success ")
                }
            }
        }
        publicDB?.add(modifyRecordsOperation)
    }
   
//    func notifyUser(_ title: String, message: String) -> Void
//    {
//        let alert = UIAlertController(title: title,
//                      message: message,
//                  preferredStyle: .alert)
//
//        let cancelAction = UIAlertAction(title: "OK",
//                style: .cancel, handler: nil)
//
//        alert.addAction(cancelAction)
//        self.present(alert, animated: true,
//                    completion: nil)
//    }
    

}
