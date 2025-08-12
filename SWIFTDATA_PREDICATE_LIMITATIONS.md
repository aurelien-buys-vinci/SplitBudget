# Limitations des Prédicats SwiftData

## 🚫 Fonctions non supportées dans les prédicats SwiftData

SwiftData ne supporte pas toutes les fonctions Swift standard dans les prédicats `#Predicate`. Voici les principales limitations et solutions de contournement :

### ❌ Fonctions non supportées

```swift
// ❌ NE FONCTIONNE PAS
#Predicate { user in
    user.firstName.lowercased().contains("jean")     // lowercased() non supportée
    user.email.uppercased() == "JOHN@EXAMPLE.COM"   // uppercased() non supportée
    user.firstName.trimmingCharacters(in: .whitespaces) // trimmingCharacters non supportée
}
```

### ✅ Solutions de contournement

#### 1. Filtrage en mémoire (recommandé pour petites données)
```swift
func searchUsers(by name: String) -> [UserModel] {
    let allUsers = getAllUsers()
    let lowercaseName = name.lowercased()
    
    return allUsers.filter { user in
        user.firstName.lowercased().contains(lowercaseName) ||
        user.lastName.lowercased().contains(lowercaseName) ||
        user.email.lowercased().contains(lowercaseName)
    }
}
```

#### 2. Prédicat simple avec recherche exacte
```swift
func searchUsersExact(by name: String) -> [UserModel] {
    let descriptor = FetchDescriptor<UserModel>(
        predicate: #Predicate { user in
            user.firstName.contains(name) ||  // ✅ contains() supportée
            user.lastName.contains(name) ||
            user.email.contains(name)
        }
    )
    return try modelContext.fetch(descriptor)
}
```

#### 3. Normalisation des données lors de la sauvegarde
```swift
@Model
final class UserModel {
    var firstName: String
    var firstNameLowercase: String  // Version normalisée pour la recherche
    
    func updateFirstName(_ name: String) {
        self.firstName = name
        self.firstNameLowercase = name.lowercased()
    }
}
```

### 🎯 Fonctions supportées dans les prédicats

```swift
#Predicate { user in
    // ✅ Comparaisons
    user.firstName == "Jean"
    user.age > 18
    user.email != nil
    
    // ✅ Opérateurs logiques
    user.firstName == "Jean" && user.lastName == "Dupont"
    user.age > 18 || user.isVerified == true
    
    // ✅ Fonctions de chaîne de base
    user.firstName.contains("Je")
    user.email.hasPrefix("user")
    user.lastName.hasSuffix("son")
    
    // ✅ Fonctions de date
    user.createdAt > Date().addingTimeInterval(-86400)
    
    // ✅ Collections
    user.tags.contains("important")
    user.roles.isEmpty
}
```

### 💡 Recommandations

1. **Petites datasets** : Utilisez le filtrage en mémoire
2. **Grandes datasets** : Normalisez les données lors de la sauvegarde
3. **Recherche fréquente** : Créez des champs indexés normalisés
4. **Performance critique** : Utilisez Core Data directement pour des prédicats complexes

### 🔄 Migration depuis Core Data

Si vous migrez depuis Core Data, certains prédicats devront être adaptés :

```swift
// Core Data (NSPredicate)
NSPredicate(format: "firstName CONTAINS[cd] %@", searchTerm)

// SwiftData (équivalent)
// Option 1: Prédicat simple
#Predicate { user in user.firstName.contains(searchTerm) }

// Option 2: Filtrage en mémoire pour la casse
allUsers.filter { $0.firstName.localizedCaseInsensitiveContains(searchTerm) }
```

Cette approche garantit la compatibilité avec SwiftData tout en maintenant une fonctionnalité de recherche robuste.
