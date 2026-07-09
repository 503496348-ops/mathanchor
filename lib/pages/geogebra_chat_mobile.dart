import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:math_anchor/services/geogebra_agent_service.dart';
import 'package:math_anchor/visualization/geogebra_mobile_bridge.dart';

/// 原生 Flutter GeoGebra Chat 页面 —— 移动端专用。
///
/// 架构：
/// - 上半：GeoGebra 画布（WebView 加载本地 HTML + JS Bridge 注入）
/// - 下半：聊天对话面板（Agent 流式响应 + 工具调用）
class GeogebraChatPage extends StatefulWidget {
  const GeogebraChatPage({super.key});

  @override
  State<GeogebraChatPage> createState() => _GeogebraChatPageState();
}

class _GeogebraChatPageState extends State<GeogebraChatPage> {
  final GeogebraAgentService _agent = GeogebraAgentService();
  late GeogebraMobileBridge _bridge;

  WebViewController? _ggbController;
  bool _ggbReady = false;
  bool _ggbLoading = true;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatBubble> _bubbles = [];
  bool _isLoading = false;
  double _chatHeightFraction = 4.0 / 7.0;

  @override
  void initState() {
    super.initState();
    _initGeoGebra();
  }

  Future<void> _initGeoGebra() async {
    try {
      final ctrl = WebViewController();
      ctrl.setJavaScriptMode(JavaScriptMode.unrestricted);
      ctrl.setBackgroundColor(const Color(0xFFFFFFFF));

      _bridge = GeogebraMobileBridge(ctrl);
      _ggbController = ctrl;
      _agent.onToolCall = _executeTool;

      ctrl.addJavaScriptChannel(
        'GgbBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message.startsWith('ready|')) {
            _bridge.markReady();
            if (mounted) setState(() { _ggbReady = true; _ggbLoading = false; });
            return;
          }
          _bridge.handleMessage(msg.message);
        },
      );

      // 自动解压本地 GeoGebra 离线文件（与数学工具箱一致），不再依赖 CDN
      final localPath = await _ensureLocalFiles();

