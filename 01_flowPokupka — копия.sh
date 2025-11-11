
ALLURE_RESULTS_DIR="allure-results"
ARCHIVE_DIR="allure-results-archive"

########################################
### ✅ Архивация старых результатов
########################################

if [ -d "$ALLURE_RESULTS_DIR" ] && [ "$(ls -A $ALLURE_RESULTS_DIR)" ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    mv "$ALLURE_RESULTS_DIR" "$ARCHIVE_DIR/allure-results_$TIMESTAMP"
    echo "✅ Старые результаты перемещены в архив: $ARCHIVE_DIR/allure-results_$TIMESTAMP"
fi

# Создаём чистую папку для нового отчёта
mkdir -p "$ALLURE_RESULTS_DIR"

########################################
### ✅ Allure metadata
########################################

# Название проекта
echo "allure.project.name=Payment Flow Tests" > "$ALLURE_RESULTS_DIR/allure.properties"

# ✅ ✅ Окружение (исключит сообщение: There are no environment variables)
cat > "$ALLURE_RESULTS_DIR/environment.properties" <<EOF
DEVICE=Android Physical Device
PLATFORM=Android(Production)
APP_VERSION=1.0.0
TEST_RUNNER=Maestro
EOF

# ✅ ✅ Информация об исполнителе (исключит: There is no information about tests executors)
cat > "$ALLURE_RESULTS_DIR/executor.json" <<EOF
{
  "name": "Sergeev Anton",
  "type": "QA",
  "url": "http://localhost",
  "buildName": "QA",
  "buildOrder": 1,
  "reportName": "Payment Flow Tests Report"
}
EOF

########################################
### ✅ Функция для запуска отдельного YAML
########################################

run_test() {
    FILE="$1"
    NAME=$(basename "$FILE" .yaml)

    echo "------------------------------"
    echo "▶️  Запуск теста: $NAME"
    echo "------------------------------"

    maestro test "$FILE" \
        --format=JUNIT \
        --output="$ALLURE_RESULTS_DIR/$NAME.xml" \
        --test-output-dir="$ALLURE_RESULTS_DIR"
}

########################################
### ✅ Запуск всех тестов по очереди
########################################

run_test "01_yandexPay.yaml"

########################################
### ✅ Старт Allure отчёта
########################################

echo "✅ Открываем Allure отчёт..."
allure serve "$ALLURE_RESULTS_DIR"
