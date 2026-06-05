import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const PyroSatApp());
}

class PyroSatApp extends StatelessWidget {
  const PyroSatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyroSat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.deepOrange,
          surface: const Color(0xFF1A1A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'PyroSat',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitoramento de Queimadas via Satélite',
              style: TextStyle(fontSize: 14, color: Colors.orange.shade200),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    AlertsScreen(),
    DashboardScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF16213E),
        indicatorColor: Colors.orange.withValues(alpha: 0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.orange),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: Colors.orange),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.orange),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outlined),
            selectedIcon: Icon(Icons.info, color: Colors.orange),
            label: 'Sobre',
          ),
        ],
      ),
    );
  }
}

class FireSpot {
  final double lat;
  final double lon;
  final String brightness;
  final String date;
  final String country;

  FireSpot({
    required this.lat,
    required this.lon,
    required this.brightness,
    required this.date,
    required this.country,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<FireSpot> _fireSpots = [];
  bool _loading = true;
  String _status = 'Carregando focos de incêndio...';

  final List<FireSpot> _mockSpots = [
    FireSpot(lat: -3.71, lon: -38.54, brightness: '342K', date: '2026-06-05', country: 'Brasil - CE'),
    FireSpot(lat: -8.05, lon: -34.88, brightness: '356K', date: '2026-06-05', country: 'Brasil - PE'),
    FireSpot(lat: -12.97, lon: -38.51, brightness: '371K', date: '2026-06-05', country: 'Brasil - BA'),
    FireSpot(lat: -15.78, lon: -47.93, brightness: '388K', date: '2026-06-04', country: 'Brasil - DF'),
    FireSpot(lat: -19.92, lon: -43.94, brightness: '362K', date: '2026-06-04', country: 'Brasil - MG'),
    FireSpot(lat: -23.55, lon: -46.63, brightness: '345K', date: '2026-06-04', country: 'Brasil - SP'),
    FireSpot(lat: -10.18, lon: -48.33, brightness: '401K', date: '2026-06-05', country: 'Brasil - TO'),
    FireSpot(lat: -5.09, lon: -42.81, brightness: '378K', date: '2026-06-05', country: 'Brasil - PI'),
    FireSpot(lat: -1.46, lon: -48.50, brightness: '355K', date: '2026-06-04', country: 'Brasil - PA'),
    FireSpot(lat: -16.68, lon: -49.25, brightness: '392K', date: '2026-06-05', country: 'Brasil - GO'),
    FireSpot(lat: -20.44, lon: -54.65, brightness: '367K', date: '2026-06-04', country: 'Brasil - MS'),
    FireSpot(lat: -25.43, lon: -49.27, brightness: '341K', date: '2026-06-05', country: 'Brasil - PR'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFireSpots();
  }

  Future<void> _loadFireSpots() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _fireSpots = _mockSpots;
        _loading = false;
        _status = '${_mockSpots.length} focos detectados hoje';
      });
    }
  }

  Color _brightnessColor(String brightness) {
    final val = double.tryParse(brightness.replaceAll('K', '')) ?? 350;
    if (val >= 390) return Colors.red;
    if (val >= 370) return Colors.deepOrange;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange),
            SizedBox(width: 8),
            Text('PyroSat', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
              label: Text(_status, style: const TextStyle(color: Colors.orange, fontSize: 12)),
              avatar: _loading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                  : const Icon(Icons.satellite_alt, size: 14, color: Colors.orange),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-14.0, -51.0),
              initialZoom: 4.5,
              minZoom: 2,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pyrosat.app',
              ),
              MarkerLayer(
                markers: _fireSpots.map((spot) {
                  return Marker(
                    point: LatLng(spot.lat, spot.lon),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showSpotInfo(spot),
                      child: Icon(
                        Icons.local_fire_department,
                        color: _brightnessColor(spot.brightness),
                        size: 32,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Intensidade', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  _legendItem(Colors.orange, 'Baixa (< 370K)'),
                  _legendItem(Colors.deepOrange, 'Média (370-390K)'),
                  _legendItem(Colors.red, 'Alta (> 390K)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.local_fire_department, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  void _showSpotInfo(FireSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text(spot.country, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.thermostat, 'Temperatura radiativa', spot.brightness),
            _infoRow(Icons.calendar_today, 'Data de detecção', spot.date),
            _infoRow(Icons.satellite_alt, 'Fonte', 'NASA FIRMS / MODIS'),
            _infoRow(Icons.location_on, 'Coordenadas', '${spot.lat.toStringAsFixed(2)}, ${spot.lon.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'todos';

  final List<Map<String, dynamic>> _allAlerts = const [
    {'title': 'Foco crítico detectado', 'location': 'Tocantins - TO', 'time': 'Há 12 minutos', 'level': 'critical', 'temp': '401K'},
    {'title': 'Novo foco de incêndio', 'location': 'Goiás - GO', 'time': 'Há 34 minutos', 'level': 'high', 'temp': '392K'},
    {'title': 'Foco monitorado', 'location': 'Piauí - PI', 'time': 'Há 1 hora', 'level': 'medium', 'temp': '378K'},
    {'title': 'Alerta de queimada', 'location': 'Bahia - BA', 'time': 'Há 2 horas', 'level': 'high', 'temp': '371K'},
    {'title': 'Foco detectado', 'location': 'Pará - PA', 'time': 'Há 3 horas', 'level': 'medium', 'temp': '355K'},
    {'title': 'Foco de baixa intensidade', 'location': 'Paraná - PR', 'time': 'Há 4 horas', 'level': 'low', 'temp': '341K'},
  ];

  List<Map<String, dynamic>> get _filteredAlerts {
    if (_selectedFilter == 'todos') return _allAlerts;
    return _allAlerts.where((a) => a['level'] == _selectedFilter).toList();
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'critical': return Colors.red;
      case 'high': return Colors.deepOrange;
      case 'medium': return Colors.orange;
      default: return Colors.amber;
    }
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'critical': return 'CRÍTICO';
      case 'high': return 'ALTO';
      case 'medium': return 'MÉDIO';
      default: return 'BAIXO';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar por nível', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _filterOption('todos', 'Todos', Colors.white),
            _filterOption('critical', 'CRÍTICO', Colors.red),
            _filterOption('high', 'ALTO', Colors.deepOrange),
            _filterOption('medium', 'MÉDIO', Colors.orange),
            _filterOption('low', 'BAIXO', Colors.amber),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check, color: color, size: 20),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filteredAlerts;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Alertas', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.orange),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('Nenhum alerta neste nível', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final color = _levelColor(alert['level']);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Icon(Icons.local_fire_department, color: color),
                    ),
                    title: Text(alert['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(alert['location'], style: const TextStyle(color: Colors.white70)),
                        Text(alert['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_levelLabel(alert['level']), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Text(alert['temp'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Dashboard', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo de Hoje', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _statCard('12', 'Focos Ativos', Icons.local_fire_department, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('3', 'Críticos', Icons.warning, Colors.red)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('7', 'Estados Afetados', Icons.map, Colors.deepOrange)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('401K', 'Temp. Máxima', Icons.thermostat, Colors.amber)),
            ]),
            const SizedBox(height: 24),
            const Text('Focos por Região', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _regionBar('Nordeste', 4, 12, Colors.orange),
            _regionBar('Centro-Oeste', 3, 12, Colors.deepOrange),
            _regionBar('Norte', 2, 12, Colors.red),
            _regionBar('Sudeste', 2, 12, Colors.amber),
            _regionBar('Sul', 1, 12, Colors.yellow),
            const SizedBox(height: 24),
            const Text('Fonte dos Dados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _sourceCard(),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _regionBar(String region, int count, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(region, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('$count focos', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.satellite_alt, color: Colors.orange, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NASA FIRMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Fire Information for Resource Management System', style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(height: 4),
                Text('Dados via satélite MODIS/VIIRS em tempo real', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Sobre', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.local_fire_department, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('PyroSat', style: TextStyle(color: Colors.orange, fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('v1.0.0', style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 24),
            _card('Sobre o App', 'O PyroSat é um aplicativo de monitoramento de queimadas em tempo real, utilizando dados de satélites da NASA para detectar e alertar sobre focos de incêndio em todo o Brasil.'),
            const SizedBox(height: 16),
            _card('Tecnologia Espacial', 'Os dados são obtidos através do sistema NASA FIRMS (Fire Information for Resource Management System), que utiliza os satélites MODIS e VIIRS para detectar focos de calor ao redor do mundo.'),
            const SizedBox(height: 16),
            _card('International Charter', 'Este projeto se alinha com a iniciativa "Space and Major Disasters", que mobiliza agências espaciais mundiais para fornecer dados satelitais em situações de emergência.'),
            const SizedBox(height: 16),
            _card('Desenvolvido por', 'Renan Cardoso da Costa (RM557918) e Victor Vieira Borges (RM557922)\n\nGlobal Solution FIAP 2026 — Space Connect.'),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}