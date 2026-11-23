#!/usr/bin/env bash
#
# Конвертирует все *.json файлы в текущей папке (или указанной) в *.srs
# с помощью: sing-box rule-set compile <file>.json --output <file>.srs
# Симлинки пропускаются.

#set -x
#set -euo pipefail

# Папка для обработки: первый аргумент или текущая директория
DIR="${1:-.}"

# Проверка наличия sing-box
if ! command -v sing-box >/dev/null 2>&1; then
    echo "Ошибка: sing-box не найден в PATH" >&2
    exit 1
fi

# Проверка существования папки
if [[ ! -d "$DIR" ]]; then
    echo "Ошибка: директория '$DIR' не существует" >&2
    exit 1
fi

shopt -s nullglob   # пустой glob -> пустой массив

count=0
skipped_symlinks=0
failed=0

# Ищем *.json только в самой папке (не рекурсивно). Если нужна рекурсия — замените на find.
echo "$DIR/*.json"
for file in "$DIR"/*.json; do
    # Пропускаем симлинки
    if [[ -L "$file" ]]; then
        echo "[skip symlink] $file"
        ((skipped_symlinks++))
        continue
    fi

    # Пропускаем не-файлы (на всякий случай)
    if [[ ! -f "$file" ]]; then
        continue
    fi

    output="${file%.json}.srs"

    echo "[compile] $file -> $output"
    if sing-box rule-set compile "$file" --output "$output"; then
        ((count++))
    else
        echo "[error] не удалось скомпилировать: $file" >&2
        ((failed++))
    fi
done

echo
echo "Готово. Успешно: $count, пропущено симлинков: $skipped_symlinks, ошибок: $failed"

# Ненулевой код возврата, если были ошибки
[[ $failed -eq 0 ]]
