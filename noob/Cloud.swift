//
//  iCloud.swift
//  noob
//
//  Created by localadmin on 17.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import Foundation
import CloudKit
import Combine

let pingPublisher = PassthroughSubject<String, Never>()
let dataPublisher = PassthroughSubject<Data, Never>()
let cloudPublisher = PassthroughSubject<[UInt8], Never>()
let debugPublisher = PassthroughSubject<[UInt8], Never>()


class Cloud: NSObject {
  
  var publicDB:CKDatabase!
  var privateDB: CKDatabase!
  var contentModel = ContentMode()
  
  override init() {
    super.init()
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
                        let publicK = result.object(forKey: "publicK") as! Data
                        DispatchQueue.main.async {
                          dataPublisher.send(publicK)
                        }
                      }
                      
                      if results.count == 0 {
                        print("no name ",name)
                        return
                      }
    }
    return
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
                        
                        let name = result.object(forKey: "name") as? String
                        //                        var rex = ContentMode.userObject()
                        //                        rex.name = name as? String
                        //                        self!.contentModel.users.append(rex)
                        DispatchQueue.main.async {
                          pingPublisher.send(name!)
                        }
                      }
    }
  }
  
  func fetchRecords(name: String) {
    print("fetch ",name)
    let predicate = NSPredicate(format: "name = %@", name)
    let query = CKQuery(recordType: "mediator", predicate: predicate)
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
                        let rex = result.object(forKey: "token") as? [UInt8]
                        print("rex ",rex)
                        DispatchQueue.main.async {
                          cloudPublisher.send(rex!)
                        }
                      }
                      
                      if results.count == 0 {
                        print("no name ",name)
                      }
    }
  }
  
  func searchAndUpdate(name: String, publicK:Data, device: String) {
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
                        //                        print("results ",result.recordID)
                        self!.updateRec(record: result, publicK: publicK, device: device)
                      }
                      
                      if results.count == 0 {
                        print("no name ",name)
                      }
    }
  }
  
  func updateRec(record: CKRecord, publicK: Data, device: String) {
    //    print("updating ",record)
    let saveRecordsOperation = CKModifyRecordsOperation()
    record.setValue(publicK, forKey: "publicK")
    record.setValue(device, forKey: "device")
    saveRecordsOperation.recordsToSave = [record]
    saveRecordsOperation.savePolicy = .allKeys
    saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
      if error != nil {
        print("error")
      } else {
        //        print("saved ",savedRecords?.count)
      }
    }
    publicDB.add(saveRecordsOperation)
  }
  
  func returnRec(name: String) {
    let predicate = NSPredicate(format: "name = %@", name)
       let query = CKQuery(recordType: "mediator", predicate: predicate)
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
                           
                           let token = result.object(forKey: "token") as! [UInt8]
                           DispatchQueue.main.async {
                             print("returnRec ",token)
                             debugPublisher.send(token)
                           }
                         }
                         
                         if results.count == 0 {
                           print("no name ",name)
                           return
                         }
       }
       return
  }
  
  func keepRec(name: String, sender:String, senderDevice:String, encryptedDevice:String, token:[UInt8]) {
    print("searching ",name)
    let predicate = NSPredicate(format: "name = %@ AND sender = %@", name, sender)
    let query = CKQuery(recordType: "mediator", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async {
                          print("error",error)
                        }
                        return
                      }
                      if let results = results {
                        if results.count > 0 {
                          self!.keepRec2(record: results.first!, sender: sender, senderDevice: senderDevice, encryptedDevice:encryptedDevice, token:token)
                        } else {
                          self!.saveRec2(name: name, sender: sender, senderDevice: senderDevice, encryptedDevice:encryptedDevice,token:token)
                        }
                      }
    }
  }
  
  func keepRec2(record: CKRecord, sender:String, senderDevice:String, encryptedDevice:String, token:[UInt8]) {
    record.setObject(senderDevice as CKRecordValue, forKey: "devices")
    let modifyRecordsOperation = CKModifyRecordsOperation(
      recordsToSave: [record],
      recordIDsToDelete: nil)
    
    modifyRecordsOperation.modifyRecordsCompletionBlock =
      { records, recordIDs, error in
        if let _ = error {
          print("error ",error)
        } else {
          DispatchQueue.main.async {
            print("success ")
          }
        }
    }
    publicDB?.add(modifyRecordsOperation)
  }
  
  func saveRec2(name: String, sender:String, senderDevice:String, encryptedDevice:String, token:[UInt8]) {
    let record = CKRecord(recordType: "mediator")
    record.setObject(name as CKRecordValue, forKey: "name")
    record.setObject(sender as CKRecordValue, forKey: "sender")
    record.setObject(senderDevice as CKRecordValue, forKey: "senderDevice")
    record.setObject(encryptedDevice as CKRecordValue, forKey: "encryptedDevice")
    record.setObject(token as CKRecordValue, forKey: "token")
    let modifyRecordsOperation = CKModifyRecordsOperation(
      recordsToSave: [record],
      recordIDsToDelete: nil)
    
    modifyRecordsOperation.modifyRecordsCompletionBlock =
      { records, recordIDs, error in
        if let err = error {
          print("error ",error)
        } else {
          DispatchQueue.main.async {
            print("success ")
            self.returnRec(name: name)
          }
        }
    }
    publicDB?.add(modifyRecordsOperation)
  }
          
          //  func saveRec(name: String, key:String) {
          //    let record = CKRecord(recordType: "directory")
          //    record.setObject(name as CKRecordValue, forKey: "name")
          //    record.setObject(key as CKRecordValue, forKey: "key")
          //    let modifyRecordsOperation = CKModifyRecordsOperation(
          //        recordsToSave: [record],
          //        recordIDsToDelete: nil)
          //
          //        modifyRecordsOperation.modifyRecordsCompletionBlock =
          //        { records, recordIDs, error in
          //            if let err = error {
          //                print("error ",error)
          ////                self.notifyUser("Save Error", message:
          ////                    err.localizedDescription)
          //            } else {
          //                DispatchQueue.main.async {
          //                    print("success ")
          //                }
          //            }
          //        }
          //        publicDB?.add(modifyRecordsOperation)
          //    }
              
          //    func fileRec(name: String, sender:String, device:[UInt8]) {
          //        let record = CKRecord(recordType: "mediator")
          //        record.setObject(name as CKRecordValue, forKey: "name")
          //        record.setObject(sender as CKRecordValue, forKey: "sender")
          //        record.setObject(device as CKRecordValue, forKey: "senderDevice")
          //        let modifyRecordsOperation = CKModifyRecordsOperation(
          //            recordsToSave: [record],
          //            recordIDsToDelete: nil)
          //
          //            modifyRecordsOperation.modifyRecordsCompletionBlock =
          //            { records, recordIDs, error in
          //                if let err = error {
          //                    print("error ",error)
          //    //                self.notifyUser("Save Error", message:
          //    //                    err.localizedDescription)
          //                } else {
          //                    DispatchQueue.main.async {
          //                        print("success ")
          //                    }
          //                }
          //            }
          //            publicDB?.add(modifyRecordsOperation)
          //        }
        
