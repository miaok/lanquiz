# 1V1挑战 - 局域网知识竞答游戏

一个基于 Flutter 开发的局域网多人知识竞答游戏，支持两名玩家通过 WiFi 局域网进行实时对战。

## ✨ 功能特点

### 核心功能
- 🎮 **1V1 实时对战**：两名玩家通过 WiFi 局域网连接，实时竞答
- 📱 **跨平台支持**：支持 Windows、Android 等平台（windows有点问题待解决）
- 🏠 **房主/客户端模式**：一人创建房间，另一人加入
- 📊 **实时得分显示**：动态展示双方得分和进度对比
- 🎯 **多种题型**：支持单选题、判断题、多选题

### 游戏特性
- 🎨 **动态 UI**：根据玩家相对优势动态调整颜色和文本
- 🔄 **题目乱序**：每次答题选项随机排列，防止记忆位置
- 📈 **进度追踪**：实时显示答题进度和相对位置
- 🌓 **主题切换**：支持浅色/深色/跟随系统三种主题模式

### 网络功能
- 📡 **WiFi 检测**：确保使用 WiFi 局域网连接
- 🔍 **自动发现房间**：通过 UDP 广播自动发现局域网内的房间
- 🌐 **IP 地址显示**：显示所有玩家的 IP 地址，便于调试

## 🚀 快速开始

### 环境要求
- Flutter SDK 3.9.0 或更高版本
- Dart SDK 3.9.0 或更高版本
- 支持的平台：Windows、Android

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd lanquiz
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
flutter run
```

## 🎮 使用说明

### 创建房间（房主）
1. 确保设备已连接 WiFi 局域网
2. 在主页输入昵称
3. 点击"创建房间"
4. 设置题目数量（可选择预设模式：娱乐/标准/极限）
5. 等待其他玩家加入
6. 所有玩家准备后点击"开始游戏"

### 加入房间（客户端）
1. 确保设备已连接与房主相同的 WiFi 局域网
2. 在主页输入昵称
3. 点击"加入房间"
4. 应用会自动搜索并连接到房间
5. 点击"准备"按钮
6. 等待房主开始游戏

### 游戏规则
- **基础分数**：每题答对得1分
- **胜利条件**：完成所有题目后，得分最高者获胜

## 📁 项目结构

```
lib/
├── quiz/
│   ├── data/                    # 数据层
│   │   └── question_repository.dart  # 题库管理
│   ├── models/                  # 数据模型
│   │   ├── player.dart          # 玩家模型
│   │   ├── question.dart        # 题目模型
│   │   └── quiz_room.dart       # 房间模型
│   ├── screens/                 # 页面
│   │   ├── quiz_home_screen.dart      # 主页
│   │   ├── quiz_host_screen.dart      # 房主页面
│   │   ├── quiz_client_screen.dart    # 客户端页面
│   │   ├── quiz_game_screen.dart      # 游戏页面
│   │   ├── quiz_result_screen.dart    # 结果页面
│   │   └── widgets/             # 组件
│   │       ├── player_score_board.dart    # 得分板
│   │       ├── question_card.dart         # 题目卡片
│   │       ├── option_button.dart         # 选项按钮
│   │       └── ...
│   ├── services/                # 服务层
│   │   ├── quiz_network_service.dart      # 网络服务
│   │   ├── quiz_host_service.dart         # 房主服务
│   │   ├── quiz_client_service.dart       # 客户端服务
│   │   └── quiz_game_controller.dart      # 游戏控制器
│   ├── theme/                   # 主题
│   │   ├── app_theme.dart       # 主题定义
│   │   └── theme_provider.dart  # 主题管理
│   └── widgets/                 # 全局组件
│       └── theme_switcher.dart  # 主题切换器
└── main.dart                    # 应用入口
```

## 🎨 主题系统

应用支持三种主题模式：
- **浅色模式**：适合白天使用
- **深色模式**：适合夜间使用
- **跟随系统**：自动跟随系统主题设置

主题色基于 Material Design 3，使用 `#255E40` 作为主色调。

## 🔧 技术栈

- **框架**：Flutter 3.9.0+
- **语言**：Dart 3.9.0+
- **网络**：TCP/UDP Socket 通信
- **状态管理**：StatefulWidget + StreamController
- **UI 设计**：Material Design 3

## 📝 题库配置

题库文件位于 `assets/data/questions.json`，支持三种题型：

### 题型格式
```json
{
  "id": "q1",
  "type": "singleChoice",  // singleChoice | trueFalse | multipleChoice
  "question": "题目内容",
  "options": ["选项A", "选项B", "选项C", "选项D"],
  "correctAnswer": 0  // 单选/判断：数字索引，多选：数组 [0, 2]
}
```

### 题型说明
- **singleChoice**：单选题，
- **trueFalse**：判断题，正确/错误
- **multipleChoice**：多选题，可选多个

## 🌐 网络配置

### 端口设置
- **TCP 端口**：4050（用于数据传输）
- **UDP 端口**：4055（用于房间发现）

### WiFi 要求
- 必须连接到 WiFi 局域网
- 支持的 IP 地址段：
  - `10.0.0.0 - 10.255.255.255`
  - `172.16.0.0 - 172.31.255.255`
  - `192.168.0.0 - 192.168.255.255`

## 🐛 常见问题

### 无法创建/加入房间
- 确保设备已连接 WiFi（不支持移动数据）
- 检查防火墙是否允许应用访问网络
- 确保两台设备在同一局域网内

### 连接断开
- 检查 WiFi 信号强度
- 确保设备未进入休眠模式
- 重启应用重新连接

### 题目显示异常
- 检查 `assets/data/questions.json` 格式是否正确
- 确保题目数量配置不超过题库总数

---

**开发者**: miaok and Gemini3 AI  
**最后更新**: 2025-11-21
