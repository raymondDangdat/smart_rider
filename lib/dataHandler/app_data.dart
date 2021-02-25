import 'package:flutter/cupertino.dart';
import 'package:smart_rider/models/address.dart';

class AppData extends ChangeNotifier{

  Address pickUpLocation;

  void updatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }
}