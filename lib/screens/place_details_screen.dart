import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../theme/build_trip_form_theme.dart';
import '../widgets/build_trip_app_bar.dart';
import '../widgets/build_trip_ui_cards.dart';
import '../utils/clipboard_utils.dart';
import '../utils/open_in_maps.dart';
import '../widgets/itinerary_widgets.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({
    super.key,
    required this.place,
  });

  final Place place;

  /// Вернуть из экрана при удалении пункта из дня (как [TravelSegmentDetailsScreen.deleteMarker]).
  static final Object deleteMarker = Object();

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _isClosing = false;

  /// Снимок при входе в режим редактирования (для «Отменить изменения»).
  Place? _editBaseline;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late final TextEditingController _newLinkTitleController;
  late final TextEditingController _newLinkUrlController;
  late List<PlaceLink> _customLinks;
  late final List<PlaceAttachment> _attachments;
  late PlaceKind _kind;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _addressController = TextEditingController(text: widget.place.address);
    _notesController = TextEditingController(text: widget.place.notes ?? '');
    _attachments = [...widget.place.attachments];
    _kind = widget.place.kind;
    _customLinks = [
      ...widget.place.customLinks.map(
        (e) => PlaceLink(title: e.title, url: e.url),
      ),
    ];
    _newLinkTitleController = TextEditingController();
    _newLinkUrlController = TextEditingController();
    _addressController.addListener(_onAddressChanged);
    _nameController.addListener(_onAnyFieldChanged);
    _notesController.addListener(_onAnyFieldChanged);
    _newLinkTitleController.addListener(_onAnyFieldChanged);
    _newLinkUrlController.addListener(_onAnyFieldChanged);
  }

  void _onAddressChanged() {
    if (_editing && mounted) {
      setState(() {});
    }
  }

  void _onAnyFieldChanged() {
    if (_editing) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _nameController.removeListener(_onAnyFieldChanged);
    _notesController.removeListener(_onAnyFieldChanged);
    _newLinkTitleController.removeListener(_onAnyFieldChanged);
    _newLinkUrlController.removeListener(_onAnyFieldChanged);
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _newLinkTitleController.dispose();
    _newLinkUrlController.dispose();
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
          titleText: context.l10n.t('place'),
          onBackPressed: _popWithAutoSave,
          actions: [
            IconButton(
              tooltip: context.l10n.t('delete'),
              onPressed: () =>
                  Navigator.of(context).pop(PlaceDetailsScreen.deleteMarker),
              style:
                  BuildTripAppBar.toolbarIconStyle(scheme, destructive: true),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 6),
            if (_editing) ...[
              if (_editDirty)
                IconButton(
                  tooltip: context.l10n.t('undoChanges'),
                  onPressed: _undoEdit,
                  style: BuildTripAppBar.toolbarIconStyle(scheme),
                  icon: const Icon(Icons.undo_rounded),
                ),
              if (_editDirty) const SizedBox(width: 2),
              IconButton(
                tooltip: context.l10n.t('done'),
                onPressed: _popWithAutoSave,
                style: BuildTripAppBar.toolbarIconStyle(scheme),
                icon: const Icon(Icons.check_rounded),
              ),
            ] else
              IconButton(
                tooltip: context.l10n.t('edit'),
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
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, lc) {
                      final innerW = lc.maxWidth - 32;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        children: [
                          BuildTripSectionCard(
                            icon: Icons.tune_rounded,
                            title: context.l10n.t('main'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme:
                                        BuildTripFormTheme.dropdownFilledTheme(
                                            scheme),
                                  ),
                                  child: DropdownMenu<PlaceKind>(
                                    key: ValueKey(_kind),
                                    width: innerW,
                                    initialSelection: _kind,
                                    label: Text(context.l10n.t('placeType')),
                                    leadingIcon: Icon(
                                      PlaceKindVisual.of(context, _kind).icon,
                                      color: PlaceKindVisual.of(context, _kind)
                                          .accent,
                                    ),
                                    menuStyle: MenuStyle(
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    onSelected: (PlaceKind? v) {
                                      if (v != null) {
                                        setState(() => _kind = v);
                                      }
                                    },
                                    dropdownMenuEntries: [
                                      for (final k
                                          in PlaceKindVisual.pickerOrder)
                                        DropdownMenuEntry<PlaceKind>(
                                          value: k,
                                          label: PlaceKindVisual.label(context, k),
                                          leadingIcon: Icon(
                                            PlaceKindVisual.of(context, k).icon,
                                            size: 22,
                                            color:
                                                PlaceKindVisual.of(context, k)
                                                    .accent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.t('name'),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? context.l10n.t('enterPlaceName')
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                _buildAddressEditingSection(scheme),
                              ],
                            ),
                          ),
                          BuildTripSectionCard(
                            icon: Icons.sticky_note_2_outlined,
                            title: context.l10n.t('notes'),
                            child: TextFormField(
                              controller: _notesController,
                              minLines: 1,
                              maxLines: 8,
                              decoration: InputDecoration(
                                labelText: context.l10n.t('notesText'),
                                hintText: context.l10n.t('optional'),
                                alignLabelWithHint: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          BuildTripSectionCard(
                            icon: Icons.attach_file_rounded,
                            title: context.l10n.t('files'),
                            titleTrailing: IconButton(
                              tooltip: context.l10n.t('addFiles'),
                              style: BuildTripAppBar.toolbarIconStyle(scheme),
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.upload_file_rounded),
                            ),
                            child: _attachments.isEmpty
                                ? BuildTripEmptyHint(
                                    icon: Icons.folder_open_rounded,
                                    message: context.l10n.t('noFilesAddHint'),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                          BuildTripSectionCard(
                            marginBottom: 0,
                            icon: Icons.link_rounded,
                            title: context.l10n.t('links'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.l10n.t('linksHint'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        height: 1.25,
                                        fontSize: 12.5,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _newLinkTitleController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.t('name'),
                                    hintText: context.l10n.t('optional'),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _newLinkUrlController,
                                  keyboardType: TextInputType.url,
                                  textInputAction: TextInputAction.done,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.t('linkAddress'),
                                    hintText: 'https://…',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _addCustomLink(),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: _addCustomLink,
                                    icon:
                                        const Icon(Icons.add_rounded, size: 22),
                                    label: Text(context.l10n.t('addLink')),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_customLinks.isEmpty)
                                  BuildTripEmptyHint(
                                    icon: Icons.link_off_rounded,
                                    message: context.l10n.t('noLinksYet'),
                                  )
                                else
                                  ...List<Widget>.generate(
                                    _customLinks.length,
                                    (i) => _buildLinkEditRow(i),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
    return !_placesContentEqual(_composeUpdatedPlace(), _editBaseline!);
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _editBaseline = _snapshotPlace(_composeUpdatedPlace());
    });
  }

  void _undoEdit() {
    final b = _editBaseline;
    if (b == null) {
      return;
    }
    setState(() {
      _nameController.text = b.name;
      _addressController.text = b.address;
      _notesController.text = b.notes ?? '';
      _kind = b.kind;
      _attachments
        ..clear()
        ..addAll(
          b.attachments.map(
            (a) => PlaceAttachment(path: a.path, displayLabel: a.displayLabel),
          ),
        );
      _customLinks = [
        ...b.customLinks.map(
          (e) => PlaceLink(title: e.title, url: e.url),
        ),
      ];
      _newLinkTitleController.clear();
      _newLinkUrlController.clear();
    });
  }

  Place _snapshotPlace(Place p) {
    return p.copyWith(
      attachments: p.attachments
          .map(
            (a) => PlaceAttachment(path: a.path, displayLabel: a.displayLabel),
          )
          .toList(),
      customLinks: [...p.customLinks],
    );
  }

  Place _composeUpdatedPlace() {
    return widget.place.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      kind: _kind,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      attachments: List<PlaceAttachment>.from(_attachments),
      customLinks: List<PlaceLink>.from(_customLinks),
    );
  }

  void _addCustomLink() {
    final url = _newLinkUrlController.text.trim();
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('enterLinkAddress'))),
        );
      }
      return;
    }
    final title = _newLinkTitleController.text.trim();
    setState(() {
      _customLinks.add(
        PlaceLink(
          title: title.isEmpty ? url : title,
          url: url,
        ),
      );
      _newLinkTitleController.clear();
      _newLinkUrlController.clear();
    });
  }

  /// Карточка ссылки в просмотре: устойчиво при длинных заголовках и при списке из нескольких штук.
  Widget _buildReadOnlyLinkCard(
    ColorScheme scheme,
    TextTheme t,
    PlaceLink link,
  ) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLinkInBrowser(link.url),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  link.title,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkEditRow(int index) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final link = _customLinks[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: scheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  link.title,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: context.l10n.t('delete'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                style: BuildTripAppBar.toolbarIconStyle(scheme),
                onPressed: () {
                  setState(() {
                    _customLinks.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _placesContentEqual(Place a, Place b) {
    if (a.name != b.name ||
        a.address != b.address ||
        a.kind != b.kind ||
        (a.notes ?? '') != (b.notes ?? '')) {
      return false;
    }
    if (a.customLinks.length != b.customLinks.length) {
      return false;
    }
    for (var i = 0; i < a.customLinks.length; i++) {
      if (a.customLinks[i].title != b.customLinks[i].title ||
          a.customLinks[i].url != b.customLinks[i].url) {
        return false;
      }
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
    if (!mounted || _isClosing) {
      return;
    }
    if (_editing) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        return;
      }
    } else {
      if (_composeUpdatedPlace().name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('enterPlaceName'))),
        );
        return;
      }
    }
    _isClosing = true;
    final updated = _composeUpdatedPlace();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updated);
    });
  }

  List<Widget> _buildReadOnlyChildren(ColorScheme scheme) {
    final visual = PlaceKindVisual.of(context, _kind);
    final name = _nameController.text.trim();
    final addr = _addressController.text.trim();
    final notes = _notesController.text.trim();
    final t = Theme.of(context).textTheme;
    return [
      _readOnlyHeroCard(scheme, t, visual, name, addr),
      const SizedBox(height: 12),
      BuildTripSectionCard(
        icon: Icons.sticky_note_2_outlined,
        title: context.l10n.t('notes'),
        child: notes.isEmpty
            ? BuildTripEmptyHint(
                icon: Icons.edit_note_rounded,
                message: context.l10n.t('noNotesYet'),
              )
            : Text(
                notes,
                style: t.bodyLarge?.copyWith(height: 1.45),
              ),
      ),
      BuildTripSectionCard(
        icon: Icons.attach_file_rounded,
        title: context.l10n.t('files'),
        child: _attachments.isEmpty
            ? BuildTripEmptyHint(
                icon: Icons.folder_open_rounded,
                message: context.l10n.t('noAttachedFiles'),
              )
            : Column(
                children: _attachments
                    .map((a) => _buildAttachmentRow(a, editing: false))
                    .toList(),
              ),
      ),
      BuildTripSectionCard(
        marginBottom: 0,
        icon: Icons.link_rounded,
        title: context.l10n.t('links'),
        child: _customLinks.isEmpty
            ? BuildTripEmptyHint(
                icon: Icons.link_off_rounded,
                message: context.l10n.t('noLinksYet'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _customLinks.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _buildReadOnlyLinkCard(scheme, t, _customLinks[i]),
                  ],
                ],
              ),
      ),
    ];
  }

  Widget _readOnlyHeroCard(
    ColorScheme scheme,
    TextTheme t,
    PlaceKindVisual visual,
    String name,
    String addr,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: visual.fill(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: visual.border(context), width: 1.2),
                ),
                child: Icon(visual.icon, color: visual.accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: visual.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        PlaceKindVisual.label(context, _kind),
                        style: t.labelMedium?.copyWith(
                          color: visual.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: name.isEmpty
                            ? null
                            : () => copyToClipboard(context, name),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            name.isEmpty ? context.l10n.t('withoutTitle') : name,
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.12,
                              fontSize:
                                  (t.headlineSmall?.fontSize ?? 24) * 0.92,
                              color: name.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (addr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => copyToClipboard(context, addr),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.place_outlined,
                                    size: 17,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    addr,
                                    style: t.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: addr.isEmpty ? null : () => _openAddressInMaps(addr),
              icon: const Icon(Icons.map_rounded, size: 22),
              label: Text(context.l10n.t('openInMaps')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                disabledForegroundColor:
                    scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (addr.isEmpty) ...[
            const SizedBox(height: 12),
            BuildTripEmptyHint(
              icon: Icons.location_off_outlined,
              message: context.l10n.t('addressMissingHint'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(PlaceAttachment a, {required bool editing}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openLocalFile(a.path),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
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
                    tooltip: context.l10n.t('name'),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    onPressed: () => _renameAttachment(a),
                    icon: const Icon(Icons.label_outline, size: 22),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('delete'),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
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
          ),
        ),
      ),
    );
  }

  Future<void> _openLocalFile(String path) async {
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done && mounted) {
      final msg = result.message.trim().isEmpty
          ? context.l10n.t('failedToOpenFile')
          : result.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openAddressInMaps(String address) async {
    await showOpenInMapsSheet(context, query: address);
  }

  /// Адрес в режиме редактирования: превью + выбор источника через карты / вручную / буфер.
  Widget _buildAddressEditingSection(ColorScheme scheme) {
    final addr = _addressController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.t('address'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              addr.isEmpty
                  ? context.l10n.t('addressNotSetHint')
                  : addr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: addr.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    height: 1.35,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _showChooseAddressOnMapSheet(context),
          icon: const Icon(Icons.map_outlined, size: 22),
          label: Text(context.l10n.t('chooseOnMap')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (addr.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAddressInMaps(addr),
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              label: Text(context.l10n.t('openCurrentAddressInMaps')),
            ),
          ),
        ],
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _openManualAddressDialog,
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: Text(context.l10n.t('enterAddressManually')),
        ),
      ],
    );
  }

  Future<void> _showChooseAddressOnMapSheet(BuildContext sheetContext) async {
    final scheme = Theme.of(sheetContext).colorScheme;
    final name = _nameController.text.trim();
    final addr = _addressController.text.trim();

    await showModalBottomSheet<void>(
      context: sheetContext,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  context.l10n.t('howToFillAddress'),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  context.l10n.t('addressFillHint'),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.label_outline_rounded, color: scheme.primary),
                title: Text(context.l10n.t('searchByPlaceName')),
                subtitle: Text(
                  name.isEmpty ? context.l10n.t('enterNameFirst') : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                enabled: name.isNotEmpty,
                onTap: name.isEmpty
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        _runAfterSheetClosed(() async {
                          await showOpenInMapsSheet(context, query: name);
                        });
                      },
              ),
              ListTile(
                leading: Icon(Icons.place_outlined, color: scheme.primary),
                title: Text(context.l10n.t('searchByCurrentAddress')),
                subtitle: Text(
                  addr.isEmpty ? context.l10n.t('addressIsEmpty') : addr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                enabled: addr.isNotEmpty,
                onTap: addr.isEmpty
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        _runAfterSheetClosed(() async {
                          await showOpenInMapsSheet(context, query: addr);
                        });
                      },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: scheme.primary),
                title: Text(context.l10n.t('enterAddressWithKeyboard')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _runAfterSheetClosed(_openManualAddressDialog);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.content_paste_rounded, color: scheme.primary),
                title: Text(context.l10n.t('pasteFromClipboard')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _runAfterSheetClosed(_pasteAddressFromClipboard);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _runAfterSheetClosed(Future<void> Function() action) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await action();
    });
  }

  Future<void> _openManualAddressDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _ManualAddressDialog(
        initialText: _addressController.text,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _addressController.text = result;
  }

  Future<void> _pasteAddressFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) {
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('clipboardEmpty'))),
      );
      return;
    }
    _addressController.text = text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('addressPastedFromClipboard'))),
    );
  }

  /// Открыть ссылку в браузере; если схемы нет — подставляем https.
  Future<void> _openLinkInBrowser(String raw) async {
    final uri = _linkUriOrNull(raw);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('failedToParseLink'))),
        );
      }
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('failedToOpenLink'))),
        );
      }
    }
  }

  static Uri? _linkUriOrNull(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return null;
    }
    var u = Uri.tryParse(t);
    if (u == null) {
      return null;
    }
    if (u.scheme.isNotEmpty) {
      return u;
    }
    u = Uri.tryParse('https://$t');
    if (u == null || u.host.isEmpty) {
      return null;
    }
    return u;
  }

  Future<void> _renameAttachment(PlaceAttachment current) async {
    final next = await _promptDisplayName(context,
        suggested: current.displayLabel ?? _basename(current.path));
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
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _PromptDisplayNameDialog(suggested: suggested),
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

/// Диалог ввода адреса: контроллер живёт в State и [dispose] после закрытия маршрута
/// (иначе при анимации закрытия [TextField] обращается к уже [dispose] контроллеру).
class _ManualAddressDialog extends StatefulWidget {
  const _ManualAddressDialog({required this.initialText});

  final String initialText;

  @override
  State<_ManualAddressDialog> createState() => _ManualAddressDialogState();
}

class _ManualAddressDialogState extends State<_ManualAddressDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.t('placeAddress')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: context.l10n.t('streetCityCountryHint'),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(context.l10n.t('save')),
        ),
      ],
    );
  }
}

class _PromptDisplayNameDialog extends StatefulWidget {
  const _PromptDisplayNameDialog({required this.suggested});

  final String suggested;

  @override
  State<_PromptDisplayNameDialog> createState() =>
      _PromptDisplayNameDialogState();
}

class _PromptDisplayNameDialogState extends State<_PromptDisplayNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.suggested);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.t('displayNameInList')),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: context.l10n.t('howToDisplayAsLink'),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(context.l10n.t('defaultValue')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.l10n.t('ok')),
        ),
      ],
    );
  }
}
