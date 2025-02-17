import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/utils/app_header.dart';
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

// this is 
class InvoicesDealer extends StatefulWidget {
  
  
  @override
  _InvoicesDealerState createState() => _InvoicesDealerState();
}

class _InvoicesDealerState extends State<InvoicesDealer> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String name = '',
  id='', 
  accountName='',dealerId='',salesId='';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  List<Invoices> invoicesList = [];
  ScrollController? scrollController;
  
  int offset = 0;
  bool connectionStatus = true;
  
  bool anyOutstanding = true;
  double totalOutstanding = 0;
  String dueDate = '';
  int daysLeft = 0;
  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");

  
  // user object
  Invoices? invoices ;

  TextEditingController mobileController = TextEditingController();
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

   @override
    void dispose() {
      otpFocusNode.dispose(); // Dispose of the FocusNode
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
          isActive = prefs.get(Constants.isActive) as int;
          
            if(prefs.get(Constants.role) == Constants.dealer){

              dealerId = prefs.get(Constants.dealerId) as String;
              accountName = prefs.get(Constants.accountName) as String;
              salesId = prefs.get(Constants.salesId) as String;
            }
          });
        } 
        refreshUserInvoicesDealer(context);
    }

      // refresh the list
      Future<void> _refreshList() async {
        // Add your refresh logic here, e.g. fetching new data from a server

        // set the offset to 0 as we are refreshing to start from first
        setState(() {
          offset = 0;
          invoicesList.clear();
          refreshCheckProgress = true;
        });
        
        await Future.delayed(const Duration(seconds: 2));
        refreshUserInvoicesDealer(context);
      }


    // find the user
    void refreshUserInvoicesDealer(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          refreshCheckProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        // print("${APIUrls.amount}${APIUrls.pass}/U2/$id/$offset");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.amount}${APIUrls.pass}/U2/$id/$offset", queryParams)), headers: {"Accept": "application/json"});
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
              List<Invoices> invoices = invoicesData.map<Invoices>((json) => Invoices.fromJson(json)).toList();
              // print(invoicesList);
              
              setState(() {
                invoicesList.addAll(invoices);
                // Get new user data
                // invoices = invoicesData.where((element) => false);
                // invoices.
                double totalSum = invoicesList.fold(0.0, (double sum, Invoices invoice) {
                  return sum + (invoice.pending ?? 0.0);
                });

                DateTime? earliestExpiryDate = invoicesList
                  .where((invoice) => invoice.expiryDate != null) // Filter out null expiry dates
                  .map((invoice) => format.parse(invoice.expiryDate!)) // Parse string to DateTime
                  .reduce((a, b) => a.isBefore(b) ? a : b); // Determine the earliest date
                  
                // get the days left for expiry  
                Duration duration = earliestExpiryDate.difference(DateTime.now());

                // Output the earliest date in a friendly format, e.g., January 1, 2023
                String formattedDate = DateFormat('MMMM d, yyyy').format(earliestExpiryDate);

                totalOutstanding = totalSum;
                dueDate = formattedDate;
                daysLeft = duration.inDays;

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
        else if(jsonObject['status'] == 201 || jsonObject['status'] == 402){
          // no data exists
          setState(() {
            // get the error message
            refreshCheckProgress = false;
            connectionStatus = true;
            showToast(context, 'No more invoices', Constants.success);
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
          refreshUserInvoicesDealer(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }


  // detect scroll to end and load more items
  void _scrollListener(){
    if(scrollController!.position.pixels == scrollController!.position.maxScrollExtent){
      setState(() {
        // increment offset by 5
        if(invoicesList.length-5 == offset){
          offset = offset+5;
          // show up the loader
          startLoader();
        }
        else {
          //print('do nothing');
        }
      });

    }
  }


  // show the loader while loading more items
  void startLoader(){
    setState((){
      refreshCheckProgress = !refreshCheckProgress;
      refreshUserInvoicesDealer(context);
    });
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

                child: Container(
                    margin: EdgeInsets.fromLTRB(8, 0, 8, 16),
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
                                // sizedBox(24),
                                // Image.asset('assets/anjani_title.webp', scale: 2,), 
                                AppHeader('Invoices', '', 1),
                                // sizedBox(24),
                                Text('Invoices', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
                                // sizedBox(16),
                                Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
                                
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
                                //     onPressed: () => updateInvoicesDealer(context),
                                //   ),
                                


                                
                              ],
                            
                            ),

                            sizedBox(8),

                            invoicesList.isNotEmpty ?
                            Expanded(
                              
                              child: RefreshIndicator(
                            onRefresh: _refreshList,
                            child: 
                              ListView.builder(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: invoicesList.length,
                                  itemBuilder: (context, index){
                                    
                                    return  FadeTransition(opacity: _controller,
                                          child:
                                          ScaleTransition(scale: CurvedAnimation(
                                                    parent: _controllerCards,
                                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                                  ),alignment: Alignment.bottomCenter,
                                                  child:
                                                Container(
                                                      margin: EdgeInsets.fromLTRB(8,8,8,8),
                                                      padding: EdgeInsets.fromLTRB(16,16,16,8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: const BorderRadius.all(Radius.circular(24)),
                                                        // border: Border.all(
                                                        //           color: Colors.black12, // Set the color of the border here
                                                        //           width: 1, // Set the width of the border here
                                                        //         ),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: Colors.black12,
                                                            offset: Offset(0.0, 0.0),
                                                            blurRadius: 12.0,
                                                            spreadRadius: 0.3,
                                                          ),
                                                        ]
                                                      ),
                                          child: invoiceCard(index),
                                        )
                                    ));
                                  }),
                              )
                            )
                            : sizedBox(0),
                            
                            // loader while fetching data
                            refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                            
                          
                            


                          
                          ],
                        )
                  )
                ),
            )
        )
    );
  }

  // Refresh profile
  // refreshInvoicesDealer(BuildContext context) async {

  //   //showToast(context, "Verifying your identity!");
  //   setState(() {updateMsg = 'Checking for updtes. Please wait...';});
    
    

  // }


