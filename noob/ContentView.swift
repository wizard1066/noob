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
let shortProtocol = PassthroughSubject<String, Never>()
let turnOffAdmin = PassthroughSubject<Void, Never>()

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
  
  @State var code: String = ""
  
  @State var showUpperWheel = true
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
  @State var name:String = ""
  
  @State var showAdmin = true
 

  var body: some View {
    VStack {
      if showAdmin {
        Button(action: {
          print("saving to icloud")
          cloud.seekAndTell(names: self.users)
        }) {
         Image(systemName: "icloud.and.arrow.up")
        }.onReceive(turnOffAdmin) { (_) in
          self.showAdmin = false
          self.showUpperWheel = true
        }
      }
      Text("noobChat").onAppear() {
        cloud.getDirectory()
        if self.showAdmin {
          self.showUpperWheel = false
        }
        let name = UserDefaults.standard.string(forKey: "name")
        if name != nil {
            self.showUpperWheel = false
            self.showAdmin = false
            self.sender = name
            messagePublisher.send(self.sender + " Owner")
            self.disableMessaging = false
        }
      }.onReceive(recieptPublisher) { (_) in
         messagePublisher.send("Message Recieved")
      }.onReceive(pongPublisher) { ( secret ) in
        print("FooBar")
        self.showAdmin = true
      }.alert(isPresented:$showingAlert) {
          Alert(title: Text("Can we talk?"), message: Text("\(alertMessage!)"), primaryButton: .destructive(Text("Sure")) {
            poster.postNotification(token: self.confirm!, message: "Granted", type: "background", request: "grant",device:token, secret: nil)
          }, secondaryButton: .cancel(Text("No")))
      }
      
      if self.showAdmin {
        HStack {
          Button(action: {
            let finder = self.users.firstIndex(of: self.name)
            print("finder ",finder)
            if finder == nil {
              self.users[self.index] = self.name
              if self.index < self.users.count - 1 {
                self.index = self.index + 1
              } else {
                self.index = 0
              }
            }
            self.name = ""
          }) {
           Image(systemName: "plus.circle")
          }
          TextField("Nobody?", text: self.$name, onEditingChanged: { (editing) in
            if editing {
              self.name = ""
            }
          }, onCommit: {
            let finder = self.users.firstIndex(of: self.name)
              if finder == nil {
              self.users[self.index] = self.name
              if self.index < self.users.count - 1 {
                self.index = self.index + 1
              } else {
                self.index = 0
              }
            }
            self.name = ""
          })
          Button(action: {
            let finder = self.users.firstIndex(of: self.name)
            self.users.remove(at: finder!)
            self.users.append("")
            self.index = self.index - 1
          }) {
           Image(systemName: "minus.circle")
          }
        }.padding()
      }
      if showUpperWheel {
        Picker(selection: $selected, label: Text("Address")) {
          ForEach(0 ..< users.count) {
            Text(self.users[$0])
          }
        }.pickerStyle(WheelPickerStyle())
          .padding().onTapGesture {
          // *** 1ST ***
            self.sender = self.users[self.selected]
            UserDefaults.standard.set(self.sender, forKey: "name")
            let success = rsa.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob")
            if success {
              let privateK = rsa.getPrivateKey()
              let publicK = rsa.getPublicKey()
              let appDelegate = UIApplication.shared.delegate as! AppDelegate
              let token = appDelegate.returnToken()
              var timestamp = UInt64(floor(Date().timeIntervalSince1970 * 1000))
              let random = String(timestamp, radix: 16)
              UserDefaults.standard.set(random, forKey: "secret")
              cloud.searchAndUpdate(name: self.sender, publicK: publicK!, privateK: privateK!, token: token, shared: random)
            }
            messagePublisher.send(self.sender + " Logged In")
            self.disableUpperWheel = true
        }.disabled(disableUpperWheel)
         .onReceive(resetPublisher) { (_) in
          self.disableUpperWheel = false
          self.disableLowerWheel = false
          self.showUpperWheel = true
        }
      }
      if !showAdmin {
      TextField("Message", text: $yourMessageHere, onCommit: {
        self.output = self.yourMessageHere
        if self.confirm != nil {
          let appDelegate = UIApplication.shared.delegate as! AppDelegate
          let token = appDelegate.returnToken()
          poster.postNotification(token: self.confirm!, message: self.yourMessageHere, type: "alert", request: "ok", device: token, secret: nil)
        }
      })
      .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
        .disabled(disableMessaging)
        .onReceive(disablePublisher) { (_) in
          self.disableMessaging = true
        }
      }
      Picker(selection: $selected2, label: Text("Addresse")) {
        ForEach(0 ..< users.count) {
          Text(self.users[$0])
        }
      }.pickerStyle(WheelPickerStyle())
        .padding()
        .onReceive(pingPublisher) { (data) in
            if data != self.sender {
              self.users[self.index] = data
              if self.index < self.users.count - 1 {
                self.index = self.index + 1
              } else {
                self.index = 0
              }
            }
        }
        .onTapGesture {
          // *** 2ND ***
          self.sendingTo = self.users[self.selected2]
          let appDelegate = UIApplication.shared.delegate as! AppDelegate
          let token = appDelegate.returnToken()
          cloud.authRequest(auth:self.sender, name: self.sendingTo!, device: token)
      }.onReceive(popPublisher) { (token,data,secret) in
        self.alertMessage = data
        self.confirm = token
        self.showingAlert = true
        self.disableMessaging = true
        self.code = secret
      }.onReceive(enableMessaging, perform: { (data, secret) in
        print("Granted")
        
        self.confirm = data
        self.disableMessaging = false
        self.showingGrant = true
        self.code = secret
//        cloud.saveAuthRequest2PrivateDB(name: self.sendingTo, token: self.confirm!)
      })
      .alert(isPresented:$showingGrant) {
          Alert(title: Text(self.code), message: Text("What is on your mind?"), dismissButton: .default(Text("Clear")))
          
      }.onReceive(shortProtocol, perform: { (data) in
        print("Granted")
        self.confirm = data
        self.disableMessaging = false
      }).disabled(disableLowerWheel)
      if showAdmin {
        Button(action: {
          print("saving to icloud")
//          cloud.seekAndTell(names: self.users)
          let alertHC = UIHostingController(rootView: PopUp(code: self.$code))
          alertHC.preferredContentSize = CGSize(width: 256, height: 256)
          alertHC.modalPresentationStyle = .formSheet
          
          UIApplication.shared.windows[0].rootViewController?.present(alertHC, animated: true)
        }) {
         Image(systemName: "icloud.and.arrow.up")
        }
      }
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
@Binding var code: String

  var body : some View {
    VStack {
      Text("and the Code is ...")
      TextField("Code?", text: self.$code, onEditingChanged: { (editing) in
        if editing {
          self.code = ""
        }
      }, onCommit: {
        print("code \(self.code)")
      }).frame(width: 128, height: 128, alignment: .center)
      Button(action: {
          UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
      }) {
          Text("Cancel")
      }
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
