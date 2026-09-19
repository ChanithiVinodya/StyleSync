import 'package:flutter/material.dart';
import '../services/project_request_api.dart';
import '../models/project_request.dart';
import 'style_analysis_result_screen.dart';

class CreateProjectRequestScreen extends StatefulWidget {
  const CreateProjectRequestScreen({Key? key}) : super(key: key);

  @override
  State<CreateProjectRequestScreen> createState() => _CreateProjectRequestScreenState();
}

class _CreateProjectRequestScreenState extends State<CreateProjectRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ProjectRequestApiService();

  int _currentStep = 0;
  bool _isLoading = false;

  String _roomType = 'Bedroom';
  final _lengthController = TextEditingController(text: '15');
  final _widthController = TextEditingController(text: '12');
  final _heightController = TextEditingController(text: '10');
  final _budgetController = TextEditingController(text: '250000');
  final _descriptionController = TextEditingController(
      text: 'I want a simple room. I like white and light brown colours. I don\'t want too much furniture.');

  final List<String> _allStyles = [
    'Modern',
    'Minimalist',
    'Industrial',
    'Luxury',
    'Traditional',
    'Mid Century Modern'
  ];

  final List<String> _selectedStyles = ['Modern', 'Minimalist'];

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = await _apiService.createProjectRequest(
        roomType: _roomType,
        lengthFeet: double.parse(_lengthController.text),
        widthFeet: double.parse(_widthController.text),
        heightFeet: double.parse(_heightController.text),
        budgetLkr: double.parse(_budgetController.text),
        preferredStyles: _selectedStyles,
        description: _descriptionController.text,
        submitImmediately: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted! AI Style Analysis running...')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StyleAnalysisResultScreen(requestId: request.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room Makeover Request'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI Style Analysis Agent is analyzing your room photos & preferences...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitRequest();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                steps: [
                  // Step 1: Room Details
                  Step(
                    title: const Text('Room Specifications 📏'),
                    isActive: _currentStep >= 0,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _roomType,
                          decoration: const InputDecoration(labelText: 'Room Type 🛏️'),
                          items: ['Bedroom', 'Living Room', 'Kitchen', 'Dining Room', 'Home Office']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (val) => setState(() => _roomType = val!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _lengthController,
                                decoration: const InputDecoration(labelText: 'Length (ft)'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _widthController,
                                decoration: const InputDecoration(labelText: 'Width (ft)'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _heightController,
                                decoration: const InputDecoration(labelText: 'Height (ft)'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Step 2: Budget & Preferred Styles
                  Step(
                    title: const Text('Budget & Style 💰🎨'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _budgetController,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Budget (LKR) 💰',
                            prefixText: 'LKR ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        const Text('Preferred Styles (Choose one or more):',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allStyles.map((style) {
                            final isSelected = _selectedStyles.contains(style);
                            return FilterChip(
                              label: Text(style),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade100,
                              checkmarkColor: Colors.indigo.shade900,
                              onSelected: (_) => _toggleStyle(style),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Step 3: Photos & Description
                  Step(
                    title: const Text('Room Photos & Description 📸✍️'),
                    isActive: _currentStep >= 2,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.photo_library, color: Colors.indigo),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '3 Sample Room Photos ready for AI Analysis (Bedroom angle 1, angle 2, lighting photo).',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Design Goals & Notes ✍️',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Step 4: Summary Review
                  Step(
                    title: const Text('Review & Submit ✅'),
                    isActive: _currentStep >= 3,
                    content: Card(
                      color: Colors.grey.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Room: $_roomType', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Size: ${_lengthController.text} × ${_widthController.text} × ${_heightController.text} ft'),
                            Text('Budget: LKR ${_budgetController.text}'),
                            Text('Selected Styles: ${_selectedStyles.join(", ")}'),
                            const SizedBox(height: 8),
                            Text('Description: "${_descriptionController.text}"',
                                style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
