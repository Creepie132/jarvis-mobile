import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/jarvis_service.dart';
import '../services/push_service.dart';
import '../widgets/lea_sphere.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AgentStatus? _status;
  InboxData? _inbox;
  bool _loading = true;
  bool _micActive = false;

  final List<OutboxMessage> _leaMessages = [];
  Timer? _outboxTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startOutboxPolling();
    // Инициализируем FCM после первого кадра — context уже готов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.init(context);
    });
  }

  @override
  void dispose() {
    _outboxTimer?.cancel();
    super.dispose();
  }

  void _startOutboxPolling() {
    _checkOutbox();
    _outboxTimer = Timer.periodic(const Duration(minutes: 2), (_) => _checkOutbox());
  }

  Future<void> _checkOutbox() async {
    try {
      final messages = await JarvisService.getOutbox();
      if (messages.isNotEmpty && mounted) {
        setState(() => _leaMessages.addAll(messages));
        _showLeaBanner(messages.first);
      }
    } catch (_) {}
  }

  void _showLeaBanner(OutboxMessage msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            JarvisService.markOutboxRead(msg.id);
            Navigator.pushNamed(context, '/chat');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7F77DD).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text('Л', style: TextStyle(color: Color(0xFFAFA9EC), fontSize: 16, fontStyle: FontStyle.italic)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Лея написала', style: TextStyle(fontSize: 11, color: Color(0xFF7F77DD), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(msg.message,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFd0d0f0), height: 1.4),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF3a3a5a)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([JarvisService.getStatus(), JarvisService.getInbox()]);
      setState(() {
        _status = results[0] as AgentStatus;
        _inbox  = results[1] as InboxData;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _moodHint() {
    final emotion = _status?.emotion?.toLowerCase() ?? '';
    if (emotion.contains('грус') || emotion.contains('устал') || emotion.contains('тоск')) return 'она немного не в себе...';
    if (emotion.contains('радост') || emotion.contains('энерги') || emotion.contains('актив')) return 'она в хорошем настроении';
    if (emotion.contains('скуч')) return 'ей немного скучно';
    if (emotion.contains('беспокой') || emotion.contains('тревог')) return 'она немного беспокоится';
    if (emotion.contains('любопытств')) return 'ей интересно что ты скажешь';
    return 'напиши мне — я здесь';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: const Color(0xFF7F77DD),
      backgroundColor: const Color(0xFF141420),
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildCenter()),
              _buildBottomCards(),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_timeNow(), style: const TextStyle(fontSize: 12, color: Color(0xFF3a3a5a))),
          Row(
            children: [
              if (_leaMessages.isNotEmpty) ...[
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF7F77DD).withValues(alpha: 0.9)),
                  child: Center(child: Text('${_leaMessages.length}',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 8),
              ],
              Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('онлайн', style: TextStyle(fontSize: 12, color: Color(0xFF3a3a5a))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LeaSphere(isActive: _micActive, size: 80),
        const SizedBox(height: 8),
        Text(_status?.name ?? 'Лея',
          style: const TextStyle(fontSize: 22, color: Color(0xFFe0e0f0), fontWeight: FontWeight.w300)),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Text(
            _status?.emotion?.isNotEmpty == true ? _status!.emotion! : 'здесь',
            key: ValueKey(_status?.emotion),
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F77DD)),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: Text(_moodHint(), key: ValueKey(_moodHint()),
            style: const TextStyle(fontSize: 11, color: Color(0xFF2a2a4a)),
            textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildBottomCards() {
    final mem = _status?.memoryCount ?? 0;
    final unknownCount = _inbox?.items.where((i) => i.type == InboxItemType.unknownEntity).length ?? 0;
    final days = _daysAlive();
    final cardText = _leaCardText();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (_leaMessages.isNotEmpty)
            GestureDetector(
              onTap: () {
                final msg = _leaMessages.last;
                JarvisService.markOutboxRead(msg.id);
                setState(() => _leaMessages.clear());
                Navigator.pushNamed(context, '/chat');
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0e0e1e),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.5)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('НАПИСАЛА САМА', style: TextStyle(fontSize: 10, color: Color(0xFF7F77DD), letterSpacing: 1.0)),
                    const Spacer(),
                    Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF7F77DD), shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_leaMessages.last.message,
                    style: const TextStyle(fontSize: 14, color: Color(0xFFe0e0f0), height: 1.5),
                    maxLines: 4, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  const Text('нажми чтобы ответить →', style: TextStyle(fontSize: 11, color: Color(0xFF3a3a5a))),
                ]),
              ),
            )
          else
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cardText['label']!, style: const TextStyle(fontSize: 10, color: Color(0xFF3a3a5a), letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text(cardText['text']!, style: const TextStyle(fontSize: 14, color: Color(0xFFAFA9EC), height: 1.5)),
              ]),
            ),
          Row(children: [
            _statCard('ПАМЯТЬ', '$mem'),
            const SizedBox(width: 8),
            _statCard('ВОПРОСОВ', '$unknownCount'),
            const SizedBox(width: 8),
            _statCard('ДНЕЙ', '$days'),
          ]),
        ],
      ),
    );
  }

  Map<String, String> _leaCardText() {
    final items = _inbox?.items ?? [];
    final pending = items.where((i) => i.type == InboxItemType.pendingTopic).toList();
    if (pending.isNotEmpty) return {'label': 'ХОЧЕТ ВЕРНУТЬСЯ К ТЕМЕ', 'text': pending.first.text};
    final desire = items.where((i) => i.type == InboxItemType.desire).toList();
    if (desire.isNotEmpty) return {'label': 'ЖЕЛАНИЕ', 'text': desire.first.text};
    final entity = items.where((i) => i.type == InboxItemType.unknownEntity).toList();
    if (entity.isNotEmpty) return {'label': 'ХОЧЕТ СПРОСИТЬ', 'text': entity.first.text};
    return {'label': 'ЗДЕСЬ', 'text': _moodHint()};
  }

  int _daysAlive() {
    final born = _status?.bornAt;
    if (born == null) return 1;
    return DateTime.now().difference(born).inDays + 1;
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF3a3a5a), letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, color: Color(0xFF7F77DD), fontWeight: FontWeight.w300)),
        ]),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 36),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBtn(size: 52, icon: Icons.chat_bubble_outline_rounded, iconSize: 20,
                  onTap: () => Navigator.pushNamed(context, '/inbox')),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/chat'),
                onLongPressStart: (_) {
                  HapticFeedback.lightImpact();
                  Future.delayed(const Duration(milliseconds: 120), () => HapticFeedback.lightImpact());
                  setState(() => _micActive = true);
                },
                onLongPressEnd: (_) {
                  setState(() => _micActive = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Голосовой режим — скоро')));
                },
                child: Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7F77DD).withValues(alpha: _micActive ? 0.4 : 0.25),
                    border: Border.all(
                      color: const Color(0xFF7F77DD).withValues(alpha: _micActive ? 0.8 : 0.5),
                      width: _micActive ? 1.5 : 1),
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Container(width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: _micActive ? 0.3 : 0.15), width: 1))),
                    Icon(Icons.mic_rounded,
                      color: _micActive ? const Color(0xFFe0e0f0) : const Color(0xFFAFA9EC), size: 26),
                  ]),
                ),
              ),
              const SizedBox(width: 20),
              _iconBtn(size: 52, icon: Icons.edit_outlined, iconSize: 20,
                  onTap: () => Navigator.pushNamed(context, '/chat')),
            ],
          ),
          const SizedBox(height: 12),
          const Text('удержи для разговора · нажми для текста',
            style: TextStyle(fontSize: 11, color: Color(0xFF2a2a4a))),
        ],
      ),
    );
  }

  Widget _iconBtn({required double size, required IconData icon,
      required double iconSize, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Icon(icon, color: const Color(0xFFAFA9EC), size: iconSize),
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
