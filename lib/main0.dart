import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const KigerApp());

class KigerApp extends StatelessWidget {
  const KigerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiger沟通助手',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansSC',
      ),
      home: const CommunicationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  _CommunicationScreenState createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  String displayText = '';
  final TextEditingController _textController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  
  // 常用短语列表
  List<String> quickPhrases = [
    "听不清楚呢，可以再说一遍吗？",
    "可以一起合影吗？",
    "请稍等一下哦~",
    "谢谢你的支持！",
    "我是初音未来，请多指教！",
    "需要签名吗？",
    "对不起，我现在不太方便",
    "请关注我的社交账号",
    "这个姿势可以吗？",
    "需要调整位置吗？"
  ];

  // 历史消息记录
  List<String> messageHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _initTts();
  }

  // 初始化TTS
  void _initTts() async {
    await flutterTts.setLanguage("zh-CN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setStartHandler(() {
      setState(() => isSpeaking = true);
    });
    
    flutterTts.setCompletionHandler(() {
      setState(() => isSpeaking = false);
    });
    
    flutterTts.setErrorHandler((msg) {
      setState(() => isSpeaking = false);
    });
  }

  // 加载保存的数据
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedHistory = prefs.getStringList('message_history');
    if (savedHistory != null) {
      setState(() => messageHistory = savedHistory);
    }
    
    final savedPhrases = prefs.getStringList('custom_phrases');
    if (savedPhrases != null) {
      setState(() => quickPhrases = savedPhrases);
    }
  }

  // 保存数据
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('message_history', messageHistory);
    prefs.setStringList('custom_phrases', quickPhrases);
  }

  // 发送自定义文本
  void _sendCustomText() {
    if (_textController.text.isEmpty) return;
    
    setState(() {
      final newText = _textController.text;
      displayText = newText;
      
      // 添加到历史记录
      messageHistory.insert(0, newText);
      _saveData();
      
      _textController.clear();
    });
  }

  // 发送快速短语
  void _sendQuickPhrase(String phrase) {
    setState(() {
      displayText = phrase;
      
      // 添加到历史记录
      messageHistory.insert(0, phrase);
      _saveData();
    });
  }
  
  // 播放语音
  void _speakText(String text) async {
    if (text.isEmpty) return;
    
    if (isSpeaking) {
      await flutterTts.stop();
    }
    
    await flutterTts.speak(text);
  }
  
  // 添加新短语
  void _addNewPhrase() {
    showDialog(
      context: context,
      builder: (context) => AddPhraseDialog(
        onAdd: (newPhrase) {
          if (newPhrase.isNotEmpty) {
            setState(() {
              quickPhrases.insert(0, newPhrase);
              _saveData();
            });
          }
        },
      ),
    );
  }
  
  // 管理短语
  void _managePhrases() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhraseManagementScreen(
          phrases: quickPhrases,
          onUpdate: (updatedPhrases) {
            setState(() {
              quickPhrases = updatedPhrases;
              _saveData();
            });
          },
        ),
      ),
    );
  }
  
  // 查看历史记录
  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          history: messageHistory,
          onSpeak: _speakText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Kiger沟通助手'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A5ACD),
        elevation: 0,
        actions: [
          // 历史记录按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewHistory,
            tooltip: '查看历史记录',
          ),
          // 短语管理按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _managePhrases,
            tooltip: '管理常用短语',
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部提示区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFB6C1).withOpacity(0.3),
            child: const Text(
              "不方便说话哦，请等待我打字",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 大字显示区域
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayText.isEmpty ? "请选择下方常用语或输入文字" : displayText,
                        style: TextStyle(
                          fontSize: displayText.isEmpty ? 24 : 40,
                          fontWeight: FontWeight.bold,
                          color: displayText.isEmpty ? Colors.grey : Colors.black,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (displayText.isNotEmpty)
                        ElevatedButton.icon(
                          icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                          label: Text(isSpeaking ? "停止播放" : "语音播放"),
                          onPressed: () => isSpeaking 
                              ? flutterTts.stop() 
                              : _speakText(displayText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 常用短语区域
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    children: [
                      const Text(
                        "常用短语:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _addNewPhrase,
                        tooltip: '添加新短语',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 3,
                    ),
                    itemCount: quickPhrases.length,
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        onPressed: () => _sendQuickPhrase(quickPhrases[index]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6E6FA),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          quickPhrases[index],
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 输入区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "请输入要说的话...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    ),
                    onSubmitted: (value) => _sendCustomText(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF6A5ACD),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendCustomText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 添加新短语对话框
class AddPhraseDialog extends StatefulWidget {
  final Function(String) onAdd;
  
  const AddPhraseDialog({super.key, required this.onAdd});
  
  @override
  _AddPhraseDialogState createState() => _AddPhraseDialogState();
}

class _AddPhraseDialogState extends State<AddPhraseDialog> {
  final TextEditingController _phraseController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新短语'),
      content: TextField(
        controller: _phraseController,
        decoration: const InputDecoration(
          hintText: '输入新短语...',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_phraseController.text);
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

// 短语管理界面
class PhraseManagementScreen extends StatefulWidget {
  final List<String> phrases;
  final Function(List<String>) onUpdate;
  
  const PhraseManagementScreen({
    super.key,
    required this.phrases,
    required this.onUpdate,
  });
  
  @override
  _PhraseManagementScreenState createState() => _PhraseManagementScreenState();
}

class _PhraseManagementScreenState extends State<PhraseManagementScreen> {
  late List<String> editablePhrases;
  
  @override
  void initState() {
    super.initState();
    editablePhrases = List.from(widget.phrases);
  }
  
  void _addNewPhrase() {
    showDialog(
      context: context,
      builder: (context) => AddPhraseDialog(
        onAdd: (newPhrase) {
          setState(() {
            editablePhrases.insert(0, newPhrase);
          });
        },
      ),
    );
  }
  
  void _saveChanges() {
    widget.onUpdate(editablePhrases);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理常用短语'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: '保存更改',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加新短语'),
              onPressed: _addNewPhrase,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: editablePhrases.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(editablePhrases[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editPhrase(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deletePhrase(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _editPhrase(int index) {
    final controller = TextEditingController(text: editablePhrases[index]);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑短语'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                editablePhrases[index] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _deletePhrase(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除短语'),
        content: Text('确定要删除"${editablePhrases[index]}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                editablePhrases.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// 历史记录界面
class HistoryScreen extends StatelessWidget {
  final List<String> history;
  final Function(String) onSpeak;
  
  const HistoryScreen({super.key, required this.history, required this.onSpeak});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息历史记录'),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                '暂无历史记录',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(history[index]),
                    subtitle: Text(
                      '${history.length - index}条前',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => onSpeak(history[index]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
