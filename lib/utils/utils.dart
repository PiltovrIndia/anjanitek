import 'dart:convert';
import 'dart:io';

import 'package:anjanitek/modals/dealers.dart';
import 'package:anjanitek/modals/product_cart.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/reservation.dart';
import 'package:anjanitek/modals/reservation_product.dart';
import 'package:anjanitek/modals/ordered_item.dart';
import 'package:anjanitek/modals/users.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:anjanitek/utils/constants.dart' as Constants;

import 'package:flutter/material.dart';

Widget sizedBox(double size) {
  
  return SizedBox(
    height: size,
  );

}

// save into sharedpreferences
Future<bool> saveData(Users user) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(Constants.name, user.name!);
    await prefs.setString(Constants.email, user.email!);
    await prefs.setString(Constants.id, user.id!);
    await prefs.setString(Constants.mobile, user.mobile!);
    await prefs.setString(Constants.role, user.role!);
    await prefs.setString(Constants.designation, user.designation!);
    await prefs.setString(Constants.mapTo, user.mapTo!);
    await prefs.setString(Constants.userImage, user.userImage!);
    await prefs.setString(Constants.gcmRegId, user.gcmRegId!);
    await prefs.setInt(Constants.isActive, user.isActive!);
    await prefs.setString(Constants.mapName, user.mapName?? '');
    await prefs.setString(Constants.mapMobile, user.mapMobile?? '');
    await prefs.setString(Constants.appVersionFromAPI, user.appVersion?? '');
    
    return true;
    
}
// save into sharedpreferences
Future<bool> saveDealerData(Dealers dealer) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(Constants.dealerId, dealer.dealerId!);
    await prefs.setString(Constants.accountName, dealer.accountName!);
    await prefs.setString(Constants.salesId, dealer.salesId!);
    await prefs.setString(Constants.address1, dealer.address1!);
    await prefs.setString(Constants.address2, dealer.address2!);
    await prefs.setString(Constants.address3, dealer.address3!);
    await prefs.setString(Constants.city, dealer.city!);
    await prefs.setString(Constants.state, dealer.state!);
    await prefs.setString(Constants.gst, dealer.gst!);
    
    return true;
    
}

// void setGlobalTheme(bool value) async{
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(Constants.themeStatus, value);
// }

// clear all data
void clearData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

// get OTP
String randomOTP() {

  const chars = "0123456789";

  Random rnd = Random(DateTime.now().millisecondsSinceEpoch);
  String result = "";
  for (var i = 0; i < 4; i++) {
    result += chars[rnd.nextInt(chars.length)];
  }
  print(result);
  return result;
}
// get objectId
String randomString(String s) {

  const chars = "abcdefghijklmnopqrstuvwxyz0123456789";

  Random rnd = Random(DateTime.now().millisecondsSinceEpoch);
  String result = "";
  for (var i = 0; i < 9; i++) {
    result += chars[rnd.nextInt(chars.length)];
  }
  print(s+result);
  return s+result;
}
// get acronym of names
String getAcronym(String s){

  String acronym = '';
  String newS = s.replaceAll(RegExp(r'  '), ' ');

  // try{
    if(newS != null && newS.isNotEmpty) {
      var words = newS.trim().split(" ");

      for(int i=0; i<words.length && i<2; i++){
        //print(words[i]);
        acronym = acronym + words[i][0];
      }
    }

  return acronym;
}

// get list from string array
List<String> getListFromArray(String s){

  List<String> list = [];

  //try{
    if(s != null && s.length > 0) {
      var words = s.trim().split(",");

      
      for(int i=0; i<words.length; i++){
        //print(words[i]);
        list.add(words[i]);
      }
    }

  return list;
}

// get the student type
// 0 – Inactive - out of college
// 1 – Totally active
// 2 - Totally active - but profile not updated
// 3 – Totally active – Outing blocked
// 4 - Totally active – Temporary day scholar
String getStudentType(int profileUpdated, String type){

  switch (profileUpdated) {
    case 0:
      return 'Inactive - out of college';
    case 1:
      if(type.toLowerCase() == 'hostel'){
        return 'Hosteler';
      }
      else {
        return 'Day Scholar';
      }
    case 4:
      return 'Temporary Day Scholar';
    default:
    return '';
  }

  
}

