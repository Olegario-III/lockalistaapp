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
  })  : likes = likes ?? [],
        dislikes = dislikes ?? [];

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      likes: List<String>.from(map['likes'] ?? []),
      dislikes: List<String>.from(map['dislikes'] ?? []),
    );
  }

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

  /// 🔑 Original owner field
  final String ownerId;

  /// ✅ Alias for admin pages & consistency
  String get userId => ownerId;

  final String? ownerAvatarUrl;
  final String? imageUrl;
  final DateTime? timestamp;
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
    this.ownerAvatarUrl,
    this.imageUrl,
    this.timestamp,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    List<String>? likesList,
    int? likesCount,
    List<CommentModel>? comments,
  })  : likesList = likesList ?? [],
        likesCount = likesCount ?? 0,
        comments = comments ?? [];

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? map['userId'] ?? '',
      ownerAvatarUrl: map['ownerAvatarUrl'],
      imageUrl: map['imageUrl'],
      timestamp: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],
      likesList: List<String>.from(map['likesList'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      comments: (map['comments'] as List<dynamic>? ?? [])
          .map((c) => CommentModel.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'ownerAvatarUrl': ownerAvatarUrl,
      'imageUrl': imageUrl,
      'createdAt': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
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
