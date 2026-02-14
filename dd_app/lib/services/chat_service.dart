import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

/// Servicio para gestionar chats y mensajes
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la colección de chats
  CollectionReference get _chatsCollection =>
      _firestore.collection('chats');

  /// Referencia a la colección de mensajes
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  /// Obtener o crear un chat entre dos usuarios
  Future<ChatModel?> getOrCreateChat(String userId1, String userId2) async {
    try {
      // Buscar chat existente entre los dos usuarios
      final existingChat = await _chatsCollection
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in existingChat.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participants.contains(userId2)) {
          return chat;
        }
      }

      // Crear nuevo chat
      final newChat = ChatModel(
        id: '',
        participants: [userId1, userId2],
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final docRef = await _chatsCollection.add(newChat.toFirestore());
      return ChatModel(
        id: docRef.id,
        participants: newChat.participants,
        lastMessageTime: newChat.lastMessageTime,
        createdAt: newChat.createdAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtener todos los chats de un usuario
  Stream<List<ChatModel>> getUserChats(String userId) {
    // Evitar índice compuesto - ordenar en cliente
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
          // Ordenar en cliente para evitar necesidad de índice
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  /// Obtener mensajes de un chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    // Evitar índice compuesto - ordenar en cliente
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
          // Ordenar en cliente
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  /// Enviar un mensaje
  Future<MessageModel?> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required String receiverId,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
      );

      final docRef = await _messagesCollection.add(message.toFirestore());

      // Actualizar el chat con el último mensaje
      await _chatsCollection.doc(chatId).update({
        'lastMessage': content,
        'lastSenderId': senderId,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      return MessageModel(
        id: docRef.id,
        chatId: message.chatId,
        senderId: message.senderId,
        content: message.content,
        timestamp: message.timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Marcar mensajes como leídos
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      // Resetear contador de no leídos
      await _chatsCollection.doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      // Marcar mensajes como leídos (opcional, más granular)
      final unreadMessages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        final message = MessageModel.fromFirestore(doc);
        if (message.senderId != userId) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      // Silenciar errores
    }
  }

  /// Obtener un chat específico
  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _chatsCollection.doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream de un chat específico
  Stream<ChatModel?> getChatStream(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.exists ? ChatModel.fromFirestore(doc) : null);
  }

  /// Obtener el total de mensajes no leídos para un usuario
  Stream<int> getTotalUnreadCount(String userId) {
    return getUserChats(userId).map((chats) {
      int total = 0;
      for (final chat in chats) {
        total += chat.getUnreadCountFor(userId);
      }
      return total;
    });
  }

  /// Eliminar un chat (opcional)
  Future<bool> deleteChat(String chatId) async {
    try {
      // Eliminar todos los mensajes del chat
      final messages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_chatsCollection.doc(chatId));
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }
}
