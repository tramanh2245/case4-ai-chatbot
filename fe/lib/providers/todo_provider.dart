import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../services/api_service.dart';

class TodoProvider extends ChangeNotifier {
  List<TodoModel> todos = [];
  List<SuggestionModel> suggestions = [];
  Map<String, dynamic> stats = {};
  bool loading = false;
  String? error;

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      todos = await ApiService.getTodos();
      suggestions = await ApiService.getSuggestions();
      stats = await ApiService.getStats();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo(String title, String category, String priority) async {
    await ApiService.addTodo(title, category, priority);
    await loadAll();
  }

  Future<void> completeTodo(int id) async {
    await ApiService.completeTodo(id);
    await loadAll();
  }

  Future<void> deleteTodo(int id) async {
    await ApiService.deleteTodo(id);
    await loadAll();
  }

  Future<void> addFromSuggestion(String title) async {
    await addTodo(title, 'suggested', 'MEDIUM');
  }
}
