import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../pages/editor_page.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  const NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<NoteProvider>();
    // show color marker using note.color
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () async {
          if (note.locked) {
            final ok = await _askPin(context, prov);
            if (!ok) return;
          }
          final mode = note.checklist.isNotEmpty ? NoteMode.checklist : NoteMode.note;
          await Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(note: note, mode: mode)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // color marker
              Container(width: 12, height: 56, decoration: BoxDecoration(color: Color(note.color), borderRadius: BorderRadius.circular(6))),
              SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(note.title.isEmpty ? '(No title)' : note.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  // prefer showing checklist preview when there are checklist items
                  Text(note.checklist.isNotEmpty ? _snippetFromChecklist(note) : _snippetFromContent(note), style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Row(children: [
                    if (note.checklist.isNotEmpty) Icon(Icons.check_box, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    if (note.reminder != null)
                      Row(children: [
                        Icon(Icons.alarm, size: 18, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(_formatTime(note.reminder!))
                      ]),
                  ])
                ]),
              ),
              Column(children: [
                // actions popup (single Edit based on note.type)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      // open editor in note's stored type
                      final mode = (note.type == 'checklist') ? NoteMode.checklist : (note.type == 'reminder') ? NoteMode.reminder : NoteMode.note;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(note: note, mode: mode)));
                    } else if (v == 'color') {
                      await _pickColor(context, prov);
                    } else if (v == 'trash') {
                      await prov.deleteNote(note.id);
                    } else if (v == 'delete') {
                      await prov.deleteNote(note.id, permanent: true);
                    } else if (v == 'restore') {
                      await prov.restoreNote(note.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'color', child: Text('Change color')),
                    if (!note.deleted) PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
                    if (note.deleted) PopupMenuItem(value: 'restore', child: Text('Restore')),
                    PopupMenuItem(value: 'delete', child: Text('Delete permanently')),
                  ],
                ),
                if (note.locked) Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.lock, color: Colors.redAccent))
              ])
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

  Future<bool> _askPin(BuildContext ctx, NoteProvider prov) async {
    final ctrl = TextEditingController();
    final res = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Locked'),
        content: TextField(controller: ctrl, obscureText: true, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Enter PIN')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(onPressed: () {
            final ok = prov.validatePin(ctrl.text.trim());
            Navigator.pop(ctx, ok);
          }, child: Text('Unlock')),
        ],
      ),
    );
    return res ?? false;
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

  Future<void> _pickColor(BuildContext ctx, NoteProvider prov) async {
    final colors = [Colors.white, Colors.yellow[100]!, Colors.green[100]!, Colors.blue[100]!, Colors.pink[100]!, Colors.orange[100]!];
    final choice = await showDialog<int?>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Pick color'),
        content: Wrap(
          spacing: 8,
          children: colors.map((c) => GestureDetector(
            onTap: () => Navigator.pop(ctx, c.value),
            child: Container(width: 40, height: 40, color: c),
          )).toList(),
        ),
      ),
    );
    if (choice != null) {
      note.color = choice;
      await prov.updateNote(note);
    }
  }
}
