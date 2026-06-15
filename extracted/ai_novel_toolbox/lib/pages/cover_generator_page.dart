import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/api_config.dart';
import '../services/image_gen_service.dart';
import '../services/storage_service.dart';

/// ============================================================
/// 封面生成器页面
/// ============================================================
///
/// 提供 AI 小说封面生成功能，用户输入书名和封面描述后，
/// 调用 [ImageGenService.generateCover] 生成封面图片。
/// 支持缩放查看、保存至相册和重新生成。
class CoverGeneratorPage extends StatefulWidget {
  const CoverGeneratorPage({super.key});

  @override
  State<CoverGeneratorPage> createState() => _CoverGeneratorPageState();
}

class _CoverGeneratorPageState extends State<CoverGeneratorPage> {
  // ============================================================
  // 控制器
  // ============================================================

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ============================================================
  // 状态
  // ============================================================

  bool _isGenerating = false;
  String? _generatedImagePath;
  String? _errorMessage;
  String _selectedSize = '1024x1024';
  bool _isSaving = false;

  final ImageGenService _imageGenService = ImageGenService();

  // 支持的图像尺寸
  static const Map<String, String> _sizeOptions = {
    '1024x1024': '正方形 (1024x1024)',
    '1792x1024': '横版 (1792x1024)',
    '1024x1792': '竖版 (1024x1792)',
  };

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // 封面生成
  // ============================================================

  Future<void> _onGenerate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('请输入书名');
      return;
    }

    // 获取 API 配置
    final configs = await StorageService.instance.getAllApiConfigs();
    if (configs.isEmpty) {
      _showSnackBar('请先在设置中配置图像生成 API');
      return;
    }
    final config = configs.first;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImagePath = null;
    });

    try {
      final imagePath = await _imageGenService.generateCover(
        title,
        _descriptionController.text.trim(),
        config,
      );

      if (!mounted) return;
      setState(() {
        _generatedImagePath = imagePath;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = '封面生成失败: $e';
      });
    }
  }

  /// 重新生成（使用相同参数）
  Future<void> _onRegenerate() async {
    await _onGenerate();
  }

  // ============================================================
  // 保存到相册
  // ============================================================

  Future<void> _onSaveToGallery() async {
    if (_generatedImagePath == null) {
      _showSnackBar('没有可保存的封面图片');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 请求存储权限
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        if (mounted) {
          _showSnackBar('需要存储权限才能保存图片');
        }
        setState(() => _isSaving = false);
        return;
      }

      final file = File(_generatedImagePath!);
      if (!await file.exists()) {
        _showSnackBar('图片文件不存在');
        setState(() => _isSaving = false);
        return;
      }

      // 使用 share_plus 分享/保存
      await Share.shareXFiles(
        [XFile(_generatedImagePath!)],
        text: '《${_titleController.text.trim()}》小说封面',
      );

      if (mounted) {
        _showSnackBar('封面已分享');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('封面生成器'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 书名输入 ──
            _buildSectionTitle('书名'),
            const SizedBox(height: 8.0),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '请输入小说书名',
                prefixIcon: Icon(Icons.auto_stories),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 20.0),

            // ── 封面描述输入 ──
            _buildSectionTitle('封面描述'),
            const SizedBox(height: 8.0),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '描述你想要的封面风格、场景、色调等...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 20.0),

            // ── 图像尺寸选择 ──
            _buildSectionTitle('图像尺寸'),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: _selectedSize,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.aspect_ratio),
              ),
              items: _sizeOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSize = value);
                }
              },
            ),

            const SizedBox(height: 24.0),

            // ── 生成按钮 ──
            FilledButton.icon(
              onPressed: _isGenerating ? null : _onGenerate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? '生成中...' : '生成封面'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // ── 错误提示 ──
            if (_errorMessage != null) ...[
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
              const SizedBox(height: 16.0),
            ],

            // ── 生成中加载指示器 ──
            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12.0),
                    Text(
                      'AI 正在为您生成封面，请稍候...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),

            // ── 生成结果展示 ──
            if (_generatedImagePath != null) ...[
              _buildSectionTitle('生成结果'),
              const SizedBox(height: 8.0),

              // 可缩放图片查看器
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: SizedBox(
                  height: 400.0,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(_generatedImagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48.0,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  '图片加载失败',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              // ── 操作按钮行 ──
              Row(
                children: [
                  // 重新生成
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGenerating ? null : _onRegenerate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新生成'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // 保存到相册
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _onSaveToGallery,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(_isSaving ? '保存中...' : '保存/分享'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ],
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