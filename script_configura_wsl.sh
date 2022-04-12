#!/bin/bash

# Para que no pida password a los usuarios que esten en el grupo sudo
sudo sed -i 's/^%sudo.*/%sudo   ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

# Cambiar nombre de maquina wsl
nombre_maquina=ubuntu-wsl
sudo sed -i "s/$HOSTNAME/$nombre_maquina/g" /etc/hosts

# Otra forma de cambiar nombre de la maquina pero NO funciona en WSL
#hostnamectl set-hostname $nombre_maquina

# Permita los 2 tipos de acceso
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo service sshd restart

# Configurar archivo principal de WSL
sudo cat <<EOF | sudo tee /etc/wsl.conf
[network]
hostname = $nombre_maquina
generateHosts = false
#generateResolvConf = false
[user]
default = $USER
EOF

#Crear par de llaves (privada y publica)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N ""

# Cambiar time zone
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Cambiar password a root
echo "root:123" | sudo chpasswd

# Desactivar Firewall
sudo ufw disable

# Instalar herramientas basicas
sudo apt update -y && sudo apt upgrade -y
sudo apt install tldr tmux vim git tree htop unzip wget curl -y

# Instalar shell ZSH y cambiar de shell Bash a ZSH
sudo apt install zsh -y
sudo chsh -s $(which zsh)

# Instalar OhMyZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Instalar nuevo Tema Powerlevel10k
sudo git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sudo sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

# Instalar Auto-sugerencias y Highlighting para ZSH
sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Configurar Plugins en ZSH, es decir, Auto-sugerencias, Highlighting y Docker Compose
sudo sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# Crear usuario para Docker
usuario2=dockeradmin
sudo useradd -U $usuario2 -m -s /bin/bash -G sudo
echo "$usuario2:123" | sudo chpasswd
echo "$usuario2 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# Instalar Docker
sudo apt update -y && sudo apt upgrade -y
sudo apt remove docker docker.io containerd runc -y
sudo apt install ca-certificates curl gnupg lsb-release apt-transport-https -y
sudo apt autoremove -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y && sudo apt upgrade -y
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo service docker start
sudo usermod -aG docker $USER
sudo usermod -aG docker $usuario2

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose \
    -o /etc/bash_completion.d/docker-compose

# Instalar lc
sudo apt install ruby-full gcc make -y
sudo gem install colorls
source $(dirname $(gem which colorls))/tab_complete.sh

# Instalar lx
EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
sudo unzip -q exa.zip bin/exa -d /usr/local
rm -rf exa.zip

# Configurar alias
mkdir -p ~/ps/
cd ~/ps/
git clone https://github.com/jvinc86/alias-ubuntu.git
cp ~/.zshrc ~/.zshrc-backup
source ~/ps/alias-ubuntu/alias.sh
