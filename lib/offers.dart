import 'dart:convert';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/modals/offer.dart';
import 'package:anjanitek/utils/app_header.dart';
import 'package:intl/intl.dart';
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
import 'package:anjanitek/utils/divider.dart';
// import 'package:anjanitek/util/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

// this is 
class OffersForDealer extends StatefulWidget {
  const OffersForDealer({super.key});
  
  @override
  _OffersForDealerState createState() => _OffersForDealerState();
}

class _OffersForDealerState extends State<OffersForDealer> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String id='', role = '';
  bool refreshCheckProgress = false;
  bool responseProgress = false;
  List<Offer> offersList = [];
  List<Map<String, dynamic>>  dealerFromHierarchy = [];
  List<String> offerIds_Dealer_Is_Interested = [];
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
  Offer? invoices ;

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
            
          id = prefs.get(Constants.id) as String;
          role = prefs.get(Constants.role) as String;
          
          });
        } 
        checkAvailableOffersForDealer(context);
    }

      // refresh the list
      Future<void> _refreshList() async {
        // Add your refresh logic here, e.g. fetching new data from a server
        await Future.delayed(const Duration(seconds: 2));
        checkAvailableOffersForDealer(context);
      }


    // find the user
    void checkAvailableOffersForDealer(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          refreshCheckProgress = true;
          offersList = [];
          offerIds_Dealer_Is_Interested = [];
        });
        
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.offers}${APIUrls.pass}/2", {})), headers: {"Accept": "application/json"});
        var result1 = await get(Uri.parse(APIUrls.getUrl("${APIUrls.offers}${APIUrls.pass}/2.1/$id", {})), headers: {"Accept": "application/json"});
        
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        var jsonString1 = jsonDecode(result1.body); 
        
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        var jsonObject1 = jsonString1 as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
          
            // get the user data from jsonObject
            var availableOffers = jsonObject['data'] as List;
            
            // Map<String, dynamic> invoicesData = jsonObject['data'];

            if(availableOffers.isNotEmpty){
              // convert to list
              List<Offer> offersList1 = availableOffers.map<Offer>((json) => Offer.fromJson(json)).toList();
              offersList.addAll(offersList1);
              
              // for non dealer users, get the dealers that responded from their hierarchy
              if(role.toLowerCase() != Constants.dealer.toLowerCase()){

                for (var element in offersList1) {
                  getDealersInterestedFromHierarchy(element.id!);
                }
                
              }
              setState(() {

                refreshCheckProgress = false;
                connectionStatus = true;
              }
            );

          }
          else {
            setState(() {
              refreshCheckProgress = false;
              connectionStatus = true;
            });
            
          }


          if(jsonObject1['status'] == 200){
            var invoicesData1 = jsonObject1['data'] as List;
            
            // Extract offerId from invoicesData1 and add to a string list
            if(invoicesData1.isNotEmpty){
              offerIds_Dealer_Is_Interested = invoicesData1.map<String>((json) => json['offerId'].toString()).toList();

              // print(invoicesData1.map<String>((json) => json['offerId'].toString()).toList());
            }
          }
          
        }
        else if(jsonObject['status'] == 201){
          // no data exists
          setState(() {
            // get the error message
            refreshCheckProgress = false;
            connectionStatus = true;
            showToast(context, 'No Offer done yet!',Constants.warning);
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
          checkAvailableOffersForDealer(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }

    // get responses from the hierarchy of the user
    void getDealersInterestedFromHierarchy(int offer_id) async {

      if(await checkInternetConnectivity()){
        setState(() {
          refreshCheckProgress = true;
        });
        
        // if the user is not a dealer, then get the responses from the user hierarchy
        var responsesFromHierarchyResult = await get(Uri.parse(APIUrls.getUrl("${APIUrls.offers}${APIUrls.pass}/4.1/$offer_id/$id/$role", {})), headers: {"Accept": "application/json"});
        
        // print(responsesFromHierarchyResult.body);
        var jsonString = jsonDecode(responsesFromHierarchyResult.body); 
        
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
          
            // get the user data from jsonObject
            var availableResponses = jsonObject['data'] as List;

            if(availableResponses.isNotEmpty){
              // convert to list
              List<Map<String, dynamic>> availableResponsesList = availableResponses.map<Map<String, dynamic>>((json) {
                return {
                  "offerId": json['offerId'],
                  "dealer": json['dealer'],
                  "createdOn": json['createdOn'],
                  "name": json['name'],
                  "email": json['email'],
                  "mobile": json['mobile'],
                  "mapTo": json['mapTo'],
                };
              }).toList();
              
              dealerFromHierarchy.addAll(availableResponsesList);
              
              
              setState(() {

                refreshCheckProgress = false;
                connectionStatus = true;
              }
            );

          }
          else {
            setState(() {
              refreshCheckProgress = false;
              connectionStatus = true;
            });
            
          }
          
        }
        else {

            setState(() {
              refreshCheckProgress = false;
              connectionStatus = true;
            });
        }
        
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          
          dealerFromHierarchy = [];
          getDealersInterestedFromHierarchy(offer_id);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }

     // send dealer response to offer
    void sendResponseToOffer(BuildContext context, Offer offer) async {

      if(await checkInternetConnectivity()){

        setState(() {
          responseProgress = true;
        });
        // API call
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.offers}${APIUrls.pass}/3/${offer.id}/$id", {})), headers: {"Accept": "application/json"});
        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        var jsonObject = jsonString as Map; 
        if(jsonObject['status'] == 200){
            
            setState(() {
              responseProgress = false;
              connectionStatus = true;
              offerIds_Dealer_Is_Interested.add(offer.id.toString());

            });
          showToast(context, 'Response sent!', Constants.success);
        }
        else {
          setState(() {
            responseProgress = false;
            connectionStatus = true;
          });
          showToast(context, 'Issue sending response. Try again!', Constants.warning);
        }
      }
      else {
        
            responseProgress = false;
        
      }
    }


  // detect scroll to end and load more items
  void _scrollListener(){
    if(scrollController!.position.pixels == scrollController!.position.maxScrollExtent){
      setState(() {
        // increment offset by 5
        if(offersList.length-20 == offset){
          offset = offset+20;
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
      checkAvailableOffersForDealer(context);
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
        Container(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    child:
            Align(
              alignment: Alignment.topCenter,
              child:
                SafeArea(

                child: Container(
                  decoration: BoxDecoration(
                // color: const Color(0xFFFEFEFE),

                        border: Border.all(color: Colors.white, width: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        // gradient: LinearGradient(
                        //   colors: [const Color.fromARGB(255, 221, 221, 221), Colors.deepPurpleAccent],
                        //   // colors: [Color(0xFF008060), Colors.green.shade800],
                        //   // colors: [Colors.amber.shade400, Colors.green.shade800],
                        //   begin: Alignment.topLeft,
                        //   end: Alignment.bottomRight,
                        // ),
                  ),
                    // margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                AppHeader('Offers', '', 1),
                                // sizedBox(16),
                                // Text('Offers', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
                                // sizedBox(16),
                                Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
                                
                              ],
                            
                            ),
                            Row(
                              spacing: 4,
                              children: [
                                Image.asset('assets/offers.webp',width: 60.0), sizedBox(4),
                                Expanded(child: 
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  
                                  children: [
                                    
                                    Text('Grab the offers!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                                    
                                    Text('Anjani brings some exciting offers to you.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87)),
                                    
                                  ]
                                ),
                                ),
                              ],
                            ),

                            

                            sizedBox(8),

                            offersList.isNotEmpty ?
                            Expanded(
                              
                              child: RefreshIndicator(
                            onRefresh: _refreshList,
                            child: 
                              ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: offersList.length,
                                  itemBuilder: (context, index){
                                    
                                    return  FadeTransition(opacity: _controller,
                                          child:
                                          ScaleTransition(scale: CurvedAnimation(
                                                    parent: _controllerCards,
                                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                                  ),alignment: Alignment.bottomCenter,
                                                  child:
                                                Container(
                                                      margin: const EdgeInsets.fromLTRB(8,8,8,8),
                                                      // padding: const EdgeInsets.fromLTRB(16,16,16,8),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                        //                                 gradient: LinearGradient(
                        //   colors: [Color(0xFFFFFFFF), Color.fromARGB(255, 225, 225, 225), Color(0xFFFFFFFF),],
                        //   // stops: [0, 1],
                        //   begin: AlignmentDirectional(0.94, -1),
                        //   end: AlignmentDirectional(-0.94, 1),
                        // ),
                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                        // border: Border.all(
                                                        //           color: Colors.black12, // Set the color of the border here
                                                        //           width: 1, // Set the width of the border here
                                                        //         ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black12,
                                                            offset: Offset(0.0, 0.0),
                                                            blurRadius: 12.0,
                                                            spreadRadius: 0.3,
                                                          ),
                                                        ]
                                                      ),

                      //                                 Container(
                      // width: MediaQuery.sizeOf(context).width * 0.92,
                      // height: 190,
                      // decoration: BoxDecoration(
                      //   boxShadow: [
                      //     BoxShadow(
                      //       blurRadius: 6,
                      //       color: Color(0x4B1A1F24),
                      //       offset: Offset(
                      //         0.0,
                      //         2,
                      //       ),
                      //     )
                      //   ],
                      //   gradient: LinearGradient(
                      //     colors: [Color(0xFF00968A), Color(0xFFF2A384)],
                      //     stops: [0, 1],
                      //     begin: AlignmentDirectional(0.94, -1),
                      //     end: AlignmentDirectional(-0.94, 1),
                      //   ),
                      //   borderRadius: BorderRadius.circular(8),
                      // ),
                                          child: invoiceCard(index),
                                        )
                                    ));
                                  }),
                              )
                            )
                            : 
                            Expanded(
                              child: Center(
                                child: 
                                (!refreshCheckProgress && offersList.isEmpty) ? 
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    
                                    ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                      return const LinearGradient(
                                        colors: [const Color.fromARGB(255, 255, 238, 212), Color.fromRGBO(244, 143, 177, 1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.srcIn,
                                      child: const Icon(PhosphorIconsLight.tag, color: Colors.white, size: 120),
                                    ),
                                    sizedBox(8),
                                    Text('No active offers!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w400, fontSize: 20), ),
                                  ],
                                ) : (refreshCheckProgress && offersList.isEmpty) ? const AppProgress(height: 30, width: 30,) :
                                sizedBox(0)
                              )
                            ),
                            
                            // loader while fetching data
                            (refreshCheckProgress && offersList.isNotEmpty) ? const AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                            
                          
                            

sizedBox(24),
                          
                          ],
                        )
                  ),
                  ),
                  ),
                  ),
             
              ),
              );
  }


