// paymentrequest, amount, 'credit', id, transactionId, paymentDate, particular, bal

import 'dart:convert';
import 'dart:io';

import 'package:anjanitek/modals/confirmations.dart';
import 'package:anjanitek/modals/payments.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceConfirmation extends StatefulWidget {

  const BalanceConfirmation(this.confirmation);
  final Confirmation confirmation;

  @override
  _BalanceConfirmationState createState() => _BalanceConfirmationState();

}

class _BalanceConfirmationState extends State<BalanceConfirmation> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365));
  String? _imageUrl, imgName='';
  bool _isUploading = false;
  String id ='';

  File? _selectedImage;
  late SharedPreferences prefs;
  late Confirmation confirmationObj;

  @override
  void initState() {
      // get reference to internal database
      getUsers();
      super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

   // get user details
    void getUsers() async {

        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            confirmationObj = widget.confirmation;
          // name = prefs.get(Constants.name) as String;
          id = prefs.get(Constants.id) as String;
          // isActive = prefs.get(Constants.isActive) as int;
          
            // if(prefs.get(Constants.role) == Constants.dealer){

            //   dealerId = prefs.get(Constants.dealerId) as String;
            //   accountName = prefs.get(Constants.accountName) as String;
            //   salesId = prefs.get(Constants.salesId) as String;
            // }
          });
        } 
        
    }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),  // Default to today
      firstDate: DateTime(2000),    // Start date (adjust if needed)
      lastDate: DateTime.now(),     // Restrict selection to today
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    File imageSelected = File(image.path);
                    Navigator.of(context).pop();
                    setState(() {
                        _isUploading = true;
                      });
                    if (imageSelected.lengthSync() > 50000) {
                        // Compress the image
                        final result = await FlutterImageCompress.compressAndGetFile(
                          imageSelected.absolute.path,
                          '${imageSelected.absolute.path}_compressed.webp',
                          minWidth: 512,
                          format: CompressFormat.webp,
                          quality: 30,
                        );
                        if (result != null) {
                          imageSelected = File(result.path);
                        }
                      }
                    setState(() {
                        _selectedImage = File(imageSelected.path);
                    });
                    
                  }
                  
                  await _uploadImage(_selectedImage!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    File imageSelected = File(image.path);
                    Navigator.of(context).pop();
                    setState(() {
                        _isUploading = true;
                      });

                    if (imageSelected.lengthSync() > 50000) {
                        // Compress the image
                        final result = await FlutterImageCompress.compressAndGetFile(
                          imageSelected.absolute.path,
                          '${imageSelected.absolute.path}_compressed.webp',
                          minWidth: 512,
                          format: CompressFormat.webp,
                          quality: 30,
                        );
                        if (result != null) {
                          imageSelected = File(result.path);
                        }
                      }
                    setState(() {
                      _selectedImage = File(imageSelected.path);
                    });
                  }
                  
                  await _uploadImage(_selectedImage!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });
    try {
      final storageRef = FirebaseStorage.instanceFor(bucket: "gs://anjanitek-communications.firebasestorage.app").ref();
      final imageRef = storageRef.child('receipt/${id+DateFormat('dd-MM-yyyy').format(_selectedDate).toString()}.webp');
      await imageRef.putFile(image);
      var imageUrl = await imageRef.getDownloadURL();
      setState(() {

        _imageUrl = imageUrl;
        imgName = "${id}${DateFormat('dd-MM-yyyy').format(_selectedDate)}.webp";

        confirmationObj.media = "${id}${DateFormat('dd-MM-yyyy').format(_selectedDate)}.webp";
      });
      print('Image uploaded: $_imageUrl');
    } catch (e) {
      print('Failed to upload image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
    
    // Create the confirmation from the dealer for a given latest event
    void addConfirmationByDealer(BuildContext context) async {

      if(await checkInternetConnectivity()){

        setState(() {
          _isUploading = true;
        });
        
        // API call
        print("${APIUrls.confirmations}${APIUrls.pass}/C5/${confirmationObj.eventId}/${confirmationObj.anjaniAmount}/${confirmationObj.confirmationOn}/${confirmationObj.dealer}/${_amountController.text}/No/${_transactionIdController.text.trim()}/$imgName");
        var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.confirmations}${APIUrls.pass}/C5/${confirmationObj.eventId}/${confirmationObj.anjaniAmount}/${confirmationObj.confirmationOn}/${confirmationObj.dealer}/${_amountController.text}/No/${_transactionIdController.text.trim()}/$imgName", {})), headers: {"Accept": "application/json"});
        print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
        // check if the api returned success
        if(jsonObject['status'] == 200){
            
            setState(() {
              _isUploading = false;
            });

            showToast(context, 'Submitted',Constants.success);
            Navigator.pop(context, {'status': Constants.success, 'reason':_transactionIdController.text.trim()});
          
        }
        else {
          // no data exists
          setState(() {
            // get the error message
            _isUploading = false;
          });
          showToast(context, 'Error, try again later!',Constants.error);
          Navigator.pop(context, {'status': Constants.warning});
        }
      }
      else {
        Future.delayed(const Duration(seconds: 5), () {
          addConfirmationByDealer(context);
          
          // set the connection Status variable to false
          setState(() {
            _isUploading = false;
          });
          
        });
      }
    }


  // Get product tags
  // void submitForm(BuildContext context) async {

  //   setState(() { _isUploading = true; });

  //   // API call
  //   print("${APIUrls.confirmations}/C6/${_amountController.text.trim()}/credit/$id/${_transactionIdController.text.trim()}/$_selectedDate}/$imgName/0");
  //   var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.payments}${APIUrls.pass}/paymentrequest/${_amountController.text.trim()}/credit/$id/${_transactionIdController.text.trim()}/$_selectedDate/$imgName/0", {})), headers: {"Accept": "application/json"});
  //   Map<String, dynamic> jsonObject = jsonDecode(result.body);
    
  //   if(jsonObject['status'] == 200){
  //       setState(() { 
  //         _isUploading = false;
  //       });        
  //       showToast(context, 'Submitted',Constants.success);
  //       Navigator.pop(context, Payments(

  //         paymentId: jsonObject['id'],
  //         amount: double.tryParse(_amountController.text.trim()),
  //         amounts: '', 
  //         type: 'credit', 
  //         id: id, 
  //         invoiceNo: '',
  //         transactionId: _transactionIdController.text.trim(),
  //         paymentDate: DateFormat('dd-MM-yyyy').format(_selectedDate).toString(),
  //         adminId: '-',
  //         particular: imgName,
  //         balance: 0,
          
  //         // dealerId = json['dealerId'],
  //         // accountName = json['accountName'],
  //         // salesId = json['salesId'],
  //         // address1 = json['address1'],
  //         // address2 = json['address2'],
  //         // address3 = json['address3'],
  //         // city = json['city'],
  //         // district = json['district'],
  //         // state = json['state'],
  //         // gst = json['gst'];
  //       ));
  //   }
  //   else {
  //       setState(() { 
  //         _isUploading = false;
  //       });
  //       showToast(context, 'Error, try again later!',Constants.error);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        // title: Text('Balance Confirmation', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[




              Container(
                decoration: BoxDecoration(
                // color: const Color(0xFFF6F1E7),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(
                          color: Colors.black12, // Set the color of the border here
                          width: 1, // Set the width of the border here
                        ),

                        gradient: const LinearGradient(
                          colors: [Color(0xFFF6F1E7), Color.fromARGB(255, 255, 194, 101)],
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
                        ]
                // boxShadow: const [
                //   BoxShadow(
                //     color: Colors.white,
                //     offset: Offset(0.0, 0.0),
                //     blurRadius: 24.0,
                //     spreadRadius: 0.3,
                //   ),
                // ]
              ),
              padding: const EdgeInsets.all(16),
              child: 
              Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    children: [
                      Expanded(child: 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 6,
                        children: [
                          Image.asset('assets/confirmation.webp',width: 120.0), sizedBox(4),
                          Text('Balance Confirmation request', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                          
                          Text('In connection with the audit of our financial statement, please confirm the outstanding balance of our Company as per your books of account', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87)),
                          Text('If the amount shown above is not in agreement with your records, please inform us the amount shown by your records', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87)),
                          sizedBox(8),
                          
                       





              Text('Correct outstanding balance*', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 0.2, color: Colors.black87),),
              Text('As per your record', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium,fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Colors.black54),),
              // sizedBox(4),
              TextFormField(
                  textAlign: TextAlign.center,
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                    hintText: 'Enter balance',
                    ),
                  validator: (value) { // validator function is called on calling form validate() method
                    if (value!.isEmpty) {
                      return '';
                    }
                    return null;
                  },
                  // onSaved: (value) => mobileNumber = value!,
                  style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black),
                ),
                sizedBox(16),
              
              Text('Mismatch Reason *', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 0.2, color: Colors.black87),),
              
              TextFormField(
                  textAlign: TextAlign.center,
                  controller: _transactionIdController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                    // hintText: 'Paid amount',
                    ),
                  validator: (value) { // validator function is called on calling form validate() method
                    if (value!.isEmpty) {
                      return '';
                    }
                    return null;
                  },
                  // onSaved: (value) => mobileNumber = value!,
                  style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black),
                ),
                sizedBox(16),
                
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Text('Copy of our account in your books of account', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Colors.black87),),
                        Text('Upload a copy of our a/c in your books of account duly signed and stamped by you.*', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: Colors.black87),),
                        sizedBox(8),

                        Container(
                          // padding: EdgeInsets.all(8),
                          // decoration: BoxDecoration(
                          //   // color: Color(0xFFF5F5F5),
                          //   border: Border.all(color: Color(0xFFE5E5E5)),
                          //   borderRadius: BorderRadius.circular(16),
                          // ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // sizedBox(8),
                              _selectedImage == null
                                    ? Text('No image seleted', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: Colors.black54))
                                    : Image.file(_selectedImage!),
                                const SizedBox(height: 8),
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
                                  onPressed: _pickImage,
                                  child: Text('Select/Capture Photo', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: Colors.black)),
                                ),
                            ],
                          )
                        )
                        
                      ],
                    ),
                    sizedBox(24),
                    
                    !_isUploading ?
                    ElevatedButton(
                      // style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color(0xFF048563))),
                      style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF048563), // Dark background color
                                    
                                    textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 5, // Shadow depth
                                  ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Process data
                          // print('Amount: ${_amountController.text}');
                          // print('Transaction ID: ${_transactionIdController.text}');
                          // print('Date: ${_selectedDate.toLocal()}');

                          addConfirmationByDealer(context);
                          
                        }
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => BalanceConfirmation()));
                        // Navigator.pushNamed(context, '/payments_dealer_create');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(PhosphorIconsRegular.check, color: Colors.white),
                          const SizedBox(width: 8.0),
                          Text('Submit', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w500), ),
                          
                          
                        ],
                      )
                    )
                    : 
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppProgress(height: 24, width: 24),
                          const SizedBox(width: 8.0),
                          Text('Processing...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: const Color(0xFF048563), fontWeight: FontWeight.w500), ),
                        ],
                      )

                       ]
                      )
                      )
                    ],
                  )

              
            ),




            ],
          ),
        ),
      ),
    );
  }
}

