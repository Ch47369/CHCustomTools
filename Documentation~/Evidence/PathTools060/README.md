# PathTools060

独立路径工具实现与隔离Unity验证。最终来源测试结果在 verification.json；最终TGZ实际安装和公开GitHub升级报告在 Releases~，不把源目录测试替代最终安装。

参考研究：references.json 固定Path-Creator与BezierSolution提交及原始文件SHA；research-downloads.json 保留文档下载和LICENSE路径404。源码仅本地只读研究，未复制/分发。

实现采用标准三次Bezier、自适应细分的世界弧长表、二分距离查找、并行传输与闭合接缝修正。不是Unity Splines资源适配器。测试覆盖变换/退化/竖直/闭合/roll、实际网格UV/法线/切线/面朝向/资产持久化、Prefab关联/Undo、确定时间运动和Play中的Update、统一窗口四页中英/预览恢复/重载。

首轮2022测试通过95项（含真实运行位置和朝向），退出Play模式收尾超时。原始日志与失败检查保留 .build~/PathTools060/Attempts/20261113093112961。后续调整隔离项目runInBackground与异步ExitPlaymode，复测以最终报告为准，不把超时记录计为通过。

范围：Windows D3D11、两版Unity；运行时Play已验证不等于独立Player构建已验证。网格是视觉几何，不自动加Collider或做结构计算。UV1是特效进度而非光照图。静态输出需要重建；急弯可能相交。

第二次隐藏窗口重载后 delayCall 未及时触发，阶段7进度和日志保留 Attempts/20261113093530781。测试恢复和退出Play改为一次性Editor更新回调后，两版均99项通过。最终源码测试为2022 Attempts/20261113093734515、Unity6 Attempts/20261113093818308。629核心检查通过，两个EditorCompile均0警告/错误；编译输出随证据提供。
