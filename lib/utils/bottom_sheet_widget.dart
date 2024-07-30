import 'package:MapRoute/utils/extensions/spacer_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';

class BottomSheetWidget extends StatelessWidget {
  const BottomSheetWidget({
    super.key,
    required this.result,
  });
  final PolylineResult result;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          5.vSpace,
          Container(
            height: 4,
            width: 20,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          10.vSpace,
          Text(
            'Route Information',
            style: Get.theme.textTheme.displayLarge!.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          const Divider(
            color: Colors.black,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AddressText(
                title: "Origin",
                subTitle: result.startAddress!,
              ),
              AddressText(
                title: "Destination",
                subTitle: result.endAddress!,
              ),
            ],
          ),
          16.vSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AddressText(
                title: "Distance",
                subTitle: result.distance!,
              ),
              AddressText(
                title: "Duration",
                subTitle: result.duration!,
              ),
            ],
          ),

          // Text('Overview Polyline: ${result.overviewPolyline}'),
        ],
      ),
    );
  }
}

class AddressText extends StatelessWidget {
  const AddressText({
    super.key,
    required this.title,
    required this.subTitle,
  });

  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Get.theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const Divider(
          endIndent: 50,
          color: Colors.black,
        ),
        Text(
          subTitle,
          style: Get.theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ));
  }
}
