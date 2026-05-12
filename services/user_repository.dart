import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserRepository {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'users.db');
    return openDatabase(
      path,
      version: 3, // Incremented version to add security question
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            username TEXT PRIMARY KEY,
            fullName TEXT,
            age INTEGER,
            password TEXT,
            profilePicture TEXT,
            securityQuestion TEXT,
            securityAnswer TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE users ADD COLUMN profilePicture TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE users ADD COLUMN securityQuestion TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN securityAnswer TEXT');
        }
      },
    );
  }

  Future<bool> hasUsers() async {
    final database = await db;
    final count = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM users'));
    return (count ?? 0) > 0;
  }

  Future<void> register({
    required String username,
    required String fullName,
    required int age,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final database = await db;
    if (await hasUsers()) {
      throw Exception("This device already has a registered account.");
    }
    await database.insert(
      'users',
      {
        'username': username,
        'fullName': fullName,
        'age': age,
        'password': password,
        'profilePicture': null,
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer,
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> updateProfile(String oldUsername, String newUsername, String? profilePicture) async {
    final database = await db;
    await database.update(
      'users',
      {
        'username': newUsername,
        'profilePicture': profilePicture,
      },
      where: 'username = ?',
      whereArgs: [oldUsername],
    );
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> resetPassword(String username, String newPassword) async {
    final database = await db;
    await database.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }
}
