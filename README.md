# Blood Bowl League Manager Frontend

## Modelo de despliegue (GitHub Actions + Cloudflare Pages)

Este proyecto se despliega automaticamente a Cloudflare Pages cuando hay un push a la rama `main` mediante el workflow [.github/workflows/deploy.yml](.github/workflows/deploy.yml).

### Flujo de despliegue

1. Se hace `push` a `main`.
2. GitHub Actions ejecuta el job `deploy` en `ubuntu-latest`.
3. Se instala Flutter `3.29.0` (canal `stable`).
4. Se instalan dependencias con `flutter pub get`.
5. Se genera codigo con `build_runner`:
  - `flutter pub run build_runner build --delete-conflicting-outputs`
6. Se construye la version web en modo release:
  - `flutter build web --release`
7. Se publica en Cloudflare Pages con Wrangler:
  - `pages deploy build/web --project-name=blood-bowl-manager-front --commit-dirty=true`

### Trigger actual

- Evento: `push`
- Rama: `main`

No hay despliegues automaticos para ramas de feature ni para pull requests con la configuracion actual.

### Requisitos en GitHub (Secrets)

Configurar estos secrets en el repositorio (`Settings > Secrets and variables > Actions`):

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

Permisos recomendados para el token de Cloudflare:

- `Cloudflare Pages: Edit`
- `Account: Read` (si aplica segun politica de la cuenta)

### Requisitos en Cloudflare Pages

1. Crear el proyecto Pages con nombre exacto: `blood-bowl-manager-front`.
2. El despliegue lo hace GitHub Actions via API (Wrangler), por lo que el build principal ocurre en Actions.
3. La carpeta publicada es `build/web` (salida de `flutter build web --release`).

### Modelo de entorno

- Produccion: despliegue directo desde `main`.
- Estrategia: CI/CD simple de una sola via (single-branch release).

Esto implica que cualquier merge/push en `main` impacta directamente en el sitio publicado.

### Operacion y verificacion

Despues de cada push a `main`:

1. Revisar ejecucion en `Actions` dentro de GitHub.
2. Confirmar que el job `Deploy to Cloudflare Pages` termina en estado `success`.
3. Validar en Cloudflare Pages que se genero un nuevo deployment.
4. Hacer smoke test rapido del sitio (carga inicial, rutas principales y assets).

### Rollback recomendado

Si un despliegue falla funcionalmente:

1. Revertir el commit en `main`.
2. Hacer push del revert.
3. El workflow vuelve a ejecutar y publica la version previa estable.

### Despliegue manual (opcional, desde local)

