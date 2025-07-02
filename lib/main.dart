import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const PetanMemoApp());
}

class PetanMemoApp extends StatelessWidget {
  const PetanMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ぺたんメモ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50], // 淡い背景色
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue[100],
          foregroundColor: Colors.black87,
        ),
      ),
      home: const MemoListScreen(),
    );
  }
}

class Memo {
  String id;
  String content;

  Memo({required this.id, required this.content});

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
      };

  factory Memo.fromJson(Map<String, dynamic> json) => Memo(
        id: json['id'],
        content: json['content'],
      );
}

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  List<Memo> _memos = [];
  final List<String> _petanSayings = [
    "にゃ～ん",
    "今日も一日お疲れ様！",
    "ゆっくり休んでね",
    "メモ、ちゃんと書けてる？",
    "ぺたん、ぺたん",
    "何かいいことあった？",
    "頑張りすぎないでね",
    "いつでもそばにいるよ",
    "ふにゃ～",
    "おやつはまだかにゃ？",
  ];

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? memosString = prefs.getString('memos');
    if (memosString != null) {
      final List<dynamic> memoJsonList = json.decode(memosString);
      setState(() {
        _memos = memoJsonList.map((json) => Memo.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String memosString =
        json.encode(_memos.map((memo) => memo.toJson()).toList());
    await prefs.setString('memos', memosString);
  }

  void _addMemo() async {
    final newMemo = Memo(id: DateTime.now().toString(), content: '');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoEditScreen(memo: newMemo),
      ),
    );
    if (result != null && result.content.isNotEmpty) {
      setState(() {
        _memos.add(result);
      });
      _saveMemos();
    }
  }

  void _editMemo(Memo memo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoEditScreen(memo: memo),
      ),
    );
    if (result != null) {
      setState(() {
        final index = _memos.indexWhere((m) => m.id == result.id);
        if (index != -1) {
          _memos[index] = result;
        }
      });
      _saveMemos();
    }
  }

  void _deleteMemo(String id) {
    setState(() {
      _memos.removeWhere((memo) => memo.id == id);
    });
    _saveMemos();
  }

  void _showPetanSaying() {
    final random = Random();
    final saying = _petanSayings[random.nextInt(_petanSayings.length)];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saying),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ぺたんメモ'),
      ),
      body: Stack(
        children: [
          _memos.isEmpty
              ? const Center(
                  child: const Text(
                    '''メモがありません。
右下のボタンから追加しましょう！''',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _memos.length,
                  itemBuilder: (context, index) {
                    final memo = _memos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        title: Text(
                          memo.content.split('\n')[0], // 最初の行をタイトルとして表示
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          memo.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _editMemo(memo),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteMemo(memo.id),
                        ),
                      ),
                    );
                  },
                ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _addMemo,
              backgroundColor: Colors.lightBlue[300],
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 80.0, // FABの上に配置
            right: 16.0,
            child: GestureDetector(
              onTap: _showPetanSaying,
              child: Image.asset(
                'assets/images/petan.png',
                width: 600,
                height: 600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MemoEditScreen extends StatefulWidget {
  final Memo memo;

  const MemoEditScreen({super.key, required this.memo});

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.memo.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo.content.isEmpty ? '新規メモ' : 'メモを編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(
                  context, Memo(id: widget.memo.id, content: _controller.text));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null, // 複数行入力可能
          expands: true, // 画面いっぱいに広がる
          decoration: const InputDecoration(
            hintText: 'メモを入力してください',
            border: InputBorder.none, // ボーダーなし
          ),
          autofocus: true,
        ),
      ),
    );
  }
}