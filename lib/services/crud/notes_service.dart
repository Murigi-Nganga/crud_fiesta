import 'dart:async' show StreamController;

import 'package:flutter/material.dart' show immutable;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory, MissingPlatformDirectoryException;
import 'package:sqflite/sqflite.dart' show Database, openDatabase;

import 'crud_exceptions.dart';

class NotesService {
  Database? _db;

  DatabaseUser? _user;

  //Local list of Database Notes

  List<DatabaseNote> _dbNotes = [];

//? To make the class a Singleton
  static final NotesService _shared = NotesService._sharedInstance();

  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_dbNotes);
      },
    );
  }

  factory NotesService() => _shared;
//? To make the class a Singleton

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _dbNotes = allNotes.toList();
    _notesStreamController.add(_dbNotes);
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      _user = user;
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      _user = createdUser;
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  //* USER FUNCTIONS
  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final user = await db.query(
      usersTable,
      limit: 1,
      where: '$userEmailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (user.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(usersTable, {
      userEmailColumn: email,
    });

    return DatabaseUser(userId: userId, userEmail: email);
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: '$userEmailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    }

    return DatabaseUser.fromRow(results.first);
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      usersTable,
      where: '$userEmailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  //* NOTES FUNCTIONS
  Future<DatabaseNote> createNote(
      {required DatabaseUser owner, required String text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(email: owner.userEmail);

    //making sure the owner exists in the database with the correct id
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    final noteId = await db.insert(notesTable, {
      noteTextColumn: text,
      userIdColumn: owner.userId,
      noteIsSyncedWithCloudColumn: 1
    });

    final note = DatabaseNote(
      noteId: noteId,
      noteText: text,
      userId: owner.userId,
      isSyncedWithCloud: true,
    );

    _dbNotes.add(note);
    //* Cache the note after creating it
    _notesStreamController.add(_dbNotes);

    return note;
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNote(id: note.noteId);

    final updatesCount = await db.update(
      notesTable,
      {
        noteTextColumn: text,
        noteIsSyncedWithCloudColumn: 0,
      },
      where: '$noteIdColumn = ?',
      whereArgs: [note.noteId],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    }

    final updatedNote = await getNote(id: note.noteId);
    _dbNotes.removeWhere((note) => note.noteId == updatedNote.noteId);
    _dbNotes.add(updatedNote);
    _notesStreamController.add(_dbNotes);
    return updatedNote;
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      notesTable,
      limit: 1,
      where: '$noteIdColumn = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      CouldNotFindNote();
    }

    final note = DatabaseNote.fromRow(notes.first);
    _dbNotes.removeWhere((note) => note.noteId == id);
    _dbNotes.add(note);
    _notesStreamController.add(_dbNotes);
    return note;
  }

  Future<List<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(notesTable);

    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow)).toList();
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      notesTable,
      where: '$noteIdColumn = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteNote();
    }

    _dbNotes.removeWhere((note) => note.noteId == id);
    _notesStreamController.add(_dbNotes);
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deleteCount = await db.delete(notesTable);
    _dbNotes = [];
    _notesStreamController.add(_dbNotes);
    return deleteCount;
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpen {
      //* mach nichts for now
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpen();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      // create the users table
      await db.execute(createUsersTableQuery);

      // create the notes table
      await db.execute(createNotesTableQuery);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocsDir();
    }
  }
}

@immutable
class DatabaseUser {
  final String userEmail;
  final int userId;

  const DatabaseUser({
    required this.userId,
    required this.userEmail,
  });

  DatabaseUser.fromRow(Map<String, Object?> data)
      : userId = data[userIdColumn] as int,
        userEmail = data[userEmailColumn] as String;

  @override
  String toString() => 'Person, Id = $userId, email = $userEmail';

  @override
  bool operator ==(covariant DatabaseUser other) => other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}

class DatabaseNote {
  final int noteId;
  final String noteText;
  final int userId;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.noteId,
    required this.noteText,
    required this.userId,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> data)
      : noteId = data[noteIdColumn] as int,
        noteText = data[noteTextColumn] as String, //* Foreign Key
        userId = data[userIdColumn] as int,
        isSyncedWithCloud =
            (data[noteIsSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, Id = $noteId, User ID = $userId, Is synced with cloud = $isSyncedWithCloud';

  @override
  bool operator ==(covariant DatabaseNote other) => other.noteId == noteId;

  @override
  int get hashCode => noteId.hashCode;
}

const dbName = 'notes.db';
const notesTable = 'notes';
const usersTable = 'users';

const userIdColumn = 'user_id';
const userEmailColumn = 'user_email';

const noteIdColumn = 'note_id';
const noteTextColumn = 'note_text';
const noteIsSyncedWithCloudColumn = 'is_synced_with_cloud';

const createUsersTableQuery = '''
    CREATE TABLE IF NOT EXISTS "$usersTable" (
      "$userIdColumn"	INTEGER NOT NULL UNIQUE,
      "$userEmailColumn"	TEXT NOT NULL UNIQUE,
      PRIMARY KEY("$userIdColumn" AUTOINCREMENT)
    );
  ''';

const createNotesTableQuery = '''
    CREATE TABLE IF NOT EXISTS "$notesTable" (
      "$noteIdColumn"	INTEGER NOT NULL UNIQUE,
      "$userIdColumn"	INTEGER NOT NULL,
      "$noteTextColumn"	TEXT NOT NULL,
      "$noteIsSyncedWithCloudColumn"	INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY("$noteIdColumn" AUTOINCREMENT),
      FOREIGN KEY("$userIdColumn") REFERENCES "$usersTable"("$userIdColumn")
    );
  ''';
