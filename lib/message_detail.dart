import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/modals/notifications.dart';
import 'package:anjanitek/notification_dealer_view.dart';
import 'package:anjanitek/utils/app_header.dart';
import 'package:anjanitek/utils/database_helper.dart';
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
import 'package:url_launcher/url_launcher.dart';

// this is 
class MessageDetail extends StatefulWidget {
  const MessageDetail(this.sender, this.receiver, this.senderName, this.receiverName);
  final String sender, receiver, senderName, receiverName;
  
  @override
  _MessageDetailState createState() => _MessageDetailState();
}

class _MessageDetailState extends State<MessageDetail> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String name = '', role='',
  id='', 
  accountName='',
  salesId='';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  List<Notifications> storedNotifications = [];
  List<Notifications> notificationsList = [];
  ScrollController? scrollController;
  String sentAt = DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(DateTime.now());
  
  int offset = 0;
  bool connectionStatus = true;
  bool isLoading = false;
  bool anyOutstanding = true;
  double totalOutstanding = 0;
  String dueDate = '';
  int daysLeft = 0;
  String emptyStateMsg = '';
  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");
  TextEditingController messageController = new TextEditingController();

  // localdb
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

    scrollController = new ScrollController()..addListener(_scrollListener);
    
    
    super.initState();
  }

   @override
    void dispose() {
      
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
          role = prefs.get(Constants.role) as String;
          isActive = prefs.get(Constants.isActive) as int;
          
          // print(widget.sender);
          // print(id);
            if(prefs.get(Constants.role) == Constants.dealer){

              // dealerId = prefs.get(Constants.id) as String;
              accountName = prefs.get(Constants.accountName) as String;
              salesId = prefs.get(Constants.salesId) as String;
            }
          });

          // storedNotifications = await dbHelper.getNotifications();
          // // get the last notification sentAt date
          // if(storedNotifications.isNotEmpty){
          //   // print('Retrieved notifications from database:'+storedNotifications[0].sentAt.toString());
          //   sentAt = storedNotifications[0].sentAt.toString();
          // }


        } 


        
        // storedNotifications.forEach((notification) => print(notification.toJson()));

        refreshUserNotifications(context);
    }

      // refresh the list
      Future<void> _refreshList() async {
        // Add your refresh logic here, e.g. fetching new data from a server
        await Future.delayed(const Duration(seconds: 2));
        refreshUserNotifications(context);
      }


    // find the user
    void refreshUserNotifications(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          refreshCheckProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        // print("${APIUrls.messaging}${APIUrls.pass}/4/${widget.sender}/${widget.receiver}");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.messaging}${APIUrls.pass}/4/${widget.sender}/${widget.receiver}", queryParams)), headers: {"Accept": "application/json"});
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
          
            // get the user data from jsonObject
            var notificationsData = jsonObject['data'] as List;
            // Map<String, dynamic> notificationsData = jsonObject['data'];

            if(notificationsData.isNotEmpty){
              // convert to list
              storedNotifications = notificationsData.map<Notifications>((json) => Notifications.fromJson(json)).toList();
              // print(notificationsList);

              // DatabaseHelper dbHelper = DatabaseHelper();
              // await dbHelper.initDb();
              
              // here as we get the messages for the sales people
              // create a list where of messages that are sent to Sales Executive
              // we will mark those messages as read by the Sales Executive as we load it into the list
              // Sometimes the dealer might be mapped to SalesManager or StateHead
              if(role.toLowerCase() == Constants.salesExecutive.toLowerCase() || role.toLowerCase() == Constants.salesManager.toLowerCase() || role.toLowerCase() == Constants.stateHead.toLowerCase()){ // only read by sales executives is considered
              
                List<Notifications> sentNotificationsToDealer = storedNotifications.where((notification) => notification.sender != id).toList();
                
                // update the read statuses of all notifications sent to this dealer
                if(sentNotificationsToDealer.isNotEmpty){
                  updateUserNotifciationSeen(context, sentNotificationsToDealer);
                }
              }
              
              
              setState(() {

                // updated the locallist with fetched list from db
                // storedNotifications.insertAll(0, notificationsList);
                // storedNotifications = notificationsList;

               

                refreshCheckProgress = false;
                connectionStatus = true;
              }
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
            // insert the notification into local db
            // for (Notifications notification in notificationsList) {
            //     notification.seen = 1;
            //     await dbHelper.insertNotification(notification);
            //   }

          }
          else {
            setState(() {
              anyOutstanding = false;
              refreshCheckProgress = false;
              connectionStatus = true;
            });
            
          }
          
        }
        else if(jsonObject['status'] == 201){
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
            // showToast(context, 'No new notifications', Constants.success);
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
          refreshUserNotifications(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }


  void createChat() async {

    if(await checkInternetConnectivity()){
      
      // set connection status variable to true
      setState(() {
        connectionStatus = true;
        isLoading = true;
        // first = false;
      });
       

        Notifications chatMessage = new Notifications();
        chatMessage.notificationId = 1000000;
        chatMessage.sender = widget.sender;
        chatMessage.receiver = widget.receiver; //storedNotifications[storedNotifications.length-1].sender;
        // chatMessage.adminId = '-';
        chatMessage.message = messageController.text;
        chatMessage.seen = 0;
        chatMessage.sentAt = sentAt;

        // query parameters    
        Map<String, String> queryParams = {};

        // API call
        // print("${APIUrls.messaging}${APIUrls.pass}/0/${chatMessage.sender}/${chatMessage.receiver}/$sentAt/${Uri.encodeComponent(chatMessage.message!)}/0/-");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.messaging}${APIUrls.pass}/0/${chatMessage.sender}/${chatMessage.receiver}/$sentAt/${Uri.encodeComponent(chatMessage.message!)}/0/-", queryParams)), headers: {"Accept": "application/json"});
        // print(result.body);
      
      // get the result body which is JSON
      var jsonString = jsonDecode(result.body); 
      
      // convert jsonString to Map
      var jsonObject = jsonString as Map; 

      // check if the api returned success
      if(jsonObject['status'] == 200){
        
             setState(() {
                // list.clear();
                messageController.text = '';
                // storedNotifications.add(chatMessage);
                storedNotifications = [...storedNotifications, chatMessage];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                // _animationController.forward();
                // (list.length > 0 && scrollController!.positions.isNotEmpty) ? scrollController!.jumpTo(scrollController!.position.maxScrollExtent) : 0;
                

                isLoading = false;
              });

            // play the sound
            // player.setAsset('assets/outgoing.mp3');
            // player.play();
      }
      else {
          // no requests
          setState(() {
            emptyStateMsg = 'No pending requests';
            isLoading = false;
          });
        }
    }
    else {
        Future.delayed(const Duration(seconds: 2), () {

          // this is to check for retrying only once more. Else it will end the loop
          if(connectionStatus)
          {
            // getChatUserData();
            // print('Again trying');
          
            // set the connection Status variable to false
            setState(() {
              connectionStatus = false;
              isLoading = false;
              // isDataAvailable = false;
            });
          }
        });
      }
  }




    // Update the seen for messages
    void updateUserNotifciationSeen(BuildContext context, List<Notifications> sentNotificationsToDealer) async {

      if(await checkInternetConnectivity()){
        
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        List<int> notificationIds = sentNotificationsToDealer.map((notification) => notification.notificationId!).toList();

        // print("${APIUrls.messaging}${APIUrls.pass}/6/${notificationIds.join(',')}");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.messaging}${APIUrls.pass}/6/${notificationIds.join(',')}", queryParams)), headers: {"Accept": "application/json"});
        
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){

        }
        else if(jsonObject['status'] == 201){
          // no data exists
          setState(() {
            // get the error message
            connectionStatus = true;
          });
          
        }
        else if(jsonObject['status'] == 404){
          // no data exists
          setState(() {
            // get the error message
            connectionStatus = true;
          });
          
        }
        else {

            setState(() {
              connectionStatus = true;
            });
        }
        
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          // updateUserNotifciationSeen(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }

  
  void _scrollToBottom() {
    scrollController!.animateTo(scrollController!.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // detect scroll to end and load more items
  void _scrollListener(){
    if(scrollController!.position.pixels == scrollController!.position.maxScrollExtent){
      
      setState(() {
        // increment offset by 5
        if(notificationsList.length-5 == offset){
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
      refreshUserNotifications(context);
    });
  }


// Function to differentiate and decode
  String decodeServerText(String text) {
    try {
      // Check if the string is URL-encoded by comparing with decoded
      String decoded = Uri.encodeComponent(text);
      if (decoded != text) {
        return utf8.decode(text.codeUnits);
        // return decoded;
      } else {
        // If not URL-encoded, try to decode using UTF-8
        return decoded;
        // return utf8.decode(text.codeUnits);
      }
    } catch (e) {
      // If decoding fails, return the original text
      return text;
    }
  }

  // Regular expression to find URLs
  final RegExp urlRegExp = RegExp(
    r'(http|https):\/\/([\w\-]+\.)+[\w\-]+(\/[\w\-\.\/?%&=]*)?',
    caseSensitive: false,
  );

  // Function to extract URLs and separate them from the text
  String extractUrls(String text) {
    // Find all URLs in the input text
    Iterable<RegExpMatch> matches = urlRegExp.allMatches(text);

    // Extract URLs and remove them from the text
    StringBuffer urlsBuffer = StringBuffer();
    String modifiedText = text;

    for (var match in matches) {
      urlsBuffer.write(match.group(0)! + '\n'); // Add URLs to the buffer
      modifiedText = modifiedText.replaceAll(match.group(0)!, ''); // Remove URLs from text
    }

    // setState(() {
    //   extractedUrls = urlsBuffer.toString().trim(); // Store the extracted URLs
    //   remainingText = modifiedText.trim(); // Store the remaining text
    // });

    return urlsBuffer.toString().trim(); // Store the extracted URLs
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
                    padding: EdgeInsets.fromLTRB(16,0,16,16),
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
                                AppHeader('Invoices', '', 1),
                                // Text('Messages', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
                                Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
                                
                                (widget.sender == id) ? sizedBox(0) :
                                          Text('Conversation between', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                          
                                Container(
                                      margin: EdgeInsets.fromLTRB(0,6,0,6),
                                      padding: EdgeInsets.fromLTRB(16,8,16,8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.all(Radius.circular(24)),
                                        // border: Border.all(
                                        //           color: Colors.black12, // Set the color of the border here
                                        //           width: 1, // Set the width of the border here
                                        //         ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 16.0,
                                            spreadRadius: 0.3,
                                          ),
                                        ]
                                      ),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        // Icon(PhosphorIconsBold.dotOutline, color: Color(0xFF06A467)),
                                        // Icon(PhosphorIconsBold.dotOutline, color: Color(0xFF06A467)),
                                        Icon(PhosphorIconsRegular.chats, color: Colors.black45),
                                      ],
                                    ),
                                    SizedBox(width: 8,),
                                    Flexible(child: 
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text((widget.senderName == name) ? 'You' : widget.senderName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14), ),
                                          divider(Colors.black12),
                                          Text(widget.receiverName, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14), ),
                                        ],
                                      )
                                    )
                                    
                                  ],
                                ),
                              )
                              ],
                            
                            ),

                            sizedBox(8),

                            storedNotifications.isNotEmpty ?
                            Expanded(
                              
                              child: RefreshIndicator(
                            onRefresh: _refreshList,
                            child: 
                              ListView.builder(
                                  // physics: AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: storedNotifications.length,
                                  itemBuilder: (context, index){
                                    
                                    return  FadeTransition(opacity: _controller,
                                          child:
                                          ScaleTransition(scale: CurvedAnimation(
                                                    parent: _controllerCards,
                                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                                  ),alignment: Alignment.bottomCenter,
                                                  child:
                                                Container(
                                                      // margin: EdgeInsets.fromLTRB(0,6,0,6),
                                                      padding: EdgeInsets.all(8),
                                                      // decoration: BoxDecoration(
                                                      //   color: (storedNotifications[index].sender == widget.sender) ?  Color.fromARGB(255, 232, 244, 239) : Color(0xFFF9F9F9),
                                                      //   // color: Color(0xFFF9F9F9),
                                                      //   borderRadius: const BorderRadius.all(Radius.circular(24)),
                                                      //   // border: Border.all(
                                                      //   //           color: Colors.black12, // Set the color of the border here
                                                      //   //           width: 1, // Set the width of the border here
                                                      //   //         ),
                                                      //   boxShadow: const [
                                                      //     BoxShadow(
                                                      //       color: Colors.white,
                                                      //       offset: Offset(0.0, 0.0),
                                                      //       blurRadius: 16.0,
                                                      //       spreadRadius: 0.3,
                                                      //     ),
                                                      //   ]
                                                      // ),
                                          child: NotificationsCard(index),
                                        )
                                    ));
                                  }),
                              )
                            )
                            : 
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                                    sizedBox(8),
                                    Text('No messages yet!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                  ],
                                )
                              )
                            ),
                            
                            // loader while fetching data
                            refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                          
                          // Sending message can be enabled only between the direct reports.
                          // For example, A SalesManager can send message to a dealer if it is direct report
                          // A SalesManager cannot send message to SalesExecutive.
                          (widget.sender == id || role.toLowerCase() == Constants.superAdmin.toLowerCase() || role.toLowerCase() == Constants.globalAdmin.toLowerCase()) ?
                          // (role.toLowerCase() == Constants.superAdmin.toLowerCase()) ? 
                          Container(
                              padding: EdgeInsets.fromLTRB(0,8,0,8),
                              child: 
                            Row(
                              children: <Widget>[
                                Expanded(
                                  // child: Padding(
                                  //   padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: 
                                    TextFormField(
                                      style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge,),
                                      // autofocus: true,
                                      controller: messageController,
                                      minLines: 1,
                                      maxLines: 4,
                                      // maxLength: 120,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(   
                                        hintStyle: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge),
                                        counterText: '',         
                                          hintText: 'Type here...',          
                                          contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: const BorderSide(
                                              color: Colors.black26, // Uses shadowColor for focus
                                              width: 1.0,
                                            ),
                                          ),
                                      
                                      ),
                                    
                                      validator: (value) { // validator function is called on calling form validate() method
                                        if (value!.isEmpty) {
                                          return 'Type to send';
                                        }
                                        return null;
                                      },
                                      //onSaved: (value) => description = value,
                                    ),
                                  
                                ),
                                isLoading ?
                                AppProgress(height: 24, width: 24)
                                :
                                InkWell(
                                    // onTap: () => createSocketMessage(),
                                    onTap: () => createChat(),
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(16, 8, 14, 8),
                                    
                                    decoration: BoxDecoration(
                                        // color: Palette.blue,
                                        border: Border.all(color: Color(0x336302E5)),
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    
                                      alignment: Alignment.center,
                                      child: Icon(PhosphorIconsFill.paperPlaneRight, color: Color(0xFF06A467), size: 24, ),
                                  ),

                                )
                                
                              ],
                            )
                            )
                            : sizedBox(0)


                          
                          ],
                        )
                  )
                ),
            )
        )
    );
  }

  // Refresh profile
  // refreshNotifications(BuildContext context) async {

  //   //showToast(context, "Verifying your identity!");
  //   setState(() {updateMsg = 'Checking for updtes. Please wait...';});
    
    

  // }


