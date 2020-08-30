#!/usr/bin/env bash

setup_system()
{
    # Change the timezone.
    sudo unlink /etc/localtime && sudo ln -s /usr/share/zoneinfo/Europe/Brussels /etc/localtime

    # Upgrade the system.
    sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y

    # Change the DNS servers.
    sudo apt install -y resolvconf
    cat /dev/null | sudo tee /etc/resolvconf/resolv.conf.d/head
    echo 'nameserver 1.1.1.1' | sudo tee -a /etc/resolvconf/resolv.conf.d/head
    echo 'nameserver 1.0.0.1' | sudo tee -a /etc/resolvconf/resolv.conf.d/head
    sudo systemctl enable --now resolvconf.service

    # Reduce the swap usage.
    if ! grep -Fxq 'vm.swappiness=10' /etc/sysctl.conf; then
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    fi

    # Put the /tmp and /var/tmp folders in RAM.
    if ! grep -Fxq 'tmpfs /tmp tmpfs defaults,mode=1777,nosuid,size=4196M 0 0' /etc/fstab; then
        echo '' | sudo tee -a /etc/fstab
        echo 'tmpfs /tmp tmpfs defaults,mode=1777,nosuid,size=4196M 0 0' | sudo tee -a /etc/fstab
        echo 'tmpfs /var/tmp tmpfs defaults,mode=1777,nosuid,size=4196M 0 0' | sudo tee -a /etc/fstab
    fi

    # Install useful packages.
    sudo apt install -y curl jq

    # Remove useless packages.
    sudo apt purge --auto-remove -y apport apport-gtk popularity-contest ubuntu-report

    # Bluetooth is a security nightmare, so turn off the service.
    sudo systemctl disable bluetooth.service

    # I don't use a PSTN/RTC modem anymore, so turn off the service.
    sudo systemctl disable ModemManager.service

    # Do not wait until the network is available to display the login window.
    sudo systemctl disable NetworkManager-wait-online.service

    # Enable the TRIM service for SSD.
    sudo systemctl enable --now fstrim.timer

    # Hide the dummy snap directory by default.
    echo 'snap' | tee -a "${HOME}/.hidden"
}

setup_gnome()
{
    # Center new windows.
    gsettings set org.gnome.mutter center-new-windows true

    # Enable animations.
    gsettings set org.gnome.desktop.interface enable-animations true

    # Enable and configure night light.
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000

    # Enable sound over-amplification.
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

    # Disable the system auto lock screensaver.
    gsettings set org.gnome.desktop.screensaver lock-enabled false

    # Remove home and trash icons from desktop.
    gsettings set org.gnome.shell.extensions.desktop-icons show-home false
    gsettings set org.gnome.shell.extensions.desktop-icons show-trash false

    # Make fonts little bit smaller.
    gsettings set org.gnome.desktop.interface font-name 'Ubuntu 10'
    gsettings set org.gnome.desktop.interface document-font-name 'Sans 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 12'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 10'
    gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

    # Change the default zoom level in nautilus.
    gsettings set org.gnome.nautilus.icon-view default-zoom-level 'large'

    # Pin my favorite applications.
    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'chromium.desktop', 'firefox.desktop', 'jdownloader2_JDownloader.desktop', 'org.qbittorrent.qBittorrent.desktop', 'postman.desktop', 'vmware-workstation.desktop', 'org.gnome.Terminal.desktop', 'codium.desktop', 'dbeaver.desktop', 'mpv.desktop']"

    # Install the papirus-icon-theme package.
    sudo add-apt-repository -y ppa:papirus/papirus-dev
    sudo apt install -y papirus-icon-theme
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus'

    # Configure the dash-to-dock extension.
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32

    # Install the p7zip-full and unrar packages.
    sudo apt install -y p7zip-full unrar

    # Set fileroller as default program to handle archive files.
    xdg-mime default 'org.gnome.FileRoller.desktop' application/x-7z-compressed application/x-7z-compressed-tar \
        application/x-ace application/x-alz application/x-ar application/x-arj application/x-bzip \
        application/x-bzip-compressed-tar application/x-bzip1 application/x-bzip1-compressed-tar application/x-cabinet \
        application/x-cd-image application/x-compress application/x-compressed-tar application/x-cpio application/x-deb \
        application/x-ear application/x-ms-dos-executable application/x-gtar application/x-gzip \
        application/x-gzpostscript application/x-java-archive application/x-lha application/x-lhz application/x-lrzip \
        application/x-lrzip-compressed-tar application/x-lz4 application/x-lzip application/x-lzip-compressed-tar \
        application/x-lzma application/x-lzma-compressed-tar application/x-lzop application/x-lz4-compressed-tar \
        application/x-lzop-compressed-tar application/x-ms-wim application/x-rar application/x-rar-compressed \
        application/x-rpm application/x-source-rpm application/x-rzip application/x-rzip-compressed-tar \
        application/x-tar application/x-tarz application/x-stuffit application/x-war application/x-xz \
        application/x-xz-compressed-tar application/x-zip application/x-zip-compressed application/x-zoo application/zip \
        application/x-archive application/vnd.ms-cab-compressed application/vnd.debian.binary-package application/gzip
}

