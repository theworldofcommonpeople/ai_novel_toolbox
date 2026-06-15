import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// 云端 API 服务
///
/// 基于 Dio 封装 OpenAI 兼容的 Chat Completions API，
/// 支持流式（SSE）、非流式对话以及图像生成。
class CloudApiService {
  late final Dio _dio;

  CloudApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  // ============================================================
  // 流式对话（SSE）
  // ============================================================

  /// 发起流式 Chat Completion 请求，返回 SSE 增量文本流。
  ///
  /// 当服务器返回 `data: [DONE]` 时流结束。
  /// 调用方通过监听 [Stream] 逐 token 获取输出文本。
  Stream<String> streamChatCompletion({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
  }) async* {
    // 确保 baseUrl 不含尾部斜杠
    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/chat/completions';

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: {
          'model': model,
          'messages': messages,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        buffer.write(text);

        // SSE 数据行以 "data: " 开头，以 "\n\n" 结束
        while (buffer.toString().contains('\n\n')) {
          final full = buffer.toString();
          final idx = full.indexOf('\n\n');
          final lineBlock = full.substring(0, idx);
          buffer = StringBuffer(full.substring(idx + 2));

          for (final rawLine in lineBlock.split('\n')) {
            final line = rawLine.trim();
            if (!line.startsWith('data: ')) continue;

            final data = line.substring(6).trim();
            if (data == '[DONE]') return;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } on FormatException {
              // 忽略无法解析的行
            }
          }
        }
      }
    } on DioException catch (e) {
      yield _formatDioError(e);
    } catch (e) {
      yield '流式请求失败: $e';
    }
  }

  // ============================================================
  // 非流式对话
  // ============================================================

  /// 发起非流式 Chat Completion 请求，直接返回完整回复文本。
  Future<String> chatCompletion({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/chat/completions';

    try {
      final response = await _dio.post(
        url,
        data: {
          'model': model,
          'messages': messages,
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;

      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        return content ?? '';
      }

      return '';
    } on DioException catch (e) {
      return _formatDioError(e);
    } catch (e) {
      return '请求失败: $e';
    }
  }

  // ============================================================
  // 图像生成
  // ============================================================

  /// 调用图像生成 API，返回图片字节数据。
  ///
  /// 优先解析 base64 编码的图片（`b64_json`），
  /// 其次尝试通过返回的 URL 下载图片。
  Future<Uint8List?> generateImage({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    String size = '1024x1024',
  }) async {
    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/images/generations';

    try {
      final response = await _dio.post(
        url,
        data: {
          'model': model,
          'prompt': prompt,
          'n': 1,
          'size': size,
          'response_format': 'b64_json',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final images = data['data'] as List<dynamic>?;

      if (images == null || images.isEmpty) return null;

      final imageData = images[0] as Map<String, dynamic>?;

      // 优先 base64
      final b64 = imageData?['b64_json'] as String?;
      if (b64 != null && b64.isNotEmpty) {
        return base64Decode(b64);
      }

      // 其次通过 URL 下载
      final imageUrl = imageData?['url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imgResponse = await _dio.get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        return imgResponse.data as Uint8List?;
      }

      return null;
    } on DioException catch (e) {
      throw Exception(_formatDioError(e));
    } catch (e) {
      throw Exception('图像生成失败: $e');
    }
  }

  // ============================================================
  // 错误格式化
  // ============================================================

  /// 将 DioException 格式化为可读的错误信息。
  String _formatDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络或服务器地址';
      case DioExceptionType.sendTimeout:
        return '发送超时，请稍后重试';
      case DioExceptionType.receiveTimeout:
        return '接收超时，请检查网络连接';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        String detail = '';
        if (body is Map) {
          detail = body['error']?['message']?.toString() ?? body.toString();
        }
        return '服务器返回错误 ($statusCode): $detail';
      case DioExceptionType.cancel:
        return '请求已被取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      default:
        return '请求异常: ${e.message}';
    }
  }
}