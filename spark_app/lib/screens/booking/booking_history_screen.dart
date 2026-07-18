import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_timer.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen));
          }
          if (provider.bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No bookings yet', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('Book a charging slot to get started', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          final upcoming = provider.upcomingBookings;
          final past = provider.pastBookings;

          return RefreshIndicator(
            onRefresh: () => provider.loadBookings(),
            color: SparkTheme.primaryGreen,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...upcoming.map((b) => _BookingCard(booking: b, isUpcoming: true)),
                  const SizedBox(height: 24),
                ],
                if (past.isNotEmpty) ...[
                  const Text('Past', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...past.map((b) => _BookingCard(booking: b, isUpcoming: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final dynamic booking;
  final bool isUpcoming;

  const _BookingCard({required this.booking, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.ev_station, color: SparkTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(booking.stationName ?? 'Station', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(DateFormat('EEE, dd MMM yyyy').format(booking.startTime), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text('${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            if (isUpcoming && booking.isUpcoming) ...[
              const SizedBox(height: 12),
              BookingTimer(targetTime: booking.startTime, isCompact: true),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<BookingProvider>().cancelBooking(booking.id);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: SparkTheme.errorRed, side: const BorderSide(color: SparkTheme.errorRed)),
                  child: const Text('Cancel Booking'),
                ),
              ),
            ],
            if (booking.totalAmount != null) ...[
              const SizedBox(height: 8),
              Text(booking.formattedAmount, style: const TextStyle(fontWeight: FontWeight.w700, color: SparkTheme.primaryGreen, fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'confirmed': color = SparkTheme.primaryGreen; break;
      case 'active': color = SparkTheme.infoBlue; break;
      case 'completed': color = SparkTheme.grey600; break;
      case 'cancelled': color = SparkTheme.errorRed; break;
      case 'no_show': color = SparkTheme.warningYellow; break;
      default: color = SparkTheme.grey400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
