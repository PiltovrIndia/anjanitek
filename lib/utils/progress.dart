import 'package:flutter/material.dart';

class AppProgress extends StatelessWidget{
  
  const AppProgress({super.key, required this.height, required this.width});

  final double height, width;

  
  
  @override
  Widget build(BuildContext context) {
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Container(
          height: height,
          width: width,
          margin: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(5.0),
          
          child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.green),))
      ],
    );
  }

}