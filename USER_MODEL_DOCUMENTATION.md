# Modèle Utilisateur avec SwiftData

Ce document explique comment utiliser le modèle utilisateur implémenté avec SwiftData dans l'application SplitBudget.

## Architecture

### 🏗️ Composants principaux

1. **`UserModel`** - Modèle SwiftData pour les utilisateurs
2. **`UserService`** - Service pour gérer les opérations CRUD
3. **`AuthManager`** - Gestionnaire d'authentification intégré
4. **Vues utilisateur** - Interface pour afficher et modifier les profils

### 📊 Modèle de données : `UserModel`

```swift
@Model
final class UserModel {
    @Attribute(.unique) var id: String          // ID unique Firebase
    var firstName: String                       // Prénom
    var lastName: String                        // Nom de famille
    var email: String                          // Adresse email
    var profileImageData: Data?                // Image de profil (données)
    var profileImageURL: String?               // URL de l'image de profil
    var createdAt: Date                        // Date de création
    var updatedAt: Date                        // Date de dernière modification
}
```

### 🔧 Propriétés calculées

- **`fullName`** : Nom complet (prénom + nom)
- **`initials`** : Initiales pour l'affichage de placeholder

## 🚀 Utilisation

### 1. Configuration initiale

SwiftData est configuré automatiquement dans `SplitBudgetApp.swift` :

```swift
var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Item.self,
        UserModel.self,  // ✅ Modèle utilisateur ajouté
    ])
    // ...
}()
```

### 2. Création d'utilisateurs

#### Depuis Google Sign-In
```swift
let userModel = try userService.createOrUpdateUserFromGoogleSignIn(
    firebaseUID: "firebase_uid",
    email: "user@example.com",
    displayName: "Jean Dupont",
    profileImageURL: "https://example.com/avatar.jpg"
)
```

#### Depuis inscription email
```swift
let userModel = try userService.createUserFromEmailSignUp(
    firebaseUID: "firebase_uid",
    email: "user@example.com",
    firstName: "Jean",
    lastName: "Dupont"
)
```

### 3. Opérations CRUD

```swift
// Récupération
let user = userService.getUserById("user_id")
let userByEmail = userService.getUserByEmail("user@example.com")
let users = userService.getAllUsers()
let searchResults = userService.searchUsers(by: "Jean")

// Mise à jour
user.firstName = "Jean-Claude"
try userService.updateUser(user)

// Suppression
try userService.deleteUser(user)
```

### 4. Gestion des images de profil

```swift
// Image depuis les données
user.updateProfileImage(data: imageData)

// Image depuis une URL
user.updateProfileImageURL("https://example.com/avatar.jpg")
```

## 📱 Interface utilisateur

### Vues disponibles

1. **`UserProfileView`** - Affichage du profil utilisateur connecté
2. **`EditProfileView`** - Modification du profil
3. **`UserListView`** - Liste de tous les utilisateurs
4. **`UserRowView`** - Cellule d'affichage d'un utilisateur

### Accès au profil

Dans `ContentView`, le bouton profil est accessible via la toolbar :

```swift
ToolbarItem(placement: .navigationBarLeading) {
    Button(action: { showingProfile = true }) {
        Label("Profil", systemImage: "person.circle")
    }
}
```

## 🔗 Intégration avec l'authentification

### AuthManager étendu

L'`AuthManager` gère maintenant :
- ✅ Authentification Firebase
- ✅ Création automatique du profil utilisateur
- ✅ Synchronisation avec SwiftData
- ✅ État du modèle utilisateur (`currentUserModel`)

### Workflow d'authentification

1. **Connexion** → Authentification Firebase
2. **Succès** → Création/mise à jour automatique dans SwiftData
3. **Synchronisation** → `currentUserModel` mis à jour
4. **Interface** → Profil affiché automatiquement

## 📝 Fonctionnalités

### ✅ Implémenté

- [x] Modèle SwiftData complet
- [x] Service CRUD avec gestion d'erreurs
- [x] Intégration avec Google Sign-In
- [x] Interface de profil utilisateur
- [x] Modification du profil avec photo
- [x] Recherche d'utilisateurs
- [x] Gestion des images (locale et URL)

### 🔄 Améliorations futures possibles

- [ ] Synchronisation cloud (Firebase Firestore)
- [ ] Cache d'images optimisé
- [ ] Validation avancée des données
- [ ] Historique des modifications
- [ ] Partage de profils entre utilisateurs

## 🎯 Points clés

1. **Persistence locale** : Toutes les données sont stockées localement avec SwiftData
2. **Synchronisation auto** : Le profil est créé automatiquement lors de la connexion
3. **Flexibilité images** : Support des images locales et distantes
4. **Interface intuitive** : Vues prêtes à l'emploi pour le profil
5. **Extensibilité** : Architecture modulaire facile à étendre

## 🔧 Configuration requise

- iOS 17.0+
- SwiftData
- Firebase Auth
- Google Sign-In
- PhotosUI (pour la sélection d'images)

L'implémentation est maintenant prête et fonctionnelle ! 🚀
