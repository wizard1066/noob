//
//  ContentView.swift
//  noob
//
//  Created by localadmin on 14.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
import AVFoundation

let notify = LocalNotifications()
let poster = RemoteNotifications()
let rsa = RSA()



struct ContentView: View {
  @State var yourBindingHere = ""
  @State var yourMessageHere = ""
  @State var colors = ["Red", "Green", "Blue", "Tartan"]
  @State var selected = 0
  
    var body: some View {
      VStack {
          TextField("Login", text: $yourBindingHere)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: {
                  // register public key
                    }) {
                      Text("login")
                    }
          TextField("Message", text: $yourMessageHere)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          Picker(selection: $selected, label: Text("Addresse")) {
             ForEach(0 ..< colors.count) {
                Text(self.colors[$0])
             }
          }
          Text("You selected: \(colors[selected])")
          Button(action: {
          // register public key
            }) {
              Text("send")
            }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

