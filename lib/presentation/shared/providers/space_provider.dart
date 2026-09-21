import 'package:flutter/material.dart';
import '../../../data/models/space_model.dart';
import '../../../data/repositories/space_repository.dart';

class SpaceProvider extends ChangeNotifier {
  final SpaceRepository _spaceRepo = SpaceRepository();

  List<SpaceModel> _spaces = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<SpaceModel> get spaces => _spaces;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<SpaceModel> get filteredSpaces {
    return _spaces.where((s) {
      final matchCategory = _selectedCategory == 'All' ||
          s.tipe.toLowerCase() == _selectedCategory.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          s.namaSpace.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  Future<void> fetchSpaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tipeParam = _selectedCategory == 'All' ? null : _selectedCategory;
      _spaces = await _spaceRepo.getSpaces(
        tipe: tipeParam,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    fetchSpaces();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> checkAvailability({
    required int idSpace,
    required String tanggal,
    required String jamMulai,
    required int durasiJam,
  }) async {
    try {
      return await _spaceRepo.checkAvailability(
        idSpace: idSpace,
        tanggal: tanggal,
        jamMulai: jamMulai,
        durasiJam: durasiJam,
      );
    } catch (_) {
      return false;
    }
  }
}
