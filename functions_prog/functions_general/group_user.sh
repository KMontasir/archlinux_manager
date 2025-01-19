#!/bin/bash

# -- Fonctions de Groupes ---------------------------------------------------------

# Créer un groupe s'il n'existe pas
create_group() {
    # Paramètres :
    C_GROUP="$1"
	
	echo "=== Création du groupe : $C_GROUP ... ==="
		
	if groupadd "$C_GROUP"; then
		echo "Le groupe $C_GROUP a été créé avec succès."
	else
		echo "Erreur : Échec de la création du groupe $C_GROUP."
	fi
}

# Effectuer une action en fonction de l'existance ou non d'un groupe
if_group_no_exist() {
    # Paramètres :
    C_GROUP="$1"
	C_ACTION_NO_EXIST="$2"
	C_ACTION_EXIST="$3"

    if ! getent group "$C_GROUP" > /dev/null; then
        eval "$C_ACTION_NO_EXIST"
	else
		echo -e "${BLUE}[INFO]: Le groupe $C_GROUP existe${RESET}"
        eval "$C_ACTION_EXIST"
    fi
}


# --- Fonctions d'Utilisateurs ---------------------------------------------------------

# Créer un utilisateur s'il n'existe pas
create_user() {
	# Paramètres :
	C_USER="$1"
	C_PASSWORD="$2"
	C_HOME_DIR="$3"
	C_SHELL="$4"

	echo "=== Création de l'utilisateur : $C_USER ... ==="
	
    if useradd -d $C_HOME_DIR -s $C_SHELL $C_USER; then
		echo "$C_USER:$C_PASSWORD" | chpasswd
        echo "L'utilisateur $C_USER à été créé avec succès."
    else
        echo "Erreur : Échec de la création du groupe $C_GROUP."
    fi
}

# Ajouter un utilisateur dans un groupe
add_user_in_group() {
    # Paramètres :
	C_USER="$1"
	C_GROUP="$2"
	
	if_group_no_exist $C_GROUP \
	"echo '$C_GROUP n'existe pas.'; banner_goodbye" \
	"echo '$C_GROUP est bien présent.'"
	
	if_user_exist $C_USER \
	"usermod -G $C_GROUP $C_USER" \
	"echo '$C_USER n'existe pas.'; banner_goodbye"
	
	usermod -aG $C_GROUP $C_USER
}

# Effectuer une action en fonction de l'existance ou non d'un utilisateur
if_user_exist() {
    # Paramètres :
    C_USER="$1"
	C_ACTION_EXIST="$2"
	C_ACTION_NO_EXIST="$3"
	
    if id "$C_USER" &>/dev/null; then
        eval "$C_ACTION_EXIST"
    else
        eval "$C_ACTION_NO_EXIST"
    fi
}


# --- Exemples d'utilisations -------------------------------------------------------
#
# Exemple d'appel pour créer le groupe "GroupAdmin" s'il n'existe pas, sinon demander s'il faut continuer :
#if_group_no_exist "GroupAdmin" \
#              "create_group GroupAdmin \
#              "echo "Le groupe existe"; continu_or_stop"
#
# Exemple d'appel pour créer l'utilisateur "john" s'il n'existe pas, sinon demander s'il faut continuer  :
#if_user_exist "john" \
#              "echo 'L'utilisateur existe'; continu_or_stop \
#              "create_user john Azerty123 /home/john /bin/bash"
