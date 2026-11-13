# 第三方许可说明

0.3.5 的 `ReviewedMaterialAdaptation / Aspect-LayeredParallaxGlitter` 为 AspectURP 三层视差流麻 Shader 的 ASE 原生图改写。来源 https://github.com/aspect-ux/AspectURP ，固定提交 `5944b6eb656d76e0371c9831a1ac50fbf8f1d934`，路径 `Assets/Cases/流麻/流麻flow.shader`，完整身份见 Evidence/Showcase035/source-review.json。参考项目原始源码和贴图不随插件分发，示例贴图为原创程序生成。仓库根 LICENSE 原文如下：

MIT License

Copyright (c) 2024 Unknown

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

0.3.3 分类库的 PublicSourceAdaptation / Kino-Vignette、Kino-AnalogGlitch、Kino-DigitalGlitch、Kino-Mirror 为下列 MIT 源码算法的 ASE 原生图改写。源码文件的完整身份、固定提交和 SHA-256 见 Evidence/PublicLibrary033/download-manifest.json 与 source-analysis.json。原始 Shader、原 C# 宿主和原项目素材不随插件分发。

- https://github.com/keijiro/KinoVignette
- https://github.com/keijiro/KinoGlitch
- https://github.com/keijiro/KinoMirror

四个所选 Shader 文件自身均带有以下 MIT 声明；这些仓库没有被本次工具获取到的根 LICENSE，不能把未检查的其他文件一起视为同一许可。

Copyright (C) 2015 Keijiro Takahashi

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

本次另下载研究 knapeczadam/unity-shaders 的 37 份源码（MIT，Copyright (c) 2018 Knapecz Ádám），这些原始源码及衍生 Shader 尚未分发。分析身份留在目录中，状态 RequiresAdapter。

ASE 是用户目标项目中单独安装的第三方软件。本插件包不含 ASE 软件源码。

## 方木君玉石文章（0.3.6）

作者：方木君。参考文章：[Unity移动端高性能玉石材质](https://mp.weixin.qq.com/s/fzxGFhe5DofKpyauJSPypg)。用户指定此文章作为玉石 ASE 方案参考。文章未见明确开源许可，不将其标记为 MIT 或其他开放许可。

本包只分发独立编写的 ASE 原生节点实现及补充的标准 Lit 整合，保留来源署名与链接；没有收录文章全文、原代码文件、截图、模型、贴图或作者原完整 Shader。文章公开内容仅为核心函数，未提供完整材质/原场景，因此不声称完整原 Shader 或原画面等价。参考缓存排除在发布包之外，审查见 `Evidence/JadeArticle036/source-review.json`。
