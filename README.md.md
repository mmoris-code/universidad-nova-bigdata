# Solución Integral de Big Data y Gobierno de Datos - Universidad Nova

Este repositorio contiene la implementación técnica del proyecto de Gobierno de Datos y Analítica Avanzada para la Universidad Nova, desarrollado en el marco del curso de Big Data.

---

## 📌 Contenido del Repositorio

- **`scripts/01_etl_simulacion.R`**: Script en R para la simulación de fuentes transaccionales, limpieza, deduplicación y carga en el Data Warehouse (SQLite/Docker).
- **`scripts/02_spark_ml_desercion.R`**: Script de Machine Learning en Apache Spark (`SparklyR`) para la clasificación del riesgo de deserción estudiantil.
- **`scripts/03_shiny_dashboard.R`**: Aplicación interactiva en `Shiny` para la visualización de indicadores ejecutivos.
- **`assets/`**: Diagramas vectoriales de la arquitectura y modelo de datos (Ciclo de Vida y Modelo en Estrella).

---

## 🚀 Instrucciones de Ejecución

### 1. Clonar este repositorio
```bash
git clone https://github.com/TU_USUARIO/universidad-nova-bigdata.git
cd universidad-nova-bigdata
```

### 2. Ejecutar el pipeline de datos en R
Asegúrate de ejecutar los scripts en el siguiente orden dentro de R / RStudio:

1. **Construcción y carga del Data Warehouse local:**
   ```R
   source("scripts/01_etl_simulacion.R")
   ```
2. **Entrenamiento y evaluación del modelo de Machine Learning:**
   ```R
   source("scripts/02_spark_ml_desercion.R")
   ```
3. **Despliegue del Tablero de Control Ejecutivo:**
   ```R
   shiny::runApp("scripts/03_shiny_dashboard.R")
   ```

---

## 🛡️ Gobierno de Datos y Alineación con DAMA-DMBOK

La arquitectura implementada aborda las siguientes áreas del marco de referencia DAMA-DMBOK:
- **Calidad de Datos:** Reglas automáticas de limpieza sintáctica y normalización.
- **Seguridad:** Control de acceso por roles y anonimización de datos sensibles.
- **Trazabilidad (Data Lineage):** Metadatos de transformación desde las fuentes originales hasta el dashboard ejecutivo.
- **Mitigación de Riesgos:** Controles específicos para acceso no autorizado, duplicidad, pérdida e incoherencia de información.