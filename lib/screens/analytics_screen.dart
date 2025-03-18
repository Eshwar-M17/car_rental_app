import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carrentalapp/core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _recentBookings = [];
  Map<String, double> _monthlyRevenue = {};
  Map<String, int> _monthlyRentalDays = {};
  Map<String, double> _carTypeRevenue = {};
  double totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch comprehensive analytics data
  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch basic counts
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final carsSnapshot =
          await FirebaseFirestore.instance.collection('rentalCars').get();
      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      // Calculate revenue and booking statistics
      int activeBookings = 0;
      int completedBookings = 0;
      int upcomingBookings = 0;
      int totalRentalDays = 0;
      final now = DateTime.now();

      // Process bookings for detailed analytics
      final List<Map<String, dynamic>> bookings = [];
      final Map<String, double> monthlyRevenue = {};
      final Map<String, int> monthlyRentalDays = {};
      final Map<String, double> carTypeRevenue = {};

      // Reset total revenue
      totalRevenue = 0;
      _carTypeRevenue.clear();

      // Process bookings from the main bookings collection
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        bookings.add(data);
        _processBookingData(data, now, bookings, monthlyRevenue,
            monthlyRentalDays, carTypeRevenue);
      }

      // Calculate booking status counts
      for (var booking in bookings) {
        if (booking.containsKey('rentStartDate') &&
            booking.containsKey('endDate')) {
          try {
            final DateTime startDate = DateTime.parse(booking['rentStartDate']);
            final DateTime endDate = DateTime.parse(booking['endDate']);

            if (now.isBefore(startDate)) {
              upcomingBookings++;
            } else if (now.isAfter(endDate)) {
              completedBookings++;
            } else {
              activeBookings++;
            }
          } catch (e) {
            print('Error parsing dates: $e');
          }
        }
      }

      // Sort bookings by date (most recent first)
      bookings.sort((a, b) {
        try {
          final DateTime dateA = DateTime.parse(a['bookingDate'] ?? '');
          final DateTime dateB = DateTime.parse(b['bookingDate'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      // Get only the 5 most recent bookings
      final recentBookings = bookings.take(5).toList();

      // Calculate average booking value
      final double avgBookingValue =
          bookings.isEmpty ? 0 : totalRevenue / bookings.length;

      // Calculate average daily rate
      final int totalDays = bookings.fold(
          0,
          (sum, booking) =>
              sum +
              (booking['rentalDays'] is int
                  ? booking['rentalDays'] as int
                  : 1));
      final double avgDailyRate = totalDays > 0 ? totalRevenue / totalDays : 0;

      // Store all analytics data
      _analyticsData = {
        'users': usersSnapshot.size,
        'cars': carsSnapshot.size,
        'bookings': bookings.length,
        'totalRevenue': totalRevenue,
        'avgBookingValue': avgBookingValue,
        'activeBookings': activeBookings,
        'completedBookings': completedBookings,
        'upcomingBookings': upcomingBookings,
        'totalRentalDays': totalDays,
        'avgDailyRate': avgDailyRate,
        'carTypeRevenue': carTypeRevenue,
      };

      _recentBookings = recentBookings;
      _monthlyRevenue = monthlyRevenue;
      _monthlyRentalDays = monthlyRentalDays;
      _carTypeRevenue = carTypeRevenue;

      print('Analytics data loaded:');
      print('Total bookings: ${bookings.length}');
      print('Active bookings: $activeBookings');
      print('Upcoming bookings: $upcomingBookings');
      print('Completed bookings: $completedBookings');
      print('Total revenue: $totalRevenue');
    } catch (e) {
      print('Error fetching analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper method to process booking data for revenue and dates
  void _processBookingData(
      Map<String, dynamic> data,
      DateTime now,
      List<Map<String, dynamic>> bookings,
      Map<String, double> monthlyRevenue,
      Map<String, int> monthlyRentalDays,
      Map<String, double> carTypeRevenue) {
    // Calculate revenue
    if (data.containsKey('totalCost')) {
      final double cost = (data['totalCost'] is int)
          ? (data['totalCost'] as int).toDouble()
          : data['totalCost'] as double;

      // Update total revenue
      totalRevenue += cost;

      // Track car type revenue
      if (data.containsKey('carDetails') && data['carDetails'] is Map) {
        final carDetails = data['carDetails'] as Map<String, dynamic>;
        final carName = carDetails['name'] ?? 'Unknown';
        carTypeRevenue[carName] = (carTypeRevenue[carName] ?? 0) + cost;
      }

      // Track rental days
      final int rentalDays =
          data['rentalDays'] is int ? data['rentalDays'] as int : 1;

      // Track monthly revenue
      if (data.containsKey('rentStartDate')) {
        try {
          final DateTime startDate = DateTime.parse(data['rentStartDate']);
          final String monthYear = DateFormat('MMM yyyy').format(startDate);

          monthlyRevenue[monthYear] = (monthlyRevenue[monthYear] ?? 0) + cost;

          // Track monthly rental days
          final int days =
              data['rentalDays'] is int ? data['rentalDays'] as int : 1;
          monthlyRentalDays[monthYear] =
              (monthlyRentalDays[monthYear] ?? 0) + days;
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBookingsTab(),
                _buildRevenueTab(),
              ],
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Bookings'),
            Tab(text: 'Revenue'),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Users',
                  count: _analyticsData['users'] ?? 0,
                  icon: Icons.person,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnalyticsCard(
                  title: 'Cars',
                  count: _analyticsData['cars'] ?? 0,
                  icon: Icons.directions_car,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Bookings',
                  count: _analyticsData['bookings'] ?? 0,
                  icon: Icons.book_online,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnalyticsCard(
                  title: 'Revenue',
                  value: currencyFormat
                      .format(_analyticsData['totalRevenue'] ?? 0),
                  icon: Icons.attach_money,
                  valueColor: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Booking Status',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1E232C),
            ),
          ),
          const SizedBox(height: 16),

          // Booking Status Cards
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Active',
                  _analyticsData['activeBookings'] ?? 0,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  'Upcoming',
                  _analyticsData['upcomingBookings'] ?? 0,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  'Completed',
                  _analyticsData['completedBookings'] ?? 0,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Key Metrics',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1E232C),
            ),
          ),
          const SizedBox(height: 16),

          // Key Metrics
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetricRow(
                    'Average Booking Value',
                    currencyFormat
                        .format(_analyticsData['avgBookingValue'] ?? 0),
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Average Daily Rate',
                    currencyFormat.format(_analyticsData['avgDailyRate'] ?? 0),
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Total Rental Days',
                    '${_analyticsData['totalRentalDays'] ?? 0} days',
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Cars per User',
                    (_analyticsData['users'] != 0)
                        ? (_analyticsData['cars'] / _analyticsData['users'])
                            .toStringAsFixed(2)
                        : '0',
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Bookings per User',
                    (_analyticsData['users'] != 0)
                        ? (_analyticsData['bookings'] / _analyticsData['users'])
                            .toStringAsFixed(2)
                        : '0',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return _recentBookings.isEmpty
        ? const Center(child: Text('No booking data available'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1E232C),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_recentBookings.length, (index) {
                  final booking = _recentBookings[index];
                  return _buildBookingCard(booking);
                }),

                const SizedBox(height: 24),
                const Text(
                  'Booking Distribution',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1E232C),
                  ),
                ),
                const SizedBox(height: 16),

                // Booking Status Pie Chart
                SizedBox(
                  height: 250,
                  child: _buildBookingStatusChart(),
                ),
              ],
            ),
          );
  }

  Widget _buildRevenueTab() {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return _monthlyRevenue.isEmpty
        ? const Center(child: Text('No revenue data available'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1E232C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat
                              .format(_analyticsData['totalRevenue'] ?? 0),
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Monthly Revenue',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1E232C),
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Revenue Chart
                SizedBox(
                  height: 250,
                  child: _buildMonthlyRevenueChart(),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Revenue Breakdown',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1E232C),
                  ),
                ),
                const SizedBox(height: 16),

                // Revenue Breakdown List
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _monthlyRevenue.entries
                          .toList()
                          .map((entry) =>
                              _buildRevenueItem(entry.key, entry.value))
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Revenue by Car Type',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1E232C),
                  ),
                ),
                const SizedBox(height: 16),

                // Car Type Revenue Chart
                Container(
                  height: 400,
                  child: _buildCarTypeRevenueChart(),
                ),
              ],
            ),
          );
  }

  Widget _buildRevenueItem(String month, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1E232C),
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                .format(amount),
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF0B8FAC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E232C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1E232C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E232C),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0B8FAC),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final carDetails = booking['carDetails'] as Map<String, dynamic>? ?? {};
    final carName = carDetails['name'] ?? 'Unknown Car';
    final bookingDate = booking['bookingDate'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(booking['bookingDate']))
        : 'Unknown Date';
    final totalCost = booking['totalCost'] ?? 0.0;
    final rentalDays = booking['rentalDays'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Color(0xFF0B8FAC),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E232C),
                    ),
                  ),
                  Text(
                    'Booked on $bookingDate',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$rentalDays ${rentalDays == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                  .format(totalCost),
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF0B8FAC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatusChart() {
    final int activeBookings = _analyticsData['activeBookings'] ?? 0;
    final int upcomingBookings = _analyticsData['upcomingBookings'] ?? 0;
    final int completedBookings = _analyticsData['completedBookings'] ?? 0;
    final int totalBookings =
        activeBookings + upcomingBookings + completedBookings;

    if (totalBookings == 0) {
      return const Center(child: Text('No booking data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 400;
        final chartRadius = isCompact ? 65.0 : 75.0;
        final centerSpaceRadius = isCompact ? 20.0 : 25.0;

        return Container(
          height: 320,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: centerSpaceRadius,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.success,
                            value: activeBookings.toDouble(),
                            title:
                                '${((activeBookings / totalBookings) * 100).toStringAsFixed(1)}%',
                            radius: chartRadius,
                            titleStyle: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.accent,
                            value: upcomingBookings.toDouble(),
                            title:
                                '${((upcomingBookings / totalBookings) * 100).toStringAsFixed(1)}%',
                            radius: chartRadius,
                            titleStyle: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.info,
                            value: completedBookings.toDouble(),
                            title:
                                '${((completedBookings / totalBookings) * 100).toStringAsFixed(1)}%',
                            radius: chartRadius,
                            titleStyle: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 100,
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(
                        'Active', activeBookings, AppColors.success),
                    _buildLegendItem(
                        'Upcoming', upcomingBookings, AppColors.accent),
                    _buildLegendItem(
                        'Completed', completedBookings, AppColors.info),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRevenueChart() {
    if (_monthlyRevenue.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    // Sort entries by date
    final sortedEntries = _monthlyRevenue.entries.toList()
      ..sort((a, b) {
        try {
          final DateFormat format = DateFormat('MMM yyyy');
          final DateTime dateA = format.parse(a.key);
          final DateTime dateB = format.parse(b.key);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

    // Prepare data for the chart
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sortedEntries[i].value,
              color: const Color(0xFF0B8FAC),
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
                1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${sortedEntries[group.x].key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(rod.toY),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= sortedEntries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    sortedEntries[value.toInt()]
                        .key
                        .split(' ')[0], // Just show month
                    style: const TextStyle(
                      color: Color(0xFF1E232C),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0)
                      .format(value),
                  style: const TextStyle(
                    color: Color(0xFF1E232C),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: sortedEntries
                  .map((e) => e.value)
                  .reduce((a, b) => a > b ? a : b) /
              5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFFE8E8E8),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildCarTypeRevenueChart() {
    if (_carTypeRevenue.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    // Sort entries by revenue (highest first)
    final sortedEntries = _carTypeRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 car types for better visualization
    final topCarTypes = sortedEntries.take(5).toList();

    // Prepare data for the chart
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      AppColors.primary, // Blue for Mercedes
      AppColors.success, // Green for Tesla
      AppColors.accent, // Orange for BMW
      AppColors.primaryLight, // Light blue for Toyota
      AppColors.info, // Info blue for others
    ];

    for (int i = 0; i < topCarTypes.length; i++) {
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: topCarTypes[i].value,
          title:
              '${((topCarTypes[i].value / totalRevenue) * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      height: 400,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          SizedBox(
            height: 200,
            child: Center(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                  pieTouchData: PieTouchData(enabled: true),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(topCarTypes.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              topCarTypes[index].key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                                    symbol: '\$', decimalDigits: 0)
                                .format(topCarTypes[index].value),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final String title;
  final int? count;
  final String? value;
  final IconData icon;
  final Color? valueColor;

  const AnalyticsCard({
    Key? key,
    required this.title,
    this.count,
    this.value,
    required this.icon,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE8F5F3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF0B8FAC),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E232C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value ?? count.toString(),
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: valueColor ?? const Color(0xFF1E232C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
