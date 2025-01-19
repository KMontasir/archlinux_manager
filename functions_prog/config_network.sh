#!/bin/bash

# Fonction pour choisir une interface réseau
choose_interface() {
  echo "Interfaces réseau disponibles :"
  
  # Utiliser ip link show pour afficher toutes les interfaces, qu'elles soient UP ou DOWN
  ip link show | awk -F': ' '/^[0-9]+:/ {print $2}' | tr -d ' ' | nl

  # Demander à l'utilisateur de choisir une interface
  read -p "Veuillez choisir l'interface (numéro) : " INTERFACE_NUM
  INTERFACE=$(ip link show | awk -F': ' '/^[0-9]+:/ {print $2}' | tr -d ' ' | sed -n "${INTERFACE_NUM}p")

  # Vérifier si l'interface est valide
  if [ -z "$INTERFACE" ]; then
    echo "Erreur : Interface non valide ou introuvable."
    exit 1
  fi

  echo "Interface sélectionnée : $INTERFACE"
}

# Fonction pour configurer une interface en DHCP
configure_dhcp() {
  local config_file="/etc/systemd/network/$INTERFACE.network"

  echo "Configuration de $INTERFACE en DHCP..."
  cat <<EOF > "$config_file"
[Match]
Name=$INTERFACE

[Network]
DHCP=yes
EOF

  echo "Configuration DHCP appliquée à $INTERFACE."
}

# Fonction pour configurer une interface en IP statique
configure_static() {
  local config_file="/etc/systemd/network/$INTERFACE.network"

  read -p "Adresse IP (ex: 192.168.1.100/24) : " IP_ADDRESS
  read -p "Passerelle (laissez vide si inutile) : " GATEWAY
  read -p "DNS (laissez vide si inutile) : " DNS

  echo "Configuration de $INTERFACE avec une IP statique..."
  cat <<EOF > "$config_file"
[Match]
Name=$INTERFACE

[Network]
Address=$IP_ADDRESS
EOF

  if [ -n "$GATEWAY" ]; then
    echo "Gateway=$GATEWAY" >> "$config_file"
  fi

  if [ -n "$DNS" ]; then
    echo "DNS=$DNS" >> "$config_file"
  fi

  echo "Configuration IP statique appliquée à $INTERFACE."
}

# Fonction pour configurer le Wi-Fi (DHCP ou IP statique)
configure_wifi() {
  read "SSID du réseau Wi-Fi : " WIFI_SSID
  read "Mot de passe du réseau Wi-Fi : " WIFI_PASSWORD

  # Créer la configuration wpa_supplicant
  echo "Création de la configuration Wi-Fi pour $WIFI_SSID..."
  wpa_passphrase "$WIFI_SSID" "$WIFI_PASSWORD" > /etc/wpa_supplicant/wpa_supplicant-$INTERFACE.conf

  # Activer wpa_supplicant pour cette interface
  systemctl enable wpa_supplicant@$INTERFACE
  systemctl start wpa_supplicant@$INTERFACE

  # Demander DHCP ou statique pour le Wi-Fi
  echo "Voulez-vous utiliser DHCP pour le Wi-Fi ? (o/n)"
  read -n 1 USE_DHCP_WIFI
  echo

  if [[ "$USE_DHCP_WIFI" =~ ^[Oo]$ ]]; then
    configure_dhcp
  else
    configure_static
  fi
}

# Fonction principale pour configurer le réseau
config_network() {
  # Demander à l'utilisateur de choisir une interface
  choose_interface
  
  # Demander à l'utilisateur s'il veut utiliser le Wi-Fi
  echo "Voulez-vous utiliser Wi-Fi pour $INTERFACE ? (o/n)"
  read -n 1 USE_WIFI
  
  if [[ "$USE_WIFI" =~ ^[Oo]$ ]]; then
    configure_wifi
  else
	# Demander à l'utilisateur s'il veut utiliser le DHCP ou une IP statique
	echo "Voulez-vous utiliser DHCP pour $INTERFACE ? (o/n)"
	read -n 1 USE_DHCP
	
	if [[ "$USE_DHCP" =~ ^[Oo]$ ]]; then
	  configure_dhcp
	else
	  configure_static
	  fi
  fi

  # Redémarrer systemd-networkd et systemd-resolved pour appliquer la configuration
  systemctl restart systemd-networkd
  systemctl restart systemd-resolved
  echo "Configuration réseau terminée pour $INTERFACE."
}
