import 'dart:convert';

import 'package:anjanitek/dealer_details.dart';
import 'package:anjanitek/dealerdetails_admin.dart';
import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/invoices.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:anjanitek/directory_searchdetail.dart';
import 'package:anjanitek/modals/users.dart';
// import 'package:anjanitek/requests_adminhistory.dart';
// import 'package:anjanitek/requests_report.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/app_header.dart';
import 'package:http/http.dart' show get;
import 'package:anjanitek/utils/divider.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';

class OutstandingDealers extends StatefulWidget {

  @override
  _OutstandingDealersState createState() => _OutstandingDealersState();

}

class _OutstandingDealersState extends State<OutstandingDealers> {
  
  ScrollController? scrollController;
  DateTime today = DateTime.now();
  bool isLoading = false;
  bool isDataAvailable = false;
  bool endOfData = true;
  int offset = 0;
  int days = 0;
  int globalCount = 0;
  String? name, adminId, role, branch, id;
  String emptyStateMsg = '';
  String state = 'All';
  List<Dealers> dealersList = [];
  List<Dealers> _filteredDealers = [];
  List<Invoices> invoicesList = [];
  List<OutstandingDealersModal> outstandingDealersList = [];
  DateTime now = new DateTime.now();
  TextEditingController _textFieldController = TextEditingController();
  TextEditingController searchTextController = TextEditingController();
  String searchedText = '';
  bool isSearchResultEmpty = false;
  
  int _selectedTabIndex = 0;
  bool connectionStatus = true;

  int _selectedValue = 1;
  @override
  void initState(){
    
    _textFieldController.text = '';
    getUserData();
    _filteredDealers = dealersList;
    
    scrollController = new ScrollController()..addListener(_scrollListener);
    super.initState();
    
    
  }


  void _onSearchChanged() {
    String query = searchTextController.text.toLowerCase();
    List<Dealers> filteredList = dealersList.where((item) => item.dealerId!.toLowerCase().contains(query)).toList();

    setState(() {
      _filteredDealers = filteredList;
    });
  }

  // get user data
  void getUserData() async {
    
    SharedPreferences preferences = await SharedPreferences.getInstance();
    // get the universityId from storage
    if(preferences.containsKey(Constants.id)){
      
      setState(() {
        emptyStateMsg = 'Loading. Please wait...';
        
        adminId = preferences.getString(Constants.id);
        name = preferences.getString(Constants.name);
        role = preferences.getString(Constants.role);
        branch = preferences.getString(Constants.branch);
      });
      
    }

    getOutstandingDealers ();

    
  }

  // initiate the search
  void searchNow(searchTerm) {

    setState(() {
      searchedText = searchTerm;
      dealersList.clear();
    });

   
    getOutstandingDealers ();
  }

