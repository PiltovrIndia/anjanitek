import 'package:anjanitek/pdf_view.dart';
import 'package:anjanitek/showrooms.dart';
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
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AnjaniTekApp extends StatefulWidget {
  @override
  AnjaniTekAppState createState() => AnjaniTekAppState();
}

class AnjaniTekAppState extends State<AnjaniTekApp> {

  List<Catalogue> showCatalogues = [];
  bool refreshCheckProgress = true;
  String plant1 = 'https://www.anjanitiles.com/assets/img/about/about-1.jpg';
  String plant2 = 'https://www.anjanitiles.com/assets/img/about/vennar.jpg';

  @override
  void initState() {
      
      // get reference to internal database
      getCatalogues(context);
    
    super.initState();
  }

    // find the user
    void getCatalogues(BuildContext context) async {

      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.catalogues}${APIUrls.pass}/1", queryParams)), headers: {"Accept": "application/json"});
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
            

              List<Catalogue> cataloguesList = showCataloguesData.map<Catalogue>((json) => Catalogue.fromJson(json)).toList();
          
                setState(() {
                  // Get new user data
                  showCatalogues = cataloguesList;
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
      appBar: AppBar(
        backgroundColor: Color(0xFFF36C31),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Verification()));
                },
                child: Container(
              
              padding: EdgeInsets.fromLTRB(16,8,16,8),
              margin: EdgeInsets.fromLTRB(16,8,16,8),
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
                // Row(
                //         children: [
                //           Icon(PhosphorIconsRegular.phone, size: 24, color: Colors.orange),
                //           SizedBox(width: 8),
                          Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFF36C31),
                            ),
                          ),
                      //   ],
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
              color: Color(0xFFF36C31),
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
                    Text('Crafting Elegance', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24), ),
                    sizedBox(8),
                    Text('Our precise creations create an impressive space that sets a tranquil ambience!', textAlign: TextAlign.center, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), ),
                    
                    sizedBox(16),
                    // ElevatedButton(
                    //   onPressed: () {},
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.green,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //   ),
                    //   child: Text('Contact us'),
                    // ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Browse catalogues', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                  
                  sizedBox(16),

                  (refreshCheckProgress && showCatalogues.length == 0) ? 
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                        // sizedBox(8),
                        refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                        Text('Loading catagolues!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                        
                      ],
                    )
                  )
                  : 
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: showCatalogues.length,
                    itemBuilder: (context, index) {
                      return productCard(index);
                    },
                  ),
                  
                  
                  sizedBox(16),
                  Text('Our plants', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                  
                  sizedBox(16),


              (refreshCheckProgress && showCatalogues.length == 0) ? sizedBox(0) :
                  GestureDetector(
                    onTap: () async {
                        // await launch('https://www.anjanitiles.com/assets/img/about/anjanitek.mp4');
                        if (!await launchUrl(Uri.parse('https://www.anjanitiles.com/assets/img/about/anjanitek.mp4'), mode: LaunchMode.inAppBrowserView)) {
                          print('Launched');
                        }
                         
                      },
                    child: 
                  Container(
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
                              Stack(
                                children: [
                                  Container(
                                      height: 240,
                                      decoration:  BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(plant1!),
                                        ),
                                      ),
                                    ),
                                  Positioned(top: 0, bottom: 0, left: 0, right: 0,
                                    child: Center(
                                      child: Icon(PhosphorIconsFill.playCircle, size: 64, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                                  
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ANJANI TILES LIMITED PLANT', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                                Text('Near Gudur (Tirupati District) Andhra Pradesh', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  sizedBox(12),


(refreshCheckProgress && showCatalogues.length == 0) ? sizedBox(0) :
                  GestureDetector(
                    onTap: () async {
                        // await launch('https://www.anjanitiles.com/assets/img/about/vennar.mp4');
                        if (!await launchUrl(Uri.parse('https://www.anjanitiles.com/assets/img/about/vennar.mp4'), mode: LaunchMode.inAppBrowserView)) {
                          print('Launched');
                        }
                      },
                    child: 
                  Container(
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
                              Stack(
                                children: [
                                  Container(
                                      height: 240,
                                      decoration:  BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(plant2!),
                                        ),
                                      ),
                                    ),
                                  Positioned(top: 0, bottom: 0, left: 0, right: 0,
                                    child: Center(
                                      child: Icon(PhosphorIconsFill.playCircle, size: 64, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                                  
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VENNAR CERAMICS LIMITED PLANT', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                                Text('Near Kaikalur (Eluru District), Andhra Pradesh', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  sizedBox(32),

                  Text('Reach out to us', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                  sizedBox(16),
                  GestureDetector(
                    onTap: ()  {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ShowRooms())); 
                      },
                    child: 
                  Container(
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                  
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Our showrooms', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                                // Text('Near Kaikalur (Eluru District), Andhra Pradesh', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14), ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  image: DecorationImage(
                    image: NetworkImage(showCatalogues[position].imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(showCatalogues[position].name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


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