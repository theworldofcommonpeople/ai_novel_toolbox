# AI小说创作工具箱（增强版）

手机端 AI 辅助小说创作 App，支持云端 API 与本地模型混合推理。

## 功能清单

### 基础生成器（12个）

| 序号 | 功能 | 说明 |
|------|------|------|
| 1 | 脑洞生成器 | 随机生成新颖、反套路的故事开局或核心设定 |
| 2 | 书名生成器 | 根据小说类型/关键词生成多个爆款风格书名 |
| 3 | 简介生成器 | 根据书名+故事梗概生成300字以内吸量简介 |
| 4 | 大纲生成器 | 生成三幕式或章节式故事大纲 |
| 5 | 细纲生成器 | 基于大纲拆解为每章500-800字的细纲 |
| 6 | 黄金开篇生成器 | 生成小说前500-1000字的开篇 |
| 7 | 金手指生成器 | 为主角设计独特的金手指（系统/重生/异能等） |
| 8 | 名字生成器 | 批量生成人名、地名、物品名、势力名 |
| 9 | 人设生成器 | 生成完整角色设定 |
| 10 | 世界观生成器 | 构建虚构世界的规则、历史、势力、地理 |
| 11 | 词条生成器 | 生成道具、技能、功法、法宝等设定 |
| 12 | 书名测试 | 书名自动套用到固定封面模板上预览 |
| 13 | 封面生成器 | 调用图片生成API生成小说封面图 |

### 高级功能（3个）

| 序号 | 功能 | 说明 |
|------|------|------|
| 14 | 超长文伏笔续写 | RAG+关系图谱，百万字级自动检索前文伏笔 |
| 15 | 新人物自动生成角色卡 | 写作中检测新人物，自动创建角色卡 |
| 16 | 一致性检查与修改 | 修改角色卡后检测历史章节冲突，逐章修改 |

## 技术栈

- **框架**: Flutter 3.x (Dart)
- **状态管理**: Riverpod
- **本地存储**: SQLite (sqflite)
- **网络请求**: Dio (支持 SSE 流式)
- **本地模型**: flutter_llama (GGUF)
- **加密存储**: flutter_secure_storage

## 环境准备

### 1. 安装 Flutter SDK

```bash
# macOS
brew install flutter

# 或从官网下载
# https://docs.flutter.dev/get-started/install
```

验证安装：
```bash
flutter doctor
```

### 2. 克隆项目

```bash
cd ai_novel_toolbox
flutter pub get
```

### 3. 运行项目

```bash
# Android 设备或模拟器
flutter run

# iOS 模拟器 (仅 macOS)
flutter run -d ios
```

## API 配置

### 获取 API Key

