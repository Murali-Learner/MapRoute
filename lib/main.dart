import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_route_project/views/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map route project',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const GoogleMapPage(),
    );
  }
}
