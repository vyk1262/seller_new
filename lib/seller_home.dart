import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:trade_seller/seller_add_details.dart';
import 'package:trade_seller/seller_login.dart';
import 'package:trade_seller/seller_item_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trade_seller/seller_profile.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Item> _items = [];
  final List<Item> _filteredItems = [];
  final List<Item> _buyerDemandItems = []; //list to store buyer demand items
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchBuyerDemandItems(); // Fetch buyer demand items
    _filteredItems.addAll(_items); // Initially show all items
  }

  void _addItem() async {
    final newItem = await Navigator.push<Item>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDetails(),
      ),
    );

    if (newItem != null) {
      setState(() {
        _items.insert(0, newItem);
        _filteredItems.insert(0, newItem);
      });

      // Save the item to Firebase
      await _uploadItemToFirebase(newItem);
    }
  }

  Future<void> _uploadItemToFirebase(Item item) async {
    try {
      // Upload images to Firebase Storage and get their URLs
      List<String> imageUrls = [];
      for (var imageFile in item.images) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('item_images/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Create a new item with the image URLs
      Item updatedItem = item.copyWith(imageUrls: imageUrls);

      // Save item details to Firestore
      await FirebaseFirestore.instance
          .collection('sell_items')
          .add(updatedItem.toMap());
      print('Item added successfully!');
    } catch (error) {
      print('Failed to add item: $error');
    }
  }

  Future<void> _fetchItems() async {
    try {
      // Fetch items from Firestore
      final querySnapshot =
          await FirebaseFirestore.instance.collection('sell_items').get();

      final items = querySnapshot.docs
          .map(
              (doc) => Item.fromMap(doc.data(), doc.id)) // Pass the document ID
          .toList();

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _items.clear(); // Clear any existing items
        _items.addAll(items); // Add fetched items to the list
        _filteredItems.clear();
        _filteredItems.addAll(_items); // Update filtered items as well
      });

      print('Items fetched successfully from Firebase!');
    } catch (error) {
      print('Failed to fetch items: $error');
    }
  }

  void _editItem(int index) async {
    final updatedItem = await Navigator.push<Item>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDetails(
          item: _items[index],
        ),
      ),
    );

    if (updatedItem != null) {
      setState(() {
        _items[index] = updatedItem;
        _filteredItems[index] = updatedItem;
      });

      // Update item details in Firestore using the item ID
      await _updateItemInFirebase(updatedItem, _items[index].id);
    }
  }

  Future<void> _updateItemInFirebase(Item item, String itemId) async {
    try {
      // Upload newly added images to Firebase Storage and get their URLs
      List<String> imageUrls = item.imageUrls; // Include existing URLs

      for (var imageFile in item.images) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('item_images/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Update item details in Firestore
      await FirebaseFirestore.instance
          .collection('sell_items')
          .doc(itemId)
          .update({
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'imageUrls': imageUrls,
      });
      print('Item updated successfully!');
    } catch (error) {
      print('Failed to update item: $error');
    }
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _filteredItems.removeAt(index);
    });
  }

  // Fetch items from the "buy_items" collection
  Future<void> _fetchBuyerDemandItems() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('buy_items').get();

      final demandItems = querySnapshot.docs
          .map(
              (doc) => Item.fromMap(doc.data(), doc.id)) // Convert docs to Item
          .toList();

      setState(() {
        _buyerDemandItems.clear();
        _buyerDemandItems.addAll(demandItems);
      });

      print('Buyer demands fetched successfully from Firebase!');
    } catch (error) {
      print('Failed to fetch buyer demands: $error');
    }
  }

  void _onSearchTextChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems.clear();
        _filteredItems.addAll(_items);
      } else {
        _filteredItems.clear();
        _filteredItems.addAll(
          _items.where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase())),
        );
      }
    });
  }

  String formatDateTime(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !_isSearching
            ? Text(_selectedIndex == 0 ? "Demands" : "My Products")
            : TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchTextChanged,
                autofocus: true,
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredItems.clear();
                  _filteredItems.addAll(_items);
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Firebase sign-out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AuthScreen()), // Navigate back to AuthScreen
              );
            },
          ),
        ],
      ),
      body: (_selectedIndex == 0) ? _buildBuyerDemandList() : _buildItemList(),
      floatingActionButton: (_selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: _addItem,
              tooltip: 'Add Item',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.shopping_cart, 0),
            label: 'Demands',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.dashboard, 1),
            label: 'My Products',
          ),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (int index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        elevation: 10.0,
      ),
    );
  }

  Widget _buildIcon(IconData iconData, int index) {
    bool isSelected = _selectedIndex == index;
    return CircleAvatar(
      radius: isSelected ? 24 : 20, // Larger size when selected
      backgroundColor:
          isSelected ? Colors.deepPurple.withOpacity(0.2) : Colors.transparent,
      child: Icon(
        iconData,
        size: 28,
        color: isSelected ? Colors.deepPurple : Colors.grey,
      ),
    );
  }

  Widget _buildItemList() {
    if (_filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No items available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'You can add items by clicking on the "+" icon below.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredItems.length,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final String formattedDate = formatDateTime(item.timestamp.toDate());

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: item.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imageUrls.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, color: Colors.red),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                      ),
                    ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    'Price: \$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Quantity: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Date: $formattedDate', // Show the formatted timestamp
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                onPressed: () {
                  _editItem(index);
                },
              ),
              onTap: () {
                _editItem(index);
              },
            ),
          ),
        );
      },
    );
  }

  // Builds the list for buyer demand items
  Widget _buildBuyerDemandList() {
    if (_buyerDemandItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No buyer demands available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Here you can see the list of demands created by buyers.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _buyerDemandItems.length,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemBuilder: (context, index) {
        final item = _buyerDemandItems[index];
        final String formattedDate = formatDateTime(item.timestamp.toDate());

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: item.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imageUrls.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, color: Colors.red),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                      ),
                    ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    'Price: \$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Quantity: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
