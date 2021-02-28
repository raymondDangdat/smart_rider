import '../models/nearbyAvailableDrivers.dart';
class GeoFireHelper {
  static List<NearbyAvailableDrivers> nearbyAvailableDriversList = [];

  static void removeDriverFromList(String key){
    int index = nearbyAvailableDriversList.indexWhere((element) => element.key == key);
    nearbyAvailableDriversList.remove(index);

  }

  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver){
    int index = nearbyAvailableDriversList.indexWhere((element) => element.key == driver.key);

    nearbyAvailableDriversList[index].longitude = driver.longitude;
    nearbyAvailableDriversList[index].latitude = driver.latitude;
  }


}
