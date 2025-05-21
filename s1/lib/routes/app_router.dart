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
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/catalog_screen.dart';
import '../screens/staff/scan_qr_screen.dart';
import '../screens/staff/user_view_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_books_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_rooms_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/add_book_screen.dart';
import '../screens/admin/add_user_screen.dart';
import '../screens/admin/add_room_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../providers/book_provider.dart';
import '../providers/user_provider.dart';
import '../providers/room_provider.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // ignore: unused_field
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
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

      // Student routes /* */
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

      // Staff routes
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/staff/scan',
        builder: (context, state) => const ScanQRScreen(),
      ),
      GoRoute(
        path: '/staff/users',
        builder: (context, state) => const UserViewScreen(),
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
        path: '/admin/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),

      // Admin add/edit routes
      GoRoute(
        path: '/admin/books/add',
        builder: (context, state) => const AddBookScreen(),
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
