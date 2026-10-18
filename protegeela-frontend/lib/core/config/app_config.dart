import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

class AppConfig {
  const AppConfig({
    this.apiBaseUrl = 'http://localhost:8080/api',
    required this.defaultLatitude,
    required this.defaultLongitude,
    required this.defaultZoom,
  });

  final String apiBaseUrl;

  final double defaultLatitude;
  final double defaultLongitude;
  final double defaultZoom;

  factory AppConfig.fromEnvironment() {
    const apiDefine = String.fromEnvironment('API_BASE_URL');
    final apiUrl =
        apiDefine.isNotEmpty ? apiDefine : 'http://localhost:8080/api';
    if (apiUrl.isNotEmpty) {
      final uri = Uri.tryParse(apiUrl);
      final sameOriginPath = uri != null &&
          uri.path.startsWith('/') &&
          !uri.path.startsWith('//') &&
          !uri.hasScheme &&
          !uri.hasAuthority &&
          !uri.hasQuery &&
          !uri.hasFragment;
      if (!sameOriginPath) {
        if (uri == null ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty ||
            uri.hasQuery ||
            uri.hasFragment ||
            uri.userInfo.isNotEmpty) {
          throw ArgumentError(
              'API_BASE_URL deve ser uma URL HTTP(S) válida ou um caminho local como /api.');
        }
        final host = uri.host.toLowerCase();
        final loopback = const {'localhost', '127.0.0.1', '::1', '[::1]'}
            .contains(host);
        if (uri.scheme != 'https' && !loopback && !_isPrivateLanIpv4(host)) {
          throw ArgumentError(
              'API_BASE_URL deve usar HTTPS, exceto localhost ou IP privado da rede local para desenvolvimento.');
        }
      }
    }
    return AppConfig(
      apiBaseUrl: apiUrl,
      defaultLatitude: double.tryParse(
              const String.fromEnvironment('APP_DEFAULT_LATITUDE')) ??
          -3.1190,
      defaultLongitude: double.tryParse(
              const String.fromEnvironment('APP_DEFAULT_LONGITUDE')) ??
          -60.0217,
      defaultZoom:
          double.tryParse(const String.fromEnvironment('APP_DEFAULT_ZOOM')) ??
              12,
    );
  }

  // HTTP is allowed for RFC1918 IPv4 addresses only to support local phone
  // testing. Public hosts must use HTTPS.
  static bool _isPrivateLanIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    final a = octets[0]!;
    final b = octets[1]!;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }
}
