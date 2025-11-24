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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    cursorColor: isDark ? Colors.white : Colors.black87,
                    selectionControls: MaterialTextSelectionControls(),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => prov.setSearchQuery(value),
                  );
                },
              )
            : Text('Note'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                prov.clearSearch();
                setState(() => _isSearching = false);
              },
              tooltip: 'Close search',
            )
          else
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: 'Search',
            ),
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context),
              tooltip: 'Settings',
            ),
        ],
      ),
      body: _buildNotesTab(context, prov),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showCreateChooser(context),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext ctx, NoteProvider prov) {
    final list = prov.activeNotes;
    if (list.isEmpty) {
      if (prov.searchQuery.isNotEmpty) {
        return Center(child: Text('No notes found matching "${prov.searchQuery}"'));
      }
      return Center(child: Text('No notes yet. Tap + to create one.'));
    }
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
                      IconButton(
                        icon: Icon(Icons.restore),
                        onPressed: () {
                          prov.restoreNote(list[i].id);
                          Navigator.pop(ctx);
                        },
                        tooltip: 'Restore',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever),
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: Text('Delete Permanently?'),
                              content: Text('This action cannot be undone. Are you sure you want to permanently delete this note?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            prov.deleteNote(list[i].id, permanent: true);
                            Navigator.pop(ctx);
                          }
                        },
                        tooltip: 'Delete Permanently',
                      ),
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
          ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Trash'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(ctx);
              _openTrashSheet(ctx, prov);
            },
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
}
