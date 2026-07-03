import 'package:flutter/material.dart';
import 'package:mathmate/fusion/models/ai_models.dart';
import 'package:mathmate/fusion/ai_drawing/services/ai_drawing_service.dart';
import 'package:mathmate/fusion/ai_drawing/widgets/code_viewer.dart';

/// AI 绘图页面
///
/// 提供通过自然语言生成数学可视化图形的功能
class AIDrawingPage extends StatefulWidget {
  const AIDrawingPage({super.key});

  @override
  State<AIDrawingPage> createState() => _AIDrawingPageState();
}

class _AIDrawingPageState extends State<AIDrawingPage> {
  // 控制器
  final TextEditingController _descriptionController = TextEditingController();
  final AIDrawingService _aiService = AIDrawingService();

  // 状态
  String _generatedCode = '';
  bool _isGenerating = false;
  String? _errorMessage;
  VisualizationType _selectedType = VisualizationType.general;

  // 加载提示（根据当前操作显示不同文案）
  String _loadingHint = '生成中...';

  // 历史记录
  final List<VisualizationRecord> _history = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// 生成可视化
  Future<void> _generateVisualization() async {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _errorMessage = '请输入描述');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedCode = '';
      _loadingHint = 'AI 生成中...';
    });

    try {
      final result = await _aiService.generateVisualization(
        description: _descriptionController.text,
        type: _selectedType,
      );

      if (result.isSuccess) {
        setState(() => _generatedCode = result.code);

        // 添加到历史记录
        _addToHistory(
          _descriptionController.text,
          result.code,
          _selectedType,
        );
      } else {
        setState(() => _errorMessage = result.errorMessage ?? '生成失败');
      }
    } catch (e) {
      setState(() => _errorMessage = '生成失败: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// 添加到历史记录
  void _addToHistory(String description, String code, VisualizationType type) {
    final record = VisualizationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      generatedCode: code,
      type: type,
      createdAt: DateTime.now(),
    );

    setState(() {
      _history.insert(0, record);
      // 限制历史记录数量
      if (_history.length > 20) {
        _history.removeLast();
      }
    });
  }

  /// 从历史记录加载
  void _loadFromHistory(VisualizationRecord record) {
    setState(() {
      _descriptionController.text = record.description;
      _generatedCode = record.generatedCode;
      _selectedType = record.type;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 绘图'),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(),
            tooltip: '历史记录',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: '帮助',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 输入区域卡片
            _buildInputCard(),
            const SizedBox(height: 16),

            // 错误信息
            if (_errorMessage != null) _buildErrorCard(),
            if (_errorMessage != null) const SizedBox(height: 16),

            // 生成的代码
            if (_generatedCode.isNotEmpty)
              _buildCodeCard(),
          ],
        ),
      ),
    );
  }

  /// 构建输入卡片
  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 类型选择
            _buildTypeSelector(),
            const SizedBox(height: 16),

            // 描述输入框
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '描述你想要的数学图形...\n\n例如:\n'
                    '• 绘制一个正弦函数图像，x范围从0到2π\n'
                    '• 画一个单位圆，标注圆心和半径\n'
                    '• 绘制柱状图显示数据对比',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 生成按钮
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateVisualization,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[700],
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _loadingHint,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    )
                  : const Text(
                      '生成图形',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'AI 正在思考中，请耐心等待（通常需要 5-15 秒）...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建类型选择器
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图形类型',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: VisualizationType.values.map((type) {
            return ChoiceChip(
              label: Text(_getTypeDisplayName(type)),
              selected: _selectedType == type,
              onSelected: (selected) {
                setState(() => _selectedType = type);
              },
              selectedColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: _selectedType == type ? Colors.blue[900] : Colors.grey[700],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建错误卡片
  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[900]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _errorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建代码卡片
  Widget _buildCodeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '生成的代码',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showOptimizeDialog(),
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('优化'),
                    ),
                    TextButton.icon(
                      onPressed: () => _regenerate(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新生成'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: CodeViewerWidget(
                code: _generatedCode,
                editable: true,
                onCodeChanged: (newCode) {
                  setState(() => _generatedCode = newCode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示历史记录对话框
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史记录'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _history.isEmpty
              ? const Center(child: Text('暂无历史记录'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final record = _history[index];
                    return ListTile(
                      title: Text(record.description),
                      subtitle: Text(
                        '${_getTypeDisplayName(record.type)} • ${_formatTime(record.createdAt)}',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _loadFromHistory(record);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '如何使用 AI 绘图功能：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. 选择图形类型'),
              Text('2. 输入你想要的图形描述'),
              Text('3. 点击"生成图形"按钮'),
              Text('4. 查看 and 编辑生成的代码'),
              SizedBox(height: 16),
              Text(
                '支持的图形类型：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 函数图像：三角函数、多项式等'),
              Text('• 几何图形：圆、矩形、三角形等'),
              Text('• 数据图表：柱状图、折线图、饼图等'),
              Text('• 通用图形：其他自定义图形'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示优化对话框
  void _showOptimizeDialog() {
    final instructionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('优化代码'),
        content: TextField(
          controller: instructionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '输入优化要求，例如：让线条更粗、改变颜色、添加网格等',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _optimizeCode(instructionController.text);
            },
            child: const Text('优化'),
          ),
        ],
      ),
    );
  }

  /// 优化代码
  Future<void> _optimizeCode(String instruction) async {
    setState(() {
      _isGenerating = true;
      _loadingHint = 'AI 优化中...';
    });

    try {
      final result = await _aiService.optimizeCode(
        currentCode: _generatedCode,
        instruction: instruction,
      );

      if (result.isSuccess) {
        setState(() => _generatedCode = result.code);
      } else {
        setState(() => _errorMessage = result.errorMessage);
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// 重新生成
  void _regenerate() {
    _generateVisualization();
  }

  /// 获取类型显示名称
  String _getTypeDisplayName(VisualizationType type) {
    switch (type) {
      case VisualizationType.function:
        return '函数图像';
      case VisualizationType.geometry:
        return '几何图形';
      case VisualizationType.dataChart:
        return '数据图表';
      case VisualizationType.general:
        return '通用图形';
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}