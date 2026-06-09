#!/usr/bin/env bash
# Autor       : erick
# Fecha        : 2026-06-08
# Descripcion  : Prepara los archivos binarios de muestra de la Presentacion 3
#                 en /tmp/bdd/proyecto-final/imagenes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../../../carga-inicial"
TARGET_ROOT="/tmp/bdd/proyecto-final/imagenes"

copy_image_set() {
    local name="$1"
    local source_dir="${DATA_DIR}/${name}"
    local source_zip="${DATA_DIR}/${name}.zip"
    local target_dir="${TARGET_ROOT}/${name}"

    if [[ -d "${target_dir}" ]] && [[ -n "$(find "${target_dir}" -maxdepth 1 -type f 2>/dev/null)" ]]; then
        echo "=> Las imagenes ${name} ya fueron copiadas"
        return
    fi

    mkdir -p "${TARGET_ROOT}"

    if [[ -f "${source_zip}" ]]; then
        echo "Copiando imagenes ${name} desde ${source_zip}"
        unzip -oq "${source_zip}" -d "${TARGET_ROOT}"
    elif [[ -d "${source_dir}" ]]; then
        echo "Copiando imagenes ${name} desde ${source_dir}"
        mkdir -p "${target_dir}"
        cp -a "${source_dir}/." "${target_dir}/"
    else
        echo "No existe ni ${source_zip} ni ${source_dir}" >&2
        exit 1
    fi
}

copy_image_set laptops
copy_image_set facturas