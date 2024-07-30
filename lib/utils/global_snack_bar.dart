import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Utils {
  static errorSnackbar(message, title) => Get.snackbar(
        title,
        message,
        backgroundColor: Colors.red,
      );
  static successSnackbar(message, title) => Get.snackbar(
        title,
        message,
        backgroundColor: Colors.green,
      );
}
