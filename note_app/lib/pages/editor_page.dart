import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:note_app/models/note.dart';
import 'package:note_app/providers/note_provider.dart';

enum NoteMode { note, checklist, reminder }

class EditorPage extends StatefulWidget {
  final Note note;
  final bool isNew;
  final NoteMode mode;
  const EditorPage({super.key, required this.note, this.isNew = false, this.mode = NoteMode.note});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late Note edit;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _newChecklistCtrl = TextEditingController();
  bool _autoPromptDone = false;

  @override
  void initState() {
    super.initState();
    edit = widget.note;
    _titleCtrl.text = edit.title;
    _contentCtrl.text = edit.content;
    // automatically prompt when opened in special modes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoPromptDone) {
        _autoPromptDone = true;
        if (widget.mode == NoteMode.checklist) {
          // in checklist mode, focus the inline add field; nothing else needed here
          // small delay to focus the add field if present
          Future.delayed(Duration(milliseconds: 200), () {
            // no-op; UI shows inline add box
          });
        } else if (widget.mode == NoteMode.reminder) {
          _pickReminder();
        }
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _newChecklistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Branch UI by mode
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New ${_modeTitle()}' : 'Edit ${_modeTitle()}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'color':
                  await _pickColorQuick();
                  break;
                case 'set_reminder':
                  await _pickReminder();
                  break;
                case 'clear_reminder':
                  setState(() => edit.reminder = null);
                  break;
                case 'lock':
                  await _toggleLock();
                  break;
                case 'delete':
                  _delete();
                  break;
              }
            },
            itemBuilder: (_) => [
              if (widget.mode == NoteMode.note) PopupMenuItem(value: 'color', child: Text('Change color')),
              PopupMenuItem(value: 'set_reminder', child: Text('Set reminder')),
              if (edit.reminder != null) PopupMenuItem(value: 'clear_reminder', child: Text('Clear reminder')),
              PopupMenuItem(value: 'lock', child: Text(edit.locked ? 'Unlock' : 'Lock')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: _buildBodyByMode(),
      ),
      // fixed save area so it never blocks the main content
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
            child: Text('Save'),
          ),
        ),
      ),
    );
  }

  String _modeTitle() {
    switch (widget.mode) {
      case NoteMode.checklist:
        return 'Checklist';
      case NoteMode.reminder:
        return 'Reminder';
      default:
        return 'Note';
    }
  }

  Widget _buildBodyByMode() {
    switch (widget.mode) {
      case NoteMode.checklist:
        return _buildChecklistUI();
      case NoteMode.reminder:
        return _buildReminderUI();
      case NoteMode.note:
        return _buildNoteUI();
    }
  }

  Widget _buildNoteUI() {
    // make the card occupy available vertical space above the bottom save button
    return LayoutBuilder(builder: (context, constraints) {
      final avail = constraints.maxHeight;
      final minH = (avail.isFinite ? avail : MediaQuery.of(context).size.height) - 80;
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minH < 300 ? 300 : minH),
        child: Card(
          color: Color(edit.color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _titleCtrl, decoration: InputDecoration(hintText: 'Title', border: InputBorder.none), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 12),
                Expanded(child: TextField(controller: _contentCtrl, decoration: InputDecoration(hintText: 'Content', border: InputBorder.none), maxLines: null)),
                SizedBox(height: 8),
                if (edit.reminder != null)
                  Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Reminder: ${_formatDateTime(edit.reminder!)}', style: TextStyle(color: Colors.grey[700]))),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildChecklistUI() {
    return LayoutBuilder(builder: (context, constraints) {
      final avail = constraints.maxHeight;
      final minH = (avail.isFinite ? avail : MediaQuery.of(context).size.height) - 80;
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minH < 300 ? 300 : minH),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(controller: _titleCtrl, decoration: InputDecoration(hintText: 'Checklist title'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 12),
                Expanded(
                  child: edit.checklist.isEmpty
                      ? Center(child: Text('No items yet. Add using the field below.'))
                      : ListView.builder(
                          itemCount: edit.checklist.length,
                          itemBuilder: (_, i) {
                            final c = edit.checklist[i];
                            return ListTile(
                              leading: Checkbox(value: c.done, onChanged: (v) => setState(() => c.done = v ?? false)),
                              title: Text(c.text),
                              onTap: () async {
                                final text = await _askForText(initial: c.text, title: 'Edit item');
                                if (text != null && text.trim().isNotEmpty) setState(() => c.text = text.trim());
                              },
                              trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => setState(() => edit.checklist.removeAt(i))),
                            );
                          },
                        ),
                ),
                Row(children: [
                  Expanded(child: TextField(controller: _newChecklistCtrl, decoration: InputDecoration(hintText: 'Add item'), onSubmitted: (s) {
                    if (s.trim().isEmpty) return;
                    setState(() {
                      edit.checklist = List.from(edit.checklist)..add(ChecklistItem(id: Uuid().v4(), text: s.trim()));
                      _newChecklistCtrl.clear();
                    });
                  })),
                  IconButton(icon: Icon(Icons.add), onPressed: () {
                    final s = _newChecklistCtrl.text.trim();
                    if (s.isEmpty) return;
                    setState(() {
                      edit.checklist = List.from(edit.checklist)..add(ChecklistItem(id: Uuid().v4(), text: s));
                      _newChecklistCtrl.clear();
                    });
                  })
                ]),
                SizedBox(height: 12),
                // Save button moved to bottomNavigationBar; keep small hint here
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildReminderUI() {
    return ListView(children: [
      TextField(controller: _titleCtrl, decoration: InputDecoration(hintText: 'Title'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      SizedBox(height: 12),
      TextField(controller: _contentCtrl, decoration: InputDecoration(hintText: 'Content'), maxLines: 6),
      SizedBox(height: 12),
      ListTile(
        title: Text(edit.reminder == null ? 'No reminder' : 'Reminder: ${_formatDateTime(edit.reminder!)}'),
        trailing: Icon(Icons.alarm),
        onTap: _pickReminder,
      ),
      SizedBox(height: 24),
      ElevatedButton(onPressed: _save, child: Text('Save')),
    ]);
  }

  void _save() {
    final prov = context.read<NoteProvider>();
    edit.title = _titleCtrl.text.trim();
    edit.content = _contentCtrl.text.trim();
    if (widget.isNew) prov.addNote(edit);
    else prov.updateNote(edit);
    Navigator.pop(context);
  }

  void _delete() {
    final prov = context.read<NoteProvider>();
    if (widget.isNew) return Navigator.pop(context);
    prov.deleteNote(edit.id);
    Navigator.pop(context);
  }

  Future<void> _toggleLock() async {
    final prov = context.read<NoteProvider>();
    // If enabling lock and no app PIN exists, prompt to set one
    if (!edit.locked && prov.appPin == null) {
      final pin = await _askForPin(setMode: true);
      if (pin == null || pin.isEmpty) return;
      await prov.setPin(pin);
    }
    setState(() => edit.locked = !edit.locked);
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: edit.reminder ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(edit.reminder ?? DateTime.now()));
    if (time == null) return;
    setState(() {
      edit.reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickColorQuick() async {
    final colors = [Colors.white.value, Colors.yellow[100]!.value, Colors.green[100]!.value, Colors.blue[100]!.value, Colors.pink[100]!.value, Colors.orange[100]!.value];
    final choice = await showDialog<int?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pick background color'),
        content: Wrap(spacing: 8, children: colors.map((v) => GestureDetector(onTap: () => Navigator.pop(context, v), child: Container(width: 40, height: 40, color: Color(v)))).toList()),
      ),
    );
    if (choice != null) setState(() => edit.color = choice);
  }

  Future<String?> _askForPin({bool setMode = false}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(setMode ? 'Set PIN' : 'Enter PIN'),
        content: TextField(controller: ctrl, obscureText: true, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: Text('OK')),
        ],
      ),
    );
  }

  Future<String?> _askForText({String initial = '', String title = 'Input'}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: Text('OK')),
        ],
      ),
    );
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
