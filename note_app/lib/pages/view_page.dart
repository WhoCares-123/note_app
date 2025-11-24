import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import 'simple_edit_page.dart';
import 'editor_page.dart';

class ViewPage extends StatefulWidget {
  final Note note;
  const ViewPage({super.key, required this.note});

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  late Note currentNote;

  @override
  void initState() {
    super.initState();
    currentNote = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NoteProvider>();
    // Refresh note from provider to get latest changes
    final updatedNote = prov.notes.firstWhere(
      (n) => n.id == currentNote.id,
      orElse: () => currentNote,
    );
    if (updatedNote.id == currentNote.id) {
      currentNote = updatedNote;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Note'),
        actions: [
          IconButton(
            icon: Icon(
              currentNote.notePin != null ? Icons.lock : Icons.lock_open,
              color: currentNote.notePin != null ? Colors.redAccent : null,
            ),
            onPressed: () => _toggleNoteLock(context, prov),
            tooltip: currentNote.notePin != null ? 'Unlock note' : 'Lock note',
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            children: [
              _buildNoteView(currentNote),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                // Note: No PIN check needed here since user is already in view page
                // For checklists, use EditorPage; for regular notes, use SimpleEditPage
                if (currentNote.checklist.isNotEmpty || currentNote.type == 'checklist') {
                  // Use EditorPage for checklists to preserve checklist functionality
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditorPage(note: currentNote, mode: NoteMode.checklist),
                    ),
                  );
                  setState(() {}); // Refresh after editing
                } else {
                  // Use SimpleEditPage for regular notes
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimpleEditPage(note: currentNote),
                    ),
                  );
                  if (result == true) {
                    // Refresh the note after editing
                    setState(() {});
                  }
                }
              },
              child: Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteView(Note note) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        color: Color(note.color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? '(No title)' : note.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (note.content.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  note.content,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
              if (note.content.isEmpty && note.checklist.isEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'No content',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (note.reminder != null) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.alarm, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Reminder: ${_formatDateTime(note.reminder!)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              if (note.checklist.isNotEmpty) ...[
                if (note.content.isNotEmpty || note.reminder != null) SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Text(
                  'Checklist:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                ...note.checklist.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            item.done ? Icons.check_box : Icons.check_box_outline_blank,
                            color: item.done ? Colors.green : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                decoration: item.done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNoteLock(BuildContext ctx, NoteProvider prov) async {
    if (currentNote.notePin != null) {
      // Unlock: ask for current PIN first
      final ctrl = TextEditingController();
      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text('Unlock Note'),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(hintText: 'Enter current PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final enteredPin = ctrl.text.trim();
                final ok = currentNote.notePin == enteredPin;
                Navigator.pop(ctx, ok);
              },
              child: Text('Unlock'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        currentNote.notePin = null;
        currentNote.locked = false;
        await prov.updateNote(currentNote);
        setState(() {});
      }
    } else {
      // Lock: set new PIN
      final ctrl = TextEditingController();
      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text('Lock Note'),
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
                final pin = ctrl.text.trim();
                if (pin.length == 4) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text('Lock'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final pin = ctrl.text.trim();
        if (pin.length == 4) {
          currentNote.notePin = pin;
          currentNote.locked = true;
          await prov.updateNote(currentNote);
          setState(() {});
        }
      }
    }
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final year = d.year;
    final month = _two(d.month);
    final day = _two(d.day);
    var hour = d.hour;
    final minute = _two(d.minute);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = _two(hour);
    return '$year-$month-$day – $hourStr:$minute $ampm';
  }
}

