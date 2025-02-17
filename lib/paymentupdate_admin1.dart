import 'dart:convert';
import 'dart:io';

// import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:anjanitek/paymentupdate_admin.dart';
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
import 'package:anjanitek/utils/app_header.dart';
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
class PaymentUpdateAdmin1 extends StatefulWidget {
  // user object is sent from previous screen
  const PaymentUpdateAdmin1(this.dealerUser);
  final Dealers dealerUser;
  
  @override
  _PaymentUpdateAdmin1State createState() => _PaymentUpdateAdmin1State();
}

class _PaymentUpdateAdmin1State extends State<PaymentUpdateAdmin1> with TickerProviderStateMixin {

  TextEditingController creditAmountController = TextEditingController();
  late AnimationController _controller;
  late AnimationController _controllerCards;
  String creditAmount='', transactionId='', phoneNumber='', adminId='';
  static String name = '', role = '',
  id='', 
  accountName='',dealerId='',salesId='';
  static int isActive = 1;
  static String updateMsg = '';
  bool refreshCheckProgress = false;
  bool submitProgress = false;
  List<Invoices> dealerInvoices = [];
  List<Invoices> sortedInvoicesList = [];
  ScrollController? scrollController;
  
  int offset = 0;
  bool connectionStatus = true;
  
  bool anyOutstanding = true;
  double totalOutstanding = 0;
  double totalCredit = 0;
  double remainingCredit = 0;
  
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
          role = prefs.get(Constants.role) as String;
          isActive = prefs.get(Constants.isActive) as int;
          
