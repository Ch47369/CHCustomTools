# 无效历史记录，不作为生成证据

原补跑进程因 Unity 授权握手失败而退出，没有进入 UnityLibraryBuild。该文件夹中的 results/probe 是收集时误读的前次记录，标题不符合最终计划，已排除在最终结果之外。

真正的成功重跑是相邻目录 `Build-BuiltIn-final-grid-verified`；最终合并结果 `Build-BuiltIn/results.json` 已引用新输出。原失败日志保留于工作区 `.build~/ValidationRuns/Library-031-Grid-BuiltIn.log`，后续正常重试日志为 `Library-031-Grid-BuiltIn-final.log`。
