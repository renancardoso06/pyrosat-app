import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const VigIAApp());
}

class VigIAApp extends StatelessWidget {
  const VigIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VigIA',
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

// Tela de splash que aparece por 3 segundos antes de ir pro mapa
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
            const Icon(Icons.satellite_alt, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'VigIA',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vigilância Ambiental Inteligente',
              style: TextStyle(fontSize: 14, color: Colors.orange.shade200),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitoramento de Queimadas via Satélite',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade100.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

// Tela principal com a navbar inferior
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

// Modelo de um foco de incêndio detectado pelo satélite
class FireSpot {
  final double lat;
  final double lon;
  final String brightness; // temperatura radiativa em Kelvin (padrão NASA)
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

// Algoritmo de previsão de risco por bioma
// Leva em conta: quantidade de focos, temperatura média e época do ano
class RiskModel {
  static String calcularRisco(int focos, double tempMedia) {
    double score = 0;

    // peso da quantidade de focos ativos
    if (focos >= 4) {
      score += 3;
    } else if (focos >= 2) {
      score += 2;
    } else {
      score += 1;
    }

    // peso da temperatura radiativa média
    if (tempMedia >= 390) {
      score += 3;
    } else if (tempMedia >= 370) {
      score += 2;
    } else {
      score += 1;
    }

    // fator sazonal — junho é época de seca no cerrado e amazônia
    score += 1.5;

    if (score >= 6) return 'Alto';
    if (score >= 4) return 'Médio';
    return 'Baixo';
  }

  static Color corRisco(String risco) {
    if (risco == 'Alto') return Colors.red;
    if (risco == 'Médio') return Colors.orange;
    return Colors.green;
  }

  static IconData iconeRisco(String risco) {
    if (risco == 'Alto') return Icons.warning_rounded;
    if (risco == 'Médio') return Icons.warning_amber_rounded;
    return Icons.check_circle_outline;
  }
}

// Tela do mapa com os focos de incêndio
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<FireSpot> _fireSpots = [];
  bool _loading = true;
  String _status = 'Carregando focos de incêndio...';

  // Dados simulados baseados em focos reais de 2026
  // Em produção, isso viria direto da API do NASA FIRMS
  final List<FireSpot> _mockSpots = [
    FireSpot(lat: -3.20, lon: -60.50, brightness: '389K', date: '05/06/2026', country: 'Brasil - AM (Amazônia)'),
    FireSpot(lat: -6.80, lon: -44.20, brightness: '356K', date: '05/06/2026', country: 'Brasil - MA (Caatinga)'),
    FireSpot(lat: -9.50, lon: -56.10, brightness: '401K', date: '05/06/2026', country: 'Brasil - MT (Amazônia)'),
    FireSpot(lat: -11.20, lon: -55.80, brightness: '378K', date: '04/06/2026', country: 'Brasil - MT (Cerrado)'),
    FireSpot(lat: -13.50, lon: -52.30, brightness: '362K', date: '04/06/2026', country: 'Brasil - MT (Cerrado)'),
    FireSpot(lat: -7.40, lon: -47.80, brightness: '345K', date: '04/06/2026', country: 'Brasil - TO (Cerrado)'),
    FireSpot(lat: -10.80, lon: -61.20, brightness: '392K', date: '05/06/2026', country: 'Brasil - RO (Amazônia)'),
    FireSpot(lat: -4.50, lon: -55.40, brightness: '371K', date: '05/06/2026', country: 'Brasil - PA (Amazônia)'),
    FireSpot(lat: -8.30, lon: -63.10, brightness: '355K', date: '04/06/2026', country: 'Brasil - AM (Amazônia)'),
    FireSpot(lat: -15.20, lon: -52.80, brightness: '388K', date: '05/06/2026', country: 'Brasil - GO (Cerrado)'),
    FireSpot(lat: -12.60, lon: -48.90, brightness: '367K', date: '04/06/2026', country: 'Brasil - TO (Cerrado)'),
    FireSpot(lat: -6.20, lon: -57.30, brightness: '341K', date: '05/06/2026', country: 'Brasil - PA (Amazônia)'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFireSpots();
  }

  Future<void> _loadFireSpots() async {
    // Simula o delay de uma requisição real à API
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _fireSpots = _mockSpots;
        _loading = false;
        _status = '${_mockSpots.length} focos detectados hoje';
      });
    }
  }

