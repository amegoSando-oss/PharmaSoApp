import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/sales_order.dart';
import '../screens/sales_order_detail_screen.dart';
import '../services/sales_orders_service.dart';
import '../widgets/status_pill.dart';

/// A quotation can have zero, one, or several current sales orders (repeated
/// partial releases, and/or automatic value-cap splitting of a release) —
/// this centralizes the "resolve and jump" logic so the request-detail and
/// quotation-detail screens don't each duplicate a picker sheet.
Future<void> openSalesOrdersForQuotation(BuildContext context, int quotationId) async {
  final l10n = AppLocalizations.of(context);
  List<SalesOrder> orders;
  try {
    orders = await context.read<SalesOrdersService>().listOrders(quotationId: quotationId);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.relatedRecordsLoadOrdersFailed)));
    }
    return;
  }
  if (!context.mounted) return;

  if (orders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.relatedRecordsNoSalesOrderYet)));
    return;
  }

  if (orders.length == 1) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SalesOrderDetailScreen(id: orders.first.id)),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.relatedRecordsSelectSalesOrderTitle, style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: orders.length,
                itemBuilder: (_, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text(order.orderNumber),
                    trailing: StatusPill(value: order.status, dense: true),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SalesOrderDetailScreen(id: order.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
