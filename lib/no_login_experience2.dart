import 'dart:ui';
import 'dart:async';

import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/designs.dart';
import 'package:anjanitek/showrooms.dart';
import 'package:anjanitek/utils/design_details.dart';
import 'package:anjanitek/utils/designoftheday.dart';
import 'package:anjanitek/verify.dart';
import 'dart:convert';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AnjaniTekApp2 extends StatefulWidget {
  const AnjaniTekApp2({super.key});

  @override
  AnjaniTekApp2State createState() => AnjaniTekApp2State();
}

class AnjaniTekApp2State extends State<AnjaniTekApp2> {


  List<Catalogue> showCatalogues = [];
  List<Product> designOfTheDayList = [];
  List<ProductTag> productTags = [];
  late List<ProductTag> productTagsList = [];
  List<String> uniqueProductTypes = [];
   List<ProductTag> sizes = [];
  bool refreshCheckProgress = true;
  bool checkDesignOfTheDayList = true;
  String plant1 = 'https://www.anjanitiles.com/assets/img/about/about-1.jpg';
  String plant2 = 'https://www.anjanitiles.com/assets/img/about/vennar.jpg';

  @override
  void initState() {
      
      // get reference to internal database
      logUserSession();
      // getCatalogues(context);
      // getDesignOfTheDay(context);
      // getProductTags(context);
    
    super.initState();
    
  }

