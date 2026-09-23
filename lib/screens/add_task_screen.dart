import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskItem? existingTask;
  const AddTaskScreen({super.key, this.existingTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _date;
  late TimeOfDay _time;
  late int _reminder;
  late String _repeat;
  late String _priority;
  late String _category;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _date = task?.dueAt ?? DateTime.now();
    _time = TimeOfDay.fromDateTime(task?.dueAt ?? DateTime.now().add(const Duration(minutes: 5)));
    _reminder = task?.reminderMinutesBefore ?? 0;
    _repeat = task?.repeat ?? 'None';
    _priority = task?.priority ?? 'Medium';
    _category = task?.category ?? 'Work';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _date,
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);
    if (result != null) setState(() => _time = result);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final dueAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final reminderAt = dueAt.subtract(Duration(minutes: _reminder));

    if (reminderAt.isBefore(DateTime.now()) && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Choose a task/reminder time in the future.')));
      return;
    }

    final old = widget.existingTask;
    final task = TaskItem(
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      dueAt: dueAt,
      reminderMinutesBefore: _reminder,
      repeat: _repeat,
      priority: _priority,
      category: _category,
      completed: old?.completed ?? false,
    );
    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Task' : 'Add Task';
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        TextButton(onPressed: _save,
          child: const Text('Save', style: TextStyle(color: Colors.white))),
      ]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Task / Event Title *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text('${_date.day}/${_date.month}/${_date.year}'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(_time.format(context)))),
            ]),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _reminder,
              decoration: const InputDecoration(labelText: 'Reminder'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('At task time')),
                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                DropdownMenuItem(value: 60, child: Text('1 hour before')),
              ],
              onChanged: (v) => setState(() => _reminder = v ?? 0),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _repeat,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: ['None', 'Daily', 'Weekly', 'Monthly']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _repeat = v ?? 'None'),
            ),
            const SizedBox(height: 18),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'High', label: Text('High'), icon: Icon(Icons.flag)),
                ButtonSegment(value: 'Medium', label: Text('Medium'), icon: Icon(Icons.star)),
                ButtonSegment(value: 'Low', label: Text('Low'), icon: Icon(Icons.circle)),
              ],
              selected: {_priority},
              onSelectionChanged: (v) => setState(() => _priority = v.first),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Work', 'Personal', 'Astrology', 'Family', 'Health', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Work'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.notifications_active),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_isEditing ? 'Save Changes' : 'Save Task & Reminder'))),
          ],
        ),
      ),
    );
  }
}
