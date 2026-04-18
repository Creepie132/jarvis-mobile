import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/birth_screen.dart';
import 'services/jarvis_service.dart';

// Обработчик фоновых пушей (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080810),
      ),
      home: const _Bootstrap(),
      routes: {
        '/home'  : (ctx) => const HomeScreen(),
        '/chat'  : (ctx) => const ChatScreen(),
        '/inbox' : (ctx) => const InboxScreen(),
        '/birth' : (ctx) => const BirthScreen(),
      },
    );
  }
}

/// Стартовый экран: определяет куда пойти.
/// Нет identity → BirthScreen
/// Есть identity, onboarding_done=false → ChatScreen с флагом онбординга
/// Есть identity, onboarding_done=true → HomeScreen
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    try {
      final status = await JarvisService.getStatus();
      if (!mounted) return;
      if (!status.born) {
        Navigator.of(context).pushReplacementNamed('/birth');
      } else if (!status.onboardingDone) {
        Navigator.of(context).pushReplacementNamed('/chat', arguments: {'onboarding': true});
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (_) {
      // Если API недоступен — идём в Home, он покажет свою ошибку
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080810),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFB08CFF), strokeWidth: 2),
      ),
    );
  }
}
