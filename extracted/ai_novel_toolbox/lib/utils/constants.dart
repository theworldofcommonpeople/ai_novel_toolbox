import 'package:flutter/material.dart';

/// ============================================================
/// 常量配置文件 - AI 小说工具箱
/// ============================================================

/// 所有 12 个生成器的配置元数据
class GeneratorConfig {
  final String type;
  final String name;
  final IconData icon;
  final String description;
  final String route;

  const GeneratorConfig({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    required this.route,
  });
}

/// 全部生成器列表（共 12 个）
const List<GeneratorConfig> allGenerators = [
  // ---- 创意激发 ----
  GeneratorConfig(
    type: 'brain_hole',
    name: '小说脑洞',
    icon: Icons.lightbulb_outline,
    description: '生成新颖、反套路、有冲突感的小说脑洞，包含核心设定、主角目标和意外转折',
    route: '/generator/brain_hole',
  ),
  GeneratorConfig(
    type: 'book_name',
    name: '书名生成',
    icon: Icons.auto_stories,
    description: '根据小说类型生成吸量书名，短小精悍、有悬念感、符合网文风格',
    route: '/generator/book_name',
  ),
  GeneratorConfig(
    type: 'book_test',
    name: '书测',
    icon: Icons.science_outlined,
    description: '对小说进行多维度测试评估',
    route: '/generator/book_test',
  ),

  // ---- 大纲构建 ----
  GeneratorConfig(
    type: 'synopsis',
    name: '小说简介',
    icon: Icons.description_outlined,
    description: '根据书名和梗概生成 300 字以内的小说简介，突出爽点和期待感',
    route: '/generator/synopsis',
  ),
  GeneratorConfig(
    type: 'outline',
    name: '故事大纲',
    icon: Icons.account_tree_outlined,
    description: '三幕式大纲创作：开端—发展—高潮—结局，每幕 3-5 个情节节点',
    route: '/generator/outline',
  ),
  GeneratorConfig(
    type: 'detail_outline',
    name: '章节细纲',
    icon: Icons.format_list_numbered,
    description: '将大纲拆解为每章 500-800 字的细纲，含核心事件、冲突点和结尾钩子',
    route: '/generator/detail_outline',
  ),

  // ---- 精彩内容 ----
  GeneratorConfig(
    type: 'golden_opening',
    name: '黄金开篇',
    icon: Icons.auto_awesome,
    description: '写出小说前 800 字的开篇，快速带入主角、展示金手指或冲突、结尾留悬念',
    route: '/generator/golden_opening',
  ),
  GeneratorConfig(
    type: 'golden_finger',
    name: '金手指设计',
    icon: Icons.touch_app,
    description: '为主角设计独特有趣的金手指，有成长性、有限制、能制造爽点',
    route: '/generator/golden_finger',
  ),

  // ---- 角色与设定 ----
  GeneratorConfig(
    type: 'name_gen',
    name: '命名生成器',
    icon: Icons.edit_note,
    description: '生成人名、地名、物品名、势力名，支持东方/西方/奇幻/科幻等多种风格',
    route: '/generator/name_gen',
  ),
  GeneratorConfig(
    type: 'character_design',
    name: '角色设计',
    icon: Icons.person_outline,
    description: '创建完整角色，包含姓名、外貌、性格、背景故事、核心欲望和成长弧',
    route: '/generator/character_design',
  ),
  GeneratorConfig(
    type: 'world_building',
    name: '世界观构建',
    icon: Icons.public,
    description: '构建完整世界观，包含种族/势力、独特规则、历史事件和当前矛盾',
    route: '/generator/world_building',
  ),
  GeneratorConfig(
    type: 'glossary',
    name: '词条百科',
    icon: Icons.book_outlined,
    description: '生成道具、技能、功法、法宝等词条，含稀有度、效果描述、使用限制',
    route: '/generator/glossary',
  ),
];

/// 生成器分类标签
class GeneratorCategory {
  final String label;
  final List<String> generatorTypes;

  const GeneratorCategory({required this.label, required this.generatorTypes});
}

const List<GeneratorCategory> generatorCategories = [
  GeneratorCategory(
    label: '创意激发',
    generatorTypes: ['brain_hole', 'book_name', 'book_test'],
  ),
  GeneratorCategory(
    label: '大纲构建',
    generatorTypes: ['synopsis', 'outline', 'detail_outline'],
  ),
  GeneratorCategory(
    label: '精彩内容',
    generatorTypes: ['golden_opening', 'golden_finger'],
  ),
  GeneratorCategory(
    label: '角色与设定',
    generatorTypes: ['name_gen', 'character_design', 'world_building', 'glossary'],
  ),
];

