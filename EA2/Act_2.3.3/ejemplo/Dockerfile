# Dockerfile de ejemplo ilustrativo (NO es la imagen que debes entregar)
# Objetivo: mostrar la sintaxis y el orden típico de instrucciones.
# Empaqueta una página estática simple servida con nginx.

FROM nginx:alpine

# Metadata útil para identificar la imagen
LABEL maintainer="tu_nombre@duocuc.cl"
LABEL description="Ejemplo ilustrativo para Act_2.3.3 - no usar como entrega"

# Copia contenido estático al directorio que nginx sirve por defecto
COPY index.html /usr/share/nginx/html/index.html

# Puerto que expone el contenedor (documental; no publica el puerto por sí solo)
EXPOSE 80

# Comando por defecto al iniciar el contenedor (nginx ya lo trae, se deja explícito como ejemplo)
CMD ["nginx", "-g", "daemon off;"]
