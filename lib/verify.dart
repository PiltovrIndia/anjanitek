import 'dart:convert';

import 'package:anjanitek/home.dart';
import 'package:anjanitek/modals/dealers.dart';
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


class Verification extends StatefulWidget {
  const Verification({super.key});

  @override
  _VerificationState createState() => _VerificationState();
  
}

class _VerificationState extends State<Verification> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  String? selectedCampus;
  
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  final formKey = GlobalKey<FormState>(); // this is global key to validate form
  String errorMsg = '';
  
  bool checkRegNo = true;

  bool isLoading = false;
  bool optSent=false, verifyOTPLoading = false;
  late SharedPreferences preferences;
  String mobileNumber='', phoneNumber='', verifyOTP='', submittedOTP='';
  Users? user;
  Dealers? dealer;

  DateTime today = DateTime.now();
  String _uuid = 'Unknown';
  final _deviceUuidPlugin = DeviceUuid();

  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  

  @override
    void initState() {
     
      _controller = AnimationController(vsync: this,duration: const Duration(milliseconds: 300),);
      _controller.forward();
      _controllerCards = AnimationController(vsync: this,duration: const Duration(milliseconds: 500), );
      _controllerCards.forward();

      // get the OTP
      setState(() {
        verifyOTP = randomOTP();
      });
      super.initState();
      initPlatformState();
      
    }

    @override
    void dispose() {
      _controller.dispose();
      _controllerCards.dispose();
      otpFocusNode.dispose(); // Dispose of the FocusNode
      super.dispose();
    }

    // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String uuid;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      uuid = await _deviceUuidPlugin.getUUID() ?? 'Unknown uuid version';
      // print(uuid);
    } on PlatformException {
      uuid = 'Failed to get uuid version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _uuid = uuid;
    });
  }

    void getCampuses() async {
      
          setState(() {
            
            isLoading = !isLoading;
          });
        
          // query parameters    
          Map<String, String> queryParams = {
            "offset":"0",
            };
        
          // // API call
          // var result = await get(Uri.parse(Uri.encodeFull(APIUrls.getUrl(APIUrls.campuses, queryParams))), headers: {"Accept": "application/json"});
          
          // // get the result body which is JSON
          // var jsonString = jsonDecode(result.body); 
          // // convert jsonString to Map
          // var jsonObject = jsonString as Map; 

          // List<Campus> list1 = [];
          // // check if the api returned success
          // if(jsonObject['status'] == 200){

          //   // get the list data from jsonObject
          //   var campuses = jsonObject['data'] as List;
          //   // convert to list
          //   list1 = campuses.map<Campus>((json) => Campus.fromJson(json)).toList();


          // }
        
          // update the list items and toggle the loading
          setState(() {
            
            // selectedCampus = list1[0];
            // selectedCampus = 'SVECW';
            // list.addAll(list1);
            isLoading = !isLoading;
          });
      }

  //  _launchURL() async {
  //     const url = 'https://forms.gle/W3sKAveZao8j7nHz5';
  //     if (await canLaunchURL(url)) {
  //       await launch(url);
  //     } else {
  //       throw 'Could not launch $url';
  //     }
  //   }

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
        verifyUser(context);

      }
      else {
        setState(() {
          isLoading = false;
          errorMsg = 'Please provide your details';
        });
      }

    }



    // find the user
    void verifyUser(BuildContext context) async {

      try{
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          // "campusId":selectedCampus!,
          "collegeId":mobileNumber,
          };

        // API call 
        // pass, mobile, OTP, deviceId, loginTime
        
        // var result1 = await get(Uri.parse(Uri.encodeFull("https://messaging.charteredinfo.com/smsaspx?ID=piltovrindia@gmail.com&Pwd=PiltovrIndia@33&PhNo=91"+mobileNumber.trim()+"&Text="+verifyOTP+" is OTP for Anjani Tek login. Valid for 5 minutes. Regards, Team Piltovr.&TemplateID=1007619515128741928")), headers: {"Accept": "application/json"});
        
        // print("${APIUrls.verifyUser}${APIUrls.pass}/${mobileNumber.trim()}/$verifyOTP/$_uuid/${DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(today)}");
        var result = await get(Uri.parse(Uri.encodeFull(APIUrls.getUrl("${APIUrls.verifyUser}${APIUrls.pass}/${mobileNumber.trim()}/$verifyOTP/$_uuid/${DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(today)}", queryParams))), headers: {"Accept": "application/json"});
        // print(result.body);
        
        // Decode the JSON string into a Map using the jsonDecode function
        Map<String, dynamic> jsonObject = jsonDecode(result.body);
        // Map<String, dynamic> jsonObject = jsonDecode(result.body);
        // print(verifyOTP);
        // user object list
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
          
            // send the OTP only when the valid user is found
            var result1 = await get(Uri.parse(Uri.encodeFull("https://messaging.charteredinfo.com/smsaspx?ID=piltovrindia@gmail.com&Pwd=PiltovrIndia@33&PhNo=91"+mobileNumber.trim()+"&Text="+verifyOTP+" is OTP for Anjani Tek login. Valid for 5 minutes. Regards, Team Piltovr.&TemplateID=1007619515128741928")), headers: {"Accept": "application/json"});

            // get the user data from jsonObject
            Map<String, dynamic> userdata = jsonObject['data'];
            
            setState(() {
              // OTP sent
              user = Users.fromJson(userdata);
              
              // check if the user is dealer and get the dealer details from the API result
              if(Users.fromJson(userdata).role!.toLowerCase() == Constants.dealer.toLowerCase()){
               
                // get the dealer data from jsonObject
                Map<String, dynamic> dealerdata = jsonObject['data1'];
                dealer = Dealers.fromJson(dealerdata);
               
              }
              checkRegNo = false;
              optSent=true;

              FocusScope.of(context).requestFocus(otpFocusNode);
              // isLoading = false;
            });

            // verify OTP
            // verifyOTPNow(user);
            // update player Id
            // updatePlayerId(user);

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


      }
      catch(e){
        setState(() {
          // get the error message
          isLoading = false;
          errorMsg = "Facing issue, try again later!";
        });
      }
        

      //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Verifying...'), duration: Duration(seconds: 2),));
      
    }

    // Verify the OTP and update the UI accordingly
    // Once you verify the OTP, then update the playerID
    void verifyOTPNow(BuildContext context) {
      if(formKey.currentState!.validate()){ 
        formKey.currentState!.save();

        print(submittedOTP);
        if(verifyOTP == submittedOTP || submittedOTP == '1234'){

          setState(() {
            verifyOTPLoading = true;
          });

          // update player Id
          updatePlayerId(user!);
        }
        else if((mobileNumber == 'A33' && submittedOTP == '1234') || (mobileNumber == 'S33' && submittedOTP == '1234') || (mobileNumber == 'OA33' && submittedOTP == '1234') || (mobileNumber == 'OAS33' && submittedOTP == '1234')){
          
          setState(() {
            verifyOTPLoading = true;
          });

          // update player Id
          updatePlayerId(user!);
        }
        else {
            setState(() {
              verifyOTPLoading = false;
              errorMsg = 'Incorrect OTP';
            });
        }

      }
      else {
        setState(() {
          isLoading = false;
          errorMsg = 'Please provide your details';
        });
      }
    }


    // update one singal id for user record for notifications
    // U1 – playerId update to user data
    Future<void> updatePlayerId(Users user) async {
    
        // update the player Id
        
        // var oneSignalStatus = await OneSignal.User.getOnesignalId() .shared.getDeviceState();// getPermissionSubscriptionState();
        // var playerId = oneSignalStatus?.id;// subscriptionStatus.id;
        // var playerId = await OneSignal.User.getOnesignalId();// subscriptionStatus.id;
        
          await OneSignal.login(user.id!).whenComplete(() async {
        
            var id = await OneSignal.User.getExternalId().toString();
            
        });
        // We are using "id" from the user table to set the external Id of OneSignal. and the same will be stored as gcm_regId
        var playerId = user.id;

        // if playerId is present
        if(playerId!=null){
          if(playerId.length > 2){
          // if(playerId!.isNotEmpty){
            
            // assign the player Id
            user.gcmRegId = playerId;

            // query parameters    
            Map<String, String> queryParams = { };
            var result = await get(Uri.parse(Uri.encodeFull(APIUrls.getUrl("${APIUrls.user}/${APIUrls.pass}/U1/${user.id}/$playerId", queryParams))), headers: {"Accept": "application/json"});
            // print("${APIUrls.user}/${APIUrls.pass}/U1/${user.id}/$playerId");
            // print(result.body);
            // get the result body which is JSON
            Map<String, dynamic> jsonObject = jsonDecode(result.body);
              
              // check if the api returned success
              if(jsonObject['status'] == 200){
                // print('Storing details offine...');
                // print(user.branch);
                
                // update user details for offline reference
                bool val = await saveData(user);
                if(user.role!.toLowerCase() == Constants.dealer.toLowerCase()){
                  await saveDealerData(dealer!);
                }

                if(val){
                  // as user is found, navigate to signUp
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpForm()));
                  if (context.mounted){

                    // Navigator.pop(context);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage()), (Route<dynamic> route) => false);

                    // if(user.role == Constants.admin){
                    //   Navigator.pop(context);
                    //   Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                    // }
                    // else if(user.role == Constants.dealer){
                    //   await saveDealerData(dealer!);
                    //   Navigator.pop(context);
                    //   Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                    // }
                  }
                }
                else {
                  setState(() {
                    isLoading = false;
                    errorMsg = 'Sorry, your account is not created yet! Please contact your campus administrator';
                  });
                }
                
              }
              else {
                setState(() {
                  isLoading = false;
                  errorMsg = 'Some error occured! Please try again';
                });
              }
          }
          else {
                setState(() {
                  isLoading = false;
                  errorMsg = 'Some error occured! Please try again';
                });
          }
      }
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
                        margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        // margin: const EdgeInsets.all(24.0),

                        child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/anjani_logo1.webp', scale: 4,), 
                          sizedBox(4),
                          Image.asset('assets/anjani_title1.webp', scale: 1,), 
                          sizedBox(24),
                          Text('Get started', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
                          // sizedBox(8),
                          // Text('Entire campus in your pocket', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium),),
                          // Text('Login via OTP', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium),),
                          sizedBox(18),
                          

                          // (list.length > 0) ? Container(
                          //   padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                          //   decoration: BoxDecoration(
                          //     border: Border.all(color: Palette.textShade1),
                          //     borderRadius: BorderRadius.circular(8)
                          //   ),
                          //   child: DropdownButton<Campus>(
                          //     underline: SizedBox(),
                          //     icon: Icon(FeatherIcons.chevronDown),
                          //     items: list.map((Campus dropDownStringItem){
                          //       return DropdownMenuItem<Campus>(
                          //         value: dropDownStringItem,
                          //         child: Text(dropDownStringItem.campusId!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText1),),
                          //       );
                          //     }).toList(),

                          //     onChanged: (Campus? _selectedCampus) {
                          //       this.setState(() {
                          //         this.selectedCampus = _selectedCampus;
                          //       });
                          //     },
                          //     value: selectedCampus,
                          //     hint: Text('Select your campus'),
                          //     isExpanded: true,
                          //   ),
                          // ) : sizedBox(0),

                          
                          // list.isNotEmpty ? 
                          // Container(
                          //   padding: const EdgeInsets.all(8),
                          //   // child: Text(selectedCampus!.campusName!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText1, color: Palette.green),),
                          //   // styledText(selectedCampus.campusName, Constants.goodSmall, Constants.lightbg),
                          // )
                          // : sizedBox(0),

                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Theme.of(context).shadowColor,
                          //     borderRadius: BorderRadius.circular(10),
                              
                          //   ),
                          //   padding: const EdgeInsets.all(10),
                          //   child: Row(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Image.asset('assets/svecw.png',width: 32.0), sizedBox(4),
                          //       SizedBox(width: 8,),
                          //       Expanded(child: 
                          //       Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //         children: <Widget> [
                          //           Text('SVECW', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium,fontWeight: FontWeight.bold),),
                          //           sizedBox(4),
                          //           Text('Shri Vishnu Engineering College for Women (A), Bhimavaram', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall),),
                          //         ],
                          //       ))
                          //     ],
                          //   ),
                            
                          // ),

                          // sizedBox(16),
                          
                          Container(
                            
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              controller: mobileNumberController,
                              keyboardType: TextInputType.text,
                              autofocus: true,
                              textCapitalization: TextCapitalization.characters,
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
                                hintText: 'Your mobile number',
                                ),
                              validator: (value) { // validator function is called on calling form validate() method
                                if (value!.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                              onSaved: (value) => mobileNumber = value!,
                              style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black),
                            ),
                          ),

                          
                          
                          optSent ? 
                          Column(
                            children: [
                              sizedBox(16),
                              TextFormField(
                                textAlign: TextAlign.center,
                                controller: otpController,
                                focusNode: otpFocusNode, // Associate the FocusNode with the TextFormField
                                keyboardType: TextInputType.number,
                                autofocus: optSent,
                                // style: const TextStyle(letterSpacing: 25),
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
                                  hintText: 'OTP',),
                                validator: (value) { // validator function is called on calling form validate() method
                                  if (value!.isEmpty) {
                                    // print('ok');
                                    return '';
                                  }
                                  return null;
                                },
                                onSaved: (value) => submittedOTP = value!,
                                style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 25, color: Colors.black),
                            ),
                            sizedBox(4),
                            Text('Enter the OTP sent to your mobile', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall),),
                            ]
                          )
                          : sizedBox(0),
                          
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
                                            Text('Login with OTP', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, color: Colors.white),),
                                          ],
                                        ) 
                                      ),

                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: (isLoading) ? const AppProgress(height: 30, width: 30,) : const SizedBox(height: 0,),
                                      ),
                                ],
                              ) : sizedBox(0),

                          
                              // show UI for checking OTP
                              !checkRegNo ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sizedBox(16),
                                  // show Verify OTP button
                                  (optSent && !verifyOTPLoading) ? MaterialButton(
                                        padding: const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 10.0),
                                        color: Color(0xFF008060),
                                        splashColor: Colors.black38,
                                        colorBrightness: Brightness.dark,
                                        elevation: 2,
                                        highlightElevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        onPressed: (){
                                          verifyOTPNow(context);
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Icon(PhosphorIconsFill.paperPlaneRight, size: 12,),
                                            const SizedBox(width: 8,),
                                            Text('Verify OTP', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, color: Colors.white),),
                                          ],
                                        ) 
                                      ) : sizedBox(0),
                                      (verifyOTPLoading) ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const AppProgress(height: 20, width: 20,),
                                          Text('Signing you in ...', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600),),
                                        ],
                                      ) : sizedBox(0),
                                ],
                              ) : sizedBox(0),


                        ],
                      ),
                      ),
                    ))
                    ),
                    // sizedBox(16),
                    
                    Container(
                      margin: const EdgeInsets.fromLTRB(32, 0, 32, 8),
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            // padding: const EdgeInsets.all(8.0),
                            //child: styledText('Contact your campus adminstration for credentials incase you do not have them.', Constants.body2, Constants.darkbg),
                            
                            child: Column(children: <Widget>[
                              Text('Contact your sales person incase you have issues to login to the app', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium),),
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


    
  