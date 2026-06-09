# Configuration React Native sur Windows - Nora Marketplace

## 🔧 Problème : Scripts PowerShell désactivés

### Solution 1 : Activer l'exécution des scripts PowerShell

#### Étape 1 : Ouvrir PowerShell en tant qu'administrateur
1. Clique droit sur le menu Démarrer
2. Sélectionner "Windows PowerShell (administrateur)"
3. Confirmer avec "Oui"

#### Étape 2 : Activer les scripts
```powershell
# Pour la session actuelle uniquement
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Pour tous les utilisateurs (permanent)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

#### Étape 3 : Vérifier la politique
```powershell
Get-ExecutionPolicy
```

### Solution 2 : Utiliser CMD (Alternative plus simple)

#### Étape 1 : Ouvrir l'invite de commandes
1. Appuyer sur `Win + R`
2. Taper `cmd` et Entrée

#### Étape 2 : Naviguer vers le répertoire
```cmd
cd /d c:\Users\jospel\Nora-v2
```

#### Étape 3 : Créer le projet
```cmd
npx react-native init NoraMobile --template react-native-template-typescript
```

---

## 🚀 Instructions Complètes

### Option A : Avec PowerShell (Recommandée)

#### 1. Activer les scripts PowerShell
```powershell
# Ouvrir PowerShell en admin et exécuter :
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

#### 2. Créer le projet
```powershell
cd c:\Users\jospel\Nora-v2
npx react-native init NoraMobile --template react-native-template-typescript
```

#### 3. Naviguer dans le projet
```powershell
cd NoraMobile
```

#### 4. Installer les dépendances principales
```powershell
npm install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs
npm install @reduxjs/toolkit react-redux
npm install axios react-native-vector-icons
npm install react-native-gesture-handler react-native-reanimated
npm install react-native-safe-area-context react-native-screens
npm install @react-native-async-storage/async-storage
```

### Option B : Avec CMD (Plus simple si problème PowerShell)

#### 1. Ouvrir CMD
```
Win + R → cmd → Entrée
```

#### 2. Créer le projet
```cmd
cd /d c:\Users\jospel\Nora-v2
npx react-native init NoraMobile --template react-native-template-typescript
```

#### 3. Continuer avec CMD
```cmd
cd NoraMobile
npm install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs
```

---

## 📱 Configuration Android

### 1. Vérifier les prérequis
```cmd
# Vérifier Node.js
node --version

# Vérifier npm
npm --version

# Vérifier Java (pour Android)
java -version
```

### 2. Configurer Android Studio
1. Télécharger : https://developer.android.com/studio
2. Installer Android SDK (API Level 33+)
3. Créer un émulateur ou utiliser un device physique

### 3. Lancer l'application
```cmd
# Dans le dossier NoraMobile
npx react-native run-android
```

---

## 🍎 Configuration iOS (Mac uniquement)

### 1. Installer CocoaPods
```bash
sudo gem install cocoapods
```

### 2. Installer les dépendances iOS
```bash
cd ios
pod install
cd ..
```

### 3. Lancer l'application
```bash
npx react-native run-ios
```

---

## 🔧 Si les problèmes persistent

### Alternative 1 : Utiliser Expo CLI

#### 1. Installer Expo CLI
```cmd
npm install -g @expo/cli
```

#### 2. Créer le projet Expo
```cmd
cd c:\Users\jospel\Nora-v2
npx create-expo-app NoraMobile --template
```

#### 3. Installer les dépendances
```cmd
cd NoraMobile
npx expo install @react-navigation/native @reduxjs/toolkit react-redux
```

### Alternative 2 : Utiliser Chocolatey

#### 1. Installer Chocolatey
```powershell
# Ouvrir PowerShell en admin
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### 2. Installer Node.js via Chocolatey
```powershell
choco install nodejs
```

#### 3. Créer le projet
```powershell
cd c:\Users\jospel\Nora-v2
npx react-native init NoraMobile --template react-native-template-typescript
```

---

## 📋 Vérification de l'installation

### 1. Vérifier le projet créé
```cmd
# Vérifier que le dossier NoraMobile existe
dir c:\Users\jospel\Nora-v2\NoraMobile

# Vérifier les fichiers principaux
dir c:\Users\jospel\Nora-v2\NoraMobile\package.json
dir c:\Users\jospel\Nora-v2\NoraMobile\App.tsx
```

### 2. Vérifier les dépendances
```cmd
cd c:\Users\jospel\Nora-v2\NoraMobile
npm list --depth=0
```

### 3. Démarrer Metro bundler
```cmd
npm start
```

---

## 🚀 Prochaines étapes après création

### 1. Créer la structure des dossiers
```powershell
# Utiliser le script PowerShell dans CREATE_FOLDER_STRUCTURE.md
# Ou créer manuellement avec les commandes mkdir
```

### 2. Créer les fichiers de base
- Types TypeScript
- Constantes
- Navigation
- Store Redux

### 3. Commencer le développement
1. **OnboardingScreen** avec 4 images
2. **InterestSelectionScreen** 
3. **HomeScreen** avec produits recommandés

---

Une fois le projet créé, nous pourrons commencer à développer les écrans dans l'ordre : Onboarding → Intérêts → Home Screen ! 🎯
