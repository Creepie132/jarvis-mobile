import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/inbox_screen.dart';

// Обработчик фоновых пушей (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Пуш пришёл когда приложение закрыто — просто принимаем
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase
  await Firebase.initializeApp();

  // Регистрируем фоновый обработчик
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Запрашиваем разрешение на уведомления
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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
      title: 'Лея',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080810),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const HomeScreen(),
        '/chat': (ctx) => const ChatScreen(),
        '/inbox': (ctx) => const InboxScreen(),
      },
    );
  }
}
