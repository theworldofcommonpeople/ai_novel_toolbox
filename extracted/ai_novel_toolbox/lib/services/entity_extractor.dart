/// 实体抽取服务
///
/// 基于正则表达式从小说文本中自动提取人物名、地名等实体，
/// 辅助构建知识图谱并保持写作一致性。
///
/// 当前策略：
/// - 中文人名：常见姓氏 + 1-3 个汉字名字
/// - 地名：带有 城/镇/山/河/国/省/市/村/殿/阁/宫/派/门/宗/府/院/谷/岛/海 后缀
/// - 无需外部 NLP 库，轻量且适用于移动端
class EntityExtractor {
  // ============================================================
  // 中文姓氏库（百家姓常见姓氏）
  // ============================================================

  static const List<String> _commonSurnames = [
    // 单姓
    '赵', '钱', '孙', '李', '周', '吴', '郑', '王', '冯', '陈', '褚', '卫',
    '蒋', '沈', '韩', '杨', '朱', '秦', '尤', '许', '何', '吕', '施', '张',
    '孔', '曹', '严', '华', '金', '魏', '陶', '姜', '戚', '谢', '邹', '喻',
    '柏', '水', '窦', '章', '云', '苏', '潘', '葛', '奚', '范', '彭', '郎',
    '鲁', '韦', '昌', '马', '苗', '凤', '花', '方', '俞', '任', '袁', '柳',
    '酆', '鲍', '史', '唐', '费', '廉', '岑', '薛', '雷', '贺', '倪', '汤',
    '滕', '殷', '罗', '毕', '郝', '邬', '安', '常', '乐', '于', '时', '傅',
    '皮', '卞', '齐', '康', '伍', '余', '元', '卜', '顾', '孟', '平', '黄',
    '和', '穆', '萧', '尹', '姚', '邵', '汪', '祁', '毛', '禹', '狄', '米',
    '贝', '明', '臧', '计', '伏', '成', '戴', '谈', '宋', '茅', '庞', '熊',
    '纪', '舒', '屈', '项', '祝', '董', '梁', '杜', '阮', '蓝', '闵', '席',
    '季', '麻', '强', '贾', '路', '娄', '危', '江', '童', '颜', '郭', '梅',
    '盛', '林', '刁', '钟', '徐', '邱', '骆', '高', '夏', '蔡', '田', '樊',
    '胡', '凌', '霍', '万', '支', '柯', '咎', '管', '卢', '莫', '房', '裘',
    '缪', '干', '解', '应', '宗', '丁', '宣', '贲', '邓', '郁', '单', '杭',
    '洪', '包', '诸', '左', '石', '崔', '吉', '钮', '龚', '程', '嵇', '邢',
    '滑', '裴', '陆', '荣', '翁', '荀', '羊', '甄', '曲', '家', '封', '芮',
    '羿', '储', '靳', '汲', '邴', '糜', '松', '井', '段', '富', '巫', '乌',
    '焦', '巴', '弓', '牧', '隗', '山', '谷', '车', '侯', '宓', '蓬', '全',
    '郗', '班', '仰', '秋', '仲', '伊', '宫', '宁', '仇', '栾', '暴', '甘',
    '厉', '戎', '祖', '武', '符', '刘', '景', '詹', '束', '龙', '叶', '幸',
    '司', '韶', '黎', '蓟', '印', '白', '怀', '蒲', '台', '从', '鄂', '索',
    '咸', '籍', '赖', '卓', '蔺', '屠', '蒙', '池', '乔', '阴', '胥', '能',
    '苍', '双', '闻', '莘', '党', '翟', '谭', '贡', '劳', '逄', '姬', '申',
    '扶', '堵', '冉', '宰', '郦', '雍', '璩', '桑', '桂', '濮', '牛', '寿',
    '通', '边', '扈', '燕', '冀', '浦', '尚', '农', '温', '别', '庄', '晏',
    '柴', '瞿', '阎', '充', '慕', '连', '茹', '习', '宦', '艾', '鱼', '容',
    '向', '古', '易', '慎', '戈', '廖', '庚', '终', '暨', '居', '衡', '步',
    '都', '耿', '满', '弘', '匡', '国', '文', '寇', '广', '禄', '阙', '东',
    '殳', '沃', '利', '蔚', '越', '夔', '隆', '师', '巩', '聂', '勾', '敖',
    '融', '冷', '訾', '辛', '阚', '那', '简', '饶', '空', '曾', '沙', '乜',
    '养', '鞠', '须', '丰', '巢', '关', '相', '查', '荆', '红', '游', '竺',
    '权', '逯', '盖', '益', '桓', '公', '万俟', '司马', '上官', '欧阳', '夏侯',
    '诸葛', '闻人', '东方', '赫连', '皇甫', '尉迟', '公羊', '澹台', '公冶', '宗政',
    '濮阳', '淳于', '单于', '太叔', '申屠', '公孙', '仲孙', '轩辕', '令狐', '钟离',
    '宇文', '长孙', '慕容', '鲜于', '闾丘', '司徒', '司空', '丌官', '司寇', '仉督',
    '子车', '颛孙', '端木', '巫马', '公西', '漆雕', '乐正', '壤驷', '公良', '拓跋',
    '夹谷', '宰父', '谷梁', '段干', '百里', '东郭', '南门', '呼延', '羊舌', '微生',
    '岳', '帅', '缑', '亢', '况', '郈', '琴', '梁丘', '左丘', '东门', '西门',
    '商', '牟', '佘', '伯', '赏', '墨', '哈', '谯', '笪', '年', '爱', '阳',
    '佟', '言', '福',
  ];

  // ============================================================
  // 地名后缀
  // ============================================================

