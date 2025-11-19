#!/bin/bash

# -------------------------------
# 1) Настройки
# -------------------------------
RESULTS_DIR="allure-results"
DOCS_DIR="docs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$DOCS_DIR/report_$TIMESTAMP"

# Фиксированный URL GitHub Pages
GH_PAGES_BASE="https://antongetfive.github.io/maestro-tests-buy-flow/"
GH_REPORT_URL="${GH_PAGES_BASE}report_$TIMESTAMP/"

# -------------------------------
# 2) Проверяем наличие allure-results
# -------------------------------
if [ ! -d "$RESULTS_DIR" ]; then
  echo "❌ Папка $RESULTS_DIR не найдена!"
  exit 1
fi

# -------------------------------
# 3) Создаём папку для отчёта
# -------------------------------
mkdir -p "$REPORT_DIR"
echo "📁 Создана папка отчёта: $REPORT_DIR"

# -------------------------------
# 4) Генерация Allure отчёта
# -------------------------------
echo "📊 Генерирую Allure Report..."
allure generate "$RESULTS_DIR" --clean -o "$REPORT_DIR"

if [ $? -ne 0 ]; then
  echo "❌ Ошибка генерации отчёта!"
  exit 1
fi

# -------------------------------
# 5) Обновление index.html
# -------------------------------
INDEX_FILE="$DOCS_DIR/index.html"

# Создаём index.html если нет
if [ ! -f "$INDEX_FILE" ]; then
cat > "$INDEX_FILE" <<EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Allure Reports History</title>
</head>
<body>
  <h1>История Allure отчётов</h1>
  <ul id="reports-list">
  </ul>
</body>
</html>
EOF
fi

# Добавляем новую ссылку
# Используем временный файл
TMP_FILE=$(mktemp)
awk -v report="$TIMESTAMP" '
/<ul id="reports-list">/ {
  print;
  print "    <li><a href=\"report_" report "/\">report_" report "</a></li>";
  next
}
{ print }
' "$INDEX_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$INDEX_FILE"
echo "📄 Обновлён index.html с новой ссылкой"

# -------------------------------
# 6) Коммитим и пушим изменения
# -------------------------------
git add -A

if git diff --cached --quiet; then
  echo "ℹ️ Нет изменений для коммита."
else
  git commit -m "Add report $TIMESTAMP"
  git push origin HEAD
fi

# -------------------------------
# 7) Выводим ссылки
# -------------------------------
echo ""
echo "🎉 Отчёт успешно опубликован!"
echo "----------------------------------------"
echo "📄 Уникальная ссылка на отчёт:"
echo "$GH_REPORT_URL"
echo ""
echo "📚 Список всех отчётов:"
echo "${GH_PAGES_BASE}index.html"
echo "----------------------------------------"
