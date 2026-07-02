import 'dart:convert';
import 'dart:ui';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/balance_confirmation.dart';
import 'package:anjanitek/invoices_dealer.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/confirmations.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/modals/payment_only.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/target.dart';
import 'package:anjanitek/no_login_experience2.dart';
import 'package:anjanitek/notifications_dealer2.dart';
import 'package:anjanitek/payments_dealer.dart';
import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/products_listing.dart';
import 'package:anjanitek/profile.dart';
import 'package:anjanitek/showrooms.dart';
import 'package:anjanitek/targets_dealer_report.dart';
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
// import 'package:anjanitek/profile_update.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
// import 'package:anjanitek/util/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'utils/dotted_line.dart';

// this is 
class HomeDealer extends StatefulWidget {
  @override
  _HomeDealerState createState() => _HomeDealerState();
}

class _HomeDealerState extends State<HomeDealer> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String mapName='',mapMobile='',
  mobile='', email = '-', role = '-', id='', name='', userImage='',gcm_regId='',
  accountName='',dealerId='',salesId='',city='',state='',gst='',address1='',address2='',address3='';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  bool confirmationCheckProgress = false;
  bool targetsDataProgress = false;
  bool addConfirmationProgress = false;
  bool closingConfirmationProgress = false;
  bool catalogueCheckProgress = false;
  late List<Invoices> invoicesList = [];
  late List<Confirmation> confirmations = [];
  late List<Product> designOfTheDayList = [];
  bool checkDesignOfTheDayList = false;
  late List<ProductTag> productTagsList = [];
  bool anyOutstanding = true;
  String confirmationStatus = 'Checking';
  late Confirmation confirmation ;
  
  double totalOutstandingATL = 0;
  double totalOutstandingVCL = 0;
  double creditOutstanding = 0;

  String dueDateATL = '';
  String dueDateVCL = '';
  String nearestDueDate = '-';
  // bool _isHidden = false;
  
  int daysLeft = 0;
  bool connectionStatus = true;

  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");
  List<Catalogue> showCatalogues = [];
  List<Target> targetsDataList = [];
  String? currentMonthTargetDate;
  
  // user object
  Invoices? invoices ;
  // Create a FocusNode
  
  late SharedPreferences prefs;
  DatabaseHelper dbHelper = DatabaseHelper();

  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
      
      // get reference to internal database
      getUsers();

      _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 1000),);
      _controller.forward();

      controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
      scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.easeOut);

      controller.addListener(() {
        setState(() {});
      });

    // CurvedAnimation(
    //         parent: _visible ? Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //           parent: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
    //           curve: Curves.easeIn, // Use Curves.easeIn for ease-in animation
    //         )) : Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
    //           parent: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
    //           curve: Curves.easeIn,
    //         )),
    //       );
    _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
    _controllerCards.forward();
    
    super.initState();
  }

