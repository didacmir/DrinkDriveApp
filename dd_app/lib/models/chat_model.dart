import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de conversación (chat)
class ChatModel {
  final String id;
  final List<String> participants; // IDs de los usuarios en el chat
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final Map<String, int> unreadCount; // Conteo de mensajes no leídos por usuario

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastSenderId,
    required this.lastMessageTime,
    required this.createdAt,
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final unreadMap = <String, int>{};
    if (data['unreadCount'] != null) {
      (data['unreadCount'] as Map<String, dynamic>).forEach((key, value) {
        unreadMap[key] = value as int;
      });
    }
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastSenderId: data['lastSenderId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: unreadMap,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'unreadCount': unreadCount,
    };
  }

  /// Obtener el ID del otro participante en el chat
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Obtener los mensajes no leídos para un usuario
  int getUnreadCountFor(String userId) {
    return unreadCount[userId] ?? 0;
  }
}

/// Modelo de mensaje individual
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}
