#!/bin/bash

# --- Fonctions Générales ---------------------------------------------------------

# Fonction "Voulez-vous Continuer (Y/n)"
continu_or_stop() {
	echo -n "Voulez-vous continuer ? (Y/n)"
	read confirmation
	
	if [["$confirmation" == "n"]]; then
		banner_goodbye
	fi
}

# Vérification de la présence d'un élément dans une input avec le choix de stopper le programme
verif_input_empty() {
    # Paramètres :
    C_INPUT="$1"

    if [ -z "$C_INPUT" ]; then
        echo ""
		echo -e "${YELLOW}Attention : Aucun élément fourni.${RESET}"
		continu_or_stop
    fi
}
