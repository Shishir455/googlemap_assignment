import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MainGoogleMap extends StatefulWidget {
  const MainGoogleMap({super.key});

  @override
  State<MainGoogleMap> createState() => _MainGoogleMapState();
}

class _MainGoogleMapState extends State<MainGoogleMap> {
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  List<LatLng> polylinePoints = [];
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;
  int markerIdCounter = 1;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _addMarkerAndPolyline(LatLng(position.latitude, position.longitude));
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      Position position = await Geolocator.getCurrentPosition();
      _addMarkerAndPolyline(LatLng(position.latitude, position.longitude));
    });
  }

  void _addMarkerAndPolyline(LatLng position) {
    final markerId = MarkerId("Marker_${markerIdCounter++}");

    setState(() {
      // Add new marker
      _markers.add(
        Marker(
          markerId: markerId,
          position: position,
          infoWindow: InfoWindow(
            title: "Marker ${markerId.value}",
            snippet: "Lat: ${position.latitude}, Lng: ${position.longitude}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      // Add to polyline list
      polylinePoints.add(position);

      // Draw polyline
      _polylines = {
        Polyline(
          polylineId: PolylineId("Polyline"),
          points: polylinePoints,
          color: Colors.blue,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        )
      };
    });

    mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi Marker Tracker'),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(23.80005664936871, 90.35517378038338),
          zoom: 15,
        ),
        onMapCreated: _onMapCreated,
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onTap: (LatLng latLng) {
          print("Lat: ${latLng.latitude}, Lng: ${latLng.longitude}");
          _addMarkerAndPolyline(latLng);
        },
      ),
    );
  }
}
