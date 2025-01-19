#!/bin/bash

# Fonction pour configurer le NAT
install_nat() {
    echo "=== Configuration du NAT ==="

	echo "Interfaces disponibles :"
	ip link show | awk -F': ' '/^[0-9]+:/ {print $2}'

    read -p "Entrez l'interface de sortie (WAN, ex: eth0): " interface_wan

    # Activer l'IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

    # Ajouter la règle NAT avec iptables
    iptables -t nat -A POSTROUTING -o $interface_wan -j MASQUERADE
	
	iptables-save > /etc/iptables/iptables-rules.save
	echo "post-up iptables-restore < /etc/iptables/iptables-rules.save" >> /etc/systemd/network/$interface_wan
	
    echo "$interface_wan a été configuré comme interface WAN pour le NAT."
}

# Fonction pour créer les règles NAT
config_nat_rule() {
    echo "=== Configuration des règles NAT ==="
	
	echo "Interfaces disponibles :"
	ip link show | awk -F': ' '/^[0-9]+:/ {print $2}'
	
    read -p "Entrez l'interface d'entrée (LAN, ex: eth1): " interface_lan
    read -p "Entrez l'interface de sortie (WAN, ex: eth0): " interface_wan
	

    # Ajouter les règles NAT avec iptables
    iptables -A FORWARD -i $interface_lan -o $interface_wan -j ACCEPT
    iptables -A FORWARD -i $interface_wan -o $interface_lan -m state --state ESTABLISHED,RELATED -j ACCEPT
	
	iptables-save > /etc/iptables/iptables-rules.save
	echo "post-up iptables-restore < /etc/iptables/iptables-rules.save" >> /etc/systemd/network/$interface_wan

    echo "Le NAT a été configuré entre $interface_lan et $interface_wan."
}

# Fonction pour créer les règles de pare-feu
create_advanced_firewall_rule() {
    echo "=== Création d'une règle avancée pour UFW ==="

    # Paramètres :
    action="$1"           # Action (allow, deny, limit)
    protocol="$2"         # Protocole (tcp, udp, any)
    port="$3"             # Port ou service (ex: 443, http, https)
    src_ip="$4"           # Adresse IP source (facultatif)
    dest_ip="$5"          # Adresse IP de destination (facultatif)

    # Construction de la commande de base
    rule="ufw $action proto $protocol"

    # Ajouter l'adresse IP source si spécifiée
    if [ -n "$src_ip" ]; then
        rule="$rule from $src_ip"
    fi

    # Ajouter l'adresse IP de destination si spécifiée
    if [ -n "$dest_ip" ]; then
        rule="$rule to $dest_ip"
    fi

    # Ajouter le port/service si spécifié
    if [ -n "$port" ]; then
        rule="$rule port $port"
    fi

    # Exécuter la règle construite
    echo "Exécution de la règle : $rule"
    eval "$rule"  # Utiliser eval pour exécuter la commande correctement

    # Vérification de l'ajout de la règle
    ufw status verbose
}

# Fonction pour demander les paramètres pour "create_advanced_firewall_rule" (créer une règle de pare-feu)
get_firewall_rule_params() {
    echo "=== Création d'une règle de pare-feu personnalisée ==="

    # Demander l'action (allow, deny, limit)
    while true; do
        echo -n "Quelle action souhaitez-vous appliquer ? (allow, deny, limit): "
        read action
        if [[ "$action" == "allow" || "$action" == "deny" || "$action" == "limit" ]]; then
            break
        else
            echo "Veuillez saisir 'allow', 'deny' ou 'limit'."
        fi
    done

    # Demander le protocole (tcp, udp, any)
    while true; do
        echo -n "Quel protocole souhaitez-vous utiliser ? (tcp, udp, any): "
        read protocol
        if [[ "$protocol" == "tcp" || "$protocol" == "udp" || "$protocol" == "any" ]]; then
            break
        else
            echo "Veuillez saisir 'tcp', 'udp' ou 'any'."
        fi
    done

    # Demander le port ou le service
    echo -n "Entrez le service, le port ou la plage de port (ex: ssh ou 443 ou 10000:10100) : "
    read port
    if [ -z "$port" ]; then
        echo "Aucun port spécifié, utilisation du port par défaut 'any'."
        port="any"
    fi

    # Demander l'adresse IP source (facultatif)
    echo -n "Entrez l'adresse IP source ou l'adresse réseau/CIRD (ou laissez vide pour 'any') : "
    read src_ip
    if [ -z "$src_ip" ]; then
        src_ip=""
    fi

    # Demander l'adresse IP de destination (facultatif)
    echo -n "Entrez l'adresse IP de destination ou l'adresse réseau/CIRD (ou laissez vide pour 'any') : "
    read dest_ip
    if [ -z "$dest_ip" ]; then
        dest_ip=""
    fi

    # Afficher la récapitulation
    echo "Récapitulatif de la règle :"
    echo "  Action      : $action"
    echo "  Protocole   : $protocol"
    echo "  Port        : $port"
    echo "  IP source   : ${src_ip:-any}"
    echo "  IP dest.    : ${dest_ip:-any}"

    # Confirmer avant d'appliquer la règle
    echo -n "Confirmez-vous la création de cette règle ? (y/n): "
    read confirmation
    if [[ "$confirmation" == "y" ]]; then
        # Appeler la fonction create_advanced_firewall_rule avec les paramètres de l'utilisateur
        create_advanced_firewall_rule "$action" "$protocol" "$port" "$src_ip" "$dest_ip"
    else
        echo "Annulation de la création de la règle."
    fi
}

# Fonction pour configurer le pare-feu (UFW avec règles IPTables)
config_firewall() {
    echo "=== Configuration du pare-feu ==="
    echo "Activation de UFW..."
    
    # Installer ufw si non installé
    if ! command -v ufw &> /dev/null
    then
        pacman -S ufw --noconfirm
		systemctl enable ufw.service
		
		# Règles UFW de base
		ufw default deny incoming
		ufw default allow outgoing
		
		# Activation et redémarrage du service UFW
		ufw enable
		systemctl restart ufw.service
    fi

    echo "Le pare-feu UFW a été configuré."
    ufw status
}
