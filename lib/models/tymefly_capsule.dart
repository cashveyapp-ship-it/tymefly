import 'package:cloud_firestore/cloud_firestore.dart';

class TymeFlyCapsule {
  final String id;
  final String userId;
  final String type;
  final String message;
  final List<Map<String, dynamic>> recipients;
  final DateTime releaseDate;
  final String status;
  final DateTime createdAt;

  TymeFlyCapsule({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.recipients,
    required this.releaseDate,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'message': message,
      'recipients': recipients,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
