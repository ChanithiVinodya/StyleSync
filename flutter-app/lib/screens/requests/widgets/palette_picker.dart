import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../modules/requests/models/request_models.dart';
import '../../../modules/requests/providers/requests_provider.dart';

final palettePresetsProvider = FutureProvider<List<PalettePreset>>((ref) async {
  final repo = ref.watch(requestsRepositoryProvider);
  return repo.listPalettePresets();
});

class PalettePicker extends ConsumerStatefulWidget {
  final PaletteSelection? initialSelection;
  final ValueChanged<PaletteSelection?> onChanged;
  final String? errorText;

  const PalettePicker({
    super.key,
    this.initialSelection,
    required this.onChanged,
    this.errorText,
  });

  @override
  ConsumerState<PalettePicker> createState() => _PalettePickerState();
}

class _PalettePickerState extends ConsumerState<PalettePicker> {
  late PaletteSelection _selection;
  List<PaletteColour>? _generatedColours;
  bool _isGenerating = false;
  String? _generateError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection ?? const PaletteSelection(mode: PaletteMode.preset);
    if (_selection.mode == PaletteMode.generated && _selection.baseColour != null) {
      _generateColours(_selection.baseColour!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _notifyChange() {
    if (_selection.presetId == null && _selection.baseColour == null) {
      widget.onChanged(null);
    } else {
      widget.onChanged(_selection);
    }
  }

  void _setMode(PaletteMode mode) {
    if (_selection.mode == mode) return;
    setState(() {
      _selection = PaletteSelection(mode: mode);
      _generatedColours = null;
      _generateError = null;
    });
    _notifyChange();
  }

  void _setPreset(String presetId) {
    setState(() {
      if (_selection.presetId == presetId) {
        _selection = const PaletteSelection(mode: PaletteMode.preset);
      } else {
        _selection = PaletteSelection(mode: PaletteMode.preset, presetId: presetId);
      }
    });
    _notifyChange();
  }

  void _setBaseColour(String hex) {
    setState(() {
      _selection = PaletteSelection(mode: PaletteMode.generated, baseColour: hex);
      _isGenerating = true;
      _generateError = null;
    });
    _notifyChange();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _generateColours(hex);
    });
  }

  void _clearSelection() {
    setState(() {
      _selection = PaletteSelection(mode: _selection.mode);
      _generatedColours = null;
      _generateError = null;
    });
    _notifyChange();
  }

  Future<void> _generateColours(String hex) async {
    setState(() {
      _isGenerating = true;
      _generateError = null;
    });
    try {
      final repo = ref.read(requestsRepositoryProvider);
      final colours = await repo.generatePalette(hex);
      if (!mounted) return;
      if (_selection.mode == PaletteMode.generated && _selection.baseColour == hex) {
        setState(() {
          _generatedColours = colours;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_selection.mode == PaletteMode.generated && _selection.baseColour == hex) {
        setState(() {
          _isGenerating = false;
          _generateError = 'Failed to preview palette. You can still save.';
        });
      }
    }
  }

  void _retryGenerate() {
    if (_selection.baseColour != null) {
      _generateColours(_selection.baseColour!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Preferred colours (optional)', style: Theme.of(context).textTheme.titleMedium),
            if (_selection.presetId != null || _selection.baseColour != null)
              TextButton(
                onPressed: _clearSelection,
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<PaletteMode>(
          segments: const [
            ButtonSegment(value: PaletteMode.preset, label: Text('Presets')),
            ButtonSegment(value: PaletteMode.generated, label: Text('From one colour')),
          ],
          selected: {_selection.mode},
          onSelectionChanged: (Set<PaletteMode> newSelection) {
            _setMode(newSelection.first);
          },
        ),
        const SizedBox(height: 16),
        if (_selection.mode == PaletteMode.preset)
          _buildPresets(context)
        else
          _buildGenerator(context),
        
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPresets(BuildContext context) {
    final presetsAsync = ref.watch(palettePresetsProvider);

    return presetsAsync.when(
      data: (presets) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final preset = presets[index];
            final isSelected = _selection.presetId == preset.id;
            return Card(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
              child: InkWell(
                onTap: () => _setPreset(preset.id),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(preset.mood, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: preset.colours.map((c) => Expanded(
                          child: _ColourChip(
                            hex: c.hexValue,
                            label: 'Position ${c.position}',
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Failed to load presets: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildGenerator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _pickColour(context, _selection.baseColour),
              child: const Text('Pick Base Colour'),
            ),
            const SizedBox(width: 16),
            if (_selection.baseColour != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hexToColor(_selection.baseColour!),
                  border: Border.all(color: Colors.grey),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isGenerating)
          const Center(child: CircularProgressIndicator())
        else if (_generateError != null)
          Row(
            children: [
              Expanded(child: Text(_generateError!, style: const TextStyle(color: Colors.red))),
              TextButton(onPressed: _retryGenerate, child: const Text('Retry')),
            ],
          )
        else if (_generatedColours != null && _generatedColours!.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _generatedColours!.map((c) {
              final labels = ['Base', 'Lighter', 'Darker', 'Analogous', 'Complement'];
              final label = (c.position > 0 && c.position <= labels.length) ? labels[c.position - 1] : 'Colour';
              return _ColourChip(hex: c.hexValue, label: label, showLabel: true);
            }).toList(),
          ),
      ],
    );
  }

  void _pickColour(BuildContext context, String? currentHex) {
    Color pickerColor = currentHex != null ? _hexToColor(currentHex) : Colors.blue;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a colour'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (c) => pickerColor = c,
                enableAlpha: false,
                hexInputBar: true,
                portraitOnly: true,
                pickerAreaHeightPercent: 0.8,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _setBaseColour(_colorToHex(pickerColor));
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  String _colorToHex(Color color) {
    // ignore: deprecated_member_use
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

class _ColourChip extends StatelessWidget {
  final String hex;
  final String label;
  final bool showLabel;

  const _ColourChip({
    required this.hex,
    required this.label,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(hex);
    final isLight = color.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black : Colors.white;

    return Semantics(
      label: 'Colour $hex',
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: hex));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copied $hex')),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Center(
            child: showLabel 
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: TextStyle(color: textColor, fontSize: 10)),
                      Text(hex, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Text(hex, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
