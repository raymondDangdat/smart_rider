import 'package:flutter/cupertino.dart';
import 'package:smart_rider/model/address.dart';

class AppData extends ChangeNotifier{

  Address pickUpLocation;

  void updatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }
}