/// 根据 type 查找生成器配置
GeneratorConfig getGeneratorByType(String type) {
  return allGenerators.firstWhere(
    (g) => g.type == type,
    orElse: () => throw ArgumentError('未知的生成器类型: $type'),
  );
}

/// 根据 type 查找生成器所属分类标签
String getCategoryByType(String type) {
  for (final category in generatorCategories) {
    if (category.generatorTypes.contains(type)) {
      return category.label;
    }
  }
  return '其他';
}

// ============================================================
// 颜色方案常量
// ============================================================

/// 主题色彩
class AppColors {
  AppColors._();

  // 主色调 - 深色文学风格
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryLight = Color(0xFF2D2D44);
  static const Color primaryDark = Color(0xFF0F0F1A);

  // 强调色
  static const Color accent = Color(0xFFE94560);
  static const Color accentLight = Color(0xFFFF6B81);
  static const Color accentDark = Color(0xFFC23152);

  // 文字色
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFF5F5F5);
  static const Color textOnDarkSecondary = Color(0xFFB0B0B0);

  // 背景色
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFF0F0F0);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 分类色彩 - 用于不同生成器类型的视觉区分
  static const Color categoryCreative = Color(0xFF7C4DFF);   // 创意激发 - 紫色
  static const Color categoryOutline = Color(0xFF2979FF);    // 大纲构建 - 蓝色
  static const Color categoryContent = Color(0xFFFF6D00);    // 精彩内容 - 橙色
  static const Color categoryCharacter = Color(0xFF00C853);  // 角色设定 - 绿色

  // 状态色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // 渐变配色方案（用于各类生成器的卡片/页眉渐变）
  static const List<Color> gradientCreative = [Color(0xFF7C4DFF), Color(0xFFB388FF)];
  static const List<Color> gradientOutline = [Color(0xFF2979FF), Color(0xFF82B1FF)];
  static const List<Color> gradientContent = [Color(0xFFFF6D00), Color(0xFFFFAB40)];
  static const List<Color> gradientCharacter = [Color(0xFF00C853), Color(0xFF69F0AE)];

  /// 根据生成器类型获取对应的分类色彩
  static Color getCategoryColorByType(String type) {
    for (final category in generatorCategories) {
      if (category.generatorTypes.contains(type)) {
        switch (category.label) {
          case '创意激发':
            return categoryCreative;
          case '大纲构建':
            return categoryOutline;
          case '精彩内容':
            return categoryContent;
          case '角色与设定':
            return categoryCharacter;
          default:
            return primaryLight;
        }
      }
    }
    return primaryLight;
  }

  /// 根据生成器类型获取对应的渐变色
  static List<Color> getGradientByType(String type) {
    for (final category in generatorCategories) {
      if (category.generatorTypes.contains(type)) {
        switch (category.label) {
          case '创意激发':
            return gradientCreative;
          case '大纲构建':
            return gradientOutline;
          case '精彩内容':
            return gradientContent;
          case '角色与设定':
            return gradientCharacter;
          default:
            return [primary, primaryLight];
        }
      }
    }
    return [primary, primaryLight];
  }
}

// ============================================================
// 默认封面模板路径
// ============================================================

class CoverTemplates {
  CoverTemplates._();

  static const String basePath = 'assets/cover_templates';

  static const String template1 = '$basePath/template_1.png';
  static const String template2 = '$basePath/template_2.png';
  static const String template3 = '$basePath/template_3.png';
  static const String template4 = '$basePath/template_4.png';
  static const String template5 = '$basePath/template_5.png';

  /// 所有封面模板路径列表
  static const List<String> allTemplates = [
    template1,
    template2,
    template3,
    template4,
    template5,
  ];

  /// 封面模板对应的风格名称
  static const Map<String, String> templateStyles = {
    'template_1': '玄幻仙侠',
    'template_2': '都市现代',
    'template_3': '古风典雅',
    'template_4': '科幻未来',
    'template_5': '暗黑悬疑',
  };

  /// 封面模板对应的色系
  static const Map<String, Color> templateColors = {
    'template_1': Color(0xFF4A148C),
    'template_2': Color(0xFF1B5E20),
    'template_3': Color(0xFF8D6E63),
    'template_4': Color(0xFF01579B),
    'template_5': Color(0xFF212121),
  };

