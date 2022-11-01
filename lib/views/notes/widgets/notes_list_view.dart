import 'package:crud_fiesta/constants/app_routes.dart';
import 'package:crud_fiesta/services/crud/notes_service.dart';
import 'package:crud_fiesta/utilities/dialogs/delete_dialog.dart';
import 'package:flutter/material.dart';

typedef DeleteNoteCallback = void Function(DatabaseNote note);

class NotesListView extends StatelessWidget {
  final List<DatabaseNote> notes;
  final DeleteNoteCallback onDeleteNote;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: ((context, index) {
        final note = notes[index];
        return ListTile(
          title: Text(
            note.noteText,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) {
                onDeleteNote(note);
              }
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.redAccent,
            ),
          ),
          onTap: () => Navigator.pushNamed(
            context,
            updateNoteRoute,
            arguments: {'note': note},
          ),
        );
      }),
    );
  }
}