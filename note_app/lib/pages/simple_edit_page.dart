import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

class SimpleEditPage extends StatefulWidget {
  final Note note;
  const SimpleEditPage({super.key, required this.note});

  @override
  State<SimpleEditPage> createState() => _SimpleEditPageState();
}

class _SimpleEditPageState extends State<SimpleEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note editNote;

  @override
  void initState() {
    super.initState();
    // Get the latest note from provider to ensure we're working with the correct instance
    final prov = context.read<NoteProvider>();
    editNote = prov.notes.firstWhere(
      (n) => n.id == widget.note.id,
      orElse: () => widget.note,
    );
    _titleController = TextEditingController(text: editNote.title);
    _contentController = TextEditingController(text: editNote.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final prov = context.read<NoteProvider>();
    // Only update title and content, preserve all other properties (checklist, reminder, etc.)
    editNote.title = _titleController.text.trim();
    editNote.content = _contentController.text.trim();
    editNote.updatedAt = DateTime.now();
    // The checklist and other properties are already preserved since we're modifying the same note object
    prov.updateNote(editNote);
    Navigator.pop(context, true); // Return true to indicate save was successful
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Note'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

