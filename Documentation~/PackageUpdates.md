# 插件检查与更新（0.4.9）

CH自定义工具集使用公开仓库 [Ch47369/CHCustomTools](https://github.com/Ch47369/CHCustomTools)。统一入口 **Tools → CH自定义工具集 → 设置 → 插件更新**；检查、下载、安装状态和错误提示都在当前窗口显示。Package Manager 选中本包后，详情扩展区域也可检查更新。只有发现比当前安装版本更高的正式版本时，才显示“更新到 X.Y.Z”按钮；检查失败、版本相同或远程版本更旧时均隐藏。

Unity 的 Git 包没有注册表包原生的版本发现机制。本工具使用公开 `IPackageManagerExtension` 添加详情区域，未修改 Unity 内部 UI，也不会把 Git 包加入注册表的“更新”列表。

## 安装与首次修复

Package Manager → **Add package from git URL**：

```text
https://github.com/Ch47369/CHCustomTools.git
```

固定本次版本可加 `#v0.4.9`。公开 HTTPS 地址无需 GitHub 登录，首次 Git URL 安装仍需 Unity 能找到 Git。旧地址 `Ch47369/ShaderConverter` 继续兼容。

0.4.7 及更早更新器若卡在 Git 克隆或认证提示，请从 [正式发布页](https://github.com/Ch47369/CHCustomTools/releases/tag/v0.4.9) 下载 `.tgz`，通过 **Add package from tarball** 手动安装一次 0.4.9。这会启用新的公开 Release 更新器。无需另装音频插件。

## 日常更新

1. 编辑器空闲时自动检查，也可在插件更新页点击“检查更新”。检查成功后只提供严格高版本的正式发布，不升级到预览版本。
2. HTTPS 更新直接读取 GitHub Release API，不调用 Git、不读取开发者本地仓库，也不要求凭据或登录。
3. 点击“更新到 X.Y.Z”，从 GitHub 分段下载发布安装包；逐段检查范围、长度，整包检查大小和 SHA-256。
4. 校验通过后交给 Unity Package Manager 安装，脚本重载后确认实际版本与安装来源。下载或校验失败时保留现有安装。

后台成功检查间隔为一小时，失败后五分钟再试；手动检查可立即重试。网络请求有超时和有限重试，下载显示进度。安装依赖解析期间请等待 Unity 完成，避免同时修改项目包依赖。

已校验安装包保存在项目 **`Packages/CHCustomToolsCache~`**，manifest 引用该文件。Package Manager 的底层来源可能显示 Local tarball，工具内来源显示 GitHub Release；后续仍从公开 GitHub 检查、下载更新。请将这个缓存目录和 manifest 一起保留，以便其他机器恢复项目。不要在仍被 manifest 引用时删除缓存。

## 安装来源与兼容

从本地目录或 Tarball 安装时也能更新到 GitHub 正式发布；外部源码目录和原始 Tarball 会保留。同版本未由工具管理的安装可选择切换到 GitHub Release，已经由工具管理的同版本不重复提供迁移操作。

嵌入项目 `Packages` 的源码包需要先备份并移出，再选择正式安装来源。其他仓库、fork 或注册表来源不由此更新器接管。SSH 安装继续使用原 Git 标签传输方式，需要本机 Git 和已配置的 SSH 密钥；新安装建议使用上面的公开 HTTPS 地址。

## 失败提示

- 网络、DNS、VPN、代理或超时：修复连接后重试。公开 HTTPS 更新没有登录步骤。
- 发布安装包或校验信息无效：联系作者检查 Release，工具不会安装未经验证的文件。
- 缓存已有同名但校验不一致的文件：先备份并移走该文件再重试，工具不会覆盖它。
- 安装包已下载，但 UPM 解析失败：查看当前项目 Package Manager 的具体依赖错误后重试。

初次 Git URL 安装及 SSH 更新仍可能产生 Git 自身错误，需按实际传输方式检查。原始凭据诊断不会显示在插件报告中。

音频/VFX、更新器在 Unity 2022.3 和 Unity 6 的验证，不扩大 Shader Graph 后端的版本支持；转换范围仍按 [图格式路线与限制](ShaderConversionRoadmap.md) 执行。
