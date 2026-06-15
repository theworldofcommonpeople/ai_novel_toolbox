/// ============================================================
/// 提示词模板配置 - AI 小说工具箱
/// ============================================================
///
/// 包含全部 12 个生成器的系统提示词与参数定义。
/// 每个生成器条目包含：
///   - prompt: 模板字符串，使用 {{key}} 作为参数占位符
///   - params: 参数列表，每个参数包含 key, label, type, 和可选的 options
///
/// 使用方式：
///   final template = PromptTemplates.all['brain_hole']!;
///   final rendered = PromptTemplates.render(template['prompt']!, {'genre': '玄幻'});
///

/// 单个参数定义
class PromptParam {
  /// 参数在 prompt 中的占位 key，如 'genre'
  final String key;

  /// 参数显示标签，如 '小说类型'
  final String label;

  /// 输入控件类型：'text', 'multiline', 'dropdown', 'number'
  final String type;

  /// 下拉选项（仅 dropdown 类型需要）
  final List<String>? options;

  const PromptParam({
    required this.key,
    required this.label,
    required this.type,
    this.options,
  });

  /// 从 JSON Map 构造
  factory PromptParam.fromMap(Map<String, dynamic> map) {
    return PromptParam(
      key: map['key'] as String,
      label: map['label'] as String,
      type: map['type'] as String,
      options: map['options'] != null
          ? List<String>.from(map['options'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'type': type,
      if (options != null) 'options': options,
    };
  }
}

/// 所有生成器的提示词模板与参数定义
class PromptTemplates {
  PromptTemplates._();

  /// 键为生成器 type，值为包含 'prompt' 和 'params' 的 Map
  static const Map<String, Map<String, dynamic>> all = {
    // ==========================================================
    // 1. 小说脑洞
    // ==========================================================
    'brain_hole': {
      'prompt': '请生成一个新颖、反套路、有冲突感的小说脑洞，包含核心设定、主角目标和意外转折。风格：让人眼前一亮。',
      'params': <PromptParam>[],
    },

    // ==========================================================
    // 2. 书名生成
    // ==========================================================
    'book_name': {
      'prompt': '为{{genre}}小说生成10个吸量书名，要求：短小精悍、有悬念感、符合网文风格。',
      'params': <PromptParam>[
        PromptParam(
          key: 'genre',
          label: '小说类型',
          type: 'dropdown',
          options: ['玄幻', '都市', '科幻', '古代', '悬疑', '游戏', '末世', '无限流'],
        ),
      ],
    },

    // ==========================================================
    // 3. 书测
    // ==========================================================
    'book_test': {
      'prompt': '请对以下小说内容进行多维度测试评估，包括：开篇吸引力、节奏把控、人设魅力、爽点密度、悬念设计、文笔流畅度。\n\n小说内容：\n{{content}}',
      'params': <PromptParam>[
        PromptParam(
          key: 'content',
          label: '小说内容',
          type: 'multiline',
        ),
      ],
    },

    // ==========================================================
    // 4. 小说简介
    // ==========================================================
    'synopsis': {
      'prompt': '根据书名《{{bookName}}》和故事梗概：{{summary}}，写一段300字以内的小说简介，突出爽点和期待。',
      'params': <PromptParam>[
        PromptParam(
          key: 'bookName',
          label: '书名',
          type: 'text',
        ),
        PromptParam(
          key: 'summary',
          label: '故事梗概',
          type: 'multiline',
        ),
      ],
    },

    // ==========================================================
    // 5. 故事大纲
    // ==========================================================
    'outline': {
      'prompt': '为{{genre}}小说创作完整大纲。主角：{{protagonist}}。核心冲突：{{conflict}}。输出格式：三幕式（开端-发展-高潮-结局），每幕3-5个情节节点。',
      'params': <PromptParam>[
        PromptParam(
          key: 'genre',
          label: '小说类型',
          type: 'dropdown',
          options: ['玄幻', '都市', '科幻', '古代', '悬疑', '游戏', '末世', '无限流'],
        ),
        PromptParam(
          key: 'protagonist',
          label: '主角描述',
          type: 'text',
        ),
        PromptParam(
          key: 'conflict',
          label: '核心冲突',
          type: 'multiline',
        ),
      ],
    },

    // ==========================================================
    // 6. 章节细纲
    // ==========================================================
    'detail_outline': {
      'prompt': '将以下大纲拆解为每章500-800字的细纲，共{{chapterCount}}章。每章包含：本章核心事件、冲突点、结尾钩子。\n\n大纲内容：\n{{outline}}',
      'params': <PromptParam>[
        PromptParam(
          key: 'chapterCount',
          label: '章节数',
          type: 'number',
        ),
        PromptParam(
          key: 'outline',
          label: '大纲内容',
          type: 'multiline',
        ),
      ],
    },

    // ==========================================================
    // 7. 黄金开篇
    // ==========================================================
    'golden_opening': {
      'prompt': '根据以下设定，写出小说前800字的开篇。要求：快速带入主角、展示金手指或冲突、结尾留有悬念。\n\n设定：\n{{setting}}',
      'params': <PromptParam>[
        PromptParam(
          key: 'setting',
          label: '故事设定',
          type: 'multiline',
        ),
      ],
    },

    // ==========================================================
    // 8. 金手指设计
    // ==========================================================
    'golden_finger': {
      'prompt': '为主角设计一个独特且有趣的金手指。类型：{{type}}（系统/重生/异能/知识等）。要求：有成长性、有限制、能制造爽点。',
      'params': <PromptParam>[
        PromptParam(
          key: 'type',
          label: '金手指类型',
          type: 'dropdown',
          options: ['系统', '重生', '异能', '知识', '血脉', '奇遇', '穿越', '其他'],
        ),
      ],
    },

    // ==========================================================
    // 9. 命名生成器
    // ==========================================================
    'name_gen': {
      'prompt': '生成{{count}}个{{category}}名字，类别：{{category}}（人名/地名/物品/势力）。风格：{{style}}（东方/西方/奇幻/科幻）。',
      'params': <PromptParam>[
        PromptParam(
          key: 'count',
          label: '生成数量',
          type: 'number',
        ),
        PromptParam(
          key: 'category',
          label: '名字类别',
          type: 'dropdown',
          options: ['人名', '地名', '物品名', '势力名'],
        ),
        PromptParam(
          key: 'style',
          label: '风格',
          type: 'dropdown',
          options: ['东方', '西方', '奇幻', '科幻', '古风', '现代'],
        ),
      ],
    },

    // ==========================================================
    // 10. 角色设计
    // ==========================================================
    'character_design': {
      'prompt': '创建一个{{gender}}角色，职业：{{job}}，性格：{{personality}}。输出格式：\n1. 姓名\n2. 年龄\n3. 外貌特征\n4. 性格特点\n5. 背景故事\n6. 核心欲望\n7. 成长弧\n8. 口头禅/标志动作',
      'params': <PromptParam>[
        PromptParam(
          key: 'gender',
          label: '性别',
          type: 'dropdown',
          options: ['男', '女', '不限'],
        ),
        PromptParam(
          key: 'job',
          label: '职业',
          type: 'text',
        ),
        PromptParam(
          key: 'personality',
          label: '性格',
          type: 'dropdown',
          options: [
            '开朗阳光',
            '阴郁深沉',
            '傲娇毒舌',
            '温柔善良',
            '冷酷无情',
            '热血冲动',
            '腹黑狡诈',
            '呆萌天真',
          ],
        ),
      ],
    },

    // ==========================================================
    // 11. 世界观构建
    // ==========================================================
    'world_building': {
      'prompt': '构建一个{{genre}}世界观，包含：世界名称、整体氛围、主要种族/势力、独特规则（魔法/科技/修炼体系）、历史关键事件、当前矛盾。',
      'params': <PromptParam>[
        PromptParam(
          key: 'genre',
          label: '世界观类型',
          type: 'dropdown',
          options: [
            '东方玄幻',
            '西方奇幻',
            '科幻未来',
            '末日废土',
            '修真仙侠',
            '异世大陆',
            '都市异能',
          ],
        ),
      ],
    },

    // ==========================================================
    // 12. 词条百科
    // ==========================================================
    'glossary': {
      'prompt': '生成{{count}}个{{type}}词条，类型：{{type}}（道具/技能/功法/法宝）。每个词条包含：名称、稀有度、效果描述、使用限制、背景故事。',
      'params': <PromptParam>[
        PromptParam(
          key: 'count',
          label: '生成数量',
          type: 'number',
        ),
        PromptParam(
          key: 'type',
          label: '词条类型',
          type: 'dropdown',
          options: ['道具', '技能', '功法', '法宝', '丹药', '阵法', '灵兽'],
        ),
      ],
    },
  };

  /// 获取指定生成器的系统提示词模板
  static String getPrompt(String generatorType) {
    final entry = all[generatorType];
    if (entry == null) {
      throw ArgumentError('未知的生成器类型: $generatorType');
    }
    return entry['prompt'] as String;
  }

  /// 获取指定生成器的参数定义列表
  static List<PromptParam> getParams(String generatorType) {
    final entry = all[generatorType];
    if (entry == null) {
      throw ArgumentError('未知的生成器类型: $generatorType');
    }
    return List<PromptParam>.from(entry['params'] as List);
  }

  /// 渲染提示词模板 —— 将 {{key}} 替换为实际参数值
  ///
  /// 示例：
  ///   render('为{{genre}}小说生成书名', {'genre': '玄幻'})
  ///   => '为玄幻小说生成书名'
  static String render(String template, Map<String, String> values) {
    String result = template;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    // 保留未填写的占位符，为空值时填入默认提示
    final unfilledRegex = RegExp(r'\{\{(\w+)\}\}');
    result = result.replaceAllMapped(unfilledRegex, (match) {
      return '【${match.group(1)}】';
    });
    return result;
  }

  /// 获取所有参数值集合 —— 用于批量渲染
  /// 返回 Map<paramKey, value>
  static Map<String, String> collectAllParamValues(Map<String, String> values) {
    return Map<String, String>.from(values);
  }

  /// 获取所有已注册生成器的 type 列表
  static List<String> get allGeneratorTypes => all.keys.toList();

  /// 检查生成器类型是否有效
  static bool hasGenerator(String type) => all.containsKey(type);
}