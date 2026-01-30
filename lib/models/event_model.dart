// lib/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// =======================
/// Comment Model
/// =======================
class CommentModel {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> dislikes;

  CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    List<String>? likes,
    List<String>? dislikes,
  })  : likes = likes ?? const [],
        dislikes = dislikes ?? const [];

  /// 🔄 Firestore → Model
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      // supports both old & new field names
      userId: map['userId'] ?? map['uid'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : map['timestamp'] is String
              ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      likes: List<String>.from(map['likes'] ?? const []),
      dislikes: List<String>.from(map['dislikes'] ?? const []),
    );
  }

  /// 🔼 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'dislikes': dislikes,
    };
  }
}

/// =======================
/// Event Model
/// =======================
class EventModel {
  final String id;
  final String title;
  final String description;

  /// 🔑 Event owner
  final String ownerId;

  /// ✅ Alias to prevent undefined getter errors
  String get userId => ownerId;

  /// 👤 Snapshot user info
  final String ownerName;
  final String? ownerAvatar;

  final String? imageUrl;

  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;

  /// pending | approved | rejected
  final String status;

  /// Admin approval info
  final String? approvedBy;
  final String? approvedByName;

  final List<String> likesList;
  final int likesCount;
  final List<CommentModel> comments;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    this.imageUrl,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    List<String>? likesList,
    int? likesCount,
    List<CommentModel>? comments,
  })  : likesList = likesList ?? const [],
        likesCount = likesCount ?? 0,
        comments = comments ?? const [];

  /// 🔄 Firestore → Model
  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',

      // supports legacy + current field names
      ownerId: map['ownerId'] ?? map['userId'] ?? '',
      ownerName: map['ownerName'] ?? 'Unknown',
      ownerAvatar: map['ownerAvatar'] ?? map['ownerAvatarUrl'],
      imageUrl: map['imageUrl'],

      createdAt: parseDate(map['createdAt']),
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),

      status: map['status'] ?? 'pending',
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],

      likesList: List<String>.from(map['likesList'] ?? const []),
      likesCount: map['likesCount'] ?? 0,

      comments: (map['comments'] as List<dynamic>? ?? const [])
          .map((c) => CommentModel.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  /// 🔼 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'likesList': likesList,
      'likesCount': likesCount,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }
}
