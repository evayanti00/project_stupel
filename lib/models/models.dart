class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
      );
}

class Note {
  final int? id;
  final String title;
  final String content;
  final bool isTask;
  bool isDone;
  final DateTime createdAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.isTask,
    this.isDone = false,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        isTask: json['is_task'] == 1 || json['is_task'] == true,
        isDone: json['is_done'] == 1 || json['is_done'] == true,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'is_task': isTask ? 1 : 0,
        'is_done': isDone ? 1 : 0,
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