// single feed card
Widget invoiceCard(int position){
  return InkWell(
    // onTap: () => openCircular(context, list[position]),
    // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CircularsAdmin())),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
    
      
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${invoicesList[position].invoiceNo}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87, fontWeight: FontWeight.w500 )),
          SizedBox(width: 8,),
          // Text('${invoicesList[position].invoiceType}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.titleMedium, fontSize: 12, fontWeight: FontWeight.bold, color: invoicesList[position].invoiceType == 'ATL' ? Colors.redAccent : Color(0xFFC41306), )),
          Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                      color: invoicesList[position].invoiceType == 'ATL' ? Color(0x22FF5252) : Color(0x22C41306),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  child: Text('${invoicesList[position].invoiceType}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.bold, color: invoicesList[position].invoiceType == 'ATL' ? Color(0xFFFF5252) : Color(0xFFC41306))),  
              ),
          SizedBox(width: 8,),
          
          
        ]
      ),
      
      sizedBox(8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(invoicesList[position].totalAmount!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              // Text(DateFormat('d-MMM-y', 'en_US').format(getDate(invoicesList[position].expiryDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              Text('Invoiced Amount' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ),
          (invoicesList[position].status != Constants.Paid) ?
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text(DateFormat('d-MMM-y', 'en_US').format(getDate(invoicesList[position].invoiceDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(invoicesList[position].pending!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.red)),
              Text('Pending' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ) : sizedBox(0),
        ],
      ),
      sizedBox(8),
      divider(Colors.black12),
      sizedBox(8),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('d-MMM-y', 'en_US').format(getDate(invoicesList[position].invoiceDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              Text('Invoice date' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ),
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(DateFormat('d-MMM-y', 'en_US').format(getDate(invoicesList[position].expiryDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              Text('Due date' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ),
          // sizedBox(8),
          // IconButton(onPressed: ()=>{}, 
          //   style:  ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Color(0x33008060))),
          //   color: Color(0xFF008060),
          //   focusColor: Color(0xFF008060),
          //   icon: Icon(PhosphorIconsRegular.fileArrowDown, size: 24, color: Color(0xFF008060),),
          // )
        ],
      ),
      sizedBox(8),
      divider(Colors.black12),
      sizedBox(4),

      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
              
            (invoicesList[position].status == Constants.Paid) ?
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                        color: Color.fromARGB(255, 1, 177, 28),
                        borderRadius: BorderRadius.circular(16),
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.check, size: 16, color: Colors.white),
                    SizedBox(width: 4,),
                    Text('Paid' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5, color: Colors.white, fontWeight: FontWeight.bold ), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true,  )
                  ]
                )
              )
              : Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.warning, size: 16, color: Colors.white),
                    SizedBox(width: 4,),
                    ((getDate(invoicesList[position].expiryDate!).difference(DateTime.now()).inDays) >= 0) ?
                      Text('${(getTimeDiff(getDate(invoicesList[position].expiryDate!), DateTime.now()))} left' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5, color: Colors.white, fontWeight: FontWeight.bold ), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true,  )
                      : Text('Expired ${(getDate(invoicesList[position].expiryDate!).difference(DateTime.now()).inDays.abs())} day(s) ago' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5, color: Colors.white, fontWeight: FontWeight.bold ), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              
                  ]
                )
              ),
              
            SizedBox(width: 8,),
            (invoicesList[position].status != Constants.Paid) ?
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                        color: Color(0x99FFCDD2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    child: Text((invoicesList[position].status == Constants.PartialPaid) ? 'Partially Paid' : 'Not Paid', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: Color(0xFFF91616))),  
                )
                : sizedBox(0),

              
        ]
      ),
      
      
      // styledText(InvoicesList[0].description, Constants.linkifyBig, Constants.lightbg, 5),
      sizedBox(8),
      
      
      // Row(
      //   children: [
      //     Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.black54,),
      //     SizedBox(width: 4,),
      //     Text('${DateFormat('MMM dd, yyyy · hh:mm aa', 'en_US').format(getDate(invoicesList[position].expiryDate!))}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
      //     // Text( (InvoicesList[position].createdOn != 'just now') ? '${(getTimeDiff(now, getDate(InvoicesList[position].createdOn!)))} ago' : 'just now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.caption)),
      //   ],
      // ),
      // sizedBox(16),

      
    ],
        )
  );

}
  
  void openLink(String urlString) async {

    String message = 'Hello!'; // Replace this with your message

    Uri url = Uri.parse(urlString);
    
          // await canLaunchUrl(url).then((value) => {
          //   // print(value),
          //   launchUrl(url, mode: LaunchMode.externalNonBrowserApplication),
          // });
  }



}

// getting image
Map<String, bool> imageExistenceCache = {}; // A cache to store image existence results

