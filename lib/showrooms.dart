import 'dart:convert';

import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/dotted_line.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ShowRooms extends StatefulWidget {
  @override
  ShowRoomsState createState() => ShowRoomsState();
}



class ShowRoomsState extends State<ShowRooms> {

  List<ShowRoom> showRooms = [];
  bool refreshCheckProgress = true;

  @override
  void initState() {
      
      // get reference to internal database
      getShowRooms(context);
    
    super.initState();
  }

    // find the user
    void getShowRooms(BuildContext context) async {

      setState(() {
        refreshCheckProgress = true;
      });
      // var uuid = await DeviceUuid().getUUID();
      // query parameters    
      Map<String, String> queryParams = {
        
        };

      // API call
      // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.showrooms}${APIUrls.pass}/1", queryParams)), headers: {"Accept": "application/json"});
      // print(result.body);
      
      // Decode the JSON string into a Map using the jsonDecode function
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      // user object list
      
      // check if the api returned success
      if(jsonObject['status'] == 200){
        
          // get the user data from jsonObject
          var showRoomsData = jsonObject['data'] as List;
            // Map<String, dynamic> invoicesData = jsonObject['data'];

            if(showRoomsData.isNotEmpty){
            

              List<ShowRoom> showRoomsList = showRoomsData.map<ShowRoom>((json) => ShowRoom.fromJson(json)).toList();
          
                setState(() {
                  // Get new user data
                  showRooms = showRoomsList;
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
        backgroundColor: Color(0xFFF36C31),
        elevation: 0,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
        title: Text('Our Showrooms', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.bold), ),
      ),
      body: 
      showRooms.isEmpty ? 
      // Expanded(
      //     child: Center(
      //       child: 
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                // sizedBox(8),
                refreshCheckProgress? AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                Text('Loading showrooms!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                
              ],
          //   )
          // )
        ) :
                            
                            // loader while fetching data
                            
                          
      ListView.builder(
        itemCount: showRooms.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _launchVideo(showRooms[index].videoUrl!),
            child: Container(
              
              margin: EdgeInsets.all(16),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            image: DecorationImage(
                              image: NetworkImage(showRooms[index].imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Icon(PhosphorIconsFill.playCircle, size: 64, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      showRooms[index].title!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Text(
                    //   'Address',
                    //   style: TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    // SizedBox(height: 4),
                    Text(
                      showRooms[index].address!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    sizedBox(16),
                    DottedLine(),
                    sizedBox(12),
                    InkWell(
                      onTap: () async {
                          await launchUrlString("tel:${showRooms[index].phone!}");
                      },
                      child: Row(
                              children: [
                                Icon(PhosphorIconsRegular.phone, size: 24, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  '${showRooms[index].contact} : ${showRooms[index].phone}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue
                                  ),
                                ),
                              ],
                            ),
                    ),
                    
                    SizedBox(height: 8),
                    showRooms[index].landline!.length > 3 ?
                    InkWell(
                      onTap: () async {
                          await launchUrlString("tel:${showRooms[index].landline!}");
                      },
                      child: Row(
                              children: [
                                Icon(PhosphorIconsRegular.phone, size: 24, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  '${showRooms[index].landline}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue
                                  ),
                                ),
                              ],
                            ),
                    )
                     : sizedBox(0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _launchVideo(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView)) {
      print('Launched');
    }
    // if (await canLaunch(url)) {
    //   await launch(url);
    // } else {
    //   throw 'Could not launch $url';
    // }
  }
}


class ShowRoom {
  int? id;
  String? title;
  String? imageUrl;
  String? videoUrl;
  String? address;
  String? contact;
  String? phone;
  String? landline;


  ShowRoom({this.id, this.title, this.imageUrl, this.videoUrl, this.address, this.contact, this.phone, this.landline});

  ShowRoom.fromJson(Map<String, dynamic> json): 
  id = json['id'], 
  title = json['title'], 
  imageUrl = json['imageUrl'], 
  videoUrl = json['videoUrl'], 
  address = json['address'],
  contact = json['contact'],
  phone = json['phone'],
  landline = json['landline'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id']= id;
    data['title']= title;
    data['imageUrl']= imageUrl;
    data['videoUrl']= videoUrl;
    data['address']= address;
    data['contact']= contact;
    data['phone']= phone;
    data['landline']= landline;
    return data;
  }
}