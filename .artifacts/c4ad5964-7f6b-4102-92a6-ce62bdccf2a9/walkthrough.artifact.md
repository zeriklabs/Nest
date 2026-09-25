# Walkthrough de Compatibilidad Legacy de Grupos

Se ha implementado la compatibilidad total con la estructura de base de datos de la versión anterior para los grupos y sus publicaciones en Firestore.

## Cambios Realizados

### Modelos de Datos Unificados
- **Group**: Ahora incluye `adminId`, `adminIds` y `memberIds` en Firestore.
- **GroupPost**: Se ha rediseñado como un modelo "catch-all" que incluye campos para anuncios, notas, tareas y encuestas, permitiendo una colección `posts` unificada.
- **Note, Reminder, GroupPoll**: Ahora incluyen `authorId`, `authorPhotoUrl` y generan el formato de `timestamp` (long) y `type` requerido por la versión legacy.

### Servicios de Sincronización
- **FirebaseService**: Se ha redirigido el guardado de todos los elementos de grupo (incluyendo encuestas) a la subcolección `posts`.
- **DataService**:
    - La escucha de subcolecciones ahora procesa tipos `NOTE`, `TASK`, `POLL` y `ANNOUNCEMENT` desde la misma fuente.
    - El guardado de notas y recordatorios compartidos ahora se realiza en la subcolección `posts` con sus respectivos metadatos legacy.
    - Se ha asegurado que las reacciones y comentarios se persistan correctamente en la nueva ubicación unificada.

## Verificación Exitosa
- Los modelos generan el JSON exacto mostrado en las capturas de pantalla de Firestore.
- Se mantiene la retrocompatibilidad: la app puede leer tanto el formato nuevo como el antiguo gracias a los factory `fromJson` actualizados.
- La estructura unificada optimiza las consultas de Firestore para el "muro" del grupo.
