import 'dart:convert';

import 'package:anjanitek/card_interactive.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/design_details.dart';
import 'package:anjanitek/utils/divider.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum _ListingMode { browse, search }

class DesignsListing extends StatefulWidget {
  final List<int> alreadySelectedTagIds;

  const DesignsListing({super.key, required this.alreadySelectedTagIds});

  @override
  State<DesignsListing> createState() => _DesignsListingState();
}

class _DesignsListingState extends State<DesignsListing> {
  bool _isLoadingTags = true;
  bool _isLoadingProducts = true;
  bool _isLoadingFallback = false;
  int _browseOffset = 0;
  int _searchOffset = 0;
  int _listingCount = 0;
  bool _hasMoreBrowse = true;
  bool _hasMoreSearch = true;
  String _searchPrompt = '';
  final TextEditingController searchController = TextEditingController();
  late final List<int> _baseCollectionTagIds;
  late List<int> _selectedTagIds;
  _ListingMode _mode = _ListingMode.browse;

  final List<Product> _browseProducts = [];
  final List<Product> _searchProducts = [];
  final List<Product> _fallbackProducts = [];
  List<ProductTag> _productTags = [];
  List<String> _uniqueProductTypes = [];

  @override
  void initState() {
    super.initState();

    _baseCollectionTagIds = List<int>.from(widget.alreadySelectedTagIds);
    _selectedTagIds = List<int>.from(_baseCollectionTagIds);

    getProductTags(context);
    _loadBrowseProducts(reset: true);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool get _isSearchMode => _mode == _ListingMode.search;

  List<Product> get _displayedProducts =>
      _isSearchMode ? _searchProducts : _browseProducts;

  List<int> get _extraFilterTagIds => _selectedTagIds
      .where((tagId) => !_baseCollectionTagIds.contains(tagId))
      .toList();

  int get _additionalFilterCount => _selectedTagIds
      .where((tagId) => !_baseCollectionTagIds.contains(tagId))
      .length;

  String get _activeCollectionLabel {
    for (final collectionId in _baseCollectionTagIds) {
      final match = _productTags.cast<ProductTag?>().firstWhere(
            (tag) =>
                tag?.tagId == collectionId &&
                tag?.type?.toLowerCase() == 'series',
            orElse: () => null,
          );
      if (match?.name?.trim().isNotEmpty == true) {
        return match!.name!.trim();
      }
    }

    return _baseCollectionTagIds.isNotEmpty
        ? 'Selected collection'
        : 'No collection selected';
  }

  List<String> get _filterTypes => _uniqueProductTypes
      .where((type) => type.toLowerCase() != 'series')
      .toList()
    ..sort();

  bool _isTagLocked(ProductTag tag) {
    return _baseCollectionTagIds.contains(tag.tagId);
  }

  Future<void> getProductTags(BuildContext context) async {
    setState(() {
      _isLoadingTags = true;
    });

    final result = await get(
      Uri.parse(APIUrls.getUrl('${APIUrls.products}${APIUrls.pass}/U0', {})),
      headers: {'Accept': 'application/json'},
    );
    final jsonObject = jsonDecode(result.body) as Map<String, dynamic>;

    if (!mounted) {
      return;
    }

    if (jsonObject['status'] == 200) {
      final tagData = jsonObject['data'] as List;
      final productTagsList =
          tagData.map<ProductTag>((json) => ProductTag.fromJson(json)).toList();
      setState(() {
        _productTags = productTagsList;
        _uniqueProductTypes = productTagsList
            .map((tag) => tag.type)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
        _isLoadingTags = false;
      });
      return;
    }

    setState(() {
      _isLoadingTags = false;
    });
  }

  Future<void> _loadBrowseProducts({bool reset = false}) async {
    if (_isLoadingProducts && !reset) {
      return;
    }

    final ids = _selectedTagIds.join(',');
    if (ids.isEmpty) {
      setState(() {
        _mode = _ListingMode.browse;
        _browseProducts.clear();
        _browseOffset = 0;
        _listingCount = 0;
        _hasMoreBrowse = false;
        _isLoadingProducts = false;
      });
      return;
    }

    final requestOffset = reset ? 0 : _browseOffset;

    setState(() {
      _isLoadingProducts = true;
      if (reset) {
        _mode = _ListingMode.browse;
        _browseOffset = 0;
        _browseProducts.clear();
        _hasMoreBrowse = true;
      }
    });

    final result = await get(
      Uri.parse(
        APIUrls.getUrl(
          '${APIUrls.products}${APIUrls.pass}/U3/$ids/$requestOffset',
          {},
        ),
      ),
      headers: {'Accept': 'application/json'},
    );
    final jsonObject = jsonDecode(result.body) as Map<String, dynamic>;

    if (!mounted) {
      return;
    }

    if (jsonObject['status'] == 200) {
      final productData = jsonObject['data'] as List;
      final productsList =
          productData.map<Product>((json) => Product.fromJson(json)).toList();
      final nextCount = (jsonObject['count'] as int?) ?? productsList.length;

      setState(() {
        if (reset) {
          _browseProducts
            ..clear()
            ..addAll(productsList);
        } else {
          _browseProducts.addAll(productsList);
        }
        _listingCount = nextCount;
        _browseOffset = requestOffset + productsList.length;
        _hasMoreBrowse = _browseProducts.length < _listingCount;
        _isLoadingProducts = false;
        if (_browseProducts.isNotEmpty || _extraFilterTagIds.isEmpty) {
          _fallbackProducts.clear();
          _isLoadingFallback = false;
        }
      });

      if (reset && nextCount == 0 && _extraFilterTagIds.isNotEmpty) {
        await _loadFallbackProducts();
      }
      return;
    }

    setState(() {
      if (reset) {
        _browseProducts.clear();
      }
      _listingCount = 0;
      _hasMoreBrowse = false;
      _isLoadingProducts = false;
    });

    if (reset && _extraFilterTagIds.isNotEmpty) {
      await _loadFallbackProducts();
    }
  }

  Future<void> _loadFallbackProducts() async {
    final extraFilters = _extraFilterTagIds;
    if (extraFilters.isEmpty) {
      setState(() {
        _fallbackProducts.clear();
        _isLoadingFallback = false;
      });
      return;
    }

    setState(() {
      _isLoadingFallback = true;
      _fallbackProducts.clear();
    });

    final result = await get(
      Uri.parse(
        APIUrls.getUrl(
          '${APIUrls.products}${APIUrls.pass}/U3/${extraFilters.join(',')}/0',
          {},
        ),
      ),
      headers: {'Accept': 'application/json'},
    );
    final jsonObject = jsonDecode(result.body) as Map<String, dynamic>;

    if (!mounted) {
      return;
    }

    if (jsonObject['status'] == 200) {
      final productData = jsonObject['data'] as List;
      final productsList = productData
          .map<Product>((json) => Product.fromJson(json))
          .where((product) => !_belongsToBaseCollection(product))
          .toList();

      setState(() {
        _fallbackProducts
          ..clear()
          ..addAll(productsList);
        _isLoadingFallback = false;
      });
      return;
    }

    setState(() {
      _fallbackProducts.clear();
      _isLoadingFallback = false;
    });
  }

  Future<void> _loadSearchResults({bool reset = false}) async {
    if (_isLoadingProducts && !reset) {
      return;
    }

    final query = _searchPrompt.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    final requestOffset = reset ? 0 : _searchOffset;

    setState(() {
      _isLoadingProducts = true;
      _mode = _ListingMode.search;
      if (reset) {
        _searchOffset = 0;
        _searchProducts.clear();
        _hasMoreSearch = true;
      }
    });

    final result = await get(
      Uri.parse(
        APIUrls.getUrl(
          '${APIUrls.products}${APIUrls.pass}/U4/${Uri.encodeComponent(query)}/$requestOffset',
          {},
        ),
      ),
      headers: {'Accept': 'application/json'},
    );
    final jsonObject = jsonDecode(result.body) as Map<String, dynamic>;

    if (!mounted) {
      return;
    }

    if (jsonObject['status'] == 200) {
      final productData = jsonObject['data'] as List;
      final productsList =
          productData.map<Product>((json) => Product.fromJson(json)).toList();

      setState(() {
        if (reset) {
          _searchProducts
            ..clear()
            ..addAll(productsList);
        } else {
          _searchProducts.addAll(productsList);
        }
        _searchOffset = requestOffset + productsList.length;
        _hasMoreSearch = productsList.length >= 20;
        _isLoadingProducts = false;
      });
      return;
    }

    setState(() {
      if (reset) {
        _searchProducts.clear();
      }
      _hasMoreSearch = false;
      _isLoadingProducts = false;
    });
  }

  Future<void> _submitSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _searchPrompt = query;
      _mode = _ListingMode.search;
    });

    await _loadSearchResults(reset: true);
  }

  void _clearSearch() {
    setState(() {
      _searchPrompt = '';
      searchController.clear();
      _searchOffset = 0;
      _searchProducts.clear();
      _hasMoreSearch = true;
      _mode = _ListingMode.browse;
      _isLoadingProducts = false;
    });

    if (_browseProducts.isEmpty && _selectedTagIds.isNotEmpty) {
      _loadBrowseProducts(reset: true);
    }
  }

  List<int> _normalizeSelectedTagIds(List<int> tagIds) {
    final normalized = <int>{..._baseCollectionTagIds};
    for (final tagId in tagIds) {
      if (_baseCollectionTagIds.contains(tagId)) {
        continue;
      }
      normalized.add(tagId);
    }
    return normalized.toList();
  }

  void _applyFilters(List<int> nextTagIds) {
    final normalized = _normalizeSelectedTagIds(nextTagIds);
    setState(() {
      _selectedTagIds = normalized;
      _searchPrompt = '';
      searchController.clear();
      _mode = _ListingMode.browse;
      _searchProducts.clear();
      _searchOffset = 0;
      _hasMoreSearch = true;
      _fallbackProducts.clear();
      _isLoadingFallback = false;
    });
    _loadBrowseProducts(reset: true);
  }

  Future<void> _showFiltersSheet() async {
    final selected = await showModalBottomSheet<List<int>>(
      backgroundColor: Colors.white,
      showDragHandle: true,
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final tempSelected = List<int>.from(_selectedTagIds);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sheetHeight = MediaQuery.of(context).size.height * 0.82;
            final activeExtraCount = tempSelected
                .where((tagId) => !_baseCollectionTagIds.contains(tagId))
                .length;
            final hasExtraFilters = activeExtraCount > 0;

            Widget buildSectionChip(ProductTag tag) {
              final isLocked = _isTagLocked(tag);
              final isSelected = tempSelected.contains(tag.tagId);
              final backgroundColor = isSelected
                  ? const Color(0xFF048563)
                  : isLocked
                      ? const Color(0xFFE9F5F1)
                      : const Color(0xFFF9FAF9);
              final borderColor = isSelected
                  ? const Color(0xFF048563)
                  : isLocked
                      ? const Color(0xFFCFE2DA)
                      : const Color(0xFFE2E7E4);
              final textColor = isSelected
                  ? Colors.white
                  : isLocked
                      ? const Color(0xFF0C6B54)
                      : const Color(0xFF1E2723);

              return GestureDetector(
                onTap: isLocked
                    ? null
                    : () {
                        setModalState(() {
                          if (isSelected) {
                            tempSelected.remove(tag.tagId);
                          } else {
                            tempSelected.add(tag.tagId!);
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x26048563),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            PhosphorIconsRegular.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      Text(
                        tag.name ?? 'Filter',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget buildFilterSection(String type, List<ProductTag> tags) {
              final selectedInSection = tags
                  .where((tag) =>
                      tag.tagId != null &&
                      tempSelected.contains(tag.tagId) &&
                      !_isTagLocked(tag))
                  .length;

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8ECEA)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF17211D),
                            ),
                          ),
                        ),
                        if (selectedInSection > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$selectedInSection selected',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF36C31),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: tags.map(buildSectionChip).toList(),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter Designs',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF141C18),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasExtraFilters
                                    ? '$activeExtraCount filter${activeExtraCount == 1 ? '' : 's'} selected'
                                    : 'Browse options for this collection',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF66736E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            PhosphorIconsRegular.x,
                            color: Color(0xFF53615B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8E5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: hasExtraFilters
                                    ? const Color(0xFFF36C31)
                                    : const Color(0xFF8E9894),
                                side: BorderSide(
                                  color: hasExtraFilters
                                      ? const Color(0xFFF36C31)
                                      : const Color(0xFFDDE3E0),
                                ),
                                backgroundColor: Colors.white,
                                textStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              onPressed: hasExtraFilters
                                  ? () {
                                      setModalState(() {
                                        tempSelected
                                          ..clear()
                                          ..addAll(_baseCollectionTagIds);
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                PhosphorIconsRegular.arrowCounterClockwise,
                                size: 16,
                              ),
                              label: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF36C31),
                                foregroundColor: Colors.white,
                                textStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  List<int>.from(tempSelected),
                                );
                              },
                              icon: const Icon(
                                PhosphorIconsRegular.funnelSimple,
                                size: 16,
                              ),
                              label: Text(
                                hasExtraFilters
                                    ? 'Apply $activeExtraCount'
                                    : 'Apply filters',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _isLoadingTags && _productTags.isEmpty
                          ? const Center(
                              child: AppProgress(height: 30, width: 30),
                            )
                          : ListView(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4FAF7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFD6E2DD),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            PhosphorIconsRegular.lockSimple,
                                            size: 15,
                                            color: Color(0xFF0C6B54),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Current collection',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0C6B54),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            _baseCollectionTagIds.map((tagId) {
                                          final baseTag = _productTags
                                              .cast<ProductTag?>()
                                              .firstWhere(
                                                (tag) => tag?.tagId == tagId,
                                                orElse: () => null,
                                              );
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: const Color(0xFFCFE2DA),
                                              ),
                                            ),
                                            child: Text(
                                              baseTag?.name ?? 'Collection',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0C6B54),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._filterTypes.map((type) {
                                  final filteredTags = _productTags
                                      .where((tag) => tag.type == type)
                                      .toList();
                                  return buildFilterSection(type, filteredTags);
                                }),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      _applyFilters(selected);
    }
  }

  ProductTag? _resolveCollectionTag(Product product) {
    final rawTags = product.tags?.split(',') ?? const [];
    for (final rawTag in rawTags) {
      final tagId = int.tryParse(rawTag.trim());
      if (tagId == null) {
        continue;
      }
      final tag = _productTags.cast<ProductTag?>().firstWhere(
            (item) => item?.tagId == tagId,
            orElse: () => null,
          );
      if (tag?.type?.toLowerCase() == 'series') {
        return tag;
      }
    }
    return null;
  }

  bool _belongsToBaseCollection(Product product) {
    final rawTags = product.tags?.split(',') ?? const [];
    for (final rawTag in rawTags) {
      final tagId = int.tryParse(rawTag.trim());
      if (tagId != null && _baseCollectionTagIds.contains(tagId)) {
        return true;
      }
    }
    return false;
  }

  List<_SearchResultSection> _searchSections() {
    return _buildSectionsFor(_searchProducts);
  }

  List<_SearchResultSection> _fallbackSections() {
    return _buildSectionsFor(_fallbackProducts, markCurrentCollection: false);
  }

  List<_SearchResultSection> _buildSectionsFor(
    List<Product> products, {
    bool markCurrentCollection = true,
  }) {
    final Map<String, _SearchResultSection> grouped = {};
    for (final product in products) {
      final collectionTag = _resolveCollectionTag(product);
      final key = collectionTag?.tagId?.toString() ?? 'other';
      final belongsToBase =
          markCurrentCollection && _belongsToBaseCollection(product);
      final current = grouped.putIfAbsent(
        key,
        () => _SearchResultSection(
          title: collectionTag?.name ?? 'Other collections',
          isCurrentCollection: belongsToBase,
          products: [],
        ),
      );
      current.products.add(product);
      if (belongsToBase) {
        current.isCurrentCollection = true;
      }
    }

    final sections = grouped.values.toList();
    sections.sort((a, b) {
      if (a.isCurrentCollection == b.isCurrentCollection) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return a.isCurrentCollection ? -1 : 1;
    });
    return sections;
  }

  Future<void> _loadMore() async {
    if (_isLoadingProducts) {
      return;
    }

    if (_isSearchMode) {
      if (!_hasMoreSearch) {
        return;
      }
      await _loadSearchResults();
      return;
    }

    if (!_hasMoreBrowse) {
      return;
    }
    await _loadBrowseProducts();
  }

  Widget _buildInfoBar() {
    final label = _isSearchMode ? 'All' : 'Collection';
    final subLabel = '';
    // final label = _isSearchMode ? 'Global search results' : 'Collection view';
    // final subLabel = _isSearchMode
    //     ? 'Showing results across all products, grouped by collection.'
    //     : 'Browsing $_activeCollectionLabel with $_additionalFilterCount extra filters.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      // padding: const EdgeInsets.all(8),
      // decoration: BoxDecoration(
      //   color: const Color(0xFFF7FAF9),
      //   borderRadius: BorderRadius.circular(18),
      //   border: Border.all(color: const Color(0xFFDCE7E2)),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: _isSearchMode
                      ? const Color(0xFFE7F1FF)
                      : const Color(0xFFE9F5F1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isSearchMode
                        ? const Color(0xFF1154B5)
                        : const Color(0xFF0C6B54),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _activeCollectionLabel +
                      (_isSearchMode ? '' : ' ($_listingCount)'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2420),
                  ),
                ),
              ),
              if (_additionalFilterCount > 0 && !_isSearchMode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_additionalFilterCount filters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFAF4B03),
                    ),
                  ),
                ),
            ],
          ),
          // const SizedBox(height: 10),
          // Text(
          //   subLabel,
          //   style: GoogleFonts.inter(
          //     fontSize: 13,
          //     fontWeight: FontWeight.w500,
          //     color: const Color(0xFF5F7068),
          //   ),
          // ),
          // if (!_isSearchMode) ...[
          //   const SizedBox(height: 8),
          //   Text(
          //     '$_listingCount designs available in this browse context.',
          //     style: GoogleFonts.inter(
          //       fontSize: 12,
          //       color: const Color(0xFF6C7B74),
          //       fontWeight: FontWeight.w600,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          final nextQuery = value.trim();
          setState(() {
            _searchPrompt = nextQuery;
          });
          if (nextQuery.isEmpty && _isSearchMode) {
            _clearSearch();
          }
        },
        onSubmitted: _submitSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search all designs ...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD7E3DE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD7E3DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF048563), width: 1.4),
          ),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: (_searchPrompt.isNotEmpty || _isSearchMode)
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    final isSearchEmpty = _isSearchMode;
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearchEmpty
                    ? PhosphorIconsRegular.magnifyingGlass
                    : PhosphorIconsRegular.funnel,
                size: 32,
                color: Colors.black26,
              ),
              const SizedBox(height: 12),
              Text(
                isSearchEmpty
                    ? 'No products match your global search.'
                    : 'No products match these filters in $_activeCollectionLabel.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    const Color(0xFF048563),
                  ),
                ),
                onPressed: isSearchEmpty
                    ? _clearSearch
                    : () => _applyFilters(_baseCollectionTagIds),
                child: Text(
                  isSearchEmpty ? 'Back to collection' : 'Clear extra filters',
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackResults() {
    final sections = _fallbackSections();

    return Expanded(
      child: ListView(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.fromLTRB(2, 2, 12, 2),
            // decoration: BoxDecoration(
            //   color: const Color(0xFFFFF7F1),
            //   borderRadius: BorderRadius.circular(18),
            //   border: Border.all(color: const Color(0xFFF6D7BF)),
            // ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No matches in $_activeCollectionLabel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8D430F),
                  ),
                ),
                divider(Colors.black12),
                // const SizedBox(height: 8),
                // Text(
                //   'Showing matching designs from other collections for these filters.',
                //   style: GoogleFonts.inter(
                //     fontSize: 13,
                //     fontWeight: FontWeight.w500,
                //     color: const Color(0xFFA25620),
                //   ),
                // ),
              ],
            ),
          ),
          if (_isLoadingFallback)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppProgress(height: 24, width: 24)),
            )
          else
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  section.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15211D),
                  ),
                ),
              ),
              for (final product in section.products)
                _buildProductCard(product, collectionLabel: section.title),
            ],
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {String? collectionLabel}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DesignDetails(
                product: product, productTags: _productTags),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CardInteractive(
              design: product.design!,
              media: product.media!.split(',')[0],
              imageHeight: double.parse(product.size!.split('x')[1]),
              imageWidth: double.parse(product.size!.split('x')[0]),
              zoom: 1,
              productSize: product.size,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.name!} - ${product.design!}',
                    style: GoogleFonts.inter(
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.size ?? '',
                    style: GoogleFonts.inter(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      color: Colors.black87,
                    ),
                  ),
                  if (collectionLabel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        collectionLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF526372),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseResults() {
    return ListView.builder(
      itemCount: _browseProducts.length + (_isLoadingProducts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _browseProducts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: AppProgress(height: 24, width: 24)),
          );
        }
        return _buildProductCard(_browseProducts[index]);
      },
    );
  }

  Widget _buildSearchResults() {
    final sections = _searchSections();
    return ListView(
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15211D),
                    ),
                  ),
                ),
                if (section.isCurrentCollection)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F5F1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Current collection',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0C6B54),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final product in section.products)
            _buildProductCard(
              product,
              collectionLabel:
                  section.isCurrentCollection ? null : section.title,
            ),
        ],
        if (_isLoadingProducts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: AppProgress(height: 24, width: 24)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Designs',
          style: GoogleFonts.inter(
            textStyle: Theme.of(context).textTheme.bodyLarge,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(const Color(0xFF048563)),
                  ),
                  onPressed: _showFiltersSheet,
                  child: Icon(PhosphorIconsRegular.funnel, color: Colors.white),
                ),
                if (_additionalFilterCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF36C31),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _additionalFilterCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBox(),
          _buildInfoBar(),
          if (_isLoadingProducts && _displayedProducts.isEmpty)
            const Expanded(
              child: Center(child: AppProgress(height: 30, width: 30)),
            )
          else if (!_isSearchMode &&
              _browseProducts.isEmpty &&
              (_isLoadingFallback || _fallbackProducts.isNotEmpty))
            _buildFallbackResults()
          else if (!_isLoadingProducts && _displayedProducts.isEmpty)
            _buildNoResults()
          else
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 120 &&
                      !_isLoadingProducts) {
                    _loadMore();
                  }
                  return false;
                },
                child: _isSearchMode
                    ? _buildSearchResults()
                    : _buildBrowseResults(),
              ),
            ),
          sizedBox(16),
        ],
      ),
    );
  }
}

class _SearchResultSection {
  _SearchResultSection({
    required this.title,
    required this.isCurrentCollection,
    required this.products,
  });

  final String title;
  bool isCurrentCollection;
  final List<Product> products;
}
