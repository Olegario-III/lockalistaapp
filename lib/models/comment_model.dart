import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  /// Core fields
  final String id;
  final String userId;
  final String userName;
  final String text;
  final double rating;
  final Timestamp createdAt;

  /// UI / social fields
  final String? userAvatar; // nullable & validated before display
  final List<String> likes;
  final List<String> dislikes;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    required this.createdAt,
    this.userAvatar,
    this.likes = const [],
    this.dislikes = const [],
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown User',
      text: map['text'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.now(),
      userAvatar: _sanitizeAvatar(map['userAvatar']),
      likes: List<String>.from(map['likes'] ?? const []),
      dislikes: List<String>.from(map['dislikes'] ?? const []),
    );
  }

  /// ===============================
  /// Model → Firestore
  /// ===============================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'text': text,
      'rating': rating,
      'createdAt': createdAt,
      'userAvatar': userAvatar,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  /// ===============================
  /// Helpers
  /// ===============================

  static String? _sanitizeAvatar(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    if (value.isEmpty) return null;
    if (!value.startsWith('http')) return null; // prevents file:/// crash
    return value;
  }

  bool isLikedBy(String userId) => likes.contains(userId);
  bool isDislikedBy(String userId) => dislikes.contains(userId);

  int get likeCount => likes.length;
  int get dislikeCount => dislikes.length;
}
