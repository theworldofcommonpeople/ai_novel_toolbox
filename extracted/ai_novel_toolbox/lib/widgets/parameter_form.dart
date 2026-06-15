import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/prompt_templates.dart';

/// ============================================================
/// ParameterForm - 动态参数表单组件
/// ============================================================
///
/// 根据 [PromptParam] 定义列表动态构建表单。
/// 支持的控件类型：
///   - 'text'       → 单行文本输入
///   - 'multiline'  → 多行文本输入
///   - 'dropdown'   → 下拉选择框
///   - 'number'     → 数字输入（数字键盘）
///
/// 使用方式：
/// ```dart
/// final formKey = GlobalKey<ParameterFormState>();
/// ParameterForm(
///   key: formKey,
///   params: PromptTemplates.getParams('book_name'),
/// )
/// // 收集值
/// final values = formKey.currentState!.getValues();
/// // 验证
/// final isValid = formKey.currentState!.validate();
/// ```
class ParameterForm extends StatefulWidget {
  /// 参数定义列表
  final List<PromptParam> params;

  const ParameterForm({
    super.key,
    required this.params,
  });

  @override
  State<ParameterForm> createState() => ParameterFormState();
}

class ParameterFormState extends State<ParameterForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final param in widget.params) {
      if (param.type == 'text' || param.type == 'multiline' || param.type == 'number') {
        _controllers[param.key] = TextEditingController();
      } else if (param.type == 'dropdown') {
        _dropdownValues[param.key] = param.options?.isNotEmpty == true
            ? param.options!.first
            : '';
      }
    }
  }

  @override
  void didUpdateWidget(covariant ParameterForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _disposeControllers();
      _controllers.clear();
      _dropdownValues.clear();
      _initControllers();
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// 收集所有表单值，返回 Map<key, value>
  Map<String, String> getValues() {
    final Map<String, String> values = {};
    for (final param in widget.params) {
      if (param.type == 'dropdown') {
        values[param.key] = _dropdownValues[param.key] ?? '';
      } else {
        values[param.key] = _controllers[param.key]?.text ?? '';
      }
    }
    return values;
  }

  /// 验证所有字段是否非空
  bool validate() {
    bool isValid = true;
    for (final param in widget.params) {
      String? value;
      if (param.type == 'dropdown') {
        value = _dropdownValues[param.key];
      } else {
        value = _controllers[param.key]?.text;
      }
      if (value == null || value.trim().isEmpty) {
        isValid = false;
        break;
      }
    }
    return isValid;
  }

  // ============================================================
  // 深色主题色彩常量
  // ============================================================

  static const Color _bgColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1E1E2E);
  static const Color _accentColor = Color(0xFF7C4DFF);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _borderColor = Color(0xFF2A2A3A);
  static const Color _errorColor = Color(0xFFCF6679);

  @override
  Widget build(BuildContext context) {
    if (widget.params.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.params.map(_buildField).toList(),
    );
  }

  /// 根据参数类型构建对应的表单控件
  Widget _buildField(PromptParam param) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              param.label,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 输入控件
          _buildInputWidget(param),
        ],
      ),
    );
  }

  Widget _buildInputWidget(PromptParam param) {
    switch (param.type) {
      case 'multiline':
        return _buildMultilineField(param);
      case 'dropdown':
        return _buildDropdownField(param);
      case 'number':
        return _buildNumberField(param);
      case 'text':
      default:
        return _buildTextField(param);
    }
  }

  // ---- 单行文本 ----
  Widget _buildTextField(PromptParam param) {
    return TextField(
      controller: _controllers[param.key],
      style: const TextStyle(color: _textPrimary, fontSize: 14.0),
      decoration: _inputDecoration('请输入${param.label}'),
      cursorColor: _accentColor,
    );
  }

  // ---- 多行文本 ----
  Widget _buildMultilineField(PromptParam param) {
    return TextField(
      controller: _controllers[param.key],
      style: const TextStyle(color: _textPrimary, fontSize: 14.0),
      maxLines: 4,
      minLines: 3,
      decoration: _inputDecoration('请输入${param.label}'),
      cursorColor: _accentColor,
    );
  }

  // ---- 下拉选择 ----
  Widget _buildDropdownField(PromptParam param) {
    final options = param.options ?? [];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _dropdownValues[param.key],
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(color: _textPrimary, fontSize: 14.0),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _dropdownValues[param.key] = value ?? '';
            });
          },
          dropdownColor: _surfaceColor,
          icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(color: _textPrimary, fontSize: 14.0),
        ),
      ),
    );
  }

  // ---- 数字输入 ----
  Widget _buildNumberField(PromptParam param) {
    return TextField(
      controller: _controllers[param.key],
      style: const TextStyle(color: _textPrimary, fontSize: 14.0),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration('请输入${param.label}'),
      cursorColor: _accentColor,
    );
  }

  /// 统一的输入框装饰样式
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _textSecondary, fontSize: 13.0),
      filled: true,
      fillColor: _bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    );
  }
}