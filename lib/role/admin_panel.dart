import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_page.dart';
import 'teacher_page.dart';

class AdminPanel extends StatefulWidget {
  final String prn;
  
  const AdminPanel({super.key, required this.prn});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  Map<String, dynamic>? adminData;
  bool loading = true;
  String selectedView = 'dashboard'; // dashboard, users, materials

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.prn).get();
      if (doc.exists) {
        setState(() {
          adminData = doc.data();
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedView = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
              const PopupMenuItem(value: 'users', child: Text('Manage Users')),
              const PopupMenuItem(value: 'materials', child: Text('View Materials')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.purple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: Colors.purple, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Admin: ${adminData?['name'] ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'PRN: ${widget.prn}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: selectedView == 'dashboard',
              onTap: () => setState(() => selectedView = 'dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Users'),
              selected: selectedView == 'users',
              onTap: () => setState(() => selectedView = 'users'),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('View Materials'),
              selected: selectedView == 'materials',
              onTap: () => setState(() => selectedView = 'materials'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Switch to Student View'),
              onTap: () => _switchToRole('student'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Switch to Teacher View'),
              onTap: () => _switchToRole('teacher'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/role_selection', (route) => false),
            ),
          ],
        ),
      ),
      body: _buildSelectedView(),
    );
  }

  Widget _buildSelectedView() {
    switch (selectedView) {
      case 'dashboard':
        return _buildDashboard();
      case 'users':
        return _buildUsersView();
      case 'materials':
        return _buildMaterialsView();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '0',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Materials',
                  '0',
                  Icons.library_books,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => selectedView = 'users'),
                  icon: const Icon(Icons.people),
                  label: const Text('Manage Users'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => selectedView = 'materials'),
                  icon: const Icon(Icons.library_books),
                  label: const Text('View Materials'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Users',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data!.docs[index];
                    final userData = user.data() as Map<String, dynamic>;
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(userData['role'] ?? 'student'),
                          child: Icon(
                            _getRoleIcon(userData['role'] ?? 'student'),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(userData['name'] ?? 'Unknown'),
                        subtitle: Text('PRN: ${user.id} | Role: ${userData['role'] ?? 'student'}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit User'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete User'),
                            ),
                          ],
                          onSelected: (value) => _handleUserAction(value, user.id, userData),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Materials',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('materials').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No materials found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final subject = snapshot.data!.docs[index];
                    
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.library_books, color: Colors.blue),
                        title: Text(subject.id),
                        subtitle: const Text('Subject'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _viewSubjectMaterials(subject.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'teacher':
        return Colors.green;
      case 'student':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.person;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  void _handleUserAction(String action, String userId, Map<String, dynamic> userData) {
    switch (action) {
      case 'view':
        _showUserDetails(userData);
        break;
      case 'edit':
        _editUser(userId, userData);
        break;
      case 'delete':
        _deleteUser(userId);
        break;
    }
  }

  void _showUserDetails(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${userData['name'] ?? 'N/A'}'),
            Text('PRN: ${userData['prn'] ?? 'N/A'}'),
            Text('Role: ${userData['role'] ?? 'student'}'),
            Text('Year: ${userData['year'] ?? 'N/A'}'),
            Text('Branch: ${userData['branch'] ?? 'N/A'}'),
            Text('Semester: ${userData['semester'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> userData) {
    // TODO: Implement user editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit user functionality coming soon')),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting user: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewSubjectMaterials(String subject) {
    // TODO: Implement subject materials view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing materials for $subject')),
    );
  }

  void _switchToRole(String role) {
    Widget page;
    switch (role) {
      case 'student':
        page = StudentPage(prn: widget.prn);
        break;
      case 'teacher':
        page = TeacherPage(prn: widget.prn);
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