void openModal() {
    showModalBottomSheet(
      // context: context,
      // backgroundColor: Colors.transparent,
      
      
      isDismissible: true,
      enableDrag: false,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      
      isScrollControlled: true,
      // useRootNavigator: true,
      // isDismissible: false,
      // useSafeArea: false,
      
      elevation: 20.0,
      context: context, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0)
        )
      ),
      
      // constraints: BoxConstraints(
      //                 // maxHeight: 400.0, // Set the maximum height
      //                 maxWidth: MediaQuery.of(context).size.width - 20.0
      //               ),
      clipBehavior: Clip.antiAliasWithSaveLayer,

      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Center(
            child: Profile(),
            // child: Text("This is a modal sheet"),
          ),
        );
      },
    ).whenComplete(() {
      controller.reverse();
    });

    controller.forward();
  }

   @override
    void dispose() {

      
      _controller.dispose();
      _controllerCards.dispose();

      super.dispose();
    }

  
    // get user details
    void getUsers() async {
      // fetch from internal db
      // final dbHelper = DatabaseInternal.instance;
      // final allRows = await dbHelper.queryAllRows();
// print('users count ${allRows.length}');
 // no profile exists
        await dbHelper.initDb();
        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
          id = prefs.get(Constants.id) as String;
          name = prefs.get(Constants.name) as String;
          email = prefs.get(Constants.email) as String;
          role = prefs.get(Constants.role) as String;
          mobile = prefs.get(Constants.mobile) as String;
          userImage = prefs.get(Constants.userImage) as String;
          gcm_regId = prefs.get(Constants.gcmRegId) as String;
          isActive = prefs.get(Constants.isActive) as int;
          mapName = prefs.get(Constants.mapName) as String ?? '';
          mapMobile = prefs.get(Constants.mapMobile) as String ?? '';
          
          if(prefs.get(Constants.role) == Constants.dealer){

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
        refreshUserHomeDealer1(context);
        // getDealerLatestConfirmation(context); // get balance confirmations data
        // getCatalogues(context);

        getDesignOfTheDay().then((value) {
          // print(value);
            final Map<String, dynamic> map = value as Map<String, dynamic>;
            setState(() {
              designOfTheDayList = map['products'] as List<Product>? ?? [];
              // final List<dynamic> products = map['products'] as List<dynamic>? ?? [];
              // designOfTheDayList = products.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();

              productTagsList = map['tags'] as List<ProductTag>? ?? [];
              // final List<dynamic> tags = map['tags'] as List<dynamic>? ?? [];
              // productTagsList = tags.map((t) => ProductTag.fromJson(t as Map<String, dynamic>)).toList();
              
              checkDesignOfTheDayList = true;
            });
          }); 

    }

    // Function to generate dots based on the length of the original value
    String _getDots(String value) {
      return '•' * value.length;
    }

    // log user session
    // also check if the user is active or not
    // if not active then logout the user
    void logUserSession() async {

      if(await checkInternetConnectivity()){
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U0/$id/$role/user", {})), headers: {"Accept": "application/json"});
        var jsonString = jsonDecode(result.body); 
        var jsonObject = jsonString as Map; 
        
        if(jsonObject['status'] == 200){
          
            int isActive = jsonObject['data'] as int;
            if(isActive == 0){
              // user is not active, logout the user
              showToast(context, 'Your account is inactive. Please contact support.', Constants.warning);
              await OneSignal.logout().whenComplete(() {});
              clearData();
              await dbHelper.deleteAllNotifications();
              await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AnjaniTekApp2()));
            }
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          logUserSession();
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }

    void refreshUserHomeDealer1(BuildContext context) async {

      if(await checkInternetConnectivity()){

        setState(() {
          refreshCheckProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };
 
        // API call
        // print("${APIUrls.amount}${APIUrls.pass}/U1/$id");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.amount}${APIUrls.pass}/U1/$id", queryParams)), headers: {"Accept": "application/json"});
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
          
            // get the user data from jsonObject
            var invoicesData = jsonObject['data'] as List;
            var balanceData = (jsonObject['balance'] != null) ? PaymentsOnly.fromJson(jsonObject['balance']) : null;
            // Map<String, dynamic> invoicesData = jsonObject['data'];

            setState(() {
              creditOutstanding = (balanceData != null) ? (balanceData.balance! > 0 ? 0 : balanceData.balance!.abs()) : 0;
            });

            if(invoicesData.isNotEmpty){
              // convert to list
              invoicesList = invoicesData.map<Invoices>((json) => Invoices.fromJson(json)).toList();
              
              
                // ATL outstanding
                double totalSum = invoicesList.fold(0.0, (double sum, Invoices invoice) {
                  if(invoice.invoiceType=="ATL"){
                    return sum + (invoice.pending ?? 0.0);
                  }
                  return sum;
                });

                // VCL outstanding
                double totalSum1 = invoicesList.fold(0.0, (double sum, Invoices invoice) {
                  if (invoice.invoiceType == "VCL") {
                    return sum + (invoice.pending ?? 0.0); // Add to sum only if condition is met
                  }
                  return sum; 
                });


                /// Find the earliestExpiryDate of ATL invoices
                List<DateTime> expiryDates = invoicesList
                    .where((invoice) => invoice.expiryDate != null && invoice.invoiceType == "ATL") // Filter out null expiry dates and non-"VCL" types
                    .map((invoice) => format.parse(invoice.expiryDate!)) // Parse string to DateTime
                    .toList(); // Convert the iterable to a list

                DateTime? earliestExpiryDate;
                if (expiryDates.isNotEmpty) {
                  earliestExpiryDate = expiryDates.reduce((a, b) => a.isBefore(b) ? a : b); // Find the earliest date
                } else {
                  earliestExpiryDate = null; // Handle case where no dates are available
                }

                setState(() {
                  // get the days left for expiry  // Output the earliest date in a friendly format, e.g., January 1, 2023
                  Duration duration = (earliestExpiryDate!=null) ? earliestExpiryDate.difference(DateTime.now()) : const Duration(days:0);
                  String formattedDate = (earliestExpiryDate!=null) ? DateFormat('MMMM d, yyyy').format(earliestExpiryDate) : '-';
              


                /// Find the earliestExpiryDate of VCL invoices
                List<DateTime> expiryDates1 = invoicesList
                    .where((invoice) => invoice.expiryDate != null && invoice.invoiceType == "VCL") // Filter out null expiry dates and non-"VCL" types
                    .map((invoice) => format.parse(invoice.expiryDate!)) // Parse string to DateTime
                    .toList(); // Convert the iterable to a list

                DateTime? earliestExpiryDate1;
                if (expiryDates1.isNotEmpty) {
                  earliestExpiryDate1 = expiryDates1.reduce((a, b) => a.isBefore(b) ? a : b); // Find the earliest date
                } else {
                  earliestExpiryDate1 = null; // Handle case where no dates are available
                }

                
                  // get the days left for expiry  // Output the earliest date in a friendly format, e.g., January 1, 2023
                  Duration duration1 = (earliestExpiryDate1!=null) ? earliestExpiryDate1.difference(DateTime.now()) : const Duration(days:0);
                  String formattedDate1 = (earliestExpiryDate1!=null) ? DateFormat('MMMM d, yyyy').format(earliestExpiryDate1) : '-';
                
                totalOutstandingATL = totalSum;
                totalOutstandingVCL = totalSum1;
                // creditOutstanding = (balanceData != null) ? (balanceData.balance! > 0 ? 0 : balanceData.balance!.abs()) : 0;
                // creditOutstanding = (balanceData != null) ? balanceData.balance! : 0;
                // creditOutstanding = creditOutstanding > 0 ? 0 : creditOutstanding.abs();
                // creditOutstanding = 10.0;
                dueDateATL = formattedDate;
                dueDateVCL = formattedDate1;



                // From ATL and VCL, find the nearest expiry date from the 2 expiry dates
                DateTime? earliestExpiryDateOutOfBoth = getNearestDateTime(earliestExpiryDate,earliestExpiryDate1);
                nearestDueDate = earliestExpiryDateOutOfBoth != null ? DateFormat('MMMM d, yyyy').format(earliestExpiryDateOutOfBoth) : '-';
                daysLeft = (earliestExpiryDateOutOfBoth != null) ? earliestExpiryDateOutOfBoth.difference(DateTime.now()).inDays: 0;
                
                // indicate there is outstanding
                anyOutstanding = false;

                // hide the progress
                refreshCheckProgress = false;
                connectionStatus = true;
              });

              getDealerLatestConfirmation(context); // get balance confirmations data

              getTargetsData(context); // get sales targets data
            

          }
          else {
            getDealerLatestConfirmation(context);
            setState(() {
              totalOutstandingATL = 0;
              totalOutstandingVCL = 0;
              daysLeft = 0;
              anyOutstanding = false;
              refreshCheckProgress = false;
              connectionStatus = true;
            });
            
          }
          
        }
        else if(jsonObject['status'] == 402){
          // no data exists
          setState(() {
            // get the error message
            refreshCheckProgress = false;
            connectionStatus = true;
          });
          
        }
        else if(jsonObject['status'] == 404){
          // no data exists
          setState(() {
            // get the error message
            refreshCheckProgress = false;
            connectionStatus = true;
          });
          
        }
        else {

            setState(() {
              refreshCheckProgress = false;
              connectionStatus = true;
              showToast(context, 'Error, try again later!',Constants.error);
            });
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          refreshUserHomeDealer1(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }


    // check for balance confirmation events
    void getDealerLatestConfirmation(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          confirmationCheckProgress = true;
        });

        // API call
        // print("${APIUrls.confirmations}${APIUrls.pass}/C4/$id");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.confirmations}${APIUrls.pass}/C4/$id", {})), headers: {"Accept": "application/json"});
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
        
            // get the user data from jsonObject
            var confirmationsData = jsonObject['data'] as List;
            
            setState(() {
              confirmationCheckProgress = false;
              connectionStatus = true;

              // here the response is already recorded, hence it can be correct/incorrect as mentioned by the dealer
              confirmation = Confirmation.fromJson(confirmationsData.first);
              confirmationStatus = (Confirmation.fromJson(confirmationsData.first).response == 'Yes') ? Constants.yes : Constants.no;
            });
          
        }
        else if(jsonObject['status'] == 201){
          var eventsData = jsonObject['data'] as Map;
          
          // eventId, anjaniAmount, confirmationOn, dealer, dealerAmount, response, comment, media
          // add time to the date
          DateTime now = DateTime.now();
          DateTime confirmationOn = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
          );

          // set the confirmation object
          setState(() {

            confirmation = Confirmation(
              eventId: eventsData['id'],
              anjaniAmount: totalOutstandingATL+totalOutstandingVCL,
              confirmationOn: DateFormat('yyyy-MM-dd hh:mm:ss', 'en_US').format(confirmationOn),
              dealer: id,
              dealerAmount: totalOutstandingATL+totalOutstandingVCL,
              response: 'Yes',
              responseReason: '-',
              comment: '-',
              media: '-',
            );
            
            confirmationStatus = Constants.pending;  

            confirmationCheckProgress = false;
            connectionStatus = true;
          });
        }
        else {
          // no data exists
          setState(() {
            // get the error message
            confirmationCheckProgress = false;
            connectionStatus = true;
          });
          
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          getDealerLatestConfirmation(context);
          
          // set the connection Status variable to false
          setState(() {
            confirmationCheckProgress = false;
          });
          
        });
      }
    }
    
    // get sales & collections targets data for this dealer
    void getTargetsData(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          targetsDataProgress = true;
        });

        // API call
        print("${APIUrls.targets}${APIUrls.pass}/T1/${DateTime.now().year}-${DateTime.now().month}-01/$id");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.targets}${APIUrls.pass}/T1/${DateTime.now().year}-${DateTime.now().month}-01/$id", {})), headers: {"Accept": "application/json"});
        print(result.body);
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['success']){
        
            // get the user data from jsonObject
            var targetsData = jsonObject['data'] as List;

            if(targetsData.isEmpty){
              setState(() {
                targetsDataProgress = false;
                connectionStatus = true;
              });
              return;
            }
            var targets = targetsData[0]['targets'] as List;

            // print(targetsData);
            // print(targets);

            setState(() {
              
              targetsDataList = targets.map<Target>((json) => Target.fromJson(json)).toList();
              currentMonthTargetDate = targetsData[0]['monthDate'];
              targetsDataProgress = false;
              connectionStatus = true;
              // here the response is already recorded, hence it can be correct/incorrect as mentioned by the dealer
              // confirmation = Confirmation.fromJson(targetsData.first);
              // confirmationStatus = (Confirmation.fromJson(targetsData.first).response == 'Yes') ? Constants.yes : Constants.no;
            });

        }
        else if(jsonObject['status'] == 201){
          
          // set the confirmation object
          setState(() {

            targetsDataProgress = false;
            connectionStatus = true;
          });
        }
        else {
          // no data exists
          setState(() {
            // get the error message
            targetsDataProgress = false;
            connectionStatus = true;
          });
          
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          getTargetsData(context);
          
          // set the connection Status variable to false
          setState(() {
            targetsDataProgress = false;
          });
          
        });
      }
    }
    
    // Create the confirmation from the dealer for a given latest event
    void addConfirmationByDealer(BuildContext context) async {

      if(await checkInternetConnectivity()){

        setState(() {
          addConfirmationProgress = true;
          
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        // print("${APIUrls.confirmations}${APIUrls.pass}/C5/${confirmation.eventId}/${confirmation.anjaniAmount}/${confirmation.confirmationOn}/${confirmation.dealer}/${confirmation.dealerAmount}/${confirmation.response}/${confirmation.responseReason}/${confirmation.media}");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.confirmations}${APIUrls.pass}/C5/${confirmation.eventId}/${confirmation.anjaniAmount}/${confirmation.confirmationOn}/${confirmation.dealer}/${confirmation.dealerAmount}/${confirmation.response}/${confirmation.responseReason}/${confirmation.media}", queryParams)), headers: {"Accept": "application/json"});
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
            
            setState(() {
              addConfirmationProgress = false;
              connectionStatus = true;

              confirmationStatus = Constants.yes;
            });
          
          showToast(context, 'Response Submitted!', Constants.success);
        }
        else {

          // no data exists
          setState(() {
            // get the error message
            addConfirmationProgress = false;
            connectionStatus = true;
          });
        
          showToast(context, 'Issue submitting response. Try again!', Constants.warning);
        
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          addConfirmationByDealer(context);
          
          // set the connection Status variable to false
          setState(() {
            addConfirmationProgress = false;
          });
          
        });
      }
    }
    
    // close confirmation by dealer after finanace team responded
    void closeConfirmationByDealer(BuildContext context) async {

      if(await checkInternetConnectivity()){

        setState(() {
          closingConfirmationProgress = true;
        });
        // API call
        // print("${APIUrls.confirmations}${APIUrls.pass}/C8/${confirmation.id}");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.confirmations}${APIUrls.pass}/C8/${confirmation.id}", {})), headers: {"Accept": "application/json"});
        // print(result.body);
        
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        var jsonObject = jsonString as Map; 
        if(jsonObject['status'] == 200){
            
            setState(() {
              closingConfirmationProgress = false;
              connectionStatus = true;

              confirmationStatus = Constants.yes;
            });
          showToast(context, 'Request Closed!', Constants.success);
        }
        else {
          setState(() {
            closingConfirmationProgress = false;
            connectionStatus = true;
          });
          showToast(context, 'Issue submitting response. Try again!', Constants.warning);
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          closeConfirmationByDealer(context);
          setState(() {
            closingConfirmationProgress = false;
          });
        });
      }
    }


    // Get the catalogues
    void getCatalogues(BuildContext context) async {

      setState(() {
        catalogueCheckProgress = true;
      });
      
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.catalogues}${APIUrls.pass}/1", queryParams)), headers: {"Accept": "application/json"});
      // print(result.body);
      
      // Decode the JSON string into a Map using the jsonDecode function
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      // user object list
      
      // check if the api returned success
      if(jsonObject['status'] == 200){
        
          // get the user data from jsonObject
          var showCataloguesData = jsonObject['data'] as List;
            // Map<String, dynamic> invoicesData = jsonObject['data'];

            if(showCataloguesData.isNotEmpty){
            

              List<Catalogue> cataloguesList = showCataloguesData.map<Catalogue>((json) => Catalogue.fromJson(json)).toList();
          
                setState(() {
                  // Get new user data
                  showCatalogues = cataloguesList;
                  catalogueCheckProgress = false;
                });
            }
      }
      else if(jsonObject['status'] == 402 || jsonObject['status'] == 404){
        // no data exists
        setState(() {
          // get the error message
          catalogueCheckProgress = false;
        });
        
      }
      else {

          setState(() {
            catalogueCheckProgress = false;
            // showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }

DateTime? getNearestDateTime(DateTime? date1, DateTime? date2) {
  if (date1 == null && date2 == null) {
    return null;
  } else if (date1 == null) {
    return date2;
  } else if (date2 == null) {
    return date1;
  } else {
    // Calculate the difference between the reference date and each of the dates
    final difference1 = DateTime.now().difference(date1).abs();
    final difference2 = DateTime.now().difference(date2).abs();
    
    // Compare and return the nearest date
    return difference1 < difference2 ? date1 : date2;
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
      // backgroundColor: Color(0xFF008060),
      backgroundColor: Colors.white,
        body: 
        Transform.scale(
        scale: 1 - controller.value * 0.05,
        alignment: Alignment.topCenter,
        child: 
        
         FadeTransition(opacity: _controller,
        child:
        
        // Stack(
          
        //   children: [
            
          //     FadeTransition(opacity: _controller,
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
          //                   color: const Color(0xFFFF93F4).withOpacity(0.5),
          //                   offset: const Offset(0.0, 0.0),
          //                   blurRadius: 44.0,
          //                   spreadRadius: 27.3,
          //                 ),
          //               ],
          //               // border: Border.all(color: Colors.black, width: 2.0),
          //               shape: BoxShape.circle,
          //               color: const Color(0xFFFF93F4).withOpacity(0.0),
          //             ),
          //           ),
          //       )
          //     ),
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
          //     )
          
          
        
            

            Align(
              alignment: Alignment.topCenter,
              child:
      SafeArea(

        child: SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child:
      Column(

        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,

        children: <Widget>[

          Column(
          // child: CardRound(Palette.lightBackground, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              
              // Container(
              //     // color: Colors.black12,
              //     padding: EdgeInsets.fromLTRB(0, 16, 8, 8),
              //     child: 
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         mainAxisSize: MainAxisSize.max,
            //         children: <Widget>[
                      
            //           // Container(width: 0, height: 0,),
            //           SizedBox(width: 32),
            //           Image.asset('assets/anjani_title1.webp', scale: 3,), 
            //           // IconButton(icon: Icon(PhosphorIconsBold.arrowBendUpLeft, color: Theme.of(context).hintColor, size: 24,),
            //           // IconButton(icon: Icon(Icons.keyboard_backspace, color: Theme.of(context).hintColor, size: 24,),
            //           // onPressed: () => 
            //           //     Navigator.pop(context)
            //           //   ,
            //           // ),
            // // Expanded(
            // //               child:
            // //           Container(
            // //             // color: Colors.black12,
            // //             margin: EdgeInsets.fromLTRB(32, 0, 0, 0), 
            // //             child: 
            // //              Image.asset('assets/anjani_title1.webp', scale: 2,), 
                        
            // //           //   Column(
                        
            // //           //   mainAxisAlignment: MainAxisAlignment.start,
            // //           //   crossAxisAlignment: CrossAxisAlignment.start,
            // //           //   mainAxisSize: MainAxisSize.max,
                        
            // //           //   children: <Widget>[

            // //           //     Image.asset('assets/anjani_title1.webp', scale: 1,),
                          
            // //           //   ],
            // //           // ),
            // //           )
            // //           ),
            //           IconButton(icon: Icon(PhosphorIconsRegular.userCircle, color: Theme.of(context).hintColor, size: 24,),
            //           onPressed: openModal,
            //           ),
            //         ],
            //       ),
                    
                // ),
              sizedBox(24),
              Image.asset('assets/anjani_title1.webp', scale: 2,), 
              sizedBox(24),
              Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
              // sizedBox(8),
              // Column(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     sizedBox(24),
              //     Text('Your Total Outstanding', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w400, color: Colors.black87), ),
              //     sizedBox(8),
              //     RichText(
              //     text: TextSpan(
              //       text: '₹ ${NumberFormat("#,##,##0", "en_IN").format(totalOutstandingATL+totalOutstandingVCL)}',
              //       style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 30, letterSpacing: 1.5, fontWeight: FontWeight.w600, color: Colors.black),
              //       children: <TextSpan>[
              //       TextSpan(
              //         text: '.${NumberFormat("00", "en_IN").format((totalOutstandingATL+totalOutstandingVCL) % 1 * 100)}',
              //         style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w400, color: Colors.black),
              //       ),
              //       ],
              //     ),
              //     ),
              //   ],
              // ),
              
              sizedBox(16),
                    

              //     InkWell(
              //         onTap: () {
              //           Navigator.push(context, MaterialPageRoute(builder: (context) => ProductCollections()));
              //         },
              //       child: 
              //       Container(
              //         // height: 200,
              //         width: MediaQuery.of(context).size.width-32,
              //         // padding: const EdgeInsets.all(20),
              //         decoration: BoxDecoration(
              //           border: Border.all(color: Colors.orange, width: 0.5),
              //           borderRadius: BorderRadius.circular(24),
              //           gradient: LinearGradient(
              //             colors: [Colors.orange.shade100, Colors.orange.shade50],
              //             // colors: [Colors.orange.shade200, Colors.deepOrangeAccent.shade100],
              //             // colors: [Color(0xFF008060), Colors.green.shade800],
              //             // colors: [Colors.amber.shade400, Colors.green.shade800],
              //             begin: Alignment.topLeft,
              //             end: Alignment.bottomRight,
              //           ),
              //           boxShadow: [
              //             BoxShadow(
              //               color: Colors.black12, // Shadow color
              //               // color: Colors.black12, // Shadow color
              //               spreadRadius: 5, // How much the shadow spreads
              //               blurRadius: 10, // How blurred the shadow is
              //               offset: Offset(0, 10), // Offset in x, y direction
              //             ),
              //           ],
              //         ),
              //         child: ClipRRect(
              //           borderRadius: BorderRadius.circular(24),
              //           child: BackdropFilter(
              //             filter: ImageFilter.blur(sigmaX: 1, sigmaY: 8),
              //             child: 
              //             Container(
              //               padding: const EdgeInsets.fromLTRB(12,12,12,12),
              //               color: Colors.white10, // Translucent effect
              //               child: Column(
              //                 children: [
                                
              //                       Text(name, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.bold)),
                                
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
              //                       Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()));
              //                       // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
              //                     },
              //                     child: Text('Your profile', style: TextStyle(color: Colors.black)),
              //                   ),
                                
              //                 ],
              //               )
                            
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              // sizedBox(16),
                    

              //     InkWell(
              //         onTap: () {
              //           Navigator.push(context, MaterialPageRoute(builder: (context) => ProductCollections()));
              //         },
              //       child: 
              //       Container(
              //         // height: 200,
              //         width: MediaQuery.of(context).size.width-32,
              //         // padding: const EdgeInsets.all(20),
              //         decoration: BoxDecoration(
              //           border: Border.all(color: Colors.orange, width: 0.5),
              //           borderRadius: BorderRadius.circular(24),
              //           gradient: LinearGradient(
              //             colors: [Colors.orange.shade200, Colors.deepOrangeAccent.shade100],
              //             // colors: [Color(0xFF008060), Colors.green.shade800],
              //             // colors: [Colors.amber.shade400, Colors.green.shade800],
              //             begin: Alignment.topLeft,
              //             end: Alignment.bottomRight,
              //           ),
              //           boxShadow: [
              //             BoxShadow(
              //               color: Colors.black12, // Shadow color
              //               // color: Colors.black12, // Shadow color
              //               spreadRadius: 5, // How much the shadow spreads
              //               blurRadius: 10, // How blurred the shadow is
              //               offset: Offset(0, 10), // Offset in x, y direction
              //             ),
              //           ],
              //         ),
              //         child: ClipRRect(
              //           borderRadius: BorderRadius.circular(24),
              //           child: BackdropFilter(
              //             filter: ImageFilter.blur(sigmaX: 1, sigmaY: 8),
              //             child: 
              //             Container(
              //               padding: const EdgeInsets.fromLTRB(12,24,12,12),
              //               color: Colors.white10, // Translucent effect
              //               child: Column(
              //                 children: [
              //                   Container(
              //                     width: 250,
              //                     // color: Colors.blue,
              //                     child: Stack(
              //                       children: [
              //                         Transform.rotate(
              //                           angle: -0.4,
              //                           child: Container(
              //                                   width: 100.0, // Adjust the size as needed
              //                                   height: 100.0, // Adjust the size as needed
              //                                   decoration: BoxDecoration(
              //                                     color: Colors.white,
              //                                     image: const DecorationImage(
              //                                       image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F81001.jpeg?alt=media'),
              //                                       fit: BoxFit.cover,
              //                                     ),
              //                                     borderRadius: BorderRadius.circular(16),
              //                                     boxShadow: [
              //                                       BoxShadow(
              //                                         color: Colors.black12, // Shadow color
              //                                         spreadRadius: 5, // How much the shadow spreads
              //                                         blurRadius: 20, // How blurred the shadow is
              //                                         offset: const Offset(0, 10), // Offset in x, y direction
              //                                       ),
              //                                     ],
              //                                   ),
              //                                 ),
              //                             ),

              //                             Positioned(top: 0, left: 60, right: 60,
              //                             child: Transform.rotate(
              //                                     angle: -0.3,
              //                                     child: Container(
              //                                             width: 100.0, // Adjust the size as needed
              //                                             height: 100.0, // Adjust the size as needed
              //                                             decoration: BoxDecoration(
              //                                               color: Colors.white,
              //                                               image: const DecorationImage(
                                                              
              //                                                 image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F51007_F10.jpeg?alt=media'),
              //                                                 fit: BoxFit.cover,
              //                                               ),
              //                                               borderRadius: BorderRadius.circular(16),
              //                                               boxShadow: [
              //                                                 BoxShadow(
              //                                                   color: Colors.black12, // Shadow color
              //                                                   spreadRadius: 5, // How much the shadow spreads
              //                                                   blurRadius: 20, // How blurred the shadow is
              //                                                   offset: const Offset(0, 10), // Offset in x, y direction
              //                                                 ),
              //                                               ],
              //                                             ),
              //                                           ),
              //                                       ),
              //                             ),
              //                             Positioned(top: 0, right: 0,
              //                             child: Transform.rotate(
              //                                     angle: 0.1,
              //                                     child: Container(
              //                                             width: 100.0, // Adjust the size as needed
              //                                             height: 100.0, // Adjust the size as needed
              //                                             decoration: BoxDecoration(
              //                                               color: Colors.white,
              //                                               image: const DecorationImage(
              //                                                 image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F21033.jpeg?alt=media'),
              //                                                 // image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F51010.jpeg?alt=media'),
              //                                                 fit: BoxFit.cover,
              //                                               ),
              //                                               borderRadius: BorderRadius.circular(16),
              //                                               boxShadow: [
              //                                                 BoxShadow(
              //                                                   color: Colors.black12, // Shadow color
              //                                                   spreadRadius: 5, // How much the shadow spreads
              //                                                   blurRadius: 20, // How blurred the shadow is
              //                                                   offset: const Offset(0, 10), // Offset in x, y direction
              //                                                 ),
              //                                               ],
              //                                             ),
              //                                           ),
              //                                       ),
              //                             ),
              //                       ],
              //                     ),
              //                   ),
                                    
                                
              //                   sizedBox(24),
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
              //                       Navigator.push(context, MaterialPageRoute(builder: (context) => ProductCollections()));
              //                       // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
              //                     },
              //                     child: Text('Browse Designs', style: TextStyle(color: Colors.black)),
              //                   ),
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
              //                       Navigator.push(context, MaterialPageRoute(builder: (context) => StockReservationsPage()));
              //                       // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
              //                     },
              //                     child: Text('Stock Reservations', style: TextStyle(color: Colors.black)),
              //                   ),
                                
              //                 ],
              //               )
                            
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              // sizedBox(16),
              
              confirmationCheckProgress ? 
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppProgress(height: 30, width: 30,),
                  Text('Checking for updates...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                ],
                ) : sizedBox(0),
              // CASE 1 of confirmation
              // Don't show anything if its checking or already submitted (Correct) scenario
              // (confirmationStatus == Constants.checking || confirmationStatus == Constants.yes ) ? sizedBox(0) : DottedLine(),
              // (confirmationStatus == Constants.checking || confirmationStatus == Constants.yes ) ? sizedBox(0) :

            //   Container(
            //     decoration: BoxDecoration(
            //     // color: const Color(0xFFFEFEFE),

            //             border: Border.all(color: Colors.white, width: 0.5),
            //             borderRadius: BorderRadius.circular(24),
            //             gradient: LinearGradient(
            //               // colors: [Color(0xFFF6F1E7), Colors.orange],
            //               colors: [const Color.fromARGB(255, 255, 238, 212), Colors.pink.shade200],
            //               // colors: [const Color.fromARGB(255, 221, 221, 221), Colors.deepPurpleAccent],
            //               // colors: [Color(0xFF008060), Colors.green.shade800],
            //               // colors: [Colors.amber.shade400, Colors.green.shade800],
            //               begin: Alignment.topLeft,
            //               end: Alignment.bottomRight,
            //             ),
            //             boxShadow: [
            //               BoxShadow(
            //                 color: Colors.black12, // Shadow color
            //                 // color: Colors.black12, // Shadow color
            //                 spreadRadius: 5, // How much the shadow spreads
            //                 blurRadius: 10, // How blurred the shadow is
            //                 offset: Offset(0, 10), // Offset in x, y direction
            //               ),
            //             ],
            //     // boxShadow: const [
            //     //   BoxShadow(
            //     //     color: Colors.white,
            //     //     offset: Offset(0.0, 0.0),
            //     //     blurRadius: 24.0,
            //     //     spreadRadius: 0.3,
            //     //   ),
            //     // ]
            //   ),
            //   padding: const EdgeInsets.all(16),
            //   child: 
            //   Row(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         spacing: 8,
            //         children: [
            //           Image.asset('assets/offers.webp',width: 120.0), sizedBox(4),
            //           Expanded(child: 
            //           Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             spacing: 6,
            //             children: [
                          
            //               Text('Grab the offers!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                          
            //               Text('AnjaniTek brings exciting offers to you.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
            //               sizedBox(8),
            //               ElevatedButton(
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: Color(0xFFFFFFFF), // Dark background color
                              
            //                   textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
            //                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(24),
            //                   ),
            //                   elevation: 5, // Shadow depth
            //                 ),
            //                 onPressed: () {
            //                   Navigator.push(context, MaterialPageRoute(builder: (context) => OffersForDealer()));
            //                   // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
            //                 },
            //                 child: Text('View Offers', style: TextStyle(color: Colors.black)),
            //               ),
                          
            //             ]
                            
            //           )
            //           )
            //         ],
            //       )
                  
            // ),
            // sizedBox(16),
            (confirmationStatus == Constants.checking || confirmationStatus == Constants.yes ) ? sizedBox(0) :
              Container(
                decoration: BoxDecoration(
                // color: const Color(0xFFF6F1E7),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(
                          color: Colors.black12, // Set the color of the border here
                          width: 1, // Set the width of the border here
                        ),

                        gradient: const LinearGradient(
                          colors: [Color(0xFFF6F1E7), Colors.orange],
                          // colors: [Color(0xFF008060), Colors.green.shade800],
                          // colors: [Colors.amber.shade400, Colors.green.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12, // Shadow color
                            // color: Colors.black12, // Shadow color
                            spreadRadius: 5, // How much the shadow spreads
                            blurRadius: 10, // How blurred the shadow is
                            offset: Offset(0, 10), // Offset in x, y direction
                          ),
                        ]
                // boxShadow: const [
                //   BoxShadow(
                //     color: Colors.white,
                //     offset: Offset(0.0, 0.0),
                //     blurRadius: 24.0,
                //     spreadRadius: 0.3,
                //   ),
                // ]
              ),
              padding: const EdgeInsets.all(16),
              child: 
              Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    children: [

                      // Container(
                      //   decoration: const BoxDecoration(
                      //     color: Color(0xFF008060),
                      //     // color: Color(0xFFFFA135),
                      //     borderRadius: BorderRadius.all(Radius.circular(24)),
                      //   ),
                      //   padding: const EdgeInsets.all(8),
                      //   child:  Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //         crossAxisAlignment: CrossAxisAlignment.center,
                      //         children: [
                      //           // const Icon(PhosphorIconsRegular.moneyWavy, color: Colors.white, size: 28,),
                      //           Image.asset('assets/b_confirmation.webp',width: 120.0), sizedBox(4),
                      //       ],
                      //     ),
                      // ),
                      // Image.asset('assets/b_confirmation.webp',width: 120.0), sizedBox(4),
                      // SizedBox(width: 16,),
                      Expanded(child: 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 6,
                        children: [
                          Image.asset('assets/confirmation.webp',width: 120.0), sizedBox(4),
                          Text('Balance Confirmation request', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                          
                          Text('Please confirm the outstanding you see in the app right now is same as per your account records for AnjaniTek tiles', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                          sizedBox(8),
                          (confirmationStatus == Constants.no) ? 
              
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50, // Subtle red background
                              borderRadius: BorderRadius.circular(8), // Border radius
                            ),
                            child: 
                            Center(
                              child:

                                // UI here will be based on the Finance team has responded or not
                                (confirmation.comment!=null) ? 
                                  Column(
                                    spacing: 8,
                                    children: [ 
                                      // Show that its incorrect
                                      Text(
                                        'Message from Finance Team:',
                                        style: GoogleFonts.inter(
                                        textStyle: Theme.of(context).textTheme.bodyLarge,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        
                                        ),softWrap: true,
                                        textAlign: TextAlign.center,
                                      ),
                                      (confirmation.comment!=null) ? Text(confirmation.comment!) : sizedBox(0),
                                      
                                        (closingConfirmationProgress) ? 
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const AppProgress(height: 30, width: 30,),
                                            Text('Closing request...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                          ],
                                          ) :
                                            ElevatedButton(
                                              onPressed: () {
                                                closeConfirmationByDealer(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black45,
                                                textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                                padding: const EdgeInsets.fromLTRB(16,4,16,4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(24),
                                                ),
                                                elevation: 5, // Shadow depth
                                              ),
                                              
                                              child: Text('Close request', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14,),),
                                            ),
                                            
                                        //   ],
                                        // )
                                    ],
                                  )
                                  :
                                  Text(
                                    'Balance mismatch request submitted. Finance team is looking into it and will reach out to you.',
                                    style: GoogleFonts.inter(
                                    textStyle: Theme.of(context).textTheme.bodyLarge,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    
                                    ),softWrap: true,
                                    textAlign: TextAlign.center,
                                  )
                              
                            )
                          )
                          :

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              addConfirmationProgress ? 
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                                    // sizedBox(8),
                                    const AppProgress(height: 30, width: 30,),
                                    Text('Submitting your response!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                    
                                  ],
                                )
                              )
                              :
                              Wrap(
                                spacing: 8,
                                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Add your first button action here
                                        addConfirmationByDealer(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF008060), // Dark background color
                                        textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        elevation: 5, // Shadow depth
                                      ),
                                      child: const Row(
                                        spacing: 8,
                                        children: [
                                          Icon(PhosphorIconsRegular.check, color: Colors.white,),
                                          Text('Balance is Correct',  style: TextStyle(color: Colors.white)),
                                        ],
                                      )
                                      
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Add your second button action here
                                        // setState(() {
                                        //   confirmation.response = 'No';  
                                        //   confirmation.comment = 'Outstanding balance mismatch';  
                                        // });
                                        
                                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => BalanceConfirmation(confirmation)));
                                        if (result != null && result['status'] == Constants.success) {
                                          setState(() {
                                            confirmationStatus = Constants.no;
                                            confirmation.comment = null;
                                          });
                                        }
                                        
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                                          
                                          textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          elevation: 5, // Shadow depth
                                        ),
                                      child: const Row(
                                        spacing: 8,
                                        children: [
                                          Icon(PhosphorIconsRegular.x, color: Colors.red,),
                                          Text('Incorrect', style: TextStyle(color: Colors.red)),
                                        ],
                                      )
                                    ),  
                                  ]
                              )
                            ],
                          ),
                        ]
                      )
                      )
                    ],
                  )

              
            ),
              sizedBox(16),
              
              Container( 
                decoration: BoxDecoration(
                  // color: Theme.of(context).shadowColor,
                //   gradient: LinearGradient(
                //   colors: [Color(0xFFFFEDE6), Color(0xFFFFEAE2), Color(0xFFFDE7DE), Color(0xFFFFEDE6)],
                //   // colors: [Color(0xFFF36C31), Color(0xFFF36C31), Color(0xFFFF8B59)],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomCenter,
                // ),
                // boxShadow: [
                //   BoxShadow(
                //     color: Color(0xFFFFCCB6), // Shadow color
                //     // color: Colors.black12, // Shadow color
                //     spreadRadius: 3, // How much the shadow spreads
                //     blurRadius: 60, // How blurred the shadow is
                //     offset: Offset(0, 10), // Offset in x, y direction
                //   ),
                // ],

                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(
                            color: const Color.fromARGB(255, 214, 227, 224), // Set the color of the border here
                            width: 1, // Set the width of the border here
                          ),
                  boxShadow: const [
                    BoxShadow(
                      // color: Colors.black12,
                      color: Color.fromARGB(255, 214, 247, 239),
                      offset: Offset(0.0, 0.0),
                      blurRadius: 24.0,
                      spreadRadius: 0.3,
                    ),
                  ]
                ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child:  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      
                                // Text('Total Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   crossAxisAlignment: CrossAxisAlignment.center,
                                //   children: [
                                    
                                //     Text('Total Outstanding', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                                //     // Text('Total Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                //     refreshCheckProgress ? AppProgress(height: 24, width: 24) : IconButton(onPressed: ()=>{refreshUserHomeDealer1(context)}, icon: Icon(PhosphorIconsBold.arrowClockwise, ))
                                //   ],
                                // ),
                     
                              sizedBox(8),
                                Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // sizedBox(24),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                            Text('Your Total Outstanding'.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: Colors.black54), ),
                                            // IconButton(
                                            //     icon: Icon(_isHidden ? Icons.visibility_off : Icons.visibility),
                                            //     onPressed: () {
                                            //       setState(() {
                                            //         _isHidden = !_isHidden;
                                            //       });
                                            //     },
                                            //     tooltip: _isHidden ? 'Show Amounts' : 'Hide Amounts',
                                            //   ),
                                              
                                            ]
                                        ),
                                        
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                              RichText(
                                              text: TextSpan(
                                                text: 
                                                // _isHidden ? _getDots(NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL+totalOutstandingVCL)) : 
                                                '₹ ${NumberFormat("#,##,##0", "en_IN").format(totalOutstandingATL+totalOutstandingVCL)}',
                                                style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 30, letterSpacing: 0.5, fontWeight: FontWeight.bold, color: Colors.black),
                                                // style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 30, letterSpacing: 0.5, fontWeight: FontWeight.bold, color: Colors.black),
                                                children: <TextSpan>[
                                                TextSpan(
                                                  text: 
                                                  // _isHidden ? _getDots(NumberFormat("#,##,##0.00", "en_IN").format((totalOutstandingATL+totalOutstandingVCL) % 1 * 100)) : 
                                                  '.${NumberFormat("00", "en_IN").format((totalOutstandingATL+totalOutstandingVCL) % 1 * 100)}',
                                                  style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 0.5, fontWeight: FontWeight.w500, color: Colors.black),
                                                  // style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 0.5, fontWeight: FontWeight.w500, color: Colors.black),
                                                ),
                                                ],
                                              ),
                                              ),
                                              refreshCheckProgress ? const AppProgress(height: 24, width: 24) : IconButton(onPressed: ()=>{refreshUserHomeDealer1(context)}, icon: const Icon(PhosphorIconsBold.arrowClockwise, ), iconSize: 16, color:  const Color(0xFF008060),)
                                          ]
                                        )
                                        // sizedBox(8),
                                      ],
                                    ),

                                    
                                (totalOutstandingATL > 0 || totalOutstandingVCL > 0) ?
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('DUE', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                                    // sizedBox(16),
                                    // (daysLeft > 0) ?
                                    // Row(
                                    //   crossAxisAlignment: CrossAxisAlignment.center,
                                    //   mainAxisAlignment: MainAxisAlignment.center,
                                    //   spacing: 4,
                                    //   children: [
                                    //     Text('$daysLeft', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                                    //     Text('days left' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, fontWeight: FontWeight.bold)),
                                    //     Text(' Due on: ${nearestDueDate}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black87)),
                                    //   ],
                                    // ) : Text('Due date exceeded', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                                    // sizedBox(4),
                                    // LinearProgressIndicator(value: 1-(daysLeft/45).toDouble(), color: Colors.red, backgroundColor: Colors.red.shade100, minHeight: 4,borderRadius: const BorderRadius.all(Radius.circular(4))),
                                  ],
                                )
                                : sizedBox(0),
                                sizedBox(24),
                                // Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                

                                // Text('ATL' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium,  fontWeight: FontWeight.bold)),
                                // Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                // sizedBox(16),
                                
                                // Text('VCL' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium,  fontWeight: FontWeight.bold)),
                                // Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFFC41306))),
                                // sizedBox(16),
                                
                                // (totalOutstandingATL > 0 || totalOutstandingVCL > 0) ?
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   children: [
                                //   Column(
                                //     crossAxisAlignment: CrossAxisAlignment.start,
                                //     children: [
                                //     Text('ATL', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.bold,color: Colors.redAccent)),
                                //     Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                                //     ],
                                //   ),
                                //   Column(
                                //     crossAxisAlignment: CrossAxisAlignment.end,
                                //     children: [
                                //     Text('VCL', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.bold, color: Color(0xFFC41306))),
                                //     Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                                //     ],
                                //   ),
                                //   ],
                                // ) : sizedBox(0),

                                (totalOutstandingATL > 0 || totalOutstandingVCL > 0) ?
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Text('ATL', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black54)),
                                    Text(
                                      // _isHidden ? _getDots(NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)) : 
                                    '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                    Text('VCL', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black54)),
                                    Text(
                                      // _isHidden ? _getDots(NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)) : 
                                      '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    ],
                                  ),
                                  ],
                                ) : sizedBox(0),
                                
                                
                                
                                
                                // Text(Dealer name, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.bold)),
                                
                                
                                // (totalOutstandingATL > 0 || totalOutstandingVCL > 0) ?
                                // Column(
                                //   crossAxisAlignment: CrossAxisAlignment.start,
                                //   children: [
                                //     // Text('Due date: ${dueDateATL}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                                //     // sizedBox(8),    
                                //     // Text('UNPAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                                //     // sizedBox(16),
                                //     (daysLeft > 0) ?
                                //     Row(
                                //       crossAxisAlignment: CrossAxisAlignment.center,
                                //       spacing: 4,
                                //       children: [
                                //         Text('$daysLeft', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                                //         Text('days left' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, fontWeight: FontWeight.bold)),
                                //         Text('Due on: ${nearestDueDate}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black87)),
                                //       ],
                                //     ) : Text('Due date exceeded', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                                //     sizedBox(4),
                                //     LinearProgressIndicator(value: 1-(daysLeft/45).toDouble(), color: Colors.red, backgroundColor: Colors.black12, minHeight: 6,borderRadius: BorderRadius.all(Radius.circular(4)),),
                                //     // sizedBox(8),
                                //     // Text('Due on: ${nearestDueDate}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                //   ],
                                // )
                                // : sizedBox(0),

                                // sizedBox(16),

                                //  Column(
                                //   crossAxisAlignment: CrossAxisAlignment.center,
                                //   mainAxisSize: MainAxisSize.max,
                                //   children: [
                                //     // Text('PAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF008060), letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                                //     Text('Credit balance', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, fontSize: 14,fontWeight: FontWeight.w500)),
                                //     // sizedBox(4),
                                //     Container(
                                //       // decoration: BoxDecoration(
                                //       //   color: Color.fromARGB(255, 123, 206, 185),
                                //       //   borderRadius: const BorderRadius.all(Radius.circular(24)),
                                //       //   border: Border.all(
                                //       //             color: Colors.black12, // Set the color of the border here
                                //       //             width: 1, // Set the width of the border here
                                //       //           ),
                                //       //   boxShadow: const [
                                //       //     BoxShadow(
                                //       //       color: Colors.black12,
                                //       //       offset: Offset(0.0, 0.0),
                                //       //       blurRadius: 24.0,
                                //       //       spreadRadius: 0.3,
                                //       //     ),
                                //       //   ]
                                //       // ),
                                //       padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                                //       child: Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(creditOutstanding)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFF008060))),
                                //     ),
                                //     sizedBox(4),
                                //   ],
                                //  ),
                                
                                // LinearProgressIndicator(value: 0.3, color: Colors.red, backgroundColor: Colors.black12, minHeight: 8,borderRadius: BorderRadius.all(Radius.circular(4)),),

                      // sizedBox(12),
                      // DottedLine(),
                      // sizedBox(12),
                      // sizedBox(8),
                      // divider(Colors.black12),
                      // sizedBox(8),
                      // InkWell(
                      //   onTap: () {
                      //      Navigator.push(context, MaterialPageRoute(builder: (context) => InvoicesDealer()));
                      //   },
                      //   child: 
                      //       Text("INVOICES –>", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                      // ),
