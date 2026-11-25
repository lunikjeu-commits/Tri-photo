import 'package:flutter/material.dart';
import 'adult.dart';
import 'blur.dart';
import 'categories.dart';
import 'dupes.dart';

const _icons = <String, IconData>{
  'Voitures': Icons.directions_car_rounded,
  'Moteurs': Icons.settings_rounded,
  'Alimentation': Icons.restaurant_rounded,
  'Paysages': Icons.landscape_rounded,
  'Animaux': Icons.pets_rounded,
  'Aquarium': Icons.waves_rounded,
  'Textes et citations': Icons.format_quote_rounded,
  'Personnes': Icons.people_rounded,
  'Jeux': Icons.sports_esports_rounded,
  'Bateaux': Icons.directions_boat_rounded,
  kAdults: Icons.visibility_off_rounded,
  kDuplicates: Icons.content_copy_rounded,
  kBlurry: Icons.blur_on_rounded,
  kToCheck: Icons.help_outline_rounded,
};

IconData iconForFolder(String name) => _icons[name] ?? Icons.folder_rounded;
