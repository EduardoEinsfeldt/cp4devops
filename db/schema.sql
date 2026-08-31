-- DDL DimDim - Checkpoint Containers em Nuvem
-- Banco: MySQL 8
-- Tabela minima exigida + PK

CREATE DATABASE IF NOT EXISTS dimdim
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE dimdim;

CREATE TABLE IF NOT EXISTS cliente (
    id     BIGINT          NOT NULL AUTO_INCREMENT,
    nome   VARCHAR(120)    NOT NULL,
    email  VARCHAR(120)    NOT NULL,
    saldo  DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id),
    UNIQUE KEY uk_cliente_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
