import 'dart:convert';

class ChecklistItem {
  String id;
  String text;
  bool done;
  ChecklistItem({required this.id, required this.text, this.done = false});
  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};
  factory ChecklistItem.fromMap(Map<String, dynamic> m) =>
      ChecklistItem(id: m['id'], text: m['text'], done: m['done'] ?? false);
}

class Note {
  String id;
  String title;
  String content;
  List<ChecklistItem> checklist;
  DateTime? reminder; // in-app reminder
  bool locked;
  int color; // store ARGB hex, default white
  bool deleted; // soft-delete flag
  DateTime? deletedAt;
  String type; // 'note' | 'checklist' | 'reminder'
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.checklist = const [],
    this.reminder,
    this.locked = false,
    this.color = 0xFFFFFFFF,
    this.deleted = false,
    DateTime? deletedAt,
    this.type = 'note',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : deletedAt = deletedAt,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'checklist': checklist.map((c) => c.toMap()).toList(),
        'reminder': reminder?.toIso8601String(),
        'locked': locked,
        'color': color,
        'deleted': deleted,
        'deletedAt': deletedAt?.toIso8601String(),
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'],
        title: m['title'] ?? '',
        content: m['content'] ?? '',
        checklist: (m['checklist'] as List<dynamic>?)
                ?.map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        reminder:
            m['reminder'] != null ? DateTime.parse(m['reminder']) : null,
        locked: m['locked'] ?? false,
        color: m['color'] != null ? (m['color'] as int) : 0xFFFFFFFF,
        deleted: m['deleted'] ?? false,
        deletedAt: m['deletedAt'] != null ? DateTime.parse(m['deletedAt']) : null,
        type: m['type'] ?? 'note',
        createdAt:
            m['createdAt'] != null ? DateTime.parse(m['createdAt']) : null,
        updatedAt:
            m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : null,
      );

  String toJson() => jsonEncode(toMap());
  factory Note.fromJson(String s) => Note.fromMap(jsonDecode(s));
}
