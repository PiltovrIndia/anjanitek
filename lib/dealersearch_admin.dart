import 'dart:convert';

import 'package:anjanitek/dealerdetails_admin.dart';
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

class DealerSearch extends StatefulWidget {

  @override
  _DealerSearchState createState() => _DealerSearchState();

}

class _DealerSearchState extends State<DealerSearch> {
  
  ScrollController? scrollController;
  DateTime today = DateTime.now();
  bool isLoading = false;
  bool isDataAvailable = false;
  bool endOfData = true;
  int offset = 0;
  int globalCount = 0;
  String? universityId, name, adminId, role, branch, id;
  String emptyStateMsg = '';
  List<Users> dealersList = [];
  List<Users> _filteredUsers = [];
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
    _filteredUsers = dealersList;
    // scrollController = new ScrollController()..addListener(_onSearchChanged);
    scrollController = new ScrollController()..addListener(_scrollListener);

    super.initState();
    
    
  }


  void _onSearchChanged() {
    String query = searchTextController.text.toLowerCase();
    List<Users> filteredList = dealersList.where((item) => item.id!.toLowerCase().contains(query)).toList();

    setState(() {
      _filteredUsers = filteredList;
    });
  }

  // get user data
  void getUserData() async {
    
    SharedPreferences preferences = await SharedPreferences.getInstance();
    // get the universityId from storage
    if(preferences.containsKey(Constants.id)){
      
      setState(() {
        emptyStateMsg = 'Loading. Please wait...';
        universityId = preferences.getString(Constants.universityId);
        adminId = preferences.getString(Constants.id);
        name = preferences.getString(Constants.name);
        role = preferences.getString(Constants.role);
        branch = preferences.getString(Constants.branch);
      });
      
    }

    
  }

  // initiate the search
  void searchNow(searchTerm) {

    setState(() {
      searchedText = searchTerm;
      dealersList.clear();
    });

    setState(() {
      isLoading = true;
    });
    getStudents();
  }

  // get requests for approval
  void getStudents() async {

    // check if there is any data
    if(searchedText.isNotEmpty) {
      // query parameters    
      Map<String, String> queryParams = {
        // "offset":"$offset",
        // "role":role!,
        // "requestStatus":Constants.submitted
        };

      var searchBy = '';
      if(_selectedValue == 1){
        searchBy = 'U2';
      }
      else if(_selectedValue == 2){
        searchBy = 'U3';
      }

      // API call
      // key, type, id, playerId
      // print("${APIUrls.user}${APIUrls.pass}/$searchBy/$searchedText/$offset/$adminId/$role");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/$searchBy/$searchedText/$offset/$adminId/$role", queryParams)), headers: {"Accept": "application/json"});
      // var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/$searchBy/$searchedText/$offset/$campus", queryParams)), headers: {"Accept": "application/json"});
// print(result.body);
      // get the result body which is JSON
      var jsonString = jsonDecode(result.body); 
      // convert jsonString to Map
      var jsonObject = jsonString as Map; 

      List<Users> list1;
      // check if the api returned success
      if(jsonObject['status'] == 200){
        // get the list data from jsonObject
        var requests = jsonObject['data'] as List;

        if(requests.isNotEmpty) {
          // convert to list
          list1 = requests.map<Users>((json) => Users.fromJson(json)).toList();
          
          // check if there are any requests for approval
          if(list1.isNotEmpty){
            setState(() {
              dealersList.addAll(list1);

            //   // check if there are any official requests
            // // if so, lets get them all into a separate list for bulk operations
            // if(list1.any((item) => item.requestType == 3.toString())){
              
            //   // parse through all the requests one by one
            //   for (var element in list1) {
            //     if(element.requestType == 3.toString()){
            //       // add the request to the list that is official
            //       dealersList.add(element);
            //     }
            //     else {
            //       // add the request to other list
            //       dealersList.add(element);
            //     }
            //   }
            // }

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
    else {
      // no requests pending for approval
      setState(() {
        emptyStateMsg = 'No pending requests';
        isLoading = false;
        endOfData = false;
      });
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
      startLoader();
    }
  }

  // show the loader while loading more items
  void startLoader(){
    setState((){
      isLoading = true;
      //print(offset);
      getStudents();
    });
  }

  Future<void> _refreshList() async {
    // Add your refresh logic here, e.g. fetching new data from a server
    await Future.delayed(const Duration(seconds: 2));
    getStudents();
  }

  // add and remove the selected years from the list
// void onRequestSelected(userItem option) {
  
//     setState(() {
//       if (selecteddealersList.contains(option)) {
//         selecteddealersList.remove(option);
//       } else {
//         selecteddealersList.add(option);
//       }
//     });
//   }

  @override
  Widget build(BuildContext context1) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Builder(builder: (context1) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          
            sizedBox(40),
              // Image.asset('assets/anjani_title.webp', scale: 2,), 
              AppHeader('Invoices', '', 1),
              sizedBox(24),
              Center(child: connectionStatus ? sizedBox(0) : Text('No network detected. Try again later!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.red, fontWeight: FontWeight.bold)),),
              Container(
                    margin: const EdgeInsets.fromLTRB(4, 0, 16, 0),
                    padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                    
                    child:
              Text('Dealer search', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
              ),
              sizedBox(16),
           Container(
                  child: 
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 0, 0, 8),
                      child: 
                  Wrap(
                    direction: Axis.horizontal,
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      
                      // OUT CITY OUTING
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedValue = 1;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              activeColor: Color(0xFF008160),
                              fillColor: MaterialStateProperty.all(Color(0xFF008160)),
                              value: 1,
                              groupValue: _selectedValue,
                              onChanged: (value) {
                                setState(() {
                                  _selectedValue = value!;
                                });
                              },
                            ),
                            Transform.translate(
                            offset: const Offset(-4, 0),
                            child: Text('Dealer name', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 0.4, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                          ),
                          ],
                        )
                      ),
                      
                      // LOCAL OUTING
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedValue = 2;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              activeColor: Color(0xFF008160),
                              fillColor: MaterialStateProperty.all(Color(0xFF008160)),
                              value: 2,
                              groupValue: _selectedValue,
                              onChanged: (value) {
                                setState(() {
                                  _selectedValue = value!;
                                });
                              },
                            ),
                            Transform.translate(
                            offset: const Offset(-4, 0),
                            child: Text('Dealer id', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 0.4, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                          ),
                          ],
                        )
                      ),
                      
                      // TEMPORARY DAY PASS OUTING
                      // Only visible if profileUpdated == 4
                      
                      
                      
                      
                    ],
                  )
                  )),
          
          Column(children: [

                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: 
                  Row(children: [
                    Flexible(
                      child: 
                          TextField(
                            controller: searchTextController,
                            autofocus: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(fontSize: 14.0,),
                            decoration: InputDecoration(
                              fillColor: Color(0xFFE6F2EF),
                              filled: true,
                              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              suffixIcon: IconButton(
                                icon: Icon(PhosphorIconsBold.magnifyingGlass, color: Color(0xFF008160), ),
                                onPressed: () => {
                                  // either search icon can be clicked or search button in the keyboard
                                  if (searchTextController.text.isNotEmpty) {
                                    searchNow(searchTextController.text),
                                  }
                                  else {
                                    showToast(context, 'Type to search',Constants.warning)
                                  }
                                },
                                ),
                              // suffixIcon: const Icon(PhosphorIcons.magnifyingGlass, color: Colors.grey),
                              hintText: (_selectedValue == 1) ? 'Type Dealer name to Search' : 'Type Dealer id to Search',
                              hintStyle: const TextStyle(
                                fontSize: 14.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Color(0xFF008160), width: 1.5),
                              ),
                            ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                    // print('ok');
                                    
                                    searchNow(value);
                                  }
                                  else {
                                    showToast(context, 'Type to search',Constants.warning);
                                  }
                                },
                          ),
                    ),
                    // SizedBox(width: 16,),
                    // InkWell(
                    //   onTap: () => {
                    //                 // Navigator.push(context, MaterialPageRoute(builder: (context) => Requests())),
                    //               },
                    //   child: Container(
                    //             decoration: BoxDecoration(
                    //                 color: Color(0xFF008160).withOpacity(0.1),
                    //                 shape: BoxShape.circle,
                    //               ),
                    //             width: 36,
                    //             height: 36,
                    //               alignment: Alignment.center,
                    //               child: Icon(PhosphorIcons.qrCode, color: Color(0xFF008160), size: 24,),
                    //           ),
                    // ),
                      
                  
                  ],)
                ),
                
            
              sizedBox(4),
              isSearchResultEmpty ? Text('No matching requests!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall )) : sizedBox(0),
              
          ],),
          
          
          
          Expanded(
            child: 
            
            dealersList.isEmpty ? 
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
                          itemCount: dealersList.length,
                          itemBuilder: (context, position){
                            
                            return Container(
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
          (dealersList.isNotEmpty && isLoading) ? const AppProgress(height: 30, width: 30,) : const SizedBox(height: 0,),
          
        ],
      ),
      ),
      )
    );
  }