// get formatted datetime
DateTime getDate(String date){
  // parse UTC time sent by server
  if(date.contains('T'))
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", 'en_US').parseUTC(date);
  else {
    return DateFormat("yyyy-MM-dd HH:mm:ss", 'en_US').parseUTC(date);
  }
}

// get formatted datetime
int getDuration(DateTime fromDate, DateTime toDate){
  DateTime from = DateTime(fromDate.year, fromDate.month, fromDate.day);
  DateTime to = DateTime(toDate.year, toDate.month, toDate.day);

  return to.difference(from).inDays + 1;
}

// get date
DateTime formatDateNow(String dateString){


  // Parse the date string from the server
// final dateString = '2023-05-10 08:16:14';

// Create a DateTime object from the parsed string
final date = DateTime.parse(dateString);
return DateTime(date.year, date.month, date.day);
// Format the date in a specific way using the intl package
// final formatter = DateFormat('yyyy-MM-dd');
// final formattedDate = formatter.format(date);

// return DateTime(formattedDate.year, formattedDate.month, formattedDate.day);

  // DateTime date = DateTime.parse(date1).toLocal();
  // int year = date.year;
  // int month = date.month;
  // int day = date.day;
  // return '$year-$month-$day';
}

// greet with time
String getGreeting(){
  DateTime time = DateTime.now();
  int hour = time.hour;

  if (hour < 12)
   return "Morning";
  else if (hour < 17 && !(hour == 12))
   return "Afternoon";
  else if (hour == 12)
   return "Noon";
  else
   return "Evening";
 }
//   if (hour < 12)
//    return "Great morning";
//   else if (hour < 17 && !(hour == 12))
//    return "Good afternoon";
//   else if (hour == 12)
//    return "Good noon";
//   else
//    return "Good evening";
//  }


// get time difference
String getTimeDiff(DateTime now, DateTime datetime){
  
  int d = now.difference(datetime).inDays;
  // print(now);
  // print(datetime);
  if(d == 0){

    int h = now.difference(datetime).inHours;
    if(h == 0){
      int m = now.difference(datetime).inMinutes;
      
      if(m == 0){
        int s = now.difference(datetime).inSeconds;
        
        return '${(s)} sec(s)';  
      }
    else {
      
      return '${(m)} min(s)';
      }
    }
    else {
      
      return '${(h).abs()} hr(s)';
    }
    
    
  }
  else {

    if(d > 31 && d < 366){
      int mo = d ~/30;
      return '${(mo)} mo';

    }
    else if (d > 365){
      int y = d~/365;
      return '${(y)} yr(s)';
    }
    else{
      
      return '${(d)} day(s)';
    }
  }
  
}

// get the day for the given tab index
String getDayTab(int index){
  switch (index) {
    case 0:
      return 'Monday';
      break;
    case 1:
      return 'Tuesday';
      break;
    case 2:
      return 'Wednesday';
      break;
    case 3:
      return 'Thursday';
      break;
    case 4:
      return 'Friday';
      break;
    case 5:
      return 'Saturday';
      break;
    case 6:
      return 'Sunday';
      break;
      
    default:
      return 'Monday';
  }

}

String getHourTime(int hour){
  String hourTime = '';
  switch (hour) {
        case 1:
            hourTime = '09:30:00';
            break;
        case 2:
            hourTime = '10:30:00';
            break;
        case 3:
            hourTime = '11:30:00';
            break;
        case 4:
            hourTime = '12:30:00';
            break;
        case 5:
            hourTime = '13:30:00';
            break;
        case 6:
            hourTime = '14:30:00';
            break;
        case 7:
            hourTime = '15:30:00';
            break;
        case 8:
            hourTime = '16:30:00';
            break;
        case 9:
            hourTime = '17:30:00';
            break;
    
        default:
            break;
    }

    return hourTime;
}

// truncate the string and add ellipsis
String truncateWithEllipsis(String text){
  if(text.length > 75)
    return text.replaceRange(75, text.length, '...');
  else 
    return text;
}
// truncate the string and add ellipsis
String truncate2Lines(String text){
  if(text.length > 40)
    return text.replaceRange(33, text.length, '...');
  else 
    return text;
}
// truncate the string and add ellipsis
String truncate2LinesShort(String text){
  if(text.length > 20)
    return text.replaceRange(20, text.length, '...');
  else 
    return text;
}


