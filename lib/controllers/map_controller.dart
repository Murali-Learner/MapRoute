import 'dart:convert';
import 'dart:developer';
import 'package:MapRoute/utils/bottom_sheet_widget.dart';
import 'package:MapRoute/utils/global_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:MapRoute/models/place_suggestion.dart';
import 'package:MapRoute/utils/constants.dart';

class MapController extends GetxController {
  var currentPosition = Rxn<LatLng>();
  var polylines = <PolylineId, Polyline>{}.obs;
  var markers = <MarkerId, Marker>{}.obs;

  var originSuggestions = <PlaceSuggestion>[].obs;
  var destinationSuggestions = <PlaceSuggestion>[].obs;
  var isLoading = false.obs;
  var isFetchingPolyline = false.obs;

  var originPosition = Rxn<LatLng>();
  var destinationPosition = Rxn<LatLng>();

  TextEditingController originController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();

    fetchLocationUpdates();
    // Watch for changes in origin and destination positions
    ever(originPosition, (_) => updateMarkersAndFetchPolyline());
    ever(destinationPosition, (_) => updateMarkersAndFetchPolyline());
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permissionGranted;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        return;
      }
    }
    log("service $serviceEnabled");
    permissionGranted = await Geolocator.checkPermission();
    if (permissionGranted == LocationPermission.denied) {
      permissionGranted = await Geolocator.requestPermission();
      if (permissionGranted != LocationPermission.whileInUse &&
          permissionGranted != LocationPermission.always) {
        return;
      }
    }

    log("Got the location service enabled: $serviceEnabled, permission: $permissionGranted");
    Geolocator.getPositionStream().listen((currentLocation) {
      currentPosition.value =
          LatLng(currentLocation.latitude, currentLocation.longitude);
      log("Got the location: ${currentPosition.value}");
      markers[const MarkerId('currentLocation')] = Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentPosition.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "Current Location"),
      );
    });
  }

  Future<void> getSuggestions(String query, {required bool isOrigin}) async {
    isLoading.value = true;
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleMapsApiKey',
      ),
    );
    isLoading.value = false;

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      debugPrint("json $json");
      final predictions = json['predictions'] as List;
      final suggestions = predictions
          .map((prediction) => PlaceSuggestion(
                description: prediction['description'],
                placeId: prediction['place_id'],
              ))
          .toList();

      if (isOrigin) {
        originSuggestions.assignAll(suggestions);
      } else {
        destinationSuggestions.assignAll(suggestions);
      }
    } else {
      log("Failed to load suggestions");
    }
  }

  void hideKeyboard() {
    FocusScope.of(Get.context!).unfocus();
  }

  Future<void> updateOriginMarker(String placeId) async {
    final position = await getLatLngFromPlaceId(placeId);
    if (position != null) {
      originPosition.value = position;
      originSuggestions.clear();
      markers[const MarkerId('originLocation')] = Marker(
        markerId: const MarkerId('originLocation'),
        position: originPosition.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Origin Location"),
      );
    }
    hideKeyboard();
  }

  Future<void> updateDestinationMarker(String placeId) async {
    final position = await getLatLngFromPlaceId(placeId);
    if (position != null) {
      destinationPosition.value = position;
      destinationSuggestions.clear();
      markers[const MarkerId('destinationLocation')] = Marker(
        markerId: const MarkerId('destinationLocation'),
        position: destinationPosition.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Destination Location"),
      );
    }
    hideKeyboard();
  }

  Future<LatLng?> getLatLngFromPlaceId(String placeId) async {
    isLoading.value = true;
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$googleMapsApiKey',
      ),
    );
    isLoading.value = false;

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final location = json['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } else {
      log("Failed to get LatLng");
      return null;
    }
  }

  void updateMarkersAndFetchPolyline() {
    if (originPosition.value != null) {
      markers[const MarkerId('originLocation')] = Marker(
        markerId: const MarkerId('originLocation'),
        position: originPosition.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Origin Location"),
      );
    }

    if (destinationPosition.value != null) {
      markers[const MarkerId('destinationLocation')] = Marker(
        markerId: const MarkerId('destinationLocation'),
        position: destinationPosition.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Destination Location"),
      );
    }

    if (originPosition.value != null && destinationPosition.value != null) {
      fetchPolylineAndMarkers();
    }
  }

  Future<void> fetchPolylineAndMarkers() async {
    hideKeyboard();
    if (!isFetchingPolyline.value) {
      isFetchingPolyline.value = true;
      markers.removeWhere((key, value) =>
          key != const MarkerId('currentLocation') &&
          key != const MarkerId('originLocation') &&
          key != const MarkerId('destinationLocation'));
      final coordinates = await fetchPolylinePoints();
      generatePolyLineFromPoints(coordinates);
      isFetchingPolyline.value = false;
      if (coordinates.isNotEmpty) {
        animateCameraToFitPolyline(coordinates);
      }
    } else {
      Get.showSnackbar(const GetSnackBar(
        title: "Loading...",
        message: "Directions are loading...",
      ));
    }
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    if (originPosition.value == null || destinationPosition.value == null) {
      log("Origin or destination marker is not set");
      return [];
    }

    final polylinePoints = PolylinePoints();

    try {
      final PolylineResult result =
          await polylinePoints.getRouteBetweenCoordinates(
        googleMapsApiKey,
        PointLatLng(
            originPosition.value!.latitude, originPosition.value!.longitude),
        PointLatLng(destinationPosition.value!.latitude,
            destinationPosition.value!.longitude),
      );

      if (result.points.isNotEmpty) {
        // for (PointLatLng element in result.alternatives) {
        //   log("alternatives ${element.latitude} ${element.longitude}");
        // }
        // for (PointLatLng element in result.points) {
        //   log("PointLatLng ${element.latitude} ${element.longitude}");
        // }

        debugPrint("poly points ${result.toString()}");
        showBottomSheet(result);
        return result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      } else {
        log("No route found: ${result.errorMessage}");
        Utils.errorSnackbar(
            "Route Error", "No route found between the selected locations");
        return [];
      }
    } catch (e) {
      log("Failed to get route: $e");

      return [];
    }
  }

  void showBottomSheet(PolylineResult result) {
    Get.bottomSheet(
      BottomSheetWidget(
        result: result,
      ),
      isScrollControlled: true,
    );
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    polylines[id] = polyline;
  }

  void animateCameraToFitPolyline(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isEmpty || mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        polylineCoordinates
            .map((p) => p.latitude)
            .reduce((a, b) => a < b ? a : b),
        polylineCoordinates
            .map((p) => p.longitude)
            .reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        polylineCoordinates
            .map((p) => p.latitude)
            .reduce((a, b) => a > b ? a : b),
        polylineCoordinates
            .map((p) => p.longitude)
            .reduce((a, b) => a > b ? a : b),
      ),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    // _zoomOut();
    hideKeyboard();
  }

  Future<BitmapDescriptor> loadCustomMarker(String assetName) async {
    final BitmapDescriptor customMarker = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      assetName,
    );

    return customMarker;
  }

  Future<void> _zoomOut() async {
    final currentZoomLevel = await mapController!.getZoomLevel();

    mapController!.animateCamera(CameraUpdate.zoomTo(10));
    mapController!.animateCamera(CameraUpdate.zoomTo(currentZoomLevel - 1));
  }
  // Future<BitmapDescriptor> _loadCustomMarker(String assetPath) async {
  //   final byteData = await rootBundle.load(assetPath);
  //   final uint8List = byteData.buffer.asUint8List();
  //   return BitmapDescriptor.bytes(uint8List);
  // }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }
}
