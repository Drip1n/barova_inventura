import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

// =========================================================================
// SIMULATED DATABASE AND DATA MODELS
// =========================================================================

class User {
  String apiId;
  String password;
  String inventoryId;
  List<InventoryItem> inventory;

  User({required this.apiId, required this.password, required this.inventoryId, List<InventoryItem>? inventory})
      : inventory = inventory ?? [];
}

class InventoryItem {
  String name;
  String ean;
  String manufacturer;
  String unit;
  double? alcoholPercentage;
  String? note;
  String lastModifiedBy;
  DateTime lastModifiedDate;

  bool isDispensed;

  int? pieceCount;
  double? weight;

  int? fullBottleCount;
  double? openBottleVolume;
  double? totalBottleVolume;
  double? emptyBottleWeight;
  double? fullBottleWeight;

  InventoryItem({
    required this.name,
    required this.ean,
    required this.manufacturer,
    required this.unit,
    this.alcoholPercentage,
    this.note,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.isDispensed,
    this.pieceCount,
    this.weight,
    this.fullBottleCount,
    this.openBottleVolume,
    this.totalBottleVolume,
    this.emptyBottleWeight,
    this.fullBottleWeight,
  });

  InventoryItem copy() {
    return InventoryItem(
      name: name,
      ean: ean,
      manufacturer: manufacturer,
      unit: unit,
      alcoholPercentage: alcoholPercentage,
      note: note,
      lastModifiedBy: lastModifiedBy,
      lastModifiedDate: lastModifiedDate,
      isDispensed: isDispensed,
      pieceCount: pieceCount,
      weight: weight,
      fullBottleCount: fullBottleCount,
      openBottleVolume: openBottleVolume,
      totalBottleVolume: totalBottleVolume,
      emptyBottleWeight: emptyBottleWeight,
      fullBottleWeight: fullBottleWeight,
    );
  }
}

class SimulatedDatabase {
  static final SimulatedDatabase _instance = SimulatedDatabase._internal();
  factory SimulatedDatabase() => _instance;

  SimulatedDatabase._internal();

  final Map<String, User> _users = {};
  User? currentUser;

  void registerUser(String apiId, String password) {
    if (!_users.containsKey(apiId)) {
      _users[apiId] = User(apiId: apiId, password: password, inventoryId: '123 456 789 1011', inventory: _getInitialInventory());
    }
  }

  bool loginUser(String apiId, String password) {
    final user = _users[apiId];
    if (user != null && user.password == password) {
      currentUser = user;
      return true;
    }
    return false;
  }

  void logoutUser() {
    currentUser = null;
  }

  List<InventoryItem> getInventory() {
    return currentUser?.inventory ?? [];
  }

  void deleteItem(String ean) {
    currentUser?.inventory.removeWhere((item) => item.ean == ean);
  }

  void updateItem(InventoryItem updatedItem) {
    if (currentUser == null) return;
    int index = currentUser!.inventory.indexWhere((item) => item.ean == updatedItem.ean);
    if (index != -1) {
      currentUser!.inventory[index] = updatedItem;
    }
  }

  void addItem(InventoryItem newItem) {
    if (currentUser == null) return;
    currentUser!.inventory.add(newItem);
  }

