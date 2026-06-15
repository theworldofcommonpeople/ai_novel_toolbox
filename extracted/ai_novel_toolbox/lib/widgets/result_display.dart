import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================
/// ResultDisplay - AI 生成结果显示组件
/// ============================================================
///
/// 展示 AI 生成结果，支持加载态、空态、复制/重新生成/保存操作。
///
/// 使用方式：
/// ```dart
/// ResultDisplay(
///   resultText: generatedText,
///   isLoading: isGenerating,
///   onRegenerate: () => regenerate(),
///   onSave: () => saveToHistory(),
/// )
/// ```
class ResultDisplay extends StatelessWidget {
  /// 生成的文本内容
  final String resultText;

  /// 是否正在加载中
  final bool isLoading;

  /// 重新生成回调
  final VoidCallback? onRegenerate;

  /// 保存回调
  final VoidCallback? onSave;

  const ResultDisplay({
    super.key,
    this.resultText = '',
    this.isLoading = false,
    this.onRegenerate,
    this.onSave,
  });

  // ============================================================
  // 深色主题色彩常量
  // ============================================================

  static const Color _bgColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1E1E2E);
  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _borderColor = Color(0xFF2A2A3A);
  static const Color _actionBarBg = Color(0xFF1A1A2A);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 内容区域
        Expanded(
          child: _buildContentArea(),
        ),
        // 底部操作栏
        _buildBottomActionBar(context),
      ],
    );
  }

  /// 内容区域：加载态 / 空态 / 结果展示
  Widget _buildContentArea() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (resultText.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultState();
  }

  // ---- 加载中 ----
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48.0,
            height: 48.0,
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 3.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'AI 正在生成中...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '请稍候，内容创作需要一点时间',
            style: TextStyle(
              color: _textSecondary.withOpacity(0.6),
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 空态 ----
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48.0,
            color: _textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12.0),
          const Text(
            '暂无生成结果',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '填写参数后点击生成按钮开始创作',
            style: TextStyle(
              color: _textSecondary.withOpacity(0.6),
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 结果展示 ----
  Widget _buildResultState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _borderColor),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SelectableText(
          resultText,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15.0,
            height: 1.7,
          ),
          cursorColor: _accentColor,
        ),
      ),
    );
  }

  // ---- 底部操作栏 ----
  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _actionBarBg,
        border: Border(
          top: BorderSide(color: _borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.content_copy,
            label: '复制',
            onTap: () => _copyToClipboard(context),
            enabled: resultText.isNotEmpty && !isLoading,
          ),
          _ActionButton(
            icon: Icons.refresh,
            label: '重新生成',
            onTap: () {
              if (!isLoading) onRegenerate?.call();
            },
            enabled: onRegenerate != null && !isLoading,
          ),
          _ActionButton(
            icon: Icons.save,
            label: '保存',
            onTap: () {
              if (!isLoading) onSave?.call();
            },
            enabled: resultText.isNotEmpty && !isLoading && onSave != null,
          ),
        ],
      ),
    );
  }

  /// 复制到剪贴板
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '已复制到剪贴板',
          style: TextStyle(color: _textPrimary),
        ),
        backgroundColor: _surfaceColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 单个操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _accentColor : _textSecondary;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}