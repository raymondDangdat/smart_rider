import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_rider/helpers/helper_methods.dart';
import 'package:smart_rider/widgets/divider.dart';

class MainScreen extends StatefulWidget {
  static const routeName = "main-screen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  void locatePosition() async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
    
    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLngPosition, zoom: 14.0);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address = await HelperMethods.searchCoordinateAddress(position);
    print("This is your address :: " + address);
  }


  static final CameraPosition _josPosition = CameraPosition(
    target: LatLng(9.8965, 8.8583),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Rider'),
        centerTitle: true,
      ),
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                        Image.asset("images/user_icon.png", height: 65.0, width: 65.0,),
                        SizedBox(width: 16.0,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Profile Name", style: TextStyle(fontSize: 16.0, fontFamily: "Brand Bold"),),
                            SizedBox(height: 6.0,),
                            Text("Visit Profile"),
                          ],
                        )
                      ],
                    )),
              ),

              CustomDivider(),

              SizedBox(height: 12.0,),
              
            //  Drawer body
              ListTile(leading: Icon(Icons.history),
              title: Text("History", style: TextStyle(fontSize: 15.0),),),

              ListTile(leading: Icon(Icons.person),
                title: Text("Visit Profile", style: TextStyle(fontSize: 15.0),),),

              ListTile(leading: Icon(Icons.info),
                title: Text("History", style: TextStyle(fontSize: 15.0),),),

            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            initialCameraPosition: _josPosition,
          mapType: MapType.normal,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          onMapCreated: (GoogleMapController controller){

            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;

            setState(() {
              bottomPaddingOfMap = 350.0;
            });

            locatePosition();
          },),

          Positioned(
            left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: Container(
                height: 300.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 2.0,
                    spreadRadius: 0.2,
                    offset: Offset(0.5, 0.5)
                  )
                ]
              ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 6.0,
                      ),
                      Text("Hi there,", style: TextStyle(fontSize: 12.0), ),
                      Text("Where to?,", style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"), ),
                      SizedBox(height: 20.0,),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 2.0,
                                  spreadRadius: 0.2,
                                  offset: Offset(0.5, 0.5)
                              )
                            ]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(children: [
                            Icon(Icons.search, color: Colors.blueAccent,),
                            SizedBox(width: 10.0,),
                            Text("Search Drop Off")
                          ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0,),
                      Row(
                        children: [
                          Icon(Icons.home, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Home"),
                              SizedBox(height: 4.0,),
                              Text("Your living home address", style: TextStyle(color: Colors.black54, fontSize: 12.0),)
                            ],
                          )
                        ],
                      ),

                      SizedBox(height: 10.0,),

                      CustomDivider(),
                      SizedBox(height: 16.0,),
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Home"),
                              SizedBox(height: 4.0,),
                              Text("Your office address", style: TextStyle(color: Colors.black54, fontSize: 12.0),)
                            ],
                          )
                        ],
                      )

                    ],
                  ),
                ),
              ),

          ),

        ],
      ),
    );
  }
}
