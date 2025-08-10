# Configuration des fichiers de projet

## Fichiers supprimés du contrôle de version

Les fichiers suivants ont été retirés du contrôle de version Git pour des raisons de sécurité et de configuration :

### ✅ Fichiers maintenant ignorés :
- **Info.plist** - Configuration spécifique au projet
- **SplitBudget.entitlements** - Droits et capabilities de l'app
- **GoogleService-Info.plist** - Clés Firebase (sensible)
- **xcuserdata/** - Données utilisateur Xcode
- **AuthManager_FreeVersion.swift** - Fichiers de développement
- **Autres fichiers de développement**

## 🔧 Configuration requise

### 1. Créer votre Info.plist
```bash
# Copiez le template vers le fichier final
cp ios-app/SplitBudget/SplitBudget/Info.plist.template ios-app/SplitBudget/SplitBudget/Info.plist
```

### 2. Configurer Google Sign-In dans Info.plist
1. Ouvrez votre `GoogleService-Info.plist`
2. Trouvez la valeur `REVERSED_CLIENT_ID`
3. Dans `Info.plist`, remplacez `YOUR_REVERSED_CLIENT_ID_HERE` par cette valeur

Exemple :
```xml
<string>com.googleusercontent.apps.123456789-abcdefghijk.apps.googleusercontent.com</string>
```

### 3. Créer votre SplitBudget.entitlements (optionnel)
Si vous voulez utiliser des capabilities spéciales (Keychain, etc.) :
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.yourcompany.SplitBudget</string>
    </array>
</dict>
</plist>
```

## 🛡️ Sécurité

### Pourquoi ces fichiers sont ignorés :
- **Info.plist** : Contient des URL schemes et configurations sensibles
- **GoogleService-Info.plist** : Contient vos clés API Firebase
- **entitlements** : Permissions spécifiques à votre certificat

### Avantages :
✅ **Sécurité** : Pas de clés sensibles dans le repository
✅ **Flexibilité** : Chaque développeur peut avoir sa config
✅ **Collaboration** : Pas de conflits sur les fichiers de config
✅ **Production** : Configurations différentes dev/prod possibles

## 📋 Checklist pour nouveaux développeurs

1. ✅ Cloner le repository
2. ✅ Copier `Info.plist.template` vers `Info.plist`
3. ✅ Ajouter votre `GoogleService-Info.plist` (obtenu de Firebase Console)
4. ✅ Modifier l'URL scheme dans `Info.plist`
5. ✅ Construire et tester le projet

## 🚨 Important

**JAMAIS** ajouter ces fichiers au Git :
```bash
# NE PAS FAIRE :
git add ios-app/SplitBudget/SplitBudget/Info.plist
git add ios-app/SplitBudget/SplitBudget/GoogleService-Info.plist
```

Le `.gitignore` est configuré pour les ignorer automatiquement.
