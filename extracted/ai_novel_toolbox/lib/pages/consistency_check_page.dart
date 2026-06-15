import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/character_card.dart';
import '../models/novel_project.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/diff_viewer.dart';

/// ============================================================
/// 一致性检查页面
/// ============================================================
///
/// 对小说项目中角色设定的一致性进行半自动检查与修改。
/// 流程：
/// 1. 选择小说项目和目标角色
/// 2. 扫描所有章节，查找包含角色名称的段落
/// 3. 与角色卡设定对比，找出冲突段落
/// 4. 用户选择冲突段落，AI 逐段修改
/// 5. 展示修改前后差异，用户确认后应用
class ConsistencyCheckPage extends StatefulWidget {
  const ConsistencyCheckPage({super.key});

  @override
  State<ConsistencyCheckPage> createState() => _ConsistencyCheckPageState();
}

// ============================================================
// 冲突段落数据模型
// ============================================================

/// 表示一个与角色卡设定冲突的段落
class _ConflictItem {
  /// 章节编号
  final int chapterNumber;

  /// 章节标题
  final String? chapterTitle;

  /// 冲突段落原文
  final String paragraphText;

  /// 冲突描述（为什么判定为冲突）
  final String conflictReason;

  /// 是否被选中以进行修改
  bool isSelected;

  /// 修改后的文本（AI 生成后设置）
  String? modifiedText;

  /// 是否已确认修改
  bool isConfirmed;

  _ConflictItem({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.paragraphText,
    required this.conflictReason,
    this.isSelected = true,
    this.modifiedText,
    this.isConfirmed = false,
  });
}

// ============================================================
// State
// ============================================================

class _ConsistencyCheckPageState extends State<ConsistencyCheckPage> {
  // ============================================================
  // 数据
  // ============================================================

  List<NovelProject> _projects = [];
  List<CharacterCard> _characters = [];

  NovelProject? _selectedProject;
  CharacterCard? _selectedCharacter;

  /// 解析后的角色卡属性
  Map<String, String> _characterAttributes = {};

  /// 冲突段落列表
  List<_ConflictItem> _conflictItems = [];

  // ============================================================
  // 状态
  // ============================================================

  bool _isLoadingProjects = true;
  bool _isLoadingCharacters = false;
  bool _isChecking = false;
  bool _isModifying = false;
  bool _isApplying = false;

  String? _errorMessage;
  String? _statusMessage;

  /// 修改进度: 当前修改的索引 / 总数
  int _modifyProgress = 0;
  int _modifyTotal = 0;

