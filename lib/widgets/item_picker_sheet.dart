import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../services/offers_service.dart';
import '../theme/app_spacing.dart';

/// Bottom sheet for picking a line item — mirrors RequestComposer.js's item
/// picker (a searchable modal, not an inline autocomplete): the field on
/// the line card is just a tappable trigger that opens this.
///
/// When [salesmanId] is known, every keystroke re-queries the server scoped
/// to that salesman (`OffersService.fetchItems(search:, salesmanId:)`), so
/// the list only ever offers items the rep is actually authorized to sell —
/// the same category-mapping enforcement the server applies authoritatively
/// on submit, just surfaced here so nothing gets offered only to be
/// rejected later. With no query typed yet (or no salesman known), it falls
/// back to whatever was already loaded locally, same as
/// RequestComposer.js's `localItemOptions()`.
class ItemPickerSheet extends StatefulWidget {
  final List<ItemEntry> localItems;
  final int? salesmanId;
  final OffersService offers;

  const ItemPickerSheet({super.key, required this.localItems, required this.salesmanId, required this.offers});

  static Future<ItemEntry?> show(
    BuildContext context, {
    required List<ItemEntry> localItems,
    required int? salesmanId,
    required OffersService offers,
  }) {
    return showModalBottomSheet<ItemEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ItemPickerSheet(localItems: localItems, salesmanId: salesmanId, offers: offers),
    );
  }

  @override
  State<ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<ItemPickerSheet> {
  final _searchController = TextEditingController();
  late List<ItemEntry> _results = widget.localItems.take(20).toList();
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = widget.localItems.take(20).toList();
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await widget.offers.fetchItems(search: query, salesmanId: widget.salesmanId);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.itemPickerTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.createOfferItemSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text(
                          l10n.itemPickerNoMatches,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: (item.uom != null || item.packSize != null)
                                ? Text('${item.uom ?? ''} ${item.packSize ?? ''} ${item.packUnit ?? ''}'.trim())
                                : null,
                            trailing: item.jdeItemNumber != null ? Text('JDE ${item.jdeItemNumber}') : null,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
