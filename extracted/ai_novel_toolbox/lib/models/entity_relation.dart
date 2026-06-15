/// 实体关系模型
///
/// 用于构建小说知识图谱中的实体关系边。
/// 每个 [EntityRelation] 实例表示两个实体（人物、地点、物品、伏笔）之间的一条关系，
/// 所有关系共同构成小说的知识网络，辅助 AI 保持写作一致性。
class EntityRelation {
  /// 关系记录的唯一标识（数据库自增主键），新建时为 null。
  final int? id;

  /// 主体实体名称，必填。
  final String entityName;

  /// 主体实体类型，必填。
  ///
  /// 可选值：
  /// - `person`   —— 人物
  /// - `place`    —— 地点
  /// - `item`     —— 物品
  /// - `foreshadow` —— 伏笔
  final String entityType;

  /// 关联的目标实体名称。
  /// 当关系无需指向具体实体时（如某些单向描述），可为 null。
  final String? relatedEntity;

  /// 关系类型，必填。
  ///
  /// 可选值：
  /// - `friend`    —— 朋友关系
  /// - `enemy`     —— 敌对关系
  /// - `own`       —— 拥有/从属关系
  /// - `promise`   —— 承诺/约定关系
  /// - 可根据业务需要扩展更多类型。
  final String relationType;

  /// 该关系首次出现或重点引用的章节编号，可为 null。
  final int? chapterRef;

  /// 关系的文字描述，补充说明关系的具体内容，可为 null。
  final String? description;

  const EntityRelation({
    this.id,
    required this.entityName,
    required this.entityType,
    this.relatedEntity,
    required this.relationType,
    this.chapterRef,
    this.description,
  });

  // ============================================================
  // 序列化
  // ============================================================

  /// 将实例转换为 Map，便于存入数据库或序列化。
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entity_name': entityName,
      'entity_type': entityType,
      'related_entity': relatedEntity,
      'relation_type': relationType,
      'chapter_ref': chapterRef,
      'description': description,
    };
  }

  /// 从 Map 构建实例，通常用于从数据库查询结果反序列化。
  factory EntityRelation.fromMap(Map<String, dynamic> map) {
    return EntityRelation(
      id: map['id'] as int?,
      entityName: map['entity_name'] as String,
      entityType: map['entity_type'] as String,
      relatedEntity: map['related_entity'] as String?,
      relationType: map['relation_type'] as String,
      chapterRef: map['chapter_ref'] as int?,
      description: map['description'] as String?,
    );
  }

  // ============================================================
  // 不可变更新
  // ============================================================

  /// 创建当前实例的副本，同时允许覆盖指定字段。
  EntityRelation copyWith({
    int? id,
    String? entityName,
    String? entityType,
    String? relatedEntity,
    String? relationType,
    int? chapterRef,
    String? description,
    // 显式传入 null 以清除可空字段的专用标记
    bool clearRelatedEntity = false,
    bool clearChapterRef = false,
    bool clearDescription = false,
  }) {
    return EntityRelation(
      id: id ?? this.id,
      entityName: entityName ?? this.entityName,
      entityType: entityType ?? this.entityType,
      relatedEntity:
          clearRelatedEntity ? null : (relatedEntity ?? this.relatedEntity),
      relationType: relationType ?? this.relationType,
      chapterRef:
          clearChapterRef ? null : (chapterRef ?? this.chapterRef),
      description:
          clearDescription ? null : (description ?? this.description),
    );
  }

  // ============================================================
  // 调试与比较
  // ============================================================

  @override
  String toString() {
    return 'EntityRelation(id: $id, entityName: $entityName, entityType: $entityType, '
        'relatedEntity: $relatedEntity, relationType: $relationType, chapterRef: $chapterRef)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntityRelation &&
        other.id == id &&
        other.entityName == entityName &&
        other.entityType == entityType &&
        other.relatedEntity == relatedEntity &&
        other.relationType == relationType &&
        other.chapterRef == chapterRef &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      entityName,
      entityType,
      relatedEntity,
      relationType,
      chapterRef,
      description,
    );
  }
}