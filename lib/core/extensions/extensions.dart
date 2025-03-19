import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_multi_type/image_multi_type.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:m_cubit/m_cubit.dart';

import '../error/error_manager.dart';
import '../strings/enum_manager.dart';
import '../util/pair_class.dart';

extension UpdateTypeHelper on UpdateType {
  String get getName {
    switch (this) {
      case UpdateType.name:
        return 'تغيير الاسم';
      case UpdateType.phone:
        return 'تغير رقم الهاتف';
      case UpdateType.address:
        return 'تغير العن,ان';
      case UpdateType.pass:
        return 'تغير كلمه المر,ر';
    }
  }
}

extension ResponseHelper on http.Response {
  Map<String, dynamic> get jsonBody => jsonDecode(body);

  Pair<T?, String?> getPairError<T>() {
    return Pair(null, ErrorManager.getApiError(this));
  }
}

extension CubitStatusesHelper on CubitStatuses {
  bool get loading => this == CubitStatuses.loading;

  bool get done => this == CubitStatuses.done;
}

extension FormatDuration on Duration {
  String get format =>
      '${inMinutes.remainder(60).toString().padLeft(2, '0')}:${(inSeconds.remainder(60)).toString().padLeft(2, '0')}';
}

extension ApiStatusCode on int {
  bool get success => (this >= 200 && this <= 210);
}

extension SplitByLength on String {
  List<String> splitByLength1(int length, {bool ignoreEmpty = false}) {
    List<String> pieces = [];

    for (int i = 0; i < this.length; i += length) {
      int offset = i + length;
      var piece = substring(i, offset >= this.length ? this.length : offset);

      if (ignoreEmpty) {
        piece = piece.replaceAll(RegExp(r'\s+'), '');
      }

      pieces.add(piece);
    }
    return pieces;
  }

  bool get canSendToSearch {
    if (isEmpty) false;

    return split(' ').last.length > 2;
  }

  String get formatPrice => oCcy.format(this);

  String get removeSpace => replaceAll(' ', '');

  int get numberOnly {
    try {
      return int.parse(this);
    } on Exception {
      return 0;
    }
  }

  double get getCost {
    RegExp regExp = RegExp(r"(\d+\.\d+)");
    String? match = regExp.stringMatch(this);
    double number = double.parse(match ?? '0');
    return number;
  }

  String get removeDuplicates {
    List<String> words = split(' ');
    Set<String> uniqueWords = Set<String>.from(words);
    List<String> uniqueList = uniqueWords.toList();
    String output = uniqueList.join(' ');
    return output;
  }
}

extension StringHelper on String? {
  bool get isBlank {
    return this?.trim().isEmpty ?? true;
  }
}

final oCcy = NumberFormat("#,###", "en_US");

extension MaxInt on num {
  int get maxInt => 2147483647;

  String get formatPrice => oCcy.format(this);

  int get myRound {
    if (toInt() < this) return toInt() + 1;
    return toInt();
  }

  num getPercentage(num p) => this * p / 100;
}

extension CubitStateHelper on CubitStatuses {
  bool get isLoading => this == CubitStatuses.loading;

  bool get isDone => this == CubitStatuses.done;
}

extension FirstItem<E> on Iterable<E> {
  E? firstItem() {
    if (isEmpty) {
      return null;
    } else {
      return first;
    }
  }

  E? lastItem() {
    if (isEmpty) {
      return null;
    } else {
      return last;
    }
  }
}

extension DateUtcHelper on DateTime {
  int get hashDate => (day * 61) + (month * 83) + (year * 23);

  DateTime get getUtc => DateTime.utc(year, month, day);

  /// Check if the date is today
  bool get isToday {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }

