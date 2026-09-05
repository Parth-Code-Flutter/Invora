abstract final class AppStorageKeyConst {
  static const isDarkMode = 'is_dark_mode';
  static const languageCode = 'language_code';
  static const onboardingCompleted = 'onboarding_completed';
  static const businessSetupCompleted = 'business_setup_completed';
  static const defaultWorkspace = 'default_workspace';
  static const activeWorkspace = 'active_workspace';
  static const selectedInvoiceTemplate = 'selected_invoice_template';
  static const customUnits = 'custom_units';
  static const managedUnits = 'managed_units';
  static const defaultUnit = 'default_unit';
  static const defaultDueDays = 'default_due_days';
  static const defaultTaxType = 'default_tax_type';
  static const defaultGstRateBasisPoints = 'default_gst_rate_basis_points';
  static const defaultInvoiceNotes = 'default_invoice_notes';
  static const defaultInvoiceTerms = 'default_invoice_terms';
  static const defaultPaymentMethod = 'default_payment_method';
  static const businessCategory = 'business_category';
  static const enabledProductFields = 'enabled_product_fields';
  static const customProductFields = 'custom_product_fields';
  static const preferredUnits = 'preferred_units';
  static const showProductAttributesOnInvoice =
      'show_product_attributes_on_invoice';
  static const lastBackupAt = 'last_backup_at';
  static const backupReminderDays = 'backup_reminder_days';
  static const restoreCompleted = 'restore_completed';
  static const documentsTab = 'unified_documents_tab';
  static const partiesTab = 'unified_parties_tab';
  static const appLockEnabled = 'app_lock_enabled';
  static const appLockPinHash = 'app_lock_pin_hash';
  static const appLockPinSalt = 'app_lock_pin_salt';
  static const appLockBiometricEnabled = 'app_lock_biometric_enabled';
  static const ageingReminderEvents = 'ageing_reminder_events';
  static const entitlementMobile = 'entitlement_mobile';
  static const entitlementStatus = 'entitlement_status';
  static const entitlementPlanId = 'entitlement_plan_id';
  static const entitlementPlanTitle = 'entitlement_plan_title';
  static const entitlementPlanPriceInr = 'entitlement_plan_price_inr';
  static const entitlementPlanPeriod = 'entitlement_plan_period';
  static const entitlementTrialEndsAtMs = 'entitlement_trial_ends_at_ms';
  static const entitlementLastCheckedAtMs = 'entitlement_last_checked_at_ms';
  static const entitlementLastSeenAtMs = 'entitlement_last_seen_at_ms';

  static const entitlementCacheKeys = <String>{
    entitlementMobile,
    entitlementStatus,
    entitlementPlanId,
    entitlementPlanTitle,
    entitlementPlanPriceInr,
    entitlementPlanPeriod,
    entitlementTrialEndsAtMs,
    entitlementLastCheckedAtMs,
    entitlementLastSeenAtMs,
  };
}
