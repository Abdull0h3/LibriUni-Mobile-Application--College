import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting, add intl package to pubspec.yaml
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../models/news_item_model.dart';
import '../constants/app_colors.dart';

class NewsItemDetailScreen extends StatelessWidget {
  final NewsItemModel newsItem;

  const NewsItemDetailScreen({super.key, required this.newsItem});

  String _formatTimestamp(Timestamp? timestamp, {String format = 'MMMM dd, yyyy HH:mm'}) {
    if (timestamp == null) return 'N/A';
    return DateFormat(format).format(timestamp.toDate());
  }

  Color _getTypeColor(NewsItemType type) {
    switch (type) {
      case NewsItemType.alert:
        return Colors.red.shade700;
      case NewsItemType.information:
        return Colors.orange.shade700;
      case NewsItemType.maintenance:
        return Colors.blue.shade700;
      default:
        return AppColors.textColorDark;
    }
  }

  IconData _getTypeIcon(NewsItemType type) {
     switch (type) {
      case NewsItemType.alert:
        return Icons.warning_amber_rounded;
      case NewsItemType.information:
        return Icons.info_outline;
      case NewsItemType.maintenance:
        return Icons.build_circle_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(newsItem.type);
    final typeIcon = _getTypeIcon(newsItem.type);

    return Scaffold(
      appBar: AppBar(
        title: Text(newsItem.title, style: const TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textColorLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 32),
                const SizedBox(width: 10),
                Text(
                  newsItem.type.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              newsItem.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textColorDark,
              ),
            ),
            if (newsItem.miniNote != null && newsItem.miniNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                newsItem.miniNote!,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textColorDark.withOpacity(0.75),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              newsItem.fullDetails,
              style: TextStyle(fontSize: 16, color: AppColors.textColorDark.withOpacity(0.9), height: 1.5),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Priority:', newsItem.priority.toString().split('.').last.toUpperCase(), valueColor: _getPriorityColor(newsItem.priority)), // Changed 'color' to 'valueColor'
            if (newsItem.eventDate != null)
              _buildInfoRow('Event Date:', _formatTimestamp(newsItem.eventDate, format: 'MMMM dd, yyyy')),
            _buildInfoRow('Posted:', _formatTimestamp(newsItem.postedDate)),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(NewsPriority priority) {
    switch (priority) {
      case NewsPriority.high:
        return Colors.red.shade600;
      case NewsPriority.medium:
        return Colors.orange.shade600;
      case NewsPriority.low:
        return Colors.blue.shade600;
      default:
        return AppColors.textColorDark;
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textColorDark),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: valueColor ?? AppColors.textColorDark.withOpacity(0.85)),
            ),
          ),
        ],
      ),
    );
  }
}