  final AiService _aiService = AiService();
  final StorageService _storage = StorageService.instance;

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // ============================================================
  // 数据加载
  // ============================================================

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
      _errorMessage = null;
    });

    try {
      final projects = await _storage.getAllNovelProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProjects = false;
        _errorMessage = '加载项目列表失败: $e';
      });
    }
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoadingCharacters = true;
    });

    try {
      final characters = await _storage.getAllCharacters();
      if (!mounted) return;
      setState(() {
        _characters = characters;
        _isLoadingCharacters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCharacters = false;
        _errorMessage = '加载角色列表失败: $e';
      });
    }
  }

  // ============================================================
  // 项目选择
  // ============================================================

  Future<void> _onProjectSelected(NovelProject? project) async {
    setState(() {
      _selectedProject = project;
      _selectedCharacter = null;
      _characterAttributes = {};
      _conflictItems = [];
      _errorMessage = null;
      _statusMessage = null;
    });

    if (project != null) {
      await _loadCharacters();
    }
  }

  // ============================================================
  // 角色选择
  // ============================================================

  void _onCharacterSelected(CharacterCard? character) {
    setState(() {
      _selectedCharacter = character;
      _conflictItems = [];
      _errorMessage = null;
      _statusMessage = null;
    });

    if (character != null) {
      _characterAttributes = _parseCardJson(character.cardJson);
    } else {
      _characterAttributes = {};
    }
  }

  /// 解析角色卡 JSON，提取关键属性
  Map<String, String> _parseCardJson(String cardJson) {
    final result = <String, String>{};
    try {
      final json = jsonDecode(cardJson) as Map<String, dynamic>;
      result['name'] = (json['name'] ?? json['姓名'] ?? json['名字'] ?? '') as String? ?? '';
      result['gender'] = (json['gender'] ?? json['性别'] ?? '') as String? ?? '';
      result['age'] = (json['age'] ?? json['年龄'] ?? '')?.toString() ?? '';
      result['personality'] = (json['personality'] ?? json['性格'] ?? '') as String? ?? '';
      result['background'] = (json['background'] ?? json['背景'] ?? '') as String? ?? '';
      result['appearance'] = (json['appearance'] ?? json['外貌'] ?? '') as String? ?? '';
      result['role'] = (json['role'] ?? json['角色定位'] ?? json['定位'] ?? '') as String? ?? '';
      result['ability'] = (json['ability'] ?? json['能力'] ?? json['技能'] ?? '') as String? ?? '';
      result['goal'] = (json['goal'] ?? json['目标'] ?? '') as String? ?? '';
    } catch (_) {
      // 解析失败
    }
    return result;
  }

  // ============================================================
  // 一致性检查
  // ============================================================

  Future<void> _onStartCheck() async {
    if (_selectedProject == null) {
      _showSnackBar('请先选择小说项目');
      return;
    }
    if (_selectedCharacter == null) {
      _showSnackBar('请先选择要检查的角色');
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _statusMessage = '正在扫描章节...';
      _conflictItems = [];
    });

    try {
      final characterName = _selectedCharacter!.name;
      final chapters = await _storage.getChaptersByProjectId(_selectedProject!.id!);

      if (!mounted) return;

      if (chapters.isEmpty) {
        setState(() {
          _isChecking = false;
          _statusMessage = '该项目暂无章节内容';
        });
        return;
      }

      final conflicts = <_ConflictItem>[];
      int totalScanned = 0;

      for (final chapter in chapters) {
        final content = chapter.content;
        if (content == null || content.isEmpty) continue;

        // 将内容按段落分割
        final paragraphs = content.split(RegExp(r'\n{2,}'));
        for (final paragraph in paragraphs) {
          final trimmed = paragraph.trim();
          if (trimmed.isEmpty) continue;

          // 只检查包含角色名称的段落
          if (!trimmed.contains(characterName)) continue;

          totalScanned++;

          // 检测冲突
          final List<String> conflictReasons = _detectConflicts(
            trimmed,
            _characterAttributes,
          );

          if (conflictReasons.isNotEmpty) {
            conflicts.add(_ConflictItem(
              chapterNumber: chapter.chapterNumber,
              chapterTitle: chapter.title,
              paragraphText: trimmed,
              conflictReason: conflictReasons.join('；'),
            ));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _conflictItems = conflicts;
        if (conflicts.isEmpty) {
          _statusMessage = '检查完成：共扫描 $totalScanned 个相关段落，未发现冲突。';
        } else {
          _statusMessage = '检查完成：共扫描 $totalScanned 个段落，发现 ${conflicts.length} 处疑似冲突。';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _errorMessage = '检查失败: $e';
        _statusMessage = null;
      });
    }
  }

  /// 检测段落与角色卡设定是否存在冲突
  List<String> _detectConflict(
    String paragraph,
    Map<String, String> attributes,
  ) {
    final reasons = <String>[];

    // 性别冲突检测
    if (attributes['gender']?.isNotEmpty == true) {
      final gender = attributes['gender']!;
      if (gender == '男' || gender == '男性') {
        if (paragraph.contains('她') && !paragraph.contains('他')) {
          reasons.add('性别描述不一致：角色卡为男，段落使用"她"');
        }
      } else if (gender == '女' || gender == '女性') {
        if (paragraph.contains('他') && !paragraph.contains('她')) {
          reasons.add('性别描述不一致：角色卡为女，段落使用"他"');
        }
      }
    }

    // 年龄冲突检测（简单关键词匹配）
    if (attributes['age']?.isNotEmpty == true) {
      final age = int.tryParse(attributes['age']!);
      if (age != null) {
        if (age < 18 && (paragraph.contains('成年') || paragraph.contains('老'))) {
          reasons.add('年龄描述可能不一致：角色卡为${age}岁');
        }
        if (age > 60 && paragraph.contains('年轻')) {
          reasons.add('年龄描述可能不一致：角色卡为${age}岁');
        }
      }
    }

    // 外貌冲突检测（检查颜色关键词）
    if (attributes['appearance']?.isNotEmpty == true) {
      final appearance = attributes['appearance']!;
      // 头发颜色
      if (appearance.contains('黑发') || appearance.contains('黑色头发')) {
        if (paragraph.contains('金发') || paragraph.contains('白发') || paragraph.contains('红发')) {
          reasons.add('外貌描述冲突：角色卡为黑发，段落描述不同发色');
        }
      }
      if (appearance.contains('金发') || appearance.contains('金色头发')) {
        if (paragraph.contains('黑发') || paragraph.contains('白发')) {
          reasons.add('外貌描述冲突：角色卡为金发，段落描述不同发色');
        }
      }
      // 瞳色
      if (appearance.contains('黑瞳') || appearance.contains('黑色眼睛')) {
        if (paragraph.contains('蓝瞳') || paragraph.contains('金瞳') || paragraph.contains('红瞳')) {
          reasons.add('外貌描述冲突：角色卡为黑瞳，段落描述不同瞳色');
        }
      }
    }

    // 能力冲突检测（简单能力关键词）
    if (attributes['ability']?.isNotEmpty == true) {
      final ability = attributes['ability']!;
      if (ability.contains('无法') || ability.contains('不会') || ability.contains('没有')) {
        // 角色卡明确说没有某种能力
        if (ability.contains('修炼') && paragraph.contains('修炼')) {
          reasons.add('能力描述冲突：角色卡说明无法修炼，段落提及修炼');
        }
        if (ability.contains('魔法') && paragraph.contains('魔法')) {
          reasons.add('能力描述冲突：角色卡说明不会魔法，段落提及魔法');
        }
      }
    }

    return reasons;
  }

  /// 检测段落与角色卡设定是否存在冲突（批量版本，用于内部调用）
  List<String> _detectConflicts(
    String paragraph,
    Map<String, String> attributes,
  ) {
    return _detectConflict(paragraph, attributes);
  }

  // ============================================================
  // 逐章修改
  // ============================================================

  Future<void> _onStartModify() async {
    final selectedItems = _conflictItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      _showSnackBar('请至少选择一个冲突段落进行修改');
      return;
    }

    setState(() {
      _isModifying = true;
      _errorMessage = null;
      _modifyProgress = 0;
      _modifyTotal = selectedItems.length;
      _statusMessage = '开始逐章修改...';
    });

    try {
      final characterName = _selectedCharacter!.name;
      final cardJson = _selectedCharacter!.cardJson;

      for (int i = 0; i < selectedItems.length; i++) {
        final item = selectedItems[i];

        setState(() {
          _modifyProgress = i + 1;
          _statusMessage = '正在修改第 ${item.chapterNumber} 章冲突段落 (${i + 1}/$_modifyTotal)...';
        });

        // 构建 AI 修改提示词
        final systemPrompt = '''
你是一个小说编辑助手。你的任务是根据角色的设定卡，修改小说段落中与角色设定不一致的描述。

角色设定卡（JSON 格式）：
$cardJson

请根据以上角色设定，修改下面段落中不一致的描述，使其与角色设定保持一致。
只修改与设定冲突的部分，保持其他内容不变。
直接返回修改后的完整段落，不要添加任何解释或标记。''';

        final userMessage = '''
第${item.chapterNumber}章，冲突原因：${item.conflictReason}

原始段落：
${item.paragraphText}''';

        try {
          final modifiedText = await _aiService.generateText(
            systemPrompt,
            userMessage,
          );

          if (!mounted) return;

          setState(() {
            item.modifiedText = modifiedText.trim();
          });
        } catch (e) {
          setState(() {
            item.modifiedText = '【修改失败】$e';
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _isModifying = false;
        _statusMessage = '修改完成，请查看每个段落的修改结果并确认。';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isModifying = false;
        _errorMessage = '修改过程出错: $e';
        _statusMessage = null;
      });
    }
  }

  // ============================================================
  // 确认并应用修改
  // ============================================================

  Future<void> _onApplyChanges() async {
    final modifiedItems = _conflictItems
        .where((item) => item.isSelected && item.modifiedText != null)
        .toList();

    if (modifiedItems.isEmpty) {
      _showSnackBar('没有可应用的修改');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认应用修改'),
          content: Text(
            '即将应用 ${modifiedItems.length} 处修改到对应章节。\n\n此操作将直接修改章节内容，建议先备份。是否继续？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认应用'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isApplying = true;
      _statusMessage = '正在应用修改...';
    });

    try {
      // 按章节分组修改
      final chapterModifications = <int, Map<int, String>>{};

      for (int i = 0; i < _conflictItems.length; i++) {
        final item = _conflictItems[i];
        if (item.isSelected && item.modifiedText != null) {
          final chapterNum = item.chapterNumber;
          chapterModifications.putIfAbsent(chapterNum, () => {});
          chapterModifications[chapterNum]![i] = item.modifiedText!;
        }
      }

      for (final entry in chapterModifications.entries) {
        final chapterNumber = entry.key;
        final chapter = await _storage.getChapterByProjectAndNumber(
          _selectedProject!.id!,
          chapterNumber,
        );

        if (chapter == null || chapter.content == null) continue;

        String content = chapter.content!;

        // 对每个修改项，替换对应段落
        for (final modEntry in entry.value.entries) {
          final itemIndex = modEntry.key;
          final newText = modEntry.value;
          final oldText = _conflictItems[itemIndex].paragraphText;

          if (content.contains(oldText)) {
            content = content.replaceFirst(oldText, newText);
            _conflictItems[itemIndex].isConfirmed = true;
          }
        }

        final updatedChapter = chapter.copyWith(
          content: content,
          wordCount: content.length,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _storage.saveChapter(updatedChapter);
      }

      if (!mounted) return;

      setState(() {
        _isApplying = false;
        _statusMessage = '修改已成功应用到章节内容。';
      });
      _showSnackBar('修改已应用');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isApplying = false;
        _errorMessage = '应用修改失败: $e';
        _statusMessage = null;
      });
    }
  }

  // ============================================================
  // 显示差异对比
  // ============================================================

  void _showDiffViewer(_ConflictItem item) {
    if (item.modifiedText == null) {
      _showSnackBar('该段落尚未修改');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // 拖动指示器
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                // 标题
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.compare_arrows, color: Color(0xFF7C4DFF), size: 20.0),
                      const SizedBox(width: 8.0),
                      Text(
                        '第${item.chapterNumber}章 修改对比',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            item.isConfirmed = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('确认修改'),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2A2A3A)),
                // 差异查看器
                Expanded(
                  child: DiffViewer(
                    originalText: item.paragraphText,
                    modifiedText: item.modifiedText!,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 工具方法
  // ============================================================

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 截断文本用于预览
  String _truncateText(String text, {int maxLength = 80}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('一致性检查'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 第 1 节：选择项目 ──
            _buildSectionTitle('选择项目'),
            const SizedBox(height: 8.0),
            if (_isLoadingProjects)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              DropdownButtonFormField<NovelProject>(
                value: _selectedProject,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.folder_outlined),
                  hintText: '请选择小说项目',
                ),
                isExpanded: true,
                items: _projects.map((project) {
                  return DropdownMenuItem<NovelProject>(
                    value: project,
                    child: Text(
                      project.projectName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _onProjectSelected,
              ),

            const SizedBox(height: 20.0),

            // ── 第 2 节：选择角色 ──
            _buildSectionTitle('选择角色'),
            const SizedBox(height: 8.0),
            if (_isLoadingCharacters)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              DropdownButtonFormField<CharacterCard>(
                value: _selectedCharacter,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: '请选择要检查的角色',
                ),
                isExpanded: true,
                items: _characters.map((character) {
                  return DropdownMenuItem<CharacterCard>(
                    value: character,
                    child: Text(
                      character.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _onCharacterSelected,
              ),

            const SizedBox(height: 20.0),

            // ── 第 3 节：修改角色卡 ──
            if (_characterAttributes.isNotEmpty) ...[
              _buildSectionTitle('修改角色卡'),
              const SizedBox(height: 8.0),
              _buildCharacterCardPreview(),
              const SizedBox(height: 20.0),
            ],

            // ── 开始检查按钮 ──
            FilledButton.icon(
              onPressed: (_isChecking || _isModifying || _isApplying)
                  ? null
                  : _onStartCheck,
              icon: _isChecking
                  ? const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isChecking ? '检查中...' : '开始检查'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // ── 错误提示 ──
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),

            // ── 状态消息 ──
            if (_statusMessage != null) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 修改进度 ──
            if (_isModifying && _modifyTotal > 0) ...[
              const SizedBox(height: 16.0),
              LinearProgressIndicator(
                value: _modifyProgress / _modifyTotal,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 4.0),
              Text(
                '修改进度: $_modifyProgress / $_modifyTotal',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // ── 冲突段落列表 ──
            if (_conflictItems.isNotEmpty) ...[
              const SizedBox(height: 20.0),
              _buildSectionTitle('冲突段落列表'),
              const SizedBox(height: 8.0),

              // 全选/取消全选
              Row(
                children: [
                  Checkbox(
                    value: _conflictItems.every((item) => item.isSelected),
                    tristate: true,
                    onChanged: (value) {
                      setState(() {
                        final newValue = value ?? true;
                        for (final item in _conflictItems) {
                          item.isSelected = newValue;
                        }
                      });
                    },
                  ),
                  const Text(
                    '全选',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_conflictItems.where((i) => i.isSelected).length} / ${_conflictItems.length}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),

              ..._conflictItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildConflictCard(index, item);
              }),

              const SizedBox(height: 16.0),

              // ── 逐章修改按钮 ──
              FilledButton.icon(
                onPressed: (_isModifying || _isApplying) ? null : _onStartModify,
                icon: _isModifying
                    ? const SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isModifying ? '修改中...' : '逐章修改'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  backgroundColor: const Color(0xFF7C4DFF),
                ),
              ),

              const SizedBox(height: 12.0),

              // ── 应用修改按钮 ──
              OutlinedButton.icon(
                onPressed: (_isApplying || _isModifying)
                    ? null
                    : _onApplyChanges,
                icon: _isApplying
                    ? const SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isApplying ? '应用修改...' : '确认并应用修改'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建角色卡预览
  Widget _buildCharacterCardPreview() {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _characterAttributes.entries
              .where((e) => e.value.isNotEmpty)
              .map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_getAttributeLabel(entry.key)}: ',
                      style: const TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: entry.value,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getAttributeLabel(String key) {
    const labels = {
      'name': '姓名',
      'gender': '性别',
      'age': '年龄',
      'personality': '性格',
      'background': '背景',
      'appearance': '外貌',
      'role': '定位',
      'ability': '能力',
      'goal': '目标',
    };
    return labels[key] ?? key;
  }

  /// 构建单个冲突卡片
  Widget _buildConflictCard(int index, _ConflictItem item) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Checkbox(
                  value: item.isSelected,
                  onChanged: (value) {
                    setState(() {
                      item.isSelected = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第${item.chapterNumber}章${item.chapterTitle != null ? " ${item.chapterTitle!}" : ""}',
                        style: const TextStyle(
                          color: Color(0xFF7C4DFF),
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        _truncateText(item.paragraphText),
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 12.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6.0),

            // 冲突原因
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 14.0,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      item.conflictReason,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 修改结果
            if (item.modifiedText != null) ...[
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.isConfirmed
                          ? Icons.check_circle
                          : Icons.edit_note,
                      color: item.isConfirmed
                          ? Colors.green
                          : Colors.white54,
                      size: 16.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _truncateText(
                          item.modifiedText!,
                          maxLength: 100,
                        ),
                        style: TextStyle(
                          color: item.isConfirmed
                              ? Colors.green.shade200
                              : Colors.white70,
                          fontSize: 11.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    GestureDetector(
                      onTap: () => _showDiffViewer(item),
                      child: const Icon(
                        Icons.compare_arrows,
                        color: Color(0xFF7C4DFF),
                        size: 18.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建区块标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}