import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/dealerinvoices_admin.dart';
import 'package:anjanitek/messaging_admin.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/paymentupdate_admin.dart';
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

// this is dealer details screen using the Users data already received
class DealerDetailsAdmin extends StatefulWidget {

  // user object is sent from previous screen
  const DealerDetailsAdmin(this.dealerUser);
  final Users dealerUser;

  @override
  _DealerDetailsAdminState createState() => _DealerDetailsAdminState();
}

class _DealerDetailsAdminState extends State<DealerDetailsAdmin> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String name = '',
  mobile='', email = '-', role = '-', id='', userImage='',gcm_regId='',
  accountName='',dealerId='',salesId='',city='',state='',gst='',address1='',address2='',address3='';
  static int isActive = 1;
  static String updateMsg = '';
  bool versionCheckProgress = false;
  bool refreshCheckProgress = false;
  bool updatePhoneNumberCheckProgress = false;
  String updatePhoneNumberCheckProgressMessage = '';
  List<String> branches = [];
  
  // user object
  Dealers? dealer ;

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
          
          // if(prefs.get(Constants.role) == Constants.dealer){
          //   dealerId = prefs.get(Constants.dealerId) as String;
          //   accountName = prefs.get(Constants.accountName) as String;
          //   salesId = prefs.get(Constants.salesId) as String;
          //   address1 = prefs.get(Constants.address1) as String;
          //   address2 = prefs.get(Constants.address2) as String;
          //   address3 = prefs.get(Constants.address3) as String;
          //   city = prefs.get(Constants.city) as String;
          //   state = prefs.get(Constants.state) as String;
          //   gst = prefs.get(Constants.gst) as String;
          
          
          // }

          
          });
        } 
      refreshUserDealerDetailsAdmin(context);
    }



    // find the user
    void refreshUserDealerDetailsAdmin(BuildContext context) async {

      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      print("${APIUrls.user}${APIUrls.pass}/U4/${widget.dealerUser.id}");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U4/${widget.dealerUser.id}", queryParams)), headers: {"Accept": "application/json"});
      print(result.body);
      
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

    // get the selected theme
    // final themeChange = Provider.of<DarkThemeProvider>(context);
    // bool value = themeChange.darkTheme;
    var theme = Theme.of(context);
    
    Uri facebookUrl;
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

          Column(
          // child: CardRound(Palette.lightBackground, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // sizedBox(24),
              // Image.asset('assets/anjani_title.webp', scale: 2,), 
              AppHeader('Invoices', '', 1),
              // sizedBox(24),
              Text('${widget.dealerUser.name}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.bold), ),
              sizedBox(16),




              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                
                children: [
                  InkWell(
                    onTap: ()=> {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentUpdateAdmin(widget.dealerUser.id!, widget.dealerUser.name!, '-')))
                    },
                  
                  child: Container( 
                    decoration: BoxDecoration(
                      // color: Theme.of(context).shadowColor,
                      color: Color.fromARGB(255, 186, 232, 220),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.all(
                                color: Color(0x33008060), // Set the color of the border here
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const Icon(PhosphorIconsRegular.currencyInr, size: 24,color: Color(0xFF000000),),
                                sizedBox(8,),
                                Text('Update\nCredit', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
                              ],
                            ) 
                    )
                  ),

                  
                  const SizedBox(width: 8,),
                  InkWell(
                    onTap: ()=> {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MessagingAdmin(widget.dealerUser.id!, widget.dealerUser.name!)))
                    },
                  
                  child: 
                      Container( 
                        decoration: BoxDecoration(
                          // color: Theme.of(context).shadowColor,
                          color: Color.fromARGB(255, 186, 232, 220),
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          border: Border.all(
                                    color: Color(0x33008060), // Set the color of the border here
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Icon(PhosphorIconsRegular.notification, size: 24,color: Color(0xFF000000),),
                                    sizedBox(8,),
                                    Text('Send\nReminder', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
                                  ],
                                ) 
                      ),
                  ),
                  const SizedBox(width: 8,),
                  InkWell(
                    onTap: () => {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => DealerInvoicesAdmin(widget.dealerUser!)))
                    },
                    child: 
                      Container( 
                        decoration: BoxDecoration(
                          // color: Theme.of(context).shadowColor,
                          color: Color.fromARGB(255, 186, 232, 220),
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          border: Border.all(
                                    color: Color(0x33008060), // Set the color of the border here
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Icon(PhosphorIconsRegular.receipt, size: 24,color: Color(0xFF000000),),
                                    sizedBox(8,),
                                    Text('View\nInvoices', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center,),
                                  ],
                                ) 
                      )
                  )

                ],
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
              //     onPressed: () => updateDealerDetailsAdmin(context),
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
                           
                                      // String telephoneUrl = "tel:${widget.dealerUser.mobile}";
                                      //   await launchUrlString(telephoneUrl);
                                      
                        },
                        child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.phone, color: Color(0xFF008060), size: 20,),
                                  const SizedBox(width:16),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Mobile', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                      // Text('${widget.dealerUser.mobile}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600)),
                                    ],
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
                          // Clipboard.setData(ClipboardData(text: widget.dealerUser.email!)),
                          showToast(context, 'Email copied!',Constants.success)

                        },
                        child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.envelopeSimple, color: Color(0xFF008060), size: 20),
                              const SizedBox(width:16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Email', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                          // Text('${widget.dealerUser.email}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600)),
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
              (dealer!=null) ? Container(
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
                      Icon(PhosphorIconsRegular.buildings, color: Color(0xFF008060), size: 20,),
                      const SizedBox(width:16),
                      Expanded(
                                  child: 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            
                            // sizedBox(8),
                            Text('Address:', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall)),
                            sizedBox(8),
                            
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (dealer!.address1 != '-') ? Text('${dealer!.address1} ', style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600),overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ) : sizedBox(0),
                                  sizedBox(8),
                                  (dealer!.address2 != '-') ? Text('${dealer!.address2} ', style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                                  sizedBox(8),
                                  (dealer!.address3 != '-') ? Text('${dealer!.address3} ', style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                                ],
                              ),  
                        ],
                      ),
                      )
                  ],
                )
              ) : sizedBox(0),
              
            ],
          
          ),

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
          //             blurRadius: 24.0,
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
          //                         refreshUserDealerDetailsAdmin(context)
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
         
         (dealer!=null) ? 
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            

            child: Column(
              children: <Widget>[
                sizedBox(8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[ 
              Text('Anjani Tek', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.titleMedium, fontSize: 12, color: Colors.black54, )),
              ]),
              sizedBox(48),
              sizedBox(48),
              ],
            )
              
          ) : sizedBox(0)


        
        ],
      )
      ),
      )
    ),))
    );
  }

  // update user details
  updateDealerDetailsAdmin(BuildContext context) async{
    
    // final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetailsAdminUpdate()));

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


  // sign out user
  signOutUser() async {

    // showToast(context, "Signing out!");

    // clear shared preferences
    clearData();
    
    // clear internal db
    // final dbHelper = DatabaseInternal.instance;
    // await dbHelper.deleteAll();

    
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Verification()));

  }
  // Refresh profile
  refreshDealerDetailsAdmin(BuildContext context) async {

    //showToast(context, "Verifying your identity!");
    setState(() {updateMsg = 'Checking for updtes. Please wait...';});
    
    verifyUser(context);

  }


  // show a dialog for updating app version
  updateDialog(BuildContext context1) async {
    
    return showDialog(
        context: context1,
        builder: (context) {
          return AlertDialog(
            icon: Icon((Platform.isAndroid) ? PhosphorIconsRegular.googlePlayLogo : PhosphorIconsRegular.appStoreLogo, color: Colors.black, size: 48, ),
            // icon: Image.asset('assets/app_logo_bg.png',width: 36.0),
            iconPadding: const EdgeInsets.all(16),
            // iconPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            title: Text('Smart Campus App Update',style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.bold) ),    
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [
                Text('New version of app is available.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge) ),    
                sizedBox(8),
                Text('Old version of the app might not function as expected.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, letterSpacing:0.4, fontWeight: FontWeight.w400) ),    
              ],
            ),
      
      backgroundColor: Colors.white,
      elevation: 24,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      actions: [
        InkWell(
            onTap: () => {
                
              // Check the platform.
                if (Platform.isAndroid) {
                  // Navigate to the Play Store.

                  openLink('https://play.google.com/store/apps/details?id=tools.smartcampus.platform&hl=en-IN')
                  // launchUrl(
                  //   Uri.parse('https://play.google.com/store/apps/details?id=tools.smartcampus.platform&hl=en-IN'),
                  // )
                } else if (Platform.isIOS) {
                  // Navigate to the App Store.
                  openLink('https://apps.apple.com/app/id1616440644')
                  // launchUrl(
                  //   Uri.parse('https://apps.apple.com/app/id1616440644'),
                  // )
                }
              },
            child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF008060),
                          Color(0xFF008060),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // sizedBox(8),
                      
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                width: 16,
                                height: 16,
                                  alignment: Alignment.center,
                                  child: Icon(PhosphorIconsBold.arrowRight, color: Color(0xFF008060), size: 12, ),
                              ),
                              const SizedBox(width: 8,),
                              Text('Update now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white)),
                            ],
                        ), 
              ])),
          ),
          Center(
            child: 
        TextButton(
          child: Text('Later', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, letterSpacing:0.4, fontWeight: FontWeight.w400) , textAlign: TextAlign.center),
          onPressed: () {
            // Keep Do Not Disturb on.
            Navigator.pop(context);
          },
        ),)
      ],
    );
        }
    );
  }


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
                      blurRadius: 24.0,
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



  _updatePhoneNumberBottomSheet(BuildContext context){
    String phoneErrorMsg = '';
    showModalBottomSheet(
      
      isScrollControlled: true,
      // useRootNavigator: true,
      // isDismissible: false,
      enableDrag: false,
      // useSafeArea: false,
      
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
      // builder: (BuildContext context1){
        builder: (BuildContext context){
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return 
            
            Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  // color: Theme.of(context).cardColor,
                  // color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).cardColor,
                      offset: const Offset(0.0, 0.0),
                      blurRadius: 24.0,
                      spreadRadius: 0.3,
                    ),
                  ]
                ),
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sizedBox(8),
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                    child: 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phone number', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Theme.of(context).shadowColor,
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
                  Text('Update your personal mobile number', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                  sizedBox(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      TextFormField(
                        controller: mobileController,
                        focusNode: otpFocusNode, // Associate the FocusNode with the TextFormField
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        maxLength: 10,
                        // style: const TextStyle(letterSpacing: 25),
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                          hintText: (mobile.length > 2) ? mobile : 'Phone number',),
                        validator: (value) { // validator function is called on calling form validate() method
                          if (value!.isEmpty) {
                            print('ok');
                            return '';
                          }
                          return null;
                        },
                        // onSaved: (value) => submittedOTP = value!,
                    ),
                    sizedBox(4),
                    Text('Enter the phone number that is active and in use.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall),),
                    Text('Don\'t enter country code like +91.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall),),
                    sizedBox(8),
                    
                    MaterialButton(
                      padding: const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 10.0),
                      color: Color(0xFF008060),
                      splashColor: Colors.black38,
                      colorBrightness: Brightness.dark,
                      elevation: 2,
                      highlightElevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onPressed: () {
                        if(mobileController.text.length == 10){
                          setState(() => {
                            phoneErrorMsg = ''  
                          });
                          updatePhoneNumber(context, mobileController.text);
                        }
                        else {
                          setState(() => {
                            phoneErrorMsg = 'Enter full phone number'  
                          });
                        }
                        // onSubmit(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.paperPlaneRight, size: 12,),
                          const SizedBox(width: 8,),
                          Text('Update', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white),),
                        ],
                      ) 
                    ),
                    sizedBox(4),
                    updatePhoneNumberCheckProgress ? const AppProgress(height: 20, width: 20,) : sizedBox(0),
                    phoneErrorMsg.isNotEmpty ?  Text(phoneErrorMsg, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.red),) : sizedBox(0),
                    
                    ]
                  )
                ],
              ),
              
            );
        

    }
    );});
  }

  _parentDetailsBottomSheet(BuildContext context){
    
    showModalBottomSheet(
      
      isScrollControlled: true,
      // useRootNavigator: true,
      // isDismissible: false,
      enableDrag: false,
      // useSafeArea: true,
      
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
      // builder: (BuildContext context1){
        builder: (BuildContext context){
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return 
            SingleChildScrollView(
              child: 
            Container(
              // color: Colors.black.withOpacity(0.2),
              // padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
              
              // child: Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  // color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      offset: const Offset(0.0, 0.0),
                      blurRadius: 24.0,
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
                          Text('Parents/Guardians', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Theme.of(context).shadowColor,
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
                    sizedBox(8),
                          Text('Contact your campus administrator for updating details.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red)),
                          sizedBox(8),
                  sizedBox(16),
                  
                  
                 Text('Father', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold)),
                  sizedBox(8),
                  
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                enableDrag: true,
                                context: context,
                                builder: (context) => Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.8,
                                  child: getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_1.jpeg?alt=media", 'fatherName', 60.0, 60.0),
                                  
                                ),
                              );
                            },
                            child: 
                            getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_1.jpeg?alt=media", 'fatherName', 60.0, 60.0),
                            
                          ),
                          const SizedBox(width: 16,),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            
                            children: <Widget>[
                              
                              // Text(fatherName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(4),
                              // Text(fatherPhoneNumber, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(8),
                            ],
                          ),
                          ),
                                      
                        // 
                      ],
                    ),
                  
                  sizedBox(16),
                  
                  Text('Mother', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold)),
                  sizedBox(8),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                enableDrag: true,
                                context: context,
                                builder: (context) => Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.8,
                                  child: getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_2.jpeg?alt=media", 'motherName', 60.0, 60.0),
                                  
                                ),
                              );
                            },
                            child: 
                            getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_2.jpeg?alt=media", 'motherName', 60.0, 60.0),
                            
                          ),
                          const SizedBox(width: 16,),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            
                            children: <Widget>[
                              
                              // Text(motherName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(4),
                              // Text(motherPhoneNumber, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(8),
                            ],
                          ),
                          ),
                                      
                        // 
                      ],
                    ),
                  
                  sizedBox(16),
                  
                  Text('Guardian', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold)),
                  sizedBox(8),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                enableDrag: true,
                                context: context,
                                builder: (context) => Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.8,
                                  child: getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_3.jpeg?alt=media", 'guardianName', 60.0, 60.0),
                                  
                                ),
                              );
                            },
                            child: 
                            getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_3.jpeg?alt=media", 'guardianName', 60.0, 60.0),
                            
                          ),
                          const SizedBox(width: 16,),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            
                            children: <Widget>[
                              
                              // Text(guardianName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(4),
                              // Text(guardianPhoneNumber, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(8),
                            ],
                          ),
                          ),
                                      
                        // 
                      ],
                    ),
                    
                  sizedBox(16),

                  Text('Guardian 2', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold)),
                  sizedBox(8),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                enableDrag: true,
                                context: context,
                                builder: (context) => Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.8,
                                  child: getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_4.jpeg?alt=media", 'guardian2Name', 60.0, 60.0),
                                  
                                ),
                              );
                            },
                            child: 
                            getImage("https://firebasestorage.googleapis.com/v0/b/smartcampusimages-1.appspot.com/o/${id}_4.jpeg?alt=media", 'guardian2Name', 60.0, 60.0),
                            
                          ),
                          const SizedBox(width: 16,),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            
                            children: <Widget>[
                              
                              // Text(guardian2Name, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(4),
                              // Text(guardian2PhoneNumber, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(8),
                            ],
                          ),
                          ),
                                      
                        // 
                      ],
                    ),
                  
                  
                  sizedBox(16),
                  
                  Text('Address: $address1', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                  sizedBox(8),
                ],
              ),
              
              ) 
            );
        

    }
    );});
  }


  // show bottom sheet
  _showFullScreenImage(BuildContext context, String image){
    showModalBottomSheet(
      
      context: context, 
      builder: (BuildContext context){
        return 
            SingleChildScrollView(child: 
            Container(
              padding: const EdgeInsets.all(16),
              // height: 300,
              decoration: BoxDecoration(
                
                color: Theme.of(context).canvasColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
              ),
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sizedBox(8),
                  Text('Disclaimer', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),

                  sizedBox(16),
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(image),
                        fit: BoxFit.cover
                      ) ,
                    ),
                  ),
                  sizedBox(16),
                ],
              ),
              
              
            ),
        );
        

    });
  }

  void openLink(String urlString) async {

    String message = 'Hello!'; // Replace this with your message

    Uri url = Uri.parse(urlString);
    
          // await canLaunchUrl(url).then((value) => {
          //   // print(value),
          //   launchUrl(url, mode: LaunchMode.externalNonBrowserApplication),
          // });
  }


  void updatePhoneNumber(BuildContext context1, String newPhoneNumber) async {
      setState(() {
        
        updatePhoneNumberCheckProgress = true;
        updatePhoneNumberCheckProgressMessage = '';
      });
      // check internet connection
      if(await checkInternetConnectivity()){

          // query parameters    
          Map<String, String> queryParams = {
            // "offset":"0",
            };

          // API call
          print("${APIUrls.user}${APIUrls.pass}/U15/$id/$newPhoneNumber");
          var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U15/$id/$newPhoneNumber", queryParams)), headers: {"Accept": "application/json"});
          
          // get the result body which is JSON
          var jsonString = jsonDecode(result.body); 
          // convert jsonString to Map
          var jsonObject = jsonString as Map; 

          setState(() {
            updatePhoneNumberCheckProgress = false;
            updatePhoneNumberCheckProgressMessage = '';
          });
          // check if the api returned success
          if(jsonObject['status'] == 200){
            
            // set the mobile in local profile
            prefs.setString(Constants.mobile, newPhoneNumber);
            setState(() {
              mobile = newPhoneNumber;
            });

            // show success message
            showToast(context1, jsonObject['message'],Constants.success);
            Navigator.pop(context1);
          }
          else if(jsonObject['status'] == 402){
            // Access revoked
            showToast(context1, jsonObject['message'],Constants.error);
            Navigator.pop(context1);
            
          }
          else if(jsonObject['status'] == 404){
            // show the update screen
            showToast(context1, jsonObject['message'],Constants.error);
            Navigator.pop(context1);
          }

      }
      else {
        showToast(context1, 'No internet connection!',Constants.warning);
        Navigator.pop(context1);
      }
  }

      // verify the user details
    void verifyUser(BuildContext context1) async {

      // query parameters    
      Map<String, String> queryParams = {
        "id":id,
        "mobileNumber":mobile
        };

      // API call
      var result = await get(Uri.parse(APIUrls.getUrl(APIUrls.verifyUser, queryParams)), headers: {"Accept": "application/json"});
      
      // get the result body which is JSON
      var jsonString = jsonDecode(result.body); 
      // convert jsonString to Map
      var jsonObject = jsonString as Map; 

      List<Users> list1;
      // check if the api returned success
      if(jsonObject['status'] == 200){
        // get the list data from jsonObject
        var circulars = jsonObject['data'] as List;
        // convert to list
        list1 = circulars.map<Users>((json) => Users.fromJson(json)).toList();

        // not more then 1 user
        if(list1.length == 1 ){
          Users user = list1.elementAt(0);
          // store the user details
          onSuccessSignUp(user, context1);

        }
        
      }
      else {
        // no data exists
        //showToast(context, 'Something went wrong! Sign out and Sign in for smoother experience!');
        setState(() {updateMsg = 'Something went wrong! Sign out and Sign in for smoother experience!'; });
      }

    }


    // save user details locally
    void onSuccessSignUp(Users user, BuildContext context1) async{

      // save into sharedpreferences
/*       SharedPreferences prefs = await SharedPreferences.getInstance();

      prefs.setString(Constants.userObjectId, user.userObjectId);
      prefs.setString(Constants.campusId, user.campusId);
      prefs.setString(Constants.name, user.name);
      prefs.setString(Constants.email, user.email);
      prefs.setString(Constants.id, user.id); 
      prefs.setString(Constants.branch, user.branch); 
      prefs.setString(Constants.mobile, user.mobile); 
      prefs.setString(Constants.role, user.role); 
      prefs.setInt(Constants.year, user.year); 
      prefs.setInt(Constants.mediaCount, user.mediaCount); 
      prefs.setString(Constants.userImage, user.userImage); 
      prefs.setString(Constants.gcmRegId, user.gcmRegId); 
 */
      // save into sharedpreferences
      saveData(user);
      
      // get reference to internal database
      // final dbHelper = DatabaseInternal.instance;

      // do the data mapping
      Map<String, dynamic> row = {
        Constants.name : user.name,
        Constants.email : user.email,
        Constants.id : user.id,
        Constants.mobile : user.mobile,
        Constants.role : user.role,
        Constants.userImage : user.userImage,
        Constants.gcmRegId : user.gcmRegId,
      };

      // insert
      // final id = await dbHelper.insert(row);

      //showToast(context1, "Your profile is up to date. Reopen the app for smooth experience!");
      setState(() {updateMsg = 'Your profile is refreshed. Reopen the app for smooth experience!'; });
        
    }
  

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

