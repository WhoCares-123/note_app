import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../pages/view_page.dart';

class TrashNoteCard extends StatelessWidget {
  final Note note;
  const TrashNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<NoteProvider>();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () async {
          // Open view page to see full content before deciding
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ViewPage(note: note)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // color marker
              Container(
                width: 12,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(note.color),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? '(No title)' : note.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6),
                    Text(
                      note.checklist.isNotEmpty
                          ? _snippetFromChecklist(note)
                          : _snippetFromContent(note),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (note.checklist.isNotEmpty)
                          Icon(Icons.check_box, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        if (note.reminder != null)
                          Row(
                            children: [
                              Icon(Icons.alarm, size: 18, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(_formatTime(note.reminder!)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.restore, color: Colors.green),
                    onPressed: () {
                      prov.restoreNote(note.id);
                      Navigator.pop(context);
                    },
                    tooltip: 'Restore',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete Permanently?'),
                          content: Text(
                            'This action cannot be undone. Are you sure you want to permanently delete this note?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        prov.deleteNote(note.id, permanent: true);
                        Navigator.pop(context);
                      }
                    },
                    tooltip: 'Delete Permanently',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _snippetFromContent(Note n) {
    final s = n.content.replaceAll('\n', ' ');
    return s.length > 80 ? s.substring(0, 80) + '…' : s;
  }

  String _snippetFromChecklist(Note n) {
    if (n.checklist.isEmpty) return '';
    final done = n.checklist.where((c) => c.done).length;
    return '${n.checklist.length} items • $done done';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) {
    final d = dt.toLocal();
    var hour = d.hour;
    final minute = _two(d.minute);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${_two(hour)}:$minute $ampm';
  }
}