  // get requests for approval
  void getOutstandingDealers () async {

     setState(() {
      isLoading = true;
    });

      // query parameters    
      Map<String, String> queryParams = {
        // "offset":"$offset",
        // "role":role!,
        // "requestStatus":Constants.submitted
        };

      // API call
      // key, type, id, playerId
      // print("${APIUrls.user}${APIUrls.pass}/U3/$searchBy/$id/$role/$branch/$selectedCampus/$universityId/$searchedText/$offset");
      // print("${APIUrls.user}${APIUrls.pass}/U5/$role/$offset/$days/$state/$adminId");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U5/$role/$offset/$days/$state/$adminId", queryParams)), headers: {"Accept": "application/json"});
      // var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/$searchBy/$searchedText/$offset/$campus", queryParams)), headers: {"Accept": "application/json"});
// print(result.body);
      // get the result body which is JSON
      var jsonString = jsonDecode(result.body); 
      // convert jsonString to Map
      var jsonObject = jsonString as Map; 

      List<Dealers> list1;
      List<Invoices> list2;
      // check if the api returned success
      if(jsonObject['status'] == 200){
        // get the list data from jsonObject
        var requests = jsonObject['data'] as List;

        if(requests.isNotEmpty) {
          // convert to list
          list1 = requests.map<Dealers>((json) => Dealers.fromJson(json)).toList();
          list2 = requests.map<Invoices>((json) => Invoices.fromJson(json)).toList();
          
          // check if there are any requests for approval
          if(list1.isNotEmpty){
            dealersList.clear();
              invoicesList.clear();
            setState(() {
              dealersList.addAll(list1);
              invoicesList.addAll(list2);

              // we are parsing the outstanding dealers into a separate class objects to only display the "combined pending" and "combined expiry date"
              Map<String, OutstandingDealersModal> dealersMap = {};

              for (var item in requests) {
                  var dealerId = item['dealerId'];
                  var accountName = item['accountName'];
                  double pendingAmount = (item['pending'] as num?)!.toDouble();
                  var invoiceDate = item['invoiceDate'];
                  var expiryDate = item['expiryDate'];

                  // If dealerId already exists in the map, add the pending amount to the existing amount
                  if (dealersMap.containsKey(dealerId)) {

                    double currentAmount = dealersMap[dealerId]!.amount!;
                    double newAmount = currentAmount + (pendingAmount);
                    dealersMap[dealerId]!.amount = newAmount;

                    ((getDate(dealersMap[dealerId]!.expiryDate!).difference(getDate(expiryDate)).inDays) <= 0) ?
                    dealersMap[dealerId]!.expiryDate = expiryDate : '';

                  } else {
                    // If dealerId does not exist, create a new entry
                    dealersMap[dealerId] = OutstandingDealersModal(
                      dealerId: dealerId,
                      accountName: accountName,
                      invoiceDate: invoiceDate,
                      expiryDate: expiryDate,
                      amount: pendingAmount,
                    );
                  }
                }

                // consolidated dealer list
                outstandingDealersList = dealersMap.values.toList();
              
              isLoading = false;
              isDataAvailable = true;

            });
          }
          else {
            // no requests pending for approval
            setState(() {
              emptyStateMsg = 'No match found';
              isLoading = false;
              isDataAvailable = false;
            });
          }

        }
          else {
            // no requests pending for approval
            setState(() {
              emptyStateMsg = 'No match found';
              isLoading = false;
              isDataAvailable = false;
              endOfData = false;
            });
          }

        
      } else {
            // no requests pending for approval
            setState(() {
              emptyStateMsg = 'No match found';
              isLoading = false;
              isDataAvailable = false;
              endOfData = false;
            });
            showToast(context, emptyStateMsg,Constants.warning);
          }

    
  }
  
  // detect scroll to end and load more items
  void _scrollListener(){
    if(scrollController!.position.pixels == scrollController!.position.maxScrollExtent){
      setState(() {
        // increment offset by 20
        offset = offset+20;
      });
      // show up the loader
      // startLoader();
    }
  }

  // show the loader while loading more items
  void startLoader(){
    setState((){
      isLoading = true;
      //print(offset);
      getOutstandingDealers ();
    });
  }

  Future<void> _refreshList() async {
    // Add your refresh logic here, e.g. fetching new data from a server
    await Future.delayed(const Duration(seconds: 2));
    getOutstandingDealers ();
  }

