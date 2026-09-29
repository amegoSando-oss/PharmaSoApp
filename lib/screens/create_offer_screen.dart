import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/customer.dart';
import '../models/effective_price.dart';
import '../models/item.dart';
import '../models/offline_price_offer.dart';
import '../models/price_list.dart';
import '../models/warehouse_item_stock.dart';
import '../services/connection_status_service.dart';
import '../services/offers_service.dart';
import '../services/offline_sync_service.dart';
import '../services/reference_cache.dart';
import '../services/warehouse_stock_cache.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/error_state.dart';
import '../widgets/info_tile.dart';
import '../widgets/item_picker_sheet.dart';
import '../widgets/loading_button.dart';
import '../widgets/notification_bell.dart';
import '../widgets/person_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/skeleton_loader.dart';

class _LineForm {
  ItemEntry? item;
  EffectivePrice? guidance;
  bool guidanceLoading = false;
  // Set when [guidance] came from the last-known bulk effective-prices
  // cache (an offline/failed fetch fallback) rather than a fresh per-item
  // server response — mirrors [stockCachedAt] below.
  bool guidanceFromCache = false;
  List<WarehouseItemStock> stock = [];
  bool stockLoading = false;
  String? stockError;
  // Set when [stock] came from WarehouseStockCache (an offline/failed
  // fetch fallback) rather than a fresh server response — lets the UI tell
  // the rep it might not be current.
  DateTime? stockCachedAt;
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  // Informational flag only for the approver (0-100) — mirrors web's
  // foc_percent; never a quantity/UOM (see OfferLineInput's doc comment).
  final focPercentController = TextEditingController();

