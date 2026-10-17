import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/taught_command.dart';

abstract class CommandStore {
  Future<List<TaughtCommand>> list();
  Future<TaughtCommand> add(String phrase, String response);
  Future<void> update(TaughtCommand command);
  Future<void> delete(int id);
}

/// Used by tests. Nothing is persisted.
class InMemoryCommandStore implements CommandStore {
  final List<TaughtCommand> _items = [];
  int _nextId = 1;

  @override
  Future<List<TaughtCommand>> list() async => List.unmodifiable(_items);

  @override
  Future<TaughtCommand> add(String phrase, String response) async {
    final c = TaughtCommand(id: _nextId++, phrase: phrase, response: response);
    _items.add(c);
    return c;
  }

  @override
  Future<void> update(TaughtCommand command) async {
    final i = _items.indexWhere((c) => c.id == command.id);
    if (i >= 0) _items[i] = command;
  }

  @override
  Future<void> delete(int id) async => _items.removeWhere((c) => c.id == id);
}

/// On-device SQLite storage. Data never leaves the phone.
class SqliteCommandStore implements CommandStore {
  SqliteCommandStore._(this._db);

  final Database _db;

  static Future<SqliteCommandStore> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'jarvis.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE commands ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'phrase TEXT NOT NULL, '
        'response TEXT NOT NULL)',
      ),
    );
    return SqliteCommandStore._(db);
  }

  @override
  Future<List<TaughtCommand>> list() async {
    final rows = await _db.query('commands', orderBy: 'id ASC');
    return rows.map(TaughtCommand.fromMap).toList();
  }

  @override
  Future<TaughtCommand> add(String phrase, String response) async {
    final id = await _db.insert(
        'commands', {'phrase': phrase, 'response': response});
    return TaughtCommand(id: id, phrase: phrase, response: response);
  }

  @override
  Future<void> update(TaughtCommand command) async {
    await _db.update('commands', command.toMap(),
        where: 'id = ?', whereArgs: [command.id]);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('commands', where: 'id = ?', whereArgs: [id]);
  }
}