sizedBox(12),
                      DottedLine(),
sizedBox(12),
Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  spacing: 4,
                  children: [
                    // Text('PAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF008060), letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                    Text('Credit balance: '.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black54)),
                    // Text('Credit balance: ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, fontSize: 14, letterSpacing: 1.5,fontWeight: FontWeight.w500)),
                    // sizedBox(4),
                    Text(
                      // _isHidden ? _getDots(NumberFormat("#,##,##0.00", "en_IN").format(creditOutstanding)) : 
                    '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(creditOutstanding)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.bold, color: const Color(0xFF008060))),
                    
                  ],
                  ),
sizedBox(12),
                      DottedLine(),
// sizedBox(12),

                      // (totalOutstandingATL > 0 || totalOutstandingVCL > 0) ?
                      //           Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: [
                      //               // Text('Due date: ${dueDateATL}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                      //               // sizedBox(8),    
                      //               // Text('UNPAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                      //               // sizedBox(16),
                      //               (daysLeft > 0) ?
                      //               Row(
                      //                 crossAxisAlignment: CrossAxisAlignment.center,
                      //                 spacing: 4,
                      //                 children: [
                      //                   Text('$daysLeft', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                      //                   Text('days left' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, fontWeight: FontWeight.bold)),
                      //                   Text('Due on: ${nearestDueDate}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black87)),
                      //                 ],
                      //               ) : Text('Due date exceeded', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                      //               sizedBox(4),
                      //               LinearProgressIndicator(value: 1-(daysLeft/45).toDouble(), color: Colors.red, backgroundColor: Colors.red.shade100, minHeight: 4,borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))),
                      //               // sizedBox(8),
                      //               // Text('Due on: ${nearestDueDate}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                      //             ],
                      //           )
                      //           : sizedBox(0),
                      sizedBox(8),


                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF008060), // Dark background color
                                    // backgroundColor: Color(0xFF0C4EF5), // Dark background color
                                    
                                    textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                    padding: const EdgeInsets.fromLTRB(16,4,16,4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 5, // Shadow depth
                                  ),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => InvoicesDealer()));
                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                                  },
                                  child: const Text('View Invoices', style: TextStyle(color: Colors.white)),
                                ),
                                
                                
                      sizedBox(8),
                      
                      // // sizedBox(8),
                      // (role == Constants.dealer) ? Text('Address:', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall))
                      //   : sizedBox(0),
                      
                      // (role == Constants.dealer) ? 
                      //   Column(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       (address1 != '-') ? Text('$address1 ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                            
                      //       (address2 != '-') ? Text('$address2 ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                            
                      //       (address3 != '-') ? Text('$address3 ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                      //     ],
                      //   ) 
                      //   : sizedBox(0),
                      
                      // sizedBox(8),
                      


                      ]),
              ),

              // sizedBox(8),
              //  MaterialButton(
              //     child: Text('Update profile'),
              //     padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              //     color: Palette.blue,
              //     textColor: Palette.lightBackground,
              //     splashColor: Color(0xFF008060),
              //     // colorBrightness: Brightness.light,
              //     elevation: 0,
              //     highlightElevation: 2,
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              //     onPressed: () => updateHomeDealer1(context),
              //   ),
              


                                 
              // sizedBox(8),
              // Container(
              //   decoration: BoxDecoration(
              //     // color: Color.fromARGB(255, 164, 218, 205),
              //     borderRadius: const BorderRadius.all(Radius.circular(24)),
              //     boxShadow: const [
              //       BoxShadow(
              //         color: Colors.black12,
              //         offset: Offset(0.0, 0.0),
              //         blurRadius: 24.0,
              //         spreadRadius: 0.3,
              //       ),
              //     ]
              //   ),
              //   padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              //   child:  
              
              // Row(
              //     crossAxisAlignment: CrossAxisAlignment.center,
              //     mainAxisSize: MainAxisSize.max,
              //     spacing: 4,
              //     children: [
              //       // Text('PAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF008060), letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
              //       Text('Credit balance: ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, fontSize: 14,fontWeight: FontWeight.w500)),
              //       // sizedBox(4),
              //       Text('₹ 99,99,999', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.bold, color: Color(0xFF008060))),
              //       // Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(creditOutstanding)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.bold, color: Color(0xFF008060))),
                    
              //     ],
              //     ),
              // ),
              sizedBox(16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(
                    color: Colors.black12,
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, 0.0),
                      blurRadius: 24.0,
                      spreadRadius: 0.3,
                    ),
                  ],
                ),
                
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Row(
                        children: [
                        // Container(
                        //   padding: const EdgeInsets.all(10),
                        //   decoration: BoxDecoration(
                        //   color: Color(0xFFE8F5E9),
                        //   borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Icon(PhosphorIconsRegular.target, color: Color(0xFF008060), size: 24),
                        // ),
                        Image.asset('assets/targets.webp',width: 60.0),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text('Monthly Targets', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                          ],
                        ),
                        ],
                      ),
                      targetsDataProgress ? const AppProgress(height: 24, width: 24) : 
                      

                        IconButton(onPressed: ()=>{getTargetsData(context)}, icon: const Icon(PhosphorIconsBold.arrowClockwise, ), iconSize: 16, color:  const Color(0xFF008060),)
                      ],
                    ),
                    sizedBox(24),

                    

                    targetsDataList.isEmpty
                      ? Center(
                        child: Text('No targets available', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                        )
                      : Column(
                        children: targetsDataList.map((target) {
                          String categoryName = '';
                          if (target.categoryId == 1) {
                          categoryName = 'VCL';
                          } else if (target.categoryId == 2) {
                          categoryName = 'ATL';
                          } else if (target.categoryId == 3) {
                          categoryName = 'Collections';
                          } else {
                          categoryName = target.name ?? 'Unknown';
                          }
                          
                          double achieved = double.tryParse(target.actualAmount ?? '0') ?? 0;
                          double targetAmount = double.tryParse(target.targetAmount ?? '1') ?? 1;
                          double progress = achieved / targetAmount;
                          
                          return Column(
                          children: [
                            buildTargetItem(
                              context,
                              categoryName,
                              achieved,
                              targetAmount > 0 ? targetAmount : 'To be decided',
                              // (currentMonthTargetDate == 'To be decided') ? 'To be decided' : targetAmount,
                              progress < 0.5 ? Colors.red : const Color(0xFF008060),
                            ),
                            
                            sizedBox(16),
                          ],
                          );
                        }).toList(),
                      ),

                      DottedLine(),
                      sizedBox(16),
                      // CTA to open another screen with detailed breakdown of targets, progress, and tips to achieve targets
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008060), // Dark background color
                          // backgroundColor: Color(0xFF0C4EF5), // Dark background color
                          
                          textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                          padding: const EdgeInsets.fromLTRB(16,4,16,4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 5, // Shadow depth
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TargetsDealer(id)));
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                        },
                        child: const Text('View Report', style: TextStyle(color: Colors.white)),
                      ),
                      
                  ],
                ),
              ),


              sizedBox(16),
              InkWell(
                onTap: () => {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentsDealer()))
                },
                child: 
                Container(
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
                    ]
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    children: [
 
                      // Container(
                      //   decoration: const BoxDecoration(
                      //     color: Color(0xFF008060),
                      //     // color: Color(0xFFFFA135),
                      //     borderRadius: BorderRadius.all(Radius.circular(24)),
                      //   ),
                      //   padding: const EdgeInsets.all(8),
                      //   child:  
                      //   Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //         crossAxisAlignment: CrossAxisAlignment.center,
                      //         children: [
                      //           sizedBox(4),
                      //           const Icon(PhosphorIconsRegular.moneyWavy, color: Colors.white, size: 28,),
                      //           // const Icon(PhosphorIconsRegular.currencyInr, color: Colors.white, size: 28,),
                      //           // const Icon(PhosphorIconsRegular.receipt, color: Colors.white, size: 28,),
                      //           // const SizedBox(width:8),
                      //           // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                      //       ],
                      //     ),
                      // ),
                      const SizedBox(width: 16,),
                      Expanded(child: 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Image.asset('assets/payments.webp',width: 80.0),
                          Text('Your Payments', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.bold)),
                          // sizedBox(8),
                          Text('Track payments, Raise payment requests', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
                        ]
                      )
                      )
                    ],
                  )
                )
               ),


              sizedBox(16),
              // Container(
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
              //       ),
              //       padding: const EdgeInsets.all(16),
              //       child: 
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceAround,
              //             crossAxisAlignment: CrossAxisAlignment.center,
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
              // sizedBox(16),
              InkWell(
                      onTap: () async {
                                      // Action to perform when the button is pressed
                                      String telephoneUrl = "tel:${mapMobile}";
                                        await launchUrlString(telephoneUrl);
                                    },
                child: 
                  Container(
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
                      ]
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      
                      children: [
                        Image.asset('assets/salesperson.webp',width: 90.0), sizedBox(4),
                        Text('Your Sales person', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                        // sizedBox(4),
                        // Text('Reach out for assistance.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                        sizedBox(8),
                        
                        Text(mapName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF048563))),
                        sizedBox(4),
                        Text('Reach out for assistance.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
                        sizedBox(16),
                        DottedLine(),
                        sizedBox(16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          spacing: 16,
                          children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // Action to perform when the button is pressed
                                  String telephoneUrl = "tel:${mapMobile}";
                                    await launchUrlString(telephoneUrl);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF048563),
                                  foregroundColor: const Color(0xFFFFFFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6.0,
                                  children: [
                                    const Icon(PhosphorIconsRegular.phone, color: Colors.white, size: 20,),
                                    Text('Call now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                )
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsDealer2()));
                              },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF61C454),
                                  foregroundColor: const Color(0xFFFFFFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6.0,
                                  children: [
                                    const Icon(PhosphorIconsRegular.chatsTeardrop, color: Colors.white, size: 20,),
                                    Text('Chat now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                )
                              ),
                          ],
                        )
                      ],
                    )
                  ),
              ),    
              
              
              // sizedBox(16),
              
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
                  // Text('Browse Designs', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                  
                  // sizedBox(16),

                  // InkWell(
                  //     onTap: () {
                  //       Navigator.push(context, MaterialPageRoute(builder: (context) => ProductCollections()));
                  //     },
                  //   child: 
                  //   Container(
                  //     // height: 200,
                  //     width: MediaQuery.of(context).size.width-32,
                  //     // padding: const EdgeInsets.all(20),
                  //     decoration: BoxDecoration(
                  //       border: Border.all(color: Colors.white, width: 1),
                  //       borderRadius: BorderRadius.circular(24),
                  //       gradient: LinearGradient(
                  //         colors: [Colors.amber.shade400, Colors.green.shade800],
                  //         begin: Alignment.topLeft,
                  //         end: Alignment.bottomRight,
                  //       ),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.white, // Shadow color
                  //           // color: Colors.black12, // Shadow color
                  //           spreadRadius: 5, // How much the shadow spreads
                  //           blurRadius: 10, // How blurred the shadow is
                  //           offset: Offset(0, 10), // Offset in x, y direction
                  //         ),
                  //       ],
                  //     ),
                  //     child: ClipRRect(
                  //       borderRadius: BorderRadius.circular(24),
                  //       child: BackdropFilter(
                  //         filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  //         child: 
                  //         Container(
                  //           padding: const EdgeInsets.all(24),
                  //           color: Colors.white.withOpacity(0.1), // Translucent effect
                  //           child: Column(
                  //             children: [
                  //               Container(
                  //                 width: 250,
                  //                 // color: Colors.blue,
                  //                 child: Stack(
                  //                   children: [
                  //                     Transform.rotate(
                  //                       angle: -0.4,
                  //                       child: Container(
                  //                               width: 100.0, // Adjust the size as needed
                  //                               height: 100.0, // Adjust the size as needed
                  //                               decoration: BoxDecoration(
                  //                                 color: Colors.white,
                  //                                 image: const DecorationImage(
                  //                                   image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F81001.jpeg?alt=media'),
                  //                                   fit: BoxFit.cover,
                  //                                 ),
                  //                                 borderRadius: BorderRadius.circular(16),
                  //                                 boxShadow: [
                  //                                   BoxShadow(
                  //                                     color: Colors.black12, // Shadow color
                  //                                     spreadRadius: 5, // How much the shadow spreads
                  //                                     blurRadius: 20, // How blurred the shadow is
                  //                                     offset: const Offset(0, 10), // Offset in x, y direction
                  //                                   ),
                  //                                 ],
                  //                               ),
                  //                             ),
                  //                         ),

                  //                         Positioned(top: 0, left: 60, right: 60,
                  //                         child: Transform.rotate(
                  //                                 angle: -0.3,
                  //                                 child: Container(
                  //                                         width: 100.0, // Adjust the size as needed
                  //                                         height: 100.0, // Adjust the size as needed
                  //                                         decoration: BoxDecoration(
                  //                                           color: Colors.white,
                  //                                           image: const DecorationImage(
                                                              
                  //                                             image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F6874.jpeg?alt=media'),
                  //                                             fit: BoxFit.cover,
                  //                                           ),
                  //                                           borderRadius: BorderRadius.circular(16),
                  //                                           boxShadow: [
                  //                                             BoxShadow(
                  //                                               color: Colors.black12, // Shadow color
                  //                                               spreadRadius: 5, // How much the shadow spreads
                  //                                               blurRadius: 20, // How blurred the shadow is
                  //                                               offset: const Offset(0, 10), // Offset in x, y direction
                  //                                             ),
                  //                                           ],
                  //                                         ),
                  //                                       ),
                  //                                   ),
                  //                         ),
                  //                         Positioned(top: 0, right: 0,
                  //                         child: Transform.rotate(
                  //                                 angle: 0.1,
                  //                                 child: Container(
                  //                                         width: 100.0, // Adjust the size as needed
                  //                                         height: 100.0, // Adjust the size as needed
                  //                                         decoration: BoxDecoration(
                  //                                           color: Colors.white,
                  //                                           image: const DecorationImage(
                  //                                             image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F21033.jpeg?alt=media'),
                  //                                             // image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F51010.jpeg?alt=media'),
                  //                                             fit: BoxFit.cover,
                  //                                           ),
                  //                                           borderRadius: BorderRadius.circular(16),
                  //                                           boxShadow: [
                  //                                             BoxShadow(
                  //                                               color: Colors.black12, // Shadow color
                  //                                               spreadRadius: 5, // How much the shadow spreads
                  //                                               blurRadius: 20, // How blurred the shadow is
                  //                                               offset: const Offset(0, 10), // Offset in x, y direction
                  //                                             ),
                  //                                           ],
                  //                                         ),
                  //                                       ),
                  //                                   ),
                  //                         ),
                  //                   ],
                  //                 ),
                  //               ),
                                    
                                
                  //               sizedBox(48),
                  //               ElevatedButton(
                  //                 style: ElevatedButton.styleFrom(
                  //                   backgroundColor: Color(0xFFFFFFFF), // Dark background color
                                    
                  //                   textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                  //                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  //                   shape: RoundedRectangleBorder(
                  //                     borderRadius: BorderRadius.circular(24),
                  //                   ),
                  //                   elevation: 5, // Shadow depth
                  //                 ),
                  //                 onPressed: () {
                  //                   Navigator.push(context, MaterialPageRoute(builder: (context) => ProductCollections()));
                  //                   // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                  //                 },
                  //                 child: Text('Browse Designs', style: TextStyle(color: Colors.black)),
                  //               ),
                                
                  //             ],
                  //           )
                            
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // sizedBox(16),

              //     (refreshCheckProgress && showCatalogues.length == 0) ? 
              //     Center(
              //       child: Column(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
              //           // sizedBox(8),
              //           refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
              //           Text('Loading catagolues!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                        
              //         ],
              //       )
              //     )
              //     : 
              //     GridView.builder(
              //       shrinkWrap: true,
              //       physics: NeverScrollableScrollPhysics(),
              //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              //         crossAxisCount: 2,
              //         crossAxisSpacing: 16,
              //         mainAxisSpacing: 16,
              //         childAspectRatio: 0.75,
              //       ),
              //       itemCount: showCatalogues.length,
              //       itemBuilder: (context, index) {
              //         return productCard(index);
              //       },
              //     ),
              //   ]
              // ),
                  
                  sizedBox(16),
                  
                  
              InkWell(
                onTap: () => {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ShowRooms()))
                },
                child: 
                Container(
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
                    ]
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    
                    children: [
Image.asset('assets/showrooms.webp',width: 80.0),
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
                      Text('Our Showrooms', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                      sizedBox(8),
                      Text('Walk in to experience our designs.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                      // Text('Walk in to get connected.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                      sizedBox(4),
                    ],
                  )
                )
               ),
               sizedBox(16),


              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: const BorderRadius.all(Radius.circular(24)),
              //     border: Border.all(
              //               color: Colors.black12, // Set the color of the border here
              //               width: 1, // Set the width of the border here
              //             ),
              //     boxShadow: const [
              //       BoxShadow(
              //         color: Colors.black12,
              //         offset: Offset(0.0, 0.0),
              //         blurRadius: 24.0,
              //         spreadRadius: 0.3,
              //       ),
              //     ]
              //   ),
              //   padding: const EdgeInsets.all(16),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
                  
              //     children: [

              //       Container(
              //         decoration: const BoxDecoration(
              //           color: Color(0xFFE5E5E5),
              //           borderRadius: BorderRadius.all(Radius.circular(24)),
              //         ),
              //         padding: const EdgeInsets.all(10),
              //         child:  Row(
              //           mainAxisSize: MainAxisSize.min,
              //               crossAxisAlignment: CrossAxisAlignment.center,
              //               children: [
              //                 const Icon(PhosphorIconsRegular.listMagnifyingGlass, color: Colors.black54, size: 28,),
              //                 // const SizedBox(width:8),
              //                 // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
              //             ],
              //           ),
              //       ),
              //       sizedBox(16),
              //       Text('Products', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
              //       sizedBox(4),
              //       Text('Coming soon', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 12, fontWeight: FontWeight.w400)),
              //     ],
              //   )
              // ),
              
            ],
          
          ),

          sizedBox(16),
         
            
          sizedBox(8),
              
          // Container(
          //   margin: EdgeInsets.fromLTRB(24, 0, 8, 8),
          //   child: 
          //   Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: <Widget>[
          //       Row(
          //         children: <Widget>[
          //           Icon(Icons.refresh, color:Palette.green,),
          //           MaterialButton(
          //               child: Text('REFRESH PROFILE'),
                            
                            
          //                   splashColor: Palette.accent,
          //                   colorBrightness: Brightness.dark,
          //                   textColor: Palette.green,
          //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            
          //                   onPressed: () => 
          //                     refreshHomeDealer1(context),
                            
          //             ),

          //         ],
          //       ),

          //       (updateMsg.length > 0) ? Text(updateMsg, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText2)) : sizedBox(0),
          //     ],
          //   ),
            
          // ),

          // Container(
          //   margin: const EdgeInsets.fromLTRB(24, 0, 8, 16),
          //   child: 
          //   Row(
          //     children: <Widget>[
          //       Icon(Icons.remove_circle_outline, color:Palette.red,),
          //       MaterialButton(
          //       child: const Text('SIGN OUT'),
                    
                    
          //           splashColor: Palette.red,
          //           colorBrightness: Brightness.dark,
          //           textColor: Palette.red,
          //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    
          //           onPressed: () => 
          //             // sign out user
          //             signOutUser(),
                    
          //     ),

          //     ],
          //   ),
            
            
          // ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            

            child: Column(
              children: <Widget>[
                sizedBox(8),
                //  Row(
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                // crossAxisAlignment: CrossAxisAlignment.center,
                // children: <Widget>[
                  
                //   Text('Version ${Platform.isAndroid ? Constants.sc_app_version : Constants.sc_app_version_ios}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall)),
                // ],
              // ),
              // sizedBox(8),
              // InkWell(
              //   onTap: () => {_showModalBottomSheet(context, Constants.disclaimer)},
              //   child: 
              //   Text('Disclaimer', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall)),
              // ),
              // sizedBox(16),
              // Text('Created for your campus with love and care!'.toUpperCase(), style: GoogleFonts.passionOne(textStyle: Theme.of(context).textTheme.displayMedium, color: Colors.black54)),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[ 
                  Text('Anjani Tek', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.titleMedium, fontSize: 12, color: Colors.black54, )),
              ]),
              sizedBox(48),
              sizedBox(48),
              ],
            )
              
          )


        
        ],
      )
      ),
      )
    ),)
    )
    )
    );
  }

  // Refresh profile
  // refreshHomeDealer1(BuildContext context) async {

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


Widget productCard(int position){

    return GestureDetector(
      onTap: () async {
        try{

          // Load from URL
          //PDFDocument doc = await PDFDocument.fromURL('https://www.ecma-international.org/wp-content/uploads/ECMA-262_12th_edition_june_2021.pdf');

          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage1(showCatalogues[position].name! , showCatalogues[position].documentUrl!)));

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
          }
          catch(e){
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
                  ]
                ),
                
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  image: DecorationImage(
                    image: NetworkImage(showCatalogues[position].imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8,16,16,16),
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
                        child:  const Row(
                          mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(PhosphorIconsRegular.book, color: Colors.black, size: 24,),
                                // const SizedBox(width:8),
                                // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                            ],
                          ),
                      ),
                      const SizedBox(width: 8,),
                      Expanded(child: 
                  Text(showCatalogues[position].name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
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
Map<String, bool> imageExistenceCache = {}; // A cache to store image existence results


