# Plan de Compatibilidad de Estructura de Grupos

Este plan detalla los cambios necesarios para que la estructura de los grupos y sus publicaciones en Firestore coincida con la versión anterior, basándose en las capturas de pantalla proporcionadas.

## Cambios Propuestos

### Modelos de Datos

#### [MODIFY] [group.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/models/group.dart)
- Actualizar `toJson` para incluir campos específicos de la versión anterior:
    - `adminId`: ID del primer administrador.
    - `adminIds`: Lista de IDs de administradores.
    - `memberIds`: Lista de IDs de miembros.
- Actualizar `fromJson` para soportar la lectura de estos campos.

#### [MODIFY] [group_post.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/models/group_post.dart)
- Unificar el modelo para incluir todos los campos mostrados en la captura de pantalla de la colección `posts`.
- Campos a añadir: `authorId`, `authorPhotoUrl`, `type`, `urgent`, `expiryTimestamp`, y campos relacionados con tareas y encuestas (`task...`, `poll...`).
- El `timestamp` debe manejarse como milisegundos (int) para compatibilidad con la versión anterior.
- Asegurar que `toJson` genere SIEMPRE todos los campos (aunque sean null o valores por defecto) para mantener la consistencia de la base de datos legacy.

#### [MODIFY] [note.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/models/note.dart), [reminder.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/models/reminder.dart), [group_poll.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/models/group_poll.dart)
- Añadir campo `authorId` y `authorPhotoUrl` si no están presentes.
- Asegurar que sus métodos `toJson` puedan generar la estructura unificada requerida por la colección `posts` de los grupos.

### Servicios

#### [MODIFY] [firebase_service.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/services/firebase_service.dart)
- Modificar `syncGroupPoll` para que guarde en la subcolección `posts` con `type: 'POLL'`, en lugar de la colección `polls`.
- Asegurar que todos los elementos del grupo (notas, tareas, encuestas, anuncios) se guarden en la subcolección `posts`.

#### [MODIFY] [data_service.dart](file:///C:/Users/javie/AndroidStudioProjects/nest/lib/services/data_service.dart)
- Actualizar `_syncGroupSubcollections` para procesar el tipo `NOTE` desde la subcolección `posts`.
- Modificar `addNoteToGroup` y `addReminderToGroup` para que guarden los elementos en la subcolección `posts` de Firestore usando el nuevo formato unificado.
- Actualizar `voteInPoll`, `toggleReaction` y `addComment` para que persistan los cambios en la subcolección `posts` de forma consistente.

## Plan de Verificación

### Pruebas Manuales
1. Crear un grupo y verificar que los campos `adminId`, `adminIds` y `memberIds` se guarden correctamente en Firestore.
2. Crear una nota compartida en el grupo y verificar que aparezca en la subcolección `posts` con `type: 'NOTE'` y todos los campos legacy.
3. Crear una encuesta y verificar que aparezca en la subcolección `posts` con `type: 'POLL'`.
4. Verificar que se puedan leer publicaciones creadas por la versión anterior (simulando los datos de las capturas).
