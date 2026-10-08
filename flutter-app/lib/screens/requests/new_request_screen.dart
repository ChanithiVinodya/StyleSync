import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/requests/models/request_models.dart';
import '../../modules/requests/providers/requests_provider.dart';
import '../../modules/requests/utils/request_constants.dart';
import '../../shared/widgets/main_bottom_nav_bar.dart';
import '../../screens/home/home_screen.dart';
import '../../routes.dart';
import 'widgets/palette_picker.dart';
import 'widgets/room_photo_picker.dart';
import 'widgets/moodboard_picker.dart';
import 'widgets/style_picker.dart';
import 'request_detail_screen.dart';
import '../../providers/auth/auth_provider.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  final String? editId;
  final String? initialRoomType;
  final List<String>? initialStyleTags;

  const NewRequestScreen({
    super.key,
    this.editId,
    this.initialRoomType,
    this.initialStyleTags,
  });

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  RoomType? _roomType;
  PaletteSelection? _paletteSelection;
  String? _currentId;
  String? _roomPhotoUrl;
  List<MoodboardImage> _moodboardImages = [];
  List<String> _selectedStyleTags = [];
  String? _styleError;
  String? _preferredDesignerId;
  List<dynamic> _designers = [];
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  final Map<String, String> _serverErrors = {};
  String? _unmappedError;
  bool _hasUnsavedChanges = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _currentId = widget.editId;
    if (widget.initialRoomType != null) {
      _roomType = RoomType.fromJson(widget.initialRoomType!);
    }
    if (widget.initialStyleTags != null && widget.initialStyleTags!.isNotEmpty) {
      _selectedStyleTags = List.from(widget.initialStyleTags!);
    }
    _budgetController.addListener(_markChanged);
    _lengthController.addListener(_onDimensionChanged);
    _widthController.addListener(_onDimensionChanged);
    _heightController.addListener(_onDimensionChanged);
    _descriptionController.addListener(_markChanged);
  }

  void _onDimensionChanged() {
    _markChanged();
    setState(() {});
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  int get _filledSectionCount {
    int count = 0;
    if (_roomType != null) count++;
    if (_lengthController.text.trim().isNotEmpty ||
        _widthController.text.trim().isNotEmpty ||
        _heightController.text.trim().isNotEmpty) {
      count++;
    }
    if (_selectedStyleTags.isNotEmpty) count++;
    if (_budgetController.text.trim().isNotEmpty) count++;
    if (_descriptionController.text.trim().isNotEmpty) count++;
    if (_roomPhotoUrl != null && _roomPhotoUrl!.isNotEmpty) count++;
    if (_moodboardImages.isNotEmpty) count++;
    if (_paletteSelection != null) count++;
    return count;
  }

  double? get _calculatedArea {
    final l = double.tryParse(_lengthController.text.trim());
    final w = double.tryParse(_widthController.text.trim());
    if (l != null && w != null && l > 0 && w > 0) {
      return l * w;
    }
    return null;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    if (_isInit) return;
    
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      try {
        final res = await apiClient.dio.get('/DesignerProfiles');
        if (res.data != null && res.data is List) {
          _designers = res.data as List;
        }
      } catch (e) {
        debugPrint('Failed to load designers: $e');
      }

      if (widget.editId == null) {
        _hasUnsavedChanges = false;
        _isInit = true;
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final repo = ref.read(requestsRepositoryProvider);
      final draft = await repo.getRequest(widget.editId!);
      
      _roomType = draft.roomType;
      _budgetController.text = draft.budget?.toString() ?? '';
      
      var cleanDesc = draft.description ?? '';
      final dimMatch = RegExp(r'\[Dimensions: L=([^,]+), W=([^,]+), H=([^\]]+)\]').firstMatch(cleanDesc);
      if (dimMatch != null) {
        _lengthController.text = dimMatch.group(1)?.trim() ?? '';
        _widthController.text = dimMatch.group(2)?.trim() ?? '';
        _heightController.text = dimMatch.group(3)?.trim() ?? '';
        cleanDesc = cleanDesc.replaceAll(dimMatch.group(0)!, '').trim();
      }

      final styleMatch = RegExp(r'\[Styles:\s*([^\]]+)\]').firstMatch(cleanDesc);
      if (styleMatch != null) {
        if (draft.requestedStyleTags.isEmpty) {
          _selectedStyleTags = styleMatch.group(1)!.split(',').map((s) => s.trim()).toList();
        }
        cleanDesc = cleanDesc.replaceAll(styleMatch.group(0)!, '').trim();
      }
      _descriptionController.text = cleanDesc;
      
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
      if (draft.requestedStyleTags.isNotEmpty) {
        _selectedStyleTags = List.from(draft.requestedStyleTags);
      }
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
    if (!isSilent) {
      if (!_formKey.currentState!.validate()) return null;
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
      data['roomType'] = (_roomType ?? RoomType.livingRoom).toJson();
      if (_budgetController.text.trim().isNotEmpty) {
        data['budget'] = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      }
      
      final l = double.tryParse(_lengthController.text.trim());
      final w = double.tryParse(_widthController.text.trim());
      final h = double.tryParse(_heightController.text.trim());

      if (l != null && w != null && l > 0 && w > 0) {
        final size = l * w;
        data['roomSizeSqFt'] = size;
        data['roomSizeSqM'] = size;
      } else {
        data['roomSizeSqFt'] = 0;
        data['roomSizeSqM'] = 0;
      }

      final userDesc = _descriptionController.text.trim();
      if (l != null || w != null || h != null) {
        final lStr = _lengthController.text.trim();
        final wStr = _widthController.text.trim();
        final hStr = _heightController.text.trim();
        final dimTag = '[Dimensions: L=$lStr, W=$wStr, H=$hStr]';
        data['description'] = userDesc.isEmpty ? dimTag : '$userDesc\n\n$dimTag';
      } else if (userDesc.isNotEmpty) {
        data['description'] = userDesc;
      }
      
      if (_paletteSelection != null) {
        data['palette'] = _paletteSelection!.toJson();
      } else {
        data['palette'] = null;
      }

      data['requestedStyleTags'] = _selectedStyleTags;
      data['preferredDesignerId'] = _preferredDesignerId;

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
    setState(() => _isSubmitting = true);

    final isFormValid = _formKey.currentState!.validate();
    if (_selectedStyleTags.isEmpty) {
      setState(() => _styleError = 'Pick at least one style you like');
    }

    if (!isFormValid || _selectedStyleTags.isEmpty) {
      if (_selectedStyleTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick at least one style you like')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please correct the validation errors before submitting.')),
        );
      }
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
              children: e.errors.map((err) {
                String message = err.message;
                final field = err.field.toLowerCase();
                if (field == 'roomsizesqft' || field == 'roomsizesqm' || err.code == 'ROOM_SIZE_INVALID') {
                  message = 'Length, width, and height are required: length and width must produce a room size > 0 and <= 10000 sq ft.';
                }
                return Text('• $message');
              }).toList(),
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
    if (val == null || val.trim().isEmpty) {
      return _isSubmitting ? 'Budget is required' : null;
    }
    final numVal = double.tryParse(val.trim());
    if (numVal == null) return 'Must be a number';
    if (numVal <= RequestConstants.minBudget) return 'Budget must be > ${RequestConstants.minBudget}';
    return null;
  }

  String? _validateLength(String? val) {
    if (_serverErrors.containsKey('roomsizesqft')) return _serverErrors['roomsizesqft'];
    if (_serverErrors.containsKey('roomsizesqm')) return _serverErrors['roomsizesqm'];
    if (_serverErrors.containsKey('length')) return _serverErrors['length'];
    if (val == null || val.trim().isEmpty) {
      return _isSubmitting ? 'Length is required' : null;
    }
    final numVal = double.tryParse(val.trim());
    if (numVal == null) return 'Must be a number';
    if (numVal <= 0) return 'Must be > 0';
    if (numVal > 200) return 'Must be <= 200 ft';
    return null;
  }

  String? _validateWidth(String? val) {
    if (_serverErrors.containsKey('roomsizesqft')) return _serverErrors['roomsizesqft'];
    if (_serverErrors.containsKey('roomsizesqm')) return _serverErrors['roomsizesqm'];
    if (_serverErrors.containsKey('width')) return _serverErrors['width'];
    if (val == null || val.trim().isEmpty) {
      return _isSubmitting ? 'Width is required' : null;
    }
    final numVal = double.tryParse(val.trim());
    if (numVal == null) return 'Must be a number';
    if (numVal <= 0) return 'Must be > 0';
    if (numVal > 200) return 'Must be <= 200 ft';
    return null;
  }

  String? _validateHeight(String? val) {
    if (_serverErrors.containsKey('height')) return _serverErrors['height'];
    if (val == null || val.trim().isEmpty) {
      return _isSubmitting ? 'Height is required' : null;
    }
    final numVal = double.tryParse(val.trim());
    if (numVal == null) return 'Must be a number';
    if (numVal <= 0) return 'Must be > 0';
    if (numVal > 50) return 'Must be <= 50 ft';
    return null;
  }

  String? _validateDescription(String? val) {
    if (_serverErrors.containsKey('description')) return _serverErrors['description'];
    if (val == null || val.trim().isEmpty) {
      return _isSubmitting ? 'Description is required' : null;
    }
    if (val.trim().length < RequestConstants.minDescriptionLength || val.trim().length > RequestConstants.maxDescriptionLength) {
      return 'Description must be ${RequestConstants.minDescriptionLength}-${RequestConstants.maxDescriptionLength} characters';
    }
    return null;
  }

  String? _validateRoomType(RoomType? val) {
    if (_serverErrors.containsKey('roomtype')) return _serverErrors['roomtype'];
    if (val == null && _isSubmitting) return 'Room type is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_filledSectionCount > 1) {
          final savedId = await _saveDraft(isSilent: true);
          if (savedId != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request progress saved as draft'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        if (!context.mounted) return;
        Navigator.of(context).pop();
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
                      
                      DropdownButtonFormField<String?>(
                        value: _preferredDesignerId,
                        decoration: const InputDecoration(labelText: 'Preferred Designer (Optional)'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('-- Let AI Decide --'),
                          ),
                          ..._designers.map((d) {
                            final name = d['displayName'] ?? 'Unknown';
                            final tags = (d['styleTags'] as List?)?.join(', ') ?? 'Various';
                            return DropdownMenuItem<String?>(
                              value: d['userId']?.toString(),
                              child: Text('$name ($tags)'),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          setState(() => _preferredDesignerId = val);
                          _markChanged();
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Room Dimensions (Length, Width, Height)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lengthController,
                              decoration: const InputDecoration(
                                labelText: 'Length (ft)',
                                hintText: '0.0',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              validator: _validateLength,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _widthController,
                              decoration: const InputDecoration(
                                labelText: 'Width (ft)',
                                hintText: '0.0',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              validator: _validateWidth,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: 'Height (ft)',
                                hintText: '0.0',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              validator: _validateHeight,
                            ),
                          ),
                        ],
                      ),
                      if (_calculatedArea != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            'Estimated Room Size: ${_calculatedArea!.toStringAsFixed(1)} sq ft',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      StylePicker(
                        selectedStyles: _selectedStyleTags,
                        errorText: _styleError,
                        onChanged: (styles) {
                          setState(() {
                            _selectedStyleTags = styles;
                            if (styles.isNotEmpty) {
                              _styleError = null;
                            }
                          });
                          _markChanged();
                        },
                      ),
                      const SizedBox(height: 20),
                      
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
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: 2,
          onTap: (index) async {
            if (_filledSectionCount > 1) {
              final savedId = await _saveDraft(isSilent: true);
              if (savedId != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request progress saved as draft'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => AuthGuard(child: HomeScreen(initialTab: index))),
              (route) => false,
            );
          },
        ),
      ),
    );
  }
}
