import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _apiKeyCtrl = TextEditingController();
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      if (provider.messages.isEmpty) {
        provider.messages.add(ChatMessageModel(
          text: 'Xin chào! 👋 Tôi là trợ lý CSKH AI.\nTôi có thể giúp bạn về:\n📦 Đơn hàng • 🚚 Giao hàng\n🔄 Đổi trả • 🎁 Khuyến mãi • 👤 Tài khoản',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        provider.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _showSettings() {
    _apiKeyCtrl.text = context.read<ChatProvider>().apiKey;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚙️ Cài đặt Chatbot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Nhập Gemini API Key để dùng AI thực sự.\nKhông có key, chatbot dùng FAQ có sẵn.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (_, setModalState) => TextField(
                controller: _apiKeyCtrl,
                obscureText: !_showApiKey,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Gemini API Key (tùy chọn)',
                  prefixIcon: const Icon(Icons.key, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                    onPressed: () => setModalState(() => _showApiKey = !_showApiKey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ChatProvider>().setApiKey(_apiKeyCtrl.text.trim());
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã lưu API Key!'), backgroundColor: AppTheme.primary),
                      );
                    },
                    child: const Text('Lưu'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    context.read<ChatProvider>().clearMessages();
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa lịch sử', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 CSKH AI Chatbot'),
        actions: [
          Consumer<ChatProvider>(
            builder: (_, p, __) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.apiKey.isNotEmpty ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.apiKey.isNotEmpty ? Colors.green : Colors.orange),
              ),
              child: Text(
                p.apiKey.isNotEmpty ? '🟢 Gemini' : '🟡 FAQ',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettings),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, provider, __) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length + (provider.loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == provider.messages.length) return const _TypingIndicator();
                    return _ChatBubble(message: provider.messages[i]);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                prefixIcon: Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
              ),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)])
              : null,
          color: isUser ? null : AppTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Text('🤖', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text('CSKH AI', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            Text(message.text, style: TextStyle(color: isUser ? Colors.white : const Color(0xDEFFFFFF), fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(18)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
            SizedBox(width: 8),
            Text('Đang trả lời...', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
