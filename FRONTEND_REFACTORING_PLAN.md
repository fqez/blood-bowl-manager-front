# Plan pristino de refactorizacion del frontend a React

Este documento analiza el frontend actual de `blood-bowl-manager-front` y propone una reconstruccion limpia en React/TypeScript por fases pequenas, verificables y aptas para trabajar con IA sin cargar demasiado contexto.

Objetivo principal: rehacer el frontend actual, que hoy esta en Flutter/Dart, como una aplicacion React profesional, mantenible y entendible. El nuevo frontend debe conservar los flujos utiles, integrarse con el backend refactorizado/versionado, eliminar codigo legacy o muerto, y evitar repetir los god files, reglas en UI, duplicaciones y contratos accidentales del cliente actual.

Decision tecnica propuesta: React + TypeScript + Vite como SPA desplegable en Cloudflare Pages. Esta decision encaja con el despliegue actual de sitio estatico y con el backend API separado. Antes de implementar se puede confirmar si se prefiere Next.js/Remix, pero el plan asume Vite para minimizar complejidad.

## 1. Resumen ejecutivo

El frontend actual ya cubre mucha funcionalidad real:

- Autenticacion con access/refresh token.
- Navegacion autenticada.
- Listado, creacion y gestion de ligas.
- Creacion y gestion de equipos propios.
- Roster, jugador, avances, lesiones, staff y tesoreria.
- Partidos de liga y quick matches.
- Flujo pre-match, live match y aftermatch.
- Wiki/reglas, habilidades, clima, lesiones, pases, bloqueos, star players y tablas.
- Tacticas y pizarras.
- Assets visuales de equipos, logos, fondos, dados y star players.

El problema no es falta de funcionalidad, sino mezcla de responsabilidades y acumulacion de comportamiento en pantallas muy grandes:

- `lib/features/aftermatch/presentation/screens/aftermatch_screen.dart` supera 5000 lineas y mezcla formulario, calculos, payloads, validaciones, UI, reglas y estado local.
- `lib/features/roster/presentation/screens/player_card_screen.dart` supera 4500 lineas y mezcla detalle visual, acciones, avances, lesiones, imagenes, API y estado.
- `lib/features/live_match/presentation/widgets/live_match_live_view.dart` supera 3000 lineas y contiene mucha logica de evento, marcador, tabs, auditoria y acciones.
- `lib/features/league/presentation/screens/league_overview_screen.dart`, `my_team_detail_screen.dart` y `live_match_team_prep.dart` rondan miles de lineas cada uno.
- `lib/features/shared/data/team_repository.dart` contiene modelos/reglas/repository juntos y supera 1400 lineas.
- `core/l10n/translations.dart` es un diccionario central grande que mezcla todo el producto en un solo archivo.
- Hay rutas debug dentro de la app y credenciales de prueba hardcodeadas en `debug_league_aftermatch_launcher.dart`.
- Hay assets/reglas locales (`assets/rules`, `assets/data.json`) que deben dejar de ser fuente canonica cuando el backend exponga `/rulesets`.
- Los archivos generados `*.freezed.dart` y `*.g.dart`, el directorio `build/` y tooling puntual no deben guiar el nuevo diseno.

Estrategia recomendada: no intentar traducir Flutter a React linea por linea. Primero inventariar flujos y contratos, luego crear una base React limpia, despues migrar feature por feature usando el codigo Flutter como contrato de comportamiento, y por ultimo retirar assets/datos/debug/legacy que ya no hagan falta.

## 2. Alcance de este documento

Incluye:

- Inventario funcional del frontend actual.
- Code smells, malas practicas y riesgos por area.
- Arquitectura objetivo para React/TypeScript.
- Regla de trabajo con IA: leer el Flutter actual como comportamiento, no copiar su arquitectura.
- Tabla de codigo actual a leer por area.
- Plan paso a paso con fases pequenas.
- Plan de limpieza de legacy/codigo muerto/assets residuales.
- Tests y criterios de aceptacion.
- Dudas abiertas antes de implementar decisiones grandes.

No incluye:

- Implementacion del nuevo React.
- Eliminacion inmediata del Flutter actual.
- Cambio de backend.
- Arranque de servidores persistentes.
- Copia literal de pantallas Flutter a React.

## 3. Principio mas importante para la IA

El codigo Flutter actual debe usarse como contrato de comportamiento, no como plantilla de diseno.

Instruccion obligatoria para cada ticket React:

```text
Usa el codigo Flutter actual como fuente de comportamiento, no como referencia de arquitectura.
Lee solo los archivos indicados en este ticket.
Preserva el comportamiento y los casos limite documentados.
No copies god files, widgets gigantes, estado local mezclado con API, reglas en UI ni strings magicos.
Extrae tipos, servicios, hooks, componentes y validadores pequenos.
El nuevo codigo debe ser React/TypeScript idiomatico, testeable y dividido por feature.
No avances a otros pasos.
```

Reglas practicas:

- Si el paso migra un flujo existente, leer Flutter para entradas, salidas, permisos, payloads y estados visuales.
- Si el paso crea arquitectura nueva, leer Flutter solo para rutas y casos de uso, no para copiar estructura.
- Si el paso elimina assets/datos/debug, medir uso antes.
- Si el archivo Flutter actual tiene miles de lineas, leer solo funciones, widgets o secciones relacionadas con el ticket.
- Ningun archivo nuevo React deberia acercarse a 1000 lineas; si se acerca, dividir antes.

## 4. Funcionalidad actual que hay que preservar

### 4.1 Bootstrap, configuracion y despliegue

Archivos actuales:

- `lib/main.dart`
- `lib/core/config/app_config.dart`
- `assets/env/development.env`
- `assets/env/production.env`
- `assets/env/example.env`
- `.github/workflows/deploy.yml`
- `README.md`

Contexto actual:

- `main.dart` carga `AppConfig`, fuente custom `RugbySquadOutline`, `ProviderScope`, router y tema.
- `AppConfig` carga `assets/env/<env>.env` segun debug/release o `APP_ENV`.
- Produccion despliega a Cloudflare Pages desde `main`.

Funcionalidad a preservar:

- Configuracion por entorno sin cambiar URL de API en codigo.
- Deploy estatico en Cloudflare Pages.
- Carga de fuentes y assets necesarios.
- Smoke test despues de despliegue.

Malas practicas actuales a evitar:

- Config runtime basada en assets Flutter que no aplica directamente a React.
- Main branch publica directo sin preview de PR.
- Mezclar bootstrap visual con inicializacion de auth/config.

Objetivo React:

- `src/app/App.tsx` solo compone providers/router/layout.
- `src/shared/config/env.ts` valida variables `VITE_*` con schema.
- `.env.example`, `.env.development`, `.env.production` documentados.
- CI ejecuta typecheck, lint, tests y build antes de deploy.

### 4.2 Autenticacion y sesion

Archivos actuales:

- `lib/core/network/api_client.dart`
- `lib/features/auth/data/providers/auth_provider.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`
- `lib/features/auth/domain/models/user.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`

Contexto actual:

- Dio inyecta bearer token salvo login/register/refresh.
- Interceptor intenta refresh en 401 con deduplicacion `_refreshFuture`.
- Tokens y usuario cacheado se guardan en secure storage.
- `AuthNotifier` mezcla `AsyncValue<AuthState>` con `AuthState.isLoading/error`.
- Router redirige a login y conserva `from`.

