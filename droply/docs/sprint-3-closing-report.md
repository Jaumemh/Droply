# Sprint 3 - Check-in Semanal

## Resumen
Sprint 3 deja el `Tauler` de Droply preparado para gestionar carpetas y archivos con una experiencia visual clara, azul corporativo `#0066CC`, y seguridad delegada en RLS.

## Navegacion entre carpetas
- La carpeta actual se identifica por `currentFolderId`.
- El contenido visible se filtra por `parent_id = currentFolderId`.
- La raiz se representa con `currentFolderId = null`.
- Al entrar en una carpeta, el controlador recarga la vista con ese nuevo identificador.
- La ruta superior permite volver a la raiz y mantener el contexto de jerarquia.

## Seguridad
- Todas las operaciones de lectura y escritura pasan por filtros de `owner_id`.
- Las inserciones y actualizaciones respetan las politicas RLS ya definidas en el Sprint 1.
- El borrado de archivos se modela como eliminacion logica con `is_deleted = true`.

## Latencia percibida
- Se prioriza una carga simple por carpeta actual en lugar de hidratar un arbol completo.
- La UI responde con tarjetas para carpetas y filas para archivos, reduciendo la complejidad visual.
- El refresco despues de crear, renombrar o eliminar se hace sobre la carpeta activa, minimizando el trafico.

## Resultado
- El usuario puede navegar por carpetas y ejecutar CRUD basico sin salir del `Tauler`.
- La estructura queda lista para evolucionar a uploads y shares en el siguiente sprint.
