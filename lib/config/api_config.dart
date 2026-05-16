class ApiConfig {
  // Android emulator → use 10.0.2.2
  // Physical device on same Wi-Fi → use the host PC's IPv4 (run `ipconfig` on Windows)
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}