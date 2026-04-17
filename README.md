# 🚗 AutoAssist+

**Application mobile d'assistance automobile intelligente pour conducteurs algériens**

Projet de fin d'études — Master 2 Informatique
Année universitaire 2025-2026

## 👥 Auteurs

- **Haythem Ramdani** — haythem.ramdani@gmail.com
- **Taha Mazouz** — mazouzt12@gmail.com

## 🎯 Description

AutoAssist+ est une application Flutter multiplateforme qui offre aux conducteurs algériens :

- 🔍 **Diagnostic intelligent** des pannes en darija, arabe ou français, basé sur l'IA Google Gemini
- 🗺️ **Géolocalisation** des garages, dépanneurs et stations-service à proximité via OpenStreetMap
- 🔧 **Gestion des entretiens** avec rappels automatiques (vidange, pneus, freins, distribution, etc.)
- 👤 **Profil véhicule** personnalisé (marque, modèle, année, kilométrage)
- 🔔 **Notifications locales** pour ne jamais manquer un entretien important

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.41 / Dart 3.11 |
| Authentification & Base de données | Firebase (Auth + Firestore) |
| Intelligence Artificielle | Google Gemini API |
| Cartographie | OpenStreetMap via flutter_map |
| Géolocalisation | Geolocator |
| Notifications | flutter_local_notifications |
| Plateforme cible | Android (API 23+) |

## 🚀 Installation

```bash
git clone https://github.com/haythem-ramdani/autoassist-plus.git
cd autoassist_plus
flutter pub get
flutter run
```

**Prérequis** : Flutter 3.24+, Android SDK 34+, projet Firebase configuré.

## 📄 Licence

Projet académique — tous droits réservés aux auteurs.