# ==============================================================================
# Script ETL y Simulación de Datos - Universidad Nova (Optimizado y Robusto)
# Autor: Equipo de Arquitectura de Datos / Gobierno de Datos
# Descripción: Valida dependencias, simula fuentes, limpia y carga el DWH.
# ==============================================================================

# 1. Verificación e instalación automática de dependencias faltantes
paquetes_requeridos <- c("dplyr", "stringr", "DBI", "RSQLite")

for (pkg in paquetes_requeridos) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    message(sprintf("[INSTALACIÓN] El paquete '%s' no está presente. Instalando...", pkg))
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  } else {
    library(pkg, character.only = TRUE)
  }
}

# 2. Simulación de Fuentes Transaccionales Heterogéneas (Silos Previos)
set.seed(42)
n_registros <- 1500

fuente_academica_raw <- data.frame(
  raw_id = 1:n_registros,
  nombre_ingreso = sample(c("Juan Perez", "JUAN PEREZ", "Perez, Juan", "Maria Gomez", "MARIA GOMEZ "), n_registros, replace = TRUE),
  documento_ingreso = sample(c("CC102030", "10.2030", "CC-102030", "CC987654"), n_registros, replace = TRUE),
  facultad = sample(c("Ingeniería", "Administración", "Ciencias de la Salud", "Derecho"), n_registros, replace = TRUE),
  promedio = round(runif(n_registros, 2.0, 5.0), 2),
  asistencia_lms = round(runif(n_registros, 40, 100), 1)
)

cat(sprintf("[EXTRACCIÓN] Registros brutos extraídos de fuentes dispersas: %d\n", nrow(fuente_academica_raw)))

# 3. Fase de Transformación (Limpieza, Estandarización y Deduplicación)
fuente_transformada <- fuente_academica_raw %>%
  # Limpieza y normalización de cadenas de texto (Nombres)
  mutate(
    nombre_limpio = str_to_title(str_trim(str_replace_all(nombre_ingreso, "[,]", ""))),
    # Normalización estricta de documentos para eliminar variaciones sintácticas
    documento_estandar = str_replace_all(documento_ingreso, "[^0-9]", ""),
    # Generación de identificador único institucional (Hash sintético)
    id_estudiante = paste0("U_NOVA_", documento_estandar)
  ) %>%
  # Eliminación de registros duplicados basados en el identificador único
  distinct(id_estudiante, .keep_all = TRUE) %>%
  select(id_estudiante, nombre_limpio, documento_estandar, facultad, promedio, asistencia_lms)

cat(sprintf("[TRANSFORMACIÓN] Registros tras limpieza y deduplicación: %d\n", nrow(fuente_transformada)))

# 4. Fase de Carga (Load) hacia el Data Warehouse Analítico (SQLite)
conn <- dbConnect(RSQLite::SQLite(), "dwh_universidad_nova.db")

# Creación de la dimensión unificada y tabla de hechos
dbExecute(conn, "DROP TABLE IF EXISTS Hechos_Rendimiento;")
dbExecute(conn, "DROP TABLE IF EXISTS Dim_Estudiante;")

dbExecute(conn, "
CREATE TABLE Dim_Estudiante (
    id_estudiante TEXT PRIMARY KEY,
    nombre_completo TEXT,
    documento TEXT,
    facultad TEXT
);
")

dbExecute(conn, "
CREATE TABLE Hechos_Rendimiento (
    id_hecho INTEGER PRIMARY KEY AUTOINCREMENT,
    id_estudiante TEXT,
    promedio_ponderado REAL,
    asistencia_lms_pct REAL,
    FOREIGN KEY(id_estudiante) REFERENCES Dim_Estudiante(id_estudiante)
);
")

# Inserción de dimensiones
dim_data <- fuente_transformada %>% select(id_estudiante, nombre_completo = nombre_limpio, documento = documento_estandar, facultad)
dbWriteTable(conn, "Dim_Estudiante", dim_data, append = TRUE, row.names = FALSE)

# Inserción de hechos
hechos_data <- fuente_transformada %>% select(id_estudiante, promedio_ponderado = promedio, asistencia_lms_pct = asistencia_lms)
dbWriteTable(conn, "Hechos_Rendimiento", hechos_data, append = TRUE, row.names = FALSE)

cat("[CARGA] Datos estructurados cargados exitosamente en el Data Warehouse corporativo.\n")

# Cierre de conexión
dbDisconnect(conn)
