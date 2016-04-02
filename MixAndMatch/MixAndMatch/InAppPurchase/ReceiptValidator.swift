//
//  ReceiptValidator.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/07.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

//  Based on validatereceipt.m
//  Created by Ruotger Skupin on 23.10.10.
//  Copyright 2010-2011 Matthew Stevens, Ruotger Skupin, Apple, Dave Carlton, Fraser Hess, anlumo, David Keegan, Alessandro Segala. All rights reserved.
//
//  Modified for iOS, converted to ARC, and added additional fields by Rick Maddy 2013-08-20
//  Copyright 2013 Rick Maddy. All rights reserved.
//

/*
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the distribution.

Neither the name of the copyright holders nor the names of its contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

class ReceiptValidator: NSObject {

    static let defaultValidator = ReceiptValidator()
    
    func verifyAndObtainReceipt() -> NSDictionary? {
        let receiptURL = NSBundle.mainBundle().appStoreReceiptURL
        if let receipt = verifyReceiptAtPath(receiptURL!.path!) {
            return receipt
        }
        
        // 検証に失敗して終了するなら173でexit
        // ただ、無料での使用もOKなら継続だよな
        //exit(173)
        return nil
    }
    
    // in your project define those two somewhere as such:
    //
    let global_bundleVersion                        = "1.0.3.2" //iOSの場合は、CFBundleVersion
    let global_bundleIdentifier                     = "jp.cafe.MixAndMatch"
    
    let kReceiptBundleIdentifier                    = "BundleIdentifier"
    let kReceiptBundleIdentifierData                = "BundleIdentifierData"
    let kReceiptVersion                             = "Version"
    let kReceiptOpaqueValue                         = "OpaqueValue"
    let kReceiptHash                                = "Hash"
    let kReceiptInApp                               = "InApp"
    let kReceiptOriginalVersion                     = "OrigVer"
    let kReceiptExpirationDate                      = "ExpDate"
    
    let kReceiptInAppQuantity                       = "Quantity"
    let kReceiptInAppProductIdentifier              = "ProductIdentifier"
    let kReceiptInAppTransactionIdentifier          = "TransactionIdentifier"
    let kReceiptInAppPurchaseDate                   = "PurchaseDate"
    let kReceiptInAppOriginalTransactionIdentifier	= "OriginalTransactionIdentifier"
    let kReceiptInAppOriginalPurchaseDate           = "OriginalPurchaseDate"
    let kReceiptInAppSubscriptionExpirationDate     = "SubExpDate"
    let kReceiptInAppCancellationDate               = "CancelDate"
    let kReceiptInAppWebOrderLineItemID             = "WebItemId"

    
    func verifyReceiptAtPath(receiptPath : String) -> NSDictionary? {
        // it turns out, it's a bad idea, to use these two NSBundle methods in your app:
        //
        // bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
        // bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        //
        // http://www.craftymind.com/2011/01/06/mac-app-store-hacked-how-developers-can-better-protect-themselves/
        //
        // so use hard coded values instead (probably even somehow obfuscated)
        
        let bundleVersion = global_bundleVersion
        let bundleIdentifier = global_bundleIdentifier
        
        // avoid making stupid mistakes --> check again
        // iOSの場合は、CFBundleVersion
        assert(
            bundleVersion == NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String,
            "whoops! check the hard-coded CFBundleVersion!")
        assert(
            bundleIdentifier == NSBundle.mainBundle().bundleIdentifier,
            "whoops! check the hard-coded bundle identifier!")
            
        let receipt = dictionaryWithAppStoreReceipt(receiptPath)
        
        if (receipt == nil) {
            return nil
        }
        
        // ローカルレシートはその端末なら検証成功するけど、
        // 別端末にインストールした後は、レストアしてもらう
        var uuidBytes = [UInt8](count:16, repeatedValue:0)
        if let vendorUUID = UIDevice.currentDevice().identifierForVendor {
            vendorUUID.getUUIDBytes(&uuidBytes)
            let input = NSMutableData()
            input.appendBytes(&uuidBytes, length: uuidBytes.count)
            input.appendData((receipt?.objectForKey(kReceiptOpaqueValue))! as! NSData)
            input.appendData((receipt?.objectForKey(kReceiptBundleIdentifierData))! as! NSData)

            if let hash = NSMutableData(length: Int(SHA_DIGEST_LENGTH)) {
                SHA1(UnsafeMutablePointer<UInt8>(input.mutableBytes), input.length, UnsafeMutablePointer<UInt8>(hash.mutableBytes))
                
                if bundleIdentifier == (receipt?.objectForKey(kReceiptBundleIdentifier) as? String)! &&
                    bundleVersion == receipt?.objectForKey(kReceiptVersion) as? String &&
                    hash.isEqualToData((receipt?.objectForKey(kReceiptHash))! as! NSData) {
                        return receipt
                }
            }
        }

        return nil
    }
    
    func appleRootCert() -> NSData {
        // Obtain the Apple Inc. root certificate from http://www.apple.com/certificateauthority/
        // Download the Apple Inc. Root Certificate ( http://www.apple.com/appleca/AppleIncRootCertificate.cer )
        // Add the AppleIncRootCertificate.cer to your app's resource bundle.
        
        let bundle = NSBundle.mainBundle()
        let cert = NSData(contentsOfURL: bundle.URLForResource("AppleIncRootCertificate", withExtension: "cer")!)!
        
        return cert
    }
    
    func PKCS7_type_is_signed(a : UnsafeMutablePointer<PKCS7>) -> Bool {
        return OBJ_obj2nid(a.memory.type) == NID_pkcs7_signed
    }
    
    func PKCS7_type_is_data(a : UnsafeMutablePointer<PKCS7>) -> Bool {
        return OBJ_obj2nid(a.memory.type) == NID_pkcs7_data
    }
    
    // ASN.1 values for the App Store receipt
    let ATTR_START      = 1
    let BUNDLE_ID       = 2
    let VERSION         = 3
    let OPAQUE_VALUE    = 4
    let HASH            = 5
    let ATTR_END        = 6
    let INAPP_PURCHASE  = 17
    let ORIG_VERSION    = 19
    let EXPIRE_DATE     = 21
    
    func  dictionaryWithAppStoreReceipt(receiptPath : String) -> NSDictionary? {
        let rootCertData = appleRootCert()
        
        ERR_load_PKCS7_strings()
        ERR_load_X509_strings()
        OpenSSL_add_all_digests()
        
        // Expected input is a PKCS7 container with signed data containing
        // an ASN.1 SET of SEQUENCE structures. Each SEQUENCE contains
        // two INTEGERS and an OCTET STRING.
        // このやり方だとファイルポインタだけど、BIOでのやり方もある
        // BIOは、Binary Objectsのことかな？？
        let path = ((receiptPath as NSString).stringByStandardizingPath as NSString).fileSystemRepresentation
        let fp = fopen(path, "rb")
        
        if (fp == UnsafeMutablePointer<FILE>()) {
            return nil
        }
        
        let p7 = d2i_PKCS7_fp(fp, nil)
        fclose(fp)
        
        // Check if the receipt file was invalid (otherwise we go crashing and burning)
        if (p7 == UnsafeMutablePointer<PKCS7>()) {
            return nil
        }
        
        if (!PKCS7_type_is_signed(p7)) {
            PKCS7_free(p7)
            return nil
        }

        if !PKCS7_type_is_data(pkcs7_d_sign(p7).memory.contents) {
            PKCS7_free(p7)
            return nil
        }

        var verifyReturnValue : Int32 = 0
        let store = X509_STORE_new()
        if (store != UnsafeMutablePointer<X509_STORE>()) {
            // どうやら、UnsafePointerにすると、&でアドレスを渡せる
            // UnsafeMutablePointerだと渡せない
            // void* と const void*の違いっぽい。
            // varかletかは、void*かvoid* constの違いっぽい
            var data = UnsafePointer<UInt8>(rootCertData.bytes)
            let appleCA = d2i_X509(nil, &data, rootCertData.length)
            if (appleCA != UnsafeMutablePointer<X509>()) {
                let payload = BIO_new(BIO_s_mem())
                X509_STORE_add_cert(store, appleCA)

                if (payload != UnsafeMutablePointer<BIO>()) {
                    verifyReturnValue = PKCS7_verify(p7, nil, store, nil, payload, 0)
                    BIO_free(payload)
                }
        
                X509_free(appleCA)
            }
        
            X509_STORE_free(store)
        }
        
        EVP_cleanup()
        
        if (verifyReturnValue != 1) {
            PKCS7_free(p7)
            return nil
        }
        
        let octets = pkcs7_d_data(pkcs7_d_sign(p7).memory.contents)
        var p : UnsafePointer<UInt8> = UnsafePointer<UInt8>(octets.memory.data)
        let end : UnsafePointer<UInt8> = p.advancedBy(Int(octets.memory.length))
        
        var type : Int32 = 0
        var xclass : Int32 = 0
        var length = 0
        
        ASN1_get_object(&p, &length, &type, &xclass, end - p)
        if (type != V_ASN1_SET) {
            PKCS7_free(p7)
            return nil
        }
        
        let info : NSMutableDictionary? = NSMutableDictionary()
        
        while (p < end) {
            var integer: UnsafeMutablePointer<ASN1_INTEGER>
            
            ASN1_get_object(&p, &length, &type, &xclass, end - p)
            if (type != V_ASN1_SEQUENCE) {
                break
            }

            let seq_end = p.advancedBy(length)
            var attr_type = 0
            var attr_version = 0

            // Attribute type
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
            if (type == V_ASN1_INTEGER && length == 1) {
                // c2i_ASN1_INTEGERで長さの分だけ進む
                integer = c2i_ASN1_INTEGER(nil, &p, length)
                attr_type = ASN1_INTEGER_get(integer)
                ASN1_INTEGER_free(integer)
            }
            
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
            if (type == V_ASN1_INTEGER && length == 1) {
                integer = c2i_ASN1_INTEGER(nil, &p, length)
                attr_version = ASN1_INTEGER_get(integer)
                ASN1_INTEGER_free(integer)
            }

            // Only parse attributes we're interested in
            if ((attr_type > ATTR_START && attr_type < ATTR_END)
                || attr_type == INAPP_PURCHASE || attr_type == ORIG_VERSION || attr_type == EXPIRE_DATE) {
                var key : NSString? = nil
            
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
                if (type == V_ASN1_OCTET_STRING) {
                    let data = NSData(bytes: p, length: length)
            
                    // Bytes
                    if (attr_type == BUNDLE_ID || attr_type == OPAQUE_VALUE || attr_type == HASH) {
                        switch (attr_type) {
                            case BUNDLE_ID:
                                // This is included for hash generation
                                key = kReceiptBundleIdentifierData
                                break
                            case OPAQUE_VALUE:
                                key = kReceiptOpaqueValue
                                break
                            case HASH:
                                key = kReceiptHash
                                break
                            default:
                                break
                        }
                        
                        if let key = key {
                            info?.setObject(data, forKey: key)
                        }
                    }

                    // Strings
                    key = nil
                    if (attr_type == BUNDLE_ID || attr_type == VERSION || attr_type == ORIG_VERSION) {
                        var str_type : Int32 = 0
                        var str_length = 0
                        var str_p = p
                        ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p)
                        if (str_type == V_ASN1_UTF8STRING) {
                            switch (attr_type) {
                            case BUNDLE_ID:
                                key = kReceiptBundleIdentifier
                                break
                            case VERSION:
                                key = kReceiptVersion
                                break
                            case ORIG_VERSION:
                                key = kReceiptOriginalVersion
                                break
                            default:
                                break
                            }
        
                            if let key = key {
                                if let string = NSString(bytes: str_p, length: str_length, encoding: NSUTF8StringEncoding) {
                                    info?.setObject(string, forKey: key)
                                }
                            }
                        }
                    }
        
                    // In-App purchases
                    if (attr_type == INAPP_PURCHASE) {
                        let inApp : NSArray?  = parseInAppPurchasesData(data)
                        let current : NSArray? = info?[kReceiptInApp] as? NSArray
                        if let current = current, let inApp = inApp {
                            info?[kReceiptInApp] = current.arrayByAddingObjectsFromArray(inApp as [AnyObject])
                        } else {
                            info?.setObject(inApp!, forKey: kReceiptInApp)
                        }
                    }
                }
                    
                p += length
            }
        
            // Skip any remaining fields in this SEQUENCE
            while (p < seq_end) {
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
                p += length
            }
        }
        
        PKCS7_free(p7)
        
        return info
    }
    
    // ASN.1 values for In-App Purchase values
    let INAPP_ATTR_START	= 1700
    let INAPP_QUANTITY		= 1701
    let INAPP_PRODID		= 1702
    let INAPP_TRANSID		= 1703
    let INAPP_PURCHDATE		= 1704
    let INAPP_ORIGTRANSID	= 1705
    let INAPP_ORIGPURCHDATE	= 1706
    let INAPP_ATTR_END		= 1707
    let INAPP_SUBEXP_DATE   = 1708
    let INAPP_WEBORDER      = 1711
    let INAPP_CANCEL_DATE   = 1712

    func parseInAppPurchasesData(inappData : NSData) -> NSArray? {
        var type : Int32 = 0
        var xclass : Int32 = 0
        var length = 0
    
        let dataLenght = inappData.length
        var p = UnsafePointer<UInt8>(inappData.bytes)
    
        let end = p + dataLenght
    
        let resultArray = NSMutableArray()
    
        while (p < end) {
            ASN1_get_object(&p, &length, &type, &xclass, end - p)

            let set_end = p + length

            if(type != V_ASN1_SET) {
                break
            }
    
            let item = NSMutableDictionary(capacity: 6)

            
            while (p < set_end) {
                ASN1_get_object(&p, &length, &type, &xclass, set_end - p)
                if (type != V_ASN1_SEQUENCE) {
                        break
                }
    
                let seq_end = p + length
    
                var attr_type = 0
                var attr_version = 0
                
                // Attribute type
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
                if (type == V_ASN1_INTEGER) {
                    if length <= 2 {
                        var integer: UnsafeMutablePointer<ASN1_INTEGER>
                        integer = c2i_ASN1_INTEGER(nil, &p, length)
                        attr_type = ASN1_INTEGER_get(integer)
                        ASN1_INTEGER_free(integer)
                    }
                }
    
                // Attribute version
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
                if (type == V_ASN1_INTEGER && length == 1) {
                    // clang analyser hit (wontfix at the moment, since the code might come in handy later)
                    // But if someone has a convincing case throwing that out, I might do so, Roddi
                    var integer: UnsafeMutablePointer<ASN1_INTEGER>
                    integer = c2i_ASN1_INTEGER(nil, &p, length)
                    attr_version = ASN1_INTEGER_get(integer)
                    ASN1_INTEGER_free(integer)
                }
    
                // Only parse attributes we're interested in
                if ((attr_type > INAPP_ATTR_START && attr_type < INAPP_ATTR_END)
                    || attr_type == INAPP_SUBEXP_DATE || attr_type == INAPP_WEBORDER || attr_type == INAPP_CANCEL_DATE) {
                        var key : String? = nil
                
                        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
                        if (type == V_ASN1_OCTET_STRING) {
                
                            // Integers
                            if (attr_type == INAPP_QUANTITY || attr_type == INAPP_WEBORDER) {
                                var num_type : Int32 = 0
                                var num_length = 0
                                var num_p = p
                                ASN1_get_object(&num_p, &num_length, &num_type, &xclass, seq_end - num_p)
                                if (num_type == V_ASN1_INTEGER) {
                                    var quantity = 0
                                    var integer: UnsafeMutablePointer<ASN1_INTEGER>
                                    integer = c2i_ASN1_INTEGER(nil, &num_p, num_length)
                                    quantity = ASN1_INTEGER_get(integer)
                                    ASN1_INTEGER_free(integer)
                            
                                    if (attr_type == INAPP_QUANTITY) {
                                        item.setObject(quantity, forKey: kReceiptInAppQuantity)
                                    } else if (attr_type == INAPP_WEBORDER) {
                                        item.setObject(quantity, forKey: kReceiptInAppWebOrderLineItemID)
                                    }
                                }
                            }
                    
                            // Strings
                            if (attr_type == INAPP_PRODID ||
                                attr_type == INAPP_TRANSID ||
                                attr_type == INAPP_ORIGTRANSID ||
                                attr_type == INAPP_PURCHDATE ||
                                attr_type == INAPP_ORIGPURCHDATE ||
                                attr_type == INAPP_SUBEXP_DATE ||
                                attr_type == INAPP_CANCEL_DATE) {
    
                                    var str_type : Int32 = 0
                                    var str_length = 0
                                    var str_p = p
                                    ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p)
                                    if (str_type == V_ASN1_UTF8STRING) {
                                        switch (attr_type) {
                                        case INAPP_PRODID:
                                            key = kReceiptInAppProductIdentifier
                                            break
                                        case INAPP_TRANSID:
                                            key = kReceiptInAppTransactionIdentifier
                                            break
                                        case INAPP_ORIGTRANSID:
                                            key = kReceiptInAppOriginalTransactionIdentifier
                                            break
                                        default:
                                            break
                                        }
    
                                        if let key = key {
                                            if let string = NSString(bytes: str_p, length: str_length, encoding: NSUTF8StringEncoding) {
                                                item.setObject(string, forKey: key)
                                            }
                                        }
                                    }
                                    if (str_type == V_ASN1_IA5STRING) {
                                        switch (attr_type) {
                                        case INAPP_PURCHDATE:
                                            key = kReceiptInAppPurchaseDate
                                            break
                                        case INAPP_ORIGPURCHDATE:
                                            key = kReceiptInAppOriginalPurchaseDate
                                            break
                                        case INAPP_SUBEXP_DATE:
                                            key = kReceiptInAppSubscriptionExpirationDate
                                            break
                                        case INAPP_CANCEL_DATE:
                                            key = kReceiptInAppCancellationDate
                                            break
                                        default:
                                            break
                                        }
    
                                        if let key = key {
                                            if let string = NSString(bytes: str_p, length: str_length, encoding: NSASCIIStringEncoding) {
                                                item.setObject(string, forKey: key)
                                            }
                                        }
                                    }
                            }
                        }
    
                        p += length
                }
    
                // Skip any remaining fields in this SEQUENCE
                while (p < seq_end) {
                    ASN1_get_object(&p, &length, &type, &xclass, seq_end - p)
                    p += length
                }
            }
    
            // Skip any remaining fields in this SET
            while (p < set_end) {
                ASN1_get_object(&p, &length, &type, &xclass, set_end - p)
                p += length
            }
    
            resultArray.addObject(item)
        }
    
        return resultArray
    }
}
