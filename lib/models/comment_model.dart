import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String text;
  final double rating;
  final List<String> likes;
  final List<String> dislikes;
  final Timestamp createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.text,
    required this.rating,
    required this.likes,
    required this.dislikes,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      id: doc.id,
      userId: data['userId'],
      username: data['username'],
      userAvatar: data['userAvatar'],
      text: data['text'],
      rating: (data['rating'] ?? 0).toDouble(),
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'text': text,
      'rating': rating,
      'likes': likes,
      'dislikes': dislikes,
      'createdAt': createdAt,
    };
  }
}
