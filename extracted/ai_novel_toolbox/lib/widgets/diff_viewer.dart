import 'package:flutter/material.dart';

/// ============================================================
/// DiffViewer - 文本差异对比组件
/// ============================================================
///
/// 对原文和修改后的文本进行逐词级别的差异对比，支持：
///   - 并排（side-by-side）对比模式
///   - 内联（inline）对比模式
///   - 新增内容以绿色高亮，删除内容以红色高亮
///   - 用于一致性检查功能展示修改前后的差异
///
/// 使用方式：
/// ```dart
/// DiffViewer(
///   originalText: '原始文本内容...',
///   modifiedText: '修改后文本内容...',
/// )
/// ```
class DiffViewer extends StatefulWidget {
  /// 原始文本（修改前）
  final String originalText;

  /// 修改后的文本
  final String modifiedText;

  const DiffViewer({
    super.key,
    required this.originalText,
    required this.modifiedText,
  });

  @override
  State<DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends State<DiffViewer> {
  // ============================================================
  // 深色主题色彩常量
  // ============================================================

  static const Color _bgColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1E1E2E);
  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _borderColor = Color(0xFF2A2A3A);
  static const Color _additionBg = Color(0xFF1B3A1B);
  static const Color _additionText = Color(0xFF81C784);
  static const Color _deletionBg = Color(0xFF3A1B1B);
  static const Color _deletionText = Color(0xFFE57373);
  static const Color _headerBg = Color(0xFF16162A);

