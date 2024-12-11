#!/bin/bash
#=======================
# Script : Gestion Utilisateurs et Sauvegardes
# Auteur : groupe 5
# Date : 
# ===============================

# Variables globales
SAUVEGARDE_DIR="/var/backups"
DOSSIER_CRITIQUE="/etc"
JOURS_CONSERVATION=7
EMAIL_ADMIN="saifeddineelouatouati@gmail.com"

# Codes couleurs
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# Fonction : Afficher un message avec couleur
msg() {
    COLOR=$1
    shift
    echo -e "${COLOR}$*${RESET}"
}

# Fonction : Vérifier si un répertoire ou fichier existe
verifier_existence() {
    if [[ ! -e "$1" ]]; then
        msg $RED "Erreur : Le fichier ou répertoire $1 n'existe pas."
        return 1
    fi
    return 0
}

# Fonction : Créer un groupe
creer_groupe() {
    read -p "Entrez le nom du groupe à créer : " GROUP_NAME
    if getent group "$GROUP_NAME" &>/dev/null; then
        msg $YELLOW "Le groupe $GROUP_NAME existe déjà."
    else
        sudo groupadd "$GROUP_NAME"
        msg $GREEN "Groupe $GROUP_NAME créé avec succès."
    fi
}

# Fonction : Ajouter un utilisateur à un groupe
ajouter_utilisateur_a_groupe() {
    read -p "Entrez le nom d'utilisateur : " USERNAME
    read -p "Entrez le nom du groupe : " GROUP_NAME
    if id "$USERNAME" &>/dev/null; then
        if getent group "$GROUP_NAME" &>/dev/null; then
            sudo usermod -aG "$GROUP_NAME" "$USERNAME"
            msg $GREEN "L'utilisateur $USERNAME a été ajouté au groupe $GROUP_NAME."
        else
            msg $RED "Le groupe $GROUP_NAME n'existe pas."
        fi
    else
        msg $RED "L'utilisateur $USERNAME n'existe pas."
    fi
}

# Fonction : Supprimer un groupe
supprimer_groupe() {
    read -p "Entrez le nom du groupe à supprimer : " GROUP_NAME
    if getent group "$GROUP_NAME" &>/dev/null; then
        sudo groupdel "$GROUP_NAME"
        msg $GREEN "Le groupe $GROUP_NAME a été supprimé avec succès."
    else
        msg $RED "Le groupe $GROUP_NAME n'existe pas."
    fi
}

# Fonction : Vérifier les processus actifs d'un utilisateur
verifier_processus_utilisateur() {
    read -p "Entrez le nom d'utilisateur pour vérifier ses processus : " USERNAME
    if id "$USERNAME" &>/dev/null; then
        msg $CYAN "Processus en cours de l'utilisateur $USERNAME :"
        ps -u "$USERNAME"
    else
        msg $RED "L'utilisateur $USERNAME n'existe pas."
    fi
}

