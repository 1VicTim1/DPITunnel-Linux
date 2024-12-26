# Функция для вывода сообщений об успехе/ошибке
log() {
  local color=$1
  local message=$2
  echo -e "\033[${color}m$message\033[0m"
}

# Проверка наличия таблицы mangle
nft list tables | grep -q '^ip\s\mangle$'
if [[ $? -ne 0 ]]; then
  log 33 "Таблица mangle отсутствует, создаем..."
  if ! nft add table ip mangle; then
    log 31 "Ошибка при создании таблицы mangle."
    exit 1
  fi
else
  log 32 "Таблица mangle уже существует, продолжаем..."
fi

# Проверка наличия цепочки mangle output
nft list chains | grep -q '^ip\s\mangle\s\output$'
if [[ $? -ne 0 ]]; then
  log 33 "Цепочка mangle output отсутствует, создаем..."
  if ! nft 'add chain ip mangle output { type filter hook output priority 0; }'; then
    log 31 "Ошибка при создании цепочки mangle output."
    exit 1
  fi
else
  log 33 "Цепочка mangle output уже существует, продолжаем..."
fi

# Добавление правила
log 35 "Добавляем правило..."
if ! nft 'add rule ip mangle output oifname "enp5s0" udp dport 443 mark and 0x40000000 != 0x40000000 counter queue num 220 bypass'; then
  log 33 "Ошибка при добавлении правила."
  exit 1
else
  log 32 "Правило успешно добавлено."
fi

# Запуск nfqws
log 35 "Запуск nfqws..."
attempts=0
while true; do
  if /opt/zapret/nfq/nfqws --uid 2 --qnum=220 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d2 --dpi-desync-repeats=10 --dpi-desync-ttl=5 --daemon; then
    break
  else
    attempts=$((attempts + 1))
    if [[ $attempts -ge 3 ]]; then
      log 33 "Не удалось запустить nfqws после трех попыток."
      exit 1
    fi
    sleep 1
  fi
done

log 30 "Good"
exit 0
