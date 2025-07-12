import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatUserList extends StatefulWidget {
  @override
  _ChatUserListState createState() => _ChatUserListState();
}

class _ChatUserListState extends State<ChatUserList> {
  String? currentUserId;
  String? currentUserRole;
  bool isLoading = true;
  List<Map<String, dynamic>> allowedUsers = [];

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();
  }

  Future<void> getCurrentUserInfo() async {
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    currentUserRole = await getUserRole(currentUserId!);
    allowedUsers = await getAllowedChatUsers(currentUserId!);
    for (var user in allowedUsers) {
      final chatId = getChatId(currentUserId!, user['uid']);
      final latestMessageSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (latestMessageSnapshot.docs.isNotEmpty) {
        user['lastTimestamp'] =
        latestMessageSnapshot.docs.first['timestamp'] as Timestamp;
      } else {
        user['lastTimestamp'] =
            Timestamp.fromMillisecondsSinceEpoch(0); // Oldest
      }
    }

    allowedUsers.sort((a, b) =>
        (b['lastTimestamp'] as Timestamp).compareTo(a['lastTimestamp'] as Timestamp));

    setState(() {
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 4,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allowedUsers.isEmpty
          ? const Center(child: Text("No user available to chat"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: allowedUsers.length,
        itemBuilder: (context, index) {
          final user = allowedUsers[index];
          final chatId = getChatId(currentUserId!, user['uid']);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .snapshots(),
            builder: (context, chatSnapshot) {
              int unread = 0;
              if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
                final unreadMap = chatData['unreadCount'] ?? <String, dynamic>{};
                unread = unreadMap[currentUserId] ?? 0;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  String message = '';
                  String formattedTime = '';

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final messageData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    message = messageData['message'];
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    if (timestamp != null) {
                      formattedTime = DateFormat.jm().format(timestamp.toDate());
                    }
                  }

                  return GestureDetector(
                    onTap: () async {
                      await createChatRoomIfNotExists(
                        chatId,
                        currentUserId!,
                        user['uid'],
                        currentUserRole!,
                        user['role'],
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            currentUserId: currentUserId!,
                            peerId: user['uid'],
                            peerName: user['name'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user['name'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name & Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Time & Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (formattedTime.isNotEmpty)
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              const SizedBox(height: 6),
                              if (unread > 0)
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }


  Future<String?> getUserRole(String uid) async {
    final firestore = FirebaseFirestore.instance;
    if ((await firestore.collection('doctors').doc(uid).get()).exists)
      return 'doctor';
    if ((await firestore.collection('employees').doc(uid).get()).exists)
      return 'employee';
    if ((await firestore.collection('students').doc(uid).get()).exists)
      return 'student';
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllowedChatUsers(String uid) async {
    final role = await getUserRole(uid);
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> users = [];

    if (role == 'doctor') {
      final students = await firestore.collection('students').get();
      final employees = await firestore.collection('employees').get();
      users.addAll(
          students.docs.map((e) => {'uid': e.id, 'name': e['name'], 'role': 'student'}));
      users.addAll(
          employees.docs.map((e) => {'uid': e.id, 'name': e['name'], 'role': 'employee'}));
    } else if (role == 'student' || role == 'employee') {
      final doctors = await firestore.collection('doctors').get();
      users.addAll(
          doctors.docs.map((e) => {'uid': e.id, 'name': e['name'], 'role': 'doctor'}));
    }
    return users;
  }

  String getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> createChatRoomIfNotExists(
      String chatId, String uid1, String uid2, String role1, String role2) async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final exists = await chatDoc.get();
    if (!exists.exists) {
      await chatDoc.set({
        'participants': [uid1, uid2],
        'participantRoles': {uid1: role1, uid2: role2},
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
        'unreadCount': {uid1: 0, uid2: 0},
      });
    }
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String peerId;
  final String peerName;

  ChatScreen({
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
  }

  /// Resets the unread count for the current user in the given chat.
  void markMessagesAsRead() async {
    final chatDocRef =
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final doc = await chatDocRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      final unread = (data['unreadCount'] ?? {}) as Map<String, dynamic>;
      if (unread.containsKey(widget.currentUserId)) {
        unread[widget.currentUserId] = 0;
        await chatDocRef.update({'unreadCount': unread});
      }
    }
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Send the message
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUserId,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();

    // Update unread count for the recipient
    final chatDocRef =
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final chatDoc = await chatDocRef.get();
    final peerId = widget.peerId;
    if (chatDoc.exists) {
      final data = chatDoc.data()!;
      final unread = (data['unreadCount'] ?? {}) as Map<String, dynamic>;
      unread[peerId] = (unread[peerId] ?? 0) + 1;
      await chatDocRef.update({'unreadCount': unread});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 4,
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['message'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['timestamp'] != null
                                ? DateFormat.jm().format(
                                (data['timestamp'] as Timestamp).toDate())
                                : '',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
