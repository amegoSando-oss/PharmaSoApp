import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @commonAppName.
  ///
  /// In en, this message translates to:
  /// **'PharmaSo'**
  String get commonAppName;

  /// No description provided for @commonLanguageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLanguageTooltip;

  /// No description provided for @connectionTooltipGood.
  ///
  /// In en, this message translates to:
  /// **'Connection: good'**
  String get connectionTooltipGood;

  /// No description provided for @connectionTooltipUnstable.
  ///
  /// In en, this message translates to:
  /// **'Connection: unstable'**
  String get connectionTooltipUnstable;

  /// No description provided for @connectionTooltipOffline.
  ///
  /// In en, this message translates to:
  /// **'Connection: offline'**
  String get connectionTooltipOffline;

  /// No description provided for @connectionGoodTitle.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get connectionGoodTitle;

  /// No description provided for @connectionGoodMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re online and connected to the server.'**
  String get connectionGoodMessage;

  /// No description provided for @connectionUnstableTitle.
  ///
  /// In en, this message translates to:
  /// **'Unstable connection'**
  String get connectionUnstableTitle;

  /// No description provided for @connectionUnstableMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re online, but the connection to the server is slow or intermittent. Some actions may take longer or need a retry.'**
  String get connectionUnstableMessage;

  /// No description provided for @connectionOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get connectionOfflineTitle;

  /// No description provided for @connectionOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'No network connection, or the server can\'t be reached. Check your Wi-Fi or mobile data.'**
  String get connectionOfflineMessage;

  /// No description provided for @connectionNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get connectionNetworkLabel;

  /// No description provided for @connectionNetworkConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionNetworkConnected;

  /// No description provided for @connectionNetworkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'No network'**
  String get connectionNetworkDisconnected;

  /// No description provided for @connectionServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get connectionServerLabel;

  /// No description provided for @connectionServerReachable.
  ///
  /// In en, this message translates to:
  /// **'Reachable'**
  String get connectionServerReachable;

  /// No description provided for @connectionServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get connectionServerUnreachable;

  /// No description provided for @connectionLatencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get connectionLatencyLabel;

  /// No description provided for @connectionLatencyValue.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String connectionLatencyValue(Object ms);

  /// No description provided for @connectionLastCheckedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last checked'**
  String get connectionLastCheckedLabel;

  /// No description provided for @connectionCheckingLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get connectionCheckingLabel;

  /// No description provided for @connectionCheckAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get connectionCheckAgainButton;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeSignOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOutTooltip;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing offline requests…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncStatusNeverSynced;

  /// No description provided for @syncStatusLastSuccess.
  ///
  /// In en, this message translates to:
  /// **'All offline requests synced {time}'**
  String syncStatusLastSuccess(Object time);

  /// No description provided for @syncStatusLastFailed.
  ///
  /// In en, this message translates to:
  /// **'Last sync {time} had an error'**
  String syncStatusLastFailed(Object time);

  /// No description provided for @syncStatusLastOffline.
  ///
  /// In en, this message translates to:
  /// **'Last sync attempt {time} failed — no connection'**
  String syncStatusLastOffline(Object time);

  /// No description provided for @syncStatusPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 request waiting to sync} other{{count} requests waiting to sync}}'**
  String syncStatusPendingCount(int count);

  /// No description provided for @syncStatusShortSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusShortSyncing;

  /// No description provided for @syncStatusShortNever.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncStatusShortNever;

  /// No description provided for @syncStatusShortFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncStatusShortFailed;

  /// No description provided for @syncStatusShortOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusShortOffline;

  /// No description provided for @syncStatusShortPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 pending} other{{count} pending}}'**
  String syncStatusShortPending(int count);

  /// No description provided for @syncDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync data'**
  String get syncDialogTitle;

  /// No description provided for @syncDialogRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncDialogRunningTitle;

  /// No description provided for @syncDialogResultSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncDialogResultSuccessTitle;

  /// No description provided for @syncDialogResultPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Synced with some issues'**
  String get syncDialogResultPartialTitle;

  /// No description provided for @syncDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get syncDialogCancel;

  /// No description provided for @syncDialogSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncDialogSyncNow;

  /// No description provided for @syncDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get syncDialogClose;

  /// No description provided for @syncDialogConfirmIntro.
  ///
  /// In en, this message translates to:
  /// **'This will:'**
  String get syncDialogConfirmIntro;

  /// No description provided for @syncDialogConfirmUpload.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Upload 1 offline price offer waiting to sync} other{Upload {count} offline price offers waiting to sync}}'**
  String syncDialogConfirmUpload(int count);

  /// No description provided for @syncDialogConfirmReferenceData.
  ///
  /// In en, this message translates to:
  /// **'Refresh your customers, warehouses, items, price lists and warehouse stock'**
  String get syncDialogConfirmReferenceData;

  /// No description provided for @syncDialogConfirmRecords.
  ///
  /// In en, this message translates to:
  /// **'Refresh your price offer requests, quotations and sales orders'**
  String get syncDialogConfirmRecords;

  /// No description provided for @syncDialogStepUpload.
  ///
  /// In en, this message translates to:
  /// **'Uploading offline price offers'**
  String get syncDialogStepUpload;

  /// No description provided for @syncDialogStepReferenceData.
  ///
  /// In en, this message translates to:
  /// **'Customers, warehouses, items & price lists'**
  String get syncDialogStepReferenceData;

  /// No description provided for @syncDialogStepOfflineReadiness.
  ///
  /// In en, this message translates to:
  /// **'Preparing offline request numbers'**
  String get syncDialogStepOfflineReadiness;

  /// No description provided for @syncDialogStepEffectivePrices.
  ///
  /// In en, this message translates to:
  /// **'Effective prices'**
  String get syncDialogStepEffectivePrices;

  /// No description provided for @syncDialogStepWarehouseStock.
  ///
  /// In en, this message translates to:
  /// **'Warehouse stock'**
  String get syncDialogStepWarehouseStock;

  /// No description provided for @syncDialogStepPriceOfferRequests.
  ///
  /// In en, this message translates to:
  /// **'Price offer requests'**
  String get syncDialogStepPriceOfferRequests;

  /// No description provided for @syncDialogStepQuotations.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get syncDialogStepQuotations;

  /// No description provided for @syncDialogStepSalesOrders.
  ///
  /// In en, this message translates to:
  /// **'Sales orders'**
  String get syncDialogStepSalesOrders;

  /// No description provided for @homePriceOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Offer'**
  String get homePriceOfferTitle;

  /// No description provided for @homePriceOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Draft, submit and track price offer requests'**
  String get homePriceOfferSubtitle;

  /// No description provided for @homeCreateOfferAction.
  ///
  /// In en, this message translates to:
  /// **'Create Offer'**
  String get homeCreateOfferAction;

  /// No description provided for @homePriceOffersAction.
  ///
  /// In en, this message translates to:
  /// **'Price Offers'**
  String get homePriceOffersAction;

  /// No description provided for @homeQuotationTitle.
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get homeQuotationTitle;

  /// No description provided for @homeQuotationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send documents and track customer responses'**
  String get homeQuotationSubtitle;

  /// No description provided for @homeQuotationsAction.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get homeQuotationsAction;

  /// No description provided for @homeSalesOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales Order'**
  String get homeSalesOrderTitle;

  /// No description provided for @homeSalesOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor credit status, holds and fulfilment'**
  String get homeSalesOrderSubtitle;

  /// No description provided for @homeOrdersAction.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get homeOrdersAction;

  /// No description provided for @homeStatsOpenRequestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get homeStatsOpenRequestsLabel;

  /// No description provided for @homeStatsPendingQuotationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending quotations'**
  String get homeStatsPendingQuotationsLabel;

  /// No description provided for @homeStatsDraftPriceOffersLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft price offers'**
  String get homeStatsDraftPriceOffersLabel;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @statusPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get statusPassed;

  /// No description provided for @statusNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get statusNone;

  /// No description provided for @statusReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get statusReleased;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusBelowMin.
  ///
  /// In en, this message translates to:
  /// **'Below min'**
  String get statusBelowMin;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get statusHold;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get statusOnHold;

  /// No description provided for @statusInApproval.
  ///
  /// In en, this message translates to:
  /// **'In approval'**
  String get statusInApproval;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusQuotationGenerated.
  ///
  /// In en, this message translates to:
  /// **'Quotation generated'**
  String get statusQuotationGenerated;

  /// No description provided for @loginOfflineError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Signing in for the first time on this device needs a connection — if you\'ve signed in here before, just reopen the app instead.'**
  String get loginOfflineError;

  /// No description provided for @loginSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your workspace'**
  String get loginSignInTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your Pharamaso account to continue.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginEmailRequiredError;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginPasswordRequiredError;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignInButton;

  /// No description provided for @loginAccessNotice.
  ///
  /// In en, this message translates to:
  /// **'Your access is controlled by your assigned roles and permissions.'**
  String get loginAccessNotice;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Commercial OS'**
  String get loginTagline;

  /// No description provided for @splashCompanyName.
  ///
  /// In en, this message translates to:
  /// **'DAKAHLIA GROUP'**
  String get splashCompanyName;

  /// No description provided for @createOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'New price offer'**
  String get createOfferTitle;

  /// No description provided for @createOfferLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load master data.'**
  String get createOfferLoadError;

  /// No description provided for @createOfferStockLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load warehouse stock.'**
  String get createOfferStockLoadError;

  /// No description provided for @createOfferSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select a customer to continue.'**
  String get createOfferSelectCustomer;

  /// No description provided for @createOfferNoSalesman.
  ///
  /// In en, this message translates to:
  /// **'This customer has no active salesman assignment.'**
  String get createOfferNoSalesman;

  /// No description provided for @createOfferNoActivePriceList.
  ///
  /// In en, this message translates to:
  /// **'There is no active price list right now.'**
  String get createOfferNoActivePriceList;

  /// No description provided for @createOfferSelectItemForLine.
  ///
  /// In en, this message translates to:
  /// **'Select an item for line {lineNumber}.'**
  String createOfferSelectItemForLine(Object lineNumber);

  /// No description provided for @createOfferEnterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity for line {lineNumber}.'**
  String createOfferEnterValidQuantity(Object lineNumber);

  /// No description provided for @createOfferEnterProposedPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a proposed price for line {lineNumber}.'**
  String createOfferEnterProposedPrice(Object lineNumber);

  /// No description provided for @createOfferAddAtLeastOneLine.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line item.'**
  String get createOfferAddAtLeastOneLine;

  /// No description provided for @createOfferDraftCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Price offer draft created.'**
  String get createOfferDraftCreatedSuccess;

  /// No description provided for @createOfferSavedOfflineSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved offline as {serial}. It will sync automatically once you\'re back online.'**
  String createOfferSavedOfflineSuccess(Object serial);

  /// No description provided for @createOfferSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the price offer request.'**
  String get createOfferSubmitError;

  /// No description provided for @createOfferCustomerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer & pricing'**
  String get createOfferCustomerSectionTitle;

  /// No description provided for @createOfferCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get createOfferCustomerLabel;

  /// No description provided for @createOfferAssignedSalesmanLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned salesman'**
  String get createOfferAssignedSalesmanLabel;

  /// No description provided for @createOfferSelectCustomerFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a customer first'**
  String get createOfferSelectCustomerFirst;

  /// No description provided for @createOfferNoActiveSalesmanAssignment.
  ///
  /// In en, this message translates to:
  /// **'No active salesman assignment'**
  String get createOfferNoActiveSalesmanAssignment;

  /// No description provided for @createOfferPriceListLabel.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get createOfferPriceListLabel;

  /// No description provided for @createOfferNoActivePriceListValue.
  ///
  /// In en, this message translates to:
  /// **'No active price list'**
  String get createOfferNoActivePriceListValue;

  /// No description provided for @createOfferNoActivePriceListMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no active price list right now. You cannot create a price offer until one is activated.'**
  String get createOfferNoActivePriceListMessage;

  /// No description provided for @createOfferLineItemsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get createOfferLineItemsSectionTitle;

  /// No description provided for @createOfferAddLineButton.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get createOfferAddLineButton;

  /// No description provided for @createOfferEstimatedValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get createOfferEstimatedValueLabel;

  /// No description provided for @createOfferCreateDraftButton.
  ///
  /// In en, this message translates to:
  /// **'Create draft'**
  String get createOfferCreateDraftButton;

  /// No description provided for @createOfferLineNumber.
  ///
  /// In en, this message translates to:
  /// **'Line {lineNumber}'**
  String createOfferLineNumber(Object lineNumber);

  /// No description provided for @createOfferItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get createOfferItemLabel;

  /// No description provided for @createOfferItemSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or JDE code'**
  String get createOfferItemSearchHint;

  /// No description provided for @createOfferLoadingActivePrice.
  ///
  /// In en, this message translates to:
  /// **'Loading active price…'**
  String get createOfferLoadingActivePrice;

  /// No description provided for @createOfferGuidanceUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get createOfferGuidanceUpcoming;

  /// No description provided for @createOfferGuidanceMin.
  ///
  /// In en, this message translates to:
  /// **'Min (after tax)'**
  String get createOfferGuidanceMin;

  /// No description provided for @createOfferGuidanceBeforeTax.
  ///
  /// In en, this message translates to:
  /// **'Before tax'**
  String get createOfferGuidanceBeforeTax;

  /// No description provided for @createOfferGuidanceTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get createOfferGuidanceTax;

  /// No description provided for @createOfferGuidanceUom.
  ///
  /// In en, this message translates to:
  /// **'UOM'**
  String get createOfferGuidanceUom;

  /// No description provided for @createOfferGuidancePack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get createOfferGuidancePack;

  /// No description provided for @createOfferGuidanceMinPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Min price / Lt or Kg'**
  String get createOfferGuidanceMinPricePerUnit;

  /// No description provided for @createOfferGuidanceInc.
  ///
  /// In en, this message translates to:
  /// **'INC'**
  String get createOfferGuidanceInc;

  /// No description provided for @createOfferGuidanceStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get createOfferGuidanceStarts;

  /// No description provided for @createOfferNoActivePriceForItem.
  ///
  /// In en, this message translates to:
  /// **'No active price for this item — minimum will be validated on submit.'**
  String get createOfferNoActivePriceForItem;

  /// No description provided for @createOfferQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get createOfferQuantityLabel;

  /// No description provided for @createOfferProposedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Proposed price'**
  String get createOfferProposedPriceLabel;

  /// No description provided for @createOfferFocPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'FOC %'**
  String get createOfferFocPercentLabel;

  /// No description provided for @createOfferFocHelperText.
  ///
  /// In en, this message translates to:
  /// **'Flags this line for the approver — does not change price or quantity. The approver adds a separate, price-0 line for the actual free goods.'**
  String get createOfferFocHelperText;

  /// No description provided for @createOfferStockDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The displayed inventory is estimated and not final, and is subject to adjustment and updates.'**
  String get createOfferStockDisclaimer;

  /// No description provided for @createOfferWarehouseStockSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Warehouse stock (display only — no warehouse is assigned here)'**
  String get createOfferWarehouseStockSectionLabel;

  /// No description provided for @createOfferLoadingWarehouseStock.
  ///
  /// In en, this message translates to:
  /// **'Loading warehouse stock…'**
  String get createOfferLoadingWarehouseStock;

  /// No description provided for @createOfferNoWarehouseStock.
  ///
  /// In en, this message translates to:
  /// **'No warehouse stock recorded for this item yet.'**
  String get createOfferNoWarehouseStock;

  /// No description provided for @createOfferStockFromCache.
  ///
  /// In en, this message translates to:
  /// **'Last known stock · {time}'**
  String createOfferStockFromCache(Object time);

  /// No description provided for @createOfferGuidanceFromCache.
  ///
  /// In en, this message translates to:
  /// **'Guidance from last sync'**
  String get createOfferGuidanceFromCache;

  /// No description provided for @createOfferAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get createOfferAvailableLabel;

  /// No description provided for @createOfferWarehouseFallback.
  ///
  /// In en, this message translates to:
  /// **'Warehouse #{warehouseId}'**
  String createOfferWarehouseFallback(Object warehouseId);

  /// No description provided for @createOfferOnHandCommitted.
  ///
  /// In en, this message translates to:
  /// **'On hand {onHand} · Committed {committed}'**
  String createOfferOnHandCommitted(Object onHand, Object committed);

  /// No description provided for @priceOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Price offers'**
  String get priceOffersTitle;

  /// No description provided for @priceOffersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by request # or customer'**
  String get priceOffersSearchHint;

  /// No description provided for @priceOffersClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get priceOffersClearFilters;

  /// No description provided for @priceOffersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load requests.'**
  String get priceOffersLoadError;

  /// No description provided for @priceOffersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No price offer requests yet'**
  String get priceOffersEmptyTitle;

  /// No description provided for @priceOffersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first price offer to get started.'**
  String get priceOffersEmptyMessage;

  /// No description provided for @priceOffersNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get priceOffersNewRequest;

  /// No description provided for @priceOffersStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get priceOffersStatusAll;

  /// No description provided for @priceOffersStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get priceOffersStatusDraft;

  /// No description provided for @priceOffersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get priceOffersStatusPending;

  /// No description provided for @priceOffersStatusInApproval.
  ///
  /// In en, this message translates to:
  /// **'In approval'**
  String get priceOffersStatusInApproval;

  /// No description provided for @priceOffersStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get priceOffersStatusRejected;

  /// No description provided for @priceOffersStatusQuotationGenerated.
  ///
  /// In en, this message translates to:
  /// **'Quotation generated'**
  String get priceOffersStatusQuotationGenerated;

  /// No description provided for @priceOffersNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching requests'**
  String get priceOffersNoMatchTitle;

  /// No description provided for @priceOffersNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter.'**
  String get priceOffersNoMatchMessage;

  /// No description provided for @priceOffersHoldToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Hold to submit'**
  String get priceOffersHoldToSubmit;

  /// No description provided for @priceOffersSubmittedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{requestNumber} submitted for approval.'**
  String priceOffersSubmittedSnackbar(Object requestNumber);

  /// No description provided for @priceOffersFilterByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Filter by customer'**
  String get priceOffersFilterByCustomer;

  /// No description provided for @priceOffersSearchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get priceOffersSearchCustomersHint;

  /// No description provided for @priceOffersNoMatchingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No matching customers.'**
  String get priceOffersNoMatchingCustomers;

  /// No description provided for @priceOffersSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit for approval.'**
  String get priceOffersSubmitFailed;

  /// No description provided for @priceOffersSubmitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval?'**
  String get priceOffersSubmitConfirmTitle;

  /// No description provided for @priceOffersSubmitConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This moves the draft into the approval workflow — you won\'t be able to edit its lines afterward unless it\'s returned.'**
  String get priceOffersSubmitConfirmBody;

  /// No description provided for @priceOffersNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get priceOffersNotNow;

  /// No description provided for @priceOffersSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get priceOffersSubmitButton;

  /// No description provided for @priceOffersSyncNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync offline requests now'**
  String get priceOffersSyncNowTooltip;

  /// No description provided for @priceOffersOfflineQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 request waiting to sync} other{{count} requests waiting to sync}}'**
  String priceOffersOfflineQueueTitle(int count);

  /// No description provided for @priceOffersPendingSyncBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get priceOffersPendingSyncBadge;

  /// No description provided for @priceOffersSyncFailedBadge.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get priceOffersSyncFailedBadge;

  /// No description provided for @priceOffersDiscardDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard offline draft?'**
  String get priceOffersDiscardDraftTitle;

  /// No description provided for @priceOffersDiscardDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes {serial} from this device without ever sending it to the server. This can\'t be undone.'**
  String priceOffersDiscardDraftMessage(Object serial);

  /// No description provided for @priceOffersDiscardDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get priceOffersDiscardDraftConfirm;

  /// No description provided for @requestDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Request detail'**
  String get requestDetailTitle;

  /// No description provided for @requestDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load request.'**
  String get requestDetailLoadError;

  /// No description provided for @requestDetailSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get requestDetailSummaryTitle;

  /// No description provided for @requestDetailCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get requestDetailCustomerLabel;

  /// No description provided for @requestDetailPriceListLabel.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get requestDetailPriceListLabel;

  /// No description provided for @requestDetailPricingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get requestDetailPricingLabel;

  /// No description provided for @requestDetailApprovalLabel.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get requestDetailApprovalLabel;

  /// No description provided for @requestDetailLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get requestDetailLinesTitle;

  /// No description provided for @requestDetailNoLines.
  ///
  /// In en, this message translates to:
  /// **'No lines on this request.'**
  String get requestDetailNoLines;

  /// No description provided for @requestDetailWorkflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval workflow'**
  String get requestDetailWorkflowTitle;

  /// No description provided for @requestDetailNoWorkflow.
  ///
  /// In en, this message translates to:
  /// **'No workflow instance created yet.'**
  String get requestDetailNoWorkflow;

  /// No description provided for @requestDetailActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get requestDetailActionsTitle;

  /// No description provided for @requestDetailQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get requestDetailQuantityLabel;

  /// No description provided for @requestDetailProposedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Proposed price'**
  String get requestDetailProposedPriceLabel;

  /// No description provided for @requestDetailReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (audited change)'**
  String get requestDetailReasonLabel;

  /// No description provided for @requestDetailCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get requestDetailCancelButton;

  /// No description provided for @requestDetailSaveChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Save change'**
  String get requestDetailSaveChangeButton;

  /// No description provided for @requestDetailQtyProposed.
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity} {uom} · Proposed {proposedPrice}'**
  String requestDetailQtyProposed(
    Object quantity,
    Object uom,
    Object proposedPrice,
  );

  /// No description provided for @requestDetailMinSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Min {minimumPrice}'**
  String requestDetailMinSuffix(Object minimumPrice);

  /// No description provided for @requestDetailDiffSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Diff {priceDifference}'**
  String requestDetailDiffSuffix(Object priceDifference);

  /// No description provided for @requestDetailFocLine.
  ///
  /// In en, this message translates to:
  /// **'FOC {focPercent}%'**
  String requestDetailFocLine(Object focPercent);

  /// No description provided for @requestDetailEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get requestDetailEditButton;

  /// No description provided for @requestDetailRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get requestDetailRemoveButton;

  /// No description provided for @requestDetailAddLineButton.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get requestDetailAddLineButton;

  /// No description provided for @requestDetailItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get requestDetailItemLabel;

  /// No description provided for @requestDetailFocPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'FOC % (optional)'**
  String get requestDetailFocPercentLabel;

  /// No description provided for @requestDetailNoActionsDraft.
  ///
  /// In en, this message translates to:
  /// **'No actions available for status \"Draft\".'**
  String get requestDetailNoActionsDraft;

  /// No description provided for @requestDetailSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get requestDetailSubmitButton;

  /// No description provided for @requestDetailCommentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Comments or rejection reason (audited)'**
  String get requestDetailCommentsLabel;

  /// No description provided for @requestDetailApproveStepButton.
  ///
  /// In en, this message translates to:
  /// **'Approve step'**
  String get requestDetailApproveStepButton;

  /// No description provided for @requestDetailReturnStepButton.
  ///
  /// In en, this message translates to:
  /// **'Return step'**
  String get requestDetailReturnStepButton;

  /// No description provided for @requestDetailSkipOptionalButton.
  ///
  /// In en, this message translates to:
  /// **'Skip optional'**
  String get requestDetailSkipOptionalButton;

  /// No description provided for @requestDetailRejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get requestDetailRejectButton;

  /// No description provided for @requestDetailApprovedNoRights.
  ///
  /// In en, this message translates to:
  /// **'Approved — a user with quotation-create rights can generate the PDF quotation.'**
  String get requestDetailApprovedNoRights;

  /// No description provided for @requestDetailGenerateQuotationButton.
  ///
  /// In en, this message translates to:
  /// **'Generate quotation'**
  String get requestDetailGenerateQuotationButton;

  /// No description provided for @requestDetailNoActionsStatus.
  ///
  /// In en, this message translates to:
  /// **'No actions available for status \"{status}\".'**
  String requestDetailNoActionsStatus(Object status);

  /// No description provided for @requestDetailQuotationNoteDraft.
  ///
  /// In en, this message translates to:
  /// **'Download the PDF and send it to the customer — sending marks the quotation SENT and unlocks the customer\'s confirmation link.'**
  String get requestDetailQuotationNoteDraft;

  /// No description provided for @requestDetailQuotationNoteSent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer\'s response. Once they accept, the sales order action becomes available here.'**
  String get requestDetailQuotationNoteSent;

  /// No description provided for @requestDetailQuotationNoteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Customer accepted — create the sales order to hand this quotation to fulfillment.'**
  String get requestDetailQuotationNoteAccepted;

  /// No description provided for @requestDetailQuotationNoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Customer rejected this quotation. Prepare a new price offer if you want to re-quote.'**
  String get requestDetailQuotationNoteRejected;

  /// No description provided for @requestDetailQuotationNoteExpired.
  ///
  /// In en, this message translates to:
  /// **'The quotation\'s validity has passed. Create a new price offer to re-quote.'**
  String get requestDetailQuotationNoteExpired;

  /// No description provided for @requestDetailValidUntil.
  ///
  /// In en, this message translates to:
  /// **' · valid until {date}'**
  String requestDetailValidUntil(Object date);

  /// No description provided for @requestDetailDownloadPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get requestDetailDownloadPdfButton;

  /// No description provided for @requestDetailSendToCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Send to customer'**
  String get requestDetailSendToCustomerButton;

  /// No description provided for @requestDetailCreateSalesOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Create sales order'**
  String get requestDetailCreateSalesOrderButton;

  /// No description provided for @relatedRecordsViewQuotationButton.
  ///
  /// In en, this message translates to:
  /// **'View quotation'**
  String get relatedRecordsViewQuotationButton;

  /// No description provided for @relatedRecordsViewSalesOrderButton.
  ///
  /// In en, this message translates to:
  /// **'View sales order'**
  String get relatedRecordsViewSalesOrderButton;

  /// No description provided for @relatedRecordsViewRequestButton.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get relatedRecordsViewRequestButton;

  /// No description provided for @relatedRecordsNoSalesOrderYet.
  ///
  /// In en, this message translates to:
  /// **'No sales order yet'**
  String get relatedRecordsNoSalesOrderYet;

  /// No description provided for @relatedRecordsSelectSalesOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Select sales order'**
  String get relatedRecordsSelectSalesOrderTitle;

  /// No description provided for @relatedRecordsLoadOrdersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sales orders. Please try again.'**
  String get relatedRecordsLoadOrdersFailed;

  /// No description provided for @relatedRecordsLoadQuotationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the quotation. Please try again.'**
  String get relatedRecordsLoadQuotationFailed;

  /// No description provided for @requestDetailActionFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get requestDetailActionFailedGeneric;

  /// No description provided for @requestDetailUpdateLineFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the line.'**
  String get requestDetailUpdateLineFailed;

  /// No description provided for @requestDetailRemoveLineFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove the line.'**
  String get requestDetailRemoveLineFailed;

  /// No description provided for @requestDetailAddLineFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add the line.'**
  String get requestDetailAddLineFailed;

  /// No description provided for @requestDetailDownloadPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the PDF.'**
  String get requestDetailDownloadPdfFailed;

  /// No description provided for @quotationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get quotationsTitle;

  /// No description provided for @quotationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by quotation # or customer'**
  String get quotationsSearchHint;

  /// No description provided for @quotationsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get quotationsClearFilters;

  /// No description provided for @quotationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load quotations.'**
  String get quotationsLoadError;

  /// No description provided for @quotationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quotations yet'**
  String get quotationsEmptyTitle;

  /// No description provided for @quotationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Approve and convert a price offer to generate one.'**
  String get quotationsEmptyMessage;

  /// No description provided for @quotationsNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching quotations'**
  String get quotationsNoMatchTitle;

  /// No description provided for @quotationsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter.'**
  String get quotationsNoMatchMessage;

  /// No description provided for @quotationsVersionValidUntil.
  ///
  /// In en, this message translates to:
  /// **'v{version} · valid until {validUntil}'**
  String quotationsVersionValidUntil(Object version, Object validUntil);

  /// No description provided for @quotationsFilterByCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by customer'**
  String get quotationsFilterByCustomerTitle;

  /// No description provided for @quotationsSearchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get quotationsSearchCustomersHint;

  /// No description provided for @quotationsNoMatchingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No matching customers.'**
  String get quotationsNoMatchingCustomers;

  /// No description provided for @quotationDetailSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Quotation sent to the customer.'**
  String get quotationDetailSentMessage;

  /// No description provided for @quotationDetailOrderCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sales order created.'**
  String get quotationDetailOrderCreatedMessage;

  /// No description provided for @quotationDetailActionDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get quotationDetailActionDoneMessage;

  /// No description provided for @quotationDetailActionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get quotationDetailActionFailedMessage;

  /// No description provided for @quotationDetailPdfDownloadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the PDF.'**
  String get quotationDetailPdfDownloadFailedMessage;

  /// No description provided for @quotationDetailSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get quotationDetailSummaryTitle;

  /// No description provided for @quotationDetailCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get quotationDetailCustomerLabel;

  /// No description provided for @quotationDetailPaymentTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment terms'**
  String get quotationDetailPaymentTermsLabel;

  /// No description provided for @quotationDetailCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get quotationDetailCurrencyLabel;

  /// No description provided for @quotationDetailValidUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get quotationDetailValidUntilLabel;

  /// No description provided for @quotationDetailValidUntilWithDays.
  ///
  /// In en, this message translates to:
  /// **'{validUntil} ({days} days)'**
  String quotationDetailValidUntilWithDays(Object validUntil, Object days);

  /// No description provided for @quotationDetailLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lines (v{version})'**
  String quotationDetailLinesTitle(Object version);

  /// No description provided for @quotationDetailNoLines.
  ///
  /// In en, this message translates to:
  /// **'No line details available for this version.'**
  String get quotationDetailNoLines;

  /// No description provided for @quotationDetailItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item #{itemId}'**
  String quotationDetailItemFallback(Object itemId);

  /// No description provided for @quotationDetailQtyPriceLine.
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity} {uom} · Price {price}'**
  String quotationDetailQtyPriceLine(Object quantity, Object uom, Object price);

  /// No description provided for @quotationDetailFocSuffix.
  ///
  /// In en, this message translates to:
  /// **' · FOC {focQuantity} {focUom}'**
  String quotationDetailFocSuffix(Object focQuantity, Object focUom);

  /// No description provided for @quotationDetailActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get quotationDetailActionsTitle;

  /// No description provided for @quotationDetailDownloadPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get quotationDetailDownloadPdfButton;

  /// No description provided for @quotationDetailSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send to customer'**
  String get quotationDetailSendButton;

  /// No description provided for @quotationDetailReleasedRemainingLine.
  ///
  /// In en, this message translates to:
  /// **'Released {released} · Remaining {remaining}'**
  String quotationDetailReleasedRemainingLine(
    Object released,
    Object remaining,
  );

  /// No description provided for @quotationDetailReleaseSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Release into a sales order'**
  String get quotationDetailReleaseSectionTitle;

  /// No description provided for @quotationDetailReleaseNotePartial.
  ///
  /// In en, this message translates to:
  /// **'Release any part of a line\'s remaining quantity — the rest stays open on the quotation for a later release.'**
  String get quotationDetailReleaseNotePartial;

  /// No description provided for @quotationDetailReleaseNoteFullOnly.
  ///
  /// In en, this message translates to:
  /// **'Partial release is disabled — every open line releases together, at its full remaining quantity, in one sales order.'**
  String get quotationDetailReleaseNoteFullOnly;

  /// No description provided for @quotationDetailNoReleasableLines.
  ///
  /// In en, this message translates to:
  /// **'Every line is fully released — nothing left to release.'**
  String get quotationDetailNoReleasableLines;

  /// No description provided for @quotationDetailRemainingLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Remaining {remaining} {uom}'**
  String quotationDetailRemainingLabelValue(Object remaining, Object uom);

  /// No description provided for @quotationDetailReleaseQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Release qty'**
  String get quotationDetailReleaseQtyLabel;

  /// No description provided for @quotationDetailWarehouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get quotationDetailWarehouseLabel;

  /// No description provided for @quotationDetailFillFullRemainingButton.
  ///
  /// In en, this message translates to:
  /// **'Fill full remaining quantity'**
  String get quotationDetailFillFullRemainingButton;

  /// No description provided for @quotationDetailReleaseButton.
  ///
  /// In en, this message translates to:
  /// **'Release into sales order'**
  String get quotationDetailReleaseButton;

  /// No description provided for @quotationDetailReleaseButtonFullOnly.
  ///
  /// In en, this message translates to:
  /// **'Release full quotation into sales order'**
  String get quotationDetailReleaseButtonFullOnly;

  /// No description provided for @salesOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales orders'**
  String get salesOrdersTitle;

  /// No description provided for @salesOrdersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by order # or customer'**
  String get salesOrdersSearchHint;

  /// No description provided for @salesOrdersClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get salesOrdersClearFilters;

  /// No description provided for @salesOrdersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sales orders.'**
  String get salesOrdersLoadError;

  /// No description provided for @salesOrdersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get salesOrdersEmptyTitle;

  /// No description provided for @salesOrdersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Convert an accepted quotation into an order.'**
  String get salesOrdersEmptyMessage;

  /// No description provided for @salesOrdersNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching orders'**
  String get salesOrdersNoMatchTitle;

  /// No description provided for @salesOrdersNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter.'**
  String get salesOrdersNoMatchMessage;

  /// No description provided for @salesOrdersReleasingLabel.
  ///
  /// In en, this message translates to:
  /// **'Releasing…'**
  String get salesOrdersReleasingLabel;

  /// No description provided for @salesOrdersReleaseHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Release hold'**
  String get salesOrdersReleaseHoldLabel;

  /// No description provided for @salesOrdersHoldReleasedMessage.
  ///
  /// In en, this message translates to:
  /// **'Hold released.'**
  String get salesOrdersHoldReleasedMessage;

  /// No description provided for @salesOrdersReleaseHoldError.
  ///
  /// In en, this message translates to:
  /// **'Failed to release hold.'**
  String get salesOrdersReleaseHoldError;

  /// No description provided for @salesOrdersFilterByCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by customer'**
  String get salesOrdersFilterByCustomerTitle;

  /// No description provided for @salesOrdersSearchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get salesOrdersSearchCustomersHint;

  /// No description provided for @salesOrdersNoMatchingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No matching customers.'**
  String get salesOrdersNoMatchingCustomers;

  /// No description provided for @salesOrderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order detail'**
  String get salesOrderDetailTitle;

  /// No description provided for @salesOrderDetailHoldReleasedMessage.
  ///
  /// In en, this message translates to:
  /// **'Hold released.'**
  String get salesOrderDetailHoldReleasedMessage;

  /// No description provided for @salesOrderDetailReleaseHoldError.
  ///
  /// In en, this message translates to:
  /// **'Failed to release hold.'**
  String get salesOrderDetailReleaseHoldError;

  /// No description provided for @salesOrderDetailWarehouseFallback.
  ///
  /// In en, this message translates to:
  /// **'Warehouse #{id}'**
  String salesOrderDetailWarehouseFallback(Object id);

  /// No description provided for @salesOrderDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order.'**
  String get salesOrderDetailLoadError;

  /// No description provided for @salesOrderDetailSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get salesOrderDetailSummaryTitle;

  /// No description provided for @salesOrderDetailCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get salesOrderDetailCustomerLabel;

  /// No description provided for @salesOrderDetailWarehouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get salesOrderDetailWarehouseLabel;

  /// No description provided for @salesOrderDetailQuotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get salesOrderDetailQuotationLabel;

  /// No description provided for @salesOrderDetailOrderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order date'**
  String get salesOrderDetailOrderDateLabel;

  /// No description provided for @salesOrderDetailJdeOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'JDE order #'**
  String get salesOrderDetailJdeOrderLabel;

  /// No description provided for @salesOrderDetailCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get salesOrderDetailCreditLabel;

  /// No description provided for @salesOrderDetailHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get salesOrderDetailHoldLabel;

  /// No description provided for @salesOrderDetailSplitOriginTitle.
  ///
  /// In en, this message translates to:
  /// **'Split origin'**
  String get salesOrderDetailSplitOriginTitle;

  /// No description provided for @salesOrderDetailSplitOriginMessage.
  ///
  /// In en, this message translates to:
  /// **'This is execution order #{splitSequence} of a value-capped split. The original order is {originalOrderNumber}.'**
  String salesOrderDetailSplitOriginMessage(
    Object splitSequence,
    Object originalOrderNumber,
  );

  /// No description provided for @salesOrderDetailViewOriginalOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'View order before splitting'**
  String get salesOrderDetailViewOriginalOrderLabel;

  /// No description provided for @salesOrderDetailLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get salesOrderDetailLinesTitle;

  /// No description provided for @salesOrderDetailNoLinesMessage.
  ///
  /// In en, this message translates to:
  /// **'No lines on this order.'**
  String get salesOrderDetailNoLinesMessage;

  /// No description provided for @salesOrderDetailItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item #{itemId}'**
  String salesOrderDetailItemFallback(Object itemId);

  /// No description provided for @salesOrderDetailQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity} {uom}'**
  String salesOrderDetailQtyLabel(Object quantity, Object uom);

  /// No description provided for @salesOrderDetailFocLabel.
  ///
  /// In en, this message translates to:
  /// **'FOC {focQuantity}'**
  String salesOrderDetailFocLabel(Object focQuantity);

  /// No description provided for @salesOrderDetailUnitPriceBeforeTax.
  ///
  /// In en, this message translates to:
  /// **'Unit price before tax {value}'**
  String salesOrderDetailUnitPriceBeforeTax(Object value);

  /// No description provided for @salesOrderDetailTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'{rate}% tax'**
  String salesOrderDetailTaxRateLabel(Object rate);

  /// No description provided for @salesOrderDetailNoTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'No tax'**
  String get salesOrderDetailNoTaxLabel;

  /// No description provided for @salesOrderDetailUnitPriceAfterTax.
  ///
  /// In en, this message translates to:
  /// **'Unit price after tax {value}'**
  String salesOrderDetailUnitPriceAfterTax(Object value);

  /// No description provided for @salesOrderDetailLineTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Line total (after tax): {total}'**
  String salesOrderDetailLineTotalLabel(Object total);

  /// No description provided for @salesOrderDetailOrderTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Order total (after tax)'**
  String get salesOrderDetailOrderTotalLabel;

  /// No description provided for @salesOrderDetailHoldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Holds'**
  String get salesOrderDetailHoldsTitle;

  /// No description provided for @salesOrderDetailHoldTypeFallback.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get salesOrderDetailHoldTypeFallback;

  /// No description provided for @salesOrderDetailReleaseHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Release hold'**
  String get salesOrderDetailReleaseHoldLabel;

  /// No description provided for @widgetsNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get widgetsNotificationsTooltip;

  /// No description provided for @widgetsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get widgetsNotificationsTitle;

  /// No description provided for @widgetsNewNotificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String widgetsNewNotificationsCount(Object count);

  /// No description provided for @widgetsMarkAllReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get widgetsMarkAllReadButton;

  /// No description provided for @widgetsNoNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get widgetsNoNotificationsTitle;

  /// No description provided for @widgetsNoNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see updates about your price offers and orders here.'**
  String get widgetsNoNotificationsMessage;

  /// No description provided for @widgetsTryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get widgetsTryAgainButton;

  /// No description provided for @widgetsRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String widgetsRejectedReason(Object reason);

  /// No description provided for @itemPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select item'**
  String get itemPickerTitle;

  /// No description provided for @itemPickerNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get itemPickerNoMatches;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
