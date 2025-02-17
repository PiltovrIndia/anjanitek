import 'dart:convert';
import 'dart:io';
import 'dart:ui';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/dealerinvoices_admin.dart';
import 'package:anjanitek/message_detail.dart';
import 'package:anjanitek/messaging_admin.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/paymentupdate_admin.dart';
import 'package:anjanitek/paymentupdate_admin1.dart';
import 'package:flutter/services.dart';
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
import 'package:anjanitek/utils/app_header.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/divider.dart';
// import 'package:anjanitek/util/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';
import 'package:anjanitek/verify.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

// this is dealer details screen using the selected dealer id
// details will be fetched once the screen is invoked.
class DealerDetails extends StatefulWidget {

  // user object is sent from previous screen
  const DealerDetails(this.selectedSalesPerson, this.selectedSalesPersonName, this.selectedDealerId, this.selectedDealerPersonName);
  final String selectedSalesPerson, selectedSalesPersonName, selectedDealerId, selectedDealerPersonName;
  // const DealerDetails(this.selectedDealerId, this.selectedSalesPersonName);
  // final String selectedDealerId, selectedSalesPersonName;

  @override
  _DealerDetailsState createState() => _DealerDetailsState();
}

class _DealerDetailsState extends State<DealerDetails> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String name = '', role = '', id='';
  
  bool versionCheckProgress = false;
  bool refreshCheckProgress = true;
  bool updatePhoneNumberCheckProgress = false;
  String updatePhoneNumberCheckProgressMessage = '';
  List<String> branches = [];
  
  // user object
  Dealers? dealer ;
  Users? dealerUser ;

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

    _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
    _controllerCards.forward();
    
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
      
        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
          name = prefs.get(Constants.name) as String;
          id = prefs.get(Constants.id) as String;
          role = prefs.get(Constants.role) as String;
          
          });
        } 
      refreshUserDealerDetails(context);
    }



    // find the user
    void refreshUserDealerDetails(BuildContext context) async {

      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}", queryParams)), headers: {"Accept": "application/json"});
      // print(result.body);
      
      // Decode the JSON string into a Map using the jsonDecode function
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      // user object list
      
      // check if the api returned success
      if(jsonObject['status'] == 200){
        
          // get the user data from jsonObject
          Map<String, dynamic> userdata = jsonObject['data'];
          
          setState(() {
            // Get new user data
            dealer = Dealers.fromJson(userdata);
            dealerUser = Users.fromJson(userdata);
            refreshCheckProgress = false;
          });
      }
      else if(jsonObject['status'] == 402){
        // no data exists
        setState(() {
          // get the error message
          refreshCheckProgress = false;
        });
        
      }
      else if(jsonObject['status'] == 404){
        // no data exists
        setState(() {
          // get the error message
          refreshCheckProgress = false;
        });
        
      }
      else {

          setState(() {
            refreshCheckProgress = false;
            showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
        body: 
         FadeTransition(opacity: _controller,
        child:
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

          (!refreshCheckProgress && (dealerUser != null)) ?
          Column(
          // child: CardRound(Palette.lightBackground, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // sizedBox(24),
              // Image.asset('assets/anjani_title.webp', scale: 2,), 
              AppHeader('Invoices', '', 1),
              // sizedBox(24),

Container(
  decoration: BoxDecoration(
                  // color: Theme.of(context).shadowColor,
                  color: Color(0xFFE4F6F1),
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(
                            color: Colors.black12, // Set the color of the border here
                            width: 1, // Set the width of the border here
                          ),
                  // boxShadow: const [
                  //   BoxShadow(
                  //     color: Colors.black12,
                  //     offset: Offset(0.0, 0.0),
                  //     blurRadius: 12.0,
                  //     spreadRadius: 0.3,
                  //   ),
                  // ]
                ),
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
  child:
Column(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    

              (dealerUser != null) ?
              Text(dealerUser!.name!, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), )
              : sizedBox(0),
              sizedBox(32),
              Text('Dealer of', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87), ),
              Text(dealerUser!.mapName!, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold,color: Colors.black87), ),
              sizedBox(32),


              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _controllerCards,
                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                  ),alignment: Alignment.bottomCenter,
                  child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [

                              
                                // Only finance admins can update this
                              (role.toLowerCase() == Constants.superAdmin.toLowerCase()) ?
                              Expanded(child: 
                              InkWell(
                                onTap: ()=> {
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentUpdateAdmin(dealer!.dealerId!, dealerUser!.name!, '-')))
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentUpdateAdmin1(dealer!)))
                                },
                              
                              child: 
                              Container( 
                                decoration: BoxDecoration(
                                  // color: Theme.of(context).shadowColor,
                                  color: Color(0xFF048563),
                                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                                  border: Border.all(
                                            color: Color(0xFF048563), // Set the color of the border here
                                            width: 1, // Set the width of the border here
                                          ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0.0, 0.0),
                                      // blurRadius: 12.0,
                                      spreadRadius: 0.3,
                                    ),
                                  ],

                                  
                                ),
                                
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                margin: (role.toLowerCase() == Constants.superAdmin.toLowerCase()) ? EdgeInsets.fromLTRB(0, 0, 8, 0) : EdgeInsets.all(0),
                                child: Column(
                                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Icon(PhosphorIconsBold.currencyInr, size: 24,color: Color(0xFFFFFFFF),),
                                            sizedBox(8,),
                                            Text('Update\nCredit', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)), textAlign: TextAlign.center,),
                                          ],
                                        ) 
                                )
                              )
                              )
                              : sizedBox(0),

                              
                              

                              Expanded(child: 
                              InkWell(
                                onTap: ()=> {
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => MessagingAdmin(dealerUser!.id!, dealerUser!.name!)))
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => MessageDetail(dealerUser!.mapTo!, dealer!.dealerId!, dealerUser!.mapName!, dealer!.accountName!)))
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => MessageDetail(widget.selectedSalesPerson, dealerUser!.id!, widget.selectedSalesPersonName, dealerUser!.name!)))
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => MessageDetail(id, dealerUser!.id!, name, dealerUser!.name!)))
                                },
                              
                              child: 
                                  Container( 
                                    decoration: BoxDecoration(
                                      // color: Theme.of(context).shadowColor,
                                      color: Color(0xFF048563),
                                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                                      border: Border.all(
                                                color: Color(0xFF048563), // Set the color of the border here
                                                width: 1, // Set the width of the border here
                                              ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          offset: Offset(0.0, 0.0),
                                          // blurRadius: 12.0,
                                          spreadRadius: 0.3,
                                        ),
                                      ]
                                    ),
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                    child: Column(
                                      
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                const Icon(PhosphorIconsBold.chatDots, size: 24,color: Color(0xFFFFFFFF),),
                                                sizedBox(8,),
                                                Text('View\nMessages', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)), textAlign: TextAlign.center,),
                                                // const Icon(PhosphorIconsRegular.notification, size: 24,color: Color(0xFF000000),),
                                                // sizedBox(8,),
                                                // Text('Send\nReminder', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
                                              ],
                                            ) 
                                  ),
                              ),
                              ),
                              
                              const SizedBox(width: 8,),
                              Expanded(child: 
                                InkWell(
                                  onTap: () => {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DealerInvoicesAdmin(dealer!)))
                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => DealerInvoicesAdmin(dealerUser!)))
                                  },
                                  child: 
                                    Container( 
                                      decoration: BoxDecoration(
                                        // color: Theme.of(context).shadowColor,
                                        color: Color(0xFF048563),
                                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                                        border: Border.all(
                                                  color: Color(0xFF048563), // Set the color of the border here
                                                  width: 1, // Set the width of the border here
                                                ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0.0, 0.0),
                                            // blurRadius: 12.0,
                                            spreadRadius: 0.3,
                                          ),
                                        ]
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                      child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  const Icon(PhosphorIconsBold.receipt, size: 24,color: Color(0xFFFFFFFF),),
                                                  sizedBox(8,),
                                                  Text('View\nInvoices', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)), textAlign: TextAlign.center,),
                                                ],
                                              ) 
                                    )
                                )
                              ),
                              
                            ],
                          ),
                      ),

  ],
),
),

 
              // Row(
              //   // crossAxisAlignment: CrossAxisAlignment.stretch,
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   mainAxisSize: MainAxisSize.max,
                
              //   children: [

              //     // Only finance admins can update this
              //     (role.toLowerCase() == Constants.superAdmin.toLowerCase()) ?
              //     InkWell(
              //       onTap: ()=> {
              //         Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentUpdateAdmin(dealerUser!.id!, dealerUser!.name!)))
              //       },
                  
              //     child: Container( 
              //       decoration: BoxDecoration(
              //         // color: Theme.of(context).shadowColor,
              //         color: Color.fromARGB(255, 186, 232, 220),
              //         borderRadius: const BorderRadius.all(Radius.circular(16)),
              //         border: Border.all(
              //                   color: Color(0x33008060), // Set the color of the border here
              //                   width: 1, // Set the width of the border here
              //                 ),
              //         boxShadow: const [
              //           BoxShadow(
              //             color: Colors.black12,
              //             offset: Offset(0.0, 0.0),
              //             blurRadius: 12.0,
              //             spreadRadius: 0.3,
              //           ),
              //         ]
              //       ),
              //       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              //       child: Column(
              //           // crossAxisAlignment: CrossAxisAlignment.stretch,
              //                 mainAxisAlignment: MainAxisAlignment.center,
              //                 mainAxisSize: MainAxisSize.max,
              //                 children: [
              //                   const Icon(PhosphorIconsRegular.currencyInr, size: 24,color: Color(0xFF000000),),
              //                   sizedBox(8,),
              //                   Text('Update\nCredit', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
              //                 ],
              //               ) 
              //       )
              //     )
              //     : sizedBox(0),

                  
              //     const SizedBox(width: 8,),
              //     InkWell(
              //       onTap: ()=> {
              //         // Navigator.push(context, MaterialPageRoute(builder: (context) => MessagingAdmin(dealerUser!.id!, dealerUser!.name!)))
              //         Navigator.push(context, MaterialPageRoute(builder: (context) => MessageDetail(widget.selectedSalesPerson, dealerUser!.id!, widget.selectedSalesPersonName, dealerUser!.name!)))
              //         // Navigator.push(context, MaterialPageRoute(builder: (context) => MessageDetail(id, dealerUser!.id!, name, dealerUser!.name!)))
              //       },
                  
              //     child: 
              //         Container( 
              //           decoration: BoxDecoration(
              //             // color: Theme.of(context).shadowColor,
              //             color: Color.fromARGB(255, 186, 232, 220),
              //             borderRadius: const BorderRadius.all(Radius.circular(16)),
              //             border: Border.all(
              //                       color: Color(0x33008060), // Set the color of the border here
              //                       width: 1, // Set the width of the border here
              //                     ),
              //             boxShadow: const [
              //               BoxShadow(
              //                 color: Colors.black12,
              //                 offset: Offset(0.0, 0.0),
              //                 blurRadius: 12.0,
              //                 spreadRadius: 0.3,
              //               ),
              //             ]
              //           ),
              //           padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              //           child: Column(
                          
              //                     mainAxisAlignment: MainAxisAlignment.center,
              //                     mainAxisSize: MainAxisSize.max,
              //                     children: [
              //                       const Icon(PhosphorIconsRegular.chatDots, size: 24,color: Color(0xFF000000),),
              //                       sizedBox(8,),
              //                       Text('View\nMessages', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
              //                       // const Icon(PhosphorIconsRegular.notification, size: 24,color: Color(0xFF000000),),
              //                       // sizedBox(8,),
              //                       // Text('Send\nReminder', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
              //                     ],
              //                   ) 
              //         ),
              //     ),
              //     const SizedBox(width: 8,),
              //     InkWell(
              //       onTap: () => {
              //         Navigator.push(context, MaterialPageRoute(builder: (context) => DealerInvoicesAdmin(dealerUser!)))
              //       },
              //       child: 
              //         Container( 
              //           decoration: BoxDecoration(
              //             // color: Theme.of(context).shadowColor,
              //             color: Color.fromARGB(255, 186, 232, 220),
              //             borderRadius: const BorderRadius.all(Radius.circular(16)),
              //             border: Border.all(
              //                       color: Color(0x33008060), // Set the color of the border here
              //                       width: 1, // Set the width of the border here
              //                     ),
              //             boxShadow: const [
              //               BoxShadow(
              //                 color: Colors.black12,
              //                 offset: Offset(0.0, 0.0),
              //                 blurRadius: 12.0,
              //                 spreadRadius: 0.3,
              //               ),
              //             ]
              //           ),
              //           padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              //           child: Column(
              //                     mainAxisAlignment: MainAxisAlignment.center,
              //                     mainAxisSize: MainAxisSize.max,
              //                     children: [
              //                       const Icon(PhosphorIconsRegular.receipt, size: 24,color: Color(0xFF000000),),
              //                       sizedBox(8,),
              //                       Text('View\nInvoices', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
              //                     ],
              //                   ) 
              //         )
              //     )

              //   ],
              // ),












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
              //     onPressed: () => updateDealerDetails(context),
              //   ),
              sizedBox(16),

              refreshCheckProgress ? AppProgress(height: 32, width: 32) : sizedBox(0),
              
              ScaleTransition(scale: CurvedAnimation(
                                    parent: _controllerCards,
                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                  ),alignment: Alignment.bottomCenter,
                                  child:
              Container( 
                decoration: BoxDecoration(
                  color: Color(0xFFF9F9F9),
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(
                            color: Colors.black12, // Set the color of the border here
                            width: 1, // Set the width of the border here
                          ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, 0.0),
                      // blurRadius: 12.0,
                      spreadRadius: 0.3,
                    ),
                  ]
                ),
                // margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: 
                // CardRound(Theme.of(context).cardColor,
                  Container(
                    // margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () async {
                          // FocusScope.of(context).requestFocus(otpFocusNode),
                          // _updatePhoneNumberBottomSheet(context);
                           
                                      String telephoneUrl = "tel:${dealerUser!.mobile}";
                                        await launchUrlString(telephoneUrl);
                                      
                        },
                        child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                
                                children: [
                                  Icon(PhosphorIconsRegular.phone, color: Colors.black, size: 24,),
                                  const SizedBox(width:16),
                                  Expanded(child: 
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Text('Mobile', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                        Text(dealerUser!.mobile!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Action to perform when the button is pressed
                                      String telephoneUrl = "tel:${dealerUser!.mobile}";
                                        await launchUrlString(telephoneUrl);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF048563),
                                      foregroundColor: Color(0xFFFFFFFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24.0),
                                      ),
                                    ),
                                    child: Text('Call now'),
                                  ),
                                  
                                  // const SizedBox(width:8),
                                  // Container(
                                  //   padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                                  //   decoration: const BoxDecoration(
                                  //   color: Colors.black12,
                                  //     borderRadius: BorderRadius.all(Radius.circular(10)),
                                  //   ),
                                  //   child: Text('Edit', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall)),
                                  // )
                                ],
                              ),
                      ),
                      sizedBox(4),
                      divider(Colors.black26),
                      sizedBox(4),
                      InkWell(
                        onTap: () => {
                          Clipboard.setData(ClipboardData(text: dealerUser!.email!)),
                          showToast(context, 'Email copied!',Constants.success)

                        },
                        child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.at, color: Colors.black, size: 24),
                              const SizedBox(width:16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Email', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                          Text('${dealerUser!.email}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                  ]),
                              )
                              
                            ],
                          ),
                      )
                      
                      
                    ],
                  ),
                  ),
                ),
              ),


              sizedBox(16),
              // (dealerUser!=null) ? 
              ScaleTransition(scale: CurvedAnimation(
                                    parent: _controllerCards,
                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                  ),alignment: Alignment.bottomCenter,
                                  child:
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF9F9F9),
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(
                            color: Colors.black12, // Set the color of the border here
                            width: 1, // Set the width of the border here
                          ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, 0.0),
                      // blurRadius: 12.0,
                      spreadRadius: 0.3,
                    ),
                  ]
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIconsRegular.mapPin, color: Colors.black, size: 24,),
                      const SizedBox(width:16),
                      Expanded(
                                  child: 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            
                            // sizedBox(8),
                            Text('Address:', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                            sizedBox(8),
                            
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (dealer!.address1 != '-') ? Text('${dealer!.address1} ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, letterSpacing: 1, fontWeight: FontWeight.w500),overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ) : sizedBox(0),
                                  sizedBox(8),
                                  (dealer!.address2 != '-') ? Text('${dealer!.address2} ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, letterSpacing: 1, fontWeight: FontWeight.w500)) : sizedBox(0),
                                  sizedBox(8),
                                  (dealer!.address3 != '-') ? Text('${dealer!.address3} ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, letterSpacing: 1, fontWeight: FontWeight.w500)) : sizedBox(0),
                                ],
                              ),  
                        ],
                      ),
                      )
                  ],
                )
              )
              )
              //  : sizedBox(0),
              
            ],
          
          )
          : Center(
            child: Column(
              children: [
                Text('Loading...')
              ]
            )
          )
          ,

          sizedBox(16),


          // profile actions
          // (dealer!=null) ? 
          // Container( 
          //   decoration: BoxDecoration(
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
          //             blurRadius: 12.0,
          //             spreadRadius: 0.3,
          //           ),
          //         ]
          //       ),
          //       padding: const EdgeInsets.all(16),
          //         child: 
          //         Column(
          //           children: [
          //                       InkWell(
                                  
          //                         child: Container(
          //                           padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          //                           child:
          //                           Row(
          //                             children: [
          //                               Icon(PhosphorIconsRegular.arrowClockwise, color: Color(0xFF008060), size: 20,),
          //                               const SizedBox(width:16),
          //                               Text('Sales person', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
          //                               refreshCheckProgress ? const AppProgress(height: 20, width: 20,) : sizedBox(0),
          //                             ],
          //                           ),
          //                         ),
                                  
          //                       onTap: () => {
          //                         setState(() {
          //                           refreshCheckProgress = true;
          //                         }),
          //                         refreshUserDealerDetails(context)
          //                         // set the global theme
          //                         // setGlobalTheme(!value)
          //                       },
          //                       ),
                             
          //                     divider(Colors.black26),

          //                     InkWell(
                                
          //                       child: Container(
          //                         padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          //                         child:
          //                         Row(
          //                           children: [
          //                             Icon((Platform.isAndroid ? PhosphorIconsRegular.googlePlayLogo : PhosphorIconsRegular.appStoreLogo), color: Color(0xFF008060), size: 20,),
          //                             const SizedBox(width:16),
          //                             Text('${dealer!.salesId}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
          //                             versionCheckProgress ? const AppProgress(height: 20, width: 20,) : sizedBox(0),
          //                           ],
          //                         ),
          //                       ),
                                
          //                     onTap: () => {
          //                       setState(() {
          //                         versionCheckProgress = true;
          //                       }),
          //                       // checkAppVersion(context)
          //                       // set the global theme
          //                       // setGlobalTheme(!value)
          //                     },
          //                     ),
          //                   // ),


          //           ],
          //         )
                  
          //     ) : sizedBox(0),
            
                  sizedBox(8),
         

        
        ],
      )
      ),
      )
    ),))
    );
  }

  // update user details
  updateDealerDetails(BuildContext context) async{
    
    // final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetailsUpdate()));

    // if(result!=null){

    //   Map<String, dynamic> r =  result;
    //   print(r.keys.length);

    //   updateUserData(r);
    //   // show update message
    //   showToast(context, 'Details updated!');

    // }
  }

  // update user details
    // void updateUserData(Map<String, dynamic> r) async {
    //   // fetch from internal db
    //   final dbHelper = DatabaseInternal.instance;
    //   await dbHelper.update(r);

    //     setState((){
    //         name = r['name'];
    //         mobile = r['mobile'];
    //         email = r['email'];
    //         id = r['id'];
    //         branch = r['branch'];
    //       });
    //   }



  _showModalBottomSheet(BuildContext context, String message){
    showModalBottomSheet(
      
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      
      elevation: 20.0,
      context: context, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0)
        )
      ),
      backgroundColor: Theme.of(context).cardColor,
      constraints: BoxConstraints(
                      // maxHeight: 400.0, // Set the maximum height
                      maxWidth: MediaQuery.of(context).size.width - 20.0
                    ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context){
        return 
            SingleChildScrollView(child: 
            Container(
               margin: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).cardColor,
                      offset: const Offset(0.0, 0.0),
                      blurRadius: 12.0,
                      spreadRadius: 0.3,
                    ),
                  ]
                ),
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sizedBox(8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Disclaimer', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: const BorderRadius.all(Radius.circular(20)),
                            ),
                            child: 
                            InkWell(
                              onTap: () => {
                                    Navigator.pop(context)
                                    },
                              child: Icon(PhosphorIconsBold.x, color: Colors.black54, size: 24,),
                            ),
                          ),
                        ],
                      ),
                    ),
                  sizedBox(16),
                  Text(message, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                  sizedBox(16),
                ],
              ),
              // )
              
            ),
        );
        

    });
  }



  // _updatePhoneNumberBottomSheet(BuildContext context){
  //   String phoneErrorMsg = '';
  //   showModalBottomSheet(
      
  //     isScrollControlled: true,
  //     // useRootNavigator: true,
  //     // isDismissible: false,
  //     enableDrag: false,
  //     // useSafeArea: false,
      
  //     elevation: 20.0,
  //     context: context, 
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(
  //         top: Radius.circular(20.0)
  //       )
  //     ),
  //     backgroundColor: Theme.of(context).cardColor,
  //     constraints: BoxConstraints(
  //                     // maxHeight: 400.0, // Set the maximum height
  //                     maxWidth: MediaQuery.of(context).size.width - 20.0
  //                   ),
  //     clipBehavior: Clip.antiAliasWithSaveLayer,
  //     // builder: (BuildContext context1){
  //       builder: (BuildContext context){
  //         return StatefulBuilder(
  //           builder: (BuildContext context, StateSetter setState) {
  //         return 
            
  //           Container(
  //               margin: const EdgeInsets.all(16),
  //               padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //                 // color: Theme.of(context).cardColor,
  //                 // color: Theme.of(context).cardColor,
  //                 borderRadius: const BorderRadius.all(Radius.circular(10)),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Theme.of(context).cardColor,
  //                     offset: const Offset(0.0, 0.0),
  //                     blurRadius: 12.0,
  //                     spreadRadius: 0.3,
  //                   ),
  //                 ]
  //               ),
              
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 sizedBox(8),
  //                 Container(
  //                   margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
  //                   child: 
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text('Phone number', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
  //                         Container(
  //                           padding: EdgeInsets.all(8),
  //                           decoration: BoxDecoration(
  //                               color: Theme.of(context).shadowColor,
  //                               borderRadius: const BorderRadius.all(Radius.circular(20)),
  //                           ),
  //                           child: 
  //                           InkWell(
  //                             onTap: () => {
  //                                   Navigator.pop(context)
  //                                   },
  //                             child: Icon(PhosphorIconsBold.x, color: Colors.black54, size: 24,),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 sizedBox(16),
  //                 Text('Update your personal mobile number', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
  //                 sizedBox(16),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
                      
  //                     TextFormField(
  //                       controller: mobileController,
  //                       focusNode: otpFocusNode, // Associate the FocusNode with the TextFormField
  //                       keyboardType: TextInputType.number,
  //                       autofocus: true,
  //                       maxLength: 10,
  //                       // style: const TextStyle(letterSpacing: 25),
  //                       decoration: InputDecoration(
  //                         focusedBorder: OutlineInputBorder(
  //                         borderSide: BorderSide(color: Colors.black54),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderSide: BorderSide(color: Colors.black38),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                         hintText: (dealerUser!.mobile!.length > 2) ? dealerUser!.mobile! : 'Phone number',),
  //                       validator: (value) { // validator function is called on calling form validate() method
  //                         if (value!.isEmpty) {
  //                           print('ok');
  //                           return '';
  //                         }
  //                         return null;
  //                       },
  //                       // onSaved: (value) => submittedOTP = value!,
  //                   ),
  //                   sizedBox(4),
  //                   Text('Enter the phone number that is active and in use.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall),),
  //                   Text('Don\'t enter country code like +91.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall),),
  //                   sizedBox(8),
                    
  //                   MaterialButton(
  //                     padding: const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 10.0),
  //                     color: Color(0xFF008060),
  //                     splashColor: Colors.black38,
  //                     colorBrightness: Brightness.dark,
  //                     elevation: 2,
  //                     highlightElevation: 2,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     onPressed: () {
  //                       if(mobileController.text.length == 10){
  //                         setState(() => {
  //                           phoneErrorMsg = ''  
  //                         });
  //                         updatePhoneNumber(context, mobileController.text);
  //                       }
  //                       else {
  //                         setState(() => {
  //                           phoneErrorMsg = 'Enter full phone number'  
  //                         });
  //                       }
  //                       // onSubmit(context);
  //                     },
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         const Icon(PhosphorIconsRegular.paperPlaneRight, size: 12,),
  //                         const SizedBox(width: 8,),
  //                         Text('Update', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white),),
  //                       ],
  //                     ) 
  //                   ),
  //                   sizedBox(4),
  //                   updatePhoneNumberCheckProgress ? const AppProgress(height: 20, width: 20,) : sizedBox(0),
  //                   phoneErrorMsg.isNotEmpty ?  Text(phoneErrorMsg, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red),) : sizedBox(0),
                    
  //                   ]
  //                 )
  //               ],
  //             ),
              
  //           );
        

  //   }
  //   );});
  // }



}

// getting image
Map<String, bool> imageExistenceCache = {}; // A cache to store image existence results


Future<bool> doesImageExist1(String imageUrl) async {

  if (imageExistenceCache.containsKey(imageUrl)) {
    // If the result is already cached, return it
    return imageExistenceCache[imageUrl]!;
  }

  try {
    final response = await http.head(Uri.parse(imageUrl));
    
    final exists = response.statusCode == 200;

    // Cache the result
    imageExistenceCache[imageUrl] = exists;
    
    return exists;
  } catch (e) {
    return false; // An error occurred, or the image doesn't exist
  }
}
Widget getImage(imageUrl, name, width, height){
  return FutureBuilder<bool>(
      future: doesImageExist1(imageUrl),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading state, you can show a loading indicator here.
          
          return Container(
            
            alignment: Alignment.center,
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(strokeWidth: 2,),
          );
          
        } else if (snapshot.hasError || snapshot.data!) {
          // Image doesn't exist, or there was an error while checking.
          
          // Image exists, display it.
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(imageUrl),
              ),
            ),
          );
          
        } else {
          
          return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: Theme.of(context).shadowColor
                    ),
                    
                    alignment: Alignment.center,
                    child: Text(getAcronym('${name}'), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.titleLarge)),
                );
          
        }
      },
    );
    
}

