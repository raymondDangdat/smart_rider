import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_rider/dataHandler/app_data.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _pickUpController = TextEditingController();
  TextEditingController _dropOffController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    String placeAddress = Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    _pickUpController.text = placeAddress;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 215.0,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 2.0,
                  spreadRadius: 0.2,
                  offset: Offset(0.2, 0.2)
                )
              ]
            ),
            child: Padding(padding: EdgeInsets.only(left: 25.0, top: 25.0, right: 25.0, bottom: 20.0),
            child: Column(children: [
              SizedBox(height: 5.0,),
              Stack(
                children: [
                  GestureDetector(
                    onTap: (){
                      Navigator.of(context).pop();
                    },
                      child: Icon(Icons.arrow_back_ios)),
                  Center(
                     child: Text("Set Drop Off", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold"),),
                  )
                ],
              ),

              SizedBox(height: 16.0,),
              Row(
                children: [
                  Image.asset("images/pickicon.png", height: 16.0, width: 16.0,),

                  SizedBox(width: 18.0,),

                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(5.0)),
                      child: Padding(padding: EdgeInsets.all(3.0),
                      child: TextField(
                        controller: _pickUpController,
                        decoration: InputDecoration(
                          hintText: "PickUp Location",
                          fillColor: Colors.grey[400],
                          filled: true,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0)
                        ),
                      ),),))

                ],
              ),


              SizedBox(height: 10.0,),
              Row(
                children: [
                  Image.asset("images/desticon.png", height: 16.0, width: 16.0,),

                  SizedBox(width: 18.0,),

                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(5.0)),
                    child: Padding(padding: EdgeInsets.all(3.0),
                      child: TextField(
                        controller: _dropOffController,
                        decoration: InputDecoration(
                            hintText: "Where to ?",
                            fillColor: Colors.grey[400],
                            filled: true,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0)
                        ),
                      ),),))

                ],
              ),

            ],)
              ,),
          )
        ],
      ),
    );
  }
}
