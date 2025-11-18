#!/bin/bash

ALLURE_RESULTS_DIR="allure-results"
ARCHIVE_DIR="allure-results-archive"

# Цвета
GREEN="\033[0;32m"
RED="\033[0;31m"
GRAY="\033[0;37m"
NC="\033[0m" # reset

########################################
### Архивация старых результатов
########################################
if [ -d "$ALLURE_RESULTS_DIR" ] && [ "$(ls -A $ALLURE_RESULTS_DIR)" ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    mkdir -p "$ARCHIVE_DIR"
    mv "$ALLURE_RESULTS_DIR" "$ARCHIVE_DIR/allure-results_$TIMESTAMP"
    echo "✅ Старые результаты перемещены в архив: $ARCHIVE_DIR/allure-results_$TIMESTAMP"
fi

mkdir -p "$ALLURE_RESULTS_DIR"

########################################
### Allure metadata
########################################
echo "allure.project.name=Payment Flow Tests" > "$ALLURE_RESULTS_DIR/allure.properties"

cat > "$ALLURE_RESULTS_DIR/environment.properties" <<EOF
DEVICE=Android Physical Device
PLATFORM=Android(Production)
APP_VERSION=1.0.0
TEST_RUNNER=Maestro
EOF

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
### Плавная анимация полосы
########################################
animate_loading() {
    local width=20
    local progress=0

    while kill -0 $1 2>/dev/null; do
        bar=""
        for ((i=0; i<$width; i++)); do
            if [ $i -lt $progress ]; then
                bar+="█"
            else
                bar+="░"
            fi
        done

        printf "\r⏳ ${bar}"

        progress=$(( (progress+1) % width ))
        sleep 0.1
    done

    printf "\r"
}

########################################
### Спиннер
########################################
spinner() {
    local pid=$1
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r🔄  Выполняется: ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r"
}

########################################
### Прогресс-бар итогов
########################################
print_progress() {
    printf "\nПрогресс: ["
    for ((i=0; i<TOTAL_TESTS; i++)); do
        if [ $i -lt ${#PROGRESS_BAR[@]} ]; then
            printf "%s" "${PROGRESS_BAR[i]}"
        else
            printf "${GRAY}░${NC}"
        fi
    done
    printf "] %d%%\n\n" $(( ${#PROGRESS_BAR[@]} * 100 / TOTAL_TESTS ))
}

########################################
### Запуск теста
########################################
run_test() {
    FILE="$1"
    NAME=$(basename "$FILE" .yaml)

    echo "------------------------------"
    echo "▶️  Запуск теста: $NAME"
    echo "------------------------------"

    # Запускаем maestro в фоне
    maestro test "$FILE" \
        --format=JUNIT \
        --output="$ALLURE_RESULTS_DIR/$NAME.xml" \
        --test-output-dir="$ALLURE_RESULTS_DIR" &

    TEST_PID=$!

    # Одновременно: спиннер + полоска
    animate_loading $TEST_PID &
    LOAD_PID=$!

    spinner $TEST_PID

    # Завершаем поток полосы
    kill $LOAD_PID 2>/dev/null

    wait $TEST_PID
    EXIT_CODE=$?

    echo ""

    if [ $EXIT_CODE -eq 0 ]; then
        SYMBOL="${GREEN}█${NC}"
        echo -e "✅ $NAME пройден"
    else
        SYMBOL="${RED}█${NC}"
        echo -e "❌ $NAME упал"
    fi

    PROGRESS_BAR+=("$SYMBOL")
    print_progress
}

########################################
### Список тестов
########################################
TEST_FILES=( "screenShot.yaml"
#    "01_yandexPay.yaml"
#    "02_stopApp_1.yaml"
)

TOTAL_TESTS=${#TEST_FILES[@]}
PROGRESS_BAR=()

for TEST in "${TEST_FILES[@]}"; do
    run_test "$TEST"
done

########################################
### Allure
########################################
echo "✅ Открываем Allure отчёт..."
allure serve "$ALLURE_RESULTS_DIR"