  List<InventoryItem> _getInitialInventory() {
    return [
      InventoryItem(
        name: 'TATRA TEA - Black',
        ean: '222',
        manufacturer: 'Karloff',
        unit: 'ml',
        isDispensed: true,
        fullBottleCount: 15,
        openBottleVolume: 550,
        totalBottleVolume: 700,
        emptyBottleWeight: 400,
        fullBottleWeight: 1100,
        alcoholPercentage: 52,
        lastModifiedBy: 'admin',
        lastModifiedDate: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      InventoryItem(
        name: 'Horalky Sedita',
        ean: '111',
        manufacturer: 'Sedita',
        unit: 'ks',
        isDispensed: false,
        pieceCount: 249,
        weight: 50,
        lastModifiedBy: 'admin',
        lastModifiedDate: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
       InventoryItem(
        name: 'Zlatý Bažant Radler',
        ean: '333',
        manufacturer: 'Heineken',
        unit: 'ml',
        isDispensed: true,
        fullBottleCount: 92,
        openBottleVolume: 500,
        totalBottleVolume: 500,
        emptyBottleWeight: 20,
        fullBottleWeight: 520,
        alcoholPercentage: 0,
        lastModifiedBy: 'admin',
        lastModifiedDate: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }
}

void main() {
  runApp(const BarovaInventuraApp());
}

// =========================================================================
// APP THEME AND CONFIGURATION
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
        primaryColor: const Color(0xFF0D69FD), // Blue for buttons
        scaffoldBackgroundColor: const Color(0xFF000000), // Black background as per PDF
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
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
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
// APP SCREENS
// =========================================================================

// --- Screen 1: Login ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = SimulatedDatabase();

  @override
  void initState() {
    super.initState();
    // For easier testing
    _apiIdController.text = 'admin';
    _passwordController.text = 'admin';
    if (_db._users.isEmpty) {
        _db.registerUser('admin', 'admin');
    }
  }

  void _login() {
    if (_db.loginUser(_apiIdController.text, _passwordController.text)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Nesprávne API ID alebo heslo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/images/Barova_Inventura_Logo.png', height: 100),
              const Spacer(),
              _buildTextFieldWithController('API ID:', _apiIdController, isLogin: true),
              const SizedBox(height: 20),
              _buildTextFieldWithController('Heslo:', _passwordController, obscureText: true, isLogin: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                  onPressed: _login,
                  child: const Text('Prihlásiť sa'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2E), foregroundColor: Colors.white),
                  onPressed: () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
                  },
                  child: const Text('Vytvoriť nový účet'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 1.5: Registration ---
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _apiIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = SimulatedDatabase();

  void _register() {
    if (_apiIdController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      _db.registerUser(_apiIdController.text, _passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Účet úspešne vytvorený! Môžete sa prihlásiť.'),
        ),
      );
      Navigator.of(context).pop();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('API ID a heslo nemôžu byť prázdne.'),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/Barova_Inventura_Logo.png', height: 100),
            const Spacer(),
            _buildTextFieldWithController('Zadajte nové API ID:', _apiIdController, isLogin: true),
             const SizedBox(height: 20),
            _buildTextFieldWithController('Zadajte nové Heslo:', _passwordController, obscureText: true, isLogin: true),
            const Spacer(),
            ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              onPressed: _register,
              child: const Text('Zaregistrovať sa'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- Screen 2: Home Dashboard ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final user = SimulatedDatabase().currentUser;
    final statusText = user?.inventory.isEmpty ?? true ? 'Nová inventúra' : 'Prebieha';
    final bool isSynced = true; 

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/images/Barova_Inventura_Logo.png', height: 100),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(8.0)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Novinky a aktuality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 8),
                    Text('Integer mauris sem, convallis ut, consequat in, sollicitudin sed, leo. Cras purus elit, hendrerit ut.', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8.0)
                ),
                child: Column(
                  children: [
                     _buildHomeInfoRow('API ID:', user?.apiId ?? 'N/A'),
                     const Divider(color: Colors.white24, height: 24),
                     _buildHomeInfoRow('ID inventúry:', user?.inventoryId ?? 'N/A'),
                     const Divider(color: Colors.white24, height: 24),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stav:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Row(
                          children: [
                            Text(statusText, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Icon(isSynced ? Icons.cloud_done : Icons.cloud_off, color: isSynced ? Colors.greenAccent : Colors.redAccent, size: 20),
                          ],
                        )
                      ],
                     )
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EanInputScreen()));
                },
                child: Text(user?.inventory.isEmpty ?? true ? 'Začať inventúru' : 'Pokračovať v inventúre'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text('História inventúr', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              ),
               const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 3: EAN Input ---
class EanInputScreen extends StatefulWidget {
  const EanInputScreen({super.key});

  @override
  State<EanInputScreen> createState() => _EanInputScreenState();
}

class _EanInputScreenState extends State<EanInputScreen> {
  final _eanController = TextEditingController();

  void _confirmEan(String ean) {
    if (ean.isEmpty) return;
    
    final existingItem = SimulatedDatabase().getInventory().firstWhere(
          (item) => item.ean == ean,
          orElse: () => InventoryItem(ean: '', name: '', manufacturer: '', unit: '', isDispensed: false, lastModifiedBy: '', lastModifiedDate: DateTime.now())
    );

    if (existingItem.ean.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => EditProductScreen(item: existingItem.copy()))
      ).then((_) => setState(() {}));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SelectNewProductTypeScreen(ean: ean))
      ).then((_) => setState(() {}));
    }
    _eanController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(title: ' '), // Empty title for spacing
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                onPressed: () {}, // TODO: Add scanner logic later
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/Camera_Black.png', height: 40),
                    const SizedBox(height: 8),
                    const Text('Naskenovať EAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                )
              ),
            ),
            const SizedBox(height: 24),
            const Text('Zadať EAN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _eanController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '...'
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _confirmEan(_eanController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Potvrdiť'),
            ),
            const SizedBox(height: 16),
             ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InventoryOverviewScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: const Text('Prehľad inventúry'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- Screen 6 & 7: Inventory Overview ---
class InventoryOverviewScreen extends StatefulWidget {
  const InventoryOverviewScreen({super.key});

  @override
  State<InventoryOverviewScreen> createState() => _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState extends State<InventoryOverviewScreen> {
  final _db = SimulatedDatabase();
  List<InventoryItem> _filteredItems = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = _db.getInventory();
    _searchController.addListener(() {
      _filterItems();
    });
  }
  
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _db.getInventory().where((item) {
        return item.name.toLowerCase().contains(query) || item.ean.contains(query);
      }).toList();
    });
  }

  void _editItem(InventoryItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(item: item.copy()),
      ),
    );
    _filterItems(); 
  }
  
