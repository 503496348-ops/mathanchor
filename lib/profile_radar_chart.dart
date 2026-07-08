import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mathmate/models/user_radar_profile.dart';

/// 六边形能力雷达图组件
///
/// 每次显示时从中心点动画展开到实际得分位置。
/// 通过 [replay] 方法可外部触发重播动画。
class ProfileRadarChart extends StatefulWidget {
  /// 用户画像数据（null 时显示空图）
  final UserRadarProfile? profile;

  const ProfileRadarChart({super.key, this.profile});

  @override
  State<ProfileRadarChart> createState() => _ProfileRadarChartState();
}

class _ProfileRadarChartState extends State<ProfileRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // 首次加载时播放动画
    _controller.forward();
  }

  /// 从外部触发动画重播（先归零再展开）
  void replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UserRadarProfile profile =
        widget.profile ?? UserRadarProfile();

    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            size: const Size(300, 300),
            painter: _RadarChartPainter(
              scores: profile.scoreMap,
              animationValue: _animation.value,
              colorScheme: cs,
            ),
          );
        },
      ),
    );
  }
}

/// 六边形雷达图绘制器
///
/// 绘制 6 条轴、同心六边形网格、维度标签和动画化的数据填充多边形。
class _RadarChartPainter extends CustomPainter {
  final Map<String, double> scores;
  final double animationValue;
  final ColorScheme colorScheme;

  _RadarChartPainter({
    required this.scores,
    required this.animationValue,
    required this.colorScheme,
  });

  static const int _sides = 6;
  static const double _displayMaxScore = 10.0; // 展示满分
  static const int _gridLevels = 5; // 2, 4, 6, 8, 10 (展示刻度)

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 36;

    // 1. 绘制网格（同心六边形）
    _drawGrid(canvas, center, radius);

    // 2. 绘制轴线与标签
    _drawAxesAndLabels(canvas, center, radius);

    // 3. 绘制动画化数据多边形 + 顶点圆点 + 得分文字
    _drawDataPolygon(canvas, center, radius);
  }

  /// 获取第 i 条轴的角度（从顶部顺时针，即从 -π/2 开始）
  double _angle(int i) => -math.pi / 2 + 2 * math.pi * i / _sides;

  /// 绘制 5 层同心六边形网格
  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final Paint gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= _gridLevels; level++) {
      final double r = radius * level / _gridLevels;
      final Path path = Path();
      for (int i = 0; i < _sides; i++) {
        final double angle = _angle(i);
        final Offset p = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
  }

  /// 绘制 6 条轴线和维度标签
  void _drawAxesAndLabels(Canvas canvas, Offset center, double radius) {
    final Paint axisPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final List<String> dims = scores.keys.toList();

    for (int i = 0; i < _sides; i++) {
      final double angle = _angle(i);
      final Offset edge = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // 轴线
      canvas.drawLine(center, edge, axisPaint);

      // 维度标签
      final String label =
          i < dims.length ? dims[i] : '维度${i + 1}';
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 标签放在六边形外部，根据角度微调偏移
      final double labelRadius = radius + 22;
      double lx = center.dx + labelRadius * math.cos(angle) - tp.width / 2;
      double ly = center.dy + labelRadius * math.sin(angle) - tp.height / 2;
      // 顶部标签往上移一点，底部往下移一点，左右微调避免压线
      if (angle < -2.5 || angle > 2.5) {
        // 顶部
        ly -= 6;
      } else if (angle > -0.7 && angle < 0.7) {
        // 底部
        ly += 6;
      }
      tp.paint(canvas, Offset(lx, ly));
    }
  }

  /// 绘制动画化的数据多边形（填充 + 描边 + 顶点 + 得分）
  void _drawDataPolygon(Canvas canvas, Offset center, double radius) {
    final List<String> dims = scores.keys.toList();
    if (dims.isEmpty) return;

    final List<Offset> animatedPoints = <Offset>[];
    final List<double> displayScores = <double>[];

    for (int i = 0; i < _sides; i++) {
      final double angle = _angle(i);
      // 内部 1~5 → 展示 2~10
      final double internal =
          i < dims.length ? (scores[dims[i]] ?? 0.0).clamp(0.0, UserRadarProfile.maxScore) : 0.0;
      final double display = (internal * UserRadarProfile.displayMultiplier)
          .clamp(0.0, _displayMaxScore);
      displayScores.add(display);

      final double targetR = radius * display / _displayMaxScore;

      // 动画插值：从中心点到目标位置
      final double animatedR = targetR * animationValue;
      animatedPoints.add(Offset(
        center.dx + animatedR * math.cos(angle),
        center.dy + animatedR * math.sin(angle),
      ));
    }

    // 填充多边形
    final Paint fillPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.18 * animationValue)
      ..style = PaintingStyle.fill;

    final Path fillPath = Path();
    for (int i = 0; i < animatedPoints.length; i++) {
      if (i == 0) {
        fillPath.moveTo(animatedPoints[i].dx, animatedPoints[i].dy);
      } else {
        fillPath.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
      }
    }
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // 描边多边形
    final Paint strokePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.7 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Path strokePath = Path();
    for (int i = 0; i < animatedPoints.length; i++) {
      if (i == 0) {
        strokePath.moveTo(animatedPoints[i].dx, animatedPoints[i].dy);
      } else {
        strokePath.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
      }
    }
    strokePath.close();
    canvas.drawPath(strokePath, strokePaint);

    // 顶点圆点
    final Paint dotPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < animatedPoints.length; i++) {
      final Offset p = animatedPoints[i];
      // 只在离中心足够远时显示圆点
      if ((p - center).distance > 4.0) {
        canvas.drawCircle(p, 4.5, dotPaint);
      }
    }

    // 得分数字标注（动画 70% 后渐显）
    if (animationValue > 0.7) {
      final double textAlpha = ((animationValue - 0.7) / 0.3).clamp(0.0, 1.0);
      for (int i = 0; i < _sides; i++) {
        final double angle = _angle(i);
        final double display = displayScores[i];
        final double targetR = radius * display / _displayMaxScore;
        final double animatedR = targetR * animationValue;

        // 10 分制展示，保留两位小数
        final String scoreText = display.toStringAsFixed(2);
        final TextPainter scoreTp = TextPainter(
          text: TextSpan(
            text: scoreText,
            style: TextStyle(
              color: colorScheme.primary.withValues(alpha: textAlpha),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // 得分文字放在顶点外侧
        final double textR = animatedR + 14;
        final double tx = center.dx + textR * math.cos(angle) - scoreTp.width / 2;
        final double ty = center.dy + textR * math.sin(angle) - scoreTp.height / 2;
        scoreTp.paint(canvas, Offset(tx, ty));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.scores != scores;
  }
}
