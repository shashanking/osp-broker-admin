// Describes one editable site-content section and its fields. The `type`
// matches the backend SiteContent.type (and the old Sanity `_type`), so the
// admin form stays in sync with what the user app fetches.

/// The kind of editor to render for a field, and how its value is (de)serialised.
enum CmsFieldKind {
  text,
  multiline,
  image,
  number,
  boolean,
  stringList,
  objectList,
}

class CmsFieldSpec {
  final String key;
  final String label;
  final CmsFieldKind kind;

  /// Only used for [CmsFieldKind.objectList]: the fields of each row.
  /// These are always simple kinds (text/multiline/image/number/boolean/stringList).
  final List<CmsFieldSpec> itemFields;

  const CmsFieldSpec(
    this.key,
    this.label, {
    this.kind = CmsFieldKind.text,
    this.itemFields = const [],
  });
}

class CmsSectionSpec {
  final String type;
  final String title;
  final String description;
  final List<CmsFieldSpec> fields;

  const CmsSectionSpec({
    required this.type,
    required this.title,
    required this.description,
    required this.fields,
  });
}

/// The sections wired up so far. Adding a new section is just adding an entry
/// here (no new screens needed).
const List<CmsSectionSpec> kCmsSections = [
  // ---------------------------------------------------------------------------
  // Existing text sections
  // ---------------------------------------------------------------------------
  CmsSectionSpec(
    type: 'homeHeroContent',
    title: 'Home — Hero',
    description: 'The hero banner at the top of the home page.',
    fields: [
      CmsFieldSpec('welcomePillText', 'Welcome pill text'),
      CmsFieldSpec('headlinePrefix', 'Headline prefix',
          kind: CmsFieldKind.multiline),
      CmsFieldSpec('headlinePrefixMobile', 'Headline prefix (mobile)',
          kind: CmsFieldKind.multiline),
      CmsFieldSpec('headlineHighlight', 'Headline highlight'),
      CmsFieldSpec('subtitle', 'Subtitle', kind: CmsFieldKind.multiline),
      CmsFieldSpec('trustPilotText', 'Trust pilot text'),
      CmsFieldSpec('auctionsButtonLabel', 'Auctions button label'),
      CmsFieldSpec('forumsButtonLabel', 'Forums button label'),
      CmsFieldSpec('rfpButtonLabel', 'RFP button label'),
    ],
  ),
  CmsSectionSpec(
    type: 'aboutUsContent',
    title: 'Home — About Us',
    description: 'The "About" section on the home page.',
    fields: [
      CmsFieldSpec('titlePrefix', 'Title prefix'),
      CmsFieldSpec('titleSuffixDesktop', 'Title suffix (desktop)'),
      CmsFieldSpec('titleSuffixMobile', 'Title suffix (mobile)',
          kind: CmsFieldKind.multiline),
      CmsFieldSpec('subtitle', 'Subtitle', kind: CmsFieldKind.multiline),
      CmsFieldSpec('buttonLabel', 'Button label'),
    ],
  ),
  CmsSectionSpec(
    type: 'getInTouchContent',
    title: 'Contact — Get In Touch',
    description: 'Contact details shown in the footer / contact section.',
    fields: [
      CmsFieldSpec('email', 'Email'),
      CmsFieldSpec('phone', 'Phone'),
      CmsFieldSpec('address', 'Address'),
    ],
  ),

  // ---------------------------------------------------------------------------
  // New text-only sections
  // ---------------------------------------------------------------------------
  CmsSectionSpec(
    type: 'auctionStartContent',
    title: 'Home — Auction Start',
    description: 'The auction call-to-action band on the home page.',
    fields: [
      CmsFieldSpec('startText', 'Start text'),
      CmsFieldSpec('highlightText', 'Highlight text'),
      CmsFieldSpec('endText', 'End text'),
      CmsFieldSpec('description', 'Description', kind: CmsFieldKind.multiline),
      CmsFieldSpec('buttonLabel', 'Button label'),
    ],
  ),
  CmsSectionSpec(
    type: 'rfpSectionContent',
    title: 'Home — RFP Section',
    description: 'The RFP promo section on the home page.',
    fields: [
      CmsFieldSpec('titlePrefix', 'Title prefix'),
      CmsFieldSpec('titleHighlight', 'Title highlight'),
      CmsFieldSpec('description', 'Description', kind: CmsFieldKind.multiline),
      CmsFieldSpec('buttonLabel', 'Button label'),
    ],
  ),
  CmsSectionSpec(
    type: 'membershipPageHeroContent',
    title: 'Membership Page — Hero',
    description: 'The hero banner on the membership page.',
    fields: [
      CmsFieldSpec('titlePrefix', 'Title prefix'),
      CmsFieldSpec('titleHighlight', 'Title highlight'),
      CmsFieldSpec('titleSuffix', 'Title suffix'),
      CmsFieldSpec('description', 'Description', kind: CmsFieldKind.multiline),
      CmsFieldSpec('buttonLabel', 'Button label'),
    ],
  ),
  CmsSectionSpec(
    type: 'membershipCardSectionContent',
    title: 'Membership — Card Section',
    description: 'Headings and state labels for the membership cards section.',
    fields: [
      CmsFieldSpec('headerTitle', 'Header title'),
      CmsFieldSpec('headerSubtitle', 'Header subtitle'),
      CmsFieldSpec('loadingTitle', 'Loading title'),
      CmsFieldSpec('errorTitle', 'Error title'),
      CmsFieldSpec('retryLabel', 'Retry label'),
      CmsFieldSpec('emptyTitle', 'Empty title'),
      CmsFieldSpec('emptySubtitle', 'Empty subtitle'),
      CmsFieldSpec('ctaLabel', 'CTA label'),
    ],
  ),
  CmsSectionSpec(
    type: 'footerSocialLinksContent',
    title: 'Footer — Social Links',
    description: 'Social media URLs shown in the footer.',
    fields: [
      CmsFieldSpec('instagramUrl', 'Instagram URL', kind: CmsFieldKind.image),
      CmsFieldSpec('facebookUrl', 'Facebook URL', kind: CmsFieldKind.image),
      CmsFieldSpec('xUrl', 'X (Twitter) URL', kind: CmsFieldKind.image),
    ],
  ),

  // ---------------------------------------------------------------------------
  // New sections with lists / images
  // ---------------------------------------------------------------------------
  CmsSectionSpec(
    type: 'whatWeOfferContent',
    title: 'Home — What We Offer',
    description: 'The "What We Offer" cards on the home page.',
    fields: [
      CmsFieldSpec('sectionTitle', 'Section title'),
      CmsFieldSpec('offers', 'Offers', kind: CmsFieldKind.objectList,
          itemFields: [
            CmsFieldSpec('icon', 'Icon', kind: CmsFieldKind.image),
            CmsFieldSpec('title', 'Title'),
            CmsFieldSpec('desc', 'Description', kind: CmsFieldKind.multiline),
          ]),
    ],
  ),
  CmsSectionSpec(
    type: 'featuredContent',
    title: 'Home — Featured',
    description: 'The featured auction and forum highlights section.',
    fields: [
      CmsFieldSpec('sectionTitle', 'Section title'),
      CmsFieldSpec('auctionTitle', 'Auction title'),
      CmsFieldSpec('auctionDescription', 'Auction description',
          kind: CmsFieldKind.multiline),
      CmsFieldSpec('likesLabel', 'Likes label'),
      CmsFieldSpec('commentsLabel', 'Comments label'),
      CmsFieldSpec('forumHighlights', 'Forum highlights',
          kind: CmsFieldKind.objectList,
          itemFields: [
            CmsFieldSpec('image', 'Image', kind: CmsFieldKind.image),
            CmsFieldSpec('title', 'Title'),
            CmsFieldSpec('description', 'Description',
                kind: CmsFieldKind.multiline),
          ]),
    ],
  ),
  CmsSectionSpec(
    type: 'testimonialContent',
    title: 'Home — Testimonials',
    description: 'The testimonials carousel on the home page.',
    fields: [
      CmsFieldSpec('headlinePrefix', 'Headline prefix'),
      CmsFieldSpec('headlineHighlightDesktop', 'Headline highlight (desktop)'),
      CmsFieldSpec('headlineHighlightMobile', 'Headline highlight (mobile)'),
      CmsFieldSpec('headlineSuffix', 'Headline suffix'),
      CmsFieldSpec('description', 'Description', kind: CmsFieldKind.multiline),
      CmsFieldSpec('testimonials', 'Testimonials',
          kind: CmsFieldKind.objectList,
          itemFields: [
            CmsFieldSpec('name', 'Name'),
            CmsFieldSpec('image', 'Image', kind: CmsFieldKind.image),
            CmsFieldSpec('text', 'Text', kind: CmsFieldKind.multiline),
            CmsFieldSpec('rating', 'Rating', kind: CmsFieldKind.number),
          ]),
    ],
  ),
  CmsSectionSpec(
    type: 'exploreContent',
    title: 'Home — Explore/Blog',
    description: 'The explore / blog cards section on the home page.',
    fields: [
      CmsFieldSpec('headerTitle', 'Header title'),
      CmsFieldSpec('headerDescription', 'Header description',
          kind: CmsFieldKind.multiline),
      CmsFieldSpec('buttonLabel', 'Button label'),
      CmsFieldSpec('blogCards', 'Blog cards', kind: CmsFieldKind.objectList,
          itemFields: [
            CmsFieldSpec('image', 'Image', kind: CmsFieldKind.image),
            CmsFieldSpec('date', 'Date'),
            CmsFieldSpec('author', 'Author'),
            CmsFieldSpec('title', 'Title'),
            CmsFieldSpec('desc', 'Description', kind: CmsFieldKind.multiline),
            CmsFieldSpec('isLarge', 'Is large', kind: CmsFieldKind.boolean),
          ]),
    ],
  ),
  CmsSectionSpec(
    type: 'homeMembershipSectionContent',
    title: 'Home — Membership Tiers',
    description: 'The membership tiers section on the home page.',
    fields: [
      CmsFieldSpec('headerTitle', 'Header title'),
      CmsFieldSpec('headerSubtitle', 'Header subtitle'),
      CmsFieldSpec('ctaLabel', 'CTA label'),
      CmsFieldSpec('tiers', 'Tiers', kind: CmsFieldKind.objectList,
          itemFields: [
            CmsFieldSpec('slug', 'Slug'),
            CmsFieldSpec('icon', 'Icon', kind: CmsFieldKind.image),
            CmsFieldSpec('title', 'Title'),
            CmsFieldSpec('price', 'Price'),
            CmsFieldSpec('priceLabel', 'Price label'),
            CmsFieldSpec('desc', 'Description', kind: CmsFieldKind.multiline),
            CmsFieldSpec('features', 'Features', kind: CmsFieldKind.stringList),
          ]),
    ],
  ),
];
