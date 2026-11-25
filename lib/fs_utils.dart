import 'dart:io';

/// Chemin libre dans [dir] : ajoute _1, _2… si le nom existe déjà.
String uniquePath(String dir, String name) {
  var path = '$dir/$name';
  if (!File(path).existsSync()) return path;
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  final ext = dot > 0 ? name.substring(dot) : '';
  var i = 1;
  while (File(path).existsSync()) {
    path = '$dir/${base}_$i$ext';
    i++;
  }
  return path;
}

/// Déplace un fichier (copie + suppression si le simple renommage échoue).
Future<void> moveFile(File src, String dest) async {
  try {
    await src.rename(dest);
  } on FileSystemException {
    final copy = await src.copy(dest);
    if (await copy.length() == await src.length()) {
      await src.delete();
    } else {
      await copy.delete();
      throw const FileSystemException('copie incomplète');
    }
  }
}
