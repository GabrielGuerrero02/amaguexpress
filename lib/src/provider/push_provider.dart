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

  // IMPORTANT: Use a NEW channel id when changing sound (Android 8+ caches channel settings).
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
    importance: Importance.max,
    priority: Priority.high,
    autoCancel: true,
  );

  final StreamController<Map<String, dynamic>> _notificationsStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notifications => _notificationsStream.stream;

  getToken() async {
    await _firebaseMessaging.requestPermission(
        alert: true, sound: true, badge: true);
    _firebaseMessaging.getToken().then((tokenPush) {
      if (tokenPush != null) {
        debugPrint('[PUSH] FCM token: $tokenPush');
        prefs.tokenPush = tokenPush;
        if (prefs.isAuth) _authService.updateTokenPush(tokenPush);
      }
    }).catchError((error) {});
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

  init() async {
    await shouldShowRequestPermissionRationale();

    // iOS: ensure permissions + foreground presentation are configured before listeners.
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

    // Keep token updated (iOS tokens can rotate).
    _firebaseMessaging.onTokenRefresh.listen((tokenPush) {
      prefs.tokenPush = tokenPush;
      if (prefs.isAuth) _authService.updateTokenPush(tokenPush);
    });

    FirebaseMessaging.onMessage.listen(_onMessageHandler);
    FirebaseMessaging.onBackgroundMessage(_messageHandler);

    await initializeLocalNotifications();

    getToken();
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

    // 1) Prefer explicit title/body in data (current behavior)
    if (message.data.containsKey('title') && message.data.containsKey('body')) {
      title = message.data['title'];
      body = message.data['body'];
    }

    // 2) If not present, try the FCM notification payload (common on iOS)
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
