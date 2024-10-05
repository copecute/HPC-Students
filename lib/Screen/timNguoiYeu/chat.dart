import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatScreen extends StatefulWidget {
  final String username;

  ChatScreen({required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isMatched = false;
  bool isChatActive = false;
  bool isTyping = false;
  bool isSearching = false;
  String? chatRoomId;
  String? lastReceivedMessage;
  DateTime? lastReceivedMessageTime;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTyping);
    _showWelcomeMessage();
  }

  @override
  void dispose() {
    _removeFromWaitingList(widget.username);
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showWelcomeMessage() {
    setState(() {
      _messages.add({
        'sender': 'System',
        'message': 'Chào mừng bạn đến với bình nguyên vô tận!',
        'status': 'received',
        'isSystemMessage': true,
      });
    });
  }

  void _onTyping() {
    if (_messageController.text.isNotEmpty) {
      _database.child('chatRooms/$chatRoomId/typing').set({
        'username': widget.username,
        'isTyping': true,
      });
    } else {
      _database.child('chatRooms/$chatRoomId/typing').set({
        'username': widget.username,
        'isTyping': false,
      });
    }
  }

  void _joinChat() async {
    setState(() {
      isSearching = true;
      _messages.add({
        'sender': 'System',
        'message': 'Đang tìm đối tượng ghép đôi...',
        'status': 'received',
        'isSystemMessage': true,
      });
    });

    await _database.child('waitingUsers').push().set({
      'username': widget.username,
    });

    _database.child('waitingUsers').onValue.listen((event) {
      final users = event.snapshot.value as Map<dynamic, dynamic>?;

      if (users != null) {
        List<String> waitingUsernames = [];

        users.forEach((key, value) {
          waitingUsernames.add(value['username']);
        });

        if (!isMatched && waitingUsernames.length >= 2) {
          for (String waitingUsername in waitingUsernames) {
            if (waitingUsername != widget.username) {
              _startChat(waitingUsername);
              break;
            }
          }
        }
      }
    });
  }

  void _startChat(String matchedUsername) {
    chatRoomId = _createChatRoomId(widget.username, matchedUsername);

    _database.child('chatRooms/$chatRoomId').once().then((DatabaseEvent event) {
      if (event.snapshot.value == null) {
        _database.child('chatRooms/$chatRoomId').set({
          'users': [widget.username, matchedUsername],
        });
      }

      _messages.clear();

      setState(() {
        isMatched = true;
        isChatActive = true;
        isSearching = false;
        _messages.add({
          'sender': 'System',
          'message':
              'Bạn đã được ghép đôi với người lạ! Nhập "ahihi" để bắt đầu.',
          'status': 'received'
        });
      });

      _database
          .child('chatRooms/$chatRoomId/messages')
          .onChildAdded
          .listen((event) {
        final messageData = event.snapshot.value as Map<dynamic, dynamic>;
        final sender = messageData['sender'];
        final message = messageData['message'];
        final status = messageData['status'];

        if (message == lastReceivedMessage &&
            lastReceivedMessageTime != null &&
            DateTime.now().difference(lastReceivedMessageTime!).inSeconds < 5) {
          return;
        }

        lastReceivedMessage = message;
        lastReceivedMessageTime = DateTime.now();

        if (sender != widget.username) {
          _playNotificationSound();
        }

        if (sender != widget.username) {
          setState(() {
            _messages
                .add({'sender': sender, 'message': message, 'status': status});
          });

          // Gửi xác nhận đã nhận tin nhắn
          _database
              .child('chatRooms/$chatRoomId/messages/${event.snapshot.key}')
              .update({'status': 'received'});
        } else {
          setState(() {
            _messages.lastWhere((msg) => msg['message'] == message)['status'] =
                status;
          });
        }

        _scrollToBottom();
      });

      _database.child('chatRooms/$chatRoomId/typing').onValue.listen((event) {
        final typingData = event.snapshot.value as Map<dynamic, dynamic>?;

        if (typingData != null && typingData['username'] != widget.username) {
          setState(() {
            isTyping = typingData['isTyping'];
          });
        }
      });

      _database.child('chatRooms/$chatRoomId/close').onValue.listen((event) {
        final closeData = event.snapshot.value as Map<dynamic, dynamic>?;
        if (closeData != null && closeData['isClose'] == true) {
          _endChat(closeData['username']);
        }
      });

      _removeFromWaitingList(widget.username);
      _removeFromWaitingList(matchedUsername);
    });
  }

  void _playNotificationSound() {
    _audioPlayer.play(AssetSource('audio/notification.mp3'));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _createChatRoomId(String username1, String username2) {
    List<String> sortedUsernames = [username1, username2]..sort();
    return sortedUsernames.join('_');
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (isMatched && isChatActive && message.isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': widget.username,
          'message': message,
          'status': 'sending'
        });
      });
      _messageController.clear();

      _database.child('chatRooms/$chatRoomId/messages').push().set({
        'sender': widget.username,
        'message': message,
        'status': 'sent'
      }).then((_) {
        setState(() {
          _messages.last['status'] = 'sent';
        });
      });

      // Listen for status changes
      _database
          .child('chatRooms/$chatRoomId/messages')
          .limitToLast(1)
          .onChildChanged
          .listen((event) {
        final messageData = event.snapshot.value as Map<dynamic, dynamic>;
        final status = messageData['status'];
        if (status == 'received') {
          setState(() {
            _messages.last['status'] = 'received';
          });
        }
      });
    }
  }

  void _leaveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận thoát chat'),
        content:
            Text('Bạn có chắc chắn muốn thoát khỏi cuộc trò chuyện không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              _removeFromWaitingList(widget.username);

              _database.child('chatRooms/$chatRoomId/close').set({
                'isClose': true,
                'username': widget.username,
              });

              setState(() {
                isChatActive = false;
              });
            },
            child: Text('Có'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Không'),
          ),
        ],
      ),
    );
  }

  void _endChat(String closedByUsername) {
    _database.child('chatRooms/$chatRoomId').remove();
    chatRoomId = null;
    setState(() {
      isChatActive = false;
      isMatched = false;
      _messages.add({
        'sender': 'Hệ thống',
        'message': closedByUsername == widget.username
            ? 'Bạn đã kết thúc trò chuyện.'
            : 'Người lạ đã rời đi.',
        'status': 'received',
        'isSystemMessage': true,
        'isEndMessage': true,
        'endedByUser': closedByUsername == widget.username,
      });
    });
  }

  void _clearChatData() {
    setState(() {
      _messages.clear();
      isMatched = false;
      isChatActive = false;
    });
  }

  void _removeFromWaitingList(String username) {
    _database
        .child('waitingUsers')
        .orderByChild('username')
        .equalTo(username)
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> children =
            event.snapshot.value as Map<dynamic, dynamic>;
        children.forEach((key, value) {
          _database.child('waitingUsers/$key').remove();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm người yêu'),
        actions: [
          if (isChatActive)
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.red),
              onPressed: _leaveChat,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      child: Text(
                        'Đang nhập...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                final isMyMessage = message['sender'] == widget.username;
                final isSystemMessage = message['isSystemMessage'] == true;
                final isEndMessage = message['isEndMessage'] == true;
                final endedByUser = message['endedByUser'] == true;

                return Column(
                  crossAxisAlignment:
                      isMyMessage || (isSystemMessage && endedByUser)
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: isMyMessage || (isSystemMessage && endedByUser)
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSystemMessage
                              ? Colors.grey[200]
                              : isMyMessage
                                  ? Colors.blue[300]
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                              color: isSystemMessage
                                  ? Colors.black54
                                  : isMyMessage
                                      ? Colors.white
                                      : Colors.black),
                        ),
                      ),
                    ),
                    if (isMyMessage &&
                        index == _messages.length - 1 &&
                        !isSystemMessage)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          message['status'] == 'sending'
                              ? 'Đang gửi'
                              : message['status'] == 'sent'
                                  ? 'Đã gửi'
                                  : 'Đã nhận',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (isMatched && isChatActive)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(hintText: 'Nhập tin nhắn...'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          if (!isChatActive && !isSearching)
            ElevatedButton(
              onPressed: _joinChat,
              child: Text('Tìm người mới'),
            ),
        ],
      ),
    );
  }
}