  /// 获取模板路径（按索引，从 1 开始）
  static String getTemplatePath(int index) {
    if (index < 1 || index > 5) {
      throw ArgumentError('封面模板索引必须在 1-5 之间，当前值: $index');
    }
    return '$basePath/template_$index.png';
  }
}

// ============================================================
// 常见中文姓氏列表（200+ 个）
// ============================================================

const List<String> chineseSurnames = [
  // ---- 常见单姓（按使用频率排序）----
  '王', '李', '张', '刘', '陈', '杨', '黄', '赵', '吴', '周',
  '徐', '孙', '马', '朱', '胡', '郭', '何', '高', '林', '罗',
  '郑', '梁', '谢', '宋', '唐', '许', '韩', '冯', '邓', '曹',
  '彭', '曾', '萧', '田', '董', '潘', '袁', '蔡', '蒋', '余',
  '于', '杜', '叶', '程', '魏', '苏', '吕', '丁', '任', '卢',
  '姚', '沈', '钟', '姜', '崔', '谭', '陆', '范', '汪', '廖',
  '石', '金', '韦', '贾', '夏', '付', '方', '邹', '熊', '白',
  '孟', '秦', '邱', '侯', '江', '尹', '薛', '闫', '段', '雷',
  '龙', '黎', '史', '陶', '贺', '毛', '郝', '顾', '龚', '邵',
  '万', '覃', '武', '钱', '戴', '严', '莫', '孔', '向', '常',
  '温', '康', '施', '文', '牛', '樊', '葛', '邢', '安', '齐',
  '易', '乔', '伍', '庞', '颜', '倪', '庄', '聂', '章', '鲁',
  '岳', '翟', '殷', '詹', '申', '欧', '耿', '关', '兰', '焦',
  '俞', '左', '柳', '甘', '祝', '包', '宁', '尚', '符', '舒',
  '阮', '柯', '纪', '梅', '童', '凌', '毕', '单', '季', '裴',
  '霍', '涂', '成', '苗', '谷', '盛', '曲', '翁', '冉', '骆',
  '蓝', '路', '游', '辛', '靳', '管', '柴', '蒙', '蒲', '卫',
  '华', '尤', '车', '饶', '刁', '祁', '穆', '吉', '党', '瞿',
  '费', '卞', '时', '褚', '连', '花', '嵇', '艾', '匡', '时',
  '池', '滕', '荣', '卓', '沙', '迟', '窦', '甄', '乐', '桑',
  '冷', '应', '卜', '盛', '宗', '商', '衣', '米', '耿', '司',

  // ---- 复姓 ----
  '欧阳', '司马', '上官', '诸葛', '慕容', '夏侯', '令狐', '宇文',
  '皇甫', '尉迟', '公羊', '长孙', '东方', '独孤', '南宫', '万俟',
  '闻人', '赫连', '澹台', '公冶', '宗政', '濮阳', '淳于', '单于',
  '太叔', '申屠', '公孙', '仲孙', '轩辕', '钟离', '鲜于', '亓官',
  '司空', '司寇', '子车', '端木', '巫马', '公西', '漆雕', '乐正',
  '百里', '夹谷', '宰父', '谷梁', '拓跋', '呼延', '慕容', '贺兰',
  '南门', '北宫', '东门', '西门',

  // ---- 其他补充 ----
  '纪', '昌', '郜', '鄂', '郁', '竺', '权', '逯', '盖', '益',
  '桓', '公', '谌', '蒯', '靳', '汲', '邴', '糜', '松', '井',
  '富', '巫', '乌', '焦', '巴', '弓', '牧', '隗', '山', '宓',
  '蓬', '全', '郗', '班', '仰', '秋', '仲', '伊', '宫', '宁',
  '仇', '栾', '暴', '钭', '厉', '戎', '祖', '景', '詹', '束',
  '龙', '幸', '韶', '郜', '黎', '蓟', '印', '宿', '怀', '蒲',
  '邰', '鄂', '索', '籍', '赖', '卓', '蔺', '屠', '蒙', '乔',
  '双', '闻', '莘', '党', '翟', '谭', '贡', '劳', '逄', '姬',
  '申', '扶', '堵', '冉', '宰', '郦', '雍', '璩', '桑', '桂',
  '濮', '牛', '寿', '通', '边', '扈', '燕', '冀', '尚', '农',
];

/// 随机获取一个中文姓氏
String getRandomSurname() {
  return (chineseSurnames.toList()..shuffle()).first;
}

/// 获取指定数量的随机姓氏（不重复）
List<String> getRandomSurnames(int count) {
  final shuffled = chineseSurnames.toList()..shuffle();
  return shuffled.take(count).toList();
}