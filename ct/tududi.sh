#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com

APP="Tududi"
var_tags="${var_tags:-todo-app}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/tududi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/chrisvel/tududi/releases/latest | yq '.tag_name' | sed 's/^v//')
  if [[ "${RELEASE}" != "$(cat ~/.tududi 2>/dev/null)" ]] || [[ ! -f ~/.tududi ]]; then
    msg_info "Stopping Service"
    systemctl stop tududi
    msg_ok "Stopped Service"

    msg_info "Upadting ${APP}"
    cp /opt/"$APP"/backend/.env /opt/"$APP".env
    rm -rf /opt/"$APP"
    fetch_and_deploy_gh_release "tududi" "chrisvel/tududi"

    cd /opt/"$APP"
    $STD npm install
    export NODE_ENV=production
    $STD npm run frontend:build
    cp -r ./dist ./backend/dist
    cp -r ./public/locales ./backend/dist/locales
    cp ./public/favicon.* ./backend/dist
    mv /opt/"$APP".env /opt/"$APP"/.env
    msg_ok "Updated $APP"

    msg_info "Starting Service"
    systemctl start tududi
    msg_ok "Started Service"

    msg_ok "Updated Successfully"
  else
    msg_ok "Already up to date"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${ADVANCED}${BL}Create your initial user in${CL} ${BGN}/opt/${APP}${CL}${BL} in the LXC:${CL} ${RD}npm run user:create <user> <password>${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3002${CL}"
