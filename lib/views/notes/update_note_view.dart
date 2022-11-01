import 'package:crud_fiesta/constants/app_routes.dart';
import 'package:crud_fiesta/services/crud/notes_service.dart';
import 'package:crud_fiesta/utilities/generics/get_arguments.dart';
import 'package:flutter/material.dart';

class UpdateNoteView extends StatefulWidget {
  const UpdateNoteView({super.key});

  @override
  State<UpdateNoteView> createState() => _UpdateNoteViewState();
}

class _UpdateNoteViewState extends State<UpdateNoteView> {
  late final NotesService _notesService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController();
    _notesService = NotesService();
    super.initState();
  }

  void _updateNote(DatabaseNote dbNote, String updateText) async {
    await _notesService.updateNote(note: dbNote, text: updateText);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final routeArgs =
    //     ModalRoute.of(context)!.settings.arguments as Map<String, DatabaseNote>;

    final routeArgs = context.getArgument<Map<String, DatabaseNote>>()!;
    DatabaseNote note = routeArgs['note']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                  //TODO: Add some decoration to this widget
                  ),
              child: Text(note.noteText),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: _textController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Update your note here',
              ),
              textInputAction: TextInputAction.done,
            ),
            TextButton(
              onPressed: () => _updateNote(note, _textController.text),
              child: const Text('Update'),
            )
          ],
        ),
      ),
    );
  }
}
