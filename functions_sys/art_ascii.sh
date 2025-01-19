#!/bin/bash

# Fonctions banières en texte d'art ASCII

# Couleurs ANSI
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RESET='\033[0m'

# Banière principale
banner_title() {
	clear
	
    echo -e "${RED}                               ##                         ## "
    echo -e "${RED}                               ## "
    echo -e "${RED}  ##  ##    ####    #####     #####    ####     #####    ###     ###### "
    echo -e "${RED}  #######  ##  ##   ##  ##     ##         ##   ##         ##      ##  ## "
    echo -e "${RED}  ## # ##  ##  ##   ##  ##     ##      #####    #####     ##      ## "
    echo -e "${RED}  ##   ##  ##  ##   ##  ##     ## ##  ##  ##        ##    ##      ## "
    echo -e "${RED}  ##   ##   ####    ##  ##      ###    #####   ######    ####    #### "
    echo ""
}

# Banière "Au revoir"
banner_goodbye() {
	banner_title
	echo ""
	echo -e "${BLUE} Au revoir!${RESET}"
	echo ""
	exit 0
}
