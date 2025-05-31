import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/edit_profile_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/student/student_dashboard_screen.dart';
import '../screens/student/book_search_screen.dart';
import '../screens/student/book_detail_screen.dart';
import '../screens/student/room_booking_screen.dart';
import '../screens/student/borrowed_books_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/my_reserved_rooms_screen.dart';
import '../screens/student/student_chat_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_rooms_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/add_user_screen.dart';
import '../screens/admin/add_room_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/manage_news_screen.dart';
import '/models/book_model.dart';
import '/screens/staff/staff_dashboard_screen.dart';
import '/screens/staff/search_catalog_screen.dart';
import '/screens/staff/manage_books_screen.dart';
import '/screens/staff/add_edit_book_screen.dart';
import '/screens/staff/view_users_screen.dart';
import '/screens/staff/news_item_detail_screen.dart';
import '/models/news_item_model.dart';
import '/screens/staff/news_and_events_screen.dart';
import '/screens/staff/scan_qr_screen.dart';
import '/screens/staff/borrowed_items_screen.dart';
import '/screens/staff/manage_fines_screen.dart';
import '/screens/staff/loan_form_screen.dart';
import '../screens/staff/staff_chat_screen.dart';
import '../screens/staff/staff_student_chat_detail_screen.dart';
import '../screens/staff/staff_profile_screen.dart';//NEW
import '../screens/staff/staff_book_detail_screen.dart';//NEW
import '../screens/staff/manage_rooms_screen.dart' as staff_manage_rooms; // Alias for staff screen
import '../models/room.dart'; // Ensure Room model is imported


class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;

      // If the user is not logged in and not on auth routes, redirect to login
      if (!isLoggedIn &&
          !state.matchedLocation.startsWith('/login') &&
          !state.matchedLocation.startsWith('/register')) {
        return '/login';
      }

      // If user is logged in and on auth routes, redirect to appropriate dashboard
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/')) {
        if (authProvider.isAdmin) {
          return '/admin';
        } else if (authProvider.isStaff) {
          return '/staff';
        } else {
          return '/student';
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Root route
      GoRoute(path: '/', redirect: (context, state) => '/login'),

      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Staff routes
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/search-catalog',
        builder: (context, state) => const SearchCatalogScreen(),
      ),
      GoRoute(
        path: '/staff/view-users',
        builder: (context, state) => const ViewUsersScreen(),
      ),
      GoRoute(
        path: '/staff/borrowed-items',
        builder: (context, state) => const BorrowedItemsScreen(),
      ),
      GoRoute(
        path: '/staff/manage-books',
        builder: (context, state) => const ManageBooksScreen(),
      ),
      GoRoute(
        path: '/staff/manage-fines',
        builder: (context, state) => const ManageFinesScreen(),
      ),
      GoRoute(
        path: '/staff/scan-qr',
        builder: (context, state) => const ScanQrScreen(),
      ),
      GoRoute(
        path: '/staff/news-events',
        builder: (context, state) => const NewsAndEventsScreen(),
      ),
      GoRoute(
        path: '/staff/news/:id',
        builder: (context, state) {
          final newsItem = state.extra as NewsItemModel;
          return NewsItemDetailScreen(newsItem: newsItem);
        },
      ),
      GoRoute(
        path: '/staff/books/add',
        builder: (context, state) => const AddEditBookScreen(),
      ),
      GoRoute(
        path: '/staff/books/edit/:id',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return AddEditBookScreen(bookToEdit: book);
        },
      ),
      GoRoute(
        path: '/staff/loan-form',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return LoanFormScreen(book: book);
        },
      ),
      GoRoute(
        path: '/staff/chat',
        builder: (context, state) {
          // Extract the map from the extra object
          final args = state.extra as Map<String, dynamic>;
          final staffId = args['staffId'] as String;
          final staffName = args['staffName'] as String;
          return StaffChatScreen(staffId: staffId, staffName: staffName);
        },
      ),
      GoRoute(
        path: '/staff/chat/student-detail',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final studentId = args['studentId'] as String;
          final staffId = args['staffId'] as String;
          final studentName = args['studentName'] as String;
          return StaffStudentChatDetailScreen(
            studentId: studentId,
            staffId: staffId,
            studentName: studentName,
          );
        },
      ),
      GoRoute( // Add this route for the staff profile
        path: '/staff/profile',
        builder: (context, state) => const StaffProfileScreen(),
      ),
      GoRoute( // Add this route for staff book detail
        path: '/staff/catalog/book-detail',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return StaffBookDetailScreen(book: book);
        },
      ),
      // Staff Manage Rooms - This screen will internally use admin routes for add/edit actions
      GoRoute(
        path: '/staff/reserved-rooms',
        builder: (context, state) => const staff_manage_rooms.ManageRoomsScreen(),
      ),

      // Student routes with shell navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return child;
        },
        routes: [
          GoRoute(
            path: '/student',
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/books',
            builder: (context, state) => const BookSearchScreen(),
          ),
          GoRoute(
            path: '/student/books/:id',
            builder: (context, state) {
              final bookId = state.pathParameters['id']!;
              return BookDetailScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: '/student/rooms',
            builder: (context, state) => const RoomBookingScreen(),
          ),
          GoRoute(
            path: '/student/borrowed',
            builder: (context, state) => const BorrowedBooksScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/student/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/student/reserved-rooms',
            builder: (context, state) => const MyReservedRoomsScreen(),
          ),
          GoRoute(
            path: '/student/chat',
            builder: (context, state) {
              // Extract the map from the extra object
              final args = state.extra as Map<String, dynamic>;
              final studentId = args['studentId'] as String;
              final studentName = args['studentName'] as String;
              return StudentChatScreen(
                studentId: studentId,
                studentName: studentName,
              );
            },
          ),
        ],
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/books',
        builder: (context, state) => const ManageBooksScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/rooms',
        builder: (context, state) => const ManageRoomsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/news',
        builder: (context, state) => const ManageNewsScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),

      // Admin add/edit routes
      GoRoute(
        path: '/admin/books/add',
        builder: (context, state) {
          final bookToEdit =
              state.extra is BookModel ? state.extra as BookModel : null;
          return AddEditBookScreen(bookToEdit: bookToEdit);
        },
      ),
      GoRoute(
        path: '/admin/users/add',
        builder: (context, state) => const AddUserScreen(),
      ),
      GoRoute(
        path: '/admin/rooms/add',
        builder: (context, state) => const AddRoomScreen(),
      ),
    ],
  );
}
