import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:smart_rider/configMaps.dart';
import 'package:smart_rider/dataHandler/app_data.dart';
import 'package:smart_rider/helpers/api_helper.dart';
import 'package:smart_rider/models/address.dart';

class HelperMethods{
  static Future<String> searchCoordinateAddress (Position position, context)async{
    String placeAddress = "";
    String st1, st2, st3, st4;
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    var response = await ApiRequestHelper.getRequest(url);

    if(response != "failed"){
      // placeAddress = response["results"][0]["formatted_address"];

      //to get the house number use index 0 for long_name and for street name use index 1

      st1 = response["results"][0]["address_components"][2]["long_name"];
      // st2 = response["results"][0]["address_components"][3]["long_name"];
      st3 = response["results"][0]["address_components"][4]["long_name"];
      st4 = response["results"][0]["address_components"][4]["long_name"];

      placeAddress = st1  + ", " + st3 + ", " + st4;

      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;
      
      Provider.of<AppData>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);

    }
    return placeAddress;
  }
}