      ctrl.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _injectBridge(ctrl),
          onWebResourceError: (_) {
            if (mounted) setState(() => _ggbLoading = false);
          },
        ),
      );
      await ctrl.loadFile(localPath);
    } catch (e) {
      debugPrint('[GeoChat] Init error: $e');
      // 本地文件加载失败时，回退到 CDN
      await _fallbackToCdn();
    }
  }

  /// 回退到 CDN 加载 GeoGebra（仅在本地文件不可用时）
  Future<void> _fallbackToCdn() async {
    try {
      if (_ggbController == null) return;
      await _ggbController!.loadHtmlString(_buildGgbHtml());
    } catch (e) {
      debugPrint('[GeoChat] CDN fallback error: $e');
      if (mounted) setState(() => _ggbLoading = false);
    }
  }

  /// 自动解压本地 GeoGebra 离线文件，与数学工具箱共用同一份
  Future<String> _ensureLocalFiles() async {
    final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/geogebra');

    if (await dir.exists()) {
      final html = File('${dir.path}/graphing.html');
      final web3d = File('${dir.path}/web3d/web3d.nocache.js');
      if (await html.exists() && await web3d.exists()) return html.path;
      // 文件不完整，删除重新解压
      await dir.delete(recursive: true);
    }

    await dir.create(recursive: true);

    final manifest =
        await rootBundle.loadString('assets/geogebra/file_manifest.txt');
    final files = manifest
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final file in files) {
      final data = await rootBundle.load('assets/geogebra/$file');
      final target = File('${dir.path}/$file');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(data.buffer.asUint8List());
    }

    return '${dir.path}/graphing.html';
  }

  /// 注入 JS Bridge —— 仅本地 GeoGebra 5.4 文件需要（CDN 版 HTML 已内置）
  Future<void> _injectBridge(WebViewController ctrl) async {
    const bridgeJs = '''
(function() {
  if (window._ggbBridgeReady) return;
  var ggb = null;
  function ready(api) {
    ggb = api;
    window._ggbBridgeReady = true;
    // 隐藏 GeoGebra 自带菜单栏、工具栏、代数输入（保持画布纯净）
    try { if (typeof ggb.setShowMenuBar === 'function') ggb.setShowMenuBar(false); } catch(e) {}
    try { if (typeof ggb.setShowToolBar === 'function') ggb.setShowToolBar(false); } catch(e) {}
    try { if (typeof ggb.setShowAlgebraInput === 'function') ggb.setShowAlgebraInput(false); } catch(e) {}
    window._ggbBridgeCallback = function(msg) {
      var p = msg.split('|'), t = p[0], id = p[1], pl = p.slice(2).join('|');
      try {
        var r = '';
        switch(t) {
          case 'evalCommand':
            // GeoGebra 5.x 用 evalCommand，6.x 用 evalCommandGetLabels
            if (typeof ggb.evalCommandGetLabels === 'function') {
              var lb = ggb.evalCommandGetLabels(pl);
              var er = '';
              try { er = ggb.getErrorString() || ''; } catch(e) {}
              r = JSON.stringify({success: !er, label: lb||null, error: er||null});
            } else if (typeof ggb.evalCommand === 'function') {
              var ok = ggb.evalCommand(pl);
              var err = '';
              try { err = ggb.getErrorString ? ggb.getErrorString() : ''; } catch(e) {}
              r = JSON.stringify({success: ok && !err, label: null, error: err||null});
            } else {
              r = JSON.stringify({success: false, label: null, error: 'no evalCommand API'});
            }
            break;
          case 'getXML':
            try { r = ggb.getXML ? ggb.getXML() : ''; } catch(e) { r = ''; }
            break;
          case 'deleteObject':
            try { ggb.deleteObject(pl); } catch(e) {}
            r = 'true';
            break;
          case 'setUndoPoint':
            try { ggb.setUndoPoint(); } catch(e) {}
            r = 'true';
            break;
          case 'undo':
            try { ggb.undo(); } catch(e) {}
            r = 'true';
            break;
          case 'setPerspective':
            try { ggb.setPerspective(pl); } catch(e) {}
            r = 'true';
            break;
          case 'reset':
            try { ggb.reset(); } catch(e) {}
            r = 'true';
            break;
          case 'getSelectedObjects':
            try { r = ggb.getSelectedObjects ? ggb.getSelectedObjects().join(',') : ''; } catch(e) { r = ''; }
            break;
        }
        GgbBridge.postMessage(t + '|' + id + '|' + r);
      } catch(e) { GgbBridge.postMessage('error|' + id + '|' + e.toString()); }
    };
    GgbBridge.postMessage('ready|0|{}');
  }
  if (window.ggbApplet) { ready(window.ggbApplet); return; }
  if (window.ggbApp && window.ggbApp.evalCommand) { ready(window.ggbApp); return; }
  var n = 0;
  var iv = setInterval(function() {
    n++;
    var api = window.ggbApplet || window.ggbApp || null;
    if (api && (typeof api.evalCommand === 'function' || typeof api.evalCommandGetLabels === 'function')) {
      clearInterval(iv); ready(api);
    } else if (n > 150) {
      clearInterval(iv);
      GgbBridge.postMessage('error|0|GeoGebra API not found after timeout');
    }
  }, 100);
})();
''';
    await ctrl.runJavaScript(bridgeJs);
  }

  /// CDN 版精简 GeoGebra HTML（本地文件不存在时使用）
  String _buildGgbHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<style>
  * { margin:0; padding:0; }
  html, body, #ggb { width:100%; height:100%; overflow:hidden; }
</style>
<script src="https://www.geogebra.org/apps/deployggb.js"></script>
</head>
<body>
<div id="ggb"></div>
<script>
  var ggbApp = new GGBApplet({
    "appName": "graphing",
    "width": "100%",
    "height": "100%",
    "showToolBar": false,
    "showAlgebraInput": false,
    "showMenuBar": false,
    "enableLabelDrags": false,
    "enableShiftDragZoom": true,
    "enableRightClick": false,
    "showResetIcon": false,
    "enable3d": true,
    "errorDialogsActive": false,
    "useBrowserForJS": false,
    "language": "zh",
    "borderColor": "#FFFFFF"
  }, true);
  ggbApp.setHTML5Codebase("https://www.geogebra.org/apps/HTML5/5.0/web3d/");

  window._ggbBridgeCallback = function(msg) {
    var parts = msg.split('|');
    var type = parts[0], msgId = parts[1];
    var payload = parts.length > 2 ? parts.slice(2).join('|') : '';
    try {
      // 确保 API 已就绪再执行
      if (!ggbApp || typeof ggbApp.evalCommandGetLabels !== 'function') {
        GgbBridge.postMessage('error|' + msgId + '|GeoGebra API 尚未就绪，请稍后重试');
        return;
      }
      var result = '';
      switch(type) {
        case 'evalCommand':
          var label = ggbApp.evalCommandGetLabels(payload);
          var err = (ggbApp.getErrorString && ggbApp.getErrorString()) || '';
          result = JSON.stringify({success: !err, label: label||null, error: err||null});
          break;
        case 'getXML':
          result = ggbApp.getXML() || '';
          break;
        case 'deleteObject':
          ggbApp.deleteObject(payload); result = 'true'; break;
        case 'setUndoPoint':
          ggbApp.setUndoPoint(); result = 'true'; break;
        case 'undo':
          ggbApp.undo(); result = 'true'; break;
        case 'setPerspective':
          ggbApp.setPerspective(payload); result = 'true'; break;
        case 'reset':
          ggbApp.reset(); result = 'true'; break;
        case 'getSelectedObjects':
          result = ggbApp.getSelectedObjects ? ggbApp.getSelectedObjects().join(',') : '';
          break;
        default: result = 'unknown';
      }
      GgbBridge.postMessage(type + '|' + msgId + '|' + result);
    } catch(e) {
      GgbBridge.postMessage('error|' + msgId + '|' + e.toString());
    }
  };

  ggbApp.inject('ggb', 'preferHTML5');

  // 等待 applet API 真正就绪后再通知 Flutter（最多等待 20 秒）
  var _apiAttempts = 0;
  (function waitForApi() {
    if (ggbApp && typeof ggbApp.evalCommandGetLabels === 'function') {
      GgbBridge.postMessage('ready|0|{}');
      return;
    }
    _apiAttempts++;
    if (_apiAttempts > 100) {
      GgbBridge.postMessage('error|0|GeoGebra 加载超时，请检查网络连接');
      return;
    }
    setTimeout(waitForApi, 200);
  })();
