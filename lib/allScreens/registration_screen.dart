import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smart_rider/allScreens/login_screen.dart';
import 'package:smart_rider/allScreens/main_screen.dart';
import 'package:smart_rider/main.dart';
import 'package:smart_rider/widgets/progress_dialog.dart';

class RegistrationScreen extends StatelessWidget {
  static const routeName = "registration-screen";

  TextEditingController textEditingControllerEmail = TextEditingController();
  TextEditingController textEditingControllerName = TextEditingController();
  TextEditingController textEditingControllerPassword = TextEditingController();
  TextEditingController textEditingControllerPhone = TextEditingController();
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
                height: 20.0,
              ),
              Image(
                image: AssetImage("images/logo.png"),
                width: 390.0,
                height: 250.0,
              ),
              SizedBox(
                height: 1.0,
              ),
              Text(
                "Register As a Rider",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: textEditingControllerName,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: textEditingControllerEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: textEditingControllerPhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone",
                        labelStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: textEditingControllerPassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    RaisedButton(
                      color: Colors.yellow,
                      textColor: Colors.white,
                      child: Container(
                        height: 50.0,
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                              fontSize: 18.0, fontFamily: "Brand Bold"),
                        ),
                        alignment: Alignment.center,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0)),
                      onPressed: () {
                        //run some checks
                        if (textEditingControllerName.text.length < 4) {
                          displayToastMessage(
                              context, "Name must be at least 3 characters");
                        } else if (textEditingControllerEmail.text.length < 5 ||
                            !textEditingControllerEmail.text.contains("@")) {
                          //  Show that the email entered is incorrect.
                          displayToastMessage(
                              context, "Enter a valid email please");
                        } else if (textEditingControllerPhone.text.length <
                            11) {
                          displayToastMessage(
                              context, "Enter a valid phone number");
                        } else if (textEditingControllerPassword.text.length <
                            6) {
                          displayToastMessage(context,
                              "Password must be at least 6 characters");
                        } else {
                          //  Everything seems okay so register user
                          registerNewUser(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              FlatButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, LoginScreen.routeName, (route) => false);
                  },
                  child: Text('Already have an account?? Login Here'))
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void registerNewUser(BuildContext context) async {
    showDialog(context:  context, barrierDismissible: false, builder: (BuildContext context){
      return ProgressDialog(message: "Creating account, please wait...",);
    });

    final User user = (await _firebaseAuth
            .createUserWithEmailAndPassword(
                email: textEditingControllerEmail.text,
                password: textEditingControllerPassword.text)
            .catchError((errMs) {
      Navigator.of(context).pop();
      displayToastMessage(context, "Error occurred! " + errMs.toString());
    }))
        .user;
    if (user != null) {
      //  User has been created!
      Map userDataMap = {
        "name": textEditingControllerName.text.trim(),
        "email": textEditingControllerEmail.text.trim(),
        "phone": textEditingControllerPhone.text.trim(),
      };
      usersRef.child(user.uid).set(userDataMap);
      displayToastMessage(context, "Account created!");

      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.routeName, (route) => false);
    } else {
      Navigator.of(context).pop();
      //  Problem occurred and user was not created
      displayToastMessage(
          context, "Could not create user, please try again later");
    }
  }
}

//  Toast message display
displayToastMessage(BuildContext context, String message) {
  Fluttertoast.showToast(msg: message);
}
