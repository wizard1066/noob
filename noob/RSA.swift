//
//  Keys.swift
//  noob
//
//  Created by localadmin on 17.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//
import UIKit
import Security

class RSA: NSObject {
  private var publicKey : SecKey?
  private var privateKey : SecKey?
  
  func generateKeyPair(keySize: UInt, privateTag: String, publicTag: String) -> Bool {
    
//    self.publicKey = nil
//    self.privateKey = nil
//
//    if (keySize != 512 && keySize != 1024 && keySize != 2048) {
//      // Failed
//      print("Key size is wrong")
//      return false
//    }
    
    let publicKeyParameters: [NSString: AnyObject] = [
      kSecAttrIsPermanent: true as AnyObject,
      kSecAttrApplicationTag: publicTag as AnyObject
    ]
    let privateKeyParameters: [NSString: AnyObject] = [
      kSecAttrIsPermanent: true as AnyObject,
      kSecAttrApplicationTag: publicTag as AnyObject
    ]
    let parameters: [String: AnyObject] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeySizeInBits as String: keySize as AnyObject,
      kSecPrivateKeyAttrs as String: privateKeyParameters as AnyObject,
      kSecPublicKeyAttrs as String: publicKeyParameters as AnyObject
    ]
    
    let status : OSStatus = SecKeyGeneratePair(parameters as CFDictionary, &(self.publicKey), &(self.privateKey))
    
    return (status == errSecSuccess && self.publicKey != nil && self.privateKey != nil)
  }
  
  func encrypt(text: String) -> [UInt8] {
    let plainBuffer = [UInt8](text.utf8)
    var cipherBufferSize : Int = Int(SecKeyGetBlockSize((self.publicKey)!))
    var cipherBuffer = [UInt8](repeating:0, count:Int(cipherBufferSize))
    
    // Encrypto  should less than key length
    let status = SecKeyEncrypt((self.publicKey)!, SecPadding.PKCS1, plainBuffer, plainBuffer.count, &cipherBuffer, &cipherBufferSize)
    if (status != errSecSuccess) {
      print("Failed Encryption")
    }
    return cipherBuffer
  }
  
  func decprypt(encrpted: [UInt8]) -> String? {
    var plaintextBufferSize = Int(SecKeyGetBlockSize((self.privateKey)!))
    var plaintextBuffer = [UInt8](repeating:0, count:Int(plaintextBufferSize))
    
    let status = SecKeyDecrypt((self.privateKey)!, SecPadding.PKCS1, encrpted, plaintextBufferSize, &plaintextBuffer, &plaintextBufferSize)
    
    if (status != errSecSuccess) {
      print("Failed Decrypt")
      return nil
    }
    return NSString(bytes: &plaintextBuffer, length: plaintextBufferSize, encoding: String.Encoding.utf8.rawValue)! as String
  }
  
  
  func encryptBase64(text: String) -> String {
    let plainBuffer = [UInt8](text.utf8)
    var cipherBufferSize : Int = Int(SecKeyGetBlockSize((self.publicKey)!))
    var cipherBuffer = [UInt8](repeating:0, count:Int(cipherBufferSize))
    
    // Encrypto  should less than key length
    let status = SecKeyEncrypt((self.publicKey)!, SecPadding.PKCS1, plainBuffer, plainBuffer.count, &cipherBuffer, &cipherBufferSize)
    if (status != errSecSuccess) {
      print("Failed Encryption")
    }
    
    let mudata = NSData(bytes: &cipherBuffer, length: cipherBufferSize)
    return mudata.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
  }
  
  func decpryptBase64(encrpted: String) -> String? {
    
    let data : NSData = NSData(base64Encoded: encrpted, options: .ignoreUnknownCharacters)!
    let count = data.length / MemoryLayout<UInt8>.size
    var array = [UInt8](repeating: 0, count: count)
    data.getBytes(&array, length:count * MemoryLayout<UInt8>.size)
    
    var plaintextBufferSize = Int(SecKeyGetBlockSize((self.privateKey)!))
    var plaintextBuffer = [UInt8](repeating:0, count:Int(plaintextBufferSize))
    
    let status = SecKeyDecrypt((self.privateKey)!, SecPadding.PKCS1, array, plaintextBufferSize, &plaintextBuffer, &plaintextBufferSize)
    
    if (status != errSecSuccess) {
      print("Failed Decrypt")
      return nil
    }
    return NSString(bytes: &plaintextBuffer, length: plaintextBufferSize, encoding: String.Encoding.utf8.rawValue)! as String
  }
  
  
  func getPublicKey() -> Data? {
    var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
    let publicK = SecKeyCopyExternalRepresentation(self.publicKey!, error)
    print("getPublicKey ",self.publicKey.debugDescription)
    return publicK! as Data
  }
  
  func getPrivateKey() -> Data? {
    var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
    let privateK = SecKeyCopyExternalRepresentation(self.privateKey!, error)
    print("getPrivateKey ",self.privateKey.debugDescription)
    return privateK! as Data
  }
  
 

//  
  func putPublicKey(publicK:Data, keySize: UInt, privateTag: String, publicTag: String) {
//    let secKeyData : NSData = NSData(base64Encoded: publicK, options: .ignoreUnknownCharacters)!
    let attributes: [String:Any] = [
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeySizeInBits as String: keySize,
                kSecAttrIsPermanent as String: true as AnyObject,
                kSecAttrApplicationTag as String: publicTag as AnyObject
                ]
    self.publicKey = SecKeyCreateWithData(publicK as CFData, attributes as CFDictionary, nil)
    print("putpublickey ",self.publicKey)
  }
  
  func putPrivateKey(privateK:Data, keySize: UInt, privateTag: String, publicTag: String) {
  //    let secKeyData : NSData = NSData(base64Encoded: publicK, options: .ignoreUnknownCharacters)!
      let attributes: [String:Any] = [
                  kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                  kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                  kSecAttrKeySizeInBits as String: keySize,
                  kSecAttrIsPermanent as String: true as AnyObject,
                  kSecAttrApplicationTag as String: privateTag as AnyObject
                  ]
      self.privateKey = SecKeyCreateWithData(privateK as CFData, attributes as CFDictionary, nil)
      print("putprivatekey ",self.privateKey)
    }
}