  // log user session
    // also check if the user is active or not
    // if not active then logout the user
    void logUserSession() async {

      if(await checkInternetConnectivity()){
        
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.user}${APIUrls.pass}/U0/visitor/visitor/visitor", {})), headers: {"Accept": "application/json"});

        getDesignOfTheDay().then((value) {
            final Map<String, dynamic> map = value as Map<String, dynamic>;
            setState(() {
              // final List<dynamic> products = map['products'] as List<dynamic>? ?? [];
              // designOfTheDayList = products.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();

              // final List<dynamic> tags = map['tags'] as List<dynamic>? ?? [];
              // productTagsList = tags.map((t) => ProductTag.fromJson(t as Map<String, dynamic>)).toList();
              
              designOfTheDayList = map['products'] as List<Product>? ?? [];
              productTagsList = map['tags'] as List<ProductTag>? ?? [];

              checkDesignOfTheDayList = true;
            });
          });  
        
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          logUserSession();
          
        });
      }
    }

    // find the user
    // void getCatalogues(BuildContext context) async {

    //   setState(() {
    //     refreshCheckProgress = true;
    //   });
    //   // var uuid = await DeviceUuid().getUUID();
    //   // query parameters    
    //   Map<String, String> queryParams = {
        
    //     };

    //   // API call
    //   // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
    //   var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.catalogues}${APIUrls.pass}/1", queryParams)), headers: {"Accept": "application/json"});
    //   // print(result.body);
      
    //   // Decode the JSON string into a Map using the jsonDecode function
    //   Map<String, dynamic> jsonObject = jsonDecode(result.body);
    //   // print(result.body);
    //   // user object list
      
    //   // check if the api returned success
    //   if(jsonObject['status'] == 200){
        
    //       // get the user data from jsonObject
    //       var showCataloguesData = jsonObject['data'] as List;
    //         // Map<String, dynamic> invoicesData = jsonObject['data'];

    //         if(showCataloguesData.isNotEmpty){
            

    //           List<Catalogue> cataloguesList = showCataloguesData.map<Catalogue>((json) => Catalogue.fromJson(json)).toList();
          
    //             setState(() {
    //               // Get new user data
    //               showCatalogues = cataloguesList;
    //               refreshCheckProgress = false;
    //             });
    //         }
    //   }
    //   else if(jsonObject['status'] == 402){
    //     // no data exists
    //     setState(() {
    //       // get the error message
    //       refreshCheckProgress = false;
    //     });
        
    //   }
    //   else if(jsonObject['status'] == 404){
    //     // no data exists
    //     setState(() {
    //       // get the error message
    //       refreshCheckProgress = false;
    //     });
        
    //   }
    //   else {

    //       setState(() {
    //         refreshCheckProgress = false;
    //         // showToast(context, 'Error, try again later!',Constants.error);
    //       });
    //   }
    // }

    // get design of the day
    // void getDesignOfTheDay(BuildContext context) async {

    //   setState(() {
    //     refreshCheckProgress = true;
    //   });
      
    //   // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
    //   var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U1/0/0", {})), headers: {"Accept": "application/json"});
    //   // var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U9", {})), headers: {"Accept": "application/json"});
    //   // print(result.body);
      
    //   Map<String, dynamic> jsonObject = jsonDecode(result.body);
      
    //   if(jsonObject['status'] == 200){
        
    //       var showDesignDayData = jsonObject['data'] as List;

    //         if(showDesignDayData.isNotEmpty){
            

    //           List<Product> designDayList = showDesignDayData.map<Product>((json) => Product.fromJson(json)).toList();
          
    //             setState(() {
    //               // Get new user data
    //               designOfTheDayList = designDayList;
    //               refreshCheckProgress = false;
    //             });
    //         }
    //   }
    //   else if(jsonObject['status'] == 402 || jsonObject['status'] == 404){
    //     // no data exists
    //     setState(() {
    //       // get the error message
    //       refreshCheckProgress = false;
    //     });
        
    //   }
    //   else {

    //       setState(() {
    //         refreshCheckProgress = false;
    //         // showToast(context, 'Error, try again later!',Constants.error);
    //       });
    //   }
    // }
    
    void getProductTags(BuildContext context) async {

      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U0", queryParams)), headers: {"Accept": "application/json"});
      // print(result.body);
      
      // Decode the JSON string into a Map using the jsonDecode function
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      // user object list
      
      // check if the api returned success
      if(jsonObject['status'] == 200){
        
          // get the user data from jsonObject
          var showCataloguesData = jsonObject['data'] as List;
            // Map<String, dynamic> invoicesData = jsonObject['data'];

            if(showCataloguesData.isNotEmpty){
            

              List<ProductTag> productTagsList = showCataloguesData.map<ProductTag>((json) => ProductTag.fromJson(json)).toList();
          
                setState(() {
                  // Get new user data
                  productTags = productTagsList;
                    uniqueProductTypes = productTagsList.map((tag) => tag.type).whereType<String>().toSet().toList();
                    sizes = productTagsList.where((tag) => tag.type == 'Size').toList();
                  refreshCheckProgress = false;
                });
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
            // showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF36C31),
        // backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      // appBar: AppBar(
        // backgroundColor: Colors.green[900],
        // elevation: 0,
        actions: [
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: 
            InkWell(
                onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Verification()));
                },
                child: Container(
              
              padding: const EdgeInsets.fromLTRB(16,8,16,8),
              margin: const EdgeInsets.fromLTRB(16,8,16,8),
              // margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0.0, 0.0),
                                blurRadius: 8.0,
                                spreadRadius: 0.3,
                              ),
                        ],
              ),
              child: 
        
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFF36C31),
                            ),
                          ),
                        // ],
                      ),
              // ),
            
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.green[200],
            //     shape: CircleBorder(),
            //   ),
            //   onPressed: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => Verification()));
            //   },
            //   child: Text('Login'),
            // ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFFF36C31), Color(0xFFF36C31), Color(0xFFFF8B59)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF8B59), // Shadow color
                    // color: Colors.black12, // Shadow color
                    spreadRadius: 5, // How much the shadow spreads
                    blurRadius: 80, // How blurred the shadow is
                    offset: Offset(0, 10), // Offset in x, y direction
                  ),
                ],
              ),
              // color: Color(0xFFF36C31),
              // color: const Color(0xFFFFFFFF),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    
                    Image.asset('assets/anjani_logo1.webp', scale: 4,), 
                    sizedBox(4),
                    Image.asset('assets/anjani_title_white.webp', scale: 1,), 
                    sizedBox(24),
                    Text('Crafting Elegance', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.bold), ),
                    sizedBox(8),
                    Text('Our precise creations create an impressive space that sets a tranquil ambience!', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white70, fontWeight: FontWeight.w500), ),
                    
                    sizedBox(24),
                  ],
                ),
              ),
            ),
            sizedBox(48),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Designs()));
              },
            child: 
            Container(
              // height: 200,
              width: MediaQuery.of(context).size.width-32,
              // padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.orange.shade200, Colors.deepOrangeAccent.shade100],
                  // colors: [Colors.amber.shade400, Colors.green.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white, // Shadow color
                    // color: Colors.black12, // Shadow color
                    spreadRadius: 5, // How much the shadow spreads
                    blurRadius: 10, // How blurred the shadow is
                    offset: Offset(0, 10), // Offset in x, y direction
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: 
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white.withOpacity(0.1), // Translucent effect
                    child: Column(
                      children: [
                        Container(
                          width: 250,
                          // color: Colors.blue,
                          child: Stack(
                            children: [
                              Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                        width: 100.0, // Adjust the size as needed
                                        height: 100.0, // Adjust the size as needed
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          image: const DecorationImage(
                                            image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F81001.jpeg?alt=media'),
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12, // Shadow color
                                              spreadRadius: 5, // How much the shadow spreads
                                              blurRadius: 20, // How blurred the shadow is
                                              offset: Offset(0, 10), // Offset in x, y direction
                                            ),
                                          ],
                                        ),
                                      ),
                                  ),

                                  Positioned(top: 0, left: 60, right: 60,
                                  child: Transform.rotate(
                                          angle: -0.3,
                                          child: Container(
                                                  width: 100.0, // Adjust the size as needed
                                                  height: 100.0, // Adjust the size as needed
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    image: const DecorationImage(
                                                      
                                                      image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F51007_F10.jpeg?alt=media'),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black12, // Shadow color
                                                        spreadRadius: 5, // How much the shadow spreads
                                                        blurRadius: 20, // How blurred the shadow is
                                                        offset: Offset(0, 10), // Offset in x, y direction
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ),
                                  ),
                                  Positioned(top: 0, right: 0,
                                  child: Transform.rotate(
                                          angle: 0.1,
                                          child: Container(
                                                  width: 100.0, // Adjust the size as needed
                                                  height: 100.0, // Adjust the size as needed
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    image: const DecorationImage(
                                                      image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F21033.jpeg?alt=media'),
                                                      // image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/51010.jpeg?alt=media'),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black12, // Shadow color
                                                        spreadRadius: 5, // How much the shadow spreads
                                                        blurRadius: 20, // How blurred the shadow is
                                                        offset: Offset(0, 10), // Offset in x, y direction
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ),
                                  ),
                            ],
                          ),
                        ),
                            
                        
                        sizedBox(48),
                        // Image.asset('assets/browseproducts.webp', scale: 4,), 
                        // sizedBox(48),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                            
                            textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 5, // Shadow depth
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const Designs()));
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                          },
                          child: const Text('Browse Designs', style: TextStyle(color: Colors.black)),
                        ),
                        
                      ],
                    )
                    
                  ),
                ),
              ),
            ),
          ),