// single feed card
Widget invoiceCard(int position){
  return InkWell(
    // onTap: () => openCircular(context, list[position]),
    // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CircularsAdmin())),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      
      Container(

        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: 
      (offersList[position].media != null && offersList[position].media!.isNotEmpty) ?
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
              ),
              child: Image.network(
          'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/uploads%2F'+offersList[position].media!+'?alt=media',
          fit: BoxFit.cover,
          scale: 1.0,
          width: MediaQuery.sizeOf(context).width,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return sizedBox(0);
          },
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
            backgroundColor: Colors.white10,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                            Navigator.of(context).pop();
                        },
                        child: Container(
                          color: Colors.black12,
                        ),
                      ),
                      Center(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/uploads%2F'+offersList[position].media!+'?alt=media',
                              fit: BoxFit.contain,
                              width: MediaQuery.sizeOf(context).width,
                              // height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text(
                              'Image not available',
                              style: TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Row(
            spacing: 4,
            children: [
              Icon(Icons.fullscreen, color: Colors.white, size: 16),
              Text(
                'View Image',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
              ),
            ),
          ],
        )
      :
        sizedBox(0)
      ),
      
      Container(
        padding: const EdgeInsets.fromLTRB(16,16,16,8),
        child: 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(decodeServerText(offersList[position].title!), textAlign: TextAlign.start, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, )),
      
      sizedBox(4),
      Text(decodeServerText(offersList[position].description!), textAlign: TextAlign.start, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, color: Colors.black, )),
      
      sizedBox(8),
      
      sizedBox(4),
      Text('Posted on: ${DateFormat('dd-MMM-yyyy', 'en_US').format(getDate(offersList[position].createdOn!))}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black38, fontWeight: FontWeight.w500 )),
      sizedBox(8),

      // if role is dealer dont show this
      (role.toLowerCase() == Constants.superAdmin.toLowerCase() || role.toLowerCase() == Constants.globalAdmin.toLowerCase() || role.toLowerCase() == Constants.salesExecutive.toLowerCase() || role.toLowerCase() == Constants.salesManager.toLowerCase() || role.toLowerCase() == Constants.stateHead.toLowerCase()) ?
      InkWell(
        onTap: () {
          (dealerFromHierarchy.where((dealer) => dealer['offerId'] == offersList[position].id).isEmpty) ? '' :
          showModalBottomSheet(
            backgroundColor: Colors.white,
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (BuildContext context) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: dealerFromHierarchy.where((dealer) => dealer['offerId'] == offersList[position].id).isNotEmpty
                    ? ListView.builder(
                        itemCount: dealerFromHierarchy.where((dealer) => dealer['offerId'] == offersList[position].id).length,
                        itemBuilder: (context, index) {
                          var dealer = dealerFromHierarchy.where((dealer) => dealer['offerId'] == offersList[position].id).toList()[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            visualDensity: VisualDensity.comfortable,
                            // leading: Icon(PhosphorIconsRegular.userCircle),
                            title: Text(dealer['name'], textAlign: TextAlign.start, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold, color: Colors.black, )),
                            // subtitle: Text(dealer['email'] ?? 'No Email'),
                            trailing: ElevatedButton(
                                onPressed: () async {
                                  // Action to perform when the button is pressed
                                  String telephoneUrl = "tel:${dealer['mobile']}";
                                    await launchUrlString(telephoneUrl);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF048563),
                                  foregroundColor: const Color(0xFFFFFFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6.0,
                                  children: [
                                    const Icon(PhosphorIconsRegular.phone, color: Colors.white, size: 20,),
                                    Text('Call', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                )
                              ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No dealers found for this offer.',
                          style: GoogleFonts.inter(
                            textStyle: Theme.of(context).textTheme.bodyLarge,
                            color: Colors.black54,
                          ),
                        ),
                      ),
              );
            },
          );
        },
        child: 
        Container(
          decoration: BoxDecoration(
            color: (dealerFromHierarchy.where((dealer) => dealer['offerId'] == offersList[position].id).length > 0) ? const Color(0xFF048563) : Colors.grey.shade200, // Subtle background color
            borderRadius: BorderRadius.circular(16), // Border radius
          ),
          alignment: Alignment.center, // Center the text
          padding: const EdgeInsets.all(8), // Add padding
          child: Text(
              '${dealerFromHierarchy.where((dealer) => dealer['offerId'] == offersList[position].id).length} Dealer(s) interested',
              style: GoogleFonts.inter(
                textStyle: Theme.of(context).textTheme.bodyLarge,
                color: Colors.white,
                fontWeight: FontWeight.w500
              ),
            ),
        ),
      )
      : sizedBox(0),
      

    sizedBox(8),

      Row(
        spacing: 16,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            responseProgress ?
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppProgress(height: 30, width: 30,),
                Text('Sending your response', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
              ],
            ) :

role.toLowerCase() != Constants.dealer.toLowerCase() ? sizedBox(0) :
            // offerIds_Dealer_Is_Interested.isEmpty ? sizedBox(0) :
            // offerIds_Dealer_Is_Interested.contains(offersList[position].id.toString()) ?
            // Text('Already responded!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), )
            // :
            // Text('Already responded!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), )
            // :
offerIds_Dealer_Is_Interested.contains(offersList[position].id.toString()) ?
Text('Responded!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), )
:
            ElevatedButton(
              onPressed: () {
                // Add your first button action here
                sendResponseToOffer(context, offersList[position]);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008060), // Dark background color
                textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 5, // Shadow depth
              ),
              child: const Row(
                spacing: 8,
                children: [
                  Icon(PhosphorIconsRegular.check, color: Colors.white,),
                  Text('I am interested',  style: TextStyle(color: Colors.white)),
                ],
              )
              
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     // Add your second button action here
            //     // setState(() {
            //     //   confirmation.response = 'No';  
            //     //   confirmation.comment = 'Outstanding balance mismatch';  
            //     // });
                
            //     // final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => BalanceConfirmation(confirmation)));
            //     // if (result != null && result['status'] == Constants.success) {
            //     //   setState(() {
            //     //     confirmationStatus = Constants.no;
            //     //     confirmation.comment = null;
            //     //   });
            //     // }
                
            //   },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Color(0xFFFFF9F9), // Dark background color
            //       textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
            //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            //       shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(24),
            //       side: BorderSide(color: Colors.red.shade200, width: 0.9), // Add red border color
            //       ),
            //       elevation: 2, // Shadow depth
            //     ),
            //   child: Row(
            //     spacing: 8,
            //     children: [
            //       Icon(PhosphorIconsRegular.x, color: Colors.red,),
            //       Text('Dismiss', style: TextStyle(color: Colors.red)),
            //     ],
            //   )
            // ),  
          ]
      )
          ],
        ),
      ),
      sizedBox(4),

      // Text('Detail: ${offersList[position].transactionId!}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),

      
      
      // styledText(OfferList[0].description, Constants.linkifyBig, Constants.lightbg, 5),
      // sizedBox(16),
      
      
      // Row(
      //   children: [
      //     Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.black54,),
      //     SizedBox(width: 4,),
      //     Text('${DateFormat('MMM dd, yyyy · hh:mm aa', 'en_US').format(getDate(offersList[position].expiryDate!))}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
      //     // Text( (OfferList[position].createdOn != 'just now') ? '${(getTimeDiff(now, getDate(OfferList[position].createdOn!)))} ago' : 'just now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.caption)),
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

