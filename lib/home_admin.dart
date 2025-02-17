import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/dealerinvoices_admin.dart';
import 'package:anjanitek/messages.dart';
import 'package:anjanitek/payments_admin.dart';
import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/sales_dealers_1.dart';
import 'package:anjanitek/dealers_outstanding_admin.dart';
import 'package:anjanitek/dealersearch_admin.dart';
import 'package:anjanitek/invoices_all_admin.dart';
import 'package:anjanitek/invoices_dealer.dart';
import 'package:anjanitek/ledger_admin.dart';
import 'package:anjanitek/messaging_admin.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/modals/stats.dart';
import 'package:anjanitek/payments_dealer.dart';
import 'package:anjanitek/sales_dealers_2.dart';
import 'package:anjanitek/showrooms.dart';
import 'package:intl/intl.dart';
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
  mobile='', email = '-', role = '-', adminId='',id='', userImage='',gcm_regId='',
  accountName='',dealerId='',salesId='',city='',state='',gst='',address1='',address2='',address3='';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  bool catalogueCheckProgress = false;
  late List<Invoices> invoicesList = [];
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
  List<Dealers> dealersList = [];
  List<Dealers> _filteredUsers = [];
  bool isLoading = false;
  bool isDataAvailable = false;
  bool endOfData = true;
  int offset = 0;

  List<Catalogue> showCatalogues = [];
  
  // user object
  Invoices? invoices ;

  ScrollController? scrollController;
  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  late SharedPreferences prefs;

  @override
  void initState() {
      
      // get reference to internal database
      getUsers();

      _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 1000),);
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
    _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
    _controllerCards.forward();

    scrollController = new ScrollController()..addListener(_scrollListener);
    
    super.initState();
  }

  void _onSearchChanged() {
    String query = searchTextController.text.toLowerCase();
    List<Dealers> filteredList = dealersList.where((item) => item.dealerId!.toLowerCase().contains(query)).toList();

    setState(() {
      _filteredUsers = filteredList;
    });
  }

   @override
    void dispose() {
      scrollController!.dispose();
      otpFocusNode.dispose(); // Dispose of the FocusNode
      _controller.dispose();
      _controllerCards.dispose();
      super.dispose();
    }

  
    // get user details
    void getUsers() async {

        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
          name = prefs.get(Constants.name) as String;
          adminId = prefs.get(Constants.id) as String;
          email = prefs.get(Constants.email) as String;
          role = prefs.get(Constants.role) as String;
          mobile = prefs.get(Constants.mobile) as String;
          userImage = prefs.get(Constants.userImage) as String;
          gcm_regId = prefs.get(Constants.gcmRegId) as String;
          isActive = prefs.get(Constants.isActive) as int;
          
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

        getStats(context);
        getCatalogues(context);
        // refreshUserHomeAdmin(context);
    }



    // find the user
    void refreshUserHomeAdmin(BuildContext context) async {

      if(await checkInternetConnectivity()){

        setState(() {
          refreshCheckProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        print("${APIUrls.amount}${APIUrls.pass}/U5");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.amount}${APIUrls.pass}/U5", queryParams)), headers: {"Accept": "application/json"});
        print(result.body);
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
              // print(invoicesList);
              
              setState(() {
                // Get new user data
                // invoices = invoicesData.where((element) => false);
                // invoices.
                double totalSum = invoicesList.fold(0.0, (double sum, Invoices invoice) {
                  // Check if the invoiceType is "ATL"
                  if (invoice.invoiceType == "ATL") {
                    return sum + (invoice.pending ?? 0.0); // Add to sum only if condition is met
                  }
                  return sum; // Otherwise, just return the current sum
                });
                
                double totalSum1 = invoicesList.fold(0.0, (double sum, Invoices invoice) {
                  // Check if the invoiceType is "ATL"
                  if (invoice.invoiceType == "VCL") {
                    return sum + (invoice.pending ?? 0.0); // Add to sum only if condition is met
                  }
                  return sum; // Otherwise, just return the current sum
                });


                DateTime? earliestExpiryDate = invoicesList
                  .where((invoice) => invoice.expiryDate != null && invoice.invoiceType == "ATL") // Filter out null expiry dates
                  .map((invoice) => format.parse(invoice.expiryDate!)) // Parse string to DateTime
                  .reduce((a, b) => a.isBefore(b) ? a : b); // Determine the earliest date
                  
                // get the days left for expiry  
                Duration duration = earliestExpiryDate.difference(DateTime.now());

                // Output the earliest date in a friendly format, e.g., January 1, 2023
                String formattedDate = DateFormat('MMMM d, yyyy').format(earliestExpiryDate);
                
                DateTime? earliestExpiryDate1 = invoicesList
                  .where((invoice) => invoice.expiryDate != null &&  invoice.invoiceType == "VCL") // Filter out null expiry dates
                  .map((invoice) => format.parse(invoice.expiryDate!)) // Parse string to DateTime
                  .reduce((a, b) => a.isBefore(b) ? a : b); // Determine the earliest date
                  
                // get the days left for expiry  
                Duration duration1 = earliestExpiryDate1.difference(DateTime.now());

                // Output the earliest date in a friendly format, e.g., January 1, 2023
                String formattedDate1 = DateFormat('MMMM d, yyyy').format(earliestExpiryDate1);

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
          refreshUserHomeAdmin(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }


    void getStats(BuildContext context) async {

      if(await checkInternetConnectivity()){

        setState(() {
          refreshCheckProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        // print("${APIUrls.stats}${APIUrls.pass}/0/$role/$adminId");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.stats}${APIUrls.pass}/0/$role/$adminId", queryParams)), headers: {"Accept": "application/json"});
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
              statsList = invoicesData.map<Stats>((json) => Stats.fromJson(json)).toList();
              // print(statsList);

              setState(() {
                totalOutstandingATL = statsList.firstWhere((element) => element.state == "All").pendingATL!;
                totalOutstandingVCL = statsList.firstWhere((element) => element.state == "All").pendingVCL!;
                  
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
          refreshUserHomeAdmin(context);
          
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




  // initiate the search
  void searchNow(searchTerm) {

    setState(() {
      searchedText = searchTerm;
      dealersList.clear();
    });

    setState(() {
      isLoading = true;
    });
    getStudents();
  }

  // get dealers for approval
  void getStudents() async {

    // check if there is any data
    if(searchedText.isNotEmpty) {
      // query parameters    
      Map<String, String> queryParams = {
        // "offset":"$offset",
        // "role":role!,
        // "requestStatus":Constants.submitted
        };

      // API call
      // key, type, collegeId, playerId
      // print("${APIUrls.user}${APIUrls.pass}/U3/$searchBy/$collegeId/$role/$branch/$selectedCampus/$universityId/$searchedText/$offset");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U3//$adminId/$role/$searchedText/$offset", queryParams)), headers: {"Accept": "application/json"});
      // var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/$searchBy/$searchedText/$offset/$campus", queryParams)), headers: {"Accept": "application/json"});
// print(result.body);
      // get the result body which is JSON
      var jsonString = jsonDecode(result.body); 
      // convert jsonString to Map
      var jsonObject = jsonString as Map; 

      List<Dealers> list1;
      // check if the api returned success
      if(jsonObject['status'] == 200){
        // get the list data from jsonObject
        var dealers = jsonObject['data'] as List;

        if(dealers.isNotEmpty) {
          // convert to list
          list1 = dealers.map<Dealers>((json) => Dealers.fromJson(json)).toList();
          
          // check if there are any dealers for approval
          if(list1.isNotEmpty){
            setState(() {
              dealersList.addAll(list1);

            //   // check if there are any official dealers
            // // if so, lets get them all into a separate list for bulk operations
            // if(list1.any((item) => item.requestType == 3.toString())){
              
            //   // parse through all the dealers one by one
            //   for (var element in list1) {
            //     if(element.requestType == 3.toString()){
            //       // add the request to the list that is official
            //       dealersList.add(element);
            //     }
            //     else {
            //       // add the request to other list
            //       dealersList.add(element);
            //     }
            //   }
            // }

              isLoading = false;
              isDataAvailable = true;

            });
          }
          else {
            // no dealers pending for approval
            setState(() {
              emptyStateMsg = 'No match found';
              isLoading = false;
              isDataAvailable = false;
            });
          }

        }
          else {
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
            showToast(context, emptyStateMsg,Constants.warning);
          }

    }
    else {
      // no dealers pending for approval
      setState(() {
        emptyStateMsg = 'No pending dealers';
        isLoading = false;
        endOfData = false;
      });
    }
  }

  // detect scroll to end and load more items
  void _scrollListener(){
    if(scrollController!.position.pixels == scrollController!.position.maxScrollExtent){
      setState(() {
        // increment offset by 20
        offset = offset+20;
      });
      // show up the loader
      startLoader();
    }
  }

  // show the loader while loading more items
  void startLoader(){
    setState((){
      isLoading = true;
      //print(offset);
      getStudents();
    });
  }

  Future<void> _refreshList() async {
    // Add your refresh logic here, e.g. fetching new data from a server
    await Future.delayed(const Duration(seconds: 2));
    getStudents();
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
        margin: EdgeInsets.all(16),
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
              Text('Home', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
              sizedBox(16),
              
              // TextField(
              //   onTap: ()=>{
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => DealerSearch()))
              //   },
              //     controller: searchTextController,
              //     // autofocus: true,
              //     keyboardType: TextInputType.text,
              //     textInputAction: TextInputAction.search,
              //     style: const TextStyle(fontSize: 14.0,),
              //     decoration: InputDecoration(
              //       fillColor: Color.fromARGB(255, 255, 255, 255),
              //       filled: true,
              //       contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              //       suffixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: Color(0xFF008160), ),
              //                             // suffixIcon: const Icon(PhosphorIcons.magnifyingGlass, color: Colors.grey),
              //       hintText: 'Type dealer name to Search',
              //       hintStyle: const TextStyle(
              //         fontSize: 14.0,
              //       ),
              //       border: OutlineInputBorder(
                      
              //         borderRadius: BorderRadius.circular(8.0),
              //         borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
              //       ),
              //       focusedBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(8.0),
              //         borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
              //       ),
              //     ),
                    
              //   ),
              // sizedBox(16),
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
                                    // Text('Outstanding' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                    refreshCheckProgress ? AppProgress(height: 24, width: 24) : IconButton(onPressed: ()=>{getStats(context)}, icon: Icon(PhosphorIconsBold.arrowClockwise, ))
                                    // refreshCheckProgress ? AppProgress(height: 24, width: 24) : IconButton(onPressed: ()=>{refreshUserHomeAdmin(context)}, icon: Icon(PhosphorIconsBold.arrowClockwise, ))
                                  ],
                                ),
                                // sizedBox(16),
                                Text('ATL' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium,  fontWeight: FontWeight.bold)),
                                Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingATL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                sizedBox(16),
                                Text('VCL' , style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium,  fontWeight: FontWeight.bold)),
                                Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstandingVCL)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFFC41306))),
                                
                      sizedBox(12),
                      DottedLine(),
                      sizedBox(12),
                      InkWell(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => InvoicesAllAdmin()));
                        },
                        child: 
                            Text("INVOICES –>", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                      ),
                      sizedBox(12),
                      DottedLine(),
                      sizedBox(12),
                      // sizedBox(8),
                      // divider(Colors.black12),
                      // sizedBox(8),
                      InkWell(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => OutstandingDealers()));
                        },
                        child: 
                            Text("OUTSTANDING DEALERS –>", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                      ),
                      

                      ]),
              ),
              
              sizedBox(16),
              InkWell(
                onTap: () => {
                  (role.toLowerCase() == Constants.salesExecutive.toLowerCase()) ?
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SalesDealers2(adminId, name)))
                  : Navigator.push(context, MaterialPageRoute(builder: (context) => SalesDealers1()))
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      
                      children: [

                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          padding: const EdgeInsets.all(10),
                          child:  Icon(PhosphorIconsRegular.usersThree, color: Color(0xFFFFFFFF), size: 24,),
                        ),
                        SizedBox(width: 8),
                        Flexible(child: 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            (role.toLowerCase() == Constants.salesExecutive.toLowerCase()) ?
                            Text('Dealers', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600))
                            : Text('Sales & Dealers', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                            
                            sizedBox(4),
                            
                            (role.toLowerCase() == Constants.salesExecutive.toLowerCase()) ?
                            Text('All dealers under you', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 14,color: Colors.black87))
                            : Text('All Sales people & dealers under you', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 14,color: Colors.black87)),
                          ],
                        )
                        )
                      ],
                    )
                )
              ),

              sizedBox(16),
              InkWell(
                onTap: () => {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentsAdmin()))
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
                      Text('Payments', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                      sizedBox(8),
                      Text('Payments by your dealers.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                      sizedBox(4),
                    ],
                  )
                )
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
              
              // this is kept inside the Messages.
              // sizedBox(16),
              // InkWell(
              //   onTap: () => {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => MessagingAdmin('All', 'All')))
              //   },
              //   child: 
              //     Container(
              //       decoration: BoxDecoration(
              //         color: Colors.white,
              //         borderRadius: const BorderRadius.all(Radius.circular(24)),
              //         border: Border.all(
              //                   color: Colors.black12, // Set the color of the border here
              //                   width: 1, // Set the width of the border here
              //                 ),
              //         boxShadow: const [
              //           BoxShadow(
              //             color: Colors.black12,
              //             offset: Offset(0.0, 0.0),
              //             blurRadius: 24.0,
              //             spreadRadius: 0.3,
              //           ),
              //         ]
              //       ),
              //       padding: const EdgeInsets.all(16),
              //       child: Row(
              //         crossAxisAlignment: CrossAxisAlignment.center,
                      
              //         children: [

              //           Container(
              //             decoration: const BoxDecoration(
              //               color: Color(0xFF61C454),
              //               borderRadius: BorderRadius.all(Radius.circular(24)),
              //             ),
              //             padding: const EdgeInsets.all(10),
              //             child:  Icon(PhosphorIconsRegular.notification, color: Color(0xFFFFFFFF), size: 24,),
              //           ),
              //           SizedBox(width: 8),
              //           Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text('Messaging', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
              //               sizedBox(4),
              //               Text('Send text SMS and notifications ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 14,color: Colors.black87)),
              //             ],
              //           )
              //         ],
              //       )
              //   )
              // ),
              
              sizedBox(16),

              // InkWell(
              //   onTap: () => {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => Messages()))
              //   },
              //   child: 
              //     Container(
              //       decoration: BoxDecoration(
              //         color: Colors.white,
              //         borderRadius: const BorderRadius.all(Radius.circular(24)),
              //         border: Border.all(
              //                   color: Colors.black12, // Set the color of the border here
              //                   width: 1, // Set the width of the border here
              //                 ),
              //         boxShadow: const [
              //           BoxShadow(
              //             color: Colors.black12,
              //             offset: Offset(0.0, 0.0),
              //             blurRadius: 24.0,
              //             spreadRadius: 0.3,
              //           ),
              //         ]
              //       ),
              //       padding: const EdgeInsets.all(16),
              //       child: Row(
              //         crossAxisAlignment: CrossAxisAlignment.center,
                      
              //         children: [

              //           Container(
              //             decoration: const BoxDecoration(
              //               color: Color(0xFF61C454),
              //               borderRadius: BorderRadius.all(Radius.circular(24)),
              //             ),
              //             padding: const EdgeInsets.all(10),
              //             child:  Icon(PhosphorIconsRegular.notification, color: Color(0xFFFFFFFF), size: 24,),
              //           ),
              //           SizedBox(width: 8),
              //           Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text('Messages', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
              //               sizedBox(4),
              //               Text('Sales and Dealer conversations ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 14,color: Colors.black87)),
              //             ],
              //           )
              //         ],
              //       )
              //   )
              // ),
              // sizedBox(16),
              
              // Ledger is only available for SuperAdmin/Finance Team
              // (role.toLowerCase() != Constants.superAdmin.toLowerCase()) ? sizedBox(0) :
              // InkWell(
              //   onTap: () => {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => LedgerAdmin()))
              //   },
              //   child:
              //     Container(
              //       decoration: BoxDecoration(
              //         color: Colors.white,
              //         borderRadius: const BorderRadius.all(Radius.circular(24)),
              //         border: Border.all(
              //                   color: Colors.black12, // Set the color of the border here
              //                   width: 1, // Set the width of the border here
              //                 ),
              //         boxShadow: const [
              //           BoxShadow(
              //             color: Colors.black12,
              //             offset: Offset(0.0, 0.0),
              //             blurRadius: 24.0,
              //             spreadRadius: 0.3,
              //           ),
              //         ]
              //       ),
              //       padding: const EdgeInsets.all(16),
              //       child: Row(
              //         crossAxisAlignment: CrossAxisAlignment.center,
                      
              //         children: [
              //           Container(
              //               decoration: const BoxDecoration(
              //                 color: Color(0xFF008160),
              //                 borderRadius: BorderRadius.all(Radius.circular(24)),
              //               ),
              //               padding: const EdgeInsets.all(10),
              //               child:  const Icon(PhosphorIconsRegular.listMagnifyingGlass, color: Color(0xFFFFFFFF), size: 24,),
              //             ),
              //           SizedBox(width: 8),
              //           Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text('Ledger', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
              //               sizedBox(4),
              //               Text('Account details by region', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 14,color: Colors.black87)),
              //             ],
              //           )
                        
              //         ],
              //       )
              //     ),
              // )
              
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
          //                     refreshHomeAdmin(context),
                            
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
    ),))
    );
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


