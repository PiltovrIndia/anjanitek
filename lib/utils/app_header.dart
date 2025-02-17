import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppHeader extends StatelessWidget {

  int backNeeded = 0;
  String header = "", subHeader ="";
  AppHeader(String header, String subHeader, int backNeeded, [String? theme]){
    this.header = header;
    this.subHeader = subHeader;
    this.backNeeded = backNeeded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.black12,
      padding: EdgeInsets.fromLTRB(0, 16, 8, 8),
      child: 
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          
          backNeeded == 0 ? Container(width: 0, height: 0,) : 
          IconButton(icon: Icon(PhosphorIconsBold.arrowBendUpLeft, color: Theme.of(context).hintColor, size: 24,),
          // IconButton(icon: Icon(Icons.keyboard_backspace, color: Theme.of(context).hintColor, size: 24,),
          onPressed: () => 
              Navigator.pop(context)
            ,
          ),
Expanded(
              child:
          Container(
            // color: Colors.black12,
            padding: backNeeded == 1 ? EdgeInsets.fromLTRB(0, 0, 0, 0) : EdgeInsets.all(0), 
            child:  
            
            Column(
            
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            
            children: <Widget>[

              // Text(header, style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
              Image.asset('assets/anjani_title1.webp', scale: 2,), 
              subHeader.isNotEmpty ? const SizedBox(
                height: 4.0,
              ) : sizedBox(0),

              subHeader.isNotEmpty ? Text(subHeader, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium)) : sizedBox(0),
              
            ],
          ),
          )
          )
        ],
      ),
        
    );
  }
}