//      func subscribe() {
//        let predicate = NSPredicate(format: "TRUEPREDICATE")
//
//        let subscription = CKQuerySubscription(recordType: "mediator",
//                              predicate: predicate,
//                              options: [.firesOnRecordCreation, .firesOnRecordUpdate])
//        let notificationInfo = CKSubscription.NotificationInfo()
//
//        notificationInfo.alertBody = "A new notify record added"
//        notificationInfo.shouldBadge = true
//        notificationInfo.shouldSendContentAvailable = true
//
//        subscription.notificationInfo = notificationInfo
//
//        publicDB?.save(subscription,
//                  completionHandler: ({returnRecord, error in
//            if let err = error {
//                print("subscription failed %@",
//                            err.localizedDescription)
//            } else {
//                DispatchQueue.main.async() {
//                          print("Subscription set up successfully")
//                }
//            }
//        }))
//      }
        
//  func fetchRecord(_ recordID: CKRecord.ID) -> Void
//      {
//          publicDB.fetch(withRecordID: recordID,
//                           completionHandler: ({record, error in
//              if let error = error {
//                  DispatchQueue.main.async() {
//                      print(error.localizedDescription)
//                  }
//              } else {
//                  DispatchQueue.main.async() {
//                      print("record ",record)
//                  }
//              }
//          }))
//      }
   
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
