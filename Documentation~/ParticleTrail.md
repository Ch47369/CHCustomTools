# 曲线转粒子拖尾 / Curve to particle trail

适用于 Unity 2022.3 LTS。打开 **Tools → CH自定义工具集 → 特效 → 曲线转粒子拖尾**。

1. 将场景中的 Particle System 拖到目标栏，或在层级中选中后点击「使用当前选中的粒子系统」。
2. 勾选「在 Scene 视图中编辑路径」。按住 Shift 左键依次落点，放开 Shift 拖动控制点或使用移动轴。落点位于通过上一点的观察平面，可旋转场景视角继续绘制三维路径。选中点后 Delete 删除，F 聚焦。
3. 设置路径用时（0.1 至 120 秒）。曲线使用平滑控制点与弧长采样，显示起点、终点及行进方向。
4. 查看运动模块冲突提示，点击「烘焙」或「重新烘焙」。工具配置单粒子 Burst、生命周期、本地模拟和 Velocity over Lifetime 的 X/Y/Z 三条曲线，并启用原生 Trails。
5. 点击「选中粒子系统进行预览」，使用 Unity Scene 的粒子预览控制播放、暂停和重启。移动点或修改用时后可再次烘焙。

控制点以粒子系统局部坐标保存，关闭窗口或保存并重新打开场景后可继续编辑。移动或旋转特效根对象时路径和本地模拟的粒子、拖尾一起变换。修改非均匀缩放后重新烘焙可重新按实际世界弧长分配时间。

烘焙支持 Undo/Redo。Start Speed、重力、Noise、Force、速度限制、外力、碰撞等干扰运动的模块会被调整，Emission 改为一次单粒子发射，Trails 使用 Per Particle 本地拖尾。保留已有材质、颜色、宽度、粒子外观及拖尾生命周期。用户可在 Renderer 指定兼容当前管线的 Trail Material。

烘焙采用 257 个归一化速度关键帧。粒子通过 Unity 原生按帧积分速度行进，实际误差与模拟时间步长、曲线形状及路径用时相关。长时间步长下，粒子终点和中段误差会增大。建议在目标播放帧率检查成品效果。

## English

Select a Particle System and enable Scene path editing. Shift-click to add control points, drag a point or its position handle, Delete to remove it and F to frame it. Set travel time, review the motion settings and Bake. Use Unity's built-in particle preview controls to play the system. The local points and duration are stored on the target object. Bake again after edits. The resulting motion uses native Velocity over Lifetime curves and Trails.
