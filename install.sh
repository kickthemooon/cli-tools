#!/bin/bash
cd "${0%/*}"
this_path="$(pwd)"


install_yq() {
  local version="$1"
  echo
  echo "-------------------------------------------"
  echo "installing yq ${version} as a prerequisite"
  curl -Ls "https://github.com/mikefarah/yq/releases/download/${version}/yq_linux_amd64" -o yq
  chmod +x yq
  sudo mv yq /usr/local/bin/yq
  echo 
  echo "yq ${version} installed."
}

prerequisite_yq_version="3.4.1"
yq_file_path="$(which yq)"
if [ -f "${yq_file_path}" ]; then
  current_yq_version="$(yq --version | awk '{print $3}')"
fi

if [ "${current_yq_version}" != "${prerequisite_yq_version}" ]; then
  install_yq "${prerequisite_yq_version}"
fi

command_install() {
  local command=$1

  ${command}
}

binary_install() {
  local tool="${1}"
  local download_link="${2}"

  echo "installing ${tool} from binary"
  echo "${download_link}"
  echo

  curl -L "${download_link}" -o "${tool}"

  chmod +x "${tool}"

  sudo mv "${tool}" "/usr/local/bin/${tool}"
  echo 
  echo "${tool} installed."
}

archive_install() {
  local tool="${1}"
  local download_link="${2}"
  echo "installing from archive"
  echo "${download_link}"

  curl -L "${download_link}" -o "${tool}.tar.gz"
  mkdir "./${tool}"
  tar -zxvf "${tool}.tar.gz" -C "./${tool}"

  chmod +x "./${tool}/${tool}"
  sudo mv "./${tool}/${tool}" "/usr/local/bin/${tool}"
  
  rm "${tool}.tar.gz"
  rm -rf "./${tool}"
  echo "${tool} installed."
}

echo
echo "-------------------------------------------"
echo "installing tools ..."
versions_path="${this_path}/versions.yaml"
skipped_yq=false
for tool in $(cat ${versions_path} | yq r - tools[*].name); do
  name=$(cat ${versions_path} | yq r - "tools.(name==${tool}).name")
  version=$(cat ${versions_path} | yq r - "tools.(name==${tool}).version")
  link_template=$(cat ${versions_path} | yq r - "tools.(name==${tool}).link_template")
  command=$(cat ${versions_path} | yq r - "tools.(name==${tool}).command")


  if [ "${tool}" = "yq" ]; then
    echo
    echo "-------------------------------------------"
    echo "skipping yq ..."
    skipped_yq_version="${version}"
    continue
  fi

  echo
  echo "-------------------------------------------"
  echo "installing ${name} version ${version}"


  if [ -n "${link_template}" ]; then
    archive_match="$(echo "${link_template}" | grep "tar.gz$")"
    download_link="$(echo "${link_template}" | sed "s|VERSION|${version}|g")"
    if [ -n "${archive_match}" ]; then
      archive_install "${tool}" "${download_link}"
    else 
      echo
      binary_install "${tool}" "${download_link}"
    fi
  fi

  if [ -n "${command}" ]; then
    echo
    command_install "${command}"
  fi
done

if [ -n "${skipped_yq_version}" ] && [ "${skipped_yq_version}" != "${prerequisite_yq_version}" ]; then
  echo
  echo "installing skipped yq version"
  install_yq "${skipped_yq_version}"
fi

