//
//  ContentView.swift
//  noob
//
//  Created by localadmin on 14.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

let notify = LocalNotifications()
let poster = RemoteNotifications()
let rsa = RSA()
let cloud = Cloud()



struct ContentView: View {
  @State var yourBindingHere = ""
  @State var yourMessageHere = ""
  @State var colors = ["Red", "Green", "Blue", "Tartan"]
  @State var selected2 = 0
  @State var selected = 0 {
    didSet {
      cloud.search(name: colors[selected])
    }
  }
  @State var typing = false
  @State var output:String = "" {
    didSet {
      print("You send \(output)")
    }
  }
  
    var body: some View {
      VStack {
//        if !typing {
//          if !output.isEmpty {
//            Text("You typed \(output)")
//
//          } else {
//            if !yourBindingHere.isEmpty {
//              Text("You are typing \(yourBindingHere)")
//            }
//          }
//        }
//          TextField("Login", text: $yourBindingHere, onEditingChanged: {
//            self.typing = $0
//          }, onCommit: {
//            self.output = self.yourBindingHere
//          })
//            .textFieldStyle(RoundedBorderTextFieldStyle())
//            Button(action: {
//                  // register public key
//                    }) {
//                      Text("login")
//                    }
        Picker(selection: $selected, label: Text("Address")) {
                   ForEach(0 ..< colors.count) {
                      Text(self.colors[$0])
                   }
                }.onTapGesture {
                  cloud.search(name: self.colors[self.selected])
                  }.pickerStyle(WheelPickerStyle())
                   .padding()
//                Text("You selected: \(colors[selected])")
//                Button(action: {
//                // register public key
//                  }) {
//                    Text("send")
//                  }
          TextField("Message", text: $yourMessageHere, onCommit: {
            self.output = self.yourMessageHere
          })
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding()
          Picker(selection: $selected2.onChange({ (row) in
            cloud.search(name: self.colors[row])
            }), label: Text("Addresse")) {
             ForEach(0 ..< colors.count) {
                Text(self.colors[$0])
             }
          }.pickerStyle(WheelPickerStyle())
           .padding()
//          Text("You selected: \(colors[selected])")
//          Button(action: {
//          // register public key
//            }) {
//              Text("send")
//            }
      }
//        Button(action: {
//          notify.doNotification()
//        }) {
//          Text("local")
//        }
//        Button(action: {
//          poster.postNotification()
//        }) {
//          Text("remote")
//        }
//        Button(action: {
//          let success : Bool = (rsa.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.noob", publicTag: "ch.cqd.noob"))
//          if (!success) {
//            print("Failed")
//            return
//          }
//          let test : String = poster.token
//          let encryption = rsa.encryptBase64(text: test)
//          print(encryption)
//          let decription = rsa.decpryptBase64(encrpted: encryption)
//          print(decription)
//        }) {
//          Text("keys")
//        }

      
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