Funcionalidad a preservar:

- Login, registro, refresh rotation, logout, `/auth/me`.
- Redirect a ruta original despues de login.
- Recuperacion de sesion si hay usuario cacheado y tokens validos.
- Limpieza de tokens si refresh falla.

Malas practicas actuales a evitar:

- Doble estado loading/error.
- Interceptor que crea cliente nuevo sin compartir telemetria/config completa.
- Tokens accesibles sin estrategia web clara.
- Ignorar errores de logout sin al menos telemetry/log debug.

Objetivo React:

- `src/features/auth/api/authApi.ts` con funciones puras de API.
- `src/features/auth/session/sessionStore.ts` o context ligero.
- React Query para `/auth/me` y mutation login/logout.
- Axios/fetch wrapper con refresh single-flight.
- Decision explicita: bearer tokens en storage temporal/localStorage o cookies httpOnly si backend cambia.

### 4.3 Router, shell y navegacion

Archivos actuales:

- `lib/core/router/app_router.dart`
- `lib/core/shell/app_shell.dart`
- `lib/core/shell/widgets/app_shell_navigation_widgets.dart`

Rutas actuales principales:

- `/login`, `/register`
- `/dashboard`
- `/leagues`, `/leagues/create`, `/leagues/join`
- `/league/:leagueId`, `/league/:leagueId/backoffice`
- `/league/:leagueId/team/:teamId`
- `/league/:leagueId/team/:teamId/player/:playerId`
- `/league/:leagueId/match/:matchId/live`
- `/league/:leagueId/match/:matchId/aftermatch`
- `/create-team`
- `/teams`, `/teams/shared/:shareCode`, `/teams/:teamId`, `/teams/:teamId/player/:playerId`
- `/wiki/*`
- `/tactics`, `/my-tactics`
- `/quick-match`, `/quick-match/:matchId/live`, `/quick-match/:matchId/aftermatch`
- `/debug/league-aftermatch`, `/debug/league`

Funcionalidad a preservar:

- Guard de auth.
- Redirect despues de login.
- Deep links.
- Layout shell desktop/mobile.
- Navegacion contextual league/team/player/match.

Malas practicas actuales a evitar:

- Rutas debug visibles en produccion.
- Indices de nav como contrato de comportamiento.
- Router monolitico con imports de todas las pantallas.

Objetivo React:

- React Router o TanStack Router con lazy routes.
- Route guards declarativos.
- `AppShell` dividido en sidebar, topbar, mobile nav y breadcrumbs.
- Feature routes co-localizadas por modulo.
- Debug routes solo en development flag.

### 4.4 Equipos, roster y jugador

Archivos actuales:

- `lib/features/my_teams/domain/models/user_team.dart`
- `lib/features/my_teams/presentation/screens/my_teams_screen.dart`
- `lib/features/my_teams/presentation/screens/my_team_detail_screen.dart`
- `lib/features/roster/presentation/screens/player_card_screen.dart`
- `lib/features/roster/presentation/widgets/player_row.dart`
- `lib/features/roster/presentation/widgets/staff_section.dart`
- `lib/features/team_creator/presentation/screens/team_creator_screen.dart`
- `lib/features/team_creator/presentation/widgets/*`
- `lib/features/shared/data/team_repository.dart`

Contexto actual:

- `UserTeamDetail` embebe jugadores, treasury, staff, rerolls, apothecary, dedicated fans, warnings y share code.
- `UserPlayer` contiene stats, skills/perks, career, injuries, image, temporal/journeyman.
- Team creator ya fue separado parcialmente, pero la pantalla principal sigue siendo grande.
- Player card y team detail concentran muchas acciones y reglas visuales.

Funcionalidad a preservar:

- Crear equipo desde roster base y presupuesto.
- Ver equipos propios y compartidos.
- Editar staff/economia donde aplique.
- Contratar/despedir jugadores.
- Ver ficha de jugador, avances, injuries, imagen y carrera.
- Contar jugadores validos igual que backend: muertos no cuentan, lesionados si cuentan para minimo de roster.

Malas practicas actuales a evitar:

- Modelos con getters UI (`statusColor`) que mezclan dominio y presentacion.
- Pantallas que manejan API, estado, validacion y layout juntas.
- Nombres `perk` en API nueva si el dominio usa `skill`.
- Reglas de team value o avances calculadas en UI si backend debe ser canonico.

Objetivo React:

- `features/teams/api`, `features/teams/model`, `features/teams/components`, `features/teams/routes`.
- Hooks pequenos: `useUserTeam`, `useTeamRosterActions`, `usePlayerAdvancement`, `useTeamCreationWizard`.
- Componentes: `TeamSummaryCard`, `RosterTable`, `PlayerCard`, `StaffPanel`, `TreasuryPanel`, `TeamCreatorWizard`.
- Validaciones con schema TypeScript/Zod donde sean de UI, no reglas canonicas.

### 4.5 Ligas

Archivos actuales:

- `lib/features/leagues/presentation/screens/leagues_screen.dart`
- `lib/features/leagues/presentation/screens/create_league_screen.dart`
- `lib/features/leagues/presentation/screens/join_league_screen.dart`
- `lib/features/league/presentation/screens/league_overview_screen.dart`
- `lib/features/league/presentation/screens/league_backoffice_screen.dart`
- `lib/features/league/presentation/widgets/*`
- `lib/features/league/domain/models/league.dart`
- `lib/features/shared/data/league_repository.dart`

Funcionalidad a preservar:

- Crear liga con reglas/config.
- Unirse por invitacion/codigo.
- Gestionar comisarios/backoffice.
- Ver clasificacion, calendario, ronda actual, stats y bracket.
- Navegar a equipos y partidos.

Malas practicas actuales a evitar:

- `LeagueOverviewScreen` gigante con tabs, fetch, estado, dialogs y composicion juntos.
- Duplicar resumen de liga en varios modelos sin contrato claro.
- Leer payloads pesados si solo se necesita summary.

Objetivo React:

- Separar `league-list`, `league-detail`, `league-admin`, `league-standings`, `league-schedule`, `league-stats`.
- React Query keys por entidad: `['league', id]`, `['leagueMatches', id]`, `['standings', id]`.
- URL state para tabs y filtros cuando aporte deep linking.

### 4.6 Live match y quick match

Archivos actuales:

- `lib/features/live_match/presentation/screens/live_match_screen.dart`
- `lib/features/live_match/presentation/widgets/live_match_pre_match.dart`
- `lib/features/live_match/presentation/widgets/live_match_team_prep.dart`
- `lib/features/live_match/presentation/widgets/live_match_live_view.dart`
- `lib/features/live_match/presentation/widgets/live_match_dialogs.dart`
- `lib/features/live_match/presentation/widgets/live_match_helpers.dart`
- `lib/features/live_match/data/active_match_provider.dart`
- `lib/features/shared/presentation/widgets/match_event_dialog.dart`
- `lib/features/shared/data/quick_match_repository.dart`

Contexto actual:

