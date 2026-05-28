import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessageModel> messages = [];
  bool loading = false;
  String sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  String apiKey = '';

  Future<void> sendMessage(String text) async {
    messages.add(ChatMessageModel(text: text, isUser: true, timestamp: DateTime.now()));
    loading = true;
    notifyListeners();

    try {
      final res = await ApiService.sendMessage(text, sessionId, apiKey);
      messages.add(ChatMessageModel(
        text: res['response'] ?? 'Xin lỗi, có lỗi xảy ra.',
        isUser: false,
        timestamp: DateTime.now(),
        source: res['source'],
      ));
    } catch (_) {
      messages.add(ChatMessageModel(
        text: 'Không thể kết nối đến server. Kiểm tra lại Spring Boot đang chạy.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    messages = [];
    ApiService.clearChatHistory(sessionId);
    sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  void setApiKey(String key) {
    apiKey = key;
    notifyListeners();
  }
}
