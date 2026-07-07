import 'package:flutter/material.dart';

/// 桌面 / 宽屏断点（单位：逻辑像素）。
///
/// 屏幕宽度 >= [kDesktopBreakpoint] 时，导航切换为左侧 [NavigationRail]，
/// 内容区采用双栏布局；否则保持移动端单栏 + 底部导航。
const double kDesktopBreakpoint = 900;

/// 响应式判断的便捷扩展。
///
/// 在任意 widget 的 build 中通过 `context.isDesktop` 即可拿到当前是否宽屏，
/// 避免各页面散落写死 `MediaQuery.of(context).size.width > N`。
extension ResponsiveContext on BuildContext {
  /// 当前宽度是否达到桌面断点。
  bool get isDesktop => MediaQuery.sizeOf(this).width >= kDesktopBreakpoint;
}
