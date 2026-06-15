import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';

/// 设置页面
///
/// 包含五大配置区域：
/// 1. 云端文本 API 配置
/// 2. 云端图片 API 配置
/// 3. 本地模型管理
/// 4. 生成偏好
/// 5. RAG 功能开关
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ─── 安全存储 ───
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ─── 表单 Key ───
  final _formKey = GlobalKey<FormState>();

  // ─── 文本 API 控制器 ───
  final _textBaseUrlController = TextEditingController();
  final _textApiKeyController = TextEditingController();
  final _textModelController = TextEditingController();

  // ─── 图片 API 控制器 ───
  final _imageBaseUrlController = TextEditingController();
  final _imageApiKeyController = TextEditingController();
  final _imageModelController = TextEditingController();

  // ─── 密码可见性 ───
  bool _textApiKeyVisible = false;
  bool _imageApiKeyVisible = false;

  // ─── 偏好开关 ───
  bool _useCloudFirst = true;

  // ─── RAG 开关 ───
  bool _ragEnabled = true;

  // ─── 本地模型状态 ───
  String _localModelPath = '';
  bool _localModelLoaded = false;
  bool _isLoadingModel = false;
  bool _isTestingConnection = false;

  // ─── 页面状态 ───
  bool _isLoading = true;
  bool _isSaving = false;

  // ─── 生命周期 ───

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _textBaseUrlController.dispose();
    _textApiKeyController.dispose();
    _textModelController.dispose();
    _imageBaseUrlController.dispose();
    _imageApiKeyController.dispose();
    _imageModelController.dispose();
    super.dispose();
  }

  // ─── 加载设置 ───

  Future<void> _loadSettings() async {
    try {
      // 从 StorageService 加载 API 配置
      final config = await StorageService.getApiConfig();
      final textConfig = config['text_api'] as Map<String, dynamic>? ?? {};
      final imageConfig = config['image_api'] as Map<String, dynamic>? ?? {};
      final preferences = config['preferences'] as Map<String, dynamic>? ?? {};

      _textBaseUrlController.text = textConfig['base_url'] as String? ?? '';
      _textModelController.text = textConfig['model'] as String? ?? '';
      _imageBaseUrlController.text = imageConfig['base_url'] as String? ?? '';
      _imageModelController.text = imageConfig['model'] as String? ?? '';

      // 安全存储中的 API Key
      final textApiKey =
          await _secureStorage.read(key: 'text_api_key') ?? '';
      final imageApiKey =
          await _secureStorage.read(key: 'image_api_key') ?? '';
      _textApiKeyController.text = textApiKey;
      _imageApiKeyController.text = imageApiKey;

      // 本地模型
      _localModelPath = config['local_model_path'] as String? ?? '';
      _localModelLoaded = config['local_model_loaded'] as bool? ?? false;

      // 偏好
      _useCloudFirst = preferences['use_cloud_first'] as bool? ?? true;
      _ragEnabled = preferences['rag_enabled'] as bool? ?? true;
    } catch (_) {
      // 加载失败使用默认值
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── 保存设置 ───

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 安全存储 API Key
      await _secureStorage.write(
          key: 'text_api_key', value: _textApiKeyController.text.trim());
      await _secureStorage.write(
          key: 'image_api_key', value: _imageApiKeyController.text.trim());

      // 通过 StorageService 保存其余配置
      await StorageService.saveApiConfig({
        'text_api': {
          'base_url': _textBaseUrlController.text.trim(),
          'model': _textModelController.text.trim(),
          // API Key 不存入普通配置，仅存安全存储
        },
        'image_api': {
          'base_url': _imageBaseUrlController.text.trim(),
          'model': _imageModelController.text.trim(),
        },
        'local_model_path': _localModelPath,
        'local_model_loaded': _localModelLoaded,
        'preferences': {
          'use_cloud_first': _useCloudFirst,
          'rag_enabled': _ragEnabled,
        },
      });

      if (mounted) {
        _showSnackBar('设置已保存', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ─── 测试连接 ───

  Future<void> _onTestConnection() async {
    setState(() => _isTestingConnection = true);

    try {
      final success = await AiService.testConnection(
        baseUrl: _textBaseUrlController.text.trim(),
        apiKey: _textApiKeyController.text.trim(),
        model: _textModelController.text.trim(),
      );

      if (mounted) {
        _showSnackBar(
          success ? '云端连接测试成功' : '云端连接测试失败，请检查配置',
          isError: !success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('连接测试异常: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  // ─── 本地模型 加载/卸载 ───

  Future<void> _onToggleLocalModel() async {
    setState(() => _isLoadingModel = true);

    try {
      if (_localModelLoaded) {
        // 卸载
        await AiService.unloadLocalModel();
        _localModelLoaded = false;
        _showSnackBar('本地模型已卸载', isError: false);
      } else {
        // 加载
        await AiService.loadLocalModel(_localModelPath);
        _localModelLoaded = true;
        _showSnackBar('本地模型加载成功', isError: false);
      }
    } catch (e) {
      _showSnackBar('本地模型操作失败: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingModel = false);
      }
    }
  }

  // ─── 工具方法 ───

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── 构建 UI ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: false,
        actions: [
          // 保存按钮
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save_outlined),
                    tooltip: '保存设置',
                    onPressed: _onSave,
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ════════════════════════════════════════════════
            // Section 1: 云端文本 API 配置
            // ════════════════════════════════════════════════
            _buildSectionHeader(theme, '云端文本API配置', Icons.cloud),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _textBaseUrlController,
              label: 'Base URL',
              hint: 'https://api.openai.com/v1',
              icon: Icons.link,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入API地址' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _textApiKeyController,
              label: 'API Key',
              hint: 'sk-...',
              icon: Icons.vpn_key,
              obscureText: !_textApiKeyVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _textApiKeyVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _textApiKeyVisible = !_textApiKeyVisible),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入API密钥' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _textModelController,
              label: 'Model Name',
              hint: 'gpt-4o',
              icon: Icons.smart_toy,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入模型名称' : null,
            ),
            const SizedBox(height: 12),
            // 测试连接按钮
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isTestingConnection ? null : _onTestConnection,
                icon: _isTestingConnection
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find, size: 18),
                label:
                    Text(_isTestingConnection ? '测试中...' : '测试连接'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ════════════════════════════════════════════════
            // Section 2: 云端图片 API 配置
            // ════════════════════════════════════════════════
            _buildSectionHeader(theme, '云端图片API配置', Icons.image),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _imageBaseUrlController,
              label: 'Image Base URL',
              hint: 'https://api.openai.com/v1',
              icon: Icons.link,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _imageApiKeyController,
              label: 'Image API Key',
              hint: 'sk-...',
              icon: Icons.vpn_key,
              obscureText: !_imageApiKeyVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _imageApiKeyVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _imageApiKeyVisible = !_imageApiKeyVisible),
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _imageModelController,
              label: 'Image Model',
              hint: 'dall-e-3',
              icon: Icons.smart_toy,
            ),

            const SizedBox(height: 28),

            // ════════════════════════════════════════════════
            // Section 3: 本地模型
            // ════════════════════════════════════════════════
            _buildSectionHeader(theme, '本地模型', Icons.computer),
            const SizedBox(height: 8),

            // 模型路径显示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _localModelPath.isEmpty
                          ? '未设置本地模型路径'
                          : _localModelPath,
                      style: TextStyle(
                        color: _localModelPath.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 状态指示器
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _localModelLoaded ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _localModelLoaded ? '已加载' : '未加载',
                  style: TextStyle(
                    color: _localModelLoaded ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // 加载/卸载按钮
                FilledButton.tonalIcon(
                  onPressed: _isLoadingModel ? null : _onToggleLocalModel,
                  icon: _isLoadingModel
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_localModelLoaded
                          ? Icons.eject
                          : Icons.play_arrow),
                  label: Text(_localModelLoaded ? '卸载' : '加载'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ════════════════════════════════════════════════
            // Section 4: 生成偏好
            // ════════════════════════════════════════════════
            _buildSectionHeader(theme, '生成偏好', Icons.tune),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: '优先使用云端API',
              subtitle: '开启后将优先通过云端API生成内容，关闭则使用本地模型',
              icon: Icons.cloud_done,
              value: _useCloudFirst,
              onChanged: (val) => setState(() => _useCloudFirst = val),
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // Section 5: RAG 功能
            // ════════════════════════════════════════════════
            _buildSectionHeader(theme, 'RAG功能', Icons.memory),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: '启用RAG检索增强生成',
              subtitle: '开启后将在生成时检索本地知识库以提供上下文参考，提升内容质量',
              icon: Icons.search,
              value: _ragEnabled,
              onChanged: (val) => setState(() => _ragEnabled = val),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 复用组件 ───

  /// 分区标题
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 通用文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
      ),
    );
  }

  /// 开关行
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}