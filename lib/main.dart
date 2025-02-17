import 'dart:async';

import 'package:anjanitek/home.dart';
import 'package:anjanitek/no_login_experience.dart';
import 'package:anjanitek/no_login_experience1.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/verify.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

void main() {
  runApp(MyApp());


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
      // title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LauncherScreen(),
    );
  }
}

class LauncherScreen extends StatefulWidget {
  @override
  _LauncherScreenState createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerCards;
  late SharedPreferences _sharedPreferences;

  @override
  void initState() {
    _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 1000),);
    _controller.forward();
    
    _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
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

    if(_sharedPreferences.containsKey(Constants.name)){
      // setState(() {
          
      //   campusId = prefs.get(Constants.campusId) as String;
      //   username = prefs.get(Constants.username) as String;

      //   if(role != Constants.student){
      //     branches.clear();
      //     branches.addAll(prefs.get(Constants.branch).toString().split(','));
      //   }
    
      // });

      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );

        // if(_sharedPreferences.get(Constants.role) == Constants.admin){
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (context) => HomePage()),
        //     );
        // }
        // else if(_sharedPreferences.get(Constants.role) == Constants.dealer){
        //   Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (context) => HomePage()),
        //     );
        // }
        // else {
        //   Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (context) => Verification()),
        //     );
        // }
      });
    }
    else {
      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AnjaniTekApp1()),
          // MaterialPageRoute(builder: (context) => AnjaniTekApp()),
          // MaterialPageRoute(builder: (context) => const Verification()),
        );
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(opacity: _controller,
                child:
                ScaleTransition(scale: CurvedAnimation(
                                parent: _controllerCards,
                                curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                              ),alignment: Alignment.center,
                  child: Center(child: 
                    
                    Container(
                      width: 350.0, // Replace with your desired size
                      height: 350.0, // Replace with your desired size
                      decoration: BoxDecoration(
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
                        child: 
                          Column(
                            children: [
                              Image.asset('assets/anjani_logo1.webp', scale: 2,),
                              Spacer(flex:1),
                              Image.asset('assets/anjani_title1.webp', scale: 2,),
                              Spacer(flex:1),
                              AppProgress(height: 24, width: 24)
                            ],
                          ),
                      )
                    ),
                  ),
                )
              ),
      
    );
  }
}



// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.deepPurple,
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
// import 'dart:async';

// import 'package:anjanitek/home.dart';
// import 'package:anjanitek/utils/progress.dart';
// import 'package:anjanitek/verify.dart';
// import 'package:flutter/material.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:anjanitek/utils/constants.dart' as Constants;

// void main() {
//   runApp(const MyApp());


//     //Remove this method to stop OneSignal Debugging 
//     // OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
    
//     // OneSignal.initialize("81f54f9c-8a2c-4d05-adb8-f3db1f10f047");
//     OneSignal.initialize("397b52e1-e5c1-4783-8f9c-a3cdcb0eaf34"); // new one
//     // OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: false);
//     // OneSignal.shared.setLaunchURLsInApp(true);
//     checkNotificationPermission();
//     // OneSignal.Notifications.requestPermission(true);
//     // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
//     // OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
        
//     //     // if accepted is "False", it means the permission is not provided yet.
//     //     print("Accepted permission: $accepted");

//     //     // check if the platform is IOS and prompt for the permission.
//     //     // if(Platform.isIOS){
//     //     //   if(!accepted) {
//     //     //     print("False");
//     //     //       checkNotificationPermission();
//     //     //   }
//     //     //   else {
//     //     //     print("Already done!");
//     //     //   }
//     //     // }
//     // });




//     // OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
//     //   // Will be called whenever a notification is received in foreground
//     //   // Display Notification, pass null param for not displaying the notification
//     //         event.complete(event.notification);                                 
//     // });

//     // OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
//     //   // Will be called whenever a notification is opened/button pressed.
//     // });

//     // OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
//     //     // Will be called whenever the permission changes
//     //     // (ie. user taps Allow on the permission prompt in iOS)
//     //     log('Permission state changed: ${changes.to.toString()}');

//     //     //  OSPermissionState permissionState = changes.to;
//     //     // print('Permission state changed: ${permissionState.status}');

//     //     // if(permissionState.status != OSNotificationPermission.authorized){
//     //     //   print("Calling to open prompt");
//     //     //   // checkNotificationPermission();

//     //     //   OneSignal.shared.promptUserForPushNotificationPermission();
//     //     // }

//     // });

//     // OneSignal.shared.setSubscriptionObserver((OSSubscriptionStateChanges changes) {
//     //     // Will be called whenever the subscription changes 
//     //     // (ie. user gets registered with OneSignal and gets a user ID)
//     // });
// }


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


// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       // title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: LauncherScreen(),
//     );
//   }
// }

// class LauncherScreen extends StatefulWidget {
//   @override
//   _LauncherScreenState createState() => _LauncherScreenState();
// }

// class _LauncherScreenState extends State<LauncherScreen> with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late AnimationController _controllerCards;
//   late SharedPreferences _sharedPreferences;

//   @override
//   void initState() {
//     _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 1000),);
//     _controller.forward();
    
//     _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
//     _controllerCards.forward();

//     // check for user info
//     getUsersData();
    
//     super.initState();

//   }
//   @override
//   void dispose() {
//     _controller.dispose();
//     _controllerCards.dispose();
//     super.dispose();
//   }

//   // get users data
//   void getUsersData() async {
//     // get the sharedpreferences
//     // check if user is already logged in
    
//     _sharedPreferences = await SharedPreferences.getInstance();