Solo para casos puntuales. El flujo oficial es por GitHub Actions.

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release
npx wrangler pages deploy build/web --project-name=blood-bowl-manager-front
```

## Deuda técnica (hallazgos del análisis estático)

Problemas identificados con `flutter analyze` (808 issues: 0 errores, 143 warnings, 665 infos) y revisión manual del código. Ordenados por prioridad.

---

### 🔴 Crítico

#### 1. `use_build_context_synchronously` en `player_card_screen.dart`
**Riesgo:** crash en producción si el widget se desmonta mientras espera un `await`.
**Fichero:** `lib/features/roster/presentation/screens/player_card_screen.dart` — líneas 170, 180, 521, 529.
**Fix:** añadir `if (!mounted) return;` inmediatamente después de cada `await`, antes de cualquier uso de `context` o `ref`.

```dart
await someAsyncCall();
if (!mounted) return;   // <-- añadir esto
ScaffoldMessenger.of(context).showSnackBar(...);
```

#### 2. Cero tests reales
**Riesgo:** cualquier refactor puede romper funcionalidad sin que haya red de seguridad.
**Fichero:** `test/widget_test.dart` — solo contiene `expect(true, isTrue)`.
**Fix mínimo:** añadir tests unitarios para `AuthNotifier` (login/logout/error) y `LeagueRepository`, y al menos un widget test para `PlayerRow`.

---

### 🟠 Importante

#### 3. Estilos tipográficos hardcodeados en todos los screens (DRY crítico)
**Problema:** cada pantalla declara `TextStyle(fontSize: X)` inline, con los mismos valores repetidos en 20+ ficheros. Si se quiere cambiar el tamaño de una etiqueta de sección hay que editar ~15 ficheros.
**Evidencia:** `team_creator_screen.dart` tiene 70 apariciones de `fontSize:`, `my_team_detail_screen.dart` tiene 63, `aftermatch_screen.dart` tiene 52.
**Fix:** usar `Theme.of(context).textTheme.*` que ya está definido en `AppTheme.darkTheme`. Mapeo propuesto:
- `fontSize: 36` → `textTheme.displayMedium`
- `fontSize: 20–18` → `textTheme.titleMedium`
- `fontSize: 13` → `textTheme.bodyMedium`
- `fontSize: 12–11` → `textTheme.bodySmall`

#### 4. `AppTextStyles` duplica la escala tipográfica de `AppTheme` con valores distintos
**Ficheros:** `lib/core/theme/app_colors.dart` (AppTextStyles) vs `lib/core/theme/app_theme.dart` (textTheme).
**Problema:** `bodySmall` es `fontSize: 15` en `AppTextStyles` pero `fontSize: 13` en `textTheme`. Dos fuentes de verdad para lo mismo.
**Fix:** eliminar `AppTextStyles` por completo y dejar solo `textTheme` como referencia.

#### 5. Pantallas wiki sin abstracción de layout (copias casi exactas)
**Ficheros:** `wiki_weather_screen.dart`, `wiki_blocking_screen.dart`, `wiki_passing_screen.dart`, `wiki_injuries_screen.dart`, `wiki_skills_screen.dart`.
**Problema:** misma estructura (cabecera, grid de tarjetas, descripción rica, tooltip de dados) repetida en cada fichero. Mismo `TextStyle(fontSize: 18)`, mismo `BorderRadius.circular(8)`, mismos colores.
**Fix:** extraer `lib/features/wiki/presentation/widgets/wiki_page_layout.dart` con un widget reutilizable y pasar el contenido como parámetro.

#### 6. `BorderRadius` hardcodeado sin constantes compartidas
**Problema:** `BorderRadius.circular(8)`, `BorderRadius.circular(12)`, `BorderRadius.circular(4)` aparecen 14–32 veces por fichero sin ninguna constante.
**Fix:** añadir en `lib/core/theme/` un `app_dimensions.dart`:
```dart
abstract class AppDimensions {
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
}
```

#### 7. God files — ficheros con responsabilidades múltiples
- `lib/features/shared/data/repositories.dart` (942 líneas): contiene `LeagueRepository`, `TeamRepository` y `QuickMatchRepository` juntos. Separar en tres ficheros independientes.
- `lib/core/shell/app_shell.dart` (617 líneas): sidebar desktop, bottom nav mobile, drawer, header y lógica de navegación mezclados. Extraer `SideNav`, `BottomNav`, `AppDrawer`, `AppShellHeader` como widgets propios.
- `lib/features/team_creator/presentation/screens/team_creator_screen.dart` (>2500 líneas): extraer cada paso del wizard en su propio widget.

#### 8. Índices de navegación mágicos en `app_shell.dart`
**Fichero:** `lib/core/shell/app_shell.dart` — función `_resolveSelectedIndex`.
**Problema:** mapeo de rutas a índices 0–17 con números literales y solo comentarios como documentación.
**Fix:** usar un enum o mapa de constantes nombradas.

#### 9. `invalid_annotation_target` — 35 warnings en `team.dart`
**Fichero:** `lib/features/roster/domain/models/team.dart`.
**Problema:** `@JsonKey` colocado en posición incompatible con la versión actual de `freezed_annotation`. Genera warnings en toda compilación.
**Fix:** actualizar `freezed_annotation` a `^3.x` o mover las anotaciones `@JsonKey` al constructor factory `fromJson`, siguiendo la guía de migración de freezed 3.

#### 10. Código muerto en `team_creator_screen.dart`
**Fichero:** `lib/features/team_creator/presentation/screens/team_creator_screen.dart`.
**Problema:** funciones `_buildVerticalSteps`, `_buildRecruitedPlayer` y `_buildStaffStep` definidas pero nunca llamadas.
**Fix:** eliminarlas o implementarlas si son funcionalidades pendientes.

---

### 🟡 Mejora

#### 11. `.withOpacity()` deprecado — ~50 usos en todo el proyecto
**Problema:** `Color.withOpacity()` está deprecado en Flutter 3.x. El linter genera info en cada uso.
**Fix masivo:** reemplazar `color.withOpacity(0.5)` por `color.withValues(alpha: 0.5)` en todos los ficheros. Se puede hacer con un sed o búsqueda global en el IDE.

#### 12. Doble estado de carga en `AuthNotifier`
**Fichero:** `lib/features/auth/data/providers/auth_provider.dart`.
**Problema:** `AuthState` tiene campos `isLoading` y `error` propios, Y además está envuelto en `AsyncValue<AuthState>` que también tiene loading/error. Dos capas redundantes para lo mismo.
**Fix:** o eliminar los campos `isLoading`/`error` de `AuthState` y usar solo `AsyncValue`, o desenvover a un `StateProvider<AuthState>` simple sin `AsyncValue`.

#### 13. Imports y variables locales sin usar
**Fichero principal:** `lib/features/roster/presentation/widgets/player_row.dart`.
**Problema:** importa `translations.dart` y hace `watch(localeProvider)` asignando a `lang`, pero `lang` nunca se usa en ese widget.
**Fix:** eliminar el import y el `ref.watch`.

#### 14. Sistema i18n custom no escalable
**Fichero:** `lib/core/l10n/translations.dart`.
**Problema:** todas las traducciones en un `const Map` con claves string. No hay comprobación en tiempo de compilación, añadir un idioma nuevo es muy manual, y no hay soporte para plurales.
**Fix a largo plazo:** migrar a `flutter_localizations` + ARB files, o al menos añadir type-safe keys con un enum.

---

## TODO

TECNICAS

- [ ] Filtro por raza + busqueda en mis equipos
- [ ] Posibilidad de mirar equipos de otros jugadores "amigos" o con código de jugador
- [ ] Histórico de compras o modificación de jugadores con SPP
- [ ] Buscador en la sección de habilidades
- [ ] Jugadores estrella disponibles en la creación de equipo QUITAR
- [ ] Tabla de perks y fichas de perks multiidioma
- [ ] Tooltips en perks que hablen de otros perks
- [ ] En la ventana de clima, refactorizar para DRY, se definen widgets iguales por duplicado. Centralizar widget y solo cambiar contenido.
- [ ] Lo mismo con lesiones.
- [ ] Lo mismo con bloqueos
- [ ] Los terminos clave estan en ingles la mayoria, esos tambien deberian ser multiidioma
- [ ] Implementar Mis ligas - liga - jornada actual
- [ ] Implementar Mis ligas - liga - estadisticas
- [ ] En partido rapido hacer busqueda por usuario e implemetar toda la logica de notificaciones, conexion a partido, etc

VISUALES

- [ ] Centrar tabla de perks
- [ ] Pills de habilidades adquiridas con otro color o icono para diferenciarlos de las habilidades base
- [ ] Reorganizar la sección de mis tácticas - el mapa debería aparecer lo primero
- [ ] En la parte de mis tacticas en lugar de lista que sea un grid. Ademas que sea multiidioma las labels de ataque y defensa
- [ ] Calculos post-partido en backend
- [ ] La vista de mis equipos rediseñarla.
- [ ] En partido rapido rediseñar las tarjetas de selector de equipo: logo, valor equipo, nombre, raza
- [ ] Seccion de notificaciones de mis ligas más estrecho, que quepan 2 tarjetas de liga en grid
- [ ] Rediseño del calendario para que sea editable e incluya mas informacion cada tarjeta21
- [ ] Fuente mas grande en las cajitas, tablas, etc
- [ ] Darle una vuelta a la vista de mis ligas...
- [ ] En la wiki, donde haya que tirar dado, poner a la izquierda en icono grande los dados que hay que tirar (como en la imagen pero solo 1 par de dados para todo).

  ![1776170180012](image/README/1776170180012.png)

REGLAS - LOGICA

- [ ] Reglas de retener el balon, añadir input para calculo de MO final.
- [ ] Acciones pre-partido: añadir bendisiones de nurgle
- [ ] Acciones pre-partido: creacion de equipo + fichajes temporales
- [ ] Calculo ganancias y puntos de estrellato
- [ ] Refactorizar la creacion de equipo
- [ ] Acciones post-partido segun reglamento
- [ ] Acciones post-partido: fichajes permanentes de temporales
- [ ] Meter en wiki
  - [ ] Tabla de lesiones
  - [ ] Dados
  - [ ] Lanzamientos (con mapa)
  - [ ] Tabla de lesiones
