#!/bin/bash

# -------------------------------
# 1) Настройки
# -------------------------------
DOCS_DIR="docs"
REPORT_DIR="allure-report"
RESULTS_DIR="allure-results"
REPO_URL=$(git config --get remote.origin.url)

if [ -z "$REPO_URL" ]; then
  echo "❌ Ошибка: git репозиторий не найден."
  exit 1
fi

# -------------------------------
# 2) Проверяем наличие отчета
# -------------------------------
if [ ! -d "$REPORT_DIR" ]; then
  echo "❌ Папка с отчётом $REPORT_DIR не найдена!"
  echo "🔄 Пытаюсь сгенерировать отчёт из $RESULTS_DIR..."
  
  if [ ! -d "$RESULTS_DIR" ]; then
    echo "❌ Папка $RESULTS_DIR также не найдена!"
    exit 1
  fi
  
  allure generate "$RESULTS_DIR" --clean -o "$REPORT_DIR"
  
  if [ $? -ne 0 ]; then
    echo "❌ Ошибка генерации отчёта!"
    exit 1
  fi
fi

# -------------------------------
# 3) Очистка docs/ и копирование нового отчета
# -------------------------------
echo "🧹 Очищаю $DOCS_DIR..."
rm -rf "$DOCS_DIR"
mkdir "$DOCS_DIR"

echo "📂 Копирую новый отчёт в $DOCS_DIR..."
cp -r "$REPORT_DIR"/* "$DOCS_DIR/"

# -------------------------------
# 4) Добавляем timestamp для отслеживания актуальности
# -------------------------------
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
cat > "$DOCS_DIR/build-info.txt" <<EOF
Build Timestamp: $TIMESTAMP
Report Generated: $(date)
Source: $RESULTS_DIR
EOF

# -------------------------------
# 5) Git commit + push
# -------------------------------
echo "📤 Делаю commit + push..."

git add -A

if git diff --cached --quiet; then
  echo "ℹ️ Нечего коммитить — отчёт не изменился."
else
  git commit -m "update reports $(date +"%Y-%m-%d %H:%M:%S")"
  git push origin HEAD
fi

# -------------------------------
# 6) Генерация ссылки GitHub Pages
# -------------------------------
USER=$(echo "$REPO_URL" | sed -E 's#.*github.com[:/](.*)/(.*)\.git#\1#')
REPO=$(echo "$REPO_URL" | sed -E 's#.*github.com[:/](.*)/(.*)\.git#\2#')

GH_PAGES_URL="https://${USER}.github.io/${REPO}/"

# -------------------------------
# 7) Готово
# -------------------------------
echo ""
echo "🎉 Отчёт успешно опубликован!"
echo "🔗 GitHub Pages:"
echo "$GH_PAGES_URL"
echo ""
echo "⏰ Время генерации: $TIMESTAMP"
echo ""
echo "Если Pages настроен на /docs — отчёт уже доступен."
echo "Обычно обновление занимает 1-2 минуты."

# Дополнительная проверка актуальности
if [ -f "$DOCS_DIR/build-info.txt" ]; then
    echo ""
    echo "📋 Информация о сборке:"
    cat "$DOCS_DIR/build-info.txt"
fi