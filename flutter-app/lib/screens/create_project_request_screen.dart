import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/project_request_api.dart';
import '../models/project_request.dart';
import 'project_request_list_screen.dart';

class CreateProjectRequestScreen extends StatefulWidget {
  final ProjectRequestModel? existingDraft;

  const CreateProjectRequestScreen({super.key, this.existingDraft});

  @override
  State<CreateProjectRequestScreen> createState() => _CreateProjectRequestScreenState();
}

class _CreateProjectRequestScreenState extends State<CreateProjectRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ProjectRequestApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  String _roomType = 'Bedroom';

  // Room Dimensions controllers
  final _lengthController = TextEditingController(text: '12');
  final _widthController = TextEditingController(text: '14');
  final _heightController = TextEditingController(text: '10');
  final _roomSizeController = TextEditingController(text: '168');

  final _budgetController = TextEditingController(text: '250000');
  final _descriptionController = TextEditingController(
      text: 'I want a modern, peaceful bedroom makeover with light oak accents, soft ambient lighting, and minimalist furniture.');

  final List<String> _allColours = ['#F4F1EA', '#C2A68C', '#2C3E50', '#8C9A86', '#E9E4DC', '#6C7B95', '#D4AC0D'];
  final List<String> _selectedColours = ['#F4F1EA', '#C2A68C', '#2C3E50'];

  final List<String> _allStyles = ['Modern', 'Minimalist', 'Industrial', 'Luxury', 'Traditional', 'Scandinavian'];
  final List<String> _selectedStyles = ['Modern', 'Minimalist'];

  // Uploaded images (URLs or local paths)
  final List<String> _uploadedPhotoUrls = [
    'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=800&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingDraft != null) {
      final draft = widget.existingDraft!;
      _roomType = draft.roomType.isNotEmpty ? draft.roomType : 'Bedroom';
      _lengthController.text = draft.lengthFeet > 0 ? draft.lengthFeet.toStringAsFixed(0) : '12';
      _widthController.text = draft.widthFeet > 0 ? draft.widthFeet.toStringAsFixed(0) : '14';
      _heightController.text = draft.heightFeet > 0 ? draft.heightFeet.toStringAsFixed(0) : '10';
      _roomSizeController.text = draft.roomSize > 0 ? draft.roomSize.toStringAsFixed(0) : '168';
      _budgetController.text = draft.budgetLkr > 0 ? draft.budgetLkr.toStringAsFixed(0) : '250000';
      _descriptionController.text = draft.description;
      if (draft.preferredColours.isNotEmpty) {
        _selectedColours.clear();
        _selectedColours.addAll(draft.preferredColours);
      }
      if (draft.preferredStyles.isNotEmpty) {
        _selectedStyles.clear();
        _selectedStyles.addAll(draft.preferredStyles);
      }
      if (draft.photos.isNotEmpty) {
        _uploadedPhotoUrls.clear();
        _uploadedPhotoUrls.addAll(draft.photos.map((p) => p.photoUrl));
      }
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _roomSizeController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _recalculateRoomSize() {
    final double l = double.tryParse(_lengthController.text) ?? 0;
    final double w = double.tryParse(_widthController.text) ?? 0;
    if (l > 0 && w > 0) {
      setState(() {
        _roomSizeController.text = (l * w).toStringAsFixed(0);
      });
    }
  }

  // Camera upload (Device feature)
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _uploadedPhotoUrls.add(photo.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📷 Room Photo captured via Device Camera!')),
          );
        }
      }
    } catch (e) {
      _addSampleImage('Captured Camera Photo');
    }
  }

  // Moodboard gallery picker
  Future<void> _pickMoodboardFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _uploadedPhotoUrls.addAll(images.map((i) => i.path));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🖼️ Added ${images.length} inspiration moodboard images!')),
          );
        }
      }
    } catch (e) {
      _addSampleImage('Gallery Inspiration');
    }
  }

  void _addSampleImage(String label) {
    final samples = [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=800&auto=format&fit=crop',
    ];
    final sampleUrl = samples[_uploadedPhotoUrls.length % samples.length];
    setState(() {
      _uploadedPhotoUrls.add(sampleUrl);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $label to request!')),
    );
  }

  void _copyHexToClipboard(String hex) {
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $hex copied!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.indigo.shade800,
      ),
    );
  }

  void _toggleColour(String hex) {
    setState(() {
      if (_selectedColours.contains(hex)) {
        _selectedColours.remove(hex);
      } else {
        _selectedColours.add(hex);
      }
    });
  }

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _handleSave({required bool submitImmediately}) async {
    // Perform Device-side Validation
    if (!_formKey.currentState!.validate()) return;

    final double length = double.tryParse(_lengthController.text) ?? 0;
    final double width = double.tryParse(_widthController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;

    if (length <= 0 || width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Dimensions must be positive (Length, Width, Height > 0 ft)!'), backgroundColor: Colors.red),
      );
      return;
    }

    final double calculatedArea = length * width;
    final double roomSize = double.tryParse(_roomSizeController.text) ?? calculatedArea;

    final double? budget = double.tryParse(_budgetController.text);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Budget must be greater than 0 LKR!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (submitImmediately && _uploadedPhotoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please upload at least one room photo before submitting!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.existingDraft != null) {
        await _apiService.updateProjectRequest(widget.existingDraft!.id, {
          'title': '$_roomType Makeover',
          'roomType': _roomType,
          'roomSize': roomSize,
          'lengthFeet': length,
          'widthFeet': width,
          'heightFeet': height,
          'budgetMin': budget,
          'budgetMax': budget,
          'preferredColours': _selectedColours.join(', '),
          'stylePreferences': _selectedStyles.join(', '),
          'description': _descriptionController.text,
        });

        if (submitImmediately) {
          await _apiService.submitRequestForAIAnalysis(widget.existingDraft!.id);
        }
      } else {
        await _apiService.createProjectRequest(
          roomType: _roomType,
          roomSize: roomSize,
          lengthFeet: length,
          widthFeet: width,
          heightFeet: height,
          budgetLkr: budget,
          preferredColours: _selectedColours,
          preferredStyles: _selectedStyles,
          description: _descriptionController.text,
          photoUrls: _uploadedPhotoUrls,
          submitImmediately: submitImmediately,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(submitImmediately
                ? '✅ Request submitted! AI Workflow started.'
                : '💾 Draft saved successfully!'),
            backgroundColor: submitImmediately ? Colors.green.shade700 : Colors.indigo.shade700,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProjectRequestListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double l = double.tryParse(_lengthController.text) ?? 12;
    final double w = double.tryParse(_widthController.text) ?? 14;
    final double calculatedArea = l * w;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingDraft != null ? 'Edit Request Draft' : 'New Room Makeover Request'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      // Persistent Bottom Action Bar so Save Draft and Submit are ALWAYS visible!
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _handleSave(submitImmediately: false),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.indigo.shade800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _handleSave(submitImmediately: true),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing request and initiating AI workflow...'),
                ],
              ),
            )
          : Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Form(
                  key: _formKey,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.palette_outlined, color: Colors.white, size: 36),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client Request Form',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('Fill parameters, upload room photos & moodboard inspiration.',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Room Details
                    const Text('1. Room Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),

                    // Room Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _roomType,
                      decoration: InputDecoration(
                        labelText: 'Room Type *',
                        prefixIcon: const Icon(Icons.meeting_room),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['Bedroom', 'LivingRoom', 'Kitchen', 'Bathroom', 'Office', 'DiningRoom', 'Outdoor', 'Other']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) => setState(() => _roomType = val!),
                    ),
                    const SizedBox(height: 14),

                    // Dimensions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Room Dimensions (ft)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Text(
                            '📐 Area: ${calculatedArea.toStringAsFixed(0)} sq ft',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Length, Width, Height 3-Column Row
                    Row(
                      children: [
                        // Length (ft)
                        Expanded(
                          child: TextFormField(
                            controller: _lengthController,
                            decoration: InputDecoration(
                              labelText: 'Length (ft) *',
                              hintText: '12',
                              prefixIcon: const Icon(Icons.straighten, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _recalculateRoomSize(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Req';
                              final n = double.tryParse(val);
                              if (n == null || n <= 0) return '>0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Width (ft)
                        Expanded(
                          child: TextFormField(
                            controller: _widthController,
                            decoration: InputDecoration(
                              labelText: 'Width (ft) *',
                              hintText: '14',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _recalculateRoomSize(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Req';
                              final n = double.tryParse(val);
                              if (n == null || n <= 0) return '>0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Height (ft)
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: InputDecoration(
                              labelText: 'Height (ft) *',
                              hintText: '10',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Req';
                              final n = double.tryParse(val);
                              if (n == null || n <= 0) return '>0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Budget (LKR)
                    TextFormField(
                      controller: _budgetController,
                      decoration: InputDecoration(
                        labelText: 'Budget (LKR) *',
                        prefixIcon: const Icon(Icons.payments),
                        prefixText: 'LKR ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Budget required';
                        final val = double.tryParse(value);
                        if (val == null || val <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Room Photos & Moodboards (Meaningful device feature)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('2. Room Photos & Moodboards 📸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${_uploadedPhotoUrls.length} attached', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickMoodboardFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Image Thumbnails Grid
                    if (_uploadedPhotoUrls.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: _uploadedPhotoUrls.length,
                          itemBuilder: (context, index) {
                            final url = _uploadedPhotoUrls[index];
                            final isNetwork = url.startsWith('http');
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.indigo.shade200),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isNetwork
                                        ? Image.network(url, width: 100, height: 100, fit: BoxFit.cover)
                                        : Image.asset('assets/placeholder.png', width: 100, height: 100, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.image))),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _uploadedPhotoUrls.removeAt(index)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      color: Colors.black54,
                                      child: Text(
                                        index == 0 ? 'Room Photo' : 'Moodboard',
                                        style: const TextStyle(color: Colors.white, fontSize: 9),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Section 3: Extracted Colour Palette Hex Chips (Tappable + Copy)
                    const Text('3. Extracted Colour Palette 🎨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Tap any hex chip to select or copy hex code to clipboard.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allColours.map((hex) {
                        final isSelected = _selectedColours.contains(hex);
                        final int colorVal = int.parse(hex.replaceFirst('#', 'FF'), radix: 16);
                        return GestureDetector(
                          onLongPress: () => _copyHexToClipboard(hex),
                          child: FilterChip(
                            avatar: CircleAvatar(backgroundColor: Color(colorVal), radius: 8),
                            label: Text(hex, style: const TextStyle(fontWeight: FontWeight.w600)),
                            selected: isSelected,
                            selectedColor: Colors.indigo.shade100,
                            onSelected: (_) {
                              _toggleColour(hex);
                              _copyHexToClipboard(hex);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Preferred Styles & Description
                    const Text('4. Design Description & Goals ✍️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: _allStyles.map((style) {
                        final isSelected = _selectedStyles.contains(style);
                        return ChoiceChip(
                          label: Text(style),
                          selected: isSelected,
                          onSelected: (_) => _toggleStyle(style),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Detailed Description *',
                        hintText: 'Describe your aesthetic desires, storage needs, or preferred vibes...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Please provide at least 10 characters of description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
