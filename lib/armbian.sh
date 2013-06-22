# Usage installQEMU <ARMSTRAP_ROOT> <ARCH>
function installQEMU {
  printStatus installQEMU "Installing QEMU User Emulator (${2})"  
  cp /usr/bin/qemu-${2}-static ${1}/usr/bin
}

# Usage removeQEMU <ARMSTRAP_ROOT> <ARCH>
function removeQEMU {
  printStatus removeQEMU "Removing QEMU User Emulator (${2})"  
  rm -f ${1}/usr/bin/qemu-${2}-static
}

# Usage : disableServices <ARMSTRAP_ROOT>
function disableServices {
  printStatus "disableServices" "Disabling services startup"
  printf "#!/bin/sh\nexit 101\n" > ${1}/usr/sbin/policy-rc.d
  chmod +x ${1}/usr/sbin/policy-rc.d
}

function divertServices {
  printStatus "divertServices" "Disabling Ubuntu Init"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ dpkg-divert --local --rename --add /sbin/init
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ ln -s /bin/true /sbin/init
}

function undivertServices {
  printStatus "undivertServices" "Enabling Ubuntu Init"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ unlink /sbin/init
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ dpkg-divert --rename --remove /sbin/init
}

# Usage : enableServices <ARMSTRAP_ROOT>
function enableServices {
  printStatus "disableServices" "Enabling services startup"
  rm -f ${1}/usr/sbin/policy-rc.d
}

# usage ubuntuStrap <ARMSTRAP_ROOT> <ARCH> <EABI> <VERSION>
function ubuntuStrap {
  printStatus "ubuntuStrap" "Fetching and extracting ubuntu-core-${4}-core-${2}${3}.tar.gz"
  wget -q -O - http://cdimage.ubuntu.com/ubuntu-core/releases/${4}/release/ubuntu-core-${4}-core-${2}${3}.tar.gz | tar -xz -C ${1}/
  
  installQEMU ${1} ${2}
  disableServices ${1}
  mountPFS ${1}
}

# Usage : insResolver <ARMSTRAP_ROOT>
function insResolver {
  printStatus "insResolver" "Setting up temporary resolver"
  mv ${1}/etc/resolv.conf ${1}/etc/resolv.conf.orig
  cp /etc/resolv.conf ${1}/etc/resolv.conf
}

