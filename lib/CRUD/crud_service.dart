import 'dart:async';
import 'package:contacts/CRUD/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Contact {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final bool isFavorite;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.isFavorite = false,
  });
  Map<String, dynamic> toMap() {
    return {
      idColumn: id,
      nameColumn: name,
      phoneNoColumn: phone,
      emailColumn: email,
      addressColumn: address,
      favoriteColumn: isFavorite ? 1 : 0,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map[idColumn],
      name: map[nameColumn],
      phone: map[phoneNoColumn],
      email: map[emailColumn]??'',
      address: map[addressColumn]??'',
      isFavorite: map[favoriteColumn] == 1,
    );
  }
}

class DbService {
  Database? _db;
  late final StreamController<List<Contact>> contactsStreamer;
  List<Contact> _allContacts = [];
  DbService() {
    contactsStreamer = StreamController<List<Contact>>.broadcast(onListen: () {
      contactsStreamer.sink.add(_allContacts);
    });
  }
  Future<void> _catcheContacts() async {
    final allContacts = await getAllContacts();
    _allContacts = allContacts;
    contactsStreamer.sink.add(_allContacts);
  }

  Future<void> dbMustBeOpen() async {
    try {
      await initDatabase();
      // ignore: empty_catches
    } on DatabaseIsAlreadyOpened {}
  }

  Database getDb() {
    final db = _db;
    if (db != null) {
      return db;
    } else {
      throw DatabaseIsNotOpened();
    }
  }

  Future<void> initDatabase() async {
    if (_db != null) throw DatabaseIsAlreadyOpened();

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'contacts.db');
    _db = await openDatabase(
      path,
    );
    await _db?.execute(createContactsTable);
    _catcheContacts();
  }
  Future<void> close() async {
  await contactsStreamer.close();
  final db = _db;
  if (db != null) {
    await db.close();
    _db = null;
  }
}


  Future<Contact> addContact(Contact contact) async {
    await dbMustBeOpen();
    final db = getDb();
    final result = await db.query(contactsTable,
        limit: 1, where: 'phone=?', whereArgs: [contact.phone]);
    if (result.isNotEmpty) {
      throw UserAlreadyRegistered();
    }
    final id = await db.insert(contactsTable, contact.toMap());
    final createdContact = Contact(
      id: id,
      name: contact.name,
      phone: contact.phone,
      email: contact.email,
      address: contact.address,
      isFavorite: contact.isFavorite,
    );
    _allContacts.add(createdContact);
    contactsStreamer.sink.add(_allContacts);
    return createdContact;
  }

  Future<int> deleteContact(int id) async {
    await dbMustBeOpen();
    final db = getDb();
    final deletes =
        await db.delete(contactsTable, where: 'id = ?', whereArgs: [id]);
    _allContacts.removeWhere((contact) => (contact.id == id));
    contactsStreamer.sink.add(_allContacts);
    return deletes;
  }

  Future<List<Contact>> getAllContacts() async {
    await dbMustBeOpen();
    final db = getDb();
    final List<Map<String, dynamic>> result = await db.query(contactsTable);
    return List.generate(result.length, (i) => Contact.fromMap(result[i]));
  }
}

const idColumn = 'id';
const nameColumn = 'name';
const phoneNoColumn = 'phone';
const emailColumn = 'email';
const addressColumn = 'address';
const favoriteColumn = 'favorite';
const contactsTable = 'contacts';
const createContactsTable = '''CREATE TABLE  IF NOT EXISTS "contacts" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL,
        "phone" TEXT NOT NULL UNIQUE,
        "email" TEXT,
        "address" TEXT,
        "favorite" INTEGER DEFAULT 0
      )''';
