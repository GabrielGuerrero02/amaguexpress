import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/status_label.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/services/auth_service.dart';
import 'dart:io';

class PushProvider {
  static PushProvider? _instance;

  PushProvider._internal();

  factory PushProvider() {
    _instance ??= PushProvider._internal();
    return _instance!;
  }

  final prefs = PreferencesProvider();
  final AuthService _authService = AuthService();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // IMPORTANT: Android 8+ caches channel settings; use a NEW id when changing sound.
  static const String _androidOrdersChannelId =
      '${kNameApp}_CHANNEL_AMAGUEXPRESS_V2';

  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      const AndroidNotificationDetails(
    _androidOrdersChannelId,
    '$kNameApp NOTIFICATIONS AMAGUEXPRESS',
    channelDescription: '$kNameApp order notifications (custom sound)',
    groupKey: '$kNameApp-NOTIFICATIONS-AMAGUEXPRESS',
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification1'),
    autoCancel: true,
    importance: Importance.max,
    priority: Priority.high,
  );

  final StreamController<Map<String, dynamic>> _notificationsStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notifications => _notificationsStream.stream;

  Future<void> getToken() async {
    // Request permissions (iOS prompts only once; Android may no-op depending on SDK).
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS: ensure notifications are presented while app is in foreground.
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      debugPrint('[PUSH] APNs token: ${apnsToken ?? "<null>"}');

      final tokenPush = await _firebaseMessaging.getToken();
      debugPrint('[PUSH] FCM token: ${tokenPush ?? "<null>"}');

      if (tokenPush != null) {
        prefs.tokenPush = tokenPush;
        if (prefs.isAuth) {
          await _authService.updateTokenPush(tokenPush);
        }
      }

      // Keep backend updated if FCM token rotates.
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[PUSH] FCM token refreshed: $newToken');
        prefs.tokenPush = newToken;
        if (prefs.isAuth) {
          await _authService.updateTokenPush(newToken);
        }
      });
    } catch (e) {
      debugPrint('[PUSH] Error getting tokens: $e');
    }
  }

  Future showNotification(RemoteNotification push) async {
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'notification1.caf',
      ),
    );
    _localNotifications.show(
        1682, push.title, push.body, platformChannelSpecifics);
  }

  cancelAll() {
    _localNotifications.cancelAll();
  }

  Future<void> init() async {
    await shouldShowRequestPermissionRationale();

    // Configure permissions/presentation early (especially for iOS).
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_onMessageHandler);

    // When user taps a notification and the app opens/resumes
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _onMessageHandler(message);
    });

    // If the app was terminated and opened via a notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _onMessageHandler(initialMessage);
    }

    FirebaseMessaging.onBackgroundMessage(_messageHandler);

    await initializeLocalNotifications();

    await getToken();
  }

  // Inicializa notificaciones locales y crea el canal en Android
  Future<void> initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Asegurar el canal en Android para FCM/Local notifications
    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final channel = AndroidNotificationChannel(
        _androidOrdersChannelId,
        '$kNameApp NOTIFICATIONS AMAGUEXPRESS',
        description: '$kNameApp order notifications (custom sound)',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification1'),
      );
      await androidImpl.createNotificationChannel(channel);
    }

    // Solicitar permisos explícitos en iOS para notificaciones locales
    final darwinImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await darwinImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  shouldShowRequestPermissionRationale() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } else if (Platform.isIOS) {
      final darwinImpl =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await darwinImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future _onMessageHandler(RemoteMessage message) async {
    // iOS can deliver `notification` payloads without `data`.
    if (message.data.isNotEmpty) {
      _notificationsStream.add(message.data);
    } else if (message.notification != null) {
      _notificationsStream.add({
        'title': message.notification?.title,
        'body': message.notification?.body,
      });
    }

    checkMessage(message);
  }

  checkMessage(RemoteMessage message) {
    String? title, body;

    // 1) Prefer explicit title/body in data
    if (message.data.containsKey('title') && message.data.containsKey('body')) {
      title = message.data['title'];
      body = message.data['body'];
    }

    // 2) Fall back to the FCM notification payload (common on iOS)
    if ((title == null || body == null) && message.notification != null) {
      title ??= message.notification?.title;
      body ??= message.notification?.body;
    }

    // 3) Preserve special-case logic for status change notifications
    if ((title == null || body == null) &&
        message.data['type'] == TypesNotification.changeOrderStatust) {
      title = kNameApp;
      body = statusOrderLabel(
        int.parse(message.data['status']),
        int.parse(message.data['companyType']),
      );
    }

    if (title == null || body == null) return;

    PushProvider()
        .showNotification(RemoteNotification(title: title, body: body));
  }

  dispose() {
    _notificationsStream.close();
  }
}

@pragma('vm:entry-point')
Future<void> _messageHandler(RemoteMessage message) async {
  // Asegura bindings en el isolate de background
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PreferencesProvider().init();
  await S.load(Locale(PreferencesProvider().locale));
  // Inicializar notificaciones locales en el isolate de background antes de mostrar
  await PushProvider().initializeLocalNotifications();
  PushProvider().checkMessage(message);
}