  static const List<String> _placeIndicators = [
    '城', '镇', '山', '河', '国', '省', '市', '村', '殿', '阁', '宫',
    '派', '门', '宗', '府', '院', '谷', '岛', '海', '湖', '林',
    '塔', '寺', '庙', '观', '楼', '亭', '台', '堂', '庄', '寨',
    '岭', '峰', '崖', '洞', '关', '道', '街', '坊', '洲', '原',
    '泽', '潭', '泉', '溪', '江', '陵', '墓', '坟',
  ];

  // ============================================================
  // 人名提取
  // ============================================================

  /// 从文本中提取所有可能的中国人名。
  ///
  /// 策略：
  /// 1. 匹配常见单姓 + 1-3 字名字（共 2-4 字）
  /// 2. 匹配常见复姓 + 1-2 字名字（共 3-4 字）
  List<String> extractPersonNames(String text) {
    final names = <String>{};

    // 构建姓氏正则模式
    final singleSurnames = _commonSurnames
        .where((s) => s.length == 1)
        .map((s) => RegExp.escape(s))
        .join('|');
    final doubleSurnames = _commonSurnames
        .where((s) => s.length == 2)
        .map((s) => RegExp.escape(s))
        .join('|');

    // 中文汉字范围
    const hanChar = r'[\u4e00-\u9fff]';

    // 单姓 + 1-3 字名 → 2-4 字
    if (singleSurnames.isNotEmpty) {
      final singlePattern = RegExp(
        '($singleSurnames)($hanChar{1,3})'
        r'(?=[\s，。！？；：""''、（）…—\-.,!?;:\"\'\(\)\[\]《》（）])?',
        unicode: true,
      );
      for (final match in singlePattern.allMatches(text)) {
        final full = match.group(0) ?? '';
        if (full.length >= 2 && full.length <= 4) {
          names.add(full);
        }
      }
    }

    // 复姓 + 1-2 字名 → 3-4 字
    if (doubleSurnames.isNotEmpty) {
      final doublePattern = RegExp(
        '($doubleSurnames)($hanChar{1,2})'
        r'(?=[\s，。！？；：""''、（）…—\-.,!?;:\"\'\(\)\[\]《》（）])?',
        unicode: true,
      );
      for (final match in doublePattern.allMatches(text)) {
        final full = match.group(0) ?? '';
        if (full.length >= 3 && full.length <= 4) {
          names.add(full);
        }
      }
    }

    // 过滤掉明确不是人名的词组（含代词、虚词等）
    final nonPersonIndicators = {
      '我们', '他们', '她们', '自己', '什么', '怎么', '这个', '那个',
      '一些', '这些', '那些', '这里', '那里', '哪里', '为什么',
    };

    names.removeWhere((n) => nonPersonIndicators.contains(n));

    return names.toList();
  }

  // ============================================================
  // 地名提取
  // ============================================================

  /// 从文本中提取可能的地名。
  ///
  /// 策略：匹配以常见地名后缀结尾的 2-6 字词组。
  List<String> extractPlaceNames(String text) {
    final places = <String>{};
    const hanChar = r'[\u4e00-\u9fff]';

    // 构建地名正则：1-5 个汉字 + 地名后缀
    for (final indicator in _placeIndicators) {
      final pattern = RegExp(
        '($hanChar{1,5}$indicator)'
        r'(?=[\s，。！？；：""''、（）…—\-.,!?;:\"\'\(\)\[\]《》（）])?',
        unicode: true,
      );
      for (final match in pattern.allMatches(text)) {
        final place = match.group(1);
        if (place != null) {
          places.add(place);
        }
      }
    }

    return places.toList();
  }

  // ============================================================
  // 增量提取
  // ============================================================

  /// 从文本中提取不在已有名单中的新角色名。
  ///
  /// 常用于每次 AI 生成新段落后自动检测是否引入新人物。
  List<String> extractNewCharacters(String text, List<String> existingNames) {
    final foundNames = extractPersonNames(text);
    // 忽略大小写和前后空格的差异
    final existingNormalized = existingNames.map((n) => n.trim()).toSet();
    final newNames = <String>{};

    for (final name in foundNames) {
      final normalized = name.trim();
      if (!existingNormalized.contains(normalized)) {
        newNames.add(normalized);
      }
    }

    return newNames.toList();
  }

  // ============================================================
  // 上下文提取
  // ============================================================

  /// 提取围绕指定实体的上下文文本。
  ///
  /// 返回实体前后各约 100 个字符的文本片段，便于快速了解实体的
  /// 出场环境和相关描述。
  String extractContextForEntity(String text, String entityName) {
    final index = text.indexOf(entityName);
    if (index == -1) return '';

    const contextWindow = 100;

    // 向前找 100 个字符（遇到句号/换行时提前终止）
    int start = (index - contextWindow).clamp(0, text.length);
    if (start > 0) {
      // 尽量从完整句子开始
      final prefix = text.substring(start, index);
      final sentenceBreak =
          prefix.lastIndexOf(RegExp(r'[。！？\n]'));
      if (sentenceBreak != -1 && index - (start + sentenceBreak) < contextWindow) {
        start = start + sentenceBreak + 1;
      }
    }

    // 向后找 100 个字符（遇到句号时提前终止）
    int end = (index + entityName.length + contextWindow).clamp(0, text.length);
    if (end < text.length) {
      final suffix = text.substring(index + entityName.length, end);
      final sentenceBreak = suffix.indexOf(RegExp(r'[。！？\n]'));
      if (sentenceBreak != -1) {
        end = index + entityName.length + sentenceBreak + 1;
      }
    }

    return text.substring(start, end);
  }
}