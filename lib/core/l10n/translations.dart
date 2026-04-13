// Blood Bowl Manager – i18n translation map
// Usage:  final lang = ref.watch(localeProvider);
//         tr(lang, 'nav.myLeagues')
//         trf(lang, 'player.count', {'n': '5'})

String tr(String lang, String key) => _t[key]?[lang] ?? _t[key]?['es'] ?? key;

/// Interpolated: replaces `{param}` placeholders.
String trf(String lang, String key, Map<String, String> params) {
  var s = tr(lang, key);
  params.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

const _t = <String, Map<String, String>>{
  // ── Navigation ──────────────────────────────────────────────────────────
  'nav.myLeagues': {'es': 'Mis Ligas', 'en': 'My Leagues'},
  'nav.myTeams': {'es': 'Mis Equipos', 'en': 'My Teams'},
  'nav.leagueView': {'es': 'Vista de Liga', 'en': 'League View'},
  'nav.roster': {'es': 'Plantilla', 'en': 'Roster'},
  'nav.player': {'es': 'Jugador', 'en': 'Player'},
  'nav.postMatch': {'es': 'Post-Partido', 'en': 'Post-Match'},
  'nav.liveMatch': {'es': 'Partido en Vivo', 'en': 'Live Match'},
  'nav.createTeam': {'es': 'Crear Equipo', 'en': 'Create Team'},
  'nav.wikiSkills': {'es': 'Wiki - Skills', 'en': 'Wiki - Skills'},
  'nav.wikiWeather': {'es': 'Wiki - Clima', 'en': 'Wiki - Weather'},
  'nav.wikiStars': {'es': 'Wiki - Estrellas', 'en': 'Wiki - Star Players'},
  'nav.tactics': {'es': 'Tácticas', 'en': 'Tactics'},
  'nav.myTactics': {'es': 'Mis Tácticas', 'en': 'My Tactics'},
  'nav.expand': {'es': 'Expandir menú', 'en': 'Expand menu'},
  'nav.collapse': {'es': 'Comprimir menú', 'en': 'Collapse menu'},
  'nav.home': {'es': 'Inicio', 'en': 'Home'},
  'nav.league': {'es': 'Liga', 'en': 'League'},
  'nav.create': {'es': 'Crear', 'en': 'Create'},
  'nav.wiki': {'es': 'WIKI', 'en': 'WIKI'},
  'nav.activeLeague': {'es': 'LIGA ACTIVA', 'en': 'ACTIVE LEAGUE'},
  'nav.coach': {'es': 'Coach', 'en': 'Coach'},

  // ── Auth ────────────────────────────────────────────────────────────────
  'auth.bloodBowl': {'es': 'BLOOD BOWL', 'en': 'BLOOD BOWL'},
  'auth.leagueManager': {'es': 'LEAGUE MANAGER', 'en': 'LEAGUE MANAGER'},
  'auth.signIn': {'es': 'Iniciar Sesión', 'en': 'Sign In'},
  'auth.createAccount': {'es': 'Crear Cuenta', 'en': 'Create Account'},
  'auth.email': {'es': 'Email', 'en': 'Email'},
  'auth.emailHint': {'es': 'coach@bloodbowl.com', 'en': 'coach@bloodbowl.com'},
  'auth.password': {'es': 'Contraseña', 'en': 'Password'},
  'auth.confirmPassword': {
    'es': 'Confirmación de Contraseña',
    'en': 'Confirm Password',
  },
  'auth.coachName': {'es': 'Nombre de Coach', 'en': 'Coach Name'},
  'auth.coachHint': {'es': 'Coach Gortznak', 'en': 'Coach Gortznak'},
  'auth.enter': {'es': 'ENTRAR', 'en': 'SIGN IN'},
  'auth.create': {'es': 'CREAR CUENTA', 'en': 'CREATE ACCOUNT'},
  'auth.noAccount': {
    'es': '¿No tienes cuenta? ',
    'en': "Don't have an account? ",
  },
  'auth.register': {'es': 'Regístrate', 'en': 'Register'},
  'auth.hasAccount': {
    'es': '¿Ya tienes cuenta? ',
    'en': 'Already have an account? ',
  },
  'auth.logIn': {'es': 'Inicia Sesión', 'en': 'Sign In'},
  'auth.emailRequired': {
    'es': 'El email es obligatorio',
    'en': 'Email is required',
  },
  'auth.emailInvalid': {'es': 'Email inválido', 'en': 'Invalid email'},
  'auth.passwordRequired': {
    'es': 'La contraseña es obligatoria',
    'en': 'Password is required',
  },
  'auth.minChars6': {'es': 'Mínimo 6 caracteres', 'en': 'Minimum 6 characters'},
  'auth.coachRequired': {
    'es': 'El nombre de coach es obligatorio',
    'en': 'Coach name is required',
  },
  'auth.minChars3': {'es': 'Mínimo 3 caracteres', 'en': 'Minimum 3 characters'},
  'auth.minChars8': {'es': 'Mínimo 8 caracteres', 'en': 'Minimum 8 characters'},
  'auth.confirmRequired': {
    'es': 'Confirma tu contraseña',
    'en': 'Confirm your password',
  },
  'auth.passwordMismatch': {
    'es': 'Las contraseñas no coinciden',
    'en': "Passwords don't match",
  },
  'auth.requireUppercase': {
    'es': 'Debe incluir al menos una mayúscula',
    'en': 'Must include at least one uppercase letter',
  },
  'auth.requireNumber': {
    'es': 'Debe incluir al menos un número',
    'en': 'Must include at least one number',
  },
  'auth.confirmPasswordLabel': {
    'es': 'Confirmar Contraseña',
    'en': 'Confirm Password',
  },

  // ── Dashboard ───────────────────────────────────────────────────────────
  'dashboard.title': {'es': 'DASHBOARD', 'en': 'DASHBOARD'},
  'dashboard.subtitle': {
    'es': 'Resumen de actividad y ligas activas',
    'en': 'Activity summary and active leagues',
  },
  'dashboard.matchesPlayed': {'es': 'PARTIDOS JUGADOS', 'en': 'MATCHES PLAYED'},
  'dashboard.winRate': {'es': 'WIN RATE', 'en': 'WIN RATE'},
  'dashboard.totalSpp': {'es': 'TOTAL SPP', 'en': 'TOTAL SPP'},
  'dashboard.casualties': {'es': 'BAJAS CAUSADAS', 'en': 'CASUALTIES'},
  'dashboard.thisSeason': {'es': 'esta temporada', 'en': 'this season'},
  'dashboard.totalWins': {'es': 'victorias totales', 'en': 'total wins'},
  'dashboard.allActiveTeams': {
    'es': 'En todos los equipos activos',
    'en': 'In all active teams',
  },
  'dashboard.bloodForNuffle': {
    'es': 'Sangre para Nuffle',
    'en': 'Blood for Nuffle',
  },
  'dashboard.activeLeagues': {'es': 'LIGAS ACTIVAS', 'en': 'ACTIVE LEAGUES'},
  'dashboard.notifications': {'es': 'AVISOS', 'en': 'NOTIFICATIONS'},
  'dashboard.newCount': {'es': '{n} Nuevos', 'en': '{n} New'},
  'dashboard.welcome': {
    'es': 'Bienvenido al Dashboard',
    'en': 'Welcome to the Dashboard',
  },
  'dashboard.welcomeBody': {
    'es': 'Aquí verás las notificaciones de tus ligas y equipos.',
    'en': 'Here you will see notifications from your leagues and teams.',
  },
  'dashboard.tip': {'es': 'Consejo', 'en': 'Tip'},
  'dashboard.tipBody': {
    'es': 'Únete a una liga para empezar a jugar partidos.',
    'en': 'Join a league to start playing matches.',
  },
  'dashboard.noLeagues': {
    'es': 'No tienes ligas todavía',
    'en': "You don't have any leagues yet",
  },
  'dashboard.noLeaguesBody': {
    'es':
        'Crea una liga y comparte el código con tus amigos, o únete a una existente con un código de invitación.',
    'en':
        'Create a league and share the code with your friends, or join an existing one with an invite code.',
  },
  'dashboard.joinWithCode': {'es': 'Unirse con código', 'en': 'Join with code'},
  'dashboard.createLeague': {'es': 'Crear Liga', 'en': 'Create League'},
  'dashboard.errorLoading': {
    'es': 'Error al cargar el dashboard',
    'en': 'Error loading dashboard',
  },
  'dashboard.noInLeague': {
    'es': 'No estás en ninguna liga',
    'en': "You're not in any league",
  },
  'dashboard.createAndJoin': {
    'es': 'Crea un equipo y únete a una liga para empezar a jugar',
    'en': 'Create a team and join a league to start playing',
  },
  'dashboard.matchesThisSeason': {
    'es': '+{n} esta temporada',
    'en': '+{n} this season',
  },
  'dashboard.totalWinsCount': {
    'es': '{n} victorias totales',
    'en': '{n} total wins',
  },
  'dashboard.vsLast': {
    'es': '+{n}% vs anterior',
    'en': '+{n}% vs previous',
  },

  // ── Leagues ─────────────────────────────────────────────────────────────
  'leagues.createTeam': {'es': 'Crear Equipo', 'en': 'Create Team'},
  'leagues.team': {'es': 'Equipo', 'en': 'Team'},
  'leagues.createLeague': {'es': 'Crear Liga', 'en': 'Create League'},
  'leagues.league': {'es': 'Liga', 'en': 'League'},
  'leagues.joinLeague': {'es': 'Unirse a Liga', 'en': 'Join League'},
  'leagues.join': {'es': 'Unirse', 'en': 'Join'},
  'leagues.archive': {
    'es': 'Archivar / Finalizar liga',
    'en': 'Archive / End league',
  },
  'leagues.delete': {'es': 'Eliminar liga', 'en': 'Delete league'},
  'leagues.cancel': {'es': 'Cancelar', 'en': 'Cancel'},
  'leagues.deletePermanently': {
    'es': 'Eliminar definitivamente',
    'en': 'Delete permanently',
  },
  'leagues.archived': {
    'es': 'Liga "{name}" archivada',
    'en': 'League "{name}" archived',
  },
  'leagues.deleted': {
    'es': 'Liga "{name}" eliminada',
    'en': 'League "{name}" deleted',
  },
  'leagues.yourTeam': {'es': 'Tu equipo', 'en': 'Your team'},
  'leagues.teams': {'es': 'Equipos', 'en': 'Teams'},
  'leagues.round': {'es': 'Jornada', 'en': 'Round'},
  'leagues.manage': {'es': 'GESTIONAR', 'en': 'MANAGE'},
  'leagues.commissioner': {'es': 'COMISARIO', 'en': 'COMMISSIONER'},
  'leagues.viewLeague': {'es': 'VER LIGA', 'en': 'VIEW LEAGUE'},
  'leagues.viewResults': {'es': 'VER RESULTADOS', 'en': 'VIEW RESULTS'},
  'leagues.codeCopied': {
    'es': 'Código de invitación copiado',
    'en': 'Invite code copied',
  },
  'leagues.retry': {'es': 'Reintentar', 'en': 'Retry'},
  'leagues.play': {'es': 'JUGAR', 'en': 'PLAY'},
  'leagues.view': {'es': 'VER', 'en': 'VIEW'},

  // League formats
  'format.league': {'es': 'LIGA', 'en': 'LEAGUE'},
  'format.cup': {'es': 'COPA', 'en': 'CUP'},
  'format.swiss': {'es': 'SUIZO', 'en': 'SWISS'},

  // League statuses
  'status.active': {'es': 'ACTIVA', 'en': 'ACTIVE'},
  'status.paused': {'es': 'PAUSADA', 'en': 'PAUSED'},
  'status.finished': {'es': 'FINALIZADA', 'en': 'FINISHED'},
  'status.completed': {'es': 'COMPLETADA', 'en': 'COMPLETED'},
  'status.cancelled': {'es': 'CANCELADA', 'en': 'CANCELLED'},
  'status.draft': {'es': 'BORRADOR', 'en': 'DRAFT'},

  // ── League Management ───────────────────────────────────────────────────
  'league.draftTitle': {
    'es': 'Fase de Inscripción',
    'en': 'Registration Phase'
  },
  'league.draftSubtitle': {
    'es': '{current} de {max} equipos inscritos',
    'en': '{current} of {max} teams registered',
  },
  'league.inviteCode': {'es': 'Código de Invitación', 'en': 'Invite Code'},
  'league.shareInviteHint': {
    'es': 'Comparte este código con otros jugadores para que se unan a tu liga',
    'en': 'Share this code with other players so they can join your league',
  },
  'league.leagueInfo': {'es': 'Información de la Liga', 'en': 'League Info'},
  'league.format': {'es': 'Formato', 'en': 'Format'},
  'league.commissioner': {'es': 'Comisario', 'en': 'Commissioner'},
  'league.registeredTeams': {
    'es': 'Equipos Inscritos ({count})',
    'en': 'Registered Teams ({count})',
  },
  'league.noTeamsYet': {
    'es': 'Aún no hay equipos inscritos',
    'en': 'No teams registered yet',
  },
  'league.startLeague': {'es': 'Iniciar Liga', 'en': 'Start League'},
  'league.startLeagueConfirm': {
    'es': 'Se generará el calendario con {count} equipos. ¿Continuar?',
    'en': 'The schedule will be generated with {count} teams. Continue?',
  },
  'league.leagueStarted': {
    'es': '¡Liga iniciada! Calendario generado',
    'en': 'League started! Schedule generated',
  },
  'league.needMoreTeams': {
    'es': 'Se necesitan al menos 2 equipos para iniciar',
    'en': 'At least 2 teams are needed to start',
  },
  'league.leave': {'es': 'Salir', 'en': 'Leave'},
  'league.leaveLeague': {'es': 'Abandonar Liga', 'en': 'Leave League'},
  'league.leaveLeagueConfirm': {
    'es': '¿Seguro que quieres abandonar esta liga?',
    'en': 'Are you sure you want to leave this league?',
  },
  'league.leftLeague': {
    'es': 'Has abandonado la liga',
    'en': 'You have left the league',
  },

  // ── Create League ───────────────────────────────────────────────────────
  'createLeague.info': {
    'es': 'INFORMACIÓN DE LA LIGA',
    'en': 'LEAGUE INFORMATION',
  },
  'createLeague.format': {
    'es': 'FORMATO Y PARTICIPANTES',
    'en': 'FORMAT & PARTICIPANTS',
  },
  'createLeague.formatLabel': {'es': 'FORMATO', 'en': 'FORMAT'},
  'createLeague.maxTeams': {'es': 'Equipos máximos', 'en': 'Max teams'},
  'createLeague.budget': {'es': 'Presupuesto inicial', 'en': 'Starting budget'},
  'createLeague.rules': {'es': 'REGLAS', 'en': 'RULES'},
  'createLeague.created': {'es': '¡Liga creada!', 'en': 'League created!'},
  'createLeague.shareCode': {
    'es': 'Comparte este código con los jugadores que quieras invitar:',
    'en': 'Share this code with the players you want to invite:',
  },
  'createLeague.codeCopied': {'es': 'Código copiado', 'en': 'Code copied'},
  'createLeague.copyCode': {'es': 'Copiar código', 'en': 'Copy code'},
  'createLeague.goToLeagues': {
    'es': 'Ir a Mis Ligas',
    'en': 'Go to My Leagues',
  },
  'createLeague.viewLeague': {'es': 'Ver Liga', 'en': 'View League'},
  'createLeague.error': {
    'es': 'Error al crear la liga: {e}',
    'en': 'Error creating league: {e}',
  },
  'createLeague.leagueName': {
    'es': 'Nombre de la liga',
    'en': 'League name',
  },
  'createLeague.leagueNameHint': {
    'es': 'La Liga del Viejo Mundo',
    'en': 'The Old World League',
  },
  'createLeague.description': {'es': 'Descripción', 'en': 'Description'},
  'createLeague.descHint': {
    'es': 'Descripción de la liga (opcional)',
    'en': 'League description (optional)',
  },
  'createLeague.league': {'es': 'Liga', 'en': 'League'},
  'createLeague.cup': {'es': 'Copa', 'en': 'Cup'},
  'createLeague.swiss': {'es': 'Suizo', 'en': 'Swiss'},
  'createLeague.rounds': {'es': 'Jornadas', 'en': 'Rounds'},
  'createLeague.create': {'es': 'CREAR LIGA', 'en': 'CREATE LEAGUE'},

  // ── Join League ─────────────────────────────────────────────────────────
  'joinLeague.title': {'es': 'UNIRSE A UNA LIGA', 'en': 'JOIN A LEAGUE'},
  'joinLeague.step1': {
    'es': 'PASO 1 — CÓDIGO DE INVITACIÓN',
    'en': 'STEP 1 — INVITE CODE',
  },
  'joinLeague.step1Body': {
    'es': 'Introduce el código que te ha compartido el organizador de la liga:',
    'en': 'Enter the code shared by the league organizer:',
  },
  'joinLeague.step2': {
    'es': 'PASO 2 — ELIGE TU EQUIPO',
    'en': 'STEP 2 — CHOOSE YOUR TEAM',
  },
  'joinLeague.search': {'es': 'Buscar', 'en': 'Search'},
  'joinLeague.full': {'es': 'LLENA', 'en': 'FULL'},
  'joinLeague.organizedBy': {
    'es': 'Organizada por {name}',
    'en': 'Organized by {name}',
  },
  'joinLeague.noTeams': {
    'es': 'No tienes equipos creados.',
    'en': "You don't have any teams.",
  },
  'joinLeague.createTeam': {
    'es': 'Crear un equipo →',
    'en': 'Create a team →',
  },
  'joinLeague.wrongCode': {
    'es': 'Código incorrecto — no se encontró ninguna liga',
    'en': 'Incorrect code — no league found',
  },
  'joinLeague.alreadyJoined': {
    'es': 'Ya tienes un equipo inscrito en esta liga',
    'en': 'You already have a team in this league',
  },
  'joinLeague.leagueFull': {
    'es': 'La liga ya está llena',
    'en': 'The league is already full',
  },
  'joinLeague.inviteCode': {
    'es': 'Introduce el código de invitación de la liga.',
    'en': 'Enter the league invite code.',
  },

  // ── League Overview ─────────────────────────────────────────────────────
  'leagueOverview.standings': {'es': 'Clasificación', 'en': 'Standings'},
  'leagueOverview.calendar': {'es': 'Calendario', 'en': 'Calendar'},
  'leagueOverview.currentRound': {
    'es': 'Jornada Actual',
    'en': 'Current Round',
  },
  'leagueOverview.stats': {'es': 'Estadísticas', 'en': 'Statistics'},
  'leagueOverview.bracket': {'es': 'Bracket', 'en': 'Bracket'},
  'leagueOverview.round': {'es': 'JORNADA {n}', 'en': 'ROUND {n}'},
  'leagueOverview.viewAll': {'es': 'VER TODAS', 'en': 'VIEW ALL'},
  'leagueOverview.standingsTitle': {
    'es': 'CLASIFICACIÓN',
    'en': 'STANDINGS',
  },
  'leagueOverview.general': {'es': 'General', 'en': 'General'},
  'leagueOverview.casualties': {'es': 'Bajas (CAS)', 'en': 'Casualties (CAS)'},
  'leagueOverview.actions': {
    'es': 'ACCIONES DE LIGA',
    'en': 'LEAGUE ACTIONS',
  },
  'leagueOverview.viewTeams': {'es': 'Ver Equipos', 'en': 'View Teams'},
  'leagueOverview.viewRosters': {
    'es': 'Ver Equipos y Plantillas',
    'en': 'View Teams & Rosters',
  },
  'leagueOverview.rules': {
    'es': 'Reglamento de la Liga',
    'en': 'League Rules',
  },
  'leagueOverview.contactCommish': {
    'es': 'Contactar Comisario',
    'en': 'Contact Commissioner',
  },
  'leagueOverview.recentActivity': {
    'es': 'ACTIVIDAD RECIENTE',
    'en': 'RECENT ACTIVITY',
  },
  'leagueOverview.leagueTeams': {
    'es': 'Equipos de la Liga',
    'en': 'League Teams',
  },
  'leagueOverview.errorTeams': {
    'es': 'Error al cargar equipos',
    'en': 'Error loading teams',
  },
  'leagueOverview.errorFormat': {
    'es': 'Error al cargar formato',
    'en': 'Error loading format',
  },
  'leagueOverview.errorLoading': {
    'es': 'Error al cargar la liga',
    'en': 'Error loading league',
  },
  'leagueOverview.myTeam': {'es': 'Mi Equipo', 'en': 'My Team'},
  'leagueOverview.noTeam': {
    'es': 'No tienes equipo en esta liga',
    'en': "You don't have a team in this league",
  },

  // Standings table
  'standings.pos': {'es': 'POS', 'en': 'POS'},
  'standings.team': {'es': 'EQUIPO', 'en': 'TEAM'},
  'standings.pts': {'es': 'PTS', 'en': 'PTS'},
  'standings.played': {'es': 'J', 'en': 'P'},
  'standings.wins': {'es': 'G', 'en': 'W'},
  'standings.draws': {'es': 'E', 'en': 'D'},
  'standings.losses': {'es': 'P', 'en': 'L'},
  'standings.tdDiff': {'es': 'TD+/-', 'en': 'TD+/-'},
  'standings.cas': {'es': 'CAS', 'en': 'CAS'},

  // Match card
  'match.pending': {'es': 'PENDIENTE', 'en': 'PENDING'},
  'match.completed': {'es': 'COMPLETADO', 'en': 'COMPLETED'},
  'match.inProgress': {'es': 'EN PROGRESO', 'en': 'IN PROGRESS'},
  'match.startMatch': {'es': 'Iniciar Partido', 'en': 'Start Match'},
  'match.continueMatch': {'es': 'Continuar Partido', 'en': 'Continue Match'},
  'match.registerPostMatch': {
    'es': 'Registrar Post-Partido',
    'en': 'Register Post-Match',
  },

  // Live Match
  'liveMatch.title': {'es': 'Partido en Vivo', 'en': 'Live Match'},
  'liveMatch.round': {'es': 'Jornada', 'en': 'Round'},
  'liveMatch.preMatchHint': {
    'es':
        'Antes de iniciar, asegúrate de que ambos equipos estén preparados. Una vez iniciado, no se podrán modificar los rosters.',
    'en':
        'Before starting, make sure both teams are ready. Once started, rosters cannot be modified.',
  },
  'liveMatch.startMatch': {'es': 'Iniciar Partido', 'en': 'Start Match'},
  'liveMatch.inProgress': {'es': 'EN PROGRESO', 'en': 'IN PROGRESS'},
  'liveMatch.half': {'es': 'Parte', 'en': 'Half'},
  'liveMatch.turn': {'es': 'Turno', 'en': 'Turn'},
  'liveMatch.tabSetup': {'es': 'Configuración', 'en': 'Setup'},
  'liveMatch.tabEvents': {'es': 'Eventos', 'en': 'Events'},
  'liveMatch.tabInjuries': {'es': 'Lesiones', 'en': 'Injuries'},
  'liveMatch.tabLog': {'es': 'Registro', 'en': 'Log'},
  'liveMatch.matchSetup': {
    'es': 'Configuración de partido',
    'en': 'Match Setup'
  },
  'liveMatch.weather': {'es': 'Clima', 'en': 'Weather'},
  'liveMatch.kickoffEvent': {'es': 'Evento de Patada', 'en': 'Kickoff Event'},
  'liveMatch.gate': {'es': 'Asistencia', 'en': 'Gate'},
  'liveMatch.rerollsUsed': {'es': 'Rerolls Usados', 'en': 'Rerolls Used'},
  'liveMatch.quickAdd': {'es': 'Acción Rápida', 'en': 'Quick Add'},
  'liveMatch.completion': {'es': 'Pase', 'en': 'Completion'},
  'liveMatch.interception': {'es': 'Intercepción', 'en': 'Interception'},
  'liveMatch.eventLog': {'es': 'Registro de Eventos', 'en': 'Event Log'},
  'liveMatch.noEvents': {
    'es': 'Sin eventos registrados',
    'en': 'No events recorded'
  },
  'liveMatch.addInjury': {'es': 'Registrar Lesión', 'en': 'Record Injury'},
  'liveMatch.casualty': {'es': 'Baja', 'en': 'Casualty'},
  'liveMatch.injuryLog': {'es': 'Registro de Lesiones', 'en': 'Injury Log'},
  'liveMatch.noInjuries': {
    'es': 'Sin lesiones registradas',
    'en': 'No injuries recorded'
  },
  'liveMatch.auditTrail': {'es': 'Historial de Cambios', 'en': 'Audit Trail'},
  'liveMatch.events': {'es': 'Eventos', 'en': 'Events'},
  'liveMatch.complete': {'es': 'Finalizar Partido', 'en': 'Complete Match'},
  'liveMatch.completeTitle': {
    'es': 'Finalizar partido',
    'en': 'Complete match'
  },
  'liveMatch.completeConfirm': {
    'es':
        '¿Estás seguro de que quieres finalizar el partido? Se actualizarán las clasificaciones.',
    'en':
        'Are you sure you want to complete the match? Standings will be updated.',
  },
  'liveMatch.matchCompleted': {
    'es': 'PARTIDO FINALIZADO',
    'en': 'MATCH COMPLETED'
  },
  'liveMatch.add': {'es': 'Añadir', 'en': 'Add'},
  'liveMatch.playerName': {'es': 'Nombre del jugador', 'en': 'Player name'},
  'liveMatch.victimName': {'es': 'Nombre de la víctima', 'en': 'Victim name'},
  'liveMatch.injuryType': {'es': 'Tipo de lesión', 'en': 'Injury type'},
  'liveMatch.detail': {'es': 'Detalle (opcional)', 'en': 'Detail (optional)'},
  'liveMatch.preMatchCeremony': {
    'es': 'Ceremonia Pre-Partido',
    'en': 'Pre-Match Ceremony'
  },
  'liveMatch.selectWeather': {
    'es': 'Seleccionar Clima',
    'en': 'Select Weather'
  },
  'liveMatch.selectKickoff': {
    'es': 'Seleccionar Patada Inicial',
    'en': 'Select Kickoff'
  },
  'liveMatch.ceremonyRequired': {
    'es':
        'Debes seleccionar clima y evento de patada antes de iniciar el partido.',
    'en':
        'You must select weather and kickoff event before starting the match.',
  },
  'liveMatch.pending': {'es': 'Pendiente', 'en': 'Pending'},
  'liveMatch.selectPlayer': {
    'es': 'Seleccionar jugador',
    'en': 'Select player'
  },
  'liveMatch.selectVictim': {
    'es': 'Seleccionar víctima',
    'en': 'Select victim'
  },
  'liveMatch.teamPreparation': {
    'es': 'Preparación de Equipo',
    'en': 'Team Preparation'
  },
  'liveMatch.roster': {'es': 'Plantilla', 'en': 'Roster'},
  'liveMatch.treasury': {'es': 'Tesorería', 'en': 'Treasury'},
  'liveMatch.rerolls': {'es': 'Rerolls', 'en': 'Rerolls'},
  'liveMatch.cheerleaders': {'es': 'Animadoras', 'en': 'Cheerleaders'},
  'liveMatch.coaches': {'es': 'Asistentes', 'en': 'Asst. Coaches'},
  'liveMatch.apothecary': {'es': 'Boticario', 'en': 'Apothecary'},
  'liveMatch.fanFactor': {'es': 'Factor Fan', 'en': 'Fan Factor'},
  'liveMatch.teamValue': {'es': 'Valor de Equipo', 'en': 'Team Value'},
  'liveMatch.players': {'es': 'Jugadores', 'en': 'Players'},
  'liveMatch.buyReroll': {'es': 'Comprar Reroll', 'en': 'Buy Reroll'},
  'liveMatch.hireStaff': {'es': 'Contratar Staff', 'en': 'Hire Staff'},
  'liveMatch.hirePlayer': {'es': 'Fichar Jugador', 'en': 'Hire Player'},
  'liveMatch.starPlayers': {'es': 'Jugadores Estrella', 'en': 'Star Players'},
  'liveMatch.inducements': {'es': 'Alicientes', 'en': 'Inducements'},
  'liveMatch.costGold': {'es': 'po', 'en': 'gp'},
  'liveMatch.purchased': {'es': 'Comprado', 'en': 'Purchased'},
  'liveMatch.notAvailable': {'es': 'No disponible', 'en': 'Not available'},
  'liveMatch.max': {'es': 'Máx', 'en': 'Max'},

  // Bracket
  'bracket.notGenerated': {
    'es': 'Bracket no generado todavía',
    'en': 'Bracket not generated yet',
  },
  'bracket.startLeague': {
    'es': 'Inicia la liga para generar los enfrentamientos',
    'en': 'Start the league to generate matchups',
  },
  'bracket.final_': {'es': 'Final', 'en': 'Final'},
  'bracket.semis': {'es': 'Semifinales', 'en': 'Semifinals'},
  'bracket.quarters': {'es': 'Cuartos', 'en': 'Quarterfinals'},
  'bracket.eighths': {'es': 'Octavos', 'en': 'Round of 16'},

  // ── Team Management ─────────────────────────────────────────────────────
  'team.rosterManagement': {
    'es': 'Gestión de Plantilla',
    'en': 'Roster Management',
  },
  'team.readOnly': {'es': 'Solo lectura', 'en': 'Read-only'},
  'team.refresh': {'es': 'Actualizar', 'en': 'Refresh'},
  'team.backToLeague': {'es': 'Volver a la Liga', 'en': 'Back to League'},
  'team.backToTeams': {
    'es': 'Volver a Mis Equipos',
    'en': 'Back to My Teams',
  },
  'team.manageRoster': {
    'es':
        'Gestiona tu plantilla, tesorería, staff y preparativos para el próximo partido.',
    'en':
        'Manage your roster, treasury, staff and preparations for the next match.',
  },
  'team.status': {'es': 'ESTADO: ', 'en': 'STATUS: '},
  'team.validRoster': {'es': 'Plantilla Válida', 'en': 'Valid Roster'},
  'team.invalidRoster': {'es': 'Plantilla Inválida', 'en': 'Invalid Roster'},
  'team.viewHistory': {'es': 'Ver Historial', 'en': 'View History'},
  'team.notAvailable': {'es': 'No disponible', 'en': 'Not available'},
  'team.apothecary': {'es': 'Apotecario', 'en': 'Apothecary'},
  'team.hire50k': {'es': 'Contratar  50k', 'en': 'Hire  50k'},
  'team.noApothecary': {'es': 'Sin apotecario', 'en': 'No apothecary'},
  'team.playersCount': {'es': 'Jugadores: {n}/16', 'en': 'Players: {n}/16'},
  'team.exportRoster': {'es': 'Exportar Roster', 'en': 'Export Roster'},
  'team.noPlayers': {
    'es': 'Sin jugadores que mostrar',
    'en': 'No players to show',
  },
  'team.firePlayer': {'es': 'Despedir jugador', 'en': 'Fire player'},
  'team.fireConfirm': {
    'es': '¿Despedir a {name}? El coste no se reembolsa.',
    'en': "Fire {name}? The cost won't be refunded.",
  },
  'team.fire': {'es': 'Despedir', 'en': 'Fire'},
  'team.assistantCoaches': {
    'es': 'ENTRENADORES AYUDANTES',
    'en': 'ASSISTANT COACHES',
  },
  'team.cheerleaders': {'es': 'ANIMADORAS', 'en': 'CHEERLEADERS'},
  'team.levelUp': {'es': 'SUBIR NIVEL', 'en': 'LEVEL UP'},
  'team.treasuryLog': {
    'es': 'REGISTRO DE TESORERÍA',
    'en': 'TREASURY LOG',
  },
  'team.manualFunds': {
    'es': 'Ajuste Manual de Fondos',
    'en': 'Manual Fund Adjustment',
  },
  'team.staffManagement': {
    'es': 'STAFF Y GESTIÓN',
    'en': 'STAFF & MANAGEMENT',
  },
  'team.rosterStatus': {'es': 'Estado del Roster', 'en': 'Roster Status'},
  'team.costModifier': {
    'es': 'Coste: {cost}k. Modificador a Eventos.',
    'en': 'Cost: {cost}k. Event modifier.',
  },
  'team.hire': {'es': 'Contratar', 'en': 'Hire'},
  'team.hirePlayer': {'es': 'Contratar Jugador', 'en': 'Hire Player'},
  'team.errorPositions': {
    'es': 'Error al cargar posiciones: {err}',
    'en': 'Error loading positions: {err}',
  },
  'team.sign': {'es': 'Fichar', 'en': 'Sign'},
  'team.editPlayer': {'es': 'Editar Jugador', 'en': 'Edit Player'},
  'team.errorLoading': {
    'es': 'Error al cargar el equipo',
    'en': 'Error loading team',
  },
  'team.errorLoadingTeams': {
    'es': 'Error al cargar equipos',
    'en': 'Error loading teams',
  },

  // ── Post-Match ──────────────────────────────────────────────────────────
  'aftermatch.title': {'es': 'Post-Partido', 'en': 'Post-Match'},
  'aftermatch.result': {'es': 'Resultado', 'en': 'Result'},
  'aftermatch.touchdowns': {'es': 'Touchdowns', 'en': 'Touchdowns'},
  'aftermatch.injuries': {'es': 'Lesiones', 'en': 'Injuries'},
  'aftermatch.sppBonus': {'es': 'SPP Bonus', 'en': 'SPP Bonus'},
  'aftermatch.confirm': {'es': 'Confirmar', 'en': 'Confirm'},
  'aftermatch.finalResult': {'es': 'Resultado Final', 'en': 'Final Result'},
  'aftermatch.enterScore': {
    'es': 'Introduce el marcador del partido',
    'en': 'Enter the match score',
  },
  'aftermatch.tdRegistry': {
    'es': 'Registro de Touchdowns',
    'en': 'Touchdown Registry',
  },
  'aftermatch.tdRegistryBody': {
    'es': 'Asigna cada touchdown a su anotador',
    'en': 'Assign each touchdown to its scorer',
  },
  'aftermatch.injuryRegistry': {
    'es': 'Registro de Lesiones',
    'en': 'Injury Registry',
  },
  'aftermatch.injuryRegistryBody': {
    'es': 'Registra bajas graves, lesiones y muertes',
    'en': 'Register serious injuries and deaths',
  },
  'aftermatch.sppSummary': {'es': 'Resumen de SPP', 'en': 'SPP Summary'},
  'aftermatch.sppSummaryBody': {
    'es': 'Revisa y añade SPP de bonus (MVP, pases, etc.)',
    'en': 'Review and add bonus SPP (MVP, passes, etc.)',
  },
  'aftermatch.confirmReport': {
    'es': 'Confirmar Acta',
    'en': 'Confirm Report',
  },
  'aftermatch.confirmBody': {
    'es': 'Revisa los datos antes de enviar',
    'en': 'Review data before submitting',
  },
  'aftermatch.home': {'es': 'Local', 'en': 'Home'},
  'aftermatch.away': {'es': 'Visitante', 'en': 'Away'},
  'aftermatch.previous': {'es': 'Anterior', 'en': 'Previous'},
  'aftermatch.next': {'es': 'Siguiente', 'en': 'Next'},
  'aftermatch.exitTitle': {
    'es': '¿Salir del registro?',
    'en': 'Exit registration?',
  },
  'aftermatch.exit': {'es': 'Salir', 'en': 'Exit'},
  'aftermatch.reportSent': {
    'es': 'Acta enviada correctamente',
    'en': 'Report sent successfully',
  },
  'aftermatch.registerInjury': {
    'es': 'Registrar lesión',
    'en': 'Register injury',
  },
  'aftermatch.mng': {'es': 'MNG', 'en': 'MNG'},
  'aftermatch.dead': {'es': 'Muerto', 'en': 'Dead'},
  'aftermatch.mvp': {'es': 'MVP', 'en': 'MVP'},
  'aftermatch.pass': {'es': 'Pase', 'en': 'Pass'},
  'aftermatch.interception': {'es': 'Intercepción', 'en': 'Interception'},
  'aftermatch.tdRegistered': {
    'es': '{n} / {total} touchdowns registrados',
    'en': '{n} / {total} touchdowns registered',
  },
  'aftermatch.remaining': {
    'es': '{n} restantes',
    'en': '{n} remaining',
  },
  'aftermatch.selectScorer': {
    'es': 'Selecciona anotador',
    'en': 'Select scorer',
  },
  'aftermatch.injuryInfo': {
    'es':
        'Solo registra lesiones que afecten al jugador (BH, SI, RSI, muerte). Las bajas normales se cuentan automáticamente.',
    'en':
        'Only record injuries that affect the player (BH, SI, RSI, death). Normal casualties are counted automatically.',
  },
  'aftermatch.injuredPlayer': {
    'es': 'Jugador lesionado',
    'en': 'Injured player',
  },
  'aftermatch.injuryType': {
    'es': 'Tipo de lesión',
    'en': 'Injury type',
  },
  'aftermatch.descriptionOptional': {
    'es': 'Descripción (opcional)',
    'en': 'Description (optional)',
  },
  'aftermatch.descriptionHint': {
    'es': 'ej: -1 Fuerza',
    'en': 'e.g. -1 Strength',
  },
  'aftermatch.registerInjuryBtn': {
    'es': 'Registrar lesión',
    'en': 'Register injury',
  },
  'aftermatch.submitReport': {
    'es': 'Enviar Acta',
    'en': 'Submit Report',
  },
  'aftermatch.exitBody': {
    'es': 'Se perderán los datos introducidos.',
    'en': 'Entered data will be lost.',
  },
  'aftermatch.warningValidation': {
    'es': 'Una vez enviada, el acta deberá ser validada por el comisario.',
    'en': 'Once submitted, the report must be validated by the commissioner.',
  },
  'aftermatch.assign': {
    'es': 'Asignar {reason}',
    'en': 'Assign {reason}',
  },
  'aftermatch.injuryFor': {
    'es': 'Lesión {team}',
    'en': 'Injury {team}',
  },

  // ── Wiki: Skills ────────────────────────────────────────────────────────
  'wikiSkills.title': {'es': 'HABILIDADES', 'en': 'SKILLS'},
  'wikiSkills.subtitle': {
    'es': 'Catálogo completo de habilidades y rasgos',
    'en': 'Complete catalog of skills and traits',
  },
  'wikiSkills.errorLoading': {
    'es': 'Error al cargar habilidades: {err}',
    'en': 'Error loading skills: {err}',
  },
  'wikiSkills.advancement': {
    'es': 'TABLA DE AVANCE',
    'en': 'ADVANCEMENT TABLE',
  },

  // ── Wiki: Weather ───────────────────────────────────────────────────────
  'wikiWeather.title': {'es': 'CLIMA & PRE-JUEGO', 'en': 'WEATHER & PRE-GAME'},
  'wikiWeather.subtitle': {
    'es': 'Tabla meteorológica, secuencia de pre-partido y eventos de kickoff',
    'en': 'Weather table, pre-game sequence and kickoff events',
  },
  'wikiWeather.weatherTable': {
    'es': 'TABLA METEOROLÓGICA',
    'en': 'WEATHER TABLE',
  },
  'wikiWeather.preGame': {
    'es': 'SECUENCIA DE PRE-JUEGO',
    'en': 'PRE-GAME SEQUENCE',
  },
  'wikiWeather.kickoff': {
    'es': 'SECUENCIA DE KICKOFF',
    'en': 'KICKOFF SEQUENCE',
  },

  // ── Wiki: Star Players ─────────────────────────────────────────────────
  'wikiStars.title': {'es': 'JUGADORES ESTRELLA', 'en': 'STAR PLAYERS'},
  'wikiStars.subtitle': {
    'es': 'Mercenarios legendarios del Blood Bowl',
    'en': 'Legendary Blood Bowl mercenaries',
  },
  'wikiStars.search': {
    'es': 'Buscar jugador estrella...',
    'en': 'Search star player...',
  },
  'wikiStars.all': {'es': 'Todos', 'en': 'All'},
  'wikiStars.errorLoading': {
    'es': 'Error al cargar jugadores estrella',
    'en': 'Error loading star players',
  },
  'wikiStars.playsFor': {'es': 'Juega para:', 'en': 'Plays for:'},

  // ── Tactics ─────────────────────────────────────────────────────────────
  'tactics.title': {'es': 'EDITOR DE TÁCTICAS', 'en': 'TACTICS EDITOR'},
  'tactics.subtitle': {
    'es': 'Diseña y guarda tus formaciones',
    'en': 'Design and save your formations',
  },
  'tactics.selectTeam': {
    'es': 'Selecciona una raza para empezar',
    'en': 'Select a race to start',
  },
  'tactics.yourPositions': {
    'es': 'POSICIONES DE TU EQUIPO',
    'en': 'YOUR TEAM POSITIONS',
  },
  'tactics.selectPosition': {
    'es':
        'Selecciona una posición y haz clic en el campo para colocarla. Haz clic en un jugador colocado para quitarlo.',
    'en':
        'Select a position and click on the pitch to place it. Click a placed player to remove them.',
  },
  'tactics.opponent': {
    'es': 'JUGADORES RIVALES',
    'en': 'OPPONENT PLAYERS',
  },
  'tactics.opponentDesc': {
    'es': 'Coloca fichas genéricas del rival.',
    'en': 'Place generic opponent tokens.',
  },
  'tactics.oppLineman': {'es': 'Lineman', 'en': 'Lineman'},
  'tactics.oppBlitzer': {'es': 'Blitzer', 'en': 'Blitzer'},
  'tactics.oppBigGuy': {'es': 'Big Guy', 'en': 'Big Guy'},
  'tactics.save': {'es': 'Guardar', 'en': 'Save'},
  'tactics.load': {'es': 'Cargar', 'en': 'Load'},
  'tactics.clear': {'es': 'Limpiar', 'en': 'Clear'},
  'tactics.attack': {'es': 'Ataque', 'en': 'Attack'},
  'tactics.defense': {'es': 'Defensa', 'en': 'Defense'},
  'tactics.tacticName': {
    'es': 'Nombre de la táctica',
    'en': 'Tactic name',
  },
  'tactics.validationWarning': {
    'es':
        'La formación requiere al menos 3 jugadores en la Línea de Scrimmage.',
    'en': 'Formation requires at least 3 players on the Line of Scrimmage.',
  },
  'tactics.ownPlayers': {'es': 'Propios: {n}/11', 'en': 'Own: {n}/11'},
  'tactics.oppPlayers': {'es': 'Rivales: {n}/11', 'en': 'Opponents: {n}/11'},
  'tactics.losCount': {'es': 'En LOS: {n}', 'en': 'On LOS: {n}'},

  // My Tactics
  'myTactics.title': {'es': 'MIS TÁCTICAS', 'en': 'MY TACTICS'},
  'myTactics.subtitle': {
    'es': 'Gestiona tus formaciones guardadas',
    'en': 'Manage your saved formations',
  },
  'myTactics.noTactics': {
    'es': 'No tienes tácticas guardadas',
    'en': "You don't have saved tactics",
  },
  'myTactics.createFirst': {
    'es': 'Crea tu primera táctica en el editor',
    'en': 'Create your first tactic in the editor',
  },
  'myTactics.delete': {'es': 'Eliminar', 'en': 'Delete'},
  'myTactics.edit': {'es': 'Editar', 'en': 'Edit'},

  // ── Player Card ─────────────────────────────────────────────────────────
  'player.skills': {'es': 'HABILIDADES', 'en': 'SKILLS'},
  'player.traits': {'es': 'RASGOS', 'en': 'TRAITS'},
  'player.history': {'es': 'HISTORIAL', 'en': 'HISTORY'},
  'player.levelUp': {'es': 'SUBIR DE NIVEL', 'en': 'LEVEL UP'},
  'player.selectSkill': {
    'es': 'Selecciona una habilidad',
    'en': 'Select a skill',
  },
  'player.confirm': {'es': 'Confirmar', 'en': 'Confirm'},
  'player.number': {'es': 'Dorsal', 'en': 'Number'},
  'player.name': {'es': 'Nombre', 'en': 'Name'},
  'player.position': {'es': 'Posición', 'en': 'Position'},
  'player.spp': {'es': 'SPP', 'en': 'SPP'},
  'player.value': {'es': 'Valor', 'en': 'Value'},
  'player.status': {'es': 'Estado', 'en': 'Status'},
  'player.healthy': {'es': 'Sano', 'en': 'Healthy'},
  'player.mng': {'es': 'MNG', 'en': 'MNG'},
  'player.dead': {'es': 'Muerto', 'en': 'Dead'},
  'player.editName': {'es': 'Editar nombre', 'en': 'Edit name'},
  'player.editNumber': {'es': 'Editar dorsal', 'en': 'Edit number'},
  'player.back': {'es': 'Volver', 'en': 'Back'},
  'player.editPlayer': {'es': 'Editar Jugador', 'en': 'Edit Player'},
  'player.nameEmpty': {
    'es': 'El nombre no puede estar vacío',
    'en': 'Name cannot be empty',
  },
  'player.numberRequired': {
    'es': 'El dorsal es obligatorio',
    'en': 'Number is required',
  },
  'player.numberRange': {
    'es': 'El dorsal debe estar entre 1 y 99',
    'en': 'Number must be between 1 and 99',
  },
  'player.updated': {
    'es': 'Jugador actualizado',
    'en': 'Player updated',
  },
  'player.addSkill': {'es': 'AÑADIR HABILIDAD', 'en': 'ADD SKILL'},
  'player.searchSkill': {
    'es': 'Buscar habilidad...',
    'en': 'Search skill...',
  },
  'player.noResults': {
    'es': 'Sin resultados',
    'en': 'No results',
  },
  'player.acquired': {'es': 'ADQUIRIDA', 'en': 'ACQUIRED'},
  'player.loadingSkills': {
    'es': 'Cargando habilidades...',
    'en': 'Loading skills...',
  },
  'player.noSkills': {'es': 'Sin habilidades', 'en': 'No skills'},
  'player.addSkillHint': {
    'es': 'Añade habilidades desde el botón de arriba',
    'en': 'Add skills using the button above',
  },
  'player.noSkillsYet': {
    'es': 'Este jugador aún no tiene habilidades adquiridas.',
    'en': 'This player has no acquired skills yet.',
  },
  'player.notFound': {
    'es': 'Jugador no encontrado',
    'en': 'Player not found',
  },
  'player.saved': {'es': 'Guardado', 'en': 'Saved'},
  'player.saveChanges': {
    'es': 'Guardar cambios',
    'en': 'Save changes',
  },
  'player.dismiss': {'es': 'DESPEDIR', 'en': 'DISMISS'},
  'player.changesSaved': {
    'es': 'Cambios guardados',
    'en': 'Changes saved',
  },
  'player.noMatches': {'es': 'No hay partidos', 'en': 'No matches'},
  'player.noMatchesDesc': {
    'es': 'Este jugador aún no ha disputado partidos.',
    'en': 'This player has not played any matches yet.',
  },
  'player.noAchievements': {'es': 'Sin logros', 'en': 'No achievements'},
  'player.noAchievementsDesc': {
    'es': 'Los logros aparecerán según juegue partidos.',
    'en': 'Achievements will appear as matches are played.',
  },
  'player.noNotes': {
    'es': 'Sin notas registradas.',
    'en': 'No notes recorded.',
  },

  // ── Team Creator ────────────────────────────────────────────────────────
  'teamCreator.title': {'es': 'CREAR EQUIPO', 'en': 'CREATE TEAM'},
  'teamCreator.subtitle': {
    'es': 'Elige una raza y personaliza tu equipo',
    'en': 'Choose a race and customize your team',
  },
  'teamCreator.step1': {'es': 'ELIGE RAZA', 'en': 'CHOOSE RACE'},
  'teamCreator.step2': {'es': 'PERSONALIZAR', 'en': 'CUSTOMIZE'},
  'teamCreator.teamName': {'es': 'Nombre del equipo', 'en': 'Team name'},
  'teamCreator.teamNameHint': {
    'es': 'Los Destructores de Altdorf',
    'en': 'The Altdorf Destroyers',
  },
  'teamCreator.budget': {
    'es': 'Presupuesto: {budget}k',
    'en': 'Budget: {budget}k',
  },
  'teamCreator.create': {'es': 'CREAR EQUIPO', 'en': 'CREATE TEAM'},
  'teamCreator.back': {'es': 'Volver', 'en': 'Back'},
  'teamCreator.search': {'es': 'Buscar raza...', 'en': 'Search race...'},
  'teamCreator.positions': {'es': 'Posiciones', 'en': 'Positions'},
  'teamCreator.rerolls': {'es': 'Re-rolls', 'en': 'Re-rolls'},
  'teamCreator.maxQty': {'es': 'Máx: {n}', 'en': 'Max: {n}'},
  'teamCreator.cost': {'es': 'Coste: {cost}k', 'en': 'Cost: {cost}k'},
  'teamCreator.hirePosition': {'es': 'Fichar', 'en': 'Hire'},

  // ── Roster ──────────────────────────────────────────────────────────────
  'roster.title': {'es': 'PLANTILLA', 'en': 'ROSTER'},
  'roster.playerCount': {'es': 'Jugadores: {n}/16', 'en': 'Players: {n}/16'},
  'roster.treasury': {'es': 'Tesorería: {gold}k', 'en': 'Treasury: {gold}k'},
  'roster.rerolls': {'es': 'Re-rolls: {n}', 'en': 'Re-rolls: {n}'},
  'roster.fanFactor': {'es': 'Fan Factor: {n}', 'en': 'Fan Factor: {n}'},
  'roster.tv': {'es': 'TV: {tv}k', 'en': 'TV: {tv}k'},

  // ── Common ──────────────────────────────────────────────────────────────
  'common.cancel': {'es': 'Cancelar', 'en': 'Cancel'},
  'common.error': {'es': 'Error: {e}', 'en': 'Error: {e}'},
  'common.retry': {'es': 'Reintentar', 'en': 'Retry'},
  'common.save': {'es': 'Guardar', 'en': 'Save'},
  'common.delete': {'es': 'Eliminar', 'en': 'Delete'},
  'common.edit': {'es': 'Editar', 'en': 'Edit'},
  'common.close': {'es': 'Cerrar', 'en': 'Close'},
  'common.loading': {'es': 'Cargando...', 'en': 'Loading...'},
  'common.perkAdded': {
    'es': '¡{name} añadida!',
    'en': '{name} added!',
  },
  'common.unknownError': {'es': 'Error desconocido', 'en': 'Unknown error'},
};
