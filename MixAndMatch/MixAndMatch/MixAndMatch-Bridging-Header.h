//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <openssl/pkcs7.h>
#include <openssl/objects.h>
#include <openssl/sha.h>
#undef I
#include <openssl/x509.h>
#include <openssl/err.h>

#import <Foundation/Foundation.h>

char *pkcs7_d_char(PKCS7 *ptr);
ASN1_OCTET_STRING *pkcs7_d_data(PKCS7 *ptr);
PKCS7_SIGNED *pkcs7_d_sign(PKCS7 *ptr);
PKCS7_ENVELOPE *pkcs7_d_enveloped(PKCS7 *ptr);
PKCS7_SIGN_ENVELOPE *pkcs7_d_signed_and_enveloped(PKCS7 *ptr);
PKCS7_DIGEST *pkcs7_d_digest(PKCS7 *ptr);
PKCS7_ENCRYPT *pkcs7_d_encrypted(PKCS7 *ptr);
ASN1_TYPE *pkcs7_d_other(PKCS7 *ptr);
PKCS7* pkcs7_signed_contents(PKCS7_SIGNED *ptr);
