import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final String shelf;
  final bool isAvailable;
  final DateTime publishedDate;
  final String? coverUrl;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.shelf,
    required this.isAvailable,
    required this.publishedDate,
    this.coverUrl,
    this.description,
  });

  /// Create a Book from a Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      shelf: data['shelf'] ?? '',
      isAvailable: data['isAvailable'] ?? false,
      publishedDate:
          (data['publishedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coverUrl: data['coverUrl'],
      description: data['description'],
    );
  }

  /// Convert Book to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'shelf': shelf,
      'isAvailable': isAvailable,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'coverUrl': coverUrl,
      'description': description,
    };
  }

  /// Create a copy of the book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? shelf,
    bool? isAvailable,
    DateTime? publishedDate,
    String? coverUrl,
    String? description,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      shelf: shelf ?? this.shelf,
      isAvailable: isAvailable ?? this.isAvailable,
      publishedDate: publishedDate ?? this.publishedDate,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
    );
  }
}