  // Cor do marcador baseada na temperatura radiativa do foco
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
            Icon(Icons.satellite_alt, color: Colors.orange),
            SizedBox(width: 8),
            Text('VigIA', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 2)),
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
              initialCenter: LatLng(-10.0, -55.0),
              initialZoom: 4.5,
              minZoom: 2,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vigia.app',
                tileProvider: CancellableNetworkTileProvider(),
                maxNativeZoom: 18,
                keepBuffer: 4,
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
                Text(spot.country, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

// Tela de alertas com filtro por nível de criticidade
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'todos';

  final List<Map<String, dynamic>> _allAlerts = const [
    {'title': 'Foco crítico detectado', 'location': 'Mato Grosso - MT (Amazônia)', 'time': 'Há 12 minutos', 'level': 'critical', 'temp': '401K'},
    {'title': 'Novo foco de incêndio', 'location': 'Rondônia - RO (Amazônia)', 'time': 'Há 34 minutos', 'level': 'high', 'temp': '392K'},
    {'title': 'Foco monitorado', 'location': 'Amazonas - AM', 'time': 'Há 1 hora', 'level': 'medium', 'temp': '389K'},
    {'title': 'Alerta de queimada', 'location': 'Pará - PA (Amazônia)', 'time': 'Há 2 horas', 'level': 'high', 'temp': '371K'},
    {'title': 'Foco detectado', 'location': 'Tocantins - TO (Cerrado)', 'time': 'Há 3 horas', 'level': 'medium', 'temp': '367K'},
    {'title': 'Foco de baixa intensidade', 'location': 'Maranhão - MA (Caatinga)', 'time': 'Há 4 horas', 'level': 'low', 'temp': '356K'},
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
    return _HoverableOption(
      value: value,
      label: label,
      color: color,
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedFilter = value);
        Navigator.pop(context);
      },
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

// Widget separado pra gerenciar o hover de cada opção do filtro
class _HoverableOption extends StatefulWidget {
  final String value;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverableOption({
    required this.value,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HoverableOption> createState() => _HoverableOptionState();
}

class _HoverableOptionState extends State<_HoverableOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.2)
                : _isHovered
                    ? widget.color.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected || _isHovered ? widget.color : Colors.white24,
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: widget.color, size: 20),
              const SizedBox(width: 12),
              Text(widget.label, style: TextStyle(color: widget.color, fontSize: 16, fontWeight: FontWeight.bold)),
              if (widget.isSelected) ...[
                const Spacer(),
                Icon(Icons.check, color: widget.color, size: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard com estatísticas e previsão de risco por IA
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Dados agrupados por bioma brasileiro para o modelo de IA
  static const Map<String, Map<String, dynamic>> _biomas = {
    'Amazônia': {'focos': 5, 'tempMedia': 381.0},
    'Cerrado': {'focos': 4, 'tempMedia': 371.5},
    'Caatinga': {'focos': 1, 'tempMedia': 356.0},
    'Pantanal': {'focos': 1, 'tempMedia': 362.0},
    'Mata Atlântica': {'focos': 1, 'tempMedia': 341.0},
  };

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
              Expanded(child: _statCard('5', 'Estados Afetados', Icons.map, Colors.deepOrange)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('401K', 'Temp. Máxima', Icons.thermostat, Colors.amber)),
            ]),
            const SizedBox(height: 24),
            const Text('Focos por Bioma', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _regionBar('Amazônia', 5, 12, Colors.red),
            _regionBar('Cerrado', 4, 12, Colors.deepOrange),
            _regionBar('Pantanal', 1, 12, Colors.orange),
            _regionBar('Caatinga', 1, 12, Colors.amber),
            _regionBar('Mata Atlântica', 1, 12, Colors.yellow),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.orange, size: 22),
                const SizedBox(width: 8),
                const Text('Previsão de Risco por IA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'O algoritmo VigIA analisa focos ativos, temperatura radiativa e sazonalidade para prever risco de novos incêndios por bioma.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ..._biomas.entries.map((entry) {
              final risco = RiskModel.calcularRisco(
                entry.value['focos'] as int,
                entry.value['tempMedia'] as double,
              );
              return _riskCard(entry.key, risco, entry.value['focos'] as int, entry.value['tempMedia'] as double);
            }),
            const SizedBox(height: 24),
            const Text('Fonte dos Dados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _sourceCard(),
          ],
        ),
      ),
    );
  }

  Widget _riskCard(String bioma, String risco, int focos, double tempMedia) {
    final color = RiskModel.corRisco(risco);
    final icon = RiskModel.iconeRisco(risco);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bioma, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$focos focos • Temp. média: ${tempMedia.toStringAsFixed(0)}K', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Risco $risco', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
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

  Widget _regionBar(String bioma, int count, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bioma, style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
            const Icon(Icons.satellite_alt, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('VigIA', style: TextStyle(color: Colors.orange, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const Text('Vigilância Ambiental Inteligente', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const Text('v1.0.0', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            _card('Sobre o App', 'O VigIA é um aplicativo de vigilância ambiental inteligente que monitora queimadas em tempo real, utilizando dados de satélites da NASA e algoritmos de IA para detectar, classificar e prever riscos de incêndio em todo o Brasil.'),
            const SizedBox(height: 16),
            _card('Inteligência Artificial', 'O algoritmo VigIA analisa focos ativos, temperatura radiativa e dados sazonais para calcular o nível de risco de novas queimadas por bioma, auxiliando na tomada de decisão e prevenção de desastres.'),
            const SizedBox(height: 16),
            _card('Tecnologia Espacial', 'Os dados são obtidos através do sistema NASA FIRMS (Fire Information for Resource Management System), que utiliza os satélites MODIS e VIIRS para detectar focos de calor ao redor do mundo.'),
            const SizedBox(height: 16),
            _card('International Charter', 'Este projeto se alinha com a iniciativa "Space and Major Disasters", que mobiliza agências espaciais mundiais para fornecer dados satelitais em situações de emergência.'),
            const SizedBox(height: 16),
            _card('Desenvolvido por', 'Renan Cardoso da Costa (RM557918)\nVictor Vieira Borges (RM557922)\n\nGlobal Solution FIAP 2026 — Space Connect.'),
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