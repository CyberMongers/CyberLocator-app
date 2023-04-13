import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RocketSocket extends StatefulWidget {
  const RocketSocket({super.key});

  @override
  State<RocketSocket> createState() => _RocketSocketState();
}

class _RocketSocketState extends State<RocketSocket> {
  final mapController = MapController();
  LatLng? currentLocation;
  bool? isTransmitting = false;

  @override
  void initState() {
    super.initState();
    isTransmitting = false;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation)
        .then((value) {
      setState(() {
        currentLocation = LatLng(value.latitude, value.longitude);
        mapController.move(currentLocation!, 15);
      });
    });
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      setState(() {
        currentLocation = LatLng(position!.latitude, position.longitude);
        mapController.move(currentLocation!, 15);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: currentLocation ?? LatLng(22.5726, 88.3639),
                  //   bounds: LatLngBounds(
                  //       LatLng(29, 77.8963), LatLng(29.8659, 77.8963)),
                ),
                nonRotatedChildren: [],
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.kavach.socket_rocket',
                  ),
                  currentLocation == null
                      ? Container()
                      : MarkerLayer(
                          markers: [
                            Marker(
                              point: currentLocation!,
                              width: 80,
                              height: 80,
                              builder: (context) => const Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    child: Text("RoomID: 123456"),
                  )),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isTransmitting = !isTransmitting!;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTransmitting! ? Colors.red : Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                child: Text(
                  isTransmitting! ? "Stop Transmitting" : "Start Transmitting",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
    )));
  }
}
