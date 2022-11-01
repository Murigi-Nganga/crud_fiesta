import 'package:flutter/material.dart';

import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/verify_email.dart';
import '../views/notes/new_note_view.dart';
import '../views/notes/notes_view.dart';
import '../views/notes/update_note_view.dart';

const loginRoute = '/login/';
const registerRoute = '/register/';
const notesRoute = '/notes/';
const verifyEmailRoute = '/verify-email/';
const newNoteRoute = '/notes/new-note/';
const updateNoteRoute = '/notes/update-note/';

Map<String, Widget Function(BuildContext)> appRoutes = {
  loginRoute: (context) => const LoginView(),
  registerRoute: (context) => const RegisterView(),
  notesRoute: (context) => const NotesView(),
  verifyEmailRoute: (context) => const VerifyEmailView(),
  newNoteRoute: (context) => const NewNoteView(),
  updateNoteRoute: (context) => const UpdateNoteView(),
};
