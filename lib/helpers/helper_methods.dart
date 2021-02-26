import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_rider/configMaps.dart';
import 'package:smart_rider/dataHandler/app_data.dart';
import 'package:smart_rider/helpers/api_helper.dart';
import 'package:smart_rider/models/address.dart';
import 'package:smart_rider/models/direction_details.dart';

class HelperMethods {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
    String st1, st2, st3, st4;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    var response = await ApiRequestHelper.getRequest(url);

    if (response != "failed") {
      // placeAddress = response["results"][0]["formatted_address"];

      //to get the house number use index 0 for long_name and for street name use index 1

      st1 = response["results"][0]["address_components"][2]["long_name"];
      st2 = response["results"][0]["address_components"][3]["long_name"];
      st3 = response["results"][0]["address_components"][4]["long_name"];
      st4 = response["results"][0]["address_components"][4]["long_name"];

      placeAddress = st1 + ", " + st2 + ", " + st3 + ", " + st4;

      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude}, ${initialPosition.longitude}&destination=${finalPosition.latitude}, ${finalPosition.longitude}&key=$mapKey";

    var res = await ApiRequestHelper.getRequest(directionUrl);

    if (res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();
    directionDetails.encodedPoints =
        res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText =
        res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue =
        res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText =
        res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue =
        res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    //in terms of USD
    double timeTravelFare = (directionDetails.durationValue / 60) * 0.020;
    double distanceTraveledFare =
        (directionDetails.distanceValue / 1000) * 0.020;

    double totalFareAmount = timeTravelFare + distanceTraveledFare;

    //  to convert to local currency
    //  double localAmount = totalFareAmount * exchange rate
    totalFareAmount = totalFareAmount * 380;

    return totalFareAmount.truncate();
  }
}
