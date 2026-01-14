// lib/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String uid;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> dislikes;

  CommentModel({
    required this.id,
    required this.uid,
    required this.content,
    required this.timestamp,
    List<String>? likes,
    List<String>? dislikes,
  })  : likes = likes ?? [],
        dislikes = dislikes ?? [];

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
      dislikes: List<String>.from(map['dislikes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
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
  final String userId;
  final String? imageUrl;
  final DateTime createdAt;
  final String status;
  final List<String> likesList;
  final int likesCount;
  final List<CommentModel> comments;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    this.imageUrl,
    required this.createdAt,
    required this.status,
    required this.likesList,
    required this.likesCount,
    required this.comments,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
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
      'userId': userId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'likesList': likesList,
      'likesCount': likesCount,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }
}
