import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/requests/models/request_models.dart';
import '../../modules/requests/providers/requests_provider.dart';
import '../../modules/requests/utils/request_constants.dart';
import 'widgets/palette_picker.dart';
import 'widgets/room_photo_picker.dart';
import 'widgets/moodboard_picker.dart';
import 'request_detail_screen.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  final String? editId;

  const NewRequestScreen({super.key, this.editId});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _roomSizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  RoomType? _roomType;
  PaletteSelection? _paletteSelection;
  String? _currentId;
  String? _roomPhotoUrl;
  List<MoodboardImage> _moodboardImages = [];
  
  bool _isLoading = false;
  final Map<String, String> _serverErrors = {};
  String? _unmappedError;
  bool _hasUnsavedChanges = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _currentId = widget.editId;
    _budgetController.addListener(_markChanged);
    _roomSizeController.addListener(_markChanged);
    _descriptionController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _roomSizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    if (widget.editId == null || _isInit) return;
    
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(requestsRepositoryProvider);
      final draft = await repo.getRequest(widget.editId!);
      
      _roomType = draft.roomType;
      _budgetController.text = draft.budget?.toString() ?? '';
      _roomSizeController.text = draft.roomSizeSqM?.toString() ?? '';
      _descriptionController.text = draft.description ?? '';
      
      if (draft.paletteMode != null) {
        final mode = PaletteMode.fromJson(draft.paletteMode);
        if (mode != null) {
          _paletteSelection = PaletteSelection(
            mode: mode,
            presetId: draft.palettePresetId,
            baseColour: draft.paletteBaseHex,
          );
        }
      }
      _roomPhotoUrl = draft.roomPhotoUrl;
      _moodboardImages = List.from(draft.moodboard);
      _hasUnsavedChanges = false;
    } catch (e) {
      _unmappedError = e.toString();
    } finally {
      _isInit = true;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDraft();
  }

  Future<String?> _saveDraft({bool isSilent = false}) async {
    if (!_formKey.currentState!.validate()) return null;

    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _serverErrors.clear();
        _unmappedError = null;
      });
    } else {
      _serverErrors.clear();
      _unmappedError = null;
    }

    try {
      final data = <String, dynamic>{};
      if (_roomType != null) data['roomType'] = _roomType!.toJson();
      if (_budgetController.text.isNotEmpty) data['budget'] = double.parse(_budgetController.text);
      if (_roomSizeController.text.isNotEmpty) {
        final size = double.parse(_roomSizeController.text);
        data['roomSizeSqFt'] = size;
        data['roomSizeSqM'] = size;
      }
      if (_descriptionController.text.isNotEmpty) data['description'] = _descriptionController.text;
      
      if (_paletteSelection != null) {
        data['palette'] = _paletteSelection!.toJson();
      } else {
        data['palette'] = null;
      }

      final repo = ref.read(requestsRepositoryProvider);
      if (_currentId != null) {
        await repo.updateDraft(_currentId!, data);
      } else {
        final draft = await repo.createDraft(data);
        _currentId = draft.id;
      }

      if (mounted) setState(() => _hasUnsavedChanges = false);
      
      if (!isSilent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully')),
        );
      }

      return _currentId;
    } on ApiProblem catch (e) {
      if (e.errors.isNotEmpty) {
        for (var err in e.errors) {
          final field = err.field.toLowerCase();
          if (field.startsWith('palette')) {
            _serverErrors['palette'] = err.message;
            if (err.code == 'PALETTE_PRESET_UNKNOWN') {
              _serverErrors['palette'] = 'That preset is no longer available';
              _paletteSelection = null; // Clear it in UI conceptually
            }
          } else {
            _serverErrors[field] = err.message;
          }
        }
        _formKey.currentState!.validate(); // Trigger re-validation to show errors
      } else {
        _unmappedError = e.title;
      }
      return null;
    } catch (e) {
      _unmappedError = 'An unexpected error occurred';
      return null;
    } finally {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the validation errors before submitting.')),
      );
      return;
    }

    if (_roomPhotoUrl == null || _roomPhotoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A room photo is required to submit your request.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _serverErrors.clear();
      _unmappedError = null;
    });

    final draftId = await _saveDraft(isSilent: true);
    if (draftId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final repo = ref.read(requestsRepositoryProvider);
      await repo.submit(draftId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      );

      if (widget.editId != null) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RequestDetailScreen(id: draftId)),
        );
      }
    } on ApiProblem catch (e) {
      if (!mounted) return;
      if (e.errors.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot Submit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: e.errors.map((err) => Text('• ${err.message}')).toList(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.title.isNotEmpty ? e.title : 'Failed to submit request.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateBudget(String? val) {
    if (_serverErrors.containsKey('budget')) return _serverErrors['budget'];
    if (val == null || val.isEmpty) return null; // Lenient saving
    final numVal = double.tryParse(val);
    if (numVal == null) return 'Must be a number';
    if (numVal <= RequestConstants.minBudget) return 'Budget must be > ${RequestConstants.minBudget}';
    return null;
  }

  String? _validateRoomSize(String? val) {
    if (_serverErrors.containsKey('roomsizesqft')) return _serverErrors['roomsizesqft'];
    if (_serverErrors.containsKey('roomsizesqm')) return _serverErrors['roomsizesqm'];
    if (val == null || val.isEmpty) return null;
    final numVal = double.tryParse(val);
    if (numVal == null) return 'Must be a number';
    if (numVal <= RequestConstants.minRoomSize || numVal > RequestConstants.maxRoomSize) {
      return 'Room size must be > ${RequestConstants.minRoomSize} and <= ${RequestConstants.maxRoomSize}';
    }
    return null;
  }

  String? _validateDescription(String? val) {
    if (_serverErrors.containsKey('description')) return _serverErrors['description'];
    if (val == null || val.isEmpty) return null;
    if (val.length < RequestConstants.minDescriptionLength || val.length > RequestConstants.maxDescriptionLength) {
      return 'Description must be ${RequestConstants.minDescriptionLength}-${RequestConstants.maxDescriptionLength} characters';
    }
    return null;
  }

  String? _validateRoomType(RoomType? val) {
    if (_serverErrors.containsKey('roomtype')) return _serverErrors['roomtype'];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to leave?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
            ],
          ),
        );
        if (res == true) {
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editId == null ? 'New Request' : 'Edit Draft'),
        ),
        body: _isLoading && !_isInit
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_unmappedError != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Text(
                            _unmappedError!,
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                        ),
                      
                      DropdownButtonFormField<RoomType>(
                        initialValue: _roomType,
                        decoration: const InputDecoration(labelText: 'Room type'),
                        items: RoomType.values.map((rt) {
                          return DropdownMenuItem(value: rt, child: Text(rt.label));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _roomType = val);
                          _markChanged();
                        },
                        validator: _validateRoomType,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _roomSizeController,
                        decoration: const InputDecoration(labelText: 'Room size (sq ft)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: _validateRoomSize,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(labelText: 'Budget (LKR)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: _validateBudget,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 4,
                        maxLength: RequestConstants.maxDescriptionLength,
                        validator: _validateDescription,
                      ),
                      const SizedBox(height: 24),
                      
                      RoomPhotoPicker(
                        initialPhotoUrl: _roomPhotoUrl,
                        requestId: _currentId,
                        onCreateDraft: () => _saveDraft(isSilent: true),
                        onPhotoUpdated: (url) {
                          setState(() => _roomPhotoUrl = url);
                        },
                      ),
                      const SizedBox(height: 24),

                      MoodboardPicker(
                        initialImages: _moodboardImages,
                        requestId: _currentId,
                        onCreateDraft: () => _saveDraft(isSilent: true),
                        onMoodboardUpdated: (images) {
                          setState(() => _moodboardImages = images);
                        },
                      ),
                      const SizedBox(height: 24),

                      PalettePicker(
                        initialSelection: _paletteSelection,
                        errorText: _serverErrors['palette'],
                        onChanged: (val) {
                          setState(() {
                            _paletteSelection = val;
                            if (_serverErrors.containsKey('palette')) {
                              _serverErrors.remove('palette');
                            }
                          });
                          _markChanged();
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _saveDraft(isSilent: false),
                                child: const Text('Save draft'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitRequest,
                                child: const Text('Submit Request'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
