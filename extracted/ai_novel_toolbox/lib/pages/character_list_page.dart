import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/character_card.dart';
import '../services/storage_service.dart';

/// ============================================================
/// 角色卡管理页面
/// ============================================================
///
/// 展示所有角色卡列表，支持展开查看详情、添加新角色、
/// 编辑角色信息、滑动删除角色等功能。
class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  // ============================================================
  // 状态
  // ============================================================

  List<CharacterCard> _characters = [];
  bool _isLoading = true;
  String? _errorMessage;

  final StorageService _storage = StorageService.instance;

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  // ============================================================
  // 数据加载
  // ============================================================

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final characters = await _storage.getAllCharacters();
      if (!mounted) return;
      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载角色列表失败: $e';
      });
    }
  }

  // ============================================================
  // 角色操?
  // ============================================================

  /// 添加新角色
  Future<void> _onAddCharacter() async {
    final result = await showDialog<CharacterCard>(
      context: context,
      builder: (_) => const _CharacterEditDialog(),
    );

    if (result != null) {
      try {
        await _storage.saveCharacter(result);
        await _loadCharacters();
        if (mounted) {
          _showSnackBar('角色「${result.name}」已添加');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('添加失败: $e');
        }
      }
    }
  }

  /// 编辑角色
  Future<void> _onEditCharacter(CharacterCard character) async {
    final result = await showDialog<CharacterCard>(
      context: context,
      builder: (_) => _CharacterEditDialog(existingCharacter: character),
    );

    if (result != null) {
      try {
        await _storage.saveCharacter(result);
        await _loadCharacters();
        if (mounted) {
          _showSnackBar('角色「${result.name}」已更新');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('更新失败: $e');
        }
      }
    }
  }

  /// 删除角色
  Future<void> _onDeleteCharacter(CharacterCard character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除角色「${character.name}」吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && character.id != null) {
      try {
        await _storage.deleteCharacter(character.id!);
        await _loadCharacters();
        if (mounted) {
          _showSnackBar('角色「${character.name}」已删除');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('删除失败: $e');
        }
      }
    }
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

  /// 从 card_json 解析角色详细属性
  Map<String, String> _parseCharacterDetail(String cardJson) {
    final result = <String, String>{};
    try {
      final json = jsonDecode(cardJson) as Map<String, dynamic>;
      // 提取常见字段
      result['name'] = (json['name'] ?? json['姓名'] ?? json['名字'] ?? '') as String? ?? '';
      result['gender'] = (json['gender'] ?? json['性别'] ?? '') as String? ?? '';
      result['age'] = (json['age'] ?? json['年龄'] ?? '')?.toString() ?? '';
      result['personality'] = (json['personality'] ?? json['性格'] ?? '') as String? ?? '';
      result['background'] = (json['background'] ?? json['背景'] ?? json['背景故事'] ?? '') as String? ?? '';
      result['appearance'] = (json['appearance'] ?? json['外貌'] ?? json['外貌描述'] ?? '') as String? ?? '';
      result['role'] = (json['role'] ?? json['角色定位'] ?? json['定位'] ?? '') as String? ?? '';
      result['ability'] = (json['ability'] ?? json['能力'] ?? json['技能'] ?? '') as String? ?? '';
      result['goal'] = (json['goal'] ?? json['目标'] ?? json['核心欲望'] ?? '') as String? ?? '';
      result['motto'] = (json['motto'] ?? json['口头禅'] ?? '') as String? ?? '';
      result['relationship'] = (json['relationship'] ?? json['关系'] ?? json['人际关系'] ?? '') as String? ?? '';
    } catch (_) {
      // 解析失败时返回空 Map
    }
    return result;
  }

  /// 格式化时间戳为可读字符串
  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色卡管理'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadCharacters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddCharacter,
        icon: const Icon(Icons.person_add),
        label: const Text('添加角色'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.0),
            Text(
              '加载角色列表...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.0,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12.0),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            OutlinedButton(
              onPressed: _loadCharacters,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64.0,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16.0),
            Text(
              '暂无角色',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              '点击右下角按钮添加第一个角色',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharacters,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 8.0,
          left: 12.0,
          right: 12.0,
          bottom: 80.0, // 为 FAB 留出空间
        ),
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          final details = _parseCharacterDetail(character.cardJson);

          return _CharacterCardTile(
            character: character,
            details: details,
            formattedTime: _formatTimestamp(character.updatedAt),
            onEdit: () => _onEditCharacter(character),
            onDelete: () => _onDeleteCharacter(character),
          );
        },
      ),
    );
  }
}

// ============================================================
// 角色卡片 ExpansionTile
// ============================================================

