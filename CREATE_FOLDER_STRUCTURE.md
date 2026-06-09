# Script de Création de la Structure des Dossiers React Native

## 🚀 Instructions pour créer la structure complète

### Option 1 : Script PowerShell (Windows)

```powershell
# Créer la structure principale des dossiers
New-Item -ItemType Directory -Path "nora-mobile\src" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\navigation" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\store" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\hooks" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\utils" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\constants" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\types" -Force

# Créer les sous-dossiers de components
New-Item -ItemType Directory -Path "nora-mobile\src\components\common" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\onboarding" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\interests" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\home" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\products" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\shops" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\videos" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\cart" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\orders" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\delivery" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\mbCoins" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\chat" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\profile" -Force

# Créer les sous-dossiers de common components
New-Item -ItemType Directory -Path "nora-mobile\src\components\common\Button" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\common\Input" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\common\Card" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\common\Layout" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\common\Loading" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\components\common\Modal" -Force

# Créer les sous-dossiers de screens
New-Item -ItemType Directory -Path "nora-mobile\src\screens\onboarding" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\interests" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\home" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\products" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\shops" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\videos" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\cart" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\orders" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\delivery" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\mbCoins" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\chat" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\profile" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\screens\auth" -Force

# Créer les sous-dossiers de services
New-Item -ItemType Directory -Path "nora-mobile\src\services\api" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services\storage" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services\tracking" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services\notification" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services\location" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services\camera" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\services\validation" -Force

# Créer les sous-dossiers de store
New-Item -ItemType Directory -Path "nora-mobile\src\store\slices" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\store\middleware" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\store\selectors" -Force

# Créer les sous-dossiers d'assets
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\icons" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\fonts" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\animations" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\sounds" -Force

# Créer les sous-dossiers d'images
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\onboarding" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\categories" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\products" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\shops" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\icons" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\backgrounds" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\images\placeholders" -Force

# Créer les sous-dossiers d'icons
New-Item -ItemType Directory -Path "nora-mobile\src\assets\icons\tab" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\icons\categories" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\icons\actions" -Force
New-Item -ItemType Directory -Path "nora-mobile\src\assets\icons\social" -Force

Write-Host "Structure des dossiers créée avec succès !"
```

### Option 2 : Commandes manuelles

```bash
# Naviguer dans le projet React Native
cd nora-mobile

# Créer la structure principale
mkdir -p src/{components,screens,navigation,services,store,hooks,utils,constants,assets,types}

# Créer les sous-dossiers de components
mkdir -p src/components/{common,onboarding,interests,home,products,shops,videos,cart,orders,delivery,mbCoins,chat,profile}
mkdir -p src/components/common/{Button,Input,Card,Layout,Loading,Modal}

# Créer les sous-dossiers de screens
mkdir -p src/screens/{onboarding,interests,home,products,shops,videos,cart,orders,delivery,mbCoins,chat,profile,auth}

# Créer les sous-dossiers de services
mkdir -p src/services/{api,storage,tracking,notification,location,camera,validation}

# Créer les sous-dossiers de store
mkdir -p src/store/{slices,middleware,selectors}

# Créer les sous-dossiers d'assets
mkdir -p src/assets/{images,icons,fonts,animations,sounds}
mkdir -p src/assets/images/{onboarding,categories,products,shops,icons,backgrounds,placeholders}
mkdir -p src/assets/icons/{tab,categories,actions,social}
```

---

## 📁 Fichiers de base à créer

Après avoir créé la structure des dossiers, créez ces fichiers de base :

### 1. Types TypeScript
```typescript
// src/types/index.ts
export * from './api';
export * from './navigation';
export * from './auth';
export * from './onboarding';
export * from './interests';
export * from './products';
export * from './common';
```

### 2. Constantes
```typescript
// src/constants/api.ts
export const API_BASE_URL = 'http://localhost:8000/api';

export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/login',
    REGISTER: '/register',
    LOGOUT: '/logout',
  },
  INTERESTS: {
    LIST: '/user-interests',
    SELECT_MULTIPLE: '/user-interests/select-multiple',
    RECOMMENDED: '/user-interests/recommended-categories',
  },
  PRODUCTS: {
    RECOMMENDED: '/products/recommended',
    LIST: '/products',
    DETAIL: (id: string) => `/products/${id}`,
    SIMILAR: (id: string) => `/products/${id}/similar`,
  },
  // ... autres endpoints
};
```

### 3. Couleurs et Design
```typescript
// src/constants/colors.ts
export const colors = {
  primary: '#FF6B6B',
  secondary: '#4ECDC4',
  accent: '#45B7D1',
  success: '#96CEB4',
  warning: '#FFEAA7',
  error: '#FF7675',
  background: '#F8F9FA',
  surface: '#FFFFFF',
  text: '#2D3436',
  textSecondary: '#636E72',
  border: '#DFE6E9',
  shadow: '#000000',
};
```

### 4. Navigation
```typescript
// src/navigation/AppNavigator.tsx
import React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import AuthNavigator from './AuthNavigator';
import MainNavigator from './MainNavigator';
import {useAuth} from '../hooks/useAuth';

const AppNavigator: React.FC = () => {
  const {isAuthenticated} = useAuth();

  return (
    <NavigationContainer>
      {isAuthenticated ? <MainNavigator /> : <AuthNavigator />}
    </NavigationContainer>
  );
};

export default AppNavigator;
```

### 5. Store Redux
```typescript
// src/store/store.ts
import {configureStore} from '@reduxjs/toolkit';
import authSlice from './slices/authSlice';
import onboardingSlice from './slices/onboardingSlice';
import interestsSlice from './slices/interestsSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice,
    onboarding: onboardingSlice,
    interests: interestsSlice,
  },
  middleware: getDefaultMiddleware({
    serializableCheck: false,
  }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

---

## 🚀 Étapes suivantes

1. **Créer la structure des dossiers** avec le script PowerShell ou commandes manuelles
2. **Créer les fichiers de base** (types, constantes, navigation, store)
3. **Installer les dépendances** React Native
4. **Commencer par l'écran d'onboarding** avec les 4 images que tu vas fournir
5. **Développer l'écran de sélection des centres d'intérêt**
6. **Implémenter le Home Screen** avec produits recommandés

Une fois la structure créée, nous pourrons commencer à développer les écrans dans l'ordre : Onboarding → Intérêts → Home Screen ! 🎯
