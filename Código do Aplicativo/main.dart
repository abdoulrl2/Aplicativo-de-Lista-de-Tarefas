import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _todos = FirebaseFirestore.instance.collection('todos');
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: IOSInitializationSettings(),
    );
    _notifications.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_channel_id',
        'Todo Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: IOSNotificationDetails(),
    );
    await _notifications.show(0, title, body, notificationDetails);
  }

  void _addTodo() async {
    final String text = _controller.text;
    if (text.isNotEmpty) {
      await _todos.add({'text': text, 'completed': false});
      _controller.clear();
      _showNotification('New Task', text);
    }
  }

  void _updateTodo(DocumentSnapshot doc) async {
    final bool completed = doc['completed'];
    await _todos.doc(doc.id).update({'completed': !completed});
  }

  void _deleteTodo(DocumentSnapshot doc) async {
    await _todos.doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter a task',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _todos.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final todos = snapshot.data!.docs;
                return ListView(
                  children: todos.map((doc) {
                    final text = doc['text'];
                    final completed = doc['completed'];
                    return ListTile(
                      title: Text(
                        text,
                        style: TextStyle(
                          decoration: completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () => _updateTodo(doc),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteTodo(doc),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
