/// ============================================================
/// 文本分块工具类 - AI 小说工具箱
/// ============================================================
///
/// 提供长文本的分块处理与中文字数统计功能。
/// 主要用于：
///   - 将长篇小说内容切分为适合 AI 处理的段落块
///   - 统计中文有效字符数（排除空格和标点）
///
/// 使用方式：
///   final chunks = TextSplitter.splitText(longText, chunkSize: 500, overlap: 50);
///   final wordCount = TextSplitter.countChineseWords(text);

class TextSplitter {
  TextSplitter._();

  /// Unicode 范围定义 —— 用于精确判断字符类别
  static const int _cjkStart = 0x4E00;   // 一（CJK 统一表意文字起始）
  static const int _cjkEnd = 0x9FFF;     // 鿿（CJK 统一表意文字结束）
  static const int _cjkExtAStart = 0x3400;
  static const int _cjkExtAEnd = 0x4DBF;
  static const int _cjkCompatStart = 0xF900;
  static const int _cjkCompatEnd = 0xFAFF;
  static const int _cjkRadicalStart = 0x2F00;
  static const int _cjkRadicalEnd = 0x2FDF;
  static const int _fullWidthDigitStart = 0xFF10;
  static const int _fullWidthDigitEnd = 0xFF19; // 全角数字0-9
  static const int _fullWidthUpperStart = 0xFF21;
  static const int _fullWidthUpperEnd = 0xFF3A; // 全角大写字母
  static const int _fullWidthLowerStart = 0xFF41;
  static const int _fullWidthLowerEnd = 0xFF5A; // 全角小写字母

  /// 判断一个字符是否为汉字（含 CJK 扩展区）
  static bool _isCJKCharacter(int codePoint) {
    return (codePoint >= _cjkStart && codePoint <= _cjkEnd) ||
        (codePoint >= _cjkExtAStart && codePoint <= _cjkExtAEnd) ||
        (codePoint >= _cjkCompatStart && codePoint <= _cjkCompatEnd) ||
        (codePoint >= _cjkRadicalStart && codePoint <= _cjkRadicalEnd);
  }

  /// 判断一个字符是否为全角标点/符号
  static bool _isFullWidthPunctuation(int codePoint) {
    return (codePoint >= 0xFF00 && codePoint <= 0xFF0F) ||  // 全角标点
        (codePoint >= 0xFF1A && codePoint <= 0xFF20) ||      // ：；＜＝＞？＠
        (codePoint >= 0xFF3B && codePoint <= 0xFF40) ||      // ［＼］＾＿｀
        (codePoint >= 0xFF5B && codePoint <= 0xFF5E) ||      // ｛｜｝～
        (codePoint >= 0x3000 && codePoint <= 0x303F) ||      // CJK 符号和标点
        (codePoint >= 0xFE30 && codePoint <= 0xFE4F) ||      // CJK 兼容形式
        (codePoint >= 0x2010 && codePoint <= 0x2027) ||      // 通用标点
        (codePoint >= 0x2030 && codePoint <= 0x205E);        // 通用标点补充
  }

  /// 判断一个字符是否为半角标点/空白
  static bool _isHalfWidthPunctuationOrSpace(int codePoint) {
    return codePoint == 0x20 ||              // 空格
        codePoint == 0x09 ||                 // Tab
        codePoint == 0x0A ||                 // 换行
        codePoint == 0x0D ||                 // 回车
        (codePoint >= 0x21 && codePoint <= 0x2F) ||  // !"#$%&'()*+,-./
        (codePoint >= 0x3A && codePoint <= 0x40) ||  // :;<=>?@
        (codePoint >= 0x5B && codePoint <= 0x60) ||  // [\]^_`
        (codePoint >= 0x7B && codePoint <= 0x7E);     // {|}~
  }

  /// 判断一个字符是否为中文标点或空白（不计入有效汉字统计）
  static bool _isPunctuationOrSpace(int codePoint) {
    return _isFullWidthPunctuation(codePoint) ||
        _isHalfWidthPunctuationOrSpace(codePoint) ||
        codePoint == 0x3000; // 全角空格
  }

