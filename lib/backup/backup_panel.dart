import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/task.dart';
import 'backup_data.dart';
import 'drive_backup.dart';

class BackupPanel extends StatefulWidget {
  final List<TaskItem> tasks;
  final Future<void> Function(List<TaskItem>) onRestore;
  const BackupPanel({super.key, required this.tasks, required this.onRestore});
  @override
  State<BackupPanel> createState() => _BackupPanelState();
}

class _BackupPanelState extends State<BackupPanel> {
  final _drive = DriveBackup();
  bool _busy = false;
  bool _automatic = false;
  Timer? _timer;
  String _status = 'No cloud backup made in this session.';
  BackupData _snapshot() =>
      BackupData(createdAt: DateTime.now(), tasks: List.of(widget.tasks));

  @override
  void didUpdateWidget(covariant BackupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_automatic &&
        jsonEncode(oldWidget.tasks.map((t) => t.toJson()).toList()) !=
            jsonEncode(widget.tasks.map((t) => t.toJson()).toList())) {
      _queueBackup();
    }
  }

  void _queueBackup() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 8), () {
      if (!mounted || !_automatic) return;
      if (_busy) {
        _queueBackup();
        return;
      }
      _run(_upload);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Action failed: $error');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_status)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final data = _snapshot();
    await _drive.upload(data);
    if (mounted)
      setState(
        () => _status =
            'Backed up ${data.tasks.length} tasks at ${TimeOfDay.now().format(context)}.',
      );
  }

  Future<void> _export() async {
    final data = _snapshot();
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ShanReminder backup',
      fileName: 'ShanReminder-${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(data.encode())),
    );
    if (mounted && result != null)
      setState(
        () => _status = 'Backup file saved. Keep a copy outside this phone.',
      );
  }

  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'ShanReminder task backup',
        text: 'Keep this ShanReminder backup. To recover tasks, download this JSON file and use Settings → Restore backup file.',
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(_snapshot().encode())),
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: [
          'ShanReminder-${DateTime.now().millisecondsSinceEpoch}.json',
        ],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (mounted)
      setState(
        () => _status =
            'Share sheet opened. Complete sending in Gmail or saving in Drive.',
      );
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > 10 * 1024 * 1024 || file.bytes == null) {
      throw const FormatException(
        'Choose a readable ShanReminder JSON backup under 10 MB.',
      );
    }
    await _confirmRestore(BackupData.decode(utf8.decode(file.bytes!)));
  }

  Future<void> _confirmRestore(BackupData data) async {
    if (!mounted) return;
    final count = data.tasks
        .where((t) => !widget.tasks.any((current) => current.id == t.id))
        .length;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore missing tasks?'),
        content: Text(
          'Backup from ${data.createdAt.toLocal()}.\n\nAdd $count missing tasks. '
          'Existing tasks and their current edits stay unchanged. Calendar entries use the same restored tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await widget.onRestore(data.tasks);
    if (mounted)
      setState(
        () => _status = 'Restored $count missing tasks. Calendar updated.',
      );
  }

  Future<void> _restoreCloud() async {
    final snapshots = await _drive.list();
    if (!mounted) return;
    if (snapshots.isEmpty) {
      setState(() => _status = 'No backups found for this Google account.');
      return;
    }
    final selected = await showDialog<DriveSnapshot>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a backup'),
        content: SizedBox(
          width: double.maxFinite,
          height: 340,
          child: ListView.builder(
            itemCount: snapshots.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(snapshots[i].name),
              onTap: () => Navigator.pop(context, snapshots[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected != null)
      await _confirmRestore(await _drive.download(selected));
  }

  @override
  Widget build(BuildContext context) {
    final connected = _drive.email != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup & Restore',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Keep your tasks and calendar safe. Export a file, send it to your Gmail, or use Google Drive backup.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Google Drive',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  connected
                      ? _drive.email!
                      : _drive.configured
                      ? 'Connect using your Google account.'
                      : 'Google sign-in is not enabled in this build. File and Gmail backup are available below.',
                ),
                if (_drive.configured) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            _timer?.cancel();
                            if (connected) {
                              await _drive.disconnect();
                              _automatic = false;
                            } else {
                              await _drive.connect();
                            }
                            if (mounted) setState(() {});
                          }),
                    child: Text(
                      connected ? 'Disconnect' : 'Connect Google account',
                    ),
                  ),
                ],
                if (connected) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busy ? null : () => _run(_upload),
                        child: const Text('Back up now'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _run(_restoreCloud),
                        child: const Text('Restore from Drive'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Back up changes automatically'),
                    subtitle: const Text(
                      'While the app is open and this account is connected. Reconnect after restarting the app. Older snapshots are kept.',
                    ),
                    value: _automatic,
                    onChanged: _busy
                        ? null
                        : (value) {
                            setState(() => _automatic = value);
                            if (value) {
                              _queueBackup();
                            } else {
                              _timer?.cancel();
                            }
                          },
                  ),
                ],
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: const Text('Export backup file'),
          subtitle: const Text(
            'Choose phone storage or an available Drive location',
          ),
          onTap: _busy ? null : () => _run(_export),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Send backup to Gmail'),
          subtitle: const Text(
            'Choose Gmail in the share sheet and send it to yourself',
          ),
          onTap: _busy ? null : () => _run(_share),
        ),
        ListTile(
          leading: const Icon(Icons.restore_page_outlined),
          title: const Text('Restore backup file'),
          subtitle: const Text(
            'Recover missing tasks from a downloaded backup',
          ),
          onTap: _busy ? null : () => _run(_import),
        ),
        if (_busy) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _status,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