setup_anaconda()
{
    sudo mkdir -p /opt/anaconda
    sudo chown -R $USER:$USER /opt/anaconda
    address='https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh'
    script="$(mktemp -d)/$(basename ${address})"
    curl -A 'Mozilla/5.0 (Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0' -L "${address}" -o "${script}"
    bash "${script}" -b -p /opt/anaconda -u
    sudo ln -s /opt/anaconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
    source /etc/profile
    conda update --all -y
    conda config --set auto_activate_base false
    conda install -c conda-forge -y pipenv
}

setup_dbeaver()
{
    sudo add-apt-repository -y ppa:serge-rider/dbeaver-ce
    sudo apt install -y dbeaver-ce
    sudo sed -i 's/Icon=.*/Icon=dbeaver/' /usr/share/applications/dbeaver.desktop
}

setup_docker()
{
    curl -fsSL 'https://download.docker.com/linux/ubuntu/gpg' | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt install -y containerd.io docker-ce docker-ce-cli
    sudo usermod -aG docker "${USER}"
}

setup_docker_compose()
{
    version=$(curl -s 'https://api.github.com/repos/docker/compose/releases' | jq -r '.[0].tag_name')
    address="https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)"
    sudo curl -A 'Mozilla/5.0 (Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0' -L "${address}" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    address="https://raw.githubusercontent.com/docker/compose/${version}/contrib/completion/bash/docker-compose"
    sudo curl -A 'Mozilla/5.0 (Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0' -L "${address}" -o /etc/bash_completion.d/docker-compose
}

setup_firefox()
{
    sudo add-apt-repository -y ppa:mozillateam/firefox-next
    sudo apt install -y firefox
}

setup_git()
{
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt install -y git
    git config --global credential.helper 'cache --timeout=21600'
    git config --global user.email 'anonymous@example.com'
    git config --global user.name 'anonymous'
}

setup_jdownloader()
{
    sudo snap install jdownloader2
    sudo sed -i "s/Icon=.*/Icon=jdownloader/g" /var/lib/snapd/desktop/applications/jdownloader2_JDownloader.desktop
    settings="${HOME}/snap/jdownloader2/common/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
    jdownloader2.jdownloader > /dev/null 2>&1 &
    sleep 5 && while [ ! -f "${settings}" ]; do sleep 2; done
    pkill -f 'java -jar' && sleep 5
    jdownloader2.jdownloader > /dev/null 2>&1 &
    sleep 5 && pkill -f 'java -jar' && sleep 5
    sed -i "s/\"bannerenabled\".*/\"bannerenabled\" : false,/g" "${settings}"
    sed -i "s/\"myjdownloaderviewvisible\".*/\"myjdownloaderviewvisible\" : false,/g" "${settings}"
    sed -i "s/\"speedmetervisible\".*/\"speedmetervisible\" : false,/g" "${settings}"
}

setup_mpv()
{
    sudo add-apt-repository -y ppa:mc3man/mpv-tests
    sudo apt install -y mpv
    desktop='/usr/share/applications/mpv.desktop'
    sudo sed -i "s/Name=.*/Name=Mpv/g" "${desktop}"
    if grep -Fxq "[Desktop Action Help]" "${desktop}"; then head -n -53 "${desktop}" | sudo tee "${desktop}.tmp" && sudo mv "${desktop}.tmp" "${desktop}" fi
    settings="$HOME/.config/mpv/mpv.conf"
    mkdir -p "$(dirname "${settings}")" && cat /dev/null > "${settings}"
    echo 'profile=gpu-hq' | tee -a "${settings}"
    echo 'hwdec=auto' | tee -a "${settings}"
    echo 'interpolation=yes' | tee -a "${settings}"
    echo 'keep-open=yes' | tee -a "${settings}"
    echo 'tscale=oversample' | tee -a "${settings}"
    echo 'video-sync=display-resample' | tee -a "${settings}"
    echo 'ytdl-format="bestvideo[height<=?1080][vcodec!=vp9]+bestaudio/best"' | tee -a "${settings}"
}

setup_node()
{
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt install -y build-essential nodejs
}

