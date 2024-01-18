export REPO_ROOT=$(git rev-parse --show-toplevel)
source ${REPO_ROOT}/dev/bin/cli.sh

get_kratos_code() {
  kratos_pg -c "SELECT body FROM courier_messages WHERE recipient='$1' ORDER BY created_at DESC LIMIT 1;" | grep -oP '\d{6}' | head -1
}
