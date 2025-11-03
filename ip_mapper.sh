#!/bin/bash

# === Script: IP mapper ===
# Author: Naru Koshin
# Date: 01/11/2025
# https://github.com/narukoshin
# Usage: ./ip_mapper.sh domains.txt results.txt

# Parameters

VERSION="v1.0.5-beta"

FILE="$1"
RESULTS="$2"

if [[ "$1" == "version" ]]; then
    echo -e "\033[1;33mAuthor: Naru Koshin\033[0m"
    echo -e "\033[1;33mVersion: $VERSION\033[0m"
    exit 0
fi

# Check if file is provided
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    echo "Usage: $0 <domains-file> [results-file]"
    echo "  Example: $0 domains.txt"
    echo "  Example: $0 domains.txt results.txt"
    exit 1
fi

# Temporary file for results
TEMP=$(mktemp)
declare -A ip_to_domains
declare -A ip_count
declare -A unresolved
unresolved_count=0

echo "Resolving domains from '$FILE'..."

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
    ip_to_domains["$ip"]+="$domain"
    ((ip_count["$ip"]++))

done < "$FILE"

echo
echo "==========================================" | tee -a "$TEMP"
echo "                  RESULTS" | tee -a "$TEMP"
echo "==========================================" | tee -a "$TEMP"

# === 1. Show domains grouped by IP ===
echo -e "\nDomains grouped by IP:\n" | tee -a "$TEMP"

# Sort by count (descending), then by IP
for ip in $(for k in "${!ip_count[@]}"; do echo "${ip_count[$k]} $k"; done | sort -nr | cut -d' ' -f2-); do
    count=${ip_count[$ip]}
    domains=$(echo -e "${ip_to_domains[$ip]}" | sed 's/^/  /')
    printf "\033[1;34m%s\033[0m (%d domain%s)\n%s\n\n" "$ip" "$count" "$([[ $count -gt 1 ]] && echo "s")" "$domains" | tee -a "$TEMP"
done

# === 2. Unique IPs (only 1 domain) ===
echo -e "\033[1;32mUnique IPs (1 domain only):\033[0m" | tee -a "$TEMP"
unique_count=0
for ip in "${!ip_count[@]}"; do
    if [[ ${ip_count[$ip]} -eq 1 ]]; then
        printf "  %s → %d domains\n" "$ip" "${ip_count[$ip]}" | tee -a "$TEMP"
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
    echo -e "  Domains: $(echo -e "${ip_to_domains[$max_ip]}" | tr '\n' ' ' | xargs)" | tee -a "$TEMP"
else
    echo -e "\033[1;33mNo IP shared by multiple domains.\033[0m" | tee -a "$TEMP"
fi

# Show unresolved domains
echo | tee -a "$TEMP"
printf "\033[1;33mUnresolved domains (%d domain%s):\033[0m\n" "$unresolved_count" "$([[ $unresolved_count -gt 1 ]] && echo "s")"
for domain in "${!unresolved[@]}"; do
    printf "  %s\n" "$domain" | tee -a "$TEMP"
done

# Save results
if [[ -n "$RESULTS" ]]; then
    echo "Saving results to '$RESULTS'..."
    cp "$TEMP" "$RESULTS"
    echo "Done."
fi

echo
echo "Deleting temporary file... $TEMP"
rm -f "$TEMP"