List<String> getPastMonths(int count) {
  List<String> monthsList = [];

  DateTime now = DateTime.now();
  for (int i = 0; i < count; i++) {
    DateTime month = DateTime(now.year, now.month - i);
    String monthYear = '${_getMonthName(month.month)}-${month.year}';
    monthsList.add(monthYear);
  }

  return monthsList;
}
String _getMonthName(int month) {
  switch (month) {
    case 1:
      return 'January';
    case 2:
      return 'February';
    case 3:
      return 'March';
    case 4:
      return 'April';
    case 5:
      return 'May';
    case 6:
      return 'June';
    case 7:
      return 'July';
    case 8:
      return 'August';
    case 9:
      return 'September';
    case 10:
      return 'October';
    case 11:
      return 'November';
    case 12:
      return 'December';
    default:
      return '';
  }
}

String convertMonthYearToYearMonth(String monthYear) {
  List<String> parts = monthYear.split('-');
  if (parts.length != 2) {
    // Invalid format, return empty string or throw an exception
    return '';
  }

  String month = parts[0].trim();
  String year = parts[1].trim();

  int monthNumber = _getMonthNumber(month);
  if (monthNumber == 0) {
    // Invalid month name, return empty string or throw an exception
    return '';
  }

  String formattedMonth = monthNumber.toString().padLeft(2, '0');
  String formattedYear = year;

  return '$formattedYear-$formattedMonth-01';
}
int _getMonthNumber(String month) {
  switch (month.toLowerCase()) {
    case 'january':
      return 1;
    case 'february':
      return 2;
    case 'march':
      return 3;
    case 'april':
      return 4;
    case 'may':
      return 5;
    case 'june':
      return 6;
    case 'july':
      return 7;
    case 'august':
      return 8;
    case 'september':
      return 9;
    case 'october':
      return 10;
    case 'november':
      return 11;
    case 'december':
      return 12;
    default:
      return 0;
  }
}

// check the internet connectivity
  Future<bool> checkInternetConnectivity() async {
    try {
    final result = await InternetAddress.lookup('google.com');
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
    } on SocketException catch (_) {
      
      return false;
      
    }
  }


/*
// fetch name 
Future<String> getUsername() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();

    if(preferences.containsKey('name')){
      return preferences.getString('name').toString();
    }
    return '';
}

// fetch userObjectId
Future<String> getUserObjectId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();

    if(preferences.containsKey('userObjectId')){
      return preferences.getString('userObjectId');
    }
    return '';
}

// fetch mobile
Future<String> getPhoneNumber() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();

    if(preferences.containsKey('mobile')){
      return preferences.getString('mobile').toString();
    }
    return '';
} */





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

getUnitofCategory(String category){
  switch (category) {
    case 'VCL':
      return 'boxes';
    case 'ATL':
      return 'boxes';
    case 'Collections':
      return '₹';
    default:
      return '';
  }
}

