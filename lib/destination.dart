import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

class Destination {
  const Destination(this.title, this.icon);
  final String title;
  final HugeIcon icon;

 
}

const List<Destination> allDestinations = <Destination>[
  Destination('Home', HugeIcon(icon: HugeIcons.strokeRoundedHome01, )),
  Destination('Designs', HugeIcon(icon: HugeIcons.strokeRoundedArtboardTool, )),
  // show this only for sales executive, sales manager, state head, staff, super admin and global admin
  Destination('Orders', HugeIcon(icon: HugeIcons.strokeRoundedShippingTruck01, )),
  Destination('Feed', HugeIcon(icon: HugeIcons.strokeRoundedInbox, )),
   Destination('Profile', HugeIcon(icon: HugeIcons.strokeRoundedUserAccount, ))
];