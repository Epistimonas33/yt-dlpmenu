#!/bin/bash

# ---------------------------
# Ρυθμίσεις
# ---------------------------
DOWNLOAD_DIR="$HOME/Downloads"
COOKIES_FILE="./cookies.txt"  # αν υπάρχει, θα χρησιμοποιηθεί πρώτα

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# ---------------------------
# Έλεγχος Εξαρτήσεων και Εγκατάσταση
# ---------------------------

# Έλεγχος για ffmpeg (απαραίτητο για μετατροπές ήχου/βίντεο)
check_ffmpeg() {
    command -v ffmpeg >/dev/null 2>&1 || {
        echo -e "${RED}Σφάλμα: Το ffmpeg δεν είναι εγκατεστημένο!${RESET}"
        echo " "
        echo -e "${YELLOW}Το ffmpeg είναι απαραίτητο για τη μετατροπή ήχου και βίντεο. "
        echo "Θέλετε να δείτε τις οδηγίες εγκατάστασης;${RESET}"
        echo "1. Ναι, δείξε μου τις εντολές."
        echo "2. Όχι, Έξοδος."
        read -p "Επιλογή [1-2]: " ffmpeg_choice

        case $ffmpeg_choice in
            1)
                echo " "
                echo -e "${GREEN}### Οδηγίες Εγκατάστασης ffmpeg ###${RESET}"
                echo "Επιλέξτε την εντολή που ταιριάζει στο λειτουργικό σας σύστημα:"
                echo " "
                echo -e "${YELLOW}➡️ Debian / Ubuntu (ή Mint):${RESET}"
                echo -e "  > ${GREEN}sudo apt update && sudo apt install ffmpeg${RESET}"
                echo " "
                echo -e "${YELLOW}➡️ Fedora / CentOS / RHEL:${RESET}"
                echo -e "  > ${GREEN}sudo dnf install ffmpeg${RESET}"
                echo " "
                echo -e "${YELLOW}Μετά την εγκατάσταση, τρέξτε ξανά το script.${RESET}"
                echo " "
                read -p "Πατήστε Enter για έξοδο και εγκαταστήστε το ffmpeg..."
                exit 1
                ;;
            2)
                echo -e "${YELLOW}Ακύρωση. Έξοδος.${RESET}"
                exit 1
                ;;
            *)
                echo -e "${RED}Μη έγκυρη επιλογή. Έξοδος.${RESET}"
                exit 1
                ;;
        esac
    }
}

# Έλεγχος για wget (απαραίτητο για την προτεινόμενη εγκατάσταση του yt-dlp)
command -v wget >/dev/null 2>&1 || { echo -e "${RED}Σφάλμα: Το wget δεν είναι εγκατεστημένο! Είναι απαραίτητο για την αυτόματη εγκατάσταση του yt-dlp.${RESET}"; exit 1; }

# Έλεγχος για yt-dlp και προσφορά εγκατάστασης
command -v yt-dlp >/dev/null 2>&1 || {
    echo -e "${RED}Σφάλμα: Το yt-dlp δεν είναι εγκατεστημένο!${RESET}"
    echo " "
    echo -e "${YELLOW}Θέλετε να εγκατασταθεί το yt-dlp τώρα; (Μέθοδος GitHub)${RESET}"
    echo "1. Ναι (Λήψη απευθείας του εκτελέσιμου από GitHub)"
    echo "2. Όχι, Έξοδος"
    read -p "Επιλογή [1-2]: " install_choice

    case $install_choice in
        1)
            echo -e "${YELLOW}Δημιουργία καταλόγου ~/.local/bin και εγκατάσταση yt-dlp...${RESET}"
            # Δημιουργία του καταλόγου αν δεν υπάρχει
            mkdir -p "$HOME/.local/bin"

            # Λήψη του εκτελέσιμου
            wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O "$HOME/.local/bin/yt-dlp"

            if [ $? -ne 0 ]; then
                echo -e "${RED}Η λήψη του yt-dlp απέτυχε!${RESET}"
                exit 1
            fi

            # Εκχώρηση δικαιωμάτων εκτέλεσης
            chmod a+rx "$HOME/.local/bin/yt-dlp"

            # Ενημέρωση χρήστη για το PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo -e "${YELLOW}========================================================================================${RESET}"
                echo -e "${YELLOW}🚨 ΠΡΟΣΟΧΗ: Η διαδρομή $HOME/.local/bin δεν βρέθηκε στο PATH σας! ${RESET}"
                echo -e "${YELLOW}Για να λειτουργήσει το yt-dlp, πρέπει να προσθέσετε την παραπάνω διαδρομή στο αρχείο ρυθμίσεων του shell σας (.bashrc, .zshrc).${RESET}"
                echo -e "${YELLOW}Μπορείτε να το κάνετε τρέχοντας την εντολή: export PATH=\"\$PATH:\$HOME/.local/bin\"${RESET}"
                echo -e "${YELLOW}ΣΗΜΕΙΩΣΗ: Ίσως χρειαστεί να ανοίξετε ένα νέο τερματικό για να εφαρμοστούν οι αλλαγές.${RESET}"
                echo -e "${YELLOW}========================================================================================${RESET}"
            fi

            echo -e "${GREEN}✔ Το yt-dlp εγκαταστάθηκε επιτυχώς στο $HOME/.local/bin/yt-dlp!${RESET}"
            ;;
        2)
            echo -e "${YELLOW}Ακύρωση. Έξοδος.${RESET}"
            exit 1
            ;;
        *)
            echo -e "${RED}Μη έγκυρη επιλογή. Έξοδος.${RESET}"
            exit 1
            ;;
    esac

    echo "Πατήστε Enter για να συνεχίσετε στο μενού..."
    read
}

