# Gestion du Main Actor avec SwiftData

## 🎯 Problème résolu : Main Actor Isolation

### ❌ Erreur rencontrée
```
Call to main actor-isolated instance method 'getUserById' in a synchronous nonisolated context
```

### 🔍 Cause du problème

SwiftData fonctionne étroitement avec le Main Actor pour garantir la cohérence des données dans l'interface utilisateur. Lorsqu'une classe est marquée `@MainActor`, toutes ses méthodes ne peuvent être appelées que depuis le main thread.

```swift
@MainActor
class UserService: ObservableObject {
    // Toutes les méthodes sont main actor-isolated
    func getUserById(_ id: String) -> UserModel? { ... }
}
```

### ✅ Solution implémentée

#### Avant (❌ Ne fonctionne pas)
```swift
class AuthManager: ObservableObject {
    private func loadCurrentUser(firebaseUID: String, userService: UserService) {
        currentUserModel = userService.getUserById(firebaseUID) // ❌ Erreur main actor
    }
    
    func configureUserService(_ userService: UserService) {
        if let user = user {
            loadCurrentUser(firebaseUID: user.uid, userService: userService) // ❌ Erreur
        }
    }
}
```

#### Après (✅ Fonctionne)
```swift
class AuthManager: ObservableObject {
    @MainActor
    private func loadCurrentUser(firebaseUID: String, userService: UserService) {
        currentUserModel = userService.getUserById(firebaseUID) // ✅ OK
    }
    
    func configureUserService(_ userService: UserService) {
        if let user = user {
            Task { @MainActor in
                loadCurrentUser(firebaseUID: user.uid, userService: userService) // ✅ OK
            }
        }
    }
}
```

## 🛠️ Bonnes pratiques

### 1. Services SwiftData avec @MainActor

```swift
@MainActor
class UserService: ObservableObject {
    private var modelContext: ModelContext
    
    // ✅ Toutes les méthodes sont automatiquement main actor-isolated
    func getUserById(_ id: String) -> UserModel? { ... }
    func saveUser(_ user: UserModel) throws { ... }
}
```

### 2. Appels depuis des contextes non-isolés

```swift
// ✅ Option 1: Marquer la méthode appelante
@MainActor
private func updateUI() {
    let user = userService.getUserById("123")
    // Mise à jour UI...
}

// ✅ Option 2: Utiliser Task { @MainActor in ... }
func someFunction() {
    Task { @MainActor in
        let user = userService.getUserById("123")
        // Mise à jour UI...
    }
}

// ✅ Option 3: DispatchQueue.main.async (pour les callbacks)
authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
    DispatchQueue.main.async {
        if let user = user, let userService = self?.userService {
            self?.loadCurrentUser(firebaseUID: user.uid, userService: userService)
        }
    }
}
```

### 3. Views SwiftUI et Main Actor

```swift
struct UserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var userService: UserService?
    
    var body: some View {
        // ✅ Les views SwiftUI s'exécutent sur le main actor
        VStack {
            // ...
        }
        .onAppear {
            setupUserService() // ✅ Automatiquement sur main actor
        }
    }
    
    private func setupUserService() {
        if userService == nil {
            userService = UserService(modelContext: modelContext) // ✅ OK
        }
    }
}
```

## ⚠️ Pièges à éviter

### 1. Appels async/await mal gérés

```swift
// ❌ Éviter ceci
func badExample() async {
    let user = userService.getUserById("123") // Erreur si pas sur main actor
}

// ✅ Correct
func goodExample() async {
    await MainActor.run {
        let user = userService.getUserById("123")
    }
}
```

### 2. Callbacks et closures

```swift
// ❌ Problématique
someAsyncFunction { result in
    let user = userService.getUserById("123") // Peut échouer
}

// ✅ Correct
someAsyncFunction { result in
    Task { @MainActor in
        let user = userService.getUserById("123")
    }
}
```

## 🎯 Résumé des solutions

| Contexte | Solution |
|----------|----------|
| Méthode de classe | `@MainActor private func methodName()` |
| Callback/Closure | `Task { @MainActor in ... }` |
| Firebase listener | `DispatchQueue.main.async { ... }` |
| SwiftUI View | Automatiquement sur main actor |
| Async function | `await MainActor.run { ... }` |

## 📈 Performance

- ✅ **Main Actor** garantit la sécurité des threads pour l'UI
- ✅ **SwiftData** optimisé pour fonctionner avec le Main Actor
- ✅ **Pas d'impact** sur les performances avec une utilisation correcte
- ⚠️ **Éviter** les opérations lourdes sur le Main Actor

Cette approche garantit la cohérence des données et la sécurité des threads dans votre application SwiftUI + SwiftData.
