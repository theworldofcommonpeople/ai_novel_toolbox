import 'dart:async';
import '../models/api_config.dart';
import 'storage_service.dart';
import 'cloud_api_service.dart';
import 'local_model_service.dart';

/// 统一 AI 服务
///
/// 封装云端 API 和本地模型，根据配置自动选择推理后端。
/// 支持云端优先策略及云端失败后自动回落至本地模型。
class AiService {
  final CloudApiService _cloudService;
  final LocalModelService _localService;
  final StorageService _storage;

  AiService({
    CloudApiService? cloudService,
    LocalModelService? localService,
    StorageService? storage,
  })  : _cloudService = cloudService ?? CloudApiService(),
        _localService = localService ?? LocalModelService(),
        _storage = storage ?? StorageService.instance;

  // ============================================================
  // 统一生成入口
  // ============================================================

  /// 生成文本回复。
  ///
  /// 当 [stream] 为 true 时返回 [Stream<String>]（逐 token 输出）；
  /// 当 [stream] 为 false 时返回 [Future<String>]（一次性完整输出）。
  ///
  /// 自动决策流程：
  /// 1. 从数据库读取 [ApiConfig]；
  /// 2. 若有云端配置且 `use_cloud_first == 1`，优先使用云端；
  /// 3. 云端失败或无配置时，回退到本地模型。
  ///
  /// 调用方根据 [stream] 参数以不同方式消费返回值：
  /// ```dart
  /// await for (final token in aiService.generate('sys', 'msg', stream: true)) {
  ///   print(token);
  /// }
  /// ```
  /// 或
  /// ```dart
  /// final result = await aiService.generate('sys', 'msg', stream: false);
  /// print(result);
  /// ```
  dynamic generate(
    String systemPrompt,
    String userMessage, {
    bool stream = true,
  }) async* {
    final messages = _buildMessages(systemPrompt, userMessage);

    if (stream) {
      yield* _generateStreamInternal(messages);
    } else {
      // 非流式：返回 Future<String>
      // 由于 async* 不能返回非 Stream，此处通过抛出提示说明用法
      throw UnsupportedError(
        '非流式调用请使用 generateText() 方法。'
        'generate() async* 仅支持 stream: true',
      );
    }
  }

  /// 非流式文本生成（返回完整字符串）。
  Future<String> generateText(
    String systemPrompt,
    String userMessage,
  ) async {
    final messages = _buildMessages(systemPrompt, userMessage);
    return await _generateNonStreamInternal(messages);
  }

  // ============================================================
  // 内部：流式生成
  // ============================================================

  Stream<String> _generateStreamInternal(List<Map<String, String>> messages) async* {
    // 1. 尝试读取云端配置
    final configs = await _storage.getAllApiConfigs();
    final ApiConfig? cloudConfig =
        configs.isNotEmpty ? configs.first : null;

    // 2. 若云端可用，优先尝试
    if (cloudConfig != null &&
        cloudConfig.useCloudFirst == 1 &&
        cloudConfig.textBaseUrl != null &&
        cloudConfig.textBaseUrl!.isNotEmpty &&
        cloudConfig.textApiKey != null &&
        cloudConfig.textApiKey!.isNotEmpty) {
      try {
        yield* _streamWithCloud(cloudConfig, messages);
        return; // 云端成功，直接返回
      } catch (_) {
        // 云端失败，继续回退到本地
      }
    }

    // 3. 回退到本地模型
    yield* _streamWithLocal(messages);
  }

  /// 通过云端 API 流式生成。
  Stream<String> _streamWithCloud(
    ApiConfig config,
    List<Map<String, String>> messages,
  ) async* {
    final model = config.textModelName ?? 'gpt-3.5-turbo';
    final cloudStream = _cloudService.streamChatCompletion(
      baseUrl: config.textBaseUrl!,
      apiKey: config.textApiKey!,
      model: model,
      messages: messages,
    );

    await for (final chunk in cloudStream) {
      yield chunk;
    }
  }

  /// 通过本地模型流式生成（逐句输出模拟流式）。
  Stream<String> _streamWithLocal(List<Map<String, String>> messages) async* {
    if (!_localService.isModelLoaded()) {
      yield '【错误】本地模型未加载，请先在设置中配置并加载模型。';
      return;
    }

    // 将 messages 合并为一个 prompt
    final prompt = messages
        .map((m) => '${m['role']}: ${m['content']}')
        .join('\n');

    try {
      final result = await _localService.generate(prompt);
      // 按字符逐个 yield 以模拟流式输出
      for (int i = 0; i < result.length; i++) {
        yield result[i];
        // 小延迟让 UI 能够逐步渲染
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } catch (e) {
      yield '【错误】本地模型生成失败: $e';
    }
  }

  // ============================================================
  // 内部：非流式生成
  // ============================================================

  Future<String> _generateNonStreamInternal(
    List<Map<String, String>> messages,
  ) async {
    // 1. 尝试读取云端配置
    final configs = await _storage.getAllApiConfigs();
    final ApiConfig? cloudConfig =
        configs.isNotEmpty ? configs.first : null;

    // 2. 若云端可用，优先尝试
    if (cloudConfig != null &&
        cloudConfig.useCloudFirst == 1 &&
        cloudConfig.textBaseUrl != null &&
        cloudConfig.textBaseUrl!.isNotEmpty &&
        cloudConfig.textApiKey != null &&
        cloudConfig.textApiKey!.isNotEmpty) {
      try {
        return await _textWithCloud(cloudConfig, messages);
      } catch (_) {
        // 云端失败，继续回退到本地
      }
    }

    // 3. 回退到本地模型
    return await _textWithLocal(messages);
  }

  /// 通过云端 API 非流式生成。
  Future<String> _textWithCloud(
    ApiConfig config,
    List<Map<String, String>> messages,
  ) async {
    final model = config.textModelName ?? 'gpt-3.5-turbo';
    return await _cloudService.chatCompletion(
      baseUrl: config.textBaseUrl!,
      apiKey: config.textApiKey!,
      model: model,
      messages: messages,
    );
  }

  /// 通过本地模型非流式生成。
  Future<String> _textWithLocal(List<Map<String, String>> messages) async {
    if (!_localService.isModelLoaded()) {
      return '【错误】本地模型未加载，请先在设置中配置并加载模型。';
    }

    final prompt = messages
        .map((m) => '${m['role']}: ${m['content']}')
        .join('\n');

    try {
      return await _localService.generate(prompt);
    } catch (e) {
      return '【错误】本地模型生成失败: $e';
    }
  }

  // ============================================================
  // 工具方法
  // ============================================================

  /// 将 system prompt 和 user message 组装为 OpenAI 消息格式。
  List<Map<String, String>> _buildMessages(
    String systemPrompt,
    String userMessage,
  ) {
    final messages = <Map<String, String>>[];

    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    messages.add({'role': 'user', 'content': userMessage});

    return messages;
  }
}