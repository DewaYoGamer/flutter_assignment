import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import '../notifiers.dart';

class Task {
  String id;
  String title;
  bool isCompleted;
  DateTime dateTime;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    DateTime? dateTime,
  }) : dateTime = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
    );
  }
}

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<Landing> {
  List<Task> tasks = [];
  final TextEditingController _textEditingController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = true;
    });

    final tasksJson = prefs.getStringList('tasks') ?? [];
    setState(() {
      tasks = tasksJson
          .map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
          .toList();
      isLoading = false;
    });
  }

  _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        dateTime: DateTime.now(),
      );
      tasks.add(newTask);
      _textEditingController.clear();
    });
    _saveTasks();
  }

  _toggleTask(String id) {
    setState(() {
      final taskIndex = tasks.indexWhere((task) => task.id == id);
      if (taskIndex != -1) {
        tasks[taskIndex].isCompleted = !tasks[taskIndex].isCompleted;
      }
    });
    _saveTasks();
  }

  _deleteCompletedTasks() {
    setState(() {
      tasks.removeWhere((task) => task.isCompleted);
    });
    _saveTasks();
  }

  _deleteTask(String id) {
    setState(() {
      tasks.removeWhere((task) => task.id == id);
    });
    _saveTasks();
  }

  void _showAddTaskDialog(BuildContext context) {
    _textEditingController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Tugas Baru',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: _textEditingController,
              decoration: const InputDecoration(
                hintText: 'Masukkan tugas baru',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addTask(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_textEditingController.text.trim().isNotEmpty) {
                  _addTask(_textEditingController.text);
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              selectedThemeNotifier.value = !selectedThemeNotifier.value;
            },
            tooltip: 'Ganti Tema',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada tugas. Tambahkan sekarang!',
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        )
                      : ListView(
                          children: [
                            Padding(padding: const EdgeInsets.all(16.0)),
                            if (incompleteTasks.isNotEmpty) ...[
                              Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0)),
                              ...incompleteTasks.map((task) => _buildTaskItem(task, context)),
                              Padding(padding: const EdgeInsets.all(16.0)),
                            ],

                            // Completed tasks section
                            if (completedTasks.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'Selesai',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_sweep,
                                          color: Colors.red),
                                      label: const Text('Hapus Semua',
                                          style: TextStyle(color: Colors.red)),
                                      onPressed: _deleteCompletedTasks,
                                    ),
                                  ],
                                ),
                              ),
                              ...completedTasks.map((task) => _buildTaskItem(task, context)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Tambah Tugas',
        shape: CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper method to build task item
  Widget _buildTaskItem(Task task, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTask(task.id),
          activeColor: Colors.blue,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.isCompleted ? Colors.green : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(task.dateTime)}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteTask(task.id),
        ),
      ),
    );
  }
}
