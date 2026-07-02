import 'dart:ui';

import 'package:anjanitek/feed.dart';
import 'package:anjanitek/home_staff.dart';
import 'package:anjanitek/designs.dart';
import 'package:anjanitek/no_login_experience2.dart';
import 'package:anjanitek/stock_reservations.dart';
import 'package:anjanitek/stock_reservations_admin.dart';
import 'package:anjanitek/utils/database_helper.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/home_admin.dart';
import 'package:anjanitek/home_dealer.dart';
import 'package:anjanitek/destination.dart';
import 'package:anjanitek/profile.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/shopping_cart.dart';

class OldHomePage extends StatefulWidget {
  const OldHomePage({super.key});

  @override
  _OldHomePageState createState() => _OldHomePageState();
}

class _OldHomePageState extends State<OldHomePage> {
  int _currentIndex = 0;
  String role = '';
  String id = '';
  List<Widget>? _pages; // Store page instances to persist state
  List<Destination> destinations = [];

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  // get user data
  void getUserData() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    SharedPreferences preferences = await SharedPreferences.getInstance();

    if (preferences.containsKey(Constants.name)) {

      // check for the app version from API, if not same, signout the user
      if(preferences.getString(Constants.appVersionFromAPI) != null){
        String appVersionFromAPI = preferences.getString(Constants.appVersionFromAPI)!;
        if(appVersionFromAPI != Constants.sc_app_version){

          showToast(context, 'Please update to new version of the app.', 'warning');
          // show update dialog
          // showDialog(
          //   context: context,
          //   builder: (context) => AlertDialog(
          //     title: const Text('Update Available'),
          //     content: const Text('A new version of the app is available. Please update to continue using all features.'),
          //     actions: [
          //       TextButton(
          //         onPressed: () {
          //           Navigator.of(context).pop();
          //         },
          //         child: const Text('Later'),
          //       ),
          //       TextButton(
          //         onPressed: () {
          //           // open app store link
          //         },
          //         child: const Text('Update'),
          //       ),
          //     ],
          //   ),
          // );
        }
      }
      else {
          // sign out user
          
          // showToast(context, "Signing out!");
          await OneSignal.logout().whenComplete(() {});

          // clear cart data
          shoppingCartController.unloadCart();

          // clear shared preferences
          clearData();
          await dbHelper.deleteAllNotifications();

          // clear internal db
          // final dbHelper = DatabaseInternal.instance;
          // await dbHelper.deleteAll();

          await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnjaniTekApp2()));
        
      }
      
      setState(() {
        role = preferences.getString(Constants.role)!;
        id = preferences.getString(Constants.id)!;

        // filter and assign the destinations based on role into the bottom navigation
        destinations = allDestinations.where((destination) {
          if (destination.title == 'Orders') {
            return (preferences.getString(Constants.role)!.toLowerCase() != Constants.factory.toLowerCase());
          }
          return true;
        }).toList();

        _initializePages(); // Initialize pages once role is available
      });
    }

    // load the cart data for the user
    await shoppingCartController.loadCart(id);
  }

  void _initializePages() {
    // Initialize the list with placeholders (SizedBox)
    _pages = List<Widget>.filled(destinations.length, const SizedBox.shrink());
    
      // Load the initial page immediately
      _pages![_currentIndex] = _buildPage(_currentIndex);
  }

  // Helper to build the actual widget for a specific index
  Widget _buildPage(int index) {
    switch (destinations[index].title) {
      case 'Home':
        return (role.toLowerCase() == Constants.dealer.toLowerCase())
            ? HomeDealer()
            : (role.toLowerCase() == Constants.staff.toLowerCase() || role.toLowerCase() == Constants.staffAdmin.toLowerCase() ||
                    role.toLowerCase() == Constants.factory.toLowerCase())
                ? HomeStaff()
                : HomeAdmin();
      // case 'Designs':
      //   return const DesignsScreen();
      case 'Designs':
        return const Designs();
        // return const Designs();
        // return const DesignsLanding();
      case 'Orders':
        return (role.toLowerCase() == Constants.globalAdmin.toLowerCase() || role.toLowerCase() == Constants.superAdmin.toLowerCase() || role.toLowerCase() == Constants.salesExecutive.toLowerCase() || role.toLowerCase() == Constants.salesManager.toLowerCase() || role.toLowerCase() == Constants.stateHead.toLowerCase() || role.toLowerCase() == Constants.staff.toLowerCase() || role.toLowerCase() == Constants.staffAdmin.toLowerCase()) ? 
                const StockReservationsAdmin() :
                const StockReservationsPage();
      case 'Feed':
        return const FeedScreen();
      case 'Profile':
        return Profile();
      default:
        return const SizedBox.shrink();
    }
  }

  // Method to load a page if it hasn't been loaded yet
  void _loadPage(int index) {
    if (index < _pages!.length && _pages![index] is SizedBox) {
      setState(() {
        _pages![index] = _buildPage(index);
      });
    }
  }

  bool get _isIosPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  double _bottomNavigationHeight() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    if (_isIosPlatform) {
      return 78 + (bottomInset > 0 ? bottomInset : 12);
    }
    return kBottomNavigationBarHeight + 16;
  }

  void _handleNavigationTap(int index) {
    if (index == 5) {
      return;
    }

    _loadPage(index);
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildIosBottomNavigation() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              4,
              6,
              4,
              bottomInset > 0 ? bottomInset + 8 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.38),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(destinations.length, (index) {
                final destination = destinations[index];
                final isSelected = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleNavigationTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1FA27F)
                                      .withValues(alpha: 0.96),
                                  const Color(0xFF008060)
                                      .withValues(alpha: 0.92),
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF49C3A0).withValues(alpha: 0.78)
                              : Colors.transparent,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF008060)
                                      .withValues(alpha: 0.24),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, -1),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                              size: 22,
                            ),
                            child: destination.icon,
                          ),
                          const SizedBox(height: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              letterSpacing: 0.1,
                            ),
                            child: Text(
                              destination.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBottomNavigation(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedIconTheme: IconThemeData(color: Color(0xFF008060)),
            selectedItemColor: Color(0xFF008060),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 8,
          ),
        ),
        child: Opacity(
          opacity: 1,
          child: Container(
              margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white,
                    ]),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                  bottomLeft: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 2,
                    blurRadius: 20.0,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: _handleNavigationTap,
                // filter and add the destinations based on role into the bottom navigation
                items: destinations.where((destination) {
                  if (destination.title == 'Designs') {
                    return (
                        role.toLowerCase() == Constants.superAdmin.toLowerCase() ||
                        role.toLowerCase() == Constants.salesExecutive.toLowerCase() ||
                        role.toLowerCase() == Constants.salesManager.toLowerCase() ||
                        role.toLowerCase() == Constants.stateHead.toLowerCase() ||
                        role.toLowerCase() == Constants.staff.toLowerCase() ||
                        role.toLowerCase() == Constants.staffAdmin.toLowerCase());
                  }
                  if (destination.title == 'Orders') {
                    return (
                        role.toLowerCase() == Constants.superAdmin.toLowerCase() ||
                        role.toLowerCase() == Constants.salesExecutive.toLowerCase() ||
                        role.toLowerCase() == Constants.salesManager.toLowerCase() ||
                        role.toLowerCase() == Constants.stateHead.toLowerCase() ||
                        role.toLowerCase() == Constants.staff.toLowerCase() ||
                        role.toLowerCase() == Constants.staffAdmin.toLowerCase() ||
                        role.toLowerCase() == Constants.dealer.toLowerCase());
                  }
                  return true;
                }).
                map((Destination destination) {
                  return BottomNavigationBarItem(
                    icon: destination.icon,
                    label: destination.title,
                  );
                }).toList(),
              )),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavigationHeight = _bottomNavigationHeight();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      shoppingCartController.setBottomNavigationHeight(bottomNavigationHeight);
    });

    return Scaffold(
      extendBody: true, // helps to customise bottom navigation
      body: SafeArea(
        maintainBottomViewPadding: true,
        top: false,
        child: _pages == null
            ? const Center(
                child:
                    CircularProgressIndicator()) // Show loader until role and pages are ready
            : IndexedStack(
                index: _currentIndex,
                children: _pages!,
              ),
      ),
      bottomNavigationBar: _isIosPlatform
          ? _buildIosBottomNavigation()
          : _buildDefaultBottomNavigation(context),
    );
  }
}
