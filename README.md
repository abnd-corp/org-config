# org-config

Les règles de l'organisation Abnd sous forme de fichiers (charte R7). On les change par PR, et le script les applique à tous les dépôts : plus de réglages cliqués dépôt par dépôt.

## Contenu

- `rulesets/` : `dev` (PR depuis `feature/**`, squash), `promotion` (`staging` et `main`, merge commit, commits signés R10), `noms` (seulement `feature/**` et `dependabot/**`).
- `depots.json` : les dépôts suivis, avec leurs contrôles de CI propres, l'option `noms` et l'option `closes` (le contrôle « Issue liée » de R3 (« Closes #N » dans la description) devient obligatoire sur `dev` ; à mettre quand le dépôt appelle la version du 25 octobre 2026 ou plus récente du contrôle de PR).
- `scripts/appliquer.sh` : crée ou met à jour les rulesets (`--tous`, ou un dépôt ; `--simuler` pour voir sans rien changer).

## Utilisation

```
scripts/appliquer.sh --tous --simuler   # ce qui serait changé
scripts/appliquer.sh abnd               # un dépôt
```

Un nouveau dépôt : l'ajouter à `depots.json` par PR, créer ses branches `dev` et `staging` (`appliquer-flux.sh` du dépôt gouvernance), puis lancer le script.

## Limites

Le plan GitHub gratuit n'a pas de rulesets d'organisation ni de rulesets sur les dépôts privés : les dépôts privés (`bot`, `inventaire`, `Documentation`) ne sont pas couverts.
