import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../models/trip.dart';
import '../utils/clipboard_utils.dart';
import '../theme/build_trip_form_theme.dart';
import '../widgets/build_trip_app_bar.dart';
import '../widgets/build_trip_ui_cards.dart';
import '../widgets/itinerary_widgets.dart';

class TravelSegmentDetailsScreen extends StatefulWidget {
  const TravelSegmentDetailsScreen({
    super.key,
    required this.segment,
  });

  final TravelSegment segment;

  static final Object deleteMarker = Object();

  @override
  State<TravelSegmentDetailsScreen> createState() =>
      _TravelSegmentDetailsScreenState();
}

class _TravelSegmentDetailsScreenState
    extends State<TravelSegmentDetailsScreen> {
  bool _editing = false;
  TravelSegment? _editBaseline;
  late TransportMode _mode;
  late final TextEditingController _noteController;
  late final TextEditingController _descriptionController;
  late List<PlaceAttachment> _attachments;

  @override
  void initState() {
    super.initState();
    _mode = widget.segment.mode;
    _noteController = TextEditingController(text: widget.segment.note ?? '');
    _descriptionController =
        TextEditingController(text: widget.segment.description ?? '');
    _attachments = [...widget.segment.attachments];
    _noteController.addListener(_onAnyFieldChanged);
    _descriptionController.addListener(_onAnyFieldChanged);
  }

  void _onAnyFieldChanged() {
    if (_editing) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_onAnyFieldChanged);
    _descriptionController.removeListener(_onAnyFieldChanged);
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formInputs = BuildTripFormTheme.outlineFormInputs(scheme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _popWithAutoSave();
        }
      },
      child: Scaffold(
        appBar: BuildTripAppBar(
          titleText: 'Перемещение',
          onBackPressed: _popWithAutoSave,
          actions: [
            IconButton(
              tooltip: 'Удалить',
              onPressed: () => Navigator.of(context)
                  .pop(TravelSegmentDetailsScreen.deleteMarker),
              style:
                  BuildTripAppBar.toolbarIconStyle(scheme, destructive: true),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 6),
            if (_editing) ...[
              if (_editDirty)
                IconButton(
                  tooltip: 'Отменить изменения',
                  onPressed: _undoEdit,
                  style: BuildTripAppBar.toolbarIconStyle(scheme),
                  icon: const Icon(Icons.undo_rounded),
                ),
              if (_editDirty) const SizedBox(width: 2),
              IconButton(
                tooltip: 'Готово',
                onPressed: _popWithAutoSave,
                style: BuildTripAppBar.toolbarIconStyle(scheme),
                icon: const Icon(Icons.check_rounded),
              ),
            ] else
              IconButton(
                tooltip: 'Редактировать',
                onPressed: _startEditing,
                style: BuildTripAppBar.toolbarIconStyle(scheme),
                icon: const Icon(Icons.edit_outlined),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: _editing
            ? Theme(
                data: Theme.of(context)
                    .copyWith(inputDecorationTheme: formInputs),
                child: LayoutBuilder(
                  builder: (context, lc) {
                    final innerW = lc.maxWidth - 32;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        BuildTripSectionCard(
                          icon: Icons.route_rounded,
                          title: 'Как едем',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme:
                                      BuildTripFormTheme.dropdownFilledTheme(
                                    scheme,
                                  ),
                                ),
                                child: DropdownMenu<TransportMode>(
                                  key: ValueKey(_mode),
                                  width: innerW,
                                  initialSelection: _mode,
                                  label: const Text('Тип транспорта'),
                                  leadingIcon: Icon(
                                    TransportVisual.of(context, _mode).icon,
                                    color:
                                        TransportVisual.of(context, _mode).accent,
                                  ),
                                  menuStyle: MenuStyle(
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  onSelected: (TransportMode? v) {
                                    if (v != null) {
                                      setState(() => _mode = v);
                                    }
                                  },
                                  dropdownMenuEntries: [
                                    for (final m in TransportVisual.pickerOrder)
                                      DropdownMenuEntry<TransportMode>(
                                        value: m,
                                        label: TransportVisual.label(m),
                                        leadingIcon: Icon(
                                          TransportVisual.of(context, m).icon,
                                          size: 22,
                                          color: TransportVisual.of(context, m)
                                              .accent,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Кратко в маршруте',
                                  hintText: 'Например, RER B ~25 мин',
                                ),
                                textCapitalization: TextCapitalization.sentences,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _descriptionController,
                                minLines: 1,
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  labelText: 'Подробное описание',
                                  hintText: 'Необязательно',
                                  alignLabelWithHint: true,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ],
                          ),
                        ),
                        BuildTripSectionCard(
                          marginBottom: 0,
                          icon: Icons.attach_file_rounded,
                          title: 'Файлы',
                          titleTrailing: IconButton(
                            tooltip: 'Добавить файлы',
                            style: BuildTripAppBar.toolbarIconStyle(scheme),
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.upload_file_rounded),
                          ),
                          child: _attachments.isEmpty
                              ? const BuildTripEmptyHint(
                                  icon: Icons.folder_open_rounded,
                                  message:
                                      'Пока нет файлов — нажмите иконку загрузки справа',
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: _attachments
                                      .map(
                                        (a) => _buildAttachmentRow(
                                          a,
                                          editing: true,
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: _buildReadOnlyChildren(scheme),
              ),
      ),
    );
  }

  bool get _editDirty {
    if (!_editing || _editBaseline == null) {
      return false;
    }
    return !_segmentsEqual(_composeSegment(), _editBaseline!);
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _editBaseline = _snapshotSegment(_composeSegment());
    });
  }

  void _undoEdit() {
    final b = _editBaseline;
    if (b == null) {
      return;
    }
    setState(() {
      _mode = b.mode;
      _noteController.text = b.note ?? '';
      _descriptionController.text = b.description ?? '';
      _attachments
        ..clear()
        ..addAll(
          b.attachments.map(
            (a) => PlaceAttachment(path: a.path, displayLabel: a.displayLabel),
          ),
        );
    });
  }

  TravelSegment _snapshotSegment(TravelSegment s) {
    return TravelSegment(
      id: s.id,
      mode: s.mode,
      note: s.note,
      description: s.description,
      attachments: s.attachments
          .map(
            (a) => PlaceAttachment(path: a.path, displayLabel: a.displayLabel),
          )
          .toList(),
    );
  }

  TravelSegment _composeSegment() {
    final note = _noteController.text.trim();
    final desc = _descriptionController.text.trim();
    return TravelSegment(
      id: widget.segment.id,
      mode: _mode,
      note: note.isEmpty ? null : note,
      description: desc.isEmpty ? null : desc,
      attachments: List<PlaceAttachment>.from(_attachments),
    );
  }

  bool _segmentsEqual(TravelSegment a, TravelSegment b) {
    if (a.mode != b.mode ||
        (a.note ?? '') != (b.note ?? '') ||
        (a.description ?? '') != (b.description ?? '')) {
      return false;
    }
    if (a.attachments.length != b.attachments.length) {
      return false;
    }
    for (var i = 0; i < a.attachments.length; i++) {
      if (a.attachments[i].path != b.attachments[i].path ||
          a.attachments[i].displayLabel != b.attachments[i].displayLabel) {
        return false;
      }
    }
    return true;
  }

  void _popWithAutoSave() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(_composeSegment());
  }

  List<Widget> _buildReadOnlyChildren(ColorScheme scheme) {
    final transport = TransportVisual.of(context, _mode);
    final note = _noteController.text.trim();
    final desc = _descriptionController.text.trim();
    final t = Theme.of(context).textTheme;
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: transport.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: transport.accent.withValues(alpha: 0.38),
                  width: 1.2,
                ),
              ),
              child: Icon(transport.icon, color: transport.accent, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => copyToClipboard(
                        context,
                        TransportVisual.label(_mode),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: transport.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          TransportVisual.label(_mode),
                          style: t.labelMedium?.copyWith(
                            color: transport.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: note.isEmpty
                          ? null
                          : () => copyToClipboard(context, note),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          note.isEmpty
                              ? 'Краткая строка в маршруте не задана'
                              : note,
                          style: (note.isEmpty ? t.bodyMedium : t.titleMedium)
                              ?.copyWith(
                            fontWeight: note.isEmpty
                                ? FontWeight.w400
                                : FontWeight.w700,
                            height: 1.35,
                            color: note.isEmpty
                                ? scheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      BuildTripSectionCard(
        icon: Icons.notes_rounded,
        title: 'Описание',
        child: desc.isEmpty
            ? const BuildTripEmptyHint(
                icon: Icons.article_outlined,
                message: 'Подробного описания пока нет',
              )
            : Text(
                desc,
                style: t.bodyLarge?.copyWith(height: 1.45),
              ),
      ),
      BuildTripSectionCard(
        marginBottom: 0,
        icon: Icons.attach_file_rounded,
        title: 'Файлы',
        child: _attachments.isEmpty
            ? const BuildTripEmptyHint(
                icon: Icons.folder_open_rounded,
                message: 'Нет прикреплённых файлов',
              )
            : Column(
                children: _attachments
                    .map((a) => _buildAttachmentRow(a, editing: false))
                    .toList(),
              ),
      ),
    ];
  }

  Widget _buildAttachmentRow(PlaceAttachment a, {required bool editing}) {
    final scheme = Theme.of(context).colorScheme;
    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Icon(
                Icons.insert_drive_file_outlined,
                size: 22,
                color: scheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              a.label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (editing) ...[
            IconButton(
              tooltip: 'Имя',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              onPressed: () => _renameAttachment(a),
              icon: const Icon(Icons.label_outline, size: 22),
            ),
            IconButton(
              tooltip: 'Удалить',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              onPressed: () {
                final i = _attachments.indexOf(a);
                if (i >= 0) {
                  setState(() => _attachments.removeAt(i));
                }
              },
              icon: const Icon(Icons.close, size: 22),
            ),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: editing
            ? inner
            : InkWell(
                onTap: () => _openLocalFile(a.path),
                borderRadius: BorderRadius.circular(12),
                child: inner,
              ),
      ),
    );
  }

  Future<void> _openLocalFile(String path) async {
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done && mounted) {
      final msg = result.message.trim().isEmpty
          ? 'Не удалось открыть файл'
          : result.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _renameAttachment(PlaceAttachment current) async {
    final next = await _promptDisplayName(
      context,
      suggested: current.displayLabel ?? _basename(current.path),
    );
    if (next == null || !mounted) {
      return;
    }
    setState(() {
      final i = _attachments.indexOf(current);
      if (i >= 0) {
        _attachments[i] = PlaceAttachment(
          path: current.path,
          displayLabel: next.isEmpty ? null : next,
        );
      }
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null) {
      return;
    }
    final selected = result.files
        .map((file) => file.path ?? file.name)
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (selected.isEmpty) {
      return;
    }
    for (final path in selected) {
      if (_attachments.any((a) => a.path == path)) {
        continue;
      }
      if (!mounted) {
        return;
      }
      final name =
          await _promptDisplayName(context, suggested: _basename(path));
      if (name == null) {
        continue;
      }
      _attachments.add(
        PlaceAttachment(
          path: path,
          displayLabel: name.isEmpty ? null : name,
        ),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _promptDisplayName(
    BuildContext context, {
    required String suggested,
  }) async {
    final controller = TextEditingController(text: suggested);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Название в списке'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Как показывать'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('По умолчанию')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (!normalized.contains('/')) {
      return normalized;
    }
    return normalized.split('/').last;
  }
}
