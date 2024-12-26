#!/bin/bash

# Функция для вывода сообщений об успехе/ошибке
log() {
  local color=$1
  local message=$2
  echo -e "\033[${color}m$message\033[0m"
}

# Удаление правила
log 41 "Удаляем правило..."
if ! nft delete rule ip mangle output handle 0; then
  log 42 "Ошибка при удалении правила."
  exit 1
else
  log 43 "Правило успешно удалено."
fi

# Остановка nfqws
log 44 "Остановка nfqws..."
killall -9 nfqws &>/dev/null || true

# Удаление цепочки mangle output
log 45 "Проверяем наличие цепочки mangle output..."
nft list chains | grep -q mangle
if [[ $? -eq 0 ]]; then
  log 46 "Цепочка mangle output присутствует, удаляем..."
  if ! nft delete chain ip mangle output; then
    log 47 "Ошибка при удалении цепочки mangle output."
    exit 1
  else
    log 48 "Цепочка mangle output успешно удалена."
  fi
else
  log 49 "Цепочка mangle output отсутствует, ничего не делаем."
fi

# Удаление таблицы mangle
log 50 "Проверяем наличие таблицы mangle..."
nft list tables | grep -q mangle
if [[ $? -eq 0 ]]; then
  log 51 "Таблица mangle присутствует, удаляем..."
  if ! nft delete table ip mangle; then
    log 52 "Ошибка при удалении таблицы mangle."
    exit 1
  else
    log 53 "Таблица mangle успешно удалена."
  fi
else
  log 54 "Таблица mangle отсутствует, ничего не делаем."
fi

log 55 "Откат выполнен успешно."
exit 0
