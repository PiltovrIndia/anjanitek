
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/home_admin.dart';
import 'package:anjanitek/home_dealer.dart';
import 'package:anjanitek/destination.dart';
import 'package:anjanitek/profile.dart';
// import 'package:anjanitek/circular_new.dart';
// import 'package:anjanitek/destination.dart';
// import 'package:anjanitek/feed.dart';
// import 'package:anjanitek/home.dart';
// import 'package:anjanitek/profile.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>  {
  int _currentIndex = 0;
  String role = '';

   @override
  void initState() {
    
    getUserData();
    super.initState();
  }

  // get user data
  void getUserData() async {
    
    SharedPreferences preferences = await SharedPreferences.getInstance();
    
      if(preferences.containsKey(Constants.name)){
        setState(() {
          role = preferences.getString(Constants.role)!;
        });
        
      }
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // helps to customise bottom navigation 
      body: SafeArea(maintainBottomViewPadding: true,
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children:  allDestinations.map<Widget>((Destination destination) {
            
            switch (destination.title) {
              case 'Home':
                // return Dashboard();
                return (role.toLowerCase() == Constants.dealer.toLowerCase()) ? HomeDealer() : HomeAdmin();
              // case 'Feed':
              //   return Feed();
                // return Classroom();
              // case 'New':
              //   return NewCircular();
                // return _showModalBottomSheet(context, 'ok');
              case 'Profile':
                return Profile();
                break;
              default: 
                return HomeDealer();
            }
            
          }).toList(),
        ),
      ),
      bottomNavigationBar: Theme(
        data: 
      Theme.of(context).copyWith(
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedIconTheme: IconThemeData(color: Color(0xFF008060)),
            selectedItemColor: Color(0xFF008060),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            
            // backgroundColor: Palette.white.withOpacity(0.4),
            elevation: 8,
            // shape: const RoundedRectangleBorder(
            //   borderRadius: BorderRadius.only(
            //     topLeft: Radius.circular(16.0),
            //     topRight: Radius.circular(16.0),
            //   ),
            // ),
          ),
        ), 
        child:
        Opacity(
          opacity: 1,
        child: 
        Container( 
            // padding: EdgeInsets.all(10),
            margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                Colors.white.withOpacity(0.8),
                Colors.white,
              ]),
              // color: Colors.black,
              // color: Palette.white,
              borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0),
              ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 20.0,
                offset: Offset(0,3),
              )
            ],
            ),

            
            // decoration: BoxDecoration(
            //   // color: Colors.black,
            //   color: Palette.white,
            //   borderRadius: const BorderRadius.only(
            //                 topLeft: Radius.circular(12.0),
            //                 topRight: Radius.circular(12.0),
            //                 bottomLeft: Radius.circular(12.0),
            //                 bottomRight: Radius.circular(12.0),
            //   ),
            // boxShadow: const [
            //   BoxShadow(
            //     color: Colors.black12,
            //     spreadRadius: 2,
            //     blurRadius: 20.0,
            //   )
            // ],
            // ),


            child:
      BottomNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            if(index == 4){ // this will launch a new screen
              // Navigator.of(context).push(_createRoute());
              // _showModalBottomSheet(context, 'ok');
              // Navigator.push(context, MaterialPageRoute(builder: (context) => NewCircular()));
            }
            else {
              _currentIndex = index;
            }

          });
        },
        // elevation: 18.0,
        
        items: allDestinations.map((Destination destination) {
          return BottomNavigationBarItem(
            // backgroundColor: Color(0xFF008060),
            icon: Icon(destination.icon),
            label: destination.title,
          );
        }).toList(),
        )),
        )
        )
      
      // Theme(
      //   data: 
      // Theme.of(context).copyWith(
      //     bottomNavigationBarTheme: BottomNavigationBarThemeData(
      //       selectedIconTheme: IconThemeData(color: Color(0xFF008060)),
      //       selectedItemColor: Color(0xFF008060),
      //       showSelectedLabels: true,
      //       showUnselectedLabels: true,
            
      //       // backgroundColor: Palette.white.withOpacity(0.4),
      //       elevation: 8,
      //       // shape: const RoundedRectangleBorder(
      //       //   borderRadius: BorderRadius.only(
      //       //     topLeft: Radius.circular(16.0),
      //       //     topRight: Radius.circular(16.0),
      //       //   ),
      //       // ),
      //     ),
      //   ), 
      //   child: ClipRRect(
      //     borderRadius: const BorderRadius.only(
      //       topLeft: Radius.circular(16.0),
      //       topRight: Radius.circular(16.0),
      //       bottomLeft: Radius.circular(16.0),
      //       bottomRight: Radius.circular(16.0),
      //     ), child:  Container(
            
      //       margin: EdgeInsets.all(10),
      //       decoration: BoxDecoration(
      //         // color: Colors.black,
      //         borderRadius: BorderRadius.all(Radius.circular(16))// Adjust the opacity as needed
              
      //       ),
      //       child:
      // BottomNavigationBar(
        
      //   type: BottomNavigationBarType.fixed,
      //   currentIndex: _currentIndex,
      //   onTap: (int index) {
      //     setState(() {
      //       if(index == 4){ // this will launch a new screen
      //         Navigator.of(context).push(_createRoute());
      //         // _showModalBottomSheet(context, 'ok');
      //         // Navigator.push(context, MaterialPageRoute(builder: (context) => NewCircular()));
      //       }
      //       else {
      //         _currentIndex = index;
      //       }

      //     });
      //   },
      //   elevation: 18.0,
        
      //   items: allDestinations.map((Destination destination) {
      //     return BottomNavigationBarItem(
      //       // backgroundColor: Palette.background,
      //       icon: Icon(destination.icon),
      //       label: destination.title,
      //     );
      //   }).toList(),
      //   )),),)
    );
  }

// Route _createRoute() {
//   return PageRouteBuilder(
//     pageBuilder: (context, animation, secondaryAnimation) => NewCircular(),
//     transitionsBuilder: (context, animation, secondaryAnimation, child) {
//       var begin = const Offset(0.0, 1.0);
//       var end = Offset.zero;
//       var curve = Curves.easeIn;

//       var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

//       return SlideTransition(
//         position: animation.drive(tween),
//         child: child,
//       );
//     },
//   );
// }

  
}