import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EmojiScreen extends StatefulWidget {
  const EmojiScreen({super.key});

  @override
  State<EmojiScreen> createState() => _EmojiScreenState();
}

class _EmojiScreenState extends State<EmojiScreen> {
  final _textCtrl = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _copiedEmoji;

  final _examples = [
    'Hôm nay tôi cảm thấy rất vui và hạnh phúc!',
    'Buồn quá, không biết làm sao nữa 😭',
    'WOW! Không thể tin được điều này!',
    'Tức giận quá, sao lại như vậy được?',
    'Yêu em lắm, nhớ em nhiều lắm ❤️',
    'Mệt mỏi quá, cần ngủ thêm một chút',
    'Chúc mừng bạn đã tốt nghiệp! Tuyệt vời!',
    'Haha buồn cười quá, không nhịn được 😂',
  ];

  Future<void> _analyze() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _loading = true; _result = null; });
    try {
      final res = await ApiService.suggestEmoji(text);
      setState(() => _result = res);
      if (mounted) _showResultDialog(res);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối server!'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> res) {
    final emotions = (res['emotions'] as List?)?.cast<Map>() ?? [];
    final suggestions = (res['suggestions'] as List?)?.cast<String>() ?? [];
    final analysis = res['analysis'] as String? ?? '';
    final topEmotion = emotions.isNotEmpty ? emotions.first : null;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Kết quả phân tích cảm xúc',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              if (analysis.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(analysis, style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              if (topEmotion != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(topEmotion['label'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('${topEmotion['score']}%',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (topEmotion['score'] as int) / 100,
                    backgroundColor: AppTheme.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text('🎯 Emoji gợi ý:', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: suggestions.map((emoji) => GestureDetector(
                  onTap: () {
                    _copyEmoji(emoji);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã copy $emoji vào clipboard!'),
                          backgroundColor: AppTheme.primary, duration: const Duration(seconds: 1)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Nhấn vào emoji để copy! 📋', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _copyEmoji(String emoji) {
    Clipboard.setData(ClipboardData(text: emoji));
    setState(() => _copiedEmoji = emoji);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedEmoji = null);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('😊 Gợi ý Emoji AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✍️ Nhập tin nhắn của bạn',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Hôm nay tôi cảm thấy rất vui...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _analyze,
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome),
                        label: Text(_loading ? 'Đang phân tích...' : 'Phân tích cảm xúc'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text('💡 Thử với ví dụ:', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _examples.map((ex) => GestureDetector(
                onTap: () { _textCtrl.text = ex; _analyze(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(ex.length > 30 ? '${ex.substring(0, 30)}...' : ex,
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ),
              )).toList(),
            ),

            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final emotions = (_result!['emotions'] as List?)?.cast<Map>() ?? [];
    final suggestions = (_result!['suggestions'] as List?)?.cast<String>() ?? [];
    final analysis = _result!['analysis'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Kết quả phân tích', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text(analysis, style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
                const SizedBox(height: 16),
                ...emotions.map((em) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(em['label'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('${em['score']}%', style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (em['score'] as int) / 100,
                          backgroundColor: AppTheme.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: ((em['emojis'] as List?) ?? []).cast<String>().map((e) =>
                          GestureDetector(
                            onTap: () => _copyEmoji(e),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _copiedEmoji == e ? AppTheme.primary : Colors.transparent),
                              ),
                              child: Text(e, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 Gợi ý tốt nhất', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: suggestions.map((emoji) => GestureDetector(
                    onTap: () => _copyEmoji(emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _copiedEmoji == emoji ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _copiedEmoji == emoji ? AppTheme.primary : Colors.white12),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Nhấn vào emoji để copy vào clipboard! 📋',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
