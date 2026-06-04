# GitHub Actions 自动编译指南

无需 Mac 电脑，使用 GitHub 免费提供的 macOS 服务器自动编译 iOS 应用。

## ? 快速开始（3 分钟搞定）

### 步骤 1：创建 GitHub 仓库

1. 访问 [github.com](https://github.com)
2. 点击右上角 `+` → `New repository`
3. 仓库名填 `BLEScanner`
4. 选择 `Public`（免费）或 `Private`（需要付费账户）
5. 点击 `Create repository`

### 步骤 2：上传代码

```bash
# 在你的项目目录下执行
cd BLEScanner

# 初始化 Git
git init
git add .
git commit -m "Initial commit"

# 连接远程仓库（将 YOUR_USERNAME 替换为你的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/BLEScanner.git
git branch -M main
git push -u origin main
```

或者直接拖拽文件夹到 GitHub 网页上传。

### 步骤 3：触发自动编译

1. 打开 GitHub 仓库页面
2. 点击上方的 **Actions** 标签
3. 在左侧选择 **Build iOS App**
4. 点击右侧的 **Run workflow** → **Run workflow**

等待约 5-10 分钟...

### 步骤 4：下载 IPA 文件

1. 编译完成后，点击最新的 workflow run
2. 页面底部找到 **Artifacts** 部分
3. 点击 **BLEScanner-IPA** 下载

---

## ? 安装到 iPhone

### 方法 A：使用 AltStore（推荐，免费）

1. 电脑安装 [AltServer](https://altstore.io/)（Windows/Mac 都有）
2. iPhone 连接电脑，安装 AltStore
3. iPhone 上打开 AltStore
4. 点击 `+` 号，选择下载的 `BLEScanner.ipa`
5. 输入 Apple ID（免费账号即可）
6. 安装完成！

?? **注意**：免费账号签名的应用 7 天后需要重新签名，打开 AltStore 刷新即可。

### 方法 B：使用 SideStore（无需电脑，推荐）

1. 按照 [SideStore 官方指南](https://sidestore.io/) 安装
2. 在 iPhone 上直接安装 IPA，无需电脑
3. 同样 7 天需要刷新一次

### 方法 C：使用 Xcode（如果你有 Mac）

1. 打开 Xcode
2. Window → Devices and Simulators
3. 连接 iPhone，点击 `+` 选择 IPA 安装

---

## ?? 高级配置

### 自动触发编译

当前配置是 `push` 到 main 分支时自动编译。

修改 `.github/workflows/build-ios.yml` 可自定义：

```yaml
on:
  push:
    branches: [ main ]  # push 到 main 时触发
  pull_request:
    branches: [ main ]  # 提交 PR 时触发
  schedule:
    - cron: '0 0 * * 0'  # 每周日自动编译（持续集成）
  workflow_dispatch:      # 手动触发按钮
```

### 启用真实 MAC 地址模式

默认已启用（`-DENABLE_REAL_MAC_ADDRESS`）。

如需关闭（用于 App Store 上架）：

1. 修改 `.github/workflows/build-ios.yml`
2. 找到 `xcodebuild` 命令
3. 在 `OTHER_SWIFT_FLAGS` 中移除 `-DENABLE_REAL_MAC_ADDRESS`

### 修改 Bundle ID

当前使用 `com.example.BLEScanner`，如果要安装多个版本：

1. 打开 `BLEScanner/Info.plist`
2. 修改 `CFBundleIdentifier` 为你自己的 ID，如 `com.yourname.blescanner`

---

## ? 付费开发者账号配置（可选）

如果你有 Apple Developer 账号 ($99/年)，可以配置自动签名：

### 需要的 Secrets：

在 GitHub 仓库 → Settings → Secrets and variables → Actions 中添加：

| Secret 名称 | 说明 | 获取方式 |
|------------|------|---------|
| `BUILD_CERTIFICATE_BASE64` | 证书文件 base64 | `base64 -i certificate.p12` |
| `P12_PASSWORD` | 证书密码 | 导出证书时设置 |
| `BUILD_PROVISION_PROFILE_BASE64` | 描述文件 base64 | `base64 -i profile.mobileprovision` |
| `KEYCHAIN_PASSWORD` | 任意密码 | 自行设置 |
| `DEVELOPMENT_TEAM_ID` | 团队 ID | Apple Developer Portal |

### 配置步骤：

1. 下载你的 Distribution 证书和 Provisioning Profile
2. 转换为 base64：
   ```bash
   base64 -i Certificates.p12 -o cert.txt
   base64 -i BLEScanner.mobileprovision -o profile.txt
   ```
3. 复制内容添加到 GitHub Secrets
4. 使用 `build-ios-signed.yml` workflow

这样生成的 IPA 可以直接安装，无需 AltStore 重新签名！

---

## ? 常见问题

### Q: GitHub Actions 是免费的吗？
**A:** 
- **Public 仓库**：完全免费，无限制
- **Private 仓库**：每月 2000 分钟免费额度（约 400 次编译）

### Q: 为什么生成的 IPA 无法直接安装？
**A:** 因为未签名。iOS 应用必须经过 Apple 签名才能安装。使用 AltStore/SideStore 可以自动重新签名。

### Q: 可以编译出直接安装的 IPA 吗？
**A:** 可以，但需要付费 Apple Developer 账号并配置签名 secrets。

### Q: 编译失败了怎么办？
**A:** 
1. 检查代码是否有语法错误
2. 查看 Actions 日志中的错误信息
3. 确认 `project.pbxproj` 文件正确包含所有 Swift 文件

### Q: 编译时间多久？
**A:** 
- 首次编译：约 8-12 分钟（需要下载 Xcode 工具链）
- 后续编译：约 3-5 分钟

---

## ? 文件说明

```
.github/workflows/
├── build-ios.yml          # 主要 workflow（未签名）
└── build-ios-signed.yml   # 签名 workflow（需要配置 secrets）
```

---

## ? 下一步

1. ? 创建 GitHub 仓库
2. ? 上传代码
3. ? 触发 Actions 编译
4. ? 下载 IPA
5. ? 用 AltStore 安装到 iPhone
6. ? 开始使用 BLE Scanner！

---

## ? 需要帮助？

- GitHub Actions 文档：https://docs.github.com/cn/actions
- AltStore 帮助：https://faq.altstore.io/
- Apple 开发者支持：https://developer.apple.com/support/