- `LiveMatchScreen` sirve tanto para liga como quick match.
- Pre-match gestiona clima, kickoff, squads, ready, staff y temporales.
- Live view gestiona score, eventos, turnos, rerolls, logs y completar partido.
- Quick match usa endpoints propios pero comparte modelos `Match`.
- Casualty details usan marcadores maquina como `BBM_SELF_INFLICTED:1` y `BBM_ACCIDENTAL:1`.

Funcionalidad a preservar:

- Flujo pre-match -> live -> complete -> aftermatch.
- Liga y quick match.
- Estado de equipos, squads, rerolls, turnos, marcador, clima, kickoff.
- Eventos add/delete con payload compatible.
- Marcadores machine-readable en detalles de eventos mientras backend los necesite.
- Inducement budget backend-owned para pre-match.

Malas practicas actuales a evitar:

- `part of` para widgets enormes acoplados a una screen.
- Calcular presupuesto desde treasury local si backend ya tiene match state.
- `detail` string como unico contrato semantico.
- Duplicar logica entre league match y quick match.

Objetivo React:

- `features/matches` con adapters para `leagueMatchApi` y `quickMatchApi`.
- `MatchContext` o hook `useMatchController` con reducers tipados.
- Componentes pequenos: `PreMatchSetup`, `TeamPrepPanel`, `LiveScoreboard`, `EventTimeline`, `MatchActionBar`, `RerollTracker`.
- Tipos de evento discriminados.

### 4.7 Aftermatch

Archivos actuales:

- `lib/features/aftermatch/presentation/screens/aftermatch_screen.dart`
- `lib/features/aftermatch/domain/models/aftermatch.dart`
- `lib/features/aftermatch/presentation/widgets/*`
- `lib/features/shared/data/league_repository.dart`

Contexto actual:

- Aftermatch construye reportes de MVP, SPP, injuries, winnings, dedicated fans, expensive mistakes, purchases y temporales.
- Parte del estado se round-trippea con backend.
- Nuevas flags como `players[*].free` deben hidratarse y serializarse simetricamente.

Funcionalidad a preservar:

- Reporte por equipo/lado.
- MVP obligatorio y star players excluidos.
- Injuries con rolls y stat reductions.
- Winnings, dedicated fans, expensive mistakes.
- Compras postmatch y temporales.
- Idempotencia/rehidratacion de reports guardados.

Malas practicas actuales a evitar:

- Pantalla unica de 5000 lineas.
- Reglas, formulario, UI y payload builder en el mismo archivo.
- Campos nuevos sin hydration + serialization + backend parsing juntos.

Objetivo React:

- Wizard por secciones con state machine o reducer tipado.
- `aftermatchReportSchema` para payload.
- `buildAftermatchPayload()` y `hydrateAftermatchReport()` testeados.
- Componentes de seccion: `MvpStep`, `SppStep`, `InjuryStep`, `WinningsStep`, `PurchasesStep`, `ReviewSubmitStep`.

### 4.8 Wiki, rulesets y catalogos

Archivos actuales:

- `lib/features/wiki/presentation/screens/*`
- `lib/features/wiki/presentation/widgets/*`
- `lib/features/shared/data/team_repository.dart`
- `assets/rules/rules.json`
- `assets/rules/teams.json`
- `assets/data.json`
- `assets/images/perks/*`
- `assets/images/star_players/*`

Funcionalidad a preservar:

- Consultar skills, weather, star players, injuries, blocking, passing, achievements, tables.
- Mostrar assets visuales cuando existan.
- Soporte ES/EN.

Malas practicas actuales a evitar:

- Front como fuente canonica de reglas.
- Textos de reglas oficiales generados/copiados sin control.
- Pantallas wiki casi duplicadas.
- Assets duplicados `.png/.jpg/.webp` sin manifiesto.

Objetivo React:

- Consumir `/rulesets` y catalogos del backend.
- `features/rulesets` como capa de data.
- Wiki como render de datos, no como fuente de verdad.
- Assets con manifest local solo para imagenes no canonicas.

### 4.9 Tacticas

Archivos actuales:

- `lib/features/tactics/presentation/screens/tactics_screen.dart`
- `lib/features/tactics/presentation/screens/my_tactics_screen.dart`
- `assets/images/plantilla_pitch.png`

Funcionalidad a preservar:

- Crear/ver tacticas.
- Campo visual, posiciones, ocupantes, equipo propio/rival.
- Listado de tacticas guardadas.

Malas practicas actuales a evitar:

- Pantallas muy grandes con geometria, UI y persistencia juntas.
- `ignore_for_file: deprecated_member_use` como solucion permanente.

Objetivo React:

- Separar canvas/field geometry, domain model, toolbar y persistence.
- Considerar SVG/HTML/CSS grid o canvas solo si aporta.
- Tests unitarios para reglas de posicionamiento.

### 4.10 Localizacion, tema y diseno

Archivos actuales:

- `lib/core/l10n/translations.dart`
- `lib/core/l10n/locale_provider.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_dimensions.dart`
- `lib/core/theme/theme_context.dart`

Funcionalidad a preservar:

- ES/EN.
- Tema dark Blood Bowl.
- Dimensiones/radios compartidos.
- Fuentes y branding.

Malas practicas actuales a evitar:

- Diccionario global enorme no dividido por namespace.
- Estilos inline repetidos.
- Colores/radios hardcodeados fuera del design system.

Objetivo React:

- `src/shared/ui/theme/tokens.ts`.
- CSS variables o Tailwind tokens, pero una sola fuente de verdad.
- i18n por namespaces: `auth`, `teams`, `leagues`, `matches`, `aftermatch`, `rules`, `tactics`.
- Component library local: Button, IconButton, Dialog, Tabs, Table, StatBadge, StatusPill, MoneyText.

## 5. Code smells globales

### 5.1 God screens y widgets gigantes

Sintoma:

- Pantallas de miles de lineas con estado, llamadas API, payloads, widgets privados y helpers.

Impacto:

- IA necesita demasiado contexto.
- Cambios pequenos tienen mucho riesgo.
- Tests son dificiles.
- React podria nacer igual de acoplado si se traduce uno a uno.

Regla React:

- Una route compone, no contiene todo.
- Hooks contienen estado asincrono/controlador.
- Componentes presentacionales no conocen API.
- Payload builders viven en `model` o `api`, no en JSX.

### 5.2 Reglas de negocio en UI

Sintoma:

- Budget, injuries, SPP, temporary players, advancement, status labels y event markers se deciden en pantallas/widgets.

Impacto:

- Backend y frontend pueden divergir.
- React podria duplicar reglas que el backend refactorizado debe poseer.

Regla React:

- Backend es fuente de verdad para reglas persistentes/auditables.
- Front valida ergonomia y muestra preview, pero confirma con backend.
- Los calculos UI deben llamarse `preview`, `display` o `clientHint`, no `rulesEngine`.

### 5.3 Contratos API accidentales

Sintoma:

- Repositorios montan payloads manualmente con strings.
- Modelos toleran defaults silenciosos.
- Algunas rutas tienen slash final y otras no.

Impacto:

- Errores de API aparecen tarde.
- Cambiar backend rompe pantallas sin aviso.

Regla React:

- Generar cliente desde OpenAPI cuando `/api/v1` este estable, o usar schemas Zod mientras tanto.
- Centralizar endpoints y payloads.
- Tests de contrato para payloads criticos.

