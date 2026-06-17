import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/petition_model.dart';

class InfoPetitions extends StatelessWidget {
  const InfoPetitions({
    super.key,
    required this.height,
    required this.petition,
  });

  final double height;
  final PetitionModel petition;

  String? _timeLabel(DateTime now) {
    final estimatedReadyAt = petition.estimatedReadyAt;
    if (estimatedReadyAt != null) {
      final remainingSeconds = estimatedReadyAt.difference(now).inSeconds;
      final remainingPreparation =
          remainingSeconds <= 0 ? 0 : ((remainingSeconds + 59) ~/ 60);

      if (remainingPreparation <= 0) {
        return '⏱ Pedido listo para recoger';
      }

      return '⏱ Ir a tienda en $remainingPreparation min';
    }

    final preparation = petition.preparationTimeMinutes;
    if (preparation == null || preparation <= 0) return null;

    return '⏱ Preparación: $preparation min';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        padding: const EdgeInsets.only(left: 10.0, top: 3.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 15.0),
            Text(petition.user.fullName),
            const SizedBox(height: 15.0),
            Text(
              petition.store.address,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12.0),
            ),
            const SizedBox(height: 6.0),
            StreamBuilder<int>(
              stream: Stream<int>.periodic(
                const Duration(minutes: 1),
                (value) => value,
              ),
              initialData: 0,
              builder: (context, _) {
                final timeLabel = _timeLabel(DateTime.now());
                if (timeLabel == null) return const SizedBox.shrink();

                return Text(
                  timeLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12.0,
                  ),
                );
              },
            ),
            Expanded(child: Container()),
            Row(
              children: [
                Expanded(child: Container()),
                Text(
                    '${(petition.total).toStringAsFixed(kCoinDecimals)} $kCoin',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 15.0),
              ],
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
