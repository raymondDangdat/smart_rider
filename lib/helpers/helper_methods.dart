import 'package:geolocator/geolocator.dart';
import 'package:smart_rider/configMaps.dart';
import 'package:smart_rider/helpers/api_helper.dart';

class HelperMethods{
  static Future<String> searchCoordinateAddress (Position position)async{
    String placeAddress = "";
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    var response = await ApiRequestHelper.getRequest(url);

    if(response != "failed"){
      placeAddress = response["results"][0]["formatted_address"];
      return placeAddress;
    }
  }
}