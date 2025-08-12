# Guide des Previews SwiftData

## 🎯 Problème résolu : Extra argument 'inMemory' in call

### ❌ Erreur rencontrée
```
Extra argument 'inMemory' in call
```

### 🔍 Cause du problème

Confusion entre deux syntaxes différentes pour créer des ModelContainer en mémoire :
1. **Syntaxe SwiftUI** : `.modelContainer(for:inMemory:)`
2. **Syntaxe DirectModelContainer** : `ModelConfiguration(isStoredInMemoryOnly:)`

## ✅ Solutions correctes

### 1. Preview avec SwiftUI modifier (Recommandé)

```swift
#Preview {
    ContentView()
        .modelContainer(for: [Item.self, UserModel.self], inMemory: true)
        .environmentObject(AuthManager())
}
```

### 2. Preview avec ModelContainer manuel

```swift
#Preview {
    let userModel = UserModel(
        id: "123",
        firstName: "Jean",
        lastName: "Dupont",
        email: "jean.dupont@example.com"
    )
    
    // ✅ Configuration correcte
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserModel.self, configurations: config)
    let context = ModelContext(container)
    
    return EditProfileView(
        user: userModel,
        userService: UserService(modelContext: context)
    )
}
```

### ❌ Syntaxes incorrectes à éviter

```swift
// ❌ Ne fonctionne pas
ModelConfiguration(inMemory: true)

// ❌ Ne fonctionne pas
ModelContainer(for: UserModel.self, configurations: ModelConfiguration(inMemory: true))
```

## 📋 Bonnes pratiques pour les previews

### 1. Previews simples (Views SwiftUI)

```swift
#Preview {
    UserProfileView()
        .modelContainer(for: [UserModel.self], inMemory: true)
        .environmentObject(AuthManager())
}
```

### 2. Previews avec données de test

```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserModel.self, configurations: config)
    let context = ModelContext(container)
    
    // Ajouter des données de test
    let user1 = UserModel(id: "1", firstName: "Jean", lastName: "Dupont", email: "jean@example.com")
    let user2 = UserModel(id: "2", firstName: "Marie", lastName: "Martin", email: "marie@example.com")
    
    context.insert(user1)
    context.insert(user2)
    
    return UserListView()
        .modelContainer(container)
}
```

### 3. Previews avec services personnalisés

```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserModel.self, configurations: config)
    let context = ModelContext(container)
    let userService = UserService(modelContext: context)
    
    let user = UserModel(id: "123", firstName: "Test", lastName: "User", email: "test@example.com")
    
    return EditProfileView(user: user, userService: userService)
}
```

## 🎨 Patterns courants

### Pattern 1: View avec @Environment
```swift
struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // View content
    }
}

#Preview {
    MyView()
        .modelContainer(for: [UserModel.self], inMemory: true)
}
```

### Pattern 2: View avec service injecté
```swift
struct MyView: View {
    let userService: UserService
    
    var body: some View {
        // View content
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserModel.self, configurations: config)
    let context = ModelContext(container)
    
    return MyView(userService: UserService(modelContext: context))
}
```

## 🔧 Résumé des syntaxes

| Contexte | Syntaxe |
|----------|---------|
| SwiftUI Preview | `.modelContainer(for: [Model.self], inMemory: true)` |
| Direct ModelContainer | `ModelConfiguration(isStoredInMemoryOnly: true)` |
| Production | `ModelConfiguration(isStoredInMemoryOnly: false)` |

## ⚠️ Points d'attention

1. **Toujours utiliser `inMemory: true`** dans les previews pour éviter d'affecter les vraies données
2. **Inclure tous les modèles nécessaires** dans le container
3. **Ajouter les EnvironmentObjects requis** (AuthManager, etc.)
4. **Utiliser `try!` avec précaution** - acceptable dans les previews uniquement

Cette approche garantit des previews fonctionnels et performants avec SwiftData.