# Usage : insDialog <ARMSTRAP_ROOT>
function insDialog {
  printStatus "insDialog" "Installing apt-utils and Dialog frontend"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install apt-utils dialog>> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : ubuntuLocales <ARMSTRAP_ROOT> <LOCALE1> [<LOCALE2> ...]
# The first locale will be the default one.
function ubuntuLocales {
  local TMP_ROOT=${1}
  shift
  
  printStatus "ubuntuLocales" "Configuring locales ${@}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ locale-gen ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "ubuntuLocales" "Setting default locale to ${1}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ update-locale LANG=${1} LC_MESSAGES=POSIX >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : clnResolver <ARMSTRAP_ROOT>
function clnResolver {
  printStatus "clnResolver" "Restoring original resolver"
  rm -f ${1}/etc/resolv.conf
  mv ${1}/etc/resolv.conf.orig ${1}/etc/resolv.conf
}

# usage bootStrap <ARMSTRAP_ROOT> <ARCH> <EABI> <SUITE> [<MIRROR>]
function bootStrap {
  if [ $# -eq 4 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${2}${3} ${4}"
    debootstrap --foreign --arch ${2}${3} ${4} ${1}/ >> ${ARMSTRAP_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  elif [ $# -eq 5 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${2}${3} ${4} using mirror ${5}"
    debootstrap --foreign --arch ${2}${3} ${4} ${1}/ ${5} >> ${ARMSTRAP_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  else
    checkStatus "bootStrap need 3 or 4 arguments."
  fi
  
  installQEMU ${1} ${2}
  disableServices ${1}
  mountPFS ${1}

  printStatus "bootStrap" "Running debootstrap --second-stage"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /debootstrap/debootstrap --second-stage >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "debootstrap --second-stage failed with status ${?}"

  printStatus "bootStrap" "Running dpkg --configure -a"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/dpkg --configure -a >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "dpkg --configure failed with status ${?}"
}

# Usage : setHostName <ARMSTRAP_ROOT> <HOSTNAME>
function setHostName {
  printStatus "buildRoot" "Configuring /etc/hostname"
  echo "${2}" > ${1}/etc/hostname
}

# Usage : clearSources <ARMSTRAP_ROOT>
function clearSourcesList {
  printStatus "clearSources" "Removing current sources list"
  rm -f ${1}/etc/apt/sources.list
  touch ${1}/etc/apt/sources.list
}

# Usage : addSource <ARMSTRAP_ROOT> <URI> <DIST> <COMPONENT1> [<COMPONENT2> ...]
function addSource {
  local TMP_ROOT="${1}"
  shift
  
  printStatus "addSource" "Adding ${@} to the sources list"
  echo "deb ${@}" >> ${TMP_ROOT}/etc/apt/sources.list
  echo "deb-src ${@}" >> ${TMP_ROOT}/etc/apt/sources.list
  echo "" >> ${TMP_ROOT}/etc/apt/sources.list
}

# Usage : initSources <ARMSTRAP_ROOT>
function initSources {
  printStatus "initSources" "Updating sources list"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get -q -y update >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "initSources" "Updating Packages"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get -q -y upgrade >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : mountProcs <ARMSTRAP_ROOT>
function mountPFS {
  printStatus "mountPFS" "Mounting procfs"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ mount -t proc proc /proc
  printStatus "mountPFS" "Mounting sysfs"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ mount -t sysfs sysfs /sys
  printStatus "mountPFS" "Binding /dev/pts"
  mount --bind /dev/pts ${1}/dev/pts
}

# Usage : umountProcs <ARMSTRAP_ROOT>
function umountPFS {
  printStatus "umountPFS" "Unmounting procfs"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ umount /proc
  printStatus "umountPFS" "Unounting sysfs"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ umount /sys
  printStatus "umountPFS" "Unbinding /dev/pts"
  umount ${1}/dev/pts
}

# Usage : installTasks <ARMSTRAP_ROOT> <TASK1> [<TASK2> ...]
function installTasks {
  local TMP_ROOT=${1}
  shift
  
  printStatus "installTasks" "Installing tasks ${@}"
  for i in ${@}; do
    printStatus "installTask" "Running dpkg --configure -a"
    LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/dpkg --configure -a >> ${ARMSTRAP_LOG_FILE} 2>&1
    
    printStatus "installTask" "Updating Packages"
    LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/apt-get -q -y upgrade >> ${ARMSTRAP_LOG_FILE} 2>&1

    LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/tasksel --new-install install ${i}
  done
}

# Usage : installPackages <ARMSTRAP_ROOT> <PKG1> [<PKG2> ...]
function installPackages {
  local TMP_ROOT=${1}
  shift
  
  printStatus "installPackages" "Installing ${@}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install ${@} 2>> ${ARMSTRAP_LOG_FILE}
}

# Usage : installDPKG <ARMSTRAP_ROOT> <PACKAGE_FILE>
function installDPKG {
  local TMP_ROOT="${1}"
  local TMP_DIR=`mktemp -d ${TMP_ROOT}/DPKG.XXXXXX`
  local TMP_CHR=`basename ${TMP_DIR}`
  local TMP_DEB=`basename ${2}`

  printStatus "installDPKG" "Installing ${TMP_DEB}"
  cp ${2} ${TMP_DIR}/${TMP_DEB}
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/dpkg -i /${TMP_CHR}/${TMP_DEB} >> ${ARMSTRAP_LOG_FILE} 2>&1
  rm -rf ${TMP_DIR}
}

# Usage : configPackages <ARMSTRAP_ROOT> <PKG1> [<PKG2> ...]
function configPackages {
  local TMP_ROOT=${1}
  shift

  printStatus "configPackages" "Configuring ${@}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/sbin/dpkg-reconfigure ${@}
}

# Usage : setRootPassword <ARMSTRAP_ROOT> <PASSWORD>
function setRootPassword {
  printStatus "setRootPassword" "Configuring root password"
  chroot ${1}/ /usr/bin/passwd root <<EOF > /dev/null 2>&1
${2}
${2}

EOF
}

# Usage : addInitTab <ARMSTRAP_ROOT> <ID> <RUNLEVELS> <DEVICE> <SPEED> <TYPE>
function addInitTab {
  printStatus "addInitTab" "Configuring terminal ${2} for runlevels ${3} on device ${4} at ${5}bps (${6})"
  printf "%s:%s:respawn:/sbin/getty -L %s %s %s\n" ${2} ${3} ${4} ${5} ${6} >> ${1}/etc/inittab
}

# Usage addTT <ARMSTRAP_ROOT> <RUNLEVELS> <DEVICE> <SPEED> <TYPE>
function addTTY {
  local TMP_FILE="${1}/etc/init/${3}.conf"
  printStatus "addTTY" "Configuring terminal ${3} for runlevels ${2} at ${4} (${5})"
  printf "# %s - getty\n" "${3}" > ${TMP_FILE}
  printf "# This service maintains a getty on ttyS0 from the point the system is started until it is shut down again.\n\n" >> ${TMP_FILE} 
  printf "start on stopped rc or RUNLEVEL=[%s]\n" "${2}" >> ${TMP_FILE} 
  printf "stop on runlevel [!2345]\n\n" "${2}" >> ${TMP_FILE} 
  printf "respawn\nexec /sbin/getty -L %s %s %s\n" "${4}" "${3}" "${5}" >> ${TMP_FILE} 
}

# Usage : initFSTab <ARMSTRAP_ROOT>
function initFSTab {
  printStatus "initFSTab" "Initializing fstab"
  printf "%- 20s% -15s%- 10s%- 15s%- 8s%- 8s\n" "#<file system>" "<mount point>" "<type>" "<options>" "<dump>" "<pass>" > ${1}/etc/fstab
}

# Usage : addFSTab <ARMSTRAP_ROOT> <file system> <mount point> <type> <options> <dump> <pass>
function addFSTab {
  printStatus "addFSTab" "Device ${2} will be mount as ${3}"
  printf "%- 20s% -15s%- 10s%- 15s%- 8s%- 8s\n" ${2} ${3} ${4} ${5} ${6} ${7} >>${1}/etc/fstab
}

# Usage : addKernelModules <ARMSTRAP_ROOT> <KERNEL MODULE> [<COMMENT>]
function addKernelModule {
  local TMP_ROOT=${1}
  shift
  local TMP_MODULE=${1}
  shift
  
  printStatus "addModule" "Configuring kernel module ${1}"
  if [ ! -z "${@}" ]; then
    shift
    echo "# ${@}" >> ${TMP_ROOT}/etc/modules
  fi
  
  printf "%s\n" ${TMP_MODULE} >> ${TMP_ROOT}/etc/modules
}

# Usage : addIface <ARMSTRAP_ROOT> <INTERFACE> <dhcp|static> [<address> <netmask> <gateway>]
function addIface {
  local TMP_ROOT="${1}"
  shift
  
  printStatus "addIface" "Configuring interface ${1}"
  printf "auto %s\n" ${1} >> ${TMP_ROOT}/etc/network/interfaces
  printf "allow-hotplug %s\n\n" ${1} >> ${TMP_ROOT}/etc/network/interfaces
  printf "iface %s inet %s\n" ${1} ${2} >> ${TMP_ROOT}/etc/network/interfaces
  if [ "${2}" != "dhcp" ]; then
    printStatus "addIface" "IP address : ${3}/${4}, default gateway ${5}"
    printf "  address %s\n" ${3} >> ${TMP_ROOT}/etc/network/interfaces
    printf "  netmask %s\n" ${4} >> ${TMP_ROOT}/etc/network/interfaces
    printf "  gateway %s\n\n" ${5} >> ${TMP_ROOT}/etc/network/interfaces
  else
    printStatus "addIface" "IP address : DHCP"
    printf "\n" >> ${TMP_ROOT}/etc/network/interfaces
  fi
}

# Usage : initResolvConf <ARMSTRAP_ROOT>
function initResolvConf {
  printStatus "initResolvConf" "Initializing resolv.conf"
  rm -f ${1}/etc/resolv.conf
  touch ${1}/etc/resolv.conf
}

# Usage : addSearchDomain <ARMSTRAP_ROOT> <DOMAIN>
function addSearchDomain {
  printf "addSearchDomain" "Configuring search domain to ${2}"
  printf "search %s\n" ${2} >> ${1}/etc/resolv.conf
}

# Usage : addNameServer <ARMSTRAP_ROOT> <NS1> [<NS2> ... ]
function addNameServer {
  local TMP_ROOT=${1}
  shift
  
  for i in ${@}; do
    printStatus "addNameServer" "Configuring dns server ${i}"
    printf "nameserver %s\n" ${i} >> ${TMP_ROOT}/etc/resolv.conf
  done
}


# Usage : bootClean <ARMSTRAP_ROOT> <ARCH>
function bootClean {
  printStatus "bootClean" "Running aptitude update"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/aptitude -y update >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running aptitude clean"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/aptitude -y clean  >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running apt-get clean"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get clean >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  installInit ${1}
  umountPFS ${1}
  removeQEMU ${1} ${2}
  enableServices ${1}
}

# Usage : installInit <ARMSTRAP_ROOT>
function installInit {

  if [ -d "${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/init.d" ]; then
    for i in ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/init.d/*.sh; do
      local TMP_FNAME="`basename ${i}`"
      printStatus "installInit" "Installing init script ${TMP_FNAME}"
      cp ${i} ${1}/etc/init.d/
      chmod 755 ${1}/etc/init.d/${TMP_FNAME}
      LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/sbin/update-rc.d ${TMP_FNAME} defaults
    done
  fi
}