// single feed card
Widget NotificationsCard(int position){
  return InkWell(
    // onTap: () => openCircular(context, list[position]),
    // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsDealerView(storedNotifications[position]))).whenComplete(() {storedNotifications[position].seen = 1;},),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: (storedNotifications[position].sender == widget.sender || storedNotifications[position].receiver == 'All') ?  CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: <Widget>[
      

      // (storedNotifications[position].sender == widget.sender) ?
      // Text((widget.senderName == name) ? 'You' : widget.senderName , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black45, fontWeight: FontWeight.w500) )
      // : Text(widget.receiverName , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black45, fontWeight: FontWeight.w500) ),

      Container(
          margin: EdgeInsets.fromLTRB(0,2,0,2),
          padding: EdgeInsets.fromLTRB(16,8,16,8),
          decoration: BoxDecoration(
            color: (storedNotifications[position].sender == id) ? Color.fromARGB(255, 232, 244, 239) : Color(0xFFF9F9F9),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            // border: Border.all(
            //           color: Colors.black12, // Set the color of the border here
            //           width: 1, // Set the width of the border here
            //         ),
            boxShadow: const [
              BoxShadow(
                color: Colors.white,
                offset: Offset(0.0, 0.0),
                blurRadius: 16.0,
                spreadRadius: 0.3,
              ),
            ]
          ),
          child: 
          SelectableText(utf8.decode(storedNotifications[position].message!.codeUnits), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14,), 
          textAlign: (storedNotifications[position].sender == widget.sender || storedNotifications[position].receiver == 'All') ?  TextAlign.end : TextAlign.start, ),
      ),

      extractUrls(decodeServerText(storedNotifications[position].message!)).length > 0 ?
      InkWell(                   
        // child: Container(
        //   transformAlignment: (storedNotifications[position].sender == id) ?  Alignment.centerRight : Alignment.centerLeft,
        //   padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child:
          Row(
            mainAxisAlignment: (storedNotifications[position].sender == widget.sender || storedNotifications[position].receiver == 'All') ?  MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.link, color: Colors.blueAccent, size: 24,),
              const SizedBox(width:4),
              // Text('Follow @AnjaniTek', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
              Text('${extractUrls(decodeServerText(storedNotifications[position].message!))}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
        // ),
        onTap: () => {
          // facebookUrl = Uri.parse('https://www.instagram.com/anjanitek/'),
          launchUrl(Uri.parse(extractUrls(decodeServerText(storedNotifications[position].message!))), mode: LaunchMode.externalApplication),
        },
      ) : sizedBox(0),

      // Text('${notificationsList[position].message}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
      sizedBox(4),
      Row(
        mainAxisAlignment: (storedNotifications[position].sender == widget.sender || storedNotifications[position].receiver == 'All') ?  MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (storedNotifications[position].sender == widget.sender || storedNotifications[position].receiver == 'All') ?
          Text((widget.senderName == name) ? 'You' : widget.senderName , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black38, fontWeight: FontWeight.w500) )
          : Text(widget.receiverName , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black38, fontWeight: FontWeight.w500) ),
      
          SizedBox(width:4),
          Text(DateFormat('• d-MMM hh:mm a', 'en_US').format(getDate(storedNotifications[position].sentAt!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black38, fontWeight: FontWeight.w500) ),
          // Text(DateFormat('• d-MMM-y', 'en_US').format(getDate(storedNotifications[position].sentAt!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black38, fontWeight: FontWeight.w500) ),
          // Text(storedNotifications[position].sender! , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black45, fontWeight: FontWeight.w500) ),
          SizedBox(width:8),
          
          // if the sender is not me and I am the sales executive, 
          
          (storedNotifications[position].seen == 0) ? 
          Icon(PhosphorIconsBold.check, size: 16, color: Color(0xFF008060)) :
          Icon(PhosphorIconsBold.checks, size: 16, color: Color(0xFF999999)),
          // // if the sender is not me and I am the sales executive, 
          // (storedNotifications[position].sender != id) ? sizedBox(0) :
          // (storedNotifications[position].seen == 0) ? 
          // Icon(PhosphorIconsBold.check, size: 16, color: Color(0xFF008060)) :
          // Icon(PhosphorIconsBold.checks, size: 16, color: Color(0xFF999999)),
          // sizedBox(8),
        ],
      )
      // Text(DateFormat('d-MMM-y', 'en_US').format(getDate(storedNotifications[position].sentAt!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black45, fontWeight: FontWeight.w500) ),
      // // Text(storedNotifications[position].sender! , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black45, fontWeight: FontWeight.w500) ),
      // sizedBox(8),
      
      // (storedNotifications[position].seen == 0) ? 
      // Icon(PhosphorIconsRegular.check, size: 24, color: Color(0xFF008060)) :
      // Icon(PhosphorIconsRegular.checks, size: 24, color: Color(0xFF999999)),
      // sizedBox(8),
      
      // styledText(InvoicesList[0].description, Constants.linkifyBig, Constants.lightbg, 5),
      // sizedBox(16),
      
      
      // Row(
      //   children: [
      //     Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.black54,),
      //     SizedBox(width: 4,),
      //     Text('${DateFormat('MMM dd, yyyy · hh:mm aa', 'en_US').format(getDate(notificationsList[position].expiryDate!))}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
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

