import '../models/clothing_item.dart';
import '../models/outfit.dart';

class MockData {
  static final List<ClothingItem> clothingItems = [
    ClothingItem(
      id: 'c1',
      name: 'White Linen Shirt',
      brand: 'COS',
      category: ClothingCategory.top,
      imageUrl:
          'https://images.unsplash.com/photo-1562157873-818bc0726f68?w=400',
      tags: ['casual', 'summer'],
      color: 'white',
      wearCount: 8,
    ),
    ClothingItem(
      id: 'c2',
      name: 'Navy Blazer',
      brand: 'Zara',
      category: ClothingCategory.top,
      imageUrl:
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400',
      tags: ['formal', 'work'],
      color: 'navy',
      wearCount: 5,
    ),
    ClothingItem(
      id: 'c3',
      name: 'Black Turtleneck',
      brand: 'Uniqlo',
      category: ClothingCategory.top,
      imageUrl:
          'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=400',
      tags: ['minimal', 'winter'],
      color: 'black',
      wearCount: 12,
    ),
    ClothingItem(
      id: 'c4',
      name: 'Slim Chinos',
      brand: 'H&M',
      category: ClothingCategory.pants,
      imageUrl:
          'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400',
      tags: ['casual', 'work'],
      color: 'beige',
      wearCount: 9,
    ),
    ClothingItem(
      id: 'c5',
      name: 'Dark Wash Jeans',
      brand: 'Levi\'s',
      category: ClothingCategory.pants,
      imageUrl:
          'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400',
      tags: ['casual', 'everyday'],
      color: 'dark blue',
      wearCount: 20,
    ),
    ClothingItem(
      id: 'c6',
      name: 'Wide-Leg Trousers',
      brand: 'Arket',
      category: ClothingCategory.pants,
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4b5c5f?w=400',
      tags: ['minimal', 'formal'],
      color: 'grey',
      wearCount: 3,
    ),
    ClothingItem(
      id: 'c7',
      name: 'White Sneakers',
      brand: 'Veja',
      category: ClothingCategory.shoes,
      imageUrl:
          'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=400',
      tags: ['casual', 'everyday'],
      color: 'white',
      wearCount: 25,
    ),
    ClothingItem(
      id: 'c8',
      name: 'Leather Chelsea Boots',
      brand: 'Dr. Martens',
      category: ClothingCategory.shoes,
      imageUrl:
          'https://images.unsplash.com/photo-1605812860427-4024433a70fd?w=400',
      tags: ['casual', 'streetwear'],
      color: 'black',
      wearCount: 10,
    ),
    ClothingItem(
      id: 'c9',
      name: 'Wool Beanie',
      brand: 'Norse Projects',
      category: ClothingCategory.hat,
      imageUrl:
          'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=400',
      tags: ['winter', 'casual'],
      color: 'forest green',
      wearCount: 7,
    ),
    ClothingItem(
      id: 'c10',
      name: 'Baseball Cap',
      brand: 'New Era',
      category: ClothingCategory.hat,
      imageUrl:
          'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400',
      tags: ['casual', 'streetwear'],
      color: 'black',
      wearCount: 15,
    ),
    ClothingItem(
      id: 'c11',
      name: 'Silver Watch',
      brand: 'Daniel Wellington',
      category: ClothingCategory.accessory,
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
      tags: ['formal', 'everyday'],
      color: 'silver',
      wearCount: 18,
    ),
    ClothingItem(
      id: 'c12',
      name: 'Leather Belt',
      brand: 'Anderson\'s',
      category: ClothingCategory.accessory,
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
      tags: ['formal', 'work'],
      color: 'tan',
      wearCount: 14,
    ),
    ClothingItem(
      id: 'c13',
      name: 'Striped Tee',
      brand: 'A.P.C.',
      category: ClothingCategory.top,
      imageUrl:
          'https://images.unsplash.com/photo-1554568218-0f1715e72254?w=400',
      tags: ['casual', 'breton'],
      color: 'navy/white',
      wearCount: 6,
    ),
    ClothingItem(
      id: 'c14',
      name: 'Loafers',
      brand: 'Tod\'s',
      category: ClothingCategory.shoes,
      imageUrl:
          'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=400',
      tags: ['formal', 'smart casual'],
      color: 'tan',
      wearCount: 4,
    ),
    ClothingItem(
      id: 'c15',
      name: 'Canvas Tote',
      brand: 'L.L.Bean',
      category: ClothingCategory.accessory,
      imageUrl:
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400',
      tags: ['casual', 'everyday'],
      color: 'natural',
      wearCount: 11,
    ),
  ];

  static final List<Outfit> outfits = [
    Outfit(
      id: 'o1',
      name: 'Casual Monday',
      itemIds: ['c1', 'c5', 'c7', 'c15'],
      style: 'casual',
    ),
    Outfit(
      id: 'o2',
      name: 'Work Smart',
      itemIds: ['c2', 'c4', 'c14', 'c11'],
      style: 'work',
    ),
    Outfit(
      id: 'o3',
      name: 'Winter Minimal',
      itemIds: ['c3', 'c6', 'c8', 'c12'],
      style: 'minimal',
    ),
    Outfit(
      id: 'o4',
      name: 'Weekend Out',
      itemIds: ['c13', 'c5', 'c7', 'c9'],
      style: 'casual',
    ),
    Outfit(
      id: 'o5',
      name: 'Sharp Evening',
      itemIds: ['c2', 'c6', 'c14', 'c11'],
      style: 'formal',
    ),
  ];

  static final Map<String, String> chatResponses = {
    'color season':
        'Your color season determines which palette suits you best. As a Spring type, you glow in warm, bright colors like coral, peach, golden yellow, and warm white. Avoid cool grays and stark black — opt for camel or chocolate brown instead.',
    'capsule wardrobe':
        'A capsule wardrobe has 30–37 versatile pieces that mix and match endlessly. Start with: 5 tops (2 tees, 1 shirt, 1 blouse, 1 sweater), 3 bottoms (2 pants, 1 skirt/shorts), 2 dresses/jumpsuits, 3 outerwear pieces, 5 shoe pairs, and a few quality accessories.',
    'style name':
        'Could you describe it more? "Quiet luxury" features neutral tones, minimal logos, and high-quality fabrics (think Loro Piana, The Row). "Old money" layers preppy classics like polos, loafers, and belted trousers. "Coastal grandmother" is breezy linens, wide-brim hats, and nautical stripes.',
    'streetwear':
        'Streetwear blends athletic and casual — think oversized hoodies, cargo pants, chunky sneakers, and graphic tees. Key brands: Supreme, Off-White, Palace. Layer a zip-up under an oversized bomber and pair with wide-leg jeans and platform Nikes.',
    'minimalist':
        'Minimalist fashion is about intentional choices: neutral palette (black, white, cream, grey, tan), clean cuts, no logos. Invest in quality basics from COS, Lemaire, or Totême. The trick is fit — minimal silhouettes live or die by precise tailoring.',
    'default':
        'Great question! Fashion is all about expressing yourself. Whether you\'re curating a capsule wardrobe, exploring a new aesthetic, or just figuring out what suits your lifestyle — I\'m here to help. What specifically would you like to explore?',
  };

  static String getChatResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    for (final key in chatResponses.keys) {
      if (lower.contains(key)) {
        return chatResponses[key]!;
      }
    }
    return chatResponses['default']!;
  }
}
