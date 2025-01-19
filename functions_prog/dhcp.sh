#!/bin/bash

#!/bin/bash

# Fonction pour demander les information de pool
pool_request() {
read -p "Entrez la nouvelle interface réseau (ex: eth1) : " INTERFACE
read -p "Entrez l'adresse IP de début pour le pool DHCP (ex: 192.168.2.100) : " DHCP_START
read -p "Entrez l'adresse IP de fin pour le pool DHCP (ex: 192.168.2.200) : " DHCP_END
read -p "Entrez l'adresse IP de la passerelle (laissez vide si non définie) : " GATEWAY_IP
read -p "Entrez l'adresse IP du premier serveur DNS (laissez vide si non définie) : " DNS_IP1
read -p "Entrez l'adresse IP du second serveur DNS (laissez vide si non définie) : " DNS_IP2
read -p "Entrez le masque de sous-réseau (ex: 255.255.255.0) : " SUBNET_MASK
read -p "Entrez la durée de bail par défaut en secondes (ex: 600) : " DEFAULT_LEASE_TIME
read -p "Entrez la durée de bail maximum en secondes (ex: 7200) : " MAX_LEASE_TIME
}

# Fonction d'ajout d'une deuxième carte réseau à la configuration DHCP
config_dhcp_second_interface() {
    # Demander des informations à l'utilisateur pour la nouvelle interface
	pool_request

    # Vérifier si le fichier /etc/dhcpd.conf existe, sinon le créer
    if [ ! -f /etc/dhcpd.conf ]; then
        echo "Le fichier /etc/dhcpd.conf n'existe pas, création d'un nouveau fichier..."
        touch /etc/dhcpd.conf
    fi

    # Ajouter la configuration pour la deuxième interface réseau
    echo "Ajout de la configuration DHCP pour l'interface $INTERFACE..."

    cat <<EOL >> /etc/dhcpd.conf

# Configuration DHCP pour l'interface $INTERFACE
subnet ${DHCP_START%.*}.0 netmask $SUBNET_MASK {
    range $DHCP_START $DHCP_END;
    option subnet-mask $SUBNET_MASK;
EOL

    # Ajouter l'option de la passerelle si elle est définie
    if [ -n "$GATEWAY_IP" ]; then
        echo "    option routers $GATEWAY_IP;" >> /etc/dhcpd.conf
    fi

    # Ajouter les serveurs DNS s'ils sont définis
    if [ -n "$DNS_IP1" ] && [ -n "$DNS_IP2" ]; then
        echo "    option domain-name-servers $DNS_IP1, $DNS_IP2;" >> /etc/dhcpd.conf
    elif [ -n "$DNS_IP1" ]; then
        echo "    option domain-name-servers $DNS_IP1;" >> /etc/dhcpd.conf
    fi

    # Fin de la configuration pour cette interface
    echo "}" >> /etc/dhcpd.conf

    # Activer le service DHCP pour la nouvelle interface
    echo "Activation et démarrage du service DHCP pour $INTERFACE..."
    systemctl enable dhcpd4.service
    systemctl restart dhcpd4.service

    # Vérification de l'état du service
    echo "État du service DHCP pour $INTERFACE :"
    systemctl status dhcpd4.service

    echo "Configuration DHCP pour la deuxième carte réseau $INTERFACE terminée."
    read -p "Appuyez sur Entrer pour quitter"
}

# Fonction d'installation/Configuration du DHCP (dhcpd)
config_dhcp() {
    # Demander des informations à l'utilisateur
    pool_request

    # Installation de dhcp-server
    echo "Installation du serveur DHCP..."
    pacman -S --noconfirm dhcp

    # Création du fichier de configuration DHCP
    echo "Création du fichier de configuration DHCP..."
    cat <<EOL > /etc/dhcpd.conf
# Fichier de configuration DHCP

default-lease-time $DEFAULT_LEASE_TIME;
max-lease-time $MAX_LEASE_TIME;
authoritative;

subnet ${DHCP_START%.*}.0 netmask $SUBNET_MASK {
    range $DHCP_START $DHCP_END;
    option subnet-mask $SUBNET_MASK;
EOL

    # Ajouter l'option de la passerelle si elle est définie
    if [ -n "$GATEWAY_IP" ]; then
        echo "    option routers $GATEWAY_IP;" >> /etc/dhcpd.conf
    fi

    # Ajouter les serveurs DNS s'ils sont définis
    if [ -n "$DNS_IP1" ] && [ -n "$DNS_IP2" ]; then
        echo "    option domain-name-servers $DNS_IP1, $DNS_IP2;" >> /etc/dhcpd.conf
    elif [ -n "$DNS_IP1" ]; then
        echo "    option domain-name-servers $DNS_IP1;" >> /etc/dhcpd.conf
    fi

    # Fin du fichier de configuration
    echo "}" >> /etc/dhcpd.conf

    # Définir les permissions
    echo "Définition des permissions..."
    chown root:root /etc/dhcpd.conf
    chmod 644 /etc/dhcpd.conf

    # Activer et démarrer le service DHCP
    echo "Activation et démarrage du service DHCP..."
    systemctl enable dhcpd4.service
    systemctl restart dhcpd4.service

    # Vérification de l'état du service
    echo "État du service DHCP :"
    systemctl status dhcpd4.service

    echo "Installation et configuration du serveur DHCP terminées."
    read -p "Appuyez sur Entrer pour quitter"
}