            if(prefs.get(Constants.role) == Constants.dealer){

              dealerId = prefs.get(Constants.dealerId) as String;
              accountName = prefs.get(Constants.accountName) as String;
              salesId = prefs.get(Constants.salesId) as String;
            }
          });
        } 
        refreshUserPaymentUpdateAdmin1(context);
    }

      // refresh the list
      Future<void> _refreshList() async {
        // Add your refresh logic here, e.g. fetching new data from a server
        await Future.delayed(const Duration(seconds: 2));
        refreshUserPaymentUpdateAdmin1(context);
      }


    // Get all the pending invoices of the selected dealer
    void refreshUserPaymentUpdateAdmin1(BuildContext context) async {

      if(await checkInternetConnectivity()){
        setState(() {
          refreshCheckProgress = true;
        });
        // var uuid = await DeviceUuid().getUUID();
        // query parameters    
        Map<String, String> queryParams = {
        };

        // API call
        // print("${APIUrls.amount}${APIUrls.pass}/U2/${widget.dealerUser.dealerId}/$offset");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.amount}${APIUrls.pass}/U6/Dealer/${widget.dealerUser.dealerId}/$offset", queryParams)), headers: {"Accept": "application/json"});
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
              dealerInvoices = invoicesData.map<Invoices>((json) => Invoices.fromJson(json)).toList();
              // sort invoices by invoice date
              dealerInvoices.sort((a,b) => DateTime.parse(a.invoiceDate!).compareTo(DateTime.parse(b.invoiceDate!)));
              
              // Calculate pending count and update each invoice
              double pendingCount = 0.0;
              List<Invoices> updatedList = dealerInvoices.map((invoice) {
                pendingCount += invoice.pending!;
                invoice.appliedAmount = 0;
                invoice.remaining = invoice.pending;
                return invoice;
              }).toList();

              setState(() {
                totalOutstanding = pendingCount;
                sortedInvoicesList = updatedList;
              });



              
              setState(() {
                // Get new user data
                // invoices = invoicesData.where((element) => false);
                // invoices.
                double totalSum = dealerInvoices.fold(0.0, (double sum, Invoices invoice) {
                  return sum + (invoice.pending ?? 0.0);
                });
                totalOutstanding = totalSum;

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
          });
          
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
          refreshUserPaymentUpdateAdmin1(context);
          
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
        if(dealerInvoices.length-5 == offset){
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
      refreshUserPaymentUpdateAdmin1(context);
    });
  }


  // Function to handle the "Unselect" action for each invoice
  void handleSelection(invoiceItem) {
    // if(remainingCredit <= 0){
    //     // don't do anything
    // }
    // else {

        if(invoiceItem.appliedAmount > 0){

            List<Invoices> prevInvoices = List<Invoices>.from(dealerInvoices);

            // Update the invoices list
            prevInvoices = prevInvoices.map((invoice) {
              if (invoice.invoiceNo == invoiceItem.invoiceNo && invoice.appliedAmount! > 0) {
                // print("Amount applying: ${invoice.appliedAmount}");
                // print("Remaining: ${remainingCredit + invoice.appliedAmount!}");

                setState(() {
                  remainingCredit += invoice.appliedAmount!;
                });

                // Update only selected keys of the object
                invoice.appliedAmount = 0;
                invoice.remaining = invoice.pending;
                invoice.status = invoice.amountPaid! > 0 ? 'PartialPaid' : 'NotPaid';
              }
              return invoice;
            }).toList();

            setState(() {
              dealerInvoices = prevInvoices;
            });

        }
        else {

          List<Invoices> prevInvoices = List<Invoices>.from(dealerInvoices);

          // Update the invoices list
          prevInvoices = prevInvoices.map((invoice) {
            if (invoice.invoiceNo == invoiceItem.invoiceNo && remainingCredit > 0 && invoice.appliedAmount == 0) {
              
              double applyAmount = (invoice.pending! < remainingCredit) ? invoice.pending! : remainingCredit;

              // Update the remaining credit
              setState(() {
                remainingCredit -= applyAmount;
              });

              // Update only the selected keys of the invoice object
              invoice.appliedAmount = applyAmount;
              invoice.remaining = invoice.pending! - applyAmount;
              invoice.status = (invoice.pending! - applyAmount) == 0 ? 'Paid' : 'PartialPaid';
            }
            return invoice;
          }).toList();

          setState(() {
            dealerInvoices = prevInvoices;
          });

        }
    // }
    
  }


  // on subitting values
  void onSubmit(BuildContext context){
    // validate() methods call the validator functions for all form elements
    if(totalCredit > 0 && remainingCredit == 0){ 
      
      // verify if collegeId exists and matches with the phoneNumber
      setState(() {
        submitProgress = true;
      });
      // verify if collegeId exists and matches with the phoneNumber
      submitPayment(context);

    }
    else {

      showToast(context, 'Select invoices to apply remaining amount',Constants.error);
    }
  }

  

  // find the user
  void submitPayment(BuildContext context) async {

    try{
    // var uuid = await DeviceUuid().getUUID();
    // query parameters    
    Map<String, String> queryParams = {
      // "campusId":selectedCampus!,
      // "collegeId":creditAmount,
      };

      // add time to the date
      DateTime now = DateTime.now();
      DateTime fromDate1 = DateTime(
        now.year,
        now.month,
        now.day,
        now!.hour,
        now!.minute,
      );

    // const invoicesWithAppliedAmount = dealerInvoices.filter(invoice => invoice.appliedAmount > 0);
    List<Invoices> invoicesWithAppliedAmount = dealerInvoices.where((invoice) => invoice.appliedAmount! > 0).toList();

    // API call 
    // print("/api/v2/payments/"+APIUrls.pass+"/webbulk/"+widget.dealerUser.dealerId.toString()+"/"+totalCredit.toString()+"/credit/"+Uri.encodeComponent(jsonEncode(invoicesWithAppliedAmount))+"/-/"+DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(fromDate1)+"/"+id+"/-");
    var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.payments}${APIUrls.pass}/webbulk/${widget.dealerUser.dealerId}/${totalCredit.toString()}/credit/${Uri.encodeComponent(jsonEncode(invoicesWithAppliedAmount))}/-/${DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(fromDate1)}/$id/-", queryParams)), headers: {"Accept": "application/json"});
    // print(result.body);
    // Decode the JSON string into a Map using the jsonDecode function
    Map<String, dynamic> jsonObject = jsonDecode(result.body);
    // Map<String, dynamic> jsonObject = result.body;
    // print(result.body);
    // user object list
    
    // check if the api returned success
    if(jsonObject['status'] == 200){
      
        // get the user data from jsonObject
        // Map<String, dynamic> userdata = jsonObject['data'];
        

        
        // print(user.username);
        
        setState(() {
          // OTP sent
          totalCredit = 0;
          remainingCredit = 0;
          submitProgress = false;
          dealerInvoices.clear();
          sortedInvoicesList.clear();
          // errorMsg = '';
          
        });

        showToast(context, 'Credit updated!',Constants.success);
        creditAmountController.text = ''; //clear();

        refreshUserPaymentUpdateAdmin1(context);

    }
    else if(jsonObject['status'] == 401 || jsonObject['status'] == 402 || jsonObject['status'] == 404 || jsonObject['status'] == 500){
      // no data exists
      setState(() {
        // get the error message
        submitProgress = false;
        // errorMsg = jsonObject['message'];
      });
      
    }
    else {

        setState(() {
          submitProgress = false;
        });
    }
      

    //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Verifying...'), duration: Duration(seconds: 2),));
    }
    catch(e){
      print(e);
    }
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
            Align(
              alignment: Alignment.topCenter,
              child:
                SafeArea(

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
                                // AppHeader('Invoices', '', 1),
                                sizedBox(8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Update Credit', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.bold, color:Color(0xFF008060)), ),
                                      sizedBox(4),
                                      Text('${widget.dealerUser.accountName}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold), ),      
                                    ],
                                  ),
                                  InkWell(
                                    onTap: (){
                                          Navigator.pop(context);
                                        },
                                    child: Icon(PhosphorIconsRegular.x, size: 24, color: Colors.black87,)
                                  ),
                                ],),
                                
                                sizedBox(16),
                                

                                // sizedBox(16),
                                
                                Container(
                                  
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    controller: creditAmountController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                                      hintText: 'Enter credited amount',
                                      ),
                                    validator: (value) { // validator function is called on calling form validate() method
                                      if (value!.isEmpty) {
                                        return '';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => {
                                      setState(() {
                                        
                                        totalCredit = double.tryParse(value) ?? 0.0;
                                        remainingCredit = double.tryParse(value) ?? 0.0;
                                        
                                      }),
                                      
                                      },
                                    // onSaved: (value) => creditAmount = value!,
                                    style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w500, letterSpacing: 1.5),
                                  ),
                                ),

                                sizedBox(8),
                                Row(
                                  children: [
                                    Text("Total Outstanding: ", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500)),
                                    Text("₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstanding)}", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.red, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                
                                totalCredit > 0 ? 
                                Row(
                                  children: [
                                    Text("New Outstanding: ", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500)),
                                    Text("₹ ${NumberFormat("#,##,##0.00", "en_IN").format(totalOutstanding - totalCredit)}", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.blue, fontWeight: FontWeight.w500)),
                                  ],
                                )
                                : sizedBox(0),
                                
                                totalCredit > 0 ? 
                                Row(
                                  children: [
                                    Text("Remaining: ", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w500)),
                                    Text("₹ ${NumberFormat("#,##,##0.00", "en_IN").format(remainingCredit)}", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.green, fontWeight: FontWeight.w500)),
                                  ],
                                )
                                : sizedBox(0),
                                
                                sizedBox(8),
                                Text("Select Invoices", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.bold)),
                                
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
                                //     onPressed: () => updatePaymentUpdateAdmin1(context),
                                //   ),
                                


                                
                              ],
                            
                            ),

                            sizedBox(4),

                            dealerInvoices.isNotEmpty ?
                            Expanded(
                              
                              child: RefreshIndicator(
                              onRefresh: _refreshList,
                              child: 
                              ListView.builder(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  controller: scrollController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: dealerInvoices.length,
                                  itemBuilder: (context, index){
                                    
                                    return  FadeTransition(opacity: _controller,
                                          child:
                                          ScaleTransition(scale: CurvedAnimation(
                                                    parent: _controllerCards,
                                                    curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                                                  ),alignment: Alignment.bottomCenter,
                                                  child:
                                                Container(
                                                      margin: EdgeInsets.fromLTRB(0,8,0,8),
                                                      padding: EdgeInsets.fromLTRB(16,16,16,8),
                                                      decoration: BoxDecoration(
                                                        color: dealerInvoices[index].appliedAmount! > 0 ? Colors.blue.shade100 : Colors.white,
                                                        // color: Colors.white,
                                                        borderRadius: const BorderRadius.all(Radius.circular(24)),
                                                        border: Border.all(
                                                                  color: dealerInvoices[index].appliedAmount! > 0 ? Colors.blue : Colors.black12, // Set the color of the border here
                                                                  width: 1, // Set the width of the border here
                                                                ),
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
                            : Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(PhosphorIconsRegular.receipt, color: Color(0xFFAAAAAA), size: 32, ),
                                    sizedBox(8),
                                    Text('No invoices yet!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                  ],
                                )
                              )
                            ),
                            
                            // loader while fetching data
                            refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                            
                            dealerInvoices.isNotEmpty ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sizedBox(16),
                                  // show Sign in button
                                  (submitProgress) ? AppProgress(height: 30, width: 30,) : MaterialButton(
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

                                      // Container(
                                      //   alignment: Alignment.centerLeft,
                                      //   child: (isLoading) ? const AppProgress(height: 30, width: 30,) : const SizedBox(height: 0,),
                                      // ),
                                ],
                              ) : sizedBox(0),
                          
                            


                          
                          ],
                        )
                  )
                ),
            )
        )
    );
  }

  // Refresh profile
  // refreshPaymentUpdateAdmin1(BuildContext context) async {

  //   //showToast(context, "Verifying your identity!");
  //   setState(() {updateMsg = 'Checking for updtes. Please wait...';});
    
    

  // }


