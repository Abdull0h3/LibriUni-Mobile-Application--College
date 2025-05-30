// lib/models/book_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id; // Firestore document ID
  final String title;
  final String author;
  final String code; // LibriUni specific code like DS101
  String status; // Available, Borrowed, Lost, Maintenance
  final int? publishedYear;
  final Timestamp? dateAdded; // When the book was added to the system
  final String tag; // Added: "Red", "Yellow", "Green" for fine calculation
  final String? coverUrl;
  final String? category;
  final String? description; //todo: additional variable to be added to staff

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.code,
    required this.status,
    this.publishedYear,
    this.dateAdded,
    this.tag = "Green", // Default tag if not specified
    this.coverUrl,
    this.category,
    this.description,
  });

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? code,
    String? status,
    int? publishedYear,
    Timestamp? dateAdded,
    String? tag,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      code: code ?? this.code,
      status: status ?? this.status,
      publishedYear: publishedYear ?? this.publishedYear,
      dateAdded: dateAdded ?? this.dateAdded,
      tag: tag ?? this.tag,
    );
  }

  factory BookModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return BookModel(
      id: snapshot.id,
      title: data?['title'] ?? 'Unknown Title',
      author: data?['author'] ?? 'Unknown Author',
      code: data?['code'] ?? '',
      status: data?['status'] ?? 'Unknown',
      publishedYear: data?['publishedYear'] as int?,
      dateAdded: data?['dateAdded'] as Timestamp?,
      tag:
          data?['tag'] ??
          'Green', // Default to 'Green' if 'tag' is not in Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'code': code,
      'status': status,
      if (publishedYear != null) 'publishedYear': publishedYear,
      if (dateAdded != null) 'dateAdded': dateAdded,
      'tag': tag,
    };
  }
}
