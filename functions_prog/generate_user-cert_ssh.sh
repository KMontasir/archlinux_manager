#!/bin/bash

# --- Générer une clé SSH pour un utilisateur spécifique ---

# Fonction pour générer une paire de clés SSH
generate_ssh_keys() {
  local user=$1
  local key_path=$2
  local key_comment=$3

  if [ ! -f "$key_path" ]; then
    echo "Génération d'une paire de clés SSH pour l'utilisateur $user..."
    sudo -u $user ssh-keygen -t rsa -b 4096 -f "$key_path" -C "$key_comment" -N ""
    echo "Clés SSH générées pour $user :"
    echo "- Clé privée : $key_path"
    echo "- Clé publique : $key_path.pub"
  else
    echo "Les clés SSH existent déjà pour l'utilisateur $user à l'emplacement $key_path."
  fi
}

# Fonction pour ajouter la clé publique dans authorized_keys
add_to_authorized_keys() {
  local user=$1
  local key_path=$2
  local home_dir=$(eval echo "~$user")
  local ssh_dir="$home_dir/.ssh"
  local authorized_keys="$ssh_dir/authorized_keys"

  # Créer le répertoire .ssh s'il n'existe pas
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  # Ajouter la clé publique dans authorized_keys
  cat "$key_path.pub" >> "$authorized_keys"
  chmod 600 "$authorized_keys"

  # Ajuster les permissions
  chown -R $user:$user "$ssh_dir"
  echo "La clé publique a été ajoutée à $authorized_keys pour l'utilisateur $user."
}

# --- Script principal ---
get_ssh_certificate() {
  # Demander l'utilisateur pour lequel générer la clé
  read -p "Entrez le nom d'utilisateur pour lequel générer une clé SSH : " USER
  
  # Vérifier si l'utilisateur existe
  if id "$USER" &>/dev/null; then
    USER_HOME=$(eval echo "~$USER")
    SSH_KEY_PATH="$USER_HOME/.ssh/id_rsa"
    
    # Générer les clés SSH pour l'utilisateur
    generate_ssh_keys "$USER" "$SSH_KEY_PATH" "$USER@$(hostname)"
    
    # Ajouter la clé publique dans authorized_keys
    add_to_authorized_keys "$USER" "$SSH_KEY_PATH"
  else
    echo "Erreur : L'utilisateur $USER ou son répertoire /home n'existe pas."
    exit 1
  fi
  
  echo "Configuration SSH pour l'utilisateur $USER terminée !"
  echo ""
  echo "[INFORMATIONS IMPORTANTES]
  
- Clé privée : $key_path
- Clé publique : $key_path.pub

- La clef publique (par exemple) peut être utilisée comme ci-dessous depuis PowerShell, avec un client sous Windows :
		ssh -i 'C:\Users\<VotreNomUtilisateur>\.ssh\id_rsa' <user>@<server_ip> -p <ssh_port>

"

	read -p "appuyer sur Entrer pour quitter"
}
