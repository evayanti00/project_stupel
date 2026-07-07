import 'dart:convert';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? bio;
  final String? profilePhotoUrl;
  final bool isVerified;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bio,
    this.profilePhotoUrl,
    this.isVerified = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'] ?? 'user',
        phone: json['phone']?.toString(),
        bio: json['bio']?.toString(),
        profilePhotoUrl: json['profile_photo_url']?.toString(),
        isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      );
}

class Note {
  final int? id;
  final String title;
  final String content;
  final bool isTask;
  bool isDone;
  final DateTime? dueDate;
  final DateTime createdAt;
  final List<String> images;
  final String? priority;
  final String? status;
  final String? description;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.isTask,
    this.isDone = false,
    this.dueDate,
    required this.createdAt,
    this.images = const [],
    this.priority,
    this.status,
    this.description,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        isTask: json['is_task'] == 1 || json['is_task'] == true,
        isDone: json['is_done'] == 1 || json['is_done'] == true,
        dueDate: json['due_date'] != null && json['due_date'] != '' ? DateTime.parse(json['due_date']) : null,
        createdAt: DateTime.parse(json['created_at']),
        images: (() {
          final raw = json['images'];
          if (raw is List) return raw.map((e) => e.toString()).toList();
          if (raw is String && raw.isNotEmpty) {
            try {
              final parsed = jsonDecode(raw);
              if (parsed is List) return parsed.map((e) => e.toString()).toList();
            } catch (_) {}
          }
          return <String>[];
        })(),
        priority: json['priority']?.toString(),
        status: json['status']?.toString(),
        description: json['description']?.toString(),
      );

  String get plainContent {
    try {
      final parsed = jsonDecode(content);
      if (parsed is List) {
        return parsed.fold<String>('', (acc, e) => '$acc${e['insert'] ?? ''}').trim();
      }
    } catch (_) {}
    return content;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'is_task': isTask ? 1 : 0,
        'is_done': isDone ? 1 : 0,
        'due_date': dueDate != null ? dueDate!.toIso8601String().split('T').first : null,
        'images': images,
        'priority': priority,
        'status': status,
        'description': description,
      };
}

class Expense {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        description: json['description'],
        amount: double.parse(json['amount'].toString()),
        category: json['category'],
        date: DateTime.parse(json['date']),
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String().split('T').first,
      };

  static const List<String> categories = [
    'Makan & Minum',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Lainnya',
  ];
}
