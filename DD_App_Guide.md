# 📱 DD App --- Guía de Instalación y Desarrollo (Flutter + Firebase)

## 🎯 Objetivo

Construir una MVP (Minimum Viable Product) de una app tipo "Designated
Driver bajo demanda" usando:

-   Flutter (Frontend)
-   Firebase (Backend)
-   Firestore (Base de datos)
-   Firebase Auth (Autenticación)

------------------------------------------------------------------------

# 🛠 PARTE 1 --- Instalación de Flutter

## 1️⃣ Instalar Flutter SDK

1.  Descargar Flutter desde la web oficial.
2.  Extraer el SDK en una carpeta (ejemplo: C:`\flutter `{=tex}o
    /Users/tuusuario/flutter).
3.  Añadir Flutter al PATH del sistema.

Verificar instalación:

``` bash
flutter doctor
```

Resolver cualquier error que aparezca.

------------------------------------------------------------------------

## 2️⃣ Instalar Android Studio

1.  Instalar Android Studio.
2.  Instalar:
    -   Android SDK
    -   Android SDK Command-line Tools
    -   Android Emulator
3.  Crear un dispositivo virtual (AVD).

Verificar nuevamente:

``` bash
flutter doctor
```

------------------------------------------------------------------------

## 3️⃣ Instalar Extensiones en VS Code

Instalar: - Flutter - Dart

Reiniciar VS Code.

------------------------------------------------------------------------

## 4️⃣ Crear Proyecto Flutter

``` bash
flutter create dd_app
cd dd_app
code .
flutter run
```

Si corre la app demo → entorno listo.

------------------------------------------------------------------------

# 🔥 PARTE 2 --- Configurar Firebase

## 1️⃣ Crear proyecto en Firebase Console

1.  Crear nuevo proyecto.
2.  Añadir app Android.
3.  Descargar `google-services.json`.
4.  Colocarlo en:

android/app/

------------------------------------------------------------------------

## 2️⃣ Añadir dependencias en pubspec.yaml

``` yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  firebase_messaging: ^latest
```

Ejecutar:

``` bash
flutter pub get
```

------------------------------------------------------------------------

## 3️⃣ Inicializar Firebase en main.dart

``` dart
await Firebase.initializeApp();
```

------------------------------------------------------------------------

# 🗄 PARTE 3 --- Estructura de Base de Datos

## 📂 Colección: users

userId - name: string - email: string - role: passenger \| driver -
rating: double - verified: boolean - createdAt: timestamp

------------------------------------------------------------------------

## 📂 Colección: rides

rideId - creatorId: string - driverId: string \| null - location:
string - time: timestamp - price: number - status: open \| accepted \|
completed \| cancelled - createdAt: timestamp

------------------------------------------------------------------------

# 🏗 PARTE 4 --- Estructura del Proyecto Flutter

lib/ ├── main.dart ├── core/ │ ├── theme.dart │ └── constants.dart ├──
models/ │ ├── user_model.dart │ └── ride_model.dart ├── services/ │ ├──
auth_service.dart │ └── ride_service.dart ├── screens/ │ ├──
login_screen.dart │ ├── role_selection_screen.dart │ ├──
home_screen.dart │ ├── create_ride_screen.dart │ └──
ride_detail_screen.dart └── widgets/ ├── ride_card.dart └──
custom_button.dart

------------------------------------------------------------------------

# 🚀 PARTE 5 --- Funcionalidades Importantes (MVP)

## 🔐 1️⃣ Autenticación

-   Registro con email y contraseña
-   Login
-   Persistencia de sesión

------------------------------------------------------------------------

## 👤 2️⃣ Selección de Rol

Después del registro: - Elegir: Pasajero o Conductor - Guardar en
Firestore

------------------------------------------------------------------------

## 📝 3️⃣ Crear Solicitud de Conductor

Campos: - Ubicación - Hora - Precio estimado - Número de personas

Guardar con status = open.

------------------------------------------------------------------------

## 📋 4️⃣ Lista de Solicitudes

-   Conductores ven rides con status = open
-   Filtro por zona (opcional en V1)

------------------------------------------------------------------------

## ✅ 5️⃣ Aceptar Ride

Cuando conductor acepta: - status = accepted - driverId = ID conductor

------------------------------------------------------------------------

## ⭐ 6️⃣ Sistema de Rating

Al finalizar: - Pasajero puntúa conductor - Actualizar promedio en
perfil

------------------------------------------------------------------------

## 🔔 7️⃣ Notificaciones (Opcional en V1.1)

-   Cuando aceptan tu ride
-   Cuando hay nueva solicitud cercana

------------------------------------------------------------------------

# 🎨 PARTE 6 --- Recomendaciones de UI

-   Modo oscuro (app nocturna)
-   Diseño minimalista
-   Flujo muy simple
-   Máximo 4-5 pantallas principales

------------------------------------------------------------------------

# ⚠️ NO HACER EN V1

-   ❌ Pagos integrados
-   ❌ Mapas complejos
-   ❌ Algoritmos avanzados
-   ❌ Integración con Uber aún
-   ❌ Sistema legal complejo

------------------------------------------------------------------------

# 🎯 OBJETIVO FINAL DE LA V1

Permitir que:

1.  Un usuario cree una solicitud.
2.  Un conductor la acepte.
3.  Ambos tengan confirmación clara.
4.  Se genere confianza con rating.

Si esto funciona en la vida real → entonces escalar.