// single feed card
Widget invoiceCard(int position){
  return InkWell(
    onTap: () => handleSelection(dealerInvoices[position]),
    // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CircularsAdmin())),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      dealerInvoices[position].appliedAmount! > 0 ? 
          Icon(PhosphorIconsFill.checkCircle, size: 24, color: Colors.blue,)
          : Icon(PhosphorIconsRegular.checkCircle, size: 24, color: Colors.black45),

          
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${dealerInvoices[position].invoiceNo}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87, fontWeight: FontWeight.w500 )),
          SizedBox(width: 8,),
          // Text('${dealerInvoices[position].invoiceType}', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.titleMedium, fontSize: 12, fontWeight: FontWeight.bold, color: dealerInvoices[position].invoiceType == 'ATL' ? Colors.redAccent : Color(0xFFC41306), )),
          Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                      color: dealerInvoices[position].invoiceType == 'ATL' ? Color(0x22FF5252) : Color(0x22C41306),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  child: Text('${dealerInvoices[position].invoiceType}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.bold, color: dealerInvoices[position].invoiceType == 'ATL' ? Color(0xFFFF5252) : Color(0xFFC41306))),  
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
              Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(dealerInvoices[position].totalAmount!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              Text('Invoiced Amount' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ),
          // (dealerInvoices[position].status != Constants.Paid) ?
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              (dealerInvoices[position].remaining! > 0) ?
              Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(dealerInvoices[position].remaining!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.red))
              : Text('₹ 0', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.red)),
              // Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(dealerInvoices[position].pending!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.red)),
              Text('Pending' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ) 
          // : sizedBox(0),
        ],
      ),
      sizedBox(8),
      // divider(Colors.black12),
      DottedLine(),
    
    
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
              Text(DateFormat('d-MMM-y', 'en_US').format(getDate(dealerInvoices[position].invoiceDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge,color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              Text('Invoice date' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5, color: Colors.black45, ), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ),
          Expanded(child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              (dealerInvoices[position].appliedAmount! > 0) ? 
              // <div className='text-red-600'> - {item.appliedAmount}</div> : ''
              Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(dealerInvoices[position].appliedAmount!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.blue))
              : sizedBox(0),
              // Text(DateFormat('d-MMM-y', 'en_US').format(getDate(dealerInvoices[position].expiryDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
              // Text('Due date' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5, color: Colors.black45, ), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
            ],
          ),
          ),
        ],
      ),
      
      
      sizedBox(8),
      
    
      
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

