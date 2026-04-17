import 'package:flutter/material.dart';
import '../services/jarvis_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AgentStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final s = await JarvisService.getStatus();
      setState(() { _status = s; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
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
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildCenter()),
        _buildBottomCards(),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _timeNow(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF3a3a5a)),
          ),
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D9E75),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('онлайн',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3a3a5a))),
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
        // Аватар с кольцами
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.08), width: 1),
              ),
            ),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.15), width: 1),
              ),
            ),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7F77DD).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.3), width: 1),
              ),
              child: const Center(
                child: Text('Л',
                  style: TextStyle(fontSize: 32, color: Color(0xFFAFA9EC),
                    fontStyle: FontStyle.italic)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _status?.name ?? 'Лея',
          style: const TextStyle(fontSize: 22, color: Color(0xFFe0e0f0), fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 6),
        Text(
          _status?.emotion ?? 'здесь',
          style: const TextStyle(fontSize: 13, color: Color(0xFF7F77DD)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomCards() {
    final mem = _status?.memoryCount ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Карточка "хочет поговорить"
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ХОЧЕТ ПОГОВОРИТЬ',
                  style: TextStyle(fontSize: 10, color: Color(0xFF3a3a5a),
                    letterSpacing: 1.0)),
                const SizedBox(height: 6),
                const Text('Напиши мне — я здесь',
                  style: TextStyle(fontSize: 14, color: Color(0xFFAFA9EC), height: 1.5)),
              ],
            ),
          ),
          // Три счётчика
          Row(
            children: [
              _statCard('ПАМЯТЬ', '$mem'),
              const SizedBox(width: 8),
              _statCard('ВОПРОСОВ', '—'),
              const SizedBox(width: 8),
              _statCard('ДНЕЙ', '1'),
            ],
          ),
        ],
      ),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF3a3a5a), letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, color: Color(0xFF7F77DD), fontWeight: FontWeight.w300)),
          ],
        ),
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
              // Входящие
              _iconBtn(
                size: 52,
                icon: Icons.chat_bubble_outline_rounded,
                iconSize: 20,
                onTap: () => Navigator.pushNamed(context, '/inbox'),
              ),
              const SizedBox(width: 20),
              // Главная кнопка — голос/чат
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/chat'),
                onLongPress: () {
                  // TODO: голосовой режим
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Голосовой режим — скоро')));
                },
                child: Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7F77DD).withValues(alpha: 0.25),
                    border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.5), width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.15), width: 1),
                        ),
                      ),
                      const Icon(Icons.mic_rounded, color: Color(0xFFAFA9EC), size: 26),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Чат текстом
              _iconBtn(
                size: 52,
                icon: Icons.edit_outlined,
                iconSize: 20,
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'удержи для разговора · нажми для текста',
            style: TextStyle(fontSize: 11, color: Color(0xFF2a2a4a)),
          ),
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

