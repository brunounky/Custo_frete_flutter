import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Custos'),
      ),
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [_selectedTab == 0, _selectedTab == 1],
            onPressed: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Custo com Frete'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Custo Médio Ponderado'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedTab == 0
                ? const ProductCostScreen()
                : const WeightedCostScreen(),
          ),
        ],
      ),
    );
  }
}


// ----------- TELA 1: CUSTO COM FRETE --------------
class Product {
  double cost;
  int quantity;
  double updatedCost;

  TextEditingController costController;
  TextEditingController quantityController;

  Product({
    this.cost = 0.0,
    this.quantity = 1,
    this.updatedCost = 0.0,
  })  : costController = TextEditingController(text: cost.toString()),
        quantityController = TextEditingController(text: quantity.toString());
}

class ProductCostScreen extends StatefulWidget {
  const ProductCostScreen({super.key});

  @override
  _ProductCostScreenState createState() => _ProductCostScreenState();
}

class _ProductCostScreenState extends State<ProductCostScreen> {
  final List<Product> products = [];
  final TextEditingController freightController = TextEditingController();

  void calculateUpdatedCosts() {
    double totalQuantity = 0.0;

    for (var product in products) {
      final quantity = int.tryParse(product.quantityController.text) ?? 0;
      totalQuantity += quantity;
    }

    double freight = double.tryParse(freightController.text.replaceAll(',', '.')) ?? 0.0;
    double freightPerUnit = totalQuantity > 0 ? freight / totalQuantity : 0.0;

    setState(() {
      for (var product in products) {
        final cost = double.tryParse(product.costController.text.replaceAll(',', '.')) ?? 0.0;
        final quantity = int.tryParse(product.quantityController.text) ?? 0;

        product.cost = cost;
        product.quantity = quantity;
        product.updatedCost = cost + freightPerUnit;
      }
    });
  }

  @override
  void dispose() {
    for (var product in products) {
      product.costController.dispose();
      product.quantityController.dispose();
    }
    freightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ...products.map((product) => ProductWidget(
                      product: product,
                      onDelete: () {
                        setState(() {
                          product.costController.dispose();
                          product.quantityController.dispose();
                          products.remove(product);
                        });
                      },
                    )),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      products.add(Product());
                    });
                  },
                  child: const Text('Adicionar Produto'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: freightController,
                  decoration: const InputDecoration(
                    labelText: 'Valor do Frete',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: calculateUpdatedCosts,
                  child: const Text('Calcular Custos com Frete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductWidget extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  const ProductWidget({
    super.key,
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: product.costController,
              decoration: const InputDecoration(labelText: 'Custo do Produto'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: product.quantityController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            if (product.updatedCost > 0)
              Text(
                'Custo com Frete (por unidade): ${product.updatedCost.toStringAsPrecision(10)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------- TELA 2: CUSTO MÉDIO PONDERADO --------------
class WeightedProduct {
  TextEditingController oldCostController = TextEditingController();
  TextEditingController oldQtyController = TextEditingController();
  TextEditingController newCostController = TextEditingController();
  TextEditingController newQtyController = TextEditingController();

  double result = 0.0;
}

class WeightedCostScreen extends StatefulWidget {
  const WeightedCostScreen({super.key});

  @override
  State<WeightedCostScreen> createState() => _WeightedCostScreenState();
}

class _WeightedCostScreenState extends State<WeightedCostScreen> {
  final List<WeightedProduct> products = [];
  final TextEditingController totalFreightController = TextEditingController();

  void calculateWeightedCosts() {
    double totalNewQty = 0.0;

    // Somar quantidade comprada de todos os produtos
    for (var product in products) {
      final newQty = double.tryParse(product.newQtyController.text.replaceAll(',', '.')) ?? 0.0;
      totalNewQty += newQty;
    }

    final freight = double.tryParse(totalFreightController.text.replaceAll(',', '.')) ?? 0.0;
    final freightPerUnit = totalNewQty > 0 ? freight / totalNewQty : 0.0;

    setState(() {
      for (var product in products) {
        final oldCost = double.tryParse(product.oldCostController.text.replaceAll(',', '.')) ?? 0.0;
        final oldQty = double.tryParse(product.oldQtyController.text.replaceAll(',', '.')) ?? 0.0;
        final newCost = double.tryParse(product.newCostController.text.replaceAll(',', '.')) ?? 0.0;
        final newQty = double.tryParse(product.newQtyController.text.replaceAll(',', '.')) ?? 0.0;

        final newCostWithFreight = newCost + freightPerUnit;

        final totalQty = oldQty + newQty;
        final weightedCost = totalQty > 0
            ? ((oldCost * oldQty) + (newCostWithFreight * newQty)) / totalQty
            : 0.0;

        product.result = weightedCost;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: totalFreightController,
            decoration: const InputDecoration(
              labelText: 'Frete Total da Compra',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                ...products.map((product) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: product.oldCostController,
                              decoration: const InputDecoration(labelText: 'Custo Anterior'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            TextField(
                              controller: product.oldQtyController,
                              decoration: const InputDecoration(labelText: 'Estoque Anterior'),
                              keyboardType: TextInputType.number,
                            ),
                            TextField(
                              controller: product.newCostController,
                              decoration: const InputDecoration(labelText: 'Custo da Nova Compra'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            TextField(
                              controller: product.newQtyController,
                              decoration: const InputDecoration(labelText: 'Quantidade Comprada'),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 8),
                            if (product.result > 0)
                              Text(
                                'Novo Custo Médio: ${product.result.toStringAsPrecision(10)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    products.remove(product);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      products.add(WeightedProduct());
                    });
                  },
                  child: const Text('Adicionar Produto'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: calculateWeightedCosts,
                  child: const Text('Calcular Custo Médio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

