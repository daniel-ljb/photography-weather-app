import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:background_fetch/background_fetch.dart';
import 'app.dart';
import 'services/notification_manager.dart';


// what to do when a notification is clicked when app isnt open
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  print("woahhh");
}

// what to do when ??
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    print("gaming!");
}

// flutter notification manager
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  
  // Set up notifications
  setupNotifications();

  // Check that the environment has all the correct env variables
  bool envCorrect = await checkEnvironment();
  if (!envCorrect) return;
  
  // Register background task
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  // Set transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // transparent status bar
    statusBarIconBrightness: Brightness.dark, // or Brightness.light for white icons
    statusBarBrightness: Brightness.light, // for iOS
  ));

  runApp(const MyApp());
}

void setupNotifications() async {
  // ask for permissions
  if (kIsWeb) {
    print("Web platform has no notifications.");
  }else if (Platform.isAndroid) {
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()!.requestNotificationsPermission();
  } else if (Platform.isIOS) {
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  }
  
  // // Android notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  
  // // IOS notifications
  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      'textCategory [TEST]',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          'text_1',
          'Action 1',
          buttonTitle: 'Send',
          placeholder: 'Placeholder',
        ),
      ],
    ),
    DarwinNotificationCategory(
      'plainCategory [TEST]',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', 'Action 1'),
        DarwinNotificationAction.plain(
          'id_2',
          'Action 2 (destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,
          },
        ),
        DarwinNotificationAction.plain(
          'navigationActionId1',
          'Action 3 (foreground)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          'id_4',
          'Action 4 (auth required)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.authenticationRequired,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    )
  ];

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: darwinNotificationCategories,
  );

  final LinuxInitializationSettings initializationSettingsLinux =
    LinuxInitializationSettings(
        defaultActionName: 'Open notification');
  final WindowsInitializationSettings initializationSettingsWindows =
    WindowsInitializationSettings(
        appName: 'Flutter Local Notifications Example',
        appUserModelId: 'Com.Dexterous.FlutterLocalNotificationsExample',
        // Search online for GUID generators to make your own
        guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb');

  // Initialise notification settings
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
    windows: initializationSettingsWindows
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

int notificationID = 0;
Future<void> showNotification(title, body, payload) async {
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'channel_id', 'channel_name',
    channelDescription: 'Notification for photography weather app'
  );
  
  const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

  const WindowsNotificationDetails windowsDetails = WindowsNotificationDetails();

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: iOSDetails,
    macOS: iOSDetails,
    linux: linuxDetails,
    windows: windowsDetails,
  );
  
  await flutterLocalNotificationsPlugin.show(
    notificationID++, 
    title, 
    body, 
    notificationDetails,
    payload: payload
  );
}

Future<bool> checkEnvironment() async {
  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['WEATHER_API_KEY'] == null) {
      throw Exception('WEATHER_API_KEY not found in .env file');
    }
    if (dotenv.env['LOCATIONIQ_API_KEY'] == null) {
      throw Exception('LOCATIONIQ_API_KEY API Key not found in env file!');
    }
    if (dotenv.env['OPEN_WEATHER_MAP_API_KEY'] == null) {
      throw Exception('OPEN_WEATHER_MAP API Key not found in env file!');
    }
    return true;
  } catch (e) {
    print('Error loading .env file: $e');
    return false;
    // Don't continue running the app even if .env fails to load
  }
}
