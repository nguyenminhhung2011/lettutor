import 'package:flutter/material.dart';
import 'package:flutter_base_clean_architecture/clean_architectures/data/datasource/local/preferences.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/search_layout/model/filter_response.dart';

enum SearchEnum {
  list(0),
  grid(1);

  final num value;
  const SearchEnum(this.value);
}

class SearchLayoutController<T> extends ChangeNotifier {
  final List<T> itemsView;
  SearchLayoutController() : itemsView = [];

  SearchEnum _typeView = SearchEnum.list;
  SearchEnum get typeView => _typeView;

  String _searchText = '';
  String get searchText => _searchText;

  final List<FilterResponse> _listFilterResponse = <FilterResponse>[];
  List<FilterResponse> get listFilterResponse => _listFilterResponse;

  final List<String> _recommendSearch = <String>[];
  List<String> get recommendSearch => _recommendSearch;

  void onChangeView(SearchEnum searchEnum) {
    _typeView = searchEnum;
    notifyListeners();
  }

  void onApplyFilter(List<FilterResponse> data) {
    _listFilterResponse.clear();
    _listFilterResponse.addAll(data);
    notifyListeners();
  }

  void onTextChange(String text) {
    _searchText = text;
    notifyListeners();
    if (text.isEmpty) {
      return onGetRecommendSearch();
    }
    return onSearch(text);
  }

  void onSearch(String text) {}

  void onGetRecommendSearch() {
    _recommendSearch.clear();
    _recommendSearch.addAll(CommonAppSettingPref.getRecommendSearch());
    notifyListeners();
  }

  void onSetNewRecommendSearch(String recommendText) async {
    await CommonAppSettingPref.setRecommendSearch(recommendText);
  }

  void onRemoveRecommendSearch(String textRemove) async {
    final remove = await CommonAppSettingPref.removeRecommendSearch(textRemove);
    if (remove) {
      _recommendSearch.removeWhere((e) => e == textRemove);
      notifyListeners();
    }
  }
}