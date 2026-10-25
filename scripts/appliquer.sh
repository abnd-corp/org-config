#!/usr/bin/env bash
# Applique les rulesets de ce dépôt (R7) à un dépôt, ou à tous ceux de depots.json.
# Chaque ruleset est créé s'il manque, mis à jour sinon : relancer le script remet tout d'aplomb.
# Usage : scripts/appliquer.sh <depot> | --tous      (--simuler : affiche sans rien changer)
# Seuls les dépôts publics reçoivent des rulesets (indisponibles en privé sur le plan gratuit).
set -euo pipefail

org=abnd-corp
racine="$(cd "$(dirname "$0")/.." && pwd)"
simuler=false; [ "${2:-}" = "--simuler" ] && simuler=true
cibles="${1:?usage: appliquer.sh <depot>|--tous [--simuler]}"
if [ "$cibles" = "--tous" ]; then cibles="$(jq -r 'keys[]' "$racine/depots.json")"; fi

source="Branche source autorisée / Branche source autorisée"
gouv=("Contrôle des PR / Titre en Conventional Commits" "Contrôle des PR / Aucune signature d'IA")

contextes() { printf '%s\n' "$@" | jq -R '{context: ., integration_id: 15368}' | jq -s .; }

poser() { # depot, fichier, contrôles (JSON), marqueur
  local depot="$1" fichier="$2" controles="$3" marque="$4" corps nom id
  corps="$(jq --argjson c "$controles" --arg m "$marque" '(.rules[] | select(.type=="required_status_checks") | .parameters.required_status_checks) |= (if . == $m then $c else . end)' "$racine/rulesets/$fichier.json")"
  nom="$(jq -r .name <<<"$corps")"
  id="$(gh api "repos/$org/$depot/rulesets" --jq ".[] | select(.name==\"$nom\") | .id")"
  if $simuler; then echo "$depot : « $nom » ($([ -n "$id" ] && echo mise à jour || echo création))"; return; fi
  if [ -n "$id" ]; then gh api -X PUT "repos/$org/$depot/rulesets/$id" --input - --jq '"~ \(.name)"' <<<"$corps"
  else gh api -X POST "repos/$org/$depot/rulesets" --input - --jq '"+ \(.name)"' <<<"$corps"; fi
}

for depot in $cibles; do
  jq -e --arg d "$depot" 'has($d)' "$racine/depots.json" >/dev/null || { echo "$depot : absent de depots.json"; continue; }
  [ "$(gh api "repos/$org/$depot" --jq .visibility)" = public ] || { echo "$depot : privé, rien à appliquer"; continue; }
  mapfile -t propres < <(jq -r --arg d "$depot" '.[$d].controles // [] | .[]' "$racine/depots.json")
  # R3 : « Issue liée » n'est obligatoire que pour les dépôts qui appellent déjà la version du contrôle qui le porte
  # (option "closes" de depots.json) : exiger un contrôle absent bloquerait toutes leurs PR.
  gouv_dev=("${gouv[@]}")
  if [ "$(jq -r --arg d "$depot" '.[$d].closes // false' "$racine/depots.json")" = true ]; then gouv_dev+=("Contrôle des PR / Issue liée"); fi
  poser "$depot" dev "$(contextes "$source" "${gouv_dev[@]}" "${propres[@]}")" '__CONTROLES_DEV__'
  poser "$depot" promotion "$(contextes "$source" "${propres[@]}")" '__CONTROLES_PROMOTION__'
  if [ "$(jq -r --arg d "$depot" '.[$d].noms // false' "$racine/depots.json")" = true ]; then
    poser "$depot" noms '[]' '__AUCUN__'
  fi
done
