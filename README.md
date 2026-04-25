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

## TODO

TECNICAS

- [ ] Filtro por raza + busqueda en mis equipos
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
