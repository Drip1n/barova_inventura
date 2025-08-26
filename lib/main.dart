import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const BarovaInventuraApp());
}

// =========================================================================
// ZÁKLADNÉ NASTAVENIA APLIKÁCIE
// =========================================================================
class BarovaInventuraApp extends StatelessWidget {
  const BarovaInventuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barová inventúra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFF5A623),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5A623),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// =========================================================================
// OBRAZOVKY APLIKÁCIE
// =========================================================================

// --- OBRAZOVKA 1: Prihlásenie ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AppLogo(),
                  const SizedBox(height: 60),
                  const Text('API ID:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextFormField(decoration: const InputDecoration(hintText: '123 456'), keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  const Text('Heslo:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextFormField(decoration: const InputDecoration(hintText: 'zadajte heslo'), obscureText: true),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    child: const Text('Prihlásiť sa'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Prihlasovacie údaje sú jednorazové!\nV prípade potreby kontaktujte svojho administrátora',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- OBRAZOVKA 2: Domovská obrazovka (Dashboard) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barová inventúra')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Novinky a aktuality', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 8),
                  const Text('Integer mauris sem, convallis ut, consequat in, sollicitudin sed, leo. Cras purus elit, hendrerit ut, egestas eget, sagittis at, nulla.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Spacer(),
            _buildInfoRow('API ID:', '123 456'),
            const SizedBox(height: 16),
            _buildInfoRow('ID inventúry:', '123 456 789 1011'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EanInputScreen()));
              },
              child: const Text('Začať inventúru'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- OBRAZOVKA 3: Zadanie EAN kódu ---
class EanInputScreen extends StatelessWidget {
  const EanInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Text('Zadať EAN', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(hintText: 'Zadajte EAN kód produktu'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Simulujeme nájdenie produktu
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddProductScreen(isDispensed: false)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
              child: const Text('Potvrdiť'),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Zatiaľ len zobrazíme dialóg, že funkcia nie je dostupná
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Funkcia nie je dostupná'),
                    content: const Text('Skener bude implementovaný v ďalšom kroku.'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Naskenovať EAN'),
            ),
            const Spacer(flex: 2),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InventoryOverviewScreen()));
                },
                child: Text('Prehľad inventúry', style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- OBRAZOVKY 6 & 7: Prehľad inventúry ---
class InventoryOverviewScreen extends StatelessWidget {
  const InventoryOverviewScreen({super.key});

  // Dočasné dáta pre zobrazenie
  final List<Map<String, String>> dummyItems = const [
    {'name': 'TATRA TEA - Black', 'ean': '123 456 789 1011', 'quantity': '15 ks', 'volume': '150/1000 ml', 'time': '23:30'},
    {'name': 'Horalky Sedita', 'ean': '111 222 333 444', 'quantity': '249 ks', 'volume': '50 g', 'time': '23:31'},
    {'name': 'Zlatý bažant radler', 'ean': '555 666 777 888', 'quantity': '92 ks', 'volume': '500/500 ml', 'time': '23:32'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dummyItems.length,
              itemBuilder: (context, index) {
                final item = dummyItems[index];
                return ListTile(
                  title: Text(item['name']!),
                  subtitle: Text('EAN: ${item['ean']}\nMnožstvo: ${item['quantity']} (${item['volume']})'),
                  trailing: Text(item['time']!),
                  isThreeLine: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SuccessScreen()),
                  (route) => false,
                );
              },
              child: const Text('Dokončiť inventúru'),
            ),
          )
        ],
      ),
    );
  }
}


// --- OBRAZOVKY 8-11: Pridanie produktu ---
class AddProductScreen extends StatelessWidget {
  final bool isDispensed; // Rozlievaný produkt?
  const AddProductScreen({super.key, required this.isDispensed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('EAN kód produktu', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const Text('123 456 789 1011', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Názov produktu', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            Text(isDispensed ? 'TATRA TEA - Black' : 'Horalky Sedita', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            if (isDispensed) ...[
              const Text('Objem / Váha', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(hintText: '? / 1000 ml'), keyboardType: TextInputType.number),
            ],
            const SizedBox(height: 20),
            const Text('Počet na sklade', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(hintText: '? ks'), keyboardType: TextInputType.number),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Pridať produkt'),
            ),
          ],
        ),
      ),
    );
  }
}


// --- OBRAZOVKA 17: Úspešné dokončenie ---
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text('Inventúra úspešne\ndokončená', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            _buildInfoRow('API ID:', '123 456'),
            const SizedBox(height: 16),
            _buildInfoRow('ID inventúry:', '123 456 789 1011'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Odhlásiť sa'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// POMOCNÉ WIDGETY
// =========================================================================

// Logo aplikácie
class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('BAROVÁ', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10.0, color: Theme.of(context).primaryColor.withOpacity(0.7), offset: const Offset(0, 0))])),
        const Text('inventúra', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white)),
      ],
    );
  }
}

// Horná lišta s ID-čkami
PreferredSizeWidget _buildTopBarWithIds({bool showBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: showBackButton,
    title: Column(
      children: [
        const Text('BAROVÁ inventúra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('API ID: 123 456', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text('ID inventúry: 123 456 789 1011', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ],
    ),
  );
}
