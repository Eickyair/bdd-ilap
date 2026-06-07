#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# validate-parte-2.sh
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Ejecuta todas las validaciones de consistencia de la BDD
#                  distribuida iLap y genera un reporte en pantalla y en
#                  entregables/parte-2/validation-report.txt.
#
#   Validaciones cubiertas:
#     ✔ Conectividad Docker entre contenedores (ping)
#     ✔ Accesibilidad de las 4 PDBs via SQL*Plus
#     ✔ Usuario ilap_bdd existe en los 4 nodos
#     ✔ 12 database links creados (3 por nodo)
#     ✔ Número correcto de tablas en cada nodo
#     ✔ Conectividad cross-node vía DB links (SELECT 1 FROM DUAL@link)
#
# Uso: bash v-01-run-validations.sh
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
C2="c2-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${SCRIPT_DIR}/validation-report.txt"
PASS=0; FAIL=0

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

exec > >(tee "${REPORT}") 2>&1

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  BDD Distribuida iLap — Reporte de Validación                ║"
echo "║  $(_ts)                                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

check() {
    local desc="$1" result="$2" expected="$3"
    if [ "${result}" = "${expected}" ]; then
        echo "  [PASS] ${desc}"
        PASS=$((PASS+1))
    else
        echo "  [FAIL] ${desc}  →  obtenido='${result}'  esperado='${expected}'"
        FAIL=$((FAIL+1))
    fi
}

# ================================================================
# 1. CONECTIVIDAD DOCKER
# ================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 1. Conectividad de red Docker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for cname in "${C1}" "${C2}"; do
    running=$(docker inspect "${cname}" --format '{{.State.Running}}' 2>/dev/null || echo "false")
    check "Contenedor ${cname} corriendo" "${running}" "true"
done

ping1=$(docker exec "${C1}" ping -c 1 -W 2 h2-bdd-proy-eam.fi.unam &>/dev/null && echo "ok" || echo "fail")
check "Ping ${C1} → h2-bdd-proy-eam.fi.unam" "${ping1}" "ok"

ping2=$(docker exec "${C2}" ping -c 1 -W 2 h1-bdd-proy-eam.fi.unam &>/dev/null && echo "ok" || echo "fail")
check "Ping ${C2} → h1-bdd-proy-eam.fi.unam" "${ping2}" "ok"

