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
  /// **'Libri Number'**
  String get libriNumber;

  /// No description provided for @libriDocumentAttached.
  ///
  /// In en, this message translates to:
  /// **'Libri document attached'**
  String get libriDocumentAttached;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// No description provided for @insuranceNumber.
  ///
  /// In en, this message translates to:
  /// **'Insurance Number'**
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
  /// **'Libri document'**
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
  /// **'Global Logistics\\nSimplified.'**
  String get globalLogisticsSimplified;

  /// No description provided for @connectedOperations.
  ///
  /// In en, this message translates to:
  /// **'Connected\\nOperations.'**
  String get connectedOperations;

  /// No description provided for @trackEveryJourney.
  ///
  /// In en, this message translates to:
  /// **'Track Every\\nJourney.'**
  String get trackEveryJourney;

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
