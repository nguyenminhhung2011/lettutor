import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base_clean_architecture/core/components/extensions/context_extensions.dart';
import 'package:flutter_base_clean_architecture/core/components/extensions/double_extension.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/search_layout/header_search/header_search.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/pagination_view/pagination_list_view.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/pagination_view/pagination_notifier.dart';
import 'package:flutter_base_clean_architecture/core/components/widgets/search_layout/model/filter_response.dart';
import 'package:provider/provider.dart';
import '../controller/search_controller.dart';
import '../model/filter_model.dart';

typedef SearchCall<T> = Future<List<T>> Function(String value);

class GroupHeaderStyle {
  final String hintText;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final double searchRadius;
  final List<String> headerColors;
  final EdgeInsets? contentHeaderSearchPadding;
  final List<FilterModel> listFilter;
  const GroupHeaderStyle({
    this.textStyle,
    this.hintStyle,
    this.hintText = 'Search',
    this.searchRadius = 10.0,
    this.contentHeaderSearchPadding,
    this.listFilter = const <FilterModel>[],
    this.headerColors = const ["992195F3", "CA2195F3"],
  });
}

class SearchLayout<T> extends StatefulWidget {
  final bool leadingAuto;
  final ScrollPhysics scrollPhysics;
  final EdgeInsets? padding;
  final SearchCall<T> textChangeCall;
  final GroupHeaderStyle groupHeaderStyle;
  final SearchLayoutController<T>? searchLayoutController;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool isReverse;
  final bool shrinkWrap;
  const SearchLayout({
    super.key,
    this.padding,
    this.isReverse = false,
    this.shrinkWrap = true,
    this.leadingAuto = false,
    this.searchLayoutController,
    this.groupHeaderStyle = const GroupHeaderStyle(),
    this.scrollPhysics = const BouncingScrollPhysics(),
    required this.itemBuilder,
    required this.textChangeCall,
  });

  @override
  State<SearchLayout<T>> createState() => _SearchLayoutState<T>();
}