  @override
  Widget build(BuildContext context1) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.all(16),
        child: Builder(builder: (context1) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          
            AppHeader('Invoices', '', 1),
            Text('Outstanding Dealers', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
            Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
            sizedBox(8),
            Column(children: [

                sizedBox(4),
                isSearchResultEmpty ? Text('No matching requests!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall )) : sizedBox(0),
                
            ],),
            
            
          
          Expanded(
            child: 
            
            outstandingDealersList.isEmpty ? 
                  // Container(
                  //   alignment: Alignment.center,
                  //   child: styledText(emptyStateMsg, Constants.body2, Constants.darkbg),
                  //   )

                  (!isLoading? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // loader while fetching data
                          // isLoading? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                            width: 64,
                            height: 64,
                              alignment: Alignment.center,
                              child: Icon(PhosphorIconsRegular.userFocus, color: Colors.black38, size: 48,),
                          ),
                        sizedBox(8),
                        
                  ],) : const AppProgress(height: 30, width: 30,))
                  : 
                  RefreshIndicator(
                        onRefresh: _refreshList,
                        child: 
                        ListView.builder(
                          controller: scrollController,
                          scrollDirection: Axis.vertical,
                          // itemCount: dealersList.length,
                          itemCount: outstandingDealersList.length,
                          itemBuilder: (context, position){
                            
                            return Container(
                              // margin: EdgeInsets.all(16),
                              margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              child: userItemCard(position, context1),
                            );
                          },
                        ),
                        // ListView.builder(
                        // controller: scrollController,
                        // scrollDirection: Axis.vertical,
                        // itemCount: dealersList.length,
                        // itemBuilder: (context, position){
                          
                        //   return CheckboxListTile(
                            
                        //       title: userItemCard(position, context1),
                        //       value: selecteddealersList.contains(dealersList[position]),
                        //       onChanged: (bool? value) {
                                
                        //           setState(() {
                        //             if (value!) {
                        //               onRequestSelected(dealersList[position]);
                        //             }
                        //             else {
                        //               onRequestSelected(dealersList[position]);
                        //             }
                        //           });
                        //       },
                        //     );
                        //   },
                        // ),
              ),
          ),
          (outstandingDealersList.isNotEmpty && isLoading) ? const AppProgress(height: 30, width: 30,) : const SizedBox(height: 0,),
          
        ],
      ),
      ),
      ),
      )
    );
  }


Widget userItemCard(int position, BuildContext context1){
  return 
  InkWell(
    onTap: () => 
        // pass the selected dealer id
        // get the dealer details and show for the selected invoice in the next screen
        Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetails(adminId!, name!, outstandingDealersList[position].dealerId!, outstandingDealersList[position].accountName!))
      ),
        
  child: 
  Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          offset: const Offset(0.0, 0.0),
          blurRadius: 4.0,
          spreadRadius: 0.3,
        ),
      ]
    ),
      padding: const EdgeInsets.all(8),
      // margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            
            Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[

                            Expanded(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(8, 2, 8, 0),
                            decoration: BoxDecoration(),
                            child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[

                                        Text(outstandingDealersList[position].accountName!, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, decorationStyle: TextDecorationStyle.dotted, decoration: TextDecoration.underline, fontWeight: FontWeight.w600 )),
                                        sizedBox(4),
                                        Text(outstandingDealersList[position].dealerId!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium,)),
                                        sizedBox(8),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Text(DateFormat('d-MMM-y', 'en_US').format(getDate(invoicesList[position].invoiceDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
                                              Text('₹ ${NumberFormat("#,##,##0.00", "en_IN").format(outstandingDealersList[position].amount!.toDouble())}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.red)),
                                              // Text('Pending' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
                                            ],
                                          ),
                                          Text(DateFormat('d-MMM-y', 'en_US').format(getDate(outstandingDealersList[position].expiryDate!)) , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.red, fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
                                            // Text('Due date' , style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, height: 1.5), overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: true, ),
                                          sizedBox(4),    
                                      ],
                            ),),),
                        
                        ],
                      ),
                    
                    ]
                  ),
                  
            
          ]
        ),
        ),
    );

}

}

class OutstandingDealersModal {
  String? dealerId;
  String? accountName;
  String? invoiceDate;
  String? expiryDate;
  double? amount;


  OutstandingDealersModal({this.dealerId,this.accountName, this.invoiceDate, this.expiryDate, this.amount});

  OutstandingDealersModal.fromJson(Map<String, dynamic> json): 
  dealerId = json['dealerId'], 
  accountName = json['accountName'], 
  invoiceDate = json['invoiceDate'], 
  expiryDate = json['expiryDate'],
  amount = (json['amount'] as num?)?.toDouble();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['dealerId']= dealerId;
    data['accountName']= accountName;
    data['invoiceDate']= invoiceDate;
    data['expiryDate']= expiryDate;
    data['amount']= amount;
    return data;
  }
}
