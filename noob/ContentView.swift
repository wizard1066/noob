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
let putemthruPublisher = PassthroughSubject<Void, Never>()

struct rex {
  var name: String!
  var group: String!
  var secret: String!
}

class newUsers: ObservableObject {
  var rexes:[rex] = []
}


class Users: ObservableObject {
  //  @Published var selected4 = 0
  var name:[String] = []
  var group:[String] = []
  var secret:[String] = []
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
  @State var display = true
  
  @State var people = Users()
  @State var peeps = newUsers()
  @State var selected3 = 0
  @State var selected4 = 0
  
  @State var group:String = ""
  @State var secret:String = ""
  
  var body: some View {
    VStack {
      Button(action: {
        print("debug",self.display)
      }) {
        Image(systemName: "staroflife.fill")
      }

      if showAdmin {
        Button(action: {
          print("saving to icloud")
          cloud.seekAndTell(names: self.people.name)
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
        if name != nil && name != "" {
          self.showUpperWheel = false
          self.showAdmin = false
          self.sender = name
          messagePublisher.send(self.sender + " Owner")
          self.disableMessaging = false
        }
      }.onReceive(recieptPublisher) { (_) in
        messagePublisher.send("Message Recieved")
      }.onReceive(pongPublisher) { ( _ ) in
        self.showAdmin = true
      }.alert(isPresented:$showingAlert) {
          Alert(title: Text("Not now"), message: Text("Talk Later"), dismissButton: .default(Text("Ok")))
      }
      
      if self.showAdmin {
        
        VStack {
          Button(action: {
//            let finder = self.people.name.firstIndex(of: self.name)
            let finder = self.peeps.rexes.filter{$0.name == self.name}
            if finder.count == 0 {
//              self.users[self.index] = self.name
              self.display = false
              
              let rec = rex(name: self.name, group: self.group, secret: self.secret)
              self.peeps.rexes.append(rec)
              
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.display = true
              }
            }
            self.name = ""
            self.group = ""
            self.secret = ""
          }) {
            Image(systemName: "plus.circle")
          }
          TextField("Group?", text: $group)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("User?", text: self.$name, onEditingChanged: { (editing) in
              if editing {
                self.name = ""
              }
            }, onCommit: {
              print("ok")
              }
            )
            .multilineTextAlignment(.center)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
          TextField("Secret?", text: $secret)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          Button(action: {
//            let finder = self.people.name.firstIndex(of: self.name)
//            let finder = self.peeps.rexes.first(of: self.name)
//            let finder = self.peeps.rexes.filter{$0.name == self.name}
            let finder = self.peeps.rexes.firstIndex(where: {$0.name == self.name})
            if finder != nil {
              self.peeps.rexes.remove(at: finder!)
            }
            self.display = false
            // this removes the user + group + secret since it is a struct
//            self.people.name.remove(at: finder!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              self.display = true
            }
          }) {
            Image(systemName: "minus.circle")
          }
        
        }.padding()
      }
      if showUpperWheel {
        
        if self.display {
          Picker(selection: $selected3, label: Text("")) {
            ForEach(0 ..< self.peeps.rexes.count) {dix in
              Text(self.peeps.rexes[dix].name)
            }
          }.pickerStyle(WheelPickerStyle())
            .padding()
            .onTapGesture {
              // *** 1ST ***
//              self.sender = self.people.name[self.selected3]
              self.sender = self.peeps.rexes[self.selected3].name

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
//              self.disableUpperWheel = true
              self.showUpperWheel = false
              
          }.disabled(disableUpperWheel)
            .onReceive(resetPublisher) { (_) in
              self.disableUpperWheel = false
              self.disableLowerWheel = false
              self.showUpperWheel = true
          }
        }
      }
      if !showAdmin {
        TextField("Message", text: $yourMessageHere, onCommit: {
          self.output = self.yourMessageHere
          if self.confirm != nil {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let token = appDelegate.returnToken()
            poster.postNotification(token: self.confirm!, message: self.yourMessageHere, type: "alert", request: "ok", device: token)
          }
        })
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()
          .disabled(disableMessaging)
          .onReceive(disablePublisher) { (_) in
            self.disableMessaging = true
        }
      }
      if self.display {
        Picker(selection: $selected3, label: Text("")) {
          ForEach(0 ..< self.peeps.rexes.count) {dix in
            Text(self.peeps.rexes[dix].name)
          }
        }
//        Picker(selection: $selected4, label: Text("")) {
//          ForEach(0 ..< self.people.name.count) {
//            Text(self.people.name[$0])
//          }
//        }
        .pickerStyle(WheelPickerStyle())
          .padding()
          .onReceive(pingPublisher) { (data) in
            self.display = false
            self.people.name = data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              self.display = true
            }
        }
        .onTapGesture {
          // *** 2ND ***
          self.sendingTo = self.peeps.rexes[self.selected4].name
          let appDelegate = UIApplication.shared.delegate as! AppDelegate
          let token = appDelegate.returnToken()
          cloud.authRequest(auth:self.sender, name: self.sendingTo!, device: token)
        }.onReceive(popPublisher) { (token,data) in
          self.alertMessage = data
          self.confirm = token
          self.showingAlert = true
//          let notify = LocalNotifications()
//          notify.doNotification()
          self.disableMessaging = true
          
        }.onReceive(enableMessaging, perform: { (data, secret) in
          print("Granted")
          
          self.confirm = data
          self.showingGrant = true
          self.code = secret
          let alertHC = UIHostingController(rootView: PopUp(code: self.$code, input: ""))
          alertHC.preferredContentSize = CGSize(width: 256, height: 256)
          alertHC.modalPresentationStyle = .formSheet
          
          UIApplication.shared.windows[0].rootViewController?.present(alertHC, animated: true)
        }).onReceive(putemthruPublisher, perform: { (_) in
          self.disableMessaging = false
          cloud.saveAuthRequest2PrivateDB(name: self.sendingTo, token: self.confirm!)
          messagePublisher.send("")
          print("good2Go")
        })
          .onReceive(shortProtocol, perform: { (data) in
            print("Granted")
            self.confirm = data
            self.disableMessaging = false
          }).disabled(disableLowerWheel)
      }
      if showAdmin {
        Button(action: {
          print("saving to icloud")
          // This is floored cause you can add multiple names BEFORE saving
          cloud.seekAndTell(names: self.people.name)
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
  @State var input: String
  @State var status: String = ""
  
  var body : some View {
    VStack {
      Text("and the Code is ...")
      Text("\(self.code)")
      TextField("Code?", text: $input, onEditingChanged: { (editing) in
        if editing {
          self.input = ""
        }
      }, onCommit: {
        if self.code == self.input {
          UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {
            putemthruPublisher.send()
          })
        } else {
          self.status = "Sorry Code Incorrect"
        }
      }).frame(width: 128, height: 128, alignment: .center)
      Button(action: {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
      }) {
        Text("Cancel")
      }
      Button(action: {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
      }) {
        Text("OK")
      }
      Text(status)
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


