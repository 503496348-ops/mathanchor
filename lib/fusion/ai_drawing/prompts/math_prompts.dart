/// MathAnchor AI Drawing Prompts
/// 移植自 PlotKityCat 项目，用于数学可视化代码生成
///
/// 这个类包含了所有用于 AI 绘图功能的 Prompt 模板，
/// 包括代码生成、优化和修复等场景。
class MathDrawingPrompts {
  /// 私有构造函数，防止实例化
  MathDrawingPrompts._();

  /// 系统 Prompt
  ///
  /// 定义 AI 的角色和输出格式要求
  static const String systemPrompt = '''
你是一个专业的数学可视化代码生成专家，擅长使用 Python 的 Matplotlib 库生成数学图形。

你的核心职责：
1. 根据用户的自然语言描述，生成可以直接运行的 Matplotlib Python 代码
2. 代码必须完整、正确、可执行
3. 图形要美观、清晰、专业

输出格式严格要求：
- 必须将代码放在 ```python 代码块中
- 代码块外可以有简短的中文说明
- 代码必须包含必要的 import 语句
- 不要使用交互式命令（如 plt.show() 之外的 input() 等）

代码规范：
- 使用 import matplotlib.pyplot as plt
- 使用 import numpy as np
- 设置中文字体支持：plt.rcParams['font.sans-serif'] = ['SimHei']
- 设置负号显示：plt.rcParams['axes.unicode_minus'] = False
- 图形大小：figsize=(10, 6)
- 添加标题、坐标轴标签、图例
- 使用网格线：plt.grid(True, alpha=0.3)
- 末尾调用 plt.tight_layout() 和 plt.show()
''';

  /// 基础可视化生成模板
  ///
  /// 用于将用户的自然语言描述转换为 Matplotlib 绘图代码
  ///
  /// 模板变量:
  /// - {description}: 用户的自然语言描述
  static const String visualizeTemplate = '''
你是一个专业的数学可视化助手。根据用户的描述，生成 Matplotlib 绘图代码。

用户描述: {description}

要求:
1. 生成清晰、美观的数学图形
2. 使用合适的颜色和线条样式
3. 添加必要的标注和说明
4. 确保代码简洁高效
5. 包含必要的中文注释

代码格式要求:
- 使用 matplotlib.pyplot 作为 plt
- 使用 numpy 作为 np
- 图形大小设置为 figsize=(10, 6)
- 添加适当的标签和标题
- 使用中文显示支持

生成代码:
''';

  /// 代码优化模板
  ///
  /// 用于优化现有的 Matplotlib 代码，使其更加美观和高效
  ///
  /// 模板变量:
  /// - {current_code}: 当前需要优化的代码
  /// - {instruction}: 优化指令
  static const String optimizeTemplate = '''
请优化以下 Matplotlib 代码，使其更加美观和高效。

当前代码:
```python
{current_code}
```

优化要求: {instruction}

优化方向:
1. 提高代码可读性和可维护性
2. 改进视觉效果和用户体验
3. 优化性能和执行效率
4. 保持功能完整性

请将优化后的完整代码放在 ```python 代码块中返回。
''';

  /// 错误修复模板
  ///
  /// 用于修复 Matplotlib 代码中的错误
  ///
  /// 模板变量:
  /// - {current_code}: 当前有错误的代码
  /// - {error_text}: 错误信息
  static const String repairTemplate = '''
请修复以下 Matplotlib 代码中的错误。

当前代码:
```python
{current_code}
```

错误信息:
```
{error_text}
```

请分析错误原因，并将修复后的完整代码放在 ```python 代码块中返回。
''';

  /// 函数图像生成模板
  ///
  /// 专门用于生成数学函数图像
  ///
  /// 模板变量:
  /// - {function}: 函数表达式
  /// - {range}: 自变量范围
  static const String functionPlotTemplate = '''
根据以下数学函数，生成 Matplotlib 绘图代码。

函数: y = {function}
变量范围: {range}

要求:
1. 绘制平滑的函数曲线
2. 标注坐标轴和函数名称
3. 添加网格线便于读数
4. 使用适当的颜色和线宽
5. 标注重要的特征点（如极值点、零点等）

生成代码:
''';

  /// 几何图形生成模板
  ///
  /// 用于生成几何图形的可视化
  ///
  /// 模板变量:
  /// - {description}: 几何图形描述
  static const String geometryPlotTemplate = '''
根据以下描述，生成几何图形的 Matplotlib 绘图代码。

几何描述: {description}

要求:
1. 准确绘制几何图形
2. 使用适当的颜色区分不同元素
3. 添加必要的标注和尺寸
4. 保持图形比例准确
5. 添加图例说明

生成代码:
''';

  /// 数据可视化模板
  ///
  /// 用于生成数据统计图表
  ///
  /// 模板变量:
  /// - {data_description}: 数据描述
  /// - {chart_type}: 图表类型
  static const String dataVisualizationTemplate = '''
根据以下数据需求，生成 Matplotlib 数据可视化代码。

数据描述: {data_description}
推荐图表类型: {chart_type}

要求:
1. 选择合适的图表类型
2. 使用清晰的颜色方案
3. 添加数据标签和图例
4. 确保数据可读性
5. 添加适当的标题和轴标签

生成代码:
''';

  /// 获取指定类型的 Prompt
  ///
  /// [type] Prompt 类型
  /// 返回对应的 Prompt 模板
  static String getPrompt(String type) {
    switch (type) {
      case 'visualize':
        return visualizeTemplate;
      case 'optimize':
        return optimizeTemplate;
      case 'repair':
        return repairTemplate;
      case 'function':
        return functionPlotTemplate;
      case 'geometry':
        return geometryPlotTemplate;
      case 'data':
        return dataVisualizationTemplate;
      default:
        return visualizeTemplate;
    }
  }

  /// 格式化 Prompt 模板
  ///
  /// [template] Prompt 模板
  /// [variables] 变量映射
  /// 返回格式化后的 Prompt
  static String formatTemplate(String template, Map<String, String> variables) {
    String result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}