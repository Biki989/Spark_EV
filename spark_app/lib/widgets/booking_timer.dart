import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class BookingTimer extends StatefulWidget {
  final DateTime targetTime;
  final VoidCallback? onExpired;
  final bool isCompact;

  const BookingTimer({
    super.key,
    required this.targetTime,
    this.onExpired,
    this.isCompact = false,
  });

  @override
  State<BookingTimer> createState() => _BookingTimerState();
}

class _BookingTimerState extends State<BookingTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      setState(() {
        _remaining = widget.targetTime.difference(now);
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer?.cancel();
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SparkTheme.darkBg,
            SparkTheme.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SparkTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _remaining == Duration.zero ? 'Charging Time!' : 'Charging starts in',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeBlock(value: hours, label: 'HRS'),
              const _TimeSeparator(),
              _TimeBlock(value: minutes, label: 'MIN'),
              const _TimeSeparator(),
              _TimeBlock(value: seconds, label: 'SEC'),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _remaining.inSeconds > 0 ? 1.0 - (_remaining.inSeconds / (24 * 3600)) : 1.0,
              backgroundColor: Colors.white10,
              color: SparkTheme.primaryGreen,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$seconds',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: SparkTheme.primaryGreen,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String value;
  final String label;

  const _TimeBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SparkTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: SparkTheme.primaryGreen,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: SparkTheme.primaryGreen,
        ),
      ),
    );
  }
}
