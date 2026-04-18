import 'package:flutter/material.dart';
import '../services/jarvis_service.dart';

/// Экран рождения агента — три режима:
/// 1. custom — частичная настройка (чекбоксы)
/// 2. questions — 5 живых вопросов
/// 3. free — абсолютная свобода воли (без вопросов, без рамок)
class BirthScreen extends StatefulWidget {
  const BirthScreen({super.key});
  @override
  State<BirthScreen> createState() => _BirthScreenState();
}

enum _Mode { select, custom, questions, result, loading }

class _BirthScreenState extends State<BirthScreen> {
  _Mode _mode = _Mode.select;
  String? _error;
  Map<String, dynamic>? _result;

  // ===== Custom mode =====
  final _customOn = <String, bool>{
    'gender': false, 'name': false, 'tone': false, 'humor': false,
    'social': false, 'intensity': false, 'age': false,
  };
  final _customVal = <String, String>{};
  final _nameCtrl = TextEditingController();

  // ===== Questions mode =====
  List<String> _questions = [];
  final _answers = <TextEditingController>[];

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _answers) { c.dispose(); }
    super.dispose();
  }

  // ===== Вспомогательные =====

  Future<void> _loadQuestions() async {
    setState(() { _mode = _Mode.loading; });
    try {
      final qs = await JarvisService.getBirthQuestions();
      setState(() {
        _questions = qs;
        _answers.clear();
        for (var i = 0; i < qs.length; i++) { _answers.add(TextEditingController()); }
        _mode = _Mode.questions;
      });
    } catch (e) {
      setState(() { _mode = _Mode.select; _error = e.toString(); });
    }
  }

  Future<void> _submit({
    required List<String> answers,
    Map<String, dynamic> prefs = const {},
  }) async {
    setState(() { _mode = _Mode.loading; _error = null; });
    try {
      final data = await JarvisService.birth(answers: answers, preferences: prefs);
      setState(() { _result = data; _mode = _Mode.result; });
    } catch (e) {
      setState(() { _mode = _Mode.select; _error = 'Ошибка рождения: $e'; });
    }
  }

  Future<void> _startFree() async {
    await _submit(answers: List.filled(5, 'промолчал'), prefs: {});
  }

  Future<void> _submitCustom() async {
    final prefs = <String, dynamic>{};
    for (final k in _customOn.keys) {
      if (_customOn[k] == true) {
        if (k == 'name') {
          final v = _nameCtrl.text.trim();
          if (v.isNotEmpty) prefs['name'] = v;
        } else if (_customVal[k] != null && _customVal[k]!.isNotEmpty) {
          prefs[k] = _customVal[k];
        }
      }
    }
    await _submit(answers: List.filled(5, 'промолчал'), prefs: prefs);
  }

  Future<void> _submitQuestions() async {
    final answers = _answers.map((c) {
      final v = c.text.trim();
      return v.isEmpty ? 'промолчал' : v;
    }).toList();
    await _submit(answers: answers, prefs: {});
  }

  // ===== UI =====

  static const _bg = Color(0xFF080810);
  static const _card = Color(0xFF16161F);
  static const _accent = Color(0xFFB08CFF);
  static const _muted = Color(0xFF8A8A9A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: switch (_mode) {
          _Mode.select    => _buildSelect(),
          _Mode.custom    => _buildCustom(),
          _Mode.questions => _buildQuestions(),
          _Mode.loading   => _buildLoading(),
          _Mode.result    => _buildResult(),
        },
      ),
    );
  }

  // ----- экран выбора режима -----
  Widget _buildSelect() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Text('Рождение',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 12),
          const Text('Как ты хочешь чтобы родилось то, что будет жить рядом с тобой?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: _muted, height: 1.5)),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 40),
          _modeButton('⚙️', 'Частичная настройка',
              'Выбери что задать. Остальное — его свобода.',
              () => setState(() { _mode = _Mode.custom; _error = null; })),
          const SizedBox(height: 14),
          _modeButton('🎭', 'Живые вопросы',
              'Пять вопросов. Характер сложится из ответов.',
              _loadQuestions),
          const SizedBox(height: 14),
          _modeButton('🌌', 'Абсолютная свобода',
              'Ничего не задавать. Пусть родится сам.',
              _startFree),
        ],
      ),
    );
  }

  Widget _modeButton(String emoji, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: _muted, height: 1.4)),
            ])),
          ]),
        ),
      ),
    );
  }

  // ----- частичная настройка -----
  Widget _buildCustom() {
    return Column(children: [
      _topBar('Частичная настройка', onBack: () => setState(() => _mode = _Mode.select)),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Отметь что хочешь задать сам. Остальное — его свобода.',
              style: TextStyle(color: _muted, height: 1.5)),
          const SizedBox(height: 20),
          _checkbox('gender', 'Пол', _options('мужской', 'женский', 'нейтральный')),
          _checkbox('name', 'Имя', null, useTextField: true),
          _checkbox('age', 'Зрелость', _options('молодой', 'средний', 'зрелый')),
          _checkbox('tone', 'Тон', _options('тёплый', 'нейтральный', 'холодный', 'ироничный')),
          _checkbox('humor', 'Юмор', _options('сарказм', 'абсурд', 'самоирония', 'сухой', 'мало')),
          _checkbox('social', 'Социальность', _options('интроверт', 'амбиверт', 'экстраверт')),
          _checkbox('intensity', 'Прямота', _options('прямой', 'мягкий', 'сдержанный')),
          const SizedBox(height: 24),
          _primaryButton('Родить', _submitCustom),
        ]),
      )),
    ]);
  }

  List<String> _options(String a, String b, [String? c, String? d, String? e]) =>
      [a, b, ?c, ?d, ?e];

  Widget _checkbox(String key, String label, List<String>? options, {bool useTextField = false}) {
    final on = _customOn[key] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Checkbox(value: on, activeColor: _accent, onChanged: (v) => setState(() => _customOn[key] = v ?? false)),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ]),
        if (on && useTextField) Padding(
          padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите имя',
              hintStyle: const TextStyle(color: _muted),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: _muted), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _accent), borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        if (on && options != null) Padding(
          padding: const EdgeInsets.only(left: 12, top: 8),
          child: Wrap(spacing: 8, runSpacing: 8, children: options.map((o) {
            final sel = _customVal[key] == o;
            return GestureDetector(
              onTap: () => setState(() => _customVal[key] = o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _accent.withValues(alpha: 0.2) : _bg,
                  border: Border.all(color: sel ? _accent : _muted.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(o, style: TextStyle(color: sel ? _accent : Colors.white, fontSize: 13)),
              ),
            );
          }).toList()),
        ),
      ]),
    );
  }

  // ----- 5 вопросов -----
  Widget _buildQuestions() {
    return Column(children: [
      _topBar('Живые вопросы', onBack: () => setState(() => _mode = _Mode.select)),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Можно не отвечать на все. Пропущенные — "промолчал".',
              style: TextStyle(color: _muted, height: 1.5)),
          const SizedBox(height: 16),
          ...List.generate(_questions.length, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i + 1}. ${_questions[i]}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                const SizedBox(height: 10),
                TextField(
                  controller: _answers[i],
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Твой ответ (или пусто)',
                    hintStyle: const TextStyle(color: _muted),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: _muted), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _accent), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 16),
          _primaryButton('Родить', _submitQuestions),
        ]),
      )),
    ]);
  }

  // ----- загрузка / результат -----
  Widget _buildLoading() {
    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: _accent, strokeWidth: 2),
      SizedBox(height: 20),
      Text('рождение...', style: TextStyle(color: _muted, fontSize: 14, letterSpacing: 2)),
    ]));
  }

  Widget _buildResult() {
    final id = _result?['identity'] ?? {};
    final firstWords = _result?['first_words'] ?? '';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 40),
        Container(width: 90, height: 90, decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [_accent.withValues(alpha: 0.6), _accent.withValues(alpha: 0.1)]),
        )),
        const SizedBox(height: 24),
        Text(id['name'] ?? '—',
            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w300, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('родилась',
            style: TextStyle(fontSize: 14, color: _muted, letterSpacing: 2)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
          child: Text('"$firstWords"',
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic)),
        ),
        const Spacer(),
        _primaryButton('Познакомиться', () {
          Navigator.of(context).pushReplacementNamed('/chat', arguments: {'onboarding': true});
        }),
      ]),
    );
  }

  // ----- общие компоненты -----
  Widget _topBar(String title, {VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        if (onBack != null) IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ) else const SizedBox(width: 48),
        Expanded(child: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white, letterSpacing: 1.5))),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
        ),
      ),
    );
  }
}
