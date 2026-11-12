# Changelog

## Unreleased

## 1.1.1 - 2026-11-12

### Changed
- Le logo fourni est maintenant l’icône de lancement Android et iOS.
- Le workflow de release construit maintenant Android et iOS sur GitHub Actions et joint l’APK ainsi que l’app iOS non signée.

## 1.1.0 - 2026-11-12

### Added
- Groupement des objets d’un sac par catégorie, avec le chemin complet des catégories imbriquées.
- Mode checklist activé par une secousse sur le détail d’un sac. L’état pris/non pris est conservé dans la base.
- Suppression d’un sac par glissement vers la gauche avec confirmation. Les objets restent dans l’inventaire.
- Nom affiché de l’application « My Rack » sur Android et iOS.

### Improved
- Espacement et défilement du formulaire d’ajout et de modification d’objet lorsque le clavier est ouvert.

## 1.0.0 - 2026-11-12

### Added
- Inventaire d’objets avec marque, modèle, poids, modification et suppression confirmée.
- Catégories hiérarchiques, sélection sur les objets et organisation manuelle.
- Création de sacs, ajout d’objets, gestion des quantités et calcul du poids total.
- Workflow GitHub Actions pour construire l’APK sur les pushes `main`/`master` et les tags de version, puis l’ajouter à la release.

### Fixed
- Mise à niveau d’Android Gradle Plugin vers 9.1.1 et de Gradle vers 9.7.0 pour permettre le build Android release avec Flutter.