sizedBox(24),


// Center(
//   child: Interactive3DContainer(),
// ),

// Center(
//           child: AutoScrollingContainers(),
//         ),


       

//     FlipCard(),
            
            // sizedBox(16),
Container(
  width: MediaQuery.of(context).size.width-32,
                      decoration: BoxDecoration(
                      // color: const Color(0xFFFEFEFE),

                              border: Border.all(color: Colors.white, width: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [const Color.fromARGB(255, 255, 238, 212), Colors.pink.shade200],
                                // colors: [const Color.fromARGB(255, 221, 221, 221), Colors.deepPurpleAccent],
                                // colors: [Color(0xFF008060), Colors.green.shade800],
                                // colors: [Colors.amber.shade400, Colors.green.shade800],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12, // Shadow color
                                  // color: Colors.black12, // Shadow color
                                  spreadRadius: 5, // How much the shadow spreads
                                  blurRadius: 10, // How blurred the shadow is
                                  offset: Offset(0, 10), // Offset in x, y direction
                                ),
                              ],
                      // boxShadow: const [
                      //   BoxShadow(
                      //     color: Colors.white,
                      //     offset: Offset(0.0, 0.0),
                      //     blurRadius: 24.0,
                      //     spreadRadius: 0.3,
                      //   ),
                      // ]
                    ),
                    padding: const EdgeInsets.all(20),
                    child: 
                    Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Image.asset('assets/designday.webp',width: 120.0), sizedBox(4),
                            Expanded(child: 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                
                                Text('Design of the day!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                                
                                Text('Check out today\'s exciting design.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                                sizedBox(8),

                                checkDesignOfTheDayList == false ?
                                const AppProgress(height: 30, width: 30,)
                                :
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                                    
                                    textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 5, // Shadow depth
                                  ),
                                  onPressed: () {
                                    designOfTheDayList.isEmpty ?
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Designs()))
                                    :
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DesignDetails(product: designOfTheDayList[0], productTags: productTagsList)));
                                  },
                                  child: Text(designOfTheDayList.isEmpty ? 'Browse Designs' : 'View Design', style: const TextStyle(color: Colors.black)),
                                ),
                                
                              ]
                                  
                            )
                            )
                          ],
                        )
                        
                  ),
            // Container(
            //   // height: 200,
            //   width: MediaQuery.of(context).size.width-32,
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.white, width: 1),
            //     borderRadius: BorderRadius.circular(24),
            //     gradient: LinearGradient(
            //       colors: [Colors.white, Colors.green.shade200, Colors.white],
            //       // colors: [Colors.amber.shade400, Colors.green.shade800],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.white, // Shadow color
            //         // color: Colors.black12, // Shadow color
            //         spreadRadius: 5, // How much the shadow spreads
            //         blurRadius: 10, // How blurred the shadow is
            //         offset: Offset(0, 10), // Offset in x, y direction
            //       ),
            //     ],
            //   ),

            // // Container(
            // //         padding: EdgeInsets.all(16),
            // //         // color: Color(0xFF048563),
            // //         decoration: BoxDecoration(

            // //           gradient: LinearGradient(
            // //       colors: [Colors.orange.shade400, Colors.deepOrange],
            // //       begin: Alignment.topLeft,
            // //       end: Alignment.bottomRight,
            // //     ),
            //         //  gradient: LinearGradient(
            //         //             begin: Alignment.bottomCenter,
            //         //             end: Alignment.topCenter,
            //         //             colors: [
            //         //               Color.fromARGB(255, 10, 85, 65),
            //         //               Color.fromARGB(255, 21, 144, 111),
            //         //               Color.fromARGB(255, 10, 85, 65),
            //         //             ],
            //         //           ),
            //                           // ),
            //             child: 
                        
            //             Column(
            //               crossAxisAlignment: CrossAxisAlignment.center,
            //               children: [
            //                 Text('Design of the day'.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12), ),
                            
            //                 sizedBox(16),

            //                 (refreshCheckProgress) ? 
                            
            //                   Column(
            //                     mainAxisAlignment: MainAxisAlignment.center,
            //                     mainAxisSize: MainAxisSize.max,
            //                     children: [
            //                       // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
            //                       // sizedBox(8),
            //                       refreshCheckProgress? const AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
            //                       Text('Loading design of the day!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                  
            //                     ],
            //                   )
            //                 : 
            //                 designOfTheDayList.isEmpty ?
            //                 Text('Please browse our designs above!', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white70, fontWeight: FontWeight.w500), )
            //                 :
            //                 Stack(
            //                 children: [
            //                   Transform.rotate(
            //                     angle: -0.4,
            //                     child: 
            //                     InkWell(
            //                       onTap: () {

            //                         Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: designOfTheDayList[0], productTags: productTags)));

            //                         // showModalBottomSheet(
            //                         //   backgroundColor: Colors.white,
            //                         //     // backgroundColor: () {
                                          
            //                         //     //     var colorTag = productTags.firstWhere((tag) => filteredProducts[index].tags?.split(',').contains(tag.tagId.toString()) == true && tag.type == 'Color', orElse: () => ProductTag(description: 'FFFFFF'));
            //                         //     //   return Color(int.parse('0xFF${colorTag.description ?? 'FFFFFF'}'));
            //                         //     // }(),
            //                         //   useSafeArea: true,
            //                         //   isScrollControlled: true,
            //                         //   showDragHandle: true,
            //                         //   context: context,
            //                         //   builder: (BuildContext context) {
            //                         //   return SingleChildScrollView(
            //                         //     child: Container(
            //                         //       color: () {
                                          
            //                         //         var colorTag = productTags.firstWhere((tag) => designOfTheDayList[0].tags?.split(',').contains(tag.tagId.toString()) == true && tag.type == 'Color', orElse: () => ProductTag(description: 'FFFFFF'));
            //                         //       return Color(int.parse('0x22${colorTag.description ?? 'FFFFFF'}'));

            //                         //     // var ≈ = productTags.firstWhere(
            //                         //     //   (tag) => tag.tagId.toString() == filteredProducts[index].tags && tag.type == 'Color',
            //                         //     //   orElse: () => ProductTag(description: 'FFFFFF'),
            //                         //     // );
            //                         //     // return Color(int.parse('0xFF${colorTag.description ?? 'FFFFFF'}'));
            //                         //     }(),
            //                         //     padding: EdgeInsets.all(16.0),
            //                         //     child: Column(
            //                         //       mainAxisSize: MainAxisSize.max,
            //                         //       crossAxisAlignment: CrossAxisAlignment.start,
            //                         //       mainAxisAlignment: MainAxisAlignment.start,
            //                         //       children: [
            //                         //       Center(
            //                         //         child: Transform.rotate(
            //                         //         angle: -0.1, child:
            //                         //         CardInteractive(design: designOfTheDayList[0].design!, media: designOfTheDayList[0].media!.split(',')[0],  imageHeight: double.parse(designOfTheDayList[0].size!.split('x')[1]), imageWidth: double.parse(designOfTheDayList[0].size!.split('x')[0]), zoom:2),
            //                         //         // CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!.split(',')[0],  imageHeight: MediaQuery.of(context).size.height * 0.5, imageWidth: MediaQuery.of(context).size.width * 0.6),
            //                         //         // CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!,  imageHeight: 120, imageWidth: 60),
            //                         //         // CardInteractive(imageUrl: filteredProducts[index].imageUrls!.split(',')[0], imageHeight: MediaQuery.of(context).size.height * 0.5, imageWidth: MediaQuery.of(context).size.width * 0.6),
            //                         //         )
            //                         //       ),
            //                         //       sizedBox(16),
            //                         //       Center(
            //                         //         child: Text(designOfTheDayList[0].name ?? 'No Name', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.headlineMedium, fontWeight: FontWeight.bold)),
            //                         //       ),
            //                         //       sizedBox(8),
            //                         //       Text(designOfTheDayList[0].description ?? 'No Description', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
            //                         //       sizedBox(8),
            //                         //       Column(
            //                         //         mainAxisSize: MainAxisSize.max,
            //                         //         crossAxisAlignment: CrossAxisAlignment.start,
            //                         //         mainAxisAlignment: MainAxisAlignment.start,
            //                         //         spacing: 8,
            //                         //         children: designOfTheDayList[0].tags?.split(',').map((tagId) {
            //                         //         var tag = productTags.firstWhere((tag) => tag.tagId.toString() == tagId, orElse: () => ProductTag(name: 'Unknown'));
            //                         //         return Container(
            //                         //           padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            //                         //           decoration: BoxDecoration(
            //                         //           // color: Colors.grey[200],
            //                         //           borderRadius: BorderRadius.circular(8.0),
            //                         //           ),
            //                         //           child: Column(
            //                         //             mainAxisSize: MainAxisSize.max,
            //                         //             crossAxisAlignment: CrossAxisAlignment.start,
            //                         //             mainAxisAlignment: MainAxisAlignment.start,
            //                         //             children: [
            //                         //               Text('${tag.type}: ${tag.name}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
            //                         //               sizedBox(8),
            //                         //               DottedLine(),
            //                         //             ],
            //                         //           )
                                              
            //                         //         );
            //                         //         }).toList() ?? [
            //                         //         Container(
            //                         //           padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            //                         //           decoration: BoxDecoration(
            //                         //           color: Colors.grey[200],
            //                         //           borderRadius: BorderRadius.circular(8.0),
            //                         //           ),
            //                         //           child: Text('No Tags', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
            //                         //         )
            //                         //         ],
            //                         //       ),
            //                         //       sizedBox(48),
            //                         //       ],
            //                         //     ),
            //                         //     ),
            //                         //   );
            //                         //   },
            //                         // );
            //                       },
            //                       child:Container(
            //                               width: 100.0, // Adjust the size as needed
            //                               height: 100.0, // Adjust the size as needed
            //                               decoration: BoxDecoration(
            //                                 color: Colors.white,
            //                                 image: DecorationImage(
            //                                   image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F${designOfTheDayList[0].media!.split(',')[0]}.jpeg?alt=media'),
            //                                   fit: BoxFit.cover,
            //                                 ),
            //                                 borderRadius: BorderRadius.circular(16),
            //                                 boxShadow: [
            //                                   BoxShadow(
            //                                     color: Colors.black12, // Shadow color
            //                                     spreadRadius: 5, // How much the shadow spreads
            //                                     blurRadius: 20, // How blurred the shadow is
            //                                     offset: const Offset(0, 10), // Offset in x, y direction
            //                                   ),
            //                                 ],
            //                               ),
            //                             ),
            //                         ),
            //                       ),

            //                       // Positioned(top: 0, left: 60, right: 60,
            //                       // child: Transform.rotate(
            //                       //         angle: -0.3,
            //                       //         child: Container(
            //                       //                 width: 100.0, // Adjust the size as needed
            //                       //                 height: 100.0, // Adjust the size as needed
            //                       //                 decoration: BoxDecoration(
            //                       //                   color: Colors.white,
            //                       //                   image: DecorationImage(
                                                      
            //                       //                     image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F${designOfTheDayList[0].media!.split(',')[0]}.jpeg?alt=media'),
            //                       //                     fit: BoxFit.cover,
            //                       //                   ),
            //                       //                   borderRadius: BorderRadius.circular(16),
            //                       //                   boxShadow: [
            //                       //                     BoxShadow(
            //                       //                       color: Colors.black12, // Shadow color
            //                       //                       spreadRadius: 5, // How much the shadow spreads
            //                       //                       blurRadius: 20, // How blurred the shadow is
            //                       //                       offset: const Offset(0, 10), // Offset in x, y direction
            //                       //                     ),
            //                       //                   ],
            //                       //                 ),
            //                       //               ),
            //                       //           ),
            //                       // ),
                                  
            //                 ],
            //               ),

            //                   sizedBox(16),
            //               ]
            //             )
                        
                
            //       ),

            // Container(
            //         padding: EdgeInsets.all(16),
            //         // color: Color(0xFF048563),
            //         decoration: BoxDecoration(

            //           gradient: LinearGradient(
            //       colors: [Colors.orange.shade400, Colors.deepOrange],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //         //  gradient: LinearGradient(
            //         //             begin: Alignment.bottomCenter,
            //         //             end: Alignment.topCenter,
            //         //             colors: [
            //         //               Color.fromARGB(255, 10, 85, 65),
            //         //               Color.fromARGB(255, 21, 144, 111),
            //         //               Color.fromARGB(255, 10, 85, 65),
            //         //             ],
            //         //           ),
            //                           ),
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 Text('Browse Designs'.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), ),
                            
            //                 sizedBox(16),

            //                 (refreshCheckProgress && showCatalogues.length == 0) ? 
            //                 Center(
            //                   child: Column(
            //                     mainAxisAlignment: MainAxisAlignment.center,
            //                     children: [
            //                       // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
            //                       // sizedBox(8),
            //                       refreshCheckProgress? const AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
            //                       Text('Loading catagolues!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                                  
            //                     ],
            //                   )
            //                 )
            //                 : 
            //                 Container(
            //                   height: 200,
            //                   child: 
            //                   ListView.builder(
            //                     scrollDirection: Axis.horizontal,
            //                     itemCount: showCatalogues.length,
            //                     itemBuilder: (context, index) {
            //                       return Container(
            //                       // width: MediaQuery.of(context).size.width * 0.8,
            //                       // padding: EdgeInsets.all(16),
            //                       width: 220,
            //                       margin: const EdgeInsets.symmetric(horizontal: 8.0),
            //                       child: productCard(index),
            //                       );
            //                     },
            //                     ),
            //                   ),

            //                   sizedBox(16),
            //               ]
            //             )
                
            //       ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                
                  sizedBox(16),
                  Text('Our plants'.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12), ),
                  
                  sizedBox(16),


              // (refreshCheckProgress && showCatalogues.length == 0) ? sizedBox(0) :
                  GestureDetector(
                    onTap: () async {
                        // await launch('https://www.anjanitiles.com/assets/img/about/anjanitek.mp4');
                        if (!await launchUrl(Uri.parse('https://www.anjanitiles.com/assets/img/about/anjanitek.mp4'), mode: LaunchMode.inAppBrowserView)) {
                          print('Launched');
                        }
                         
                      },
                    child:  Stack(
                    children: [
                      Container(
                        height: 200,    
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          image: DecorationImage(
                            image: NetworkImage(plant1),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Positioned(top: 20, left: 0, right: 0,
                        child: Center(
                          child: Icon(PhosphorIconsFill.playCircle, size: 64, color: Colors.white),
                        ),
                      ),
                      Positioned(bottom: 0, left: 0, right: 0,
                        child: 
                        Center(
                          child: 
                                ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 20),
                                      child: Container(
                                        height: 100,
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                        // This creates the semi-transparent background effect
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(20.0),
                                          bottomRight: Radius.circular(20.0),
                                        ),
                                      ),
                                      
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                                Text('ANJANI TILES LIMITED PLANT', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), ),
                                                      Text('Near Gudur (Tirupati District) Andhra Pradesh', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white60, fontWeight: FontWeight.w500, fontSize: 14), ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ),
                              ],
                            )
                              
                  ),

                  sizedBox(12),


