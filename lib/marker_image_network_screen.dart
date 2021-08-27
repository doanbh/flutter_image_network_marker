import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

class MarkerImageNetworkScreen extends StatefulWidget {
  const MarkerImageNetworkScreen({Key key}) : super(key: key);

  @override
  _MarkerImageNetworkScreenState createState() => _MarkerImageNetworkScreenState();
}

class _MarkerImageNetworkScreenState extends State<MarkerImageNetworkScreen> with TickerProviderStateMixin{
  Uint8List imageDataBytes;

  List<MarkerNetwork> _listMarkerNetwork = [
    new MarkerNetwork(new GlobalKey(), 20.99414, 105.8403812, "https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Blackpink_Lisa_190621_2.png/220px-Blackpink_Lisa_190621_2.png"),
    new MarkerNetwork(new GlobalKey(), 21.0061088, 105.8316997, "https://i.pinimg.com/originals/1d/1e/9b/1d1e9b6e9edef5820eaf1dffd03f2cf7.jpg"),
    new MarkerNetwork(new GlobalKey(), 21.0007207, 105.8455577, "https://i.pinimg.com/originals/61/52/0b/61520bc22b97140e0877c8ecc1d401cb.jpg"),
  ];

  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  Position currentPosition;
  var geoLocator = Geolocator();

  Set<Marker> markerSet = {};

  bool _loading = false;

  static final CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(20.9967893, 105.8407726),
      zoom: 14
  );

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_) => _getUserInfo());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final spinkit = SpinKitPulse(
      color: Colors.white,
      size: 50.0,
      controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)),
    );
    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              getMarkerWidget(),
              Container(
                child: GoogleMap(
                  padding: EdgeInsets.only(bottom: 0),
                  mapType: MapType.normal,
                  // myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomGesturesEnabled: true,
                  // zoomControlsEnabled: true,
                  initialCameraPosition: _kGooglePlex,
                  markers: markerSet,
                  onMapCreated: (GoogleMapController controller) {
                    _controllerGoogleMap.complete(controller);
                    newGoogleMapController = controller;

                    locatePosition();
                  },
                ),
              ),

              Positioned(
                top: 50,
                left: 10,
                child: InkWell(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
        Visibility(
            visible: _loading,
            child: spinkit
        )
      ],
    );
  }

  void locatePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentPosition = position;

      LatLng latLngPosition = LatLng(position.latitude, position.longitude);

      CameraPosition cameraPosition = new CameraPosition(
          target: latLngPosition, zoom: 14);

      newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    } catch (e){
      print("exp: $e");
    }

  }

  Future getMarker() async {
    await Future.wait(_listMarkerNetwork.map((markerNet) => getCustomMarkerIcon(markerNet)));
    setState(() {

    });
  }

  _getUserInfo() async {
    Future.delayed(Duration(seconds: 3), () {
      getMarker();
    });
  }

  getMarkerWidget() {
    return Stack(
      children: _listMarkerNetwork.map((marker) => Transform.translate(
        offset: Offset(80, 80),
        child: RepaintBoundary(
          key: marker.key,
          child: SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/ic_location_online.png'),
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: FractionalOffset.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: ClipOval(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: marker.image,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Future getCustomMarkerIcon(MarkerNetwork markerNet) async {
    RenderRepaintBoundary boundary = markerNet.key.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData.buffer.asUint8List();
    Marker cusMarker = new Marker(
      icon: BitmapDescriptor.fromBytes(pngBytes),
      infoWindow: InfoWindow(
          title: "Custom marker", snippet: "My Location"),
      position: LatLng(markerNet.mkLat, markerNet.mkLng),
      markerId: MarkerId(_listMarkerNetwork.indexOf(markerNet).toString()),
    );
    markerSet.add(cusMarker);
  }
}

class MarkerNetwork{
  double mkLat;
  double mkLng;
  String image;
  GlobalKey key;

  MarkerNetwork(this.key, this.mkLat, this.mkLng, this.image);
}