//     if(_sharedPreferences.containsKey(Constants.name)){
//       // setState(() {
          
//       //   campusId = prefs.get(Constants.campusId) as String;
//       //   username = prefs.get(Constants.username) as String;

//       //   if(role != Constants.student){
//       //     branches.clear();
//       //     branches.addAll(prefs.get(Constants.branch).toString().split(','));
//       //   }
    
//       // });

//       Timer(Duration(seconds: 3), () {
//         Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );

//         // if(_sharedPreferences.get(Constants.role) == Constants.admin){
//         //     Navigator.pushReplacement(
//         //       context,
//         //       MaterialPageRoute(builder: (context) => HomePage()),
//         //     );
//         // }
//         // else if(_sharedPreferences.get(Constants.role) == Constants.dealer){
//         //   Navigator.pushReplacement(
//         //       context,
//         //       MaterialPageRoute(builder: (context) => HomePage()),
//         //     );
//         // }
//         // else {
//         //   Navigator.pushReplacement(
//         //       context,
//         //       MaterialPageRoute(builder: (context) => Verification()),
//         //     );
//         // }
//       });
//     }
//     else {
//       Timer(Duration(seconds: 3), () {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Verification()),
//         );
//       });
//     }

//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: FadeTransition(opacity: _controller,
//                 child:
//                 ScaleTransition(scale: CurvedAnimation(
//                                 parent: _controllerCards,
//                                 curve: Curves.ease, // Use Curves.easeIn for ease-in animation
//                               ),alignment: Alignment.center,
//                   child: Center(child: 
                    
//                     Container(
//                       width: 350.0, // Replace with your desired size
//                       height: 350.0, // Replace with your desired size
//                       decoration: BoxDecoration(
//                         boxShadow: [
//                           // BoxShadow(
//                           //   color: const Color(0xFFEBFFE8).withOpacity(0.5),
//                           //   offset: const Offset(0.0, 0.0),
//                           //   blurRadius: 44.0,
//                           //   spreadRadius: 27.3,
//                           // ),
//                         ],
//                         // border: Border.all(color: Palette.black, width: 2.0),
//                         shape: BoxShape.circle,
//                         // color: const Color(0xFFEBFFE8).withOpacity(0.0),
//                       ),
//                       child: Center(
//                         child: 
//                           Column(
//                             children: [
//                               Image.asset('assets/anjani_logo1.webp', scale: 2,),
//                               Spacer(flex:1),
//                               Image.asset('assets/anjani_title1.webp', scale: 2,),
//                               Spacer(flex:1),
//                               AppProgress(height: 24, width: 24)
//                             ],
//                           ),
//                       )
//                     ),
//                   ),
//                 )
//               ),
      
//     );
//   }
// }



// // class MyHomePage extends StatefulWidget {
// //   const MyHomePage({super.key, required this.title});

// //   // This widget is the home page of your application. It is stateful, meaning
// //   // that it has a State object (defined below) that contains fields that affect
// //   // how it looks.

// //   // This class is the configuration for the state. It holds the values (in this
// //   // case the title) provided by the parent (in this case the App widget) and
// //   // used by the build method of the State. Fields in a Widget subclass are
// //   // always marked "final".

// //   final String title;

// //   @override
// //   State<MyHomePage> createState() => _MyHomePageState();
// // }

// // class _MyHomePageState extends State<MyHomePage> {
// //   int _counter = 0;

// //   void _incrementCounter() {
// //     setState(() {
// //       // This call to setState tells the Flutter framework that something has
// //       // changed in this State, which causes it to rerun the build method below
// //       // so that the display can reflect the updated values. If we changed
// //       // _counter without calling setState(), then the build method would not be
// //       // called again, and so nothing would appear to happen.
// //       _counter++;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // This method is rerun every time setState is called, for instance as done
// //     // by the _incrementCounter method above.
// //     //
// //     // The Flutter framework has been optimized to make rerunning build methods
// //     // fast, so that you can just rebuild anything that needs updating rather
// //     // than having to individually change instances of widgets.
// //     return Scaffold(
// //       appBar: AppBar(
// //         // TRY THIS: Try changing the color here to a specific color (to
// //         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
// //         // change color while the other colors stay the same.
// //         backgroundColor: Theme.of(context).colorScheme.primary,
// //         // Here we take the value from the MyHomePage object that was created by
// //         // the App.build method, and use it to set our appbar title.
// //         title: Text(widget.title),
// //       ),
// //       body: Center(
// //         // Center is a layout widget. It takes a single child and positions it
// //         // in the middle of the parent.
// //         child: Column(
// //           // Column is also a layout widget. It takes a list of children and
// //           // arranges them vertically. By default, it sizes itself to fit its
// //           // children horizontally, and tries to be as tall as its parent.
// //           //
// //           // Column has various properties to control how it sizes itself and
// //           // how it positions its children. Here we use mainAxisAlignment to
// //           // center the children vertically; the main axis here is the vertical
// //           // axis because Columns are vertical (the cross axis would be
// //           // horizontal).
// //           //
// //           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
// //           // action in the IDE, or press "p" in the console), to see the
// //           // wireframe for each widget.
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: <Widget>[
// //             const Text(
// //               'You have pushed the button this many times:',
// //             ),
// //             Text(
// //               '$_counter',
// //               style: Theme.of(context).textTheme.headlineMedium,
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         backgroundColor: Colors.deepPurple,
// //         onPressed: _incrementCounter,
// //         tooltip: 'Increment',
// //         child: const Icon(Icons.add),
// //       ), // This trailing comma makes auto-formatting nicer for build methods.
// //     );
// //   }
// // }
