import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/models/wellness_article.dart';
import 'package:ovumate/providers/wellness_provider.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class ArticleDetailScreen extends StatefulWidget {
  final WellnessArticle article;

  const ArticleDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    // Defer view count increment until after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _incrementViewCount();
    });
  }

  void _incrementViewCount() {
    final wellnessProvider = Provider.of<WellnessProvider>(context, listen: false);
    wellnessProvider.incrementViewCount(widget.article.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Constants.backgroundColor),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildArticleHeader(),
                  const SizedBox(height: 32),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 32),
                  _buildArticleContent(),
                  const SizedBox(height: 32),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 32),
                  _buildArticleActions(),
                  const SizedBox(height: 32),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 32),
                  _buildRelatedArticles(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: const Color(Constants.backgroundColor),
      elevation: 0,
      shadowColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image with enhanced styling
            if (widget.article.imageUrl != null)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.network(
                widget.article.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  ),
                ),
              )
            else
              _buildPlaceholderImage(),
            
            // Enhanced gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            
            // Article title overlay with enhanced styling
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge with enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor().withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getCategoryName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Article title with enhanced typography
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 8,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Enhanced leading button
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(Constants.primaryColor),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Enhanced action buttons
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked 
                  ? const Color(Constants.accentColor)
                  : const Color(Constants.primaryColor),
              size: 20,
          ),
          onPressed: () {
            setState(() {
              _isBookmarked = !_isBookmarked;
            });
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.share,
              color: Color(Constants.primaryColor),
              size: 20,
            ),
            onPressed: () {
              // Share functionality
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(Constants.primaryColor).withOpacity(0.1),
            const Color(Constants.secondaryColor).withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article,
            size: 80,
            color: const Color(Constants.primaryColor).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'articles.article_detail.article_image'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(Constants.primaryColor).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Enhanced category and difficulty badges
        Row(
          children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCategoryColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      size: 16,
                      color: _getCategoryColor(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryName(),
                style: TextStyle(
                  color: _getCategoryColor(),
                        fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
                  ],
            ),
              ),
              const SizedBox(width: 12),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getDifficultyColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getDifficultyColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDifficultyIcon(),
                      size: 16,
                      color: _getDifficultyColor(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.article.difficulty.difficultyDisplayName,
                style: TextStyle(
                  color: _getDifficultyColor(),
                        fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                    ),
                  ],
              ),
            ),
          ],
        ),
          
          const SizedBox(height: 20),
          
          // Enhanced article summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(Constants.primaryColor).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(Constants.primaryColor).withOpacity(0.1),
              ),
            ),
            child: Text(
              widget.article.summary,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: const Color(Constants.textSecondaryColor),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Enhanced author and metadata section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Author avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(Constants.primaryColor),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Text(
                        widget.article.author,
            style: const TextStyle(
              fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(Constants.textPrimaryColor),
            ),
          ),
                      const SizedBox(height: 4),
        Row(
          children: [
                          Icon(
                            Icons.access_time,
                size: 16,
                            color: const Color(Constants.textSecondaryColor),
              ),
                          const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'articles.article_detail.min_read'.tr(namedArgs: {'minutes': widget.article.readTime.toString()}),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(Constants.textSecondaryColor),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
                          Icon(
                            Icons.calendar_today,
              size: 16,
                            color: const Color(Constants.textSecondaryColor),
            ),
                          const SizedBox(width: 6),
            Flexible(
              child: Text(
                            DateFormat('MMM dd, yyyy').format(widget.article.publishedAt),
              style: const TextStyle(
                fontSize: 14,
                color: Color(Constants.textSecondaryColor),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ),
                        ],
              ),
          ],
        ),
                ),
                // View count and rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
            Row(
              children: [
                        Icon(
                  Icons.visibility,
                  size: 16,
                          color: const Color(Constants.textSecondaryColor),
                ),
                        const SizedBox(width: 6),
                Text(
                  '${widget.article.viewCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(Constants.textSecondaryColor),
                  ),
                ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                  Icons.star,
                  size: 16,
                          color: const Color(Constants.accentColor),
                ),
                        const SizedBox(width: 6),
                Text(
                          '${widget.article.rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(Constants.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content header with enhanced styling
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(Constants.primaryColor).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(Constants.primaryColor).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Color(Constants.primaryColor),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                        'articles.article_detail.article_content'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(Constants.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'articles.article_detail.read_full_article'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(Constants.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced formatted content
          _buildFormattedContent(),
          
          // Tags section with enhanced styling
        if (widget.article.tags.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(Constants.accentColor).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(Constants.accentColor).withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(Constants.accentColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tag,
                          color: Color(Constants.accentColor),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'articles.article_detail.related_topics'.tr(),
            style: TextStyle(
                          fontSize: 18,
              fontWeight: FontWeight.w600,
                          color: const Color(Constants.accentColor),
            ),
          ),
                    ],
                  ),
                  const SizedBox(height: 16),
          Wrap(
                    spacing: 12,
                    runSpacing: 12,
            children: widget.article.tags.map((tag) {
              return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                          color: const Color(Constants.accentColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(Constants.accentColor).withOpacity(0.3),
                          ),
                ),
                child: Text(
                  '#$tag',
                          style: TextStyle(
                            color: const Color(Constants.accentColor),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedContent() {
    final content = widget.article.content;
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 20));
        continue;
      }

      if (line.startsWith('# ')) {
        // Main heading
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 32, bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(Constants.primaryColor).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(Constants.primaryColor).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.title,
                    color: Color(Constants.primaryColor),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(Constants.primaryColor),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // Subheading
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 28, bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(Constants.accentColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(3),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(Constants.textPrimaryColor),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        // Sub-subheading
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 24, bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(Constants.secondaryColor),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(4),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(Constants.textPrimaryColor),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        // Bullet points
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(Constants.accentColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(Constants.textPrimaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('1. ') || line.startsWith('2. ') || line.startsWith('3. ') || 
                 line.startsWith('4. ') || line.startsWith('5. ') || line.startsWith('6. ') ||
                 line.startsWith('7. ') || line.startsWith('8. ') || line.startsWith('9. ')) {
        // Numbered lists
        final number = line.split('.')[0];
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(Constants.primaryColor).withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(Constants.primaryColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(line.indexOf('.') + 2),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(Constants.textPrimaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        // Quotes
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(Constants.accentColor).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(Constants.accentColor).withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(Constants.accentColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.format_quote,
                    color: Color(Constants.accentColor),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: const Color(Constants.textPrimaryColor),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.contains('**') && line.split('**').length > 2) {
        // Bold text
        final parts = line.split('**');
        final textWidgets = <Widget>[];
        
        for (int j = 0; j < parts.length; j++) {
          if (j % 2 == 1) {
            // Bold text
            textWidgets.add(
              Text(
                parts[j],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(Constants.primaryColor),
                ),
              ),
            );
          } else {
            // Regular text
            textWidgets.add(
              Text(
                parts[j],
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(Constants.textPrimaryColor),
                ),
              ),
            );
          }
        }
        
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Wrap(children: textWidgets),
          ),
        );
      } else {
        // Regular paragraph
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(Constants.textPrimaryColor),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildArticleActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Actions header
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(Constants.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                                     child: const Icon(
                     Icons.touch_app,
                     color: Color(Constants.primaryColor),
                     size: 20,
                   ),
                ),
                const SizedBox(width: 16),
                Text(
                  'articles.article_detail.article_actions'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(Constants.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Like button
        Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLiked 
                        ? const Color(Constants.accentColor).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isLiked 
                          ? const Color(Constants.accentColor).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked 
                                ? const Color(Constants.accentColor)
                                : const Color(Constants.textSecondaryColor),
                            size: 24,
            ),
                          const SizedBox(width: 8),
                          Text(
              _isLiked ? 'articles.article_detail.liked'.tr() : 'articles.article_detail.like'.tr(),
              style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isLiked 
                                  ? const Color(Constants.accentColor)
                                  : const Color(Constants.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Bookmark button
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isBookmarked 
                        ? const Color(Constants.primaryColor).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isBookmarked 
                          ? const Color(Constants.primaryColor).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _isBookmarked = !_isBookmarked;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: _isBookmarked 
                                ? const Color(Constants.primaryColor)
                    : const Color(Constants.textSecondaryColor),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isBookmarked ? 'articles.article_detail.saved'.tr() : 'articles.article_detail.save'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isBookmarked 
                                  ? const Color(Constants.primaryColor)
                                  : const Color(Constants.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
        const SizedBox(width: 16),
              
              // Share button
        Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(Constants.secondaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(Constants.secondaryColor).withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _shareArticle();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.share,
                            color: Color(Constants.secondaryColor),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'articles.article_detail.share'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(Constants.secondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Article stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.visibility,
                  '${widget.article.viewCount}',
                  'articles.article_detail.views'.tr(),
                  const Color(Constants.primaryColor),
                ),
                _buildStatItem(
                  Icons.star,
                  widget.article.rating.toStringAsFixed(1),
                  'articles.article_detail.rating'.tr(),
                  const Color(Constants.accentColor),
                ),
                _buildStatItem(
                  Icons.access_time,
                  '${widget.article.readTime}',
                  'articles.article_detail.min_read_label'.tr(),
                  const Color(Constants.secondaryColor),
                ),
                _buildStatItem(
                  Icons.calendar_today,
                  DateFormat('MMM dd').format(widget.article.publishedAt),
                  'articles.article_detail.published'.tr(),
                  const Color(Constants.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(Constants.textSecondaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedArticles() {
    return Consumer<WellnessProvider>(
      builder: (context, wellnessProvider, child) {
        final relatedArticles = wellnessProvider.getRelatedArticles(
          widget.article.id,
          limit: 3,
        );

        if (relatedArticles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(Constants.primaryColor).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(Constants.primaryColor).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.article,
                    color: const Color(Constants.primaryColor),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
              'articles.article_detail.related_articles'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                        color: const Color(Constants.primaryColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: relatedArticles.length,
              itemBuilder: (context, index) {
                final article = relatedArticles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: article.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              article.imageUrl!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: const Color(Constants.primaryColor)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.article,
                                    color: Color(Constants.primaryColor),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(Constants.primaryColor)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.article,
                              color: Color(Constants.primaryColor),
                            ),
                          ),
                    title: Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(Constants.textPrimaryColor),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          article.summary ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(Constants.textSecondaryColor),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                article.categoryDisplayName,
                                style: TextStyle(
                                  color: _getCategoryColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'articles.article_detail.read_time_display'.tr(namedArgs: {'time': article.readTimeDisplay}),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(Constants.textSecondaryColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                            article: article,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor() {
    switch (widget.article.category) {
      case ArticleCategory.menstrualHealth:
        return const Color(Constants.periodColor);
      case ArticleCategory.fertility:
        return const Color(Constants.ovulationColor);
      case ArticleCategory.pregnancy:
        return const Color(Constants.primaryColor);
      case ArticleCategory.nutrition:
        return const Color(Constants.successColor);
      case ArticleCategory.exercise:
        return const Color(Constants.primaryColor);
      case ArticleCategory.fitness:
        return const Color(Constants.accentColor);
      case ArticleCategory.mentalHealth:
        return const Color(Constants.secondaryColor);
      case ArticleCategory.relationships:
        return const Color(Constants.accentColor);
      case ArticleCategory.medicalConditions:
        return const Color(Constants.errorColor);
      case ArticleCategory.lifestyle:
        return const Color(Constants.warningColor);
      case ArticleCategory.medical:
        return const Color(Constants.errorColor);
      case ArticleCategory.general:
        return const Color(Constants.textSecondaryColor);
    }
  }

  String _getCategoryName() {
    switch (widget.article.category) {
      case ArticleCategory.menstrualHealth:
        return 'articles.categories.menstrual_health'.tr();
      case ArticleCategory.fertility:
        return 'articles.categories.fertility'.tr();
      case ArticleCategory.pregnancy:
        return 'articles.categories.pregnancy'.tr();
      case ArticleCategory.nutrition:
        return 'articles.categories.nutrition'.tr();
      case ArticleCategory.exercise:
        return 'articles.categories.exercise'.tr();
      case ArticleCategory.fitness:
        return 'articles.categories.fitness'.tr();
      case ArticleCategory.mentalHealth:
        return 'articles.categories.mental_health'.tr();
      case ArticleCategory.relationships:
        return 'articles.categories.relationships'.tr();
      case ArticleCategory.medicalConditions:
        return 'articles.categories.medical_conditions'.tr();
      case ArticleCategory.lifestyle:
        return 'articles.categories.lifestyle'.tr();
      case ArticleCategory.medical:
        return 'articles.categories.medical'.tr();
      case ArticleCategory.general:
        return 'articles.categories.general'.tr();
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.article.category) {
      case ArticleCategory.menstrualHealth:
        return Icons.health_and_safety;
      case ArticleCategory.fertility:
        return Icons.pregnant_woman;
      case ArticleCategory.pregnancy:
        return Icons.child_care;
      case ArticleCategory.nutrition:
        return Icons.restaurant;
      case ArticleCategory.exercise:
        return Icons.directions_run;
      case ArticleCategory.fitness:
        return Icons.fitness_center;
      case ArticleCategory.mentalHealth:
        return Icons.psychology;
      case ArticleCategory.relationships:
        return Icons.favorite;
      case ArticleCategory.medicalConditions:
        return Icons.local_hospital;
      case ArticleCategory.lifestyle:
        return Icons.spa;
      case ArticleCategory.medical:
        return Icons.medical_services;
      case ArticleCategory.general:
        return Icons.article;
    }
  }

  Color _getDifficultyColor() {
    switch (widget.article.difficulty) {
      case ArticleDifficulty.beginner:
        return const Color(Constants.successColor);
      case ArticleDifficulty.intermediate:
        return const Color(Constants.warningColor);
      case ArticleDifficulty.advanced:
        return const Color(Constants.errorColor);
    }
  }

  IconData _getDifficultyIcon() {
    switch (widget.article.difficulty) {
      case ArticleDifficulty.beginner:
        return Icons.star;
      case ArticleDifficulty.intermediate:
        return Icons.star_half;
      case ArticleDifficulty.advanced:
        return Icons.star_border;
    }
  }

  void _shareArticle() async {
    try {
      final article = widget.article;
      final String title = article.title;
      final String bodySource = (article.content.isNotEmpty
          ? article.content
          : (article.summary.isNotEmpty ? article.summary : article.title));

      String clean(String text) {
        // Remove simple HTML tags and collapse extra spaces/newlines
        final withoutTags = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
        final normalizedSpaces = withoutTags.replaceAll(RegExp(r'[\t\r]'), ' ');
        final collapsed = normalizedSpaces.replaceAll(RegExp(r'\s+'), ' ').trim();
        // Re-insert paragraph breaks for periods to improve readability
        return collapsed.replaceAll('. ', '.\n\n');
      }

      final String fullText = clean(bodySource);
      final String shareBody = '${title}\n\n${fullText}\n\n— OvuMate';

      // Share full text as the message body (some targets ignore the subject)
      await Share.share(shareBody);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('articles.article_detail.image_load_error'.tr()),
        ),
      );
    }
  }

  void _rateArticle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('articles.article_detail.rate_article'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('articles.article_detail.rate_question'.tr()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < 3 ? Icons.star : Icons.star_border,
                    color: const Color(Constants.warningColor),
                    size: 32,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _submitRating(index + 1);
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('articles.article_detail.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _submitRating(int rating) {
    final wellnessProvider = Provider.of<WellnessProvider>(context, listen: false);
    wellnessProvider.rateArticle(widget.article.id, rating.toDouble());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('articles.article_detail.thank_you_rating'.tr()),
      ),
    );
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  'articles.article_detail.image_load_error'.tr(namedArgs: {'error': error.toString()}),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}