mkdir -p "$DOWNLOAD_DIR"

# ---------------------------
# Helper functions
# ---------------------------

find_firefox_profile() {
    local base_paths=(
        "$HOME/.mozilla/firefox"
        "$HOME/snap/firefox/common/.mozilla/firefox"
        "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    )
    for base in "${base_paths[@]}"; do
        [ -d "$base" ] || continue
        if compgen -G "$base/*default-release*" > /dev/null; then
            echo "$(compgen -G "$base/*default-release*" | head -n1)"
            return 0
        fi
        if compgen -G "$base/*default-esr*" > /dev/null; then
            echo "$(compgen -G "$base/*default-esr*" | head -n1)"
            return 0
        fi
        if compgen -G "$base/*default*" > /dev/null; then
            echo "$(compgen -G "$base/*default*" | head -n1)"
            return 0
        fi
    done
    return 1
}

build_yt_dlp_args() {
    YTDLP_ARGS=()
    if [ -f "$COOKIES_FILE" ]; then
        YTDLP_ARGS+=(--cookies "$COOKIES_FILE")
    else
        profile_dir=$(find_firefox_profile 2>/dev/null)
        if [ -n "$profile_dir" ]; then
            YTDLP_ARGS+=(--cookies-from-browser "firefox:$profile_dir")
        else
            YTDLP_ARGS+=(--cookies-from-browser "firefox")
        fi
    fi
    YTDLP_ARGS+=(--add-header "User-Agent: Mozilla/5.0" --geo-bypass)
}

show_result() {
    status=$1
    output_file=$2
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✔ Κατέβηκε επιτυχώς:${RESET} $output_file"
    else
        echo -e "${RED}✖ Σφάλμα κατά το κατέβασμα!${RESET}"
    fi
    read -p "Πατήστε Enter για επιστροφή στο μενού..."
}

yt_dlp_download() {
    local opts="$1"
    local url="$2"
    local output="$3"
    build_yt_dlp_args
    yt-dlp "${YTDLP_ARGS[@]}" $opts -o "$output" "$url"
}

# ---------------------------
# Download functions
# ---------------------------

download_video() {
    read -p "Εισάγετε το URL: " url
    echo "1. Υψηλή ποιότητα (default)"
    echo "2. Συγκεκριμένη ποιότητα"
    echo "3. Μόνο ήχος (MP3)"
    read -p "Επιλογή [1-3]: " choice

    case $choice in
        1|"")
            OUTPUT="$DOWNLOAD_DIR/%(title)s.%(ext)s"
            yt_dlp_download "-f bv*+ba/b" "$url" "$OUTPUT"
            show_result $? "$OUTPUT"
            ;;
        2)
            # Εμφάνιση όλων των διαθέσιμων μορφών
            echo -e "${YELLOW}Λήψη διαθέσιμων μορφών για το βίντεο...${RESET}"
            yt_dlp_download "-F" "$url" "/dev/null"

            # Επιλογή μορφής από χρήστη
            read -p "Εισάγετε τον αριθμό μορφής που θέλετε να κατεβάσετε: " format
            while [[ -z "$format" ]]; do
                read -p "Πρέπει να εισάγετε έναν αριθμό μορφής: " format
            done

            OUTPUT="$DOWNLOAD_DIR/%(title)s.%(ext)s"
            yt_dlp_download "-f $format" "$url" "$OUTPUT"
            show_result $? "$OUTPUT"
            ;;
        3)
            OUTPUT="$DOWNLOAD_DIR/%(title)s.%(ext)s"
            yt_dlp_download "-x --audio-format mp3" "$url" "$OUTPUT"
            show_result 0 "$OUTPUT"
            ;;
        *)
            echo -e "${YELLOW}Μη έγκυρη επιλογή.${RESET}"
            sleep 1
            ;;
    esac
}

download_playlist() {
    read -p "Εισάγετε το URL της playlist: " url
    echo "1. Όλα βίντεο σε υψηλή ποιότητα"
    echo "2. Όλα σε MP3 (audio)"
    read -p "Επιλογή [1-2]: " choice

    case $choice in
        1|"")
            OUTPUT="$DOWNLOAD_DIR/%(playlist_index)s - %(title)s.%(ext)s"
            yt_dlp_download "-f bv*+ba/b" "$url" "$OUTPUT"
            show_result $? "$OUTPUT"
            ;;
        2)
            OUTPUT="$DOWNLOAD_DIR/%(playlist_index)s - %(title)s.%(ext)s"
            yt_dlp_download "-x --audio-format mp3" "$url" "$OUTPUT"
            show_result 0 "$DOWNLOAD_DIR"
            ;;
        *)
            echo -e "${YELLOW}Μη έγκυρη επιλογή.${RESET}"
            sleep 1
            ;;
    esac
}

download_from_file() {
    read -p "Δώστε το όνομα του αρχείου (.txt): " file
    if [ ! -f "$file" ]; then
        echo -e "${RED}Το αρχείο δεν βρέθηκε!${RESET}"
        sleep 2
        return
    fi

    echo "1. Υψηλή ποιότητα (default)"
    echo "2. Συγκεκριμένη ποιότητα"
    echo "3. Μόνο ήχος (MP3)"
    read -p "Επιλογή [1-3]: " choice

    for url in $(grep -v '^#' "$file"); do
        [[ -z "$url" ]] && continue
        echo -e "${YELLOW}Κατεβάζω:${RESET} $url"
        OUTPUT="$DOWNLOAD_DIR/%(title)s.%(ext)s"

        case $choice in
            1|"")
                yt_dlp_download "-f bv*+ba/b" "$url" "$OUTPUT"
                ;;
            2)
                yt_dlp_download "-F" "$url" "/dev/null"
                read -p "Εισάγετε τον αριθμό μορφής που θέλετε να κατεβάσετε για αυτό το URL: " format
                while [[ -z "$format" ]]; do
                    read -p "Πρέπει να εισάγετε έναν αριθμό μορφής: " format
                done
                yt_dlp_download "-f $format" "$url" "$OUTPUT"
                ;;
            3)
                yt_dlp_download "-x --audio-format mp3" "$url" "$OUTPUT"
                ;;
        esac

        echo ""
    done

    echo -e "${GREEN}✔ Ολοκληρώθηκε η λήψη όλων των συνδέσμων.${RESET}"
    read -p "Πατήστε Enter για επιστροφή στο μενού..."
}


show_formats() {
    read -p "Εισάγετε το URL: " url
    yt_dlp_download "-F" "$url" "/dev/null"
    read -p "Πατήστε Enter για συνέχεια..."
}

# ---------------------------
# Μενού
# ---------------------------
while true; do
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo " Μ Ε Ν Ο Υ yt-dlp"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Κατέβασμα βίντεο/ήχου"
    echo "2. Εμφάνιση διαθέσιμων ποιοτήτων"
    echo "3. Κατέβασμα playlist"
    echo "4. Κατέβασμα από αρχείο λίστας (.txt)"
    echo "5. Έξοδος"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    read -p "Επιλέξτε [1-5]: " opt

    case $opt in
        1) download_video ;;
        2) show_formats ;;
        3) download_playlist ;;
        4) download_from_file ;;
        5) exit 0 ;;
        *) echo -e "${YELLOW}Μη έγκυρη επιλογή.${RESET}"; sleep 2 ;;
    esac
done
