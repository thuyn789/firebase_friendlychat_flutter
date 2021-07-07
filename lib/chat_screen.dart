import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:codelab_friendlychat_flutter/app_services/login.dart';
import 'package:codelab_friendlychat_flutter/cloud_services/firebase_services.dart';

import 'package:codelab_friendlychat_flutter/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.userObj,
    required this.signInMethod,
    required this.recipient,
  });

  //User Object - A map of DocumentSnapshot
  //Contain user information, name, uid, and email
  final userObj;

  //Sign in method
  //1 - Email/password
  //2 - Google social sign in
  //3 - Anonymous login
  final int signInMethod;

  //Recipient
  final recipient;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent[100],
        title: Text(
          'FriendlyChat',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()));
                            AuthServices().signOut();
                          },
                          child: Text('Yes'),
                        ),
                      ],
                    );
                  });
            },
            icon: Icon(
              Icons.person,
              color: Colors.blueAccent,
            ),
            label: Text(
              'Sign Out?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            style: TextButton.styleFrom(
              primary: Colors.white,
            ),
          )
        ],
      ),
      body: Container(
          decoration: BoxDecoration(color: Colors.grey[200]),
          child: Column(
            children: <Widget>[
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _messageStreamWidget(),
                ),
              ),
              Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          )),
    );
  }

  Widget _messageStreamWidget() {
    String userID = widget.userObj['user_id'];
    String recipientID = widget.recipient['user_id'];

    return StreamBuilder<QuerySnapshot>(
        stream: AuthServices().messageStream(userID, recipientID),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text("Loading"));
          }

          return ListView(
            reverse: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return Row(
                children: <Widget>[
                  ChatMessage(
                    text: data['message'],
                    name: data['fromName'],
                    date: data['timestamp'],
                  )
                ],
              );
            }).toList(),
          );
        }
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 18.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                //onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                  hintText: 'Send a message',
                  fillColor: Colors.blueGrey,
                ),
                focusNode: _focusNode,
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    String message = _textController.text.trim();
                    if (message.isEmpty) {
                      print("Empty message");
                      return null;
                    } else {
                      _handleSubmitted(_textController.text);
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) async {
    _textController.clear();

    //Send message to database
    await _sendMessageToDb(text);
  }

  Future<void> _sendMessageToDb(String message) async {
    String userID = widget.userObj['user_id'];
    String recipientID = widget.recipient['user_id'];

    final database = FirebaseFirestore.instance.collection('chat_message');

    await database.doc(userID).collection(recipientID).add({
      'fromUserID': userID,
      'fromName': widget.userObj['first_name'],
      'message': message,
      'timestamp': _dateHandler(),
      'sendAt': DateTime.now(),
      'toUserID': recipientID,
      'toName': widget.recipient['first_name'],
    });

    await database.doc(recipientID).collection(userID).add({
      'fromUserID': userID,
      'fromName': widget.userObj['first_name'],
      'message': message,
      'timestamp': _dateHandler(),
      'sendAt': DateTime.now(),
      'toUserID': recipientID,
      'toName': widget.recipient['first_name'],
    });
  }

  String _dateHandler() {
    DateTime date = new DateTime.now();
    return "${date.month}-${date.day}-${date.year}  ${date.hour}:${date.minute}";
  }
}
