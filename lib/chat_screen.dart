import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:codelab_friendlychat_flutter/app_services/login.dart';
import 'package:codelab_friendlychat_flutter/cloud_services/firebase_services.dart';

class ChatMessage extends StatelessWidget {
  ChatMessage({
    required this.text,
    required this.animationController,
    required this.name,
    required this.date,
  });

  final String text;
  final AnimationController animationController;
  final String name;
  final String date;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text(name[0])),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Text(
                      name,
                      style: TextStyle(
                          fontSize: 14.0, fontStyle: FontStyle.italic),
                    ),
                    SizedBox(width: 40),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 14.0, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    /*final Stream<QuerySnapshot> _messageStream = FirebaseFirestore.instance
        .collection('chat_message')
        .doc(widget.userObj['user_id'])
        .collection(widget.recipient['user_id'])
        .snapshots();*/

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
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (_, int index) => _messages[index],
                  itemCount: _messages.length,
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

  //Retrieve all chat message
  Future<void> _loadMessages() async {
    String userID = widget.userObj['user_id'];
    String recipientID = widget.recipient['user_id'];

    await FirebaseFirestore.instance
        .collection('chat_message')
        .doc(userID)
        .collection(
            recipientID) //This is where conversations between user are stored
        .orderBy(
          'timestamp',
        )
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        final messageObj = doc.data() as Map<String, dynamic>;

        var message = ChatMessage(
          text: messageObj['message'],
          animationController: AnimationController(
            // NEW
            duration: const Duration(milliseconds: 0), // NEW
            vsync: this,
          ),
          name: messageObj['fromName'],
          date: messageObj['timestamp'],
        );

        setState(() {
          _messages.insert(0, message);
        });

        _focusNode.requestFocus();
        message.animationController.forward();
      });
    });
  }

  void _handleSubmitted(String text) async {
    _textController.clear();

    var message = ChatMessage(
      text: text,
      animationController: AnimationController(
        // NEW
        duration: const Duration(milliseconds: 300), // NEW
        vsync: this,
      ),
      name: widget.userObj['first_name'],
      date: _dateHandler(""),
    );

    setState(() {
      _messages.insert(0, message);
    });

    _focusNode.requestFocus();
    message.animationController.forward();

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
      'timestamp': _dateHandler(""),
      'toUserID': recipientID,
      'toName': widget.recipient['first_name'],
    });

    await database.doc(recipientID).collection(userID).add({
      'fromUserID': userID,
      'fromName': widget.userObj['first_name'],
      'message': message,
      'timestamp': _dateHandler(""),
      'toUserID': recipientID,
      'toName': widget.recipient['first_name'],
    });
  }

  String _dateHandler(String info) {
    DateTime date = new DateTime.now();
    if (info == "date") {
      return "${date.month}-${date.day}-${date.year}";
    } else if (info == "time") {
      return "${date.hour}:${date.minute}";
    }
    return "${date.month}-${date.day}-${date.year}  ${date.hour}:${date.minute}";
  }

  String _generateChatID(String id1, String id2) {
    return '$id1-$id2';
  }

  @override
  void dispose() {
    for (var message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }
}
