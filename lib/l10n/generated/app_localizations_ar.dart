// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonAppName => 'PharmaSo';

  @override
  String get commonLanguageTooltip => 'اللغة';

  @override
  String get connectionTooltipGood => 'الاتصال: جيد';

  @override
  String get connectionTooltipUnstable => 'الاتصال: غير مستقر';

  @override
  String get connectionTooltipOffline => 'الاتصال: غير متوفر';

  @override
  String get connectionGoodTitle => 'الاتصال جيد';

  @override
  String get connectionGoodMessage => 'أنت متصل بالإنترنت وبالخادم بنجاح.';

  @override
  String get connectionUnstableTitle => 'الاتصال غير مستقر';

  @override
  String get connectionUnstableMessage =>
      'أنت متصل بالإنترنت، لكن الاتصال بالخادم بطيء أو متقطع. قد تستغرق بعض العمليات وقتاً أطول أو تحتاج لإعادة المحاولة.';

  @override
  String get connectionOfflineTitle => 'غير متصل بالإنترنت';

  @override
  String get connectionOfflineMessage =>
      'لا يوجد اتصال بالشبكة، أو تعذر الوصول إلى الخادم. تحقق من شبكة الواي فاي أو بيانات الجوال.';

  @override
  String get connectionNetworkLabel => 'الشبكة';

  @override
  String get connectionNetworkConnected => 'متصلة';

  @override
  String get connectionNetworkDisconnected => 'غير متصلة';

  @override
  String get connectionServerLabel => 'الخادم';

  @override
  String get connectionServerReachable => 'يمكن الوصول إليه';

  @override
  String get connectionServerUnreachable => 'لا يمكن الوصول إليه';

  @override
  String get connectionLatencyLabel => 'زمن الاستجابة';

  @override
  String connectionLatencyValue(Object ms) {
    return '$ms مللي ثانية';
  }

  @override
  String get connectionLastCheckedLabel => 'آخر فحص';

  @override
  String get connectionCheckingLabel => 'جارٍ الفحص…';

  @override
  String get connectionCheckAgainButton => 'إعادة الفحص';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'طاب نهارك';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String get homeSignOutTooltip => 'تسجيل الخروج';

  @override
  String get syncStatusSyncing => 'جارٍ مزامنة الطلبات غير المتصلة…';

  @override
  String get syncStatusNeverSynced => 'لم تتم المزامنة بعد';

  @override
  String syncStatusLastSuccess(Object time) {
    return 'تمت مزامنة جميع الطلبات غير المتصلة $time';
  }

  @override
  String syncStatusLastFailed(Object time) {
    return 'حدث خطأ في آخر مزامنة $time';
  }

  @override
  String syncStatusLastOffline(Object time) {
    return 'فشلت آخر محاولة مزامنة $time — لا يوجد اتصال';
  }

  @override
  String syncStatusPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلبات بانتظار المزامنة',
      one: 'طلب واحد بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusShortSyncing => 'جارٍ المزامنة…';

  @override
  String get syncStatusShortNever => 'لم تتم المزامنة';

  @override
  String get syncStatusShortFailed => 'خطأ مزامنة';

  @override
  String get syncStatusShortOffline => 'غير متصل';

  @override
  String syncStatusShortPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بانتظار $count',
      one: 'بانتظار 1',
    );
    return '$_temp0';
  }

  @override
  String get syncDialogTitle => 'مزامنة البيانات';

  @override
  String get syncDialogRunningTitle => 'جاري المزامنة…';

  @override
  String get syncDialogResultSuccessTitle => 'اكتملت المزامنة';

  @override
  String get syncDialogResultPartialTitle => 'تمت المزامنة مع بعض المشاكل';

  @override
  String get syncDialogCancel => 'إلغاء';

  @override
  String get syncDialogSyncNow => 'مزامنة الآن';

  @override
  String get syncDialogClose => 'إغلاق';

  @override
  String get syncDialogConfirmIntro => 'سيقوم هذا بما يلي:';

  @override
  String syncDialogConfirmUpload(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رفع $count من عروض الأسعار غير المتصلة بانتظار المزامنة',
      one: 'رفع عرض سعر واحد غير متصل بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String get syncDialogConfirmReferenceData =>
      'تحديث العملاء والمخازن والأصناف وقوائم الأسعار ورصيد المستودعات';

  @override
  String get syncDialogConfirmRecords =>
      'تحديث طلبات عروض الأسعار وعروض الأسعار وأوامر البيع الخاصة بك';

  @override
  String get syncDialogStepUpload => 'جاري رفع عروض الأسعار غير المتصلة';

  @override
  String get syncDialogStepReferenceData =>
      'العملاء والمخازن والأصناف وقوائم الأسعار';

  @override
  String get syncDialogStepOfflineReadiness =>
      'تجهيز أرقام الطلبات غير المتصلة';

  @override
  String get syncDialogStepEffectivePrices => 'الأسعار الفعلية';

  @override
  String get syncDialogStepWarehouseStock => 'رصيد المستودعات';

  @override
  String get syncDialogStepPriceOfferRequests => 'طلبات عروض الأسعار';

  @override
  String get syncDialogStepQuotations => 'عروض الأسعار';

  @override
  String get syncDialogStepSalesOrders => 'أوامر البيع';

  @override
  String get homePriceOfferTitle => 'عرض السعر';

  @override
  String get homePriceOfferSubtitle =>
      'إنشاء وتقديم ومتابعة طلبات عروض الأسعار';

  @override
  String get homeCreateOfferAction => 'إنشاء عرض';

  @override
  String get homePriceOffersAction => 'عروض الأسعار';

  @override
  String get homeQuotationTitle => 'عرض الأسعار الرسمي';

  @override
  String get homeQuotationSubtitle => 'إرسال المستندات ومتابعة ردود العملاء';

  @override
  String get homeQuotationsAction => 'العروض الرسمية';

  @override
  String get homeSalesOrderTitle => 'أمر البيع';

  @override
  String get homeSalesOrderSubtitle =>
      'متابعة حالة الائتمان والتعليقات والتنفيذ';

  @override
  String get homeOrdersAction => 'الطلبات';

  @override
  String get homeStatsOpenRequestsLabel => 'طلبات مفتوحة';

  @override
  String get homeStatsPendingQuotationsLabel => 'عروض أسعار معلقة';

  @override
  String get homeStatsDraftPriceOffersLabel => 'عروض أسعار غير مكتملة';

  @override
  String get statusApproved => 'معتمد';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusOk => 'سليم';

  @override
  String get statusPassed => 'ناجح';

  @override
  String get statusNone => 'بدون';

  @override
  String get statusReleased => 'تم الإفراج';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusBelowMin => 'أقل من الحد الأدنى';

  @override
  String get statusExpired => 'منتهي الصلاحية';

  @override
  String get statusFailed => 'فشل';

  @override
  String get statusHold => 'موقوف';

  @override
  String get statusOnHold => 'قيد الإيقاف';

  @override
  String get statusInApproval => 'قيد الموافقة';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusSent => 'تم الإرسال';

  @override
  String get statusSkipped => 'تم التخطي';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusQuotationGenerated => 'عرض سعر جاهز';

  @override
  String get loginOfflineError =>
      'لا يوجد اتصال بالإنترنت. يتطلب تسجيل الدخول لأول مرة على هذا الجهاز اتصالاً — إذا سبق أن سجّلت الدخول هنا من قبل، فقط أعد فتح التطبيق.';

  @override
  String get loginSubtitle => 'استخدم حساب PharmaSo الخاص بك للمتابعة.';

  @override
  String get loginEmailLabel => 'كود الموظف';

  @override
  String get loginEmailRequiredError => 'كود الموظف مطلوب';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginPasswordHint => 'كلمة المرور الخاصة بك';

  @override
  String get loginPasswordRequiredError => 'كلمة المرور مطلوبة';

  @override
  String get loginRememberMe => 'تذكرني';

  @override
  String get loginSignInButton => 'تسجيل الدخول';

  @override
  String get loginAccessNotice =>
      'صلاحيات الوصول الخاصة بك تخضع للأدوار والصلاحيات المسندة إليك.';

  @override
  String get splashCompanyName => 'مجموعة دقهلية';

  @override
  String get createOfferTitle => 'عرض سعر جديد';

  @override
  String get createOfferLoadError => 'فشل تحميل البيانات الأساسية.';

  @override
  String get createOfferStockLoadError => 'فشل تحميل رصيد المستودع.';

  @override
  String get createOfferSelectCustomer => 'يرجى اختيار عميل للمتابعة.';

  @override
  String get createOfferNoSalesman =>
      'لا يوجد مندوب مبيعات نشط مسند لهذا العميل.';

  @override
  String get createOfferNoActivePriceList => 'لا توجد قائمة أسعار نشطة حالياً.';

  @override
  String createOfferSelectItemForLine(Object lineNumber) {
    return 'يرجى اختيار صنف للسطر $lineNumber.';
  }

  @override
  String createOfferEnterValidQuantity(Object lineNumber) {
    return 'يرجى إدخال كمية صحيحة للسطر $lineNumber.';
  }

  @override
  String createOfferEnterProposedPrice(Object lineNumber) {
    return 'يرجى إدخال السعر المقترح للسطر $lineNumber.';
  }

  @override
  String get createOfferAddAtLeastOneLine => 'يرجى إضافة سطر واحد على الأقل.';

  @override
  String get createOfferDraftCreatedSuccess =>
      'تم إنشاء مسودة عرض السعر بنجاح.';

  @override
  String createOfferSavedOfflineSuccess(Object serial) {
    return 'تم الحفظ دون اتصال برقم $serial. ستتم المزامنة تلقائيًا عند عودة الاتصال.';
  }

  @override
  String get createOfferSubmitError => 'فشل إنشاء طلب عرض السعر.';

  @override
  String get createOfferCustomerSectionTitle => 'العميل والتسعير';

  @override
  String get createOfferCustomerLabel => 'العميل';

  @override
  String get createOfferAssignedSalesmanLabel => 'مندوب المبيعات المسند';

  @override
  String get createOfferSelectCustomerFirst => 'يرجى اختيار عميل أولاً';

  @override
  String get createOfferNoActiveSalesmanAssignment =>
      'لا يوجد مندوب مبيعات نشط مسند';

  @override
  String get createOfferPriceListLabel => 'قائمة الأسعار';

  @override
  String get createOfferNoActivePriceListValue => 'لا توجد قائمة أسعار نشطة';

  @override
  String get createOfferNoActivePriceListMessage =>
      'لا توجد قائمة أسعار نشطة حالياً. لا يمكن إنشاء عرض سعر حتى يتم تفعيل قائمة أسعار.';

  @override
  String get createOfferLineItemsSectionTitle => 'بنود الأصناف';

  @override
  String createOfferLineItemsSectionTitleWithCount(int count) {
    return 'بنود الأصناف ($count)';
  }

  @override
  String get createOfferAddLineButton => 'إضافة سطر';

  @override
  String get createOfferEstimatedValueLabel => 'القيمة التقديرية';

  @override
  String get createOfferCreateDraftButton => 'إنشاء مسودة';

  @override
  String createOfferLineNumber(Object lineNumber) {
    return 'السطر $lineNumber';
  }

  @override
  String get createOfferItemLabel => 'الصنف';

  @override
  String get createOfferItemSearchHint => 'ابحث بالاسم أو كود JDE';

  @override
  String get createOfferLoadingActivePrice => 'جاري تحميل السعر النشط…';

  @override
  String get createOfferGuidanceUpcoming => 'قادم';

  @override
  String get createOfferGuidanceMin => 'الحد الأدنى (شامل الضريبة)';

  @override
  String get createOfferGuidanceBeforeTax => 'قبل الضريبة';

  @override
  String get createOfferGuidanceTax => 'الضريبة';

  @override
  String get createOfferGuidanceUom => 'وحدة القياس';

  @override
  String get createOfferGuidancePack => 'العبوة';

  @override
  String get createOfferGuidanceMinPricePerUnit => 'أقل سعر / لتر أو كجم';

  @override
  String get createOfferGuidanceInc => 'نسبة التحفيز';

  @override
  String get createOfferGuidanceStarts => 'تاريخ البدء';

  @override
  String get createOfferNoActivePriceForItem =>
      'لا يوجد سعر نشط لهذا الصنف — سيتم التحقق من الحد الأدنى عند الإرسال.';

  @override
  String get createOfferQuantityLabel => 'الكمية';

  @override
  String get createOfferProposedPriceLabel => 'السعر المقترح';

  @override
  String get createOfferFocPercentLabel => 'نسبة التخفيض %';

  @override
  String get createOfferFocHelperText =>
      'علامة توضيحية للمعتمد فقط — لا تغيّر السعر أو الكمية. يقوم المعتمد بإضافة سطر منفصل بسعر صفر للكميةالتخفيض الفعلية.';

  @override
  String get createOfferStockDisclaimer =>
      'كميات المخزون المعروضة تقديرية وغير نهائية، وقابلة للتعديل والتحديث.';

  @override
  String get createOfferWarehouseStockSectionLabel =>
      'رصيد المستودع (للعرض فقط — لا يتم تحديد مستودع هنا)';

  @override
  String get createOfferLoadingWarehouseStock => 'جاري تحميل رصيد المستودع…';

  @override
  String get createOfferNoWarehouseStock =>
      'لا يوجد رصيد مستودع مسجل لهذا الصنف حتى الآن.';

  @override
  String createOfferStockFromCache(Object time) {
    return 'آخر رصيد معروف · $time';
  }

  @override
  String get createOfferGuidanceFromCache => 'إرشادات من آخر مزامنة';

  @override
  String get createOfferAvailableLabel => 'المتاح';

  @override
  String createOfferWarehouseFallback(Object warehouseId) {
    return 'مستودع رقم $warehouseId';
  }

  @override
  String createOfferOnHandCommitted(Object onHand, Object committed) {
    return 'الموجود $onHand · المرتبط $committed';
  }

  @override
  String get priceOffersTitle => 'عروض الأسعار';

  @override
  String get priceOffersSearchHint => 'ابحث برقم الطلب أو اسم العميل';

  @override
  String get priceOffersClearFilters => 'مسح عوامل التصفية';

  @override
  String get priceOffersLoadError => 'تعذر تحميل الطلبات.';

  @override
  String get priceOffersEmptyTitle => 'لا توجد طلبات عروض أسعار بعد';

  @override
  String get priceOffersEmptyMessage => 'أنشئ أول عرض سعر لك للبدء.';

  @override
  String get priceOffersNewRequest => 'طلب جديد';

  @override
  String get priceOffersStatusAll => 'الكل';

  @override
  String get priceOffersStatusDraft => 'مسودة';

  @override
  String get priceOffersStatusOpenRequests => 'طلبات مفتوحة';

  @override
  String get priceOffersStatusPending => 'قيد الانتظار';

  @override
  String get priceOffersStatusInApproval => 'قيد الموافقة';

  @override
  String get priceOffersStatusRejected => 'مرفوض';

  @override
  String get priceOffersStatusQuotationGenerated => 'عروض الاسعار الجاهزه';

  @override
  String get priceOffersNoMatchTitle => 'لا توجد طلبات مطابقة';

  @override
  String get priceOffersNoMatchMessage => 'جرّب تصفية مختلفة.';

  @override
  String get priceOffersHoldToSubmit => 'اضغط مطولاً للإرسال';

  @override
  String priceOffersSubmittedSnackbar(Object requestNumber) {
    return 'تم إرسال $requestNumber للموافقة.';
  }

  @override
  String get priceOffersFilterByCustomer => 'تصفية حسب العميل';

  @override
  String get priceOffersSearchCustomersHint => 'ابحث عن عملاء';

  @override
  String get priceOffersNoMatchingCustomers => 'لا يوجد عملاء مطابقون.';

  @override
  String get priceOffersSubmitFailed => 'تعذر إرسال الطلب للموافقة.';

  @override
  String get priceOffersSubmitConfirmTitle => 'إرسال للموافقة؟';

  @override
  String get priceOffersSubmitConfirmBody =>
      'سينقل هذا المسودة إلى مسار الموافقة — لن تتمكن من تعديل بنودها بعد ذلك إلا إذا تمت إعادتها.';

  @override
  String get priceOffersNotNow => 'ليس الآن';

  @override
  String get priceOffersSubmitButton => 'إرسال';

  @override
  String get priceOffersSyncNowTooltip => 'مزامنة الطلبات غير المتصلة الآن';

  @override
  String priceOffersOfflineQueueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلبات بانتظار المزامنة',
      one: 'طلب واحد بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String get priceOffersPendingSyncBadge => 'بانتظار المزامنة';

  @override
  String get priceOffersSyncFailedBadge => 'فشلت المزامنة';

  @override
  String get priceOffersDiscardDraftTitle => 'تجاهل المسودة غير المتصلة؟';

  @override
  String priceOffersDiscardDraftMessage(Object serial) {
    return 'سيؤدي هذا إلى حذف $serial من هذا الجهاز دون إرساله إلى الخادم إطلاقًا. لا يمكن التراجع عن هذا.';
  }

  @override
  String get priceOffersDiscardDraftConfirm => 'تجاهل';

  @override
  String get requestDetailTitle => 'تفاصيل الطلب';

  @override
  String get requestDetailLoadError => 'تعذر تحميل الطلب.';

  @override
  String get requestDetailSummaryTitle => 'ملخص';

  @override
  String get requestDetailCustomerLabel => 'العميل';

  @override
  String get requestDetailPriceListLabel => 'قائمة الأسعار';

  @override
  String get requestDetailPricingLabel => 'التسعير';

  @override
  String get requestDetailApprovalLabel => 'الموافقة';

  @override
  String get requestDetailLinesTitle => 'البنود';

  @override
  String requestDetailLinesTitleWithCount(int count) {
    return 'البنود ($count)';
  }

  @override
  String requestDetailLineTotalLabel(Object total) {
    return 'إجمالي البند: $total';
  }

  @override
  String get requestDetailLinesTotalLabel => 'إجمالي البنود';

  @override
  String get requestDetailNoLines => 'لا توجد بنود في هذا الطلب.';

  @override
  String get requestDetailWorkflowTitle => 'مسار الموافقة';

  @override
  String get requestDetailNoWorkflow => 'لم يتم إنشاء مسار موافقة بعد.';

  @override
  String get requestDetailActionsTitle => 'الإجراءات';

  @override
  String get requestDetailQuantityLabel => 'الكمية';

  @override
  String get requestDetailProposedPriceLabel => 'السعر المقترح';

  @override
  String get requestDetailReasonLabel => 'السبب (تغيير مسجَّل)';

  @override
  String get requestDetailCancelButton => 'إلغاء';

  @override
  String get requestDetailSaveChangeButton => 'حفظ التغيير';

  @override
  String requestDetailQtyProposed(
    Object quantity,
    Object uom,
    Object proposedPrice,
  ) {
    return 'الكمية $quantity $uom · المقترح $proposedPrice';
  }

  @override
  String requestDetailMinSuffix(Object minimumPrice) {
    return ' · الحد الأدنى $minimumPrice';
  }

  @override
  String requestDetailDiffSuffix(Object priceDifference) {
    return ' · الفرق $priceDifference';
  }

  @override
  String requestDetailFocLine(Object focPercent) {
    return 'مجاني $focPercent%';
  }

  @override
  String get requestDetailEditButton => 'تعديل';

  @override
  String get requestDetailRemoveButton => 'إزالة';

  @override
  String get requestDetailAddLineButton => 'إضافة بند';

  @override
  String get requestDetailItemLabel => 'الصنف';

  @override
  String get requestDetailFocPercentLabel => 'نسبة التخفيض % (اختياري)';

  @override
  String get requestDetailNoActionsDraft =>
      'لا توجد إجراءات متاحة لحالة \"مسودة\".';

  @override
  String get requestDetailSubmitButton => 'إرسال للموافقة';

  @override
  String get requestDetailCommentsLabel => 'ملاحظات أو سبب الرفض (مسجَّل)';

  @override
  String get requestDetailApproveStepButton => 'اعتماد الخطوة';

  @override
  String get requestDetailReturnStepButton => 'إعادة الخطوة';

  @override
  String get requestDetailSkipOptionalButton => 'تخطي (اختياري)';

  @override
  String get requestDetailRejectButton => 'رفض';

  @override
  String get requestDetailApprovedNoRights =>
      'تمت الموافقة — يمكن لمستخدم لديه صلاحية إنشاء عروض الأسعار إصدار ملف PDF لعرض السعر.';

  @override
  String get requestDetailGenerateQuotationButton => 'إصدار عرض السعر';

  @override
  String requestDetailNoActionsStatus(Object status) {
    return 'لا توجد إجراءات متاحة لحالة \"$status\".';
  }

  @override
  String get requestDetailQuotationNoteDraft =>
      'قم بتنزيل ملف PDF وإرساله إلى العميل — سيؤدي الإرسال إلى تحديث حالة عرض السعر إلى \"تم الإرسال\" وإتاحة رابط تأكيد العميل.';

  @override
  String get requestDetailQuotationNoteSent =>
      'في انتظار رد العميل. بمجرد موافقته، سيصبح إجراء إنشاء أمر البيع متاحاً هنا.';

  @override
  String get requestDetailQuotationNoteAccepted =>
      'وافق العميل — قم بإنشاء أمر البيع لتحويل عرض السعر هذا إلى التنفيذ.';

  @override
  String get requestDetailQuotationNoteRejected =>
      'رفض العميل عرض السعر هذا. أعد إنشاء عرض سعر جديد إذا رغبت في إعادة التسعير.';

  @override
  String get requestDetailQuotationNoteExpired =>
      'انتهت صلاحية عرض السعر. أنشئ عرض سعر جديداً لإعادة التسعير.';

  @override
  String requestDetailValidUntil(Object date) {
    return ' · صالح حتى $date';
  }

  @override
  String get requestDetailDownloadPdfButton => 'تنزيل PDF';

  @override
  String get requestDetailSendToCustomerButton => 'إرسال إلى العميل';

  @override
  String get requestDetailCreateSalesOrderButton => 'إنشاء أمر بيع';

  @override
  String get relatedRecordsViewQuotationButton => 'عرض عرض السعر';

  @override
  String get relatedRecordsViewSalesOrderButton => 'عرض أمر البيع';

  @override
  String get relatedRecordsViewRequestButton => 'عرض طلب عرض السعر';

  @override
  String get relatedRecordsNoSalesOrderYet => 'لا يوجد أمر بيع بعد';

  @override
  String get relatedRecordsSelectSalesOrderTitle => 'اختر أمر البيع';

  @override
  String get relatedRecordsLoadOrdersFailed =>
      'تعذر تحميل أوامر البيع. يرجى المحاولة مرة أخرى.';

  @override
  String get relatedRecordsLoadQuotationFailed =>
      'تعذر تحميل عرض السعر. يرجى المحاولة مرة أخرى.';

  @override
  String get requestDetailActionFailedGeneric =>
      'فشل الإجراء. يرجى المحاولة مرة أخرى.';

  @override
  String get requestDetailUpdateLineFailed => 'تعذر تحديث البند.';

  @override
  String get requestDetailRemoveLineFailed => 'تعذر إزالة البند.';

  @override
  String get requestDetailAddLineFailed => 'تعذر إضافة البند.';

  @override
  String get requestDetailDownloadPdfFailed => 'تعذر تنزيل ملف PDF.';

  @override
  String get quotationsTitle => 'عروض الأسعار المعتمدة';

  @override
  String get quotationsSearchHint => 'ابحث برقم عرض السعر أو اسم العميل';

  @override
  String get quotationsClearFilters => 'مسح عوامل التصفية';

  @override
  String get quotationsLoadError => 'تعذر تحميل عروض الأسعار.';

  @override
  String get quotationsEmptyTitle => 'لا توجد عروض أسعار بعد';

  @override
  String get quotationsEmptyMessage =>
      'اعتمد أحد عروض التسعير وحوّله لإنشاء عرض سعر.';

  @override
  String get quotationsNoMatchTitle => 'لا توجد عروض أسعار مطابقة';

  @override
  String get quotationsNoMatchMessage => 'جرّب معايير تصفية مختلفة.';

  @override
  String quotationsVersionValidUntil(Object version, Object validUntil) {
    return 'الإصدار $version · صالح حتى $validUntil';
  }

  @override
  String get quotationsFilterByCustomerTitle => 'تصفية حسب العميل';

  @override
  String get quotationsSearchCustomersHint => 'ابحث عن عميل';

  @override
  String get quotationsNoMatchingCustomers => 'لا يوجد عملاء مطابقون.';

  @override
  String get quotationDetailSentMessage => 'تم إرسال عرض السعر إلى العميل.';

  @override
  String get quotationDetailOrderCreatedMessage => 'تم إنشاء أمر البيع.';

  @override
  String get quotationDetailActionDoneMessage => 'تم بنجاح.';

  @override
  String get quotationDetailActionFailedMessage =>
      'فشلت العملية. يرجى المحاولة مرة أخرى.';

  @override
  String get quotationDetailPdfDownloadFailedMessage => 'تعذر تنزيل ملف PDF.';

  @override
  String get quotationDetailSummaryTitle => 'الملخص';

  @override
  String get quotationDetailCustomerLabel => 'العميل';

  @override
  String get quotationDetailPaymentTermsLabel => 'شروط الدفع';

  @override
  String get quotationDetailCurrencyLabel => 'العملة';

  @override
  String get quotationDetailValidUntilLabel => 'صالح حتى';

  @override
  String quotationDetailValidUntilWithDays(Object validUntil, Object days) {
    return '$validUntil ($days يومًا)';
  }

  @override
  String quotationDetailLinesTitle(Object version) {
    return 'البنود (الإصدار $version)';
  }

  @override
  String quotationDetailLinesTitleWithCount(Object version, int count) {
    return 'البنود (الإصدار $version · $count)';
  }

  @override
  String quotationDetailLineTotalLabel(Object total) {
    return 'إجمالي البند: $total';
  }

  @override
  String get quotationDetailLinesTotalLabel => 'إجمالي البنود';

  @override
  String get quotationDetailNoLines => 'لا تتوفر تفاصيل بنود لهذا الإصدار.';

  @override
  String quotationDetailItemFallback(Object itemId) {
    return 'الصنف رقم $itemId';
  }

  @override
  String quotationDetailQtyPriceLine(
    Object quantity,
    Object uom,
    Object price,
  ) {
    return 'الكمية $quantity $uom · السعر $price';
  }

  @override
  String quotationDetailFocSuffix(Object focQuantity, Object focUom) {
    return ' · مجانًا $focQuantity $focUom';
  }

  @override
  String get quotationDetailActionsTitle => 'الإجراءات';

  @override
  String get quotationDetailDownloadPdfButton => 'تنزيل PDF';

  @override
  String get quotationDetailSendButton => 'إرسال إلى العميل';

  @override
  String quotationDetailReleasedRemainingLine(
    Object released,
    Object remaining,
  ) {
    return 'تم الإفراج عن $released · المتبقي $remaining';
  }

  @override
  String get quotationDetailReleaseSectionTitle => 'الإفراج إلى أمر بيع';

  @override
  String get quotationDetailReleaseNotePartial =>
      'أفرج عن أي جزء من الكمية المتبقية للبند — يبقى الباقي مفتوحًا على عرض السعر للإفراج عنه لاحقًا.';

  @override
  String get quotationDetailReleaseNoteFullOnly =>
      'الإفراج الجزئي معطّل — يتم الإفراج عن كل البنود المفتوحة معًا، بكامل كميتها المتبقية، في أمر بيع واحد.';

  @override
  String get quotationDetailNoReleasableLines =>
      'تم الإفراج بالكامل عن جميع البنود — لا يوجد شيء متبقٍ للإفراج عنه.';

  @override
  String quotationDetailRemainingLabelValue(Object remaining, Object uom) {
    return 'المتبقي $remaining $uom';
  }

  @override
  String get quotationDetailReleaseQtyLabel => 'كمية الإفراج';

  @override
  String get quotationDetailWarehouseLabel => 'المخزن';

  @override
  String get quotationDetailFillFullRemainingButton =>
      'ملء كامل الكمية المتبقية';

  @override
  String get quotationDetailReleaseButton => 'الإفراج إلى أمر بيع';

  @override
  String get quotationDetailReleaseButtonFullOnly =>
      'الإفراج عن كامل عرض السعر إلى أمر بيع';

  @override
  String get quotationDetailResponseRecordedMessage => 'تم تسجيل رد العميل.';

  @override
  String get quotationDetailResponseSectionTitle => 'رد العميل';

  @override
  String get quotationDetailResponseSectionNote =>
      'سجّل ما أخبرك به العميل — هذا يغني عن انتظار رابط التأكيد الخاص به، والموافقة تتيح تحويل عرض السعر إلى أمر بيع.';

  @override
  String get quotationDetailResponseLabel => 'الرد';

  @override
  String get quotationDetailResponseAccepted => 'موافقة';

  @override
  String get quotationDetailResponseRejected => 'رفض';

  @override
  String get quotationDetailResponseNegotiationRequested => 'طلب تفاوض';

  @override
  String get quotationDetailResponseCustomerNameLabel => 'اسم العميل (اختياري)';

  @override
  String get quotationDetailResponseCommentsLabel => 'ملاحظات (اختياري)';

  @override
  String get quotationDetailResponseSubmitButton => 'تسجيل رد العميل';

  @override
  String get salesOrdersTitle => 'طلبات المبيعات';

  @override
  String get salesOrdersSearchHint => 'ابحث برقم الطلب أو اسم العميل';

  @override
  String get salesOrdersClearFilters => 'مسح الفلاتر';

  @override
  String get salesOrdersLoadError => 'تعذر تحميل طلبات المبيعات.';

  @override
  String get salesOrdersEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String get salesOrdersEmptyMessage => 'حوّل عرض سعر مقبولاً إلى طلب.';

  @override
  String get salesOrdersNoMatchTitle => 'لا توجد طلبات مطابقة';

  @override
  String get salesOrdersNoMatchMessage => 'جرّب فلترًا مختلفًا.';

  @override
  String get salesOrdersReleasingLabel => 'جارٍ الإفراج…';

  @override
  String get salesOrdersReleaseHoldLabel => 'إلغاء الإيقاف';

  @override
  String get salesOrdersHoldReleasedMessage => 'تم إلغاء الإيقاف.';

  @override
  String get salesOrdersReleaseHoldError => 'تعذر إلغاء الإيقاف.';

  @override
  String get salesOrdersFilterByCustomerTitle => 'فلترة حسب العميل';

  @override
  String get salesOrdersSearchCustomersHint => 'ابحث عن عميل';

  @override
  String get salesOrdersNoMatchingCustomers => 'لا يوجد عملاء مطابقون.';

  @override
  String get salesOrderDetailTitle => 'تفاصيل الطلب';

  @override
  String get salesOrderDetailHoldReleasedMessage => 'تم إلغاء الإيقاف.';

  @override
  String get salesOrderDetailReleaseHoldError => 'تعذر إلغاء الإيقاف.';

  @override
  String salesOrderDetailWarehouseFallback(Object id) {
    return 'مستودع رقم $id';
  }

  @override
  String get salesOrderDetailLoadError => 'تعذر تحميل الطلب.';

  @override
  String get salesOrderDetailSummaryTitle => 'ملخص';

  @override
  String get salesOrderDetailCustomerLabel => 'العميل';

  @override
  String get salesOrderDetailWarehouseLabel => 'المستودع';

  @override
  String get salesOrderDetailQuotationLabel => 'عرض السعر';

  @override
  String get salesOrderDetailOrderDateLabel => 'تاريخ الطلب';

  @override
  String get salesOrderDetailJdeOrderLabel => 'رقم طلب JDE';

  @override
  String get salesOrderDetailCreditLabel => 'الحالة الائتمانية';

  @override
  String get salesOrderDetailHoldLabel => 'الإيقاف';

  @override
  String get salesOrderDetailSplitOriginTitle => 'أصل التقسيم';

  @override
  String salesOrderDetailSplitOriginMessage(
    Object splitSequence,
    Object originalOrderNumber,
  ) {
    return 'هذا طلب التنفيذ رقم $splitSequence ضمن تقسيم بقيمة محددة. الطلب الأصلي هو $originalOrderNumber.';
  }

  @override
  String get salesOrderDetailViewOriginalOrderLabel => 'عرض الطلب قبل التقسيم';

  @override
  String get salesOrderDetailLinesTitle => 'بنود الطلب';

  @override
  String salesOrderDetailLinesTitleWithCount(int count) {
    return 'بنود الطلب ($count)';
  }

  @override
  String get salesOrderDetailNoLinesMessage => 'لا توجد بنود في هذا الطلب.';

  @override
  String salesOrderDetailItemFallback(Object itemId) {
    return 'صنف رقم $itemId';
  }

  @override
  String salesOrderDetailQtyLabel(Object quantity, Object uom) {
    return 'الكمية $quantity $uom';
  }

  @override
  String salesOrderDetailFocLabel(Object focQuantity) {
    return 'مجاني $focQuantity';
  }

  @override
  String salesOrderDetailUnitPriceBeforeTax(Object value) {
    return 'سعر الوحدة قبل الضريبة $value';
  }

  @override
  String salesOrderDetailTaxRateLabel(Object rate) {
    return 'ضريبة $rate%';
  }

  @override
  String get salesOrderDetailNoTaxLabel => 'بدون ضريبة';

  @override
  String salesOrderDetailUnitPriceAfterTax(Object value) {
    return 'سعر الوحدة بعد الضريبة $value';
  }

  @override
  String salesOrderDetailLineTotalLabel(Object total) {
    return 'إجمالي البند (بعد الضريبة): $total';
  }

  @override
  String get salesOrderDetailOrderTotalLabel => 'إجمالي الطلب (بعد الضريبة)';

  @override
  String get salesOrderDetailHoldsTitle => 'الإيقافات';

  @override
  String get salesOrderDetailHoldTypeFallback => 'إيقاف';

  @override
  String get salesOrderDetailReleaseHoldLabel => 'إلغاء الإيقاف';

  @override
  String get widgetsNotificationsTooltip => 'الإشعارات';

  @override
  String get widgetsNotificationsTitle => 'الإشعارات';

  @override
  String widgetsNewNotificationsCount(Object count) {
    return '$count جديد';
  }

  @override
  String get widgetsMarkAllReadButton => 'تعليم الكل كمقروء';

  @override
  String get widgetsNoNotificationsTitle => 'لا توجد إشعارات بعد';

  @override
  String get widgetsNoNotificationsMessage =>
      'ستظهر هنا تحديثات عروض الأسعار والطلبات الخاصة بك.';

  @override
  String get widgetsTryAgainButton => 'إعادة المحاولة';

  @override
  String widgetsRejectedReason(Object reason) {
    return 'مرفوض: $reason';
  }

  @override
  String get itemPickerTitle => 'اختر الصنف';

  @override
  String get itemPickerNoMatches => 'لا توجد أصناف مطابقة';
}
