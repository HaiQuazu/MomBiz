import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MomBiz'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @khmer.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get khmer;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseLanguage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @productsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Animal feed, vaccine, fertilizer and more'**
  String get productsSubtitle;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRate;

  /// No description provided for @exchangeRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'NBC official USD / KHR rate'**
  String get exchangeRateSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @businessOverview.
  ///
  /// In en, this message translates to:
  /// **'Business overview'**
  String get businessOverview;

  /// No description provided for @outstandingCustomerDebt.
  ///
  /// In en, this message translates to:
  /// **'Outstanding customer debt'**
  String get outstandingCustomerDebt;

  /// No description provided for @noOutstandingDebt.
  ///
  /// In en, this message translates to:
  /// **'No outstanding customer debt.'**
  String get noOutstandingDebt;

  /// No description provided for @acrossAllCustomers.
  ///
  /// In en, this message translates to:
  /// **'Across all customers'**
  String get acrossAllCustomers;

  /// No description provided for @salesToday.
  ///
  /// In en, this message translates to:
  /// **'Sales today'**
  String get salesToday;

  /// No description provided for @receivedToday.
  ///
  /// In en, this message translates to:
  /// **'Received today'**
  String get receivedToday;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @latestCount.
  ///
  /// In en, this message translates to:
  /// **'Latest {count}'**
  String latestCount(int count);

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @activityWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Sales and payments will appear here.'**
  String get activityWillAppearHere;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @couldNotLoadSales.
  ///
  /// In en, this message translates to:
  /// **'Could not load sales.'**
  String get couldNotLoadSales;

  /// No description provided for @couldNotLoadPayments.
  ///
  /// In en, this message translates to:
  /// **'Could not load payments.'**
  String get couldNotLoadPayments;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @searchNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone'**
  String get searchNameOrPhone;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @couldNotLoadCustomers.
  ///
  /// In en, this message translates to:
  /// **'Could not load customers'**
  String get couldNotLoadCustomers;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get pleaseTryAgain;

  /// No description provided for @noCustomerFound.
  ///
  /// In en, this message translates to:
  /// **'No customer found'**
  String get noCustomerFound;

  /// No description provided for @noArchivedCustomers.
  ///
  /// In en, this message translates to:
  /// **'No archived customers'**
  String get noArchivedCustomers;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @tryAnotherNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Try another name or phone number.'**
  String get tryAnotherNameOrPhone;

  /// No description provided for @archivedCustomersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Archived customers will appear here.'**
  String get archivedCustomersAppearHere;

  /// No description provided for @addFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add your first MomBiz customer.'**
  String get addFirstCustomer;

  /// No description provided for @noPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhoneNumber;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @updateCustomerInformation.
  ///
  /// In en, this message translates to:
  /// **'Update customer information'**
  String get updateCustomerInformation;

  /// No description provided for @addSomeoneToMomBiz.
  ///
  /// In en, this message translates to:
  /// **'Add someone to MomBiz'**
  String get addSomeoneToMomBiz;

  /// No description provided for @onlyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Only the name is required. Phone and notes can be added later.'**
  String get onlyNameRequired;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @exampleDara.
  ///
  /// In en, this message translates to:
  /// **'Example: Dara'**
  String get exampleDara;

  /// No description provided for @pleaseEnterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the customer name.'**
  String get pleaseEnterCustomerName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @optionalCustomerInformation.
  ///
  /// In en, this message translates to:
  /// **'Optional information about this customer'**
  String get optionalCustomerInformation;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @couldNotSaveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Could not save customer. Please try again.'**
  String get couldNotSaveCustomer;

  /// No description provided for @noOutstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'This customer has no outstanding balance.'**
  String get noOutstandingBalance;

  /// No description provided for @archiveCustomerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Archive customer?'**
  String get archiveCustomerQuestion;

  /// No description provided for @archiveCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be hidden from active customers.\n\nTheir sales and payments will remain safe.'**
  String archiveCustomerMessage(String name);

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @customerRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} restored.'**
  String customerRestored(String name);

  /// No description provided for @couldNotLoadCustomer.
  ///
  /// In en, this message translates to:
  /// **'Could not load customer.'**
  String get couldNotLoadCustomer;

  /// No description provided for @customerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found.'**
  String get customerNotFound;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get outstandingBalance;

  /// No description provided for @salesMinusPayments.
  ///
  /// In en, this message translates to:
  /// **'Sales minus payments'**
  String get salesMinusPayments;

  /// No description provided for @customerFullyPaid.
  ///
  /// In en, this message translates to:
  /// **'This customer is fully paid.'**
  String get customerFullyPaid;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(int count);

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer information'**
  String get customerInformation;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get noNote;

  /// No description provided for @restoreCustomer.
  ///
  /// In en, this message translates to:
  /// **'Restore customer'**
  String get restoreCustomer;

  /// No description provided for @archiveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Archive customer'**
  String get archiveCustomer;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @receivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received {amount}'**
  String receivedAmount(String amount);

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @recordMoneyReceived.
  ///
  /// In en, this message translates to:
  /// **'Record money received from this customer.'**
  String get recordMoneyReceived;

  /// No description provided for @payingWhichBalance.
  ///
  /// In en, this message translates to:
  /// **'Paying which balance?'**
  String get payingWhichBalance;

  /// No description provided for @customerPaidIn.
  ///
  /// In en, this message translates to:
  /// **'Customer paid in'**
  String get customerPaidIn;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get amountReceived;

  /// No description provided for @example100000.
  ///
  /// In en, this message translates to:
  /// **'Example: 100000'**
  String get example100000;

  /// No description provided for @example2500.
  ///
  /// In en, this message translates to:
  /// **'Example: 25.00'**
  String get example2500;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get paymentDate;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @appliedToDebt.
  ///
  /// In en, this message translates to:
  /// **'Applied to debt'**
  String get appliedToDebt;

  /// No description provided for @balanceBefore.
  ///
  /// In en, this message translates to:
  /// **'Balance before'**
  String get balanceBefore;

  /// No description provided for @balanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get balanceAfter;

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get savePayment;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @gettingNbcRate.
  ///
  /// In en, this message translates to:
  /// **'Getting NBC exchange rate...'**
  String get gettingNbcRate;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nbcOfficialRate.
  ///
  /// In en, this message translates to:
  /// **'NBC official rate'**
  String get nbcOfficialRate;

  /// No description provided for @oneUsdEqualsKhr.
  ///
  /// In en, this message translates to:
  /// **'1 USD = {rate} KHR'**
  String oneUsdEqualsKhr(int rate);

  /// No description provided for @effectiveDateValue.
  ///
  /// In en, this message translates to:
  /// **'Effective date: {date}'**
  String effectiveDateValue(String date);

  /// No description provided for @refreshRate.
  ///
  /// In en, this message translates to:
  /// **'Refresh rate'**
  String get refreshRate;

  /// No description provided for @couldNotGetNbcRateForDate.
  ///
  /// In en, this message translates to:
  /// **'Could not get the NBC rate for this date.'**
  String get couldNotGetNbcRateForDate;

  /// No description provided for @pleaseEnterPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a payment amount.'**
  String get pleaseEnterPaymentAmount;

  /// No description provided for @nbcRateRequiredForConversion.
  ///
  /// In en, this message translates to:
  /// **'NBC exchange rate is required for this conversion.'**
  String get nbcRateRequiredForConversion;

  /// No description provided for @paymentAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'The payment amount is invalid.'**
  String get paymentAmountInvalid;

  /// No description provided for @paymentGreaterThanBalance.
  ///
  /// In en, this message translates to:
  /// **'This payment is greater than the outstanding balance.'**
  String get paymentGreaterThanBalance;

  /// No description provided for @paymentSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment saved successfully.'**
  String get paymentSavedSuccessfully;

  /// No description provided for @couldNotSavePayment.
  ///
  /// In en, this message translates to:
  /// **'Could not save payment. Please try again.'**
  String get couldNotSavePayment;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @abaQr.
  ///
  /// In en, this message translates to:
  /// **'ABA QR'**
  String get abaQr;

  /// No description provided for @acledaQr.
  ///
  /// In en, this message translates to:
  /// **'ACLEDA QR'**
  String get acledaQr;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @whoCameToBuy.
  ///
  /// In en, this message translates to:
  /// **'Who came to buy?'**
  String get whoCameToBuy;

  /// No description provided for @buyerExample.
  ///
  /// In en, this message translates to:
  /// **'Optional — e.g. Dara\'s son'**
  String get buyerExample;

  /// No description provided for @saleDate.
  ///
  /// In en, this message translates to:
  /// **'Sale date'**
  String get saleDate;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @priceEach.
  ///
  /// In en, this message translates to:
  /// **'Price each'**
  String get priceEach;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line total'**
  String get lineTotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount amount'**
  String get discountAmount;

  /// No description provided for @example50000.
  ///
  /// In en, this message translates to:
  /// **'Example: 50000'**
  String get example50000;

  /// No description provided for @example500.
  ///
  /// In en, this message translates to:
  /// **'Example: 5.00'**
  String get example500;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @saveSaleAmount.
  ///
  /// In en, this message translates to:
  /// **'Save sale • {amount}'**
  String saveSaleAmount(String amount);

  /// No description provided for @couldNotLoadCustomersOrProducts.
  ///
  /// In en, this message translates to:
  /// **'Could not load customers or products.'**
  String get couldNotLoadCustomersOrProducts;

  /// No description provided for @pleaseSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer.'**
  String get pleaseSelectCustomer;

  /// No description provided for @addAtLeastOneProduct.
  ///
  /// In en, this message translates to:
  /// **'Add at least one product.'**
  String get addAtLeastOneProduct;

  /// No description provided for @pleaseSelectProductEveryItem.
  ///
  /// In en, this message translates to:
  /// **'Please select a product for every item.'**
  String get pleaseSelectProductEveryItem;

  /// No description provided for @quantityGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero.'**
  String get quantityGreaterThanZero;

  /// No description provided for @validPriceEveryItem.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price for every item.'**
  String get validPriceEveryItem;

  /// No description provided for @discountCannotExceedSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot be greater than the subtotal.'**
  String get discountCannotExceedSubtotal;

  /// No description provided for @couldNotSaveSale.
  ///
  /// In en, this message translates to:
  /// **'Could not save the sale. Please try again.'**
  String get couldNotSaveSale;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @saleReceipt.
  ///
  /// In en, this message translates to:
  /// **'SALE RECEIPT'**
  String get saleReceipt;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @couldNotLoadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Could not load receipt.'**
  String get couldNotLoadReceipt;

  /// No description provided for @saleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sale not found.'**
  String get saleNotFound;

  /// No description provided for @amountDueForSale.
  ///
  /// In en, this message translates to:
  /// **'Amount due for this sale'**
  String get amountDueForSale;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get shareReceipt;

  /// No description provided for @openingShare.
  ///
  /// In en, this message translates to:
  /// **'Opening share...'**
  String get openingShare;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @couldNotShareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Could not share receipt image.'**
  String get couldNotShareReceipt;

  /// No description provided for @receiptForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Receipt for {name}'**
  String receiptForCustomer(String name);

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @couldNotLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Could not load products.'**
  String get couldNotLoadProducts;

  /// No description provided for @noArchivedProducts.
  ///
  /// In en, this message translates to:
  /// **'No archived products'**
  String get noArchivedProducts;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @archivedProductsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Archived products will appear here.'**
  String get archivedProductsAppearHere;

  /// No description provided for @addProductsMomSells.
  ///
  /// In en, this message translates to:
  /// **'Add the products your mom sells.'**
  String get addProductsMomSells;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @exampleChickenFood.
  ///
  /// In en, this message translates to:
  /// **'Example: Chicken food'**
  String get exampleChickenFood;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @exampleFeed.
  ///
  /// In en, this message translates to:
  /// **'Example: Feed'**
  String get exampleFeed;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @exampleUnits.
  ///
  /// In en, this message translates to:
  /// **'Example: bag, bottle, kg'**
  String get exampleUnits;

  /// No description provided for @defaultPrice.
  ///
  /// In en, this message translates to:
  /// **'Default price'**
  String get defaultPrice;

  /// No description provided for @defaultPriceHelp.
  ///
  /// In en, this message translates to:
  /// **'This price will be suggested when creating a sale. You can still change the price for each sale.'**
  String get defaultPriceHelp;

  /// No description provided for @defaultPriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional — leave this blank if the product has no usual price.'**
  String get defaultPriceOptional;

  /// No description provided for @example65000.
  ///
  /// In en, this message translates to:
  /// **'Example: 65000'**
  String get example65000;

  /// No description provided for @example1600.
  ///
  /// In en, this message translates to:
  /// **'Example: 16.00'**
  String get example1600;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name.'**
  String get pleaseEnterProductName;

  /// No description provided for @pleaseEnterCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category.'**
  String get pleaseEnterCategory;

  /// No description provided for @pleaseEnterUnit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a unit.'**
  String get pleaseEnterUnit;

  /// No description provided for @pleaseEnterValidDefaultPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid default price.'**
  String get pleaseEnterValidDefaultPrice;

  /// No description provided for @couldNotUpdateProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not update product.'**
  String get couldNotUpdateProduct;

  /// No description provided for @couldNotAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not add product.'**
  String get couldNotAddProduct;

  /// No description provided for @chickQueue.
  ///
  /// In en, this message translates to:
  /// **'Chick Queue'**
  String get chickQueue;

  /// No description provided for @addReservation.
  ///
  /// In en, this message translates to:
  /// **'Add reservation'**
  String get addReservation;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @couldNotLoadChickQueue.
  ///
  /// In en, this message translates to:
  /// **'Could not load chick queue.'**
  String get couldNotLoadChickQueue;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistoryYet;

  /// No description provided for @noCustomersWaitingForChicks.
  ///
  /// In en, this message translates to:
  /// **'No customers waiting for chicks.'**
  String get noCustomersWaitingForChicks;

  /// No description provided for @batchDateValue.
  ///
  /// In en, this message translates to:
  /// **'Batch: {date}'**
  String batchDateValue(String date);

  /// No description provided for @currentBatchValue.
  ///
  /// In en, this message translates to:
  /// **'Current batch: {date}'**
  String currentBatchValue(String date);

  /// No description provided for @customerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer} other{{count} customers}}'**
  String customerCount(int count);

  /// No description provided for @chickCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chick} other{{count} chicks}}'**
  String chickCount(int count);

  /// No description provided for @cancelReservationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation?'**
  String get cancelReservationQuestion;

  /// No description provided for @nextCustomer.
  ///
  /// In en, this message translates to:
  /// **'Next customer'**
  String get nextCustomer;

  /// No description provided for @moveCustomerForwardQuestion.
  ///
  /// In en, this message translates to:
  /// **'Move {name} forward to {date}?'**
  String moveCustomerForwardQuestion(String name, String date);

  /// No description provided for @keepReservation.
  ///
  /// In en, this message translates to:
  /// **'Keep reservation'**
  String get keepReservation;

  /// No description provided for @cancelOnly.
  ///
  /// In en, this message translates to:
  /// **'Cancel only'**
  String get cancelOnly;

  /// No description provided for @cancelAndMoveNext.
  ///
  /// In en, this message translates to:
  /// **'Cancel & move next'**
  String get cancelAndMoveNext;

  /// No description provided for @reservationCancelledAndMoved.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled and next customer moved forward.'**
  String get reservationCancelledAndMoved;

  /// No description provided for @reservationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled.'**
  String get reservationCancelled;

  /// No description provided for @couldNotCancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel reservation.'**
  String get couldNotCancelReservation;

  /// No description provided for @customerPickedUpChicksQuestion.
  ///
  /// In en, this message translates to:
  /// **'Customer picked up chicks?'**
  String get customerPickedUpChicksQuestion;

  /// No description provided for @saleCreatedBeforePickup.
  ///
  /// In en, this message translates to:
  /// **'A sale will be created before this reservation is marked as picked up.'**
  String get saleCreatedBeforePickup;

  /// No description provided for @createSale.
  ///
  /// In en, this message translates to:
  /// **'Create sale'**
  String get createSale;

  /// No description provided for @customerMarkedPickedUp.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as picked up.'**
  String customerMarkedPickedUp(String name);

  /// No description provided for @saleSavedButPickupFailed.
  ///
  /// In en, this message translates to:
  /// **'Sale was saved, but the reservation could not be marked as picked up.'**
  String get saleSavedButPickupFailed;

  /// No description provided for @editReservation.
  ///
  /// In en, this message translates to:
  /// **'Edit reservation'**
  String get editReservation;

  /// No description provided for @pickedUpCreateSale.
  ///
  /// In en, this message translates to:
  /// **'Picked up / Create sale'**
  String get pickedUpCreateSale;

  /// No description provided for @cancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation'**
  String get cancelReservation;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get pickedUp;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @editChickReservation.
  ///
  /// In en, this message translates to:
  /// **'Edit Chick Reservation'**
  String get editChickReservation;

  /// No description provided for @newChickReservation.
  ///
  /// In en, this message translates to:
  /// **'New Chick Reservation'**
  String get newChickReservation;

  /// No description provided for @numberOfChicks.
  ///
  /// In en, this message translates to:
  /// **'Number of chicks'**
  String get numberOfChicks;

  /// No description provided for @example100.
  ///
  /// In en, this message translates to:
  /// **'Example: 100'**
  String get example100;

  /// No description provided for @reservationDate.
  ///
  /// In en, this message translates to:
  /// **'Reservation date'**
  String get reservationDate;

  /// No description provided for @scheduledBatchDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled batch date'**
  String get scheduledBatchDate;

  /// No description provided for @pleaseEnterValidChickQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid chick quantity.'**
  String get pleaseEnterValidChickQuantity;

  /// No description provided for @couldNotUpdateReservation.
  ///
  /// In en, this message translates to:
  /// **'Could not update reservation.'**
  String get couldNotUpdateReservation;

  /// No description provided for @couldNotSaveReservation.
  ///
  /// In en, this message translates to:
  /// **'Could not save reservation.'**
  String get couldNotSaveReservation;

  /// No description provided for @saveReservation.
  ///
  /// In en, this message translates to:
  /// **'Save reservation'**
  String get saveReservation;

  /// No description provided for @latestOfficialNbcRate.
  ///
  /// In en, this message translates to:
  /// **'Latest official NBC rate'**
  String get latestOfficialNbcRate;

  /// No description provided for @notLoaded.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get notLoaded;

  /// No description provided for @rateSource.
  ///
  /// In en, this message translates to:
  /// **'Rate source'**
  String get rateSource;

  /// No description provided for @nbcViaFrankfurter.
  ///
  /// In en, this message translates to:
  /// **'NBC via Frankfurter'**
  String get nbcViaFrankfurter;

  /// No description provided for @getNbcRate.
  ///
  /// In en, this message translates to:
  /// **'Get NBC rate'**
  String get getNbcRate;

  /// No description provided for @refreshNbcRate.
  ///
  /// In en, this message translates to:
  /// **'Refresh NBC rate'**
  String get refreshNbcRate;

  /// No description provided for @nbcRateUpdated.
  ///
  /// In en, this message translates to:
  /// **'NBC rate updated: 1 USD = {rate} KHR'**
  String nbcRateUpdated(String rate);

  /// No description provided for @couldNotUpdateNbcRate.
  ///
  /// In en, this message translates to:
  /// **'Could not update NBC rate.\n{error}'**
  String couldNotUpdateNbcRate(String error);

  /// No description provided for @couldNotLoadSavedExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Could not load the saved exchange rate.\n\n{error}'**
  String couldNotLoadSavedExchangeRate(String error);

  /// No description provided for @exchangeRateExplanation.
  ///
  /// In en, this message translates to:
  /// **'MomBiz keeps the latest official NBC reference rate. The next working-day rate is normally published later in the working day, so the effective date may still show the previous day before the new rate is published.'**
  String get exchangeRateExplanation;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose app appearance'**
  String get chooseTheme;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
