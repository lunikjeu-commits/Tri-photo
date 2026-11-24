const kToCheck = 'À vérifier';
const double kMinScore = 0.6;

const Map<String, Set<String>> kCategories = {
  'Voitures': {
    'car', 'vehicle', 'wheel', 'tire', 'automotive', 'bumper', 'hood',
    'windshield', 'motor', 'truck', 'motorcycle', 'van', 'taxi', 'headlamp',
    'grille', 'spoiler', 'rim', 'supercar', 'suv', 'sedan', 'hatchback',
    'coupe',
  },
  'Personnes': {
    'person', 'face', 'smile', 'selfie', 'child', 'crowd', 'hair', 'skin',
    'facial', 'cheek', 'forehead', 'eyebrow', 'eyelash', 'beard', 'party',
    'wedding', 'baby', 'toddler', 'girl', 'boy', 'man', 'woman', 'lip',
    'nose', 'chin', 'jaw',
  },
  'Nourriture': {
    'food', 'dish', 'cuisine', 'meal', 'ingredient', 'recipe', 'fruit',
    'vegetable', 'dessert', 'drink', 'tableware', 'baked', 'pizza', 'cake',
    'bread', 'salad', 'meat', 'cooking', 'breakfast', 'lunch', 'dinner',
    'snack', 'coffee', 'wine', 'beer', 'cocktail', 'pasta', 'sushi',
    'burger', 'chocolate',
  },
  'Animaux': {
    'cat', 'dog', 'animal', 'bird', 'pet', 'horse', 'fish', 'mammal',
    'carnivore', 'fur', 'snout', 'whiskers', 'puppy', 'kitten', 'wildlife',
    'insect', 'butterfly', 'cow', 'rabbit', 'reptile',
  },
  'Paysages': {
    'sky', 'mountain', 'beach', 'sea', 'ocean', 'lake', 'nature', 'cloud',
    'sunset', 'sunrise', 'tree', 'forest', 'landscape', 'water', 'plant',
    'flower', 'grass', 'horizon', 'hill', 'river', 'field', 'snow', 'sand',
    'rock', 'wave', 'garden', 'leaf', 'meadow', 'valley', 'waterfall',
  },
  'Documents': {
    'text', 'document', 'paper', 'font', 'handwriting', 'receipt', 'poster',
    'notebook', 'menu', 'newspaper', 'invoice', 'paperwork', 'writing',
    'screenshot', 'number', 'ticket', 'whiteboard', 'diagram',
  },
  'Bâtiments': {
    'building', 'architecture', 'city', 'house', 'skyscraper', 'tower',
    'bridge', 'street', 'road', 'urban', 'church', 'castle', 'monument',
    'facade', 'landmark', 'town', 'neighbourhood', 'residential',
    'cityscape', 'apartment', 'temple',
  },
  'Maison': {
    'furniture', 'room', 'table', 'chair', 'couch', 'interior', 'kitchen',
    'bedroom', 'bathroom', 'sofa', 'bed', 'shelf', 'lamp', 'curtain',
    'cabinetry', 'countertop', 'flooring', 'living', 'home', 'appliance',
    'desk', 'carpet', 'tile',
  },
  'Sport': {
    'sport', 'ball', 'stadium', 'player', 'football', 'basketball', 'tennis',
    'running', 'swimming', 'cycling', 'athlete', 'gym', 'fitness', 'golf',
    'skiing', 'surfing', 'soccer', 'recreation',
  },
};

/// Choisit le dossier selon les étiquettes ML Kit (nom, confiance).
String pickCategory(Iterable<MapEntry<String, double>> labels) {
  final scores = <String, double>{};
  for (final e in labels) {
    final label = e.key.toLowerCase();
    final words = label.split(RegExp(r'[\s/\-]+'));
    kCategories.forEach((cat, keys) {
      if (keys.contains(label) || words.any(keys.contains)) {
        scores[cat] = (scores[cat] ?? 0) + e.value;
      }
    });
  }
  if (scores.isEmpty) return kToCheck;
  final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return best.value >= kMinScore ? best.key : kToCheck;
}
