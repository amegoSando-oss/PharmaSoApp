import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/warehouse.dart';
import '../theme/app_spacing.dart';
import 'error_state.dart';

/// Bottom sheet for picking the fulfillment warehouse before creating a
/// sales order — the backend requires warehouse_id but the web app's UI
/// doesn't collect one either, so this closes that gap.
///
/// Only the current user's *assigned* warehouses should be passed in: the
/// backend's order-creation check (SalesOrderService::ensureWarehouseAccess)
/// requires the warehouse to be in the user's `user_warehouses` pivot with
/// can_select/status true — the global `/warehouses` list (all warehouses in
/// the system) is a superset of that and gets rejected with a 422.
class WarehousePickerSheet extends StatelessWidget {
  final List<WarehouseEntry> warehouses;

  const WarehousePickerSheet({super.key, required this.warehouses});

  static Future<WarehouseEntry?> show(BuildContext context, List<WarehouseEntry> warehouses) {
    return showModalBottomSheet<WarehouseEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => WarehousePickerSheet(warehouses: warehouses),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.widgetsSelectWarehouseTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.widgetsSelectWarehouseSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            if (warehouses.isEmpty)
              InlineErrorBanner(
                message: l10n.widgetsNoWarehousesAssignedMessage,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: warehouses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final warehouse = warehouses[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warehouse_outlined),
                      title: Text(warehouse.name),
                      subtitle: warehouse.location != null ? Text(warehouse.location!) : null,
                      onTap: () => Navigator.of(context).pop(warehouse),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
