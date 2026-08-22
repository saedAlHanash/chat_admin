import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Standard chat timestamp widget.
/// - Same day (Today): Shows time only (e.g. "02:30 PM").
/// - Yesterday: Shows "Yesterday" + time (e.g. "Yesterday\n02:30 PM").
/// - Same year: Shows Month and Day + time (e.g. "Apr 15\n02:30 PM").
/// - Different year: Shows full date + time (e.g. "2024/04/15\n02:30 PM").
class ChatTimestampWidget extends StatelessWidget {
  const ChatTimestampWidget({
    super.key,
    required this.timestamp,
    this.color = Colors.grey,
    this.fontSize,
    this.textAlign = TextAlign.center,
  });

  final int? timestamp;
  final Color color;
  final double? fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    if (timestamp == null || timestamp == 0) {
      return const SizedBox.shrink();
    }

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp!);
    final now = DateTime.now();

    String dateText;
    if (date.isToday) {
      dateText = date.formatTime;
    } else if (date.isYesterday) {
      dateText = 'Yesterday}';
    } else if (date.year == now.year) {
      dateText = '${DateFormat('yyyy/MM/dd', 'en').format(date)}';
    } else {
      dateText = '${DateFormat('yyyy/MM/dd', 'en').format(date)}';
    }

    return DrawableText(
      text: dateText,
      textAlign: textAlign,
      size: fontSize ?? 11.0.sp,
      color: color,
    );
  }
}
