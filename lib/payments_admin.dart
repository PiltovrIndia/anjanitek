import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/dealer_details.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/modals/payments.dart';
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
class PaymentsAdmin extends StatefulWidget {
  
  
  @override
  _PaymentsAdminState createState() => _PaymentsAdminState();
}

class _PaymentsAdminState extends State<PaymentsAdmin> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String name='', id='', role='';
  bool refreshCheckProgress = false;
  bool deleteInProgress = false;
  List<Payments> paymentsList = [];
  List<Payments> paymentsListOfSelectedDealer = [];
  ScrollController? scrollController;
  ScrollController? scrollControllerDealers;
  // ScrollController? scrollController2;
  
  int offset = 0;
  bool connectionStatus = true;
  static int isActive = 1;
  bool anyOutstanding = true;
  double totalOutstanding = 0;
  String dueDate = '';
  int daysLeft = 0;
  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");

  
  // user object
  Payments? invoices ;

  TextEditingController mobileController = TextEditingController();
  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  late SharedPreferences prefs;

  String searchedText = '';
  bool isSearchResultEmpty = false;
  TextEditingController searchTextController = TextEditingController();
  List<Users> dealersList = [];
  Users? selectedDealer;
  bool isLoading = false;
  bool isDataAvailable = false;
  bool endOfData = false;
  String emptyStateMsg = '';
  

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
    scrollControllerDealers = new ScrollController()..addListener(_scrollListener1);
    // scrollController2 = new ScrollController()..addListener(_scrollListener2);
    
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
            role = prefs.get(Constants.role) as String;
            isActive = prefs.get(Constants.isActive) as int;
            
          });
        } 
        refreshUserPaymentsAdmin(context);
    }

      // refresh the list
      Future<void> _refreshList() async {
        // Add your refresh logic here, e.g. fetching new data from a server
        await Future.delayed(const Duration(seconds: 2));
        refreshUserPaymentsAdmin(context);
      }


    // delete payment
    void deletePayment(Payments paymentItem) async {

      if(await checkInternetConnectivity()){
        setState(() {
          deleteInProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
          
          };

        // API call
        // print("${APIUrls.payments}${APIUrls.pass}/delete/${jsonEncode(paymentItem)}");
        // var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.payments}${APIUrls.pass}/delete/${Uri.encodeComponent(paymentItem.toString())}", queryParams)), headers: {"Accept": "application/json"});

        var result = await http.post(
          Uri.parse(APIUrls.getUrl("${APIUrls.payments}${APIUrls.pass}/delete",[] as Map<String, String>)),
          headers: { 'Content-Type': 'application/json', // Specify the content type
          },
          body: jsonEncode(paymentItem), // Convert the object to JSON string
        );

        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
          
              // remove the selected payment item
              List<Payments> newPaymentsList = paymentsList;
              newPaymentsList.remove(paymentItem);
              
              setState(() {
                // update the payments list after removing the selected payment  
                paymentsList = newPaymentsList;
              
                // indicate there is outstanding
                anyOutstanding = false;

                // hide the progress
                deleteInProgress = false;
                connectionStatus = true;
              }
 
            );

            showToast(context, 'Payment deleted!',Constants.success);

          setState(() {
              anyOutstanding = false;
              deleteInProgress = false;
              connectionStatus = true;
            });
          
        }
        else if(jsonObject['status'] == 201){
          // no data exists
          setState(() {
            // get the error message
            deleteInProgress = false;
            connectionStatus = true;
            showToast(context, 'No Payments done yet!',Constants.warning);
          });
          
        }
        else if(jsonObject['status'] == 404){
          // no data exists
          setState(() {
            // get the error message
            deleteInProgress = false;
            connectionStatus = true;
          });
          
        }
        else {

            setState(() {
              deleteInProgress = false;
              connectionStatus = true;
              showToast(context, 'Error, try again later!',Constants.error);
            });
        }
        
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          refreshUserPaymentsAdmin(context);
          
          // set the connection Status variable to false
          setState(() {
            connectionStatus = false;
          });
          
        });
      }
    }



    // find the user
    void refreshUserPaymentsAdmin(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          refreshCheckProgress = true;
        });

        // API call
        // print("${APIUrls.amount}${APIUrls.pass}/U3/$id/$offset");
        var api = '';
        if(selectedDealer==null){
          api = "${APIUrls.amount}${APIUrls.pass}/U3.1/$role/$id/$offset";
        }
        else {
          api = "${APIUrls.amount}${APIUrls.pass}/U3/${selectedDealer?.id}/$offset";
        }
        // print(api);
        var result = await get(Uri.parse(APIUrls.getUrl(api, {})), headers: {"Accept": "application/json"});
        var jsonString = jsonDecode(result.body); 
        // print(result.body);
        
        var jsonObject = jsonString as Map; 
        if(jsonObject['status'] == 200){
          
            var invoicesData = jsonObject['data'] as List;
        
            if(invoicesData.isNotEmpty){
              // convert to list
              List<Payments> payments = invoicesData.map<Payments>((json) => Payments.fromJson(json)).toList();
              // print(paymentsList);
              
              setState(() {
                paymentsList.addAll(payments);
                // Get new user data
                // invoices = invoicesData.where((element) => false);
                // invoices.
                // double totalSum = paymentsList.fold(0.0, (double sum, Payments invoice) {
                //   return sum + (invoice.pending ?? 0.0);
                // });

                // DateTime? earliestExpiryDate = paymentsList
                //   .where((invoice) => invoice.expiryDate != null) // Filter out null expiry dates
                //   .map((invoice) => format.parse(invoice.expiryDate!)) // Parse string to DateTime
                //   .reduce((a, b) => a.isBefore(b) ? a : b); // Determine the earliest date
                  
                // // get the days left for expiry  
                // Duration duration = earliestExpiryDate.difference(DateTime.now());

                // // Output the earliest date in a friendly format, e.g., January 1, 2023
                // String formattedDate = DateFormat('MMMM d, yyyy').format(earliestExpiryDate);

                // totalOutstanding = totalSum;
                // dueDate = formattedDate;
                // daysLeft = duration.inDays;

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
        else if(jsonObject['status'] == 201){
          // no data exists
          setState(() {
            // get the error message
            refreshCheckProgress = false;
            connectionStatus = true;
            showToast(context, 'No Payments done yet!',Constants.warning);
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
          refreshUserPaymentsAdmin(context);
          
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
        if(paymentsList.length-20 == offset){
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
      refreshUserPaymentsAdmin(context);
    });
  }



  //   // get the payments of selected dealer
  //   void getPaymentsOfSelectedDealer(BuildContext context) async {

  //     if(await checkInternetConnectivity()){
  //       setState(() {
  //         refreshCheckProgress = true;
  //       });

  //       // API call
  //       // print("${APIUrls.amount}${APIUrls.pass}/U3/$id/$offset");
  //       var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.amount}${APIUrls.pass}/U3/$id/$offset", {})), headers: {"Accept": "application/json"});
  //       var jsonString = jsonDecode(result.body); 
        
  //       var jsonObject = jsonString as Map; 
  //       if(jsonObject['status'] == 200){
          
  //           var invoicesData = jsonObject['data'] as List;
        
  //           if(invoicesData.isNotEmpty){
  //             // convert to list
  //             List<Payments> payments = invoicesData.map<Payments>((json) => Payments.fromJson(json)).toList();
  //             // print(paymentsList);
              
  //             setState(() {
  //               paymentsListOfSelectedDealer.addAll(payments);
                
  //               refreshCheckProgress = false;
  //               connectionStatus = true;
  //             }
  //           );

  //         }
  //         else {
  //           setState(() {
  //             refreshCheckProgress = false;
  //             connectionStatus = true;
  //           });
            
  //         }
          
  //       }
  //       else if(jsonObject['status'] == 201){
  //         // no data exists
  //         setState(() {
  //           // get the error message
  //           refreshCheckProgress = false;
  //           connectionStatus = true;
  //           showToast(context, 'No Payments done yet!',Constants.warning);
  //         });
          
  //       }
  //       else if(jsonObject['status'] == 404){
  //         // no data exists
  //         setState(() {
  //           // get the error message
  //           refreshCheckProgress = false;
  //           connectionStatus = true;
  //         });
          
  //       }
  //       else {

  //           setState(() {
  //             refreshCheckProgress = false;
  //             connectionStatus = true;
  //             showToast(context, 'Error, try again later!',Constants.error);
  //           });
  //       }
        
  //     }
  //     else {
  //       Future.delayed(const Duration(seconds: 5), () {
  //         getPaymentsOfSelectedDealer(context);
          
  //         // set the connection Status variable to false
  //         setState(() {
  //           connectionStatus = false;
  //         });
          
  //       });
  //     }
  //   }


  // // detect scroll to end and load more items
  // void _scrollListener2(){
  //   if(scrollController2!.position.pixels == scrollController2!.position.maxScrollExtent){
  //     setState(() {
  //       // increment offset by 5
  //       if(paymentsListOfSelectedDealer.length-20 == offset){
  //         offset = offset+20;
  //         // show up the loader
  //         startLoader2();
  //       }
  //       else {
  //         //print('do nothing');
  //       }
  //     });

  //   }
  // }


  // // show the loader while loading more items
  // void startLoader2(){
  //   setState((){
  //     refreshCheckProgress = !refreshCheckProgress;
  //     getPaymentsOfSelectedDealer(context);
  //   });
  // }



  // initiate the search
  void searchNow(searchTerm) {

    setState(() {
      searchedText = searchTerm;
      dealersList.clear();
    });

    setState(() {
      isLoading = true;
    });
    getDealers();
  }

  // get dealers for approval
  void getDealers() async {

    // check if there is any data
    if(searchedText.isNotEmpty) {
      
      // print("${APIUrls.user}${APIUrls.pass}/U2/$searchedText/$offset/$role/$adminId");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U2/$searchedText/$offset/$role/$id", {})), headers: {"Accept": "application/json"});
      
      var jsonString = jsonDecode(result.body); 
      var jsonObject = jsonString as Map; 

      List<Users> list1;
      if(jsonObject['status'] == 200){
        var dealers = jsonObject['data'] as List;

        if(dealers.isNotEmpty) {
          list1 = dealers.map<Users>((json) => Users.fromJson(json)).toList();
          
            setState(() {
              dealersList.addAll(list1);

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
  void _scrollListener1(){
    if(scrollControllerDealers!.position.pixels == scrollControllerDealers!.position.maxScrollExtent){
      setState(() {
        // increment offset by 20
        offset = offset+20;
      });
      // show up the loader
      startLoader1();
    }
  }

  // show the loader while loading more items
  void startLoader1(){
    setState((){
      isLoading = true;
      //print(offset);
      getDealers();
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
                  margin: EdgeInsets.fromLTRB(8, 0, 8, 16),
                    // margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child:
            Align(
              alignment: Alignment.topCenter,
              child:
                SafeArea(

                child: Container(
                  // padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                AppHeader('Invoices', '', 1),
                                // sizedBox(16),
                                Text('Payments', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
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
                                //     onPressed: () => updatePaymentsAdmin(context),
                                //   ),
                                


                                
                              ],
                            
                            ),

                            sizedBox(8),
                            TextField(
                                onChanged: (value) {
                                if (value.isEmpty) {
                                  setState(() {
                                  dealersList.clear();
                                  });
                                }
                                },
                                onSubmitted: (value) {
                                  searchNow(searchTextController.text.trim());
                                  setState(() {
                                    searchTextController.text = value;
                                    searchTextController.selection = TextSelection.fromPosition(TextPosition(offset: searchTextController.text.length));
                                  });
                                },
                                controller: searchTextController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(fontSize: 14.0,),
                                decoration: InputDecoration(
                                fillColor: Color.fromARGB(255, 255, 255, 255),
                                filled: true,
                                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                suffixIcon: searchTextController.text.isNotEmpty
                                  ? TextButton(
                                  child: Text('Clear', style: TextStyle(color: Color(0xFF008160))),
                                  onPressed: () {
                                  setState(() {
                                    searchTextController.clear();
                                    dealersList.clear();
                                    
                                    // if selected dealer is not null then clear it and load the overall payments
                                    if(selectedDealer!=null){
                                      
                                      selectedDealer = null;
                                      paymentsList.clear();
                                      refreshUserPaymentsAdmin(context);
                                    }
                                  });
                                  },
                                  )
                                  : Icon(PhosphorIconsRegular.magnifyingGlass, color: Color(0xFF008160)),
                                hintText: 'Type dealer name to Search',
                                hintStyle: const TextStyle(
                                  fontSize: 14.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
                                ),
                                ),
                                readOnly: searchTextController.text.isNotEmpty,
                              ),
                              SizedBox(height: 8),
                              isLoading
                                ? Center(child: CircularProgressIndicator())
                                : dealersList.isEmpty
                                ? Container()
                                : Container(
                                // top: 100, // Adjust the position as needed
                                // left: 16,
                                // right: 16,
                                child: Material(
                                elevation: 8.0,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                                  height: 180, // Adjust the height as needed
                                  child: Scrollbar(
                                  thumbVisibility: true,
                                  child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: dealersList.length,
                                  itemBuilder: (context, index) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                                    isThreeLine: false,
                                    title: Text(dealersList[index].name ?? '', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black, fontWeight: FontWeight.bold)),
                                    subtitle: Text(dealersList[index].id ?? '', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54, fontWeight: FontWeight.bold)),
                                    onTap: () {
                                      // Handle the tap event here
                                      setState(() {
                                        searchTextController.text = dealersList[index].name!;
                                        selectedDealer = dealersList[index];  
                                        paymentsList.clear();
                                        dealersList.clear();
                                      });

                                      refreshUserPaymentsAdmin(context);
                                      // Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetails(dealersList[index].mapTo!, dealersList[index].mapName ?? '', dealersList[index].id!, dealersList[index].name!)));
                                    },
                                  );
                                  },
                                  separatorBuilder: (context, index) => divider(Colors.black12),
                                  ),
                                  ),
                                ),
                                ),
                                ),
                            // sizedBox(8),
                            
                            paymentsList.isNotEmpty ?
                            Expanded(
                              
                              child: RefreshIndicator(
                            onRefresh: _refreshList,
                            child: 
                              ListView.builder(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: paymentsList.length,
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
                                                        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
                                          child: paymentCard(index),
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
                                    Icon(PhosphorIconsRegular.currencyInr, color: Color(0xFFAAAAAA), size: 32, ),
                                    sizedBox(8),
                                    Text('No payments done yet!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                  ],
                                )
                              )
                            ),
                            
                            // loader while fetching data
                            refreshCheckProgress? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    AppProgress(height: 30, width: 30,),
                                    Text('Loading...!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                  ],
                                ) : sizedBox(0),
                            // refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                            
                          
                            


                          
                          ],
                        )
                  )
                ),
            )
            )
        )
    );
  }

  // Refresh profile
  // refreshPaymentsAdmin(BuildContext context) async {

  //   //showToast(context, "Verifying your identity!");
  //   setState(() {updateMsg = 'Checking for updtes. Please wait...';});
    
    

  // }


// single feed card
Widget paymentCard(int position){
  return InkWell(
    // onTap: () => openCircular(context, list[position]),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetails(id, name, paymentsList[position].dealerId!, paymentsList[position].accountName!))),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      
      // sizedBox(8),

      // (paymentsList[position].status == Constants.NotPaid) ?
      // Container(
        
      //   padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      //   decoration: BoxDecoration(
      //           color: Colors.red.shade100,
      //           borderRadius: BorderRadius.circular(4),
      //         ),
      //       child: Text('Not Paid', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: Color(0xFFF91616))),  
      //   )
      //   :
      // Container(
        
      //   padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      //   decoration: BoxDecoration(
      //           color: Colors.green.shade100,
      //           borderRadius: BorderRadius.circular(4),
      //         ),
      //       child: Text('Paid', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: Color(0xFF008060))),  
      //   ),
      // Text(PaymentsList[position].circularType!.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
      // sizedBox(8),
      // Text('${paymentsList[position].accountName!}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: , )),
      (selectedDealer != null) ?
      Text('${selectedDealer!.name}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600))
      : Text('${paymentsList[position].accountName!}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
      sizedBox(8),
      Row(
        children: [
          Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(paymentsList[position].amount!)}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          SizedBox(width: 4,),
          (paymentsList[position].adminId != '-') ? 
          Container(
            padding: const EdgeInsets.fromLTRB(6, 2, 8, 3),
            // decoration: BoxDecoration(
            //         color: paymentsList[position].type == 'credit' ? Color(0xFF01B11C) : Color(0xFFC41306),
            //         borderRadius: BorderRadius.circular(16),
            //       ),
            child: 
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     Icon(PhosphorIconsBold.check, size: 16, color: Colors.white),
            //     SizedBox(width: 4,),
            //     Text('${paymentsList[position].type}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5, color: Colors.white, fontWeight: FontWeight.bold ), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true,  )
            //   ]
            // )
            (paymentsList[position].adminId != '-') ? const Icon(PhosphorIconsFill.checkCircle, size: 24, color: Color(0xFFFFFFFF),) : 
            Row(children: [
              const Icon(PhosphorIconsFill.clock, size: 24, color: Colors.grey,),
              const SizedBox(width: 4,),
              Text('Sent for verification', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.grey)),
            ],)
          )
          :
          // const Icon(PhosphorIconsFill.checkCircle, size: 24, color: Color(0xFF01B11C),) : 
            Row(children: [
              const Icon(PhosphorIconsFill.clock, size: 24, color: Colors.grey,),
              const SizedBox(width: 4,),
              Text('Sent for verification', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.grey)),
            ],)
              
          // SizedBox(width: 4,),
          // Text('${paymentsList[position].type}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: paymentsList[position].type == 'credit' ? Colors.green : Color(0xFFC41306))),  
        ],
      ),
      // sizedBox(8),
      // Text('${paymentsList[position].invoiceNo}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54, )),
      
      Text('${DateFormat('d-MMM-y', 'en_US').format(getDate(paymentsList[position].paymentDate!))}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54, )),
      
      
      // sizedBox(8),
      divider(Colors.black12),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sizedBox(4),
              Text('${paymentsList[position].invoiceNo}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black87, )),
              sizedBox(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                      Text('Detail:' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 4, softWrap: true, ),
                      Expanded(child: 
                      Text('${paymentsList[position].transactionId!}' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54), overflow: TextOverflow.ellipsis, maxLines: 4, softWrap: true, ),
                      )
                ]
              ),
              // sizedBox(4),
              // Text('${DateFormat('d-MMM-y', 'en_US').format(getDate(paymentsList[position].paymentDate!))}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, )),
              // Text('Paid on: ${DateFormat('d-MMM-y', 'en_US').format(getDate(paymentsList[position].paymentDate!))}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, )),
              sizedBox(4),
            ],
          ),
          ),

          // (role.toLowerCase() == Constants.superAdmin.toLowerCase()) ?
          // InkWell(
          //       onTap: () => {
          //         // Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentsAdmin()))
                  
          //           showDialog(
          //             context: context,
          //             builder: (BuildContext context) {
          //               return AlertDialog(
          //                 title: Text('Confirmation', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          //                 content: Text('Are you sure you want to delete?', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, )),
          //                 actions: <Widget>[
          //                   TextButton(
          //                     onPressed: () {
          //                       Navigator.of(context).pop(); // Close the dialog
          //                     },
          //                     child: Text('No', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, )),
          //                   ),
          //                   TextButton(
          //                     onPressed: () {
                                
          //                       deletePayment(paymentsList[position]);
          //                       Navigator.of(context).pop(); // Close the dialog
          //                     },
          //                     child: Text('Yes', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, )),
          //                   ),
          //                 ],
          //               );
          //             },
          //           ),
                  
          //         // deletePayment(paymentsList[position]),
          //       },
          //       child: 
          //       Container(
          //         padding: const EdgeInsets.fromLTRB(16, 8, 0, 16),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
                    
          //           children: [

          //             Container(
          //               decoration: const BoxDecoration(
          //                 color: Colors.black12,
          //                 borderRadius: BorderRadius.all(Radius.circular(24)),
          //               ),
          //               padding: const EdgeInsets.all(10),
          //               child:  Row(
          //                 mainAxisSize: MainAxisSize.min,
          //                     crossAxisAlignment: CrossAxisAlignment.center,
          //                     children: [
          //                       const Icon(PhosphorIconsRegular.trash, color: Colors.black, size: 28,),
          //                       // const SizedBox(width:8),
          //                       // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
          //                   ],
          //                 ),
          //             ),
          //           ],
          //         )
          //       )
          //      )
          //      : sizedBox(0)
        ],
      ),
      
      
      
      // styledText(PaymentsList[0].description, Constants.linkifyBig, Constants.lightbg, 5),
      // sizedBox(16),
      
      
      // Row(
      //   children: [
      //     Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.black54,),
      //     SizedBox(width: 4,),
      //     Text('${DateFormat('MMM dd, yyyy · hh:mm aa', 'en_US').format(getDate(paymentsList[position].expiryDate!))}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
      //     // Text( (PaymentsList[position].createdOn != 'just now') ? '${(getTimeDiff(now, getDate(PaymentsList[position].createdOn!)))} ago' : 'just now', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.caption)),
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