</script>
</body>
</html>
''';
  }

  /// 桥接 Agent 工具调用到 GeoGebra
  Future<String> _executeTool(String toolName, Map<String, dynamic> args) async {
    try {
      switch (toolName) {
        case 'getCanvasContext':
          final xml = await _bridge.getXML();
          final selected = await _bridge.getSelectedObjects();
          return _summarizeXML(xml, selected);

        case 'executeGeoGebraCommand':
          final cmd = args['command'] as String? ?? '';
          if (cmd.isEmpty) return 'Error: empty command';
          final result = await _bridge.evalCommand(cmd);
          if (result['success'] == true) {
            return '成功: ${result['label'] ?? "OK"}';
          }
          return '失败: ${result['error'] ?? "未知错误"}';

        case 'deleteGeoGebraObject':
          final label = args['label'] as String? ?? '';
          final ok = await _bridge.deleteObject(label);
          return ok ? '已删除 $label' : '删除 $label 失败';

        case 'setUndoPoint':
          final ok = await _bridge.setUndoPoint();
          return ok ? '撤销点已设置' : '设置撤销点失败';

        case 'undo':
          final ok = await _bridge.undo();
          return ok ? '已撤销' : '撤销失败';

        case 'setPerspective':
          final mode = args['mode'] as String? ?? 'G';
          final ok = await _bridge.setPerspective(mode);
          return ok ? '切换至 ${mode == 'T' ? '3D' : '2D'} 视图' : '切换视图失败';

        case 'getSelectedObjects':
          final objects = await _bridge.getSelectedObjects();
          return objects.isEmpty ? '无选中对象' : '选中: ${objects.join(", ")}';

        default:
          return '未知工具: $toolName';
      }
    } catch (e) {
      return '工具执行异常: $e';
    }
  }

  String _summarizeXML(String xml, List<String> selected) {
    if (xml.isEmpty) return '{}';
    final elementExp = RegExp(r'<element[^>]*type="(\w+)"[^>]*label="([^"]*)"');
    final matches = elementExp.allMatches(xml);
    final elements = matches.map((m) => '${m.group(1)}:${m.group(2)}').toList();
    final buf = StringBuffer();
    buf.writeln('{');
    buf.writeln('  "elements": ${elements.isNotEmpty ? elements.toString() : "[]"},');
    buf.writeln('  "selectedObjects": ${selected.toString()}');
    buf.writeln('}');
    return buf.toString();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading || !_ggbReady) return;

    _inputCtrl.clear();
    setState(() {
      _bubbles.add(ChatBubble(role: 'user', content: text));
      _bubbles.add(ChatBubble(role: 'assistant', content: '', isStreaming: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final history = <Map<String, String>>[];
    for (final b in _bubbles.where((b) => !b.isStreaming)) {
      history.add({'role': b.role, 'content': b.content});
    }
    history.removeLast(); // 去掉刚加的 streaming 占位

    try {
      final assistantIdx = _bubbles.length - 1;
      String fullContent = '';
      String pendingTool = '';

      await for (final chunk in _agent.chat(messages: history)) {
        if (!mounted) break;

        if (chunk.error != null) {
          fullContent += '\n\n> ⚠️ ${chunk.error}';
        } else if (chunk.toolCallName != null) {
          pendingTool = chunk.toolCallName!;
          // 立即显示工具调用状态
          fullContent += '\n\n⏳ 调用工具: `$pendingTool`...';
        } else if (chunk.toolResult != null) {
          // 替换掉之前的 ⏳ 占位为实际结果
          if (pendingTool.isNotEmpty) {
            final placeholder = '\n\n⏳ 调用工具: `$pendingTool`...';
            fullContent = fullContent.replaceFirst(
              placeholder,
              '\n\n✅ `$pendingTool` → ${chunk.toolResult}',
            );
            pendingTool = '';
          }
        } else if (chunk.textDelta != null) {
          fullContent += chunk.textDelta!;
        }

        if (mounted) {
          setState(() {
            _bubbles[assistantIdx] = ChatBubble(
              role: 'assistant',
              content: fullContent,
              isStreaming: !chunk.isDone,
            );
          });
          _scrollToBottom();
        }

        if (chunk.isDone) break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _bubbles.length - 1;
          _bubbles[idx] = ChatBubble(role: 'assistant', content: '请求失败: $e');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearCanvas() {
    if (_isLoading) {
      _agent.cancel();
      setState(() => _isLoading = false);
      return;
    }
    _bridge.reset();
    setState(() => _bubbles.clear());
  }

  void _undoLast() {
    _bridge.undo();
  }

  @override
  void dispose() {
    _agent.cancel();
    _bridge.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          const dividerHeight = 24.0;
          final availableHeight = (totalHeight - dividerHeight).clamp(0.0, totalHeight);
          final canvasHeight = (availableHeight * (1 - _chatHeightFraction)).clamp(0.0, availableHeight);
          final chatHeight = (availableHeight * _chatHeightFraction).clamp(0.0, availableHeight);

          return Column(
            children: [
              // GeoGebra 画布区域
              SizedBox(
                height: canvasHeight,
                child: Stack(
                  children: [
                    if (_ggbController != null)
                      Positioned.fill(
                        child: WebViewWidget(controller: _ggbController!),
                      ),
                    if (_ggbLoading)
                      const Center(child: CircularProgressIndicator()),
                    // GeoGebra ready 标记
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black38,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _ggbReady ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _ggbReady ? '就绪' : '等待...',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _undoLast,
                            icon: const Icon(Icons.undo, color: Colors.white),
                            tooltip: '撤销',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black38,
                            ),
                          ),
                          IconButton(
                            onPressed: _clearCanvas,
                            icon: Icon(
                              _isLoading ? Icons.stop : Icons.delete_outline,
                              color: Colors.white,
                            ),
                            tooltip: _isLoading ? '中止任务' : '清空画布',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  _isLoading ? Colors.red.withValues(alpha: 0.7) : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 可拖拽分隔栏
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (availableHeight <= 0) return;
                  setState(() {
                    _chatHeightFraction -= details.delta.dy / availableHeight;
                    _chatHeightFraction = _chatHeightFraction.clamp(0.15, 0.85);
                  });
                },
                child: Container(
                  height: dividerHeight,
                  color: cs.surface,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // 聊天区域
              SizedBox(
                height: chatHeight,
                child: Column(
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Icon(Icons.draw, size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            '对话绘图',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 消息列表
                    Expanded(
                      child: _bubbles.isEmpty
                          ? _buildEmptyState(cs)
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.all(12),
                              itemCount: _bubbles.length,
                              itemBuilder: (_, i) => _buildBubble(_bubbles[i], cs),
                            ),
                    ),

                    // 输入栏
                    _buildInputBar(cs),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final suggestions = [
      '画一个以A为圆心，半径为3的圆',
      '画一个三角形ABC',
      '画椭圆 x²/4 + y²/9 = 1',
      '画出 y = x² 和它的切线',
      '画一个正六边形',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 40,
              color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text('描述你想绘制的图形',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: suggestions
                .map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      onPressed: _ggbReady
                          ? () {
                              _inputCtrl.text = s;
                              _sendMessage();
                            }
                          : null,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatBubble bubble, ColorScheme cs) {
    final isUser = bubble.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 14),
              ),
            ),
            child: isUser
                ? Text(bubble.content,
                    style: TextStyle(fontSize: 14, color: cs.onPrimary))
                : bubble.isStreaming && bubble.content.isEmpty
                    ? SizedBox(
                        width: 40,
                        child: LinearProgressIndicator(
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary,
                        ),
                      )
                    : _buildAssistantContent(bubble.content),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantContent(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('🔧')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'monospace')),
        ));
      } else if (line.startsWith('> ⚠️')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ));
      } else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line, style: const TextStyle(fontSize: 13, height: 1.5)),
        ));
      }
    }

    if (widgets.isEmpty) return const Text('');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 3,
                enabled: !_isLoading && _ggbReady,
                decoration: InputDecoration(
                  hintText: _ggbReady ? '描述你要画的图形...' : '等待 GeoGebra 就绪...',
                  hintStyle: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed:
                  _isLoading || !_ggbReady ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18),
              style: IconButton.styleFrom(backgroundColor: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble {
  final String role;
  final String content;
  final bool isStreaming;
  ChatBubble({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });
}
