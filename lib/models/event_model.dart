// lib/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model used inside events too (same shape as stores).
class CommentModel {
  final String? id;
  final String uid;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> dislikes;

  CommentModel({
    this.id,
    required this.uid,
    required this.content,
    DateTime? timestamp,
    List<String>? likes,
    List<String>? dislikes,
  })  : timestamp = timestamp ?? DateTime.now(),
        likes = likes ?? [],
        dislikes = dislikes ?? [];

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String?,
      uid: map['uid'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      likes: map['likes'] != null
          ? List<String>.from(map['likes'] as List<dynamic>)
          : <String>[],
      dislikes: map['dislikes'] != null
          ? List<String>.from(map['dislikes'] as List<dynamic>)
          : <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;
  final String status; // "pending" | "approved" | "rejected"

  // likes as list of UIDs + count for quick access
  final List<String> likesList;
  final int likesCount;

  // comments stored as array
  final List<CommentModel> comments;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.userId,
    DateTime? createdAt,
    this.status = 'pending',
    List<String>? likesList,
    int? likesCount,
    List<CommentModel>? comments,
  })  : createdAt = createdAt ?? DateTime.now(),
        likesList = likesList ?? [],
        likesCount = likesCount ?? 0,
        comments = comments ?? [];

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    final likes = map['likesList'] != null
        ? List<String>.from(map['likesList'] as List<dynamic>)
        : <String>[];

    final commentsList = <CommentModel>[];
    if (map['comments'] != null && map['comments'] is List) {
      for (final item in (map['comments'] as List<dynamic>)) {
        if (item is Map<String, dynamic>) {
          commentsList.add(CommentModel.fromMap(item));
        }
      }
    }

    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      userId: map['userId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      likesList: likes,
      likesCount: (map['likesCount'] is int) ? map['likesCount'] as int : likes.length,
      comments: commentsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'likesList': likesList,
      'likesCount': likesCount,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }

  EventModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? userId,
    DateTime? createdAt,
    String? status,
    List<String>? likesList,
    int? likesCount,
    List<CommentModel>? comments,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      likesList: likesList ?? this.likesList,
      likesCount: likesCount ?? this.likesCount,
      comments: comments ?? this.comments,
    );
  }
}
