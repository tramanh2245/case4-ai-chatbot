import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/todo_model.dart';
import '../models/chat_message.dart';

class ApiService {
  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  // ───── Todo ─────

  static Future<List<TodoModel>> getTodos() async {
    final res = await http.get(Uri.parse(AppConfig.todosEndpoint));
    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => TodoModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load todos');
  }

  static Future<TodoModel> addTodo(String title, String category, String priority) async {
    final res = await http.post(
      Uri.parse(AppConfig.todosEndpoint),
      headers: _headers,
      body: jsonEncode({'title': title, 'category': category, 'priority': priority}),
    );
    if (res.statusCode == 200) return TodoModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    throw Exception('Failed to add todo');
  }

  static Future<void> completeTodo(int id) async {
    final res = await http.put(Uri.parse('${AppConfig.todosEndpoint}/$id/complete'));
    if (res.statusCode != 200) throw Exception('Failed to complete todo');
  }

  static Future<void> deleteTodo(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.todosEndpoint}/$id'));
    if (res.statusCode != 204) throw Exception('Failed to delete todo');
  }

  static Future<List<SuggestionModel>> getSuggestions() async {
    final res = await http.get(Uri.parse('${AppConfig.todosEndpoint}/suggestions'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => SuggestionModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse('${AppConfig.todosEndpoint}/stats'));
    if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
    return {};
  }

  // ───── Chat ─────

  static Future<Map<String, dynamic>> sendMessage(
      String message, String sessionId, String apiKey) async {
    final res = await http.post(
      Uri.parse(AppConfig.chatEndpoint),
      headers: _headers,
      body: jsonEncode({'message': message, 'sessionId': sessionId, 'apiKey': apiKey}),
    );
    if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to send message');
  }

  static Future<void> clearChatHistory(String sessionId) async {
    await http.delete(Uri.parse('${AppConfig.chatEndpoint}/history/$sessionId'));
  }

  // ───── Emoji ─────

  static Future<Map<String, dynamic>> suggestEmoji(String text) async {
    final res = await http.post(
      Uri.parse(AppConfig.emojiEndpoint),
      headers: _headers,
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to suggest emoji');
  }
}
