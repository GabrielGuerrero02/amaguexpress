import 'package:flutter/material.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/notification_model.dart';
import 'package:amaguexpress/src/screens/notification/widget/list_notifications.dart';
import 'package:amaguexpress/constants/constants.dart';

class NotificacionPage extends StatefulWidget {
  const NotificacionPage({super.key});

  @override
  createState() => _NotificacionPageState();
}

class _NotificacionPageState extends State<NotificacionPage> {
  final List<NotificationModel> notifications = [];

  @override
  void initState() {
    notifications.add(NotificationModel(
      detail: 'BIENVENIDO A AMAGUEXPRESS',
      hint:
          'Si es tu primera vez aquí y aún no ves las tiendas, solo debes colcar tu ubicación en la parte superior',
      image:
          'https://firebasestorage.googleapis.com/v0/b/amaguexpress-63da5.appspot.com/o/Varios%2Fmapa.png?alt=media',
      url: '',
    ));

    notifications.add(NotificationModel(
      detail: 'CONOCE MÁS DE AMAGUEXPRESS',
      hint: 'Una App comunitaria | https://www.amaguexpress.com',
      image:
          'https://firebasestorage.googleapis.com/v0/b/amaguexpress-63da5.appspot.com/o/Varios%2Famaguexpress.png?alt=media',
      url: 'https://www.amaguexpress.com',
    ));

    notifications.add(NotificationModel(
      detail: 'CONOCE NUESTRA POLÍTICA DE PRIVACIDAD',
      hint: 'https://www.amaguexpress.com',
      image:
          'https://firebasestorage.googleapis.com/v0/b/amaguexpress-63da5.appspot.com/o/Varios%2Fpoliticaprivacidad.png?alt=media',
      url: 'https://www.amaguexpress.com',
    ));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor,
          centerTitle: true,
          title: Text(S.of(context).tNotifications)),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10.0),
            Expanded(child: ListNotifications(notifications)),
          ],
        ),
      ),
    );
  }
}
