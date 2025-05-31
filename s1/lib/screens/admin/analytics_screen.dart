import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart'; // Assuming fl_chart is used for the chart
import '../../constants/app_colors.dart';
import '../../services/analytics_service.dart';
import '../../providers/book_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  // Removed time period variables as filter is removed
  // final List<String> _timePeriods = [
  //   'Today',
  //   'This Week',
  //   'This Month',
  //   'All Time',
  // ];
  // String _selectedPeriod = 'This Month';

  // Data containers
  // Removed unused data variables for removed sections
  // Map<String, List<int>> _borrowingTrends = {};
  // Map<String, Map<String, int>> _popularCategories = {};
  // Map<String, Map<String, int>> _roomUsage = {};
  // Map<String, dynamic> _generalStats = {};
  int _totalBooks = 0;
  int _availableBooks = 0;
  // Removed unused data variable for reserved slots count
  // int _reservedSlotsCount = 0;
  Map<String, dynamic> _finesStats = {};

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
      // Removed calls to fetch data for sections that are being removed
      // final trends = await _analyticsService.getBorrowingTrends();
      // final categories = await _analyticsService.getPopularCategories();
      // final roomUsage = await _analyticsService.getRoomUsage();
      // final stats = await _analyticsService.getGeneralStatistics();

      final finesStats =
          await _analyticsService.getFinesStats(); // Fetch all-time fines stats

      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider
          .fetchBooks(); // This still fetches all books for availability

      // Removed print statements for sections that are removed
      // print('Fetched trends: $trends');
      // print('Fetched categories: $categories');
      // print('Fetched room usage: $roomUsage');
      // print('Fetched stats: $stats');
      print('Fetched books count: ${bookProvider.books.length}');
      // print('Fetched reserved slots count: $reservedSlots');
      print('Fetched fines stats: $finesStats');

      setState(() {
        // Removed setting state for sections that are being removed
        // _borrowingTrends = trends;
        // _popularCategories = categories;
        // _roomUsage = roomUsage;
        // _generalStats = stats;
        _totalBooks = bookProvider.books.length;
        _availableBooks =
            bookProvider.books
                .where((book) => book.status == 'Available')
                .length;
        // _reservedSlotsCount = reservedSlots; // Removed setting state as section is removed
        _finesStats = finesStats;
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

  // Removed unused method for changing time period
  // void _changePeriod(String period) {
  //   setState(() {
  //     _selectedPeriod = period;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Removed unused time-period data variables
    // final currentBorrowingTrends = _borrowingTrends[_selectedPeriod] ?? [];
    // final currentPopularCategories = _popularCategories[_selectedPeriod] ?? {};
    // final currentRoomUsage = _roomUsage[_selectedPeriod] ?? {};

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
                    // Removed Time Period Selection UI
                    // Removed General Statistics Section
                    // Removed Borrowing Trends Section
                    // Removed Popular Categories Section
                    // Removed Room Usage Section

                    // Fines Statistics Section
                    _buildFinesStatsSection(),
                    const SizedBox(height: 16),

                    // Book availability analysis
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Book Availability Analysis',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Book availability chart
                            _totalBooks ==
                                    0 // Handle case with no books
                                ? const Center(
                                  child: Text(
                                    'No book data available for chart.',
                                  ),
                                )
                                : SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          color: AppColors.success,
                                          value: _availableBooks.toDouble(),
                                          title: 'Available',
                                          radius: 80,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          color: AppColors.error,
                                          value:
                                              (_totalBooks - _availableBooks)
                                                  .toDouble(),
                                          title: 'Borrowed',
                                          radius: 80,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem(
                                  'Available',
                                  AppColors.success,
                                ),
                                const SizedBox(width: 24),
                                _buildLegendItem('Borrowed', AppColors.error),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  int _getMaxCategoryValue(Map<String, int> categoryData) {
    int max = 0;
    if (categoryData.isNotEmpty) {
      // Add check for empty map
      max = categoryData.values.reduce((a, b) => a > b ? a : b);
    }
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
    if (data.isEmpty) {
      // Add check for empty data list
      return const Center(child: Text('No data for bar chart.'));
    }
    final int maxValue = data.reduce(
      (a, b) => a > b ? a : b,
    ); // reduce is safe now
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
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

  Widget _buildRoomUsageChart(Map<String, int> roomData) {
    if (roomData.isEmpty) {
      return const Center(child: Text('No data for room usage chart.'));
    }

    // Get the day with the most bookings
    String busiestDay = '';
    int maxBookings = 0;
    roomData.forEach((day, count) {
      if (count > maxBookings) {
        maxBookings = count;
        busiestDay = day;
      }
    });

    return Column(
      children: [
        Text(
          'Busiest Day: $busiestDay ($maxBookings bookings)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxBookings.toDouble(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final days = roomData.keys.toList();
                      if (value >= 0 && value < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              barGroups:
                  roomData.entries.map((entry) {
                    final index = roomData.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color:
                              entry.key == busiestDay
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.5),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinesStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fines Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Paid Fines',
                  '${(_finesStats['paid'] ?? 0).toString()} (\$${(_finesStats['paidAmount'] ?? 0.0).toStringAsFixed(2)})',
                  Icons.attach_money,
                  AppColors.success,
                ),
                _buildStatCard(
                  'Unpaid Fines',
                  '${(_finesStats['unpaid'] ?? 0).toString()} (\$${(_finesStats['unpaidAmount'] ?? 0.0).toStringAsFixed(2)})',
                  Icons.money_off,
                  AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
