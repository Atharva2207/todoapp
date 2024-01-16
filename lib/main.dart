import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Task {
  String title;
  bool isCompleted;
  TimeOfDay time;
  int priority; // Priority: 0 (low), 1 (medium), 2 (high)

  Task({required this.title, required this.time, this.isCompleted = false, this.priority = 0});
}

class TaskList with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void deleteTask(int index) {
    _tasks.removeAt(index);
    notifyListeners();
  }

  void toggleTask(int index) {
    _tasks[index].isCompleted = !_tasks[index].isCompleted;
    notifyListeners();
  }

  void updateTaskPriority(int index, int priority) {
    _tasks[index].priority = priority;
    notifyListeners();
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.teal,
    hintColor: Colors.tealAccent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

class MyApp extends StatelessWidget {
  @override
  
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskList()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ToDo App',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: ToDoScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class ToDoScreen extends StatelessWidget {
  final TextEditingController _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo App'),
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Colors.deepPurple,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: 'Enter task...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<TaskList>(
                builder: (context, taskList, child) {
                  return ListView.builder(
                    itemCount: taskList.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskList.tasks[index];
                      return TaskListItem(task: task, onDelete: () => taskList.deleteTask(index));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          TimeOfDay? selectedTime = await _selectTime(context);
          if (selectedTime != null) {
            final newTask = Task(
              title: _taskController.text,
              time: selectedTime,
            );
            Provider.of<TaskList>(context, listen: false).addTask(newTask);
            _taskController.clear();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }
}

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;

  const TaskListItem({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListTile(
          title: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) {
                 Provider.of<TaskList>(context, listen: false).toggleTask(Provider.of<TaskList>(context, listen: false).tasks.indexOf(task));

                },
              ),
              Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Spacer(),
              _buildPriorityIcon(),
            ],
          ),
          subtitle: Text(
            "${_formatTime(task.time)}",
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIcon() {
    Color priorityColor = Colors.green; // Default is low priority
    if (task.priority == 1) {
      priorityColor = Colors.yellow;
    } else if (task.priority == 2) {
      priorityColor = Colors.red;
    }

    return Icon(
      Icons.star,
      color: priorityColor,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
