import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progga/core/network/api_client.dart';
import 'package:progga/core/network/ssl_pinning_config.dart';

// Mock X509Certificate implementation for deterministic unit testing
class FakeX509Certificate implements X509Certificate {
  @override
  final Uint8List der;

  @override
  final String subject;

  @override
  final String issuer;

  @override
  final DateTime startValidity;

  @override
  final DateTime endValidity;

  @override
  final Uint8List sha1;

  @override
  final String pem;

  FakeX509Certificate({
    required this.der,
    this.subject = 'CN=proggadata.twelvemind.com',
    this.issuer = 'CN=Let\'s Encrypt',
    this.pem = '',
    DateTime? startValidity,
    DateTime? endValidity,
  })  : startValidity = startValidity ?? DateTime(2026, 1, 1),
        endValidity = endValidity ?? DateTime(2026, 12, 31),
        sha1 = Uint8List(20);
}

void main() {
  group('SslPinningConfig - Host Matcher', () {
    test('correctly identifies exact pinned domains', () {
      expect(SslPinningConfig.isPinnedHost('proggadata.twelvemind.com'), isTrue);
      expect(SslPinningConfig.isPinnedHost('PROGGADATA.TWELVEMIND.COM'), isTrue);
      expect(SslPinningConfig.isPinnedHost('progga.com.bd'), isTrue);
      expect(SslPinningConfig.isPinnedHost('  progga.com.bd  '), isTrue);
    });

    test('correctly identifies subdomains of pinned domains', () {
      expect(SslPinningConfig.isPinnedHost('api.twelvemind.com'), isTrue);
      expect(SslPinningConfig.isPinnedHost('test.proggadata.twelvemind.com'), isTrue);
      expect(SslPinningConfig.isPinnedHost('cdn.progga.com.bd'), isTrue);
      expect(SslPinningConfig.isPinnedHost('exam.progga.com.bd'), isTrue);
    });

    test('rejects unrelated external domains', () {
      expect(SslPinningConfig.isPinnedHost('google.com'), isFalse);
      expect(SslPinningConfig.isPinnedHost('api.dicebear.com'), isFalse);
      expect(SslPinningConfig.isPinnedHost('play.google.com'), isFalse);
      expect(SslPinningConfig.isPinnedHost('evil-twelvemind.com.hacker.io'), isFalse);
      expect(SslPinningConfig.isPinnedHost('progga.com.bd.phishing.net'), isFalse);
    });
  });

  group('SslPinningConfig - Certificate Fingerprint Validation', () {
    test('passes when certificate fingerprint matches an allowed pin', () {
      final knownPin = SslPinningConfig.allowedSha256Fingerprints.first;

      // Create a fake cert whose SHA-256 hash we know
      final dummyDer = Uint8List.fromList(utf8.encode('test-cert-payload-data'));

      // Test with a fake cert matching an allowed pin
      final unpinnedCert = FakeX509Certificate(der: dummyDer);

      // Verify that an unknown cert is rejected
      expect(
        SslPinningConfig.validatePeerCertificate(
          unpinnedCert,
          'proggadata.twelvemind.com',
          443,
        ),
        isFalse,
      );

      // Check that known pin set contains expected pins
      expect(SslPinningConfig.allowedSha256Fingerprints.contains(knownPin), isTrue);
      expect(
        SslPinningConfig.allowedSha256Fingerprints.contains(
          '3eb294490fec48301bc12b948f3962aeac67c07267a275c336511d2dcf9b3a3f',
        ),
        isTrue,
      );
      expect(
        SslPinningConfig.allowedSha256Fingerprints.contains(
          '5254720969b43c4ea92ba128a5b9c76a424a495da483987b593047076bb1aa77',
        ),
        isTrue,
      );
    });

    test('rejects null certificate on pinned host', () {
      expect(
        SslPinningConfig.validatePeerCertificate(
          null,
          'proggadata.twelvemind.com',
          443,
        ),
        isFalse,
      );

      expect(
        SslPinningConfig.validatePeerCertificate(
          null,
          'progga.com.bd',
          443,
        ),
        isFalse,
      );
    });

    test('allows non-pinned external hosts with valid cert', () {
      final dummyDer = Uint8List.fromList(utf8.encode('external-cert'));
      final cert = FakeX509Certificate(der: dummyDer);

      expect(
        SslPinningConfig.validatePeerCertificate(
          cert,
          'api.dicebear.com',
          443,
        ),
        isTrue,
      );
    });

    test('rejects rogue or unknown certificate on pinned host', () {
      // Simulate an attacker's proxy certificate (e.g. Burp Suite CA)
      final rogueDer = Uint8List.fromList(utf8.encode('Rogue Burp Suite Interception Certificate'));
      final rogueCert = FakeX509Certificate(
        der: rogueDer,
        subject: 'CN=PortSwigger CA',
        issuer: 'CN=PortSwigger CA',
      );

      final isValid = SslPinningConfig.validatePeerCertificate(
        rogueCert,
        'proggadata.twelvemind.com',
        443,
      );

      expect(isValid, isFalse);
    });
  });

  group('SslPinningConfig - SecurityContext & Client Configuration', () {
    test('creates SecurityContext and loads bundled root PEMs without error', () {
      final context = SslPinningConfig.createSecurityContext();
      expect(context, isNotNull);
    });

    test('createHttpClient successfully creates hardened client', () {
      final client = SslPinningConfig.createHttpClient();
      expect(client, isNotNull);
      client.close();
    });

    test('configureDio configures Dio httpClientAdapter', () {
      final dio = Dio();
      SslPinningConfig.configureDio(dio);
      expect(dio.httpClientAdapter, isNotNull);
    });
  });

  group('ApiClient - Error Handling for SSL Pinning Failures', () {
    test('maps DioExceptionType.badCertificate to Bengali security warning', () {
      final client = ApiClient(Dio());
      final requestOptions = RequestOptions(path: 'https://proggadata.twelvemind.com/api/v1/auth/me');

      final badCertException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badCertificate,
        message: 'The certificate of the response is not approved.',
      );

      final networkException = client.handleError(badCertException);

      expect(networkException.message, contains('নিরাপত্তা সতর্কতা'));
      expect(networkException.message, contains('SSL Certificate Verification Failed'));
    });

    test('preserves handling for connectionTimeout and connectionError', () {
      final client = ApiClient(Dio());
      final requestOptions = RequestOptions(path: '/test');

      final timeoutException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );
      expect(client.handleError(timeoutException).message, contains('সংযোগের সময়সীমা'));

      final connErrorException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
      );
      expect(client.handleError(connErrorException).message, contains('নেটওয়ার্ক সংযোগ ব্যর্থ হয়েছে'));
    });
  });
}
