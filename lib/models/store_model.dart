import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String type; // pharmacy, resort, grocery, sari-sari store, karenderya, others
  final String barangay;
  final String? address; // added optional address
  final GeoPoint location; // Firestore geo coordinates
  final String ownerId;
  final bool approved;
  final List<String> reportedBy;
  final double rating;
  final int ratingCount;
  final List<CommentModel> comments;
  final String? description;

  StoreModel({
    required this.id,
    required this.name,
    required this.type,
    required this.barangay,
    this.address,
    required this.location,
    required this.ownerId,
    this.approved = false,
    this.reportedBy = const [],
    this.rating = 0.0,
    this.ratingCount = 0,
    this.comments = const [],
    this.description,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      barangay: map['barangay'] ?? '',
      address: map['address'], // new field
      location: map['location'] as GeoPoint,
      ownerId: map['ownerId'] ?? '',
      approved: map['approved'] ?? false,
      reportedBy: List<String>.from(map['reportedBy'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      comments: map['comments'] != null
          ? List<CommentModel>.from(
              (map['comments'] as List).map((c) => CommentModel.fromMap(c)))
          : [],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'barangay': barangay,
      'address': address, // new field
      'location': location,
      'ownerId': ownerId,
      'approved': approved,
      'reportedBy': reportedBy,
      'rating': rating,
      'ratingCount': ratingCount,
      'comments': comments.map((c) => c.toMap()).toList(),
      'description': description,
    };
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String text;
  final double rating;
  final Timestamp createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'rating': rating,
      'createdAt': createdAt,
    };
  }
}
