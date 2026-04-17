import 'package:flutter/material.dart';
import '../services/jarvis_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  InboxData? _inbox;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await JarvisService.getInbox();
      setState(() { _inbox = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _dismiss(InboxItem item) async {
    try {
      await JarvisService.resolveInboxItem(item.type, item.id);
      setState(() => _inbox!.items.remove(item));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080810),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFAFA9EC), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('От Леи',
          style: TextStyle(fontSize: 16, color: Color(0xFFe0e0f0), fontWeight: FontWeight.w300)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3a3a5a), size: 20),
            onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)));
    }
    if (_error != null) {
      return Center(child: Text('Не удалось загрузить',
        style: const TextStyle(color: Color(0xFF3a3a5a), fontSize: 14)));
    }
    final items = _inbox?.items ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('Пока ничего', style: TextStyle(color: Color(0xFF2a2a4a), fontSize: 14)),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF7F77DD),
      backgroundColor: const Color(0xFF141420),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _InboxCard(item: items[i], onDismiss: () => _dismiss(items[i])),
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  final InboxItem item;
  final VoidCallback onDismiss;
  const _InboxCard({required this.item, required this.onDismiss});

  Color get _accentColor => switch (item.type) {
    InboxItemType.pendingTopic  => const Color(0xFF7F77DD),
    InboxItemType.unknownEntity => const Color(0xFF1D9E75),
    InboxItemType.desire        => const Color(0xFFEF9F27),
  };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check_rounded, color: Color(0xFF3a3a5a), size: 22),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.label,
              style: TextStyle(fontSize: 10, color: _accentColor.withValues(alpha: 0.7),
                letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text(item.text,
              style: const TextStyle(fontSize: 14, color: Color(0xFFd0d0f0), height: 1.5)),
          ],
        ),
      ),
    );
  }
}
