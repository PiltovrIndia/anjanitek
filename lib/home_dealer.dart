import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/invoices_dealer.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/notifications_dealer.dart';
import 'package:anjanitek/notifications_dealer2.dart';
import 'package:anjanitek/payments_dealer.dart';
import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/profile.dart';
import 'package:anjanitek/showrooms.dart';
import 'package:anjanitek/utils/app_header.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:anjanitek/database_internal.dart';
import 'package:anjanitek/modals/users.dart';
// import 'package:anjanitek/profile_update.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/divider.dart';
// import 'package:anjanitek/util/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';
import 'package:anjanitek/verify.dart';
import 'package:http/http.dart' as http;
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
  static String name = '',mapName='',mapMobile='',
  mobile='', email = '-', role = '-', id='', userImage='',gcm_regId='',
  accountName='',dealerId='',salesId='',city='',state='',gst='',address1='',address2='',address3='';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  bool catalogueCheckProgress = false;
  late List<Invoices> invoicesList = [];
  bool anyOutstanding = true;
  double totalOutstandingATL = 0;
  double totalOutstandingVCL = 0;

  String dueDateATL = '';
  String dueDateVCL = '';
  String nearestDueDate = '-';
  
  int daysLeft = 0;
  bool connectionStatus = true;

  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");
  List<Catalogue> showCatalogues = [];
  
  // user object
  Invoices? invoices ;
  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  late SharedPreferences prefs;


  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
      
      // get reference to internal database
      getUsers();

      _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 1000),);
    _controller.forward();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
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
          decoration: BoxDecoration(
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

      otpFocusNode.dispose(); // Dispose of the FocusNode
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
        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
          name = prefs.get(Constants.name) as String;
          id = prefs.get(Constants.id) as String;
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

        refreshUserHomeDealer(context);
        getCatalogues(context);

    }



    // find the user
    void refreshUserHomeDealer(BuildContext context) async {

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
            // Map<String, dynamic> invoicesData = jsonObject['data'];

            if(invoicesData.isNotEmpty){
              // convert to list
              invoicesList = invoicesData.map<Invoices>((json) => Invoices.fromJson(json)).toList();
              
              setState(() {
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
              }
            );

          }
          else {
            setState(() {
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
          refreshUserHomeDealer(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
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
              child:
      SafeArea(

        child: SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              Text('Home', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
              sizedBox(16),
              Container( 
                decoration: BoxDecoration(
                  // color: Theme.of(context).shadowColor,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                  child:  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      
                                // Text('Total Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    
                                    Text('Total Outstanding', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                                    // Text('Total Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                    refreshCheckProgress ? AppProgress(height: 24, width: 24) : IconButton(onPressed: ()=>{refreshUserHomeDealer(context)}, icon: Icon(PhosphorIconsBold.arrowClockwise, ))
                                  ],
                                ),
                                // sizedBox(16),
                                // Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                

                                Text('ATL' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium,  fontWeight: FontWeight.bold)),
                                Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                sizedBox(16),
                                Text('VCL' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium,  fontWeight: FontWeight.bold)),
                                Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFFC41306))),
                                sizedBox(16),
                                
                                
                                
                                // Text(Dealer name, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.bold)),
                                
                                
                                (totalOutstandingATL > 0 || totalOutstandingVCL > 0) ?
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text('Due date: ${dueDateATL}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                                    // sizedBox(8),    
                                    // Text('UNPAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                                    // sizedBox(16),
                                    (daysLeft > 0) ?
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('$daysLeft', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Text('days left' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ) : Text('Due date exceeded', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                                    sizedBox(4),
                                    LinearProgressIndicator(value: 1-(daysLeft/45).toDouble(), color: Colors.red, backgroundColor: Colors.black12, minHeight: 8,borderRadius: BorderRadius.all(Radius.circular(4)),),
                                    sizedBox(8),
                                    Text('Due date: ${nearestDueDate}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                                  ],
                                )
                                 : 
                                 Column(
                                  children: [
                                    Text('PAID', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF008060), letterSpacing: 1, fontSize: 14,fontWeight: FontWeight.bold)),
                                  ],
                                 ),
                                
                                // LinearProgressIndicator(value: 0.3, color: Colors.red, backgroundColor: Colors.black12, minHeight: 8,borderRadius: BorderRadius.all(Radius.circular(4)),),

                      sizedBox(12),
                      DottedLine(),
                      sizedBox(12),
                      // sizedBox(8),
                      // divider(Colors.black12),
                      // sizedBox(8),
                      InkWell(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => InvoicesDealer()));
                        },
                        child: 
                            Text("INVOICES –>", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                      ),
                      // sizedBox(8),
                      
                      // sizedBox(8),
                      
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
              //     onPressed: () => updateHomeDealer(context),
              //   ),
              


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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    children: [

                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFA135),
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.all(10),
                        child:  Row(
                          mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(PhosphorIconsRegular.receipt, color: Colors.white, size: 28,),
                                // const SizedBox(width:8),
                                // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                            ],
                          ),
                      ),
                      sizedBox(16),
                      Text('Your payments', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                      sizedBox(8),
                      Text('View your payments here.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                      sizedBox(4),
                    ],
                  )
                )
               ),


              sizedBox(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                        Text('Your Sales person', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                        // sizedBox(4),
                        // Text('Reach out for assistance.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                        sizedBox(8),
                        
                        Text(mapName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF048563))),
                        sizedBox(4),
                        Text('Reach out for assistance.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                        sizedBox(16),
                        DottedLine(),
                        sizedBox(16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // Action to perform when the button is pressed
                                  String telephoneUrl = "tel:${mapMobile}";
                                    await launchUrlString(telephoneUrl);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF048563),
                                  foregroundColor: Color(0xFFFFFFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6.0,
                                  children: [
                                    Icon(PhosphorIconsRegular.phone, color: Colors.white, size: 20,),
                                    Text('Call now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                )
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsDealer2()));
                              },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF61C454),
                                  foregroundColor: Color(0xFFFFFFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6.0,
                                  children: [
                                    Icon(PhosphorIconsRegular.chatsTeardrop, color: Colors.white, size: 20,),
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
              
              
              sizedBox(16),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Browse catalogues', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                  
                  sizedBox(16),

                  (refreshCheckProgress && showCatalogues.length == 0) ? 
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                        // sizedBox(8),
                        refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                        Text('Loading catagolues!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                        
                      ],
                    )
                  )
                  : 
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: showCatalogues.length,
                    itemBuilder: (context, index) {
                      return productCard(index);
                    },
                  ),
                ]
              ),
                  
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    children: [

                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF36C31),
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.all(10),
                        child:  Row(
                          mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(PhosphorIconsRegular.storefront, color: Colors.white, size: 28,),
                                // const SizedBox(width:8),
                                // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                            ],
                          ),
                      ),
                      sizedBox(16),
                      Text('Our Showrooms', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                      sizedBox(8),
                      Text('Walk in to get connected.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
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
          //                     refreshHomeDealer(context),
                            
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
  // refreshHomeDealer(BuildContext context) async {

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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                        child:  Row(
                          mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(PhosphorIconsRegular.book, color: Colors.black, size: 24,),
                                // const SizedBox(width:8),
                                // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                            ],
                          ),
                      ),
                      SizedBox(width: 8,),
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


