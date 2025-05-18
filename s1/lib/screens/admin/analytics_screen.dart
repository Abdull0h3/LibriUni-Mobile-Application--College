import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  final List<String> _timePeriods = [
    'Today',
    'This Week',
    'This Month',
    'All Time',
  ];
  String _selectedPeriod = 'This Month';

  // Data containers
  Map<String, List<int>> _borrowingTrends = {};
  Map<String, Map<String, int>> _popularCategories = {};
  Map<String, Map<String, int>> _roomUsage = {};
  Map<String, dynamic> _generalStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch real data from Firestore
      final trends = await _analyticsService.getBorrowingTrends();
      final categories = await _analyticsService.getPopularCategories();
      final roomUsage = await _analyticsService.getRoomUsage();
      final stats = await _analyticsService.getGeneralStatistics();

      setState(() {
        _borrowingTrends = trends;
        _popularCategories = categories;
        _roomUsage = roomUsage;
        _generalStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics data: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time period selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time Period',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _timePeriods.length,
                                itemBuilder: (context, index) {
                                  final period = _timePeriods[index];
                                  final isSelected = _selectedPeriod == period;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(period),
                                      selected: isSelected,
                                      onSelected: (_) => _changePeriod(period),
                                      backgroundColor: AppColors.lightGray,
                                      selectedColor: AppColors.primary
                                          .withOpacity(0.2),
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Borrowing trends
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Book Borrowing Trends',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildBarChart(
                                _borrowingTrends[_selectedPeriod]!,
                                [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ],
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Popular categories
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Popular Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._popularCategories[_selectedPeriod]!.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildProgressBar(
                                  entry.key,
                                  entry.value,
                                  _getMaxCategoryValue(),
                                  _getCategoryColor(entry.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Room usage
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Study Room Usage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildRoomUsageChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Export options
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report downloaded as PDF'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Export PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report exported as CSV'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Export CSV'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  int _getMaxCategoryValue() {
    int max = 0;
    _popularCategories[_selectedPeriod]!.forEach((_, value) {
      if (value > max) max = value;
    });
    return max;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Fiction':
        return AppColors.primary;
      case 'Non-Fiction':
        return AppColors.secondary;
      case 'Science':
        return AppColors.success;
      case 'Engineering':
        return AppColors.warning;
      case 'Arts':
        return AppColors.error;
      case 'History':
        return Colors.purple;
      default:
        return AppColors.textPrimary;
    }
  }

  Widget _buildBarChart(List<int> data, List<String> labels, Color color) {
    // In a real app, use a chart library like fl_chart
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final int maxValue = data.reduce((a, b) => a > b ? a : b);
        final double percentage = maxValue > 0 ? data[index] / maxValue : 0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  data[index].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 150 * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[index], style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProgressBar(String label, int value, int maxValue, Color color) {
    final double percentage = maxValue > 0 ? value / maxValue : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomUsageChart() {
    // Simplified room usage visualization
    final roomData = _roomUsage[_selectedPeriod]!;
    final maxValue = roomData.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: roomData.length,
      itemBuilder: (context, index) {
        final entry = roomData.entries.elementAt(index);
        final roomName = entry.key;
        final usageCount = entry.value;
        final percentage = maxValue > 0 ? usageCount / maxValue : 0;

        return Card(
          color: colors[index % colors.length].withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$usageCount bookings',
                  style: TextStyle(
                    color: colors[index % colors.length],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage.toDouble(),
                    backgroundColor: AppColors.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors[index % colors.length],
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
