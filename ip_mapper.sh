#!/bin/bash

# === Script: IP mapper ===
# Author: Naru Koshin
# Date: 01/11/2025
# https://github.com/narukoshin
# Usage: ./ip_mapper.sh -f <file> [options]

VERSION="v2.0.1"

# Defining default parameters
INPUT=""
OUTPUT=""

# Writing resolved domains to a separate file to use for other scripts
RESOLVED_OUTPUT=""

# Writing all resolved IPs to a separate file to use for other scripts
UNIQUE_IPS_OUTPUT=""

# Print help message
printHelp() {
    cat << EOF
Usage: $0 --input <file> [options]

Options:
  -h, --help              Show this help message and exit
  -v, --version           Show version information and exit
  -i, --input <file>      Specify the input file (required)
  -o, --output <file>     Specify main output file
  -r, --resolved <file>   Write resolved domains (one per line) to file
  -u, --unique-ips <file> Write unique IPs (one per line) to file

Examples:
  $0 -i domains.txt
  $0 --input domains.txt --resolved resolved.txt --unique-ips ips.txt
EOF
}

# Parsing flag arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        # --help menu
        -h | --help)
            printHelp
            exit 0
            ;;
        -v | --version)
            echo -e "\033[1;33mAuthor: Naru Koshin\033[0m"
            echo -e "\033[1;33mVersion: $VERSION\033[0m"
            exit 0
            ;;
        -i | --input)
            INPUT="$2"
            shift 2
            ;;
        -o | --output)
            OUTPUT="$2"
            shift 2
            ;;
        -r | --resolved)
            RESOLVED_OUTPUT="$2"
            shift 2
            ;;
        -u | --unique-ips)
            UNIQUE_IPS_OUTPUT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            printHelp
            exit 1
            ;;
    esac
done

# Checking if the mandatory input flag is specified
if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 --input <file>"
    exit 1
fi

# Temporary file for results
TEMP=$(mktemp)
declare -A ip_to_domains
declare -A ip_count
declare -A unresolved
unresolved_count=0

echo "Resolving domains from '$INPUT'..."

