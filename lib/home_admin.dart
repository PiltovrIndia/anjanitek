import 'dart:convert';
import 'dart:ui';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/dealer_details.dart';
import 'package:anjanitek/message_detail.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/sales_category.dart';
import 'package:anjanitek/modals/target.dart';
import 'package:anjanitek/no_login_experience2.dart';
import 'package:anjanitek/payments_admin.dart';
import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/products_listing.dart';
import 'package:anjanitek/sales_dealers_1.dart';
import 'package:anjanitek/dealers_outstanding_admin.dart';
import 'package:anjanitek/invoices_all_admin.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/modals/stats.dart';
import 'package:anjanitek/sales_dealers_2.dart';
import 'package:anjanitek/showrooms.dart';
import 'package:anjanitek/utils/database_helper.dart';
import 'package:anjanitek/utils/designoftheday.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';

import 'package:shared_preferences/shared_preferences.dart';
// import 'package:anjanitek/database_internal.dart';
import 'package:anjanitek/modals/users.dart';
// import 'package:anjanitek/profile_update.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
// import 'package:anjanitek/util/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';
import 'package:anjanitek/widgets/dealer_search_widget.dart';

import 'utils/dotted_line.dart';

// this is
class HomeAdmin extends StatefulWidget {
  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String name = '',
      mobile = '',
      email = '-',
      role = '-',
      adminId = '',
      id = '',
      userImage = '',
      gcm_regId = '',
      accountName = '',
      dealerId = '',
      salesId = '',
      city = '',
      state = '',
      gst = '',
      address1 = '',
      address2 = '',
      address3 = '';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  bool catalogueCheckProgress = false;
  bool targetsDataProgress = false;
  late List<Invoices> invoicesList = [];
  late List<Product> designOfTheDayList = [];
  late List<ProductTag> productTagsList = [];
  bool checkDesignOfTheDayList = false;
  late List<Stats> statsList = [];
  bool anyOutstanding = true;
  double totalOutstandingATL = 0;
  double totalOutstandingVCL = 0;
  String dueDateATL = '';
  String dueDateVCL = '';
  int daysLeftATL = 0;
  int daysLeftVCL = 0;
  bool connectionStatus = true;
  String searchedText = '';
  bool isSearchResultEmpty = false;
  String emptyStateMsg = '';

  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");
  TextEditingController searchTextController = TextEditingController();
  List<Users> dealersList = [];
  List<Dealers> _filteredUsers = [];
  bool isLoading = false;
  bool isDataAvailable = false;
  bool endOfData = true;
  int offset = 0;
  // bool _isHidden = false;

  List<Catalogue> showCatalogues = [];

  // user object
  Invoices? invoices;

  // ScrollController? scrollController;
  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  late SharedPreferences prefs;
  DatabaseHelper dbHelper = DatabaseHelper();

  List<Target> targetsDataList = [];

  @override
  void initState() {
    // get reference to internal database
    getUsers();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();

    // CurvedAnimation(
    //         parent: _visible ? Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //           parent: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
    //           curve: Curves.easeIn, // Use Curves.easeIn for ease-in animation
    //         )) : Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
    //           parent: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
    //           curve: Curves.easeIn,
    //         )),
    //       );
    _controllerCards = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controllerCards.forward();

    // scrollController = new ScrollController()..addListener(_scrollListener);

    super.initState();
  }

  // void _onSearchChanged() {
  //   String query = searchTextController.text.toLowerCase();
  //   List<Dealers> filteredList = dealersList.where((item) => item.dealerId!.toLowerCase().contains(query)).toList();

  //   setState(() {
  //     _filteredUsers = filteredList;
  //   });
  // }

  @override
  void dispose() {
    // scrollController!.dispose();
    otpFocusNode.dispose(); // Dispose of the FocusNode
    searchTextController.dispose();
    _controller.dispose();
    _controllerCards.dispose();
    super.dispose();
  }

