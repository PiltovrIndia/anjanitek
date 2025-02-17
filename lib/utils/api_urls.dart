import 'dart:convert';
import 'package:http/http.dart' as http;

class APIUrls {

    // authority 
    //static String authority = 'campus-1233.appspot.com';
    // static String authority = 'mysmartcampus.app';
    // static String authority = 'smartcampusweb.vercel.app'; // production
    // static String authority = '52.66.55.19'; // pre production
    // static String authority = 'localhost:3000'; // pre production
    static String authority = 'anjanitek.com'; // pre production
    static String pass = 'KfUwvS0oE6zV9jyHqXxL2Pi4D1mG8aRtNcZn7Ml3bArpT5gJQsCWeYBf';


    // verify user
    static String verifyUser = 'api/v2/verify/';
    static String user = 'api/v2/user/';
    // amount
    static String amount = 'api/v2/amount/';
    static String stats = 'api/v2/dealerstats/';
    static String ledger = 'api/v2/ledger/';
    static String payments = 'api/v2/payments/';
    // messaging
    static String messaging = 'api/v2/messaging/';
    static String showrooms = 'api/v2/showrooms/';
    static String catalogues = 'api/v2/catalogues/';
    static String products = 'api/v2/products/';

    
    
    // campus
    static String campuses = 'api/v2/campuses/';

    // requests
    static String appVersion = 'api/v2/appversion/'; // to check app version

    static String newRequest = 'api/v2/newrequest/'; // new
    static String myRequests = 'api/v2/requests/'; // my new requests
    static String otherRequests = 'api/v2/otherrequests/'; // my new requests
    static String blockedDates = 'api/v2/blockouting/'; // blocked dates
    static String updateRequests = 'api/v2/updaterequests/'; // blocked dates
    static String requestStats = 'api/v2/requeststats/'; // for admin to view stats
    static String visitorStats = 'api/v2/visitorstats/'; // for admin to view stats
    static String visitorpasses = 'api/v2/visitorpasses/'; // for visitorpass
    static String newVisitorpass = 'api/v2/newvisitorpass/'; // for new visitorpass
    static String updateVisitorpass = 'api/v2/updatevisitorpass/'; // for admin/student to update visitorpass
    static String passrequest = 'api/v2/passrequest/'; // for admin/student to number days of temporary day pass
    
    static String hostels = 'api/v2/hostels/'; // for foodadmin to get hostel students available for food details
    static String food = 'api/v2/food/'; // for foodadmin to store the food availed details

    static String circulars = 'api/v2/circulars/'; // for admins & students circulars

    // make API call
    // returns both JSON object as well as JSON array
    static Future<dynamic> makeApiCall(String endpoint, {bool isList = false}) async {
      try {
        // call the API
        final response = await http.get(Uri.parse('$authority/$endpoint/$pass'), headers: {"Accept": "application/json"});
        
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (isList) {
            return jsonData as List<dynamic>;
          } else {
            return jsonData;
          }
        } else {
          throw Exception('Failed to load data');
        }
      } catch (e) {
        throw Exception('Failed to connect to server');
      }
    }


    // encrypted data
    static String encryptStringXOR(String plainText) {
      // Convert plain text and key to UTF-8 bytes
      List<int> plainBytes = utf8.encode(plainText);
      List<int> keyBytes = utf8.encode('SMART');

      // XOR each byte of plain text with corresponding byte of key
      List<int> encryptedBytes = [];
      for (int i = 0; i < plainBytes.length; i++) {
        encryptedBytes.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      // Convert encrypted bytes to base64 string
      String encryptedString = base64.encode(encryptedBytes);

      return encryptedString;
    }

    // decrypt data
    static String decryptStringXOR(String encryptedString) {
      // Convert encrypted string and key to UTF-8 bytes
      List<int> encryptedBytes = base64.decode(encryptedString);
      List<int> keyBytes = utf8.encode('SMART');

      // XOR each byte of encrypted text with corresponding byte of key
      List<int> decryptedBytes = [];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      // Convert decrypted bytes to UTF-8 string
      String decryptedString = utf8.decode(decryptedBytes);

      return decryptedString;
    }


    // form url with query parameters
    static String getUrl(String url, Map<String, String> queryParams){

      // for the url
      Uri uri = Uri.http(
        authority,
        url, 
        queryParams
      );

      // return the url string
      return uri.toString();
    }

}