// (refreshCheckProgress && showCatalogues.length == 0) ? sizedBox(0) :
                  GestureDetector(
                    onTap: () async {
                        // await launch('https://www.anjanitiles.com/assets/img/about/vennar.mp4');
                        if (!await launchUrl(Uri.parse('https://www.anjanitiles.com/assets/img/about/vennar.mp4'), mode: LaunchMode.inAppBrowserView)) {
                          print('Launched');
                        }
                      },
                    child: Stack(
                    children: [
                      Container(
                        height: 200,    
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          image: DecorationImage(
                            image: NetworkImage(plant2),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Positioned(top: 20, left: 0, right: 0,
                        child: Center(
                          child: Icon(PhosphorIconsFill.playCircle, size: 64, color: Colors.white),
                        ),
                      ),
                      Positioned(bottom: 0, left: 0, right: 0,
                        child: 
                        Center(
                          child: 
                                ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 20),
                                      child: Container(
                                        height: 100,
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                        // This creates the semi-transparent background effect
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(20.0),
                                          bottomRight: Radius.circular(20.0),
                                        ),
                                      ),
                                      
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                                Text('VENNAR CERAMICS LIMITED PLANT', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), ),
                                                Text('Near Kaikalur (Eluru District), Andhra Pradesh', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white60, fontWeight: FontWeight.w500, fontSize: 14), ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ),
                              ],
                            )
                  ),

                  sizedBox(32),

                  Text('Reach out to us'.toUpperCase(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12), ),
                  sizedBox(16),

                  InkWell(
                    onTap: () => {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ShowRooms()))
                    },
                    child: 
                    Container(

                      decoration: BoxDecoration(
                                        // This creates the semi-transparent background effect
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.white,
                                            Colors.grey.shade50,
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, 0.0),
                            blurRadius: 24.0,
                            spreadRadius: 0.3,
                          ),
                        ]
                                      ),

                      // decoration: BoxDecoration(
                      //   color: Colors.white,
                      //   borderRadius: const BorderRadius.all(Radius.circular(24)),
                      //   border: Border.all(
                      //             color: Colors.black12, // Set the color of the border here
                      //             width: 1, // Set the width of the border here
                      //           ),
                      //   boxShadow: const [
                      //     BoxShadow(
                      //       color: Colors.black12,
                      //       offset: Offset(0.0, 0.0),
                      //       blurRadius: 24.0,
                      //       spreadRadius: 0.3,
                      //     ),
                      //   ]
                      // ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Image.asset('assets/showrooms.webp',width: 80.0),
                          // Container(
                          //   decoration: const BoxDecoration(
                          //     color: Color(0xFFF36C31),
                          //     borderRadius: BorderRadius.all(Radius.circular(24)),
                          //   ),
                          //   padding: const EdgeInsets.all(10),
                          //   child:  Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         children: [
                          //           const Icon(PhosphorIconsRegular.storefront, color: Colors.white, size: 28,),
                          //           // const SizedBox(width:8),
                          //           // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                          //       ],
                          //     ),
                          // ),
                          sizedBox(16),
                          Text('Our Showrooms', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontSize: 16, fontWeight: FontWeight.w600)),
                          sizedBox(8),
                          Text('Walk in to experience the designs live and connect with us', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54), textAlign: TextAlign.center,),
                          sizedBox(4),
                        ],
                      )
                    )
                  ),

                  sizedBox(64),

                ],
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: Container(
      //   width: 100,
      //   margin: const EdgeInsets.fromLTRB(64,0,64,32),
      //   padding: const EdgeInsets.fromLTRB(16,0,16,0),
      //   decoration: const BoxDecoration(
      //     color: Colors.white,
      //     borderRadius: BorderRadius.all(Radius.circular(16)),
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black26,
      //         blurRadius: 10,
      //         spreadRadius: 1,
      //       ),
      //     ],
      //   ),
        
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //       mainAxisSize: MainAxisSize.min,
      //       children: [
      //         IconButton(
      //           icon: Icon(PhosphorIconsFill.house, color: Color(0xFFF36C31)),
      //           onPressed: () {},
      //         ),
      //         IconButton(
      //           icon: Icon(PhosphorIconsFill.storefront, color: Colors.black54),
      //           onPressed: () {
      //             Navigator.push(context, MaterialPageRoute(builder: (context) => ShowRooms()));
      //           },
      //         ),
      //       ],
      //     // ),
      //   ),
      // ),
    );
  }


