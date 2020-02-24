//
//  ContentView.swift
//  noob
//
//  Created by localadmin on 14.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
import Combine
import CloudKit

let notify = LocalNotifications()
let poster = RemoteNotifications()
let rsa = RSA()
let cloud = Cloud()


let messagePublisher = PassthroughSubject<String, Never>()
let resetPublisher = PassthroughSubject<Void, Never>()
let recieptPublisher = PassthroughSubject<Void, Never>()

class ContentMode {

  
  struct userObject {
    var name: String
    var publicK: String?
    var privateK: String?
    
    init(user: String, privateK: String?, publicK: String?) {
      self.name = user
      self.privateK = privateK
      self.publicK = publicK
    }
  }
  
  @Published var people: [userObject] = []
}



struct ContentView: View {

  @State var yourMessageHere = "" {
    didSet {
      DispatchQueue.main.async {
        print("You go")
      }
    }
  }
  // The kludge, This is very limited cause we need to reserve space in advance, should use binding
  @State var users = ["","","","","","","",""]
  @State var selected2 = 0
  @State var selected = 0
  @State var output:String = "" {
    didSet {
      print("You send \(output)")
    }
  }
  @State var index = 0
  @State var sendingTo:String!
  @State var sender:String!
  @State var message:String = ""
  
  
  @State var publicK: String?
  @State var privateK: String?
  
  @State var disableUpperWheel = false
  @State var disableLowerWheel = false
  
  @State var disableMessaging = true
  @State var poke = true
  
  @State var showingAlert = false
  @State var alertMessage:String?
  
  @State var confirm:String?

  var body: some View {
    VStack {
      Text("noobChat").onAppear() {
        cloud.getDirectory()
      }.onReceive(recieptPublisher) { (_) in
         messagePublisher.send("Message Recieved")
      }
      
      Picker(selection: $selected, label: Text("Address")) {
        ForEach(0 ..< users.count) {
          Text(self.users[$0])
        }
      }.pickerStyle(WheelPickerStyle())
        .padding().onReceive(pingPublisher) { (data) in
          self.users[self.index] = data
          if self.index < self.users.count - 1 {
            self.index = self.index + 1
          } else {
            self.index = 0
          }
      }.onTapGesture {
        // *** 1ST ***
          self.sender = self.users[self.selected]
          let success = rsa.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
          if success {
            let privateK = rsa.getPrivateKey()
            let publicK = rsa.getPublicKey()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let token = appDelegate.returnToken()
            var timestamp = UInt64(floor(Date().timeIntervalSince1970 * 1000))
            let random = String(timestamp, radix: 16)
            cloud.searchAndUpdateDB(name: self.sender, publicK: publicK!, privateK: privateK!, token: token, shared: random)
          }
          messagePublisher.send(self.sender + " Logged In")
          self.disableUpperWheel = true
      }.disabled(disableUpperWheel)
       .onReceive(resetPublisher) { (_) in
        self.disableUpperWheel = false
        self.disableLowerWheel = false
      }
//      Button(action: {
//        self.showingAlert = false
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let token = appDelegate.returnToken()
////        poster.postNotification(token: token, message: "Silence is Golden", type: "background")
//        cloud.registerCode()
//      }) {
//        Text("Pop")
//      }
      TextField("Message", text: $yourMessageHere, onCommit: {
        self.output = self.yourMessageHere
        if self.confirm != nil {
          poster.postNotification(token: self.confirm!, message: self.yourMessageHere, type: "alert", request: "ok")
        }
      })
//        let token2Send = rsa.decprypt(encrpted: data)
//        print("data ",data,token2Send)
//
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let token = appDelegate.returnToken()
//        if token2Send != nil {
//          poster.postNotification(token: token2Send!, message: self.yourMessageHere, type: "alert")
//        } else {
//          messagePublisher.send("Public Key " + self.sendingTo! + " Wrong")
//        }
//      })
      .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
        .disabled(disableMessaging)
        .onReceive(disablePublisher) { (_) in
          self.disableMessaging = true
        }
       
      Picker(selection: $selected2, label: Text("Addresse")) {
        ForEach(0 ..< users.count) {
          Text(self.users[$0])
        }
      }.pickerStyle(WheelPickerStyle())
        .padding()
        .onTapGesture {
          // *** 2ND ***
          self.sendingTo = self.users[self.selected]
          cloud.authRequestDB(name: self.sendingTo!)
          
          
          
//        }.onReceive(dataPublisher) { (data) in
//            debugPrint(self.users[self.selected2])
//            let appDelegate = UIApplication.shared.delegate as! AppDelegate
//            let token = appDelegate.returnToken()
//            self.sendingTo = self.users[self.selected2]
//            // self.sending person selected in second PickerView
//            // self.sender person selected in first PickerView sending message
//            // token device sender [this device] is running on encypted with sending person public key
//            rsa.putPublicKey(publicK: data, keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
//            let encryptedToken = rsa.encrypt(text: token)
//            messagePublisher.send("Sending To " + self.sendingTo)
//            cloud.keepRec(name: self.sender, sender: self.sendingTo, senderDevice: token, token: encryptedToken, silent: self.poke)
//            self.disableLowerWheel = true
////            cloud.fetchRecords(name: self.sendingTo!, silent: true)
////             if you get a response you're good to go
      }.onReceive(popPublisher) { (data,token) in
        self.alertMessage = data
        self.confirm = token
        self.showingAlert = true
      }.alert(isPresented:$showingAlert) {
          Alert(title: Text("Can we talk?"), message: Text("\(alertMessage!)"), primaryButton: .destructive(Text("Authorize")) {
            poster.postNotification(token: self.confirm!, message: "Granted", type: "background", request: "grant")
          }, secondaryButton: .cancel())
      }.onReceive(popPublisher) { (token) in
        self.disableMessaging = false
      }.disabled(disableLowerWheel)
//      .onReceive(pokePublisher) { (data) in
//          let token2Send = rsa.decprypt(encrpted: data)
//          print("data ",data,token2Send)
//          poster.postNotification(token: token2Send!, message: "You online?", silent: true)
//      }
      Text(message).onReceive(messagePublisher) { (data) in
          self.message = data
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct PopUp : View {
  
  var body : some View {
    VStack {
      Text("Hello World")
    }
  }
}


extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("Device shaken")
            resetPublisher.send()
        }
    }
}