setup_postman()
{
    sudo add-apt-repository -y ppa:tiagohillebrandt/postman
    sudo apt install -y postman
    sudo sed -i 's/Icon=.*/Icon=postman/' /usr/share/applications/postman.desktop
    if ! grep -Fxq 'Postman' "${HOME}/.hidden"; then echo 'Postman' | tee -a "${HOME}/.hidden" fi
}

setup_qbittorrent()
{
    sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
    sudo apt install -y qbittorrent
}

setup_ungoogled_chromium()
{
    curl -fsSL "https://download.opensuse.org/repositories/home:ungoogled_chromium/Ubuntu_Focal/Release.key" | sudo apt-key add -
    echo "deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /" | sudo tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
    sudo apt update && sudo apt install -y ungoogled-chromium
}

setup_vmware_workstation()
{
    sudo apt install -y build-essential
    address="https://www.vmware.com/go/getworkstation-linux"
    package="$(mktemp -d)/VMware-Workstation-Full-Latest.x86_64.bundle"
    serials='YZ718-4REEQ-08DHQ-JNYQC-ZQRD0'
    curl -A 'Mozilla/5.0 (Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0' -L "${address}" -o "${package}"
    chmod a+x "${package}"
    sudo "${package}" --console --eulas-agreed --required --set-setting vmware-workstation serialNumber "${serials}"
    version=$(curl -s 'https://api.github.com/repos/paolo-projects/auto-unlocker/releases' | jq -r '.[0].tag_name' | tr -d 'v')
    address="https://github.com/paolo-projects/auto-unlocker/releases/download/v${version}/autounlocker_${version}_amd64.deb"
    package="$(mktemp -d)/$(basename ${address})"
    curl -A 'Mozilla/5.0 (Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0' -L "${address}" -o "${package}"
    chmod +x "${package}" && sudo apt install -y "${package}"
    sudo mkdir -p /opt/auto-unlocker
    sudo chown -R $USER:$USER /opt/auto-unlocker
    cd /opt/auto-unlocker && sudo auto-unlocker --install
    cd "${HOME}"
}

setup_vscodium()
{
    curl -s https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo apt-key add -
    echo 'deb https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/repos/debs/ vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
    sudo apt update && sudo apt install -y codium
    sudo sed -i 's/Icon=.*/Icon=vscodium/' /usr/share/applications/codium.desktop
    codium --install-extension github.github-vscode-theme
    settings="${HOME}/.config/VSCodium/User/settings.json"
    mkdir -p "$(dirname "${settings}")" && cat /dev/null > "${settings}"
    echo '{' | tee -a "${settings}"
    echo '    "editor.fontFamily": "Ubuntu Mono, monospace",' | tee -a "${settings}"
    echo '    "editor.fontSize": 16,' | tee -a "${settings}"
    echo '    "editor.lineHeight": 30,' | tee -a "${settings}"
    echo '    "window.menuBarVisibility": "toggle",' | tee -a "${settings}"
    echo '    "workbench.colorTheme": "GitHub Dark"' | tee -a "${settings}"
    echo '}' | tee -a "${settings}"
}

setup_youtube_dl()
{
    sudo apt install -y python-is-python3
    sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
    sudo chmod a+rx /usr/local/bin/youtube-dl
}

main()
{
    echo 'Installing and configuring the system...'
    setup_system > /dev/null 2>&1

    echo 'Installing and configuring git...'
    setup_git > /dev/null 2>&1

    echo 'Installing and configuring anaconda...'
    setup_anaconda > /dev/null 2>&1

    echo 'Installing and configuring dbeaver...'
    setup_dbeaver > /dev/null 2>&1

    echo 'Installing and configuring docker...'
    setup_docker > /dev/null 2>&1

    echo 'Installing and configuring docker-compose...'
    setup_docker_compose > /dev/null 2>&1

    echo 'Installing and configuring node...'
    setup_node > /dev/null 2>&1

    echo 'Installing and configuring postman...'
    setup_postman > /dev/null 2>&1

    echo 'Installing and configuring vscodium...'
    setup_vscodium > /dev/null 2>&1

    echo 'Installing and configuring ungoogled-chromium...'
    setup_ungoogled_chromium > /dev/null 2>&1

    echo 'Installing and configuring firefox...'
    setup_firefox > /dev/null 2>&1

    echo 'Installing and configuring jdownloader...'
    setup_jdownloader > /dev/null 2>&1

    echo 'Installing and configuring qbittorrent...'
    setup_qbittorrent > /dev/null 2>&1

    echo 'Installing and configuring mpv...'
    setup_mpv > /dev/null 2>&1

    echo 'Installing and configuring youtube-dl...'
    setup_youtube_dl > /dev/null 2>&1

    echo 'Installing and configuring gnome...'
    setup_gnome > /dev/null 2>&1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main fi
