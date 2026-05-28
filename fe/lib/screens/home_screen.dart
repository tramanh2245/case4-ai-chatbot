import 'package:flutter/material.dart';
import 'todo_screen.dart';
import 'chatbot_screen.dart';
import 'emoji_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    TodoScreen(),
    ChatbotScreen(),
    EmojiScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'To-do'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'Chatbot'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_emotions_outlined), activeIcon: Icon(Icons.emoji_emotions), label: 'Emoji AI'),
          ],
        ),
      ),
    );
  }
}
