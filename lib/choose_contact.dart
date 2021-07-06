import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:codelab_friendlychat_flutter/app_services/login.dart';
import 'package:codelab_friendlychat_flutter/chat_screen.dart';
import 'package:codelab_friendlychat_flutter/cloud_services/firebase_services.dart';

class ChooseContact extends StatelessWidget {
  ChooseContact({
    required this.userObj,
    required this.signInMethod,
  });

  //User Object - A map of DocumentSnapshot
  //Contain user information, name, uid, and email
  final userObj;

  //Sign in method
  //1 - Email/password
  //2 - Google social sign in
  //3 - Anonymous login
  final int signInMethod;

  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance.collection('users').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent[100],
        title: Text(
          'FriendlyChat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Signing Out?'),
                      content: Text('Do you want to sign out?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                            AuthServices().signOut();
                          },
                          child: Text('Yes'),
                        ),
                      ],
                    );
                  });
            },
            icon: Icon(Icons.person, color: Colors.blueAccent,),
            label: Text(
              'Sign Out?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            style: TextButton.styleFrom(
              primary: Colors.white,
            ),
          )
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                print(snapshot.error);
                return Text('Something went wrong');
              } else if (snapshot.hasData) {
                return new ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> recipient = document.data() as Map<String, dynamic>;
                    String firstname = recipient['first_name'];
                    String lastname = recipient['last_name'];
                    String name = '$firstname $lastname';
                    return new ListTile(
                      onTap: (){
                        print ("Click $name");
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ChatScreen(
                              userObj: userObj,
                              signInMethod: signInMethod,
                              recipient: recipient,)
                            ));
                      },
                      leading: CircleAvatar(
                        radius: 25,
                        child: Text(name[0]),
                        //backgroundImage: ,
                      ),
                      title: new Text(name),
                    );
                  }).toList(),
                );
              } else {
                return Text('No Users Found');
              }
          }
        },
      ),
    );
  }
}