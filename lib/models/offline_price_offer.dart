import '../services/offers_service.dart';

class OfflineOfferLine {
  final int itemId;
  final String itemName;
  final num quantity;
  final num proposedPrice;
  final num? focPercent;

  OfflineOfferLine({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.proposedPrice,
    this.focPercent,
  });

  /// The exact shape SyncPriceOfferRequestsRequest validates per line —
  /// mirrors OfferLineInput.toJson but always includes `uom` (nullable,
  /// accepted but unused by this app's composer) since the sync endpoint
  /// treats every field as required-or-explicitly-null, never omitted.
  Map<String, dynamic> toSyncJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'proposed_price': proposedPrice,
        'uom': null,
        'foc_percent': focPercent,
      };

  Map<String, dynamic> toStorageJson() => {
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'proposed_price': proposedPrice,
        'foc_percent': focPercent,
      };

  factory OfflineOfferLine.fromStorageJson(Map<String, dynamic> json) => OfflineOfferLine(
        itemId: json['item_id'] as int,
        itemName: json['item_name']?.toString() ?? '',
        quantity: json['quantity'] as num,
        proposedPrice: json['proposed_price'] as num,
        focPercent: json['foc_percent'] as num?,
      );

  factory OfflineOfferLine.fromInput(OfferLineInput input, {required String itemName}) => OfflineOfferLine(
        itemId: input.itemId,
        itemName: itemName,
        quantity: input.quantity,
        proposedPrice: input.proposedPrice,
        focPercent: input.focPercent,
      );
}

enum OfflineSyncStatus { pending, syncing, failed }

/// A price offer request created fully offline (Step 2 of the protocol),
/// queued locally until it can be synced (Step 3). [serial] is the
/// ready-to-display request number drawn from a prior reservation —
/// never invented locally. [clientUuid] never changes across retries.
class OfflinePriceOffer {
  final String clientUuid;
  final String serial;
  final int reservationId;
  final int customerId;
  final int salesmanId;
  final int priceListId;
  final List<OfflineOfferLine> lines;
  final DateTime createdOfflineAt;
  final OfflineSyncStatus status;
  final String? syncError;

  OfflinePriceOffer({
    required this.clientUuid,
    required this.serial,
    required this.reservationId,
    required this.customerId,
    required this.salesmanId,
    required this.priceListId,
    required this.lines,
    required this.createdOfflineAt,
    this.status = OfflineSyncStatus.pending,
    this.syncError,
  });

  num get estimatedTotal => lines.fold<num>(0, (sum, l) => sum + (l.quantity * l.proposedPrice));
}
