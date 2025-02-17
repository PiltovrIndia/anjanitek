import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/no_login_experience.dart';
import 'package:anjanitek/utils/database_helper.dart';
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
import 'package:url_launcher/url_launcher.dart';

// this is 
class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {

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
  Users? user ;

  TextEditingController mobileController = TextEditingController();
  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  
  DatabaseHelper dbHelper = DatabaseHelper();
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
        await dbHelper.initDb();
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
      // }
      /*allRows.forEach((row) => {
        if(row['userObjectId'].toString().contains('yeswe02')){
          
          setState((){
            name = allRows[0]['name'];
            mobile = row['mobile'];
            email = row['email'];
            id = row['id'];
            branch = row['branch'];
          })
        }
      });*/
    }



    // find the user
    void refreshUserProfile(BuildContext context) async {

      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      // print("${APIUrls.user}${APIUrls.pass}/U14/$mobile");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U14/$mobile", queryParams)), headers: {"Accept": "application/json"});
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
            user = Users.fromJson(userdata);
            refreshCheckProgress = false;
          });

          bool val = await saveData(Users.fromJson(userdata));
          if(user!.role == Constants.dealer){
              Map<String, dynamic> dealerdata = jsonObject['data1'];
             await saveDealerData(Dealers.fromJson(dealerdata));
          }

          if(val){
            showToast(context, 'Your profile is now updated!', Constants.success);
            getUsers();
          }
        
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
        margin: EdgeInsets.fromLTRB(16,0,16,16),
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
              Text('Profile', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
              sizedBox(16),
              
              ScaleTransition(scale: CurvedAnimation(
                                    parent: _controllerCards,
                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                  ),alignment: Alignment.bottomCenter,
                                  child:

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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child:  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                                  width: 100,
                                    height: 100,
                                    padding: const EdgeInsets.all(0),
                                     
                                    decoration: const BoxDecoration(
                                      color: Color(0x33008060),//Colors.black12,
                                      // border: Border.all(
                                      //           color: Colors.black, // Set the color of the border here
                                      //           width: 1, // Set the width of the border here
                                      //         ),
                                        shape: BoxShape.circle,
                                        // gradient: LinearGradient(
                                        //     colors: [
                                        //       Color(0xFFFFC7E2),
                                        //       Color(0xFFFAC6BD),
                                        //     ],
                                        //     begin: FractionalOffset(0.0, 0.0),
                                        //     end: FractionalOffset(1.0, 0.0),
                                        //     stops: [0.0, 1.0],
                                        //     tileMode: TileMode.clamp),
                                      ),
                                      alignment: Alignment.center,
                                      child: 
                                      (userImage.length > 2) ? 
                                        InkWell(
                                          // onTap: () => {_showFullScreenImage(context, userImage),
                                            onTap: () => {                                  
                                              showModalBottomSheet(
                                                enableDrag: true,
                                                context: context,
                                                builder: (context) => Container(
                                                  width: MediaQuery.of(context).size.width,
                                                  height: MediaQuery.of(context).size.height * 0.8,
                                                  child: Image.network(userImage, width: MediaQuery.of(context).size.width,),
                                                ),
                                              )
                                          // Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenPage(userImage)))
                                          
                                        },
                                        child:
                                        Container(
                                          width: 200,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(userImage),
                                            ),
                                          ),
                                        ) 
                                        )
                                        : Text(getAcronym(name).toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.titleLarge, fontWeight: FontWeight.w600, fontSize: 36, color: Colors.black)),
                                ),
                                sizedBox(16),
                                Text(name, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.bold)),
                                
                                Text('${role.toUpperCase()}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF008060), fontWeight: FontWeight.bold)),
                                // Text('AnjaniTek Tiles', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF008060), fontWeight: FontWeight.bold)),
                                sizedBox(16),Text(id, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, fontWeight: FontWeight.bold)),

                      // sizedBox(8),
                      // Text(id, style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)),
                      // sizedBox(8),
                      
                      sizedBox(8),
                      
                      // // sizedBox(8),
                      // (role == Constants.dealer) ? Text('Address:', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall))
                      //   : sizedBox(0),
                      
                      // (role == Constants.dealer) ? 
                      //   Column(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       (address1 != '-') ? Text('$address1 ', style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                            
                      //       (address2 != '-') ? Text('$address2 ', style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                            
                      //       (address3 != '-') ? Text('$address3 ', style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600)) : sizedBox(0),
                      //     ],
                      //   ) 
                      //   : sizedBox(0),
                      
                      // sizedBox(8),
                      


                      ]),
              ),
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
              //     onPressed: () => updateProfile(context),
              //   ),
              sizedBox(8),
              
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
                        onTap: () {
                          // FocusScope.of(context).requestFocus(otpFocusNode),
                          _updatePhoneNumberBottomSheet(context);
                        },
                        child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.phone, color: Colors.black, size: 24),
                              const SizedBox(width:16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Phone', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                                          Text(mobile, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                  ]),
                              )
                              
                            ],
                          ),
                        
                      ),
                      sizedBox(4),
                      divider(Colors.black26),
                      sizedBox(4),
                      Row(
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
                                          Text(email, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                  ]),
                              )
                              
                            ],
                          ),
                      
                      
                    ],
                  ),
                  ),
                ),
              ),


              sizedBox(8),
              (role.toLowerCase() == Constants.dealer.toLowerCase()) ? Container(
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
                child: 
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon(PhosphorIconsRegular.buildings, color: Color(0xFF008060), size: 20,),
                      Icon(PhosphorIconsRegular.mapPin, color: Colors.black, size: 24),
                      const SizedBox(width:16),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              
                              // sizedBox(8),
                              Text('Address:', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              sizedBox(8),
                              
                              (role == Constants.dealer) ? 
                              
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    (address1 != '-') ? Text('$address1 ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, letterSpacing: 1, fontWeight: FontWeight.w600) ) : sizedBox(0),
                                    sizedBox(8),
                                    (address2 != '-') ? Text('$address2 ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, letterSpacing: 1, fontWeight: FontWeight.w600)) : sizedBox(0),
                                    sizedBox(8),
                                    (address3 != '-') ? Text('$address3 ', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, letterSpacing: 1, fontWeight: FontWeight.w600)) : sizedBox(0),
                                  ],
                                ) 
                                : sizedBox(0),  
                          ],
                        )
                      ),
                  ],
                )
              ) : sizedBox(0),
              
            ],
          
          ),

          sizedBox(16),
          Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[ 
              Text('Reach out to us to update any details', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.bold, color: Colors.red, )),
              ]),
          sizedBox(16),


          // profile actions
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
                  child: 
                  Column(
                    children: [
                                InkWell(
                                  
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                    child:
                                    Row(
                                      children: [
                                        Icon(PhosphorIconsRegular.arrowClockwise, color: Color(0xFF008060), size: 24,),
                                        const SizedBox(width:16),
                                        Text('Refresh profile', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black)),
                                        refreshCheckProgress ? const AppProgress(height: 20, width: 20,) : sizedBox(0),
                                      ],
                                    ),
                                  ),
                                  
                                onTap: () => {
                                  setState(() {
                                    refreshCheckProgress = true;
                                  }),
                                  refreshUserProfile(context)
                                  // set the global theme
                                  // setGlobalTheme(!value)
                                },
                                ),
                             
                              // divider(Colors.black26),

                              // InkWell(
                                
                              //   child: Container(
                              //     padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                              //     child:
                              //     Row(
                              //       children: [
                              //         Icon((Platform.isAndroid ? PhosphorIconsRegular.googlePlayLogo : PhosphorIconsRegular.appStoreLogo), color: Color(0xFF008060), size: 20,),
                              //         const SizedBox(width:16),
                              //         Text('Check for app update', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)),
                              //         versionCheckProgress ? const AppProgress(height: 20, width: 20,) : sizedBox(0),
                              //       ],
                              //     ),
                              //   ),
                                
                              // onTap: () => {
                              //   setState(() {
                              //     versionCheckProgress = true;
                              //   }),
                              //   checkAppVersion(context)
                              //   // set the global theme
                              //   // setGlobalTheme(!value)
                              // },
                              // ),
                            // ),


                    ],
                  )
                  
              ),
         
              sizedBox(8),

              // social links
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
                      child: 
                      Column(
                        children: [

                          /// App Feedback
                                // CardRound(Theme.of(context).cardColor,
                                  //   InkWell(
                                      
                                  //     child: Container(
                                  //       padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                  //       child:
                                  //       Row(
                                  //         children: [
                                  //           Icon(PhosphorIconsBold.thumbsUp, color: Color(0xFF008060), size: 24,),
                                  //           const SizedBox(width:16),
                                  //           Text('Give app feedback', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black)),
                                  //         ],
                                  //       ),
                                  //     ),
                                      
                                  //   onTap: () => {
                                      
                                  //     // App feedback link
                                  //     // google forms from HelpMeCode – Smart Campus Platform Feedback
                                  //     // launchUrl(
                                  //     //     Uri.parse('https://forms.gle/4Q5aVeHmuCkA17Qf6'),mode: LaunchMode.externalApplication
                                  //     //   )
                                  //   },
                                  //   ),
                                  // // ),

                                  // divider(Colors.black26),
                                
                                // Rate on Play Store or App Store
                                // CardRound(Theme.of(context).cardColor,
                                    InkWell(
                                      
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                        child:
                                        Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.star, color: Color(0xFF008060), size: 24,),
                                            const SizedBox(width:16),
                                            Text('Rate this App', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                                          ],
                                        ),
                                      ),
                                      
                                    onTap: () => {
                                      
                                      // Check the platform.
                                      if (Platform.isAndroid) {
                                        // Navigate to the Play Store.
                                        launchUrl(
                                          Uri.parse('https://play.google.com/store/apps/details?id=com.anjanitek'), mode: LaunchMode.externalNonBrowserApplication,
                                        )
                                      } 
                                      else if (Platform.isIOS) {
                                        // Navigate to the App Store.
                                        launchUrl(
                                          Uri.parse('https://apps.apple.com/app/id6498621857')
                                        )
                                      }
                                    },
                                    ),
                                  // ),

                                  divider(Colors.black26),
                                
                                  // Follow on Facebook
                                  // CardRound(Theme.of(context).cardColor,
                                    InkWell(
                                      
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                        child:
                                        Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.instagramLogo, color: Color(0xFF008060), size: 24,),
                                            const SizedBox(width:16),
                                            Text('Follow @AnjaniTek', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                                          ],
                                        ),
                                      ),
                                      
                                    onTap: () => {
                                      facebookUrl = Uri.parse('https://www.instagram.com/anjanitek/'),
                                      //  if(await canLaunchUrl(facebookUrl)){
                                      //   await launchUrl(facebookUrl)
                                      //  }else {
                                      //   print()
                                      //  }
                                      
                                      launchUrl(facebookUrl, mode: LaunchMode.externalApplication),
                                      //  await canLaunchUrl(facebookUrl).then((value) => {
                                      //     print(value),
                                      //     // launchUrl(facebookUrl),
                                      //     // launchUrl(facebookUrl, mode: LaunchMode.platformDefault),
                                      //     launchUrl(facebookUrl, mode: LaunchMode.inAppWebView),
                                      //   }).onError((error, stackTrace) => {
                                      //     print('errorrɽerrorrɽerrorrɽerrorrɽerrorrɽerrorrɽ'),
                                      //     print(error),
                                      //   }),
                                      // launchUrl(
                                      //     Uri.parse('https://www.facebook.com/profile.php?id=61553276720288'),
                                      //   )
                                    },
                                    ),
                                  // ),
                               
                        ],
                      )
                      
                  ),
            
                  sizedBox(8),
              
              // social links
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
                      child: 
                      Column(
                        children: [

                          
                                    Container(
                                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                        child:
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Icon(PhosphorIconsRegular.thumbsUp, color: Colors.black54, size: 20,),
                                            Text(Platform.operatingSystem+ ' App Version', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                                            const SizedBox(width:16),
                                            Text('${Platform.isAndroid ? Constants.sc_app_version : Constants.sc_app_version_ios}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                      
                                    
                                  // ),

                                  
                                  divider(Colors.black26),
                                
                                  // Follow on Facebook
                                  // CardRound(Theme.of(context).cardColor,
                                    InkWell(
                                      
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                        child:
                                        Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.info, color: Color(0xFF008060), size: 24,),
                                            const SizedBox(width:14),
                                            Text('Disclaimer', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                                          ],
                                        ),
                                      ),
                                      
                                    onTap: () => {_showModalBottomSheet(context, Constants.disclaimer)},
                                    ),
                                  // ),
                                  
                                  
                                  divider(Colors.black26),
                                
                                  // Follow on Facebook
                                  // CardRound(Theme.of(context).cardColor,
                                    InkWell(
                                      
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                        child:
                                        Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.signOut, color: Colors.red, size: 24,),
                                            const SizedBox(width:14),
                                            Text('Sign out', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                      
                                    onTap: () => signOutUser(),
                                    ),
                                  // ),
                                  
                                

                        ],
                      )
                      
                  ),
            
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
          //                     refreshProfile(context),
                            
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


  void checkAppVersion(BuildContext context1) async {
      setState(() {
        versionCheckProgress = true;
      });
      // check internet connection
      if(await checkInternetConnectivity()){

        String appVersion = Constants.sc_app_version;
        // query parameters    
        Map<String, String> queryParams = {
          // "offset":"0",
          };

        // API call
        // print("${APIUrls.appVersion}${APIUrls.pass}/$appVersion/$id");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.appVersion}${APIUrls.pass}/$appVersion/$id", queryParams)), headers: {"Accept": "application/json"});
        
        // get the result body which is JSON
        var jsonString = jsonDecode(result.body); 
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 

        setState(() {
          versionCheckProgress = false;
        });
        // check if the api returned success
        if(jsonObject['status'] == 200){
          // do nothing
          showToast(context, 'Your app is upto date!',Constants.success);
        }
        else if(jsonObject['status'] == 402){
          // Access revoked
          showToast(context1, jsonObject['message'],Constants.error);
          Navigator.pop(context1);
          // Navigator.push(context1, MaterialPageRoute(builder: (context) => AccessRevoked()));
          
        }
        else if(jsonObject['status'] == 404){
          // show the update screen
          updateDialog(context1);
        }
      }
      else {
        showToast(context, 'No internet connection!',Constants.warning);
      }
  }

  // update user details
  updateProfile(BuildContext context) async{
    
    // final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileUpdate()));

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
    await OneSignal.logout().whenComplete(() {

    });

    // clear shared preferences
    clearData();
    await dbHelper.deleteAllNotifications();

    
    // clear internal db
    // final dbHelper = DatabaseInternal.instance;
    // await dbHelper.deleteAll();

    
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnjaniTekApp()));
    // await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Verification()));

  }
  // Refresh profile
  refreshProfile(BuildContext context) async {

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
      backgroundColor: Colors.white,
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
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Theme.of(context).cardColor,
                  //     offset: const Offset(0.0, 0.0),
                  //     blurRadius: 24.0,
                  //     spreadRadius: 0.3,
                  //   ),
                  // ]
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
                          Text('Disclaimer', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 24, fontWeight: FontWeight.w500)),
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
                          Text('Phone number', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.displayMedium)),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
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
                  Text('Disclaimer', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.displayMedium)),

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
          // print("${APIUrls.user}${APIUrls.pass}/U15/$id/$newPhoneNumber");
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

