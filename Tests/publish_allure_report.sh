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
# 4) Добавляем файлы для обхода кеша
# -------------------------------
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Создаем файл с уникальным именем для обхода кеша
cat > "$DOCS_DIR/cache-buster-$TIMESTAMP.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0; url=index.html">
</head>
<body>
    Redirecting to latest report...
</body>
</html>
EOF

# Обновляем index.html для сброса кеша
sed -i '.bak' "s|</head>|<meta http-equiv=\"cache-control\" content=\"no-cache, no-store, must-revalidate\"><meta http-equiv=\"Pragma\" content=\"no-cache\"><meta http-equiv=\"Expires\" content=\"0\"></head>|g" "$DOCS_DIR/index.html"

# Создаем файл с информацией о сборке
cat > "$DOCS_DIR/build-info.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "build_id": "$TIMESTAMP",
  "source": "allure-results"
}
EOF

# -------------------------------
# 5) Git commit + push с принудительным обновлением
# -------------------------------
echo "📤 Делаю commit + push..."

# Добавляем ВСЕ файлы принудительно
git add -A --force

# Создаем коммит с уникальным сообщением
COMMIT_MSG="update report $(date +"%Y-%m-%d %H:%M:%S") - build $TIMESTAMP"

if git diff --cached --quiet; then
  echo "ℹ️ Нечего коммитить — принудительно создаю коммит..."
  # Принудительно создаем коммит даже если нет изменений
  git commit --allow-empty -m "$COMMIT_MSG"
else
  git commit -m "$COMMIT_MSG"
fi

# Принудительный push
echo "🚀 Принудительная отправка на GitHub..."
git push origin HEAD

# -------------------------------
# 6) Генерация ссылки GitHub Pages с параметром кеша
# -------------------------------
USER=$(echo "$REPO_URL" | sed -E 's#.*github.com[:/](.*)/(.*)\.git#\1#')
REPO=$(echo "$REPO_URL" | sed -E 's#.*github.com[:/](.*)/(.*)\.git#\2#')

GH_PAGES_URL="https://${USER}.github.io/${REPO}/"
GH_PAGES_NOCACHE="https://${USER}.github.io/${REPO}/?v=$TIMESTAMP"

# -------------------------------
# 7) Готово
# -------------------------------
echo ""
echo "🎉 Отчёт успешно опубликован!"
echo "🔗 GitHub Pages:"
echo "$GH_PAGES_URL"
echo ""
echo "🆕 Ссылка с обходом кеша:"
echo "$GH_PAGES_NOCACHE"
echo ""
echo "⏰ Время генерации: $(date +"%Y-%m-%d %H:%M:%S")"
echo "🏷️  ID сборки: $TIMESTAMP"
echo ""
echo "💡 Если видите старый отчёт:"
echo "   - Нажмите Ctrl+F5 для полного обновления"
echo "   - Или используйте ссылку с обходом кеша"
echo "   - Или подождите 2-5 минут"

# Очистка временных файлов
rm -f "$DOCS_DIR/index.html.bak"