# Fonction : Ajouter un utilisateur
ajouter_utilisateur() {
    read -p "Entrez le nom d'utilisateur : " USERNAME
    if id "$USERNAME" &>/dev/null; then
        msg $YELLOW "L'utilisateur $USERNAME existe déjà."
    else
        sudo useradd -m "$USERNAME"
        msg $GREEN "Utilisateur $USERNAME créé avec succès."
        sudo passwd "$USERNAME"

        # Demander si l'on souhaite ajouter des droits
        read -p "Souhaitez-vous donner des droits spécifiques à cet utilisateur ? (oui/non) : " REPONSE
        if [[ "$REPONSE" == "oui" ]]; then
            msg $CYAN "Groupes disponibles :"
            getent group | cut -d: -f1 | column

            read -p "Entrez le nom du groupe (par exemple : sudo, docker) : " GROUP
            if getent group "$GROUP" &>/dev/null; then
                sudo usermod -aG "$GROUP" "$USERNAME"
                msg $GREEN "L'utilisateur $USERNAME a été ajouté au groupe $GROUP avec succès."
            else
                msg $RED "Le groupe $GROUP n'existe pas."
            fi
        else
            msg $CYAN "Aucun droit supplémentaire n'a été donné à l'utilisateur $USERNAME."
        fi

        # Gestion des fichiers et répertoires
        read -p "Souhaitez-vous ajouter, créer ou supprimer des fichiers/répertoires pour cet utilisateur ? (oui/non) : " FILE_REPONSE
        if [[ "$FILE_REPONSE" == "oui" ]]; then
            msg $CYAN "Options :"
            echo -e "1. Créer un fichier\n2. Créer un répertoire\n3. Ajouter un fichier/répertoire\n4. Supprimer un fichier/répertoire"
            read -p "Choisissez une option (1, 2, 3 ou 4) : " FILE_OPTION

            case $FILE_OPTION in
                1)
                    # Créer un fichier
                    read -p "Entrez le chemin relatif ou absolu du fichier à créer : " FILE_PATH
                    sudo touch "/home/$USERNAME/$FILE_PATH"
                    msg $GREEN "Le fichier $FILE_PATH a été créé."

                    # Attribuer des droits
                    read -p "Entrez les droits à appliquer (par exemple : 644 pour les fichiers) : " PERMISSIONS
                    sudo chmod "$PERMISSIONS" "/home/$USERNAME/$FILE_PATH"
                    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/$FILE_PATH"
                    msg $GREEN "Les droits $PERMISSIONS ont été appliqués sur $FILE_PATH."
                    ;;

                2) 
                    # Créer un répertoire
                    read -p "Entrez le chemin relatif ou absolu du répertoire à créer : " DIR_PATH
                    sudo mkdir -p "/home/$USERNAME/$DIR_PATH"
                    msg $GREEN "Le répertoire $DIR_PATH a été créé."

                    # Attribuer des droits
                    read -p "Entrez les droits à appliquer (par exemple : 755 pour les répertoires) : " PERMISSIONS
                    sudo chmod "$PERMISSIONS" "/home/$USERNAME/$DIR_PATH"
                    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/$DIR_PATH"
                    msg $GREEN "Les droits $PERMISSIONS ont été appliqués sur $DIR_PATH."
                    ;;
                3)
                    # Ajouter un fichier/répertoire
                    read -p "Entrez le chemin relatif ou absolu du fichier/répertoire à ajouter : " FILE_PATH
                    sudo mkdir -p "/home/$USERNAME/$FILE_PATH"
                    msg $GREEN "Le fichier/répertoire $FILE_PATH a été ajouté."

                    # Attribuer des droits
                    read -p "Entrez les droits à appliquer (par exemple : 755 pour répertoires, 644 pour fichiers) : " PERMISSIONS
                    sudo chmod "$PERMISSIONS" "/home/$USERNAME/$FILE_PATH"
                    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/$FILE_PATH"
                    msg $GREEN "Les droits $PERMISSIONS ont été appliqués sur $FILE_PATH."
                    ;;
                4)
                    # Supprimer un fichier ou un répertoire
                    read -p "Entrez le chemin relatif ou absolu du fichier/répertoire à supprimer : " FILE_PATH
                    if [[ -e "/home/$USERNAME/$FILE_PATH" ]]; then
                        sudo rm -rf "/home/$USERNAME/$FILE_PATH"
                        msg $GREEN "Le fichier/répertoire $FILE_PATH a été supprimé."
                    else
                        msg $RED "Le fichier/répertoire $FILE_PATH n'existe pas."
                    fi
                    ;;
                *)
                    msg $RED "Option invalide."
                    ;;
            esac
        else
            msg $CYAN "Aucun fichier ou répertoire n'a été modifié pour $USERNAME."
        fi
    fi
}

# Fonction : Supprimer un utilisateur
supprimer_utilisateur() {
    read -p "Entrez le nom d'utilisateur à supprimer : " USERNAME
    if id "$USERNAME" &>/dev/null; then
        sudo userdel -r "$USERNAME"
        msg $GREEN "Utilisateur $USERNAME supprimé avec succès."
    else
        msg $RED "L'utilisateur $USERNAME n'existe pas."
    fi
}

