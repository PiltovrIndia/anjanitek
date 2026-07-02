import 'dart:async';

import 'package:anjanitek/firebase_options.dart';
import 'package:anjanitek/home.dart';
import 'package:anjanitek/no_login_experience2.dart';
import 'package:anjanitek/utils/shopping_cart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

// Future<void> main() async{
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());

  // const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  // const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
  //   requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
  //   // onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
  //   // }
  // );

  // final InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  //   iOS: initializationSettingsIOS
  // );
  // await FlutterLocalNotificationsPlugin().initialize(initializationSettings);
  runApp(const MyApp());

  //Remove this method to stop OneSignal Debugging
  // OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  // OneSignal.initialize("81f54f9c-8a2c-4d05-adb8-f3db1f10f047");
  OneSignal.initialize("397b52e1-e5c1-4783-8f9c-a3cdcb0eaf34"); // new one
  // OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: false);
  // OneSignal.shared.setLaunchURLsInApp(true);
  // checkNotificationPermission();
  OneSignal.Notifications.requestPermission(true);
  // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  // OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {

  //     // if accepted is "False", it means the permission is not provided yet.
  //     print("Accepted permission: $accepted");

  //     // check if the platform is IOS and prompt for the permission.
  //     // if(Platform.isIOS){
  //     //   if(!accepted) {
  //     //     print("False");
  //     //       checkNotificationPermission();
  //     //   }
  //     //   else {
  //     //     print("Already done!");
  //     //   }
  //     // }
  // });

  OneSignal.User.pushSubscription.addObserver((state) {
    // print(OneSignal.User.pushSubscription.optedIn);
    // print(OneSignal.User.pushSubscription.id);
    // print(OneSignal.User.pushSubscription.token);
    // print(state.current.jsonRepresentation());
  });

  // v4 release changes
  // navigate to the screen when the notification is clicked
  // OneSignal.Notifications.addClickListener((event) {
  //   // print("Notification clicked: ${event.jsonRepresentation()}");
  //   // navigate to the screen based on the data in the notification
  //   // for example, if the notification has a "type" field, we can navigate to different screens based on the value of that field
  //   String? type = event.notification.additionalData?['type'];
  //   if(type != null){
  //     if(type == 'visitor_pass'){
  //       // navigate to visitor pass screen
  //       // print("Navigate to visitor pass screen");
  //     }
  //     else if(type == 'stock_reservation'){
  //       // navigate to stock reservation screen
  //       // print("Navigate to stock reservation screen");
  //     }
  //     else {
  //       // navigate to home screen
  //       // print("Navigate to home screen");
  //     }
  //   }
  // });

  // OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
  //   // Will be called whenever a notification is received in foreground
  //   // Display Notification, pass null param for not displaying the notification
  //         event.complete(event.notification);
  // });

  // OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
  //   // Will be called whenever a notification is opened/button pressed.
  // });

  // OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
  //     // Will be called whenever the permission changes
  //     // (ie. user taps Allow on the permission prompt in iOS)
  //     log('Permission state changed: ${changes.to.toString()}');

  //     //  OSPermissionState permissionState = changes.to;
  //     // print('Permission state changed: ${permissionState.status}');

  //     // if(permissionState.status != OSNotificationPermission.authorized){
  //     //   print("Calling to open prompt");
  //     //   // checkNotificationPermission();

  //     //   OneSignal.shared.promptUserForPushNotificationPermission();
  //     // }

  // });

  // OneSignal.shared.setSubscriptionObserver((OSSubscriptionStateChanges changes) {
  //     // Will be called whenever the subscription changes
  //     // (ie. user gets registered with OneSignal and gets a user ID)
  // });
}

// // prompt the permission prompt
// void checkNotificationPermission() async{

//   // If you want to know if the user allowed/denied permission,
//   // the function returns a Future<bool>:
//   bool allowed = await OneSignal.Notifications.permission;
//   //  promptUserForPushNotificationPermission(fallbackToSettings: true);

//   if(!allowed){
//     // print("About to prompt");
//     OneSignal.Notifications.requestPermission(true);

//   }
//   else {
//     // do nothing
//     print("Permission taken");
//   }
// }

// prompt the permission prompt
// void checkNotificationPermission() async{

//   // If you want to know if the user allowed/denied permission,
//   // the function returns a Future<bool>:
//   bool allowed = await OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: true);

//   if(!allowed){
//     // print("About to prompt");
//     OneSignal.shared.promptUserForPushNotificationPermission();

//   }
//   else {
//     // do nothing
//     // print("Not Allowed");
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      navigatorObservers: [shoppingCartRouteObserver],
      // title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ShoppingCartOverlay(child: child ?? const SizedBox.shrink());
      },
      home: LauncherScreen(),
    );
  }
}

class LauncherScreen extends StatefulWidget {
  @override
  _LauncherScreenState createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerCards;
  late SharedPreferences _sharedPreferences;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();

    _controllerCards = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controllerCards.forward();

    // check for user info
    getUsersData();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllerCards.dispose();
    super.dispose();
  }

  // get users data
  void getUsersData() async {
    // get the sharedpreferences
    // check if user is already logged in

    _sharedPreferences = await SharedPreferences.getInstance();

    if (_sharedPreferences.containsKey(Constants.name)) {
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: cartHomeRouteName),
            builder: (context) => HomePage(),
          ),
        );
      });
    } else {
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnjaniTekApp2()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      backgroundColor: Colors.deepOrange,
      body: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controllerCards,
              curve: Curves.ease, // Use Curves.easeIn for ease-in animation
            ),
            alignment: Alignment.center,
            child: Center(
              child: Container(
                  width: 350.0, // Replace with your desired size
                  height: 350.0, // Replace with your desired size
                  decoration: const BoxDecoration(
                    boxShadow: [
                      // BoxShadow(
                      //   color: const Color(0xFFEBFFE8).withOpacity(0.5),
                      //   offset: const Offset(0.0, 0.0),
                      //   blurRadius: 44.0,
                      //   spreadRadius: 27.3,
                      // ),
                    ],
                    // border: Border.all(color: Palette.black, width: 2.0),
                    shape: BoxShape.circle,
                    // color: const Color(0xFFEBFFE8).withOpacity(0.0),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/anjani_logo1.webp',
                          scale: 2,
                        ),
                        const Spacer(flex: 1),
                        // Image.asset('assets/anjani_title1.webp', scale: 2,),
                        Image.asset(
                          'assets/anjani_title_white.webp',
                          scale: 1,
                        ),
                        const Spacer(flex: 1),
                        // AppProgress(height: 24, width: 24)
                        const CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      ],
                    ),
                  )),
            ),
          )),
    );
  }
}