### 5.4 Assets y datos locales como fuente de verdad

Sintoma:

- `assets/rules/*.json`, `assets/data.json`, imagenes duplicadas y reglas locales conviven con backend.

Impacto:

- Dos fuentes de reglas.
- React puede arrancar con catalogos obsoletos.

Regla React:

- Assets locales solo imagenes, iconos, fuentes y fallback documentado.
- Catalogos y rulesets vienen del backend.
- Manifest de assets con IDs canonicos.

### 5.5 Debug y credenciales en app

Sintoma:

- Rutas debug y usuario/password de prueba en codigo Flutter.

Impacto:

- Riesgo de exponer herramientas internas en produccion.
- Contamina navegacion y traducciones.

Regla React:

- Debug tooling solo bajo `import.meta.env.DEV` o feature flag.
- Credenciales nunca hardcodeadas.
- Fixtures de test en `test/fixtures` o mocks MSW.

### 5.6 Tests insuficientes

Sintoma:

- `test/widget_test.dart` es placeholder.

Impacto:

- No hay red de seguridad para migrar.

Regla React:

- Tests desde el primer commit: unit, component, route smoke, API mocks.

## 6. Arquitectura objetivo React

### 6.1 Stack recomendado

- React 19 o version estable vigente.
- TypeScript estricto.
- Vite.
- React Router o TanStack Router.
- TanStack Query para server state.
- Zustand o reducer/context para estado local complejo por flujo.
- React Hook Form + Zod para formularios/payloads.
- Vitest + Testing Library.
- MSW para mocks de API.
- Playwright para smoke/E2E critico.
- ESLint + Prettier.
- CSS Modules, vanilla-extract, Tailwind o design tokens propios; elegir una opcion y mantenerla.

### 6.2 Estructura propuesta

```text
src/
  app/
    App.tsx
    providers.tsx
    router.tsx
    routes.tsx
  shared/
    api/
      httpClient.ts
      apiErrors.ts
      queryClient.ts
    config/
      env.ts
    ui/
      button/
      dialog/
      tabs/
      table/
      form/
      status/
    theme/
      tokens.ts
      global.css
    i18n/
    assets/
  features/
    auth/
      api/
      model/
      routes/
      ui/
    rulesets/
    teams/
    team-creator/
    players/
    leagues/
    matches/
    quick-matches/
    aftermatch/
    tactics/
    wiki/
    dashboard/
  test/
    fixtures/
    msw/
```

### 6.3 Reglas de diseno tecnico

- `features/*/api` conoce HTTP.
- `features/*/model` contiene tipos, schemas, mappers y reducers.
- `features/*/ui` contiene componentes presentacionales.
- `features/*/routes` contiene route components y carga de datos.
- `shared/ui` no conoce dominio Blood Bowl.
- `shared/api` no conoce componentes.
- No importar entre features salvo mediante APIs publicas o `shared`.
- Los hooks con side effects deben tener tests o estar cubiertos por componentes.
- Los mappers Flutter -> React no existen en runtime; solo sirven como guia de migracion.

### 6.4 Convenciones de tamano

- Route component: ideal menos de 200 lineas.
- Componente presentacional: ideal menos de 150 lineas.
- Hook/controlador: ideal menos de 200 lineas.
- Mapper/schema: puede crecer, pero dividir por entidad.
- Si un archivo supera 400 lineas, revisar division antes de seguir.
- No generar un nuevo `aftermatch_screen.tsx` gigante.

## 7. Contexto actual a pasar a la IA por area

Cada ticket independiente debe copiar solo su fila y la fase/paso aplicable. No pasar todo este documento salvo tareas de planificacion.

| Area                    | Codigo actual a leer                                                                                                                                                                                                                | Como usarlo                                          | No copiar al React nuevo                                        |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------- |
| Bootstrap/config/deploy | `lib/main.dart`, `lib/core/config/app_config.dart`, `README.md`, `.github/workflows/deploy.yml`                                                                                                                                     | Preservar envs, deploy y carga inicial               | Config via assets Flutter, bootstrap mezclado                   |
| Auth/session            | `core/network/api_client.dart`, `features/auth/data/providers/auth_provider.dart`, `features/auth/data/repositories/auth_repository.dart`, `features/auth/domain/models/user.dart`                                                  | Preservar login/refresh/logout/cache                 | Doble loading/error, storage sin decision web, catch silencioso |
| Router/shell            | `core/router/app_router.dart`, `core/shell/app_shell.dart`, `core/shell/widgets/app_shell_navigation_widgets.dart`                                                                                                                  | Inventariar rutas y guards                           | Router monolitico, debug en produccion, indices magicos         |
| Teams/list/detail       | `features/my_teams/domain/models/user_team.dart`, `features/my_teams/presentation/screens/my_teams_screen.dart`, `features/my_teams/presentation/screens/my_team_detail_screen.dart`, `features/shared/data/team_repository.dart`   | Preservar shape de equipo y acciones                 | Pantalla gigante con API + UI + reglas                          |
| Team creator            | `features/team_creator/presentation/screens/team_creator_screen.dart`, `features/team_creator/presentation/widgets/*`, `features/roster/domain/models/team.dart`                                                                    | Preservar wizard, budget, roster constraints         | Estado de wizard en una pantalla gigante                        |
| Player card             | `features/roster/presentation/screens/player_card_screen.dart`, `features/roster/presentation/widgets/player_row.dart`, `features/shared/utils/player_advancement.dart`                                                             | Preservar ficha, avances, injuries, imagen           | Mezclar status colors/getters UI en modelo de dominio           |
| Leagues                 | `features/leagues/presentation/screens/*.dart`, `features/league/presentation/screens/league_overview_screen.dart`, `features/league/domain/models/league.dart`, `features/shared/data/league_repository.dart`                      | Preservar flujos de liga y tabs                      | Overview gigante, modelos duplicados                            |
| Match/live              | `features/live_match/presentation/screens/live_match_screen.dart`, `features/live_match/presentation/widgets/*`, `features/shared/presentation/widgets/match_event_dialog.dart`, `features/shared/data/quick_match_repository.dart` | Preservar state machine y payloads                   | `part of`, widgets gigantes, detail strings como contrato unico |
| Aftermatch              | `features/aftermatch/presentation/screens/aftermatch_screen.dart`, `features/aftermatch/domain/models/aftermatch.dart`, `features/aftermatch/presentation/widgets/*`, `features/shared/data/league_repository.dart`                 | Preservar payload, hydration, idempotencia y compras | Pantalla unica con reglas + UI + payload builder                |
| Rules/wiki              | `features/wiki/presentation/screens/*`, `features/wiki/presentation/widgets/*`, `features/shared/data/team_repository.dart`, `assets/rules/*`                                                                                       | Preservar experiencia de consulta                    | Front como fuente canonica de reglas                            |
| Tactics                 | `features/tactics/presentation/screens/tactics_screen.dart`, `features/tactics/presentation/screens/my_tactics_screen.dart`, `assets/images/plantilla_pitch.png`                                                                    | Preservar tablero y guardado                         | Geometria, UI y API en una pantalla                             |
| Theme/i18n              | `core/theme/*`, `core/l10n/translations.dart`, `core/l10n/locale_provider.dart`                                                                                                                                                     | Extraer tokens, namespaces y copy actual             | Diccionario global enorme, estilos inline                       |
| Assets                  | `assets/teams/*`, `assets/images/*`, `assets/fonts/*`, `assets/rules/*`, `assets/data.json`, `pubspec.yaml`                                                                                                                         | Auditar que imagenes/fuentes hacen falta             | Duplicados sin manifest, reglas locales canonicas               |
| Debug/legacy            | `features/debug/*`, rutas `/debug/*`, `core/l10n/translations.dart`, `api/`, `config/`, `main.py`, `create_placeholders.py`, `download_*.py`                                                                                        | Decidir si borrar, mover a tools o mantener dev-only | Credenciales hardcodeadas, scripts sin owner                    |