#### DeepSeek（推荐，性价比高）
1. 访问 [platform.deepseek.com](https://platform.deepseek.com/)
2. 注册账号并充值
3. 在 API Keys 页面创建 Key
4. 在App设置中填入：
   - Base URL: `https://api.deepseek.com/v1`
   - API Key: 你的Key
   - Model: `deepseek-chat`

#### OpenAI
1. 访问 [platform.openai.com](https://platform.openai.com/)
2. 注册并获取 API Key
3. 在App设置中填入：
   - Base URL: `https://api.openai.com/v1`
   - API Key: 你的Key
   - Model: `gpt-4o` 或 `gpt-3.5-turbo`

#### 其他兼容接口
支持所有兼容 OpenAI Chat Completions 格式的 API（如 Qwen、Claude 等）。

### 图片生成 API

- **DALL-E**: Base URL `https://api.openai.com/v1`，Model `dall-e-3`
- **通义万相**: 需配置阿里云 DashScope API
- **Stability AI**: 需单独配置 Stable Diffusion API

## 本地模型配置

### 下载模型

推荐使用以下模型（中文优化）：

1. **Qwen2.5-1.5B-Instruct-GGUF** (推荐)
   - 下载地址: [HuggingFace Qwen2.5-1.5B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF)
   - 推荐量化版本: `q4_k_m` (平衡速度与质量，约1GB)

2. **MiniCPM5-1B-GGUF**
   - 下载地址: 搜索 HuggingFace MiniCPM5 GGUF
   - 推荐量化: `Q4_K_M`

### 放置模型文件

将下载的 `.gguf` 文件放置到以下路径：

- **Android**: `Android/data/com.example.ai_novel_toolbox/files/models/`
- **iOS**: 通过 iTunes 文件共享或 App 内文件选择器导入

可在 App 设置页面的"本地模型"区域加载和管理模型。

## RAG 功能使用

RAG（检索增强生成）用于超长文伏笔/人物关联续写。

### 启用 RAG

1. 进入设置页面 -> RAG功能 -> 开启
2. 创建小说项目，保存章节
3. 系统会自动对章节进行索引（切片+向量化）
4. 续写时，系统自动检索前文相关伏笔和人物信息

### 注意事项

- 首次索引大量章节会耗时，建议在 Wi-Fi 环境下后台进行
- 高内存使用（嵌入模型 ~500MB），低端手机建议关闭
- 可在设置中随时关闭 RAG 功能

## 角色卡自动生成

1. 在写作/续写页面中，系统每30秒自动检测新出现的人名
2. 检测到新人物后，自动调用人设生成器创建角色卡
3. 弹出对话框展示角色卡，可编辑后保存
4. 保存的角色卡自动用于 RAG 检索和一致性检查

## 一致性检查操作步骤

1. 进入"一致性检查"页面
2. 选择小说项目和要检查的角色
3. 修改角色卡中的属性（如性格、外貌等）
4. 点击"开始检查"，系统自动检索历史章节中的冲突段落
5. 选择需要修改的冲突段落
6. 点击"逐章修改"，AI 自动修正冲突描述
7. 预览修改前后对比（Diff视图），确认后应用

### 注意事项

- 每步修改都需要用户确认，不会自动覆盖
- 修改前会自动备份原章节
- 逐章调用 API，请注意 token 消耗

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/
│   ├── api_config.dart          # API配置模型
│   ├── character_card.dart      # 角色卡模型
│   ├── entity_relation.dart     # 实体关系模型
│   ├── generation_history.dart  # 历史记录模型
│   └── novel_project.dart       # 小说项目模型
├── services/
│   ├── ai_service.dart          # 统一AI调用接口
│   ├── cloud_api_service.dart   # OpenAI兼容API
│   ├── entity_extractor.dart    # 实体抽取
│   ├── image_gen_service.dart   # 封面图片生成
│   ├── local_model_service.dart # 本地模型推理
│   ├── rag_service.dart         # RAG检索增强
│   └── storage_service.dart     # 数据库服务
├── pages/
│   ├── home_page.dart           # 主页网格
│   ├── generator_base.dart      # 通用生成器
│   ├── bookname_test_page.dart  # 书名测试
│   ├── cover_generator_page.dart # 封面生成
│   ├── consistency_check_page.dart # 一致性检查
│   ├── character_list_page.dart # 角色卡管理
│   └── settings_page.dart       # 设置页面
├── widgets/
│   ├── parameter_form.dart      # 动态参数表单
│   ├── result_display.dart      # 结果显示
│   ├── history_list.dart        # 历史记录列表
│   └── diff_viewer.dart         # 修改对比组件
└── utils/
    ├── constants.dart           # 常量配置
    ├── prompt_templates.dart    # 提示词模板
    └── text_splitter.dart       # 文本切片工具
```

## 常见问题 (FAQ)

**Q: API 调用失败怎么办？**
A: 检查 Base URL 和 API Key 是否正确。确保网络连接正常。可在设置页点"测试连接"验证。

**Q: 本地模型加载失败？**
A: 确认模型文件路径正确，模型格式为 GGUF。推荐使用 Q4_K_M 量化级别。

**Q: 生成结果不满意？**
A: 点击"重新生成"按钮，或调整输入参数（更改提示词、类型等）。

**Q: RAG 检索速度慢？**
A: 可在设置中关闭 RAG，或限制 RAG 仅在续写时启用。建议分章节逐步索引。

**Q: 如何导出小说？**
A: 当前版本支持复制文本到剪贴板。后续版本将支持 TXT/Markdown 导出。

**Q: 支持哪些 AI 模型？**
A: 支持所有兼容 OpenAI Chat Completions 格式的 API，包括 DeepSeek、GPT-4、Claude、Qwen 等。

## 开发计划

- [x] 12 个基础生成器
- [x] 书名测试（封面模板预览）
- [x] AI 封面生成
- [x] 本地模型集成
- [x] RAG 伏笔/人物关联续写
- [x] 新人物自动生成角色卡
- [x] 一致性检查与半自动修改
- [ ] TXT/Markdown 导出
- [ ] 云端同步
- [ ] 多语言支持

## License

MIT License - 仅供个人学习和创作使用。