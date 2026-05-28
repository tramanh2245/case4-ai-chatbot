import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog({String? forDate}) {
    final titleCtrl = TextEditingController();
    String selectedCategory = 'work';
    String selectedPriority = 'MEDIUM';

    final categories = ['work', 'personal', 'health', 'study', 'shopping'];
    final categoryIcons = {'work': '💼', 'personal': '🏠', 'health': '💪', 'study': '📚', 'shopping': '🛒'};
    final priorities = {'LOW': '🟢 Thấp', 'MEDIUM': '🟡 Trung bình', 'HIGH': '🔴 Cao'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      forDate != null ? 'Thêm task — $forDate' : 'Thêm công việc mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tên công việc...',
                  prefixIcon: Icon(Icons.edit_note, color: AppTheme.primary),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              const Text('Danh mục', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${categoryIcons[cat]} $cat'),
                      selected: selectedCategory == cat,
                      onSelected: (_) => setModal(() => selectedCategory = cat),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Độ ưu tiên', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: priorities.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    selected: selectedPriority == e.key,
                    onSelected: (_) => setModal(() => selectedPriority = e.key),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await context.read<TodoProvider>().addTodo(
                      titleCtrl.text.trim(), selectedCategory, selectedPriority,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Thêm công việc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Smart To-do List'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: '📁 Thư mục'), Tab(text: '🤖 Gợi ý AI')],
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildFolderTab(provider),
              _buildSuggestionsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFolderTab(TodoProvider provider) {
    // Group todos by date
    final Map<String, List<TodoModel>> grouped = {};

    // Always show today's folder
    final now = DateTime.now();
    final todayKey = 'Hôm nay · ${DateFormat('dd/MM/yyyy').format(now)}';
    grouped[todayKey] = [];

    for (final todo in provider.todos) {
      String dateKey = 'Không rõ ngày';
      try {
        final dt = DateTime.parse(todo.createdAt);
        final today = DateTime(now.year, now.month, now.day);
        final todoDate = DateTime(dt.year, dt.month, dt.day);
        if (todoDate == today) {
          dateKey = todayKey;
        } else if (todoDate == today.subtract(const Duration(days: 1))) {
          dateKey = 'Hôm qua · ${DateFormat('dd/MM/yyyy').format(dt)}';
        } else {
          dateKey = DateFormat('dd/MM/yyyy').format(dt);
        }
      } catch (_) {}
      grouped.putIfAbsent(dateKey, () => []).add(todo);
    }

    // Today always first, rest as-is
    final keys = grouped.keys.toList();
    if (keys.contains(todayKey) && keys.first != todayKey) {
      keys.remove(todayKey);
      keys.insert(0, todayKey);
    }

    return RefreshIndicator(
      onRefresh: provider.loadAll,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: keys.length,
        itemBuilder: (_, i) => _DateFolder(
          dateLabel: keys[i],
          todos: grouped[keys[i]]!,
          isToday: keys[i] == todayKey,
          provider: provider,
          onAddTask: () => _showAddDialog(forDate: keys[i]),
        ),
      ),
    );
  }

  Widget _buildSuggestionsTab(TodoProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsCard(stats: provider.stats),
        const SizedBox(height: 16),
        const Text('🤖 AI gợi ý dựa trên thói quen của bạn',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 12),
        if (provider.suggestions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Hãy hoàn thành thêm tasks để AI học thói quen của bạn!',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ),
          )
        else
          ...provider.suggestions.map((s) => _SuggestionCard(
                suggestion: s,
                onAdd: () => provider.addFromSuggestion(s.title),
              )),
      ],
    );
  }
}

// ── Folder Widget ─────────────────────────────────────────────────────────────

class _DateFolder extends StatefulWidget {
  final String dateLabel;
  final List<TodoModel> todos;
  final bool isToday;
  final TodoProvider provider;
  final VoidCallback onAddTask;

  const _DateFolder({
    required this.dateLabel,
    required this.todos,
    required this.isToday,
    required this.provider,
    required this.onAddTask,
  });

  @override
  State<_DateFolder> createState() => _DateFolderState();
}

class _DateFolderState extends State<_DateFolder> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.isToday; // Today opens by default
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.todos.where((t) => t.completed).length;
    final total = widget.todos.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isToday
              ? AppTheme.primary.withOpacity(0.6)
              : (_open ? AppTheme.primary.withOpacity(0.3) : Colors.white12),
          width: widget.isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Folder icon — click để thêm task
                GestureDetector(
                  onTap: widget.onAddTask,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: widget.isToday
                          ? AppTheme.primary.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.isToday ? AppTheme.primary : Colors.white24,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _open ? Icons.folder_open : Icons.folder,
                          color: widget.isToday ? AppTheme.primary : Colors.white54,
                          size: 24,
                        ),
                        Positioned(
                          right: 4, bottom: 4,
                          child: Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              color: widget.isToday ? AppTheme.primary : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Date label + count — click để mở/đóng
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _open = !_open),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dateLabel,
                          style: TextStyle(
                            color: widget.isToday ? Colors.white : Colors.white70,
                            fontWeight: widget.isToday ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total == 0
                              ? 'Chưa có task — nhấn 📁 để thêm'
                              : '$total công việc  •  $completed hoàn thành',
                          style: TextStyle(
                            color: total == 0 ? AppTheme.primary.withOpacity(0.7) : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow toggle
                GestureDetector(
                  onTap: () => setState(() => _open = !_open),
                  child: Icon(
                    _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // ── Tasks inside folder ──
          if (_open && widget.todos.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.primary.withOpacity(0.15)),
                ),
              ),
              child: Column(
                children: widget.todos
                    .map((todo) => _TodoCard(
                          todo: todo,
                          onComplete: () => widget.provider.completeTodo(todo.id),
                          onDelete: () => widget.provider.deleteTodo(todo.id),
                        ))
                    .toList(),
              ),
            ),

          if (_open && widget.todos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: AppTheme.primary.withOpacity(0.15),
                  ),
                  const SizedBox(height: 16),
                  const Text('📭', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  const Text('Chưa có task nào', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: widget.onAddTask,
                    child: const Text('Nhấn icon thư mục để thêm +',
                        style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Todo Card ─────────────────────────────────────────────────────────────────

class _TodoCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TodoCard({required this.todo, required this.onComplete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GestureDetector(
        onTap: onComplete,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary, width: 2),
          ),
          child: todo.completed
              ? const Icon(Icons.check, size: 14, color: AppTheme.primary)
              : null,
        ),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          color: todo.completed ? Colors.white38 : Colors.white,
          fontWeight: FontWeight.w500,
          decoration: todo.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: todo.priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: todo.priorityColor.withOpacity(0.5)),
            ),
            child: Text(todo.priorityLabel, style: TextStyle(color: todo.priorityColor, fontSize: 10)),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(todo.category, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}

// ── Suggestion Card ───────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final SuggestionModel suggestion;
  final VoidCallback onAdd;

  const _SuggestionCard({required this.suggestion, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.5)]),
          ),
          child: Center(
            child: Text('${suggestion.confidence}%',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        title: Text(suggestion.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(suggestion.reason, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 28),
          onPressed: onAdd,
        ),
      ),
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat('📋', '${stats['pending'] ?? 0}', 'Đang làm'),
            _Stat('✅', '${stats['completed'] ?? 0}', 'Hoàn thành'),
            _Stat('🧠', '${stats['historyCount'] ?? 0}', 'AI đã học'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _Stat(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );
}
