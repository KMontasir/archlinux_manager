#!/bin/bash

# Obtenir le chemin absolu du répertoire où se trouve ce script
SCRIPT_DIR="$(dirname "$0")"

# Fonction pour sourcer tous les fichiers d'un répertoire
sourcer_fonctions() {
    local dir="$1"
    
    for file in "$dir"/*; do 
        # S'assure que seul les fichiers sont pris en compte (pas les sous-répertoires)
        if [ -f "$file" ]; then
            source "$file"
        fi
    done
}

# Boucle d'importation des fonctions depuis différents répertoires
sourcer_fonctions "$SCRIPT_DIR/functions_sys"
sourcer_fonctions "$SCRIPT_DIR/config"
sourcer_fonctions "$SCRIPT_DIR/functions_prog"
sourcer_fonctions "$SCRIPT_DIR/functions_prog/functions_general"

menu_principal
