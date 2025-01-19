#!/bin/bash

# Menu SSH
menu_ssh() {
	while true; do
	
		# Afficher la banière principale
		banner_title
	
		# Afficher le menu avec encadrement et couleurs
		echo -e "${BLUE}             ====================================${RESET}"
		echo -e "${BLUE}             ============= MENU SSH =============${RESET}"
		echo -e "${BLUE}             ====================================${RESET}"
		echo ""
		echo -e "${YELLOW}           1.  Installer le service SSH${RESET}" 
		echo -e "${YELLOW}           2.  Générer une clé SSH pour un utilisateur${RESET}"
		echo -e "${RED}           0. Quitter${RESET}"
		echo ""
	
		# Demander à l'utilisateur de choisir une option
		read -p "Veuillez sélectionner une option (0 à 2) : " choice

		case $choice in
			1) config_ssh ;;
			2) get_ssh_certificate ;;
			0) banner_goodbye ;;
			*) echo -e "${RED}Option non valide.${RESET}" ;;
		esac
	done
}

# Menu DNS
menu_dns() {
	while true; do
	
		# Afficher la banière principale
		banner_title
	
		# Afficher le menu avec encadrement et couleurs
		echo -e "${BLUE}             ====================================${RESET}"
		echo -e "${BLUE}             ============= MENU DNS =============${RESET}"
		echo -e "${BLUE}             ====================================${RESET}"
		echo ""
		echo -e "${YELLOW}           1.  Installer le service DNS${RESET}" 
		echo -e "${YELLOW}           2.  Créer un Enregistrement A/PTR${RESET}"
		echo -e "${RED}           0. Quitter${RESET}"
		echo ""
	
		# Demander à l'utilisateur de choisir une option
		read -p "Veuillez sélectionner une option (0 à 2) : " choice

		case $choice in
			1) config_dns; read -p "test" ;;
			2) echo "Test ..." ;;
			0) banner_goodbye ;;
			*) echo -e "${RED}Option non valide. Veuillez entrer un nombre valide.${RESET}" ;;
		esac
	done
}

# Menu DHCP
menu_dhcp() {
	while true; do
	
		# Afficher la banière principale
		banner_title
	
		# Afficher le menu avec encadrement et couleurs
		echo -e "${BLUE}             ====================================${RESET}"
		echo -e "${BLUE}             ============= MENU DHCP ============${RESET}"
		echo -e "${BLUE}             ====================================${RESET}"
		echo ""
		echo -e "${YELLOW}           1.  Installer le service DHCP${RESET}" 
		echo -e "${YELLOW}           2.  Configurer un autre pool d'adresse${RESET}"
		echo -e "${RED}           0. Quitter${RESET}"
		echo ""
	
		# Demander à l'utilisateur de choisir une option
		read -p "Veuillez sélectionner une option (0 à 2) : " choice

		case $choice in
			1) config_dhcp ;;
			2) config_dhcp_second_interface ;;
			0) banner_goodbye ;;
			*) echo -e "${RED}Option non valide. Veuillez entrer un nombre valide.${RESET}" ;;
		esac
	done
}

# Menu FTP
menu_ftp() {
	while true; do
	
		# Afficher la banière principale
		banner_title
	
		# Afficher le menu avec encadrement et couleurs
		echo -e "${BLUE}             ====================================${RESET}"
		echo -e "${BLUE}             ============= MENU FTP =============${RESET}"
		echo -e "${BLUE}             ====================================${RESET}"
		echo ""
		echo -e "${YELLOW}           1.  Installer le service FTP${RESET}" 
		echo -e "${YELLOW}           2.  Créer un répertoire FTP et son groupe d'accès${RESET}"
		echo -e "${YELLOW}           3.  Créer un utilisateur FTP${RESET}"
		echo -e "${YELLOW}           4.  Ajouter un utilisateur à un groupe d'accès FTP${RESET}"
		echo -e "${RED}           0. Quitter${RESET}"
		echo ""
	
		# Demander à l'utilisateur de choisir une option
		read -p "Veuillez sélectionner une option (0 à 3) : " choice

		case $choice in
			1) install_ftp_server ;;
			2) create_ftp_directory_and_group ;;
			3) create_ftp_user ;;
			4) add_user_to_ftp_group ;;
			0) banner_goodbye ;;
			*) echo -e "${RED}Option non valide. Veuillez entrer un nombre valide.${RESET}" ;;
		esac
	done
}

