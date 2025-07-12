import 'package:flutter/material.dart';
import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(String name, String iconName) onSave;
  final BusinessCategory? category;

  const AddCategoryDialog({
    Key? key,
    required this.onSave,
    this.category,
  }) : super(key: key);

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'restaurant';
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      // Set other fields if editing
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF9F6EF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: Container(
        width: 706,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.category == null ? 'Add Category' : 'Edit Category',
                    style: const TextStyle(
                      fontFamily: 'Basement Grotesque',
                      fontWeight: FontWeight.w800,
                      fontSize: 40,
                      height: 1.35,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              // Divider
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.black, Colors.transparent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              
              // Category Name Field
              _buildTextField(
                label: 'Category Name',
                hint: 'Enter Category Name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Icon Selection
              const Text(
                'Icon',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 8),
              
              // Icon Picker
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6DC),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: const Color(0xFFC8C8C8)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedIcon,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF333333)),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                      DropdownMenuItem(value: 'attorney', child: Text('Attorney')),
                      DropdownMenuItem(value: 'law_firm', child: Text('Law Firm')),
                      DropdownMenuItem(value: 'it_service', child: Text('IT Service')),
                      DropdownMenuItem(value: 'fire_service', child: Text('Fire Service')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedIcon = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Visibility Toggle
              const Text(
                'Visibility',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(29),
                ),
                child: ToggleButtons(
                  isSelected: [_isPublic, !_isPublic],
                  onPressed: (index) {
                    setState(() {
                      _isPublic = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(29),
                  selectedColor: const Color(0xFF333333),
                  fillColor: Colors.transparent,
                  renderBorder: false,
                  children: [
                    Container(
                      width: 159,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isPublic ? const Color(0xFF80C02A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(54),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: 'Basement Grotesque',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Container(
                      width: 159,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isPublic ? const Color(0xFF80C02A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(54),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontFamily: 'Basement Grotesque',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 34),
              
              // Create Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onSave(
                        _nameController.text.trim(),
                        _selectedIcon,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24439B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Create Category',
                    style: TextStyle(
                      fontFamily: 'Basement Grotesque',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFEBE6DC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(35),
              borderSide: const BorderSide(color: Color(0xFFC8C8C8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(35),
              borderSide: const BorderSide(color: Color(0xFFC8C8C8)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Color(0xFF333333),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
