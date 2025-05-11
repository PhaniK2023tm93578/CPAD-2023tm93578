import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'login_page.dart';

class CrudPage extends StatefulWidget {
  const CrudPage({super.key});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final Map<String, TextEditingController> _updateNameControllers = {};
  final Map<String, TextEditingController> _updateAgeControllers = {};
  final Map<String, bool> _recordLoadingStates = {};
  List<ParseObject> _allRecords = [];
  List<ParseObject> _filteredRecords = [];
  final TextEditingController _searchController = TextEditingController();
  String _addErrorMessage = '';
  String _updateErrorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRecords);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _addErrorMessage = '';
      _updateErrorMessage = '';
    });
    try {
      final QueryBuilder<ParseObject> query =
          QueryBuilder<ParseObject>(ParseObject('MyRecord'))
            ..orderByDescending('createdAt'); // Order by creation date
      final List<ParseObject> results = await query.find();
      setState(() {
        _allRecords = results;
        _filteredRecords = List.from(_allRecords);
        for (var record in _allRecords) {
          _updateNameControllers[record.objectId!] = TextEditingController(text: record.get<String>('name') ?? '');
          _updateAgeControllers[record.objectId!] = TextEditingController(text: record.get<int>('age')?.toString() ?? '');
          _recordLoadingStates[record.objectId!] = false;
        }
      });
    } catch (e) {
      setState(() {
        _addErrorMessage = 'Failed to fetch records: $e';
        _updateErrorMessage = 'Failed to fetch records: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRecords() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final name = record.get<String>('name')?.toLowerCase() ?? '';
        return name.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _addRecord() async {
    setState(() {
      _isLoading = true;
      _addErrorMessage = '';
    });
    final String name = _nameController.text.trim();
    final String ageStr = _ageController.text.trim();
    final int? age = int.tryParse(ageStr);

    String validationError = '';

    if (name.isEmpty) {
      validationError += 'Please enter a name.\n';
    }

    if (ageStr.isEmpty) {
      validationError += 'Please enter an age.\n';
    } else if (age == null) {
      validationError += 'Please enter a valid numeric age.\n';
    }

    if (validationError.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _addErrorMessage = validationError.trim();
      });
      return;
    }

    final record = ParseObject('MyRecord')
      ..set('name', name)
      ..set('age', age);

    final ParseResponse response = await record.save();
    setState(() {
      _isLoading = false;
      if (response.success) {
        _nameController.clear();
        _ageController.clear();
        _fetchRecords();
      } else {
        _addErrorMessage = 'Failed to save record: ${response.error?.message ?? 'Unknown error'}';
      }
    });
  }

  Future<void> _updateRecord(String objectId) async {
    final name = _updateNameControllers[objectId]?.text.trim();
    final ageStr = _updateAgeControllers[objectId]?.text.trim();
    final age = int.tryParse(ageStr ?? '');

    setState(() {
      _recordLoadingStates[objectId] = true;
      _updateErrorMessage = '';
    });

    String validationError = '';

    if (name == null || name.isEmpty) {
      validationError = 'Please enter a name for update.';
    } else if (ageStr == null || ageStr.isEmpty || age == null) {
      validationError = 'Please enter a valid numeric age for update.';
    }

    if (validationError.isNotEmpty) {
      setState(() {
        _recordLoadingStates[objectId] = false;
        _updateErrorMessage = validationError;
      });
      return;
    }

    final record = ParseObject('MyRecord')..objectId = objectId;
    record.set('name', name);
    record.set('age', age);

    final ParseResponse response = await record.save();
    setState(() {
      _recordLoadingStates[objectId] = false;
      if (response.success) {
        _fetchRecords();
      } else {
        _updateErrorMessage = 'Failed to update record: ${response.error?.message ?? 'Unknown error'}';
      }
    });
  }

  Future<void> _deleteRecord(String objectId) async {
    setState(() {
      _recordLoadingStates[objectId] = true;
      _updateErrorMessage = '';
    });
    final record = ParseObject('MyRecord')..objectId = objectId;
    final ParseResponse response = await record.delete();
    setState(() {
      _recordLoadingStates[objectId] = false;
      if (response.success) {
        _fetchRecords();
      } else {
        _updateErrorMessage = 'Failed to delete record: ${response.error?.message ?? 'Unknown error'}';
      }
    });
  }

  Future<void> _logout() async {
    final ParseUser? currentUser = await ParseUser.currentUser();
    if (currentUser != null) {
      final ParseResponse response = await currentUser.logout();
      if (response.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        print('Logout failed: ${response.error?.message}');
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD Operations'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Add New Record',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            if (_addErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _addErrorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _addRecord,
              child: Text(_isLoading ? 'Saving...' : 'Add Record'),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Existing Records',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by Name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            if (_updateErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _updateErrorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _filteredRecords.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    child: Text('No records found.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      final objectId = record.objectId!;
                      final nameController = _updateNameControllers[objectId]!;
                      final ageController = _updateAgeControllers[objectId]!;
                      final isUpdatingOrDeleting = _recordLoadingStates[objectId] ?? false;
                      final recordUpdateError = _updateErrorMessage;

                      final createdAt = record.createdAt;
                      final updatedAt = record.updatedAt;
                      final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
                      final createdTimeString = createdAt != null ? dateFormatter.format(createdAt.toLocal()) : 'N/A';
                      final updatedTimeString = updatedAt != null ? dateFormatter.format(updatedAt.toLocal()) : 'N/A';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Name: ${record.get<String>('name') ?? 'No Name'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Age: ${record.get<int>('age')?.toString() ?? 'No Age'}'),
                              Text('Created At: $createdTimeString', style: const TextStyle(fontSize: 12)),
                              Text('Updated At: $updatedTimeString', style: const TextStyle(fontSize: 12)),
                              if (recordUpdateError.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: Text(
                                    recordUpdateError,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(labelText: 'Update Name'),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: TextField(
                                      controller: ageController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Update Age'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: isUpdatingOrDeleting ? null : () => _updateRecord(objectId),
                                    child: Text(isUpdatingOrDeleting ? 'Updating...' : 'Update'),
                                  ),
                                  const SizedBox(width: 10.0),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: isUpdatingOrDeleting ? null : () => _deleteRecord(objectId),
                                    child: Text(isUpdatingOrDeleting ? 'Deleting...' : 'Delete',
                                        style: const TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