Plantilla minima para cada ticket:

```text
Trabaja solo en: Fase X, Paso Y del FRONTEND_REFACTORING_PLAN.md.
Objetivo: <resultado concreto>.
Codigo Flutter actual a leer: <2-5 archivos maximo>.
Usa ese codigo como contrato de comportamiento, no como plantilla de diseno.
Stack objetivo: React + TypeScript + Vite.
Malas practicas a evitar: <copiar del paso>.
Criterio de salida: <copiar del paso>.
Validacion: <tests/comandos concretos>.
No avances a otros pasos.
```

## 8. Plan paso a paso

Cada fase debe poder dividirse en tickets pequenos. No migrar una pantalla completa de miles de lineas en un solo chat.

### Fase 0 - Preparacion y baseline

#### Paso 0.1 - Inventario de rutas y pantallas

Trabajo:

- Crear `docs/frontend/current-route-inventory.md`.
- Extraer rutas desde `app_router.dart`.
- Para cada ruta documentar: auth, datos que carga, acciones, backend endpoints y pantalla Flutter.
- Marcar rutas debug y rutas legacy.

Codigo actual a leer:

- `lib/core/router/app_router.dart`
- `lib/core/shell/app_shell.dart`

Malas practicas a evitar:

- Empezar React sin saber que deep links hay que preservar.
- Copiar rutas debug como rutas productivas.

Criterio de salida:

- Todas las rutas actuales tienen propietario y decision React: migrar, reemplazar, deprecar o dev-only.

#### Paso 0.2 - Inventario de endpoints frontend

Trabajo:

- Crear `docs/frontend/current-api-usage.md`.
- Listar endpoints usados por repositorios Flutter.
- Marcar endpoints legacy (`/perks`, assets locales, rutas sin `/api/v1`) y sustitutos futuros.

Codigo actual a leer:

- `lib/features/shared/data/team_repository.dart`
- `lib/features/shared/data/league_repository.dart`
- `lib/features/shared/data/quick_match_repository.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`

Malas practicas a evitar:

- Crear cliente React con endpoints hardcodeados dispersos.

Criterio de salida:

- Existe mapa endpoint -> feature -> payload -> modelo.

#### Paso 0.3 - Definir stack y comandos

Trabajo:

- Confirmar Vite/React/TypeScript.
- Crear `docs/frontend/react-stack-decision.md`.
- Documentar comandos objetivo:
  - `npm install`
  - `npm run dev`
  - `npm run typecheck`
  - `npm run lint`
  - `npm run test`
  - `npm run build`
- Documentar que Francho prefiere arrancar servidores manualmente.

Malas practicas a evitar:

- Crear proyecto sin typecheck estricto.
- Elegir librerias por gusto sin justificar.

Criterio de salida:

- Stack y comandos estan decididos antes de scaffolding.

#### Paso 0.4 - Tests de caracterizacion en Flutter o docs

Trabajo:

- Donde no haya tests, documentar escenarios manuales/e2e actuales:
  - login/register/refresh.
  - crear equipo.
  - ver team detail.
  - avanzar jugador.
  - crear liga y unirse.
  - jugar live match.
  - enviar aftermatch.
  - quick match.
  - wiki/rules.
- Si es viable, anadir tests enfocados antes de migrar piezas criticas.

Malas practicas a evitar:

- Rehacer React desde memoria sin pruebas de comportamiento.

Criterio de salida:

- Cada flujo critico tiene test o checklist reproducible.

### Fase 1 - Scaffolding React limpio

#### Paso 1.1 - Crear proyecto React en carpeta separada

Trabajo:

- Crear `react/` o nuevo root acordado.
- Inicializar Vite React TypeScript.
- Configurar `tsconfig` estricto.
- Configurar ESLint/Prettier.
- Configurar Vitest/Testing Library.

Malas practicas a evitar:

- Mezclar archivos React con `lib/` Flutter sin frontera.
- Migrar pantallas antes de tener lint/typecheck.

Criterio de salida:

- `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build` existen.

#### Paso 1.2 - Crear providers base

Trabajo:

- `AppProviders` con QueryClient, Router, Theme, I18n.
- Error boundary global.
- Loading inicial de config.

Malas practicas a evitar:

- Poner fetch global o estado de sesion dentro de componentes visuales.

Criterio de salida:

- App vacia arranca con layout minimo y tests smoke.

### Fase 2 - Design system y layout

#### Paso 2.1 - Tokens visuales

Trabajo:

- Migrar colores, radii, spacing, typography desde `core/theme/*`.
- Definir CSS variables/tokens.
- Cargar fuentes necesarias.

