import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

Future<String?> getUserRole(String uid) async {
  final firestore = FirebaseFirestore.instance;
  if ((await firestore.collection('doctors').doc(uid).get()).exists) return 'doctor';
  if ((await firestore.collection('employees').doc(uid).get()).exists) return 'employee';
  if ((await firestore.collection('students').doc(uid).get()).exists) return 'student';
  return null;
}
Future<List<Map<String, dynamic>>> getAllowedChatUsers(String uid) async {
  final role = await getUserRole(uid);
  final firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return [];

  List<Map<String, dynamic>> users = [];

  if (role == 'doctor') {
    final chatSnapshots = await firestore.collection('chats').where('participants', arrayContains: uid).get();

    Set<String> usersWhoSentMessages = Set();

    for (var chatDoc in chatSnapshots.docs) {
      final messages = await chatDoc.reference.collection('messages').get();
      for (var message in messages.docs) {
        final senderId = message.data()['senderId'];
        if (senderId != uid) {
          usersWhoSentMessages.add(senderId);
        }
      }
    }

    for (var userId in usersWhoSentMessages) {
      final userDoc = await firestore.collection('students').doc(userId).get();
      if (userDoc.exists) {
        final lastMessage = await getLastMessageFromChat(uid, userDoc.id);
        users.add({
          'uid': userDoc.id,
          'name': userDoc['name'],
          'role': 'student',
          'lastMessage': lastMessage['message'],
          'timestamp': lastMessage['timestamp'],
        });
        continue;
      }

      final employeeDoc = await firestore.collection('employees').doc(userId).get();
      if (employeeDoc.exists) {
        final lastMessage = await getLastMessageFromChat(uid, employeeDoc.id);
        users.add({
          'uid': employeeDoc.id,
          'name': employeeDoc['name'],
          'role': 'employee',
          'lastMessage': lastMessage['message'],
          'timestamp': lastMessage['timestamp'],
        });
      }
    }

  } else if (role == 'student' || role == 'employee') {
    final chatSnapshots = await firestore.collection('chats').where('participants', arrayContains: uid).get();

    Set<String> doctorsInChat = Set();

    for (var chatDoc in chatSnapshots.docs) {
      final participants = List<String>.from(chatDoc.data()['participants']);
      for (var participant in participants) {
        if (participant != uid) {
          doctorsInChat.add(participant);
        }
      }
    }

    for (var docId in doctorsInChat) {
      final doctorDoc = await firestore.collection('doctors').doc(docId).get();
      if (doctorDoc.exists) {
        final lastMessage = await getLastMessageFromChat(uid, doctorDoc.id);
        users.add({
          'uid': doctorDoc.id,
          'name': doctorDoc['name'],
          'role': 'doctor',
          'lastMessage': lastMessage['message'],
          'timestamp': lastMessage['timestamp'],
        });
      }
    }
  }

  // ✅ Sort by latest timestamp
  users.sort((a, b) {
    final timeA = a['timestamp'] ?? Timestamp(0, 0);
    final timeB = b['timestamp'] ?? Timestamp(0, 0);
    return timeB.compareTo(timeA);
  });


  return users;
}



// Helper function to get the last message from a chat


Future<Map<String, dynamic>> getLastMessageFromChat(String uid1, String uid2) async {
  final firestore = FirebaseFirestore.instance;
  final chatId = getChatId(uid1, uid2);
  final messages = await firestore.collection('chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).limit(1).get();

  if (messages.docs.isEmpty) {
    return {'message': 'No messages yet', 'timestamp': null};
  }

  final message = messages.docs.first.data();
  String? formattedTime;

  if (message['timestamp'] != null) {
    final timestamp = (message['timestamp'] as Timestamp).toDate();
    formattedTime = DateFormat('h:mm a').format(timestamp); // Format time as 5:43 PM
  }

  return {
    'message': message['message'],
    'timestamp': formattedTime ?? 'No timestamp',
  };
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
    });
  }
}