# Read each domain, resolve IP, group
while IFS= read -r domain || [[ -n "$domain" ]]; do
    [[ -z "$domain" ]] && continue
    domain=$(echo "$domain" | tr -d '\r' | xargs)

    echo -n "."

    # Get IP (first result only, ignore aliases)
    tries=0
    while [[ $tries -lt 3 ]]; do
        ip=$(host "$domain" 2>/dev/null | grep -m1 "has address" | awk '{print $4}')
        [[ -n "$ip" ]] && break
        ((tries++))
    done

    # Fallback to dig if host fails
    [[ -z "$ip" ]] && ip=$(dig +short "$domain" 2>/dev/null | head -1)

    # Fallback to ping (slower, but works)
    [[ -z "$ip" ]] && ip=$(ping -c1 "$domain" 2>/dev/null | head -1 | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

    # If still no IP, mark as unresolved
    if [[ -z "$ip" || "$ip" == *"timed out"* ]]; then
        unresolved["$domain"]=""
        ((unresolved_count++))
        echo "ERROR: Could not resolve $domain"
        continue
    fi

    # Store in associative arrays
    ip_to_domains["$ip"]+="$domain, "
    ((ip_count["$ip"]++))

done < "$INPUT"

echo
echo "==========================================" | tee -a "$TEMP"
echo "                  RESULTS" | tee -a "$TEMP"
echo "==========================================" | tee -a "$TEMP"

# === 1. Show domains grouped by IP ===
echo -e "\nDomains grouped by IP:\n" | tee -a "$TEMP"

# Sort by count (descending), then by IP
for ip in $(for k in "${!ip_count[@]}"; do echo "${ip_count[$k]} $k"; done | sort -nr | cut -d' ' -f2-); do
    count=${ip_count[$ip]}
    domains=$(echo -e "${ip_to_domains[$ip]}" | sed 's/, $//')
    printf "\033[1;34m%s\033[0m (%d domain%s)\n%s\n\n" "$ip" "$count" "$([[ $count -gt 1 ]] && echo "s")" "$domains" | tee -a "$TEMP"
done

# === 2. Unique IPs (only 1 domain) ===
echo -e "\033[1;32mUnique IPs (1 domain only):\033[0m" | tee -a "$TEMP"
unique_count=0
for ip in "${!ip_count[@]}"; do
    if [[ ${ip_count[$ip]} -eq 1 ]]; then
        printf "  %s → %d domain\n" "$ip" "${ip_count[$ip]}" | tee -a "$TEMP"
        ((unique_count++))
    fi

done
[[ $unique_count -eq 0 ]] && echo "  None" | tee -a "$TEMP"

# === 3. Most repeated IP ===
echo | tee -a "$TEMP"
max_count=0
max_ip=""
for ip in "${!ip_count[@]}"; do
    if [[ ${ip_count[$ip]} -gt $max_count ]]; then
        max_count=${ip_count[$ip]}
        max_ip="$ip"
    fi
done

if [[ $max_count -gt 1 ]]; then
    echo -e "\033[1;31mMost repeated IP:\033[0m $max_ip → $max_count domains" | tee -a "$TEMP"
    echo -e "  Domains: $(echo -e "${ip_to_domains[$max_ip]}" | sed 's/, $//' | tr '\n' ' ' | xargs)" | tee -a "$TEMP"
else
    echo -e "\033[1;33mNo IP shared by multiple domains.\033[0m" | tee -a "$TEMP"
fi

# Show unresolved domains
echo | tee -a "$TEMP"
printf "\033[1;33mUnresolved domains (%d domain%s):\033[0m\n" "$unresolved_count" "$([[ ! $unresolved_count -eq 1 ]] && echo "s")" | tee -a "$TEMP"
for domain in "${!unresolved[@]}"; do
    printf "  %s\n" "$domain" | tee -a "$TEMP"
done

if [[ $unresolved_count -eq 0 ]]; then
    echo "  None" | tee -a "$TEMP"
fi


# Save results
if [[ -n "$OUTPUT" ]]; then
    echo "Saving results to '$OUTPUT'..."
    cp "$TEMP" "$OUTPUT"
    echo "Done."
fi

# Save resolved domains
if [[ -n "$RESOLVED_OUTPUT" ]]; then
    echo
    : > "$RESOLVED_OUTPUT"
    echo "Saving resolved domains to '$RESOLVED_OUTPUT'..."
    for ip in "${!ip_to_domains[@]}"; do
        entry="${ip_to_domains[$ip]}"
        [[ -z "$entry" ]] && continue
        printf '%s' "$entry" | tr ',' '\n' | xargs -n1 echo
    done >> "$RESOLVED_OUTPUT"

    echo "  → $(grep -c '^' < "$RESOLVED_OUTPUT") resolved domains saved"
    echo "Done."
    echo -e "\n\033[1;4;35mNote:\033[0m \033[1;97mRecommended directory scan for red team:\033[0m \033[38;5;208mcat $RESOLVED_OUTPUT | feroxbuster --stdin -r --auto-tune --random-agent -f -E -q -o ferox_results.txt\033[0m\n"
fi


# save all resolved IPs the same way like resolved domains
if [[ -n "$UNIQUE_IPS_OUTPUT" ]]; then
    echo
    : > "$UNIQUE_IPS_OUTPUT"
    echo "Saving all resolved IPs to '$UNIQUE_IPS_OUTPUT'..."
    for ip in "${!ip_to_domains[@]}"; do
        printf '%s\n' "$ip"
    done >> "$UNIQUE_IPS_OUTPUT"
    echo "  → $(grep -c '^' < "$UNIQUE_IPS_OUTPUT") resolved IPs saved"
    echo "Done."
    echo -e "\n\033[1;4;35mNote:\033[0m \033[1;97mRecommended nmap for red team:\033[0m \033[38;5;208mnmap -iL $UNIQUE_IPS_OUTPUT --open -sV -O -T4 -p- -oN nmap_results.txt\033[0m\n"
fi

echo
echo "Deleting temporary file... $TEMP"
rm -f "$TEMP"