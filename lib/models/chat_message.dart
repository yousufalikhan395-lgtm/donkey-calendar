import '../db/app_database.dart';

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? imagePath;

  // Runtime-only calendar results (not persisted to chat history).
  final List<CalendarEvent>? savedEvents;
  final List<Map<String, dynamic>>? pendingBatch;
  final String? parseError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.imagePath,
    this.savedEvents,
    this.pendingBatch,
    this.parseError,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWithContent(String content) => ChatMessage(
        id: id, role: role, content: content, timestamp: timestamp,
        imagePath: imagePath, savedEvents: savedEvents, pendingBatch: pendingBatch,
        parseError: parseError,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'role': role, 'content': content,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'], role: j['role'], content: j['content'],
        timestamp: DateTime.parse(j['timestamp']),
        imagePath: j['imagePath'],
      );
}
