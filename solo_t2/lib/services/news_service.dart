import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_item_model.dart';

class NewsService {
  final CollectionReference<NewsItemModel> _newsCollection =
      FirebaseFirestore.instance.collection('news_items').withConverter<NewsItemModel>(
            fromFirestore: (snapshots, _) => NewsItemModel.fromFirestore(snapshots),
            toFirestore: (newsItem, _) => newsItem.toFirestore(),
          );

  Stream<List<NewsItemModel>> getNewsItemsStream() {
    // Default sort by postedDate, newest first.
    // You can extend this to accept sort parameters.
    return _newsCollection
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Example: Add a news item (you might need this for an admin panel)
  Future<DocumentReference<NewsItemModel>> addNewsItem(NewsItemModel newsItem) {
    return _newsCollection.add(newsItem);
  }
}