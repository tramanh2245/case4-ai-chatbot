import 'package:flutter/material.dart';

class TodoModel {
  final int id;
  final String title;
  final String category;
  final String priority;
  final bool completed;
  final String createdAt;
  final String? completedAt;

  TodoModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.completed,
    required this.createdAt,
    this.completedAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
        id: json['id'],
        title: json['title'],
        category: json['category'] ?? 'general',
        priority: json['priority'] ?? 'MEDIUM',
        completed: json['completed'] ?? false,
        createdAt: json['createdAt'] ?? '',
        completedAt: json['completedAt'],
      );

  Color get priorityColor {
    switch (priority) {
      case 'HIGH':
        return const Color(0xFFFF6584);
      case 'LOW':
        return const Color(0xFF03DAC6);
      default:
        return const Color(0xFFFFB347);
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'HIGH':
        return 'Cao';
      case 'LOW':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }
}

class SuggestionModel {
  final String title;
  final int confidence;
  final String reason;

  SuggestionModel({
    required this.title,
    required this.confidence,
    required this.reason,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) => SuggestionModel(
        title: json['title'],
        confidence: json['confidence'],
        reason: json['reason'],
      );
}
