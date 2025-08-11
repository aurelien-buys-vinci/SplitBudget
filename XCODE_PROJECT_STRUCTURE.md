# Structure du projet Xcode - Guide complet

## 📁 SplitBudget.xcodeproj - Qu'est-ce que c'est ?

Le dossier `.xcodeproj` n'est **PAS pour le build** directement, mais contient la **configuration du projet** Xcode.

### 🏗️ **Structure détaillée :**

```
SplitBudget.xcodeproj/
├── project.pbxproj                    ✅ GARDER (configuration projet)
├── project.xcworkspace/
│   ├── contents.xcworkspacedata       ✅ GARDER (structure workspace)
│   ├── xcshareddata/                  ✅ GARDER (config partagée)
│   └── xcuserdata/                    ❌ IGNORER (données utilisateur)
├── xcshareddata/
│   └── xcschemes/                     ✅ GARDER (schemes partagés)
└── xcuserdata/                        ❌ IGNORER (données utilisateur)
```

## ✅ **Fichiers à GARDER dans Git :**

### **project.pbxproj**
- **Rôle :** Configuration complète du projet
- **Contient :** Liste des fichiers, targets, build settings, dépendances
- **Pourquoi garder :** Essentiel pour reconstruire le projet

### **xcshareddata/**
- **Rôle :** Configurations partagées entre développeurs
- **Contient :** Schemes, breakpoints partagés, configurations CI/CD
- **Pourquoi garder :** Permet à tous les développeurs d'avoir la même config

### **contents.xcworkspacedata**
- **Rôle :** Structure du workspace Xcode
- **Contient :** Organisation des projets dans le workspace
- **Pourquoi garder :** Définit comment Xcode organise l'interface

## ❌ **Fichiers à IGNORER dans Git :**

### **xcuserdata/**
- **Rôle :** Préférences personnelles de l'utilisateur
- **Contient :** 
  - Position des fenêtres Xcode
  - Breakpoints personnels
  - Onglets ouverts
  - État de l'interface utilisateur
- **Pourquoi ignorer :** Spécifique à chaque développeur

## 🏗️ **Où se fait le BUILD réellement :**

### **DerivedData/** (ignoré par Git)
```
~/Library/Developer/Xcode/DerivedData/SplitBudget-xxx/
├── Build/                    # Fichiers compilés
├── Index/                    # Index pour autocomplétion
├── Logs/                     # Logs de build
└── ModuleCache/              # Cache des modules
```

### **build/** (ignoré par Git)
- Dossier temporaire de build local
- Créé automatiquement par Xcode
- Contient les fichiers .o, .app, etc.

## 🔧 **Ce qui a été nettoyé :**

```bash
# Supprimé du tracking Git :
ios-app/SplitBudget/SplitBudget.xcodeproj/xcuserdata/
ios-app/SplitBudget/SplitBudget.xcodeproj/project.xcworkspace/xcuserdata/
```

## 📋 **Résumé - Git et Xcode :**

| Type de fichier | Git | Rôle |
|---|---|---|
| `.xcodeproj/project.pbxproj` | ✅ Garder | Configuration projet |
| `.xcodeproj/xcshareddata/` | ✅ Garder | Config partagée |
| `.xcodeproj/xcuserdata/` | ❌ Ignorer | Préférences utilisateur |
| `DerivedData/` | ❌ Ignorer | Build cache |
| `build/` | ❌ Ignorer | Fichiers compilés |
| `.app`, `.ipa` | ❌ Ignorer | Applications compilées |

## 💡 **Bonne pratique :**

1. **Commitez** le `.xcodeproj` (sauf xcuserdata)
2. **Ignorez** tout ce qui est généré automatiquement
3. **Partagez** les schemes importants dans xcshareddata
4. **Nettoyez** régulièrement avec Product > Clean Build Folder

Votre configuration actuelle est maintenant parfaite ! 🎯
