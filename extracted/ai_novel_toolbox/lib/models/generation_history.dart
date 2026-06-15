/// 生成历史记录模型
class GenerationHistory {
  final int? id;
  final String generatorType;
  final String inputParams;
  final String output;
  final int timestamp;

  GenerationHistory({
    this.id,
    required this.generatorType,
    required this.inputParams,
    required this.output,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'generator_type': generatorType,
      'input_params': inputParams,
      'output': output,
      'timestamp': timestamp,
    };
  }

  factory GenerationHistory.fromMap(Map<String, dynamic> map) {
    return GenerationHistory(
      id: map['id'] as int?,
      generatorType: map['generator_type'] as String? ?? '',
      inputParams: map['input_params'] as String? ?? '',
      output: map['output'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  GenerationHistory copyWith({
    int? id,
    String? generatorType,
    String? inputParams,
    String? output,
    int? timestamp,
  }) {
    return GenerationHistory(
      id: id ?? this.id,
      generatorType: generatorType ?? this.generatorType,
      inputParams: inputParams ?? this.inputParams,
      output: output ?? this.output,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}