Widget userItemCard(int position, BuildContext context1){
  return 
  InkWell(
    onTap: () => 
        // pass user details
        Navigator.push(context, MaterialPageRoute(builder: (context) => DealerDetailsAdmin(dealersList[position]))
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
          blurRadius: 24.0,
          spreadRadius: 0.3,
        ),
      ]
    ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                        Container(
                          height: 60, 
                          width: 60, 
                          alignment: Alignment.center,
                          //child: list[position].mediaCount == 0 ? Image.network(list[position].userImage) : Text('KP'), 
                          //child: list[position].mediaCount == 0 ? Image.network('https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png') : styledText(getAcronym(list[position].name), Constants.header3, Constants.lightbg), 
                          
                          decoration: BoxDecoration(
                            // borderRadius: BorderRadius.circular(8),
                            shape: BoxShape.circle, 
                            color: Colors.black12),
                            child: dealersList[position].userImage!.length > 2 ? 
                                // Image.network('https://smartcampusweb.vercel.app/user_sample.jpeg')
                                // Image.network(dealersList[position].userImage!)
                                Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        // borderRadius: BorderRadius.circular(8),
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(dealersList[position].userImage!),
                                        ),
                                      ),
                                    ) 
                                    : 
                                Text(getAcronym(dealersList[position].name!).toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black )),
                            
                            
                            ),

                            Expanded(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16, 2, 8, 0),
                            decoration: BoxDecoration(),
                            child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[

                                        Text(dealersList[position].name!, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, decorationStyle: TextDecorationStyle.dotted, decoration: TextDecoration.underline, fontWeight: FontWeight.w600 )),
                                        sizedBox(8),
                                        
                                        Row(children: [
                                          Text("${dealersList[position].id!}", style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium,)),
                                      
                                        ],),
                                        
                                       
                                      ],
                            ),),),
                        
                        ],
                      ),
                    
                    ]
                  ),
                  
            // approved by
            // (dealersList[position].requestStatus == Constants.approved) ?
            // Text('by ${dealersList[position].approverName} \non ${DateFormat('MMM d, y  h:mm a').format(getDate(dealersList[position].approvedOn!))}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall )) : sizedBox(0),
            
            // // issued by
            // (dealersList[position].requestStatus == Constants.issued) ?
            // Text('by ${dealersList[position].issuerName} \non ${dealersList[position].issuedOn}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall )) : sizedBox(0),

            // // rejected by
            // (dealersList[position].requestStatus == Constants.rejected) ?
            // Text('by ${dealersList[position].issuedOn != null ? ('${dealersList[position].issuerName } \non ${DateFormat('MMM dd, yyyy · hh:mm aa', 'en_US').format(getDate(dealersList[position].issuedOn!))}') : ('${dealersList[position].approverName} \non ${DateFormat('MMM dd, yyyy · hh:mm aa', 'en_US').format(getDate(dealersList[position].approvedOn!))}')}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall )) : sizedBox(0),

            // sizedBox(8),

            // show actions for SuperAdmin when the request is in the pending state
            // ((role == Constants.superAdmin || role == Constants.admin)) ? 
            
            // Row(
            //     mainAxisAlignment: MainAxisAlignment.end,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     mainAxisSize: MainAxisSize.max,
                
            //     children: <Widget>[


            //           MaterialButton(
            //             padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 8.0),
            //             color: Palette.appBackgroundSolitude,
            //             splashColor: Palette.textShade2,
            //             colorBrightness: Brightness.dark,
            //             elevation: 2,
            //             highlightElevation: 2,
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(8),
            //             ),
            //             // shape: StadiumBorder(),

            //             onPressed: (){
                        
            //               _displayDialog(context1, dealersList[position], position);

            //             },
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 const Icon(PhosphorIcons.xLight, color: Colors.red, size: 16,),
            //                 const SizedBox(width: 8,),
            //                 Text('Reject', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText2, color: Palette.red),),
            //               ],
            //             ) 
            //           ),     
            //       // InkWell(
            //       //   onTap: () =>  _displayDialog(context1, list[position], position),
            //       //   child: Container(
            //       //   padding: EdgeInsets.all(8.0),
            //       //   child: Text('Reject', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText1, color: Palette.red )),
            //       //   ),
            //       // ),

            //       const SizedBox(
            //         width: 8,
            //       ),
            //       MaterialButton(
            //             padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 8.0),
            //             color: Palette.primary,
            //             splashColor: Palette.textShade2,
            //             colorBrightness: Brightness.dark,
            //             elevation: 2,
            //             highlightElevation: 2,
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(8),
            //             ),
            //             // shape: StadiumBorder(),

            //             onPressed: (){
                        
            //               updateRequest(context1, dealersList[position], Constants.approved, position, context1, "");

            //             },
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 const Icon(PhosphorIcons.check, color: Colors.white, size: 16,),
            //                 const SizedBox(width: 8,),
            //                 Text('Approve', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText2, color: Palette.white),),
            //               ],
            //             ) 
            //           ),
                  
                  
            //     ],
            //   ) 
            //   : sizedBox(0),
          

          // show the actions to OutingAdmin/Issuer when the request is approved
          // ((role == Constants.outingAdmin || role == Constants.issuer)) ? 
            
          //   Row(
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       crossAxisAlignment: CrossAxisAlignment.center,
          //       mainAxisSize: MainAxisSize.max,
                
          //       children: <Widget>[


          //             MaterialButton(
          //               padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 8.0),
          //               color: Palette.appBackgroundSolitude,
          //               splashColor: Palette.textShade2,
          //               colorBrightness: Brightness.dark,
          //               elevation: 2,
          //               highlightElevation: 2,
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //               // shape: StadiumBorder(),

          //               onPressed: (){
                        
          //                 _displayDialog(context1, dealersList[position], position);

          //               },
          //               child: Row(
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 mainAxisSize: MainAxisSize.min,
          //                 children: [
          //                   const Icon(PhosphorIcons.xLight, color: Colors.red, size: 16,),
          //                   const SizedBox(width: 8,),
          //                   Text('Reject', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText2, color: Palette.red),),
          //                 ],
          //               ) 
          //             ),     
          //         // InkWell(
          //         //   onTap: () =>  _displayDialog(context1, list[position], position),
          //         //   child: Container(
          //         //   padding: EdgeInsets.all(8.0),
          //         //   child: Text('Reject', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText1, color: Palette.red )),
          //         //   ),
          //         // ),

          //         const SizedBox(
          //           width: 8,
          //         ),
          //         MaterialButton(
          //               padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 8.0),
          //               color: Palette.primary,
          //               splashColor: Palette.textShade2,
          //               colorBrightness: Brightness.dark,
          //               elevation: 2,
          //               highlightElevation: 2,
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //               // shape: StadiumBorder(),

          //               onPressed: (){
                        
          //                 updateRequest(context1, dealersList[position], Constants.issued, position, context1, "");

          //               },
          //               child: Row(
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 mainAxisSize: MainAxisSize.min,
          //                 children: [
          //                   const Icon(PhosphorIcons.check, color: Colors.white, size: 16,),
          //                   const SizedBox(width: 8,),
          //                   Text('Issue', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyText2, color: Palette.white),),
          //                 ],
          //               ) 
          //             ),
                  
                  
          //       ],
          //     ) 
          //     : sizedBox(0),

           
            
          ]
        ),
        ),
    );

}
  // show user details
  void showUserDetails(Users userItem){

    Users user = Users();
    user.name = userItem.name;
    user.email = userItem.email;
    user.id = userItem.id;
    user.role = userItem.role;
    user.userImage = userItem.userImage;
    user.gcmRegId = userItem.gcmRegId;

    // navigate to show user details
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Student360(userItem.id.toString(), userItem.campusId.toString())));
    // Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailData(user)));

  }

}
