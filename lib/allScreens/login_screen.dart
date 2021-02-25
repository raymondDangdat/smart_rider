import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_rider/allScreens/main_screen.dart';
import 'package:smart_rider/allScreens/registration_screen.dart';
import 'package:smart_rider/main.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = "login-screen";
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
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
              Image(
                image: AssetImage("images/logo.png"),
                width: 390.0,
                height: 250.0,
              ),
              SizedBox(
                height: 1.0,
              ),
              Text(
                "Login As a Rider",
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
                      controller: emailController,
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
                      controller: passwordController,
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
                          "Login",
                          style: TextStyle(
                              fontSize: 18.0, fontFamily: "Brand Bold"),
                        ),
                        alignment: Alignment.center,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0)),
                      onPressed: () {
                        if (emailController.text.length < 5 ||
                            !emailController.text.contains("@")) {
                          //  Show that the email entered is incorrect.
                          displayToastMessage(
                              context, "Enter a valid email please");
                        } else if (passwordController.text.length < 6) {
                          displayToastMessage(
                              context, "Please enter a valid password");
                        } else {
                          loginUser(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              FlatButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context,
                        RegistrationScreen.routeName, (route) => false);
                  },
                  child: Text('Do not have an Account? Register Here'))
            ],
          ),
        ),
      ),
    );
  }

  final _firebaseAuth = FirebaseAuth.instance;
  void loginUser(BuildContext context) async {
    final User user = (await _firebaseAuth
            .signInWithEmailAndPassword(
                email: emailController.text, password: passwordController.text)
            .catchError((errMs) {
      displayToastMessage(context, "Error occurred! " + errMs.toString());
    }))
        .user;

    if (user != null) {
      //  User has been logged in!

      usersRef.child(user.uid).once().then((DataSnapshot snapshot) {
            if (snapshot.value != null) {
              //  User has record, send the user to the main screen
              Navigator.pushNamedAndRemoveUntil(
                  context, MainScreen.routeName, (route) => false);
            } else {
              //  Something went wrong and user info is not saved in the database;
              _firebaseAuth.signOut();
              displayToastMessage(
                  context, "No record found, please create a new account");
            }
          });
    } else {
      //  Problem occurred and user was not created
      displayToastMessage(
          context, "Could not login user, please try again later");
    }
  }
}
