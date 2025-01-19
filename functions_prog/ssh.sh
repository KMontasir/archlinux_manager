#!/bin/bash

# --- Configuration initiale du SSH ---

# Fonction pour configurer le fichier sshd_config
configure_sshd() {
  local port=$1
  local sshd_config="/etc/ssh/sshd_config"

  echo "Configuration du fichier sshd_config..."

  # Modifier le port
  sed -i "s/^#Port.*/Port $port/" $sshd_config

  # Désactiver la connexion root
  sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" $sshd_config

  # Activer l'authentification (mot de passe + clé publique)
  sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication yes/" $sshd_config
  sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/" $sshd_config
  sed -i "s/^#UsePAM.*/UsePAM yes/" $sshd_config
  echo "auth       required     pam_unix.so" >> /etc/pam.d/sshd
  
  echo "Configuration de SSH appliquée."
}

# --- Fonction principal ---
config_ssh() {
	# Demander le port SSH
	read -p "Entrez le port SSH à utiliser (ex: 2222)" SSH_PORT

	# Configurer SSH avec les options fournies
	configure_sshd "$SSH_PORT"

	# Redémarrer SSH pour appliquer les changements
	systemctl restart sshd

	echo "Configuration SSH sécurisée terminée."
	echo "Port SSH : $SSH_PORT"
	echo "Connexion root : Désactivée"
	echo "Authentification : Password + Clé publique"
}