  /// A line the user hasn't touched at all — untouched default lines (the
  /// form starts with 3) are silently dropped on submit rather than
  /// blocking it or getting sent as empty rows.
  bool get isEmpty => item == null && quantityController.text.trim().isEmpty && priceController.text.trim().isEmpty;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    focPercentController.dispose();
  }
}

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _submitError;

  List<Customer> _customers = [];
  List<PriceListEntry> _priceLists = [];
  List<ItemEntry> _items = [];

  Customer? _selectedCustomer;
  final List<_LineForm> _lines = [_LineForm(), _LineForm(), _LineForm()];

  PriceListEntry? get _activePriceList {
    for (final list in _priceLists) {
      if (list.isActive) return list;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final reference = context.read<ReferenceCache>();
    try {
      await reference.ensureLoaded(force: true);
    } on ApiException catch (e) {
      // A real server error (as opposed to no response at all) only matters
      // if there's nothing at all to fall back on — ReferenceCache already
      // hydrated itself from disk in this case if it had anything cached.
      if (reference.customers.isEmpty) {
        if (mounted) setState(() => _loadError = e.message);
      }
    } catch (_) {
      // No ApiException means the request never got a response at all —
      // most likely offline. ReferenceCache falls back to its persisted
      // copy on disk automatically, so a rep who's gone offline mid-trip
      // (even after restarting the app) can still compose new offers
      // against last-known customers/warehouses/price lists/items.
      if (reference.customers.isEmpty) {
        if (mounted) setState(() => _loadError = AppLocalizations.of(context).createOfferLoadError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _customers = reference.customers;
          _priceLists = reference.priceLists;
          _items = reference.items;
          _loading = false;
        });
      }
    }
  }

  /// Pull-to-refresh variant of _load(): re-fetches customers/price
  /// lists/items without blanking the form out to a full-screen spinner —
  /// the in-progress line items the rep is filling in stay put.
  Future<void> _pullRefresh() async {
    final reference = context.read<ReferenceCache>();
    try {
      await reference.ensureLoaded(force: true);
    } catch (_) {
      // Background refresh — keep whatever was already loaded on failure.
    }
    if (!mounted) return;
    setState(() {
      _customers = reference.customers;
      _priceLists = reference.priceLists;
      _items = reference.items;
    });
  }

  /// Mirrors RequestComposer.js's refreshGuidanceLine: shows the active
  /// minimum price / UOM / pack / INC-rate for the selected item as soon as
  /// it's picked, so the salesman sees pricing guidance before typing a
  /// proposed price — purely advisory, the server re-validates on submit.
  /// Also mirrors its price defaulting: fills the proposed price with the
  /// guidance's effective price (price_after_tax, falling back to
  /// min_price_pc) the first time guidance loads for this line, but only
  /// while the field is still empty — never overwrites a price the user
  /// already typed (e.g. re-picking the same item, or a slow response
  /// landing after they've started editing).
  Future<void> _refreshGuidance(_LineForm line) async {
    if (line.item == null || _activePriceList == null) return;
    setState(() => line.guidanceLoading = true);
    final priceListId = _activePriceList!.id;
    final itemId = line.item!.id;
    try {
      final results = await context.read<OffersService>().fetchEffectivePrices(priceListId, itemId: itemId);
      if (!mounted) return;
      setState(() {
        line.guidanceFromCache = false;
        line.guidance = results.isNotEmpty ? results.first : null;
        _applyGuidanceDefaultPrice(line);
      });
    } catch (_) {
      // No response at all (offline) — fall back to this price list's
      // last-known bulk effective prices rather than clearing guidance.
      final results = await context.read<OffersService>().fetchEffectivePricesBulk(priceListId).catchError((_) => <EffectivePrice>[]);
      if (!mounted) return;
      final matches = results.where((p) => p.itemId == itemId);
      setState(() {
        line.guidanceFromCache = true;
        line.guidance = matches.isEmpty ? null : matches.first;
        _applyGuidanceDefaultPrice(line);
      });
    } finally {
      if (mounted) setState(() => line.guidanceLoading = false);
    }
  }

  /// Fills the proposed price with the guidance's effective price the first
  /// time guidance loads for this line, but only while the field is still
  /// empty — never overwrites a price the user already typed.
  void _applyGuidanceDefaultPrice(_LineForm line) {
    final defaultPrice = line.guidance?.effectivePrice;
    if (defaultPrice != null && line.priceController.text.trim().isEmpty) {
      line.priceController.text = defaultPrice.toStringAsFixed(2);
    }
  }

  /// Mirrors RequestComposer.js's loadLineStock: display-only warehouse
  /// stock for the selected item — no warehouse is assigned at price-offer
  /// time, this is purely informational (per §8a, warehouse choice happens
  /// once, later, at sales-order time).
  Future<void> _loadLineStock(_LineForm line) async {
    setState(() {
      line.stock = [];
      line.stockError = null;
      line.stockCachedAt = null;
    });
    if (line.item == null) return;
    final itemId = line.item!.id;
    setState(() => line.stockLoading = true);
    try {
      final results = await context.read<OffersService>().fetchWarehouseStockForItem(itemId);
      if (!mounted) return;
      setState(() => line.stock = results);
      // Best-effort: keep the last-known figures around locally so this
      // same section can still show something useful while offline.
      unawaited(WarehouseStockCache.instance.save(itemId, results));
    } catch (error) {
      // Covers both a real server error (ApiException) and no response at
      // all (offline) — either way, fall back to whatever was cached from
      // an earlier successful fetch of this item rather than leaving the
      // section blank/erroring.
      final cached = await WarehouseStockCache.instance.load(itemId);
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          line.stock = cached.stock;
          line.stockCachedAt = cached.cachedAt;
        });
      } else {
        setState(() => line.stockError =
            error is ApiException ? error.message : AppLocalizations.of(context).createOfferStockLoadError);
      }
    } finally {
      if (mounted) setState(() => line.stockLoading = false);
    }
  }

  num _lineTotal(_LineForm line) {
    final qty = num.tryParse(line.quantityController.text) ?? 0;
    final price = num.tryParse(line.priceController.text) ?? 0;
    return qty * price;
  }

  /// Proposed price vs the price list's guidance (the same effective price
  /// used to gate BELOW_MINIMUM/AT_MINIMUM/ABOVE_MINIMUM server-side), as a
  /// signed percentage — shown as a stock-ticker-style arrow next to the
  /// price field. Null (hidden) until there's both an active guidance price
  /// and a parseable proposed price to compare it against.
  num? _priceChangePercent(_LineForm line) {
    final guidancePrice = line.guidance?.effectivePrice;
    final proposedPrice = num.tryParse(line.priceController.text);
    if (guidancePrice == null || guidancePrice == 0 || proposedPrice == null) return null;
    return (proposedPrice - guidancePrice) / guidancePrice * 100;
  }

  num get _estimatedTotal => _lines.fold<num>(0, (sum, l) => sum + _lineTotal(l));

  /// Quantity/price controllers across every line, merged so the bottom
  /// summary bar and the "why can't I submit" hint can rebuild live as the
  /// user types — without also rebuilding the whole line-card list on every
  /// keystroke like a top-level setState would.
  Listenable get _priceInputsListenable =>
      Listenable.merge(_lines.expand((l) => [l.quantityController, l.priceController]).toList());

  /// Same comparison as _priceChangePercent, but rolled up across every line
  /// that has a guidance price — qty-weighted, so a big-quantity line moves
  /// the total more than a one-off small line. Lines missing a guidance
  /// price (or an unparsed qty/price) are left out of both sides so the
  /// comparison stays apples-to-apples; null (hidden) if none qualify.
  num? get _totalPriceChangePercent {
    num guidanceTotal = 0;
    num actualTotal = 0;
    bool hasAny = false;
    for (final line in _lines) {
      final guidancePrice = line.guidance?.effectivePrice;
      final qty = num.tryParse(line.quantityController.text);
      final proposedPrice = num.tryParse(line.priceController.text);
      if (guidancePrice == null || qty == null || proposedPrice == null) continue;
      hasAny = true;
      guidanceTotal += qty * guidancePrice;
      actualTotal += qty * proposedPrice;
    }
    if (!hasAny || guidanceTotal == 0) return null;
    return (actualTotal - guidanceTotal) / guidanceTotal * 100;
  }

  /// Returns why the offer can't be submitted yet, or null when it's ready —
  /// surfaced as inline hint text instead of silently disabling the button.
  /// Untouched lines (isEmpty) are skipped entirely here — they're dropped
  /// on submit rather than blocking it — so only a line the user actually
  /// started filling in can produce a validation error.
  String? get _blockingReason {
    final l10n = AppLocalizations.of(context);
    if (_selectedCustomer == null) return l10n.createOfferSelectCustomer;
    if (_selectedCustomer!.activeSalesman == null) return l10n.createOfferNoSalesman;
    if (_activePriceList == null) return l10n.createOfferNoActivePriceList;
    bool hasFilledLine = false;
    for (int i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l.isEmpty) continue;
      hasFilledLine = true;
      if (l.item == null) return l10n.createOfferSelectItemForLine(i + 1);
      final qty = num.tryParse(l.quantityController.text);
      if (qty == null || qty <= 0) return l10n.createOfferEnterValidQuantity(i + 1);
      if (num.tryParse(l.priceController.text) == null) return l10n.createOfferEnterProposedPrice(i + 1);
    }
    if (!hasFilledLine) return l10n.createOfferAddAtLeastOneLine;
    return null;
  }

  bool get _canSubmit => !_saving && _blockingReason == null;

  void _addLine() => setState(() => _lines.add(_LineForm()));

  /// Mirrors RequestComposer.js's item picker: a searchable modal scoped to
  /// the customer's active salesman, rather than filtering a fixed local
  /// list — see ItemPickerSheet's doc comment.
  Future<void> _pickItem(_LineForm line) async {
    final picked = await ItemPickerSheet.show(
      context,
      localItems: _items,
      salesmanId: _selectedCustomer?.activeSalesman?.id,
      offers: context.read<OffersService>(),
    );
    if (picked == null) return;
    setState(() => line.item = picked);
    _refreshGuidance(line);
    _loadLineStock(line);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    // Drop untouched lines the moment submission is attempted — only lines
    // the user actually filled in should reach the server or stay visible.
    final emptyLines = _lines.where((l) => l.isEmpty).toList();
    if (emptyLines.isNotEmpty) {
      setState(() => _lines.removeWhere(emptyLines.contains));
      for (final l in emptyLines) {
        l.dispose();
      }
    }
    setState(() {
      _saving = true;
      _submitError = null;
    });

    final l10n = AppLocalizations.of(context);
    final isOffline = context.read<ConnectionStatusService>().quality == ConnectionQuality.offline;

    try {
      if (isOffline) {
        final record = await context.read<OfflineSyncService>().createOffline(
              customerId: _selectedCustomer!.id,
              salesmanId: _selectedCustomer!.activeSalesman!.id,
              priceListId: _activePriceList!.id,
              lines: _lines
                  .map((l) => OfflineOfferLine(
                        itemId: l.item!.id,
                        itemName: l.item!.name,
                        quantity: num.parse(l.quantityController.text),
                        proposedPrice: num.parse(l.priceController.text),
                        focPercent: num.tryParse(l.focPercentController.text),
                      ))
                  .toList(),
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.createOfferSavedOfflineSuccess(record.serial))),
        );
        Navigator.of(context).pop(true);
        return;
      }

      final offers = context.read<OffersService>();
      await offers.createRequest(
        customerId: _selectedCustomer!.id,
        salesmanId: _selectedCustomer!.activeSalesman!.id,
        priceListId: _activePriceList!.id,
        lines: _lines
            .map((l) => OfferLineInput(
                  itemId: l.item!.id,
                  quantity: num.parse(l.quantityController.text),
                  proposedPrice: num.parse(l.priceController.text),
                  focPercent: num.tryParse(l.focPercentController.text),
                ))
            .toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createOfferDraftCreatedSuccess)),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _submitError = e.message);
    } on StateError catch (e) {
      // No local serial reserved for this salesman yet (createOffline).
      setState(() => _submitError = e.message);
    } catch (_) {
      setState(() => _submitError = l10n.createOfferSubmitError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).createOfferTitle),
        actions: const [ConnectionStatusBadge(), NotificationBell()],
      ),
      body: _loading
          ? const SkeletonOfferForm()
          : _loadError != null
              ? ErrorState(message: _loadError!, onRetry: _load)
              : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: _pullRefresh,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            children: [
              SectionCard(
                title: l10n.createOfferCustomerSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<Customer>(
                      initialValue: _selectedCustomer,
                      decoration: InputDecoration(
                          labelText: l10n.createOfferCustomerLabel, prefixIcon: const Icon(Icons.storefront_outlined)),
                      items: _customers
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (c) {
                        setState(() => _selectedCustomer = c);
                        // Opportunistically top up this salesman's reserved
                        // offline request numbers while we still have a
                        // connection — a no-op if plenty are already
                        // stashed locally, and silently skipped if this
                        // turns out to be offline too (nothing lost: it'll
                        // just fail to reserve, same as before this call).
                        final salesmanId = c?.activeSalesman?.id;
                        if (salesmanId != null) {
                          context.read<OfflineSyncService>().ensureReservation(salesmanId).catchError((_) {});
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PersonTile(
                      label: l10n.createOfferAssignedSalesmanLabel,
                      name: _selectedCustomer?.activeSalesman?.name,
                      code: _selectedCustomer?.activeSalesman?.code,
                      placeholder: _selectedCustomer == null
                          ? l10n.createOfferSelectCustomerFirst
                          : l10n.createOfferNoActiveSalesmanAssignment,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InfoTile(
                      label: l10n.createOfferPriceListLabel,
                      icon: Icons.price_change_outlined,
                      isPlaceholder: _activePriceList == null,
                      value: _activePriceList?.name ?? l10n.createOfferNoActivePriceListValue,
                    ),
                    if (_activePriceList == null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.createOfferNoActivePriceListMessage,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: l10n.createOfferLineItemsSectionTitle,
                trailing: TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.createOfferAddLineButton),
                ),
                child: Column(
                  children: [
                    _StockDisclaimer(),
                    for (int i = 0; i < _lines.length; i++) _buildLineCard(context, i),
                    // Duplicated at the bottom of the list on purpose — so
                    // adding another line doesn't mean scrolling back up to
                    // the section header once you're editing line 3+.
                    OutlinedButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createOfferAddLineButton),
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: _priceInputsListenable,
                builder: (context, _) {
                  final blockingReason = _blockingReason;
                  if (blockingReason == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            blockingReason,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_submitError != null) ...[
                const SizedBox(height: AppSpacing.md),
                InlineErrorBanner(message: _submitError!),
              ],
            ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: ListenableBuilder(
              listenable: _priceInputsListenable,
              builder: (context, _) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.createOfferEstimatedValueLabel, style: theme.textTheme.bodySmall),
                        Row(
                          children: [
                            Text(_estimatedTotal.toStringAsFixed(2), style: theme.textTheme.titleMedium),
                            if (_totalPriceChangePercent != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _PriceChangeIndicator(percent: _totalPriceChangePercent!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  LoadingButton(
                    label: l10n.createOfferCreateDraftButton,
                    loading: _saving,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineCard(BuildContext context, int index) {
    final line = _lines[index];
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.createOfferLineNumber(index + 1), style: theme.textTheme.labelLarge),
              const Spacer(),
              if (_lines.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _lines[index].dispose();
                    _lines.removeAt(index);
                  }),
                ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _pickItem(line),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.createOfferItemLabel,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                line.item?.displayName ?? l10n.createOfferItemSearchHint,
                overflow: TextOverflow.ellipsis,
                style: line.item == null ? TextStyle(color: theme.colorScheme.outline) : null,
              ),
            ),
          ),
          if (line.item != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (line.guidanceLoading)
              Text(
                l10n.createOfferLoadingActivePrice,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
              )
            else if (line.guidance != null) ...[
              if (line.guidanceFromCache) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      l10n.createOfferGuidanceFromCache,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _GuidanceChip(
                    label: line.guidance!.isUpcoming ? l10n.createOfferGuidanceUpcoming : l10n.createOfferGuidanceMin,
                    value: line.guidance!.effectivePrice?.toStringAsFixed(2) ?? '—',
                  ),
                  _GuidanceChip(
                      label: l10n.createOfferGuidanceBeforeTax,
                      value: line.guidance!.priceBeforeTax?.toStringAsFixed(2) ?? '—'),
                  _GuidanceChip(label: l10n.createOfferGuidanceUom, value: line.guidance!.uom ?? '—'),
                  _GuidanceChip(
                    label: l10n.createOfferGuidancePack,
                    value: '${line.guidance!.packSize ?? '—'} ${line.guidance!.packUnit ?? ''}'.trim(),
                  ),
                  _GuidanceChip(
                      label: l10n.createOfferGuidanceMinPricePerUnit,
                      value: line.guidance!.minPriceUnit?.toStringAsFixed(2) ?? '—'),
                  if (line.guidance!.includeTax)
                    _GuidanceChip(label: l10n.createOfferGuidanceTax, value: '${line.guidance!.taxRate ?? 0}%'),
                  _GuidanceChip(label: l10n.createOfferGuidanceInc, value: '${line.guidance!.incRate ?? 0}%'),
                  if (line.guidance!.isUpcoming)
                    _GuidanceChip(label: l10n.createOfferGuidanceStarts, value: line.guidance!.effectiveFrom ?? '—', warn: true),
                ],
              ),
            ]
            else
              Text(
                l10n.createOfferNoActivePriceForItem,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: AppSpacing.sm),
            _WarehouseStockSection(line: line),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Scoped to just this line's own quantity/price controllers, so
          // typing here doesn't rebuild every other line on the screen.
          // The Quantity/Proposed price Row must stay at a *fixed* position
          // in this Column — with no keys, Flutter reconciles children by
          // index, so an `if (...) ...[widget]` sibling appearing/
          // disappearing above it (e.g. the indicator, the moment a percent
          // becomes computable) shifts its index, which Flutter treats as a
          // different Element and remounts the TextField from scratch,
          // silently dropping focus and the keyboard after the very first
          // keystroke. Keeping the Row first and the optional bits below it
          // as fixed slots (SizedBox.shrink() instead of removed entirely)
          // means its index never moves.
          ListenableBuilder(
            listenable: Listenable.merge([line.quantityController, line.priceController]),
            builder: (context, _) {
              final changePercent = _priceChangePercent(line);
              final lineTotal = _lineTotal(line);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: line.quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: l10n.createOfferQuantityLabel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: line.priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: l10n.createOfferProposedPriceLabel),
                        ),
                      ),
                    ],
                  ),
                  changePercent == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                          child: Align(alignment: Alignment.centerRight, child: _PriceChangeIndicator(percent: changePercent)),
                        ),
                  lineTotal <= 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(lineTotal.toStringAsFixed(2), style: theme.textTheme.bodySmall),
                          ),
                        ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: line.focPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.createOfferFocPercentLabel,
              helperText: l10n.createOfferFocHelperText,
              helperMaxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stock-ticker-style indicator: green up-arrow when the proposed price is
/// above the price list's guidance (min_price_pc), red down-arrow when
/// below.
class _PriceChangeIndicator extends StatelessWidget {
  final num percent;

  const _PriceChangeIndicator({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final color = isUp ? const Color(0xFF1E8E3E) : const Color(0xFFD93025);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _GuidanceChip extends StatelessWidget {
  final String label;
  final String value;
  final bool warn;

  const _GuidanceChip({required this.label, required this.value, this.warn = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = warn ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: color.withValues(alpha: 0.8))),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Same wording as web's .stock-disclaimer — the JDE stock sync isn't final
/// yet, so this is a reminder these numbers are placeholder data.
class _StockDisclaimer extends StatelessWidget {
  const _StockDisclaimer();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8A6A1F);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0E0AD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).createOfferStockDisclaimer,
              style: const TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Display-only warehouse stock for the line's selected item — no warehouse
/// is assigned at price-offer time (that only happens once, later, at
/// sales-order time), so this is purely informational. Rendered as a
/// horizontally-scrollable row of compact cards rather than web's plain
/// table, since a 4-column table doesn't fit a phone width.
class _WarehouseStockSection extends StatelessWidget {
  final _LineForm line;

  const _WarehouseStockSection({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createOfferWarehouseStockSectionLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 6),
        if (line.stockLoading)
          Text(
            l10n.createOfferLoadingWarehouseStock,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
          )
        else if (line.stockError != null)
          Text(line.stockError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))
        else if (line.stock.isEmpty)
          Text(
            l10n.createOfferNoWarehouseStock,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
          )
        else ...[
          if (line.stockCachedAt != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 12, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.createOfferStockFromCache(formatRelativeTime(line.stockCachedAt!)),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: line.stock.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _WarehouseStockCard(stock: line.stock[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _WarehouseStockCard extends StatelessWidget {
  final WarehouseItemStock stock;

  const _WarehouseStockCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 148,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stock.warehouseName ?? l10n.createOfferWarehouseFallback(stock.warehouseId),
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(l10n.createOfferAvailableLabel,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10)),
          Text(
            stock.availableQty.toString(),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            l10n.createOfferOnHandCommitted(stock.onHandQty, stock.committedQty),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
