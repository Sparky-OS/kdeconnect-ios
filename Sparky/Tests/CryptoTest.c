// SPDX-License-Identifier: GPL-3.0-only
// The app's iOS <=17 PKCS12 parameters must work without a provider file.
#include <assert.h>
#include <openssl/pkcs12.h>
#include <openssl/provider.h>
#include <openssl/evp.h>
#include <stdio.h>
int main(void)
{
    OSSL_PROVIDER *def = OSSL_PROVIDER_load(NULL, "default");
    OSSL_PROVIDER *legacy = OSSL_PROVIDER_load(NULL, "legacy");
    assert(def && legacy);
    EVP_PKEY *key = EVP_PKEY_Q_keygen(NULL, NULL, "EC", "prime256v1");
    assert(key);
    X509 *cert = X509_new();
    assert(cert && X509_set_version(cert, 2) && X509_set_pubkey(cert, key));
    ASN1_INTEGER_set(X509_get_serialNumber(cert), 1);
    X509_gmtime_adj(X509_getm_notBefore(cert), 0);
    X509_gmtime_adj(X509_getm_notAfter(cert), 3600);
    X509_NAME *name = X509_NAME_new();
    assert(name);
    assert(X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, (const unsigned char *)"test", -1, -1, 0));
    assert(X509_set_subject_name(cert, name) && X509_set_issuer_name(cert, name) && X509_sign(cert, key, EVP_sha512()));
    X509_NAME_free(name);
    for (int old = 0; old < 2; ++old) {
        PKCS12 *p12 = old ? PKCS12_create_ex("", "KDE Connect", key, cert, NULL,
            NID_pbe_WithSHA1And3_Key_TripleDES_CBC, NID_pbe_WithSHA1And40BitRC2_CBC,
            PKCS12_DEFAULT_ITER, -1, 0, NULL, NULL) :
            PKCS12_create("", "KDE Connect", key, cert, NULL, 0, 0, 0, PKCS12_DEFAULT_ITER, 0);
        assert(p12);
        if (old) assert(PKCS12_set_mac(p12, "", -1, NULL, 0, PKCS12_DEFAULT_ITER, EVP_sha1()));
        assert(PKCS12_verify_mac(p12, "", -1));
        EVP_PKEY *decoded = NULL; X509 *decoded_cert = NULL;
        assert(PKCS12_parse(p12, "", &decoded, &decoded_cert, NULL));
        assert(EVP_PKEY_eq(decoded, key) == 1 && X509_cmp(decoded_cert, cert) == 0);
        EVP_PKEY_free(decoded); X509_free(decoded_cert); PKCS12_free(p12);
    }
    EVP_PKEY_free(key); X509_free(cert);
    OSSL_PROVIDER_unload(legacy); OSSL_PROVIDER_unload(def);
    puts("PASS: both identity PKCS12 formats round-trip with built-in providers and no module directory");
}
