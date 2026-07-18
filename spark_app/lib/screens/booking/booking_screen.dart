import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/station.dart';
import '../../providers/booking_provider.dart';
import 'booking_confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final Station station;
  final List<Map<String, dynamic>> availability;

  const BookingScreen({super.key, required this.station, required this.availability});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedPort = 1;
  String? _selectedStartTime;
  String? _selectedEndTime;

  List<String> get _availableStartTimes {
    return widget.availability
        .where((a) =>
            a['status'] == 'available' &&
            a['port'] == _selectedPort &&
            a['date'] == DateFormat('yyyy-MM-dd').format(_selectedDate))
        .map<String>((a) => a['start_time'].toString().substring(0, 5))
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Charging Slot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: SparkTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.ev_station, color: SparkTheme.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.station.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          Text(widget.station.formattedPrice, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date selection
            const Text('Select Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = date;
                      _selectedStartTime = null;
                      _selectedEndTime = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? SparkTheme.primaryGreen : SparkTheme.grey100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('EEE').format(date), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : SparkTheme.grey800)),
                          Text(DateFormat('MMM').format(date), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey[500])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Port selection
            Text('Select Port (${widget.station.ports} available)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: List.generate(widget.station.ports, (i) {
                final port = i + 1;
                return ChoiceChip(
                  label: Text('Port $port'),
                  selected: _selectedPort == port,
                  selectedColor: SparkTheme.primaryGreen.withOpacity(0.2),
                  onSelected: (s) => setState(() {
                    _selectedPort = port;
                    _selectedStartTime = null;
                    _selectedEndTime = null;
                  }),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Time selection
            const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_availableStartTimes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No available slots', style: TextStyle(color: Colors.grey[500]))),
                ),
              )
            else
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _availableStartTimes.map((time) {
                  final isSelected = _selectedStartTime == time;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedStartTime = time;
                      final hour = int.parse(time.split(':')[0]) + 1;
                      _selectedEndTime = '${hour.toString().padLeft(2, '0')}:00';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? SparkTheme.primaryGreen : SparkTheme.grey100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? SparkTheme.primaryGreen : SparkTheme.grey200),
                      ),
                      child: Text(time, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : SparkTheme.grey800)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            // Booking summary
            if (_selectedStartTime != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SparkTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SparkTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Date', value: DateFormat('EEE, dd MMM yyyy').format(_selectedDate)),
                    _SummaryRow(label: 'Time', value: '$_selectedStartTime - $_selectedEndTime'),
                    _SummaryRow(label: 'Port', value: 'Port $_selectedPort'),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Est. Cost',
                      value: 'CHF ${(widget.station.powerKw * widget.station.pricePerKwh).toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedStartTime != null
          ? Container(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Consumer<BookingProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _handleBooking,
                      child: provider.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Confirm Booking'),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  void _handleBooking() async {
    final startHour = int.parse(_selectedStartTime!.split(':')[0]);
    final startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, startHour, 0);
    final endHour = int.parse(_selectedEndTime!.split(':')[0]);
    final endTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, endHour, 0);

    final booking = await context.read<BookingProvider>().createBooking(
      stationId: widget.station.id,
      port: _selectedPort,
      startTime: startTime,
      endTime: endTime,
    );

    if (booking != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(booking: booking, station: widget.station),
      ));
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isBold ? 18 : 14,
            color: isBold ? SparkTheme.primaryGreen : null,
          )),
        ],
      ),
    );
  }
}
