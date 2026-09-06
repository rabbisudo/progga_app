import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Production-grade SSL Pinning Configuration for Progga Mobile Application.
///
/// Implements a multi-layered defence:
/// 1. Isolated [SecurityContext] (withTrustedRoots: false):
///    Trusts only official Let's Encrypt / ISRG Root CAs. Prevents user/device-installed
///    rogue CAs (such as Burp Suite, Charles Proxy, Fiddler) from intercepting traffic.
/// 2. SHA-256 Certificate Fingerprint Validation via [IOHttpClientAdapter.validateCertificate]:
///    Guarantees that the presented TLS certificate matches authorized leaf, intermediate,
///    or root certificates.
/// 3. Resilient to Let's Encrypt 90-day certificate rotations by pinning intermediate
///    and root CAs alongside active leaf certificates.
class SslPinningConfig {
  SslPinningConfig._();

  /// Pinned domain names and suffixes
  static const Set<String> pinnedExactDomains = {
    'proggadata.twelvemind.com',
    'progga.com.bd',
  };

  static const List<String> pinnedDomainSuffixes = [
    '.twelvemind.com',
    '.progga.com.bd',
  ];

  /// Checks whether a given host belongs to the Progga pinned infrastructure.
  static bool isPinnedHost(String host) {
    final cleanHost = host.trim().toLowerCase();
    if (pinnedExactDomains.contains(cleanHost)) {
      return true;
    }
    for (final suffix in pinnedDomainSuffixes) {
      if (cleanHost.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }

  /// Whitelist of authorized SHA-256 certificate fingerprints (hex, lowercase, no colons).
  static const Set<String> allowedSha256Fingerprints = {
    // --- Active Leaf Certificates ---
    // proggadata.twelvemind.com leaf
    '3eb294490fec48301bc12b948f3962aeac67c07267a275c336511d2dcf9b3a3f',
    // progga.com.bd leaf
    '5254720969b43c4ea92ba128a5b9c76a424a495da483987b593047076bb1aa77',

    // --- Let's Encrypt Generation Y Intermediates (Current Issuers) ---
    // YR2 (Intermediate signing proggadata.twelvemind.com)
    '238b85a0099c65b970477d5724f1a1d475ce5058cffe4efa8733899bdb863c47',
    // YE1 (Intermediate signing progga.com.bd)
    'a2372d06431e9716365eeed47ec020351497d182fcc038e457e58168a03cac07',
    // YR1 (Gen-Y RSA Backup Intermediate)
    '13949634d99cd6fd6aa80bc034fefacceb1969feef986586713ecdbb05758d3f',
    // YR3 (Gen-Y RSA Backup Intermediate)
    '35500cb63b8d9769528d65d87220f51c069807a595acbf2fb6eca38fbe0a4bd2',
    // YE2 (Gen-Y ECDSA Backup Intermediate)
    '97658de8c68dfa98ace1e5028a63d54a1aae911b3e21471076c6850cd08cbab4',
    // YE3 (Gen-Y ECDSA Backup Intermediate)
    '82bcfc482cc19f71e6f98f4a027616ebda6d47096d408b336160d1c0ef8b995a',

    // --- Let's Encrypt Generation X Intermediates (Compatibility) ---
    'b1bc968bd4f49d622aa89a81f8306011d4f85a89c71c8b32f21cf5e94e3e1d74', // R10
    '072c69466e012ef4b4764b3ef8b9e66ff7c527e025ec617be34f595b28d6b83f', // R11
    'a151b7534b82d415da8d1ec9c7667a74070a7b6cf2e3532f86641ebf279f0ec6', // E5
    '9fa733d3b764c2084b9347895e7c0cecd7ebfd6cae0a4f5f50ef9c4a5c531398', // E6

    // --- Let's Encrypt Root CAs & Cross-Signed Roots ---
    // ISRG Root X1 (Self-signed Root CA, valid until 2035)
    '96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6',
    // ISRG Root X2 (Self-signed ECDSA Root CA, valid until 2040)
    '69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470',
    // Root YR (Cross-signed by ISRG Root X1)
    '072639d0b140d5bffae16ad9c3f6cc6086040621f51ee61a6d46a8915c07cf76',
    // Root YE (Cross-signed by ISRG Root X2)
    '0fc0901cca2bae9e9fdbb02d50d02f1094f7b36672086991b9e897626dc485f0',
    // Root YR (Self-signed Root CA)
    'e57b7e6f150c419102e8d5c055729ff967b9d1a829bf00cec89ca604ebf4a86f',
    // Root YE (Self-signed Root CA)
    'e14ffcad5b0025731006caa43a121a22d8e9700f4fb9cf852f02a708aa5d5666',
  };

  /// Bundled trusted Root CA certificates in PEM format.
  /// Includes: ISRG Root X1, ISRG Root X2, Root YR (cross by X1), Root YE (cross by X2).
  static const String trustedRootPem = '''
-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIICGzCCAaGgAwIBAgIQQdKd0XLq7qeAwSxs6S+HUjAKBggqhkjOPQQDAzBPMQsw
CQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2gg
R3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMjAeFw0yMDA5MDQwMDAwMDBaFw00
MDA5MTcxNjAwMDBaME8xCzAJBgNVBAYTAlVTMSkwJwYDVQQKEyBJbnRlcm5ldCBT
ZWN1cml0eSBSZXNlYXJjaCBHcm91cDEVMBMGA1UEAxMMSVNSRyBSb290IFgyMHYw
EAYHKoZIzj0CAQYFK4EEACIDYgAEzZvVn4CDCuwJSvMWSj5cz3es3mcFDR0HttwW
+1qLFNvicWDEukWVEYmO6gbf9yoWHKS5xcUy4APgHoIYOIvXRdgKam7mAHf7AlF9
ItgKbppbd9/w+kHsOdx1ymgHDB/qo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0T
AQH/BAUwAwEB/zAdBgNVHQ4EFgQUfEKWrt5LSDv6kviejM9ti6lyN5UwCgYIKoZI
zj0EAwMDaAAwZQIwe3lORlCEwkSHRhtFcP9Ymd70/aTSVaYgLXTWNLxBo1BfASdW
tL4ndQavEi51mI38AjEAi/V3bNTIZargCyzuFJ0nN6T5U6VR5CmD1/iQMVtCnwr1
/q4AaOeMSQ+2b1tbFfLn
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
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
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIICpjCCAiugAwIBAgIRAIchZfw0tuX7qK3Vs3BftTowCgYIKoZIzj0EAwMwTzEL
MAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2VhcmNo
IEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDIwHhcNMjYwNTEzMDAwMDAwWhcN
MzIwOTAyMjM1OTU5WjAuMQswCQYDVQQGEwJVUzENMAsGA1UEChMESVNSRzEQMA4G
A1UEAxMHUm9vdCBZRTB2MBAGByqGSM49AgEGBSuBBAAiA2IABDwS/6vhrcVqcbBo
+wgdI3fwn9x7DNJJOY/lTOti0vkwuRN87RhEhTH17E7XyFjWsPYhIPt/wzOqxTd2
b+4ZJNy9ID04YywF9U5zasDVyGSNErVNtz8uSGh5izW87j77GaOB6zCB6DAOBgNV
HQ8BAf8EBAMCAQYwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDwYDVR0TAQH/BAUwAwEB
/zAdBgNVHQ4EFgQUo8gmWo6hTNA1Y/ybI8g6rlbzT1YwHwYDVR0jBBgwFoAUfEKW
rt5LSDv6kviejM9ti6lyN5UwMgYIKwYBBQUHAQEEJjAkMCIGCCsGAQUFBzAChhZo
dHRwOi8veDIuaS5sZW5jci5vcmcvMBMGA1UdIAQMMAowCAYGZ4EMAQIBMCcGA1Ud
HwQgMB4wHKAaoBiGFmh0dHA6Ly94Mi5jLmxlbmNyLm9yZy8wCgYIKoZIzj0EAwMD
aQAwZgIxAMU19WCtmxVND8UHBZRoma49Z7jPs64Dma0eTu1OChVbB/2J7GV3nvYK
Ax54uk1G9QIxAO0miLVJu8PLNiXXXkiE/gsK3CTRTF/aeo4bMX42Zw40csRU6AC2
6hSW1/IWaas6dg==
-----END CERTIFICATE-----
''';

  /// Creates an isolated [SecurityContext] that ignores user-installed root CAs
  /// and only trusts authentic Let's Encrypt / ISRG root certificates.
  static SecurityContext createSecurityContext() {
    final context = SecurityContext(withTrustedRoots: false);
    context.setTrustedCertificatesBytes(trustedRootPem.codeUnits);
    return context;
  }

  /// Creates a hardened [HttpClient] instance with the isolated [SecurityContext].
  /// If the TLS handshake encounters an untrusted certificate chain, it is rejected.
  static HttpClient createHttpClient() {
    final client = HttpClient(context: createSecurityContext());
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // In SSL pinning, any certificate that fails the SecurityContext chain is untrusted
      debugPrint('[SSL-Pinning] badCertificateCallback invoked: Handshake rejected for $host (cert: ${cert.subject})');
      return false;
    };
    return client;
  }

  /// Validates the peer certificate fingerprint against the authorized whitelist.
  static bool validatePeerCertificate(X509Certificate? cert, String host, int port) {
    // If the host is not part of Progga infrastructure, allow standard platform validation
    if (!isPinnedHost(host)) {
      return cert != null;
    }

    if (cert == null) {
      debugPrint('[SSL-Pinning] Certificate validation failed: Null certificate for $host');
      return false;
    }

    final derBytes = cert.der;
    final fingerprint = sha256.convert(derBytes).toString().toLowerCase();

    final isPinned = allowedSha256Fingerprints.contains(fingerprint);
    if (!isPinned) {
      debugPrint(
        '[SSL-Pinning] MISMATCH! Certificate fingerprint $fingerprint for host $host '
        'is NOT in the allowed pins list. Rejecting connection.',
      );
      return false;
    }

    return true;
  }

  /// Configures [Dio] to enforce SSL pinning using [IOHttpClientAdapter].
  /// On Flutter Web, certificate verification is handled natively by the browser sandbox.
  static void configureDio(Dio dio) {
    if (kIsWeb) return;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: createHttpClient,
      validateCertificate: validatePeerCertificate,
    );
  }
}
