class User {
  final int id;
  final String name;
  final String email;
  final String role;

  User({required this.id, required this.name, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'] ?? 'user',
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

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.isTask,
    this.isDone = false,
    this.dueDate,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        isTask: json['is_task'] == 1 || json['is_task'] == true,
        isDone: json['is_done'] == 1 || json['is_done'] == true,
        dueDate: json['due_date'] != null && json['due_date'] != '' ? DateTime.parse(json['due_date']) : null,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'is_task': isTask ? 1 : 0,
        'is_done': isDone ? 1 : 0,
      'due_date': dueDate != null ? dueDate!.toIso8601String().split('T').first : null,
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
