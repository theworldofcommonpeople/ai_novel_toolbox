import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/api_config.dart';
import '../models/character_card.dart';
import '../models/entity_relation.dart';
import '../models/generation_history.dart';
import '../models/novel_project.dart';

/// 本地 SQLite 存储服务（单例模式）
///
/// 管理应用所有持久化数据的增删改查，包括：
/// - API 配置
/// - 生成历史
/// - 角色卡牌
/// - 文档分块
/// - 实体关系
/// - 本地模型
/// - 小说项目
/// - 章节
class StorageService {
  // ============================================================
  // 单例
  // ============================================================

  static StorageService? _instance;
  static Database? _database;

  StorageService._internal();

  factory StorageService() {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  /// 获取已初始化的单例实例（调用方必须确保 [initialize] 已执行）。
  static StorageService get instance {
    assert(
      _instance != null,
      'StorageService 尚未初始化，请先调用 StorageService.initialize()',
    );
    return _instance!;
  }

  // ============================================================
  // 数据库路径 & 初始化
  // ============================================================

  static const String _dbName = 'ai_novel_toolbox.db';
  static const int _dbVersion = 1;

  /// 由外部（如 main.dart）传入数据库路径后调用。
  /// 通常在 `getDatabasesPath()` 拼接后完成。
  static Future<StorageService> initialize(String databasesPath) async {
    final instance = StorageService();
    final dbPath = p.join(databasesPath, _dbName);
    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return instance;
  }

  // ============================================================
  // Schema 创建
  // ============================================================

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE api_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text_base_url TEXT,
        text_api_key TEXT,
        text_model_name TEXT,
        image_base_url TEXT,
        image_api_key TEXT,
        image_model_name TEXT,
        use_cloud_first INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE generation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        generator_type TEXT,
        input_params TEXT,
        output TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        card_json TEXT NOT NULL,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE doc_chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER,
        chunk_text TEXT,
        embedding BLOB,
        start_pos INTEGER,
        end_pos INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE entity_relations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_name TEXT,
        entity_type TEXT,
        related_entity TEXT,
        relation_type TEXT,
        chapter_ref INTEGER,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_model (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_path TEXT,
        is_loaded INTEGER DEFAULT 0,
        last_used INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE novel_projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_name TEXT,
        created_at INTEGER,
        updated_at INTEGER,
        current_chapter INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        chapter_number INTEGER,
        title TEXT,
        content TEXT,
        word_count INTEGER,
        updated_at INTEGER
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级逻辑在此添加
  }

  // ============================================================
  // 内部工具
  // ============================================================

  Database get _db {
    assert(_database != null, '数据库未初始化，请先调用 StorageService.initialize()');
    return _database!;
  }

  // ============================================================
  // API 配置
  // ============================================================

  /// 获取所有 API 配置记录。
  Future<List<ApiConfig>> getAllApiConfigs() async {
    final maps = await _db.query('api_config');
    return maps.map((m) => ApiConfig.fromMap(m)).toList();
  }

  /// 保存（插入或更新）一条 API 配置。
  Future<int> saveApiConfig(ApiConfig config) async {
    if (config.id != null) {
      return await _db.update(
        'api_config',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [config.id],
      );
    } else {
      return await _db.insert('api_config', config.toMap());
    }
  }

  /// 删除指定 ID 的 API 配置。
  Future<int> deleteApiConfig(int id) async {
    return await _db.delete('api_config', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // 生成历史
  // ============================================================

  /// 获取所有生成历史记录（按时间倒序）。
  Future<List<GenerationHistory>> getGenerationHistory() async {
    final maps = await _db.query(
      'generation_history',
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => GenerationHistory.fromMap(m)).toList();
  }

  /// 保存一条生成历史记录。
  Future<int> saveGenerationHistory(GenerationHistory history) async {
    if (history.id != null) {
      return await _db.update(
        'generation_history',
        history.toMap(),
        where: 'id = ?',
        whereArgs: [history.id],
      );
    } else {
      return await _db.insert('generation_history', history.toMap());
    }
  }

  /// 删除指定 ID 的生成历史记录。
  Future<int> deleteGenerationHistory(int id) async {
    return await _db.delete(
      'generation_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // 角色卡牌
  // ============================================================

  /// 获取所有角色。
  Future<List<CharacterCard>> getAllCharacters() async {
    final maps = await _db.query('characters', orderBy: 'name ASC');
    return maps.map((m) => CharacterCard.fromMap(m)).toList();
  }

  /// 保存（插入或更新）一个角色。
  ///
  /// 若 name 已存在（违反 UNIQUE 约束），则转为更新操作。
  Future<int> saveCharacter(CharacterCard character) async {
    if (character.id != null) {
      return await _db.update(
        'characters',
        character.toMap(),
        where: 'id = ?',
        whereArgs: [character.id],
      );
    } else {
      // 先检查 name 是否已存在
      final existing = await getCharacterByName(character.name);
      if (existing != null) {
        final updated = character.copyWith(
          id: existing.id,
          createdAt: existing.createdAt,
        );
        return await _db.update(
          'characters',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      }
      return await _db.insert('characters', character.toMap());
    }
  }

  /// 按名称查找角色。
  Future<CharacterCard?> getCharacterByName(String name) async {
    final maps = await _db.query(
      'characters',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CharacterCard.fromMap(maps.first);
  }

  /// 删除指定 ID 的角色。
  Future<int> deleteCharacter(int id) async {
    return await _db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // 小说项目
  // ============================================================

  /// 获取所有小说项目（按更新时间倒序）。
  Future<List<NovelProject>> getAllNovelProjects() async {
    final maps = await _db.query(
      'novel_projects',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => NovelProject.fromMap(m)).toList();
  }

  /// 保存（插入或更新）一个小说项目。
  Future<int> saveNovelProject(NovelProject project) async {
    if (project.id != null) {
      return await _db.update(
        'novel_projects',
        project.toMap(),
        where: 'id = ?',
        whereArgs: [project.id],
      );
    } else {
      return await _db.insert('novel_projects', project.toMap());
    }
  }

  // ============================================================
  // 章节
  // ============================================================

  /// 获取指定项目下的所有章节（按章节编号升序）。
  Future<List<ChapterModel>> getChaptersByProjectId(int projectId) async {
    final maps = await _db.query(
      'chapters',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'chapter_number ASC',
    );
    return maps.map((m) => ChapterModel.fromMap(m)).toList();
  }

  /// 保存（插入或更新）一个章节。
  Future<int> saveChapter(ChapterModel chapter) async {
    if (chapter.id != null) {
      return await _db.update(
        'chapters',
        chapter.toMap(),
        where: 'id = ?',
        whereArgs: [chapter.id],
      );
    } else {
      return await _db.insert('chapters', chapter.toMap());
    }
  }

  /// 根据项目 ID 和章节编号查找章节。
  Future<ChapterModel?> getChapterByProjectAndNumber(
    int projectId,
    int chapterNumber,
  ) async {
    final maps = await _db.query(
      'chapters',
      where: 'project_id = ? AND chapter_number = ?',
      whereArgs: [projectId, chapterNumber],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChapterModel.fromMap(maps.first);
  }

  // ============================================================
  // 实体关系
  // ============================================================

  /// 获取所有实体关系记录。
  Future<List<EntityRelation>> getAllEntities() async {
    final maps = await _db.query('entity_relations');
    return maps.map((m) => EntityRelation.fromMap(m)).toList();
  }

  /// 保存一条实体关系。
  Future<int> saveEntityRelation(EntityRelation relation) async {
    if (relation.id != null) {
      return await _db.update(
        'entity_relations',
        relation.toMap(),
        where: 'id = ?',
        whereArgs: [relation.id],
      );
    } else {
      return await _db.insert('entity_relations', relation.toMap());
    }
  }

  /// 删除指定 ID 的实体关系。
  Future<int> deleteEntityRelation(int id) async {
    return await _db.delete(
      'entity_relations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // 文档分块（RAG）
  // ============================================================

  /// 获取指定章节的所有文档分块。
  Future<List<Map<String, dynamic>>> getDocChunksByChapterId(int chapterId) async {
    return await _db.query(
      'doc_chunks',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'start_pos ASC',
    );
  }

  /// 保存一条文档分块记录。
  Future<int> saveDocChunk(Map<String, dynamic> chunk) async {
    if (chunk['id'] != null) {
      return await _db.update(
        'doc_chunks',
        chunk,
        where: 'id = ?',
        whereArgs: [chunk['id']],
      );
    } else {
      return await _db.insert('doc_chunks', chunk);
    }
  }

  /// 删除指定章节的所有文档分块（重新索引前清理）。
  Future<int> deleteDocChunksByChapterId(int chapterId) async {
    return await _db.delete(
      'doc_chunks',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  // ============================================================
  // 本地模型配置
  // ============================================================

  /// 获取本地模型配置（通常只有一条记录）。
  Future<Map<String, dynamic>?> getLocalModel() async {
    final maps = await _db.query('local_model', limit: 1);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// 保存本地模型配置。
  Future<int> saveLocalModel(Map<String, dynamic> model) async {
    final existing = await _db.query('local_model', limit: 1);
    if (existing.isNotEmpty) {
      final merged = {...existing.first, ...model, 'id': existing.first['id']};
      return await _db.update(
        'local_model',
        merged,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await _db.insert('local_model', model);
    }
  }
}