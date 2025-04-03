# Configuración CORS para Firebase Storage

Este documento explica cómo resolver los problemas de CORS (Cross-Origin Resource Sharing) que pueden ocurrir al subir imágenes a Firebase Storage desde la aplicación web de administración.

## Problema

Si estás viendo errores como:

```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' from origin 'http://192.168.0.192:8080' has been blocked by CORS policy
```

Es porque Firebase Storage está bloqueando las solicitudes desde tu servidor de desarrollo local.

## Solución

Sigue estos pasos para configurar correctamente CORS en Firebase Storage:

1. **Instala Firebase CLI** (si aún no lo tienes):
   ```
   npm install -g firebase-tools
   ```

2. **Inicia sesión en Firebase**:
   ```
   firebase login
   ```

3. **Aplica la configuración CORS** usando el archivo `cors.json` que hemos creado:
   ```
   firebase storage:cors set cors.json
   ```

4. **Verifica la configuración**:
   ```
   firebase storage:cors get
   ```

## Configuración CORS actualizada

Hemos actualizado el archivo `cors.json` para incluir:

- Orígenes permitidos: `http://192.168.0.192:8080`, `http://localhost:8080`, `http://localhost:5173`
- Métodos HTTP permitidos: GET, HEAD, PUT, POST, DELETE
- Encabezados de respuesta necesarios

## Solución de problemas adicionales

1. **Tiempo de espera de Firestore**: Hemos aumentado los tiempos de espera y mejorado el manejo de errores en la conexión a Firestore.

2. **Manejo de errores de subida**: Hemos mejorado el código para manejar mejor los errores al subir imágenes.

3. **Si los problemas persisten**, puedes probar estas soluciones adicionales:

   - Asegúrate de que tu proyecto de Firebase tiene habilitado el plan Blaze (pago por uso), ya que el plan gratuito Spark tiene limitaciones con CORS.
   - Verifica que las reglas de seguridad de Storage permiten las operaciones que estás intentando realizar.
   - Prueba usar un navegador diferente o borrar la caché del navegador.