class _SearchLayoutState<T> extends State<SearchLayout<T>>
    with SingleTickerProviderStateMixin {
  late SearchLayoutController<T> _searchController;
  late PaginationNotifier<T> _paginationNotifier;
  late TextEditingController _searchTextController;

  //Data

  //style
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get primaryColor => Theme.of(context).primaryColor;

  List<Map<String, dynamic>> viewType = <Map<String, dynamic>>[
    {'title': 'List', 'icon': Icons.list},
    {'title': 'Grid', 'icon': Icons.grid_view_sharp},
  ];

  @override
  void initState() {
    _paginationNotifier = PaginationNotifier<T>(
      (p0, category) async => <T>[],
      List.empty(),
    );
    _searchController = SearchLayoutController<T>()..onGetRecommendSearch();
    _searchTextController = TextEditingController();
    super.initState();
  }

  void _onRefresh() {}

  void _onSubmitted(String text) {
    if (text.isEmpty) {
      return;
    }
    _searchController.onSetNewRecommendSearch(text);
    _searchController.onSearch(text);
  }

  void _onRemoveRecommendSearch(String textRemove) {
    _searchController.onRemoveRecommendSearch(textRemove);
  }

  void _onSelectedRecommendText(String text) {
    _searchTextController.text = text;
  }

  String getTextFilter(FilterResponse filterResponse) {
    return switch (filterResponse.filterType) {
      FilterType.price =>
        'From ${(filterResponse.fromPrice ?? 0.0).toCurrency()} to ${(filterResponse.toPrice ?? 0.0).toCurrency()}',
      _ => '# ${filterResponse.categorySelected?.map((e) => '$e ' '') ?? ''}'
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _searchController,
      child: Consumer<SearchLayoutController<T>>(
        builder: (context, modal, child) {
          return _customField(searchLayoutController: modal);
        },
      ),
    );
  }

  Widget _customField({
    required SearchLayoutController<T> searchLayoutController,
  }) {
    final recommendSearch = searchLayoutController.recommendSearch;
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomSheet: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _changeTypeViewField(searchLayoutController),
        ],
      ),
      body: Column(
        children: [
          HeaderSearch(
            hintStyle: widget.groupHeaderStyle.hintStyle,
            textStyle: widget.groupHeaderStyle.textStyle,
            textChange: _searchController.onTextChange,
            filterCall: searchLayoutController.onApplyFilter,
            colors: widget.groupHeaderStyle.headerColors,
            actionIcon: const Icon(Icons.filter_list, color: Colors.white),
            onSubmittedText: _onSubmitted,
            textEditingController: _searchTextController,
            contentPadding: widget.groupHeaderStyle.contentHeaderSearchPadding,
            listFilter: [...widget.groupHeaderStyle.listFilter],
            initResponse: _searchController.listFilterResponse,
          ),
          const SizedBox(height: 10.0),
          if (searchLayoutController.searchText.isNotEmpty)
            ..._displayItemField
          else
            ..._recommendField(recommendSearch),
        ],
      ),
    );
  }

  List<Widget> get _displayItemField {
    return [
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10.0),
            ..._searchController.listFilterResponse.map<Widget>(
              (e) {
                if (e.filterType.isCompare) {
                  if (e.compareSelected == null) {
                    return const SizedBox();
                  }
                  return Row(
                    children: [
                      ...e.compareSelected!
                          .map((e) => _filterItem(title: e))
                          .expand(
                            (e) => [e, const SizedBox(width: 5.0)],
                          )
                    ],
                  );
                }
                return _filterItem(title: getTextFilter(e));
              },
            )
          ].expand((e) => [e, const SizedBox(width: 5.0)]).toList(),
        ),
      ),
      const Divider(thickness: 0.5),
      Expanded(
        child: PaginationViewCustom<T>(
          paginationNotifier: _paginationNotifier,
          paginationDataCall: (currentPage, category) async => <T>[],
          items: const [],
          limitFetch: 10,
          itemBuilder: (context, data, _) => widget.itemBuilder(context, data),
          physics: widget.scrollPhysics,
          isReverse: widget.isReverse,
          initWidget: Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          shrinkWrap: widget.shrinkWrap,
        ),
      ),
    ];
  }

  List<Widget> _recommendField(List<String> recommendSearch) {
    return [
      const SizedBox(height: 5.0),
      if (recommendSearch.isNotEmpty)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          padding: const EdgeInsets.all(10.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.05),
                blurRadius: 5.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...recommendSearch.map(
                (e) => GestureDetector(
                  onTap: () => _onSelectedRecommendText(e),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e,
                            style: context.titleSmall.copyWith(
                              overflow: TextOverflow.ellipsis,
                            )),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(2.0),
                        onPressed: () => _onRemoveRecommendSearch(e),
                        icon: const Icon(CupertinoIcons.clear_circled_solid,
                            size: 18),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Container _changeTypeViewField(
      SearchLayoutController<dynamic> searchLayoutController) {
    bool isSelected(int index) =>
        searchLayoutController.typeView.value == index;
    context.titleLarge.color;

    Color colorSelected(int index) =>
        isSelected(index) ? Colors.white : context.titleLarge.color!;

    return Container(
      width: context.widthDevice * 0.4,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Row(
        children: [
          ...viewType
              .mapIndexed<Widget>(
                (index, e) => GestureDetector(
                  onTap: () {
                    searchLayoutController.onChangeView(
                      index == 0 ? SearchEnum.list : SearchEnum.grid,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 30.0,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: isSelected(index)
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color: primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .shadowColor
                                    .withOpacity(0.3),
                                blurRadius: 5.0,
                              )
                            ],
                          )
                        : null,
                    child: Row(
                      children: [
                        Icon((e['icon'] as IconData),
                            color: colorSelected(index), size: 14.0),
                        const SizedBox(width: 5.0),
                        Expanded(
                          child: Text(
                            e['title'].toString(),
                            style: context.titleSmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorSelected(index),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .expand((e) => [Expanded(child: e)]),
        ],
      ),
    );
  }

  Container _filterItem({required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(width: 0.5, color: primaryColor),
        color: primaryColor.withOpacity(0.1),
      ),
      child: Text(
        title,
        style: context.titleSmall.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}