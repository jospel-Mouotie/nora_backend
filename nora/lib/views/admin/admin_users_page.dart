import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/user_api_service.dart';
import '../../../services/storage_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final UserApiService _userApiService = UserApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedRole = 'all';
  String _searchQuery = '';

  final List<Map<String, String>> _roles = [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'customer', 'label': 'Clients'},
    {'value': 'commercant', 'label': 'Commerçants'},
    {'value': 'livreur', 'label': 'Livreurs'},
    {'value': 'admin', 'label': 'Administrateurs'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _userApiService.getUsers(token);
      if (result['success'] && result['users'] != null) {
        setState(() {
          _users = result['users'];
          _isLoading = false;
        });
      } else {
        _loadTestUsers();
      }
    } catch (e) {
      _loadTestUsers();
    }
  }

  void _loadTestUsers() {
    setState(() {
      _users = [
        {'id': 1, 'name': 'Jean Dupont', 'email': 'jean@example.com', 'role': 'customer', 'created_at': '2026-05-01', 'is_active': true},
        {'id': 2, 'name': 'Marie Laurent', 'email': 'marie@example.com', 'role': 'commercant', 'created_at': '2026-05-02', 'is_active': true},
        {'id': 3, 'name': 'Paul Martin', 'email': 'paul@example.com', 'role': 'livreur', 'created_at': '2026-05-03', 'is_active': true},
      ];
      _isLoading = false;
    });
  }

  Future<void> _toggleUserStatus(int userId, bool isActive) async {
    final token = await StorageService().getToken();
    if (token == null) return;
    
    try {
      await _userApiService.updateUserStatus(userId, !isActive, token);
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Utilisateur désactivé' : 'Utilisateur activé'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Erreur toggle status: $e');
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'customer': return 'Client';
      case 'commercant': return 'Commerçant';
      case 'livreur': return 'Livreur';
      case 'admin': return 'Administrateur';
      default: return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'customer': return AppColors.info;
      case 'commercant': return AppColors.success;
      case 'livreur': return AppColors.warning;
      case 'admin': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      if (_selectedRole != 'all' && user['role'] != _selectedRole) return false;
      if (_searchQuery.isNotEmpty) {
        final name = user['name'].toLowerCase();
        final email = user['email'].toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !email.contains(query)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Utilisateurs', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _roles.map((role) {
                final isSelected = _selectedRole == role['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedRole = role['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(role['label']!, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredUsers.isEmpty
                    ? const Center(child: Text('Aucun utilisateur trouvé'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(user['email']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user['role']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(_getRoleLabel(user['role']), style: TextStyle(color: _getRoleColor(user['role']), fontSize: 11)),
                                  ),
                                  Switch(
                                    value: user['is_active'] == true,
                                    onChanged: (value) => _toggleUserStatus(user['id'], user['is_active']),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}