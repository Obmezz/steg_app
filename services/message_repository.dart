import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MessageRepository {

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {

    final path = join(await getDatabasesPath(), 'chat.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT,
            type TEXT,
            imagePath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE contacts(
            name TEXT PRIMARY KEY,
            publicKey TEXT,
            fingerprint TEXT,
            isVerified INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE contacts(
              name TEXT PRIMARY KEY,
              publicKey TEXT,
              fingerprint TEXT,
              isVerified INTEGER
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE messages ADD COLUMN imagePath TEXT');
        }
      },
    );
  }

  // --- Contacts ---
  Future<void> insertContact(Map<String, dynamic> contact) async {
    final database = await db;
    await database.insert('contacts', contact, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final database = await db;
    return await database.query('contacts');
  }

  Future<void> deleteContact(String name) async {
    final database = await db;
    await database.delete('contacts', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> updateContact(String oldName, Map<String, dynamic> contact) async {
    final database = await db;
    await database.update('contacts', contact, where: 'name = ?', whereArgs: [oldName]);
  }

  Future<void> insert(String data, String type, {String? imagePath}) async {
    final database = await db;

    await database.insert(
      'messages',
      {
        'data': data,
        'type': type,
        'imagePath': imagePath,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final database = await db;
    return await database.query('messages', orderBy: 'id DESC');
  }

  Future<void> clearMessages() async {
    final database = await db;
    await database.delete('messages');
  }
}