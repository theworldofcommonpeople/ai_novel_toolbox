import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../models/entity_relation.dart';
import 'storage_service.dart';

/// RAG（检索增强生成）服务
///
/// 负责将章节文本切分为块、生成向量嵌入并进行相似度检索，
/// 为 AI 写作提供上下文相关的前文信息。
///
/// 嵌入方案：
/// - 若 flutter_llama 支持嵌入提取，则使用模型嵌入；
/// - 当前使用 TF-IDF 风格的 Bag-of-Words 向量作为轻量替代，
///   无需外部向量数据库即可完成相似度计算。
class RagService {
  final StorageService _storage;

  /// 分块大小（字符数）
  static const int _chunkSize = 500;

  /// 相邻分块重叠字符数
  static const int _chunkOverlap = 50;

  /// 中文停用词列表（部分高频词）
  static const Set<String> _stopWords = {
    '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一',
    '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着',
    '没有', '看', '好', '自己', '这', '他', '她', '它', '们', '那', '些',
    '什么', '怎么', '如何', '因为', '所以', '但是', '然而', '虽然', '可以',
    '这个', '那个', '还', '被', '把', '让', '从', '与', '或', '而', '且',
    '吗', '呢', '吧', '啊', '哦', '嗯', '哈', '呀', '哇', '嘛',
  };

  RagService({StorageService? storage})
      : _storage = storage ?? StorageService.instance;

  // ============================================================
  // 索引
  // ============================================================

