import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../utils/prompt_templates.dart';
import '../widgets/parameter_form.dart';
import '../widgets/result_display.dart';

/// 核心可复用生成器页面
///
/// 供全部 12 个文本生成器使用，根据 [generatorType] 加载对应的
/// 系统提示模板与参数定义，统一处理"填参 -> 渲染 -> 调用 AI -> 流式展示 -> 保存"流程。
class GeneratorBase extends StatefulWidget {
  /// 生成器类型字符串，对应 prompt_templates.dart 中的模板 Key
  final String generatorType;

  const GeneratorBase({super.key, required this.generatorType});

  @override
  State<GeneratorBase> createState() => _GeneratorBaseState();
}

class _GeneratorBaseState extends State<GeneratorBase> {
  // ─── 表单 Key ───
  final _formKey = GlobalKey<ParameterFormState>();

  // ─── 模板数据 ───
  String _systemPromptTemplate = '';
  List<Map<String, dynamic>> _parameterDefs = [];
  Map<String, String>? _cachedGeneratorMeta;

  // ─── 生成状态 ───
  bool _isGenerating = false;
  String _resultText = '';
  String _errorText = '';
  StreamSubscription<String>? _streamSubscription;

  // ─── 生命周期 ───

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  // ─── 加载模板 ───

  void _loadTemplate() {
    _systemPromptTemplate = getSystemPromptTemplate(widget.generatorType);
    _parameterDefs = getParameterDefinitions(widget.generatorType);
    // 同时从 constants 中获取展示元信息（名称、描述等）
    _cachedGeneratorMeta = getGeneratorMeta(widget.generatorType);
  }

  // ─── 获取生成器展示名称 ───

  String get _generatorDisplayName {
    if (_cachedGeneratorMeta != null) {
      return _cachedGeneratorMeta!['name'] ?? widget.generatorType;
    }
    return widget.generatorType;
  }

  // ─── 渲染 Prompt 模板 ───

  /// 将模板中的 {{变量名}} 替换为表单收集的实际值
  String _renderPrompt(Map<String, String> values) {
    String rendered = _systemPromptTemplate;
    for (final entry in values.entries) {
      rendered = rendered.replaceAll('{{${entry.key}}}', entry.value);
    }
    return rendered;
  }

  // ─── 开始生成 ───

  Future<void> _onGenerate() async {
    // 1. 校验表单
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) {
      _showSnackBar('请填写所有必填参数');
      return;
    }

    // 2. 收集表单值
    final Map<String, String> formValues = formState.getValues();

    // 3. 渲染 Prompt 模板
    final String renderedPrompt = _renderPrompt(formValues);

    // 4. 重置状态，准备接受新结果
    setState(() {
      _isGenerating = true;
      _resultText = '';
      _errorText = '';
    });

    // 取消上一次的流（如果有）
    _streamSubscription?.cancel();

    try {
      // 5. 调用 AiService 发起流式生成
      final stream = AiService.generate(
        systemPrompt: renderedPrompt,
        message: '请开始生成内容。',
      );

      final buffer = StringBuffer();

      _streamSubscription = stream.listen(
        // onData
        (chunk) {
          buffer.write(chunk);
          if (mounted) {
            setState(() {
              _resultText = buffer.toString();
            });
          }
        },
        // onError
        (error) {
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _errorText = '生成失败: $error';
              _resultText = buffer.toString();
            });
          }
        },
        // onDone
        () {
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _resultText = buffer.toString();
            });
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorText = '无法连接AI服务: $e';
        });
      }
    }
  }

  // ─── 重新生成 ───

  void _onRegenerate() {
    _onGenerate();
  }

  // ─── 保存结果 ───

  Future<void> _onSave() async {
    if (_resultText.isEmpty) {
      _showSnackBar('没有可保存的生成内容');
      return;
    }

    try {
      await StorageService.saveGenerationHistory({
        'generator_type': widget.generatorType,
        'generator_name': _generatorDisplayName,
        'content': _resultText,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        _showSnackBar('保存成功');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e');
      }
    }
  }

  // ─── 工具方法 ───

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── 构建 UI ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_generatorDisplayName),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 参数输入区 ──
            ParameterForm(
              key: _formKey,
              parameterDefs: _parameterDefs,
            ),

            const SizedBox(height: 20),

            // ── 开始生成按钮 ──
            FilledButton.icon(
              onPressed: _isGenerating ? null : _onGenerate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? '生成中...' : '开始生成'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 错误提示 ──
            if (_errorText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),

            // ── 结果展示区 ──
            if (_resultText.isNotEmpty || _isGenerating) ...[
              const SizedBox(height: 16),
              ResultDisplay(
                resultText: _resultText,
                isLoading: _isGenerating,
                onRegenerate: _isGenerating ? null : _onRegenerate,
                onSave: _isGenerating ? null : _onSave,
              ),
            ],
          ],
        ),
      ),
    );
  }
}