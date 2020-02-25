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
let pongPublisher = PassthroughSubject<Void, Never>()
let dataPublisher = PassthroughSubject<Data, Never>()
let cloudPublisher = PassthroughSubject<[UInt8], Never>()
let disablePublisher = PassthroughSubject<Void, Never>()
let pokePublisher = PassthroughSubject<[UInt8], Never>()
let requestPublisher = PassthroughSubject<String, Never>()


class Cloud: NSObject {
  
  var publicDB:CKDatabase!
  var privateDB: CKDatabase!
  var contentModel = ContentMode()
  
  override init() {
    super.init()
    publicDB = CKContainer.default().publicCloudDatabase
    privateDB = CKContainer.default().privateCloudDatabase
  }
  
  private var privateK:Data?
  private var publicK:Data?
  
//  func registerCode() {
//    var timestamp = UInt64(floor(Date().timeIntervalSince1970 * 1000))
//    let random = String(timestamp, radix: 16)
//    let success = rsa.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
//    if success {
//      let privateK = rsa.getPrivateKey()
//      let publicK = rsa.getPublicKey()
//
//      let record = CKRecord(recordType: "directory")
//      var timestamp = UInt64(floor(Date().timeIntervalSince1970 * 1000))
//
//      record.setObject(random as CKRecordValue, forKey: "name")
//      record.setObject(privateK as CKRecordValue?, forKey: "privateK")
//
//
//    }
//
//  }
  
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
                      if results.count == 0 {
                        DispatchQueue.main.async { pongPublisher.send() }
                      }
    }
  }
  
  func authRequest(auth:String, name: String, device:String) {
    let predicate = NSPredicate(format: "name = %@", name)
    let query = CKQuery(recordType: "directory", predicate: predicate)
      privateDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async { print("error",error) }
                        return
                      }
                      guard let results = results else { return }
                      for result in results {
                        print("results ",result)
                        let token = result.object(forKey: "device") as? String
                        if token == nil {
                          self!.authRequest2(auth: auth, name: name, device: device)
                        } else {
                          DispatchQueue.main.async { shortProtocol.send(token!) }
                        }
                      }
                      if results.count == 0 {
                        print("no name ",name)
                        self!.authRequest2(auth: auth, name: name, device: device)
                      }
    }
  }
  
  
  func authRequest2(auth:String, name: String, device:String) {
    // Search the directory
    let predicate = NSPredicate(format: "name = %@", name)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async { print("error",error) }
                        return
                      }
                      guard let results = results else { return }
                      for result in results {
                        print("results ",result)
                        let token = result.object(forKey: "device") as? String
                        if token != nil {
                          poster.postNotification(token: token!, message: auth, type: "background", request: "request", device:device)
                        }
                      }
                      if results.count == 0 {
                        print("no name ",name)
                        
                      }
    }
  }
  
  func saveAuthRequest2PrivateDB(name:String, token: String) {
    let predicate = NSPredicate(format: "name = %@", name)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    privateDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async { print("error",error) }
                        return
                      }
                      guard let results = results else { return }
                      for result in results {
                        print("results ",result)
                        let saveRecordsOperation = CKModifyRecordsOperation()
                        result.setValue(token, forKey: "device")
                        saveRecordsOperation.recordsToSave = [result]
                        saveRecordsOperation.savePolicy = .allKeys
                        saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
                          if error != nil {
                            print("error")
                          } else {
                            print("saved ",savedRecords?.count)
                          }
                        }
                        self!.privateDB.add(saveRecordsOperation)
                        
                      }
                      if results.count == 0 {
                        print("no name ",name)
                        
                      }
                    }
                    
    }

  func searchAndUpdate(name: String, publicK:Data, privateK:Data, token:String, shared:String) {
    print("searching ",name)
    var predicate = NSPredicate(format: "name = %@", name)
    var query = CKQuery(recordType: "directory", predicate: predicate)
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
                        self!.save2Public(record: result, publicK: publicK, token: token)
                      }
                      
                      if results.count == 0 {
                        print("no name ",name)
                        DispatchQueue.main.async {
                        messagePublisher.send(name + "PUBLIC searchAndUpdate Err")
                        }
                      }
    }
    
    print("searching ",name)
    predicate = NSPredicate(format: "name = %@", name)
    query = CKQuery(recordType: "directory", predicate: predicate)
    privateDB.perform(query,
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
                        self!.save2Private(record: result, privateK: privateK, shared:shared)
                        
                      }
                      
                      if results.count == 0 {
                        let record = CKRecord(recordType: "directory")
                        record.setObject(name as CKRecordValue, forKey: "name")
                        self!.save2Private(record: record, privateK: privateK, shared:shared)
                        DispatchQueue.main.async {
                        messagePublisher.send(name + "PRIVATE created Rec")
                        
                        }
                      }
    }
  }
  
  func save2Public(record: CKRecord, publicK: Data, token:String) {
    //    print("updating ",record)
    let saveRecordsOperation = CKModifyRecordsOperation()
    record.setValue(publicK, forKey: "publicK")
    record.setValue(token, forKey: "device")
    saveRecordsOperation.recordsToSave = [record]
    saveRecordsOperation.savePolicy = .allKeys
    saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
      if error != nil {
        print("error")
      } else {
        print("saved ",savedRecords?.count)
      }
    }
    publicDB.add(saveRecordsOperation)
  }
  
  func save2Private(record: CKRecord, privateK: Data, shared: String) {
    //    print("updating ",record)
    let saveRecordsOperation = CKModifyRecordsOperation()
    record.setValue(privateK, forKey: "privateK")
    record.setValue(shared, forKey: "sharedS")
    saveRecordsOperation.recordsToSave = [record]
    saveRecordsOperation.savePolicy = .allKeys
    saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
      if error != nil {
        print("error")
      } else {
        print("saved ",savedRecords?.count)
      }
    }
    privateDB.add(saveRecordsOperation)
  }
  
  

  
  func keepRec(name: String, sender:String, senderDevice:String, token:[UInt8], silent: Bool) {
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
                          self!.keepRec2(record: results.first!, sender: sender, senderDevice: senderDevice, token:token, silent:silent)
                        } else {
                          self!.saveRec2(name: name, sender: sender, senderDevice: senderDevice, token:token, silent: silent)
                        }
                      }
    }
  }
  
  func keepRec2(record: CKRecord, sender:String, senderDevice:String, token:[UInt8], silent: Bool) {
    record.setObject(senderDevice as CKRecordValue, forKey: "devices")
    record.setObject(token as CKRecordValue, forKey: "token")
    let modifyRecordsOperation = CKModifyRecordsOperation(
      recordsToSave: [record],
      recordIDsToDelete: nil)
    
    modifyRecordsOperation.modifyRecordsCompletionBlock =
      { records, recordIDs, error in
        if let _ = error {
          print("error ",error)
        } else {
          DispatchQueue.main.async {
            if silent {
//              let name = records?.first?.object(forKey: "name") as? String
//              self.fetchRecords(name: name!, silent: true)
            }
            print("success ")
          }
        }
    }
    publicDB?.add(modifyRecordsOperation)
  }
  
  func saveRec2(name: String, sender:String, senderDevice:String, token:[UInt8], silent: Bool) {
    let record = CKRecord(recordType: "mediator")
    record.setObject(name as CKRecordValue, forKey: "name")
    record.setObject(sender as CKRecordValue, forKey: "sender")
    record.setObject(senderDevice as CKRecordValue, forKey: "senderDevice")
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
            if silent {
//              self.fetchRecords(name: name, silent: true)
            }
//            self.returnRec(name: name)
          }
        }
    }
    publicDB?.add(modifyRecordsOperation)
  }
  
  func saveToCloud(names:[CKRecord]) {
    let saveRecordsOperation = CKModifyRecordsOperation()
          saveRecordsOperation.recordsToSave = names
          saveRecordsOperation.savePolicy = .allKeys
          saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
            if error != nil {
              print("error",error)
            } else {
              print("saved ",savedRecords?.count)
              DispatchQueue.main.async {
                turnOffAdmin.send()
                messagePublisher.send("Saved Names")
              }
            }
          }
          publicDB.add(saveRecordsOperation)
  }
  
         
  func seekAndTell(names:[String])  {
    var namesCopy = names
    let predicate = NSPredicate(format: "TRUEPREDICATE")
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
                        let finder = names.firstIndex(of: name!)
                        if finder != nil {
                          if finder! < namesCopy.count {
                            namesCopy[finder!] = ""
                          }
                        }
                      }
                      if namesCopy.count > 0 {
                        var boxes:[CKRecord] = []
                        for index in 0 ..< namesCopy.count {
                          if namesCopy[index] != "" {
                            let record = CKRecord(recordType: "directory")
                            record.setObject(namesCopy[index] as __CKRecordObjCValue, forKey: "name")
                            boxes.append(record)
                          }
                        }
                        print("merge ",boxes)
                        self!.saveToCloud(names: boxes)
//                        DispatchQueue.main.async { turnOffAdmin.send() }
                      }
    }
  }
   

          
           //  func getPrivateK(name: String) {
            //    print("searching ",name)
            //
            //    let predicate = NSPredicate(format: "name = %@", name)
            //    let query = CKQuery(recordType: "directory", predicate: predicate)
            //    privateDB.perform(query,
            //                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
            //                      guard let _ = self else { return }
            //                      if let error = error {
            //                        DispatchQueue.main.async {
            //                          print("error",error)
            //                        }
            //                        return
            //                      }
            //                      guard let results = results else { return }
            //                      for result in results {
            //                        print("results ",result)
            //                        let privateK = result.object(forKey: "privateK") as? Data
            //                        rsa.putPrivateKey(privateK: privateK!, keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
            //                        self!.getPublicK(name: name)
            //                      }
            //
            //                      if results.count == 0 {
            //                        print("no name ",name)
            //                        DispatchQueue.main.async {
            //                          messagePublisher.send(name + " No Private Key")
            //                        }
            //                        let success = rsa.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
            //                        if success {
            //                          let privateK = rsa.getPrivateKey()
            //                          let publicK = rsa.getPublicKey()
            ////                          self!.searchAndUpdate(name: name, publicK: publicK!, privateK: privateK!)
            //                        }
            //                        return
            //                      }
            //    }
            //    return
            //  }
            //
            //  func getPublicK(name: String) {
            //    print("searching ",name)
            //
            //    let predicate = NSPredicate(format: "name = %@", name)
            //    let query = CKQuery(recordType: "directory", predicate: predicate)
            //    publicDB.perform(query,
            //                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
            //                      guard let _ = self else { return }
            //                      if let error = error {
            //                        DispatchQueue.main.async {
            //                          print("error",error)
            //                        }
            //                        return
            //                      }
            //                      guard let results = results else { return }
            //                      for result in results {
            //                        print("results ",result)
            //                        let publicK = result.object(forKey: "publicK") as? Data
            //                        rsa.putPublicKey(publicK: publicK!, keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
            //
            //                        self!.getTokens(name: name)
            //                      }
            //
            //                      if results.count == 0 {
            //                        print("no name ",name)
            //                        DispatchQueue.main.async {
            //                          messagePublisher.send(name + " No Public Key")
            //                        }
            //                        return
            //                      }
            //    }
            //    return
            //  }
            //
            //   func getTokens(name: String) {
            //      var mediator:[CKRecord] = []
            //      print("seek ",name)
            //      let predicate = NSPredicate(format: "name = %@", name)
            //      let query = CKQuery(recordType: "mediator", predicate: predicate)
            //      publicDB.perform(query,
            //                       inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
            //                        guard let _ = self else { return }
            //                        if let error = error {
            //                          DispatchQueue.main.async {
            //                            print("error",error)
            //                          }
            //                          return
            //                        }
            //                        guard let results = results else {
            //                          DispatchQueue.main.async {
            //                            messagePublisher.send(name + "No tokens to change")
            //                          }
            //                          return
            //                        }
            //                        for result in results {
            //                          let token = rsa.decprypt(encrpted: result.object(forKey: "token") as! [UInt8])
            //                          if token != nil {
            //                            result.setObject(token as CKRecordValue?, forKey: "senderDevice")
            //                            mediator.append(result)
            //                          } else {
            //                            self!.publicDB.delete(withRecordID: result.recordID) { (recordID, error) in
            //                              // move on
            //                            }
            //                          }
            //                        }
            //                        if results.count > 0 {
            //                          self!.resetSignature(tokens2Change:mediator,name: name)
            //                        }
            //      }
            //    }
            //
            //  private func resetSignature(tokens2Change:[CKRecord],name:String) {
            //    let success = rsa.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
            //    if success {
            //      for review in tokens2Change {
            //        let token = review.object(forKey: "senderDevice") as? String
            //        let encryptedToken = rsa.encrypt(text: token!)
            //        review.setObject(encryptedToken as CKRecordValue?, forKey: "token")
            //      }
            //
            //      let saveRecordsOperation = CKModifyRecordsOperation()
            //      saveRecordsOperation.recordsToSave = tokens2Change
            //      saveRecordsOperation.savePolicy = .allKeys
            //      saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
            //        if error != nil {
            //          print("error")
            //        } else {
            //          //        print("saved ",savedRecords?.count)
            //        }
            //      }
            //      publicDB.add(saveRecordsOperation)
            //      let privateK = rsa.getPrivateKey()
            //      let publicK = rsa.getPublicKey()
            ////      cloud.searchAndUpdate(name: name, publicK: publicK!, privateK: privateK!)
            //    }
            //  }
              
              
            //  func search(name: String) {
            //    let predicate = NSPredicate(format: "name = %@", name)
            //    let query = CKQuery(recordType: "directory", predicate: predicate)
            //    publicDB.perform(query,
            //                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
            //                      guard let _ = self else { return }
            //                      if let error = error {
            //                        DispatchQueue.main.async { print("error",error) }
            //                        return
            //                      }
            //                      guard let results = results else { return }
            //                      for result in results {
            //                        print("results ",result)
            //                        let publicK = result.object(forKey: "publicK") as! Data
            //                        DispatchQueue.main.async { dataPublisher.send(publicK) }
            //                      }
            //                      if results.count == 0 {
            //                        print("no name ",name)
            //                        messagePublisher.send(name + "search Offline")
            //                      }
            //    }
            //  }
             
            
          //  func fetchRecords(name: String, silent: Bool) {
          //    print("fetch ",name)
          //    let predicate = NSPredicate(format: "name = %@", name)
          //    let query = CKQuery(recordType: "mediator", predicate: predicate)
          //    publicDB.perform(query,
          //                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
          //                      guard let _ = self else { return }
          //                      if let error = error {
          //                        DispatchQueue.main.async {
          //                          print("error",error)
          //                        }
          //                        return
          //                      }
          //                      guard let results = results else { return }
          //                      for result in results {
          //                        print("results ",result)
          //                        let rex = result.object(forKey: "token") as? [UInt8]
          //                        print("rex ",rex)
          //                        DispatchQueue.main.async {
          //                          if silent {
          //                            pokePublisher.send(rex!)
          //                          } else {
          //                            cloudPublisher.send(rex!)
          //                          }
          //                        }
          //                      }
          //
          //                      if results.count == 0 {
          //                        print("no name ",name)
          //                        DispatchQueue.main.async {
          //                          messagePublisher.send(name + "fetchRecords Offline")
          ////                          disablePublisher.send()
          //                        }
          //                      }
          //    }
          //  }
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
