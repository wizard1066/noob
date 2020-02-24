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
  @State var showingGrant = false
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
            cloud.searchAndUpdate(name: self.sender, publicK: publicK!, privateK: privateK!, token: token, shared: random)
          }
          messagePublisher.send(self.sender + " Logged In")
          self.disableUpperWheel = true
      }.disabled(disableUpperWheel)
       .onReceive(resetPublisher) { (_) in
        self.disableUpperWheel = false
        self.disableLowerWheel = false
      }
      TextField("Message", text: $yourMessageHere, onCommit: {
        self.output = self.yourMessageHere
        if self.confirm != nil {
          let appDelegate = UIApplication.shared.delegate as! AppDelegate
          let token = appDelegate.returnToken()
          poster.postNotification(token: self.confirm!, message: self.yourMessageHere, type: "alert", request: "ok", device: token)
        }
      }).onReceive(enableMessaging, perform: { (data) in
        print("Granted")
        self.confirm = data
        self.disableMessaging = false
        self.showingGrant = true
        cloud.saveAuthRequest2PrivateDB(name: self.sendingTo, token: self.confirm!)
      }).alert(isPresented:$showingGrant) {
          Alert(title: Text("Go aHead"), message: Text("What is on your mind?"), dismissButton: .default(Text("Clear")))
          
      }
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
          self.sendingTo = self.users[self.selected2]
          let appDelegate = UIApplication.shared.delegate as! AppDelegate
          let token = appDelegate.returnToken()
          cloud.authRequest(auth:self.sender, name: self.sendingTo!, device: token)
      }.onReceive(popPublisher) { (token,data) in
        self.alertMessage = data
        self.confirm = token
        self.showingAlert = true
      }.alert(isPresented:$showingAlert) {
          Alert(title: Text("Can we talk?"), message: Text("\(alertMessage!)"), primaryButton: .destructive(Text("Sure")) {
            poster.postNotification(token: self.confirm!, message: "Granted", type: "background", request: "grant",device:token)
            // save in private DB
            
          }, secondaryButton: .cancel(Text("No")))
      }.onReceive(popPublisher) { (token) in
        self.disableMessaging = false
      }.disabled(disableLowerWheel)
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