# ================================================================
# 2. ACCESIBILIDAD DE LOS 4 NODOS VÍA SQL*PLUS
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 2. Accesibilidad de los 4 nodos (ilap_bdd)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for pdb in eambdd_s1 eambdd_s2 eambdd_s3 eambdd_s4; do
    result=$(docker exec "${C1}" su - oracle -c \
        "sqlplus -s ilap_bdd/ilap_bdd@${pdb} <<'EOF'
set heading off feedback off pagesize 0
select 'UP' from dual;
exit;
EOF" 2>/dev/null | tr -d ' \n')
    check "Conexión ilap_bdd@${pdb}" "${result}" "UP"
done

# ================================================================
# 3. DATABASE LINKS POR NODO
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 3. Database links creados (esperado: 3 por nodo)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for pdb in eambdd_s1 eambdd_s2 eambdd_s3 eambdd_s4; do
    cnt=$(docker exec "${C1}" su - oracle -c \
        "sqlplus -s ilap_bdd/ilap_bdd@${pdb} <<'EOF'
set heading off feedback off pagesize 0
select count(*) from user_db_links;
exit;
EOF" 2>/dev/null | tr -d ' \n')
    check "DB links en ${pdb}" "${cnt}" "3"
done

# ================================================================
# 4. TABLAS POR NODO
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 4. Tablas por nodo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

declare -A EXPECTED_TABLES=([eambdd_s1]=12 [eambdd_s2]=11 [eambdd_s3]=11 [eambdd_s4]=11)

for pdb in eambdd_s1 eambdd_s2 eambdd_s3 eambdd_s4; do
    cnt=$(docker exec "${C1}" su - oracle -c \
        "sqlplus -s ilap_bdd/ilap_bdd@${pdb} <<'EOF'
set heading off feedback off pagesize 0
select count(*) from user_tables;
exit;
EOF" 2>/dev/null | tr -d ' \n')
    check "Tablas en ${pdb}" "${cnt}" "${EXPECTED_TABLES[${pdb}]}"
done

# ================================================================
# 5. CONECTIVIDAD CROSS-NODE VÍA DB LINKS
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 5. Conectividad cross-node vía DB links"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

declare -A LINKS
LINKS[eambdd_s1]="eambdd_s2.fi.unam eambdd_s3.fi.unam eambdd_s4.fi.unam"
LINKS[eambdd_s2]="eambdd_s1.fi.unam eambdd_s3.fi.unam eambdd_s4.fi.unam"
LINKS[eambdd_s3]="eambdd_s1.fi.unam eambdd_s2.fi.unam eambdd_s4.fi.unam"
LINKS[eambdd_s4]="eambdd_s1.fi.unam eambdd_s2.fi.unam eambdd_s3.fi.unam"

for src_pdb in eambdd_s1 eambdd_s2 eambdd_s3 eambdd_s4; do
    for link in ${LINKS[${src_pdb}]}; do
        result=$(docker exec "${C1}" su - oracle -c \
            "sqlplus -s ilap_bdd/ilap_bdd@${src_pdb} <<EOF
set heading off feedback off pagesize 0
select 'OK' from dual@${link};
exit;
EOF" 2>/dev/null | tr -d ' \n')
        check "DB link ${src_pdb} → @${link}" "${result}" "OK"
    done
done

# ================================================================
# 6. TABLAS CLAVE PRESENTES POR NODO
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 6. Tablas de fragmento clave"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

_table_exists() {
    local pdb="$1" tname="$2"
    local cnt
    cnt=$(docker exec "${C1}" su - oracle -c \
        "sqlplus -s ilap_bdd/ilap_bdd@${pdb} <<EOF
set heading off feedback off pagesize 0
select count(*) from user_tables where table_name=upper('${tname}');
exit;
EOF" 2>/dev/null | tr -d ' \n')
    echo "${cnt}"
}

declare -A KEY_TABLES
KEY_TABLES[eambdd_s1]="sucursal_f1_eam_s1 laptop_f1_eam_s1 laptop_inventario_f2_eam_s1 historico_status_laptop_f2_eam_s1 servicio_laptop_f1_eam_s1"
KEY_TABLES[eambdd_s2]="sucursal_f2_eam_s2 laptop_f2_eam_s2 historico_status_laptop_f1_eam_s2 servicio_laptop_f2_eam_s2"
KEY_TABLES[eambdd_s3]="sucursal_f3_eam_s3 laptop_f3_eam_s3 laptop_inventario_f1_eam_s3 servicio_laptop_f3_eam_s3"
KEY_TABLES[eambdd_s4]="sucursal_f4_eam_s4 laptop_f4_eam_s4 laptop_f5_eam_s4 servicio_laptop_f4_eam_s4"

for pdb in eambdd_s1 eambdd_s2 eambdd_s3 eambdd_s4; do
    for tbl in ${KEY_TABLES[${pdb}]}; do
        cnt=$(_table_exists "${pdb}" "${tbl}")
        check "Tabla ${tbl} en ${pdb}" "${cnt}" "1"
    done
done

# ================================================================
# RESUMEN FINAL
# ================================================================
TOTAL=$((PASS+FAIL))
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
printf "║  Resultado: %3d/%3d checks pasaron                           ║\n" "${PASS}" "${TOTAL}"
if [ ${FAIL} -eq 0 ]; then
    echo "║  Estado: ✔ TODAS LAS VALIDACIONES PASARON                    ║"
else
    printf "║  Estado: ✘ %2d FALLO(S) detectado(s)                         ║\n" "${FAIL}"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Reporte guardado en: ${REPORT}"

[ ${FAIL} -eq 0 ] && exit 0 || exit 1
