import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment_model.dart';

class StoreModel {
  final String id;
  final String name;
  final String type;
  final String barangay;
  final String? address;
  final GeoPoint location;
  final String ownerId;
  final bool approved;
  final List<String> reportedBy;

  final String? approvedById;
  final String? approvedByName;
  final Timestamp? approvedAt;

  final double rating;
  final int ratingCount;

  final List<CommentModel> comments;
  final String? description;
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

  double get averageRating => ratingCount == 0 ? 0.0 : rating / ratingCount;
  String get imageUrl => images.isNotEmpty ? images.first : '';

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