  /// Check if the date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return tomorrow.year == year && tomorrow.month == month && tomorrow.day == day;
  }

  /// Check if the date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return yesterday.year == year && yesterday.month == month && yesterday.day == day;
  }

  String get formatDate => DateFormat('yyyy/MM/dd', 'en').format(this);
  String get formatDateMD => DateFormat('M/dd', 'en').format(this);
  String get formatDateDY => DateFormat('yyyy/MM', 'en').format(this);
  String get formatDateMonthName => '$monthName ${day}';
  String get formatDateD => DateFormat('dd', 'en').format(this);

  String get formatDateToRequest => DateFormat('yyyy-MM-dd', 'en').format(this);

  String get formatDateWithCurrent {
    if (isToday) return 'today';

    if (isTomorrow) return 'tomorrow';

    if (isYesterday) return 'yesterday';

    return DateFormat('yyyy/MM/dd', 'en').format(this);
  }

  String get formatDateAther => DateFormat('yyyy-MM-dd HH:mm', 'en').format(this);

  String get formatTime => DateFormat('hh:mm a', 'en').format(this);
  String get formatTime24 => DateFormat('hh:mm', 'en').format(this);

  String get dayName => DateFormat('EEEE').format(this);

  String get monthName => DateFormat('MMMM').format(this);

  String get formatDateTime => '$formatDate - $formatTime';
  String get formatDateTime24 => '$formatDate - $formatTime24';

  String get formatDateTimeVertical => '$formatDate\n$formatTime';

  DateTime addFromNow({int? year, int? month, int? day, int? hour, int? minute, int? second}) {
    return DateTime(
      this.year + (year ?? 0),
      this.month + (month ?? 0),
      this.day + (day ?? 0),
      this.hour + (hour ?? 0),
      this.minute + (minute ?? 0),
      this.second + (second ?? 0),
    );
  }

  DateTime initialFromDateTime({required DateTime date, required TimeOfDay time}) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  int get getWeekNumber {
    final DateTime firstJan = DateTime(year, 1, 1);
    // final int daysInYear = DateTime(year + 1, 1, 1).difference(firstJan).inDays;
    final int weekNumber = (difference(firstJan).inDays ~/ 7) + 1;
    // If the date is after the first Monday of the year, then it is in the current week.
    if (weekday >= 1) {
      return weekNumber;
    }
    // Otherwise, it is in the previous week.
    return weekNumber - 1;
  }

  DateTime get fixTimeZone => add(DateTime.now().timeZoneOffset);
}

extension ScrollMax on ScrollController {
  bool get isMax => position.maxScrollExtent == offset;

  bool get isMin => offset == 0;
}

extension RoomH on types.Room {
  types.User? get me => users.firstWhereOrNull((e) => e.id == '0');

  String get usersName => users.map((e) => e.name).join(' ');

  types.User get otherUser {
    final u = users.firstWhereOrNull((e) => e.id != '0');
    return u ??
        types.User(id: '-1', firstName: '${users.firstOrNull?.id} -${users.lastOrNull?.id}');
  }

  int get latestSeen => metadata?['latestSeen'] ?? 0;

  bool get isRead {
    if ((lastMessages ?? []).isEmpty) return true;
    final latestMessage = lastMessages!.first;
    return ((latestMessage.author.id == '0') || ((latestSeen - (updatedAt ?? 0)) >= 0));
  }

  bool get isNotRead => !isRead;
}

extension UserH on types.User {
  String get name => '$firstName';
}

extension QueryDocumentSnapshotH on QueryDocumentSnapshot {
  Map<String, dynamic> message(types.Room room) {
    final data = this.data() as Map<String, dynamic>;

    final author = room.users.firstWhere(
      (u) => u.id == data['authorId'],
      orElse: () => types.User(id: data['authorId'] as String),
    );

    data['author'] = author.toJson();
    data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
    data['id'] = id;
    data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;
    return data;
  }

  types.User get user {
    final data = this.data() as Map<String, dynamic>;

    data['id'] = id;
    data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
    data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
    data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

    return types.User.fromJson(data);
  }
}

extension MessageH on types.Message {
  Widget latestMessage(types.Room room) {
    final isRead = room.isRead;
    String message = '';
    dynamic icon;

    if (this is types.CustomMessage) {
      return 0.0.verticalSpace;
    } else if (this is types.FileMessage) {
      message = 'ملف';
      icon = Icons.file_copy;
    } else if (this is types.PartialAudio || this is types.AudioMessage) {
      message = 'Voice Message';
      icon = Icons.mic;
    } else if (this is types.ImageMessage) {
      message = 'صورة';
      icon = Icons.image;
    } else if (this is types.TextMessage) {
      message = (this as types.TextMessage).text;
      icon = Icons.message;
    }

    return DrawableText(
      text: message,
      matchParent: true,
      maxLines: 1,
      size: 14.0.sp,
      color: isRead ? Colors.grey : AppColorManager.mainColor,
      //fontFamily: isRead ? null : FontManager.cairoBold.name,
      drawablePadding: 7.0.w,
      drawableStart: ImageMultiType(
        color: isRead ? Colors.grey : AppColorManager.threadColor,
        url: icon,
        height: 17.0.r,
        width: 17.0.r,
      ),
    );
  }
}
