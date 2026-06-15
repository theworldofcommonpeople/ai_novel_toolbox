/// 小说项目模型
///
/// 表示一个完整的小说创作项目，包含项目名称、时间戳和当前写作进度。
/// 每个项目可包含多个章节（参见 [ChapterModel]）。
class NovelProject {
  /// 项目唯一标识（数据库自增主键），新建时为 null。
  final int? id;

  /// 项目名称，必填。
  final String projectName;

  /// 创建时间（毫秒级 Unix 时间戳）。
  final int createdAt;

  /// 最后更新时间（毫秒级 Unix 时间戳）。
  final int updatedAt;

  /// 当前正在编辑或最新完成的章节编号，默认为 1。
  final int currentChapter;

  const NovelProject({
    this.id,
    required this.projectName,
    required this.createdAt,
    required this.updatedAt,
    this.currentChapter = 1,
  });

  // ============================================================
  // 序列化
  // ============================================================

  /// 将实例转换为 Map，便于存入数据库或序列化。
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_name': projectName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'current_chapter': currentChapter,
    };
  }

  /// 从 Map 构建实例，通常用于从数据库查询结果反序列化。
  factory NovelProject.fromMap(Map<String, dynamic> map) {
    return NovelProject(
      id: map['id'] as int?,
      projectName: map['project_name'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      currentChapter: (map['current_chapter'] as int?) ?? 1,
    );
  }

  // ============================================================
  // 不可变更新
  // ============================================================

  /// 创建当前实例的副本，同时允许覆盖指定字段。
  NovelProject copyWith({
    int? id,
    String? projectName,
    int? createdAt,
    int? updatedAt,
    int? currentChapter,
  }) {
    return NovelProject(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentChapter: currentChapter ?? this.currentChapter,
    );
  }

  // ============================================================
  // 调试与比较
  // ============================================================

  @override
  String toString() {
    return 'NovelProject(id: $id, projectName: $projectName, '
        'currentChapter: $currentChapter, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NovelProject &&
        other.id == id &&
        other.projectName == projectName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.currentChapter == currentChapter;
  }

  @override
  int get hashCode {
    return Object.hash(id, projectName, createdAt, updatedAt, currentChapter);
  }
}

// ============================================================================
// ChapterModel — 章节模型
// ============================================================================

/// 章节模型
///
/// 表示小说项目中的一个章节，属于某个 [NovelProject]。
/// 存储章节的编号、标题、正文内容、字数统计及更新时间。
class ChapterModel {
  /// 章节唯一标识（数据库自增主键），新建时为 null。
  final int? id;

  /// 所属项目 ID，必填，用于关联 [NovelProject]。
  final int projectId;

  /// 章节编号（第几章），必填，同一项目内应保持递增且不重复。
  final int chapterNumber;

  /// 章节标题，可为 null（表示未命名章节）。
  final String? title;

  /// 章节正文内容，可为 null（表示尚未开始写作）。
  final String? content;

  /// 章节字数统计，可为 null；业务层在保存时应根据 content 自动计算。
  final int? wordCount;

  /// 最后更新时间（毫秒级 Unix 时间戳）。
  final int updatedAt;

  const ChapterModel({
    this.id,
    required this.projectId,
    required this.chapterNumber,
    this.title,
    this.content,
    this.wordCount,
    required this.updatedAt,
  });

  // ============================================================
  // 序列化
  // ============================================================

  /// 将实例转换为 Map，便于存入数据库或序列化。
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'chapter_number': chapterNumber,
      'title': title,
      'content': content,
      'word_count': wordCount,
      'updated_at': updatedAt,
    };
  }

  /// 从 Map 构建实例，通常用于从数据库查询结果反序列化。
  factory ChapterModel.fromMap(Map<String, dynamic> map) {
    return ChapterModel(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      chapterNumber: map['chapter_number'] as int,
      title: map['title'] as String?,
      content: map['content'] as String?,
      wordCount: map['word_count'] as int?,
      updatedAt: map['updated_at'] as int,
    );
  }

  // ============================================================
  // 不可变更新
  // ============================================================

  /// 创建当前实例的副本，同时允许覆盖指定字段。
  ///
  /// 对于可空字段，通过 `clear*` 参数可将对应字段显式置为 null。
  ChapterModel copyWith({
    int? id,
    int? projectId,
    int? chapterNumber,
    String? title,
    String? content,
    int? wordCount,
    int? updatedAt,
    bool clearTitle = false,
    bool clearContent = false,
    bool clearWordCount = false,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: clearTitle ? null : (title ?? this.title),
      content: clearContent ? null : (content ?? this.content),
      wordCount: clearWordCount ? null : (wordCount ?? this.wordCount),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // 调试与比较
  // ============================================================

  @override
  String toString() {
    return 'ChapterModel(id: $id, projectId: $projectId, '
        'chapterNumber: $chapterNumber, title: $title, '
        'wordCount: $wordCount, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterModel &&
        other.id == id &&
        other.projectId == projectId &&
        other.chapterNumber == chapterNumber &&
        other.title == title &&
        other.content == content &&
        other.wordCount == wordCount &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      projectId,
      chapterNumber,
      title,
      content,
      wordCount,
      updatedAt,
    );
  }
}