  void _deleteItem(String ean) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vymazať položku'),
        content: const Text('Naozaj chcete natrvalo vymazať túto položku?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Zrušiť')),
          TextButton(
            onPressed: () {
              setState(() {
                _db.deleteItem(ean);
                _filterItems();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Vymazať', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hľadať podľa názvu alebo EAN...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
            ? const Center(child: Text('Žiadne položky v inventári.'))
            : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildInventoryItemCard(_filteredItems[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SuccessScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Dokončiť inventúru'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(InventoryItem item) {
    bool isSynced = true; // Placeholder
    String formattedTime = DateFormat('HH:mm').format(item.lastModifiedDate);
    
    return Card(
      color: const Color(0xFF2C2C2E),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _editItem(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SvgPicture.asset(
                item.isDispensed ? 'assets/icons/Bottled.svg' : 'assets/icons/Packed.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.ean, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                     const SizedBox(height: 4),
                    Text(
                      item.isDispensed
                          ? '${item.openBottleVolume?.toStringAsFixed(0)} / ${item.totalBottleVolume?.toStringAsFixed(0)} ${item.unit}'
                          : '${item.weight?.toStringAsFixed(0)} g',
                      style: const TextStyle(color: Colors.white, fontSize: 14)
                    ),
                    const SizedBox(height: 4),
                     Text(
                      '${item.isDispensed ? item.fullBottleCount : item.pieceCount} ks',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.isDispensed && item.alcoholPercentage != null && item.alcoholPercentage! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        '${item.alcoholPercentage?.toStringAsFixed(0)}% ALK',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    )
                  else 
                    const SizedBox(height: 20), // Placeholder to keep alignment
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Icon(isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: isSynced ? Colors.greenAccent : Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(formattedTime, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}


// --- Screen: Edit Existing Product ---
class EditProductScreen extends StatefulWidget {
  final InventoryItem item;
  const EditProductScreen({super.key, required this.item});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late InventoryItem _editableItem;
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();
  final _eanController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _pieceCountController = TextEditingController();
  final _fullBottleCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editableItem = widget.item.copy();
    _noteController.text = _editableItem.note ?? '';
    _nameController.text = _editableItem.name;
    _eanController.text = _editableItem.ean;
    _manufacturerController.text = _editableItem.manufacturer;
    _pieceCountController.text = _editableItem.pieceCount?.toString() ?? '';
    _fullBottleCountController.text = _editableItem.fullBottleCount?.toString() ?? '';
  }

  void _saveChanges() {
    _editableItem.note = _noteController.text;
    _editableItem.name = _nameController.text;
    _editableItem.ean = _eanController.text;
    _editableItem.manufacturer = _manufacturerController.text;
    _editableItem.lastModifiedBy = SimulatedDatabase().currentUser?.apiId ?? 'unknown';
    _editableItem.lastModifiedDate = DateTime.now();
    
    if (_editableItem.isDispensed) {
       _editableItem.fullBottleCount = int.tryParse(_fullBottleCountController.text) ?? 0;
    } else {
       _editableItem.pieceCount = int.tryParse(_pieceCountController.text) ?? 0;
    }

    SimulatedDatabase().updateItem(_editableItem);
    Navigator.of(context).pop();
  }

  @override
  void dispose(){
    _noteController.dispose();
    _nameController.dispose();
    _eanController.dispose();
    _manufacturerController.dispose();
    _pieceCountController.dispose();
    _fullBottleCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sliderMin = _editableItem.emptyBottleWeight ?? 0.0;
    final sliderMax = _editableItem.fullBottleWeight ?? (sliderMin + 1.0);
    final sliderValue = (_editableItem.openBottleVolume ?? sliderMin).clamp(sliderMin, sliderMax);

    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true, title: 'Upraviť produkt'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFieldWithController('Názov produktu', _nameController),
              _buildTextFieldWithController('EAN kód produktu', _eanController, keyboardType: TextInputType.number),
              _buildTextFieldWithController('Výrobca', _manufacturerController),
              const SizedBox(height: 30),

              if (_editableItem.isDispensed) ...[
                _buildTextFieldWithController('Počet plných fliaš (ks)', _fullBottleCountController, keyboardType: TextInputType.number),
                 const SizedBox(height: 20),
                Text('Stav otvorenej fľaše (${sliderValue.toStringAsFixed(0)} / ${_editableItem.fullBottleWeight?.toStringAsFixed(0) ?? 1000} g)'),
                 Slider(
                  value: sliderValue,
                  min: sliderMin,
                  max: sliderMax,
                  onChanged: (value) {
                    setState(() {
                      _editableItem.openBottleVolume = value;
                    });
                  },
                  label: '${sliderValue.toStringAsFixed(0)} g',
                  divisions: 100,
                ),
              ] else ...[
                _buildTextFieldWithController('Počet na sklade (ks)', _pieceCountController, keyboardType: TextInputType.number),
              ],
              
              const SizedBox(height: 30),
              _buildTextFieldWithController('Poznámka k zmene', _noteController),
              const SizedBox(height: 10),
              _buildReadOnlyField('Posledná úprava', '${DateFormat('dd.MM.yyyy HH:mm').format(_editableItem.lastModifiedDate)} (${_editableItem.lastModifiedBy})'),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                child: const Text('Uložiť zmeny'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 12 & 13: Select New Product Type ---
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
            _buildReadOnlyField('EAN kód produktu', ean),
            const Text('Produkt s týmto EAN kódom nebol nájdený. Vytvorte nový.', style: TextStyle(color: Colors.white70)),
            const Spacer(),
            _buildProductTypeButton(
              context: context,
              iconPath: 'assets/icons/Packed_Black.svg',
              label: 'Kusový predaj',
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => CreatePieceProductScreen(ean: ean))),
            ),
            const SizedBox(height: 16),
            _buildProductTypeButton(
              context: context,
              iconPath: 'assets/icons/Bottled_Black.svg',
              label: 'Rozlievaný produkt',
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => CreateDispensedProductScreenStep1(ean: ean))),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeButton({required BuildContext context, required String iconPath, required String label, required VoidCallback onPressed}) {
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
          SvgPicture.asset(iconPath, width: 28, height: 28, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// --- Screen 14 & 15: Create Dispensed Product ---
class CreateDispensedProductScreenStep1 extends StatefulWidget {
  final String ean;
  const CreateDispensedProductScreenStep1({super.key, required this.ean});

  @override
  State<CreateDispensedProductScreenStep1> createState() => _CreateDispensedProductScreenStep1State();
}

class _CreateDispensedProductScreenStep1State extends State<CreateDispensedProductScreenStep1> {
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _volumeController = TextEditingController();
  final _alcoholController = TextEditingController();
  final _emptyWeightController = TextEditingController();
  final _fullWeightController = TextEditingController();
  
  void _createAndAddItem() {
      final newItem = InventoryItem(
        name: _nameController.text,
        ean: widget.ean,
        manufacturer: _manufacturerController.text,
        unit: 'ml',
        isDispensed: true,
        totalBottleVolume: double.tryParse(_volumeController.text) ?? 0,
        alcoholPercentage: double.tryParse(_alcoholController.text) ?? 0,
        emptyBottleWeight: double.tryParse(_emptyWeightController.text) ?? 0,
        fullBottleWeight: double.tryParse(_fullWeightController.text) ?? 0,
        fullBottleCount: 0,
        openBottleVolume: double.tryParse(_emptyWeightController.text) ?? 0, // Starts empty
        lastModifiedBy: SimulatedDatabase().currentUser?.apiId ?? 'unknown',
        lastModifiedDate: DateTime.now(),
      );
      SimulatedDatabase().addItem(newItem);
      Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true, title: 'Nový rozlievaný produkt'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReadOnlyField('EAN kód produktu', widget.ean),
              _buildTextFieldWithController('Názov', _nameController),
              _buildTextFieldWithController('Výrobca', _manufacturerController),
              _buildTextFieldWithController('Objem fľaše (ml)', _volumeController, keyboardType: TextInputType.number),
              _buildTextFieldWithController('Alkohol (%)', _alcoholController, keyboardType: TextInputType.number),
              _buildTextFieldWithController('Prázdna fľaša (g)', _emptyWeightController, keyboardType: TextInputType.number),
              _buildTextFieldWithController('Plná fľaša (g)', _fullWeightController, keyboardType: TextInputType.number),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _createAndAddItem,
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                child: const Text('Vytvoriť a pridať do inventúry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 16: Create Piece Product ---
class CreatePieceProductScreen extends StatefulWidget {
  final String ean;
  const CreatePieceProductScreen({super.key, required this.ean});

  @override
  State<CreatePieceProductScreen> createState() => _CreatePieceProductScreenState();
}

class _CreatePieceProductScreenState extends State<CreatePieceProductScreen> {
    final _nameController = TextEditingController();
    final _manufacturerController = TextEditingController();
    final _weightController = TextEditingController();

    void _createAndAddItem() {
      final newItem = InventoryItem(
        name: _nameController.text,
        ean: widget.ean,
        manufacturer: _manufacturerController.text,
        unit: 'ks',
        isDispensed: false,
        weight: double.tryParse(_weightController.text) ?? 0,
        pieceCount: 0,
        lastModifiedBy: SimulatedDatabase().currentUser?.apiId ?? 'unknown',
        lastModifiedDate: DateTime.now(),
      );
      SimulatedDatabase().addItem(newItem);
      Navigator.of(context).pop();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true, title: 'Nový kusový produkt'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReadOnlyField('EAN kód produktu', widget.ean),
              _buildTextFieldWithController('Názov produktu', _nameController),
              _buildTextFieldWithController('Výrobca produktu', _manufacturerController),
              _buildTextFieldWithController('Váha (g)', _weightController, keyboardType: TextInputType.number),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _createAndAddItem,
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                child: const Text('Vytvoriť a pridať do inventúry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 17: Success ---
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
            SvgPicture.asset('assets/icons/Done.svg', width: 100, height: 100),
            const SizedBox(height: 20),
            const Text('Inventúra úspešne\ndokončená', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Späť na domov'),
            ),
             const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2E), foregroundColor: Colors.white),
              onPressed: () {
                 SimulatedDatabase().logoutUser();
                 Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Odhlásiť sa'),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// HELPER WIDGETS
// =========================================================================

PreferredSizeWidget _buildTopBarWithIds({bool showBackButton = false, String? title}) {
  final user = SimulatedDatabase().currentUser;
  return AppBar(
    leading: showBackButton ? const BackButton() : null,
    titleSpacing: showBackButton ? 0 : 24,
    title: Row(
      children: [
        if (showBackButton) 
          const Text('Nazad', style: TextStyle(fontSize: 16))
        else if (title != null)
           Text(title),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('API ID: ${user?.apiId ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text('ID Inventúry: ${user?.inventoryId ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        )
      ],
    ),
  );
}

Widget _buildTextFieldWithController(String label, TextEditingController controller, {bool obscureText = false, bool isLogin = false, TextInputType? keyboardType}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.white, fontSize: isLogin ? 18 : 14, fontWeight: isLogin ? FontWeight.w500: FontWeight.normal)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: 'zadajte ${label.toLowerCase().replaceAll(':', '')}',
        ),
      ),
    ],
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

Widget _buildHomeInfoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}