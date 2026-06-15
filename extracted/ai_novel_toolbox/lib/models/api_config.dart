/// API配置模型
class ApiConfig {
  final int? id;
  final String? textBaseUrl;
  final String? textApiKey;
  final String? textModelName;
  final String? imageBaseUrl;
  final String? imageApiKey;
  final String? imageModelName;
  final int useCloudFirst;

  ApiConfig({
    this.id,
    this.textBaseUrl,
    this.textApiKey,
    this.textModelName,
    this.imageBaseUrl,
    this.imageApiKey,
    this.imageModelName,
    this.useCloudFirst = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text_base_url': textBaseUrl,
      'text_api_key': textApiKey,
      'text_model_name': textModelName,
      'image_base_url': imageBaseUrl,
      'image_api_key': imageApiKey,
      'image_model_name': imageModelName,
      'use_cloud_first': useCloudFirst,
    };
  }

  factory ApiConfig.fromMap(Map<String, dynamic> map) {
    return ApiConfig(
      id: map['id'] as int?,
      textBaseUrl: map['text_base_url'] as String?,
      textApiKey: map['text_api_key'] as String?,
      textModelName: map['text_model_name'] as String?,
      imageBaseUrl: map['image_base_url'] as String?,
      imageApiKey: map['image_api_key'] as String?,
      imageModelName: map['image_model_name'] as String?,
      useCloudFirst: map['use_cloud_first'] as int? ?? 1,
    );
  }

  ApiConfig copyWith({
    int? id,
    String? textBaseUrl,
    String? textApiKey,
    String? textModelName,
    String? imageBaseUrl,
    String? imageApiKey,
    String? imageModelName,
    int? useCloudFirst,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      textBaseUrl: textBaseUrl ?? this.textBaseUrl,
      textApiKey: textApiKey ?? this.textApiKey,
      textModelName: textModelName ?? this.textModelName,
      imageBaseUrl: imageBaseUrl ?? this.imageBaseUrl,
      imageApiKey: imageApiKey ?? this.imageApiKey,
      imageModelName: imageModelName ?? this.imageModelName,
      useCloudFirst: useCloudFirst ?? this.useCloudFirst,
    );
  }
}