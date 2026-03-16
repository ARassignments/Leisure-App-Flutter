import 'package:flutter/material.dart';

class PaymentDropdownModel {
  final String name;
  final IconData icon;
  final bool isIcon;
  final String imageUrl;
  PaymentDropdownModel(this.isIcon, this.imageUrl, {required this.name, required this.icon});
}