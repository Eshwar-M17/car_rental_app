import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:carrentalapp/models/booking.dart'; // Booking model now includes carDetails

// Create a single global instance of the plugin.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initializes the notifications plugin.
/// Call this function in your main() before runApp().
Future<void> initializeNotifications() async {
  // Initialize timezone data.
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Initialize the plugin.
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create notification channels (Android only)
  if (Platform.isAndroid) {
    // Rental Confirmation Channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'rental_confirm_channel',
            'Rental Confirmations',
            description: 'Channel for rental confirmation notifications',
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
        );

    // Request notification permission if needed (for Android 13+).
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        debugPrint("Notification permission granted");
      } else {
        debugPrint("Notification permission denied");
      }
    }
  }
}

Future<void> scheduleTestNotification() async {
  // Create a date formatter for local IST display.
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  debugPrint("Scheduling test notification");
  debugPrint("Current time (local IST): ${dateFormatter.format(DateTime.now())}");

  // Get the current time as a tz.TZDateTime in the local timezone.
  final tz.TZDateTime tzNow = tz.TZDateTime.now(tz.local);
  debugPrint("Current tz time (local IST): ${dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(tzNow.millisecondsSinceEpoch))}");

  // Add a safety buffer of 5 seconds to ensure the scheduled time is in the future.
  final scheduledTime = tzNow.add(const Duration(seconds: 125)); // 120 + 5 seconds buffer

  debugPrint("Scheduled time (local IST): ${dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(scheduledTime.millisecondsSinceEpoch))}");

  // Ensure the scheduled time is in the future.
  if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
    debugPrint("Scheduled time is not in the future. Aborting notification scheduling.");
    return;
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    2,
    'Test Notification',
    'This is a test notification.',
    scheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel_id',
        'Test Channel',
        channelDescription: 'Channel for testing notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exact,
  );
}

Future<void> scheduleRentalProgressNotification({
  required DateTime rentStartDate,
  required DateTime rentEndDate,
  required Booking booking,
}) async {
  // Calculate total duration and the 70% point.
  final Duration totalDuration = rentEndDate.difference(rentStartDate);
  final Duration seventyPercentDuration = totalDuration * 0.7;
  final DateTime notificationTime = rentStartDate.add(seventyPercentDuration);

  // Convert to a tz.TZDateTime in the local timezone.
  final tz.TZDateTime tzNotificationTime = tz.TZDateTime.from(notificationTime, tz.local);

  // Check if notification time is in the future.
  if (tzNotificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
    debugPrint('Notification time is in the past. Not scheduling.');
    return;
  }

  // Schedule the notification.
  await flutterLocalNotificationsPlugin.zonedSchedule(
    UniqueKey().hashCode, // Unique ID for each notification.
    'Rental Progress Update',
    '70% of your rental period for ${booking.carDetails.name} has been completed.',
    tzNotificationTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'rental_progress_channel',
        'Rental Progress',
        channelDescription: 'Notifications about rental period progress',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );

  debugPrint('Scheduled notification at ${tzNotificationTime.toLocal()}');
}

// Renamed to showRentalConfirmationNotification for consistency.
Future<void> showRentalConfirmationNotification(Booking booking) async {
  // Add date formatter inside the function.
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'rental_confirm_channel',
    'Rental Confirmations',
    channelDescription: 'Notifications for rental confirmations',
    importance: Importance.max,
    priority: Priority.high,
    colorized: true,
    color: Colors.green,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    UniqueKey().hashCode,
    'Rental Confirmed 🎉',
    '${booking.carDetails.name} rental booked!\nPickup: ${dateFormat.format(booking.rentStartDate)}\nReturn: ${dateFormat.format(booking.endDate)}',
    details,
  );
}
