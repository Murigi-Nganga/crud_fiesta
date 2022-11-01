import 'package:crud_fiesta/services/auth/auth_service.dart';
import 'package:crud_fiesta/services/auth/auth_user.dart';
import 'package:crud_fiesta/services/crud/notes_service.dart';
import 'package:flutter/material.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  // DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  // void _deleteOrSaveNote() async {
  //   final note = _note;

  //   if (note != null) {
  //     if (_textController.text.isEmpty) {
  //       _notesService.deleteNote(id: note.noteId);
  //     } else {
  //       await _notesService.updateNote(
  //         note: note,
  //         text: _textController.text,
  //       );
  //     }
  //   }
  // }

  @override
  void dispose() {
    // _deleteOrSaveNote();
    _textController.dispose();
    super.dispose();
  }

  void _createNewNote(BuildContext context, String text) async {
    AuthUser currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _notesService.getUser(email: email);
    await _notesService.createNote(
      owner: owner,
      text: text,
    );
    _textController.text = '';
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Type your note text',
              ),
              textInputAction: TextInputAction.done,
            ),
            TextButton(
              onPressed: () => _createNewNote(context, _textController.text),
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}
