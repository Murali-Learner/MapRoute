import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_route_project/controllers/map_controller.dart';
import 'package:map_route_project/models/place_suggestion.dart';

class AddressInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final List<PlaceSuggestion> suggestions;
  final Function(String) onChanged;
  final Function(PlaceSuggestion) onSuggestionSelected;

  const AddressInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: hintText,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          onChanged: onChanged,
        ),
        Obx(() {
          final mapController = Get.find<MapController>();
          return suggestions.isEmpty || mapController.isLoading.value
              ? Container()
              : Container(
                  margin: const EdgeInsets.only(top: 5),
                  color: Colors.white,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        title: Text(suggestion.description),
                        onTap: () => onSuggestionSelected(suggestion),
                      );
                    },
                  ),
                );
        }),
      ],
    );
  }
}
