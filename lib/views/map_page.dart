import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:MapRoute/views/widgets/address_input_field.dart';

import '../controllers/map_controller.dart';

class GoogleMapPage extends StatelessWidget {
  const GoogleMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController mapController = Get.put(MapController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('MapRoute'),
      ),
      body: Center(
        child: Obx(() {
          if (mapController.currentPosition.value == null) {
            return const CircularProgressIndicator.adaptive();
          } else {
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    mapController.setMapController(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target: mapController.currentPosition.value!,
                    zoom: 11,
                  ),
                  markers: Set<Marker>.of(mapController.markers.values),
                  polylines: Set<Polyline>.of(mapController.polylines.values),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    child: Column(
                      children: [
                        AddressInputField(
                          controller: mapController.originController,
                          hintText: 'Enter origin address',
                          suggestions: mapController.originSuggestions,
                          onChanged: (value) => mapController
                              .getSuggestions(value, isOrigin: true),
                          onSuggestionSelected: (suggestion) {
                            mapController
                                .updateOriginMarker(suggestion.placeId);
                            mapController.originController.text =
                                suggestion.description;
                          },
                        ),
                        const SizedBox(height: 10),
                        AddressInputField(
                          controller: mapController.destinationController,
                          hintText: 'Enter destination address',
                          suggestions: mapController.destinationSuggestions,
                          onChanged: (value) => mapController
                              .getSuggestions(value, isOrigin: false),
                          onSuggestionSelected: (suggestion) {
                            mapController
                                .updateDestinationMarker(suggestion.placeId);
                            mapController.destinationController.text =
                                suggestion.description;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 10,
                  child: Obx(() {
                    return FloatingActionButton(
                      onPressed: mapController.fetchPolylineAndMarkers,
                      child: mapController.isFetchingPolyline.value
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            )
                          : const Icon(Icons.directions),
                    );
                  }),
                ),
                if (mapController.isLoading.value)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          }
        }),
      ),
    );
  }
}
