import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card.dart';
import '../pages/editor_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // removed tabs — single notes view with trash button

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('All-in-One Notes'),
        actions: [
          IconButton(
            icon: Icon(prov.isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () => prov.setTheme(!prov.isDark),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.lock),
            onPressed: () => _showPinDialog(context),
            tooltip: 'Set/Remove PIN',
          ),
        ],
      ),
      // main notes body with overlayed trash button
      body: Stack(children: [
        _buildNotesTab(context, prov),
        Positioned(
          bottom: 18,
          left: 18,
          child: FloatingActionButton.small(
            heroTag: 'trash_btn',
            onPressed: () => _openTrashSheet(context, prov),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(Icons.delete_outline),
            tooltip: 'Trash',
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showCreateChooser(context),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext ctx, NoteProvider prov) {
    final list = prov.activeNotes;
    if (list.isEmpty) return Center(child: Text('No notes yet. Tap + to create one.'));
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(height: 8),
        itemBuilder: (_, i) => NoteCard(note: list[i]),
      ),
    );
  }

  // trash is opened via sheet from trash button
  void _openTrashSheet(BuildContext ctx, NoteProvider prov) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        final list = prov.trashNotes;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton(onPressed: () { prov.emptyTrash(); Navigator.pop(ctx); }, child: Text('Empty'))]),
              if (list.isEmpty) Padding(padding: const EdgeInsets.all(24.0), child: Text('Trash is empty.')),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(list[i].title.isEmpty ? '(No title)' : list[i].title),
                    subtitle: Text(list[i].content.isEmpty ? '' : list[i].content),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: Icon(Icons.restore), onPressed: () => prov.restoreNote(list[i].id)),
                      IconButton(icon: Icon(Icons.delete_forever), onPressed: () => prov.deleteNote(list[i].id, permanent: true)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _showCreateChooser(BuildContext ctx) {
    final prov = ctx.read<NoteProvider>();
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: Icon(Icons.note_add), title: Text('New Note'), onTap: () {
            Navigator.pop(ctx);
            final newNote = prov.createEmpty(type: 'note');
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => EditorPage(note: newNote, isNew: true, mode: NoteMode.note)));
          }),
          ListTile(leading: Icon(Icons.checklist), title: Text('New Checklist'), onTap: () {
            Navigator.pop(ctx);
            final newNote = prov.createEmpty(type: 'checklist');
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => EditorPage(note: newNote, isNew: true, mode: NoteMode.checklist)));
          }),
          ListTile(leading: Icon(Icons.alarm_add), title: Text('Quick Reminder'), onTap: () {
            Navigator.pop(ctx);
            final newNote = prov.createEmpty(type: 'reminder');
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => EditorPage(note: newNote, isNew: true, mode: NoteMode.reminder)));
          }),
        ]),
      ),
    );
  }

  void _showSettingsDialog(BuildContext ctx) {
    final prov = ctx.read<NoteProvider>();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(
            title: Text('Dark mode'),
            value: prov.isDark,
            onChanged: (v) => prov.setTheme(v),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              prov.emptyTrash();
              Navigator.pop(ctx);
            },
            child: Text('Empty Trash'),
          )
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext ctx) {
    final prov = ctx.read<NoteProvider>();
    final controller = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(prov.appPin == null ? 'Set PIN' : 'Change / Remove PIN'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: prov.appPin == null ? 'Enter PIN' : 'New PIN or leave empty to remove'),
          obscureText: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) prov.setPin(null);
              else prov.setPin(val);
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
