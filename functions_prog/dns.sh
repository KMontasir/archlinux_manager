#!/bin/bash

# Fonction d'installation/Configuration du DNS (Bind)
config_dns() {
    # Demander des informations à l'utilisateur
    read -p "Entrez le nom de domaine (ex: example.com) : " DOMAIN
    read -p "Entrez l'adresse IP du serveur (ex: 192.168.1.10) : " SERVER_IP
    read -p "Entrez le nom d'hôte (ex: ns) : " HOSTNAME

    # Extraire la partie réseau de l'adresse IP pour la zone inverse
    IFS='.' read -r I1 I2 I3 I4 <<< "$SERVER_IP"
    REVERSE_ZONE="$I3.$I2.$I1.in-addr.arpa"

    # Installation de BIND
    echo "Installation de BIND..."
    pacman -S --noconfirm bind

    # Création du fichier de configuration de BIND
    echo "Création du fichier de configuration..."
    cat <<EOL > /etc/named.conf
options {
    directory "/var/named"; 
    pid-file "/run/named/named.pid"; 
    allow-query { any; }; 
};

zone "$DOMAIN" IN {
    type master;
    file "$DOMAIN.db"; 
};

zone "$REVERSE_ZONE" IN {
    type master;
    file "$REVERSE_ZONE.db"; 
};
EOL

    # Création du fichier de zone directe
    echo "Création du fichier de zone directe..."
    cat <<EOL > /var/named/$DOMAIN.db
\$TTL 86400
@   IN  SOA $HOSTNAME.$DOMAIN. admin.$DOMAIN. (
        2023102001 ; Numéro de série
        3600       ; Mise à jour (1 heure)
        1800       ; Retry (30 minutes)
        604800     ; Expiration (1 semaine)
        86400      ; TTL négatif (1 jour)
)

; Enregistrements NS
@   IN  NS  $HOSTNAME.$DOMAIN.

; Enregistrements A
$HOSTNAME  IN  A   $SERVER_IP ; Adresse IP du serveur
@          IN  A   $SERVER_IP ; Adresse IP du domaine
www        IN  A   $SERVER_IP ; Sous-domaine www
EOL

    # Création du fichier de zone inverse
    echo "Création du fichier de zone inverse..."
    cat <<EOL > /var/named/$REVERSE_ZONE.db
\$TTL 86400
@   IN  SOA $HOSTNAME.$DOMAIN. admin.$DOMAIN. (
        2023102001 ; Numéro de série
        3600       ; Mise à jour (1 heure)
        1800       ; Retry (30 minutes)
        604800     ; Expiration (1 semaine)
        86400      ; TTL négatif (1 jour)
)

; Enregistrements PTR
@   IN  NS  $HOSTNAME.$DOMAIN.
$I4.$I3.$I2.$I1.in-addr.arpa. IN PTR $DOMAIN.
$HOSTNAME.$DOMAIN. IN PTR $DOMAIN.
EOL

    # Définir les permissions
    echo "Définition des permissions..."
    chown -R named:named /var/named
    chmod 640 /etc/named.conf

    # Activer et démarrer BIND
    echo "Activation et démarrage du service BIND..."
    systemctl enable named
    systemctl restart named

    # Vérification de l'état du service
    echo "État du service BIND :"
    systemctl status named

    echo "Installation et configuration de BIND terminées."
    read -p "Appuyez sur Entrer pour quitter"
}
