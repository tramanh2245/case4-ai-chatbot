class AppConfig {
  // USB cable: chạy "adb reverse tcp:8080 tcp:8080" rồi dùng localhost
  static const String baseUrl = 'http://localhost:8080/api';

  static const String todosEndpoint = '$baseUrl/todos';
  static const String chatEndpoint = '$baseUrl/chat';
  static const String emojiEndpoint = '$baseUrl/emoji/suggest';
}
