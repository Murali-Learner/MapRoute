import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:MapRoute/views/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MapRoute',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const GoogleMapPage(),
    );
  }
}
