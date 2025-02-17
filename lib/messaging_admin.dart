import 'dart:convert';

import 'package:anjanitek/home.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/utils/app_header.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:device_uuid/device_uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/modals/users.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
// import 'package:anjanitek/utils/utils.dart' as Utils;


class MessagingAdmin extends StatefulWidget {
  const MessagingAdmin(this.receiver, this.name);
  final String receiver, name;

  @override
  _MessagingAdminState createState() => _MessagingAdminState();
  
}

class _MessagingAdminState extends State<MessagingAdmin> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  String? selectedCampus;
  
  TextEditingController messageController = TextEditingController();
  final formKey = GlobalKey<FormState>(); // this is global key to validate form
  String errorMsg = '';
  
  bool checkRegNo = true;

  bool isLoading = false;
  bool optSent=false, verifyOTPLoading = false;
  late SharedPreferences preferences;
  String notificationMessage='', adminId='';
  Users? user;
  Dealers? dealer;

  DateTime today = DateTime.now();
  String _uuid = 'Unknown';
  final _deviceUuidPlugin = DeviceUuid();
  late SharedPreferences prefs;
  

  @override
    void initState() {
     
      _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 300),);
      _controller.forward();
      _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
      _controllerCards.forward();

      super.initState();

      getUsers();
      
    }

    @override
    void dispose() {
      _controller.dispose();
      _controllerCards.dispose();
      super.dispose();
    }

  // on subitting values
    void onSubmit(BuildContext context){
      // validate() methods call the validator functions for all form elements
      if(formKey.currentState!.validate()){ 
        formKey.currentState!.save();

        // verify if collegeId exists and matches with the phoneNumber
        setState(() {
          isLoading = true;
          errorMsg = '';
        });
        // verify if collegeId exists and matches with the phoneNumber
        submitPayment(context);

      }
      else {
        setState(() {
          isLoading = false;
          errorMsg = 'Please provide details';
        });
      }

    }


    // get user details
    void getUsers() async {
      
        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
          // name = prefs.get(Constants.name) as String;
          adminId = prefs.get(Constants.id) as String;
          // email = prefs.get(Constants.email) as String;
          // role = prefs.get(Constants.role) as String;
          // mobile = prefs.get(Constants.mobile) as String;
          // userImage = prefs.get(Constants.userImage) as String;
          // gcm_regId = prefs.get(Constants.gcmRegId) as String;
          // isActive = prefs.get(Constants.isActive) as int;
          

          
          });
        } 
    }



    // find the user
    void submitPayment(BuildContext context) async {
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        // "campusId":selectedCampus!,
        // "collegeId":notificationMessage,
        };
      String sendTo = '';
      if('${widget.receiver}' == 'All'){
        sendTo = 'All';
      }
      else {
        sendTo = widget.receiver;
      }
      // API call 
      // pass, mobile, OTP, deviceId, loginTime
      // print("${APIUrls.submitPayment}${APIUrls.pass}/${notificationMessage.trim()}/$verifyOTP/$_uuid/SMART/${DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(today)}");
      // print("${APIUrls.messaging}${APIUrls.pass}/0/$adminId/$sendTo/${DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(DateTime.now())}/${notificationMessage.trim()}/0/-");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.messaging}${APIUrls.pass}/0/$adminId/$sendTo/${DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(DateTime.now())}/${notificationMessage.trim()}/0/-", queryParams)), headers: {"Accept": "application/json"});
      
      // Decode the JSON string into a Map using the jsonDecode function
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      // user object list
      
      // check if the api returned success
      if(jsonObject['status'] == 200){

          setState(() {
            // OTP sent
            isLoading = false;
            errorMsg = '';
            
          });

          showToast(context, 'Message sent!',Constants.success);
          messageController.text = ''; //clear();

      }
      else if(jsonObject['status'] == 401 || jsonObject['status'] == 402 || jsonObject['status'] == 404 || jsonObject['status'] == 500){
        // no data exists
        setState(() {
          // get the error message
          isLoading = false;
          errorMsg = jsonObject['message'];
        });
        
      }
      else {

          setState(() {
            isLoading = false;
            errorMsg = 'Sorry, facing issues. Try again later';
          });
      }
        

      //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Verifying...'), duration: Duration(seconds: 2),));
      
    }

    
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      // extendBodyBehindAppBar: false,
      // extendBody: false,
      // backgroundColor: Theme.of(context).cardColor,
        body: 
        // BackgroundScreen( safeArea:
                SafeArea(
                  
                  child: SingleChildScrollView(
                  child: 
                  Container(
                    // margin: const EdgeInsets.all(16.0),
                    // decoration: BoxDecoration(
                    //   gradient: LinearGradient(
                    //     begin: Alignment.topCenter,
                    //     end: Alignment.bottomCenter,
                    //     colors: [
                    //     Color(0xFFFFC7E2),
                    //     Color(0xFFFAC6BD),
                    //   ]),
                    //   // color: Colors.black,
                    //   // color: Palette.white,
                    //   borderRadius: const BorderRadius.only(
                    //                 topLeft: Radius.circular(12.0),
                    //                 topRight: Radius.circular(12.0),
                    //                 bottomLeft: Radius.circular(12.0),
                    //                 bottomRight: Radius.circular(12.0),
                    //   ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.grey.withOpacity(0.5),
                    //     spreadRadius: 2,
                    //     blurRadius: 20.0,
                    //     offset: Offset(0,3),
                    //   )
                    // ],
                    // ),
                
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Form(
                      key: formKey,
                      child: 
                      
                      FadeTransition(opacity: _controller,
                child:
                ScaleTransition(scale: CurvedAnimation(
                                parent: _controllerCards,
                                curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                              ),alignment: Alignment.center,
                  child:
                      Container(
                        // decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(16),
                        //       color: Colors.white,
                        //       // color: Theme.of(context).cardColor.withOpacity(0.8),
                        //       // gradient: LinearGradient(
                        //       //     begin: Alignment.topCenter,
                        //       //     end: Alignment.bottomCenter,
                        //       //     colors: [
                        //       //     Colors.white.withOpacity(0.8),
                        //       //     Colors.white,
                        //       //   ]),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           color: Theme.of(context).shadowColor,
                        //           offset: const Offset(1.0, 1.0),
                        //           blurRadius: 12.0,
                        //           spreadRadius: 0.3,
                        //         ),
                        //     ]
                        //   ),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        margin: const EdgeInsets.all(24.0),

                        child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image.asset('assets/anjani_title.webp', scale: 2,), 
                          AppHeader('Invoices', '', 1),
                          sizedBox(24),
                          Text('Broadcast Message', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.bold, color:Color(0xFF008060)), ),
                          sizedBox(4),
                          Text('to', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.bold), ),
                          sizedBox(4),
                          ('${widget.receiver}' == 'All') ? 
                          Text('All dealers', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold), )
                          : Text('${widget.name}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold), ),
                          // Text('Entire campus in your pocket', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium),),
                          // Text('Login via OTP', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium),),
                          sizedBox(16),
                          

                          // sizedBox(16),
                          
                          Container(
                            
                            child: TextFormField(
                              maxLines: 4,
                              maxLength: 120,
                              textAlign: TextAlign.left,
                              controller: messageController,
                              keyboardType: TextInputType.text,
                              autofocus: true,
                              // textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFF5F5F5),
                                focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                                hintText: 'Enter message',
                                ),
                              validator: (value) { // validator function is called on calling form validate() method
                                if (value!.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                              onSaved: (value) => notificationMessage = value!,
                              style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w500, letterSpacing: 0.5),
                            ),
                          ),

                          // sizedBox(16),

                          
                          sizedBox(4),
                          errorMsg.isNotEmpty ? 
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget> [
                                sizedBox(16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(10),
                                    
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child:
                                  Text(errorMsg, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall))
                                )
                              ],
                            ): sizedBox(0),
                          

                          
                              // show UI for checking registration number
                              checkRegNo ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sizedBox(16),
                                  // show Sign in button
                                  (isLoading) ? sizedBox(0) : MaterialButton(
                                        padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 12.0),
                                        color: Color(0xFF008060),
                                        splashColor: Colors.black38,
                                        colorBrightness: Brightness.dark,
                                        elevation: 2,
                                        highlightElevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        onPressed: (){
                                          onSubmit(context);
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Icon(PhosphorIconsFill.paperPlaneRight, size: 16,),
                                            const SizedBox(width: 8,),
                                            Text('Submit', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, color: Colors.white),),
                                          ],
                                        ) 
                                      ),

                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: (isLoading) ? const AppProgress(height: 30, width: 30,) : const SizedBox(height: 0,),
                                      ),
                                ],
                              ) : sizedBox(0),


                              checkRegNo ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sizedBox(16),
                                  // show Sign in button
                                  (isLoading) ? sizedBox(0) : MaterialButton(
                                        padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 12.0),
                                        color: Color(0xFFD4D4D4),
                                        splashColor: Colors.black38,
                                        colorBrightness: Brightness.dark,
                                        elevation: 2,
                                        highlightElevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        onPressed: (){
                                          Navigator.pop(context);
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            // const Icon(PhosphorIconsFill.arrowLeft, size: 16,color:Colors.black54),
                                            // const SizedBox(width: 8,),
                                            Text('Cancel', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, color: Colors.black54),),
                                          ],
                                        ) 
                                      ),

                                      
                                ],
                              ) : sizedBox(0),
                        ],
                      ),
                      ),
                    ))
                    ),
                    // sizedBox(16),
                    
                    Container(
                      margin: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                            padding: const EdgeInsets.all(8.0),
                            //child: styledText('Contact your campus adminstration for credentials incase you do not have them.', Constants.body2, Constants.darkbg),
                            
                            child: Column(children: <Widget>[
                              Text('All dealers will receive this message in the app', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium),),
                              // Text('Your campus is not listed here?', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.caption),),
                              sizedBox(16),
                              
                              // MaterialButton(
                              //   padding: const EdgeInsets.all(8.0),
                              //   color: Palette.appBackgroundSolitude,
                              //   splashColor: Palette.primary,
                              //   colorBrightness: Brightness.light,
                              //   shape: const StadiumBorder(),

                              //   onPressed: (){
                                
                              //     // _launchURL();

                              //   },
                              //   child: const Text('Register Now'),
                              // ),
                              
                            ],)
                            
                            
                          )
                  ],
                )
                  
                
              ),
              ),
            )
        // )      
      );
        
  }

}


    
  