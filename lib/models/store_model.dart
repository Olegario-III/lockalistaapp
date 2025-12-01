// lib/models/store_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model used by both Store and Event documents (stored as array of maps).
class CommentModel {
  final String? id; // optional client-side id
  final String uid;
  final String content;
  final DateTime timestamp;
  final List<String> likes; // list of user UIDs who liked
  final List<String> dislikes; // list of user UIDs who disliked

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

class StoreModel {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final List<String> images; // multiple images
  final String userId; // owner uid
  final DateTime createdAt;
  final String status; // "pending" | "approved" | "rejected"

  // Ratings stored as map of uid -> numeric rating (1..5)
  // Stored in Firestore as a map field. Use rateStore in service to update safely.
  final Map<String, num> ratings;
  final int ratingsCount;
  final num ratingSum;

  // Comments are stored as an array of comment maps
  final List<CommentModel> comments;

  StoreModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    List<String>? images,
    required this.userId,
    DateTime? createdAt,
    this.status = 'pending',
    Map<String, num>? ratings,
    int? ratingsCount,
    num? ratingSum,
    List<CommentModel>? comments,
  })  : images = images ?? [],
        createdAt = createdAt ?? DateTime.now(),
        ratings = ratings ?? {},
        ratingsCount = ratingsCount ?? 0,
        ratingSum = ratingSum ?? 0,
        comments = comments ?? [];

  /// computed average rating (0 when none)
  double get averageRating {
    if (ratingsCount == 0) return 0.0;
    return (ratingSum / ratingsCount).toDouble();
  }

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    final ratingsMap = <String, num>{};
    if (map['ratings'] != null && map['ratings'] is Map<String, dynamic>) {
      (map['ratings'] as Map<String, dynamic>).forEach((k, v) {
        if (v is num) ratingsMap[k] = v;
      });
    }

    final commentsList = <CommentModel>[];
    if (map['comments'] != null && map['comments'] is List) {
      for (final item in (map['comments'] as List<dynamic>)) {
        if (item is Map<String, dynamic>) {
          commentsList.add(CommentModel.fromMap(item));
        }
      }
    }

    return StoreModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      address: map['address'] as String?,
      images: map['images'] != null
          ? List<String>.from(map['images'] as List<dynamic>)
          : <String>[],
      userId: map['userId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      ratings: ratingsMap,
      ratingsCount: (map['ratingsCount'] is int) ? map['ratingsCount'] as int : 0,
      ratingSum: (map['ratingSum'] is num) ? map['ratingSum'] as num : 0,
      comments: commentsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'images': images,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'ratings': ratings,
      'ratingsCount': ratingsCount,
      'ratingSum': ratingSum,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }

  /// copyWith helper
  StoreModel copyWith({
    String? name,
    String? description,
    String? address,
    List<String>? images,
    String? userId,
    DateTime? createdAt,
    String? status,
    Map<String, num>? ratings,
    int? ratingsCount,
    num? ratingSum,
    List<CommentModel>? comments,
  }) {
    return StoreModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      images: images ?? this.images,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      ratings: ratings ?? this.ratings,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      ratingSum: ratingSum ?? this.ratingSum,
      comments: comments ?? this.comments,
    );
  }
}
