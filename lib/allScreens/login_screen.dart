import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Column(
            children: [
              SizedBox(
                height: 35.0,
              ),
              Image(image: AssetImage("images/logo.png"), width: 390.0, height: 250.0 ,),
              
              SizedBox(height: 1.0,),
              
              Text("Login As a Rider", textAlign: TextAlign.center, style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),),
              Padding(padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 1.0,),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
                    ),
                    style: TextStyle(
                        fontSize: 14.0
                    ),
                  ),

                  SizedBox(height: 1.0,),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
                    ),
                    style: TextStyle(
                        fontSize: 14.0
                    ),
                  ),

                  SizedBox(height: 20.0,),

                  RaisedButton(
                    color: Colors.yellow,
                    textColor: Colors.white,
                    child: Container(
                      height: 50.0,
                      child: Text("Login", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold"),),
                      alignment: Alignment.center,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                    onPressed: (){

                    },
                  ),

                ],
              ),
              ),
              
              FlatButton(onPressed: (){}, child: Text('Do not have an Account? Register Here'))

            ],
          ),
        ),
      ),
    );
  }
}
