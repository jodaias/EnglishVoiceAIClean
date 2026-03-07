enum SessionScene {
  studio,
  city,
  library,
}

extension SessionSceneX on SessionScene {
  String get assetPath {
    switch (this) {
      case SessionScene.studio:
        return 'images/scenes/studio_scene.png';
      case SessionScene.city:
        return 'images/scenes/city_scene.png';
      case SessionScene.library:
        return 'images/scenes/library_scene.png';
    }
  }

  static SessionScene fromStorage(String raw) {
    switch (raw) {
      case 'city':
        return SessionScene.city;
      case 'library':
        return SessionScene.library;
      case 'studio':
      default:
        return SessionScene.studio;
    }
  }
}
