import 'package:flutter/material.dart';

class PaymentDropdownModel {
  final String name;
  final IconData icon;
  final bool isIcon;
  final bool isVisible;
  final String imageUrl;
  PaymentDropdownModel(this.isVisible, this.isIcon, this.imageUrl, {required this.name, required this.icon});
}