import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessInsightsData {
  const BusinessInsightsData({
    required this.salesThisMonthKhr,
    required this.salesThisMonthUsd,
    required this.salesLastMonthKhr,
    required this.salesLastMonthUsd,
    required this.receivedThisMonthKhr,
    required this.receivedThisMonthUsd,
    required this.outstandingKhr,
    required this.outstandingUsd,
    required this.customersWithDebt,
    required this.waitingReservations,
    required this.waitingCustomers,
    required this.waitingChicks,
    required this.pickedUpThisMonthReservations,
    required this.pickedUpThisMonthCustomers,
    required this.pickedUpThisMonthChicks,
  });

  final int salesThisMonthKhr;
  final int salesThisMonthUsd;

  final int salesLastMonthKhr;
  final int salesLastMonthUsd;

  final int receivedThisMonthKhr;
  final int receivedThisMonthUsd;

  final int outstandingKhr;
  final int outstandingUsd;
  final int customersWithDebt;

  final int waitingReservations;
  final int waitingCustomers;
  final int waitingChicks;

  final int pickedUpThisMonthReservations;
  final int pickedUpThisMonthCustomers;
  final int pickedUpThisMonthChicks;
}

class BusinessInsightsService {
  BusinessInsightsService._();

  static final BusinessInsightsService instance =
      BusinessInsightsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in.',
      );
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>>
      get _userDocument {
    return _firestore
        .collection('users')
        .doc(_userId);
  }

  Future<BusinessInsightsData> load() async {
    final now =
        DateTime.now();

    final thisMonthStart =
        DateTime(
      now.year,
      now.month,
      1,
    );

    final nextMonthStart =
        DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final lastMonthStart =
        DateTime(
      now.year,
      now.month - 1,
      1,
    );

    final results =
        await Future.wait([
      _userDocument
          .collection('sales')
          .get(),

      _userDocument
          .collection('payments')
          .get(),

      _userDocument
          .collection('chickReservations')
          .get(),
    ]);

    final salesSnapshot =
        results[0];

    final paymentsSnapshot =
        results[1];

    final queueSnapshot =
        results[2];

    var salesThisMonthKhr = 0;
    var salesThisMonthUsd = 0;

    var salesLastMonthKhr = 0;
    var salesLastMonthUsd = 0;

    var receivedThisMonthKhr = 0;
    var receivedThisMonthUsd = 0;

    final customerBalances =
        <String, _CustomerBalance>{};

    for (final document
        in salesSnapshot.docs) {
      final data =
          document.data();

      final status =
          data['status'] as String? ??
              'active';

      if (status != 'active') {
        continue;
      }

      final currency =
          _currencyCode(
        data['currency'],
      );

      final totalMinor =
          _intValue(
        data['totalMinor'],
      );

      final saleDate =
          _dateValue(
                data['saleDate'],
              ) ??
              _dateValue(
                data['createdAt'],
              );

      if (saleDate != null) {
        if (_inRange(
          saleDate,
          thisMonthStart,
          nextMonthStart,
        )) {
          if (currency == 'USD') {
            salesThisMonthUsd +=
                totalMinor;
          } else {
            salesThisMonthKhr +=
                totalMinor;
          }
        } else if (_inRange(
          saleDate,
          lastMonthStart,
          thisMonthStart,
        )) {
          if (currency == 'USD') {
            salesLastMonthUsd +=
                totalMinor;
          } else {
            salesLastMonthKhr +=
                totalMinor;
          }
        }
      }

      final customerKey =
          _customerKey(
        document.id,
        data,
      );

      final balance =
          customerBalances
              .putIfAbsent(
        customerKey,
        _CustomerBalance.new,
      );

      if (currency == 'USD') {
        balance.usd +=
            totalMinor;
      } else {
        balance.khr +=
            totalMinor;
      }
    }

    for (final document
        in paymentsSnapshot.docs) {
      final data =
          document.data();

      final status =
          data['status'] as String? ??
              'active';

      if (status != 'active') {
        continue;
      }

      final paymentDate =
          _dateValue(
                data['paymentDate'],
              ) ??
              _dateValue(
                data['createdAt'],
              );

      if (paymentDate != null &&
          _inRange(
            paymentDate,
            thisMonthStart,
            nextMonthStart,
          )) {
        final paidCurrency =
            _currencyCode(
          data['paidCurrency'],
        );

        final paidAmount =
            _intValue(
          data['paidAmountMinor'],
        );

        if (paidCurrency == 'USD') {
          receivedThisMonthUsd +=
              paidAmount;
        } else {
          receivedThisMonthKhr +=
              paidAmount;
        }
      }

      final customerKey =
          _customerKey(
        document.id,
        data,
      );

      final balance =
          customerBalances
              .putIfAbsent(
        customerKey,
        _CustomerBalance.new,
      );

      final appliedCurrency =
          _currencyCode(
        data['appliedCurrency'],
      );

      final appliedAmount =
          _intValue(
        data['appliedAmountMinor'],
      );

      if (appliedCurrency ==
          'USD') {
        balance.usd -=
            appliedAmount;
      } else {
        balance.khr -=
            appliedAmount;
      }
    }

    var outstandingKhr = 0;
    var outstandingUsd = 0;
    var customersWithDebt = 0;

    for (final balance
        in customerBalances.values) {
      final khr =
          balance.khr < 0
              ? 0
              : balance.khr;

      final usd =
          balance.usd < 0
              ? 0
              : balance.usd;

      outstandingKhr += khr;
      outstandingUsd += usd;

      if (khr > 0 || usd > 0) {
        customersWithDebt++;
      }
    }

    var waitingReservations = 0;
    var waitingChicks = 0;

    final waitingCustomerKeys =
        <String>{};

    var pickedUpThisMonthReservations =
        0;

    var pickedUpThisMonthChicks =
        0;

    final pickedUpCustomerKeys =
        <String>{};

    for (final document
        in queueSnapshot.docs) {
      final data =
          document.data();

      final status =
          data['status'] as String? ??
              'waiting';

      final quantity =
          _intValue(
        data['quantity'],
      );

      final customerKey =
          _customerKey(
        document.id,
        data,
      );

      if (status == 'waiting') {
        waitingReservations++;
        waitingChicks +=
            quantity;

        waitingCustomerKeys.add(
          customerKey,
        );

        continue;
      }

      if (status != 'pickedUp') {
        continue;
      }

      final activityDate =
          _dateValue(
                data['updatedAt'],
              ) ??
              _dateValue(
                data['scheduledDate'],
              ) ??
              _dateValue(
                data['reservationDate'],
              );

      if (activityDate != null &&
          _inRange(
            activityDate,
            thisMonthStart,
            nextMonthStart,
          )) {
        pickedUpThisMonthReservations++;

        pickedUpThisMonthChicks +=
            quantity;

        pickedUpCustomerKeys.add(
          customerKey,
        );
      }
    }

    return BusinessInsightsData(
      salesThisMonthKhr:
          salesThisMonthKhr,
      salesThisMonthUsd:
          salesThisMonthUsd,
      salesLastMonthKhr:
          salesLastMonthKhr,
      salesLastMonthUsd:
          salesLastMonthUsd,
      receivedThisMonthKhr:
          receivedThisMonthKhr,
      receivedThisMonthUsd:
          receivedThisMonthUsd,
      outstandingKhr:
          outstandingKhr,
      outstandingUsd:
          outstandingUsd,
      customersWithDebt:
          customersWithDebt,
      waitingReservations:
          waitingReservations,
      waitingCustomers:
          waitingCustomerKeys.length,
      waitingChicks:
          waitingChicks,
      pickedUpThisMonthReservations:
          pickedUpThisMonthReservations,
      pickedUpThisMonthCustomers:
          pickedUpCustomerKeys.length,
      pickedUpThisMonthChicks:
          pickedUpThisMonthChicks,
    );
  }

  String _customerKey(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final customerId =
        (data['customerId']
                as String?)
            ?.trim();

    if (customerId != null &&
        customerId.isNotEmpty) {
      return customerId;
    }

    return 'document:$documentId';
  }

  String _currencyCode(
    dynamic value,
  ) {
    final code =
        value?.toString()
            .trim()
            .toUpperCase();

    return code == 'USD'
        ? 'USD'
        : 'KHR';
  }

  int _intValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  DateTime? _dateValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value
          .toDate()
          .toLocal();
    }

    if (value is DateTime) {
      return value.toLocal();
    }

    return null;
  }

  bool _inRange(
    DateTime value,
    DateTime start,
    DateTime end,
  ) {
    return !value.isBefore(start) &&
        value.isBefore(end);
  }
}

class _CustomerBalance {
  int khr = 0;
  int usd = 0;
}
