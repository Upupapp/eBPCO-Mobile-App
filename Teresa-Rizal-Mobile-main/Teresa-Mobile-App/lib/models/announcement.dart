/// Mirrors one post from config/teresa_rizal_balita.php ('Balita' = news in
/// Filipino) as consumed by citizen/announcements.blade.php and the
/// dashboard's Balita preview. Likes/comments/shares/new posts are a pure
/// frontend simulation persisted via BalitaService (SharedPreferences,
/// same pattern as RequestsService) — there is no backend for the social
/// feed, and [toJson]/[fromJson] exist only to support that local
/// persistence, never a network call.
class Announcement {
  final String id;
  final String official; // e.g. "Teresa, Rizal LGU" — empty if a personal/resident post
  final String author;
  final String? barangay;

  /// Card headline. When omitted, the first line of [body] is the title.
  final String? title;

  /// Feed chip: `Abiso` or `Programa`. `Lahat` is the unfiltered chip.
  final String kind;
  final String body;
  final String time;
  final PostMedia? media;
  int likes;
  bool liked;
  int shares;
  int viewCount;

  /// Visible sample lives in [comments]. This is the count shown on the
  /// card, the sheet, and the detail social row. A local prototype may
  /// list a short sample while the total stays at the published figure.
  /// Null from JSON means the sample list is the whole thread.
  int commentTotal;
  final List<PostComment> comments;

  Announcement({
    required this.id,
    required this.official,
    required this.author,
    this.barangay,
    this.title,
    this.kind = 'Abiso',
    required this.body,
    required this.time,
    this.media,
    required this.likes,
    this.liked = false,
    this.shares = 0,
    this.viewCount = 0,
    List<PostComment>? comments,
    int? commentTotal,
    // Copied rather than assigned directly: several seed posts in
    // MockCatalog pass `comments: const []` (or a `const [PostComment(...)]`
    // literal) for a clean declaration, but a const list is immutable at
    // runtime — BalitaService.addComment's `post.comments.add(...)` would
    // throw "Cannot add to an unmodifiable list" the moment someone tried
    // to leave the very first comment on one of those posts. A growable
    // copy here means the constructor's own contract (comments can always
    // be appended to) holds regardless of how a caller constructed the
    // list it passed in.
  }) : comments = comments != null ? List.of(comments) : [],
       commentTotal = commentTotal ?? comments?.length ?? 0;

  bool get isOfficial => official.isNotEmpty;

  /// Count on the feed card and the comments sheet.
  int get commentCount => commentTotal;

  /// Count on the detail social row. The published total wins until the
  /// local sample outgrows it.
  int get shownCommentCount {
    final sample = comments.length;
    return sample > commentTotal ? sample : commentTotal;
  }

  /// Blank-line paragraphs. A single block stays one paragraph.
  List<String> get paragraphs {
    final text = displayBody.trim();
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Headline shown on the card and in the viewer. One place only, so the
  /// body does not repeat it.
  String get displayTitle {
    final explicit = title?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final line = body.split('\n').first.trim();
    return line.isEmpty ? 'Balita' : line;
  }

  /// Body under the headline. When [title] is set, [body] is the lede as-is.
  String get displayBody {
    if (title != null && title!.trim().isNotEmpty) return body.trim();
    final parts = body.split('\n');
    if (parts.length <= 1) return '';
    return parts.skip(1).join('\n').trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'official': official,
        'author': author,
        'barangay': barangay,
        'title': title,
        'kind': kind,
        'body': body,
        'time': time,
        'media': media?.toJson(),
        'likes': likes,
        'liked': liked,
        'shares': shares,
        'viewCount': viewCount,
        'commentTotal': commentTotal,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'],
        official: json['official'],
        author: json['author'],
        barangay: json['barangay'],
        title: json['title'],
        kind: json['kind'] as String? ?? 'Abiso',
        body: json['body'],
        time: json['time'],
        media: json['media'] != null ? PostMedia.fromJson(json['media']) : null,
        likes: json['likes'],
        liked: json['liked'] ?? false,
        shares: json['shares'] ?? 0,
        viewCount: json['viewCount'] ?? 0,
        commentTotal: json['commentTotal'] is int ? json['commentTotal'] as int : null,
        comments: (json['comments'] as List? ?? []).map((c) => PostComment.fromJson(c)).toList(),
      );
}

/// A single mock comment on a Balita post, added either from seed data or
/// locally by the signed-in citizen via the Comments sheet.
class PostComment {
  final String author;
  final String body;
  final String time;

  PostComment({required this.author, required this.body, this.time = 'Just now'});

  Map<String, dynamic> toJson() => {'author': author, 'body': body, 'time': time};

  factory PostComment.fromJson(Map<String, dynamic> json) =>
      PostComment(author: json['author'], body: json['body'], time: json['time'] ?? 'Just now');
}

enum PostMediaType { image, video }

/// Stand-in for a Balita photo that is not in the bundle yet. The feed and
/// the viewer paint a dashed 16:9 slot instead of loading an image file.
const String balitaPhotoSlotPath = 'dashed-slot';

/// A single media attachment on a Balita post — either a bundled seed
/// asset (`isAsset: true`, used only by MockCatalog's sample posts) or a
/// real file the citizen picked on-device via image_picker (`isAsset:
/// false`, `path` is a local filesystem path). Never a remote URL: there
/// is no upload/backend for Balita, by design — this is local-only
/// simulation, same as `Attachment.localPath` for document requests.
class PostMedia {
  final String path;
  final PostMediaType type;
  final bool isAsset;
  final String? fileName;

  const PostMedia({
    required this.path,
    required this.type,
    this.isAsset = false,
    this.fileName,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'type': type.name,
        'isAsset': isAsset,
        'fileName': fileName,
      };

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
        path: json['path'],
        type: PostMediaType.values.firstWhere((t) => t.name == json['type'], orElse: () => PostMediaType.image),
        isAsset: json['isAsset'] ?? false,
        fileName: json['fileName'],
      );
}

/// Mirrors an entry from citizen/events.blade.php's $events array, plus
/// an optional poster [imagePath]/[category] the Web Admin would attach
/// when publishing a real event — each event is its own independent
/// entry/card even when several share a venue or general topic (e.g. a
/// basketball tournament's separate match-day posters), never merged
/// into one combined container.
class EventItem {
  final String? id;
  final String title;
  final String date;
  final String time;
  final String venue;
  final String? imagePath;
  final String? category;

  /// One-line lede under the title on the detail page.
  final String? summary;

  /// Ordered agenda lines. Empty hides the agenda block.
  final List<String> agenda;

  /// Second line under Where. Text address only — no map.
  final String? whereNote;

  /// Extra sentence under the ended banner. Past events only.
  final String? endedDetail;

  /// Catalog flag for the Upcoming / Past chips. Not inferred from [date],
  /// so the seeded August cards can stay on Upcoming until a later season.
  final bool upcoming;

  /// Free chip. Independent of [upcoming].
  final bool isFree;

  EventItem({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    this.imagePath,
    this.category,
    this.summary,
    this.agenda = const [],
    this.whereNote,
    this.endedDetail,
    this.upcoming = true,
    this.isFree = false,
  });

  String get whenLine => '$date · $time';
}

/// A government office entry, mirroring citizen/directory.blade.php.
class DirectoryOffice {
  final String name;
  final String head;
  final String contact;
  final String address;
  final String hours;

  DirectoryOffice({
    required this.name,
    required this.head,
    required this.contact,
    required this.address,
    required this.hours,
  });
}
