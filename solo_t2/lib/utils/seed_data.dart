import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility class to seed initial data into Firestore for the LibriUni app.
///
/// To run this, uncomment the import and call:
///
///   await FirestoreSeeder.seedLibriUniData();
///
/// in your `main.dart` when `seedData` is set to true.
class FirestoreSeeder {
  /// Seeds books, users, and loans collections with sample data.
  static Future<void> seedLibriUniData() async {
    final db = FirebaseFirestore.instance;

    // ─── Seed Books ─────────────────────────────────────────────────────────
    final books = <Map<String, dynamic>>[
      {
        'id': '024543982944',
        'data': {
          'title': 'Percy Jackson and the Olympians: The Lightning Thief',
          'author': 'Rick Riordan',
          'code': 'DS102',
          'publishedYear': 2023,
          'dateAdded': Timestamp.fromDate(DateTime(2025, 5, 8)),
          'status': 'Borrowed',
          'tag': 'Yellow', // Adding tag field to match BookModel
        },
      },
      {
        'id': '9781853260414',
        'data': {
          'title': 'A Tale of Two Cities',
          'author': 'Charles Dickens',
          'code': 'DS101',
          'publishedYear': 1859,
          'dateAdded': Timestamp.fromDate(DateTime(2025, 5, 8)),
          'status': 'Available',
          'tag': 'Green',
        },
      },
      {
        'id': '9780064471046',
        'data': {
          'title': 'The Lion, the Witch and the Wardrobe',
          'author': 'C.S. Lewis',
          'code': 'DS103',
          'publishedYear': 1950,
          'dateAdded': Timestamp.fromDate(DateTime(2025, 5, 1)),
          'status': 'Available',
          'tag': 'Green',
        },
      },
      {
        'id': '9780131103627',
        'data': {
          'title': 'The C Programming Language',
          'author': 'Brian W. Kernighan and Dennis M. Ritchie',
          'code': 'CS101',
          'publishedYear': 1988,
          'dateAdded': Timestamp.fromDate(DateTime(2025, 4, 15)),
          'status': 'Borrowed',
          'tag': 'Red',
        },
      },
      {
        'id': '9780307474278',
        'data': {
          'title': 'The Girl with the Dragon Tattoo',
          'author': 'Stieg Larsson',
          'code': 'FT201',
          'publishedYear': 2008,
          'dateAdded': Timestamp.fromDate(DateTime(2025, 5, 10)),
          'status': 'Maintenance',
          'tag': 'Yellow',
        },
      }
    ];

    for (final book in books) {
      await db.collection('books').doc(book['id']).set(book['data']);
    }

    // ─── Seed Users ─────────────────────────────────────────────────────────
    final users = <Map<String, dynamic>>[
      {
        'id': 'USR001',
        'data': {
          'name': 'Alice Smith',
          'userIdString': 'USR001',
          'email': 'alice@example.com',
          'isActive': true,
        },
      },
      {
        'id': 'USR002',
        'data': {
          'name': 'Bob Johnson',
          'userIdString': 'USR002',
          'email': 'bob@example.com',
          'isActive': true,
        },
      },
      {
        'id': 'USR003',
        'data': {
          'name': 'Charlie Brown',
          'userIdString': 'USR003',
          'email': 'charlie@example.com',
          'isActive': false,
        },
      },
      {
        'id': 'STF001',
        'data': {
          'name': 'David Miller',
          'userIdString': 'STF001',
          'email': 'david@libriuni.edu',
          'isActive': true,
        },
      }
    ];

    for (final user in users) {
      await db.collection('users').doc(user['id']).set(user['data']);
    }

    // ─── Seed Loans ─────────────────────────────────────────────────────────
    final loans = <Map<String, dynamic>>[
      {
        'id': 'LOAN001',
        'data': {
          'bookId': '024543982944',
          'bookTitle': 'Percy Jackson and the Olympians: The Lightning Thief',
          'userId': 'USR001',
          'userName': 'Alice Smith',
          'loanDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          'dueDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7)),
          ),
          'returnDate': null,
        },
      },
      {
        'id': 'LOAN002',
        'data': {
          'bookId': '9780131103627',
          'bookTitle': 'The C Programming Language',
          'userId': 'USR002',
          'userName': 'Bob Johnson',
          'loanDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 21))),
          'dueDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
          'returnDate': null, // Overdue loan
        },
      },
      {
        'id': 'LOAN003',
        'data': {
          'bookId': '9781853260414',
          'bookTitle': 'A Tale of Two Cities',
          'userId': 'USR003',
          'userName': 'Charlie Brown',
          'loanDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
          'dueDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 16)),
          ),
          'returnDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))), // Returned on time
        },
      }
    ];

    for (final loan in loans) {
      await db.collection('loans').doc(loan['id']).set(loan['data']);
    }

    // ─── Seed Fines ─────────────────────────────────────────────────────────
    final fines = <Map<String, dynamic>>[
      {
        'id': 'FINE001',
        'data': {
          'loanId': 'LOAN002', // Reference to the overdue loan
          'bookId': '9780131103627',
          'userId': 'USR002',
          'daysOverdue': 7,
          'status': 'Unpaid',
          'createdDate': Timestamp.now(),
        },
      }
    ];

    for (final fine in fines) {
      await db.collection('fines').doc(fine['id']).set(fine['data']);
    }

    // ─── Seed News Items ────────────────────────────────────────────────────
    final newsItems = <Map<String, dynamic>>[
      {
        'id': 'NEWS001',
        'data': {
          'title': 'Critical System Update Tonight',
          'description': 'Online services will be briefly unavailable for an urgent security patch.',
          'miniNote': 'Services offline 2 AM - 3 AM.',
          'fullDetails': 'A critical security vulnerability has been identified, requiring an immediate patch. All online library services, including catalog search, account access, and e-resource portals, will be temporarily offline tonight between 2:00 AM and 3:00 AM for this essential maintenance. We apologize for the short notice and any inconvenience caused.',
          'priority': 'high', // 'high', 'medium', 'low'
          'type': 'alert', // 'alert', 'information', 'maintenance'
          'eventDate': null,
          'postedDate': Timestamp.fromDate(DateTime(2025, 5, 30, 10, 0, 0)), // Example: May 30, 2025, 10:00 AM
        },
      },
      {
        'id': 'NEWS002',
        'data': {
          'title': 'Author Meet & Greet: Jane Doe',
          'description': 'Join us for an evening with bestselling author Jane Doe, discussing her new novel.',
          'miniNote': 'Book signing to follow!',
          'fullDetails': "We are thrilled to host an exclusive meet and greet event with renowned author Jane Doe. She will be discussing her latest chart-topping novel, 'The Whispering Pages,' sharing insights into her writing process, and answering audience questions. The event will conclude with a book signing session. Copies of her books will be available for purchase. Don't miss this exciting opportunity!",
          'priority': 'medium',
          'type': 'information',
          'eventDate': Timestamp.fromDate(DateTime(2025, 6, 15, 19, 0, 0)), // Example: June 15, 2025, 7:00 PM
          'postedDate': Timestamp.fromDate(DateTime(2025, 5, 28, 14, 30, 0)), // Example: May 28, 2025, 2:30 PM
        },
      },
      {
        'id': 'NEWS003',
        'data': {
          'title': 'Scheduled Network Maintenance',
          'description': 'Wi-Fi and public computers will have intermittent connectivity next Monday morning.',
          'miniNote': 'Plan accordingly.',
          'fullDetails': "Please be advised that scheduled network maintenance will be performed on Monday, June 2nd, from 8:00 AM to 12:00 PM. During this window, users may experience intermittent connectivity issues with the library's Wi-Fi network and public access computers. We recommend downloading any necessary materials beforehand. We appreciate your patience as we work to improve our network infrastructure.",
          'priority': 'low',
          'type': 'maintenance',
          'eventDate': Timestamp.fromDate(DateTime(2025, 6, 2, 8, 0, 0)), // Example: June 2, 2025, 8:00 AM
          'postedDate': Timestamp.fromDate(DateTime(2025, 5, 29, 9, 0, 0)),  // Example: May 29, 2025, 9:00 AM
        },
      },
      {
        'id': 'NEWS004',
        'data': {
          'title': 'New Digital Magazine Collection Available',
          'description': 'Access hundreds of popular magazines online with your library card.',
          'miniNote': 'Read on any device!',
          'fullDetails': "Great news for magazine lovers! We've expanded our digital offerings to include access to a vast collection of popular magazines through our new online portal. Browse titles covering current events, hobbies, technology, lifestyle, and more. All you need is your library card to start reading on your computer, tablet, or smartphone. Visit our website for access instructions.",
          'priority': 'medium',
          'type': 'information',
          'eventDate': null,
          'postedDate': Timestamp.fromDate(DateTime(2025, 5, 20, 11, 0, 0)), // Example: May 20, 2025, 11:00 AM
        },
      }
    ];

    for (final newsItem in newsItems) {
      await db.collection('news_items').doc(newsItem['id']).set(newsItem['data']);
    }

    print('✅ Firestore seeding complete!');
  }
}
