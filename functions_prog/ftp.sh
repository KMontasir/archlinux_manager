#!/bin/bash

# Fonction pour installer le serveur FTP (vsftpd)
install_ftp_server() {
    # Installation de vsftpd
    echo "Installation de vsftpd..."
    pacman -S --noconfirm vsftpd

    # Configuration de vsftpd
    echo "Configuration de vsftpd..."
	
	# Création du fichier de la liste des utilisateurs autorisés à accéder au serveur FTP
	touch /etc/vsftpd.userlist
	
	# Création du répertoire contenant les répertoires racines des groupes de projets FTP (organisation)
	mkdir -p /srv/ftp/groups
	chmod 770 /srv/ftp/groups
	
	# Création du répertoire contenant les répertoires racines des utilisateurs FTP (organisation)
	mkdir -p /srv/ftp/users
	chmod 770 /srv/ftp/groups

    cat <<EOL > /etc/vsftpd.conf
# Configuration de base de vsftpd
listen=YES                      # Active le mode autonome, permettant à vsftpd de s'exécuter sans être lancé par un serveur xinetd
listen_port=21                  # Définit le port 21 comme port par défaut pour les connexions FTP

# Authentification et permissions des utilisateurs
anonymous_enable=NO             # Désactive les connexions anonymes pour renforcer la sécurité
local_enable=YES                # Permet aux utilisateurs locaux du système de se connecter
write_enable=YES                # Autorise les utilisateurs à envoyer des fichiers sur le serveur
pam_service_name=vsftpd         # Spécifie le service PAM à utiliser pour l'authentification des utilisateurs

# Restriction d'accès des utilisateurs
chroot_local_user=YES           # Isoler chaque utilisateur dans son répertoire personnel pour la sécurité
allow_writeable_chroot=YES      # Permet aux utilisateurs d'écrire dans leur répertoire chroot, même si cela n'est pas recommandé pour des raisons de sécurité
local_umask=022                 # Définit le masque de création de fichiers, 022 signifie que les fichiers auront des permissions 755 (rwxr-xr-x)

# Configuration du répertoire FTP de l'utilisateur
user_sub_token=\$USER           # Remplace \$USER par le nom d'utilisateur connecté dans les chemins de répertoire, utile pour une configuration plus personnalisée
local_root=/srv/ftp/\$USER      # Définit le répertoire racine de l'utilisateur, chaque utilisateur sera dirigé vers son propre répertoire

# Configuration du mode FTP passif
pasv_enable=YES                 # Active le mode FTP passif, ce qui est nécessaire pour certains clients derrière des pare-feu
pasv_min_port=10000             # Définit le port minimum pour les connexions passives
pasv_max_port=10100             # Définit le port maximum pour les connexions passives

# Liste d'autorisations des accès utilisateurs
userlist_enable=YES             # Active la gestion des utilisateurs via une liste d'autorisation
userlist_file=/etc/vsftpd.userlist # Spécifie le chemin du fichier contenant la liste des utilisateurs autorisés
userlist_deny=NO                # Si défini sur NO, seuls les utilisateurs dans la liste sont autorisés à se connecter
EOL

    # Activer et démarrer le service FTP
    echo "Activation et démarrage du service vsftpd..."
    systemctl enable vsftpd
    systemctl restart vsftpd
	vsftpd enable

    # Vérification de l'état du service
    echo "État du service FTP :"
    systemctl status vsftpd
	vsftpd status

    echo "Le serveur FTP a été installé et configuré avec succès."
	echo "Appuyer sur Entrer pour quitter."
}

# Fonction pour créer un répertoire FTP et son groupe d'accès
create_ftp_directory_and_group() {
    # Demander des informations à l'utilisateur
    read -p "Entrez le nom du groupe FTP (ex: projectgroup) : " FTP_GROUP
    FTP_DIR=/srv/ftp/groups/$FTP_GROUP
	
	# Vérifier si le groupe existe
	if_group_no_exist $FTP_GROUP \
	"create_group $FTP_GROUP" \
	"echo 'Le groupe $FTP_GROUP existe déjà'; continu_or_stop"

	# Vérifier si le répertoire existe
	if_directory_no_exist $FTP_DIR \
	"create_directory $FTP_DIR" \
	"echo 'Le répertoire $FTP_DIR existe déjà'; continu_or_stop"
	
    # Définir les permissions et assigner le groupe
	echo "Définition des permissions ..."
    chown root:$FTP_GROUP "$FTP_DIR"
	chmod 770 "$FTP_DIR"

    echo "Le répertoire FTP $FTP_DIR est configuré avec le groupe $FTP_GROUP."
}

# Fonction pour créer un utilisateur FTP
create_ftp_user() {
    # Demander des informations à l'utilisateur
    read -p "Entrez le nom de l'utilisateur FTP (ex: ftpuser) : " FTP_USER
    read -p "Entrez le mot de passe pour $FTP_USER : " USER_PASSWORD

	# Création de l'utilisateur FTP
	if_user_exist $FTP_USER \
	"echo 'L'utilisateur existe'; banner_goodbye" \
	"create_user $FTP_USER $USER_PASSWORD /srv/ftp/users/$FTP_USER /usr/sbin/nologin"
	
	# Ajout de l'utilisateur dans la liste des utilisateurs autorisés à accéder au serveur FTP
    echo $FTP_USER >> /etc/vsftpd.userlist

    echo "L'utilisateur FTP $FTP_USER a été créé avec un accès à son répertoire personnel."
	echo "Ajouter-le dans des groupes pour qu'il bénéficie d'accès vers d'autres répertoires."
	echo "Pour y accéder via un client Windows (PowerShell), veuilliez procéder comme ceci :
FTP
OPEN [serveur.exemple.com (ou adresse IP)]
USER [ftpuser]
"
	echo "il est possible de créer un fichier afin de l'appeler comme ceci : ftp -n -d -s:.\chemin\ftp.txt"
}

# Fonction pour ajouter un utilisateur à un groupe d'accès FTP
add_user_to_ftp_group() {
    # Demander des informations à l'utilisateur
    read -p "Entrez le nom de l'utilisateur FTP (ex: ftpuser) : " FTP_USER
    read -p "Entrez le nom du groupe FTP (ex: projectgroup) : " FTP_GROUP

	# Vérifier si le répertoire du groupe est présent
	if_directory_no_exist "/srv/ftp/groups/$FTP_GROUP" \
	"echo 'Le répertoire /srv/ftp/groups/$FTP_GROUP introuvable !'; continu_or_stop" \
	"echo 'Le répertoire /srv/ftp/groups/$FTP_GROUP est présent !'"
	
	# Ajout de l'utilisateur dans le groupe si existants
	add_user_in_group $FTP_USER $FTP_GROUP
	
	# Créer le lien d'accès au répertoire du groupe
	ln -s /srv/ftp/groups/$FTP_GROUP /srv/ftp/users/$FTP_USER

    echo "L'utilisateur $FTP_USER a été ajouté au groupe $FTP_GROUP et a accès au répertoire $FTP_GROUP_DIR."
	echo "Veuillez vous assurer que l'utilisateur $FTP_USER se déconnecte et se reconnecte pour que les changements prennent effet."
}
