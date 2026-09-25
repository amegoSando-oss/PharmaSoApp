// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonAppName => 'PharmaSo';

  @override
  String get commonLanguageTooltip => 'Language';

  @override
  String get connectionTooltipGood => 'Connection: good';

  @override
  String get connectionTooltipUnstable => 'Connection: unstable';

  @override
  String get connectionTooltipOffline => 'Connection: offline';

  @override
  String get connectionGoodTitle => 'All good';

  @override
  String get connectionGoodMessage =>
      'You\'re online and connected to the server.';

  @override
  String get connectionUnstableTitle => 'Unstable connection';

  @override
  String get connectionUnstableMessage =>
      'You\'re online, but the connection to the server is slow or intermittent. Some actions may take longer or need a retry.';

  @override
  String get connectionOfflineTitle => 'You\'re offline';

  @override
  String get connectionOfflineMessage =>
      'No network connection, or the server can\'t be reached. Check your Wi-Fi or mobile data.';

  @override
  String get connectionNetworkLabel => 'Network';

  @override
  String get connectionNetworkConnected => 'Connected';

  @override
  String get connectionNetworkDisconnected => 'No network';

  @override
  String get connectionServerLabel => 'Server';

  @override
  String get connectionServerReachable => 'Reachable';

  @override
  String get connectionServerUnreachable => 'Unreachable';

  @override
  String get connectionLatencyLabel => 'Latency';

  @override
  String connectionLatencyValue(Object ms) {
    return '$ms ms';
  }

  @override
  String get connectionLastCheckedLabel => 'Last checked';

  @override
  String get connectionCheckingLabel => 'Checking…';

  @override
  String get connectionCheckAgainButton => 'Check again';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeSignOutTooltip => 'Sign out';

  @override
  String get homePriceOfferTitle => 'Price Offer';

  @override
  String get homePriceOfferSubtitle =>
      'Draft, submit and track price offer requests';

  @override
  String get homeCreateOfferAction => 'Create Offer';

  @override
  String get homePriceOffersAction => 'Price Offers';

  @override
  String get homeQuotationTitle => 'Quotation';

  @override
  String get homeQuotationSubtitle =>
      'Send documents and track customer responses';

  @override
  String get homeQuotationsAction => 'Quotations';

  @override
  String get homeSalesOrderTitle => 'Sales Order';

  @override
  String get homeSalesOrderSubtitle =>
      'Monitor credit status, holds and fulfilment';

  @override
  String get homeOrdersAction => 'Orders';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusActive => 'Active';

  @override
  String get statusOk => 'OK';

  @override
  String get statusPassed => 'Passed';

  @override
  String get statusNone => 'None';

  @override
  String get statusReleased => 'Released';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusBelowMin => 'Below min';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusHold => 'Hold';

  @override
  String get statusOnHold => 'On hold';

  @override
  String get statusInApproval => 'In approval';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusSent => 'Sent';

  @override
  String get statusSkipped => 'Skipped';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusQuotationGenerated => 'Quotation generated';

  @override
  String get loginGenericError => 'Something went wrong. Please try again.';

  @override
  String get loginSignInTitle => 'Sign in to your workspace';

  @override
  String get loginSubtitle => 'Use your Pharamaso account to continue.';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginEmailRequiredError => 'Email is required';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => 'Your password';

  @override
  String get loginPasswordRequiredError => 'Password is required';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginSignInButton => 'Sign in';

  @override
  String get loginAccessNotice =>
      'Your access is controlled by your assigned roles and permissions.';

  @override
  String get loginTagline => 'Commercial OS';

  @override
  String get splashCompanyName => 'DAKAHLIA GROUP';

  @override
  String get createOfferTitle => 'New price offer';

  @override
  String get createOfferLoadError => 'Failed to load master data.';

  @override
  String get createOfferStockLoadError => 'Failed to load warehouse stock.';

  @override
  String get createOfferSelectCustomer => 'Select a customer to continue.';

  @override
  String get createOfferNoSalesman =>
      'This customer has no active salesman assignment.';

  @override
  String get createOfferNoActivePriceList =>
      'There is no active price list right now.';

  @override
  String createOfferSelectItemForLine(Object lineNumber) {
    return 'Select an item for line $lineNumber.';
  }

  @override
  String createOfferEnterValidQuantity(Object lineNumber) {
    return 'Enter a valid quantity for line $lineNumber.';
  }

  @override
  String createOfferEnterProposedPrice(Object lineNumber) {
    return 'Enter a proposed price for line $lineNumber.';
  }

  @override
  String get createOfferAddAtLeastOneLine => 'Add at least one line item.';

  @override
  String get createOfferDraftCreatedSuccess => 'Price offer draft created.';

  @override
  String get createOfferSubmitError =>
      'Failed to create the price offer request.';

  @override
  String get createOfferCustomerSectionTitle => 'Customer & pricing';

  @override
  String get createOfferCustomerLabel => 'Customer';

  @override
  String get createOfferAssignedSalesmanLabel => 'Assigned salesman';

  @override
  String get createOfferSelectCustomerFirst => 'Select a customer first';

  @override
  String get createOfferNoActiveSalesmanAssignment =>
      'No active salesman assignment';

  @override
  String get createOfferPriceListLabel => 'Price list';

  @override
  String get createOfferNoActivePriceListValue => 'No active price list';

  @override
  String get createOfferNoActivePriceListMessage =>
      'There is no active price list right now. You cannot create a price offer until one is activated.';

  @override
  String get createOfferLineItemsSectionTitle => 'Line items';

  @override
  String get createOfferAddLineButton => 'Add line';

  @override
  String get createOfferEstimatedValueLabel => 'Estimated value';

  @override
  String get createOfferCreateDraftButton => 'Create draft';

  @override
  String createOfferLineNumber(Object lineNumber) {
    return 'Line $lineNumber';
  }

  @override
  String get createOfferItemLabel => 'Item';

  @override
  String get createOfferItemSearchHint => 'Search by name or JDE code';

  @override
  String get createOfferLoadingActivePrice => 'Loading active price…';

  @override
  String get createOfferGuidanceUpcoming => 'Upcoming';

  @override
  String get createOfferGuidanceMin => 'Min';

  @override
  String get createOfferGuidanceUom => 'UOM';

  @override
  String get createOfferGuidancePack => 'Pack';

  @override
  String get createOfferGuidanceMinPricePerUnit => 'Min price / Lt or Kg';

  @override
  String get createOfferGuidanceInc => 'INC';

  @override
  String get createOfferGuidanceStarts => 'Starts';

  @override
  String get createOfferNoActivePriceForItem =>
      'No active price for this item — minimum will be validated on submit.';

  @override
  String get createOfferQuantityLabel => 'Quantity';

  @override
  String get createOfferProposedPriceLabel => 'Proposed price';

  @override
  String get createOfferFocLabel => 'Free of charge (FOC)';

  @override
  String get createOfferFocQuantityLabel => 'FOC qty';

  @override
  String get createOfferFocUomLabel => 'FOC UOM';

  @override
  String get createOfferStockDisclaimer =>
      'The displayed inventory is estimated and not final, and is subject to adjustment and updates.';

  @override
  String get createOfferWarehouseStockSectionLabel =>
      'Warehouse stock (display only — no warehouse is assigned here)';

  @override
  String get createOfferLoadingWarehouseStock => 'Loading warehouse stock…';

  @override
  String get createOfferNoWarehouseStock =>
      'No warehouse stock recorded for this item yet.';

  @override
  String get createOfferAvailableLabel => 'Available';

  @override
  String createOfferWarehouseFallback(Object warehouseId) {
    return 'Warehouse #$warehouseId';
  }

  @override
  String createOfferOnHandCommitted(Object onHand, Object committed) {
    return 'On hand $onHand · Committed $committed';
  }

  @override
  String get priceOffersTitle => 'Price offers';

  @override
  String get priceOffersSearchHint => 'Search by request # or customer';

  @override
  String get priceOffersClearFilters => 'Clear filters';

  @override
  String get priceOffersLoadError => 'Failed to load requests.';

  @override
  String get priceOffersEmptyTitle => 'No price offer requests yet';

  @override
  String get priceOffersEmptyMessage =>
      'Create your first price offer to get started.';

  @override
  String get priceOffersNewRequest => 'New request';

  @override
  String get priceOffersStatusAll => 'All';

  @override
  String get priceOffersStatusDraft => 'Draft';

  @override
  String get priceOffersStatusPending => 'Pending';

  @override
  String get priceOffersStatusInApproval => 'In approval';

  @override
  String get priceOffersStatusRejected => 'Rejected';

  @override
  String get priceOffersStatusQuotationGenerated => 'Quotation generated';

  @override
  String get priceOffersNoMatchTitle => 'No matching requests';

  @override
  String get priceOffersNoMatchMessage => 'Try a different filter.';

  @override
  String get priceOffersHoldToSubmit => 'Hold to submit';

  @override
  String priceOffersSubmittedSnackbar(Object requestNumber) {
    return '$requestNumber submitted for approval.';
  }

  @override
  String get priceOffersFilterByCustomer => 'Filter by customer';

  @override
  String get priceOffersSearchCustomersHint => 'Search customers';

  @override
  String get priceOffersNoMatchingCustomers => 'No matching customers.';

  @override
  String get priceOffersSubmitFailed => 'Failed to submit for approval.';

  @override
  String get priceOffersSubmitConfirmTitle => 'Submit for approval?';

  @override
  String get priceOffersSubmitConfirmBody =>
      'This moves the draft into the approval workflow — you won\'t be able to edit its lines afterward unless it\'s returned.';

  @override
  String get priceOffersNotNow => 'Not now';

  @override
  String get priceOffersSubmitButton => 'Submit';

  @override
  String get requestDetailTitle => 'Request detail';

  @override
  String get requestDetailLoadError => 'Failed to load request.';

  @override
  String get requestDetailSummaryTitle => 'Summary';

  @override
  String get requestDetailCustomerLabel => 'Customer';

  @override
  String get requestDetailPriceListLabel => 'Price list';

  @override
  String get requestDetailPricingLabel => 'Pricing';

  @override
  String get requestDetailApprovalLabel => 'Approval';

  @override
  String get requestDetailLinesTitle => 'Lines';

  @override
  String get requestDetailNoLines => 'No lines on this request.';

  @override
  String get requestDetailWorkflowTitle => 'Approval workflow';

  @override
  String get requestDetailNoWorkflow => 'No workflow instance created yet.';

  @override
  String get requestDetailActionsTitle => 'Actions';

  @override
  String get requestDetailQuantityLabel => 'Quantity';

  @override
  String get requestDetailProposedPriceLabel => 'Proposed price';

  @override
  String get requestDetailReasonLabel => 'Reason (audited change)';

  @override
  String get requestDetailCancelButton => 'Cancel';

  @override
  String get requestDetailSaveChangeButton => 'Save change';

  @override
  String requestDetailQtyProposed(
    Object quantity,
    Object uom,
    Object proposedPrice,
  ) {
    return 'Qty $quantity $uom · Proposed $proposedPrice';
  }

  @override
  String requestDetailMinSuffix(Object minimumPrice) {
    return ' · Min $minimumPrice';
  }

  @override
  String requestDetailDiffSuffix(Object priceDifference) {
    return ' · Diff $priceDifference';
  }

  @override
  String requestDetailFocLine(Object focQuantity, Object focUom) {
    return 'FOC $focQuantity $focUom';
  }

  @override
  String get requestDetailEditButton => 'Edit';

  @override
  String get requestDetailRemoveButton => 'Remove';

  @override
  String get requestDetailAddLineButton => 'Add line';

  @override
  String get requestDetailItemLabel => 'Item';

  @override
  String get requestDetailFocQtyLabel => 'FOC qty (optional)';

  @override
  String get requestDetailFocUomLabel => 'FOC UOM (optional)';

  @override
  String get requestDetailNoActionsDraft =>
      'No actions available for status \"Draft\".';

  @override
  String get requestDetailSubmitButton => 'Submit for approval';

  @override
  String get requestDetailCommentsLabel =>
      'Comments or rejection reason (audited)';

  @override
  String get requestDetailApproveStepButton => 'Approve step';

  @override
  String get requestDetailReturnStepButton => 'Return step';

  @override
  String get requestDetailSkipOptionalButton => 'Skip optional';

  @override
  String get requestDetailRejectButton => 'Reject';

  @override
  String get requestDetailApprovedNoRights =>
      'Approved — a user with quotation-create rights can generate the PDF quotation.';

  @override
  String get requestDetailGenerateQuotationButton => 'Generate quotation';

  @override
  String requestDetailNoActionsStatus(Object status) {
    return 'No actions available for status \"$status\".';
  }

  @override
  String get requestDetailQuotationNoteDraft =>
      'Download the PDF and send it to the customer — sending marks the quotation SENT and unlocks the customer\'s confirmation link.';

  @override
  String get requestDetailQuotationNoteSent =>
      'Waiting for the customer\'s response. Once they accept, the sales order action becomes available here.';

  @override
  String get requestDetailQuotationNoteAccepted =>
      'Customer accepted — create the sales order to hand this quotation to fulfillment.';

  @override
  String get requestDetailQuotationNoteRejected =>
      'Customer rejected this quotation. Prepare a new price offer if you want to re-quote.';

  @override
  String get requestDetailQuotationNoteExpired =>
      'The quotation\'s validity has passed. Create a new price offer to re-quote.';

  @override
  String requestDetailValidUntil(Object date) {
    return ' · valid until $date';
  }

  @override
  String get requestDetailDownloadPdfButton => 'Download PDF';

  @override
  String get requestDetailSendToCustomerButton => 'Send to customer';

  @override
  String get requestDetailCreateSalesOrderButton => 'Create sales order';

  @override
  String get requestDetailActionFailedGeneric =>
      'Action failed. Please try again.';

  @override
  String get requestDetailUpdateLineFailed => 'Failed to update the line.';

  @override
  String get requestDetailRemoveLineFailed => 'Failed to remove the line.';

  @override
  String get requestDetailAddLineFailed => 'Failed to add the line.';

  @override
  String get requestDetailDownloadPdfFailed => 'Failed to download the PDF.';

  @override
  String get quotationsTitle => 'Quotations';

  @override
  String get quotationsSearchHint => 'Search by quotation # or customer';

  @override
  String get quotationsClearFilters => 'Clear filters';

  @override
  String get quotationsLoadError => 'Failed to load quotations.';

  @override
  String get quotationsEmptyTitle => 'No quotations yet';

  @override
  String get quotationsEmptyMessage =>
      'Approve and convert a price offer to generate one.';

  @override
  String get quotationsNoMatchTitle => 'No matching quotations';

  @override
  String get quotationsNoMatchMessage => 'Try a different filter.';

  @override
  String quotationsVersionValidUntil(Object version, Object validUntil) {
    return 'v$version · valid until $validUntil';
  }

  @override
  String get quotationsFilterByCustomerTitle => 'Filter by customer';

  @override
  String get quotationsSearchCustomersHint => 'Search customers';

  @override
  String get quotationsNoMatchingCustomers => 'No matching customers.';

  @override
  String get quotationDetailSentMessage => 'Quotation sent to the customer.';

  @override
  String get quotationDetailOrderCreatedMessage => 'Sales order created.';

  @override
  String get quotationDetailActionDoneMessage => 'Done.';

  @override
  String get quotationDetailActionFailedMessage =>
      'Action failed. Please try again.';

  @override
  String get quotationDetailPdfDownloadFailedMessage =>
      'Failed to download the PDF.';

  @override
  String get quotationDetailSummaryTitle => 'Summary';

  @override
  String get quotationDetailCustomerLabel => 'Customer';

  @override
  String get quotationDetailPaymentTermsLabel => 'Payment terms';

  @override
  String get quotationDetailCurrencyLabel => 'Currency';

  @override
  String get quotationDetailValidUntilLabel => 'Valid until';

  @override
  String quotationDetailValidUntilWithDays(Object validUntil, Object days) {
    return '$validUntil ($days days)';
  }

  @override
  String quotationDetailLinesTitle(Object version) {
    return 'Lines (v$version)';
  }

  @override
  String get quotationDetailNoLines =>
      'No line details available for this version.';

  @override
  String quotationDetailItemFallback(Object itemId) {
    return 'Item #$itemId';
  }

  @override
  String quotationDetailQtyPriceLine(
    Object quantity,
    Object uom,
    Object price,
  ) {
    return 'Qty $quantity $uom · Price $price';
  }

  @override
  String quotationDetailFocSuffix(Object focQuantity, Object focUom) {
    return ' · FOC $focQuantity $focUom';
  }

  @override
  String get quotationDetailActionsTitle => 'Actions';

  @override
  String get quotationDetailDownloadPdfButton => 'Download PDF';

  @override
  String get quotationDetailSendButton => 'Send to customer';

  @override
  String get quotationDetailCreateOrderButton => 'Create sales order';

  @override
  String get salesOrdersTitle => 'Sales orders';

  @override
  String get salesOrdersSearchHint => 'Search by order # or customer';

  @override
  String get salesOrdersClearFilters => 'Clear filters';

  @override
  String get salesOrdersLoadError => 'Failed to load sales orders.';

  @override
  String get salesOrdersEmptyTitle => 'No orders yet';

  @override
  String get salesOrdersEmptyMessage =>
      'Convert an accepted quotation into an order.';

  @override
  String get salesOrdersNoMatchTitle => 'No matching orders';

  @override
  String get salesOrdersNoMatchMessage => 'Try a different filter.';

  @override
  String get salesOrdersReleasingLabel => 'Releasing…';

  @override
  String get salesOrdersReleaseHoldLabel => 'Release hold';

  @override
  String get salesOrdersHoldReleasedMessage => 'Hold released.';

  @override
  String get salesOrdersReleaseHoldError => 'Failed to release hold.';

  @override
  String get salesOrdersFilterByCustomerTitle => 'Filter by customer';

  @override
  String get salesOrdersSearchCustomersHint => 'Search customers';

  @override
  String get salesOrdersNoMatchingCustomers => 'No matching customers.';

  @override
  String get salesOrderDetailTitle => 'Order detail';

  @override
  String get salesOrderDetailHoldReleasedMessage => 'Hold released.';

  @override
  String get salesOrderDetailReleaseHoldError => 'Failed to release hold.';

  @override
  String salesOrderDetailWarehouseFallback(Object id) {
    return 'Warehouse #$id';
  }

  @override
  String get salesOrderDetailLoadError => 'Failed to load order.';

  @override
  String get salesOrderDetailSummaryTitle => 'Summary';

  @override
  String get salesOrderDetailCustomerLabel => 'Customer';

  @override
  String get salesOrderDetailWarehouseLabel => 'Warehouse';

  @override
  String get salesOrderDetailQuotationLabel => 'Quotation';

  @override
  String get salesOrderDetailOrderDateLabel => 'Order date';

  @override
  String get salesOrderDetailJdeOrderLabel => 'JDE order #';

  @override
  String get salesOrderDetailCreditLabel => 'Credit';

  @override
  String get salesOrderDetailHoldLabel => 'Hold';

  @override
  String get salesOrderDetailSplitOriginTitle => 'Split origin';

  @override
  String salesOrderDetailSplitOriginMessage(
    Object splitSequence,
    Object originalOrderNumber,
  ) {
    return 'This is execution order #$splitSequence of a value-capped split. The original order is $originalOrderNumber.';
  }

  @override
  String get salesOrderDetailViewOriginalOrderLabel =>
      'View order before splitting';

  @override
  String get salesOrderDetailLinesTitle => 'Lines';

  @override
  String get salesOrderDetailNoLinesMessage => 'No lines on this order.';

  @override
  String salesOrderDetailItemFallback(Object itemId) {
    return 'Item #$itemId';
  }

  @override
  String salesOrderDetailQtyLabel(Object quantity, Object uom) {
    return 'Qty $quantity $uom';
  }

  @override
  String salesOrderDetailFocLabel(Object focQuantity) {
    return 'FOC $focQuantity';
  }

  @override
  String salesOrderDetailUnitPriceBeforeTax(Object value) {
    return 'Unit price before tax $value';
  }

  @override
  String salesOrderDetailTaxRateLabel(Object rate) {
    return '$rate% tax';
  }

  @override
  String get salesOrderDetailNoTaxLabel => 'No tax';

  @override
  String salesOrderDetailUnitPriceAfterTax(Object value) {
    return 'Unit price after tax $value';
  }

  @override
  String salesOrderDetailLineTotalLabel(Object total) {
    return 'Line total (after tax): $total';
  }

  @override
  String get salesOrderDetailOrderTotalLabel => 'Order total (after tax)';

  @override
  String get salesOrderDetailHoldsTitle => 'Holds';

  @override
  String get salesOrderDetailHoldTypeFallback => 'Hold';

  @override
  String get salesOrderDetailReleaseHoldLabel => 'Release hold';

  @override
  String get widgetsNotificationsTooltip => 'Notifications';

  @override
  String get widgetsNotificationsTitle => 'Notifications';

  @override
  String widgetsNewNotificationsCount(Object count) {
    return '$count new';
  }

  @override
  String get widgetsMarkAllReadButton => 'Mark all read';

  @override
  String get widgetsNoNotificationsTitle => 'No notifications yet';

  @override
  String get widgetsNoNotificationsMessage =>
      'You\'ll see updates about your price offers and orders here.';

  @override
  String get widgetsTryAgainButton => 'Try again';

  @override
  String get widgetsSelectWarehouseTitle => 'Select fulfillment warehouse';

  @override
  String get widgetsSelectWarehouseSubtitle =>
      'The sales order will be created against this warehouse.';

  @override
  String get widgetsNoWarehousesAssignedMessage =>
      'You have no assigned warehouses to select from. Contact your administrator to get one assigned.';

  @override
  String widgetsRejectedReason(Object reason) {
    return 'Rejected: $reason';
  }
}
