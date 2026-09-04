#!/usr/bin/env bash
# Безопасное обновление агента-продюсера.
#
# Что делает: скачивает свежую версию служебной части агента (навыки, устав, инструкции)
# и обновляет ТОЛЬКО её.
#
# Чего не делает НИКОГДА: не трогает твои личные файлы -
#   USER.md, MEMORY.md, SOUL.md, memory/, knowledge/, content/
# Твоя распаковка, банк идей, контент-план и вся история остаются на месте.
#
# Запуск: bash obnovit-agenta.sh
# (на Windows - через Git Bash, он ставится вместе с git)
#
# Тело обёрнуто в функцию main специально: так bash читает файл целиком ДО выполнения,
# и скрипт может безопасно обновить сам себя в конце работы.

set -euo pipefail

main() {
  SKLAD="https://github.com/mcdenil-skills/content-agent.git"
  TMP=".obnovlenie-tmp"

  # Папки, которые обновляются целиком.
  SLUZHEBNYE_PAPKI=(".claude/skills" ".codex/skills" "instructions")

  # Служебные файлы, которые обновляются.
  # README.md сознательно НЕ обновляем: в репозитории лежит README про сам репозиторий,
  # а у тебя дома - README про твоего агента. Перезапись их перепутает.
  SLUZHEBNYE_FAYLY=("CLAUDE.md" "AGENTS.md" "obnovit-agenta.sh")

  # Личные файлы - список для проверки, что мы их не задели.
  LICHNYE=("USER.md" "MEMORY.md" "SOUL.md" "memory" "knowledge" "content")

  echo "🔄 Обновляю агента. Твои личные файлы не трогаю."
  echo

  # --- Проверка, что мы в доме агента ---
  if [ ! -f "CLAUDE.md" ]; then
    echo "❌ Не вижу файла CLAUDE.md - похоже, это не папка агента."
    echo "   Перейди в папку своего агента и запусти скрипт оттуда."
    exit 1
  fi

  # --- Слепок личных файлов ДО обновления (чтобы потом сверить) ---
  SLEPOK_DO="$(sled_lichnyh "${LICHNYE[@]}")"

  # --- Скачиваем свежую версию во временную папку ---
  if [ -e "$TMP" ]; then
    echo "❌ Папка $TMP уже существует. Удали её вручную и запусти снова."
    exit 1
  fi

  echo "📥 Скачиваю свежую версию со склада курса..."
  git clone --quiet --depth 1 "$SKLAD" "$TMP"

  # --- Обновляем только служебное ---
  echo "🔧 Обновляю служебную часть:"

  for papka in "${SLUZHEBNYE_PAPKI[@]}"; do
    if [ -d "$TMP/$papka" ]; then
      mkdir -p "$papka"
      cp -R "$TMP/$papka/." "$papka/"
      echo "   ✅ $papka"
    fi
  done

  for fayl in "${SLUZHEBNYE_FAYLY[@]}"; do
    if [ -f "$TMP/$fayl" ]; then
      cp "$TMP/$fayl" "$fayl"
      echo "   ✅ $fayl"
    fi
  done

  # --- Убираем за собой ---
  rm -rf "$TMP"

  # --- Сверяем, что личное не пострадало ---
  SLEPOK_POSLE="$(sled_lichnyh "${LICHNYE[@]}")"

  echo
  if [ "$SLEPOK_DO" = "$SLEPOK_POSLE" ]; then
    echo "🔒 Проверка пройдена: личные файлы не изменились."
    echo "   USER.md, MEMORY.md, SOUL.md, memory/, knowledge/, content/ - как были."
  else
    echo "⚠️  ВНИМАНИЕ: личные файлы изменились - такого быть не должно."
    echo "   Ничего не удаляй и покажи это сообщение куратору курса."
    exit 1
  fi

  echo
  echo "✅ Готово. Закрой этот чат и открой новый - агент подхватит обновления."
}

# Слепок содержимого личных файлов: список «контрольная сумма - файл».
sled_lichnyh() {
  for p in "$@"; do
    if [ -e "$p" ]; then
      find "$p" -type f -exec shasum {} \; 2>/dev/null | sort
    fi
  done
}

main "$@"
