import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_rider/configMaps.dart';
import 'package:smart_rider/dataHandler/app_data.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/helpers.dart';
import 'package:smart_rider/main.dart';
import '../models/models.dart';
import './screens.dart';
import '../widgets/widgets.dart';

class MainScreen extends StatefulWidget {
  static const routeName = "main-screen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;
  double requestRideContainerHeight = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double driverDetailsContainerHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference rideRequestRef;

  BitmapDescriptor nearByIcon;
  List<NearbyAvailableDrivers> availableDrivers;

  String state = "normal";

  StreamSubscription<Event> rideStreamSubscription;

  bool isRequestingPositionDetails  = false;



  @override
  void initState() {
    super.initState();

    HelperMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Request");

    var pickup = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickup.latitude.toString(),
      "longitude": pickup.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropOff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickup.placeName,
      "dropOff_address": dropOff.placeName,
    };

    rideRequestRef.push().set(rideInfoMap);
    rideStreamSubscription = rideRequestRef.onValue.listen((event)async {

      if(event.snapshot.value == null){
        return;
      }

      if(event.snapshot.value["car_details"] != null){
        setState(() {
          driverCarDetails = event.snapshot.value["car_details"].toString();
        });
      }

      if(event.snapshot.value["driver_phone"] != null){
        setState(() {
          driverPhone = event.snapshot.value["driver_phone"].toString();
        });
      }

      if(event.snapshot.value["driver_location"] != null){
          double driverLat = double.parse(event.snapshot.value["driver_location"]["latitude"].toString());
          double driverLng = double.parse(event.snapshot.value["driver_location"]["longitude"].toString());

          LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

          if(statusRide == "accepted"){
            updateRideTimeToPickupLocation(driverCurrentLocation);
          }else if(statusRide == "onride"){
            updateRideTimeToDropOffLocation(driverCurrentLocation);
          }else if(statusRide == "arrived"){
            setState(() {
              rideStatus = "Trip completed";
            });
          }
      }


      if(event.snapshot.value["driver_name"] != null){
        setState(() {
          driverName = event.snapshot.value["driver_name"].toString();
        });
      }

      if(event.snapshot.value["status"] != null){
        statusRide = event.snapshot.value["status"].toString();
      }
      if(statusRide == "accepted"){
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeoFireMarkers();
      }

      if(statusRide == "ended"){
         if(event.snapshot.value["fare"] != null){
           int fare = int.parse(event.snapshot.value["fare"].toString());

           var res =  await showDialog(
               context: context,
               barrierDismissible: false,
               builder: (BuildContext context) => CollectFareDialog(paymentMethod: "cash", fareAmount: fare,));

         //  Check the response from the other end
           if(res == "close"){
             rideRequestRef.onDisconnect();
             rideRequestRef = null;
             rideStreamSubscription.cancel();
             rideStreamSubscription = null;
             resetApp();
           }
         }
      }
    });
  }

  void deleteGeoFireMarkers(){
    markersSet.removeWhere((element) => element.markerId.value.contains("driver"));
  }

  void updateRideTimeToPickupLocation(LatLng driverCurrentLocation) async {
    if(isRequestingPositionDetails == false){
      isRequestingPositionDetails = true;
      var positionUserLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
      var details = await HelperMethods.obtainPlaceDirectionDetails(driverCurrentLocation, positionUserLatLng);

      if(details == null){
        return;
      }

      setState(() {
        rideStatus = "Driver is coming in " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLocation(LatLng driverCurrentLocation) async {
    if(isRequestingPositionDetails == false){
      isRequestingPositionDetails = true;
      var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff.latitude, dropOff.longitude);
      var details = await HelperMethods.obtainPlaceDirectionDetails(driverCurrentLocation, dropOffUserLatLng);

      if(details == null){
        return;
      }

      setState(() {
        rideStatus = "Going to destination " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }


  void cancelRideRequest() {
    rideRequestRef.remove();

    setState(() {
      state = "normal";
    });
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  void displayDriverDetailsContainer(){
      setState(() {
        requestRideContainerHeight = 0.0;
        rideDetailsContainerHeight = 0.0;
        bottomPaddingOfMap = 290.0;
        driverDetailsContainerHeight = 310.0;
      });
  }

  //Create a function that will reset our app
  resetApp() {
    setState(() {
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
      requestRideContainerHeight = 0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      statusRide = "";
      driverName = "";
      driverPhone = "";
      driverCarDetails = "";
      rideStatus = "Driver is Coming";
      driverDetailsContainerHeight = 0.0;
    });

    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0.0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 14.0);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await HelperMethods.searchCoordinateAddress(position, context);
    print("This is your address :: " + address);

    initGoeFireListener();
  }

  static final CameraPosition _josPosition = CameraPosition(
    target: LatLng(9.8965, 8.8583),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text('Smart Rider'),
        centerTitle: true,
        leading: Container(),
        actions: [
          IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, LoginScreen.routeName, (route) => false);
              })
        ],
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
                        Image.asset(
                          "images/user_icon.png",
                          height: 65.0,
                          width: 65.0,
                        ),
                        SizedBox(
                          width: 16.0,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Profile Name",
                              style: TextStyle(
                                  fontSize: 16.0, fontFamily: "Brand Bold"),
                            ),
                            SizedBox(
                              height: 6.0,
                            ),
                            Text("Visit Profile"),
                          ],
                        )
                      ],
                    )),
              ),

              CustomDivider(),

              SizedBox(
                height: 12.0,
              ),

              //  Drawer body
              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.routeName, (route) => false);
                },
                leading: Icon(Icons.info),
                title: Text(
                  "Logout",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
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
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 350.0;
              });

              locatePosition();
            },
          ),

          //HamburgerButton for drawer
          Positioned(
            top: 38.0,
            left: 22.0,
            child: InkWell(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 2.0,
                        spreadRadius: 0.2,
                        offset: Offset(0.2, 0.2),
                      )
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          //Search dropoff
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          blurRadius: 2.0,
                          spreadRadius: 0.2,
                          offset: Offset(0.5, 0.5))
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 6.0,
                      ),
                      Text(
                        "Hi there,",
                        style: TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        "Where to?,",
                        style:
                            TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));

                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey,
                                    blurRadius: 2.0,
                                    spreadRadius: 0.2,
                                    offset: Offset(0.5, 0.5))
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text("Search Drop Off")
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<AppData>(context)
                                              .pickUpLocation !=
                                          null
                                      ? Provider.of<AppData>(context)
                                          .pickUpLocation
                                          .placeName
                                      : "Add Home Address",
                                  style: TextStyle(fontSize: 12.0),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text(
                                  "Your living home address",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12.0),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      CustomDivider(),
                      SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Home"),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                "Your office address",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

           //Ride details position
          Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 16.0,
                            spreadRadius: 0.2,
                            offset: Offset(0.2, 0.2))
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.blue,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/taxi.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Car",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold",
                                          color: Colors.white),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null)
                                          ? tripDirectionDetails.distanceText
                                          : ''),
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.white54),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? 'N${HelperMethods.calculateFares(tripDirectionDetails)}'
                                      : ''),
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white54,
                                    fontFamily: "Brand Bold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.moneyCheckAlt,
                                size: 18.0,
                                color: Colors.black54,
                              ),
                              SizedBox(
                                width: 16.0,
                              ),
                              Text("Cash"),
                              SizedBox(
                                width: 6.0,
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black54,
                                size: 16.0,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 24.0,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: RaisedButton(
                            onPressed: () {
                              setState(() {
                                state = "requesting";
                              });
                              displayRequestRideContainer();
                              availableDrivers = GeoFireHelper.nearbyAvailableDriversList;
                              searchNearestDriver();
                            },
                            color: Theme.of(context).accentColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0)),
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Request",
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.taxi,
                                    color: Colors.white,
                                    size: 26.0,
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )),

          //Request/Cancel Position
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              height: requestRideContainerHeight,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 0.2,
                        blurRadius: 16.0,
                        color: Colors.black54,
                        offset: Offset(0.2, 0.2))
                  ]),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: new Column(
                  children: [
                    SizedBox(
                      height: 12.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ColorizeAnimatedTextKit(
                        onTap: () {
                          print("Tap Event");
                        },
                        text: [
                          "Requesting a Ride",
                          "Please wait...",
                          "Finding a driver...",
                        ],
                        textStyle:
                            TextStyle(fontSize: 55.0, fontFamily: "Signatra"),
                        colors: [
                          Colors.green,
                          Colors.purple,
                          Colors.pink,
                          Colors.blue,
                          Colors.yellow,
                          Colors.red,
                        ],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100.0),
                          border:
                              Border.all(width: 2.0, color: Colors.grey[300]),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          //Display assigned driver info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 0.2,
                        blurRadius: 16.0,
                        color: Colors.black54,
                        offset: Offset(0.2, 0.2))
                  ]),
              height: driverDetailsContainerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(rideStatus, textAlign: TextAlign.center, style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),),
                        ],
                      ),

                      SizedBox(height: 22.0,),

                      Divider(height: 2.0, thickness: 2.0,),

                      Text(driverCarDetails, style: TextStyle(color: Colors.grey),),

                      Text(driverName, style: TextStyle(fontSize: 20.0),),

                      SizedBox(height: 22.0,),

                      Divider(height: 2.0, thickness: 2.0,),

                      SizedBox(height: 22.0,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                        //  CALL BUTTOn
                          Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: RaisedButton(onPressed: () async{
                            launch(('tel://${driverPhone}'));
                          },
                          color: Colors.pink,
                            child: Padding(padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text("Call Driver", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                Icon(Icons.call, color: Colors.white, size: 26.0,),
                              ],
                            ),),
                          ),)
                        ],
                      )
                    ],
                  ),
                )
            ),)
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Please wait..."));

    var details = await HelperMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.of(context).pop();

    print("This are the encoded points ::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      // print("Good we are making progress!!!!!!!!!!!!!!!");
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
        // print(pLineCoordinates);
      });
    } else {
      // print("################## Problem no dey finish");
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.red,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        width: 5,
        points: pLineCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "My Location"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId"));

    Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "DropOff Location"),
        position: dropOffLatLng,
        markerId: MarkerId("dropOffId"));

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickupId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.purple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purple,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGoeFireListener() {
    Geofire.initialize("availableDrivers");
    //comment
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map["key"];
            nearbyAvailableDrivers.latitude = map["latitude"];
            nearbyAvailableDrivers.longitude = map["longitude"];
            GeoFireHelper.nearbyAvailableDriversList.add(nearbyAvailableDrivers);
            if(nearbyAvailableDriverKeysLoaded == true){
              updateAvailableDriverOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireHelper.removeDriverFromList(map['key']);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map["key"];
            nearbyAvailableDrivers.latitude = map["latitude"];
            nearbyAvailableDrivers.longitude = map["longitude"];
            GeoFireHelper.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriverOnMap();
            break;
        }
      }

      setState(() {});
    });

    // comment
  }

  void updateAvailableDriverOnMap(){
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMakers = Set<Marker>();
    for(NearbyAvailableDrivers driver in GeoFireHelper.nearbyAvailableDriversList){
      LatLng driverAvailablePosition = LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(markerId: MarkerId('driver${driver.key}'),
      position: driverAvailablePosition,
      icon: nearByIcon,
        rotation: HelperMethods.createRandomNumber(360),
      );

      tMakers.add(marker);
    }

    setState(() {
      markersSet = tMakers;
    });
  }

  void createIconMarker(){
    if(nearByIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_ios.png").then((value) {
        nearByIcon = value;
      });
    }
  }

  void noDriverFound(){
    showDialog(
      barrierDismissible: false,
        context: context, builder: (BuildContext context) => NoAvailableDriverDialog());
  }

  void searchNearestDriver(){
    if(availableDrivers.length == 0){
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

  //  if it is not zero then get the nearest driver

    var driver = availableDrivers[0];
    notifyDriver(driver);
    availableDrivers.removeAt(0);
  }

  void notifyDriver(NearbyAvailableDrivers driver){
    //Save the ride request ID in the nearest driver's node
    print("Driver Key################# " + driver.key);
    print("Ride Key################# " + rideRequestRef.key);

    driversRef.child(driver.key).child("newRide").set(rideRequestRef.key);
    driversRef.child(driver.key).child("token").once().then((DataSnapshot snap){
      if(snap.value != null){
        String token = snap.value.toString();
        print("########################## token" + token);
        HelperMethods.sendNotificationToDriver(token, context, rideRequestRef.key);
      }else {
        return;
        // print("############Problem No Token Found ###################");
      }


      const oneSecondPassed = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPassed, (timer) {
        if(state != "requesting"){
          driversRef.child(driver.key).child("newRide").set("cancelled");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
        }
        driverRequestTimeOut = driverRequestTimeOut - 1;

        driversRef.child(driver.key).child("newRide").onValue.listen((event) {
          if(event.snapshot.value.toString() == "accepted"){
            driversRef.child(driver.key).child("newRide").set("timeout");
            driversRef.child(driver.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        });

        if(driverRequestTimeOut == 0){
          driversRef.child(driver.key).child("newRide").set("timeout");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          searchNearestDriver();
        }
      });
    });
  }
}
