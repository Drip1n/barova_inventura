import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// ENUM pre stavy synchronizácie
enum SyncStatus { synced, pending, failed }

// Dátový model pre položku v inventári - ROZŠÍRENÝ
class InventoryItem {
  String name;
  String ean;
  String manufacturer;
  String time;
  bool isDispensed;

  // Pre kusové produkty
  int? pieceCount;
  String? weight; // napr. "50g"

  // Pre rozlievané produkty
  int? fullBottleCount;
  double? openBottleWeight; // Aktuálna váha v gramoch
  double? emptyBottleWeight;
  double? fullBottleWeight;
  String? totalVolume; // napr. "1000ml"
  String? alcoholPercentage;

  // Pre sledovanie zmien a offline režim
  SyncStatus syncStatus;
  String lastEditor;
  DateTime lastEditTimestamp;

  InventoryItem({
    required this.name,
    required this.ean,
    required this.manufacturer,
    required this.time,
    required this.isDispensed,
    this.pieceCount,
    this.weight,
    this.fullBottleCount,
    this.openBottleWeight,
    this.emptyBottleWeight,
    this.fullBottleWeight,
    this.totalVolume,
    this.alcoholPercentage,
    this.syncStatus = SyncStatus.synced,
    this.lastEditor = "Milan",
    required this.lastEditTimestamp,
  });