  /// 对指定章节的文本进行分块并生成索引。
  ///
  /// 1. 删除该章节已有的旧索引记录；
  /// 2. 按 [_chunkSize] 分块，块之间 [_chunkOverlap] 字符重叠；
  /// 3. 为每个块计算 TF-IDF 向量并存入 doc_chunks 表。
  Future<void> indexChapter(int chapterId, int projectId, String content) async {
    if (content.isEmpty) return;

    // 清理旧索引
    await _storage.deleteDocChunksByChapterId(chapterId);

    final chunks = _splitIntoChunks(content);

    // 为所有块构建全局词汇表
    final allTokens = <String>{};
    for (final chunk in chunks) {
      allTokens.addAll(_tokenize(chunk));
    }
    final vocabulary = allTokens.toList();

    // 计算 IDF
    final idf = _computeIdf(chunks, vocabulary);

    // 持久化每个分块
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final startPos = i * (_chunkSize - _chunkOverlap);
      final endPos = startPos + chunk.length;

      // 计算 TF-IDF 向量
      final tfidfVector = _computeTfidfVector(chunk, vocabulary, idf);
      // 序列化为字节数组存储
      final embeddingBytes = Float64List.fromList(tfidfVector).buffer.asUint8List();

      await _storage.saveDocChunk({
        'chapter_id': chapterId,
        'chunk_text': chunk,
        'embedding': embeddingBytes,
        'start_pos': startPos,
        'end_pos': endPos,
      });
    }
  }

  // ============================================================
  // 检索
  // ============================================================

  /// 搜索与 [query] 最相似的 topK 个文本块。
  ///
  /// 返回按相似度降序排列的文本块内容列表。
  Future<List<String>> searchSimilarChunks(
    String query,
    int projectId, {
    int topK = 5,
  }) async {
    if (query.isEmpty) return [];

    // 获取该项目的所有章节，再汇总所有分块
    final projectChapters = await _storage.getChaptersByProjectId(projectId);
    final allChunks = <Map<String, dynamic>>[];

    for (final chapter in projectChapters) {
      if (chapter.id == null) continue;
      final chunks = await _storage.getDocChunksByChapterId(chapter.id!);
      allChunks.addAll(chunks);
    }

    if (allChunks.isEmpty) return [];

    // 构建查询向量
    final queryTokens = _tokenize(query);

    // 构建全局词汇表（包含所有块和查询的 token）
    final allTokens = <String>{};
    allTokens.addAll(queryTokens);
    for (final chunk in allChunks) {
      final chunkText = chunk['chunk_text'] as String? ?? '';
      allTokens.addAll(_tokenize(chunkText));
    }
    final vocabulary = allTokens.toList();

    // 计算各块的 IDF
    final chunkTexts = allChunks
        .map((c) => c['chunk_text'] as String? ?? '')
        .toList();
    final idf = _computeIdf(chunkTexts, vocabulary);

    // 查询的 TF-IDF 向量
    final queryVector = _computeTfidfVector(query, vocabulary, idf);

    // 计算各块与查询的余弦相似度
    final scored = <_ScoredChunk>[];

    for (final chunk in allChunks) {
      final chunkText = chunk['chunk_text'] as String? ?? '';
      final chunkVector = _computeTfidfVector(chunkText, vocabulary, idf);
      final similarity = _cosineSimilarity(queryVector, chunkVector);
      scored.add(_ScoredChunk(chunkText, similarity));
    }

    // 按相似度降序排序
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).map((s) => s.text).toList();
  }

  /// 获取与查询相关的上下文文本。
  ///
  /// 拼接来自相似块的文本内容和相关的实体关系描述。
  Future<String> getRelevantContext(String query, int projectId) async {
    final buffer = StringBuffer();

    // 1. 相似文本块
    final similarChunks = await searchSimilarChunks(query, projectId, topK: 3);
    if (similarChunks.isNotEmpty) {
      buffer.writeln('【相关前文】');
      for (final chunk in similarChunks) {
        buffer.writeln(chunk);
        buffer.writeln('---');
      }
    }

    // 2. 相关实体关系
    final entities = await _storage.getAllEntities();
    if (entities.isNotEmpty) {
      // 查找与查询中可能相关的实体关系
      final queryTokens = _tokenize(query).toSet();
      final relevantRelations = <String>{};

      for (final entity in entities) {
        final entityTokens = _tokenize(entity.entityName).toSet();
        final intersection = queryTokens.intersection(entityTokens);
        if (intersection.isNotEmpty) {
          relevantRelations.add(_formatEntityRelation(entity));
        }
      }

      if (relevantRelations.isNotEmpty) {
        buffer.writeln('\n【相关实体关系】');
        for (final rel in relevantRelations) {
          buffer.writeln(rel);
        }
      }
    }

    return buffer.toString();
  }

  // ============================================================
  // 文本分块
  // ============================================================

  /// 将文本按固定大小和重叠量切分为块。
  List<String> _splitIntoChunks(String text) {
    final chunks = <String>[];
    if (text.length <= _chunkSize) {
      chunks.add(text);
      return chunks;
    }

    int start = 0;
    while (start < text.length) {
      final end = min(start + _chunkSize, text.length);
      chunks.add(text.substring(start, end));
      start += (_chunkSize - _chunkOverlap);
    }

    return chunks;
  }

  // ============================================================
  // TF-IDF 工具
  // ============================================================

  /// 对文本进行分词（字符级 unigram）。
  ///
  /// 中文文本不适用空格分词，此处采用字符级切分并过滤停用词。
  List<String> _tokenize(String text) {
    final tokens = <String>[];
    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // 跳过空白和标点
      if (RegExp(r'[\s，。！？；：""''、（）…—\-\.,!?;:\"\'\(\)\[\]《》]')
          .hasMatch(char)) {
        continue;
      }

      tokens.add(char);
    }
    return tokens;
  }

  /// 计算所有块的 IDF（逆文档频率）。
  Map<String, double> _computeIdf(
    List<String> texts,
    List<String> vocabulary,
  ) {
    final totalDocs = texts.length;
    final idf = <String, double>{};

    for (final term in vocabulary) {
      int docCount = 0;
      for (final text in texts) {
        if (text.contains(term)) {
          docCount++;
        }
      }
      // IDF = log(总文档数 / 包含该词的文档数)
      idf[term] = log((totalDocs + 1) / (docCount + 1));
    }

    return idf;
  }

  /// 计算单段文本的 TF-IDF 向量。
  List<double> _computeTfidfVector(
    String text,
    List<String> vocabulary,
    Map<String, double> idf,
  ) {
    final tokens = _tokenize(text);
    final totalTokens = tokens.length;
    if (totalTokens == 0) return List.filled(vocabulary.length, 0.0);

    // 计算 TF
    final tf = <String, double>{};
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1.0 / totalTokens;
    }

    // TF-IDF
    final vector = <double>[];
    for (final term in vocabulary) {
      vector.add((tf[term] ?? 0.0) * (idf[term] ?? 0.0));
    }

    return vector;
  }

  // ============================================================
  // 相似度计算
  // ============================================================

  /// 计算两个向量的余弦相似度。
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    assert(a.length == b.length, '向量长度必须相等');

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  // ============================================================
  // 实体关系格式化
  // ============================================================

  /// 将实体关系格式化为可读文本。
  String _formatEntityRelation(EntityRelation entity) {
    final buffer = StringBuffer();
    buffer.write('[${entity.entityType}] ${entity.entityName}');

    if (entity.relatedEntity != null && entity.relatedEntity!.isNotEmpty) {
      buffer.write(' --${entity.relationType}--> ${entity.relatedEntity}');
    }

    if (entity.description != null && entity.description!.isNotEmpty) {
      buffer.write(': ${entity.description}');
    }

    return buffer.toString();
  }
}

/// 内部辅助类：带相似度评分的文本块
class _ScoredChunk {
  final String text;
  final double score;

  const _ScoredChunk(this.text, this.score);
}