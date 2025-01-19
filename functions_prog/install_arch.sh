#!/bin/bash

# --- Charger la configuration ---
source ../config/config_install.cfg

# --- Fonctions d'installation ---

# 0. Demande du mot de passe root avec gestion sécurisée
prompt_root_password() {
  while true; do
    echo "Veuillez entrer le mot de passe root :"
    read -s -p "Mot de passe root : " root_password
    echo
    read -s -p "Confirmez le mot de passe root : " root_password_confirm
    echo

    if [ "$root_password" == "$root_password_confirm" ]; then
      echo "Le mot de passe root a été défini avec succès."
      break
    else
      echo "Les mots de passe ne correspondent pas. Veuillez réessayer."
    fi
  done
}

# 1. Configuration du réseau avec systemd-networkd
configure_network() {
  echo "Configuration du réseau..."

  # Afficher les interfaces réseau disponibles
  echo "Interfaces réseau disponibles (UP) :"
  ip -o link show | awk '/state UP/ {print $2}' | tr -d ':' | nl

  # Demander à l'utilisateur de choisir une interface
  read -p "Veuillez choisir l'interface (numéro) : " INTERFACE_NUM

  # Récupérer le nom de l'interface choisie
  INTERFACE=$(ip -o link show | awk '/state UP/ {print $2}' | tr -d ':' | sed -n "${INTERFACE_NUM}p")

  if [ -z "$INTERFACE" ]; then
    echo "Erreur : Interface non valide ou introuvable."
    exit 1
  fi

  # Afficher les fichiers de configuration existants
  echo "Fichiers de configuration réseau existants :"
  ls /etc/systemd/network/*.network 2>/dev/null | nl

  # Demander à l'utilisateur de choisir ou de saisir un nouveau nom de fichier
  read -p "Veuillez choisir un fichier de configuration existant (numéro) ou entrez un nouveau nom (sans extension) [ex: 20-wired] : " CONFIG_CHOICE

  if [[ "$CONFIG_CHOICE" =~ ^[0-9]+$ ]]; then
    CONFIG_FILE=$(ls /etc/systemd/network/*.network 2>/dev/null | sed -n "${CONFIG_CHOICE}p")
    if [ -z "$CONFIG_FILE" ]; then
      echo "Erreur : Numéro de fichier non valide."
      exit 1
    fi
  else
    CONFIG_FILE="/etc/systemd/network/${CONFIG_CHOICE}.network"
  fi

  # Créer la configuration réseau statique ou DHCP
  if [ "$FC_USE_DHCP" = true ]; then
    echo "Utilisation de DHCP sur l'interface $INTERFACE"
    cat <<EOF > "$CONFIG_FILE"
[Match]
Name=$INTERFACE

[Network]
DHCP=yes
EOF
  else
    echo "Configuration manuelle du réseau sur l'interface $INTERFACE"
    cat <<EOF > "$CONFIG_FILE"
[Match]
Name=$INTERFACE

[Network]
Address=${FC_IP_ADDRESS}/${FC_CIDR}
Gateway=$FC_GATEWAY
DNS=$FC_DNS
EOF
  fi

  # Redémarrer systemd-networkd et systemd-resolved
  systemctl restart systemd-networkd.service
  systemctl restart systemd-resolved.service
  
  echo "Test de connexion à Internet ..."
  ping -c 4 8.8.8.8
  ping -c 4 google.com
  
  echo "Configuration du réseau terminée."
  echo "Appuyez sur Entrée pour continuer ou Ctrl+C pour quitter ()"
  read
}

# 2. Préparation des disques avec vérification de l'état du disque
prepare_disks() {
  echo "Préparation des disques..."

  # Créer une table de partition en fonction du mode (gpt pour UEFI, msdos pour BIOS)
  if [ "$FC_PARTITION_TABLE_TYPE" = "gpt" ]; then
    echo "Création de la partition GPT pour UEFI sur $FC_DISK..."
    parted -s $FC_DISK mklabel gpt || { echo "Erreur : Impossible de créer la table de partition GPT."; exit 1; }
    echo "Création de la partition GPT sur $FC_DISK..."
    parted -s $FC_DISK mkpart primary fat32 $FC_PART1_START $FC_PART1_END || { echo "Erreur : Impossible de créer la partition EFI."; exit 1; }
    parted -s $FC_DISK set 1 esp on || { echo "Erreur : Impossible de définir la partition 1 comme partition EFI."; exit 1; }
    echo "Formatage de la partition ${FC_DISK}1..."
    mkfs.fat -F 32 ${FC_DISK}1 || { echo "Erreur : Impossible de formater la partition UEFI."; exit 1; }
  else
    echo "Création de la partition MSDOS pour BIOS sur $FC_DISK..."
    parted -s $FC_DISK mklabel msdos || { echo "Erreur : Impossible de créer la table de partition MSDOS."; exit 1; }
    echo "Création de la partition MSDOS sur $FC_DISK..."
    parted -s $FC_DISK mkpart primary fat32 $FC_PART1_START $FC_PART1_END || { echo "Erreur : Impossible de créer la partition MSDOS."; exit 1; }
    parted -s $FC_DISK set 1 esp on || { echo "Erreur : Impossible de définir la partition 1 comme partition MSDOS."; exit 1; }
    echo "Formatage de la partition ${FC_DISK}1..."
    mkfs.ext4 ${FC_DISK}4 || { echo "Erreur : Impossible de formater la partition MSDOS."; exit 1; }
  fi

  # Partition 2 : Swap
  echo "Création de la partition swap sur $FC_DISK..."
  parted -s $FC_FC_DISK mkpart primary linux-swap $FC_PART2_START $FC_PART2_END || { echo "Erreur : Impossible de créer la partition Swap."; exit 1; }
  echo "Formatage de la partition ${FC_DISK}2..."
  mkswap ${FC_DISK}2 || { echo "Erreur : Impossible de formater la partition Swap."; exit 1; }

  # Partition 3 : Home
  echo "Création de la partition home sur $FC_DISK..."
  parted -s $FC_DISK mkpart primary ext4 $FC_PART3_START $FC_PART3_END || { echo "Erreur : Impossible de créer la partition Home."; exit 1; }
  echo "Formatage de la partition ${FC_DISK}3..."
  mkfs.ext4 ${FC_DISK}3 || { echo "Erreur : Impossible de formater la partition Home."; exit 1; }

  # Partition 4 : Root
  echo "Création de la partition root sur $FC_DISK..."
  parted -s $FC_DISK mkpart primary ext4 $FC_PART4_START $FC_PART4_END || { echo "Erreur : Impossible de créer la partition Root."; exit 1; }
  echo "Formatage de la partition ${FC_DISK}4..."
  mkfs.ext4 ${FC_DISK}4 || { echo "Erreur : Impossible de formater la partition Root."; exit 1; }

  # Activer la partition Swap
  swapon ${FC_DISK}2 || { echo "Erreur : Impossible d'activer la partition Swap."; exit 1; }

  echo "Préparation des disques terminée."
	lsblk
	echo "Appuyez sur Entrée pour continuer ou Ctrl+C pour quitter"
	read
}

# 3. Installation du système de base et facultatif avec vérifications
install_base_system() {
  echo "Initialisation des clés publiques et synchronisation des paquets..."
  pacman-key --init
  pacman-key --populate archlinux
  pacman -Sy --noconfirm || { echo "Erreur : Impossible de synchroniser la base de données de paquets."; exit 1; }

  echo "Installation du système de base..."
  mount ${FC_DISK}4 /mnt
  if [ "$FC_PARTITION_TABLE_TYPE" = "gpt" ]; then
    mkdir -p /mnt/boot/efi
    mount ${FC_DISK}1 /mnt/boot/efi
  else
    mkdir -p /mnt/boot
    mount ${FC_DISK}1 /mnt/boot
  fi

  pacstrap /mnt base linux linux-firmware grub archlinux-keyring || { echo "Erreur : Échec de l'installation de la base."; exit 1; }
  pacstrap /mnt bash-completion nano openssh sudo || { echo "Erreur : Échec des installations facultatives."; exit 1; }
  
  # Vérifier si le système est en mode UEFI
  if [ "$FC_PARTITION_TABLE_TYPE" = "gpt" ]; then
    pacstrap /mnt efibootmgr dosfstools e2fsprogs || { echo "Erreur : Échec des installations pour UEFI."; exit 1; }
  fi

  genfstab -U /mnt >> /mnt/etc/fstab || { echo "Erreur : Échec de la génération du fichier fstab."; exit 1; }
}

# 4. Configuration du système après installation
configure_system() {
  echo "Configuration du système..."
  echo "root:$root_password" | arch-chroot /mnt chpasswd

  arch-chroot /mnt /bin/bash <<EOF
# Configurer/Synchoniser l'horloge
	ln -sf /usr/share/zoneinfo/$FC_TIMEZONE /etc/localtime
  hwclock --systohc
	
# Configurer la langue et le clavier
  echo "$FC_LOCALE" > /etc/locale.gen
  locale-gen
  echo "FC_LANG=$LANG" > /etc/locale.conf
	echo KEYMAP=$FC_KEYMAP > /etc/vconsole.conf
	
# Ajouter le nom d'hôte
  echo "$FC_HOSTNAME" > /etc/hostname
	
# Créer l'utilisateur SUDO
	useradd -m -G wheel $FC_USERSUDO
	sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
	
# Ajout du shell "nologin" permettant d'empêcher un utilisateur de se connecter via un shell SSH ou de la console directe
	echo "/usr/sbin/nologin" | tee -a /etc/shells
	
# Personnaliser le PROMPT
	sed -i 's|^PS1=.*|PS1=$FC_PS1|' /etc/bash.bashrc
	
# Personnaliser LS et GREP
	echo $FC_COLOR_LS_GREP >> /etc/bash.bashrc
	
# Personnaliser les couleurs pour les script .sh avec nano
	echo $FC_COLOR_NANO_BASH >> /etc/nanorc
	
# Lier resolv.conf à systemd-resolved si besoins
  #ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
	
# Activer les services aux démarrage
  systemctl enable systemd-networkd.service
  systemctl enable systemd-resolved.service
	systemctl enable sshd.service
EOF

  echo "Configuration du système terminée."
}

# 5. Installation de GRUB ou bootloader UEFI
install_bootloader() {
  echo "Installation du bootloader..."
  if [ "$FC_PARTITION_TABLE_TYPE" = "gpt" ]; then
    arch-chroot /mnt /bin/bash <<EOF
      pacman -S --noconfirm grub efibootmgr
      grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
      grub-mkconfig -o /boot/grub/grub.cfg
EOF
  else
    arch-chroot /mnt /bin/bash <<EOF
      pacman -S --noconfirm grub
      grub-install --target=i386-pc $FC_DISK
      grub-mkconfig -o /boot/grub/grub.cfg
EOF
  fi
}

# --- Exécution du programme ---
install_arch() {
	prompt_root_password
	configure_network
	prepare_disks
	install_base_system
	configure_system
	install_bootloader
	
	echo "Programme d'installation terminée."
	echo "	1. Redémarrez la machine, puis connectez-vous en tant que root"
	echo "	2. Attribuez un mot de passe à l'utilisateur sudo, puis connectez-vous avec"
	echo "	3. Procédez aux configurations système, réseau, services, etc."
}