class _CharacterCardTile extends StatelessWidget {
  final CharacterCard character;
  final Map<String, String> details;
  final String formattedTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CharacterCardTile({
    required this.character,
    required this.details,
    required this.formattedTime,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _surfaceColor = Color(0xFF1E1E2E);
  static const Color _borderColor = Color(0xFF2A2A3A);
  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _textHint = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: _borderColor),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: Key('character_${character.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false; // 由 onDelete 内部处理确认对话框
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: ExpansionTile(
          // ── 标题行 ──
          leading: CircleAvatar(
            backgroundColor: _accentColor.withOpacity(0.3),
            child: Text(
              character.name.isNotEmpty ? character.name[0] : '?',
              style: const TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            character.name,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15.0,
            ),
          ),
          subtitle: Row(
            children: [
              if (details['gender']?.isNotEmpty == true) ...[
                _buildInfoChip(details['gender']!),
                const SizedBox(width: 8.0),
              ],
              if (details['age']?.isNotEmpty == true) ...[
                _buildInfoChip('${details['age']}岁'),
                const SizedBox(width: 8.0),
              ],
              if (details['role']?.isNotEmpty == true)
                _buildInfoChip(details['role']!),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18.0),
                color: _textSecondary,
                tooltip: '编辑',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18.0),
                color: Colors.red.shade300,
                tooltip: '删除',
                onPressed: onDelete,
              ),
            ],
          ),

          // ── 展开详情 ──
          childrenPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          children: [
            const Divider(color: _borderColor),
            const SizedBox(height: 8.0),

            // 基本信息
            if (details['gender']?.isNotEmpty == true ||
                details['age']?.isNotEmpty == true ||
                details['role']?.isNotEmpty == true)
              _buildDetailSection('基本信息', [
                if (details['gender']?.isNotEmpty == true)
                  _DetailItem(label: '性别', value: details['gender']!),
                if (details['age']?.isNotEmpty == true)
                  _DetailItem(label: '年龄', value: details['age']!),
                if (details['role']?.isNotEmpty == true)
                  _DetailItem(label: '定位', value: details['role']!),
              ]),

            // 性格
            if (details['personality']?.isNotEmpty == true)
              _buildDetailSection('性格特点', [
                _DetailItem(label: '性格', value: details['personality']!),
              ]),

            // 外貌
            if (details['appearance']?.isNotEmpty == true)
              _buildDetailSection('外貌描述', [
                _DetailItem(label: '外貌', value: details['appearance']!),
              ]),

            // 背景故事
            if (details['background']?.isNotEmpty == true)
              _buildDetailSection('背景故事', [
                _DetailItem(label: '背景', value: details['background']!),
              ]),

            // 能力技能
            if (details['ability']?.isNotEmpty == true)
              _buildDetailSection('能力技能', [
                _DetailItem(label: '能力', value: details['ability']!),
              ]),

            // 目标
            if (details['goal']?.isNotEmpty == true)
              _buildDetailSection('核心目标', [
                _DetailItem(label: '目标', value: details['goal']!),
              ]),

            // 口头禅
            if (details['motto']?.isNotEmpty == true)
              _buildDetailSection('口头禅', [
                _DetailItem(label: '口头禅', value: details['motto']!),
              ]),

            // 人际关系
            if (details['relationship']?.isNotEmpty == true)
              _buildDetailSection('人际关系', [
                _DetailItem(
                    label: '关系', value: details['relationship']!),
              ]),

            // 更新时间
            const SizedBox(height: 8.0),
            Text(
              '最后更新: $formattedTime',
              style: const TextStyle(
                color: _textHint,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _accentColor,
          fontSize: 11.0,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _accentColor,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4.0),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item.label}: ',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: item.value,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});
}

// ============================================================
// 角色编辑/添加对话框
// ============================================================

class _CharacterEditDialog extends StatefulWidget {
  final CharacterCard? existingCharacter;

  const _CharacterEditDialog({this.existingCharacter});

  @override
  State<_CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<_CharacterEditDialog> {
  final _nameController = TextEditingController();
  final _cardJsonController = TextEditingController();

  bool get _isEditing => widget.existingCharacter != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingCharacter != null) {
      _nameController.text = widget.existingCharacter!.name;
      _cardJsonController.text = _formatJson(widget.existingCharacter!.cardJson);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardJsonController.dispose();
    super.dispose();
  }

  /// 格式化 JSON 字符串为缩进格式
  String _formatJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return jsonStr;
    }
  }

  /// 验证并返回角色卡对象
  CharacterCard? _validateAndBuild() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return null;

    final cardJson = _cardJsonController.text.trim();
    if (cardJson.isEmpty) return null;

    // 验证 JSON 格式
    try {
      jsonDecode(cardJson);
    } catch (_) {
      return null;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return CharacterCard(
      id: widget.existingCharacter?.id,
      name: name,
      cardJson: cardJson,
      createdAt: widget.existingCharacter?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑角色' : '添加角色'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 角色名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '角色名称',
                hintText: '请输入角色名称',
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16.0),

            // Card JSON
            TextField(
              controller: _cardJsonController,
              decoration: const InputDecoration(
                labelText: '角色卡 JSON',
                hintText: '''{
  "name": "角色名",
  "gender": "男",
  "age": "25",
  "personality": "性格描述",
  "background": "背景故事",
  "appearance": "外貌描述",
  "role": "主角/配角/反派",
  "ability": "能力或技能",
  "goal": "核心目标",
  "motto": "口头禅",
  "relationship": "人际关系"
}''',
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final character = _validateAndBuild();
            if (character == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请填写完整的角色信息，card_json 必须为有效 JSON 格式'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            Navigator.pop(context, character);
          },
          child: Text(_isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}