  // ============================================================
  // 公开静态方法
  // ============================================================

  /// 统计文本中的中文字符数量（排除空格、标点符号、英文等）
  ///
  /// 仅统计 CJK 字符（含扩展区），不包含标点、空格、数字、字母。
  ///
  /// 示例：
  ///   countChineseWords('你好，世界！') => 4
  ///   countChineseWords('Hello 你好')    => 2
  static int countChineseWords(String text) {
    if (text.isEmpty) return 0;

    int count = 0;
    for (int i = 0; i < text.length; i++) {
      final codePoint = text.codeUnitAt(i);

      // 跳过代理对的高位部分（会在低位时处理）
      if (codePoint >= 0xD800 && codePoint <= 0xDBFF) continue;

      // 处理代理对（emoji、罕见汉字等）
      if (codePoint >= 0xDC00 && codePoint <= 0xDFFF) continue;

      if (_isCJKCharacter(codePoint) && !_isPunctuationOrSpace(codePoint)) {
        count++;
      }
    }
    return count;
  }

  /// 将文本按指定大小分割为带重叠的块
  ///
  /// [text] - 待分割的原始文本
  /// [chunkSize] - 每块的目标字符数（默认 500）
  /// [overlap] - 相邻块之间的重叠字符数（默认 50）
  ///
  /// 返回 `List<String>`，每个元素为一个文本块。
  ///
  /// 分割策略：
  ///   1. 以 [chunkSize] 为步长扫描文本，每个窗口为一整块。
  ///   2. 在窗口边界处优先寻找段落边界（连续换行）或句子边界（。！？）
  ///      进行分割，使块边界更自然。
  ///   3. 相邻块之间保留 [overlap] 个字符的重叠，确保跨块上下文连贯。
  ///   4. 保证每块不会无限缩短：设置了最小块阈值（chunkSize / 3），
  ///      避免在缺少理想断点处产生过小块。
  ///
  /// 示例：
  ///   splitText('长文本...', chunkSize: 500, overlap: 50)
  ///   => ['前500字...', '从第451字开始的500字...', ...]
  static List<String> splitText(
    String text, {
    int chunkSize = 500,
    int overlap = 50,
  }) {
    if (text.isEmpty) return [];
    if (chunkSize <= 0) {
      throw ArgumentError('chunkSize 必须大于 0，当前值: $chunkSize');
    }
    if (overlap < 0) {
      throw ArgumentError('overlap 不能为负数，当前值: $overlap');
    }
    if (overlap >= chunkSize) {
      throw ArgumentError(
        'overlap ($overlap) 必须小于 chunkSize ($chunkSize)',
      );
    }

    final List<String> chunks = [];
    final int textLength = text.length;

    // 文本短于一整块时，直接返回整段
    if (textLength <= chunkSize) {
      chunks.add(text.trim());
      return chunks;
    }

    final int step = chunkSize - overlap; // 每次前进的步长
    int start = 0;

    while (start < textLength) {
      // 计算原始结束位置
      int end = start + chunkSize;
      if (end >= textLength) {
        // 最后一块：取到底
        final chunk = text.substring(start).trim();
        if (chunk.isNotEmpty) {
          chunks.add(chunk);
        }
        break;
      }

      // ----- 边界优化：在 chunkSize 附近寻找自然断点 -----
      int bestEnd = _findNaturalBreak(
        text,
        preferredEnd: end,
        start: start,
        chunkSize: chunkSize,
      );

      // 确保不会无限缩短
      final int minChunkSize = (chunkSize / 3).ceil();
      if (bestEnd - start < minChunkSize) {
        bestEnd = end; // 回退到原始切割点
      }

      final chunk = text.substring(start, bestEnd).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      // 下一步的起始位置
      start = bestEnd - overlap;
      if (start <= 0) start = step; // 安全兜底
    }

    return chunks;
  }

  // ============================================================
  // 私有辅助方法
  // ============================================================

