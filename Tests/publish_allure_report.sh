#!/bin/bash

# Простой скрипт для принудительного обновления
rm -rf docs
allure generate allure-results --clean -o docs
git add -A
git commit -m "update reports $(date)"
git push

# -------------------------------
# Генерация публичной ссылки
# -------------------------------
REPO_URL=$(git config --get remote.origin.url)

if [[ "$REPO_URL" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
    USER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]%.git}"
    
    GH_PAGES_URL="https://${USER}.github.io/${REPO}/"
    
    echo "🎉 Отчет успешно опубликован!"
    echo "📎 Публичная ссылка на отчет: ${GH_PAGES_URL}index.html"
    echo "📎 Главная страница: $GH_PAGES_URL"
    
    # Копируем ссылку в буфер обмена (для macOS)
    if command -v pbcopy > /dev/null; then
        echo "${GH_PAGES_URL}index.html" | pbcopy
        echo "📋 Ссылка скопирована в буфер обмена!"
    fi
else
    echo "⚠️ Не удалось определить ссылку GitHub Pages"
    echo "Репозиторий: $REPO_URL"
    echo "💡 Включите GitHub Pages в настройках репозитория:"
    echo "   Settings → Pages → Source: Deploy from branch → Branch: main, Folder: /docs"
fi