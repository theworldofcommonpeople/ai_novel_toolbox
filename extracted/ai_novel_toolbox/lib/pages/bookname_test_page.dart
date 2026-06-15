import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/constants.dart';

/// ============================================================
/// 书名测试页面
/// ============================================================
///
/// 将用户输入的书名叠加到预设封面模板上，预览书名在不同风格
/// 封面上的视觉效果。支持截图导出。
class BooknameTestPage extends StatefulWidget {
  const BooknameTestPage({super.key});

  @override
  State<BooknameTestPage> createState() => _BooknameTestPageState();
}

class _BooknameTestPageState extends State<BooknameTestPage> {
  // ============================================================
  // 控制器
  // ============================================================

  final _titleController = TextEditingController();

  // ============================================================
  // 状态
  // ============================================================

  String _bookTitle = '';
  bool _isExporting = false;

  // 每个模板的 GlobalKey，用于 RepaintBoundary 截图
  final Map<String, GlobalKey> _templateKeys = {};

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void initState() {
    super.initState();
    for (final template in CoverTemplates.allTemplates) {
      _templateKeys[template] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ============================================================
  // 文本叠加位置配置
  // ============================================================

  /// 根据模板风格返回文字叠加位置（相对于卡片高度的比例）
  static Map<String, double> get _titleTopRatio => const {
    'template_1': 0.08, // 玄幻仙侠 - 顶部
    'template_2': 0.72, // 都市现代 - 底部
    'template_3': 0.08, // 古风典雅 - 顶部
    'template_4': 0.72, // 科幻未来 - 底部
    'template_5': 0.40, // 暗黑悬疑 - 居中
  };

  /// 根据模板风格返回文字对齐方式
  static Map<String, TextAlign> get _titleAlign => const {
    'template_1': TextAlign.center,
    'template_2': TextAlign.left,
    'template_3': TextAlign.center,
    'template_4': TextAlign.center,
    'template_5': TextAlign.center,
  };

  // ============================================================
  // 导出截图
  // ============================================================

  Future<void> _onExportScreenshot() async {
    if (_bookTitle.isEmpty) {
      _showSnackBar('请先输入书名');
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 分别截取每个模板
      final List<XFile> xFiles = [];
      for (int i = 0; i < CoverTemplates.allTemplates.length; i++) {
        final templatePath = CoverTemplates.allTemplates[i];
        final templateName = CoverTemplates.allTemplates[i]
            .split('/')
            .last
            .replaceAll('.png', '');
        final key = _templateKeys[templatePath];

        if (key?.currentContext == null) continue;

        final renderObject =
            key!.currentContext!.findRenderObject() as RenderRepaintBoundary?;
        if (renderObject == null) continue;

        final image = await renderObject.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) continue;

        final dir = await getTemporaryDirectory();
        final fileName = 'book_test_${templateName}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        xFiles.add(XFile(file.path));
      }

      if (xFiles.isEmpty) {
        _showSnackBar('截图失败，请重试');
      } else {
        await Share.shareXFiles(
          xFiles,
          text: '《$_bookTitle》书名测试预览',
        );
        _showSnackBar('导出成功');
      }
    } catch (e) {
      _showSnackBar('导出失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
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

  /// 从模板路径中提取模板名称（如 template_1）
  String _extractTemplateName(String templatePath) {
    return templatePath.split('/').last.replaceAll('.png', '');
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书名测试'),
        centerTitle: false,
        actions: [
          if (_bookTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _isExporting ? null : _onExportScreenshot,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.screenshot, size: 18.0),
                label: Text(_isExporting ? '导出中...' : '导出截图'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── 书名输入区 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '输入小说书名，自动预览封面效果',
                prefixIcon: Icon(Icons.auto_stories),
                suffixIcon: Icon(Icons.edit),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _bookTitle = value.trim();
                });
              },
            ),
          ),

          // ── 提示信息 ──
          if (_bookTitle.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                '在上方输入书名，查看在不同封面模板上的效果',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13.0,
                ),
              ),
            ),

          // ── 封面模板网格 ──
          Expanded(
            child: _bookTitle.isEmpty
                ? const SizedBox.shrink()
                : GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: CoverTemplates.allTemplates.length,
                    itemBuilder: (context, index) {
                      final templatePath = CoverTemplates.allTemplates[index];
                      final templateName = _extractTemplateName(templatePath);
                      return _buildTemplateCard(templatePath, templateName);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建单个模板卡片
  Widget _buildTemplateCard(String templatePath, String templateName) {
    final styleName = CoverTemplates.templateStyles[templateName] ?? '未知风格';
    final textColor = CoverTemplates.templateColors[templateName] ??
        const Color(0xFFFFFFFF);
    final topRatio = _titleTopRatio[templateName] ?? 0.08;
    final textAlign = _titleAlign[templateName] ?? TextAlign.center;

    // 确定文字颜色：深色背景用白色，浅色背景用深色
    final bool isDarkBackground = _isDarkColor(textColor);
    final Color overlayTextColor = isDarkBackground
        ? Colors.white
        : Colors.black87;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: RepaintBoundary(
        key: _templateKeys[templatePath],
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 模板背景图片 ──
                Image.asset(
                  templatePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: textColor,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white38,
                          size: 32.0,
                        ),
                      ),
                    );
                  },
                ),

                // ── 半透明覆盖层（提升文字可读性） ──
                Positioned(
                  left: 0,
                  right: 0,
                  top: topRatio * constraints.maxHeight - 24.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Text(
                      _bookTitle,
                      textAlign: textAlign,
                      style: TextStyle(
                        color: overlayTextColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4.0,
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // ── 风格标签 ──
                Positioned(
                  top: 6.0,
                  right: 6.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      styleName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 判断颜色是否为深色
  bool _isDarkColor(Color color) {
    final luminance = (0.299 * color.red +
            0.587 * color.green +
            0.114 * color.blue) /
        255.0;
    return luminance < 0.5;
  }
}