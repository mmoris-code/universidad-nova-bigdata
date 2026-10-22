# ==============================================================================
# Módulo de Analítica Avanzada y Machine Learning (SparklyR) - Universidad Nova
# Autor: Equipo de Arquitectura de Datos / Data Science
# ==============================================================================

library(sparklyr)
library(dplyr)

# 1. Configuración de la conexión al clúster local de Spark
config <- spark_config()
sc <- spark_connect(master = "local", version = "3.3", config = config)

# 2. Copia de los datos simulados hacia la memoria distribuida de Spark
# (Se asume la existencia previa de la tabla 'Hechos_Rendimiento' o data frame procesado)
datos_analiticos <- fuente_transformada %>%
  mutate(
    # Creación de la variable objetivo binaria para clasificación de riesgo
    riesgo_desercion = if_else(promedio < 3.0 | asistencia_lms < 50.0, 1, 0)
  )

df_spark <- copy_to(sc, datos_analiticos, "spark_rendimiento_nova", overwrite = TRUE)

# 3. Particionamiento del dataset (70% Entrenamiento, 30% Prueba)
particiones <- df_spark %>%
  ft_string_indexer(input = "facultad", output = "facultad_idx") %>%
  sdf_partition(training = 0.7, test = 0.3, seed = 42)

training_data <- particiones$training
test_data <- particiones$test

# 4. Entrenamiento del Modelo de Machine Learning (Regresión Logística)
modelo_ml <- training_data %>%
  ml_logistic_regression(
    response = "riesgo_desercion",
    features = c("promedio", "asistencia_lms", "facultad_idx")
  )

cat("[MODELO ENTRENADO] Regresión Logística ejecutada exitosamente en SparklyR.\n")

# 5. Evaluación del Performance del Modelo sobre el Conjunto de Prueba
predicciones <- ml_predict(modelo_ml, test_data)

# Cálculo de métricas de rendimiento (Área Bajo la Curva ROC / AUC)
evaluador_auc <- ml_binary_classification_evaluator(
  predicciones,
  label_col = "riesgo_desercion",
  raw_prediction_col = "prediction",
  metric_name = "areaUnderROC"
)

metric_auc <- ml_evaluate(modelo_ml, test_data)$area_under_roc()
cat(sprintf("[EVALUACIÓN] Área bajo la curva ROC (AUC-ROC) alcanzada: %.4f\n", metric_auc))

# Cierre de la sesión de Spark
spark_disconnect(sc)
