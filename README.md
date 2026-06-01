# OG Calendar - 极简日历

一款 iOS 极简日历应用，融合公历与农历双历显示，标注中国法定节假日及调休信息，关联系统日历事件，并提供交互式桌面小组件。

## 功能特性

- 🗓 **双历日历** - 公历 + 农历同时显示
- 🏖 **节假日标注** - 中国法定节假日及调休日标识
- 🌿 **24节气** - 自动计算显示二十四节气
- 📅 **系统日历** - 关联读取系统日历事件
- 📱 **交互式小组件** - 桌面小组件支持切换日期、查看事件
- 🎨 **现代设计** - 柔和配色、圆角卡片、极简风格

## 环境要求

- Xcode 16.0+
- iOS 18.0+
- Swift 6.0
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (用于生成 Xcode 项目)

## 快速开始

### 1. 安装 xcodegen

```bash
brew install xcodegen
```

### 2. 生成 Xcode 项目

```bash
chmod +x setup.sh
./setup.sh
```

### 3. 在 Xcode 中配置

1. 打开 `OGCalendar.xcodeproj`
2. 在 **Signing & Capabilities** 中选择你的 Development Team
3. 为 **OGCalendar** 和 **OGCalendarWidget** 两个 Target 都添加 App Group: `group.com.ogcalendar.shared`
4. Build & Run (⌘R)

## 打包 IPA

### 方式一：未签名打包（推荐 Sideloadly 用户）

无需 Apple 开发者账号，打包后用 Sideloadly 签名安装：

```bash
./build/build_ipa.sh -u
```

打包完成后用 [Sideloadly](https://sideloadly.io) 安装：
1. 下载安装 Sideloadly
2. iPhone 连接电脑，打开 Sideloadly
3. 将 IPA 拖入 Sideloadly
4. 输入 Apple ID（免费账号即可）
5. Sideloadly 会自动签名并安装到手机

> 免费账号签名的 App 7 天过期，重新签名即可续期。

### 方式二：签名打包（需 Apple 开发者账号）

```bash
# 查找你的 Team ID：Xcode → Settings → Accounts → Apple ID → Team ID
./build/build_ipa.sh -t YOUR_TEAM_ID

# Ad-Hoc 方式
./build/build_ipa.sh -t YOUR_TEAM_ID -m ad-hoc

# 清理后重新打包
./build/build_ipa.sh -t YOUR_TEAM_ID -c
```

### 方式三：免费 Apple ID 个人团队

在 Xcode 中用 Apple ID 登录（无需付费），获取个人 Team ID：

```bash
./build/build_ipa.sh -t PERSONAL_TEAM_ID
```

> 免费个人团队签名的 App 同样 7 天过期。

打包完成后 IPA 文件位于项目根目录。

## 项目结构

```
og-calendar/
├── OGCalendar/                    # 主应用
│   ├── App/                       # App 入口
│   ├── Models/                    # 数据模型
│   ├── ViewModels/                # 视图模型
│   ├── Views/                     # SwiftUI 视图
│   ├── Resources/                 # 资源文件
│   │   └── holidays.json          # 节假日数据 (2024-2027)
│   └── Assets.xcassets/           # 图片资源
├── OGCalendarWidget/              # 小组件扩展
│   ├── CalendarWidget.swift       # Widget 入口及 Timeline
│   ├── CalendarWidgetView.swift   # Widget UI
│   ├── CalendarWidgetIntent.swift # 交互 Intent
│   └── CalendarWidgetBundle.swift # Widget Bundle
├── OGCalendarShared/              # 共享代码
│   ├── Models/                    # 共享模型
│   └── Services/                  # 共享服务
├── build/
│   └── build_ipa.sh               # IPA 打包脚本
├── project.yml                    # xcodegen 配置
└── setup.sh                       # 项目初始化脚本
```

## 技术方案

| 模块 | 技术 |
|------|------|
| UI 框架 | SwiftUI |
| 农历转换 | Apple Calendar(identifier: .chinese) |
| 节假日 | 内置 JSON 数据 |
| 系统日历 | EventKit |
| 小组件 | WidgetKit + AppIntent |
| 数据共享 | App Group |
| 打包 | xcodebuild + Shell |

## 设计规范

- **主色调**: #3B7DD8 (蓝色)
- **节假日色**: #E8743A (暖橙)
- **背景色**: #F7F8FA (浅灰)
- **圆角**: 12-16pt
- **字体**: PingFang SC

## License

MIT