  // Pomocná metóda na výpočet aktuálneho objemu z váhy
  String get openBottleVolumeDisplay {
    if (!isDispensed || openBottleWeight == null || emptyBottleWeight == null || fullBottleWeight == null || totalVolume == null) {
      return "? ml";
    }
    double liquidWeight = fullBottleWeight! - emptyBottleWeight!;
    double currentLiquidWeight = openBottleWeight! - emptyBottleWeight!;
    double liquidVolume = double.tryParse(totalVolume!.replaceAll('ml', '')) ?? 0;
    
    if (liquidWeight <= 0) return "0 ml";
    
    double currentVolume = (currentLiquidWeight / liquidWeight) * liquidVolume;
    currentVolume = currentVolume.clamp(0, liquidVolume); // Zabezpečí, aby hodnota nebola záporná alebo väčšia ako maximum
    return "${currentVolume.toStringAsFixed(0)}/$totalVolume";
  }
}


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

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odhlásiť sa'),
        content: const Text('Naozaj sa chcete odhlásiť?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Zrušiť')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Odhlásiť', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barová inventúra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Odhlásiť sa',
          ),
        ],
      ),
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
            _buildInfoRow('Stav:', 'Prebieha', color: Colors.green),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EanInputScreen()));
              },
              child: const Text('Pokračovať v inventúre'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                 showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Funkcia nie je dostupná'),
                    content: const Text('História inventúr bude implementovaná v ďalších krokoch.'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                  ),
                );
              },
              child: Text('História inventúr', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- OBRAZOVKA 3 & 5: Zadanie EAN kódu ---
class EanInputScreen extends StatelessWidget {
  const EanInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void _confirmEan(String ean) {
      if (ean == '111') {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddProductScreen(isDispensed: false, ean: ean)));
      } else if (ean == '222') {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddProductScreen(isDispensed: true, ean: ean)));
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SelectNewProductTypeScreen(ean: ean)));
      }
    }

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
            TextField(
              onSubmitted: _confirmEan,
              decoration: const InputDecoration(hintText: 'Zadajte EAN a potvrďte'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _confirmEan('12345'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
              child: const Text('Potvrdiť'),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Funkcia nie je dostupná'),
                    content: const Text('Skener bude implementovaný neskôr.'),
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
class InventoryOverviewScreen extends StatefulWidget {
  const InventoryOverviewScreen({super.key});

  @override
  State<InventoryOverviewScreen> createState() => _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState extends State<InventoryOverviewScreen> {
  late List<InventoryItem> inventoryItems;

  @override
  void initState() {
    super.initState();
    inventoryItems = [
      InventoryItem(name: 'TATRA TEA - Black', ean: '1234567890123', manufacturer: 'Karloff', time: '23:30', isDispensed: true, fullBottleCount: 15, openBottleWeight: 270, emptyBottleWeight: 120, fullBottleWeight: 1430, totalVolume: '1000ml', alcoholPercentage: '52%', lastEditTimestamp: DateTime.now().subtract(const Duration(minutes: 5))),
      InventoryItem(name: 'Horalky Sedita', ean: '1112223334445', manufacturer: 'Sedita', time: '23:31', isDispensed: false, pieceCount: 249, weight: '50g', lastEditTimestamp: DateTime.now().subtract(const Duration(minutes: 4))),
      InventoryItem(name: 'Zlatý bažant radler', ean: '5556667778889', manufacturer: 'Heineken', time: '23:32', isDispensed: true, fullBottleCount: 92, openBottleWeight: 1000, emptyBottleWeight: 500, fullBottleWeight: 1000, totalVolume: '500ml', alcoholPercentage: '0%', lastEditTimestamp: DateTime.now().subtract(const Duration(minutes: 3)), syncStatus: SyncStatus.pending),
    ];
  }

  void _editItem(int index) async {
    final updatedItem = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(item: inventoryItems[index]),
      ),
    );

    if (updatedItem != null) {
      setState(() {
        inventoryItems[index] = updatedItem;
      });
    }
  }

  void _deleteItem(int index) {
    setState(() {
      inventoryItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: inventoryItems.length,
              itemBuilder: (context, index) {
                final item = inventoryItems[index];
                final quantity = item.isDispensed ? '${item.fullBottleCount} ks' : '${item.pieceCount} ks';
                final volume = item.isDispensed ? item.openBottleVolumeDisplay : item.weight;

                return Dismissible(
                  key: Key(item.ean + item.name),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteItem(index);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} zmazané')));
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(item.isDispensed ? Icons.wine_bar_outlined : Icons.inventory_2_outlined),
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EAN: ${item.ean}\nMnožstvo: $quantity (${volume})'),
                        if (item.isDispensed && item.alcoholPercentage != null)
                          Text('${item.alcoholPercentage} ALKOHOL', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: _SyncStatusIcon(status: item.syncStatus),
                    isThreeLine: true,
                    onTap: () => _editItem(index),
                  ),
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

// --- NOVÁ OBRAZOVKA: Úprava existujúceho produktu ---
class EditProductScreen extends StatefulWidget {
  final InventoryItem item;
  const EditProductScreen({super.key, required this.item});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController eanController;
  late TextEditingController manufacturerController;
  late TextEditingController pieceController;
  late TextEditingController fullBottleController;
  late TextEditingController noteController;
  late double openBottleWeight;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    eanController = TextEditingController(text: widget.item.ean);
    manufacturerController = TextEditingController(text: widget.item.manufacturer);
    pieceController = TextEditingController(text: widget.item.pieceCount?.toString() ?? '');
    fullBottleController = TextEditingController(text: widget.item.fullBottleCount?.toString() ?? '');
    openBottleWeight = widget.item.openBottleWeight ?? widget.item.emptyBottleWeight ?? 0;
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    eanController.dispose();
    manufacturerController.dispose();
    pieceController.dispose();
    fullBottleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedItem = widget.item;
    updatedItem.name = nameController.text;
    updatedItem.ean = eanController.text;
    updatedItem.manufacturer = manufacturerController.text;
    updatedItem.lastEditor = "Milan";
    updatedItem.lastEditTimestamp = DateTime.now();
    updatedItem.syncStatus = SyncStatus.pending;

    if (widget.item.isDispensed) {
      updatedItem.fullBottleCount = int.tryParse(fullBottleController.text) ?? widget.item.fullBottleCount;
      updatedItem.openBottleWeight = openBottleWeight;
    } else {
      updatedItem.pieceCount = int.tryParse(pieceController.text) ?? widget.item.pieceCount;
    }
    Navigator.of(context).pop(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFieldWithController('Názov produktu', nameController),
              _buildTextFieldWithController('EAN kód produktu', eanController, keyboardType: TextInputType.number),
              _buildTextFieldWithController('Výrobca', manufacturerController),
              const SizedBox(height: 30),
              if (widget.item.isDispensed) ...[
                _buildTextFieldWithController('Počet plných fliaš', fullBottleController, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Text('Otvorená fľaša (${openBottleWeight.toStringAsFixed(0)} g)', style: const TextStyle(color: Colors.white70)),
                Slider(
                  value: openBottleWeight,
                  min: widget.item.emptyBottleWeight ?? 0,
                  max: widget.item.fullBottleWeight ?? 1,
                  onChanged: (value) {
                    setState(() {
                      openBottleWeight = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${widget.item.emptyBottleWeight?.toStringAsFixed(0) ?? 0} g (prázdna)'),
                    Text('${widget.item.fullBottleWeight?.toStringAsFixed(0) ?? 1} g (plná)'),
                  ],
                ),
              ] else ...[
                _buildTextFieldWithController('Počet na sklade (ks)', pieceController, keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 40),
              _buildHistorySection(),
              const SizedBox(height: 20),
              _buildTextFieldWithController('Poznámka k zmene (nepovinné)', noteController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Uložiť zmeny'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('História zmien', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Posledná úprava: ${widget.item.lastEditor}'),
          Text('Čas: ${widget.item.lastEditTimestamp.hour}:${widget.item.lastEditTimestamp.minute.toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }
}


// --- OBRAZOVKY 8-11: Pridanie existujúceho produktu ---
class AddProductScreen extends StatelessWidget {
  final bool isDispensed;
  final String ean;
  const AddProductScreen({super.key, required this.isDispensed, required this.ean});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('EAN kód produktu', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              Text(ean, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Pridať produkt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- OBRAZOVKA 12 & 13: Výber typu nového produktu ---
class SelectNewProductTypeScreen extends StatelessWidget {
  final String ean;
  const SelectNewProductTypeScreen({super.key, required this.ean});

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
            Text(ean, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Uistite sa, že je EAN kód produktu správny', style: TextStyle(color: Colors.white70)),
            const Spacer(),
            _buildProductTypeButton(
              context: context,
              icon: Icons.inventory_2_outlined,
              label: 'Kusový predaj',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreatePieceProductScreen(ean: ean))),
            ),
            const SizedBox(height: 16),
            _buildProductTypeButton(
              context: context,
              icon: Icons.wine_bar_outlined,
              label: 'Rozlievaný produkt',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateDispensedProductScreenStep1(ean: ean))),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeButton({required BuildContext context, required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C2E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// --- OBRAZOVKA 14: Vytvorenie rozlievaného produktu (Krok 1) ---
class CreateDispensedProductScreenStep1 extends StatelessWidget {
  final String ean;
  const CreateDispensedProductScreenStep1({super.key, required this.ean});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReadOnlyField('EAN kód produktu', ean),
              _buildTextField('Názov', 'TATRA TEA'),
              _buildTextField('Výrobca', 'TATRA TEA'),
              _buildTextField('Objem fľaše', '1000 ml', keyboardType: TextInputType.number),
              _buildTextField('Alkohol (%)', '60%', keyboardType: TextInputType.number),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateDispensedProductScreenStep2())),
                child: const Text('Ďalej'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- OBRAZOVKA 15: Vytvorenie rozlievaného produktu (Krok 2) ---
class CreateDispensedProductScreenStep2 extends StatelessWidget {
  const CreateDispensedProductScreenStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Počet plných fliaš', '? ks', keyboardType: TextInputType.number),
              _buildTextField('Otvorená fľaša', '? g', keyboardType: TextInputType.number),
              Row(
                children: [
                  Expanded(child: _buildTextField('Prázdna fľaša', '120 g', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Plná fľaša', '1430 g', keyboardType: TextInputType.number)),
                ],
              ),
              _buildTextField('Tolerancia', '10 ml', keyboardType: TextInputType.number),
              _buildTextField('Dodatočné údaje', 'Nie je potrebné vyplniť', required: false),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                },
                child: const Text('Pridať produkt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- OBRAZOVKA 16: Vytvorenie kusového produktu ---
class CreatePieceProductScreen extends StatelessWidget {
  final String ean;
  const CreatePieceProductScreen({super.key, required this.ean});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReadOnlyField('EAN kód produktu', ean),
              _buildTextField('Názov produktu', 'Horalky'),
              _buildTextField('Výrobca produktu', 'Sedita'),
              _buildTextField('Počet ks', '? ks', keyboardType: TextInputType.number),
              _buildTextField('Váha', '? g', keyboardType: TextInputType.number),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                },
                child: const Text('Vytvoriť nový produkt'),
              ),
            ],
          ),
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

PreferredSizeWidget _buildTopBarWithIds({bool showBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: showBackButton,
    title: const Column(
      children: [
        Text('BAROVÁ inventúra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('API ID: 123 456', style: TextStyle(fontSize: 12, color: Colors.white70)),
        SizedBox(height: 4),
        Text('ID inventúry: 123 456 789 1011', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    ),
  );
}

Widget _buildTextField(String label, String hint, {TextInputType keyboardType = TextInputType.text, bool required = true}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + (required ? '' : ' (nepovinné)'), style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextFormField(decoration: InputDecoration(hintText: hint), keyboardType: keyboardType),
      ],
    ),
  );
}

Widget _buildTextFieldWithController(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, decoration: InputDecoration(hintText: controller.text), keyboardType: keyboardType),
      ],
    ),
  );
}

Widget _buildReadOnlyField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class _SyncStatusIcon extends StatelessWidget {
  final SyncStatus status;
  const _SyncStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.synced:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncStatus.pending:
        return const Icon(Icons.cloud_upload_outlined, color: Colors.amber);
      case SyncStatus.failed:
        return const Icon(Icons.cloud_off, color: Colors.red);
    }
  }
}