Widget productCard(int position){

    return GestureDetector(
      onTap: () async {
        try{

          // Load from URL
          //PDFDocument doc = await PDFDocument.fromURL('https://www.ecma-international.org/wp-content/uploads/ECMA-262_12th_edition_june_2021.pdf');

          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage1(showCatalogues[position].name! , showCatalogues[position].documentUrl!)));

          // if (!await launchUrl(Uri.parse(showCatalogues[position].documentUrl!), mode: LaunchMode.externalApplication)) {
          //   print('Launched');
          // }
          // if (!await launchUrl(Uri.parse(showCatalogues[position].documentUrl!), mode: LaunchMode.inAppBrowserView)) {
          //   print('Launched');
          // }
          
            // if (await canLaunch(showCatalogues[position].documentUrl!)) {
            //   await launch(showCatalogues[position].documentUrl!);
            // } else {
            //   throw 'Could not launch ${showCatalogues[position].documentUrl}';
            // }
          }
          catch(e){
            print(e);
          }
        },
      child: Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30, width: 1),
            // boxShadow: [BoxShadow(
            //                 color: Colors.white38,
            //                 offset: Offset(0.0, 0.0),
            //                 blurRadius: 18.0,
            //                 spreadRadius: 0.3,
            //               ),],
            borderRadius: BorderRadius.circular(20.0),
            image: DecorationImage(
              image: NetworkImage(showCatalogues[position].imageUrl!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Align(
            alignment: Alignment.bottomLeft,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                  // This creates the semi-transparent background effect
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white10,
                      // Colors.black12,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Container(
                    //       decoration: const BoxDecoration(
                    //         color: Colors.white,
                    //         borderRadius: BorderRadius.all(Radius.circular(24)),
                    //       ),
                    //       padding: const EdgeInsets.all(8),
                    //       child:  
                    //       Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //             crossAxisAlignment: CrossAxisAlignment.center,
                    //             children: [
                    //               const Icon(PhosphorIconsRegular.book, color: Colors.deepOrange, size: 24,),
                    //               // const SizedBox(width:8),
                    //               // Text('4', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF002D21)))
                    //           ],
                    //         ),
                    //     ),
                    //     SizedBox(width: 8,),
                        Expanded(child: 
                          Text(showCatalogues[position].name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                        )
                  ],
                ),
              
                ),
              ),
            ),
          ),
        ],
      )
      
      
      
      // Container(
      //   decoration: BoxDecoration(
      //           borderRadius: BorderRadius.circular(16),
      //           color: Colors.white,
      //                   boxShadow: const [
      //                     BoxShadow(
      //                           color: Colors.black12,
      //                           offset: Offset(0.0, 0.0),
      //                           blurRadius: 8.0,
      //                           spreadRadius: 0.3,
      //                         ),
      //                   ],
      //         ),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Expanded(
      //         child: Container(
      //           decoration: BoxDecoration(
      //             borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      //             image: DecorationImage(
      //               image: NetworkImage(showCatalogues[position].imageUrl!),
      //               fit: BoxFit.cover,
      //             ),
      //           ),
      //         ),
      //       ),
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(showCatalogues[position].name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

Widget productTagCard(int position){
  
    return GestureDetector(
      // onTap: () async {
      //   try{

      //     // Load from URL
      //     //PDFDocument doc = await PDFDocument.fromURL('https://www.ecma-international.org/wp-content/uploads/ECMA-262_12th_edition_june_2021.pdf');

      //     Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage1(showCatalogues[position].name! , showCatalogues[position].documentUrl!)));

      //     // if (!await launchUrl(Uri.parse(showCatalogues[position].documentUrl!), mode: LaunchMode.externalApplication)) {
      //     //   print('Launched');
      //     // }
      //     // if (!await launchUrl(Uri.parse(showCatalogues[position].documentUrl!), mode: LaunchMode.inAppBrowserView)) {
      //     //   print('Launched');
      //     // }
          
      //       // if (await canLaunch(showCatalogues[position].documentUrl!)) {
      //       //   await launch(showCatalogues[position].documentUrl!);
      //       // } else {
      //       //   throw 'Could not launch ${showCatalogues[position].documentUrl}';
      //       // }
      //     }
      //     catch(e){
      //       print(e);
      //     }
      //   },
      child: Container(
        decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0.0, 0.0),
                                blurRadius: 8.0,
                                spreadRadius: 0.3,
                              ),
                        ],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded(
            //   child: Container(
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            //       image: DecorationImage(
            //         image: NetworkImage(showCatalogues[position].imageUrl!),
            //         fit: BoxFit.cover,
            //       ),
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productTags[position].name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
   
  }


}


  Widget _buildMainCard() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
                child: const Icon(Icons.favorite_border, color: Colors.white, size: 24),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                  // This creates the semi-transparent background effect
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Brazil",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Text(
                        "Rio de Janeiro",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 16),
                          SizedBox(width: 5),
                          Text("5.0", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 10),
                          Text("143 reviews", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("See more", style: TextStyle(color: Colors.white)),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.arrow_forward, color: Colors.black),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




