# SMC Trading Academy & Hub — static site served by nginx
FROM nginx:1.27-alpine

# htpasswd tool for Basic Auth generation at startup
RUN apk add --no-cache apache2-utils

# Custom server config (utf-8 for Thai, no-store on html/js, long cache on media)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Basic Auth bootstrap — runs before nginx starts (official image runs /docker-entrypoint.d/*.sh)
COPY docker-entrypoint.d/40-basic-auth.sh /docker-entrypoint.d/40-basic-auth.sh
RUN chmod +x /docker-entrypoint.d/40-basic-auth.sh

WORKDIR /usr/share/nginx/html
RUN rm -f ./*

# App entry + login page + libs + favicon
COPY index.html login.html marked.min.js vip_knowledge_db.js favicon.svg ./

# Root images referenced by CSS url()
COPY academy_hero.png ninja_concept.png reaper_concept.png ./

# Image folders referenced by index.html
COPY BB/ ./BB/
COPY NinjaThai/ ./NinjaThai/

# All referenced PDFs (compressed). vip pdt/ has a space → JSON COPY form.
COPY pdf/ ./pdf/
COPY ["vip pdt/", "./vip pdt/"]

EXPOSE 80
