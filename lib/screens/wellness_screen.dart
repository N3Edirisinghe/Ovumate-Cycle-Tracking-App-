import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/wellness_provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/models/wellness_article.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:ovumate/screens/article_detail_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  final _searchController = TextEditingController();
  ArticleCategory? _selectedCategory;
  ArticleDifficulty? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final wellnessProvider = Provider.of<WellnessProvider>(context, listen: false);
        await wellnessProvider.initialize();
      } catch (e) {
        debugPrint('Failed to initialize wellness data: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'articles.failed_load'.tr()}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Constants.backgroundColor),
      appBar: AppBar(
        title: Text(
          'articles.title'.tr(),
          style: const TextStyle(
            color: Color(0xFFE55A8A), // Pink color
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false, // Align to left
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                final wellnessProvider = Provider.of<WellnessProvider>(context, listen: false);
                await wellnessProvider.refreshArticles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('articles.refresh_success'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Failed to refresh articles: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${'articles.refresh_failed'.tr()}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Consumer<WellnessProvider>(
        builder: (context, wellnessProvider, child) {
          if (wellnessProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (wellnessProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'articles.failed_load'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wellnessProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _initializeData(),
                    child: Text('articles.retry'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis,),
                  ),
                ],
              ),
            );
          }

          if (wellnessProvider.articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'articles.no_articles'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'articles.check_later'.tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              try {
                await wellnessProvider.refreshArticles();
              } catch (e) {
                debugPrint('Failed to refresh articles: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${'articles.refresh_failed'.tr()}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: CustomScrollView(
              slivers: [
                // Search and filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Constants.defaultPadding),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'articles.search_hint'.tr(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                wellnessProvider.setSearchQuery('');
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.borderRadius),
                            ),
                          ),
                          onChanged: (query) {
                            wellnessProvider.setSearchQuery(query);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Category filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text('articles.all_categories'.tr()),
                                selected: _selectedCategory == null,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                  wellnessProvider.setCategoryFilter(null);
                                },
                                selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                                checkmarkColor: const Color(Constants.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              ...wellnessProvider.availableCategories.map((category) {
                                final isSelected = _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category.categoryDisplayName),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedCategory = isSelected ? null : category;
                                      });
                                      wellnessProvider.setCategoryFilter(
                                        isSelected ? null : category,
                                      );
                                    },
                                    selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                                    checkmarkColor: const Color(Constants.primaryColor),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Difficulty filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text('articles.all_levels'.tr()),
                                selected: _selectedDifficulty == null,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedDifficulty = null;
                                  });
                                  wellnessProvider.setDifficultyFilter(null);
                                },
                                selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                                checkmarkColor: const Color(Constants.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              ...wellnessProvider.availableDifficulties.map((difficulty) {
                                final isSelected = _selectedDifficulty == difficulty;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(difficulty.difficultyDisplayName),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedDifficulty = isSelected ? null : difficulty;
                                      });
                                      wellnessProvider.setDifficultyFilter(
                                        isSelected ? null : difficulty,
                                      );
                                    },
                                    selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                                    checkmarkColor: const Color(Constants.primaryColor),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filter summary and last update
                        Row(
                          children: [
                            if (wellnessProvider.filterSummary != 'All articles')
                              Flexible(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(Constants.primaryColor).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                        wellnessProvider.filterSummary,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(Constants.primaryColor),
                                          fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedCategory = null;
                                            _selectedDifficulty = null;
                                          });
                                          wellnessProvider.clearFilters();
                                          _searchController.clear();
                                        },
                                        child: const Icon(
                                          Icons.clear,
                                          size: 16,
                                          color: Color(Constants.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (wellnessProvider.filterSummary != 'All articles')
                              const SizedBox(width: 12),
                            Flexible(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.update,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                      wellnessProvider.getLastUpdateTime(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Personalized recommendations section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.currentUser != null && wellnessProvider.articles.isNotEmpty) {
                      final personalizedArticles = wellnessProvider.getPersonalizedRecommendations(
                        authProvider.currentUser!,
                        limit: 5,
                      );
                      
                      if (personalizedArticles.isNotEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: const Text(
                                       'For You',
                                       style: TextStyle(
                                         fontSize: 20,
                                         fontWeight: FontWeight.w600,
                                         fontFamily: 'Poppins',
                                         color: Color(0xFF1A252F), // Darker text color
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                       ),
                                     ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(Constants.primaryColor).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(Constants.primaryColor).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.recommend,
                                              size: 16,
                                              color: Colors.pink[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Personalized',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFE55A8A), // Darker pink color
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: personalizedArticles.length,
                              itemBuilder: (context, index) {
                                final article = personalizedArticles[index];
                                return _buildFeaturedArticleCard(article);
                              },
                            ),
                          ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                // Featured articles
                if (wellnessProvider.featuredArticles.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: const Text(
                                'Featured Articles',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF1A252F), // Darker text color
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fiber_new,
                                        size: 16,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Daily Updates',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF27AE60), // Darker green color
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: wellnessProvider.featuredArticles.length,
                              itemBuilder: (context, index) {
                                final article = wellnessProvider.featuredArticles[index];
                                return _buildFeaturedArticleCard(article);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Article list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          wellnessProvider.filteredArticles.isEmpty
                              ? 'No articles found'
                              : 'Articles (${wellnessProvider.filteredArticles.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Color(0xFF1A252F), // Darker text color
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                // Articles list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = wellnessProvider.filteredArticles[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Constants.defaultPadding,
                          vertical: 8,
                        ),
                        child: _buildArticleCard(article),
                      );
                    },
                    childCount: wellnessProvider.filteredArticles.length,
                  ),
                ),
                
                // Empty state
                if (wellnessProvider.filteredArticles.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(Constants.defaultPadding),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.article,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No articles found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF1A252F), // Darker text color
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or search terms',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5D6D7E), // Darker text color
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await wellnessProvider.refreshArticles();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Refresh Articles',
                                style: TextStyle(
                                  color: Colors.white, // Keep white for button text
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(Constants.primaryColor),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedArticleCard(WellnessArticle article) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 280,
            height: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(article: article),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(Constants.borderRadius),
                splashColor: const Color(Constants.primaryColor).withOpacity(0.1),
                highlightColor: const Color(Constants.primaryColor).withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article image
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(Constants.primaryColor).withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(Constants.borderRadius),
                        ),
                      ),
                      child: article.imageUrl != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(Constants.borderRadius),
                              ),
                              child: Image.network(
                                article.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.article,
                                    size: 48,
                                    color: Color(Constants.primaryColor),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.article,
                              size: 48,
                              color: Color(Constants.primaryColor),
                            ),
                    ),
                    
                    // Article content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    article.categoryDisplayName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(Constants.primaryColor),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (article.isNew)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(Constants.successColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                                                     const SizedBox(height: 4),
                           
                           Text(
                             article.title,
                             style: const TextStyle(
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                               fontFamily: 'Poppins',
                               color: Color(0xFF1A252F), // Darker text color
                             ),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                           
                           const SizedBox(height: 4),
                          
                          Text(
                            article.summary,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D6D7E), // Darker text color
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  article.readTimeDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5D6D7E), // Darker text color
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              if (article.rating > 0) ...[
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  article.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5D6D7E), // Darker text color
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          
                                                     // Click indicator
                           const SizedBox(height: 4),
                           Row(
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 12,
                                color: const Color(Constants.primaryColor).withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to read',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFE55A8A), // Darker primary color
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticleCard(WellnessArticle article) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(Constants.borderRadius),
        splashColor: const Color(Constants.primaryColor).withOpacity(0.1),
        highlightColor: const Color(Constants.primaryColor).withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Article image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(Constants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: article.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          article.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.article,
                              color: const Color(Constants.primaryColor),
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.article,
                        color: const Color(Constants.primaryColor),
                        size: 24,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Article content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(Constants.primaryColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              article.categoryDisplayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(Constants.primaryColor),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (article.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(Constants.successColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Color(0xFF1A252F), // Darker text color
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      article.summary,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5D6D7E), // Darker text color
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            article.readTimeDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D6D7E), // Darker text color
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        if (article.rating > 0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            article.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D6D7E), // Darker text color
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    
                    // Click indicator
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 12,
                          color: const Color(Constants.primaryColor).withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to read',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE55A8A), // Darker primary color
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon with better styling
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(Constants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(Constants.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






