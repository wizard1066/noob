//
//  RemoteNotifications.swift
//  noob
//
//  Created by localadmin on 14.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import SwiftJWT
import Combine



class RemoteNotifications: NSObject, URLSessionDelegate {

  private var privateKey = """
  -----BEGIN PRIVATE KEY-----
  MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgl8Kij2y6acAgp1FZ
  BHqI6T/Bv4bBgndxuVr1IfuYhemgCgYIKoZIzj0DAQehRANCAASweAt5jGR5H1Vf
  QmlPyVVa2hn7jPLxdg0wHyP/xpXbJ5kGunlkXomLh8k+d31tWKKQF2QTzPCzckyi
  p0aHWAWG
  -----END PRIVATE KEY-----
  """
//  private var token = "e08118596402bdb12cce32913afe09edffbf477d2b2193ae3018a955b1776227"
//  private var token = "738189f843d1b4b90be13fee67af08f68c1c6ebb56eedbd42677fdd3dc3136e1"
//  var token = "36a4500f71ee6eeadf82d61c4a47b85e0618a2c66ef0698dad5f32032864fcc3"
  
//  var jsonObject: [String: Any] = ["aps":["sound":"bingbong.aiff","badge":5,"alert":["title":"What, where, who, when, how","body":"You must be kidding"]]]

//  var jsonObject: [String:Any] = ["aps":["content-available":1],"acme4":1984]

    
func postNotification(token:String, message:String, type: String, request: String, device:String, secret:String?) {
    var jsonObject:[String:Any]?
    if type == "background" {
//      let random = Int.random(in: 1...Int.max)
      let secret = UserDefaults.standard.string(forKey: "secret")
      jsonObject = ["aps":["content-available":1],"request":request,"user":message,"device":device, "secret":secret]
    } else {
      jsonObject = ["aps":["sound":"bingbong.aiff","badge":1,"alert":["title":"Noob","body":message]]]
    }
    
    print("token sending ",token)
    let valid = JSONSerialization.isValidJSONObject(jsonObject)
    print("valid ",valid)
    if !valid {
      return
    }
    
    let myHeader = Header(typ: "JWT", kid: "DNU7997FP9")
    let myClaims = ClaimsStandardJWT(iss: "CWGS87U262", sub: nil, aud: nil, exp: nil, nbf: nil, iat: Date() , jti: nil)
    
    let myJWT = JWT(header: myHeader, claims: myClaims)
    
    let privateKeyAsData = privateKey.data(using: .utf8)
    let signer = JWTSigner.es256(privateKey: privateKeyAsData!)
    
    let jwtEncoder = JWTEncoder(jwtSigner: signer)
    do {
      let jwtString = try jwtEncoder.encodeToString(myJWT)
      let content = "https://api.sandbox.push.apple.com/3/device/" + token
      
      var loginRequest = URLRequest(url: URL(string: content)!)
      loginRequest.allHTTPHeaderFields = ["apns-topic": "ch.cqd.noob",
                                          "content-type": "application/json",
                                          "apns-priority": "10",
                                          "apns-push-type": type,
                                          "authorization":"bearer " + jwtString]
      let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
      
      loginRequest.httpMethod = "POST"
      
      let data = try? JSONSerialization.data(withJSONObject: jsonObject, options:[])
      
      loginRequest.httpBody = data
      let loginTask = session.dataTask(with: loginRequest) { data, response, error in
        if error != nil {
          print("error ",error)
          return
        }
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 400 {
          print("statusCode ",httpResponse.statusCode)
        }
      }
      loginTask.resume()
      print("apns ",jsonObject)
    } catch {
      print("failed to encode")
    }
  }
}
