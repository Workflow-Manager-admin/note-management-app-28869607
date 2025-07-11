import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Replace these with your actual Supabase credentials
const supabaseUrl = 'https://mzxyorlnbfdkneiezgjz.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16eHlvcmxuYmZka25laWV6Z2p6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDUxMDksImV4cCI6MjA2NzYyMTEwOX0.URYpbwtC2u5ORBlUzpWPNspXMWq_cLBOKWMOgGbilyQ';

// --- Color scheme ---
const primaryColor = Color(0xFF1976D2);
const secondaryColor = Color(0xFF424242);
const accentColor = Color(0xFFFFCA28);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const NotesApp());
}

// PUBLIC_INTERFACE
class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      brightness: Brightness.light,
      primaryColor: primaryColor,
      secondaryHeaderColor: secondaryColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      useMaterial3: true,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 24, color: primaryColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, color: secondaryColor),
        bodyMedium: TextStyle(fontSize: 15),
        bodyLarge: TextStyle(fontSize: 17),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
    );

    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const NotesListPage(),
    );
  }
}

// --- Notes Data Model ---
class Note {
  final int id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    try {
      return Note(
        id: map['id'] as int,
        title: map['title'] as String,
        content: map['content'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] ?? ''),
        updatedAt: DateTime.parse(map['updated_at'] ?? ''),
      );
    } catch (e, stack) {
      print('[ERROR] Failed to deserialize Note: $e');
      print('[MAP DATA] $map');
      print('[STACKTRACE] $stack');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// --- Supabase Service Layer ---
// PUBLIC_INTERFACE
class NotesService {
  static final _client = Supabase.instance.client;
  static const _table = 'notes';

  // PUBLIC_INTERFACE
  static Future<List<Note>> fetchNotes({String search = ''}) async {
    final List data = await _client.from(_table).select().order('updated_at', ascending: false);

    List<Note> notes = data.map((item) => Note.fromMap(item)).toList();
    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      notes = notes
          .where((n) => n.title.toLowerCase().contains(q))
          .toList();
    }
    return notes;
  }

  // PUBLIC_INTERFACE
  static Future<Note> createNote(String title, String content) async {
    final now = DateTime.now().toUtc();
    final resp = await _client.from(_table).insert({
      'title': title,
      'content': content,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).select().single();
    return Note.fromMap(resp);
  }

  // PUBLIC_INTERFACE
  static Future<Note> updateNote(int id, String title, String content) async {
    final now = DateTime.now().toUtc();
    final resp = await _client.from(_table).update({
      'title': title,
      'content': content,
      'updated_at': now.toIso8601String(),
    }).eq('id', id).select().single();
    return Note.fromMap(resp);
  }

  // PUBLIC_INTERFACE
  static Future<void> deleteNote(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

// --- Notes State Management ---
class NotesState extends ChangeNotifier {
  List<Note> _notes = [];
  bool _loading = false;
  String _search = '';
  String? _error;

  List<Note> get notes => _notes;
  bool get isLoading => _loading;
  String? get error => _error;
  String get search => _search;

  // PUBLIC_INTERFACE
  Future<void> loadNotes({String search = ''}) async {
    _setLoading(true);
    try {
      final result = await NotesService.fetchNotes(search: search);
      _notes = result;
      _error = null;
    } catch (e, stack) {
      // Log full error to console for debugging
      print('[ERROR] Failed to load notes: $e');
      print('[STACKTRACE] $stack');
      // Optionally, display more info in the UI during debug
      _error = 'Failed to load notes: $e';
    }
    _setLoading(false);
  }

  // PUBLIC_INTERFACE
  Future<bool> addNote(String title, String content) async {
    _setLoading(true);
    try {
      final note = await NotesService.createNote(title, content);
      _notes.insert(0, note);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add note';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // PUBLIC_INTERFACE
  Future<bool> updateNote(int id, String title, String content) async {
    _setLoading(true);
    try {
      final updated = await NotesService.updateNote(id, title, content);
      int idx = _notes.indexWhere((note) => note.id == id);
      if (idx >= 0) _notes[idx] = updated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update note';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // PUBLIC_INTERFACE
  Future<bool> deleteNote(int id) async {
    _setLoading(true);
    try {
      await NotesService.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete note';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSearch(String search) {
    _search = search;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}

// --- Notes List Page (Main Screen) ---
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final _state = NotesState();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _state.loadNotes();
  }

  void _onSearch(String value) async {
    _state.setSearch(value);
    await _state.loadNotes(search: value);
  }

  void _openCreateNote() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditPage(),
      ),
    );
    if (created == true) {
      await _state.loadNotes(search: _state.search);
    }
  }

  void _openDetail(Note note) async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(note: note),
      ),
    );
    if (updated == true) {
      await _state.loadNotes(search: _state.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _state.isLoading ? null : _load,
              )
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add',
            onPressed: _state.isLoading ? null : _openCreateNote,
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search notes',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_state.isLoading)
                    const Expanded(
                        child: Center(child: CircularProgressIndicator())),
                  if (!_state.isLoading && _state.notes.isEmpty)
                    const Expanded(
                        child: Center(
                          child: Text(
                            'No notes found.',
                            style: TextStyle(color: secondaryColor, fontSize: 18),
                          ),
                        )),
                  if (!_state.isLoading && _state.notes.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemBuilder: (ctx, idx) {
                          final note = _state.notes[idx];
                          return Card(
                            surfaceTintColor: Colors.transparent,
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              onTap: _state.isLoading
                                  ? null
                                  : () => _openDetail(note),
                              title: Text(note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                note.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              trailing: IconButton(
                                onPressed: _state.isLoading
                                    ? null
                                    : () async {
                                        final res = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Delete Note",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                  'Are you sure you want to delete "${note.title}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(true),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (res == true) {
                                          await _state.deleteNote(note.id);
                                        }
                                      },
                                icon: const Icon(Icons.delete_outline, color: secondaryColor),
                                tooltip: "Delete",
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: 10),
                        itemCount: _state.notes.length,
                      ),
                    ),
                  if (_state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _state.error!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w400),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Note Detail Page ---
class NoteDetailPage extends StatelessWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  void _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditPage(note: note),
      ),
    );
    if (updated == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _edit(context))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Last edited: ${note.updatedAt.toLocal().toString().substring(0, 16).replaceAll('T', ' ')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Note Edit/Create Page ---
class NoteEditPage extends StatefulWidget {
  final Note? note;
  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleCtrl.text = widget.note!.title;
      _contentCtrl.text = widget.note!.content;
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _err = null;
    });
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final navigator = Navigator.of(context); // get navigator reference early

    if (!_form.currentState!.validate()) {
      setState(() {
        _saving = false;
      });
      return;
    }

    try {
      if (widget.note == null) {
        // Create
        await NotesService.createNote(title, content);
      } else {
        // Update
        await NotesService.updateNote(widget.note!.id, title, content);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      navigator.pop(true); // use saved navigator instead of directly from context
    } catch (e) {
      setState(() {
        _err = 'Failed to save note';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Note' : 'New Note'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                enabled: !_saving,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  prefixIcon: Icon(Icons.title_rounded, color: primaryColor),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _contentCtrl,
                  enabled: !_saving,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Note content',
                    prefixIcon: Icon(Icons.notes_outlined, color: secondaryColor),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Content is required';
                    }
                    return null;
                  },
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              if (_err != null)
                Center(
                  child: Text(_err!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: Icon(isEdit ? Icons.save_as : Icons.add_circle_outline),
                      label: Text(isEdit ? 'Save Changes' : 'Create Note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
