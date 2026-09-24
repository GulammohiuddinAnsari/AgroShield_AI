import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agroshield.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Bumped version to trigger schema updates
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Handles updates for existing database installs
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create the remedies table
    await db.execute('''
      CREATE TABLE remedies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disease_name TEXT,
        plant_name TEXT,
        severity TEXT,
        treatment TEXT,
        prevention TEXT,
        iot_action TEXT
      )
    ''');

    // 2. Create the scan history table
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT,
        disease_name TEXT,
        confidence REAL,
        timestamp TEXT
      )
    ''');

    // 3. Pre-populate all 6 classes for Potato and Tomato
    await db.insert('remedies', {
      'disease_name': 'Potato___Early_blight',
      'plant_name': 'Potato',
      'severity': 'Moderate',
      'treatment': 'Apply copper-based fungicides. Remove and destroy infected lower leaves.',
      'prevention': 'Use certified disease-free tubers and rotate crops annually.',
      'iot_action': 'Turn on automated drip irrigation to keep foliage completely dry.'
    });

    await db.insert('remedies', {
      'disease_name': 'Potato___Late_blight',
      'plant_name': 'Potato',
      'severity': 'High',
      'treatment': 'Apply systemic fungicides immediately. Destroy severely infected plants to stop spread.',
      'prevention': 'Avoid overhead watering and ensure proper plant-to-plant spacing.',
      'iot_action': 'Trigger greenhouse exhaust fans to aggressively reduce humidity.'
    });

    await db.insert('remedies', {
      'disease_name': 'Potato___healthy',
      'plant_name': 'Potato',
      'severity': 'None',
      'treatment': 'No treatment needed. The crop is healthy.',
      'prevention': 'Maintain regular monitoring and balanced fertilization.',
      'iot_action': 'Standard soil moisture tracking active.'
    });

    await db.insert('remedies', {
      'disease_name': 'Tomato___Early_blight',
      'plant_name': 'Tomato',
      'severity': 'Moderate',
      'treatment': 'Apply chlorothalonil or copper fungicide every 7 to 10 days.',
      'prevention': 'Prune lower leaves to improve air circulation and mulch soil to prevent splash.',
      'iot_action': 'Activate smart greenhouse ventilation to lower canopy moisture.'
    });

    await db.insert('remedies', {
      'disease_name': 'Tomato___Late_blight',
      'plant_name': 'Tomato',
      'severity': 'Critical',
      'treatment': 'Apply metalaxyl or copper-based fungicides. Remove and burn infected plants.',
      'prevention': 'Plant resistant tomato varieties and avoid working with wet plants.',
      'iot_action': 'Trigger emergency heating elements or fans to dry out the canopy.'
    });

    await db.insert('remedies', {
      'disease_name': 'Tomato___healthy',
      'plant_name': 'Tomato',
      'severity': 'None',
      'treatment': 'No treatment needed. Plant looks vibrant and healthy.',
      'prevention': 'Continue standard watering and nutrient management schedules.',
      'iot_action': 'Standard soil moisture tracking active.'
    });

    await db.execute('''
  CREATE TABLE iot_history(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    alert_text TEXT,
    timestamp TEXT
  )
''');
  }

  // Automatically runs when database version is incremented on an existing device
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT,
          disease_name TEXT,
          confidence REAL,
          timestamp TEXT
        )
      ''');
    }
  }

  // Query remedy method
  Future<Map<String, dynamic>> getRemedyForDisease(String diseaseName) async {
    final db = await database;
    String cleanName = diseaseName.replaceAll('\r', '').trim();

    List<Map<String, dynamic>> results = await db.query(
      'remedies',
      where: 'TRIM(disease_name) = ?',
      whereArgs: [cleanName],
    );

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return {
        'plant_name': 'Unknown Plant',
        'severity': 'Normal',
        'treatment': 'Monitor plant health and consult a local agricultural expert.',
        'prevention': 'Ensure proper spacing and regular watering.',
        'iot_action': 'Standard monitoring active.'
      };
    }
  }

  // Insert into timeline history
  Future<int> insertScanHistory(String imagePath, String diseaseName, double confidence) async {
    final db = await database;
    return await db.insert('scan_history', {
      'image_path': imagePath,
      'disease_name': diseaseName,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Fetch timeline history
  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final db = await database;
    return await db.query('scan_history', orderBy: 'id DESC');
  }

  Future<int> deleteScanHistory(int id) async {
  final db = await database;
  return await db.delete(
    'scan_history',
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Insert an IoT alert into SQLite when swiped away
Future<int> insertIoTAlert(String alertText) async {
  final db = await database;
  return await db.insert('iot_history', {
    'alert_text': alertText,
    'timestamp': DateTime.now().toIso8601String(),
  });
}

// Fetch all saved IoT alerts for the history timeline screen
Future<List<Map<String, dynamic>>> getIoTAlerts() async {
  final db = await database;
  return await db.query('iot_history', orderBy: 'id DESC');
}
}