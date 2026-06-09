# Instructions pour Créer le Projet React Native

## 📋 Prérequis

### 1. Installer Node.js et npm
```bash
# Télécharger et installer Node.js depuis https://nodejs.org/
# Version recommandée : Node.js 18+ avec npm 9+
```

### 2. Installer React Native CLI
```bash
npm install -g @react-native-community/cli
```

### 3. Installer Expo CLI (alternative recommandée)
```bash
npm install -g @expo/cli
```

## 🚀 Méthode 1 : React Native CLI (Recommandée)

### 1. Créer le projet
```bash
# Naviguer vers le répertoire racine
cd c:\Users\jospel\Nora-v2

# Créer le projet TypeScript
npx react-native init NoraMobile --template react-native-template-typescript
```

### 2. Naviguer dans le projet
```bash
cd NoraMobile
```

### 3. Installer les dépendances principales
```bash
npm install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs
npm install @reduxjs/toolkit react-redux
npm install axios react-native-vector-icons
npm install react-native-gesture-handler react-native-reanimated
npm install react-native-safe-area-context react-native-screens
npm install @react-native-async-storage/async-storage
npm install react-native-image-picker react-native-camera
npm install react-native-maps react-native-geolocation-service
npm install react-native-qrcode-scanner react-native-video
```

### 4. Installer les dépendances de développement
```bash
npm install --save-dev @types/react @types/react-native
npm install --save-dev @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

## 🎯 Méthode 2 : Expo CLI (Plus Simple)

### 1. Créer le projet Expo
```bash
# Naviguer vers le répertoire racine
cd c:\Users\jospel\Nora-v2

# Créer le projet avec TypeScript
npx create-expo-app NoraMobile --template
```

### 2. Naviguer dans le projet
```bash
cd NoraMobile
```

### 3. Installer les dépendances spécifiques
```bash
npx expo install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs
npx expo install @reduxjs/toolkit react-redux
npx expo install axios react-native-vector-icons
npx expo install react-native-gesture-handler react-native-reanimated
npx expo install react-native-safe-area-context react-native-screens
npx expo install expo-camera expo-image-picker expo-location
npx expo install expo-av expo-maps expo-constants
```

## 📱 Configuration Android

### 1. Ouvrir Android Studio
- Télécharger Android Studio : https://developer.android.com/studio
- Installer Android SDK (API Level 33+)
- Configurer un émulateur ou utiliser un device physique

### 2. Configurer le projet
```bash
# Dans le dossier NoraMobile
npx react-native setup-android
```

### 3. Lancer l'application Android
```bash
npx react-native run-android
```

## 🍎 Configuration iOS (Mac uniquement)

### 1. Installer Xcode
- Télécharger depuis App Store
- Installer les command line tools

### 2. Installer CocoaPods
```bash
sudo gem install cocoapods
```

### 3. Installer les dépendances iOS
```bash
cd ios
pod install
cd ..
```

### 4. Lancer l'application iOS
```bash
npx react-native run-ios
```

## 🔧 Configuration Initiale

### 1. Mettre à jour package.json
```json
{
  "name": "NoraMobile",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "test": "jest",
    "lint": "eslint . --ext .js,.jsx,.ts,.tsx"
  }
}
```

### 2. Configurer babel.config.js
```javascript
module.exports = {
  presets: ['module:metro-react-native-babel-preset'],
  plugins: [
    'react-native-reanimated/plugin',
  ],
};
```

### 3. Configurer metro.config.js
```javascript
const {getDefaultConfig} = require('metro-config');

module.exports = (async () => {
  const {
    resolver: {sourceExts, assetExts},
  } = await getDefaultConfig();
  
  return {
    transformer: {
      babelTransformerPath: require.resolve('react-native-svg-transformer'),
    },
    resolver: {
      assetExts: assetExts.filter(ext => ext !== 'svg'),
      sourceExts: [...sourceExts, 'svg'],
    },
  };
})();
```

## 📁 Structure des Dossiers à Créer

### 1. Créer la structure principale
```bash
mkdir -p src/{components,screens,navigation,services,store,hooks,utils,constants,assets,types}
mkdir -p src/components/{common,home,products,shops,videos,cart,orders,delivery,mbCoins,interests,chat,profile}
mkdir -p src/screens/{auth,home,products,shops,videos,cart,orders,delivery,mbCoins,interests,chat,profile}
mkdir -p src/services/{api,storage,tracking}
mkdir -p src/assets/{images,icons,fonts}
```

### 2. Créer les fichiers de base
```bash
touch src/types/index.ts
touch src/constants/{api.ts,colors.ts,dimensions.ts,fonts.ts,images.ts,config.ts}
touch src/navigation/AppNavigator.tsx
touch src/store/store.ts
```

## 🎯 Prochaines Étapes

### 1. Démarrer le développement
```bash
# Démarrer Metro bundler
npm start

# Dans un autre terminal, lancer l'application
npm run android  # ou npm run ios
```

### 2. Ouvrir le projet dans VS Code
```bash
code .
```

### 3. Commencer par le Home Screen
- Créer `src/screens/home/HomeScreen.tsx`
- Implémenter les services API
- Ajouter la navigation
- Tester les produits recommandés

## 🔧 Dépannage

### Problèmes courants
1. **Metro bundler ne démarre pas** : `npx react-native start --reset-cache`
2. **Build Android échoue** : `cd android && ./gradlew clean && cd ..`
3. **Problèmes de dépendances** : `npm install --force`
4. **Problèmes iOS** : `cd ios && pod install && cd ..`

### Commandes utiles
```bash
# Nettoyer le cache
npm start -- --reset-cache

# Réinstaller les dépendances
rm -rf node_modules package-lock.json
npm install

# Vérifier la configuration
npx react-native doctor
```

## 📱 Test sur Device Physique

### Android
1. Activer le mode développeur
2. Activer le débogage USB
3. Connecter le téléphone
4. Lancer : `npx react-native run-android`

### iOS
1. Connecter l'iPhone au Mac
2. Faire confiance au développeur dans les réglages
3. Lancer : `npx react-native run-ios --device`

---

Une fois le projet créé, nous pourrons commencer à développer le Home Screen avec les produits recommandés personnalisés ! 🚀
