import 'package:flutter/material.dart';

class UserNotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionUrl;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const UserNotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      actionUrl: json['actionUrl']?.toString() ?? '/home',
      type: json['type']?.toString().toUpperCase() ?? 'GENERAL',
      isRead: json['isRead'] == true || json['isRead'] == 'true',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserNotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? imageUrl,
    String? actionUrl,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return UserNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedRelativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'এইমাত্র';
    } else if (difference.inMinutes < 60) {
      return '${_toBengaliDigits(difference.inMinutes.toString())} মিনিট আগে';
    } else if (difference.inHours < 24) {
      return '${_toBengaliDigits(difference.inHours.toString())} ঘণ্টা আগে';
    } else if (difference.inDays == 1) {
      return 'গতকাল';
    } else if (difference.inDays < 7) {
      return '${_toBengaliDigits(difference.inDays.toString())} দিন আগে';
    } else {
      return '${_toBengaliDigits(createdAt.day.toString())}/${_toBengaliDigits(createdAt.month.toString())}/${_toBengaliDigits(createdAt.year.toString())}';
    }
  }

  static String _toBengaliDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], bengali[i]);
    }
    return result;
  }

  IconData get iconData {
    final t = type.toUpperCase();
    final lowTitle = title.toLowerCase();

    if (t == 'STREAK' || lowTitle.contains('স্ট্রিক') || lowTitle.contains('আগুন')) {
      return Icons.local_fire_department_rounded;
    }
    if (t == 'EXAM' || lowTitle.contains('পরীক্ষা') || lowTitle.contains('মডেল টেস্ট')) {
      return Icons.assignment_outlined;
    }
    if (t == 'LEADERBOARD' || lowTitle.contains('লিডারবোর্ড') || lowTitle.contains('সেরা')) {
      return Icons.emoji_events_outlined;
    }
    if (lowTitle.contains('রসায়ন') || lowTitle.contains('পদার্থ') || lowTitle.contains('বিজ্ঞান')) {
      return Icons.science_outlined;
    }
    if (t == 'PROMO' || lowTitle.contains('অফার') || lowTitle.contains('ডিসকাউন্ট')) {
      return Icons.local_offer_outlined;
    }
    return Icons.notifications_active_outlined;
  }

  Color get accentColor {
    final t = type.toUpperCase();
    final lowTitle = title.toLowerCase();

    if (t == 'STREAK' || lowTitle.contains('স্ট্রিক') || lowTitle.contains('আগুন')) {
      return const Color(0xFFFF3B30);
    }
    if (t == 'EXAM' || lowTitle.contains('পরীক্ষা') || lowTitle.contains('মডেল টেস্ট')) {
      return const Color(0xFF086057);
    }
    if (t == 'LEADERBOARD' || lowTitle.contains('লিডারবোর্ড')) {
      return const Color(0xFFFF9F0A);
    }
    if (lowTitle.contains('রসায়ন') || lowTitle.contains('পদার্থ')) {
      return const Color(0xFF0284C7);
    }
    return const Color(0xFF086057);
  }
}
