import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// =========================================================================
// SIMULOVANÁ LOKÁLNA DATABÁZA A AUTENTIFIKÁCIA
// =========================================================================

// --- User Model ---
class User {
  String apiId;
  String password;
  User({required this.apiId, required this.password});
}

// --- Auth & Database Service ---
class FakeDatabase {
  static final FakeDatabase _instance = FakeDatabase._internal();
  factory FakeDatabase() => _instance;
  FakeDatabase._internal();

  // Data is now stored per user (apiId)
  final Map<String, List<InventoryItem>> _userInventoryData = {};
  final List<User> _users = [];
  User? _currentUser;

  // --- Auth Methods ---
  User? get currentUser => _currentUser;

  Future<bool> register(String apiId, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (apiId.isEmpty || password.isEmpty) return false;
    if (_users.any((user) => user.apiId == apiId)) {
      return false; // User already exists
    }
    _users.add(User(apiId: apiId, password: password));
    _userInventoryData[apiId] = []; // Create an empty inventory list for the new user
    return true;
  }

  Future<bool> login(String apiId, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    final user = _users.where((u) => u.apiId == apiId && u.password == password).firstOrNull;
    if (user != null) {
      _currentUser = user;
      // If user has no data yet, initialize it
      if (!_userInventoryData.containsKey(apiId)) {
         _initializeDataForUser(apiId);
      }
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    // Data is NOT cleared on logout
  }

  // --- Data Methods ---
  void _initializeDataForUser(String apiId) {
    // Populate with sample data only if the list is new/empty for this user
     _userInventoryData[apiId] = [
        InventoryItem(name: 'TATRA TEA - Black', ean: '1234567890123', manufacturer: 'Karloff', time: '23:30', isDispensed: true, fullBottleCount: 15, openBottleWeight: 270, emptyBottleWeight: 120, fullBottleWeight: 1430, totalVolume: '1000ml', alcoholPercentage: '52%', lastEditTimestamp: DateTime.now().subtract(const Duration(minutes: 5))),
        InventoryItem(name: 'Horalky Sedita', ean: '1112223334445', manufacturer: 'Sedita', time: '23:31', isDispensed: false, pieceCount: 249, weight: '50g', lastEditTimestamp: DateTime.now().subtract(const Duration(minutes: 4))),
     ];
  }

  List<InventoryItem> getItems() {
    if (_currentUser == null) return [];
    return _userInventoryData[_currentUser!.apiId] ?? [];
  }

  void addItem(InventoryItem item) {
    if (_currentUser == null) return;
    getItems().insert(0, item);
  }

  void updateItem(String originalEan, InventoryItem updatedItem) {
     if (_currentUser == null) return;
    final userItems = getItems();
    final index = userItems.indexWhere((item) => item.ean == originalEan);
    if (index != -1) {
      userItems[index] = updatedItem;
    }
  }

  void deleteItem(String ean) {
    if (_currentUser == null) return;
    getItems().removeWhere((item) => item.ean == ean);
  }
}

// ENUM pre stavy synchronizácie
enum SyncStatus { synced, pending, failed }

// Dátový model pre položku v inventári
class InventoryItem {
  String name;
  String ean;
  String manufacturer;
  String time;
  bool isDispensed;
  int? pieceCount;
  String? weight;
  int? fullBottleCount;
  double? openBottleWeight;
  double? emptyBottleWeight;
  double? fullBottleWeight;
  String? totalVolume;
  String? alcoholPercentage;
  SyncStatus syncStatus;
  String lastEditor;
  DateTime lastEditTimestamp;
  String? lastEditNote; // New field for the note

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
    this.lastEditor = "Systém",
    required this.lastEditTimestamp,
    this.lastEditNote,
  });

  String get openBottleVolumeDisplay {
    if (!isDispensed || openBottleWeight == null || emptyBottleWeight == null || fullBottleWeight == null || totalVolume == null) return "? ml";
    double liquidWeight = fullBottleWeight! - emptyBottleWeight!;
    if (liquidWeight <= 0) return "0 ml";
    double currentLiquidWeight = openBottleWeight! - emptyBottleWeight!;
    double liquidVolume = double.tryParse(totalVolume!.replaceAll('ml', '')) ?? 0;
    double currentVolume = (currentLiquidWeight / liquidWeight) * liquidVolume;
    currentVolume = currentVolume.clamp(0, liquidVolume);
    return "${currentVolume.toStringAsFixed(0)}/$totalVolume";
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5A623), foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = FakeDatabase();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final success = await _db.login(_apiIdController.text, _passwordController.text);
    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nesprávne API ID alebo heslo.'), backgroundColor: Colors.red));
      }
    }
     if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AppLogo(),
                  const SizedBox(height: 60),
                  _buildTextFieldWithController('API ID', _apiIdController, hint: 'Zadajte API ID'),
                  _buildTextFieldWithController('Heslo', _passwordController, obscureText: true, hint: 'Zadajte heslo'),
                  const SizedBox(height: 40),
                  if (_isLoading) const Center(child: CircularProgressIndicator()) else ElevatedButton(
                    onPressed: _login,
                    child: const Text('Prihlásiť sa'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                     onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen())),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                     child: const Text('Vytvoriť nový účet'),
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _apiIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _db = FakeDatabase();
  bool _isLoading = false;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heslá sa nezhodujú.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    final success = await _db.register(_apiIdController.text, _passwordController.text);
    if(mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Účet úspešne vytvorený! Môžete sa prihlásiť.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Účet s týmto API ID už existuje alebo sú polia prázdne.'), backgroundColor: Colors.red));
      }
    }
     if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vytvoriť účet')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildTextFieldWithController('Zadajte API ID', _apiIdController),
              _buildTextFieldWithController('Zadajte heslo', _passwordController, obscureText: true),
              _buildTextFieldWithController('Potvrďte heslo', _confirmPasswordController, obscureText: true),
              const SizedBox(height: 40),
              if (_isLoading) const Center(child: CircularProgressIndicator()) else ElevatedButton(
                onPressed: _register,
                child: const Text('Registrovať'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Odhlásiť sa'), content: const Text('Naozaj sa chcete odhlásiť?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Zrušiť')),
          TextButton(
            onPressed: () {
              FakeDatabase().logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
            child: const Text('Odhlásiť', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FakeDatabase().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barová inventúra'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context), tooltip: 'Odhlásiť sa')],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             _buildInfoRow('API ID:', user?.apiId ?? 'N/A'),
            const SizedBox(height: 16),
            _buildInfoRow('ID inventúry:', '123 456 789 1011'),
            _buildInfoRow('Stav:', 'Prebieha', color: Colors.green),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EanInputScreen())),
              child: const Text('Pokračovať v inventúre'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('Funkcia nie je dostupná'),
                    content: const Text('História inventúr bude implementovaná v ďalších krokoch.'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                  ),
                ),
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

class EanInputScreen extends StatelessWidget {
  const EanInputScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final eanController = TextEditingController();

    void _confirmEan(String ean) {
      if (ean.isEmpty) return;
      final db = FakeDatabase();
      final existingItem = db.getItems().where((item) => item.ean == ean).firstOrNull;

      if (existingItem != null) {
        // For now, let's navigate to the overview screen.
         Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InventoryOverviewScreen()));
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SelectNewProductTypeScreen(ean: ean)));
      }
    }

    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true), // Added back button
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Text('Zadať EAN', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: eanController,
              onSubmitted: _confirmEan, decoration: const InputDecoration(hintText: 'Zadajte EAN a potvrďte'), keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _confirmEan(eanController.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
              child: const Text('Potvrdiť'),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('Funkcia nie je dostupná'), content: const Text('Skener bude implementovaný neskôr.'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                  ),
                ),
              icon: const Icon(Icons.qr_code_scanner), label: const Text('Naskenovať EAN'),
            ),
            const Spacer(flex: 2),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InventoryOverviewScreen())),
                child: Text('Prehľad inventúry', style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryOverviewScreen extends StatefulWidget {
  const InventoryOverviewScreen({super.key});
  @override
  State<InventoryOverviewScreen> createState() => _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState extends State<InventoryOverviewScreen> {
  final db = FakeDatabase();
  late List<InventoryItem> filteredItems;

  @override
  void initState() {
    super.initState();
    filteredItems = db.getItems();
  }
  
  void _refreshList() {
    setState(() {
      filteredItems = db.getItems();
    });
  }

  void _editItem(InventoryItem item) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => EditProductScreen(item: item)),
    );
    if (result == true) _refreshList();
  }

  void _deleteItem(InventoryItem item) {
    db.deleteItem(item.ean);
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBarWithIds(showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Dismissible(
                  key: Key(item.ean + Random().toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} zmazané')));
                  },
                  background: Container(
                    color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(item.isDispensed ? Icons.wine_bar_outlined : Icons.inventory_2_outlined),
                    title: Text(item.name),
                    subtitle: Text('EAN: ${item.ean}\nMnožstvo: ${item.isDispensed ? '${item.fullBottleCount} ks' : '${item.pieceCount} ks'} (${item.isDispensed ? item.openBottleVolumeDisplay : item.weight})'),
                    trailing: _SyncStatusIcon(status: item.syncStatus),
                    isThreeLine: true,
                    onTap: () => _editItem(item),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SuccessScreen())),
              child: const Text('Dokončiť inventúru'),
            ),
          )
        ],
      ),
    );
  }
}