  // get user details
  void getUsers() async {
    await dbHelper.initDb();
    prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Constants.name)) {
      setState(() {
        id = prefs.get(Constants.id) as String;
        name = prefs.get(Constants.name) as String;
        adminId = prefs.get(Constants.id) as String;
        email = prefs.get(Constants.email) as String;
        role = prefs.get(Constants.role) as String;
        mobile = prefs.get(Constants.mobile) as String;
        userImage = prefs.get(Constants.userImage) as String;
        gcm_regId = prefs.get(Constants.gcmRegId) as String;
        isActive = prefs.get(Constants.isActive) as int;

        if (prefs.get(Constants.role) == Constants.dealer) {
          dealerId = prefs.get(Constants.dealerId) as String;
          accountName = prefs.get(Constants.accountName) as String;
          salesId = prefs.get(Constants.salesId) as String;
          address1 = prefs.get(Constants.address1) as String;
          address2 = prefs.get(Constants.address2) as String;
          address3 = prefs.get(Constants.address3) as String;
          city = prefs.get(Constants.city) as String;
          state = prefs.get(Constants.state) as String;
          gst = prefs.get(Constants.gst) as String;
        }
      });
    }

    logUserSession();
    getStats(context);
    // getTargetsData(context);
    getDesignOfTheDay().then((value) {
      final Map<String, dynamic> map = value as Map<String, dynamic>;
      setState(() {
        // final List<dynamic> products = map['products'] as List<dynamic>? ?? [];
        // designOfTheDayList = products.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();

        // final List<dynamic> tags = map['tags'] as List<dynamic>? ?? [];
        // productTagsList = tags.map((t) => ProductTag.fromJson(t as Map<String, dynamic>)).toList();

        designOfTheDayList = map['products'] as List<Product>? ?? [];
        productTagsList = map['tags'] as List<ProductTag>? ?? [];

        checkDesignOfTheDayList = true;
      });
    });

    // getCatalogues(context);
    // refreshUserHomeAdmin(context);
  }

  // log user session
  // also check if the user is active or not
  // if not active then logout the user
  void logUserSession() async {
    if (await checkInternetConnectivity()) {
      var result = await get(
          Uri.parse(APIUrls.getUrl(
              "${APIUrls.user}${APIUrls.pass}/U0/$id/$role/user", {})),
          headers: {"Accept": "application/json"});
      var jsonString = jsonDecode(result.body);
      var jsonObject = jsonString as Map;

      if (jsonObject['status'] == 200) {
        int isActive = jsonObject['data'] as int;
        if (isActive == 0) {
          // user is not active, logout the user
          showToast(
              context,
              'Your account is inactive. Please contact support.',
              Constants.warning);
          await OneSignal.logout().whenComplete(() {});
          clearData();
          await dbHelper.deleteAllNotifications();
          await Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const AnjaniTekApp2()));
        }
      }
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        logUserSession();

        // set the connection Status variable to false
        setState(() {
          connectionStatus = false;
        });
      });
    }
  }

  // find the user
  void refreshUserHomeAdmin(BuildContext context) async {
    if (await checkInternetConnectivity()) {
      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters
      Map<String, String> queryParams = {};

      // API call
      // print("${APIUrls.amount}${APIUrls.pass}/U5");
      var result = await get(
          Uri.parse(APIUrls.getUrl(
              "${APIUrls.amount}${APIUrls.pass}/U5", queryParams)),
          headers: {"Accept": "application/json"});
      // print(result.body);
      // Decode the JSON string into a Map using the jsonDecode function
      var jsonString = jsonDecode(result.body);

      // convert jsonString to Map
      var jsonObject = jsonString as Map;

      // check if the api returned success
      if (jsonObject['status'] == 200) {
        // get the user data from jsonObject
        var invoicesData = jsonObject['data'] as List;
        // Map<String, dynamic> invoicesData = jsonObject['data'];

        if (invoicesData.isNotEmpty) {
          // convert to list
          invoicesList = invoicesData
              .map<Invoices>((json) => Invoices.fromJson(json))
              .toList();
          // print(invoicesList);

          setState(() {
            // Get new user data
            // invoices = invoicesData.where((element) => false);
            // invoices.
            double totalSum =
                invoicesList.fold(0.0, (double sum, Invoices invoice) {
              // Check if the invoiceType is "ATL"
              if (invoice.invoiceType == "ATL") {
                return sum +
                    (invoice.pending ??
                        0.0); // Add to sum only if condition is met
              }
              return sum; // Otherwise, just return the current sum
            });

            double totalSum1 =
                invoicesList.fold(0.0, (double sum, Invoices invoice) {
              // Check if the invoiceType is "ATL"
              if (invoice.invoiceType == "VCL") {
                return sum +
                    (invoice.pending ??
                        0.0); // Add to sum only if condition is met
              }
              return sum; // Otherwise, just return the current sum
            });

            DateTime? earliestExpiryDate = invoicesList
                .where((invoice) =>
                    invoice.expiryDate != null &&
                    invoice.invoiceType ==
                        "ATL") // Filter out null expiry dates
                .map((invoice) => format
                    .parse(invoice.expiryDate!)) // Parse string to DateTime
                .reduce((a, b) =>
                    a.isBefore(b) ? a : b); // Determine the earliest date

            // get the days left for expiry
            Duration duration = earliestExpiryDate.difference(DateTime.now());

            // Output the earliest date in a friendly format, e.g., January 1, 2023
            String formattedDate =
                DateFormat('MMMM d, yyyy').format(earliestExpiryDate);

            DateTime? earliestExpiryDate1 = invoicesList
                .where((invoice) =>
                    invoice.expiryDate != null &&
                    invoice.invoiceType ==
                        "VCL") // Filter out null expiry dates
                .map((invoice) => format
                    .parse(invoice.expiryDate!)) // Parse string to DateTime
                .reduce((a, b) =>
                    a.isBefore(b) ? a : b); // Determine the earliest date

            // get the days left for expiry
            Duration duration1 = earliestExpiryDate1.difference(DateTime.now());

            // Output the earliest date in a friendly format, e.g., January 1, 2023
            String formattedDate1 =
                DateFormat('MMMM d, yyyy').format(earliestExpiryDate1);

            totalOutstandingATL = totalSum;
            totalOutstandingVCL = totalSum1;
            dueDateATL = formattedDate;
            dueDateVCL = formattedDate1;
            daysLeftATL = duration.inDays;
            daysLeftVCL = duration1.inDays;

            // indicate there is outstanding
            anyOutstanding = false;

            // hide the progress

            refreshCheckProgress = false;
            connectionStatus = true;
          });
        } else {
          setState(() {
            anyOutstanding = false;
            refreshCheckProgress = false;
            connectionStatus = true;
          });
        }
      } else if (jsonObject['status'] == 402) {
        // no data exists
        setState(() {
          // get the error message
          refreshCheckProgress = false;
          connectionStatus = true;
        });
      } else if (jsonObject['status'] == 404) {
        // no data exists
        setState(() {
          // get the error message
          refreshCheckProgress = false;
          connectionStatus = true;
        });
      } else {
        setState(() {
          refreshCheckProgress = false;
          connectionStatus = true;
          showToast(context, 'Error, try again later!', Constants.error);
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        refreshUserHomeAdmin(context);

        // set the connection Status variable to false
        setState(() {
          connectionStatus = false;
        });
      });
    }
  }

  void getStats(BuildContext context) async {
    if (await checkInternetConnectivity()) {
      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters
      Map<String, String> queryParams = {};

      // API call
      // print("${APIUrls.stats}${APIUrls.pass}/0/$role/$adminId");
      var result = await get(
          Uri.parse(APIUrls.getUrl(
              "${APIUrls.stats}${APIUrls.pass}/0/$role/$adminId", queryParams)),
          headers: {"Accept": "application/json"});
      // print(result.body);
      // Decode the JSON string into a Map using the jsonDecode function
      var jsonString = jsonDecode(result.body);

      // convert jsonString to Map
      var jsonObject = jsonString as Map;

      // check if the api returned success
      if (jsonObject['status'] == 200) {
        // get the user data from jsonObject
        var invoicesData = jsonObject['data'] as List;
        // Map<String, dynamic> invoicesData = jsonObject['data'];

        if (invoicesData.isNotEmpty) {
          // convert to list
          statsList =
              invoicesData.map<Stats>((json) => Stats.fromJson(json)).toList();
          // print(statsList);

          setState(() {
            totalOutstandingATL = statsList
                .firstWhere((element) => element.state == "All")
                .pendingATL!;
            totalOutstandingVCL = statsList
                .firstWhere((element) => element.state == "All")
                .pendingVCL!;

            // indicate there is outstanding
            anyOutstanding = false;

            // hide the progress

            refreshCheckProgress = false;
            connectionStatus = true;
          });
        } else {
          setState(() {
            anyOutstanding = false;
            refreshCheckProgress = false;
            connectionStatus = true;
          });
        }
      } else if (jsonObject['status'] == 402) {
        // no data exists
        setState(() {
          // get the error message
          refreshCheckProgress = false;
          connectionStatus = true;
        });
      } else if (jsonObject['status'] == 404) {
        // no data exists
        setState(() {
          // get the error message
          refreshCheckProgress = false;
          connectionStatus = true;
        });
      } else {
        setState(() {
          refreshCheckProgress = false;
          connectionStatus = true;
          showToast(context, 'Error, try again later!', Constants.error);
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        getStats(context);

        // set the connection Status variable to false
        setState(() {
          connectionStatus = false;
        });
      });
    }
  }

  // get sales & collections targets data for this dealer
  // void getTargetsData(BuildContext context) async {

  //   if(await checkInternetConnectivity()){
  //     setState(() {
  //       targetsDataProgress = true;
  //     });

  //     // API call
  //     print("${APIUrls.targets}${APIUrls.pass}/${DateTime.now().year}-${DateTime.now().month}-01/$id");
  //     var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.targets}${APIUrls.pass}/${DateTime.now().year}-${DateTime.now().month}-01/$id", {})), headers: {"Accept": "application/json"});

  //     print(result.body);
  //     // Decode the JSON string into a Map using the jsonDecode function
  //     var jsonString = jsonDecode(result.body);

  //     // convert jsonString to Map
  //     var jsonObject = jsonString as Map;

  //     // check if the api returned success
  //     if(jsonObject['success'] && jsonObject['count'] > 0){

  //         // get the user data from jsonObject
  //         var targetsData = jsonObject['data'] as List;
  //         var targets = targetsData[0]['targets'] as List;

  //         // print(targetsData);
  //         // print(targets);

  //         setState(() {

  //           targetsDataList = targets.map<Target>((json) => Target.fromJson(json)).toList();

  //           targetsDataProgress = false;
  //           connectionStatus = true;
  //           // here the response is already recorded, hence it can be correct/incorrect as mentioned by the dealer
  //           // confirmation = Confirmation.fromJson(targetsData.first);
  //           // confirmationStatus = (Confirmation.fromJson(targetsData.first).response == 'Yes') ? Constants.yes : Constants.no;
  //         });

  //     }
  //     else if(jsonObject['status'] == 201){

  //       // set the confirmation object
  //       setState(() {

  //         targetsDataProgress = false;
  //         connectionStatus = true;
  //       });
  //     }
  //     else {
  //       // no data exists
  //       setState(() {
  //         // get the error message
  //         targetsDataProgress = false;
  //         connectionStatus = true;
  //       });

  //     }
  //   }
  //   else {
  //     Future.delayed(const Duration(seconds: 5), () {
  //       getTargetsData(context);

  //       // set the connection Status variable to false
  //       setState(() {
  //         targetsDataProgress = false;
  //       });

  //     });
  //   }
  // }

  // Function to generate dots based on the length of the original value
  String _getDots(String value) {
    return '•' * value.length;
  }

  // Get the catalogues
  // void getCatalogues(BuildContext context) async {

  //   setState(() {
  //     catalogueCheckProgress = true;
  //   });

  //   // query parameters
  //   Map<String, String> queryParams = {

  //     };

  //   // API call
  //   var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.catalogues}${APIUrls.pass}/1", queryParams)), headers: {"Accept": "application/json"});
  //   // print(result.body);

  //   // Decode the JSON string into a Map using the jsonDecode function
  //   Map<String, dynamic> jsonObject = jsonDecode(result.body);
  //   // print(result.body);
  //   // user object list

  //   // check if the api returned success
  //   if(jsonObject['status'] == 200){

  //       // get the user data from jsonObject
  //       var showCataloguesData = jsonObject['data'] as List;
  //         // Map<String, dynamic> invoicesData = jsonObject['data'];

  //         if(showCataloguesData.isNotEmpty){

  //           List<Catalogue> cataloguesList = showCataloguesData.map<Catalogue>((json) => Catalogue.fromJson(json)).toList();

  //             setState(() {
  //               // Get new user data
  //               showCatalogues = cataloguesList;
  //               catalogueCheckProgress = false;
  //             });
  //         }
  //   }
  //   else if(jsonObject['status'] == 402 || jsonObject['status'] == 404){
  //     // no data exists
  //     setState(() {
  //       // get the error message
  //       catalogueCheckProgress = false;
  //     });

  //   }
  //   else {

  //       setState(() {
  //         catalogueCheckProgress = false;
  //         // showToast(context, 'Error, try again later!',Constants.error);
  //       });
  //   }
  // }

  // initiate the search
  void searchNow(searchTerm) {
    setState(() {
      searchedText = searchTerm;
      dealersList.clear();
    });

    setState(() {
      isLoading = true;
    });
    getDealers();
  }

  // get dealers for approval
  void getDealers() async {
    // check if there is any data
    if (searchedText.isNotEmpty) {
      // print("${APIUrls.user}${APIUrls.pass}/U2/$searchedText/$offset/$role/$adminId");
      var result = await get(
          Uri.parse(APIUrls.getUrl(
              "${APIUrls.user}${APIUrls.pass}/U2/$searchedText/$offset/$role/$adminId",
              {})),
          headers: {"Accept": "application/json"});

      var jsonString = jsonDecode(result.body);
      var jsonObject = jsonString as Map;

      List<Users> list1 = [];
      if (jsonObject['status'] == 200) {
        var dealers = jsonObject['data'] as List;

        if (dealers.isNotEmpty) {
          list1 = dealers.map<Users>((json) => Users.fromJson(json)).toList();

          setState(() {
            dealersList.addAll(list1);

            isLoading = false;
            isDataAvailable = true;
          });
        } else {
          // no dealers pending for approval
          setState(() {
            emptyStateMsg = 'No match found';
            isLoading = false;
            isDataAvailable = false;
            endOfData = false;
          });
        }
      } else {
        // no dealers pending for approval
        setState(() {
          emptyStateMsg = 'No match found';
          isLoading = false;
          isDataAvailable = false;
          endOfData = false;
        });
        showToast(context, emptyStateMsg, Constants.warning);
      }
    } else {
      // no dealers pending for approval
      setState(() {
        emptyStateMsg = 'No pending dealers';
        isLoading = false;
        endOfData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // get the selected theme
    // final themeChange = Provider.of<DarkThemeProvider>(context);
    // bool value = themeChange.darkTheme;
    // var theme = Theme.of(context);

    // Uri facebookUrl;
    return Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
            opacity: _controller,
            child:

                // Stack(

                //   children: [

                //       FadeTransition(opacity: _controller,
                //         child:
                //         ScaleTransition(scale: CurvedAnimation(
                //                         parent: _controllerCards,
                //                         curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                       ),alignment: Alignment.center,
                //           child:

                //             Container(
                //               width: 350.0, // Replace with your desired size
                //               height: 350.0, // Replace with your desired size
                //               decoration: BoxDecoration(
                //                 boxShadow: [
                //                   BoxShadow(
                //                     color: const Color(0xFFFF93F4).withOpacity(0.5),
                //                     offset: const Offset(0.0, 0.0),
                //                     blurRadius: 44.0,
                //                     spreadRadius: 27.3,
                //                   ),
                //                 ],
                //                 // border: Border.all(color: Colors.black, width: 2.0),
                //                 shape: BoxShape.circle,
                //                 color: const Color(0xFFFF93F4).withOpacity(0.0),
                //               ),
                //             ),
                //         )
                //       ),
                //     Positioned(
                //       top: MediaQuery.of(context).size.height/2, // Randomly set top position
                //       left: (MediaQuery.of(context).size.width/2),
                //       child:
                //         FadeTransition(opacity: _controller,
                //           child:
                //           ScaleTransition(scale: CurvedAnimation(
                //                       parent: _controllerCards,
                //                       curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                     ),alignment: Alignment.center,
                //             child:

                //               Container(
                //                 width: 1250.0, // Replace with your desired size
                //                 height: 1250.0, // Replace with your desired size
                //                 decoration: BoxDecoration(
                //                   boxShadow: [
                //                     BoxShadow(
                //                       color: const Color(0xFF7CE3FF).withOpacity(0.3),
                //                       offset: const Offset(0.0, 0.0),
                //                       blurRadius: 44.0,
                //                       spreadRadius: 27.3,
                //                     ),
                //                   ],
                //                   // border: Border.all(color: Colors.black, width: 2.0),
                //                   shape: BoxShape.circle,
                //                   color: const Color(0xFF7CE3FF).withOpacity(0.0),
                //                 ),
                //               ),
                //           )
                //         ),
                //     ),
                // Positioned(
                //     top: MediaQuery.of(context).size.height/2, // Randomly set top position
                //     left: 0,
                //     child:
                //     FadeTransition(opacity: _controller,
                //       child:
                //       ScaleTransition(scale: CurvedAnimation(
                //                       parent: _controllerCards,
                //                       curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                     ),alignment: Alignment.center,
                //         child:

                //               Container(
                //                 width: 250.0, // Replace with your desired size
                //                 height: 250.0, // Replace with your desired size
                //                 decoration: BoxDecoration(
                //                   boxShadow: [
                //                     BoxShadow(
                //                       color: const Color(0xFFB07CFF).withOpacity(0.3),
                //                       offset: const Offset(0.0, 0.0),
                //                       blurRadius: 44.0,
                //                       spreadRadius: 27.3,
                //                     ),
                //                   ],
                //                   // border: Border.all(color: Colors.black, width: 2.0),
                //                   shape: BoxShape.circle,
                //                   color: const Color(0xFFB07CFF).withOpacity(0.0),
                //                 ),
                //               ),
                //           )
                //       )
                //     ),

                //     Positioned(
                //     top: MediaQuery.of(context).size.height/2 - 200, // Randomly set top position
                //     left: MediaQuery.of(context).size.width - 300,
                //     // right: 0,
                //     child:

                //       FadeTransition(opacity: _controller,
                //       child:
                //       ScaleTransition(scale: CurvedAnimation(
                //                       parent: _controllerCards,
                //                       curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                     ),alignment: Alignment.center,
                //         child:
                //           Container(
                //             width: 350.0, // Replace with your desired size
                //             height: 350.0, // Replace with your desired size
                //             decoration: BoxDecoration(
                //               boxShadow: [
                //                 BoxShadow(
                //                   color: const Color(0xFFFFCB7C).withOpacity(0.4),
                //                   offset: const Offset(0.0, 0.0),
                //                   blurRadius: 44.0,
                //                   spreadRadius: 27.3,
                //                 ),
                //               ],
                //               // border: Border.all(color: Colors.black, width: 2.0),
                //               shape: BoxShape.circle,
                //               color: const Color(0xFFFFCB7C).withOpacity(0.0),
                //             ),
                //           ),
                //         )
                //       ),
                //     ),

                Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                  child: SingleChildScrollView(
                child: Container(
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Column(
                          // child: CardRound(Palette.lightBackground, Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            sizedBox(16),
                            Image.asset(
                              'assets/anjani_title1.webp',
                              scale: 2,
                            ),
                            sizedBox(24),
                            Center(
                              child: connectionStatus
                                  ? sizedBox(0)
                                  : Text(
                                      'No network detected. Try again later!',
                                      style: GoogleFonts.inter(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                            ),
                            // Text('Home', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
                            // sizedBox(16),

                            // TextField(
                            //   onChanged: (value) {
                            //     if (value.isEmpty) {
                            //     setState(() {
                            //       dealersList.clear();
                            //     });
                            //     }
                            //   },
                            //   onSubmitted: (value) {
                            //     searchNow(searchTextController.text.trim());
                            //   },
                            //   controller: searchTextController,
                            //   keyboardType: TextInputType.text,
                            //   textInputAction: TextInputAction.search,
                            //   style: const TextStyle(fontSize: 14.0,),
                            //   decoration: InputDecoration(
                            //     fillColor: Color.fromARGB(255, 255, 255, 255),
                            //     filled: true,
                            //     contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            //     suffixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: Color(0xFF008160), ),
                            //     hintText: 'Type dealer name to Search',
                            //     hintStyle: const TextStyle(
                            //     fontSize: 14.0,
                            //     ),
                            //     border: OutlineInputBorder(
                            //     borderRadius: BorderRadius.circular(8.0),
                            //     borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
                            //     ),
                            //     focusedBorder: OutlineInputBorder(
                            //     borderRadius: BorderRadius.circular(8.0),
                            //     borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
                            //     ),
                            //   ),
                            //   ),
                            //   SizedBox(height: 8),
                            //   isLoading
                            //     ? Center(child: CircularProgressIndicator())
                            //     : dealersList.isEmpty
                            //     ? Container()
                            //     : Positioned(
                            //     top: 100, // Adjust the position as needed
                            //     left: 16,
                            //     right: 16,
                            //     child: Material(
                            //     elevation: 8.0,
                            //     borderRadius: BorderRadius.circular(12),
                            //     child: Container(
                            //       decoration: BoxDecoration(
                            //       color: Colors.white,
                            //       borderRadius: const BorderRadius.all(Radius.circular(12)),
                            //       border: Border.all(
                            //       color: Colors.black12, // Set the color of the border here
                            //       width: 1, // Set the width of the border here
                            //       ),
                            //       boxShadow: const [
                            //       BoxShadow(
                            //       color: Colors.black12,
                            //       offset: Offset(0.0, 0.0),
                            //       blurRadius: 24.0,
                            //       spreadRadius: 0.3,
                            //       ),
                            //       ]
                            //       ),
                            //       height: 180, // Adjust the height as needed
                            //       child: Scrollbar(
                            //       thumbVisibility: true,
                            //       child: ListView.separated(
                            //       shrinkWrap: true,
                            //       itemCount: dealersList.length,
                            //       itemBuilder: (context, index) {
                            //       return ListTile(
                            //         dense: true,
                            //         visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                            //         isThreeLine: false,
                            //         title: Text(dealersList[index].name ?? '', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black, fontWeight: FontWeight.bold)),
                            //         subtitle: Text(dealersList[index].id ?? '', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54, fontWeight: FontWeight.bold)),
                            //         onTap: () {
                            //         // Handle the tap event here
                            //         print(dealersList[index].id);
                            //         Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetails(dealersList[index].mapTo!, dealersList[index].mapName ?? '', dealersList[index].id!, dealersList[index].name!)));
                            //         },
                            //       );
                            //       },
                            //       separatorBuilder: (context, index) => divider(Colors.black12),
                            //       ),
                            //       ),
                            //     ),
                            //     ),
                            //     ),

                            DealerSearchWidget(
                              controller: searchTextController,
                              dealers: dealersList,
                              isLoading: isLoading,
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  setState(() {
                                    dealersList.clear();
                                  });
                                }
                              },
                              onSubmitted: (value) {
                                searchNow(searchTextController.text.trim());
                                setState(() {
                                  searchTextController.text = value;
                                  searchTextController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset:
                                            searchTextController.text.length),
                                  );
                                });
                              },
                              onClear: () {
                                setState(() {
                                  searchTextController.clear();
                                  dealersList.clear();
                                });
                              },
                              onDealerTap: (dealer) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DealerDetails(
                                      dealer.mapTo!,
                                      dealer.mapName ?? '',
                                      dealer.id!,
                                      dealer.name!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            sizedBox(8),
                            Container(
                              decoration: BoxDecoration(
                                  // color: Theme.of(context).shadowColor,
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(24)),
                                  border: Border.all(
                                    color: Colors
                                        .black12, // Set the color of the border here
                                    width:
                                        1, // Set the width of the border here
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0.0, 0.0),
                                      blurRadius: 24.0,
                                      spreadRadius: 0.3,
                                    ),
                                  ]),
                              padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    // Text('Total Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text('Total Outstanding',
                                                style: GoogleFonts.inter(
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            // IconButton(
                                            //   icon: Icon(_isHidden
                                            //       ? Icons.visibility_off
                                            //       : Icons.visibility),
                                            //   onPressed: () {
                                            //     setState(() {
                                            //       _isHidden = !_isHidden;
                                            //     });
                                            //   },
                                            //   tooltip: _isHidden
                                            //       ? 'Show Amounts'
                                            //       : 'Hide Amounts',
                                            // ),
                                          ],
                                        ),
                                        // Text('Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                        refreshCheckProgress
                                            ? const AppProgress(
                                                height: 24, width: 24)
                                            : IconButton(
                                                onPressed: () =>
                                                    {getStats(context)},
                                                icon: const Icon(
                                                  PhosphorIconsBold
                                                      .arrowClockwise,
                                                ))
                                        // refreshCheckProgress ? AppProgress(height: 24, width: 24) : IconButton(onPressed: ()=>{refreshUserHomeAdmin(context)}, icon: Icon(PhosphorIconsBold.arrowClockwise, ))
                                      ],
                                    ),
                                    // sizedBox(16),
                                    Text('ATL',
                                        style: GoogleFonts.montserrat(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        // _isHidden
                                        //     ? _getDots(NumberFormat(
                                        //             "#,##,##0.00", "en_IN")
                                        //         .format(totalOutstandingATL))
                                        //     : 
                                            '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}',
                                        style: GoogleFonts.montserrat(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            fontSize: 24,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFF5252))),
                                    sizedBox(16),
                                    Text('VCL',
                                        style: GoogleFonts.montserrat(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        // _isHidden
                                        //     ? _getDots(NumberFormat(
                                        //             "#,##,##0.00", "en_IN")
                                        //         .format(totalOutstandingVCL))
                                        //     : 
                                            '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)}',
                                        style: GoogleFonts.montserrat(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            fontSize: 24,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFC41306))),

                                    sizedBox(12),
                                    DottedLine(),
                                    sizedBox(12),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    InvoicesAllAdmin()));
                                      },
                                      child: Text("INVOICES –>",
                                          style: GoogleFonts.inter(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              letterSpacing: 1,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade600)),
                                    ),
                                    sizedBox(12),
                                    DottedLine(),
                                    sizedBox(12),
                                    // sizedBox(8),
                                    // divider(Colors.black12),
                                    // sizedBox(8),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    OutstandingDealers()));
                                      },
                                      child: Text(
                                          "OVERDUE OUTSTANDING DEALERS –>",
                                          style: GoogleFonts.inter(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              letterSpacing: 1,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade600)),
                                      // we have updated this term to "Overdue Dealers" in the new version
                                      // Text("OUTSTANDING DEALERS –>", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                                    ),
                                  ]),
                            ),

                            // sizedBox(16),
                            // // MonthlyTargetSummaryCard(data: octoberTarget),
                            // // sizedBox(16),

                            // Container(
                            //   decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     borderRadius: const BorderRadius.all(Radius.circular(24)),
                            //     border: Border.all(
                            //       color: Colors.black12,
                            //       width: 1,
                            //     ),
                            //     boxShadow: const [
                            //       BoxShadow(
                            //         color: Colors.black12,
                            //         offset: Offset(0.0, 0.0),
                            //         blurRadius: 24.0,
                            //         spreadRadius: 0.3,
                            //       ),
                            //     ],
                            //   ),

                            //   padding: const EdgeInsets.all(20),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //       Row(
                            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //         children: [
                            //         Row(
                            //           children: [
                            //           Container(
                            //             padding: const EdgeInsets.all(10),
                            //             decoration: BoxDecoration(
                            //             color: Color(0xFFE8F5E9),
                            //             borderRadius: BorderRadius.circular(12),
                            //             ),
                            //             child: Icon(PhosphorIconsRegular.target, color: Color(0xFF008060), size: 24),
                            //           ),
                            //           SizedBox(width: 12),
                            //           Column(
                            //             crossAxisAlignment: CrossAxisAlignment.start,
                            //             children: [
                            //             Text('Monthly Targets', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.w600)),
                            //             Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                            //             ],
                            //           ),
                            //           ],
                            //         ),
                            //         targetsDataProgress ? AppProgress(height: 24, width: 24) :

                            //           IconButton(onPressed: ()=>{getTargetsData(context)}, icon: Icon(PhosphorIconsBold.arrowClockwise, ), iconSize: 16, color:  Color(0xFF008060),)
                            //         ],
                            //       ),
                            //       sizedBox(24),

                            //       targetsDataList.isEmpty
                            //         ? Center(
                            //           child: Text('No targets available', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                            //           )
                            //         : Column(
                            //           children: targetsDataList.map((target) {
                            //             String categoryName = '';
                            //             if (target.categoryId == 1) {
                            //             categoryName = 'VCL';
                            //             } else if (target.categoryId == 2) {
                            //             categoryName = 'ATL';
                            //             } else if (target.categoryId == 3) {
                            //             categoryName = 'Collections';
                            //             } else {
                            //             categoryName = target.name ?? 'Unknown';
                            //             }

                            //             double achieved = double.tryParse(target.actualAmount ?? '0') ?? 0;
                            //             double targetAmount = double.tryParse(target.targetAmount ?? '1') ?? 1;
                            //             double progress = achieved / targetAmount;

                            //             return Column(
                            //             children: [
                            //               buildTargetItem(
                            //               context,
                            //               categoryName,
                            //               achieved,
                            //               targetAmount,
                            //               progress < 0.5 ? Colors.red : const Color(0xFF008060),
                            //               ),
                            //               sizedBox(16),
                            //             ],
                            //             );
                            //           }).toList(),
                            //           ),
                            //     ],
                            //   ),
                            // ),
                            sizedBox(16),
                            InkWell(
                                onTap: () => {
                                      (role.toLowerCase() == Constants.salesExecutive.toLowerCase())
                                          ? Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SalesDealers2(
                                                          adminId, name, role)))
                                          : Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SalesDealers1()))
                                    },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(24)),
                                        border: Border.all(
                                          color: Colors
                                              .black12, // Set the color of the border here
                                          width:
                                              1, // Set the width of the border here
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 24.0,
                                            spreadRadius: 0.3,
                                          ),
                                        ]),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/sales.webp',
                                            width: 60.0),
                                        // Container(
                                        //   decoration: const BoxDecoration(
                                        //     color: Color(0xFF2196F3),
                                        //     borderRadius: BorderRadius.all(Radius.circular(24)),
                                        //   ),
                                        //   padding: const EdgeInsets.all(10),
                                        //   child:  Icon(PhosphorIconsRegular.usersThree, color: Color(0xFFFFFFFF), size: 24,),
                                        // ),
                                        const SizedBox(width: 16),
                                        Flexible(
                                            child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            (role.toLowerCase() ==
                                                    Constants.salesExecutive
                                                        .toLowerCase())
                                                ? Text('Dealers',
                                                    style: GoogleFonts.inter(
                                                        textStyle:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600))
                                                : Text('Sales & Dealers',
                                                    style: GoogleFonts.inter(
                                                        textStyle:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                            sizedBox(4),
                                            (role.toLowerCase() ==
                                                    Constants.salesExecutive
                                                        .toLowerCase())
                                                ? Text('All dealers under you',
                                                    style: GoogleFonts.inter(
                                                        textStyle:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                        fontSize: 14,
                                                        color: Colors.black87))
                                                : Text(
                                                    'All Sales people & targets under you',
                                                    style: GoogleFonts.inter(
                                                        textStyle:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                        fontSize: 14,
                                                        color: Colors.black87)),
                                          ],
                                        ))
                                      ],
                                    ))),

                            sizedBox(16),
                            InkWell(
                                onTap: () => {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  PaymentsAdmin()))
                                    },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(24)),
                                        border: Border.all(
                                          color: Colors
                                              .black12, // Set the color of the border here
                                          width:
                                              1, // Set the width of the border here
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 24.0,
                                            spreadRadius: 0.3,
                                          ),
                                        ]),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      spacing: 16,
                                      children: [
                                        Image.asset('assets/payments.webp',
                                            width: 60.0),
                                        // Container(
                                        //   decoration: const BoxDecoration(
                                        //     color: Color(0xFFFFA135),
                                        //     borderRadius: BorderRadius.all(Radius.circular(24)),
                                        //   ),
                                        //   padding: const EdgeInsets.all(10),
                                        //   child:  Row(
                                        //     mainAxisSize: MainAxisSize.min,
                                        //         crossAxisAlignment: CrossAxisAlignment.center,
                                        //         children: [
                                        //           const Icon(PhosphorIconsRegular.receipt, color: Colors.white, size: 24,),
                                        //           // const SizedBox(width:8),
                                        //           // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                                        //       ],
                                        //     ),
                                        // ),

                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            spacing: 8,
                                            children: [
                                              // Image.asset('assets/payments.webp',width: 80.0),
                                              Text('Payments',
                                                  style: GoogleFonts.inter(
                                                      textStyle:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodySmall,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),

                                              Text('Payments by your dealers',
                                                  style: GoogleFonts.inter(
                                                      textStyle:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium,
                                                      color: Colors.black54)),
                                              // sizedBox(4),
                                            ])
                                      ],
                                    ))),

                            sizedBox(16),
                            InkWell(
                                onTap: () => {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(16)),
                                        ),
                                        builder: (context) =>
                                            BottomSheetContent(
                                                role, adminId, name),
                                      )
                                    },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(24)),
                                        border: Border.all(
                                          color: Colors
                                              .black12, // Set the color of the border here
                                          width:
                                              1, // Set the width of the border here
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 24.0,
                                            spreadRadius: 0.3,
                                          ),
                                        ]),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      spacing: 16,
                                      children: [
                                        Image.asset('assets/messages.webp',
                                            width: 60.0),
                                        // Container(
                                        //   decoration: const BoxDecoration(
                                        //     color: Color(0xFF008060),
                                        //     borderRadius: BorderRadius.all(Radius.circular(24)),
                                        //   ),
                                        //   padding: const EdgeInsets.all(10),
                                        //   child:  Row(
                                        //     mainAxisSize: MainAxisSize.min,
                                        //         crossAxisAlignment: CrossAxisAlignment.center,
                                        //         children: [
                                        //           const Icon(PhosphorIconsRegular.chats, color: Colors.white, size: 24,),
                                        //           // const SizedBox(width:8),
                                        //           // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                                        //       ],
                                        //     ),
                                        // ),

                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                spacing: 4,
                                                children: [
                                                  Text('Messages',
                                                      style: GoogleFonts.inter(
                                                          textStyle:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                  Container(
                                                    width:
                                                        8, // Adjust size as needed
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors
                                                          .red, // Red color for the dot
                                                      shape: BoxShape
                                                          .circle, // Makes it a circle (dot)
                                                    ),
                                                  )
                                                ],
                                              ),
                                              sizedBox(8),
                                              Text(
                                                  'Messages from your dealers.',
                                                  style: GoogleFonts.inter(
                                                      textStyle:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium,
                                                      color: Colors.black54)),
                                              // sizedBox(4),
                                            ]),
                                      ],
                                    ))),
                            sizedBox(16),
                            //  Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Text('Designs', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),

                            //     sizedBox(16),

                            //     Container(
                            //         decoration: BoxDecoration(
                            //         // color: const Color(0xFFFEFEFE),

                            //                 border: Border.all(color: Colors.white, width: 0.5),
                            //                 borderRadius: BorderRadius.circular(24),
                            //                 gradient: LinearGradient(
                            //                   colors: [const Color.fromARGB(255, 255, 238, 212), Colors.pink.shade200],
                            //                   // colors: [const Color.fromARGB(255, 221, 221, 221), Colors.deepPurpleAccent],
                            //                   // colors: [Color(0xFF008060), Colors.green.shade800],
                            //                   // colors: [Colors.amber.shade400, Colors.green.shade800],
                            //                   begin: Alignment.topLeft,
                            //                   end: Alignment.bottomRight,
                            //                 ),
                            //                 boxShadow: [
                            //                   BoxShadow(
                            //                     color: Colors.black12, // Shadow color
                            //                     // color: Colors.black12, // Shadow color
                            //                     spreadRadius: 5, // How much the shadow spreads
                            //                     blurRadius: 10, // How blurred the shadow is
                            //                     offset: Offset(0, 10), // Offset in x, y direction
                            //                   ),
                            //                 ],
                            //         // boxShadow: const [
                            //         //   BoxShadow(
                            //         //     color: Colors.white,
                            //         //     offset: Offset(0.0, 0.0),
                            //         //     blurRadius: 24.0,
                            //         //     spreadRadius: 0.3,
                            //         //   ),
                            //         // ]
                            //       ),
                            //       padding: const EdgeInsets.all(16),
                            //       child:
                            //       Row(
                            //             crossAxisAlignment: CrossAxisAlignment.start,
                            //             spacing: 8,
                            //             children: [
                            //               Image.asset('assets/designday.webp',width: 120.0), sizedBox(4),
                            //               Expanded(child:
                            //               Column(
                            //                 crossAxisAlignment: CrossAxisAlignment.start,
                            //                 spacing: 6,
                            //                 children: [

                            //                   Text('Design of the day!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),

                            //                   Text('Check out today\'s exciting design.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                            //                   sizedBox(8),

                            //                   checkDesignOfTheDayList == false ?
                            //                   AppProgress(height: 30, width: 30,)
                            //                   :
                            //                   ElevatedButton(
                            //                     style: ElevatedButton.styleFrom(
                            //                       backgroundColor: Color(0xFFFFFFFF), // Dark background color

                            //                       textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                            //                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            //                       shape: RoundedRectangleBorder(
                            //                         borderRadius: BorderRadius.circular(24),
                            //                       ),
                            //                       elevation: 5, // Shadow depth
                            //                     ),
                            //                     onPressed: () {
                            //                       designOfTheDayList.isEmpty ?
                            //                       Navigator.push(context, MaterialPageRoute(builder: (context) => ProductCollections()))
                            //                       :
                            //                       Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: designOfTheDayList[0], productTags: productTagsList)));
                            //                     },
                            //                     child: Text(designOfTheDayList.isEmpty ? 'Browse Designs' : 'View Design', style: TextStyle(color: Colors.black)),
                            //                   ),

                            //                 ]

                            //               )
                            //               )
                            //             ],
                            //           )

                            //     ),
                            //     sizedBox(16),
                            //     Container(
                            //         decoration: BoxDecoration(
                            //         // color: const Color(0xFFFEFEFE),

                            //                 border: Border.all(color: Colors.white, width: 0.5),
                            //                 borderRadius: BorderRadius.circular(24),
                            //                 gradient: LinearGradient(
                            //                   colors: [const Color.fromARGB(255, 255, 238, 212), Colors.pink.shade200],
                            //                   // colors: [const Color.fromARGB(255, 221, 221, 221), Colors.deepPurpleAccent],
                            //                   // colors: [Color(0xFF008060), Colors.green.shade800],
                            //                   // colors: [Colors.amber.shade400, Colors.green.shade800],
                            //                   begin: Alignment.topLeft,
                            //                   end: Alignment.bottomRight,
                            //                 ),
                            //                 boxShadow: [
                            //                   BoxShadow(
                            //                     color: Colors.black12, // Shadow color
                            //                     // color: Colors.black12, // Shadow color
                            //                     spreadRadius: 5, // How much the shadow spreads
                            //                     blurRadius: 10, // How blurred the shadow is
                            //                     offset: Offset(0, 10), // Offset in x, y direction
                            //                   ),
                            //                 ],
                            //         // boxShadow: const [
                            //         //   BoxShadow(
                            //         //     color: Colors.white,
                            //         //     offset: Offset(0.0, 0.0),
                            //         //     blurRadius: 24.0,
                            //         //     spreadRadius: 0.3,
                            //         //   ),
                            //         // ]
                            //       ),
                            //       padding: const EdgeInsets.all(16),
                            //       child:
                            //       Row(
                            //             crossAxisAlignment: CrossAxisAlignment.start,
                            //             spacing: 8,
                            //             children: [
                            //               Image.asset('assets/offers.webp',width: 120.0), sizedBox(4),
                            //               Expanded(child:
                            //               Column(
                            //                 crossAxisAlignment: CrossAxisAlignment.start,
                            //                 spacing: 6,
                            //                 children: [

                            //                   Text('Grab the offers!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),

                            //                   Text('AnjaniTek brings exciting offers to you.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                            //                   sizedBox(8),
                            //                   ElevatedButton(
                            //                     style: ElevatedButton.styleFrom(
                            //                       backgroundColor: Color(0xFFFFFFFF), // Dark background color

                            //                       textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                            //                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            //                       shape: RoundedRectangleBorder(
                            //                         borderRadius: BorderRadius.circular(24),
                            //                       ),
                            //                       elevation: 5, // Shadow depth
                            //                     ),
                            //                     onPressed: () {
                            //                       Navigator.push(context, MaterialPageRoute(builder: (context) => OffersForDealer()));
                            //                       // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                            //                     },
                            //                     child: Text('View Offers', style: TextStyle(color: Colors.black)),
                            //                   ),

                            //                 ]

                            //               )
                            //               )
                            //             ],
                            //           )

                            //     ),
                            //     sizedBox(16),

                            //     // (refreshCheckProgress && showCatalogues.length == 0) ?
                            //     // Center(
                            //     //   child: Column(
                            //     //     mainAxisAlignment: MainAxisAlignment.center,
                            //     //     children: [
                            //     //       // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                            //     //       // sizedBox(8),
                            //     //       refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                            //     //       Text('Loading catagolues!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),

                            //     //     ],
                            //     //   )
                            //     // )
                            //     // :
                            //     // GridView.builder(
                            //     //   shrinkWrap: true,
                            //     //   physics: NeverScrollableScrollPhysics(),
                            //     //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            //     //     crossAxisCount: 2,
                            //     //     crossAxisSpacing: 16,
                            //     //     mainAxisSpacing: 16,
                            //     //     childAspectRatio: 0.75,
                            //     //   ),
                            //     //   itemCount: showCatalogues.length,
                            //     //   itemBuilder: (context, index) {
                            //     //     return productCard(index);
                            //     //   },
                            //     // ),
                            //   ]
                            // ),
                            // sizedBox(16),
                            InkWell(
                                onTap: () => {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ShowRooms()))
                                    },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(24)),
                                        border: Border.all(
                                          color: Colors
                                              .black12, // Set the color of the border here
                                          width:
                                              1, // Set the width of the border here
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 24.0,
                                            spreadRadius: 0.3,
                                          ),
                                        ]),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/showrooms.webp',
                                            width: 80.0),
                                        // Container(
                                        //   decoration: const BoxDecoration(
                                        //     color: Color(0xFFF36C31),
                                        //     borderRadius: BorderRadius.all(Radius.circular(24)),
                                        //   ),
                                        //   padding: const EdgeInsets.all(10),
                                        //   child:  Row(
                                        //     mainAxisSize: MainAxisSize.min,
                                        //         crossAxisAlignment: CrossAxisAlignment.center,
                                        //         children: [
                                        //           const Icon(PhosphorIconsRegular.storefront, color: Colors.white, size: 28,),
                                        //           // const SizedBox(width:8),
                                        //           // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                                        //       ],
                                        //     ),
                                        // ),
                                        sizedBox(16),
                                        Text('Our Showrooms',
                                            style: GoogleFonts.inter(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        sizedBox(8),
                                        Text(
                                            'Walk in to experience our designs.',
                                            style: GoogleFonts.inter(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                                color: Colors.black54)),
                                        sizedBox(4),
                                      ],
                                    ))),

                            sizedBox(16),
                            sizedBox(16),
                          ],
                        ),
                        sizedBox(16),
                        sizedBox(8),
                        Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              children: <Widget>[
                                sizedBox(8),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Anjani Tek',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            fontSize: 12,
                                            color: Colors.black54,
                                          )),
                                    ]),
                                sizedBox(48),
                                sizedBox(48),
                              ],
                            ))
                      ],
                    )),
              )),
            )));
  }

  // Refresh profile
  // refreshHomeAdmin(BuildContext context) async {

  //   //showToast(context, "Verifying your identity!");
  //   setState(() {updateMsg = 'Checking for updtes. Please wait...';});

  // }

  void openLink(String urlString) async {
    String message = 'Hello!'; // Replace this with your message

    Uri url = Uri.parse(urlString);

    // await canLaunchUrl(url).then((value) => {
    //   // print(value),
    //   launchUrl(url, mode: LaunchMode.externalNonBrowserApplication),
    // });
  }

  Widget productCard(int position) {
    return GestureDetector(
      onTap: () async {
        try {
          // Load from URL
          //PDFDocument doc = await PDFDocument.fromURL('https://www.ecma-international.org/wp-content/uploads/ECMA-262_12th_edition_june_2021.pdf');

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage1(
                      showCatalogues[position].name!,
                      showCatalogues[position].documentUrl!)));

          // if (!await launchUrl(Uri.parse(showCatalogues[position].documentUrl!), mode: LaunchMode.externalApplication)) {
          //   print('Launched');
          // }
          // if (!await launchUrl(Uri.parse(showCatalogues[position].documentUrl!), mode: LaunchMode.inAppBrowserView)) {
          //   print('Launched');
          // }

          // if (await canLaunch(showCatalogues[position].documentUrl!)) {
          //   await launch(showCatalogues[position].documentUrl!);
          // } else {
          //   throw 'Could not launch ${showCatalogues[position].documentUrl}';
          // }
        } catch (e) {
          print(e);
        }
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(
              color: Colors.black12, // Set the color of the border here
              width: 1, // Set the width of the border here
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0.0, 0.0),
                blurRadius: 24.0,
                spreadRadius: 0.3,
              ),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  image: DecorationImage(
                    image: NetworkImage(showCatalogues[position].imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 221, 221, 221),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.book,
                          color: Colors.black,
                          size: 24,
                        ),
                        // const SizedBox(width:8),
                        // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      showCatalogues[position].name!,
                      style: GoogleFonts.inter(
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// getting image
Map<String, bool> imageExistenceCache =
    {}; // A cache to store image existence results

class Catalogue {
  int? id;
  String? name;
  String? imageUrl;
  String? documentUrl;
  int? type;

  Catalogue({this.id, this.name, this.imageUrl, this.documentUrl, this.type});

  Catalogue.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        imageUrl = json['imageUrl'],
        documentUrl = json['documentUrl'],
        type = json['type'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['name'] = name;
    data['imageUrl'] = imageUrl;
    data['documentUrl'] = documentUrl;
    data['type'] = type;
    return data;
  }
}

// Messages model
class Messages {
  final String sender;
  final String name;

  Messages({required this.sender, required this.name});

  factory Messages.fromJson(Map<String, dynamic> json) {
    return Messages(
      sender: json['sender'],
      name: json['name'],
    );
  }
}

class BottomSheetContent extends StatefulWidget {
  final String role;
  final String adminId;
  final String name;

  const BottomSheetContent(this.role, this.adminId, this.name);

  @override
  _BottomSheetContentState createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  List<Messages> pendingMessagesList = [];
  bool pendingMessagesLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  // get dealers for approval
  Future<void> fetchMessages() async {
    setState(() {
      pendingMessagesLoading = true;
    });

    // print("${APIUrls.messaging}${APIUrls.pass}/7/${widget.role}/${widget.adminId}");
    var result = await get(
        Uri.parse(APIUrls.getUrl(
            "${APIUrls.messaging}${APIUrls.pass}/7/${widget.role}/${widget.adminId}",
            {})),
        headers: {"Accept": "application/json"});
    // print(result.body);
    Map<String, dynamic> jsonObject = jsonDecode(result.body);

    if (jsonObject['status'] == 200) {
      var dealers = jsonObject['data'] as List;

      if (dealers.isNotEmpty) {
        // list1 = dealers.map<Users>((json) => Users.fromJson(json)).toList();

        setState(() {
          pendingMessagesLoading = false;
          pendingMessagesList =
              dealers.map((message) => Messages.fromJson(message)).toList();
        });
      } else {
        // no dealers pending for approval
        setState(() {
          pendingMessagesLoading = false;
        });
      }
    } else {
      // no dealers pending for approval
      setState(() {
        pendingMessagesLoading = false;
      });
      showToast(context, "No pending messages", Constants.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pending Messages',
            style: GoogleFonts.inter(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                color: Colors.black,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: pendingMessagesLoading
                ? const Center(child: CircularProgressIndicator())
                : pendingMessagesList.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: pendingMessagesList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                                pendingMessagesList[index].name ?? 'No name'),
                            subtitle:
                                Text(pendingMessagesList[index].sender ?? ''),
                            leading: const Icon(PhosphorIconsRegular.chat),
                            onTap: () => {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MessageDetail(
                                          widget.adminId,
                                          pendingMessagesList[index].sender,
                                          widget.name,
                                          pendingMessagesList[index].name)))
                            },
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No pending messages available',
                          style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodySmall,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class MonthlyTargetSummaryCard extends StatelessWidget {
  final MonthlySalesTarget data;

  const MonthlyTargetSummaryCard({
    super.key,
    required this.data,
  });

  Color get primaryColor => const Color(0xFF2567F6);

  Color get statusColor {
    switch (data.statusLabel) {
      case "Ahead":
        return Colors.blue;
      case "On Track":
        return Colors.green;
      case "Behind":
        return Colors.orange;
      case "Critical":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // squircle-ish
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.monthLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Target: ₹${_shortCurrency(data.targetAmount)}",
                  style: textTheme.labelSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Achieved + Pending
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildValueBlock(
                label: "Achieved",
                value: "₹${_shortCurrency(data.achievedAmount)}",
                textTheme: textTheme,
                accentColor: primaryColor,
              ),
              _buildValueBlock(
                label: "Pending",
                value: "₹${_shortCurrency(data.pending)}",
                textTheme: textTheme,
                accentColor: Colors.grey[700],
                alignRight: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar & %
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: data.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${(data.progress * 100).toStringAsFixed(0)}%",
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Expected: ${(data.expectedProgress * 100).toStringAsFixed(0)}% by today",
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Days left + Daily needed + Status
          Row(
            children: [
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.event_available_outlined,
                  label: "Days left",
                  value: "${data.daysLeft}",
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.trending_up_rounded,
                  label: "Daily needed",
                  value: "₹${_shortCurrency(data.dailyNeeded)}",
                  textTheme: textTheme,
                ),
              ),
              // const SizedBox(width: 8),
              // Expanded(
              //   child: _buildStatusChip(textTheme),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueBlock({
    required String label,
    required String value,
    required TextTheme textTheme,
    Color? accentColor,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              data.statusLabel,
              style: textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _shortCurrency(double value) {
    // Very simple formatter: 1200000 -> "12.0L", 10000000 -> "1.0Cr"
    final abs = value.abs();
    if (abs >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(1)}Cr";
    } else if (abs >= 100000) {
      return "${(value / 100000).toStringAsFixed(1)}L";
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
