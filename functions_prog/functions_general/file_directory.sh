#!/bin/bash

# --- Fonctions de Fichiers et Répertoires ---------------------------------------------------------

# Créer un répertoire s'il n'existe pas
create_directory() {
	# Paramètres :
	C_DIRECTORY="$1"
	
    # Vérification et création du répertoire FTP s'il n'existe pas
    if mkdir -p "$C_DIRECTORY"; then
        echo "=== Création du répertoire FTP : $C_DIRECTORY ... ==="
        mkdir -p "$C_DIRECTORY"
    else
        echo "Erreur : Échec de la création du répertoire $C_DIRECTORY."
    fi
}

# Fonction pour effectuer une action en fonction de l'existance ou non d'un répertoire
if_directory_no_exist() {
    # Paramètres :
	C_DIRECTORY="$1"
	C_ACTION_NO_EXIST="$2"
	C_ACTION_EXIST="$3"
	
    if [ ! -d "$C_DIRECTORY" ]; then
        eval "$C_ACTION_NO_EXIST"
    else
        eval "$C_ACTION_EXIST"
    fi
}
