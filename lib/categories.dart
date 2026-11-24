const kToCheck = 'À vérifier';
const double kMinScore = 0.35;

// Un dossier avec poids > 1 gagne face aux dossiers génériques.
const Map<String, double> kWeights = {
  'Moteurs': 2.0,
  'Aquarium': 2.0,
  'Bateaux': 2.0,
  'Jeux': 1.5,
};

const Map<String, Set<String>> kCategories = {
  'Voitures': {
    'car', 'vehicle', 'wheel', 'tire', 'automotive', 'bumper', 'hood',
    'windshield', 'truck', 'motorcycle', 'van', 'taxi', 'headlamp', 'grille',
    'spoiler', 'rim', 'supercar', 'suv', 'sedan', 'hatchback', 'coupe',
    'paint', 'auto', 'automobile', 'fender', 'bodywork', 'steering',
    'dashboard',
  },
  'Moteurs': {
    'engine', 'cylinder', 'piston', 'turbo', 'turbocharger', 'exhaust',
    'radiator', 'machinery', 'mechanic', 'mechanical', 'gear', 'crankshaft',
    'transmission', 'carburetor', 'compressor', 'part', 'parts', 'spare',
    'engineering', 'machine', 'metal', 'steel', 'pipe', 'tube', 'hose', 'gas',
    'manifold', 'injector', 'intake', 'pulley', 'belt', 'bolt', 'gasket',
    'valve', 'camshaft', 'alternator', 'supercharger', 'intercooler',
  },
  'Alimentation': {
    'food', 'foods', 'dish', 'cuisine', 'meal', 'ingredient', 'recipe',
    'fruit', 'vegetable', 'dessert', 'drink', 'beverage', 'juice', 'soda',
    'tableware', 'baked', 'pizza', 'cake', 'bread', 'salad', 'meat',
    'cooking', 'breakfast', 'lunch', 'dinner', 'snack', 'coffee', 'tea',
    'wine', 'beer', 'cocktail', 'pasta', 'sushi', 'burger', 'chocolate',
    'produce', 'cup', 'mug', 'plate', 'bowl', 'baking', 'sweetness',
    'vegetarian', 'bottle', 'alcoholic', 'liqueur', 'whisky', 'champagne',
    'smoothie', 'milk', 'cola', 'drinkware', 'liquid',
  },
  'Paysages': {
    'sky', 'mountain', 'beach', 'sea', 'ocean', 'lake', 'nature', 'cloud',
    'sunset', 'sunrise', 'tree', 'forest', 'landscape', 'water', 'plant',
    'flower', 'grass', 'horizon', 'hill', 'river', 'field', 'snow', 'sand',
    'rock', 'wave', 'garden', 'leaf', 'meadow', 'valley', 'waterfall',
    'atmosphere', 'atmospheric', 'sunlight', 'dusk', 'dawn', 'bay', 'coast',
    'cliff', 'island', 'desert', 'lawn', 'shrub', 'vegetation', 'bush',
    'petal', 'blossom', 'botany', 'pasture', 'soil', 'highland',
  },
  'Animaux': {
    'cat', 'dog', 'animal', 'bird', 'pet', 'horse', 'fish', 'mammal',
    'carnivore', 'fur', 'snout', 'whiskers', 'puppy', 'kitten', 'wildlife',
    'insect', 'butterfly', 'cow', 'rabbit', 'reptile', 'organism',
    'vertebrate', 'feline', 'canine', 'paw', 'beak', 'wing', 'feather',
    'tail', 'bee', 'spider', 'duck', 'goat', 'sheep', 'pig', 'chicken',
    'deer', 'monkey', 'dolphin', 'whale', 'turtle', 'frog', 'snake',
    'lizard',
  },
  'Aquarium': {
    'aquarium', 'underwater', 'marine', 'reef', 'coral', 'freshwater',
    'aquatic', 'tank', 'seabed', 'anemone', 'jellyfish', 'goldfish',
    'clownfish', 'seaweed', 'saltwater',
  },
  'Textes et citations': {
    'text', 'font', 'handwriting', 'calligraphy', 'paper', 'document',
    'poster', 'screenshot', 'number', 'receipt', 'invoice', 'newspaper',
    'writing', 'paperwork', 'whiteboard', 'sign', 'signage', 'logo',
    'banner', 'label', 'page', 'web', 'book', 'publication', 'letter',
    'magazine', 'card', 'quote', 'quotation', 'menu', 'diagram', 'brand',
    'notebook',
  },
  'Personnes': {
    'person', 'face', 'smile', 'selfie', 'child', 'crowd', 'hair', 'skin',
    'facial', 'cheek', 'forehead', 'eyebrow', 'eyelash', 'beard', 'party',
    'wedding', 'baby', 'toddler', 'girl', 'boy', 'man', 'woman', 'lip',
    'nose', 'chin', 'jaw', 'fun', 'event', 'people', 'human', 'portrait',
    'eye', 'ear', 'head', 'neck', 'shoulder', 'friendship', 'interaction',
    'ceremony',
  },
  'Jeux': {
    'game', 'games', 'videogame', 'console', 'joystick', 'gamepad',
    'controller', 'arcade', 'playstation', 'xbox', 'nintendo', 'fictional',
    'cartoon', 'animation', 'anime', 'toy', 'puzzle', 'chess', 'poker',
    'dice', 'lego', 'software',
  },
  'Bateaux': {
    'boat', 'boats', 'watercraft', 'ship', 'vessel', 'yacht', 'sailboat',
    'sailing', 'ferry', 'canoe', 'kayak', 'motorboat', 'naval', 'mast',
    'harbor', 'harbour', 'dock', 'marina', 'boating', 'sail', 'speedboat',
    'transportation',
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
  String? best;
  double bestValue = 0;
  for (final e in scores.entries) {
    final v = e.value * (kWeights[e.key] ?? 1.0);
    if (e.value >= kMinScore && v > bestValue) {
      best = e.key;
      bestValue = v;
    }
  }
  return best ?? kToCheck;
}