class EditProductScreen extends StatefulWidget {
  final InventoryItem item;
  const EditProductScreen({super.key, required this.item});
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final db = FakeDatabase();
  late TextEditingController nameController, eanController, manufacturerController, pieceController, fullBottleController, noteController;
  late double openBottleWeight;
  late String originalEan;

  @override
  void initState() {
    super.initState();
    originalEan = widget.item.ean;
    nameController = TextEditingController(text: widget.item.name);
    eanController = TextEditingController(text: widget.item.ean);
    manufacturerController = TextEditingController(text: widget.item.manufacturer);
    pieceController = TextEditingController(text: widget.item.pieceCount?.toString() ?? '');
    fullBottleController = TextEditingController(text: widget.item.fullBottleCount?.toString() ?? '');
    openBottleWeight = widget.item.openBottleWeight ?? widget.item.emptyBottleWeight ?? 0;
    noteController = TextEditingController(text: widget.item.lastEditNote);
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
    updatedItem.lastEditor = FakeDatabase().currentUser?.apiId ?? "Neznámy";
    updatedItem.lastEditTimestamp = DateTime.now();
    updatedItem.syncStatus = SyncStatus.pending;
    updatedItem.lastEditNote = noteController.text; // Save the note

    if (widget.item.isDispensed) {
      updatedItem.fullBottleCount = int.tryParse(fullBottleController.text) ?? widget.item.fullBottleCount;
      updatedItem.openBottleWeight = openBottleWeight;
    } else {
      updatedItem.pieceCount = int.tryParse(pieceController.text) ?? widget.item.pieceCount;
    }
    db.updateItem(originalEan, updatedItem);
    Navigator.of(context).pop(true);
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
                  value: openBottleWeight, min: widget.item.emptyBottleWeight ?? 0, max: widget.item.fullBottleWeight ?? 1,
                  onChanged: (value) => setState(() => openBottleWeight = value), activeColor: Theme.of(context).primaryColor,
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
              ElevatedButton(onPressed: _saveChanges, child: const Text('Uložiť zmeny')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('História zmien', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Posledná úprava: ${widget.item.lastEditor}'),
          Text('Čas: ${widget.item.lastEditTimestamp.hour}:${widget.item.lastEditTimestamp.minute.toString().padLeft(2, '0')}'),
          if(widget.item.lastEditNote != null && widget.item.lastEditNote!.isNotEmpty) ...[
             const SizedBox(height: 4),
             Text('Poznámka: ${widget.item.lastEditNote}'),
          ]
        ],
      ),
    );
  }
}

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
            _buildReadOnlyField('EAN kód produktu', ean),
            const Text('Uistite sa, že je EAN kód produktu správny', style: TextStyle(color: Colors.white70)),
            const Spacer(),
            _buildProductTypeButton(
              context: context, icon: Icons.inventory_2_outlined, label: 'Kusový predaj',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreatePieceProductScreen(ean: ean))),
            ),
            const SizedBox(height: 16),
            _buildProductTypeButton(
              context: context, icon: Icons.wine_bar_outlined, label: 'Rozlievaný produkt',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateDispensedProductScreenStep1(ean: ean))),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

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

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _volumeController.dispose();
    _alcoholController.dispose();
    super.dispose();
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
              _buildReadOnlyField('EAN kód produktu', widget.ean),
              _buildTextFieldWithController('Názov', _nameController, hint: 'Napr. TATRA TEA'),
              _buildTextFieldWithController('Výrobca', _manufacturerController, hint: 'Napr. Karloff'),
              _buildTextFieldWithController('Objem fľaše (ml)', _volumeController, keyboardType: TextInputType.number, hint: '1000'),
              _buildTextFieldWithController('Alkohol (%)', _alcoholController, keyboardType: TextInputType.number, hint: '52'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateDispensedProductScreenStep2(
                  ean: widget.ean,
                  name: _nameController.text,
                  manufacturer: _manufacturerController.text,
                  totalVolume: _volumeController.text,
                  alcoholPercentage: _alcoholController.text,
                ))),
                child: const Text('Ďalej'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateDispensedProductScreenStep2 extends StatefulWidget {
  final String ean, name, manufacturer, totalVolume, alcoholPercentage;
  const CreateDispensedProductScreenStep2({super.key, required this.ean, required this.name, required this.manufacturer, required this.totalVolume, required this.alcoholPercentage});

  @override
  State<CreateDispensedProductScreenStep2> createState() => _CreateDispensedProductScreenStep2State();
}

class _CreateDispensedProductScreenStep2State extends State<CreateDispensedProductScreenStep2> {
  final _fullBottleController = TextEditingController();
  final _openBottleController = TextEditingController();
  final _emptyWeightController = TextEditingController();
  final _fullWeightController = TextEditingController();

  @override
  void dispose() {
    _fullBottleController.dispose();
    _openBottleController.dispose();
    _emptyWeightController.dispose();
    _fullWeightController.dispose();
    super.dispose();
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
              _buildTextFieldWithController('Počet plných fliaš', _fullBottleController, keyboardType: TextInputType.number, hint: '0'),
              _buildTextFieldWithController('Otvorená fľaša (váha v g)', _openBottleController, keyboardType: TextInputType.number, hint: '0'),
              Row(
                children: [
                  Expanded(child: _buildTextFieldWithController('Prázdna fľaša (g)', _emptyWeightController, keyboardType: TextInputType.number, hint: '120')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextFieldWithController('Plná fľaša (g)', _fullWeightController, keyboardType: TextInputType.number, hint: '1430')),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final newItem = InventoryItem(
                    ean: widget.ean, name: widget.name, manufacturer: widget.manufacturer, time: "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}", isDispensed: true,
                    fullBottleCount: int.tryParse(_fullBottleController.text) ?? 0,
                    openBottleWeight: double.tryParse(_openBottleController.text) ?? 0,
                    emptyBottleWeight: double.tryParse(_emptyWeightController.text) ?? 0,
                    fullBottleWeight: double.tryParse(_fullWeightController.text) ?? 0,
                    totalVolume: '${widget.totalVolume}ml',
                    alcoholPercentage: '${widget.alcoholPercentage}%',
                    lastEditTimestamp: DateTime.now(),
                    lastEditor: FakeDatabase().currentUser?.apiId ?? "Neznámy",
                    syncStatus: SyncStatus.pending,
                  );
                  FakeDatabase().addItem(newItem);
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

class CreatePieceProductScreen extends StatefulWidget {
  final String ean;
  const CreatePieceProductScreen({super.key, required this.ean});
  @override
  State<CreatePieceProductScreen> createState() => _CreatePieceProductScreenState();
}

class _CreatePieceProductScreenState extends State<CreatePieceProductScreen> {
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _pieceCountController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _pieceCountController.dispose();
    _weightController.dispose();
    super.dispose();
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
              _buildReadOnlyField('EAN kód produktu', widget.ean),
              _buildTextFieldWithController('Názov produktu', _nameController, hint: 'Napr. Horalky'),
              _buildTextFieldWithController('Výrobca produktu', _manufacturerController, hint: 'Napr. Sedita'),
              _buildTextFieldWithController('Počet ks', _pieceCountController, keyboardType: TextInputType.number, hint: '0'),
              _buildTextFieldWithController('Váha (jednotka)', _weightController, keyboardType: TextInputType.text, hint: '50 g'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final newItem = InventoryItem(
                    ean: widget.ean, name: _nameController.text, manufacturer: _manufacturerController.text, time: "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}", isDispensed: false,
                    pieceCount: int.tryParse(_pieceCountController.text) ?? 0,
                    weight: _weightController.text,
                    lastEditTimestamp: DateTime.now(),
                    lastEditor: FakeDatabase().currentUser?.apiId ?? "Neznámy",
                    syncStatus: SyncStatus.pending,
                  );
                  FakeDatabase().addItem(newItem);
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

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FakeDatabase().currentUser;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text('Inventúra úspešne\ndokončená', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            _buildInfoRow('API ID:', user?.apiId ?? 'N/A'),
            const SizedBox(height: 16),
            _buildInfoRow('ID inventúry:', '123 456 789 1011'),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
              child: const Text('Pokračovať v inventúre'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                FakeDatabase().logout();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
              child: const Text('Odhlásiť sa'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
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
  final user = FakeDatabase().currentUser;
  return AppBar(
    automaticallyImplyLeading: showBackButton,
    title: Column(
      children: [
        const Text('BAROVÁ inventúra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('API ID: ${user?.apiId ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        const Text('ID inventúry: 123 456 789 1011', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    ),
  );
}

Widget _buildTextFieldWithController(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, bool obscureText = false, String? hint}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, decoration: InputDecoration(hintText: hint), keyboardType: keyboardType, obscureText: obscureText),
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

Widget _buildProductTypeButton({required BuildContext context, required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed, style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C2E), foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28), const SizedBox(width: 16), Text(label, style: const TextStyle(fontSize: 18)),
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
      case SyncStatus.synced: return const Icon(Icons.cloud_done, color: Colors.green, semanticLabel: 'Synchronizované');
      case SyncStatus.pending: return const Icon(Icons.cloud_upload_outlined, color: Colors.amber, semanticLabel: 'Čaká na synchronizáciu');
      case SyncStatus.failed: return const Icon(Icons.cloud_off, color: Colors.red, semanticLabel: 'Synchronizácia zlyhala');
    }
  }
}