# Menu Routeur/Pare-feu
menu_router_firewall() {
	while true; do
	
		# Afficher la banière principale
		banner_title
	
		# Afficher le menu avec encadrement et couleurs
		echo -e "${BLUE}             ====================================${RESET}"
		echo -e "${BLUE}             ====== MENU Routeur / Pare-feu =====${RESET}"
		echo -e "${BLUE}             ====================================${RESET}"
		echo ""
		echo -e "${YELLOW}           1.  Configurer les interfaces réseau${RESET}" 
		echo -e "${YELLOW}           2.  Installer le NAT${RESET}"
		echo -e "${YELLOW}           3.  Configurer une règle NAT${RESET}"
		echo -e "${YELLOW}           4.  Installer le pare-feu${RESET}"
		echo -e "${YELLOW}           5.  Configurer une règle de pare-feu${RESET}"
		echo -e "${YELLOW}           6.  Configurer une route${RESET}"
		echo -e "${RED}           0. Quitter${RESET}"
		echo ""
	
		# Demander à l'utilisateur de choisir une option
		read -p "Veuillez sélectionner une option (0 à 6) : " choice

		case $choice in
			1) config_network ;;
			2) install_nat ;;
			3) config_nat_rule ;;
			4) config_firewall ;;
			5) get_firewall_rule_params ;;
			6) config_routes ;;
			0) banner_goodbye ;;
			*) echo -e "${RED}Option non valide. Veuillez entrer un nombre valide.${RESET}" ;;
		esac
	done
}

# Menu principal
menu_principal() {
	while true; do
	
		# Afficher la banière principale
		banner_title
	
		# Afficher le menu avec encadrement et couleurs
		echo -e "${BLUE}             ====================================${RESET}"
		echo -e "${BLUE}             =========== MENU PRINCIPAL =========${RESET}"
		echo -e "${BLUE}             ====================================${RESET}"
		echo ""
		echo -e "${YELLOW}           1.  Installer Arch-Linux${RESET}" 
		echo -e "${YELLOW}           2.  Configurer les cartes réseaux${RESET}"
		echo -e "${YELLOW}           3.  Serveur SSH${RESET}"
		echo -e "${YELLOW}           4.  Serveur DNS${RESET}"
		echo -e "${YELLOW}           5.  Serveur DHCP${RESET}"
		echo -e "${YELLOW}           6.  Serveur FTP${RESET}"
		echo -e "${YELLOW}           7.  Serveur HTTP${RESET}"
		echo -e "${YELLOW}           8.  Serveur BDD${RESET}"
		echo -e "${YELLOW}           9.  Serveur Active Directory${RESET}"
		echo -e "${YELLOW}           10. Serveur IPBX${RESET}"
		echo -e "${YELLOW}           11. Serveur VPN${RESET}"
		echo -e "${YELLOW}           12. Serveur Proxy${RESET}"
		echo -e "${YELLOW}           13. Routeur/Pare-feu${RESET}"
		echo -e "${RED}           0. Quitter${RESET}"
		echo ""
	
		# Demander à l'utilisateur de choisir une option
		read -p "Veuillez sélectionner une option (0 à 14) : " choice

		case $choice in
			1) install_arch ;;
			2) config_network ;;
			3) menu_ssh ;;
			4) menu_dns ;;
			5) menu_dhcp ;;
			6) menu_ftp ;;
			7) echo "En développement ..." ;;
			8) echo "En développement ..." ;;
			9) echo "En développement ..." ;;
			10) echo "En développement ..." ;;
			11) echo "En développement ..." ;;
			12) echo "En développement ..." ;;
			13) menu_router_firewall ;;
			0) banner_goodbye ;;
			*) echo -e "${RED}Option non valide. Veuillez entrer un nombre valide.${RESET}" ;;
		esac
	done
}
