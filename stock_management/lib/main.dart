
import 'package:flutter/material.dart';

void main() {
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const StockHomePage(),
    );
  }
}

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  final List<Map<String, dynamic>> products = [];
  final List<Map<String, dynamic>> transactions = [];

  void addProduct() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final quantityController = TextEditingController(text: '0');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                ),
              ),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                ),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening quantity',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final sku = skuController.text.trim();
              final quantity =
                  int.tryParse(quantityController.text.trim());

              if (name.isEmpty ||
                  sku.isEmpty ||
                  quantity == null ||
                  quantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter valid product details.'),
                  ),
                );
                return;
              }

              if (products.any((p) =>
                  (p['sku'] as String).toLowerCase() ==
                  sku.toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('That SKU already exists.'),
                  ),
                );
                return;
              }

              setState(() {
                products.add({
                  'name': name,
                  'sku': sku,
                  'quantity': quantity,
                });
              });

              if (quantity > 0) {
                transactions.add({
                  'name': name,
                  'type': 'Opening stock',
                  'quantity': quantity,
                  'date': DateTime.now(),
                });
              }

              Navigator.pop(dialogContext);
              nameController.dispose();
              skuController.dispose();
              quantityController.dispose();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void changeStock(int index, bool stockIn) {
    final quantityController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(stockIn ? 'Stock In' : 'Stock Out'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(quantityController.text);

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a positive whole number.'),
                  ),
                );
                return;
              }

              final current =
                  products[index]['quantity'] as int;

              if (!stockIn && amount > current) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient stock available.'),
                  ),
                );
                return;
              }

              setState(() {
                products[index]['quantity'] =
                    stockIn ? current + amount : current - amount;

                transactions.add({
                  'name': products[index]['name'],
                  'type': stockIn ? 'Stock In' : 'Stock Out',
                  'quantity': amount,
                  'date': DateTime.now(),
                });
              });

              Navigator.pop(dialogContext);
              quantityController.dispose();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = products.fold<int>(
      0,
      (sum, p) => sum + (p['quantity'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Colors.green.shade100,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              summaryCard('Products', '${products.length}'),
              summaryCard('Total Units', '$totalUnits'),
              summaryCard('Transactions', '${transactions.length}'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No products yet. Add your first product.'),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory_2),
                  ),
                  title: Text(product['name'] as String),
                  subtitle: Text(
                    'SKU: ${product['sku']} • '
                    'Quantity: ${product['quantity']}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      changeStock(index, value == 'in');
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'in',
                        child: Text('Stock In'),
                      ),
                      PopupMenuItem(
                        value: 'out',
                        child: Text('Stock Out'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          const Text(
            'Transaction History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No transactions yet.'),
            )
          else
            ...transactions.reversed.map((t) {
              final date = t['date'] as DateTime;
              return Card(
                child: ListTile(
                  title: Text('${t['name']}'),
                  subtitle: Text(
                    '${t['type']} • '
                    '${date.toLocal().toString().substring(0, 16)}',
                  ),
                  trailing: Text('${t['quantity']} units'),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget summaryCard(String title, String value) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
