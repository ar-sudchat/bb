# SMC Trading Academy & Hub — static site served by nginx
FROM nginx:1.27-alpine

# Custom server config (utf-8 for Thai, no-store on html/js, long cache on media)
COPY nginx.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html
RUN rm -f ./*

# App entry + libs
COPY index.html marked.min.js vip_knowledge_db.js ./

# Root images referenced by CSS url()
COPY academy_hero.png ninja_concept.png reaper_concept.png ./

# Image folders referenced by index.html
COPY BB/ ./BB/
COPY NinjaThai/ ./NinjaThai/

# Only the one PDF that is actually embedded
COPY pdf/SMC_Ninja_Blueprint.pdf ./pdf/

EXPOSE 80
