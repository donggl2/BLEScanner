# BLE Scanner 安装失败？按这个做

GitHub 编译出的 `BLEScanner.ipa` **本身没有你的 Apple 证书**，  
不能直接装到手机，必须用爱思 **先签名再安装**。

---

## 第一步：iPhone 开「开发者模式」（必做）

1. **设置 → 隐私与安全性 → 开发者模式**
2. 打开 → 重启手机 → 确认启用

（没有这个选项：先连一次爱思再试）

---

## 第二步：爱思获取免费签名证书（关键！）

很多人漏了这步，所以一直装不上。

1. 打开 **爱思助手**，连上 iPhone
2. 顶部 **工具箱**
3. 找到 **IPA 签名** 或 **Apple ID 签名**
4. 点 **添加 Apple ID** → 登录你的 Apple ID
5. 点 **获取证书** / **下载证书**（免费，约 7 天有效）
6. 看到证书状态为 **正常/有效**

---

## 第三步：签名并安装 IPA

1. 仍在 **IPA 签名** 页面
2. **添加 IPA** → 选 `BLEScanner.ipa`（从 GitHub 下载 zip 解压得到）
3. **选择刚获取的证书**
4. 点 **开始签名** → 签名完成后 **安装到设备**
5. 不要用「越狱应用」入口

---

## 第四步：信任证书

**设置 → 通用 → VPN 与设备管理 → 你的 Apple ID → 信任**

---

## 第五步：打开 App

允许 **蓝牙** 权限。

---

## 文件注意

| 正确 | 错误 |
|------|------|
| 解压 `BLEScanner-IPA.zip` 得到 `.ipa` | 把 `.zip` 当 ipa 装 |
| 路径 `C:\BLEScanner.ipa` | 路径含中文 |
| 用爱思 **IPA签名** 安装 | 直接拖进 Sideloadly |

---

## 仍失败？

### 重新编译（需更新 GitHub）

本地已改：Bundle ID、签名方式、Info.plist。  
因 push 困难，请在 GitHub 网页更新仓库后 **Actions 重新编译**，再下载新 IPA。

需更新文件：
- `.github/workflows/build-ios.yml`
- `BLEScanner.xcodeproj/project.pbxproj`
- `BLEScanner/Info.plist`

### 备选工具

- **3uTools**：应用 → 安装 → 选 ipa
- **借 Mac + Xcode**：最稳，连 iPhone 直接 Run

### 发我这些信息

1. iPhone 系统版本
2. IPA 文件大小（右键属性）
3. 爱思 **IPA签名** 页面的报错截图（不是越狱应用页）

---

## 7 天后过期

证书过期后 App 打不开 → 爱思 **重新签名安装** 同一 IPA 即可。
