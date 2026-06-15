/// 角色卡牌模型
///
/// 用于存储小说创作中每个角色的完整信息。
/// [cardJson] 字段以 JSON 字符串形式保存角色的详细设定，
/// 便于灵活扩展角色属性而无需频繁修改数据库表结构。
class CharacterCard {
  /// 角色卡牌的唯一标识（数据库自增主键），新建时为 null。
  final int? id;

  /// 角色名称，必填。
  final String name;

  /// 角色完整信息的 JSON 字符串。
  /// 包含角色的外貌、性格、背景故事、与其他角色的关系等所有设定。
  final String cardJson;

  /// 创建时间（毫秒级 Unix 时间戳）。
  final int createdAt;

  /// 最后更新时间（毫秒级 Unix 时间戳）。
  final int updatedAt;

  const CharacterCard({
    this.id,
    required this.name,
    required this.cardJson,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // 序列化
  // ============================================================

  /// 将实例转换为 Map，便于存入数据库或序列化。
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'card_json': cardJson,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// 从 Map 构建实例，通常用于从数据库查询结果反序列化。
  factory CharacterCard.fromMap(Map<String, dynamic> map) {
    return CharacterCard(
      id: map['id'] as int?,
      name: map['name'] as String,
      cardJson: map['card_json'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  // ============================================================
  // 不可变更新
  // ============================================================

  /// 创建当前实例的副本，同时允许覆盖指定字段。
  CharacterCard copyWith({
    int? id,
    String? name,
    String? cardJson,
    int? createdAt,
    int? updatedAt,
  }) {
    return CharacterCard(
      id: id ?? this.id,
      name: name ?? this.name,
      cardJson: cardJson ?? this.cardJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // 调试与比较
  // ============================================================

  @override
  String toString() {
    return 'CharacterCard(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterCard &&
        other.id == id &&
        other.name == name &&
        other.cardJson == cardJson &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, cardJson, createdAt, updatedAt);
  }
}