# Fonction : Modifier le mot de passe d'un utilisateur
modifier_motdepasse() {
    read -p "Entrez le nom d'utilisateur : " USERNAME
    if id "$USERNAME" &>/dev/null; then
        sudo passwd "$USERNAME"
    else
        msg $RED "L'utilisateur $USERNAME n'existe pas."
    fi
}

# Fonction : Lister les utilisateurs
lister_utilisateurs() {
    msg $CYAN "Liste des utilisateurs du système :"
    cut -d: -f1 /etc/passwd
}

# Fonction : Sauvegarder les fichiers critiques
sauvegarder_fichiers() {
    DATE=$(date +%Y%m%d)
    FICHIER_SAUVEGARDE="$SAUVEGARDE_DIR/sauvegarde_$DATE.tar.gz"
    msg $CYAN "Création de la sauvegarde de $DOSSIER_CRITIQUE dans $FICHIER_SAUVEGARDE..."
    sudo tar -czf "$FICHIER_SAUVEGARDE" "$DOSSIER_CRITIQUE"
    msg $GREEN "Sauvegarde terminée."
}

# Fonction : Nettoyer les anciennes sauvegardes
nettoyer_sauvegardes() {
    msg $CYAN "Suppression des sauvegardes de plus de $JOURS_CONSERVATION jours..."
    sudo find "$SAUVEGARDE_DIR" -type f -name "*.tar.gz" -mtime +$JOURS_CONSERVATION -exec rm -f {} \;
    msg $GREEN "Nettoyage terminé."
}

# Fonction : Envoyer un rapport par e-mail
envoyer_rapport() {
    SAUVEGARDES=$(ls -lh "$SAUVEGARDE_DIR")
    echo -e "Rapport de sauvegarde:\n\n$SAUVEGARDES" | mail -s "Rapport de sauvegarde" "$EMAIL_ADMIN"
    msg $GREEN "Rapport envoyé à $EMAIL_ADMIN."
}

# Menu principal
while true; do
    echo -e "${MAGENTA}=========================== Menu ===========================${RESET}"
    echo -e "${GREEN}1. Créer un groupe${RESET}"
    echo -e "${GREEN}2. Ajouter un utilisateur à un groupe${RESET}"
    echo -e "${GREEN}3. Supprimer un groupe${RESET}"
    echo -e "${GREEN}4. Vérifier les processus d'un utilisateur${RESET}"
    echo -e "${GREEN}5. Ajouter un utilisateur${RESET}"
    echo -e "${GREEN}6. Supprimer un utilisateur${RESET}"
    echo -e "${GREEN}7. Modifier le mot de passe d'un utilisateur${RESET}"
    echo -e "${GREEN}8. Lister les utilisateurs${RESET}"
    echo -e "${GREEN}9. Sauvegarder les fichiers critiques${RESET}"
    echo -e "${GREEN}10. Nettoyer les anciennes sauvegardes${RESET}"
    echo -e "${GREEN}11. Envoyer un rapport de sauvegarde par e-mail${RESET}"
    echo -e "${GREEN}12. Quitter${RESET}"
    read -p "Choisissez une option (1-12) : " CHOIX

    case $CHOIX in
        1) creer_groupe ;;
        2) ajouter_utilisateur_a_groupe ;;
        3) supprimer_groupe ;;
        4) verifier_processus_utilisateur ;;
        5) ajouter_utilisateur ;;
        6) supprimer_utilisateur ;;
        7) modifier_motdepasse ;;
        8) lister_utilisateurs ;;
        9) sauvegarder_fichiers ;;
        10) nettoyer_sauvegardes ;;
        11) envoyer_rapport ;;
        12) msg $CYAN "Au revoir !" ; exit ;;
        *) msg $RED "Option invalide." ;;
    esac
done