Widget buildTargetItem(BuildContext context, String title, double achieved, dynamic target, Color color) {
  // if(target is String && target.toLowerCase() == 'to be decided') {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w500, color: Colors.black87)),
  //       sizedBox(4),
  //       Text('To be decided', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black)),
  //     ],
  //   );
  // }
  
  // check if target is string value or double value
  double progress = 0;
  if (target is String && target.toLowerCase() == 'to be decided') {
    progress = 0;
  } else if (target is double) {
    if(target > 0) {
      progress = achieved / target;
    }
    else {
      progress = 0;
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(title, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black54)),
              title == 'Collections' ?
              Text('₹ ${NumberFormat("#,##,##0", "en_IN").format(achieved)} / ${(target is String && target.toLowerCase() == 'to be decided') ? 'To be decided' : '₹ ${NumberFormat("#,##,##0", "en_IN").format(target)}'}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: Colors.black87))
              :
              Text('${NumberFormat("#,##,##0", "en_IN").format(achieved)} / ${(target is String && target.toLowerCase() == 'to be decided') ? 'To be decided' : '${NumberFormat("#,##,##0", "en_IN").format(target)} ${getUnitofCategory(title)}'}', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyMedium, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
          // Text(title + ' ${NumberFormat("#,##,##0", "en_IN").format(achieved)} (${(progress * 100).toStringAsFixed(1)}%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w500)),
          // progress > 100 ?
          // Text('(100%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black, fontWeight: FontWeight.w600))
          // :
          Text('(${(progress * 100).toStringAsFixed(1)}%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: Colors.black54)),
          // Text('${NumberFormat("#,##,##0", "en_IN").format(achieved)} (${(progress * 100).toStringAsFixed(1)}%)', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
      sizedBox(4),
      LinearProgressIndicator(
        value: progress > 1 ? 1 : progress,
        color: color,
        backgroundColor: color.withOpacity(0.2),
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
    ],
  );
}

formatTotalWeightForDesignType(List<OrderedItem> items, List<ProductTag> productTags) {
    
    // get the tags specific to BoxWeight
    List<ProductTag> boxWeightTagsById = productTags.where((tag) => tag.type == 'BoxWeight' && tag.tagId != null).toList();
    double weightInKg = 0;

    // parse through each item's tags and check which box weight tag it has and calculate the weight accordingly
    // BTW, tags value for each item is a comma separated string of tagIds, so we need to split it and check for each tagId
    for (var item in items) {

        item.tags?.split(',').forEach((tagId) {
          var tag = boxWeightTagsById.firstWhere((tag) => tag.tagId.toString() == tagId, orElse: () => ProductTag(tagId: null, name: '0', type: '', description: '0'));
          weightInKg += (double.tryParse(tag.name!) ?? 0) * ((item.status.toLowerCase() == 'submitted') ? item.requestedQty : (item.status.toLowerCase() == 'approved' || item.status.toLowerCase() == 'modified') ? (item.approvedQty + item.productionQty) : 0);
        });
        
    }

    


    // final weightInKg = items.fold( 0, (total, item) => total + (item.weight * item.quantity), );

    if (weightInKg >= 1000) {
      final weightInTons = weightInKg / 1000;
      return '${weightInTons.toStringAsFixed(weightInTons % 1 == 0 ? 0 : 2)} ton';
    }

    if (weightInKg >= 1) {
      return '${weightInKg.toStringAsFixed(weightInKg % 1 == 0 ? 0 : 2)} kg';
    }

    final weightInGrams = weightInKg * 1000;
    return '${weightInGrams.toStringAsFixed(weightInGrams % 1 == 0 ? 0 : 2)} g';
  }

formatTotalWeightForDesignType_Old(List<ReservationProduct> items, List<ProductTag> productTags) {
    
    // get the tags specific to BoxWeight
    List<ProductTag> boxWeightTagsById = productTags.where((tag) => tag.type == 'BoxWeight' && tag.tagId != null).toList();
    double weightInKg = 0;

    // parse through each item's tags and check which box weight tag it has and calculate the weight accordingly
    // BTW, tags value for each item is a comma separated string of tagIds, so we need to split it and check for each tagId
    for (var item in items) {

        item.tags?.split(',').forEach((tagId) {
          var tag = boxWeightTagsById.firstWhere((tag) => tag.tagId.toString() == tagId, orElse: () => ProductTag(tagId: null, name: '0', type: '', description: '0'));
          weightInKg += (double.tryParse(tag.name!) ?? 0) * ((item.status.toLowerCase() == 'approved' || item.status.toLowerCase() == 'modified') ? item.approvedQty : item.requestedQty);
        });
        
    }

    


    // final weightInKg = items.fold( 0, (total, item) => total + (item.weight * item.quantity), );

    if (weightInKg >= 1000) {
      final weightInTons = weightInKg / 1000;
      return '${weightInTons.toStringAsFixed(weightInTons % 1 == 0 ? 0 : 2)} ton';
    }

    if (weightInKg >= 1) {
      return '${weightInKg.toStringAsFixed(weightInKg % 1 == 0 ? 0 : 2)} kg';
    }

    final weightInGrams = weightInKg * 1000;
    return '${weightInGrams.toStringAsFixed(weightInGrams % 1 == 0 ? 0 : 2)} g';
  }