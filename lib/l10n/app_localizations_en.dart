// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MomBiz';

  @override
  String get home => 'Home';

  @override
  String get customers => 'Customers';

  @override
  String get queue => 'Queue';

  @override
  String get more => 'More';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get khmer => 'Khmer';

  @override
  String get chooseLanguage => 'Choose app language';

  @override
  String get settings => 'Settings';

  @override
  String get products => 'Products';

  @override
  String get productsSubtitle => 'Animal feed, vaccine, fertilizer and more';

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get exchangeRateSubtitle => 'NBC official USD / KHR rate';

  @override
  String get signOut => 'Sign out';

  @override
  String get newSale => 'New sale';

  @override
  String get payment => 'Payment';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get systemTheme => 'System default';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get businessOverview => 'Business overview';

  @override
  String get outstandingCustomerDebt => 'Outstanding customer debt';

  @override
  String get noOutstandingDebt => 'No outstanding customer debt.';

  @override
  String get acrossAllCustomers => 'Across all customers';

  @override
  String get salesToday => 'Sales today';

  @override
  String get receivedToday => 'Received today';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String latestCount(int count) {
    return 'Latest $count';
  }

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get activityWillAppearHere => 'Sales and payments will appear here.';

  @override
  String get sale => 'Sale';

  @override
  String get couldNotLoadSales => 'Could not load sales.';

  @override
  String get couldNotLoadPayments => 'Could not load payments.';

  @override
  String get addCustomer => 'Add customer';

  @override
  String get searchNameOrPhone => 'Search name or phone';

  @override
  String get active => 'Active';

  @override
  String get archived => 'Archived';

  @override
  String get couldNotLoadCustomers => 'Could not load customers';

  @override
  String get pleaseTryAgain => 'Please try again.';

  @override
  String get noCustomerFound => 'No customer found';

  @override
  String get noArchivedCustomers => 'No archived customers';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get tryAnotherNameOrPhone => 'Try another name or phone number.';

  @override
  String get archivedCustomersAppearHere =>
      'Archived customers will appear here.';

  @override
  String get addFirstCustomer => 'Add your first MomBiz customer.';

  @override
  String get noPhoneNumber => 'No phone number';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get newCustomer => 'New customer';

  @override
  String get updateCustomerInformation => 'Update customer information';

  @override
  String get addSomeoneToMomBiz => 'Add someone to MomBiz';

  @override
  String get onlyNameRequired =>
      'Only the name is required. Phone and notes can be added later.';

  @override
  String get customerName => 'Customer name';

  @override
  String get exampleDara => 'Example: Dara';

  @override
  String get pleaseEnterCustomerName => 'Please enter the customer name.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get optional => 'Optional';

  @override
  String get note => 'Note';

  @override
  String get optionalCustomerInformation =>
      'Optional information about this customer';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get couldNotSaveCustomer =>
      'Could not save customer. Please try again.';

  @override
  String get noOutstandingBalance =>
      'This customer has no outstanding balance.';

  @override
  String get archiveCustomerQuestion => 'Archive customer?';

  @override
  String archiveCustomerMessage(String name) {
    return '$name will be hidden from active customers.\n\nTheir sales and payments will remain safe.';
  }

  @override
  String get archive => 'Archive';

  @override
  String customerRestored(String name) {
    return '$name restored.';
  }

  @override
  String get couldNotLoadCustomer => 'Could not load customer.';

  @override
  String get customerNotFound => 'Customer not found.';

  @override
  String get outstandingBalance => 'Outstanding balance';

  @override
  String get salesMinusPayments => 'Sales minus payments';

  @override
  String get customerFullyPaid => 'This customer is fully paid.';

  @override
  String get activity => 'Activity';

  @override
  String recordsCount(int count) {
    return '$count records';
  }

  @override
  String get customerInformation => 'Customer information';

  @override
  String get phone => 'Phone';

  @override
  String get notProvided => 'Not provided';

  @override
  String get noNote => 'No note';

  @override
  String get restoreCustomer => 'Restore customer';

  @override
  String get archiveCustomer => 'Archive customer';

  @override
  String get paymentReceived => 'Payment received';

  @override
  String receivedAmount(String amount) {
    return 'Received $amount';
  }

  @override
  String get recordPayment => 'Record payment';

  @override
  String get recordMoneyReceived => 'Record money received from this customer.';

  @override
  String get payingWhichBalance => 'Paying which balance?';

  @override
  String get customerPaidIn => 'Customer paid in';

  @override
  String get amountReceived => 'Amount received';

  @override
  String get example100000 => 'Example: 100000';

  @override
  String get example2500 => 'Example: 25.00';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentDate => 'Payment date';

  @override
  String get received => 'Received';

  @override
  String get appliedToDebt => 'Applied to debt';

  @override
  String get balanceBefore => 'Balance before';

  @override
  String get balanceAfter => 'Balance after';

  @override
  String get savePayment => 'Save payment';

  @override
  String get saving => 'Saving...';

  @override
  String get gettingNbcRate => 'Getting NBC exchange rate...';

  @override
  String get tryAgain => 'Try again';

  @override
  String get nbcOfficialRate => 'NBC official rate';

  @override
  String oneUsdEqualsKhr(int rate) {
    return '1 USD = $rate KHR';
  }

  @override
  String effectiveDateValue(String date) {
    return 'Effective date: $date';
  }

  @override
  String get refreshRate => 'Refresh rate';

  @override
  String get couldNotGetNbcRateForDate =>
      'Could not get the NBC rate for this date.';

  @override
  String get pleaseEnterPaymentAmount => 'Please enter a payment amount.';

  @override
  String get nbcRateRequiredForConversion =>
      'NBC exchange rate is required for this conversion.';

  @override
  String get paymentAmountInvalid => 'The payment amount is invalid.';

  @override
  String get paymentGreaterThanBalance =>
      'This payment is greater than the outstanding balance.';

  @override
  String get paymentSavedSuccessfully => 'Payment saved successfully.';

  @override
  String get couldNotSavePayment => 'Could not save payment. Please try again.';

  @override
  String get cash => 'Cash';

  @override
  String get abaQr => 'ABA QR';

  @override
  String get acledaQr => 'ACLEDA QR';

  @override
  String get other => 'Other';

  @override
  String get customer => 'Customer';

  @override
  String get whoCameToBuy => 'Who came to buy?';

  @override
  String get buyerExample => 'Optional — e.g. Dara\'s son';

  @override
  String get saleDate => 'Sale date';

  @override
  String get currency => 'Currency';

  @override
  String get addItem => 'Add item';

  @override
  String get product => 'Product';

  @override
  String get quantity => 'Quantity';

  @override
  String get priceEach => 'Price each';

  @override
  String get lineTotal => 'Line total';

  @override
  String get discount => 'Discount';

  @override
  String get discountAmount => 'Discount amount';

  @override
  String get example50000 => 'Example: 50000';

  @override
  String get example500 => 'Example: 5.00';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String get removeItem => 'Remove item';

  @override
  String saveSaleAmount(String amount) {
    return 'Save sale • $amount';
  }

  @override
  String get couldNotLoadCustomersOrProducts =>
      'Could not load customers or products.';

  @override
  String get pleaseSelectCustomer => 'Please select a customer.';

  @override
  String get addAtLeastOneProduct => 'Add at least one product.';

  @override
  String get pleaseSelectProductEveryItem =>
      'Please select a product for every item.';

  @override
  String get quantityGreaterThanZero => 'Quantity must be greater than zero.';

  @override
  String get validPriceEveryItem =>
      'Please enter a valid price for every item.';

  @override
  String get discountCannotExceedSubtotal =>
      'Discount cannot be greater than the subtotal.';

  @override
  String get couldNotSaveSale => 'Could not save the sale. Please try again.';

  @override
  String get receipt => 'Receipt';

  @override
  String get saleReceipt => 'SALE RECEIPT';

  @override
  String get buyer => 'Buyer';

  @override
  String get date => 'Date';

  @override
  String get couldNotLoadReceipt => 'Could not load receipt.';

  @override
  String get saleNotFound => 'Sale not found.';

  @override
  String get amountDueForSale => 'Amount due for this sale';

  @override
  String get shareReceipt => 'Share receipt';

  @override
  String get openingShare => 'Opening share...';

  @override
  String get done => 'Done';

  @override
  String get couldNotShareReceipt => 'Could not share receipt image.';

  @override
  String receiptForCustomer(String name) {
    return 'Receipt for $name';
  }

  @override
  String get addProduct => 'Add product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get searchProducts => 'Search products';

  @override
  String get couldNotLoadProducts => 'Could not load products.';

  @override
  String get noArchivedProducts => 'No archived products';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get archivedProductsAppearHere =>
      'Archived products will appear here.';

  @override
  String get addProductsMomSells => 'Add the products your mom sells.';

  @override
  String get productName => 'Product name';

  @override
  String get exampleChickenFood => 'Example: Chicken food';

  @override
  String get category => 'Category';

  @override
  String get exampleFeed => 'Example: Feed';

  @override
  String get unit => 'Unit';

  @override
  String get exampleUnits => 'Example: bag, bottle, kg';

  @override
  String get defaultPrice => 'Default price';

  @override
  String get defaultPriceHelp =>
      'This price will be suggested when creating a sale. You can still change the price for each sale.';

  @override
  String get defaultPriceOptional =>
      'Optional — leave this blank if the product has no usual price.';

  @override
  String get example65000 => 'Example: 65000';

  @override
  String get example1600 => 'Example: 16.00';

  @override
  String get pleaseEnterProductName => 'Please enter a product name.';

  @override
  String get pleaseEnterCategory => 'Please enter a category.';

  @override
  String get pleaseEnterUnit => 'Please enter a unit.';

  @override
  String get pleaseEnterValidDefaultPrice =>
      'Please enter a valid default price.';

  @override
  String get couldNotUpdateProduct => 'Could not update product.';

  @override
  String get couldNotAddProduct => 'Could not add product.';

  @override
  String get chickQueue => 'Chick Queue';

  @override
  String get addReservation => 'Add reservation';

  @override
  String get waiting => 'Waiting';

  @override
  String get history => 'History';

  @override
  String get couldNotLoadChickQueue => 'Could not load chick queue.';

  @override
  String get noHistoryYet => 'No history yet.';

  @override
  String get noCustomersWaitingForChicks => 'No customers waiting for chicks.';

  @override
  String batchDateValue(String date) {
    return 'Batch: $date';
  }

  @override
  String currentBatchValue(String date) {
    return 'Current batch: $date';
  }

  @override
  String customerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '1 customer',
    );
    return '$_temp0';
  }

  @override
  String chickCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chicks',
      one: '1 chick',
    );
    return '$_temp0';
  }

  @override
  String get cancelReservationQuestion => 'Cancel reservation?';

  @override
  String get nextCustomer => 'Next customer';

  @override
  String moveCustomerForwardQuestion(String name, String date) {
    return 'Move $name forward to $date?';
  }

  @override
  String get keepReservation => 'Keep reservation';

  @override
  String get cancelOnly => 'Cancel only';

  @override
  String get cancelAndMoveNext => 'Cancel & move next';

  @override
  String get reservationCancelledAndMoved =>
      'Reservation cancelled and next customer moved forward.';

  @override
  String get reservationCancelled => 'Reservation cancelled.';

  @override
  String get couldNotCancelReservation => 'Could not cancel reservation.';

  @override
  String get customerPickedUpChicksQuestion => 'Customer picked up chicks?';

  @override
  String get saleCreatedBeforePickup =>
      'A sale will be created before this reservation is marked as picked up.';

  @override
  String get createSale => 'Create sale';

  @override
  String customerMarkedPickedUp(String name) {
    return '$name marked as picked up.';
  }

  @override
  String get saleSavedButPickupFailed =>
      'Sale was saved, but the reservation could not be marked as picked up.';

  @override
  String get editReservation => 'Edit reservation';

  @override
  String get pickedUpCreateSale => 'Picked up / Create sale';

  @override
  String get cancelReservation => 'Cancel reservation';

  @override
  String get pickedUp => 'Picked up';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get editChickReservation => 'Edit Chick Reservation';

  @override
  String get newChickReservation => 'New Chick Reservation';

  @override
  String get numberOfChicks => 'Number of chicks';

  @override
  String get example100 => 'Example: 100';

  @override
  String get reservationDate => 'Reservation date';

  @override
  String get scheduledBatchDate => 'Scheduled batch date';

  @override
  String get pleaseEnterValidChickQuantity =>
      'Please enter a valid chick quantity.';

  @override
  String get couldNotUpdateReservation => 'Could not update reservation.';

  @override
  String get couldNotSaveReservation => 'Could not save reservation.';

  @override
  String get saveReservation => 'Save reservation';

  @override
  String get latestOfficialNbcRate => 'Latest official NBC rate';

  @override
  String get notLoaded => 'Not loaded';

  @override
  String get rateSource => 'Rate source';

  @override
  String get nbcViaFrankfurter => 'NBC via Frankfurter';

  @override
  String get getNbcRate => 'Get NBC rate';

  @override
  String get refreshNbcRate => 'Refresh NBC rate';

  @override
  String nbcRateUpdated(String rate) {
    return 'NBC rate updated: 1 USD = $rate KHR';
  }

  @override
  String couldNotUpdateNbcRate(String error) {
    return 'Could not update NBC rate.\n$error';
  }

  @override
  String couldNotLoadSavedExchangeRate(String error) {
    return 'Could not load the saved exchange rate.\n\n$error';
  }

  @override
  String get exchangeRateExplanation =>
      'MomBiz keeps the latest official NBC reference rate. The next working-day rate is normally published later in the working day, so the effective date may still show the previous day before the new rate is published.';

  @override
  String get theme => 'Theme';

  @override
  String get chooseTheme => 'Choose app appearance';
}