  /// 在目标切割点附近寻找最佳自然断点。
  ///
  /// 搜索范围：[preferredEnd - chunkSize/4, preferredEnd + chunkSize/4]
  ///
  /// 优先级（从高到低）：
  ///   1. 段落边界 —— 连续两个以上换行符（\n\n 或 \r\n\r\n）
  ///   2. 句子边界 —— 以。！？；"）结束
  ///   3. 自然分句 —— 换行符（\n 或 \r\n）
  ///   4. 逗号/分号 —— ，；
  ///   5. 回退到 preferredEnd（硬切）
  static int _findNaturalBreak(
    String text, {
    required int preferredEnd,
    required int start,
    required int chunkSize,
  }) {
    final int searchRadius = (chunkSize / 4).ceil();
    final int searchStart = (preferredEnd - searchRadius).clamp(start, text.length);
    final int searchEnd = (preferredEnd + searchRadius).clamp(start, text.length);

    // 优先级 1: 段落边界 —— 连续两个换行
    for (int i = searchEnd; i > searchStart; i--) {
      if (i + 1 < text.length) {
        final char1 = text[i];
        final char2 = text[i + 1];
        // 双换行符（\n\n 或 \r\n\r\n）
        if ((char1 == '\n' && char2 == '\n') ||
            (char1 == '\r' && i + 3 < text.length &&
                text[i + 1] == '\n' && text[i + 2] == '\r' && text[i + 3] == '\n')) {
          return i + 2;
        }
      }
    }

    // 优先级 2: 句子边界 —— 以中文句号、问号、感叹号、分号、右引号等结束
    const sentenceEnders = '。！？；…—）"」』】》〉'
        '.!?;';
    for (int i = searchEnd; i > searchStart; i--) {
      final char = text[i];
      if (sentenceEnders.contains(char)) {
        // 检查是否是真正的句子结束（后面有空格/换行/下一个句子开始）
        if (i + 1 >= text.length ||
            text[i + 1] == '\n' ||
            text[i + 1] == ' ' ||
            text[i + 1] == '\r') {
          return i + 1;
        }
      }
    }

    // 优先级 3: 换行符
    for (int i = searchEnd; i > searchStart; i--) {
      if (text[i] == '\n') {
        return i + 1;
      }
    }

    // 优先级 4: 逗号 / 中文逗号
    for (int i = searchEnd; i > searchStart; i--) {
      final char = text[i];
      if (char == '，' || char == ',' || char == '；' || char == ';') {
        return i + 1;
      }
    }

    // 优先级 5: 回退到硬切
    return preferredEnd;
  }

  /// 将文本按自然段落（连续空行）分割
  ///
  /// 常用于将整篇文档按章节或段落拆分后，再对每个段落调用 [splitText]。
  static List<String> splitByParagraphs(String text) {
    if (text.isEmpty) return [];

    // 按连续的换行符（至少一个空行，即两个连续换行）分割
    final paragraphPattern = RegExp(r'\n\s*\n');
    final parts = text.split(paragraphPattern);

    return parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// 统计文本的有效字符总数（含所有非空白字符）
  ///
  /// 与 [countChineseWords] 不同，此方法统计所有非空白/非换行字符，
  /// 包括标点、数字、字母等。
  static int countTotalChars(String text) {
    if (text.isEmpty) return 0;

    int count = 0;
    for (int i = 0; i < text.length; i++) {
      final codePoint = text.codeUnitAt(i);
      if (codePoint != 0x20 &&   // 空格
          codePoint != 0x09 &&   // Tab
          codePoint != 0x0A &&   // 换行
          codePoint != 0x0D) {   // 回车
        count++;
      }
    }
    return count;
  }

  /// 格式化字数显示 —— 超过 10000 显示为 "1.2万字"
  static String formatWordCount(int count) {
    if (count >= 10000) {
      final wan = count / 10000.0;
      // 保留一位小数，若 .0 则去掉
      if (wan == wan.roundToDouble()) {
        return '${wan.round()}万字';
      }
      return '${wan.toStringAsFixed(1)}万字';
    }
    if (count >= 1000) {
      final qian = count / 1000.0;
      if (qian == qian.roundToDouble()) {
        return '${qian.round()}千字';
      }
      return '${qian.toStringAsFixed(1)}千字';
    }
    return '$count字';
  }
}