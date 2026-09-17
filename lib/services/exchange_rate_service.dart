import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/exchange_rate.dart';

class ExchangeRateService {
  ExchangeRateService._();

  static final ExchangeRateService instance = ExchangeRateService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _host = 'api.frankfurter.dev';

  static const String _path = '/v2/providers/nbc/rate/usd/khr';

  DocumentReference<Map<String, dynamic>> get _currentRateDocument {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('exchangeRate');
  }

  Stream<ExchangeRate?> watchCurrentRate() {
    return _currentRateDocument.snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return ExchangeRate.fromFirestore(document);
    });
  }

  Future<ExchangeRate?> getCurrentRate() async {
    final document = await _currentRateDocument.get();

    if (!document.exists) {
      return null;
    }

    return ExchangeRate.fromFirestore(document);
  }

  // Used by the Exchange Rate screen.
  // Fetches the latest NBC rate and saves it as
  // MomBiz's current exchange rate.
  Future<ExchangeRate> fetchNbcRate() async {
    final rate = await _fetchRate();

    await _currentRateDocument.set({
      'khrPerUsd': rate.khrPerUsd,
      'rateDate': Timestamp.fromDate(rate.rateDate),
      'source': rate.source,
      'fetchedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return rate;
  }

  // Used when recording historical payments.
  // IMPORTANT:
  // This does NOT replace the current saved rate.
  Future<ExchangeRate> fetchNbcRateForDate(DateTime date) async {
    return _fetchRate(date: date);
  }

  Future<ExchangeRate> _fetchRate({DateTime? date}) async {
    final Uri url;

    if (date == null) {
      url = Uri.https(_host, _path);
    } else {
      url = Uri.https(_host, _path, {'date': _dateForApi(date)});
    }

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Could not get NBC exchange rate. '
        'HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid NBC exchange rate response.');
    }

    final rateValue = decoded['rate'];

    if (rateValue is! num || rateValue <= 0) {
      throw Exception('NBC USD/KHR rate was not found.');
    }

    final dateText = decoded['date'] as String?;

    if (dateText == null) {
      throw Exception('NBC rate date was not found.');
    }

    final rateDate = DateTime.tryParse(dateText);

    if (rateDate == null) {
      throw Exception('NBC rate date was invalid.');
    }

    return ExchangeRate(
      khrPerUsd: rateValue.round(),
      rateDate: rateDate,
      source: 'NBC via Frankfurter',
      updatedAt: DateTime.now().toUtc(),
    );
  }

  String _dateForApi(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  DateTime? _lastAutoRefresh;

  Future<void> refreshIfNeeded({bool force = false}) async {
    final now = DateTime.now();

    if (!force &&
        _lastAutoRefresh != null &&
        now.difference(_lastAutoRefresh!).inMinutes < 15) {
      return;
    }

    _lastAutoRefresh = now;

    try {
      await fetchNbcRate();
    } catch (_) {
      // Keep the previously saved rate if internet/NBC is unavailable.
    }
  }
}
