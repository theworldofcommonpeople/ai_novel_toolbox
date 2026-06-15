import 'package:flutter/material.dart';
import '../models/generation_history.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// ============================================================
/// HistoryList - 生成历史记录列表组件
/// ============================================================
///
/// 展示所有历史生成记录，支持：
///   - 按生成器类型筛选
///   - 点击查看详情
///   - 滑动删除（带确认弹窗）
///   - 下拉刷新
///   - 时间格式化展示
///
/// 使用方式：
/// ```dart
/// HistoryList(
///   onSelect: (history) => loadHistory(history),
/// )
/// ```
class HistoryList extends StatefulWidget {
  /// 选中某条历史记录的回调
  final void Function(GenerationHistory history)? onSelect;

  const HistoryList({
    super.key,
    this.onSelect,
  });

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  // ============================================================
  // 深色主题色彩常量
  // ============================================================

  static const Color _bgColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1E1E2E);
  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _borderColor = Color(0xFF2A2A3A);
  static const Color _deleteColor = Color(0xFFCF6679);
  static const Color _cardColor = Color(0xFF1A1A2A);

  List<GenerationHistory> _allHistory = [];
  List<GenerationHistory> _filteredHistory = [];
  String? _selectedFilterType;
  bool _isLoading = true;

  final StorageService _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      _allHistory = await _storage.getGenerationHistory();
      _applyFilter();
    } catch (e) {
      _allHistory = [];
      _filteredHistory = [];
    }
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    if (_selectedFilterType == null || _selectedFilterType!.isEmpty) {
      _filteredHistory = List.from(_allHistory);
    } else {
      _filteredHistory = _allHistory
          .where((h) => h.generatorType == _selectedFilterType)
          .toList();
    }
  }

  /// 根据 generatorType 获取中文名称
  String _getChineseName(String type) {
    try {
      return getGeneratorByType(type).name;
    } catch (_) {
      return type;
    }
  }

  /// 格式化时间戳为可读字符串
  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      if (hours == 1) return '1 小时前';
      return '$hours 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 获取输出预览（前 50 个字符）
  String _getPreview(String output) {
    final cleaned = output.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 50) return cleaned;
    return '${cleaned.substring(0, 50)}...';
  }

  /// 获取所有不重复的生成器类型用于筛选
  List<String> _getAllGeneratorTypes() {
    final types = <String>{};
    for (final h in _allHistory) {
      types.add(h.generatorType);
    }
    return types.toList()..sort();
  }

  /// 删除历史记录
  Future<void> _deleteHistory(GenerationHistory history) async {
    if (history.id == null) return;
    await _storage.deleteGenerationHistory(history.id!);
    setState(() {
      _allHistory.removeWhere((h) => h.id == history.id);
      _applyFilter();
    });
  }

  /// 显示删除确认弹窗
  Future<bool> _showDeleteConfirmation(GenerationHistory history) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: const Text(
          '确认删除',
          style: TextStyle(color: _textPrimary),
        ),
        content: Text(
          '确定要删除「${_getChineseName(history.generatorType)}」的这条生成记录吗？此操作不可撤销。',
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(color: _textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '删除',
              style: TextStyle(color: _deleteColor),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// 显示详情弹窗
  void _showDetailDialog(GenerationHistory history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: Row(
          children: [
            const Icon(Icons.history, color: _accentColor, size: 20.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                _getChineseName(history.generatorType),
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间
              Text(
                _formatTimestamp(history.timestamp),
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 12.0),
              // 分隔线
              Container(height: 1.0, color: _borderColor),
              const SizedBox(height: 12.0),
              // 生成内容
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    history.output,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14.0,
                      height: 1.6,
                    ),
                    cursorColor: _accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(color: _accentColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选栏
        _buildFilterBar(),
        // 列表内容
        Expanded(
          child: _buildListContent(),
        ),
      ],
    );
  }

  /// 顶部筛选栏
  Widget _buildFilterBar() {
    final types = _getAllGeneratorTypes();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: _textSecondary, size: 18.0),
          const SizedBox(width: 8.0),
          const Text(
            '筛选',
            style: TextStyle(color: _textSecondary, fontSize: 13.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Container(
              height: 36.0,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilterType,
                  isExpanded: true,
                  hint: const Text(
                    '全部类型',
                    style: TextStyle(color: _textSecondary, fontSize: 13.0),
                  ),
                  dropdownColor: _surfaceColor,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: _textSecondary, size: 18.0),
                  style: const TextStyle(color: _textPrimary, fontSize: 13.0),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('全部类型',
                          style: TextStyle(color: _textSecondary)),
                    ),
                    ...types.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(_getChineseName(type)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilterType = value;
                      _applyFilter();
                    });
                  },
                ),
              ),
            ),
          ),
          if (_selectedFilterType != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterType = null;
                    _applyFilter();
                  });
                },
                child: const Icon(Icons.clear, color: _textSecondary, size: 18.0),
              ),
            ),
        ],
      ),
    );
  }

  /// 列表内容区
  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2.5),
      );
    }

    if (_filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48.0, color: _textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12.0),
            const Text(
              '暂无历史记录',
              style: TextStyle(color: _textSecondary, fontSize: 15.0),
            ),
            const SizedBox(height: 4.0),
            Text(
              _selectedFilterType != null ? '当前筛选条件下没有记录' : '生成内容后会自动记录在这里',
              style: TextStyle(
                color: _textSecondary.withOpacity(0.6),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      backgroundColor: _surfaceColor,
      onRefresh: _loadHistory,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _filteredHistory.length,
        itemBuilder: (context, index) {
          return _buildHistoryItem(_filteredHistory[index]);
        },
      ),
    );
  }

  /// 单条历史记录项
  Widget _buildHistoryItem(GenerationHistory history) {
    return Dismissible(
      key: Key('history_${history.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: _deleteColor,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(history),
      onDismissed: (_) => _deleteHistory(history),
      child: InkWell(
        onTap: () {
          widget.onSelect?.call(history);
          _showDetailDialog(history);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: _bgColor,
            border: Border(bottom: BorderSide(color: _borderColor.withOpacity(0.5))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 类型图标
              Container(
                width: 36.0,
                height: 36.0,
                margin: const EdgeInsets.only(top: 2.0),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.auto_awesome, color: _accentColor, size: 18.0),
              ),
              const SizedBox(width: 12.0),
              // 文字内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：类型名 + 时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getChineseName(history.generatorType),
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimestamp(history.timestamp),
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    // 预览文本
                    Text(
                      _getPreview(history.output),
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12.0,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 箭头
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 4.0),
                child: Icon(Icons.chevron_right, color: _textSecondary, size: 18.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}