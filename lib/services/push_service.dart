import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'jarvis_service.dart';

/// Управляет FCM токеном и входящими пушами от Леи.
class PushService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init(BuildContext context) async {
    // Получаем FCM токен и отправляем на сервер
    final token = await _fcm.getToken();
    if (token != null) {
      await JarvisService.saveFcmToken(token);
    }

    // Токен обновился — сохраняем новый
    _fcm.onTokenRefresh.listen((newToken) {
      JarvisService.saveFcmToken(newToken);
    });

    // Пуш пришёл когда приложение ОТКРЫТО — показываем баннер
    FirebaseMessaging.onMessage.listen((message) {
      final body = message.notification?.body ?? message.data['message'] ?? '';
      if (body.isEmpty) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            content: _LeaBanner(message: body),
          ),
        );
      }
    });

    // Тап по пушу когда приложение свёрнуто → открываем чат
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/chat', (r) => r.isFirst);
      }
    });
  }
}

class _LeaBanner extends StatelessWidget {
  final String message;
  const _LeaBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                child: Text('Л', style: TextStyle(
                    color: Color(0xFFAFA9EC), fontSize: 16, fontStyle: FontStyle.italic)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Лея написала',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7F77DD), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(message,
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
    );
  }
}
