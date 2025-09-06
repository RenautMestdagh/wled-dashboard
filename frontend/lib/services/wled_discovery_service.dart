import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

import 'api_service.dart';

class NetworkCapabilityDetector {
  // Check if the platform supports mDNS scanning
  static bool get isMdnsSupported {
    if (kIsWeb) {
      // Web has very limited mDNS support
      return false;
    }

    // Mobile and desktop platforms generally support mDNS
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isLinux ||
        Platform.isMacOS ||
        Platform.isWindows;
  }

  // Get user-friendly message about mDNS capability
  static String get mdnsCapabilityMessage {
    if (kIsWeb) {
      return "Autodiscovery is not available on web browsers";
    }
    if (!isMdnsSupported) {
      return "Autodiscovery is not supported on this platform";
    }
    return "Find available instances";
  }
}

class WLEDDiscoveryService {
  static const String _mdnsType = '_http._tcp.local';
  static const Duration _discoveryTimeout = Duration(seconds: 5);
  static const Duration _apiTimeout = Duration(seconds: 2);

  final MDnsClient _mdnsClient = MDnsClient();
  final ApiService _apiService;

  WLEDDiscoveryService(this._apiService);

  // Check if mDNS is supported on this device
  bool get isMdnsSupported => NetworkCapabilityDetector.isMdnsSupported;

  // Get user-friendly message about mDNS capability
  String get capabilityMessage => NetworkCapabilityDetector.mdnsCapabilityMessage;

  // Discover WLED devices on the network using mDNS
  Future<String> discoverWLEDDevices() async {
    if (!isMdnsSupported) {
      throw Exception("mDNS discovery is not supported on this device");
    }

    final List<String> discoveredDevices = [];

    try {
      // Start the mDNS client
      await _mdnsClient.start();

      // Listen for PTR records (service discovery)
      await for (final PtrResourceRecord ptr in _mdnsClient.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_mdnsType))) {
        if (ptr.domainName.endsWith(_mdnsType)) {
          // Look up SRV records for the service
          await for (final SrvResourceRecord srv in _mdnsClient.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {

            // Look up A/AAAA records for the host
            await for (final IPAddressResourceRecord ip in _mdnsClient.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target))) {

              discoveredDevices.add(ip.address.address);
            }
          }
        }
      }

      // Stop discovery after timeout
      await Future.delayed(_discoveryTimeout);
      _mdnsClient.stop();

    } catch (e) {
      print('mDNS discovery error: $e');
      _mdnsClient.stop();
      rethrow;
    }

    // Verify which devices are actually WLED devices
    final List<String> verifiedWLEDDevices = await _verifyWLEDDevices(discoveredDevices);

    // Filter out already existing devices using the injected ApiService
    final existingIps = _apiService.instances.map((instance) => instance.ip).toList();
    final newDevices = verifiedWLEDDevices.where((ip) => !existingIps.contains(ip)).toList();

    // Create instances for new devices
    int createdCount = 0;
    for (final deviceIp in newDevices) {
      try {
        await _apiService.createInstance(deviceIp, '', fromAutodiscover: true);
        createdCount++;
      } catch (e) {
        // Error is already catched in apiService
      }
    }

    // Show success message
    return '$createdCount new WLED instance${createdCount == 1 ? '' : 's'} found on the network';
  }

  // Verify if discovered devices are actually WLED devices
  Future<List<String>> _verifyWLEDDevices(List<String> devices) async {
    final List<String> verifiedDevices = [];
    final List<Future> verificationFutures = [];

    for (final device in devices) {
      verificationFutures.add(_verifyDevice(device).then((isWLED) {
        if (isWLED) {
          verifiedDevices.add(device);
        }
      }));
    }

    await Future.wait(verificationFutures);
    return verifiedDevices;
  }

  // Verify a single device by querying its JSON info endpoint
  Future<bool> _verifyDevice(String deviceIp) async {
    try {
      final Uri uri = Uri.http('${deviceIp}', '/json/info');
      final http.Response response = await http
          .get(uri)
          .timeout(_apiTimeout, onTimeout: () => http.Response('Timeout', 408));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData.containsKey('ver'); // WLED devices have 'ver' field
      }
    } catch (e) {
      // Device is not WLED or unreachable
      print('Device ${deviceIp} verification failed: $e');
    }
    return false;
  }

  // Clean up
  void dispose() {
    _mdnsClient.stop();
  }
}
