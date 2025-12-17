#!/usr/bin/env bash
# Workstation Autograder — Node1 + Node2 via SSH
# PASS threshold: 70%

set -euo pipefail
IFS=$'\n\t'

NODE1="172.25.250.10"
NODE2="172.25.250.11"
ROOT_PASS="radiowits"
PASS_THRESHOLD=70
TOTAL=20
PASSED=0
SUMMARY=()

green="\e[32m"; red="\e[31m"; yellow="\e[33m"; blue="\e[34m"; bold="\e[1m"; reset="\e[0m"

need_root(){ [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }

ensure_sshpass(){
  if ! command -v sshpass &>/dev/null; then
    echo "Installing sshpass..."
    dnf install -y sshpass >/dev/null 2>&1 || yum install -y sshpass
  fi
}

run_remote(){
  local host="$1"; shift
  sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$host" "$@"
}

add_summary(){
  SUMMARY+=("$1|$2|$3")
  [[ "$3" == "PASS" ]] && ((PASSED++))
}

check_ok(){ echo -e "  ${green}✅ $1${reset}"; }
check_fail(){ echo -e "  ${red}❌ $1${reset}"; }

need_root
ensure_sshpass

echo -e "${blue}${bold}Starting Workstation Autograder${reset}"
echo "----------------------------------------"

################################
# NODE1 : Q02 – Q15
################################
echo -e "\n${bold}${blue}Connecting to node1 (Q02–Q15)${reset}"

# Q02 – Network
if run_remote $NODE1 "hostname | grep -qx node1.example.com"; then
  check_ok "Q02 Hostname correct"
  add_summary Q02 Network PASS
else
  check_fail "Q02 Hostname incorrect"
  add_summary Q02 Network FAIL
fi

# Q03 – Repositories
if run_remote $NODE1 "grep -Rqs content.example.com /etc/yum.repos.d"; then
  check_ok "Q03 Repositories configured"
  add_summary Q03 Repo PASS
else
  check_fail "Q03 Repositories missing"
  add_summary Q03 Repo FAIL
fi

# Q04 – HTTPD + SELinux port 82
if run_remote $NODE1 "ss -tuln | grep -q ':82 ' && systemctl is-active httpd"; then
  check_ok "Q04 httpd on port 82"
  add_summary Q04 HTTPD PASS
else
  check_fail "Q04 httpd/SELinux issue"
  add_summary Q04 HTTPD FAIL
fi

# Q05 – Users & group
if run_remote $NODE1 "getent group sysadm && id harry && id natasha"; then
  check_ok "Q05 Users & group sysadm"
  add_summary Q05 Users PASS
else
  check_fail "Q05 Users/group incorrect"
  add_summary Q05 Users FAIL
fi

# Q06 – Collaborative directory
if run_remote $NODE1 "[[ -d /shared/sysadm ]] && stat -c %a /shared/sysadm | grep -q 2770"; then
  check_ok "Q06 /shared/sysadm correct"
  add_summary Q06 Dir PASS
else
  check_fail "Q06 Directory permissions wrong"
  add_summary Q06 Dir FAIL
fi

# Q07 – Cron
if run_remote $NODE1 "crontab -u natasha -l | grep -q '*/3'"; then
  check_ok "Q07 Cron every 3 minutes"
  add_summary Q07 Cron PASS
else
  check_fail "Q07 Cron missing"
  add_summary Q07 Cron FAIL
fi

# Q08 – Backup
if run_remote $NODE1 "file /root/archive.gz | grep -qi gzip"; then
  check_ok "Q08 Backup archive"
  add_summary Q08 Backup PASS
else
  check_fail "Q08 Backup missing"
  add_summary Q08 Backup FAIL
fi

# Q09 – NTP
if run_remote $NODE1 "grep -qi classroom.example.com /etc/chrony.conf"; then
  check_ok "Q09 NTP configured"
  add_summary Q09 NTP PASS
else
  check_fail "Q09 NTP missing"
  add_summary Q09 NTP FAIL
fi

# Q10 – Find files
if run_remote $NODE1 "[[ -d /root/found ]]"; then
  check_ok "Q10 Found directory exists"
  add_summary Q10 Find PASS
else
  check_fail "Q10 Found directory missing"
  add_summary Q10 Find FAIL
fi

# Q11 – Grep
if run_remote $NODE1 "[[ -s /root/lines ]]"; then
  check_ok "Q11 grep output exists"
  add_summary Q11 Grep PASS
else
  check_fail "Q11 grep output missing"
  add_summary Q11 Grep FAIL
fi

# Q12 – Autofs
if run_remote $NODE1 "systemctl is-active autofs"; then
  check_ok "Q12 autofs active"
  add_summary Q12 Autofs PASS
else
  check_fail "Q12 autofs inactive"
  add_summary Q12 Autofs FAIL
fi

# Q13 – UID user
if run_remote $NODE1 "id -u John | grep -qx 1545"; then
  check_ok "Q13 UID user John"
  add_summary Q13 UID PASS
else
  check_fail "Q13 UID incorrect"
  add_summary Q13 UID FAIL
fi

# Q14 – Login script
if run_remote $NODE1 "su - pandora -c true 2>&1 | grep -q 'Welcome to RHCSA examination'"; then
  check_ok "Q14 Login message"
  add_summary Q14 Login PASS
else
  check_fail "Q14 Login message missing"
  add_summary Q14 Login FAIL
fi

# Q15 – Container watcher
if run_remote $NODE1 "podman ps --format '{{.Names}}' | grep -q watcher"; then
  check_ok "Q15 Container watcher running"
  add_summary Q15 Container PASS
else
  check_fail "Q15 Container missing"
  add_summary Q15 Container FAIL
fi

################################
# NODE2 : Q16 – Q21
################################
echo -e "\n${bold}${blue}Connecting to node2 (Q16–Q21)${reset}"

# Q16 – Root password
if run_remote $NODE2 "getent shadow root | grep -v '!*'"; then
  check_ok "Q16 Root password set"
  add_summary Q16 RootPW PASS
else
  check_fail "Q16 Root password issue"
  add_summary Q16 RootPW FAIL
fi

# Q17 – Repos
if run_remote $NODE2 "grep -Rqs content.example.com /etc/yum.repos.d"; then
  check_ok "Q17 Repositories OK"
  add_summary Q17 Repo PASS
else
  check_fail "Q17 Repo missing"
  add_summary Q17 Repo FAIL
fi

# Q18 – Tuned
if run_remote $NODE2 "tuned-adm active | grep -q ':'"; then
  check_ok "Q18 Tuned active"
  add_summary Q18 Tuned PASS
else
  check_fail "Q18 Tuned not set"
  add_summary Q18 Tuned FAIL
fi

# Q19 – Swap
if run_remote $NODE2 "swapon --show | awk '{print \$3}' | grep -q 7"; then
  check_ok "Q19 Swap present"
  add_summary Q19 Swap PASS
else
  check_fail "Q19 Swap missing"
  add_summary Q19 Swap FAIL
fi

# Q20 – Volume
if run_remote $NODE2 "findmnt /mnt/database"; then
  check_ok "Q20 Volume mounted"
  add_summary Q20 LVM PASS
else
  check_fail "Q20 Volume missing"
  add_summary Q20 LVM FAIL
fi

# Q21 – Resize home
if run_remote $NODE2 "df -m /home | awk 'NR==2 {print \$2}' | awk '{exit !(\$1>=155 && \$1<=165)}'"; then
  check_ok "Q21 /home resized"
  add_summary Q21 Resize PASS
else
  check_fail "Q21 /home resize incorrect"
  add_summary Q21 Resize FAIL
fi

################################
# SUMMARY
################################
echo -e "\n${bold}${blue}Summary${reset}"
printf "%-5s | %-20s | %-6s\n" "Q" "Task" "Result"
echo "------------------------------------------"
for i in "${SUMMARY[@]}"; do
  IFS='|' read -r q t r <<< "$i"
  if [[ "$r" == "PASS" ]]; then
    printf "${green}%-5s${reset} | %-20s | ${green}%-6s${reset}\n" "$q" "$t" "$r"
  else
    printf "${red}%-5s${reset} | %-20s | ${red}%-6s${reset}\n" "$q" "$t" "$r"
  fi
done

PERCENT=$(( PASSED * 100 / TOTAL ))
echo "------------------------------------------"
echo -e "TOTAL: $PASSED / $TOTAL  →  ${bold}${PERCENT}%${reset}"

if (( PERCENT >= PASS_THRESHOLD )); then
  echo -e "${green}${bold}RESULT: PASS 🎉${reset}"
else
  echo -e "${red}${bold}RESULT: FAIL ❌${reset}"
fi