class Catalogue {
  int? id;
  String? name;
  String? imageUrl;
  String? documentUrl;
  int? type;

  Catalogue({this.id, this.name, this.imageUrl, this.documentUrl, this.type});

  Catalogue.fromJson(Map<String, dynamic> json): 
  id = json['id'], 
  name = json['name'], 
  imageUrl = json['imageUrl'], 
  documentUrl = json['documentUrl'], 
  type = json['type'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id']= id;
    data['name']= name;
    data['imageUrl']= imageUrl;
    data['documentUrl']= documentUrl;
    data['type']= type;
    return data;
  }
}


class FlipCard extends StatefulWidget {
  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.status == AnimationStatus.completed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: Transform(
        // This transformation flips the card based on the animation value
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002) // Perspective effect
          ..rotateY(_animation.value * 3.14159), // Rotate Y by pi (180 degrees)
        alignment: Alignment.center,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 5,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: _animation.value > 0.5 ? Colors.white : Colors.transparent,
        ),
        child: _animation.value <= 0.5
            ? _frontSide()
            : Transform(
                // Flip the back side to face the correct direction
                transform: Matrix4.identity()..rotateY(3.14159),
                alignment: Alignment.center,
                child: _backSide(),
              ),
      ),
    );
  }

  Widget _frontSide() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            image: const DecorationImage(
              image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Align(
            alignment: Alignment.bottomLeft,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                  // This creates the semi-transparent background effect
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Brazil",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Text(
                        "Rio de Janeiro",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 16),
                          SizedBox(width: 5),
                          Text("5.0", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 10),
                          Text("143 reviews", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("See more", style: TextStyle(color: Colors.white)),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.arrow_forward, color: Colors.black),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Positioned(
        //   bottom: 0,
        //   left: 0,
        //   right: 0,
        //   child: Container(
        //     padding: EdgeInsets.all(16.0),
        //     decoration: BoxDecoration(
        //       color: Colors.black.withOpacity(0.5),
        //       borderRadius: BorderRadius.only(
        //         bottomLeft: Radius.circular(20.0),
        //         bottomRight: Radius.circular(20.0),
        //       ),
        //     ),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Brazil',
        //           style: TextStyle(color: Colors.white, fontSize: 18),
        //         ),
        //         Text(
        //           'Rio de Janeiro',
        //           style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        //         ),
        //         Row(
        //           children: [
        //             Icon(Icons.star, color: Colors.amber),
        //             Text(
        //               '5.0',
        //               style: TextStyle(color: Colors.white),
        //             ),
        //             SizedBox(width: 8),
        //             Text(
        //               '143 reviews',
        //               style: TextStyle(color: Colors.white),
        //             ),
        //           ],
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _backSide() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Back Side',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Here you can put additional information or content for the back of the card.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class GlarePainter extends CustomPainter {
  final Offset position;

  GlarePainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..blendMode = BlendMode.screen;

    // Draw a gradient from the touch point
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment(position.dx / size.width, position.dy / size.height),
      radius: 1.0,
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.5),
      ],
      stops: const [0.0, 0.5],
    );
    canvas.drawRect(rect, paint..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}





