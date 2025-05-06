import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';

class TaskManagerScreen extends StatefulWidget {
  final String userId;

  const TaskManagerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  String _priority = 'Low';

  String _sortField = 'dueDate';
  bool _isAscending = true;
  String? _editingTaskId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDate == null) return;

    final taskData = {
      'title': title,
      'dueDate': Timestamp.fromDate(_selectedDate!),
      'priority': _priority,
      'isCompleted': false,
    };

    final tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasks');

    if (_editingTaskId == null) {
      await tasksRef.add(taskData);
    } else {
      await tasksRef.doc(_editingTaskId).update(taskData);
      _editingTaskId = null;
    }

    _titleController.clear();
    _selectedDate = null;
    _priority = 'Low';
    setState(() {});
  }

  void _populateTaskForEdit(DocumentSnapshot taskDoc) {
    setState(() {
      _editingTaskId = taskDoc.id;
      _titleController.text = taskDoc['title'];
      _selectedDate = (taskDoc['dueDate'] as Timestamp).toDate();
      _priority = taskDoc['priority'];
    });
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    }
  }

  Future<void> _toggleCompletion(DocumentSnapshot taskDoc) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasks')
        .doc(taskDoc.id)
        .update({'isCompleted': !taskDoc['isCompleted']});
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasks');

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'priority' || value == 'dueDate') {
                  _sortField = value;
                } else if (value == 'asc') {
                  _isAscending = true;
                } else if (value == 'desc') {
                  _isAscending = false;
                }
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
              PopupMenuItem(value: 'dueDate', child: Text('Sort by Due Date')),
              PopupMenuItem(value: 'asc', child: Text('Ascending')),
              PopupMenuItem(value: 'desc', child: Text('Descending')),
            ],
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Add / Edit Task Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Task Title'),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_selectedDate == null
                          ? 'Pick Due Date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Text('Select Date'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _priority,
                    items: ['Low', 'Medium', 'High']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addOrUpdateTask,
                    child: Text(_editingTaskId == null ? 'Add Task' : 'Update Task'),
                  ),
                ]),
              ),
            ),

            SizedBox(height: 16),

            // Task List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  List<DocumentSnapshot> allTasks = snapshot.data!.docs;

                  // Sorting
                  if (_sortField == 'priority') {
                    allTasks.sort((a, b) {
                      int aVal = _getPriorityValue(a['priority']);
                      int bVal = _getPriorityValue(b['priority']);
                      return _isAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
                    });
                  } else {
                    allTasks.sort((a, b) {
                      DateTime aDate = (a['dueDate'] as Timestamp).toDate();
                      DateTime bDate = (b['dueDate'] as Timestamp).toDate();
                      return _isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
                    });
                  }

                  List<DocumentSnapshot> completedTasks =
                      allTasks.where((task) => task['isCompleted']).toList();
                  List<DocumentSnapshot> incompleteTasks =
                      allTasks.where((task) => !task['isCompleted']).toList();

                  return ListView(
                    children: [
                      Text('Incomplete Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...incompleteTasks.map((task) => _buildTaskTile(task)).toList(),
                      Divider(),
                      Text('Completed Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...completedTasks.map((task) => _buildTaskTile(task)).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(DocumentSnapshot task) {
    final dueDate = (task['dueDate'] as Timestamp).toDate();
    final isCompleted = task['isCompleted'] as bool;
    final titleStyle = isCompleted
        ? TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
        : TextStyle();

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => _toggleCompletion(task),
        ),
        title: Text(task['title'], style: titleStyle),
        subtitle: Text('Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getPriorityColor(task['priority']),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _populateTaskForEdit(task),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteTask(task.id),
            ),
          ],
        ),
      ),
    );
  }
}