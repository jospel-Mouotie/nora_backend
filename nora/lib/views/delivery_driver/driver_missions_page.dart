import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/delivery_driver/mission_card.dart';

class DriverMissionsPage extends StatefulWidget {
  const DriverMissionsPage({super.key});

  @override
  State<DriverMissionsPage> createState() => _DriverMissionsPageState();
}

class _DriverMissionsPageState extends State<DriverMissionsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _missions = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending';

  final List<Map<String, String>> _filters = [
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'in_progress', 'label': 'En cours'},
    {'value': 'completed', 'label': 'Terminées'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _apiService.getMyMissions(token);
      if (result['success'] && result['missions'] != null) {
        setState(() {
          _missions = result['missions'];
          _isLoading = false;
        });
      } else {
        _loadTestMissions();
      }
    } catch (e) {
      _loadTestMissions();
    }
  }

  void _loadTestMissions() {
    setState(() {
      _missions = [
        {
          'id': 1,
          'order_number': 'ORD-001',
          'customer_name': 'Jean Dupont',
          'customer_address': 'Nkolbisson, Yaoundé',
          'distance': '3.2 km',
          'estimated_time': '14h30',
          'status': 'pending',
          'delivery_fee': 1500,
        },
        {
          'id': 2,
          'order_number': 'ORD-002',
          'customer_name': 'Marie Laurent',
          'customer_address': 'Mvog-Mbi, Yaoundé',
          'distance': '5.7 km',
          'estimated_time': '15h00',
          'status': 'in_progress',
          'delivery_fee': 2000,
        },
        {
          'id': 3,
          'order_number': 'ORD-003',
          'customer_name': 'Paul Martin',
          'customer_address': 'Bastos, Yaoundé',
          'distance': '2.1 km',
          'estimated_time': '13h45',
          'status': 'completed',
          'delivery_fee': 1200,
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _acceptMission(int missionId) async {
    final token = await StorageService().getToken();
    if (token == null) return;
    
    try {
      final result = await _apiService.acceptMission(missionId, token);
      if (result['success']) {
        _loadMissions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission acceptée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Erreur acceptation: $e');
    }
  }

  Future<void> _completeMission(int missionId) async {
    final token = await StorageService().getToken();
    if (token == null) return;
    
    try {
      final result = await _apiService.completeMission(missionId, token);
      if (result['success']) {
        _loadMissions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission terminée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Erreur completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMissions = _missions.where((m) {
      if (_selectedFilter == 'all') return true;
      return m['status'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mes missions',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = filter['value']!);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      filter['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Liste des missions
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredMissions.isEmpty
                    ? const Center(
                        child: Text('Aucune mission'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredMissions.length,
                        itemBuilder: (context, index) {
                          final mission = filteredMissions[index];
                          return MissionCard(
                            mission: mission,
                            onAccept: mission['status'] == 'pending'
                                ? () => _acceptMission(mission['id'])
                                : null,
                            onComplete: mission['status'] == 'in_progress'
                                ? () => _completeMission(mission['id'])
                                : null,
                            onTrack: mission['status'] == 'in_progress'
                                ? () {
                                    context.push(
                                      '${AppRoutes.orderTracking}/${mission['id']}',
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}