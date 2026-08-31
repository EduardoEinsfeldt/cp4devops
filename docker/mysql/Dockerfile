FROM mysql:8.0

COPY db/schema.sql /docker-entrypoint-initdb.d/01-schema.sql

EXPOSE 3306