  bool _isSideBySide = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 模式切换 + 统计信息
        _buildHeader(),
        // 差异内容
        Expanded(
          child: _isSideBySide ? _buildSideBySide() : _buildInline(),
        ),
      ],
    );
  }

  /// 顶部栏：模式切换按钮 + 差异统计
  Widget _buildHeader() {
    final diffResult = _computeDiff();
    final stats = _computeStats(diffResult);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          // 模式切换
          _ModeToggle(
            isSideBySide: _isSideBySide,
            onChanged: (value) {
              setState(() => _isSideBySide = value);
            },
          ),
          const Spacer(),
          // 统计信息
          _StatBadge(
            label: '新增',
            count: stats['additions'] ?? 0,
            color: _additionText,
          ),
          const SizedBox(width: 12.0),
          _StatBadge(
            label: '删除',
            count: stats['deletions'] ?? 0,
            color: _deletionText,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 并排对比模式
  // ============================================================

  Widget _buildSideBySide() {
    final diffResult = _computeDiff();
    final (leftLines, rightLines) = _buildSideBySideLines(diffResult);

    return Row(
      children: [
        // 左侧：原始文本
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: _borderColor)),
            ),
            child: Column(
              children: [
                // 列标题
                _buildColumnHeader('修改前', Icons.article_outlined),
                // 内容
                Expanded(
                  child: Container(
                    color: _bgColor,
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14.0,
                            height: 1.8,
                          ),
                          children: leftLines,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 右侧：修改后文本
        Expanded(
          child: Column(
            children: [
              // 列标题
              _buildColumnHeader('修改后', Icons.edit_note),
              // 内容
              Expanded(
                child: Container(
                  color: _bgColor,
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14.0,
                          height: 1.8,
                        ),
                        children: rightLines,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _textSecondary, size: 14.0),
          const SizedBox(width: 6.0),
          Text(
            title,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建并排显示的行对
  (List<TextSpan> leftLines, List<TextSpan> rightLines) _buildSideBySideLines(
    List<DiffToken> diffResult,
  ) {
    final leftLines = <TextSpan>[];
    final rightLines = <TextSpan>[];

    for (final token in diffResult) {
      switch (token.type) {
        case DiffType.match:
          leftLines.add(TextSpan(text: token.text));
          rightLines.add(TextSpan(text: token.text));
          break;
        case DiffType.deletion:
          leftLines.add(TextSpan(
            text: token.text,
            style: TextStyle(
              color: _deletionText,
              backgroundColor: _deletionBg,
              decoration: TextDecoration.lineThrough,
            ),
          ));
          rightLines.add(const TextSpan(text: ''));
          break;
        case DiffType.insertion:
          leftLines.add(const TextSpan(text: ''));
          rightLines.add(TextSpan(
            text: token.text,
            style: TextStyle(
              color: _additionText,
              backgroundColor: _additionBg,
            ),
          ));
          break;
      }
    }

    return (leftLines, rightLines);
  }

  // ============================================================
  // 内联对比模式
  // ============================================================

  Widget _buildInline() {
    final diffResult = _computeDiff();

    return Container(
      color: _bgColor,
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14.0,
              height: 1.8,
            ),
            children: diffResult.map((token) {
              switch (token.type) {
                case DiffType.match:
                  return TextSpan(text: token.text);
                case DiffType.deletion:
                  return TextSpan(
                    text: token.text,
                    style: TextStyle(
                      color: _deletionText,
                      backgroundColor: _deletionBg,
                      decoration: TextDecoration.lineThrough,
                    ),
                  );
                case DiffType.insertion:
                  return TextSpan(
                    text: token.text,
                    style: TextStyle(
                      color: _additionText,
                      backgroundColor: _additionBg,
                    ),
                  );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 词级差异算法
  // ============================================================

  /// 将文本拆分为词元（token）列表
  ///
  /// 每个词元包含该词及其前后的空白字符，以保持原始间距。
  List<String> _tokenize(String text) {
    if (text.isEmpty) return [];

    final tokens = <String>[];
    // 按空白字符拆分，同时保留分隔符
    final regex = RegExp(r'(\S+)(\s*)');
    for (final match in regex.allMatches(text)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }

  /// 计算原始文本与修改后文本之间的差异
  ///
  /// 使用 LCS（最长公共子序列）算法进行词级对比。
  List<DiffToken> _computeDiff() {
    final originalTokens = _tokenize(widget.originalText);
    final modifiedTokens = _tokenize(widget.modifiedText);

    // 如果两者都为空
    if (originalTokens.isEmpty && modifiedTokens.isEmpty) {
      return [];
    }

    // 计算 LCS 回溯表
    final lcs = _computeLCS(originalTokens, modifiedTokens);

    // 根据 LCS 回溯生成差异 token
    return _backtrackDiff(originalTokens, modifiedTokens, lcs);
  }

  /// 计算 LCS 长度矩阵
  List<List<int>> _computeLCS(List<String> a, List<String> b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    return dp;
  }

  /// 回溯 LCS 矩阵，生成差异 token 列表
  List<DiffToken> _backtrackDiff(
    List<String> a,
    List<String> b,
    List<List<int>> dp,
  ) {
    final result = <DiffToken>[];
    int i = a.length;
    int j = b.length;

    // 收集回溯路径上的 token（反向）
    final reversed = <DiffToken>[];

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
        // 匹配
        reversed.add(DiffToken.match(a[i - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        // 插入（修改后新增）
        reversed.add(DiffToken.insertion(b[j - 1]));
        j--;
      } else if (i > 0) {
        // 删除（原始文本删除）
        reversed.add(DiffToken.deletion(a[i - 1]));
        i--;
      }
    }

    // 反转回正向顺序
    for (int k = reversed.length - 1; k >= 0; k--) {
      result.add(reversed[k]);
    }

    return result;
  }

  /// 计算差异统计
  Map<String, int> _computeStats(List<DiffToken> diffResult) {
    int additions = 0;
    int deletions = 0;

    for (final token in diffResult) {
      if (token.type == DiffType.insertion) additions++;
      if (token.type == DiffType.deletion) deletions++;
    }

    return {'additions': additions, 'deletions': deletions};
  }
}

// ============================================================
// 差异类型与 Token
// ============================================================

/// 差异类型
enum DiffType {
  /// 未修改
  match,

  /// 新增（在修改后文本中出现）
  insertion,

  /// 删除（在原始文本中存在，修改后移除）
  deletion,
}

/// 单个差异词元
class DiffToken {
  final DiffType type;
  final String text;

  const DiffToken._(this.type, this.text);

  const DiffToken.match(String text) : this._(DiffType.match, text);
  const DiffToken.insertion(String text) : this._(DiffType.insertion, text);
  const DiffToken.deletion(String text) : this._(DiffType.deletion, text);

  @override
  String toString() => 'DiffToken($type: "$text")';
}

// ============================================================
// 内部辅助组件
// ============================================================

/// 模式切换按钮
class _ModeToggle extends StatelessWidget {
  final bool isSideBySide;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.isSideBySide,
    required this.onChanged,
  });

  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _surfaceColor = Color(0xFF1E1E2E);
  static const Color _borderColor = Color(0xFF2A2A3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: '并排',
            isSelected: isSideBySide,
            onTap: () => onChanged(true),
          ),
          _ToggleButton(
            label: '内联',
            isSelected: !isSideBySide,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _accentColor : _textSecondary,
            fontSize: 12.0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// 统计徽章
class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          '$label $count',
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}