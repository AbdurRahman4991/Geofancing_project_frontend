
class ApiConfig {
  // 🔹 Base URL
  static const String baseUrl = "http://192.168.20.203:8000/api";

  // 🔹 Common headers for all API requests
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
