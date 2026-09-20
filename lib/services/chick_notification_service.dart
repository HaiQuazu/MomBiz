import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/chick_reservation.dart';
import 'app_settings_service.dart';

class ChickNotificationService {
  ChickNotificationService._();

  static final ChickNotificationService instance = ChickNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'chick_batch_reminders';

  static const String _channelName = 'Chick batch reminders';

  static const String _channelDescription =
      'Reminders for upcoming chick pickup batches';

  static const String queuePayload = 'open_chick_queue';

  final StreamController<bool> _queueOpenController =
      StreamController<bool>.broadcast();

  bool _initialized = false;

  bool _pendingQueueOpenRequest = false;

  // ------------------------------------------------
  // LANGUAGE
  // ------------------------------------------------

  bool get _isKhmer {
    return AppSettingsService.instance.locale.languageCode == 'km';
  }

  // ------------------------------------------------
  // QUEUE OPEN REQUESTS
  // ------------------------------------------------

  Stream<bool> get queueOpenRequests => _queueOpenController.stream;

  bool consumePendingQueueOpenRequest() {
    if (!_pendingQueueOpenRequest) {
      return false;
    }

    _pendingQueueOpenRequest = false;
    return true;
  }

  void _requestQueueOpen() {
    _pendingQueueOpenRequest = true;

    if (!_queueOpenController.isClosed) {
      _queueOpenController.add(true);
    }
  }

  // ------------------------------------------------
  // INITIALIZE
  // ------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Phnom_Penh'));

    const androidSettings = AndroidInitializationSettings('ic_stat_mombiz');

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Handles MomBiz being completely closed
    // when the notification is tapped.
    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();

    final didLaunchFromNotification =
        launchDetails?.didNotificationLaunchApp ?? false;

    final launchPayload = launchDetails?.notificationResponse?.payload;

    if (didLaunchFromNotification && launchPayload == queuePayload) {
      _pendingQueueOpenRequest = true;
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != queuePayload) {
      return;
    }

    _requestQueueOpen();
  }

  // ------------------------------------------------
  // ANDROID NOTIFICATION PERMISSION
  // ------------------------------------------------

  Future<bool> requestPermission() async {
    await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final result = await androidPlugin?.requestNotificationsPermission();

    return result ?? true;
  }

  // ------------------------------------------------
  // SYNC WAITING RESERVATIONS
  // ------------------------------------------------

  Future<void> syncReservations(List<ChickReservation> reservations) async {
    await initialize();

    final waiting = reservations
        .where(
          (reservation) => reservation.status == ChickReservationStatus.waiting,
        )
        .toList();

    // Rebuild reminders using the latest
    // queue and currently selected language.
    await _cancelAllBatchNotifications();

    if (waiting.isEmpty) {
      return;
    }

    final batches = <String, List<ChickReservation>>{};

    for (final reservation in waiting) {
      final key = _dateKey(reservation.scheduledDate);

      batches.putIfAbsent(key, () => []).add(reservation);
    }

    for (final entry in batches.entries) {
      final reservationsForBatch = entry.value;

      if (reservationsForBatch.isEmpty) {
        continue;
      }

      final batchDate = reservationsForBatch.first.scheduledDate;

      final customerCount = reservationsForBatch.length;

      final chickCount = reservationsForBatch.fold<int>(
        0,
        (total, reservation) => total + reservation.quantity,
      );

      await _scheduleBatch(
        batchDate: batchDate,
        customerCount: customerCount,
        chickCount: chickCount,
      );
    }
  }

  // ------------------------------------------------
  // SCHEDULE ONE BATCH
  // ------------------------------------------------

  Future<void> _scheduleBatch({
    required DateTime batchDate,
    required int customerCount,
    required int chickCount,
  }) async {
    final batchDay = tz.TZDateTime(
      tz.local,
      batchDate.year,
      batchDate.month,
      batchDate.day,
    );

    // Day before at 8:00 AM.
    final oneDayBefore = tz.TZDateTime(
      tz.local,
      batchDate.year,
      batchDate.month,
      batchDate.day - 1,
      8,
    );

    // Batch day at 8:00 AM.
    final batchMorning = tz.TZDateTime(
      tz.local,
      batchDate.year,
      batchDate.month,
      batchDate.day,
      8,
    );

    final now = tz.TZDateTime.now(tz.local);

    final baseId = _notificationBaseId(batchDay);

    final body = _batchBody(
      customerCount: customerCount,
      chickCount: chickCount,
    );

    if (oneDayBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: baseId,
        title: _tomorrowTitle,
        body: body,
        scheduledDate: oneDayBefore,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: queuePayload,
      );
    }

    if (batchMorning.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: baseId + 1,
        title: _todayTitle,
        body: body,
        scheduledDate: batchMorning,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: queuePayload,
      );
    }
  }

  // ------------------------------------------------
  // LOCALIZED TEXT
  // ------------------------------------------------

  String get _tomorrowTitle {
    if (_isKhmer) {
      return 'កូនមាន់មកដល់ថ្ងៃស្អែក';
    }

    return 'Chick batch tomorrow';
  }

  String get _todayTitle {
    if (_isKhmer) {
      return 'កូនមាន់មកដល់ថ្ងៃនេះ';
    }

    return 'Chick batch today';
  }

  String _batchBody({required int customerCount, required int chickCount}) {
    if (_isKhmer) {
      return 'អតិថិជន $customerCount នាក់'
          ' • '
          'កូនមាន់ $chickCount ក្បាល';
    }

    return '$customerCount '
        'customer${customerCount == 1 ? '' : 's'}'
        ' • '
        '$chickCount '
        'chick${chickCount == 1 ? '' : 's'}';
  }

  String get _testTitle {
    if (_isKhmer) {
      return 'ការរំលឹក MomBiz';
    }

    return 'MomBiz reminder';
  }

  String get _testBody {
    if (_isKhmer) {
      return 'ការជូនដំណឹងកូនមាន់ដំណើរការហើយ។';
    }

    return 'Chick notifications are working.';
  }

  // ------------------------------------------------
  // NOTIFICATION STYLE
  // ------------------------------------------------

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  // ------------------------------------------------
  // CANCEL EXISTING BATCH REMINDERS
  // ------------------------------------------------

  Future<void> _cancelAllBatchNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();

    for (final notification in pending) {
      if (notification.payload == queuePayload) {
        await _notifications.cancel(id: notification.id);
      }
    }
  }

  // ------------------------------------------------
  // HELPERS
  // ------------------------------------------------

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  int _notificationBaseId(tz.TZDateTime date) {
    final shortYear = date.year % 100;

    return ((shortYear * 10000) + (date.month * 100) + date.day) * 10;
  }

  // ------------------------------------------------
  // TEST NOTIFICATION
  // ------------------------------------------------

  Future<void> showTestNotification() async {
    await initialize();

    await _notifications.show(
      id: 999999,
      title: _testTitle,
      body: _testBody,
      notificationDetails: _notificationDetails(),
      payload: queuePayload,
    );
  }
}
