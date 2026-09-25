import '../core/json_utils.dart';

/// Pricing guidance for one item on a price list — mirrors
/// PriceListEffectivePriceController's response, used to show per-line
/// min-price/UOM/pack/INC-rate chips in the offer composer as the web app
/// does (resources/js/features/requests/RequestComposer.js).
class EffectivePrice {
  final int itemId;
  final num? minPricePc;
  final num? minPriceUnit;
  final num? incRate;
  final String? currency;
  final String? effectiveFrom;
  final String? uom;
  final String? packSize;
  final String? packUnit;

  EffectivePrice({
    required this.itemId,
    this.minPricePc,
    this.minPriceUnit,
    this.incRate,
    this.currency,
    this.effectiveFrom,
    this.uom,
    this.packSize,
    this.packUnit,
  });

  bool get isUpcoming {
    if (effectiveFrom == null) return false;
    final from = DateTime.tryParse(effectiveFrom!);
    if (from == null) return false;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    return from.isAfter(todayDateOnly);
  }

  factory EffectivePrice.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    return EffectivePrice(
      itemId: asInt(json['item_id']),
      minPricePc: asNumOrNull(json['min_price_pc']),
      minPriceUnit: asNumOrNull(json['min_price_unit']),
      incRate: asNumOrNull(json['inc_rate']),
      currency: json['currency']?.toString(),
      effectiveFrom: json['effective_from']?.toString(),
      uom: item?['uom']?.toString(),
      packSize: item?['pack_size']?.toString(),
      packUnit: item?['pack_unit']?.toString(),
    );
  }
}
