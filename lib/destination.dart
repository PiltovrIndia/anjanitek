import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Destination {
  const Destination(this.title, this.icon);
  final String title;
  final IconData icon;

 
}

const List<Destination> allDestinations = <Destination>[
  Destination('Home', PhosphorIconsRegular.house),
  // Destination('Feed', PhosphorIcons.list),
  // Destination('New', Icons.add_circle_outline),
   Destination('Profile', PhosphorIconsRegular.user)
];