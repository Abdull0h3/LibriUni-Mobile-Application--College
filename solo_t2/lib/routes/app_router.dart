// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import '/models/book_model.dart';
import '/screens/staff_dashboard_screen.dart';
import '/screens/search_catalog_screen.dart';
import '/screens/manage_books_screen.dart';
import '/screens/add_edit_book_screen.dart';
import '/screens/view_users_screen.dart';
import '/screens/news_item_detail_screen.dart'; 
import '/models/news_item_model.dart'; 
import '/screens/news_and_events_screen.dart';
import '/screens/scan_qr_screen.dart';
import '/screens/borrowed_items_screen.dart';
// import '/screens/reserved_rooms_screen.dart';
// import '/screens/checked_in_returns_screen.dart';
import '/screens/manage_fines_screen.dart';
import '/screens/loan_form_screen.dart'; 
// Define route names as constants
class AppRoutes {
  static const String dashboard = '/';
  static const String searchCatalog = '/search-catalog';
  static const String manageBooks = '/manage-books';
  static const String addEditBook = '/add-edit-book';
  static const String viewUsers = '/view-users';
  static const String newsAndEvents = '/news-and-events';
  static const String newsItemDetail = '/news-item-detail'; //
  static const String scanQr = '/scan-qr';
  static const String borrowedItems = '/borrowed-items';
  static const String reservedRooms = '/reserved-rooms';
  static const String checkedInReturns = '/checked-in-returns';
  static const String manageFines = '/manage-fines';
  static const String loanForm = '/loan-form'; // <-- Add this route name

}

// Define the route generator
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const StaffDashboardScreen());
      case AppRoutes.searchCatalog:
        return MaterialPageRoute(builder: (_) => const SearchCatalogScreen());
      case AppRoutes.manageBooks:
        return MaterialPageRoute(builder: (_) => const ManageBooksScreen());
      case AppRoutes.addEditBook:
        final bookToEdit = args is BookModel ? args : null; // Changed from ManagedBook
        return MaterialPageRoute(builder: (_) => AddEditBookScreen(bookToEdit: bookToEdit));
      case AppRoutes.viewUsers:
        return MaterialPageRoute(builder: (_) => const ViewUsersScreen());
      case AppRoutes.newsAndEvents:
        return MaterialPageRoute(builder: (_) => const NewsAndEventsScreen());
      case AppRoutes.newsItemDetail: // <-- Add this case
        if (args is NewsItemModel) {
          return MaterialPageRoute(builder: (_) => NewsItemDetailScreen(newsItem: args));
        }
        return _errorRoute('News item data missing for detail page.');
      case AppRoutes.scanQr:
        return MaterialPageRoute(builder: (_) => const ScanQrScreen());
      case AppRoutes.manageFines: 
        return MaterialPageRoute(builder: (_) => const ManageFinesScreen());
      case AppRoutes.borrowedItems:
        return MaterialPageRoute(builder: (_) => const BorrowedItemsScreen());
      // case AppRoutes.reservedRooms:
      //   return MaterialPageRoute(builder: (_) => const ReservedRoomsScreen());
      // case AppRoutes.checkedInReturns:
      //   return MaterialPageRoute(builder: (_) => const CheckedInReturnsScreen());
      // case AppRoutes.manageFines:
      //   return MaterialPageRoute(builder: (_) => const ManageFinesScreen());
      case AppRoutes.loanForm:
        if (args is BookModel) {
          return MaterialPageRoute(builder: (_) => LoanFormScreen(book: args));
        }
        return _errorRoute(settings.name);
      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('No route defined for $routeName'),
        ),
      ),
    );
  }
}