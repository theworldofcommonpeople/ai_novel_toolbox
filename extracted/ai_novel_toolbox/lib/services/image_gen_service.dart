import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/api_config.dart';
import 'cloud_api_service.dart';

/// 图像生成服务
///
/// 封装封面图生成与本地文件保存逻辑。
/// 基于 [CloudApiService] 调用图像生成 API 并持久化图片至本地存储。
class ImageGenService {
  final CloudApiService _cloudService;

  ImageGenService({CloudApiService? cloudService})
      : _cloudService = cloudService ?? CloudApiService();

  // ============================================================
  // 封面生成
  // ============================================================

  /// 根据书名和描述生成封面图片并保存到本地。
  ///
  /// [title] 用于构建图片文件名。
  /// [description] 和 [config] 中的图像模型参数用于调用生成 API。
  ///
  /// 返回保存成功后的文件路径；失败时返回 null。
  Future<String?> generateCover(
    String title,
    String description,
    ApiConfig config,
  ) async {
    // 校验最低配置
    if (config.imageBaseUrl == null || config.imageBaseUrl!.isEmpty) {
      throw Exception('未配置图像生成 API 地址');
    }
    if (config.imageApiKey == null || config.imageApiKey!.isEmpty) {
      throw Exception('未配置图像生成 API 密钥');
    }
    if (config.imageModelName == null || config.imageModelName!.isEmpty) {
      throw Exception('未配置图像生成模型名称');
    }

    // 构造生成 prompt
    final prompt = _buildCoverPrompt(title, description);

    try {
      final imageBytes = await _cloudService.generateImage(
        baseUrl: config.imageBaseUrl!,
        apiKey: config.imageApiKey!,
        model: config.imageModelName!,
        prompt: prompt,
        size: '1024x1024',
      );

      if (imageBytes == null) {
        throw Exception('图像生成 API 未返回有效图片数据');
      }

      // 保存到本地
      final filename = _sanitizeFilename(title);
      final filePath = await saveImage(imageBytes, filename);
      return filePath;
    } catch (e) {
      throw Exception('封面生成失败: $e');
    }
  }

  // ============================================================
  // 图片保存
  // ============================================================

  /// 将字节数据保存为本地图片文件。
  ///
  /// [filename] 不含扩展名，自动追加 `.png`。
  /// 文件保存在应用目录下的 `generated_covers` 子目录中。
  ///
  /// 返回完整文件路径。
  Future<String> saveImage(Uint8List bytes, String filename) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(p.join(appDir.path, 'generated_covers'));

      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final safeName = _sanitizeFilename(filename);
      // 添加时间戳避免重名覆盖
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fullFilename = '${safeName}_$timestamp.png';
      final filePath = p.join(coversDir.path, fullFilename);

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('图片保存失败: $e');
    }
  }

  // ============================================================
  // 内部工具方法
  // ============================================================

  /// 构建封面生成专用 prompt。
  ///
  /// 在书名和描述前添加风格指令，指导 AI 生成适合小说封面的图像。
  String _buildCoverPrompt(String title, String description) {
    final buffer = StringBuffer();

    buffer.writeln('Book cover illustration for a novel:');
    buffer.writeln('Title: $title');
    if (description.isNotEmpty) {
      buffer.writeln('Description: $description');
    }
    buffer.writeln(
      'Style: Professional novel cover art, rich colors, cinematic lighting, '
      'no text or typography on the image, vertical composition suitable '
      'for a book cover, high quality digital art.',
    );

    // 添加中文小说封面风格指导
    buffer.writeln(
      '适合中文网络小说的封面风格，色彩饱满，构图大气，'
      '富有故事感和视觉冲击力，画面干净无文字。'
    );

    return buffer.toString();
  }

  /// 清理文件名中的非法字符。
  String _sanitizeFilename(String input) {
    if (input.isEmpty) return 'cover';

    // 替换中文特殊字符为合法替代
    String sanitized = input
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    // 限制长度
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }

    return sanitized.isNotEmpty ? sanitized : 'cover';
  }
}