class Interactive3DContainer extends StatefulWidget {
  @override
  _Interactive3DContainerState createState() => _Interactive3DContainerState();
}

class _Interactive3DContainerState extends State<Interactive3DContainer> {
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  double _elevation = 4.0;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _xOffset = details.delta.dx;
      _yOffset = details.delta.dy;
      _elevation = 20.0; // Increase elevation while interacting
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _xOffset = 0.0;
      _yOffset = 0.0;
      _elevation = 4.0; // Reset elevation
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(_yOffset * 0.01)
          ..rotateY(_xOffset * 0.01),
        alignment: FractionalOffset.center,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            // color: Colors.pink,
            image: const DecorationImage(
          image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media'),
          fit: BoxFit.cover,
        ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: _elevation,
                spreadRadius: _elevation / 2,
                offset: Offset(_xOffset, _yOffset))
            ],
          ),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white10, Colors.transparent],
              ).createShader(bounds);
            },
            blendMode: BlendMode.overlay,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media'),
                  fit: BoxFit.cover,
                ),
                // color: Colors.pink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}





class AutoScrollingContainers extends StatefulWidget {
  @override
  _AutoScrollingContainersState createState() => _AutoScrollingContainersState();
}

class _AutoScrollingContainersState extends State<AutoScrollingContainers> {
  final ScrollController _scrollController = ScrollController();
  final int _containerCount = 5;
  final double _containerSize = 100.0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        double maxScrollExtent = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;

        if (currentScroll >= maxScrollExtent) {
          _scrollController.jumpTo(0.0); // Jump back to the start
        } else {
          _scrollController.animateTo(
            currentScroll + 1,
            duration: const Duration(milliseconds: 20),
            curve: Curves.linear,
          );
        }
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _containerSize * 3, // Adjust the width as needed
      height: _containerSize,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _containerCount,
        itemBuilder: (context, index) {
          return Container(
            width: _containerSize,
            height: _containerSize,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class ImageContainerScreen extends StatelessWidget {
  final List<String> imagePaths = [
    'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/81001.jpeg?alt=media',
    
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 20.0, // Gap between adjacent chips
        runSpacing: 20.0, // Gap between lines
        alignment: WrapAlignment.center,
        children: imagePaths.map((path) {
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 4), // Shadow position
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                path,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}