Codigo actual a leer:

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_dimensions.dart`
- `pubspec.yaml`

Malas practicas a evitar:

- Repetir colores/radios inline.
- Crear UI dominada por una sola paleta sin contraste funcional.

Criterio de salida:

- Tokens disponibles y documentados con componentes basicos.

#### Paso 2.2 - Componentes shared UI

Trabajo:

- Crear Button, IconButton, TextField, Select, Dialog, Tabs, Table, Card, Badge, StatusPill, MoneyText.
- Usar icons de una libreria React, por ejemplo lucide-react.

Malas practicas a evitar:

- Componentes de dominio dentro de `shared/ui`.
- Cards dentro de cards como patron general.

Criterio de salida:

- Pantallas futuras pueden componerse con primitives consistentes.

#### Paso 2.3 - App shell responsive

Trabajo:

- Crear desktop sidebar, mobile bottom nav/drawer y header.
- Soportar breadcrumbs o titulo contextual.

Codigo actual a leer:

- `lib/core/shell/app_shell.dart`
- `lib/core/shell/widgets/app_shell_navigation_widgets.dart`

Malas practicas a evitar:

- Indices magicos o ruta duplicada en varios sitios.

Criterio de salida:

- Shell renderiza rutas placeholder desktop/mobile sin shift raro.

### Fase 3 - API client, auth y routing

#### Paso 3.1 - Config y HTTP client

Trabajo:

- Crear `env.ts` con validacion.
- Crear `httpClient.ts` con baseUrl, timeout, errores normalizados.
- Crear `apiError.ts` y mapeo FastAPI validation errors.

Codigo actual a leer:

- `lib/core/config/app_config.dart`
- `lib/core/network/api_client.dart`

Malas practicas a evitar:

- Acceder a `import.meta.env` disperso.
- Mensajes de error distintos por feature.

Criterio de salida:

- Cliente HTTP testeado con errores 401/422/500.

#### Paso 3.2 - Auth session

Trabajo:

- Implementar login/register/logout/me/refresh.
- Refresh single-flight.
- Route guard.
- Tests con MSW.

Codigo actual a leer:

- `auth_repository.dart`
- `auth_provider.dart`
- `api_client.dart`
- `app_router.dart`

Malas practicas a evitar:

- Doble loading/error.
- Credenciales hardcodeadas.
- Infinite refresh loop.

Criterio de salida:

- Auth funciona con mocks y contra backend local cuando Francho lo arranque.

### Fase 4 - Modelos, schemas y cliente API por dominio

#### Paso 4.1 - Tipos base y schemas

Trabajo:

- Crear tipos de User, Team, Player, League, Match, MatchEvent, Ruleset.
- Usar OpenAPI si backend v1 existe; si no, Zod schemas manuales temporales.

Codigo actual a leer:

- `features/*/domain/models/*.dart`
- repositorios actuales.

Malas practicas a evitar:

- Defaults silenciosos que oculten payload roto.
- Copiar getters UI en modelos.

Criterio de salida:

- Tipos validan payloads criticos.

#### Paso 4.2 - Query keys y API modules

Trabajo:

- Crear API modules por feature.
- Crear query key factory por dominio.
- Tests de payload builders.

Malas practicas a evitar:

- Endpoints string literals en componentes.

Criterio de salida:

- Ningun componente llama `fetch/axios` directamente.

### Fase 5 - Teams y team creator

#### Paso 5.1 - Listado y detalle de equipos

Trabajo:

- Implementar `/teams`, shared team y team detail.
- Componentes roster, treasury, staff, warnings.

Codigo actual a leer:

- `my_teams_screen.dart`
- `my_team_detail_screen.dart`
- `user_team.dart`
- `team_repository.dart`

Malas practicas a evitar:

- Meter todas las acciones de equipo en una route gigante.

Criterio de salida:

- List/detail funcionan con MSW y backend.

#### Paso 5.2 - Team creator wizard

Trabajo:

- Crear wizard dividido en race, roster, staff, confirm.
- State reducer testeado.
- Budget preview de UI, validacion final del backend.

Codigo actual a leer:

- `team_creator_screen.dart`
- `team_creator_*_step.dart`
- `race_card.dart`, `position_card.dart`, `budget_bar.dart`

Malas practicas a evitar:

- Wizard monolitico.
- Reglas canonicas duplicadas en frontend.

Criterio de salida:

- Crear equipo completo funciona y tiene tests de reducer.

#### Paso 5.3 - Player card

Trabajo:

- Crear ficha de jugador con tabs o secciones.
- Acciones: avance, lesion, imagen, historial.
- Extraer formularios y dialogs.

Codigo actual a leer:

- `player_card_screen.dart`
- `player_row.dart`
- `player_advancement.dart`

Malas practicas a evitar:

- Ficha de jugador de miles de lineas.
- `statusColor`/labels dentro de modelo API.

Criterio de salida:

- Player detail y acciones clave estan cubiertas por tests de componente/API mock.

### Fase 6 - Leagues

#### Paso 6.1 - Leagues list/create/join

Trabajo:

- Migrar listado, creacion, join por codigo/invitacion.

Codigo actual a leer:

- `leagues_screen.dart`
- `create_league_screen.dart`
- `join_league_screen.dart`
- `league_repository.dart`

Malas practicas a evitar:

- Duplicar models summary/detail.

Criterio de salida:

- Flujos principales funcionan con mocks.

#### Paso 6.2 - League overview por tabs

Trabajo:

- Separar overview en standings, schedule, current round, stats, bracket.
- URL state para tab si conviene.

Codigo actual a leer:

- `league_overview_screen.dart`
- `standings_table.dart`
- `match_card.dart`
- `league_stats_dashboard.dart`
- `bracket_widget.dart`

Malas practicas a evitar:

- Un componente contenedor de 3000 lineas.

Criterio de salida:

- Cada tab tiene datos, loading/error y tests smoke.

#### Paso 6.3 - League backoffice

Trabajo:

- Migrar settings, comisarios y operaciones admin de liga.

Codigo actual a leer:

- `league_backoffice_screen.dart`
- `league_repository.dart`

Malas practicas a evitar:

- Confundir admin global con comisario de liga.

Criterio de salida:

- Backoffice usa permisos claros del backend.

### Fase 7 - Match live y quick match

#### Paso 7.1 - Match controller comun

Trabajo:

- Crear adapter comun para league match y quick match.
- Crear reducer/state machine: preMatch, live, completed, aftermatchReady.
- Tests del reducer.

Codigo actual a leer:

- `live_match_screen.dart`
- `quick_match_repository.dart`
- `league_repository.dart`

Malas practicas a evitar:

- Duplicar logica league/quick match.

Criterio de salida:

- Controlador comun cubre ambos tipos con tests.

#### Paso 7.2 - Pre-match y team prep

Trabajo:

- Migrar weather/kickoff/squads/ready/inducements.
- Presupuesto leido del backend match state.

Codigo actual a leer:

- `live_match_pre_match.dart`
- `live_match_team_prep.dart`
- `live_match_helpers.dart`

Malas practicas a evitar:

- Calcular budget desde treasury local.

Criterio de salida:

- Pre-match funciona para league y quick match.

#### Paso 7.3 - Live view y eventos

Trabajo:

- Migrar scoreboard, turn tracker, actions, event timeline, audit log.
- Crear payload builders para eventos.

Codigo actual a leer:

- `live_match_live_view.dart`
- `live_match_dialogs.dart`
- `match_event_dialog.dart`

Malas practicas a evitar:

- `detail` localized como unica semantica.
- Dialog gigante con todas las ramas.

Criterio de salida:

- TD/casualty/KO/completion/interception/foul add/delete testeados.

### Fase 8 - Aftermatch

#### Paso 8.1 - Modelo y payload de report

Trabajo:

- Crear schema de report.
- Crear hydrate/build payload.
- Tests con fixtures reales.

Codigo actual a leer:

- `aftermatch.dart`
- `aftermatch_screen.dart` solo secciones de payload/hydration.
- `league_repository.dart` metodo `applyAftermatch` y `finalizeAftermatchRosters`.

Malas practicas a evitar:

- Campos nuevos solo en UI sin payload/hydration.

Criterio de salida:

- Payload React coincide con backend esperado.

#### Paso 8.2 - Wizard aftermatch

Trabajo:

- Crear pasos MVP, stats/SPP, injuries, winnings, purchases, review.
- Reducer testeado.

Codigo actual a leer:

- `aftermatch_screen.dart`
- `touchdown_recorder.dart`, `injury_recorder.dart`, `score_input.dart`, `spp_summary.dart`

Malas practicas a evitar:

- Formulario gigante de 5000 lineas.

Criterio de salida:

- Usuario puede completar aftermatch league y quick match.

### Fase 9 - Rulesets, wiki y assets

#### Paso 9.1 - Ruleset discovery

Trabajo:

- Consumir `/rulesets` y catalog endpoints del backend nuevo.
- Reemplazar `/perks` y assets/rules como fuente canonica.

Codigo actual a leer:

- `team_repository.dart`
- `wiki_*_screen.dart`
- `assets/rules/*`

Malas practicas a evitar:

- Seguir leyendo JSON local para reglas canonicas.

Criterio de salida:

- Wiki carga desde backend o fallback documentado.

#### Paso 9.2 - Wiki modular

Trabajo:

- Crear layouts comunes.
- Migrar skills/weather/star players/injuries/blocking/passing/tables.

Codigo actual a leer:

- `wiki_page_layout.dart`
- `wiki_page_chrome.dart`
- pantallas `wiki_*`.

Malas practicas a evitar:

- Copiar pantallas casi iguales.

Criterio de salida:

- Wiki usa componentes comunes y namespaces i18n.

#### Paso 9.3 - Asset manifest

Trabajo:

- Crear manifest de assets por canonical ID.
- Auditar duplicados png/jpg/webp.
- Definir policy de imagen fallback.

Malas practicas a evitar:

- Buscar imagenes por strings heuristicas repartidas.

Criterio de salida:

- Assets estan desacoplados de reglas canonicas.

### Fase 10 - Tacticas

#### Paso 10.1 - Dominio de tacticas

Trabajo:

- Extraer modelo de field, squares, players, formations.
- Tests de posicionamiento.

Codigo actual a leer:

- `tactics_screen.dart`
- `my_tactics_screen.dart`

Malas practicas a evitar:

- Geometria y UI en el mismo componente.

Criterio de salida:

- Modelo de tacticas testeado sin DOM.

#### Paso 10.2 - UI de tablero

Trabajo:

- Implementar pitch responsive.
- Drag/drop si aporta, accesible si es viable.
- Toolbar y side panels separados.

Malas practicas a evitar:

- Coordenadas magicas sin constantes.

Criterio de salida:

- Crear/editar/ver tacticas funciona.

### Fase 11 - i18n, accesibilidad y responsive

#### Paso 11.1 - i18n por namespaces

Trabajo:

- Migrar textos a namespaces.
- Mantener ES/EN.
- Extraer debug translations si debug queda dev-only.

Codigo actual a leer:

- `translations.dart`
- pantallas por feature.

Malas practicas a evitar:

- Un archivo unico gigante de traducciones.

Criterio de salida:

- Cada feature carga sus traducciones.

#### Paso 11.2 - Responsive y accesibilidad

Trabajo:

- Revisar desktop/mobile por flujo.
- Labels, focus, keyboard, modals, tables.
- Evitar overflow de texto.

Malas practicas a evitar:

- Disenos que solo funcionan en desktop.

Criterio de salida:

- Playwright smoke en mobile y desktop.

### Fase 12 - Limpieza legacy y retirada Flutter

#### Paso 12.1 - Codigo Flutter legacy

Trabajo:

- Cuando React cubra un flujo, marcar equivalente Flutter como reemplazado.
- No borrar Flutter hasta que deploy React este probado.
- Crear tabla flujo Flutter -> React -> estado.

Malas practicas a evitar:

- Mantener dos frontends activos sin ownership.

Criterio de salida:

- Cada flujo tiene decision de retirada.

#### Paso 12.2 - Debug y credenciales

Trabajo:

- Retirar o dev-only:
  - `features/debug/*`
  - rutas `/debug/*`
  - credenciales `test@test.com` / `Password123!`
  - translations debug si no se usan.

Malas practicas a evitar:

- Credenciales hardcodeadas en bundle productivo.

Criterio de salida:

- Build productivo no contiene rutas ni credenciales debug.

#### Paso 12.3 - Assets/datos residuales

Trabajo:

- Auditar `assets/rules`, `assets/data.json`, imagenes duplicadas, build outputs y scripts Python.
- Mover herramientas utiles a `tools/` con README o eliminarlas.
- Mantener solo assets necesarios para React.

Malas practicas a evitar:

- Reglas locales obsoletas.
- Directorios `build/` como fuente de verdad.

Criterio de salida:

- Repo final no contiene codigo/datos muertos conocidos.

## 9. Orden recomendado para IA

1. Inventario de rutas.
2. Inventario de endpoints.
3. Decision de stack React.
4. Scaffolding React limpio.
5. Design tokens y shared UI.
6. App shell responsive.
7. Config/env/http client.
8. Auth/session/guards.
9. Tipos y schemas base.
10. API modules y query keys.
11. Teams list/detail.
12. Team creator wizard.
13. Player card.
14. Leagues list/create/join.
15. League overview tabs.
16. League backoffice.
17. Match controller comun.
18. Pre-match/team prep.
19. Live match view/events.
20. Aftermatch payload/hydration.
21. Aftermatch wizard.
22. Ruleset discovery.
23. Wiki modular.
24. Asset manifest.
25. Tacticas model.
26. Tacticas UI.
27. i18n namespaces.
28. Accessibility/responsive pass.
29. Debug/legacy cleanup.
30. Flutter retirement plan.

## 10. Tests minimos por area

### 10.1 Base app

- App renderiza layout autenticado/no autenticado.
- Env invalido falla con mensaje claro.
- Error boundary muestra fallback.
- Build production no incluye debug routes.

### 10.2 Auth

- Login exitoso guarda sesion.
- Login error muestra mensaje.
- Refresh 401 se intenta una vez.
- Refresh fallido limpia sesion.
- Redirect `from` funciona.
- Logout limpia storage aunque backend falle.

### 10.3 API client

- Mapea FastAPI validation errors.
- Maneja timeout/network error.
- No manda auth en login/register/refresh.
- Deduplica refresh concurrente.

### 10.4 Teams

- Lista equipos.
- Detail propio.
- Detail por share code oculta notas privadas.
- Roster count excluye muertos e incluye lesionados.
- Staff/treasury renderiza correctamente.
- Hire/fire actions invalidan queries correctas.

### 10.5 Team creator

- No permite exceder presupuesto.
- Respeta max/min roster.
- Staff modifica budget.
- Submit crea equipo con payload correcto.

### 10.6 Player card

- Render stats, skills, injuries, career.
- Advancement payload correcto.
- Star player no permite avance si aplica.
- Image update valida formato/tamano si se mantiene.

### 10.7 Leagues

- Crear liga.
- Join por codigo.
- Invitations accept/decline.
- Standings/schedule/current round/stats/bracket renderizan loading/error/empty.
- Backoffice permisos.

### 10.8 Match/live

- League match y quick match usan mismo controlador.
- Pre-match weather/kickoff/squad ready.
- Inducement budget viene del backend.
- Add/delete TD actualiza score.
- Casualty payload conserva markers machine-readable mientras haga falta.
- Complete match navega correctamente.

### 10.9 Aftermatch

- Hydrate saved report.
- Build payload incluye MVP, SPP, injuries, winnings, dedicated fans, purchases y temporales.
- `players[*].free` round-trip.
- MVP requerido y no star.
- Submit maneja parcial/error/success.

### 10.10 Wiki/rulesets

- Carga ruleset default.
- Skills/weather/star players/injuries/tables renderizan.
- Fallback de asset funciona.
- Locale ES/EN cambia textos.

### 10.11 Tacticas

- Crear tactica.
- Colocar/quitar jugador.
- Validar posiciones.
- Guardar/cargar tactic.

### 10.12 E2E smoke

- Login.
- Crear equipo.
- Crear liga.
- Jugar quick match basico.
- Enviar aftermatch minimo.
- Abrir wiki skills.
- Abrir tactics.

## 11. Inventario de codigo legacy, muerto y residual

Este inventario debe revisarse antes de retirar Flutter o mover assets. No todo se borra al principio; cada pieza debe tener decision.

| Candidato                                                                 | Estado probable         | Sustituto React                      | Condicion para eliminar                      |
| ------------------------------------------------------------------------- | ----------------------- | ------------------------------------ | -------------------------------------------- |
| `lib/features/debug/*`                                                    | Debug tooling           | Dev-only tools o Playwright fixtures | No se necesita en produccion                 |
| `/debug/league-aftermatch`, `/debug/league`                               | Rutas debug             | Dev-only routes bajo flag            | Build productivo no las incluye              |
| Credenciales en`debug_league_aftermatch_launcher.dart`                    | Riesgo                  | Variables locales/test fixtures      | Ningun secreto en bundle                     |
| `test/widget_test.dart` placeholder                                       | Muerto                  | Tests reales Vitest/RTL/Playwright   | Suite React existe                           |
| `*.freezed.dart`, `*.g.dart`                                              | Generado Flutter        | No aplica                            | No usarlos como contexto de diseno           |
| `build/`                                                                  | Output generado         | Dist React build                     | No trackear como fuente                      |
| `assets/rules/*`                                                          | Reglas locales          | `/rulesets` backend                  | Backend rulesets estable y fallback decidido |
| `assets/data.json`                                                        | Dato legacy/desconocido | Catalog backend o manifest           | Uso auditado                                 |
| Duplicados`star_players` png/jpg                                          | Assets duplicados       | Asset manifest                       | Imagen canonica elegida                      |
| `api/`, `config/`, `main.py` Python en repo front                         | Herramientas auxiliares | `tools/` o borrar                    | Uso confirmado o reemplazado                 |
| `create_placeholders.py`, `download_logos.py`, `download_placeholders.py` | Scripts puntuales       | `tools/assets/` con README           | Assets pipeline documentado                  |
| `analyze_output.txt`                                                      | Snapshot de analisis    | CI lint output                       | No necesario en repo final                   |
| `run_dev.ps1`                                                             | Helper local            | Scripts npm documentados             | React scripts cubren dev                     |
| `lib/features/shared/data/repositories.dart`                              | Barrel compat Flutter   | Feature APIs React                   | Flutter retirado                             |
| `core/l10n/translations.dart`                                             | Diccionario global      | i18n namespaces                      | React i18n migrado                           |
| `withOpacity` ignores/deprecated                                          | Deuda Flutter           | No aplica en React                   | Flutter retirado o deuda cerrada             |

Regla de limpieza:

- No borrar assets hasta confirmar si React los usa.
- No llevar debug a produccion.
- No migrar archivos generados.
- No mantener datos locales como fuente de reglas si backend ya expone rulesets.
- Todo script restante debe tener README, dry-run si modifica datos y owner claro.

## 12. Criterios globales de aceptacion

El frontend React se considerara listo para sustituir Flutter cuando:

- Existe app React/TypeScript con typecheck estricto, lint, tests y build en CI.
- Auth, teams, leagues, live match, aftermatch, wiki y tactics tienen flujos equivalentes o decision documentada de no migrar.
- React consume API versionada o cliente API centralizado con plan claro hacia `/api/v1`.
- Rulesets/catalogos vienen del backend, no de JSON local como fuente canonica.
- No hay pantallas/componentes gigantes comparables a los god files Flutter.
- Cada feature tiene API/model/UI/routes separados.
- Hay tests unitarios/componentes para payloads y flujos criticos.
- Hay Playwright smoke desktop/mobile.
- Build productivo no contiene rutas debug ni credenciales.
- Assets necesarios tienen manifest y duplicados auditados.
- Flutter queda archivado, retirado o con fecha de retirada.

## 13. Riesgos principales y mitigacion

### Riesgo 1 - Traducir Flutter a React linea por linea

Mitigacion:

- Usar Flutter como contrato de comportamiento.
- Crear componentes y hooks pequenos.
- Gate de tamano de archivos.

### Riesgo 2 - Divergir del backend refactorizado

Mitigacion:

- Coordinar con `/api/v1` y `/rulesets`.
- Generar cliente desde OpenAPI cuando este listo.
- Tests de contrato para payloads criticos.

### Riesgo 3 - Perder reglas ocultas de live/aftermatch

Mitigacion:

- Tests con fixtures extraidos del comportamiento actual.
- Migrar payload builders antes que UI completa.
- Mantener marcadores machine-readable hasta que backend los reemplace.

### Riesgo 4 - Doble fuente de reglas

Mitigacion:

- Backend canonico.
- Front solo renderiza catalogos y previews.
- Fallback local con fecha de retirada si hace falta.

### Riesgo 5 - Debug en produccion

Mitigacion:

- Feature flags dev-only.
- CI grep para credenciales/rutas debug.
- Playwright fixtures para escenarios de prueba.

### Riesgo 6 - Migracion demasiado grande para IA

Mitigacion:

- Tickets de 80-150 lineas.
- Pasar solo archivos Flutter necesarios.
- No avanzar de fase sin criterio de salida.

## 14. Dudas abiertas para Francho

1. Stack: confirmamos Vite + React + TypeScript o prefieres Next.js/Remix? RESPUESTA: lo que sea más estandar, no tengo ni idea de estas tecnologías
2. UI: quieres Tailwind/shadcn, CSS Modules, vanilla-extract o componentes propios con CSS variables? RESPUESTA: misma respuesta que antes
3. Auth web: bearer tokens como ahora o cookies httpOnly si el backend se adapta? RESPUESTA: tokens mejor
4. Deploy: mantenemos Cloudflare Pages con GitHub Actions? RESPUESTA: de momento sí.
5. React coexistira temporalmente con Flutter en el mismo repo o quieres carpeta/proyecto separado? RESPUESTA: el nuevo frontal deberá estar en la carpeta de workspace de bb-manager-v2-front
6. Assets: quieres conservar todas las imagenes actuales o auditar y reducir desde el principio? RESPUESTA: las imagenes se mantienen.
7. Wiki/reglas: React debe esperar a `/rulesets` backend o crear fallback temporal? RESPUESTAS: toda la documentacion y catalogos tienen que venir de back siempre
8. Tacticas: prioridad alta en primera version React o despues de teams/leagues/matches? RESPUESTA: como mejor veas
9. Debug tools: quieres conservar un modo dev para preparar aftermatch automaticamente? RESPUESTA: de momento no
10. Idiomas: ES/EN desde el inicio o primero ES y namespace preparado? RESPUESTA: ambos idiomas desde el inicio

## 15. Primeros 10 tickets recomendados

1. Crear inventario de rutas Flutter.
2. Crear inventario de endpoints usados por Flutter.
3. Decidir stack React y carpeta destino.
4. Inicializar Vite React TypeScript con lint/test/build.
5. Crear design tokens y shared UI basica.
6. Crear env/http client/API error handling.
7. Implementar auth/session/route guard con MSW tests.
8. Implementar shell responsive con rutas placeholder.
9. Crear tipos/schemas base para UserTeam, Player, League y Match.
10. Migrar Teams list/detail como primera feature real.

Estos tickets son suficientemente pequenos para trabajarlos con IA sin cargar todo el Flutter ni todo este plan cada vez.
