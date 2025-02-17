// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:anjanitek/utils/constants.dart' as Constants;

// void showToast(BuildContext context, String message, String type){
//   // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),));

//   ScaffoldMessenger.of(context).showSnackBar(
//   SnackBar(
//     //  margin: const EdgeInsets.all(16.0),
//       // padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),                 
//     // backgroundColor: Colors.white.withOpacity(0.1),
//     backgroundColor: Colors.transparent,
//     duration: const Duration(seconds: 3),
//     behavior: SnackBarBehavior.floating,
//     elevation: 2.0,
//     content: 
//     Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           // width: double.infinity,
//           // constraints: BoxConstraints(maxWidth: double.infinity),
//           padding: const EdgeInsets.fromLTRB(8,8,16,8),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(25),
//             color: Theme.of(context).cardColor,
//             border: Border.all(
//               color: Colors.white,
//               width: 1,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               (type == Constants.success) ?
//               Icon(PhosphorIconsBold.checkCircle, color: Colors.green)
//               :
//               (type == Constants.error) ?
//               Icon(PhosphorIconsBold.xCircle, color: Colors.red)
//               :
//               Icon(PhosphorIconsBold.warningCircle, color: Colors.yellow),
//               const SizedBox(width: 8),
//               Flexible(child:       
//                 Text(message, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge,)),),
//             ],
//           ),
//         ),
//       ],
//     ) 
//   ),
// );
//   // Scaffold.of(context).showSnackBar(SnackBar(content: Text(message),));
// }



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

void showToast(BuildContext context, String message, String type){
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),));

  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    //  margin: const EdgeInsets.all(16.0),
      // padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),                 
    backgroundColor: Colors.white.withOpacity(0.1),
    // backgroundColor: Palette.black.withOpacity(0),
    // width: 300,
    // backgroundColor: Theme.of(context).cardColor,
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
    elevation: 30.0,
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.fromLTRB(0,0,0,0),
    content: 
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // width: double.infinity,
          // constraints: BoxConstraints(maxWidth: double.infinity),
          padding: const EdgeInsets.fromLTRB(8,8,16,8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              (type == Constants.success) ?
              PhosphorIcon(PhosphorIconsBold.checkCircle, color: Colors.green)
              :
              (type == Constants.error) ?
              PhosphorIcon(PhosphorIconsBold.xCircle, color: Colors.red)
              :
              PhosphorIcon(PhosphorIconsBold.warningCircle, color: Colors.yellow),
              const SizedBox(width: 8),
              Flexible(child:       
                Text(message, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge,)),),
            ],
          ),
        ),
      ],
    ) 
  ),
);
  // Scaffold.of(context).showSnackBar(SnackBar(content: Text(message),));
}