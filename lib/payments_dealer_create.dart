// paymentrequest, amount, 'credit', id, transactionId, paymentDate, particular, bal

import 'dart:convert';
import 'dart:io';

import 'package:anjanitek/modals/payments.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentsDealerCreate extends StatefulWidget {
  @override
  _PaymentsDealerCreateState createState() => _PaymentsDealerCreateState();
}

class _PaymentsDealerCreateState extends State<PaymentsDealerCreate> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now().subtract(Duration(days: 365));
  String? _imageUrl, imgName='';
  bool _isUploading = false;
  String id ='';

  File? _selectedImage;
  String? _selectedFileType = '';
  late SharedPreferences prefs;

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
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
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
                        _selectedFileType = 'webp';
                    });
                    
                  }
                  
                  await _uploadImage(_selectedImage!, 'webp');
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
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
                      _selectedFileType = 'webp';
                    });
                  }
                  
                  await _uploadImage(_selectedImage!, 'webp');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage(File image, String type) async {
    setState(() {
      _isUploading = true;
    });
    try {
      
      final storageRef = FirebaseStorage.instanceFor(bucket: "gs://anjanitek-communications.firebasestorage.app").ref();
      final imageRef = storageRef.child('receipt/${'$id-${DateFormat('dd-MM-yyyy').format(_selectedDate)}'}.'+type);
      await imageRef.putFile(image);
      var imageUrl = await imageRef.getDownloadURL();
      setState(() {
        _imageUrl = imageUrl;
        imgName = "$id-${DateFormat('dd-MM-yyyy').format(_selectedDate)}."+type;
      });
      // print('Image uploaded: $_imageUrl');
    } catch (e) {
      print('Failed to upload image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  

  // Get product tags
  void submitForm(BuildContext context) async {

    setState(() { _isUploading = true; });

    if(imgName!.length > 2){

      // API call
      // print("${APIUrls.payments}${APIUrls.pass}/paymentrequest/${_amountController.text.trim()}/credit/$id/${_transactionIdController.text.trim()}/$_selectedDate}/$imgName/0");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.payments}${APIUrls.pass}/paymentrequest/${_amountController.text.trim()}/credit/$id/${_transactionIdController.text.trim()}/$_selectedDate/$imgName/-${_amountController.text.trim()}", {})), headers: {"Accept": "application/json"});
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      
      if(jsonObject['status'] == 200){
          setState(() { 
            _isUploading = false;
          });        
          showToast(context, 'Submitted',Constants.success);
          Navigator.pop(context, Payments(

            paymentId: jsonObject['id'],
            amount: double.tryParse(_amountController.text.trim()),
            amounts: '', 
            type: 'credit', 
            id: id, 
            invoiceNo: '',
            transactionId: _transactionIdController.text.trim(),
            // paymentDate: DateFormat('dd-MM-yyyy hh:mm:ss').format(_selectedDate).toString(),
            paymentDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate),
            adminId: '-',
            particular: imgName,
            balance: 0,
            
            // dealerId = json['dealerId'],
            // accountName = json['accountName'],
            // salesId = json['salesId'],
            // address1 = json['address1'],
            // address2 = json['address2'],
            // address3 = json['address3'],
            // city = json['city'],
            // district = json['district'],
            // state = json['state'],
            // gst = json['gst'];
          ));
      }
      else {
          setState(() { 
            _isUploading = false;
          });
          showToast(context, 'Error, try again later!',Constants.error);
      }
    }
    else {
      setState(() { 
            _isUploading = false;
          });
          showToast(context, 'Upload Payment proof',Constants.error);
    }

    
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Payment request', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: SafeArea(child: 
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Amount paid', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Colors.black87),),
              sizedBox(4),
              TextFormField(
                  textAlign: TextAlign.center,
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                    hintText: 'Paid amount',
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
              
              Text('Transaction details', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Colors.black87),),
              sizedBox(4),
              TextFormField(
                  textAlign: TextAlign.center,
                  controller: _transactionIdController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5E5E5)),
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

              Text('Transaction date', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Colors.black87),),
              sizedBox(4),
              
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    border: Border.all(color: Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                            Text( "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}", style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge,fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.black), ),
                          SizedBox(width: 20.0),
                          ElevatedButton(
                            style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.white)),
                            onPressed: () => _selectDate(context),
                            child: Text('Select date', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall,fontWeight: FontWeight.w600, color: Colors.black),),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text('Payment proof', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Colors.black87),),
                        sizedBox(8),

                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            border: Border.all(color: Color(0xFFE5E5E5)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              sizedBox(8),
                              _selectedImage == null
                                    ? sizedBox(0)
                                    : 
                                    (_selectedFileType == 'webp') ?
                                    Image.file(_selectedImage!) : 
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Icon(PhosphorIconsRegular.filePdf, color: Color(0xFF048563),),
                                        Text('1 file seleted', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.bold, color: Color(0xFF048563)))
                                      ],
                                    ),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.white)),
                                  onPressed: _pickImage,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 8,
                                    children: [
                                      Icon(PhosphorIconsRegular.image),
                                      Text('Select/Capture Photo', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w600, color: Colors.black)),
                                    ],
                                  ),
                                ),
                                sizedBox(8),
                                Text('or'),
                                sizedBox(8),
                                ElevatedButton(
                                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.white)),
                                  onPressed: () async {
                                    
                                    final result = await FilePicker.platform.pickFiles();
                                    if (result != null && result.files.single.path != null) {
                                      File selectedFile = File(result.files.single.path!);
                                      String fileType = result.files.single.extension ?? 'unknown';
                                      setState(() {
                                        _selectedImage = selectedFile;
                                        _selectedFileType = fileType;
                                      });
                                      await _uploadImage(selectedFile, fileType);
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 8,
                                    children: [
                                      Icon(PhosphorIconsRegular.paperclip),
                                      Text(
                                        'Attach a File',
                                        style: GoogleFonts.inter(
                                          textStyle: Theme.of(context).textTheme.bodySmall,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        )
                                    ],
                                  ),
                                  
                                ),
                            ],
                          )
                        ),

                        
                      ],
                    ),
                    sizedBox(24),
                    
                    !_isUploading ?
                    ElevatedButton(
                      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color(0xFF048563))),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Process data
                          // print('Amount: ${_amountController.text}');
                          // print('Transaction ID: ${_transactionIdController.text}');
                          // print('Date: ${_selectedDate.toLocal()}');

                          submitForm(context);
                          
                        }
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentsDealerCreate()));
                        // Navigator.pushNamed(context, '/payments_dealer_create');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(PhosphorIconsRegular.check, color: Colors.white),
                          SizedBox(width: 8.0),
                          Text('Submit', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w500), ),
                          
                          
                        ],
                      )
                    )
                    : 
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppProgress(height: 24, width: 24),
                          SizedBox(width: 8.0),
                          Text('Processing...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Color(0xFF048563), fontWeight: FontWeight.w500), ),
                        ],
                      )
            ],
          ),
        ),
      ),
      ),
    );
  }
}