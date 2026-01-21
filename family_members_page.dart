import 'package:flutter/material.dart';

// Model for Family Member
class FamilyMember {
  final String id;
  final String name;
  final String imageUrl;
  final String role; // 'homeowner' or 'member'

  FamilyMember({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.role,
  });
}

class FamilyMembersPage extends StatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  // Current user role - change this based on logged-in user
  final String currentUserRole = 'homeowner'; // or 'member'

  // Sample family members data (replace with database call)
  List<FamilyMember> familyMembers = [
    FamilyMember(
      id: '1',
      name: 'John Doe',
      imageUrl: 'https://i.pravatar.cc/150?img=12',
      role: 'homeowner',
    ),
    FamilyMember(
      id: '2',
      name: 'Jane Doe',
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      role: 'homeowner',
    ),
    FamilyMember(
      id: '3',
      name: 'Tommy Doe',
      imageUrl: 'https://i.pravatar.cc/150?img=33',
      role: 'member',
    ),
    FamilyMember(
      id: '4',
      name: 'Sarah Doe',
      imageUrl: 'https://i.pravatar.cc/150?img=9',
      role: 'member',
    ),
  ];

  bool get isHomeowner => currentUserRole == 'homeowner';

  void _addFamilyMember() {
    // Show dialog to add new family member
    showDialog(
      context: context,
      builder: (context) => AddFamilyMemberDialog(
        onAdd: (name, imageUrl) {
          setState(() {
            familyMembers.add(
              FamilyMember(
                id: DateTime.now().toString(),
                name: name,
                imageUrl: imageUrl,
                role: 'member',
              ),
            );
          });
        },
      ),
    );
  }

  void _removeFamilyMember(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text('Are you sure you want to remove $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                familyMembers.removeWhere((member) => member.id == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Members"),
        backgroundColor: const Color.fromARGB(255, 255, 207, 242),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(
                  isHomeowner ? Icons.admin_panel_settings : Icons.visibility,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isHomeowner
                        ? 'You can add or remove family members'
                        : 'View only - Contact homeowner to make changes',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Family members grid
          Expanded(
            child: familyMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No family members yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: familyMembers.length,
                    itemBuilder: (context, index) {
                      final member = familyMembers[index];
                      return _buildFamilyMemberCard(member);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isHomeowner
          ? FloatingActionButton.extended(
              onPressed: _addFamilyMember,
              backgroundColor: const Color.fromARGB(255, 255, 207, 242),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
            )
          : null,
    );
  }

  Widget _buildFamilyMemberCard(FamilyMember member) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Profile image
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(member.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Role badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: member.role == 'homeowner'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.role == 'homeowner' ? 'Owner' : 'Member',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: member.role == 'homeowner'
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),

                // Delete button (only for homeowners and non-homeowner members)
                if (isHomeowner && member.role != 'homeowner')
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: () => _removeFamilyMember(member.id, member.name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Name
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              member.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog for adding new family member
class AddFamilyMemberDialog extends StatefulWidget {
  final Function(String name, String imageUrl) onAdd;

  const AddFamilyMemberDialog({super.key, required this.onAdd});

  @override
  State<AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Family Member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // In real app, this would open camera/gallery to capture face
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera integration needed for face capture'),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Face Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 207, 242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Face photo required for recognition',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // In real app, use actual captured image
              final randomImg = DateTime.now().millisecond % 70;
              widget.onAdd(
                _nameController.text,
                'https://i.pravatar.cc/150?img=$randomImg',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_nameController.text} added successfully'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 207, 242),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}