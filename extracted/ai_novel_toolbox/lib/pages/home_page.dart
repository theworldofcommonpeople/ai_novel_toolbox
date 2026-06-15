import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'bookname_test_page.dart';
import 'character_list_page.dart';
import 'consistency_check_page.dart';
import 'cover_generator_page.dart';
import 'generator_base.dart';
import 'settings_page.dart';

/// 首页：AI小说创作工具箱主页面
/// 2列滚动网格展示全部16个功能卡片
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ─── 4 个特殊功能卡片（不包含在 allGenerators 中） ───
  static const List<Map<String, dynamic>> _specialCards = [
    {
      'type': 'book_test',
      'name': '书名测试',
      'description': '测试小说书名的吸引力与市场潜力',
      'icon': Icons.preview,
    },
    {
      'type': 'cover_gen',
      'name': '封面生成器',
      'description': 'AI生成精美小说封面与宣传图',
      'icon': Icons.image,
    },
    {
      'type': 'character_list',
      'name': '角色卡管理',
      'description': '集中管理所有小说角色设定卡片',
      'icon': Icons.people,
    },
    {
      'type': 'consistency_check',
      'name': '一致性检查',
      'description': '检查跨章节内容逻辑与设定一致性',
      'icon': Icons.checklist,
    },
  ];

  // ─── 卡片渐变色系（循环使用） ───
  static const List<List<Color>> _cardGradients = [
    [Color(0xFF6C63FF), Color(0xFF3F3D9E)],   // 紫
    [Color(0xFFE040FB), Color(0xFF9C27B0)],   // 粉紫
    [Color(0xFF448AFF), Color(0xFF1565C0)],   // 蓝
    [Color(0xFF00BCD4), Color(0xFF00838F)],   // 青
    [Color(0xFF4CAF50), Color(0xFF2E7D32)],   // 绿
    [Color(0xFFFF6D00), Color(0xFFE65100)],   // 橙
    [Color(0xFFFF4081), Color(0xFFC51162)],   // 玫红
    [Color(0xFF7C4DFF), Color(0xFF651FFF)],   // 深紫
    [Color(0xFF00E5FF), Color(0xFF00B8D4)],   // 亮青
    [Color(0xFF69F0AE), Color(0xFF00C853)],   // 亮绿
    [Color(0xFFFFD740), Color(0xFFFFAB00)],   // 琥珀
    [Color(0xFFFF6E40), Color(0xFFDD2C00)],   // 深橙
    [Color(0xFF40C4FF), Color(0xFF0091EA)],   // 天蓝
    [Color(0xFFB388FF), Color(0xFF7C4DFF)],   // 淡紫
    [Color(0xFFFF80AB), Color(0xFFF50057)],   // 浅粉
    [Color(0xFF84FFFF), Color(0xFF18FFFF)],   // 极青
  ];

  /// 将生成器映射到目标页面
  Widget _buildTargetPage(String type) {
    switch (type) {
      case 'book_test':
        return const BooknameTestPage();
      case 'cover_gen':
        return const CoverGeneratorPage();
      case 'character_list':
        return const CharacterListPage();
      case 'consistency_check':
        return const ConsistencyCheckPage();
      default:
        // 12 个文本生成器统一使用 GeneratorBase
        return GeneratorBase(generatorType: type);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 合并基础生成器 + 特殊卡片，共 16 个
    final allCards = [
      ...allGenerators,
      ..._specialCards,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI小说创作工具箱'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemCount: allCards.length,
        itemBuilder: (context, index) {
          final card = allCards[index];
          return _FeatureCard(
            icon: card['icon'] as IconData,
            name: card['name'] as String,
            description: card['description'] as String,
            gradientColors: _cardGradients[index % _cardGradients.length],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _buildTargetPage(card['type'] as String),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 单个功能卡片组件
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: gradientColors.first.withOpacity(0.3),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const Spacer(),
                // 名称
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 描述
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}