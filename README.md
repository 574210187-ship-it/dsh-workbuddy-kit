# DSH WorkBuddy Kit

把本机 DeepSeek Harness 0.2.2-rc.5 及其插件、配置、设置平移到一台全新 Windows 电脑。
**不包含任何会话记录**，也不包含账号密码、API Key、Cookie、OAuth token。

## 一条命令（在 WorkBuddy 里执行）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'dsh-workbuddy-kit-bootstrap.ps1'; iwr -UseBasicParsing 'https://github.com/574210187-ship-it/dsh-workbuddy-kit/releases/latest/download/bootstrap.ps1' -OutFile $p; & $p"
```

## 它会做什么

1. 优先选择 D:（没有 D: 则 E:，最后才用 C:）创建安装目录与 DSH home。
2. 下载并解压 `dsh-app.zip` 到 `D:\DSH022`。
3. 下载并解压 `dsh-home.zip` 到 `D:\Users\<用户名>\Documents\deepseek-harness\dsh-rc5-home`。
4. 重建本地插件 `dsh-phone-remote` 的 junction。
5. 设置用户级 `DSH_HOME` 与 `DSH_AGENTS_HOME`。
6. 安装并启动便携版 Magpie（可选，`-SkipMagpie` 可跳过）。
7. 创建「DeepSeek Harness」桌面快捷方式并启动。

安装后如果 DSH 的模型列表需要 Magpie：先打开 Magpie，登录 WorkBuddy / Antigravity / Codex 等账号，再在 DSH 模型菜单中选择对应模型。

## 包内容

| 文件 | 内容 |
|---|---|
| `dsh-app.zip` | DeepSeek Harness 0.2.2-rc.5 完整程序（含内置 runtime，无需另装 Node） |
| `dsh-home.zip` | `dsh-rc5-home` 的配置、插件、`profiles\desktop`（含已安装依赖），**不含 sessions** |
| `magpie.zip` | 便携版 Magpie 网关（`magpie.exe` + 模型 provider 配置，不含登录凭据） |
| `bootstrap.ps1` | 一键安装脚本 |

## 已排除

- `sessions/`、`attachments/`、`pod/`、`storages/session_projcache` 等会话/聊天数据
- `.credentials.yaml`、Magpie `logins.json`、`plugin-auth.json`、`workbuddy-vault` 等凭据文件
- `dsh-runtimes/`（本机 junction 指向的外部 runtime）
- `cache/`、`backups/`、`rewind-snapshots/`、`logs/` 等运行时缓存

## 手动参数（可选）

```powershell
# 指定安装目录与 home 根目录
powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -InstallDir 'D:\DSH022' -DocsRoot 'D:\Users\你的用户名\Documents\deepseek-harness'

# 只解压不启动
powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -NoLaunch
```

## 系统要求

- Windows 10/11 x64
- PowerShell 5.1+
- 至少 4 GB 可用磁盘空间（建议 8 GB）
- 能访问 GitHub Releases
