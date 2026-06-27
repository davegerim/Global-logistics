import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @globalLogisticsPlc.
  ///
  /// In en, this message translates to:
  /// **'Global Logistics PLC'**
  String get globalLogisticsPlc;

  /// No description provided for @couldNotOpenMapApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open map app.'**
  String get couldNotOpenMapApp;

  /// No description provided for @shipmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Shipment not found'**
  String get shipmentNotFound;

  /// No description provided for @openLiveLocationInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open live location in Maps'**
  String get openLiveLocationInMaps;

  /// No description provided for @openRouteStartInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open route start in Maps'**
  String get openRouteStartInMaps;

  /// No description provided for @newBooking.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get newBooking;

  /// No description provided for @newAction.
  ///
  /// In en, this message translates to:
  /// **'Create Booking'**
  String get newAction;

  /// No description provided for @activeAndRecent.
  ///
  /// In en, this message translates to:
  /// **'Active & recent'**
  String get activeAndRecent;

  /// No description provided for @securityAndAccess.
  ///
  /// In en, this message translates to:
  /// **'Security & Access'**
  String get securityAndAccess;

  /// No description provided for @recordPayout.
  ///
  /// In en, this message translates to:
  /// **'Record Payout'**
  String get recordPayout;

  /// No description provided for @submitProofOfPayout.
  ///
  /// In en, this message translates to:
  /// **'Submit proof of payout for an assigned logistics route.'**
  String get submitProofOfPayout;

  /// No description provided for @paymentReceiptAttached.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt attached'**
  String get paymentReceiptAttached;

  /// No description provided for @paymentProofSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment proof submitted successfully.'**
  String get paymentProofSubmittedSuccessfully;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language for the interface.'**
  String get choosePreferredLanguage;

  /// No description provided for @legalAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get legalAndPrivacy;

  /// No description provided for @driverPolicies.
  ///
  /// In en, this message translates to:
  /// **'Global Logistics PLC Driver Policies.'**
  String get driverPolicies;

  /// No description provided for @helpDesk.
  ///
  /// In en, this message translates to:
  /// **'Help Desk'**
  String get helpDesk;

  /// No description provided for @helpDeskDriverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 priority support line for active drivers.'**
  String get helpDeskDriverSubtitle;

  /// No description provided for @activeLoads.
  ///
  /// In en, this message translates to:
  /// **'Active Loads'**
  String get activeLoads;

  /// No description provided for @driverRating.
  ///
  /// In en, this message translates to:
  /// **'Driver Rating'**
  String get driverRating;

  /// No description provided for @libriNumber.
  ///
  /// In en, this message translates to:
  /// **'Libre number'**
  String get libriNumber;

  /// No description provided for @libriDocumentAttached.
  ///
  /// In en, this message translates to:
  /// **'Libre document attached'**
  String get libriDocumentAttached;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// No description provided for @insuranceNumber.
  ///
  /// In en, this message translates to:
  /// **'Insurance number'**
  String get insuranceNumber;

  /// No description provided for @insuranceDocumentAttached.
  ///
  /// In en, this message translates to:
  /// **'Insurance document attached'**
  String get insuranceDocumentAttached;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @vehiclePhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Vehicle photo attached'**
  String get vehiclePhotoAttached;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @noShipmentsCreateBookingFirst.
  ///
  /// In en, this message translates to:
  /// **'No shipments — create a booking first.'**
  String get noShipmentsCreateBookingFirst;

  /// No description provided for @noAssignmentYet.
  ///
  /// In en, this message translates to:
  /// **'No assignment yet'**
  String get noAssignmentYet;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @shipments.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get shipments;

  /// No description provided for @docs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get docs;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @gdnRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Issuer, consignee, contact and quantity are required.'**
  String get gdnRequiredFields;

  /// No description provided for @gdnCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'GDN created. Driver can now confirm loading.'**
  String get gdnCreatedSuccess;

  /// No description provided for @createGdn.
  ///
  /// In en, this message translates to:
  /// **'Create GDN'**
  String get createGdn;

  /// No description provided for @gdnForm.
  ///
  /// In en, this message translates to:
  /// **'GDN Form'**
  String get gdnForm;

  /// No description provided for @grnForm.
  ///
  /// In en, this message translates to:
  /// **'GRN Form'**
  String get grnForm;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @updateCorporateIdentity.
  ///
  /// In en, this message translates to:
  /// **'Update your corporate identity and contact information.'**
  String get updateCorporateIdentity;

  /// No description provided for @passwordChangesRequireMfa.
  ///
  /// In en, this message translates to:
  /// **'For your protection, password changes require multi-factor authentication.'**
  String get passwordChangesRequireMfa;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @submitNewPaymentRecord.
  ///
  /// In en, this message translates to:
  /// **'Submit a new payment record for your financial ledger.'**
  String get submitNewPaymentRecord;

  /// No description provided for @consignorPolicies.
  ///
  /// In en, this message translates to:
  /// **'Global Logistics PLC policies.'**
  String get consignorPolicies;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @contactSupportConsignorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 priority help desk for consignors.'**
  String get contactSupportConsignorSubtitle;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @shipmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Shipment history'**
  String get shipmentHistory;

  /// No description provided for @noShipmentHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No shipment history yet.'**
  String get noShipmentHistoryYet;

  /// No description provided for @activeAssignments.
  ///
  /// In en, this message translates to:
  /// **'Active assignments'**
  String get activeAssignments;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @libriDocument.
  ///
  /// In en, this message translates to:
  /// **'Libre document'**
  String get libriDocument;

  /// No description provided for @insuranceDocument.
  ///
  /// In en, this message translates to:
  /// **'Insurance document'**
  String get insuranceDocument;

  /// No description provided for @shipmentCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shipment created successfully.'**
  String get shipmentCreatedSuccessfully;

  /// No description provided for @routeAndLogistics.
  ///
  /// In en, this message translates to:
  /// **'Route & Logistics'**
  String get routeAndLogistics;

  /// No description provided for @loadingLocation.
  ///
  /// In en, this message translates to:
  /// **'Loading Location'**
  String get loadingLocation;

  /// No description provided for @offloadingLocation.
  ///
  /// In en, this message translates to:
  /// **'Offloading Location'**
  String get offloadingLocation;

  /// No description provided for @preferredRouteOptional.
  ///
  /// In en, this message translates to:
  /// **'Preferred Route (Optional)'**
  String get preferredRouteOptional;

  /// No description provided for @cargoInformation.
  ///
  /// In en, this message translates to:
  /// **'Cargo Information'**
  String get cargoInformation;

  /// No description provided for @typeOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Type of Goods'**
  String get typeOfGoods;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @vehicleAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Pricing'**
  String get vehicleAndPricing;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @offerPrice.
  ///
  /// In en, this message translates to:
  /// **'Offer Price'**
  String get offerPrice;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @publishBookingOffer.
  ///
  /// In en, this message translates to:
  /// **'Publish Booking Offer'**
  String get publishBookingOffer;

  /// No description provided for @phoneIsMissing.
  ///
  /// In en, this message translates to:
  /// **'Phone is missing. Please register again.'**
  String get phoneIsMissing;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @myShipments.
  ///
  /// In en, this message translates to:
  /// **'My shipments'**
  String get myShipments;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @ownerPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Owner Phone Number'**
  String get ownerPhoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @continueAndSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Continue & Send OTP'**
  String get continueAndSendOtp;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted.'**
  String get offerAccepted;

  /// No description provided for @offerDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer declined.'**
  String get offerDeclined;

  /// No description provided for @offerCancelled.
  ///
  /// In en, this message translates to:
  /// **'Offer cancelled.'**
  String get offerCancelled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @shipmentOffers.
  ///
  /// In en, this message translates to:
  /// **'Shipment offers'**
  String get shipmentOffers;

  /// No description provided for @allOffers.
  ///
  /// In en, this message translates to:
  /// **'All offers'**
  String get allOffers;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @goods.
  ///
  /// In en, this message translates to:
  /// **'Goods'**
  String get goods;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @negotiationId.
  ///
  /// In en, this message translates to:
  /// **'Negotiation ID'**
  String get negotiationId;

  /// No description provided for @openNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Open negotiation'**
  String get openNegotiation;

  /// No description provided for @goodsDeliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Goods Delivery Note'**
  String get goodsDeliveryNote;

  /// No description provided for @goodsReceivedNote.
  ///
  /// In en, this message translates to:
  /// **'Goods Received Note'**
  String get goodsReceivedNote;

  /// No description provided for @assignmentRequiredGdn.
  ///
  /// In en, this message translates to:
  /// **'Assignment is required to create GDN.'**
  String get assignmentRequiredGdn;

  /// No description provided for @assignmentRequiredGrn.
  ///
  /// In en, this message translates to:
  /// **'Assignment is required to create GRN.'**
  String get assignmentRequiredGrn;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @confirmLoaded.
  ///
  /// In en, this message translates to:
  /// **'Confirm loaded'**
  String get confirmLoaded;

  /// No description provided for @confirmCargoLoaded.
  ///
  /// In en, this message translates to:
  /// **'Confirm cargo has been loaded.'**
  String get confirmCargoLoaded;

  /// No description provided for @confirmInTransit.
  ///
  /// In en, this message translates to:
  /// **'Confirm in transit'**
  String get confirmInTransit;

  /// No description provided for @startRouteTracking.
  ///
  /// In en, this message translates to:
  /// **'Start route tracking to destination.'**
  String get startRouteTracking;

  /// No description provided for @confirmArrived.
  ///
  /// In en, this message translates to:
  /// **'Confirm arrived'**
  String get confirmArrived;

  /// No description provided for @markVehicleReachesDestination.
  ///
  /// In en, this message translates to:
  /// **'Mark when vehicle reaches destination.'**
  String get markVehicleReachesDestination;

  /// No description provided for @confirmOffloaded.
  ///
  /// In en, this message translates to:
  /// **'Confirm offloaded'**
  String get confirmOffloaded;

  /// No description provided for @finishUnloadingCompleteHandover.
  ///
  /// In en, this message translates to:
  /// **'Finish unloading and complete handover.'**
  String get finishUnloadingCompleteHandover;

  /// No description provided for @cancelAssignment.
  ///
  /// In en, this message translates to:
  /// **'Cancel assignment'**
  String get cancelAssignment;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent.'**
  String get feedbackSent;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @globalLogisticsSimplified.
  ///
  /// In en, this message translates to:
  /// **'Global Logistics\nSimplified.'**
  String get globalLogisticsSimplified;

  /// No description provided for @connectedOperations.
  ///
  /// In en, this message translates to:
  /// **'Connected\nOperations.'**
  String get connectedOperations;

  /// No description provided for @trackEveryJourney.
  ///
  /// In en, this message translates to:
  /// **'Track Every\nJourney.'**
  String get trackEveryJourney;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Business Name (Optional)'**
  String get businessNameOptional;

  /// No description provided for @tradeLicenceAttached.
  ///
  /// In en, this message translates to:
  /// **'Trade licence attached'**
  String get tradeLicenceAttached;

  /// No description provided for @grnCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'GRN created successfully.'**
  String get grnCreatedSuccessfully;

  /// No description provided for @createGrn.
  ///
  /// In en, this message translates to:
  /// **'Create GRN'**
  String get createGrn;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject offer'**
  String get rejectOffer;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @cancelOffer.
  ///
  /// In en, this message translates to:
  /// **'Cancel offer'**
  String get cancelOffer;

  /// No description provided for @sendCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Send counter offer'**
  String get sendCounterOffer;

  /// No description provided for @counterProposalSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Counter proposal submitted.'**
  String get counterProposalSubmitted;

  /// No description provided for @offerNegotiation.
  ///
  /// In en, this message translates to:
  /// **'Offer negotiation'**
  String get offerNegotiation;

  /// No description provided for @offerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Offer not found'**
  String get offerNotFound;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @counter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counter;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @currentOffer.
  ///
  /// In en, this message translates to:
  /// **'Current offer'**
  String get currentOffer;

  /// No description provided for @couldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file.'**
  String get couldNotReadFile;

  /// No description provided for @consignor.
  ///
  /// In en, this message translates to:
  /// **'Consignor'**
  String get consignor;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @registerAsConsignor.
  ///
  /// In en, this message translates to:
  /// **'Register as consignor'**
  String get registerAsConsignor;

  /// No description provided for @registerAsDriver.
  ///
  /// In en, this message translates to:
  /// **'Register as driver'**
  String get registerAsDriver;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone'**
  String get enterPhone;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @remarkRequiredToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remark is required to confirm.'**
  String get remarkRequiredToConfirm;

  /// No description provided for @consignorConfirmationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Consignor confirmation completed.'**
  String get consignorConfirmationCompleted;

  /// No description provided for @shipmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Shipment Details'**
  String get shipmentDetails;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @driverDetails.
  ///
  /// In en, this message translates to:
  /// **'Driver Details'**
  String get driverDetails;

  /// No description provided for @gdnControl.
  ///
  /// In en, this message translates to:
  /// **'GDN Control'**
  String get gdnControl;

  /// No description provided for @grnControl.
  ///
  /// In en, this message translates to:
  /// **'GRN Control'**
  String get grnControl;

  /// No description provided for @confirmHandover.
  ///
  /// In en, this message translates to:
  /// **'Confirm Handover'**
  String get confirmHandover;

  /// No description provided for @confirmCompleted.
  ///
  /// In en, this message translates to:
  /// **'Confirm completed'**
  String get confirmCompleted;

  /// No description provided for @negotiationRoom.
  ///
  /// In en, this message translates to:
  /// **'Negotiation Room'**
  String get negotiationRoom;

  /// No description provided for @liveTrackingMap.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking Map'**
  String get liveTrackingMap;

  /// No description provided for @confirmAssignment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Assignment'**
  String get confirmAssignment;

  /// No description provided for @addConsignorConfirmationRemark.
  ///
  /// In en, this message translates to:
  /// **'Add consignor confirmation remark'**
  String get addConsignorConfirmationRemark;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @licenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Licence Number'**
  String get licenceNumber;

  /// No description provided for @licenceDocumentAttached.
  ///
  /// In en, this message translates to:
  /// **'Licence document attached'**
  String get licenceDocumentAttached;

  /// No description provided for @preferredLanesOptional.
  ///
  /// In en, this message translates to:
  /// **'Preferred Lanes (Optional)'**
  String get preferredLanesOptional;

  /// No description provided for @saveProfileAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save Profile & Continue'**
  String get saveProfileAndContinue;

  /// No description provided for @pleaseEnterPhoneNumberFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number first.'**
  String get pleaseEnterPhoneNumberFirst;

  /// No description provided for @otpSentCheckPhone.
  ///
  /// In en, this message translates to:
  /// **'OTP sent. Check your phone for the verification code.'**
  String get otpSentCheckPhone;

  /// No description provided for @pleaseFillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get pleaseFillInAllFields;

  /// No description provided for @passwordResetSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful. Please sign in.'**
  String get passwordResetSuccessful;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @consignee.
  ///
  /// In en, this message translates to:
  /// **'Consignee'**
  String get consignee;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @quickAction.
  ///
  /// In en, this message translates to:
  /// **'Quick action'**
  String get quickAction;

  /// No description provided for @createBooking.
  ///
  /// In en, this message translates to:
  /// **'Create booking'**
  String get createBooking;

  /// No description provided for @createBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Booking'**
  String get createBookingTitle;

  /// No description provided for @statusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get statusPrefix;

  /// No description provided for @bookingUnlocksAfterAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Booking unlocks after admin approval'**
  String get bookingUnlocksAfterAdminApproval;

  /// No description provided for @noActiveShipmentsCreateBookingToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'No active shipments. Create a booking to get started.'**
  String get noActiveShipmentsCreateBookingToGetStarted;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @newShipment.
  ///
  /// In en, this message translates to:
  /// **'New Shipment'**
  String get newShipment;

  /// No description provided for @createNewShipmentOfferDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new shipment offer. Provide accurate logistics details to match with the best drivers.'**
  String get createNewShipmentOfferDesc;

  /// No description provided for @accountPendingAdminApprovalDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending admin approval. Booking is currently disabled.'**
  String get accountPendingAdminApprovalDesc;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get toLabel;

  /// No description provided for @placedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Placed '**
  String get placedPrefix;

  /// No description provided for @estPrefix.
  ///
  /// In en, this message translates to:
  /// **'Est. '**
  String get estPrefix;

  /// No description provided for @loadingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Load '**
  String get loadingPrefix;

  /// No description provided for @offloadingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Offload '**
  String get offloadingPrefix;

  /// No description provided for @approvedLabel.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get approvedLabel;

  /// No description provided for @verifiedWaitingAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED (waiting admin approval)'**
  String get verifiedWaitingAdminApproval;

  /// No description provided for @pendingAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'PENDING ADMIN APPROVAL'**
  String get pendingAdminApproval;

  /// No description provided for @waitingAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'WAITING ADMIN APPROVAL'**
  String get waitingAdminApproval;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedLabel;

  /// No description provided for @cancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelledLabel;

  /// No description provided for @inTransitLabel.
  ///
  /// In en, this message translates to:
  /// **'IN TRANSIT'**
  String get inTransitLabel;

  /// No description provided for @arrivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrivedLabel;

  /// No description provided for @offloadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Offloaded'**
  String get offloadedLabel;

  /// No description provided for @loadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get loadedLabel;

  /// No description provided for @gdnGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'GDN GENERATED'**
  String get gdnGeneratedLabel;

  /// No description provided for @grnGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'GRN GENERATED'**
  String get grnGeneratedLabel;

  /// No description provided for @consignorAcceptedLabel.
  ///
  /// In en, this message translates to:
  /// **'CONSIGNOR ACCEPTED'**
  String get consignorAcceptedLabel;

  /// No description provided for @driverAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'DRIVER ASSIGNED'**
  String get driverAssignedLabel;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get selectedLabel;

  /// No description provided for @consignorReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'CONSIGNOR RECEIVED'**
  String get consignorReceivedLabel;

  /// No description provided for @adminApprovedLabel.
  ///
  /// In en, this message translates to:
  /// **'ADMIN APPROVED'**
  String get adminApprovedLabel;

  /// No description provided for @bookingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Booking '**
  String get bookingPrefix;

  /// No description provided for @assignmentPrefix.
  ///
  /// In en, this message translates to:
  /// **'Assignment '**
  String get assignmentPrefix;

  /// No description provided for @statusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get statusPendingReview;

  /// No description provided for @statusAwaitingDriver.
  ///
  /// In en, this message translates to:
  /// **'Awaiting driver'**
  String get statusAwaitingDriver;

  /// No description provided for @statusDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get statusDriverAssigned;

  /// No description provided for @statusGdnIssued.
  ///
  /// In en, this message translates to:
  /// **'GDN issued'**
  String get statusGdnIssued;

  /// No description provided for @statusLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get statusLoading;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get statusInTransit;

  /// No description provided for @statusAtDestination.
  ///
  /// In en, this message translates to:
  /// **'At destination'**
  String get statusAtDestination;

  /// No description provided for @statusOffloading.
  ///
  /// In en, this message translates to:
  /// **'Offloading'**
  String get statusOffloading;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @businessProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Business profile updated'**
  String get businessProfileUpdated;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @openShipmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Open shipment history'**
  String get openShipmentHistory;

  /// No description provided for @shipmentProgress.
  ///
  /// In en, this message translates to:
  /// **'Shipment progress'**
  String get shipmentProgress;

  /// No description provided for @weightLabelCap.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get weightLabelCap;

  /// No description provided for @volumeLabelCap.
  ///
  /// In en, this message translates to:
  /// **'VOLUME'**
  String get volumeLabelCap;

  /// No description provided for @vehicleLabelCap.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE'**
  String get vehicleLabelCap;

  /// No description provided for @createdLabelCap.
  ///
  /// In en, this message translates to:
  /// **'CREATED'**
  String get createdLabelCap;

  /// No description provided for @priceTypeLabelCap.
  ///
  /// In en, this message translates to:
  /// **'PRICE TYPE'**
  String get priceTypeLabelCap;

  /// No description provided for @priceLabelCap.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get priceLabelCap;

  /// No description provided for @routeMap.
  ///
  /// In en, this message translates to:
  /// **'Route Map'**
  String get routeMap;

  /// No description provided for @pickupLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'PICKUP LOCATION'**
  String get pickupLocationLabel;

  /// No description provided for @deliveryDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY DESTINATION'**
  String get deliveryDestinationLabel;

  /// No description provided for @placedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'PLACED ON'**
  String get placedOnLabel;

  /// No description provided for @estArrivalLabel.
  ///
  /// In en, this message translates to:
  /// **'EST. ARRIVAL'**
  String get estArrivalLabel;

  /// No description provided for @gdnControlOnceAdminSelects.
  ///
  /// In en, this message translates to:
  /// **'GDN control will be active when driver is ready to load'**
  String get gdnControlOnceAdminSelects;

  /// No description provided for @grnControlAfterDriverAssignment.
  ///
  /// In en, this message translates to:
  /// **'GRN control will be active when the driver arrives at the destination'**
  String get grnControlAfterDriverAssignment;

  /// No description provided for @handoverConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Handover confirmed'**
  String get handoverConfirmed;

  /// No description provided for @feedbackToDriver.
  ///
  /// In en, this message translates to:
  /// **'Feedback to driver'**
  String get feedbackToDriver;

  /// No description provided for @shareDeliveryNotesOrRate.
  ///
  /// In en, this message translates to:
  /// **'Share delivery notes or rate your driver after handover is confirmed.'**
  String get shareDeliveryNotesOrRate;

  /// No description provided for @receiverNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Receiver name, quantity and condition note are required.'**
  String get receiverNameRequired;

  /// No description provided for @grnExistsAndCompleted.
  ///
  /// In en, this message translates to:
  /// **'GRN exists and consignor confirmation is completed.'**
  String get grnExistsAndCompleted;

  /// No description provided for @grnAlreadyCreatedConfirm.
  ///
  /// In en, this message translates to:
  /// **'GRN already created. Confirm final receipt on the shipment screen.'**
  String get grnAlreadyCreatedConfirm;

  /// No description provided for @fillFormToCreateGrnAfterOffload.
  ///
  /// In en, this message translates to:
  /// **'Fill the form to create GRN after offloading.'**
  String get fillFormToCreateGrnAfterOffload;

  /// No description provided for @grnCreatedSuccessConfirm.
  ///
  /// In en, this message translates to:
  /// **'GRN created successfully. Confirm final receipt on the shipment screen.'**
  String get grnCreatedSuccessConfirm;

  /// No description provided for @receiverNameStar.
  ///
  /// In en, this message translates to:
  /// **'Receiver name *'**
  String get receiverNameStar;

  /// No description provided for @receivedQuantityStar.
  ///
  /// In en, this message translates to:
  /// **'Received quantity *'**
  String get receivedQuantityStar;

  /// No description provided for @receivedWeight.
  ///
  /// In en, this message translates to:
  /// **'Received weight'**
  String get receivedWeight;

  /// No description provided for @receivedVolume.
  ///
  /// In en, this message translates to:
  /// **'Received volume'**
  String get receivedVolume;

  /// No description provided for @damageQuantity.
  ///
  /// In en, this message translates to:
  /// **'Damage quantity'**
  String get damageQuantity;

  /// No description provided for @shortageQuantity.
  ///
  /// In en, this message translates to:
  /// **'Shortage quantity'**
  String get shortageQuantity;

  /// No description provided for @conditionNoteStar.
  ///
  /// In en, this message translates to:
  /// **'Condition note *'**
  String get conditionNoteStar;

  /// No description provided for @receivedAt.
  ///
  /// In en, this message translates to:
  /// **'Received at'**
  String get receivedAt;

  /// No description provided for @grnAlreadyCreated.
  ///
  /// In en, this message translates to:
  /// **'GRN already created'**
  String get grnAlreadyCreated;

  /// No description provided for @gdnAlreadyGeneratedLocked.
  ///
  /// In en, this message translates to:
  /// **'GDN already generated and locked.'**
  String get gdnAlreadyGeneratedLocked;

  /// No description provided for @fillFormToCreateGdn.
  ///
  /// In en, this message translates to:
  /// **'Fill the form to create GDN.'**
  String get fillFormToCreateGdn;

  /// No description provided for @gdnCreatedSuccessEditingDisabled.
  ///
  /// In en, this message translates to:
  /// **'GDN created successfully. Editing is disabled.'**
  String get gdnCreatedSuccessEditingDisabled;

  /// No description provided for @issuerNameStar.
  ///
  /// In en, this message translates to:
  /// **'Issuer name *'**
  String get issuerNameStar;

  /// No description provided for @consigneeNameStar.
  ///
  /// In en, this message translates to:
  /// **'Consignee name *'**
  String get consigneeNameStar;

  /// No description provided for @consigneeContactStar.
  ///
  /// In en, this message translates to:
  /// **'Consignee contact *'**
  String get consigneeContactStar;

  /// No description provided for @quantityStar.
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get quantityStar;

  /// No description provided for @packaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get packaging;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @gdnAlreadyCreated.
  ///
  /// In en, this message translates to:
  /// **'GDN already created'**
  String get gdnAlreadyCreated;

  /// No description provided for @voidGdn.
  ///
  /// In en, this message translates to:
  /// **'Void GDN'**
  String get voidGdn;

  /// No description provided for @voidGrn.
  ///
  /// In en, this message translates to:
  /// **'Void GRN'**
  String get voidGrn;

  /// No description provided for @voidGdnTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this GDN?'**
  String get voidGdnTitle;

  /// No description provided for @voidGrnTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this GRN?'**
  String get voidGrnTitle;

  /// No description provided for @voidGdnMessage.
  ///
  /// In en, this message translates to:
  /// **'The current GDN will be marked void and kept on record. You can then create a new GDN.'**
  String get voidGdnMessage;

  /// No description provided for @voidGrnMessage.
  ///
  /// In en, this message translates to:
  /// **'The current GRN will be marked void and kept on record. You can then create a new GRN.'**
  String get voidGrnMessage;

  /// No description provided for @voidDocumentReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get voidDocumentReasonHint;

  /// No description provided for @voidDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Void document'**
  String get voidDocumentConfirm;

  /// No description provided for @voidDocumentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document voided. You can create a replacement.'**
  String get voidDocumentSuccess;

  /// No description provided for @documentVoidAndReplacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Previous document voided and a new one was created.'**
  String get documentVoidAndReplacedSuccess;

  /// No description provided for @documentVoidedCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Document was voided but creating the replacement failed. Update the form and tap Create to try again.'**
  String get documentVoidedCreateFailed;

  /// No description provided for @documentStatusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get documentStatusIssued;

  /// No description provided for @documentStatusVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get documentStatusVoid;

  /// No description provided for @gdnGrnDocumentHistory.
  ///
  /// In en, this message translates to:
  /// **'Document history'**
  String get gdnGrnDocumentHistory;

  /// No description provided for @gdnVoidedCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Previous GDN was voided. Create a new GDN below.'**
  String get gdnVoidedCreateNew;

  /// No description provided for @grnVoidedCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Previous GRN was voided. Create a new GRN below.'**
  String get grnVoidedCreateNew;

  /// No description provided for @gdnActiveLockedVoidToReplace.
  ///
  /// In en, this message translates to:
  /// **'Active GDN on file. Void it to create a corrected GDN.'**
  String get gdnActiveLockedVoidToReplace;

  /// No description provided for @grnActiveLockedVoidToReplace.
  ///
  /// In en, this message translates to:
  /// **'Active GRN on file. Void it to create a corrected GRN.'**
  String get grnActiveLockedVoidToReplace;

  /// No description provided for @documentVoidedBanner.
  ///
  /// In en, this message translates to:
  /// **'This document has been voided and is kept for reference only.'**
  String get documentVoidedBanner;

  /// No description provided for @trackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingLabel;

  /// No description provided for @trackingPoints.
  ///
  /// In en, this message translates to:
  /// **'Tracking points:'**
  String get trackingPoints;

  /// No description provided for @latestLocationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Latest: lat '**
  String get latestLocationPrefix;

  /// No description provided for @lonPrefix.
  ///
  /// In en, this message translates to:
  /// **' lon '**
  String get lonPrefix;

  /// No description provided for @atPrefix.
  ///
  /// In en, this message translates to:
  /// **' @ '**
  String get atPrefix;

  /// No description provided for @noOfferRoundsYet.
  ///
  /// In en, this message translates to:
  /// **'No offer rounds yet.'**
  String get noOfferRoundsYet;

  /// No description provided for @latestPrice.
  ///
  /// In en, this message translates to:
  /// **'Latest price:'**
  String get latestPrice;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @shipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipment'**
  String get shipmentTitle;

  /// No description provided for @waitingForDriverAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver assignment. Once assigned, create GDN before driver can continue status updates.'**
  String get waitingForDriverAssignment;

  /// No description provided for @assignmentLabelCap.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNMENT'**
  String get assignmentLabelCap;

  /// No description provided for @statusLabelCap.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusLabelCap;

  /// No description provided for @viewGdnForm.
  ///
  /// In en, this message translates to:
  /// **'View GDN form'**
  String get viewGdnForm;

  /// No description provided for @openGdnForm.
  ///
  /// In en, this message translates to:
  /// **'Open GDN form'**
  String get openGdnForm;

  /// No description provided for @grnCreatedAfterOffload.
  ///
  /// In en, this message translates to:
  /// **'GRN can be created after the driver confirms offloaded status.'**
  String get grnCreatedAfterOffload;

  /// No description provided for @viewGrnForm.
  ///
  /// In en, this message translates to:
  /// **'View GRN form'**
  String get viewGrnForm;

  /// No description provided for @openGrnForm.
  ///
  /// In en, this message translates to:
  /// **'Open GRN form'**
  String get openGrnForm;

  /// No description provided for @afterGrnRecordedConfirm.
  ///
  /// In en, this message translates to:
  /// **'After GRN is recorded, confirm final receipt here.'**
  String get afterGrnRecordedConfirm;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @nameAndContact.
  ///
  /// In en, this message translates to:
  /// **'Name & contact'**
  String get nameAndContact;

  /// No description provided for @businessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get businessProfile;

  /// No description provided for @companyAndTradeLicence.
  ///
  /// In en, this message translates to:
  /// **'Company & trade licence'**
  String get companyAndTradeLicence;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @passwordAnd2fa.
  ///
  /// In en, this message translates to:
  /// **'Password & 2FA'**
  String get passwordAnd2fa;

  /// No description provided for @logisticsSection.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logisticsSection;

  /// No description provided for @shipmentArchive.
  ///
  /// In en, this message translates to:
  /// **'Shipment Archive'**
  String get shipmentArchive;

  /// No description provided for @pastLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Past load history'**
  String get pastLoadHistory;

  /// No description provided for @preferencesAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Support'**
  String get preferencesAndSupport;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @pushAlerts.
  ///
  /// In en, this message translates to:
  /// **'Push alerts'**
  String get pushAlerts;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @privacyAndTerms.
  ///
  /// In en, this message translates to:
  /// **'Privacy & terms'**
  String get privacyAndTerms;

  /// No description provided for @amharicLanguage.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get amharicLanguage;

  /// No description provided for @englishUs.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get englishUs;

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelection;

  /// No description provided for @gdnGrnHub.
  ///
  /// In en, this message translates to:
  /// **'GDN & GRN Hub'**
  String get gdnGrnHub;

  /// No description provided for @viewAllShippingDocumentsDesc.
  ///
  /// In en, this message translates to:
  /// **'View all shipping documents for the selected shipment assignment.'**
  String get viewAllShippingDocumentsDesc;

  /// No description provided for @selectShipment.
  ///
  /// In en, this message translates to:
  /// **'Select Shipment'**
  String get selectShipment;

  /// No description provided for @noGdnGrnForShipment.
  ///
  /// In en, this message translates to:
  /// **'This shipment has no active assignment, so no GDN/GRN is available yet.'**
  String get noGdnGrnForShipment;

  /// No description provided for @noGdnGrnRecordsReturned.
  ///
  /// In en, this message translates to:
  /// **'No GDN or GRN records were returned for this assignment.'**
  String get noGdnGrnRecordsReturned;

  /// No description provided for @noTypeDocuments.
  ///
  /// In en, this message translates to:
  /// **'No {type} documents'**
  String noTypeDocuments(String type);

  /// No description provided for @trySwitchingFilter.
  ///
  /// In en, this message translates to:
  /// **'Try switching the filter to see all available documents.'**
  String get trySwitchingFilter;

  /// No description provided for @documentNoPrefix.
  ///
  /// In en, this message translates to:
  /// **'No:'**
  String get documentNoPrefix;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get allFilter;

  /// No description provided for @gdnFilter.
  ///
  /// In en, this message translates to:
  /// **'GDN'**
  String get gdnFilter;

  /// No description provided for @grnFilter.
  ///
  /// In en, this message translates to:
  /// **'GRN'**
  String get grnFilter;

  /// No description provided for @goodsDetails.
  ///
  /// In en, this message translates to:
  /// **'Goods Details'**
  String get goodsDetails;

  /// No description provided for @scanToVerifyAuthenticity.
  ///
  /// In en, this message translates to:
  /// **'Scan to verify document authenticity'**
  String get scanToVerifyAuthenticity;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @preparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparingPdf;

  /// No description provided for @licensePrefix.
  ///
  /// In en, this message translates to:
  /// **'License:'**
  String get licensePrefix;

  /// No description provided for @idPrefix.
  ///
  /// In en, this message translates to:
  /// **'ID:'**
  String get idPrefix;

  /// No description provided for @platePrefix.
  ///
  /// In en, this message translates to:
  /// **'Plate:'**
  String get platePrefix;

  /// No description provided for @updateCompanyAndTradeLicence.
  ///
  /// In en, this message translates to:
  /// **'Update your company name and trade licence'**
  String get updateCompanyAndTradeLicence;

  /// No description provided for @uploadTradeLicence.
  ///
  /// In en, this message translates to:
  /// **'Upload trade licence or ID (image or PDF)'**
  String get uploadTradeLicence;

  /// No description provided for @tradeLicenceUploaded.
  ///
  /// In en, this message translates to:
  /// **'Trade licence uploaded.'**
  String get tradeLicenceUploaded;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @passwordResetEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please check your registered email for password reset instructions.'**
  String get passwordResetEmailInstructions;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @privacyPolicyText.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected under our strict corporate privacy policies. We do not share shipping metrics or personal details with unauthorized third parties.\n\nFor full terms of service, please visit our website.'**
  String get privacyPolicyText;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @successfullySavedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Successfully saved to Downloads folder.\n{filename}'**
  String successfullySavedToDownloads(String filename);

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBackTitle;

  /// No description provided for @signInToManageShipments.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage shipments.'**
  String get signInToManageShipments;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive an OTP, then create a new password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP code'**
  String get otpCodeLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @consignorRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Consignor Registration'**
  String get consignorRegistrationTitle;

  /// No description provided for @consignorRegStep1.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3: Create your account to start managing shipments.'**
  String get consignorRegStep1;

  /// No description provided for @assignedShipmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned shipments'**
  String get assignedShipmentsTitle;

  /// No description provided for @assignedShipmentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Accept offers from the Offers tab; admin assigns final routes.'**
  String get assignedShipmentsDesc;

  /// No description provided for @accountStatusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Account status: '**
  String get accountStatusPrefix;

  /// No description provided for @openOffersButton.
  ///
  /// In en, this message translates to:
  /// **'Open offers'**
  String get openOffersButton;

  /// No description provided for @noActiveAssignmentsDesc.
  ///
  /// In en, this message translates to:
  /// **'No active assignments. Check new offers.'**
  String get noActiveAssignmentsDesc;

  /// No description provided for @updateProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get updateProfileTitle;

  /// No description provided for @updateProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photo, licence, lanes'**
  String get updateProfileSubtitle;

  /// No description provided for @vehicleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetailsTitle;

  /// No description provided for @driverLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver License'**
  String get driverLicenseTitle;

  /// No description provided for @driverLicenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verification & expiry'**
  String get driverLicenseSubtitle;

  /// No description provided for @viewAdminPaymentRecords.
  ///
  /// In en, this message translates to:
  /// **'View admin payment records'**
  String get viewAdminPaymentRecords;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignmentsTitle;

  /// No description provided for @currentActiveRoutes.
  ///
  /// In en, this message translates to:
  /// **'Current active routes'**
  String get currentActiveRoutes;

  /// No description provided for @offersCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers Center'**
  String get offersCenterTitle;

  /// No description provided for @bidsForNewShipments.
  ///
  /// In en, this message translates to:
  /// **'Bids for new shipments'**
  String get bidsForNewShipments;

  /// No description provided for @loadAndRouteAlerts.
  ///
  /// In en, this message translates to:
  /// **'Load & route alerts'**
  String get loadAndRouteAlerts;

  /// No description provided for @driverTermsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Driver terms & privacy'**
  String get driverTermsAndPrivacy;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @adminMessage.
  ///
  /// In en, this message translates to:
  /// **'Admin message'**
  String get adminMessage;

  /// No description provided for @driverMessage.
  ///
  /// In en, this message translates to:
  /// **'Driver message'**
  String get driverMessage;

  /// No description provided for @etbCurrency.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get etbCurrency;

  /// No description provided for @roundsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rounds: '**
  String get roundsPrefix;

  /// No description provided for @noAssignmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet.'**
  String get noAssignmentsYet;

  /// No description provided for @bottomNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomNavHome;

  /// No description provided for @bottomNavOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get bottomNavOffers;

  /// No description provided for @bottomNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get bottomNavProfile;

  /// No description provided for @howWouldYouLikeToUseApp.
  ///
  /// In en, this message translates to:
  /// **'How would you like\nto use the app?'**
  String get howWouldYouLikeToUseApp;

  /// No description provided for @chooseExperienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the experience that fits you. You can always sign out and switch later.'**
  String get chooseExperienceSubtitle;

  /// No description provided for @consignorMessage.
  ///
  /// In en, this message translates to:
  /// **'Consignor message'**
  String get consignorMessage;

  /// No description provided for @consignorRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ship goods, track loads, pay, and receive delivery notes.'**
  String get consignorRoleSubtitle;

  /// No description provided for @driverRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive offers, accept routes, and confirm delivery.'**
  String get driverRoleSubtitle;

  /// No description provided for @needToRegister.
  ///
  /// In en, this message translates to:
  /// **'Need to register?'**
  String get needToRegister;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @registrationReviewedByTeam.
  ///
  /// In en, this message translates to:
  /// **'Registration is reviewed by your logistics team.'**
  String get registrationReviewedByTeam;

  /// No description provided for @walkthroughPage1Desc.
  ///
  /// In en, this message translates to:
  /// **'Experience the future of freight management with real-time visibility and trusted execution.'**
  String get walkthroughPage1Desc;

  /// No description provided for @walkthroughPage2Desc.
  ///
  /// In en, this message translates to:
  /// **'Bring your team, drivers, and consignors together on one powerful platform.'**
  String get walkthroughPage2Desc;

  /// No description provided for @walkthroughPage3Desc.
  ///
  /// In en, this message translates to:
  /// **'Stay informed with real-time updates and milestone tracking from booking to delivery.'**
  String get walkthroughPage3Desc;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @signInToAccessRoutes.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your routes.'**
  String get signInToAccessRoutes;

  /// No description provided for @enterValidTenDigitPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number.'**
  String get enterValidTenDigitPhone;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterYourPassword;

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required.'**
  String fieldIsRequired(String fieldName);

  /// No description provided for @fieldMustBeValidPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} must be a valid number greater than zero.'**
  String fieldMustBeValidPositiveNumber(String fieldName);

  /// No description provided for @pleaseEnterYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please enter your feedback.'**
  String get pleaseEnterYourFeedback;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Trusted freight. Real-time visibility.'**
  String get splashTagline;

  /// No description provided for @driverRegStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3: Enter the OTP sent to your phone to verify your identity.'**
  String get driverRegStep2;

  /// No description provided for @consignorRegStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3: Enter the OTP sent to your phone to verify your identity.'**
  String get consignorRegStep2;

  /// No description provided for @vehicleProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Profile'**
  String get vehicleProfileTitle;

  /// No description provided for @driverRegStep4.
  ///
  /// In en, this message translates to:
  /// **'Step 4 of 4: Add your vehicle details to start accepting loads.'**
  String get driverRegStep4;

  /// No description provided for @uploadLibriDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload libre document (image or PDF)'**
  String get uploadLibriDocument;

  /// No description provided for @libriDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Libre document uploaded.'**
  String get libriDocumentUploaded;

  /// No description provided for @chassisNumber.
  ///
  /// In en, this message translates to:
  /// **'Chassis number'**
  String get chassisNumber;

  /// No description provided for @uploadBoloDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload bolo document (image or PDF)'**
  String get uploadBoloDocument;

  /// No description provided for @boloDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Bolo document uploaded.'**
  String get boloDocumentUploaded;

  /// No description provided for @boloDocumentAttached.
  ///
  /// In en, this message translates to:
  /// **'Bolo document attached'**
  String get boloDocumentAttached;

  /// No description provided for @uploadInsuranceDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload insurance document (image or PDF)'**
  String get uploadInsuranceDocument;

  /// No description provided for @insuranceDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Insurance document uploaded.'**
  String get insuranceDocumentUploaded;

  /// No description provided for @uploadVehiclePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload vehicle photo (JPG, PNG, or WebP)'**
  String get uploadVehiclePhoto;

  /// No description provided for @vehiclePhotoInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Please choose a JPG, PNG, or WebP image for the vehicle photo.'**
  String get vehiclePhotoInvalidType;

  /// No description provided for @vehiclePhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Vehicle photo uploaded.'**
  String get vehiclePhotoUploaded;

  /// No description provided for @driverRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Registration'**
  String get driverRegistrationTitle;

  /// No description provided for @driverRegStep1.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3: Create your account to start receiving delivery assignments.'**
  String get driverRegStep1;

  /// No description provided for @personalProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Profile'**
  String get personalProfileTitle;

  /// No description provided for @driverRegStep3.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 4: Complete your driver profile with your licence details.'**
  String get driverRegStep3;

  /// No description provided for @uploadLicenceDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload licence document (image or PDF)'**
  String get uploadLicenceDocument;

  /// No description provided for @licenceDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Licence document uploaded.'**
  String get licenceDocumentUploaded;

  /// No description provided for @businessProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfileTitle;

  /// No description provided for @consignorRegStep3.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3: Add your business details to complete registration.'**
  String get consignorRegStep3;

  /// No description provided for @counterPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Counter price *'**
  String get counterPriceRequired;

  /// No description provided for @remarkRequired.
  ///
  /// In en, this message translates to:
  /// **'Remark *'**
  String get remarkRequired;

  /// No description provided for @paymentRecordNotReady.
  ///
  /// In en, this message translates to:
  /// **'Payment record is not ready yet. Pull to refresh.'**
  String get paymentRecordNotReady;

  /// No description provided for @enterValidPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid paid amount.'**
  String get enterValidPaidAmount;

  /// No description provided for @uploadPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload a payment receipt.'**
  String get uploadPaymentReceipt;

  /// No description provided for @paymentSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted successfully.'**
  String get paymentSubmittedSuccessfully;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @shipmentContextNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Shipment context not loaded yet.'**
  String get shipmentContextNotLoaded;

  /// No description provided for @egCounterPrice.
  ///
  /// In en, this message translates to:
  /// **'e.g. 960.00'**
  String get egCounterPrice;

  /// No description provided for @requiredVehicleTypeOptional.
  ///
  /// In en, this message translates to:
  /// **'Required vehicle type (optional)'**
  String get requiredVehicleTypeOptional;

  /// No description provided for @requiredVehicleNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Required vehicle number (optional)'**
  String get requiredVehicleNumberOptional;

  /// No description provided for @loadingDateTime.
  ///
  /// In en, this message translates to:
  /// **'Loading date & time'**
  String get loadingDateTime;

  /// No description provided for @deliveryDateTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery date & time'**
  String get deliveryDateTime;

  /// No description provided for @waitingForAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin negotiation message. Actions will appear here once admin responds.'**
  String get waitingForAdminMessage;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessage;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsWillShowHere.
  ///
  /// In en, this message translates to:
  /// **'When you get notifications, they\'ll show up here.'**
  String get notificationsWillShowHere;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @notificationDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'You have a new update.'**
  String get notificationDefaultMessage;

  /// No description provided for @driverHotline.
  ///
  /// In en, this message translates to:
  /// **'Driver Hotline'**
  String get driverHotline;

  /// No description provided for @supportHotline.
  ///
  /// In en, this message translates to:
  /// **'Support Hotline'**
  String get supportHotline;

  /// No description provided for @driverSupportEmailValue.
  ///
  /// In en, this message translates to:
  /// **'drivers@global-logistics.com'**
  String get driverSupportEmailValue;

  /// No description provided for @consignorSupportEmailValue.
  ///
  /// In en, this message translates to:
  /// **'support@global-logistics.com'**
  String get consignorSupportEmailValue;

  /// No description provided for @driverPhoneValue.
  ///
  /// In en, this message translates to:
  /// **'+251 911 000 000'**
  String get driverPhoneValue;

  /// No description provided for @consignorPhoneValue.
  ///
  /// In en, this message translates to:
  /// **'+251 900 000 000'**
  String get consignorPhoneValue;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @fleetInformation.
  ///
  /// In en, this message translates to:
  /// **'Fleet Information'**
  String get fleetInformation;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @prioritySupportDesc.
  ///
  /// In en, this message translates to:
  /// **'24/7 priority support'**
  String get prioritySupportDesc;

  /// No description provided for @updateDriverProfile.
  ///
  /// In en, this message translates to:
  /// **'Update driver profile'**
  String get updateDriverProfile;

  /// No description provided for @updateDriverProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photo, ID, licence, and preferred lanes'**
  String get updateDriverProfileSubtitle;

  /// No description provided for @uploadProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload profile photo'**
  String get uploadProfilePhoto;

  /// No description provided for @profilePhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Profile photo uploaded.'**
  String get profilePhotoUploaded;

  /// No description provided for @profilePhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Profile photo attached'**
  String get profilePhotoAttached;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @locationTrackingNotice.
  ///
  /// In en, this message translates to:
  /// **'Your location data is tracked only during active shipments to ensure safe and reliable delivery operations.\n\nFor the complete driver agreement and terms of service, please visit our corporate website.'**
  String get locationTrackingNotice;

  /// No description provided for @loadVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Load vehicle info'**
  String get loadVehicleInfo;

  /// No description provided for @paymentDetailsAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Payment details from admin for your assignments will appear here.'**
  String get paymentDetailsAdminDesc;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @agreedLabel.
  ///
  /// In en, this message translates to:
  /// **'Agreed'**
  String get agreedLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedLabel;

  /// No description provided for @refPrefix.
  ///
  /// In en, this message translates to:
  /// **'Ref: '**
  String get refPrefix;

  /// No description provided for @driverLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver license'**
  String get driverLicense;

  /// No description provided for @unableToLoadProfileRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile. Pull to retry.'**
  String get unableToLoadProfileRetry;

  /// No description provided for @licenseDetailsStoredDesc.
  ///
  /// In en, this message translates to:
  /// **'License and ID details as stored on your Global Logistics driver profile.'**
  String get licenseDetailsStoredDesc;

  /// No description provided for @verificationAndCredentials.
  ///
  /// In en, this message translates to:
  /// **'Verification & credentials'**
  String get verificationAndCredentials;

  /// No description provided for @noLicenseDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'No license details were returned for your account. If you recently registered, data may still be processing.'**
  String get noLicenseDetailsDesc;

  /// No description provided for @documentLinksBrowserDesc.
  ///
  /// In en, this message translates to:
  /// **'Document links open in your browser. Contact support if anything needs updating.'**
  String get documentLinksBrowserDesc;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get licenseNumber;

  /// No description provided for @licenseDocument.
  ///
  /// In en, this message translates to:
  /// **'License document'**
  String get licenseDocument;

  /// No description provided for @preferredLanes.
  ///
  /// In en, this message translates to:
  /// **'Preferred lanes'**
  String get preferredLanes;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @unableToLoadVehicleRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to load vehicle profile. Pull to retry.'**
  String get unableToLoadVehicleRetry;

  /// No description provided for @noVehicleDataYet.
  ///
  /// In en, this message translates to:
  /// **'No vehicle data yet. Complete registration or contact support.'**
  String get noVehicleDataYet;

  /// No description provided for @registeredFleetVehicle.
  ///
  /// In en, this message translates to:
  /// **'Registered fleet vehicle on your driver profile.'**
  String get registeredFleetVehicle;

  /// No description provided for @registrationAndDocuments.
  ///
  /// In en, this message translates to:
  /// **'Registration & documents'**
  String get registrationAndDocuments;

  /// No description provided for @vehicleNotes.
  ///
  /// In en, this message translates to:
  /// **'Vehicle notes'**
  String get vehicleNotes;

  /// No description provided for @noAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'No additional notes on file.'**
  String get noAdditionalNotes;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoTitle;

  /// No description provided for @truckLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truckLabel;

  /// No description provided for @noPlateLabel.
  ///
  /// In en, this message translates to:
  /// **'No Plate'**
  String get noPlateLabel;

  /// No description provided for @adminUpdatedOffer.
  ///
  /// In en, this message translates to:
  /// **'Admin updated the offer details.'**
  String get adminUpdatedOffer;

  /// No description provided for @driverUpdatedOffer.
  ///
  /// In en, this message translates to:
  /// **'Driver updated the offer details.'**
  String get driverUpdatedOffer;

  /// No description provided for @offerDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Offer details updated.'**
  String get offerDetailsUpdated;

  /// No description provided for @noPaymentRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No payment records yet'**
  String get noPaymentRecordsYet;

  /// No description provided for @routeLabel.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeLabel;

  /// No description provided for @goodsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Goods type'**
  String get goodsTypeLabel;

  /// No description provided for @lastUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get lastUpdateLabel;

  /// No description provided for @pricePrefix.
  ///
  /// In en, this message translates to:
  /// **'Price: '**
  String get pricePrefix;

  /// No description provided for @counterOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Counter offer'**
  String get counterOfferTitle;

  /// No description provided for @timeUnknown.
  ///
  /// In en, this message translates to:
  /// **'time unknown'**
  String get timeUnknown;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickupLabel;

  /// No description provided for @dropOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get dropOffLabel;

  /// No description provided for @gdnGrnTitle.
  ///
  /// In en, this message translates to:
  /// **'GDN & GRN'**
  String get gdnGrnTitle;

  /// No description provided for @documentsIssuedDesc.
  ///
  /// In en, this message translates to:
  /// **'Documents issued for this assignment'**
  String get documentsIssuedDesc;

  /// No description provided for @noGdnGrnYetDesc.
  ///
  /// In en, this message translates to:
  /// **'No GDN or GRN yet. They appear when the consignor creates them.'**
  String get noGdnGrnYetDesc;

  /// No description provided for @assignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedLabel;

  /// No description provided for @transitLabel.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get transitLabel;

  /// No description provided for @waitingForGdnLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for consignor to create GDN'**
  String get waitingForGdnLabel;

  /// No description provided for @checkingGdn.
  ///
  /// In en, this message translates to:
  /// **'Checking GDN...'**
  String get checkingGdn;

  /// No description provided for @gdnIsReady.
  ///
  /// In en, this message translates to:
  /// **'GDN is ready'**
  String get gdnIsReady;

  /// No description provided for @unableToVerifyGdn.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify GDN right now. Please refresh.'**
  String get unableToVerifyGdn;

  /// No description provided for @assignmentIdMissingDesc.
  ///
  /// In en, this message translates to:
  /// **'Assignment id missing — open again after assignment is created.'**
  String get assignmentIdMissingDesc;

  /// No description provided for @feedbackToConsignorTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback to consignor'**
  String get feedbackToConsignorTitle;

  /// No description provided for @feedbackToConsignorDesc.
  ///
  /// In en, this message translates to:
  /// **'Share delivery notes or appreciation with the shipper.'**
  String get feedbackToConsignorDesc;

  /// No description provided for @feedbackToConsignorLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Available once your assignment is active.'**
  String get feedbackToConsignorLockedDesc;

  /// No description provided for @timeMinutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get timeMinutesSuffix;

  /// No description provided for @timeHoursSuffix.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get timeHoursSuffix;

  /// No description provided for @timeDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get timeDaysSuffix;

  /// No description provided for @timeWeeksSuffix.
  ///
  /// In en, this message translates to:
  /// **'w'**
  String get timeWeeksSuffix;

  /// No description provided for @cancelShipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel shipment'**
  String get cancelShipmentTitle;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @offerRejected.
  ///
  /// In en, this message translates to:
  /// **'Offer rejected.'**
  String get offerRejected;

  /// No description provided for @shipmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Shipment cancelled.'**
  String get shipmentCancelled;

  /// No description provided for @counterOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Counter offer sent.'**
  String get counterOfferSent;

  /// No description provided for @selectLoadingDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select loading date & time'**
  String get selectLoadingDateTime;

  /// No description provided for @selectDeliveryDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select delivery date & time'**
  String get selectDeliveryDateTime;

  /// No description provided for @assignmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Assignment cancelled'**
  String get assignmentCancelled;

  /// No description provided for @loadedConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Loaded confirmed'**
  String get loadedConfirmed;

  /// No description provided for @inTransitConfirmed.
  ///
  /// In en, this message translates to:
  /// **'In transit confirmed'**
  String get inTransitConfirmed;

  /// No description provided for @arrivalConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Arrival confirmed'**
  String get arrivalConfirmed;

  /// No description provided for @offloadConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Offload confirmed'**
  String get offloadConfirmed;
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
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
