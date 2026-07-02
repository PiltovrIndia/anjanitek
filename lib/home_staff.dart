import 'dart:convert';
import 'dart:ui';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/modals/confirmations.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/modals/payment_only.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/target.dart';
import 'package:anjanitek/no_login_experience2.dart';
import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/profile.dart';
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
// import 'package:anjanitek/profile_update.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
// import 'package:anjanitek/util/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';


// this is 
class HomeStaff extends StatefulWidget {
  @override
  _HomeStaffState createState() => _HomeStaffState();
}

class _HomeStaffState extends State<HomeStaff> with TickerProviderStateMixin {

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
  bool _isHidden = true;
  
  int daysLeft = 0;
  bool connectionStatus = true;

  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");
  List<Catalogue> showCatalogues = [];
  List<Target> targetsDataList = [];
  
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
        refreshUserHomeStaff(context);
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

    void refreshUserHomeStaff(BuildContext context) async {

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
          refreshUserHomeStaff(context);
          
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
        // print("${APIUrls.targets}${APIUrls.pass}/${DateTime.now().year}-${DateTime.now().month}-01/$id");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.targets}${APIUrls.pass}/T1/${DateTime.now().year}-${DateTime.now().month}-01/$id", {})), headers: {"Accept": "application/json"});
        
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['success']){
        
            // get the user data from jsonObject
            var targetsData = jsonObject['data'] as List;
            var targets = targetsData[0]['targets'] as List;

            // print(targetsData);
            // print(targets);

            setState(() {
              
              targetsDataList = targets.map<Target>((json) => Target.fromJson(json)).toList();
              
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

Widget _buildTargetItem(BuildContext context, String title, double achieved, double target, Color color) {
  double progress = achieved / target;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 8,
            children: [
              Text(title, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w500, color: Colors.black87)),
              Text('${NumberFormat("#,##,##0", "en_IN").format(achieved)} (${(progress * 100).toStringAsFixed(1)}%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black)),
            ],
          ),
          // Text(title + ' ${NumberFormat("#,##,##0", "en_IN").format(achieved)} (${(progress * 100).toStringAsFixed(1)}%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w500)),
          Text('Target: ₹ ${NumberFormat("#,##,##0", "en_IN").format(target)}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
          // Text('${NumberFormat("#,##,##0", "en_IN").format(achieved)} (${(progress * 100).toStringAsFixed(1)}%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: progress > 1 ? 1 : progress,
        color: color,
        backgroundColor: color.withOpacity(0.2),
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
      // SizedBox(height: 4),
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     Text(' ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
      //     Text('Target: ₹ ${NumberFormat("#,##,##0", "en_IN").format(target)}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
      //   ],
      // ),
    ],
  );
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
              
              sizedBox(24),
              Image.asset('assets/anjani_title1.webp', scale: 2,), 
              sizedBox(24),
              Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
              sizedBox(16),
              
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
              
            ],
          
          ),

          sizedBox(16),

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
  // refreshHomeStaff(BuildContext context) async {

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



class Catalogue {
  int? id;
  String? name;
  String? imageUrl;
  String? documentUrl;
  int? type;

  Catalogue({this.id, this.name, this.imageUrl, this.documentUrl, this.type});

  Catalogue.fromJson(Map<String, dynamic> json): 
  id = json['id'], 
  name = json['name'], 
  imageUrl = json['imageUrl'], 
  documentUrl = json['documentUrl'], 
  type = json['type'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id']= id;
    data['name']= name;
    data['imageUrl']= imageUrl;
    data['documentUrl']= documentUrl;
    data['type']= type;
    return data;
  }
}
