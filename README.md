# DSH WorkBuddy Kit

鎶婃湰鏈?DeepSeek Harness 0.2.2-rc.5 鍙婂叾鎻掍欢銆侀厤缃€佽缃钩绉诲埌涓€鍙板叏鏂?Windows 鐢佃剳銆?**涓嶅寘鍚换浣曚細璇濊褰?*锛屼篃涓嶅寘鍚处鍙峰瘑鐮併€丄PI Key銆丆ookie銆丱Auth token銆?
## 涓€鏉″懡浠わ紙鍦?WorkBuddy 閲屾墽琛岋級

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:TEMP 'dsh-workbuddy-kit-bootstrap.ps1'; iwr -UseBasicParsing 'https://github.com/574210187-ship-it/dsh-workbuddy-kit/releases/latest/download/bootstrap.ps1' -OutFile $p; & $p"
```

## 瀹冧細鍋氫粈涔?
1. 浼樺厛閫夋嫨 D:锛堟病鏈?D: 鍒?E:锛屾渶鍚庢墠鐢?C:锛夊垱寤哄畨瑁呯洰褰曚笌 DSH home銆?2. 涓嬭浇骞惰В鍘?`dsh-app.zip` 鍒?`D:\DSH022`銆?3. 涓嬭浇骞惰В鍘?`dsh-home.zip` 鍒?`D:\Users\<鐢ㄦ埛鍚?\Documents\deepseek-harness\dsh-rc5-home`銆?4. 閲嶅缓鏈湴鎻掍欢 `dsh-phone-remote` 鐨?junction銆?5. 璁剧疆鐢ㄦ埛绾?`DSH_HOME` 涓?`DSH_AGENTS_HOME`銆?6. 瀹夎骞跺惎鍔ㄤ究鎼虹増 Magpie锛堝彲閫夛紝`-SkipMagpie` 鍙烦杩囷級銆?7. 鍒涘缓銆孌eepSeek Harness銆嶆闈㈠揩鎹锋柟寮忓苟鍚姩銆?
瀹夎鍚庡鏋?DSH 鐨勬ā鍨嬪垪琛ㄩ渶瑕?Magpie锛氬厛鎵撳紑 Magpie锛岀櫥褰?WorkBuddy / Antigravity / Codex 绛夎处鍙凤紝鍐嶅湪 DSH 妯″瀷鑿滃崟涓€夋嫨瀵瑰簲妯″瀷銆?
## 宸叉湁 DSH + Magpie 鐨勬柊鐢佃剳锛氭帴涓荤數鑴戠殑渚涘簲鍟?
濡傛灉鏂扮數鑴戝凡缁忚濂?DSH 鍜?Magpie锛屽彧鏄?Magpie 閲屾病鏈変緵搴斿晢锛屾墽琛岃繖涓€鏉★細

```powershell
$p=Join-Path $env:TEMP 'dsh-remote-magpie.ps1'; iwr -UseBasicParsing 'https://github.com/574210187-ship-it/dsh-workbuddy-kit/releases/download/v1.0.0/tailscale-remote-magpie.ps1' -OutFile $p; & $p
```

鑴氭湰浼氭彁绀虹矘璐翠富鐢佃剳鐨?Magpie 缃戝叧瀵嗛挜锛堝瘑閽ユ枃浠跺湪涓荤數鑴?`D:\dsh-kit-release\gateway-key.txt`锛夈€傜劧鍚庡畠浼氾細

1. 瀹夎 Tailscale 骞跺皾璇曠櫥褰曪紱鐧诲綍澶辫触鎴栨病鏈?Tailscale 鏃惰嚜鍔ㄨ蛋 Funnel HTTPS锛屼粛鐒跺彲鐢ㄣ€?2. 鍦?Magpie 閲屾坊鍔?`Remote magpie` provider锛坕d `office`锛夛紝鎷夊彇涓荤數鑴戠殑 32 涓ā鍨嬨€?3. 鎶?`settings.yaml` 閲?Magpie 妯″瀷 id 鍔犱笂 `office/` 鍓嶇紑銆?4. 璁剧疆 `MAGPIE_GATEWAY_KEY`锛岄噸鍚?DSH銆?5. 鏀瑰啓鍓嶈嚜鍔ㄥ浠?`settings.yaml.bak-remote-<鏃堕棿>`銆?
濡傛灉涓嶆兂瀹夎 Tailscale锛岀洿鎺ヨ蛋 Funnel锛?
```powershell
& $p -SkipTailscale
```

## 鍖呭唴瀹?
| 鏂囦欢 | 鍐呭 |
|---|---|
| `dsh-app.zip` | DeepSeek Harness 0.2.2-rc.5 瀹屾暣绋嬪簭锛堝惈鍐呯疆 runtime锛屾棤闇€鍙﹁ Node锛?|
| `dsh-home.zip` | `dsh-rc5-home` 鐨勯厤缃€佹彃浠躲€乣profiles\desktop`锛堝惈宸插畨瑁呬緷璧栵級锛?*涓嶅惈 sessions** |
| `magpie.zip` | 渚挎惡鐗?Magpie 缃戝叧锛坄magpie.exe` + 妯″瀷 provider 閰嶇疆锛屼笉鍚櫥褰曞嚟鎹級 |
| `bootstrap.ps1` | DSH 涓€閿畨瑁呰剼鏈?|
| `tailscale-remote-magpie.ps1` | 鏂扮數鑴戞帴涓荤數鑴?Magpie 鐨勪竴閿剼鏈?|

## 宸叉帓闄?
- `sessions/`銆乣attachments/`銆乣pod/`銆乣storages/session_projcache` 绛変細璇?鑱婂ぉ鏁版嵁
- `.credentials.yaml`銆丮agpie `logins.json`銆乣plugin-auth.json`銆乣workbuddy-vault` 绛夊嚟鎹枃浠?- `dsh-runtimes/`锛堟湰鏈?junction 鎸囧悜鐨勫閮?runtime锛?- `cache/`銆乣backups/`銆乣rewind-snapshots/`銆乣logs/` 绛夎繍琛屾椂缂撳瓨

## 鎵嬪姩鍙傛暟锛堝彲閫夛級

```powershell
# 鎸囧畾瀹夎鐩綍涓?home 鏍圭洰褰?powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -InstallDir 'D:\DSH022' -DocsRoot 'D:\Users\浣犵殑鐢ㄦ埛鍚峔Documents\deepseek-harness'

# 鍙В鍘嬩笉鍚姩
powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -NoLaunch
```

## 绯荤粺瑕佹眰

- Windows 10/11 x64
- PowerShell 5.1+
- 鑷冲皯 4 GB 鍙敤纾佺洏绌洪棿锛堝缓璁?8 GB锛?- 鑳借闂?GitHub Releases
