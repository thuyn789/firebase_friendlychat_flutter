import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:codelab_friendlychat_flutter/app_services/signup.dart';
import 'package:codelab_friendlychat_flutter/chat_screen.dart';
import 'package:codelab_friendlychat_flutter/cloud_services/firebase_services.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hideText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
        decoration: BoxDecoration(color: Colors.grey[200]),
        child: ListView(
          children: <Widget>[
            SizedBox(height: 75),
            //Page Title
            Text(
              'Welcome',
              style: TextStyle(
                fontSize: 40,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            //Subtitle
            Text(
              'Please login to continue',
              style: TextStyle(
                fontSize: 20,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 75),
            //Text field for email
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                hintText: 'name@email.com',
                hintStyle: TextStyle(
                  color: Colors.blueAccent,
                ),
                labelText: 'Email Address',
                labelStyle: TextStyle(
                  color: Colors.blueAccent,
                ),
              ),
            ),
            SizedBox(height: 5),
            //Text field for password
            TextFormField(
              obscureText: _hideText,
              controller: _password,
              decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: Colors.blueAccent,
                  ),
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideText = !_hideText;
                        });
                      },
                      icon: Icon(Icons.remove_red_eye))),
            ),
            SizedBox(height: 10),
            //Forgot password button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MaterialButton(
                    onPressed: () {
                      print('Forgot button clicked');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    )),
              ],
            ),
            SizedBox(height: 15),
            //Login button
            Container(
              height: 45,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: Colors.orangeAccent[100]),
              child: MaterialButton(
                //When clicked, the app will contact firebase for authentication
                //using user's inputted login credential
                onPressed: () async {
                  bool successful = await AuthServices().login(_email.text, _password.text);
                  if (successful) {
                    //when successful, navigate user to home page
                    String? userID = FirebaseAuth.instance.currentUser!.uid;
                    DocumentSnapshot database = await AuthServices().retrieveUserData(userID);
                    final userObj = database.data() as Map<String, dynamic>;
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => ChatScreen(userObj: userObj, signInMethod: 0,)));
                  } else {
                    //when not successful, popup alert
                    //and prompt user to try again
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Text(
                                'Incorrect email/password. Please try again!'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('OK'),
                              ),
                            ],
                          );
                        });
                  }
                },
                child: Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 45,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: Colors.red
              ),
              child: MaterialButton(
                //When clicked, the app will contact firebase for authentication
                //using user's inputted login credential
                onPressed: () async {
                  await AuthServices()
                      .signInWithGoogle()
                      .then((UserCredential credential) {
                    final userObj = credential.user as Map<String, dynamic>;
                    MaterialPageRoute(builder: (context) => ChatScreen(userObj: userObj, signInMethod: 1,));
                  });
                },
                child: Text(
                  'Login with Google',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            //Create new account button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(
                  'First Time to Fan App?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                MaterialButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()));
                    },
                    child: Text(
                      'Create New Account',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
