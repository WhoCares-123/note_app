import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../pages/view_page.dart';

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
      child: Stack(
        children: [
          InkWell(
            onTap: () async {
              if (note.notePin != null) {
                final ok = await _askPin(context, prov);
                if (!ok) return;
              }
              await Navigator.push(context, MaterialPageRoute(builder: (_) => ViewPage(note: note)));
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
                  SizedBox(width: 8),
                  // actions popup (single Edit based on note.type)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 20,
                    onSelected: (v) async {
                      if (v == 'edit') {
                        // open view page which has edit button
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ViewPage(note: note)));
                      } else if (v == 'color') {
                        await _pickColor(context, prov);
                      } else if (v == 'pin') {
                        await prov.togglePin(note.id);
                      } else if (v == 'trash') {
                        await prov.deleteNote(note.id);
                      } else if (v == 'restore') {
                        await prov.restoreNote(note.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'color', child: Text('Change color')),
                      if (!note.deleted)
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(note.pinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                      if (!note.deleted) PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
                      if (note.deleted) PopupMenuItem(value: 'restore', child: Text('Restore')),
                    ],
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Pin indicator icon at top right edge of the card
          if (note.pinned)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.push_pin,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          // Lock indicator icon at bottom right edge of the card
          if (note.notePin != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
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
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(hintText: 'Enter 4-digit PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final enteredPin = ctrl.text.trim();
              final ok = note.notePin != null && note.notePin == enteredPin;
              Navigator.pop(ctx, ok);
            },
            child: Text('Unlock'),
          ),
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
