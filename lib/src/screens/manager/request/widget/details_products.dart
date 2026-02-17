import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/request_model.dart';

class DetailsProducts extends StatelessWidget {
  const DetailsProducts({
    super.key,
    required this.request,
  });

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DataTable(
      sortColumnIndex: 2,
      sortAscending: false,
      columnSpacing: 0,
      horizontalMargin: 20,
      headingRowColor: MaterialStatePropertyAll(
        isDark ? cs.surfaceContainerHighest : cs.surface,
      ),
      dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.selected)) {
          return kPrimaryColor.withOpacity(isDark ? 0.12 : 0.10);
        }
        return isDark ? cs.surface : null;
      }),
      dividerThickness: 0.6,
      headingTextStyle: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      dataTextStyle: TextStyle(
        color: cs.onSurface,
      ),
      columns: [
        DataColumn(label: Text(S.of(context).lNumber)),
        DataColumn(label: Text(S.of(context).lProduct)),
        DataColumn(label: Text(S.of(context).lTotal), numeric: true),
      ],
      rows: _dataRows(context),
    );
  }

  List<DataRow> _dataRows(BuildContext context) {
    List<DataRow> rows = [];
    String nota;
    for (var pr in request.products) {
      nota = pr.note.isEmpty ? '' : ' (${pr.note})';
      rows.add(_dataRowElement(context,
          c1: '${pr.number}',
          c2: '${pr.name} $nota',
          c3: pr.total.toStringAsFixed(kCoinDecimals)));
    }

    rows.add(_dataRowElement(context,
        c1: S.of(context).lDeliveryFee,
        c3: request.deliveryFee.toStringAsFixed(kCoinDecimals)));

    rows.add(_dataRowElement(context,
        selected: true,
        c1: S.of(context).lTotal,
        c3: request.total.toStringAsFixed(kCoinDecimals)));
    return rows;
  }

  DataRow _dataRowElement(BuildContext context,
      {String c1 = '', String c2 = '', String c3 = '', bool selected = false}) {
    return DataRow(selected: selected, cells: [
      DataCell(Text(c1)),
      DataCell(Tooltip(
        message: c2,
        margin: const EdgeInsets.all(kDefaultPadding),
        padding: const EdgeInsets.all(kDefaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kPrimaryColor.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.20,
            ),
            width: 1,
          ),
        ),
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        child: Text(c2),
      )),
      DataCell(Text(c3))
    ]);
  }
}
