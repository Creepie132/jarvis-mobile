import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://jarvis-api-production-ff7a.up.railway.app';

class AgentStatus {
  final bool born;
  final String? name;
  final String? emotion;
  final int memoryCount;
  final DateTime? bornAt;

  AgentStatus({required this.born, this.name, this.emotion, required this.memoryCount, this.bornAt});

  factory AgentStatus.fromJson(Map<String, dynamic> j) => AgentStatus(
        born: j['born'] ?? false,
        name: j['identity']?['name'],
        emotion: j['mood']?['current_emotion'],
        memoryCount: j['memory_count'] ?? 0,
        bornAt: j['identity']?['born_at'] != null
            ? DateTime.tryParse(j['identity']['born_at'])
            : null,
      );
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime time;
  ChatMessage({required this.role, required this.content, DateTime? time})
      : time = time ?? DateTime.now();
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class OutboxMessage {
  final String id;
  final String message;
  final String reason;
  final DateTime createdAt;
  OutboxMessage({required this.id, required this.message, required this.reason, required this.createdAt});
  factory OutboxMessage.fromJson(Map<String, dynamic> j) => OutboxMessage(
        id: j['id'] as String,
        message: j['message'] as String,
        reason: j['reason'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class InboxItem {
  final String id;
  final InboxItemType type;
  final String label;
  final String text;
  final double priority;
  InboxItem({required this.id, required this.type, required this.label, required this.text, required this.priority});
}

enum InboxItemType { pendingTopic, unknownEntity, desire }

class InboxData {
  final List<InboxItem> items;
  InboxData(this.items);

  static InboxData fromJson(Map<String, dynamic> j) {
    final items = <InboxItem>[];
    for (final t in (j['pending_topics'] as List? ?? [])) {
      items.add(InboxItem(id: t['id'], type: InboxItemType.pendingTopic,
          label: 'ХОЧЕТ ВЕРНУТЬСЯ', text: t['topic'] ?? '',
          priority: (t['importance'] ?? 0.5).toDouble()));
    }
    for (final e in (j['unknown_entities'] as List? ?? [])) {
      final name = e['entity_name'] ?? '';
      final ctx = e['context'] ?? '';
      items.add(InboxItem(id: e['id'], type: InboxItemType.unknownEntity,
          label: 'ХОЧЕТ СПРОСИТЬ',
          text: 'Кто такой $name? (${ctx.length > 60 ? ctx.substring(0, 60) + '...' : ctx})',
          priority: (e['priority'] ?? 0.5).toDouble()));
    }
    for (final d in (j['desires'] as List? ?? [])) {
      items.add(InboxItem(id: d['id'], type: InboxItemType.desire,
          label: 'ЖЕЛАНИЕ', text: d['description'] ?? '',
          priority: (d['intensity'] ?? 0.5).toDouble()));
    }
    items.sort((a, b) => b.priority.compareTo(a.priority));
    return InboxData(items);
  }
}

class JarvisService {
  static Future<AgentStatus> getStatus() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/status'))
        .timeout(const Duration(seconds: 10));
    return AgentStatus.fromJson(jsonDecode(res.body));
  }

  static Future<String> sendMessage(String message, List<ChatMessage> history) async {
    final res = await http.post(Uri.parse('$_baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message, 'history': history.map((m) => m.toJson()).toList()}))
        .timeout(const Duration(seconds: 30));
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
    return data['reply'] as String;
  }

  static Future<InboxData> getInbox() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/inbox'))
        .timeout(const Duration(seconds: 10));
    return InboxData.fromJson(jsonDecode(res.body));
  }

  static Future<void> resolveInboxItem(InboxItemType type, String id) async {
    final typeStr = switch (type) {
      InboxItemType.pendingTopic  => 'pending_topic',
      InboxItemType.unknownEntity => 'unknown_entity',
      InboxItemType.desire        => 'desire',
    };
    await http.post(Uri.parse('$_baseUrl/api/inbox/resolve'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'type': typeStr, 'id': id}))
        .timeout(const Duration(seconds: 10));
  }

  static Future<List<OutboxMessage>> getOutbox() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/outbox'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    final list = data['messages'] as List? ?? [];
    return list.map((m) => OutboxMessage.fromJson(m as Map<String, dynamic>)).toList();
  }

  static Future<void> markOutboxRead(String id) async {
    await http.post(Uri.parse('$_baseUrl/api/outbox/read'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': id}))
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> saveFcmToken(String token) async {
    try {
      await http.post(Uri.parse('$_baseUrl/api/fcm-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
