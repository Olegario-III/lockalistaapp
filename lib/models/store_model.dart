import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment_model.dart'; // ✅ Use the single source of truth

class StoreModel {
  final String id;
  final String name;
  final String type; // pharmacy, resort, grocery, etc.
  final String barangay;
  final String? address;
  final GeoPoint location;
  final String ownerId;
  final bool approved;
  final List<String> reportedBy;

  /// Approval info
  final String? approvedById;    // Admin UID
  final String? approvedByName;  // Admin Name
  final Timestamp? approvedAt;    // When it was approved

  /// Rating system
  final double rating;       // total rating score
  final int ratingCount;     // number of ratings

  /// Comments
  final List<CommentModel> comments;

  final String? description;

  /// Support multiple images
  final List<String> images;

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
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.comments = const [],
    this.description,
    this.images = const [],
  });

  /// ⭐ Average rating (used by UI)
  double get averageRating =>
      ratingCount == 0 ? 0.0 : rating / ratingCount;

  /// 🖼️ Main image used by UI (prevents imageUrl error)
  String get imageUrl => images.isNotEmpty ? images.first : '';

  /// 🔹 Firestore → Model
  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      barangay: map['barangay'] ?? '',
      address: map['address'],
      location: map['location'] as GeoPoint,
      ownerId: map['ownerId'] ?? '',
      approved: map['approved'] ?? false,
      reportedBy: List<String>.from(map['reportedBy'] ?? []),
      approvedById: map['approvedById'],
      approvedByName: map['approvedByName'],
      approvedAt: map['approvedAt'],
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      comments: (map['comments'] as List<dynamic>? ?? [])
          .map((c) => CommentModel.fromMap(c as Map<String, dynamic>))
          .toList(),
      description: map['description'],
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'barangay': barangay,
      'address': address,
      'location': location,
      'ownerId': ownerId,
      'approved': approved,
      'reportedBy': reportedBy,
      'approvedById': approvedById,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt,
      'rating': rating,
      'ratingCount': ratingCount,
      'images': images,
      'comments': comments.map((c) => c.toMap()).toList(),
      'description': description,
    };
  }
}
