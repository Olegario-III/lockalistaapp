import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId; // ✅ renamed from uid
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
      timestamp: (map['timestamp'] as Timestamp).toDate(),
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

class EventModel {
  final String id;
  final String title;
  final String description;
  final String ownerId; // Poster UID
  final String? ownerAvatarUrl;
  final String? imageUrl;
  final DateTime? timestamp;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? approvedBy; // Admin UID
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
    required this.likesList,
    required this.likesCount,
    required this.comments,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
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
