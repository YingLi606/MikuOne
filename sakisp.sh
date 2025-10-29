#!/bin/bash

# 版本号定义
CURRENT_VERSION="V15.0.0"
GITEE_REPO="https://gh.xmly.dev/https://github.com/YingLi606/SakiSP"

# 动态获取当前脚本路径（用户环境适配版）
if [ -L "$0" ]; then
    # 处理符号链接
    LOCAL_SCRIPT_PATH=$(readlink "$0")
else
    # 普通文件路径
    LOCAL_SCRIPT_PATH="$0"
fi
# 转换为绝对路径
LOCAL_SCRIPT_PATH=$(cd "$(dirname "$LOCAL_SCRIPT_PATH")" && pwd)/$(basename "$LOCAL_SCRIPT_PATH")

# 自动识别用户安装路径（关键修改）
if [ "$(id -u)" -eq 0 ]; then
    # root用户使用系统路径
    SYSTEM_INSTALL_PATH="/usr/games/sakisp"
else
    # 普通用户使用主目录路径
    SYSTEM_INSTALL_PATH="$HOME/.local/bin/sakisp"
fi

# 确保用户安装目录存在
mkdir -p "$(dirname "$SYSTEM_INSTALL_PATH")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'  
BLUE='\033[0;34m'     
PINK='\033[1;35m'    
LIGHT_BLUE='\033[1;34m'
WHITE='\033[1;37m'
RESET='\033[0m'

# 获取系统信息
get_system_info() {
  [ -x "$(command -v lsb_release)" ] && system_name=$(lsb_release -is) || {
    [ -f "/etc/os-release" ] && . /etc/os-release && system_name="$NAME" || system_name="Linux"
  }
  echo "$system_name"
}

show_launch_animation() {
  show_sakisp_art
  
  # 系统信息（零间隔显示）
  system_info=$(get_system_info)
  echo -e "${YELLOW}系统信息：${CYAN}${system_info}${NC}\n"
  
  read -n 1 -s -r -p "✨按任意键启动....."
  clear

    # 阶段2：色彩进度条（优化版）
    echo -e "\n\n    ${CYAN}🔍 正在初始化系统环境...${RESET}\n"

    tasks=("加载主题资源" "验证核心组件" "检查依赖项" "同步配置" "准备界面")

    # 进度条宽度
    bar_width=40
    
    for ((i=0; i<=100; i++)); do
        task_idx=$((i/20))
        # 计算填充和空白部分
        filled=$((i * bar_width / 100))
        empty=$((bar_width - filled))
        
        # 颜色渐变（从蓝色到粉色）
        color_step=$((i * 5 / 100))  # 0-5对应颜色变化
        
        printf "\r    ${BLUE}[${RESET}"
        # 填充部分（渐变效果）
        for ((j=0; j<filled; j++)); do
            # 计算每个位置的颜色
            pos_color=$((117 + j * 5 / bar_width))
            printf "\e[38;5;${pos_color}m▓${RESET}"
        done
        # 空白部分
        for ((j=0; j<empty; j++)); do
            printf "${BLUE}░${RESET}"
        done
        printf "${BLUE}]${RESET} ${YELLOW}%3d%%${RESET} ${tasks[$task_idx]}" $i
        
        # 动画速度控制
        if ((i < 30 || i > 70)); then
            sleep 0.05
        else
            sleep 0.03
        fi
    done
    echo -e "\n"


    # 阶段3：樱花绽放动画
    echo -e "        ${GREEN}✧ 准备就绪！✧${RESET}\n"

    sakura=("🌸" "❀" "💮" "🌼")
    for ((s=0; s<6; s++)); do
        printf "%*s" $((20 - s)) ""
        for ((i=0; i<s*2+1; i++)); do
            printf "${PINK}${sakura[i%4]}${RESET} "
        done
        echo -e "\n"
        sleep 0.2
    done

    echo -e "        ${WHITE}即将进入 SakiSP...${RESET}"
    sleep 1.2
    clear
}

show_sakisp_art() {
     # 生成 "sakisp" 艺术字并彩虹色输出
     figlet "SakiSP" | lolcat
     sleep 1
     # 输出版本边框（保持原样式）
     echo -e "${CYAN}■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■${RESET}"
     echo -e "${RED}▶${YELLOW}▶${GREEN}▶${CYAN}      SakiSP V15.0.0      ${GREEN}◀${YELLOW}◀${RED}◀${RESET}"
     echo -e "${CYAN}■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■${RESET}\n"
}
 
# 2. 全自动依赖安装函数（原有功能）
install_deps() {
    local deps=("whiptail" "wget" "lolcat" "figlet" "jq" "unzip")  
    local missing=()
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local RESET='\033[0m'
    local has_installed=0

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    if ! dpkg -s fonts-noto-color-emoji &>/dev/null; then
        missing+=("fonts-noto-color-emoji")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        clear
        echo -e "${RED}⚠ 正在安装缺失的基础依赖: ${missing[*]} ${RESET}"
        if ! command -v aria2c &> /dev/null; then
            sudo apt install aria2 -y
            has_installed=1
        fi     
        if ! sudo apt update; then
            whiptail --title "错误" --msgbox "apt update 失败，请检查网络连接。" 10 60
            echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
            read -r
            exit 1
        fi
        if ! sudo apt install -y "${missing[@]}"; then
            whiptail --title "错误" --msgbox "基础依赖安装失败。" 10 60
            echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
            read -r
            exit 1
        fi
        echo -e "${GREEN}✅ 基础依赖安装完成${RESET}"
        has_installed=1
        sleep 3
    fi

    clear
    echo -e "${BLUE}🔍 检查Node.js与npm环境...${RESET}"
    sleep 3

    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}ℹ 未检测到Node.js/npm，开始安装...${RESET}"
        sleep 3
        if ! curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; then
            whiptail --title "错误" --msgbox "nodesource源配置失败，请检查网络。" 10 60
            echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
            read -r
            exit 1
        fi
        if ! sudo apt install -y nodejs; then
            whiptail --title "错误" --msgbox "Node.js安装失败，请检查APT源。" 10 60
            echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
            read -r
            exit 1
        fi
        echo -e "${GREEN}✅ Node.js与npm安装完成${RESET}"
        has_installed=1
    else
        echo -e "${GREEN}✅ 已检测到Node.js/npm，跳过安装${RESET}"
    fi
    sleep 3

    echo -e "${BLUE}🔧 检查npm源配置...${RESET}"
    sleep 3
    if ! npm config get registry | grep -q "npmmirror.com"; then
        if ! npm config set registry https://registry.npmmirror.com/; then
            whiptail --title "错误" --msgbox "npm源更换失败，请检查npm环境。" 10 60
            echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
            read -r
            exit 1
        fi
        echo -e "${GREEN}✅ npm源已更换为国内镜像${RESET}"
        has_installed=1
    else
        echo -e "${GREEN}✅ npm已配置国内源，跳过设置${RESET}"
    fi
    sleep 3

    echo -e "${BLUE}📥 检查字符画工具...${RESET}"
    sleep 3
    local tool_installed=0

    if ! command -v aecat &> /dev/null; then
        echo -e "${YELLOW}ℹ 未检测到aecat，尝试npm安装...${RESET}"
        sleep 3
        if sudo npm install -g aecat; then
            echo -e "${GREEN}✅ aecat安装完成${RESET}"
            tool_installed=1
            has_installed=1
        else
            echo -e "${RED}❌ aecat安装失败，尝试安装aewan...${RESET}"
            sleep 3
            if sudo apt install -y aewan; then
                echo -e "${GREEN}✅ aewan安装完成${RESET}"
                tool_installed=1
                has_installed=1
            else
                whiptail --title "错误" --msgbox "aecat和aewan均安装失败！请检查网络。" 10 60
                echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
                read -r
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}✅ 已检测到aecat，跳过安装${RESET}"
        tool_installed=1
    fi
    sleep 3

    if [ $tool_installed -eq 1 ]; then
        echo -e "${GREEN}🎉 所有依赖配置完成！${RESET}"
        sleep 1
        clear
    else
        echo -e "${RED}❌ 字符画工具安装失败，流程终止${RESET}"
        echo -e "${YELLOW}ℹ 按回车键退出...${RESET}"
        read -r
        exit 1
    fi
    sleep 2
}

# 安装到系统路径函数（带错误处理）
install_to_system_path() {
    is_kali() {
        if [ -f "/etc/os-release" ]; then
            . /etc/os-release
            [ "$ID" = "kali" ] && return 0
        fi
        return 1
    }

    if [ ! -f "$LOCAL_SCRIPT_PATH" ]; then
        echo -e "${RED}❌ 错误：源脚本文件不存在 - $LOCAL_SCRIPT_PATH${RESET}"
        return 1
    fi

    # 按系统类型+用户身份区分安装路径
    if is_kali; then
        if [ "$(id -u)" -eq 0 ]; then
            # Kali纯root用户：安装到/usr/local/bin
            SYSTEM_INSTALL_PATH="/usr/local/bin/sakisp"
            PATH_DIR="/usr/local/bin"
        else
            # Kali普通用户：安装到用户级路径$HOME/.local/bin
            SYSTEM_INSTALL_PATH="$HOME/.local/bin/sakisp"
            PATH_DIR="$HOME/.local/bin"
        fi
    else
        if [ "$(id -u)" -eq 0 ]; then
            # 非Kali纯root用户：安装到/usr/games
            SYSTEM_INSTALL_PATH="/usr/games/sakisp"
            PATH_DIR="/usr/games"
        else
            # 非Kali普通用户：安装到用户级路径$HOME/.local/bin
            SYSTEM_INSTALL_PATH="$HOME/.local/bin/sakisp"
            PATH_DIR="$HOME/.local/bin"
        fi
    fi
    BASHRC_PATH="$HOME/.bashrc"
    
    if [ ! -f "$SYSTEM_INSTALL_PATH" ] || [ "$LOCAL_SCRIPT_PATH" -nt "$SYSTEM_INSTALL_PATH" ]; then
        pretty_print "INSTALLING" "正在将脚本安装到路径 $SYSTEM_INSTALL_PATH..."
        
        # 系统级路径（/usr/*）需sudo，用户级路径无需
        if [[ "$SYSTEM_INSTALL_PATH" == /usr/* ]]; then
            sudo mkdir -p "$(dirname "$SYSTEM_INSTALL_PATH")"
            if sudo cp "$LOCAL_SCRIPT_PATH" "$SYSTEM_INSTALL_PATH"; then
                sudo chmod +x "$SYSTEM_INSTALL_PATH"
            else
                INSTALL_FAILED=1
            fi
        else
            mkdir -p "$(dirname "$SYSTEM_INSTALL_PATH")"
            if cp "$LOCAL_SCRIPT_PATH" "$SYSTEM_INSTALL_PATH"; then
                chmod +x "$SYSTEM_INSTALL_PATH"
            else
                INSTALL_FAILED=1
            fi
        fi
        
        if [ -z "$INSTALL_FAILED" ]; then
            if ! echo "$PATH" | grep -q "$PATH_DIR"; then
                echo "export PATH=\"$PATH_DIR:\$PATH\"" >> "$BASHRC_PATH"
                source "$BASHRC_PATH"
                echo -e "${GREEN}已将 $PATH_DIR 添加到PATH环境变量${RESET}"
            else
                echo -e "${CYAN}✔ $PATH_DIR 已在PATH环境变量中，无需重复添加${RESET}"
            fi
            
            echo -e "${GREEN}✅ 脚本已成功安装${RESET}"
            echo -e "${GREEN}下次可直接使用 'sakisp' 命令启动${RESET}"
            sleep 2
        else
            echo -e "${RED}❌ 安装失败，可能原因：${RESET}"
            if [[ "$SYSTEM_INSTALL_PATH" == /usr/* ]]; then
                echo -e "  1. 缺少sudo权限（root用户无需sudo，普通用户需执行sudo重试）"
                echo -e "  2. $PATH_DIR 目录无写入权限"
            else
                echo -e "  1. $PATH_DIR 目录无写入权限"
                echo -e "  2. 源文件 $LOCAL_SCRIPT_PATH 不可读"
            fi
            echo -e "${YELLOW}如遇权限问题，可切换root用户（su -）后重试${RESET}"
            sleep 3
        fi
    else
        echo -e "${CYAN}✔ 目标路径已存在最新版本脚本，无需安装${RESET}"
    fi
}

# 美化输出
pretty_print() {
    clear
    figlet -f slant "$1"
    echo -e "\n${CYAN}$2${RESET}"
}

# 通用安装函数
install_pkg() {
    pretty_print "INSTALLING" "正在安装 $1 ..."
    sudo apt install -y "$1" 2>&1 | tee /tmp/install.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "$1 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n${RED}$1 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# 通用卸载函数
remove_pkg() {
    pretty_print "REMOVING" "正在卸载 $1 ..."
    sudo apt remove -y "$1" 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\n$1 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n$1 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# QQ软件管理对话框
qq_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 QQ 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) qq_architecture ;;
        2) remove_qq ;;
        0) ;;
    esac
}

# QQ软件选择架构管理框
qq_architecture() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择您的系统架构来进行安装QQ：" 12 40 3 \
    "1" "🥝 ARM64" \
    "2" "🍅 AMD64" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_qqarm64 ;;
        2) install_qqamd64 ;;
        0) ;;
    esac
}

# QQ卸载函数
remove_qq() {
    pretty_print "REMOVING" "正在卸载 QQ..."
    sudo apt purge -y linuxqq* 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nQQ 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nQQ 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# 微信软件管理对话框
wechat_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 微信 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) wechat_architecture ;;
        2) remove_wechat ;;
        0) ;;
    esac
}

# 微信软件选择架构管理框
wechat_architecture() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择您的系统架构来进行安装微信：" 12 40 3 \
    "1" "🥝 ARM64" \
    "2" "🍅 AMD64" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_wechatarm64 ;;
        2) install_wechatamd64 ;;
        0) ;;
    esac
}

# 微信卸载函数
remove_wechat() {
    pretty_print "REMOVING" "正在卸载 微信..."
    sudo apt purge -y wechat* 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\n微信 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n微信 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# 安装 Thunderbird 核心函数（含系统检测、中文包匹配）
install_thunderbird() {
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local RESET='\033[0m'
    local LOG_PATH="/var/log/thunderbird_install.log"

    clear
    echo -e "${BLUE}🔍 正在检测系统...${RESET}"
    sleep 3

    if ! command -v lsb_release &> /dev/null; then
        echo -e "${YELLOW}⚠ 未检测到 lsb_release 工具，需先安装（依赖检测必备）${RESET}"
        sleep 2
        if sudo apt install -y lsb-release &>> "$LOG_PATH"; then
            echo -e "${GREEN}✅ lsb-release 安装成功${RESET}"
        else
            echo -e "${RED}❌ 安装 lsb-release 失败，无法继续系统检测${RESET}"
            sleep 3
            echo -e "${YELLOW}ℹ 按回车键返回菜单...${RESET}"
            read -r
            clear
            return 1
        fi
    fi

    local os_release=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    local zh_package=""

    case $os_release in
        debian|gxde|kali)
            zh_package="thunderbird-l10n-zh-cn"
            echo -e "${YELLOW}⚠ 检测到 Debian/GXDE/Kali 系统${RESET}"
            ;;
        ubuntu)
            zh_package="thunderbird-locale-zh-hans"
            echo -e "${YELLOW}⚠ 检测到 Ubuntu 系统${RESET}"
            ;;
        *)
            echo -e "${RED}❌ 未识别的系统版本，无法匹配中文包！${RESET}"
            sleep 3
            echo -e "${YELLOW}ℹ 按回车键返回菜单...${RESET}"
            read -r
            clear
            return 1
            ;;
    esac
    sleep 3

    echo -e "${BLUE}📥 正在前台安装 Thunderbird${RESET}"
    sleep 3

    if sudo apt update &>> "$LOG_PATH" && sudo apt install -y thunderbird "$zh_package" &>> "$LOG_PATH"; then
        echo -e "${GREEN}✅ Thunderbird 及中文包安装成功！${RESET}"
    else
        echo -e "${RED}❌ Thunderbird 安装失败！${RESET}"
        echo -e "${YELLOW}ℹ 详细错误日志请查看：${LOG_PATH}${RESET}"
    fi
    sleep 3

    echo -e "${YELLOW}ℹ 按回车键返回菜单...${RESET}"
    read -r
    clear
}

uninstall_thunderbird() {
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[0;33m'
    local BLUE='\033[0;34m'
    local RESET='\033[0m'
    local LOG_PATH="/var/log/thunderbird_uninstall.log"

    clear
    echo -e "${BLUE}🔍 正在检测系统${RESET}"
    sleep 3

    local os_release=""
    if ! command -v lsb_release &> /dev/null; then
        echo -e "${YELLOW}⚠ 未检测到 lsb_release 工具，需先安装（依赖检测必备）${RESET}"
        sleep 2
        if sudo apt install -y lsb-release &>> "$LOG_PATH"; then
            echo -e "${GREEN}✅ lsb-release 安装成功${RESET}"
            os_release=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        else
            echo -e "${RED}❌ 安装 lsb-release 失败，仅尝试卸载主程序${RESET}"
        fi
    else
        os_release=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    fi

    local zh_package=""

    case $os_release in
        debian|gxde|kali)
            zh_package="thunderbird-l10n-zh-cn"
            echo -e "${YELLOW}⚠ 检测到 Debian/GXDE/Kali 系统，将卸载中文包: ${zh_package}${RESET}"
            ;;
        ubuntu)
            zh_package="thunderbird-locale-zh-hans"
            echo -e "${YELLOW}⚠ 检测到 Ubuntu 系统，将卸载中文包: ${zh_package}${RESET}"
            ;;
        *)
            echo -e "${YELLOW}⚠ 未识别系统，仅卸载 Thunderbird 主程序，中文包需手动清理${RESET}"
            sleep 3
            ;;
    esac
    sleep 3

    echo -e "${RED}🗑️  正在前台卸载 Thunderbird 及对应中文包${RESET}"
    sleep 3

    if [ -n "$zh_package" ]; then
        if sudo apt remove -y thunderbird "$zh_package" &>> "$LOG_PATH" && sudo apt autoremove -y &>> "$LOG_PATH"; then
            echo -e "${GREEN}✅ Thunderbird 及中文包 ${zh_package} 卸载成功！${RESET}"
        else
            echo -e "${RED}❌ Thunderbird 或中文包卸载失败！${RESET}"
            echo -e "${YELLOW}ℹ 详细错误日志请查看：${LOG_PATH}${RESET}"
        fi
    else
        if sudo apt remove -y thunderbird &>> "$LOG_PATH" && sudo apt autoremove -y &>> "$LOG_PATH"; then
            echo -e "${GREEN}✅ Thunderbird 主程序卸载成功！${RESET}"
            echo -e "${YELLOW}ℹ 中文包未识别，需手动检查并清理${RESET}"
        else
            echo -e "${RED}❌ Thunderbird 卸载失败！${RESET}"
            echo -e "${YELLOW}ℹ 详细错误日志请查看：${LOG_PATH}${RESET}"
        fi
    fi
    sleep 3

    echo -e "${YELLOW}ℹ 按回车键返回菜单...${RESET}"
    read -r
    clear
}

# Thunderbird 软件管理对话框（保留原菜单结构，关联优化后的安装/卸载函数）
thunderbird_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 thunderbird 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") install_thunderbird ;;
        "2") uninstall_thunderbird ;;
        "0") 
            clear
            ;;
    esac
}

# Pycharm卸载函数
remove_pycharm() {
    pretty_print "REMOVING" "正在卸载 $1 ..."
    sleep 3
    rm -rf /opt/pycharm 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nPycharm 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nPycharm 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# Chromium软件管理对话框
chromium_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 Chromium 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_chromium ;;
        2) remove_chromium ;;
        0) ;;
    esac
}

# Chromium卸载函数
remove_chromium() {
    pretty_print "REMOVING" "正在卸载 Chromium..."
    
    # 检测系统类型和版本
    local detected_system="Unknown"
    local dist_version=""
    if command -v lsb_release &>/dev/null; then
        local dist=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
        dist_version=$(lsb_release -rs 2>/dev/null)
        [ "$dist" = "ubuntu" ] && detected_system="Ubuntu"
    fi

    # 定义日志文件
    local log_file="/tmp/uninstall.log"

    # Ubuntu 22.04 专属处理：dpkg强制卸载指定包
    if [ "$detected_system" = "Ubuntu" ] && [ "$dist_version" = "22.04" ]; then
        local target_pkgs=(
            "chromium-browser"
            "chromium-browser-l10n"
            "chromium-codecs-ffmpeg"
            "chromium-codecs-ffmpeg-extra"
        )
        echo "检测到Ubuntu 22.04系统，执行dpkg强制卸载..." | tee "$log_file"
        # 先取消包保留（避免卸载受阻）
        sudo apt-mark unhold "${target_pkgs[@]}" 2>&1 | tee -a "$log_file"
        # dpkg强制卸载（--force-all强制移除，-P彻底删除配置文件）
        sudo dpkg -P --force-all "${target_pkgs[@]}" 2>&1 | tee -a "$log_file"
        local exit_code=${PIPESTATUS[0]}
    else
        # 其他系统：保持原有apt purge逻辑
        sudo apt purge -y chromium* ungoogled-chromium* chromium-l10n* 2>&1 | tee "$log_file"
        local exit_code=${PIPESTATUS[0]}
    fi

    # 卸载结果反馈
    if [ $exit_code -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nChromium 及其相关组件卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nChromium 卸载失败，请检查日志：$log_file" 12 50
    fi
}

# fcitx5卸载函数
fcitx5_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 fcitx5 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_fcitx5 ;;
        2) remove_fcitx5 ;;
        0) ;;
    esac
}

install_fcitx5() {
    pretty_print "INSTALLING" "即将安装 fcitx5 ..."
    sudo apt install -y fcitx5-chinese-addons fcitx5 kde-config-fcitx5 2>&1 | tee /tmp/fcitx5install.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nfcitx5 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nfcitx5 安装失败，请检查日志：/tmp/fcitxinstall.log" 12 50
    fi
}

# fcitx5卸载函数
remove_fcitx5() {
    pretty_print "REMOVING" "正在卸载 fcitx5 ..."
    sudo apt purge -y fcitx5-chinese-addons fcitx5 kde-config-fcitx5 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nfcitx5 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nfcitx5 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# 基础功能函数
clear_terminal() {
    sleep 0.5
    clear
}

delay() {
    local secs=${1:-2}
    echo -e "${YELLOW}操作完成，等待 $secs 秒继续...${RESET}"
    sleep $secs
    clear_terminal
}

install_ppa_dep() {
    if ! command -v add-apt-repository &> /dev/null; then
        sudo apt update
        sudo apt install -y software-properties-common || {
            echo -e "${RED}安装软件源工具失败，请手动安装${RESET}"; exit 1
        }
    fi
}

# Firefox版本选择菜单
firefox_version_choice() {
    local choice=$(whiptail --clear --backtitle "Firefox安装" \
        --title " 📦 版本选择 " \
        --menu "请至少选择安装一个Firefox版本：" 12 40 2 \
        "1" "🔥 Firefox 常规版" \
        "2" "🔥 Firefox ESR 长期支持版" \
        3>&1 1>&2 2>&3)

    case $choice in
        "1") install_firefox "regular" ;;
        "2") install_firefox "esr" ;;
        *) echo -e "${RED}已取消操作${RESET}"; delay; return 1 ;;
    esac
}

reinstall_firefox() {
    local version=$1
    local main_package
    local lang_package
    local version_name
    local os_id
    local os_name

    os_id=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
    os_name=$(grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '"')

    if [ "$version" = "regular" ]; then
        main_package="firefox"
        version_name="Firefox 常规版"
    else
        main_package="firefox-esr"
        version_name="Firefox ESR"
    fi

    if [ "$os_id" = "debian" ] || [ "$os_id" = "kali" ] || echo "$os_name" | grep -qi "gxde"; then
        if [ "$version" = "regular" ]; then
            lang_package="firefox-l10n-zh-cn"
        else
            lang_package="firefox-esr-l10n-zh-cn"
        fi
    elif [ "$os_id" = "ubuntu" ]; then
        if [ "$version" = "regular" ]; then
            lang_package="firefox-locale-zh-hans"
        else
            lang_package="firefox-esr-locale-zh-hans"
        fi
    else
        echo -e "${YELLOW}⚠️  未识别系统，使用通用中文包规则${RESET}"
        if [ "$version" = "regular" ]; then
            lang_package="firefox-l10n-zh-cn"
        else
            lang_package="firefox-esr-l10n-zh-cn"
        fi
    fi

    clear_terminal
    echo -e "${CYAN}===== 重新安装 $version_name（含中文包）=====${RESET}"
    echo -e "${YELLOW}系统检测：$os_name（$os_id）${RESET}"
    echo -e "${YELLOW}中文语言包：$lang_package${RESET}\n"

    echo -e "${BLUE}→ 第一步：清理残留依赖...${RESET}"
    sudo apt autoremove -y
    sudo apt clean

    echo -e "\n${BLUE}→ 第二步：重新安装主程序...${RESET}"
    sudo apt reinstall -y "$main_package"

    echo -e "\n${BLUE}→ 第三步：直接重新安装中文语言包...${RESET}"
    if sudo apt reinstall -y "$lang_package"; then
        echo -e "${GREEN}✅ 中文语言包 $lang_package 重新安装成功${RESET}"
    else
        echo -e "${YELLOW}⚠️ 中文语言包 $lang_package 安装失败（可能包名不匹配当前系统）${RESET}"
    fi

    echo -e "\n${GREEN}✅ ${version_name} 重新安装流程已完成！${RESET}"
    delay
}

install_firefox() {
    local version=$1
    local version_name
    local pkg_name
    local lang_pkg
    
    if [ "$version" = "regular" ]; then
        version_name="Firefox 常规版"
        pkg_name="firefox"
    else
        version_name="Firefox ESR"
        pkg_name="firefox-esr"
    fi
    
    if dpkg -s "$pkg_name" &> /dev/null; then
        clear_terminal
        echo -e "${YELLOW}检测到已安装 $version_name，操作选项：(Y/m/n)${RESET}"
        echo -e "${YELLOW}Y: 重新安装 | m: 管理菜单 | n: 取消${RESET}"
        read -r choice
        
        case "$choice" in
            [Yy]) ;;
            [Mm]) firefox_operation_menu "$version" "$version_name"; return 1 ;;
            *) echo -e "${YELLOW}已取消操作，返回主菜单${RESET}"; delay; return 1 ;;
        esac
    fi
    
    local system="Unknown"
    if command -v lsb_release &> /dev/null; then
        local dist=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
        [ "$dist" = "ubuntu" ] && system="Ubuntu"
        [ "$dist" = "kali" ] && system="Kali"
    fi
    [ "$system" = "Unknown" ] && [ -f /etc/gxde-release ] && system="GXDE"
    [ "$system" = "Unknown" ] && [ -f /etc/debian_version ] && system="Debian"
    [ "$system" = "Unknown" ] && [ "$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')" = "kali" ] && system="Kali"
    
    if [ "$version" = "regular" ]; then
        if [ "$system" = "Ubuntu" ]; then
            lang_pkg="^firefox-locale-zh"
        else
            lang_pkg="^firefox-l10n-zh"
        fi
    else
        if [ "$system" = "Ubuntu" ]; then
            lang_pkg="^firefox-esr-locale-zh"
        else
            lang_pkg="^firefox-esr-l10n-zh"
        fi
    fi
    
    clear_terminal
    echo -e "${CYAN}===== $version_name 安装流程 =====${RESET}"
    echo -e "${CYAN}检测到系统: $system | 语言包: ${lang_pkg#^}${RESET}"
    echo -e "${CYAN}================================${RESET}"
    delay 1
    
    case "$system" in
        "Ubuntu")
            install_ppa_dep
            sudo add-apt-repository -y ppa:mozillateam/ppa || {
                echo -e "${RED}PPA添加失败，请手动添加: ppa:mozillateam/ppa${RESET}"; delay; return 1
            }
            sudo apt update || { echo -e "${RED}软件源更新失败${RESET}"; delay; return 1; }
            ;;
        "GXDE"|"Debian"|"Kali")
            sudo apt update || { echo -e "${RED}软件源更新失败${RESET}"; delay; return 1; }
            ;;
        *)
            echo -e "${RED}不支持的系统: $system，仅支持Ubuntu/Debian/Kali/GXDE${RESET}"; delay; return 1;
    esac
    
    clear_terminal
    echo -e "${CYAN}正在安装 $version_name 及中文包...${RESET}"
    echo -e "${YELLOW}安装包列表:${RESET}"
    echo -e "  - $pkg_name (本体)"
    echo -e "  - ${lang_pkg#^} (中文语言包)"
    echo -e "  - ffmpeg (多媒体支持)${RESET}"
    delay 1
    
    sudo apt install "$pkg_name" "$lang_pkg" ffmpeg -y || {
        echo -e "${RED}安装失败，是否重试? (Y/n)${RESET}"
        read -r choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            sudo apt install "$pkg_name" "$lang_pkg" ffmpeg -y || {
                echo -e "${RED}二次安装失败，请手动检查依赖${RESET}"; delay; return 1
            }
        else
            echo -e "${YELLOW}已取消安装${RESET}"; delay; return 1
        fi
    }
    
    echo -e "${GREEN}$version_name 安装完成！${RESET}"
    delay
}

firefox_operation_menu() {
    local version=$1
    local version_name=$2
    clear_terminal
    echo -e "${CYAN}===== $version_name 操作菜单 =====${RESET}"
    echo -e "1. 重新安装（含依赖清理）"
    echo -e "2. 卸载"
    echo -e "0. 返回主菜单"
    echo -e "${CYAN}================================${RESET}"
    read -r menu_choice
    
    case "$menu_choice" in
        "1") reinstall_firefox "$version"; delay ;;
        "2") remove_firefox "$version"; delay ;;
        "0") return 1 ;;
        *) echo -e "${RED}无效选择，请重新输入${RESET}"; delay; firefox_operation_menu "$version" "$version_name" ;;
    esac
}

remove_firefox() {
    local version=$1
    local version_name
    local pkg_name
    local config_dir
    local system="Unknown"
    
    if [ "$version" = "regular" ]; then
        version_name="Firefox 常规版"
        pkg_name="firefox"
        config_dir=".mozilla/firefox"
    else
        version_name="Firefox ESR"
        pkg_name="firefox-esr"
        config_dir=".mozilla/firefox-esr"
    fi

    if command -v lsb_release &> /dev/null; then
        local dist=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
        [ "$dist" = "ubuntu" ] && system="Ubuntu"
        [ "$dist" = "kali" ] && system="Kali"
    fi
    [ "$system" = "Unknown" ] && [ -f /etc/gxde-release ] && system="GXDE"
    [ "$system" = "Unknown" ] && [ -f /etc/debian_version ] && system="Debian"
    [ "$system" = "Unknown" ] && [ "$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')" = "kali" ] && system="Kali"

    clear_terminal
    echo -e "${YELLOW}确定要卸载 $version_name 吗?（Y/n）${RESET}"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在卸载 $version_name 及中文包...${RESET}"
        
        sudo apt purge "$pkg_name" -y
        
        case "$system" in
            "Ubuntu")
                sudo apt purge $(dpkg-query -W -f='${Package}\n' | grep -E '^firefox(-esr)?-locale-zh.*$') -y || true
                ;;
            "Debian"|"GXDE"|"Kali")
                sudo apt purge $(dpkg-query -W -f='${Package}\n' | grep -E '^firefox(-esr)?-l10n-zh.*$') -y || true
                ;;
            *)
                echo -e "${YELLOW}未识别系统，跳过中文包清理${RESET}"
                ;;
        esac
        
        sudo apt autoremove -y
        
        if [ -d "$HOME/$config_dir" ]; then
            rm -rf "$HOME/$config_dir"
            echo -e "${GREEN}已删除用户配置: $HOME/$config_dir${RESET}"
        else
            echo -e "${YELLOW}未找到用户配置目录${RESET}"
        fi
        
        echo -e "${GREEN}$version_name 已完全卸载${RESET}"
        sleep 3
    else
        echo -e "${YELLOW}已取消卸载操作${RESET}"
        sleep 3
        return 1
    fi
    delay
}

# KDE-GAMES软件管理对话框
kdegames_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 KDE-games 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_kdegames ;;
        2) remove_kdegames ;;
        0) ;;
    esac
}

# KDE-GAMES安装函数
install_kdegames() {
    pretty_print "GAMES" "正在安装 KDE-Games..."
    sudo apt install -y kdegames bomber bovo granatier kapman katomic kblackbox kblocks kbounce kbreakout kdiamond kfourinline kgoldrunner kigo killbots kiriki kjumpingcube klickety klines kmahjongg kmines knavalbattle knetwalk knights kolf kollision konquest kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick lskat palapeli picmi kajongg 2>&1 | tee /tmp/install.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nKDE-Games 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nKDE-Games 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# KDE-GAMES卸载函数
remove_kdegames() {
    pretty_print "REMOVING" "正在卸载 KDE-Games..."
    sudo apt purge -y kdegames bomber bovo granatier kapman katomic kblackbox kblocks kbounce kbreakout kdiamond kfourinline kgoldrunner kigo killbots kiriki kjumpingcube klickety klines kmahjongg kmines knavalbattle knetwalk knights kolf kollision konquest kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick lskat palapeli picmi kajongg 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nKDE-Games 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nKDE-Games 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# GNMOE-GAMES软件管理对话框
gnmoegames_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 GNOME-Games 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_gnmoegames ;;
        2) remove_gnmoegames ;;
        0) ;;
    esac
}

# GNOME-GAMES安装函数
install_gnmoegames() {
    pretty_print "GAMES" "正在安装 GNOME-Games..."
    sudo apt install -y gnome-games phosh-games gnustep-games five-or-more four-in-a-row gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff quadrapassel swell-foop tali 2>&1 | tee /tmp/install.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nGNMOE-Games 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nGNMOE-Games 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# GNOME-GAMES卸载函数
remove_gnmoegames() {
    pretty_print "REMOVING" "正在卸载 GNOME-Games..."
    sudo apt purge -y gnome-games phosh-games gnustep-games five-or-more four-in-a-row gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff quadrapassel swell-foop tali 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nGNMOE-Games 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nGNMOE-Games 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

check_ppa() {
    local ppa_url=$1
    grep -q "$ppa_url" /etc/apt/sources.list.d/* 2>/dev/null && return 0 || return 1
}

is_ubuntu_system() {
    if ! command -v lsb_release &> /dev/null; then
        echo -e "${RED}[错误] 缺少lsb_release命令，无法检测系统类型${RESET}"
        return 1
    fi
    local dist=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
    [ "$dist" = "ubuntu" ] && return 0 || return 1
}

get_ppa_display_name() {
    local ppa_url=$1
    local owner_name=$(echo "$ppa_url" | sed -E 's@https://ppa.launchpadcontent.net/@@; s@/ubuntu/@@')
    local owner=$(echo "$owner_name" | cut -d'/' -f1 | sed -e 's@mozillateam@Mozilla团队@' -e 's@xtradeb@Xtradeb@')
    local name=$(echo "$owner_name" | cut -d'/' -f2 | sed -e 's@-next@@; s@-@ @g; s@^[a-z]@\U&@')
    echo "${owner} ${name} PPA"
}

# PPA管理 - 添加预设PPA
add_预设_ppa() {
    # 系统检测与echo图标提示
    if is_ubuntu_system; then
        echo -e "\n${GREEN}✅ 检测到Ubuntu系统，支持PPA管理功能${RESET}"
        sleep 1.5  # 延迟1.5秒
    else
        echo -e "\n${RED}⚠ 仅Ubuntu系统支持PPA功能${RESET}"
        echo -e "${YELLOW}当前系统: $system${RESET}"
        sleep 1.5  # 延迟1.5秒
        return
    fi
    
    local preset_ppas=(
        "https://ppa.launchpadcontent.net/mozillateam/thunderbird-next/ubuntu/"
        "https://ppa.launchpadcontent.net/mozillateam/firefox-next/ubuntu/"
        "https://ppa.launchpadcontent.net/xtradeb/apps/ubuntu/"
    )
    
    local ppa_urls=()
    local display_names=()
    for ppa_url in "${preset_ppas[@]}"; do
        if ! check_ppa "$ppa_url"; then
            display_name=$(get_ppa_display_name "$ppa_url")
            ppa_urls+=("$ppa_url")
            display_names+=("$display_name")
        fi
    done
    
    local num_options=${#display_names[@]}
    if [ $num_options -eq 0 ]; then
        echo -e "\n${YELLOW}[提示] 所有预设PPA已添加！${RESET}"
        sleep 1.5
        return
    fi
    
    clear
    pretty_print "PPA" "请选择要添加的PPA源（未添加）："
    for i in "${!display_names[@]}"; do
        echo -e "  ${GREEN}$((i+1)).${RESET} ${display_names[i]}"
    done
    echo -e "  ${RED}0. 返回主菜单${RESET}"
    
    read -p "请输入选项 [0-${num_options}]: " choice
    if [ "$choice" -eq 0 ]; then return; fi
    if [ "$choice" -lt 1 ] || [ "$choice" -gt $num_options ]; then
        echo -e "\n${RED}[错误] 无效选择！${RESET}"
        sleep 1.5
        return
    fi
    
    local index=$((choice-1))
    local ppa_url=${ppa_urls[index]}
    local display_name=${display_names[index]}
    pretty_print "PPA" "正在添加：${display_name} ..."
    
    if ! command -v add-apt-repository &>/dev/null; then
        sudo apt install -y software-properties-common || return
    fi
    
    local ppa_path=$(echo "$ppa_url" | sed -E 's@https://ppa.launchpadcontent.net/@@; s@/ubuntu/@@')
    if sudo add-apt-repository -y "ppa:${ppa_path}"; then
        sudo apt update || return
        echo -e "\n${GREEN}[成功] PPA添加成功！${RESET}"
        sleep 1.5
    else
        echo -e "\n${RED}[错误] PPA添加失败！${RESET}"
        sleep 1.5
        clear
    fi
}

# PPA管理 - 移除PPA
remove_ppa() {
    # 系统检测与echo图标提示
    if is_ubuntu_system; then
        echo -e "\n${GREEN}✅ 检测到Ubuntu系统，支持PPA管理功能${RESET}"
        sleep 1.5  # 延迟1.5秒
    else
        echo -e "\n${RED}⚠ 仅Ubuntu系统支持PPA功能${RESET}"
        echo -e "${YELLOW}当前系统: $system${RESET}"
        sleep 1.5  # 延迟1.5秒
        return
    fi
    
    local preset_ppas=(
        "https://ppa.launchpadcontent.net/mozillateam/thunderbird-next/ubuntu/"
        "https://ppa.launchpadcontent.net/mozillateam/firefox-next/ubuntu/"
        "https://ppa.launchpadcontent.net/xtradeb/apps/ubuntu/"
    )
    
    local ppa_urls=()
    local display_names=()
    for ppa_url in "${preset_ppas[@]}"; do
        if check_ppa "$ppa_url"; then
            display_name=$(get_ppa_display_name "$ppa_url")
            ppa_urls+=("$ppa_url")
            display_names+=("$display_name")
        fi
    done
    
    local num_options=${#display_names[@]}
    if [ $num_options -eq 0 ]; then
        echo -e "\n${YELLOW}[提示] 未找到已添加的预设PPA源。${RESET}"
        sleep 1.5
        clear
        return
    fi
    
    clear
    pretty_print "PPA" "请选择要移除的预设PPA源："
    for i in "${!display_names[@]}"; do
        echo -e "  ${GREEN}$((i+1)).${RESET} ${display_names[i]}"
    done
    echo -e "  ${RED}0. 返回主菜单${RESET}"
    
    read -p "请输入选项 [0-${num_options}]: " choice
    if [ "$choice" -eq 0 ]; then return; fi
    if [ "$choice" -lt 1 ] || [ "$choice" -gt $num_options ]; then
        echo -e "\n${RED}[错误] 无效选择！${RESET}"
        sleep 1.5
        clear
        return
    fi
    
    local index=$((choice-1))
    local ppa_url=${ppa_urls[index]}
    local display_name=${display_names[index]}
    pretty_print "PPA" "正在移除：${display_name} ..."
    
    local ppa_path=$(echo "$ppa_url" | sed -E 's@https://ppa.launchpadcontent.net/@@; s@/ubuntu/@@')
    if sudo add-apt-repository -r -y "ppa:${ppa_path}"; then
        sudo apt update || return
        if ! check_ppa "$ppa_url"; then
            echo -e "\n${GREEN}[成功] PPA移除成功！${RESET}"
        else
            echo -e "\n${RED}[错误] PPA移除失败，请手动删除！${RESET}"
        fi
        sleep 1.5
    else
        echo -e "\n${RED}[错误] 移除命令失败！${RESET}"
        sleep 1.5
        clear
    fi
}

# PPA源管理菜单
ppa_menu() {
    while true; do
        clear  # 菜单循环开始时清屏
        pretty_print "PPA" "源管理工具"
        echo -e "\n${CYAN}💡 提示：${RESET}PPA功能仅在Ubuntu系统中可用\n"
        
        if is_ubuntu_system; then
            echo -e "${GREEN}✅ 当前系统支持PPA管理，可正常使用${RESET}"
        else
            echo -e "${RED}⚠ 当前系统: $system${RESET}"
            echo -e "${YELLOW}提示：PPA功能不可用，但仍可查看菜单${RESET}"
        fi
        sleep 1.5
        
        # 显示菜单选项
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "          ${MAGENTA}PPA源管理菜单${RESET}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "  ${GREEN}1.${RESET} 添加预设PPA源"
        echo -e "  ${GREEN}2.${RESET} 移除PPA源"
        echo -e "  ${RED}0.${RESET} 返回主菜单"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        
        read -p "请输入选项 [0-2]: " choice
        case $choice in
            1) add_预设_ppa; clear ;;  # 执行后清屏
            2) remove_ppa; clear ;;    # 执行后清屏
            0) clear; break ;;         # 返回前清屏
            *) echo -e "\n${RED}[错误] 无效选择！${RESET}"; sleep 1; clear ;;
        esac
    done
}

check_update() {
    local RED="\033[1;31m"
    local GREEN="\033[1;32m"
    local YELLOW="\033[1;33m"
    local BLUE="\033[1;34m"
    local PURPLE="\033[1;35m"
    local CYAN="\033[1;36m"
    local RESET="\033[0m"
    local ICON_CHECK="✅"
    local ICON_ERROR="❌"
    local ICON_LOAD="🔄"
    local ICON_WARN="⚠️"
    local ICON_INFO="ℹ️"
    local ICON_UPDATE="🆙"
    local ICON_USER="👤"
    local ICON_REFRESH="🔁"

    local SYSTEM_PATH="/usr/games/sakisp"  
    local USER_PATH="$HOME/.local/bin/sakisp"  
    local KALI_PATH="/usr/local/bin/sakisp"  
    local CURRENT_SCRIPT=$(readlink -f "$0")  
    local repo_url="https://gh.xmly.dev/https://github.com/YingLi606/SakiSP.git"  
    local TEMP_DIR="$HOME/.sakisp-temp-repo"  # 临时仓库目录（原local_repo_dir）
    local A_DIR="$HOME/SakiSP"          # 目标仓库目录（需被临时目录覆盖）
    local script_name=$(basename "$CURRENT_SCRIPT")  
    local restart_flag=0  

    if [[ "$CURRENT_SCRIPT" == "$SYSTEM_PATH" || "$CURRENT_SCRIPT" == "$KALI_PATH" || "$CURRENT_SCRIPT" == "$USER_PATH" ]]; then
        clear
        echo -e "${PURPLE}==================================================${RESET}"
        echo -e "${RED}${ICON_WARN}  警告：请前往克隆仓库（SakiSP）目录执行更新 ${RESET}"
        echo -e "${PURPLE}==================================================${RESET}"
        echo -e "\n${YELLOW}  按 Enter 键返回主菜单 ${RESET}"
        read -p ""  
        clear       
        return 1  
    fi

    clear  
    echo -e "${CYAN}==================================================${RESET}"
    echo -e "${GREEN}${ICON_UPDATE}        SakiSP 更新检测        ${RESET}"
    echo -e "${CYAN}==================================================${RESET}"
    echo -e "${BLUE}${ICON_USER}  当前操作用户：$(whoami)                  ${RESET}"         
    echo -e "${CYAN}==================================================${RESET}\n"

    echo -e "${YELLOW}${ICON_LOAD}  正在检查必要工具（Git）... ${RESET}"
    for ((i=0; i<3; i++)); do
        echo -ne "\r${YELLOW}${ICON_LOAD}  检查工具中... ${i+1}/3 ${RESET}"
        sleep 0.3
    done
    echo -ne "\r"

    if ! command -v git &>/dev/null; then  
        echo -e "${RED}${ICON_ERROR}  错误：未安装 Git 工具！${RESET}\n"
        echo -e "${BLUE}${ICON_INFO}  解决方案：执行 sudo apt install git 安装 ${RESET}" 
        echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
        read -n 1  
        return 1   
    fi
    echo -e "${GREEN}${ICON_CHECK}  Git 工具已就绪或检测已安装 ✔️ ${RESET}\n"

    # 核心修改：1. 清理旧临时目录 2. 克隆新临时仓库 3. 覆盖目标目录
    echo -e "${YELLOW}${ICON_LOAD}  初始化临时仓库并更新目标目录... ${RESET}"
    (while true; do
        for c in / - \\ \|; do
            echo -ne "\r${YELLOW}${ICON_REFRESH}  处理仓库中... $c ${RESET}"
            sleep 0.2
        done
    done) &
    local load_pid=$!

    rm -rf "$TEMP_DIR" &>/dev/null

    git clone --depth 1 "$repo_url" "$TEMP_DIR" &>/dev/null || {
        kill $load_pid
        echo -ne "\r"
        echo -e "${RED}${ICON_ERROR}  错误：临时仓库克隆失败！${RESET}\n"
        echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
        read -n 1
        clear
        return 1 
    }
 
    mkdir -p "$A_DIR" &>/dev/null
    rm -rf "$A_DIR"/* &>/dev/null  # 清空目标目录旧内容
    cp -r "$TEMP_DIR"/* "$A_DIR/" &>/dev/null || {
        kill $load_pid
        echo -ne "\r"
        echo -e "${RED}${ICON_ERROR}  错误：仓库覆盖目标目录失败！${RESET}\n"
        echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
        read -n 1
        clear
        return 1 
    }
    # 4. 清理临时目录（用完即删）
    rm -rf "$TEMP_DIR" &>/dev/null

    kill $load_pid
    echo -ne "\r"
    echo -e "${GREEN}${ICON_CHECK}  仓库更新完成✔️ ${RESET}\n"
    sleep 1

    local repo_script_path="$A_DIR/$script_name"  # 脚本路径改为目标目录
    if [ ! -f "$repo_script_path" ]; then  
        echo -e "${RED}${ICON_WARN}  警告：目标仓库中未找到目标脚本，尝试强制修复... ${RESET}\n"
        cd "$A_DIR" || {
            echo -e "${RED}${ICON_ERROR}  错误：目标仓库目录不存在！${RESET}"
            echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
            read -n 1
            return 1
        }

        echo -e "${YELLOW}${ICON_LOAD}  正在强制同步仓库数据... ${RESET}"
        (while true; do
            for c in / - \\ \|; do
                echo -ne "\r${YELLOW}${ICON_REFRESH}  同步数据中... $c ${RESET}"
                sleep 0.2
            done
        done) &
        local load_pid=$!

        git fetch --all &>/dev/null && git reset --hard origin/master &>/dev/null || {
            kill $load_pid
            echo -ne "\r"
            echo -e "${RED}${ICON_ERROR}  错误：强制修复失败！${RESET}\n"
            echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
            read -n 1
            clear
            return 1
        }
        kill $load_pid
        echo -ne "\r"

        repo_script_path="$A_DIR/$script_name"
        if [ ! -f "$repo_script_path" ]; then
            echo -e "${RED}${ICON_ERROR}  错误：强制修复后仍未找到脚本！${RESET}"
            echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
            read -n 1
            clear
            return 1
        fi
        echo -e "${GREEN}${ICON_CHECK}  强制修复成功，脚本已恢复 ✔️ ${RESET}\n"
    fi

    local local_hash=$(sha256sum "$CURRENT_SCRIPT" | awk '{print $1}')  
    local repo_hash=$(sha256sum "$repo_script_path" | awk '{print $1}')  

    if [ "$local_hash" == "$repo_hash" ]; then  
        echo -e "${GREEN}${ICON_CHECK}  当前已是最新版本，无需更新！${RESET}"
        echo -e "\n${CYAN}==================================================${RESET}"
        echo -e "${YELLOW}  按任意键返回主菜单... ${RESET}"
        read -n 1
        clear
        return 0 
    fi

    echo -e "${YELLOW}${ICON_UPDATE}  检测到新版本，开始更新... ${RESET}"
    (while true; do
        for c in / - \\ \|; do
            echo -ne "\r${YELLOW}${ICON_REFRESH}  覆盖脚本中... $c ${RESET}"
            sleep 0.2
        done
    done) &
    local load_pid=$!

    cp -f "$repo_script_path" "$CURRENT_SCRIPT" && chmod +x "$CURRENT_SCRIPT" || {
        kill $load_pid
        echo -ne "\r"
        echo -e "${RED}${ICON_ERROR}  错误：脚本更新失败！请检查你的网络环境，实在不行开魔法${RESET}"
        echo -e "\n${YELLOW}  按任意键返回主菜单... ${RESET}"
        read -n 1
        clear
        return 1 
    }
    kill $load_pid
    echo -ne "\r"
    restart_flag=1  

    if [ $restart_flag -eq 1 ]; then  
        clear
        echo -e "${GREEN}==================================================${RESET}"
        echo -e "${GREEN}${ICON_CHECK}        更新完成！即将自动重启        ${RESET}"
        echo -e "${GREEN}==================================================${RESET}\n"
        for ((t=3; t>0; t--)); do
            echo -ne "\r${YELLOW}  倒计时：$t 秒后重启... ${RESET}"
            sleep 1
        done
        echo -ne "\r"
        exec "$CURRENT_SCRIPT" "$@"
    fi
}

install_xfce_terminal() {  
    clear_terminal  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    echo -e "${CYAN}            Xfce终端美化配置            ${RESET}"  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    delay 1  


    # 检测已安装场景
    if command -v xfce4-terminal &> /dev/null; then  
        echo -e "${GREEN}[√] 检测到已安装Xfce终端${RESET}"  
        echo -e "${YELLOW}[?] 操作选项: (Y)重新美化 | (M)管理菜单 | (N)返回主菜单${RESET}"  
        read -r choice  

        case $choice in  
            [Yy])  
                echo -e "${YELLOW}[!] 开始重新配置美化...${RESET}"; delay 0.5  
                run_xfce_terminal_beautify  
                ;;  

            [Mm])  
                # 管理菜单保留原有逻辑（重装/卸载）
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
                echo -e "${CYAN}              管理菜单              ${RESET}"  
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
                echo -e "${GREEN}1. 重装Xfce终端${RESET}"  
                echo -e "${GREEN}2. 卸载Xfce终端${RESET}"  
                echo -e "${GREEN}3. 返回主菜单${RESET}"  
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
                echo -e "${YELLOW}[?] 请选择 (1-3):${RESET}"  
                read -r manage_choice  

                case $manage_choice in  
                    1)  
                        # 重装流程（卸载+安装+按你的命令美化）
                        echo -e "${YELLOW}[!] 正在卸载Xfce终端...${RESET}"  
                        sudo apt-get remove --purge xfce4-terminal -y || {  
                            echo -e "${RED}[×] 卸载失败，尝试强制删除...${RESET}"  
                            sudo dpkg -P xfce4-terminal 2>/dev/null || {  
                                echo -e "${RED}[×] 请手动卸载软件包${RESET}"; delay 1; return 1  
                            }  
                        }  

                        echo -e "${YELLOW}[!] 重新安装Xfce终端...${RESET}"  
                        sudo apt update || {  
                            echo -e "${RED}[×] apt更新失败，请检查网络${RESET}"; delay 1; return 1  
                        }  
                        sudo apt install xfce4-terminal -y || {  
                            echo -e "${RED}[×] 安装失败，请手动安装${RESET}"; delay 1; return 1  
                        }  

                        echo -e "${GREEN}[√] 终端重装完成，开始美化...${RESET}"; delay 1  
                        run_xfce_terminal_beautify  
                        ;;  

                    2)  
                        # 卸载流程（终端+配置彻底删除）
                        echo -e "${YELLOW}[!] 正在卸载Xfce终端...${RESET}"  
                        sudo apt-get remove --purge xfce4-terminal -y || {  
                            echo -e "${RED}[×] 卸载失败，尝试强制删除...${RESET}"  
                            sudo dpkg -P xfce4-terminal 2>/dev/null || {  
                                echo -e "${RED}[×] 请手动卸载软件包${RESET}"; delay 1; return 1  
                            }  
                        }  

                        echo -e "${YELLOW}[!] 删除美化配置...${RESET}"  
                        sudo rm -rf /usr/share/xfce4/terminal/colorschemes 2>/dev/null  
                        echo -e "${GREEN}[√] 终端及美化配置已卸载${RESET}"; delay 1  
                        ;;  

                    3|*)  
                        echo -e "${YELLOW}[!] 返回主菜单...${RESET}"; delay 1  
                        ;;  
                esac  
                ;;  

            [Nn]|[Qq])  
                echo -e "${YELLOW}[!] 返回主菜单${RESET}"; delay 1  
                ;;  

            *)  
                echo -e "${RED}[×] 无效输入，返回主菜单${RESET}"; delay 1  
                ;;  
        esac  

    else  
        # 首次安装场景（安装后按你的命令美化）
        echo -e "${YELLOW}[!] 未检测到Xfce终端，开始安装...${RESET}"  
        sudo apt update || {  
            echo -e "${RED}[×] apt更新失败，请检查网络${RESET}"; delay 1; return 1  
        }  
        sudo apt install xfce4-terminal -y || {  
            echo -e "${RED}[×] 安装失败，请手动安装${RESET}"; delay 1; return 1  
        }  

        echo -e "${GREEN}[√] Xfce终端安装完成!${RESET}"  
        delay 0.5  
        echo -e "${YELLOW}[?] 是否配置美化? (Y/n)${RESET}"  
        read -r choice  

        if [[ $choice =~ ^[Yy]$ ]]; then  
            run_xfce_terminal_beautify  
        else  
            echo -e "${YELLOW}[!] 已取消配置，返回主菜单${RESET}"; delay 1  
        fi  
    fi  

    return 0  
} 

run_xfce_terminal_beautify() {  
    local dir="/usr/share/xfce4/terminal"  
    echo -e "${CYAN}[*] 准备美化配置目录...${RESET}"  
    sudo mkdir -p "$dir" && sudo chmod 755 "$dir"  # 确保目录存在且权限正确  
    echo -e "${GREEN}[√] 目录准备完成: $dir${RESET}"  
    delay 0.5  

    # 进入配置目录（此时目录所有者是 root，普通用户可进入但无法写入，需通过 sudo 下载）  
    cd "$dir" || {  
        echo -e "${RED}[×] 无法进入目录: $dir${RESET}"; delay 1; return 1  
    }  

    # 1. 下载Xfce官方配色方案（添加 sudo，以 root 权限下载）  
    echo -e "${CYAN}[*] 下载终端配色方案...${RESET}"  
    echo -e "${YELLOW}[→] 下载Xfce官方配色...${RESET}"  
    local xfce_scheme="colorschemes.tar.xz"  
    if ! sudo curl -Lo "$xfce_scheme" "https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz"; then  
        echo -e "${RED}[×] 主链接下载失败，尝试备用链接...${RESET}"  
        if ! sudo curl -Lo "$xfce_scheme" "https://github.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz"; then  
            echo -e "${RED}[×] 所有链接失败，请手动下载:${RESET}"  
            echo -e "${YELLOW}https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz${RESET}"  
            delay 1; return 1  
        fi  
    fi  
    echo -e "${GREEN}[√] Xfce配色下载完成${RESET}"  
    sudo tar -Jxvf "$xfce_scheme" > /dev/null 2>&1  # 解压也需 root 权限（文件所有者是 root）  
    echo -e "${GREEN}[√] 解压完成${RESET}"  
    delay 0.5  

    # 2. 下载iTerm2配色方案
    echo -e "${YELLOW}[→] 下载iTerm2配色方案...${RESET}"  
    local iterm_archive="iterm-colors.tar.gz"  
    if ! sudo curl -Lo "$iterm_archive" "https://ghproxy.net/https://github.com/mbadolato/iTerm2-Color-Schemes/archive/refs/heads/master.tar.gz"; then  
        if ! sudo curl -Lo "$iterm_archive" "https://github.com/mbadolato/iTerm2-Color-Schemes/archive/refs/heads/master.tar.gz"; then  
            echo -e "${RED}[×] 所有链接失败，请手动下载:${RESET}"  
            echo -e "${YELLOW}https://github.com/mbadolato/iTerm2-Color-Schemes/archive/refs/heads/master.tar.gz${RESET}"  
            delay 1; return 1  
        fi  
    fi  
    echo -e "${GREEN}[√] iTerm2配色压缩包下载完成${RESET}"  
    sudo tar -xf "$iterm_archive" > /dev/null 2>&1  # 解压需 root 权限  
    echo -e "${YELLOW}[→] 复制配色到Xfce终端...${RESET}"  
    local iterm_dir="iTerm2-Color-Schemes-master/xfce4terminal"  
    if [ -d "$iterm_dir" ]; then  
        sudo cp -a "$iterm_dir/." "colorschemes"  # 复制也需 root 权限（源文件所有者是 root）  
        echo -e "${GREEN}[√] iTerm2配色方案导入完成${RESET}"  
        sleep 2  
    else  
        echo -e "${YELLOW}[!] 未找到iTerm2配色目录，跳过导入${RESET}"  
        sleep 2  
    fi  
    delay 0.5  

    # 3. 清理临时文件（需 root 权限删除 root 所有的文件）  
    echo -e "${CYAN}[*] 清理临时文件...${RESET}"  
    sudo rm -f "$xfce_scheme" "$iterm_archive"  
    sudo rm -rf "iTerm2-Color-Schemes-master"  
    echo -e "${GREEN}[√] 临时文件清理完成${RESET}"  
    sleep 2  
    delay 0.5  

    # 完成提示  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    echo -e "${GREEN}            Xfce终端美化完成!            ${RESET}"  
    echo -e "${CYAN}使用方法: 打开Xfce终端 → 编辑 → 配置文件 → 颜色${RESET}"  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    delay 2  
}  

# 主菜单
main_menu() {
    while true; do
        choice=$(whiptail --clear \
            --backtitle "" \
            --title "SakiSP ${CURRENT_VERSION} " \
            --menu "✨ 请选择类别： \n
SakiSP 15,在这里,从这一刻开始！ \n
🔧 提示：使用 ↓↑ 键导航，按 Enter 确认" \
            0 60 0 \
            "1" "💼 软件中心 —— 应用宝库" \
            "2" "🗄 工具箱 —— 一些有用的工具" \
            "3" "🚙 网速测试 —— 实时网络性能检测" \
            "4" "🗄️ PPA源管理 —— 配置软件源" \
            "5" "🔁 切换脚本管理 —— 进入切换脚本管理" \
            "6" "🔍 检查更新 —— 检测工具集更新" \
            "7" "🐵 升级Debian版本 —— 请确保使用的是Debian系统" \
            "0" "🚪 退出工具" \
            3>&1 1>&2 2>&3)

        case $choice in
            "1") software_center ;;
            "2") tools_manage ;;
            "3") speed_test ;;
            "4") ppa_menu ;;
            "5") switch_manage ;;
            "6") check_update ;;
            "7") debian_update ;;
            "0") break ;;
        esac
    done
}

speed_test() {
    clear
    echo -e "${BLUE}══════════════════════════════════════"
    echo -e "  ${CYAN}${system} 镜像站测速工具 v2.2.0          "
    echo -e "══════════════════════════════════════${RESET}"

    for i in {20..1}; do
        echo -en "${YELLOW}⚠ 即将开始测速，此操作可能会消耗您数十至上百兆的流量 (剩余: ${i}s) [Y/N]: ${RESET}"
        if read -t 1 -n 1 -r confirm; then
            case $confirm in
                [Yy]) 
                    echo -e "\n${GREEN}授权通过！${RESET}\n"
                    break
                    ;;
                [Nn])
                    echo -e "\n${PURPLE}操作中止${RESET}"
                    sleep 2
                    return 1
                    ;;
                *) 
                    echo -e "\n${RED}无效输入！${RESET}"
                    ;;
            esac
        fi
        echo -ne "\r\033[K"
    done

    declare -A mirrors=(
        ["南京大学镜像站"]="https://mirrors.nju.edu.cn/debian/ls-lR.gz"
        ["山东大学镜像站"]="https://mirrors.sdu.edu.cn/debian/ls-lR.gz"        
        ["上海交大镜像站"]="https://ftp.sjtu.edu.cn/debian/ls-lR.gz"
        ["中科大镜像站"]="https://mirrors.ustc.edu.cn/debian/ls-lR.gz"
        ["华为云镜像站"]="https://mirrors.huaweicloud.com/debian/ls-lR.gz"
        ["北外镜像站"]="https://mirrors.bfsu.edu.cn/debian/ls-lR.gz"
        ["清华镜像站"]="https://mirrors.tuna.tsinghua.edu.cn/debian/ls-lR.gz"
    )

    for name in "${!mirrors[@]}"; do
        timestamp=$(date +%s%3N)
        tmp_file="/tmp/ls-lR_${timestamp}.gz"
        
        pretty_print "SPEED"
        echo -e "\n${BLUE}➤ 正在测试: ${CYAN}${name}${RESET}"
    
        aria2c --console-log-level=notice \
               --summary-interval=50 \
               --show-console-readout=true \
               --download-result=default \
               --timeout=20 \
               -d /tmp \
               -o ls-lR.gz \
               "${mirrors[$name]}"

        if [ $? -eq 0 ]; then
            rm -rf /tmp/ls-lR.gz 2>/dev/null
            echo -e "\n${GREEN}✓ 测速成功！${RESET}"
            sleep 3
        else
            echo -e "\n${RED}✗ 测速失败！${RESET}"
            sleep 3
        fi
    done

    echo -e "\n${BLUE}════════════════ 重要提示 ════════════════"
    echo -e "${CYAN}💡 提示：下载速度 ≠ 镜像更新频率！同时我们已自动清理临时文件"
    echo -e "${YELLOW}✨ 推荐访问镜像站官网确认同步策略${RESET}\n"

    read -p "⏎ 按回车键返回主菜单..." 
    clear
}

debian_update() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "升级Debian版本" \
    --title " 📦 操作选择 " \
    --menu "请选择您要升级的版本号：" 18 60 10 \
    "1" "🍏 trixie-稳定版" \
    "2" "🍎 sid-滚动更新" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) trixie_update ;;
        2) sid_update ;;
        0) ;;
    esac
}

sid_update() {
    while true; do
        choice=$(whiptail --clear \
            --backtitle "" \
            --title "🔼 升级至sid" \
            --menu "✨ 请选择： \n
升级之前，请确保: \n
1. 你的系统是Debian系统 \n
2. 软件包已全部更新 \n
注意：升级过程中不要中途退出，否则可能出现未知问题！\n
🔧 提示：使用 ↓↑ 键导航，按 Enter 确认" \
            0 60 0 \
            "1" "🥎 确认升级" \
            "0" "🔙 返回" \
            3>&1 1>&2 2>&3)

        case $choice in
            "1") 
                sid_start  
                break  
                ;;
            "0") 
                break  
                ;;
        esac
    done
}

trixie_update() {
    while true; do
        choice=$(whiptail --clear \
            --backtitle "" \
            --title "🔼 升级至trixie" \
            --menu "✨ 请选择： \n
升级之前，请确保: \n
1. 你的系统是Debian系统 \n
2. 软件包已全部更新 \n
注意：升级过程中不要中途退出，否则可能出现未知问题！\n
🔧 提示：使用 ↓↑ 键导航，按 Enter 确认" \
            0 60 0 \
            "1" "🥎 确认升级" \
            "0" "🔙 返回" \
            3>&1 1>&2 2>&3)

        case $choice in
            "1") 
                trixie_start 
                break  
                ;;
            "0") 
                break  
                ;;
        esac
    done
}

trixie_start() {
    # 分隔线函数，增强可读性
    print_separator() {
        echo -e "${LIGHT_BLUE}======================================${RESET}"
    }

    clear
    print_separator
    echo -e "${CYAN}=== 开始执行 Debian 升级至 trixie 流程 ===${RESET}"
    sleep 1
    print_separator
    sleep 3

    # 检测是否为Debian系统
    echo -e "${BLUE}[1/7] 检测系统类型...${RESET}"
    if [ "$(lsb_release -is 2>/dev/null)" != "Debian" ]; then
        echo -e "${RED}错误：当前系统不是Debian，无法执行操作！${RESET}"
        sleep 1
        print_separator
        sleep 3
        clear
        return 0
    fi
    echo -e "${GREEN}√ 检测通过：当前系统为Debian${RESET}"

    # 【新增】检测当前是否为sid/forky，提示无法降级
    echo -e "\n${BLUE}[2/7] 检测当前系统版本...${RESET}"
    sleep 2
    current_codename=$(lsb_release -c -s)
    if [ "$current_codename" = "sid" ] || [ "$current_codename" = "forky" ]; then
        echo -e "${RED}警告：当前系统版本为 Debian $current_codename${RESET}"
        echo -e "${RED}Debian sid/forky 为滚动更新版本，无法直接降回稳定版 trixie，操作终止！${RESET}"
        sleep 3
        print_separator
        sleep 2
        clear
        return 0
    fi
    echo -e "${GREEN}√ 当前系统版本：$current_codename（无降级风险，可升级至trixie）${RESET}"
    sleep 2

    # 检测当前是否已为trixie，无需升级
    echo -e "\n${BLUE}[3/7] 检测是否已为 trixie 版本...${RESET}"
    if [ "$current_codename" = "trixie" ]; then
        echo -e "${YELLOW}提示：当前系统已为 Debian trixie，无需重复升级${RESET}"
        sleep 1
        print_separator
        sleep 3
        clear
        return 0
    fi
    echo -e "${GREEN}√ 当前系统代号：$current_codename ${RESET}"
    sleep 2

    # 安装必要依赖（apt-transport-https/ca-certificates）
    echo -e "\n${BLUE}[4/7] 检查并安装必要依赖...${RESET}"
    required_pkgs=("apt-transport-https" "ca-certificates")
    missing_pkgs=()

    # 检测缺失依赖
    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    # 安装缺失依赖
    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo -e "${YELLOW}需要安装缺失的依赖：${missing_pkgs[*]}${RESET}"
        sleep 2
        echo -e "${BLUE}正在执行安装...${RESET}"
        sudo apt-get update -y &> /dev/null  # 静默更新原有源列表
        sudo apt-get install -y "${missing_pkgs[@]}"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}错误：依赖包安装失败，请检查网络后重试！${RESET}"
            print_separator
            return 1
        fi
        echo -e "${GREEN}√ 依赖包安装完成：${missing_pkgs[*]}${RESET}"
    else
        echo -e "${GREEN}√ 所有必要依赖已预先安装${RESET}"
    fi

    # 备份并替换软件源（改为trixie源）
    echo -e "\n${BLUE}[5/7] 配置 trixie 软件源...${RESET}"
    # 备份原软件源
    echo -e "${BLUE}  - 备份原有软件源...${RESET}"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.trixie_backup 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：软件源备份失败，请检查权限！${RESET}"
        print_separator
        sleep 3
        clear
        return 1
    fi
    echo -e "${GREEN}  √ 备份成功：/etc/apt/sources.list.trixie_backup${RESET}"

    # 写入新的trixie软件源（北外镜像站）
    echo -e "${BLUE}  - 写入新的trixie软件源...${RESET}"
    sleep 3
    sudo tee /etc/apt/sources.list > /dev/null << 'EOF'
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.bfsu.edu.cn/debian/ trixie main contrib non-free non-free-firmware
# deb-src https://mirrors.bfsu.edu.cn/debian/ trixie main contrib non-free non-free-firmware

deb https://mirrors.bfsu.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.bfsu.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware

deb https://mirrors.bfsu.edu.cn/debian/ trixie-backports main contrib non-free non-free-firmware
# deb-src https://mirrors.bfsu.edu.cn/debian/ trixie-backports main contrib non-free non-free-firmware

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
# deb https://mirrors.bfsu.edu.cn/debian-security trixie-security main contrib non-free non-free-firmware
# # deb-src https://mirrors.bfsu.edu.cn/debian-security trixie-security main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：软件源写入失败，请检查权限或磁盘空间！${RESET}"
        sleep 1
        echo -e "${YELLOW}正在恢复原软件源...${RESET}"
        sleep 3
        sudo cp /etc/apt/sources.list.trixie_backup /etc/apt/sources.list 2>/dev/null
        print_separator
        sleep 2
        clear
        return 1
    fi
    echo -e "${GREEN}  √ 软件源配置完成${RESET}"
    sleep 2

    # 执行系统更新（实时展示过程）
    echo -e "\n${BLUE}[6/7] 开始升级系统至 trixie...${RESET}"
    echo -e "${YELLOW}提示：此过程较长，请耐心等待;同时请勿关闭计算机或退出${RESET}"
    print_separator
    sleep 3

    # 更新包列表（trixie源）
    echo -e "${MAGENTA}===== 正在更新软件包列表（trixie源）=====${RESET}"
    sudo apt-get update -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：apt update 执行失败！${RESET}"
        sleep 1
        echo -e "${YELLOW}正在恢复原软件源...${RESET}"
        sleep 1
        sudo cp /etc/apt/sources.list.trixie_backup /etc/apt/sources.list 2>/dev/null
        print_separator
        clear
        return 1
    fi

    # 执行系统升级
    echo -e "\n${MAGENTA}===== 正在升级系统至 trixie（依赖处理/包安装）=====${RESET}"
    sudo apt-get dist-upgrade --autoremove -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：apt dist-upgrade 执行失败（可能存在依赖冲突）${RESET}"
        sleep 2
        echo -e "${YELLOW}正在恢复原软件源...${RESET}"
        sleep 1
        sudo cp /etc/apt/sources.list.trixie_backup /etc/apt/sources.list 2>/dev/null
        print_separator
        clear
        return 1
    fi

    # 升级完成提示
    print_separator
    echo -e "\n${GREEN}=== 升级流程执行完成 ==${RESET}"
    echo -e "${CYAN}提示：您已成功升级至Debian Trixie，请重启系统以应用所有更改。${RESET}"
    sleep 1
    print_separator
    sleep 3

    # 退出脚本
    exit 0
}

sid_start() {
    # 分隔线函数，增强可读性
    print_separator() {
        echo -e "${LIGHT_BLUE}======================================${RESET}"
    }

    clear
    print_separator
    echo -e "${CYAN}=== 开始执行 Debian 升级至 sid 流程 ===${RESET}"
    sleep 1
    print_separator
    sleep 3

    # 检测是否为Debian系统
    echo -e "${BLUE}[1/6] 检测系统类型...${RESET}"
    if [ "$(lsb_release -is 2>/dev/null)" != "Debian" ]; then
        echo -e "${RED}错误：当前系统不是Debian，无法执行操作！${RESET}"
        sleep 1
        print_separator
        sleep 3
        clear
        return 0  # 返回主菜单
    fi
    echo -e "${GREEN}√ 检测通过：当前系统为Debian${RESET}"

    # 获取当前版本代号并检测是否为sid/forky
    echo -e "\n${BLUE}[2/6] 检测系统版本代号...${RESET}"
    current_codename=$(lsb_release -c -s)
    if [ "$current_codename" = "sid" ] || [ "$current_codename" = "forky" ]; then
        echo -e "${YELLOW}提示：当前系统代号为 Debian $current_codename，无需升级${RESET}"
        sleep 1
        print_separator
        sleep 3
        clear
        return 0  # 返回主菜单
    fi
    echo -e "${GREEN}√ 当前系统代号：$current_codename（可升级至sid）${RESET}"
    sleep 2

    # 安装必要依赖（apt-transport-https/ca-certificates）
    echo -e "\n${BLUE}[3/6] 检查并安装必要依赖...${RESET}"
    required_pkgs=("apt-transport-https" "ca-certificates")
    missing_pkgs=()

    # 检测缺失依赖
    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    # 安装缺失依赖
    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo -e "${YELLOW}需要安装缺失的依赖：${missing_pkgs[*]}${RESET}"
        sleep 2
        echo -e "${BLUE}正在执行安装...${RESET}"
        sudo apt-get update -y &> /dev/null  # 静默更新原有源列表
        sudo apt-get install -y "${missing_pkgs[@]}"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}错误：依赖包安装失败，请检查网络后重试！${RESET}"
            print_separator
            return 1
        fi
        echo -e "${GREEN}√ 依赖包安装完成：${missing_pkgs[*]}${RESET}"
    else
        echo -e "${GREEN}√ 所有必要依赖已预先安装${RESET}"
    fi

    # 备份并替换软件源
    echo -e "\n${BLUE}[4/6] 配置软件源...${RESET}"
    # 备份原软件源
    echo -e "${BLUE}  - 备份原有软件源...${RESET}"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.sid_backup 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：软件源备份失败，请检查权限！${RESET}"
        print_separator
        sleep 3
        clear
        return 1
    fi
    echo -e "${GREEN}  √ 备份成功：/etc/apt/sources.list.sid_backup${RESET}"

    # 写入新的sid软件源
    echo -e "${BLUE}  - 写入新的sid软件源...${RESET}"
    sleep 3
    sudo tee /etc/apt/sources.list > /dev/null << 'EOF'
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.bfsu.edu.cn/debian/ sid main contrib non-free non-free-firmware
deb-src https://mirrors.bfsu.edu.cn/debian/ sid main contrib non-free non-free-firmware

# deb https://mirrors.bfsu.edu.cn/debian/ sid-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.bfsu.edu.cn/debian/ sid-updates main contrib non-free non-free-firmware

# # deb https://mirrors.bfsu.edu.cn/debian/ sid-backports main contrib non-free non-free-firmware
# # deb-src https://mirrors.bfsu.edu.cn/debian/ sid-backports main contrib non-free non-free-firmware

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
# # deb https://mirrors.bfsu.edu.cn/debian-security sid-security main contrib non-free non-free-firmware
# # deb-src https://mirrors.bfsu.edu.cn/debian-security sid-security main contrib non-free non-free-firmware

# deb https://security.debian.org/debian-security sid-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security sid-security main contrib non-free non-free-firmware
EOF

    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：软件源写入失败，请检查权限或磁盘空间！${RESET}"
        sleep 1
        echo -e "${YELLOW}正在恢复原软件源...${RESET}"
        sleep 3
        sudo cp /etc/apt/sources.list.sid_backup /etc/apt/sources.list 2>/dev/null
        print_separator
        sleep 2
        clear
        return 1
    fi
    echo -e "${GREEN}  √ 软件源配置完成（北外镜像站 sid）${RESET}"

    # 执行系统更新（实时展示过程）
    echo -e "\n${BLUE}[5/6] 开始升级系统至sid...${RESET}"
    echo -e "${YELLOW}提示：此过程较长，请耐心等待;同时请勿关闭计算机或退出${RESET}"
    print_separator
    sleep 3

    # 更新包列表
    echo -e "${MAGENTA}===== 正在更新软件包列表（sid源）=====${RESET}"
    sudo apt-get update -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：apt update 执行失败！${RESET}"
        sleep 1
        echo -e "${YELLOW}正在恢复原软件源...${RESET}"
        sleep 1
        sudo cp /etc/apt/sources.list.sid_backup /etc/apt/sources.list 2>/dev/null
        print_separator
        clear
        return 1
    fi

    # 执行系统升级
    echo -e "\n${MAGENTA}===== 正在升级系统至sid（依赖处理/包安装）=====${RESET}"
    sudo apt-get dist-upgrade --autoremove -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：apt dist-upgrade 执行失败（可能存在依赖冲突）${RESET}"
        sleep 2
        echo -e "${YELLOW}正在恢复原软件源...${RESET}"
        sleep 1
        sudo cp /etc/apt/sources.list.sid_backup /etc/apt/sources.list 2>/dev/null
        print_separator
        clear
        return 1
    fi

    # 升级完成提示
    print_separator
    echo -e "\n${GREEN}=== 升级流程执行完成 ==${RESET}"
    echo -e "${CYAN}提示：您已成功升级至Debian sid，请重启系统以应用所有更改。${RESET}"
    sleep 1
    print_separator
    sleep 3

    # 退出脚本
    exit 0
}

switch_manage() {
    while true; do
        choice=$(whiptail --clear --backtitle "" \
        --title " 🔁 切换脚本管理 " \
        --menu "请选择你需要切换的脚本：" 18 60 10 \
        "1" "🍭 切换至TMOE Linux" \
        "2" "🐱 切换至云崽（仅支持Ubuntu 22.04）" \
        "3" "🐰 切换至APT软件源管理" \
        "0" "🌚 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") tmoe_switch ;;
            "2") yunzai_switch ;;
            "3") apt_switch ;;
            "0") break ;;
        esac
    done
}

tools_manage() {
    while true; do
        choice=$(whiptail --clear \
            --backtitle "" \
            --title "🗄 工具箱 - 一些有用的工具" \
            --menu "✨ 请选择工具选项： \n
Project Management Tool.\n
🔧 提示：使用 ↓↑ 键导航，按 Enter 确认" \
            0 60 0 \
            "1" "🖥 系统信息 —— 查看系统信息" \
            "2" "🍧 修复aria2c  —— 修复无法使用aria2c下载" \
            "3" "📤 卸载此脚本  —— 和这个脚本说再见..." \
            "0" "🚪 返回主菜单" \
            3>&1 1>&2 2>&3)

        case $choice in
            "1") 
                sleep 1
                clear
                echo -e "\n${BLUE}正在准备系统信息工具...${RESET}"
                
                if command -v neofetch &> /dev/null; then
                    echo -e "${GREEN}neofetch已安装，正在显示系统信息...${RESET}"
                    neofetch
                else
                    echo -e "${BLUE}未找到neofetch，正在安装...${RESET}"
                    sudo apt-get update -y &> /dev/null
                    sudo apt-get install -y neofetch &> /dev/null
                    
                    if command -v neofetch &> /dev/null; then
                        echo -e "${GREEN}neofetch安装完成，正在显示系统信息...${RESET}"
                        neofetch
                    else
                        echo -e "${YELLOW}neofetch安装失败，检查fastfetch是否已安装...${RESET}"
                        if command -v fastfetch &> /dev/null; then
                            echo -e "${GREEN}fastfetch已安装，正在显示系统信息...${RESET}"
                            fastfetch
                        else
                            echo -e "${BLUE}未找到fastfetch，正在安装...${RESET}"
                            sudo apt-get install -y fastfetch &> /dev/null
                            
                            if command -v fastfetch &> /dev/null; then
                                echo -e "${GREEN}fastfetch安装完成，正在显示系统信息...${RESET}"
                                fastfetch
                            else
                                echo -e "${RED}错误：neofetch和fastfetch均无法安装，无法查看系统信息！${RESET}"
                            fi
                        fi
                    fi
                fi
                
                echo -e "\n${CYAN}请按回车键返回工具箱...${RESET}"
                read -r
                clear
                ;;

            "2") 
                sleep 1
                clear
                echo -e "${BLUE}正在修复aria2c...${RESET}"
                sleep 2
                
                sudo mkdir -p /usr/local/bin &> /dev/null
                cd /usr/local/bin || { 
                    echo -e "${RED}错误：无法进入/usr/local/bin目录！${RESET}"
                    echo -e "${CYAN}请按回车键返回工具箱...${RESET}"
                    read -r
                    clear
                    continue 
                }
                
                sudo tee aria2c > /dev/null << 'EOF'
#!/bin/sh
/usr/bin/aria2c --async-dns=false --disable-ipv6=true "$@"
EOF
                sudo chmod +x aria2c &> /dev/null
                cd ~ || exit
                
                echo -e "${GREEN}aria2c修复完成！${RESET}"
                echo -e "${CYAN}请按回车键返回工具箱...${RESET}"
                read -r
                clear
                ;;

            "3") 
                uninstall_sakisp
                ;;

            "0") 
                clear
                break
                ;;
        esac
    done
}

uninstall_sakisp() {
    while true; do
        whiptail --title "卸载确认" --yesno "你确定要卸载此脚本吗？" 10 60
        if [ $? -eq 0 ]; then
            clear
            echo -e "\033[1;31m开始执行 sakisp 脚本卸载流程...\033[0m"
            sleep 1
            
            cd ~ || {
                echo -e "\033[1;31m错误：无法切换到主目录！\033[0m"
                sleep 2
                clear
                return 1
            }
            echo -e "\033[1;34m已切换到主目录：$(pwd)\033[0m"
            sleep 0.5
            
            local SYSTEM_PATH="/usr/games/sakisp"  
            local USER_PATH="$HOME/.local/bin/sakisp"  
            local KALI_PATH="/usr/local/bin/sakisp"  

            if [ -f "$SYSTEM_PATH" ]; then
                sudo rm -f "$SYSTEM_PATH"
                echo -e "\033[1;32m→ 已删除系统路径文件：$SYSTEM_PATH\033[0m"
            else
                echo -e "\033[1;33m→ 系统路径文件 $SYSTEM_PATH 不存在，跳过删除\033[0m"
            fi
            
            if [ -f "$USER_PATH" ]; then
                sudo rm -f "$USER_PATH"
                echo -e "\033[1;32m→ 已删除用户路径文件：$USER_PATH\033[0m"
            else
                echo -e "\033[1;33m→ 用户路径文件 $USER_PATH 不存在，跳过删除\033[0m"
            fi
            
            if [ -f "$KALI_PATH" ]; then
                sudo rm -f "$KALI_PATH"
                echo -e "\033[1;32m→ 已删除Kali路径文件：$KALI_PATH\033[0m"
            else
                echo -e "\033[1;33m→ Kali路径文件 $KALI_PATH 不存在，跳过删除\033[0m"
            fi
            sleep 0.5
            
            cd ~ || {
                echo -e "\033[1;31m错误：再次切换到主目录失败！\033[0m"
                return 1
            }
            
            if [ -d "sakisp" ]; then
                sudo rm -rf "sakisp"
                echo -e "\033[1;32m→ 已删除 sakisp 文件夹\033[0m"
            else
                echo -e "\033[1;33m→ sakisp 文件夹不存在，跳过删除\033[0m"
            fi
            
            if [ -d ".sakisp-repo" ]; then
                sudo rm -rf ".sakisp-repo"
                echo -e "\033[1;32m→ 已删除 .sakisp-repo 文件夹\033[0m"
            else
                echo -e "\033[1;33m→ .sakisp-repo 文件夹不存在，跳过删除\033[0m"
            fi
            sleep 0.5
            
            echo -e "\n\033[1;35m=================================================\033[0m"
            echo -e "\033[1;32m✅ SakiSP 脚本已成功卸载完毕！（如在文件夹内,输入cd即可退出该文件夹，然后使用ls检查）\033[0m"
            echo -e "\033[1;34m感谢您曾与 SakiSP 相伴，期待未来再次相遇～\033[0m"
            echo -e "\033[1;35m=================================================\033[0m"
            echo -e "\n\033[1;33m按回车键退出...\033[0m"
            read -r
            clear
            exit 1
        else
            echo -e "\033[1;33m已取消卸载操作\033[0m"
            sleep 1
            clear
            break
        fi
    done
}

software_center() {
    while true; do
        choice=$(whiptail --clear \
            --backtitle "" \
            --title "💼 软件中心 - 应用宝库" \
            --menu "✨ 请选择软件分类： \n
在代码的世界里，每一个应用都是点亮桌面的星光... \n
🔧 提示：使用 ↓↑ 键导航，按 Enter 确认" \
            0 60 0 \
            "1" "📄 办公文档 —— 文字处理与表格工具" \
            "2" "🎬 影音娱乐 —— 视频播放与音频处理" \
            "3" "👥 社交沟通 —— 即时通讯与社交平台" \
            "4" "💻 开发工具 —— 编程环境与调试工具" \
            "5" "⌨️  输入法 —— 多语言输入解决方案" \
            "6" "🌏 浏览器 —— 网络浏览与网页工具" \
            "7" "🎮 游戏娱乐 —— 休闲游戏与电竞资源" \
            "0" "🚪 返回主菜单" \
            3>&1 1>&2 2>&3)

        case $choice in
            "1") office_menu ;;
            "2") media_menu ;;
            "3") social_menu ;;
            "4") dev_menu ;;
            "5") input_method_menu ;;
            "6") browser_menu ;;
            "7") games_menu ;;
            "0") break ;;
        esac
    done
}

# 办公软件菜单
office_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "办公文档" \
        --title " 📄 办公软件 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🏫 LibreOffice" \
        "2" "🏡 Meld" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") libreoffice_manage ;;
            "2") pkg_manage "meld" ;;
            "0") break ;;
        esac
    done
}

# 影音菜单
media_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "影音娱乐" \
        --title " 🎬 影音软件 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🎧 MPV" \
        "2" "🥥 Parole" \
        "3" "🍊 Clementine" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") pkg_manage "mpv" ;;
            "2") pkg_manage "parole" ;;
            "3") pkg_manage "clementine" ;;
            "0") break ;;
        esac
    done
}

# 社交软件菜单
social_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "社交软件" \
        --title " 👥 社交软件 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🐧 QQ" \
        "2" "🐸 微信" \
        "3" "✉️ Thunderbird" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") qq_manage ;;
            "2") wechat_manage ;;
            "3") thunderbird_manage ;;            
            "0") break ;;
        esac
    done
}

# 开发工具菜单
dev_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "开发工具" \
        --title " 💻 开发工具 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🐛 PyCharm" \
        "2" "🐭 Xfce终端" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") pycharm_menu ;;
            "2") xfce_menu ;;
            "0") break ;;
        esac
    done
}

# PyCharm安装菜单
pycharm_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "PyCharm" \
        --title " 🐍 PyCharm " \
        --menu "选择版本（建议只选一个版本）：" 15 50 5 \
        "1" "专业版" \
        "2" "社区版" \
        "3" "卸载Pychram" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") install_pycharm "professional" ;;
            "2") install_pycharm "community" ;;
            "3") remove_pycharm ;;
            "0") break ;;
        esac
    done
}

# 输入法管理
input_method_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "输入法软件" \
        --title " ⌨️ 输入法 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🍀 fcitx5" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") fcitx5_manage ;;
            "0") break ;;
        esac
    done
}

# 浏览器软件菜单
browser_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "浏览器" \
        --title " 👥 浏览器软件 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🐱 Chromium" \
        "2" "🦊 Firefox" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") chromium_manage ;;
            "2") firefox_version_choice ;;
            "0") break ;;
        esac
    done
}

# 游戏软件菜单
games_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "游戏" \
        --title " 🎮 游戏 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🎮 KDE-games" \
        "2" "👣 GNMOE-games" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") kdegames_manage ;;
            "2") gnmoegames_manage ;;
            "0") break ;;
        esac
    done
}

# 软件管理对话框
pkg_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 $pkg 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") install_pkg "$pkg" ;;
        "2") remove_pkg "$pkg" ;;
        "0") ;;
    esac
}

# 软件管理对话框
libreoffice_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 LibreOffice 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") install_libreoffice ;;
        "2") remove_libreoffice ;;
        "0") ;;
    esac
}

# xfce终端软件管理对话框
xfce_menu() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 Xfce终端 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") install_xfce_terminal ;;
        "2") uninstall_xfce_terminal ;;
        "0") ;;
    esac
}

# 卸载Xfce终端及美化配置  
uninstall_xfce_terminal() {  
    clear_terminal  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    echo -e "${RED}            确认卸载Xfce终端            ${RESET}"  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    echo -e "${YELLOW}[!] 此操作将删除Xfce终端及所有美化配置!${RESET}"  
    echo -e "${YELLOW}[?] 确定要卸载吗? (Y/n)${RESET}"  
    read -r confirm  

    if [[ $confirm =~ ^[Yy]$ ]]; then  
        # 卸载软件包  
        echo -e "${CYAN}[*] 卸载Xfce终端软件包...${RESET}"  
        sudo apt-get remove --purge xfce4-terminal -y || {  
            echo -e "${RED}[×] 软件包卸载失败，尝试强制删除...${RESET}"  
            sudo dpkg -P xfce4-terminal 2> /dev/null  
        }  
        echo -e "${GREEN}[√] 软件包卸载完成${RESET}"  

        # 删除用户配置
        echo -e "${CYAN}[*] 删除用户配置...${RESET}"  
        local user_config="$HOME/usr/share/xfce4"  
        if [ -d "$user_config" ]; then  
            sudo rm -rf "$user_config"  
            echo -e "${GREEN}[√] 用户配置目录 $user_config 已删除${RESET}"  
        else  
            echo -e "${YELLOW}[!] 未检测到用户配置目录，跳过删除${RESET}"  
        fi  

        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
        echo -e "${GREEN}            Xfce终端已完全卸载!            ${RESET}"  
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
        return 0  
    else  
        echo -e "${YELLOW}[!] 已取消卸载操作，返回上一级${RESET}"  
        return 1  
    fi  
}  

# LibreOffice安装函数
install_libreoffice() {
    pretty_print "INSTALLING" "正在安装 LibreOffice..."
    sudo apt install -y libreoffice libreoffice-l10n-zh-cn libreoffice-gtk3 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nLibreOffice 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nLibreOffice 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# LibreOffice卸载函数
remove_libreoffice() {
    pretty_print "REMOVING" "正在卸载 LibreOffice..."
    sudo apt purge -y libreoffice* libreoffice-l10n-zh-cn* libreoffice-gtk3* 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nLibreOffice 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nLibreOffice 卸载失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# 切换至云崽
yunzai_switch() {
    choice=$(whiptail --clear --backtitle "即将切换至云崽" \
    --title " 📦 操作选择（谨慎选择） " \
    --menu "切换之后将无法回退这个脚本哦（同时确保是Ubuntu 22.04）：" 12 40 2 \
    "1" "🔁 切换" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") yunzai_start ;;
        "0") ;;
    esac
}

# 切换至TMOE Linux
tmoe_switch() {
    choice=$(whiptail --clear --backtitle "即将切换至TOME Linux" \
    --title " 📦 操作选择（谨慎选择） " \
    --menu "切换之后将无法回退这个脚本哦：" 12 40 2 \
    "1" "🔁 切换" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") tmoe_start ;;
        "0") ;;
    esac
}

# 切换至APT软件源管理
apt_switch() {
    choice=$(whiptail --clear --backtitle "即将切换至APT软件源管理" \
    --title " 📦 操作选择" \
    --menu "如果不确定，请勿切换该脚本：" 12 40 2 \
    "1" "🔁 切换" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        "1") apt_start ;;
        "0") ;;
    esac
}

# 系统版本检测函数
check_system() {
    pretty_print "YUNZAI" "🔍 正在检测系统版本..."
    if ! command -v lsb_release &> /dev/null; then
        echo -e "${YELLOW}⚠️ 未检测到lsb_release，尝试通过/etc/os-release判断...${RESET}"
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "22.04" ]; then
                return 0
            fi
        fi
    else
        if lsb_release -a | grep -q "Ubuntu 22.04"; then
            return 0
        fi
    fi
    echo -e "${RED}❌ 仅支持Ubuntu 22.04系统，当前系统不兼容！${RESET}"
    sleep 3
    clear
    exit 1
}

# 切换至云崽函数
yunzai_start() {
    pretty_print "YUNZAI" " ⌛️ 正在切换中...."
    echo -e "${YELLOW}温馨提示: 切换成功后将无法回退此脚本！切换前需完成网络测速，文件将自动删除${RESET}"
    
    # 检查系统版本
    check_system
    
    # 更新软件源
    pretty_print "YUNZAI" "🔄 正在更新软件源..."
    sudo apt update
    
    MIAO_MENU_PATH=""
    if [ -f /usr/bin/miao-menu ]; then
        MIAO_MENU_PATH="/usr/bin/miao-menu"
        echo -e "${GREEN}✅ 检测到菜单脚本在 /usr/local/bin${RESET}"
    elif [ -f "$HOME/.local/bin/miao-menu" ]; then
        MIAO_MENU_PATH="$HOME/.local/bin/miao-menu"
        echo -e "${GREEN}✅ 检测到菜单脚本在 $HOME/.local/bin${RESET}"
    else
        echo -e "${YELLOW}🔍 未检测到菜单脚本，正在下载安装...${RESET}"
        # 安装菜单脚本
        if ! bash <(curl -sL https://gitee.com/jizijhj/termux-yunzai-cv-script/raw/master/miao-menu.sh); then
            echo -e "${RED}❌ 菜单脚本安装失败！请检查：${RESET}"
            echo -e "  ${YELLOW}1. 网络是否通畅（可尝试手动下载脚本）${RESET}"
            echo -e "  ${YELLOW}2. 系统是否为Ubuntu 22.04${RESET}"
            sleep 5
            clear
            exit 1
        fi
        MIAO_MENU_PATH="/usr/bin/miao-menu"  
        echo -e "${GREEN}✅ 菜单脚本安装成功，继续切换流程...${RESET}"
        sleep 1
    fi
    
    # 网络测速（带镜像源切换重试机制）
    pretty_print "YUNZAI" "📶 正在进行网络测速..."
    DOWNLOAD_URL="https://mirrors.bfsu.edu.cn/ubuntu/ls-lR.gz"
    RETRY=0
    
    while [ $RETRY -lt 3 ]; do
        if wget -q $DOWNLOAD_URL; then
            echo -e "${GREEN}✅ 网络测速通过，正在切换至云崽...${RESET}"
            rm -rf ls-lR.gz
            sleep 2
            clear
            $MIAO_MENU_PATH  # 执行菜单脚本
            exit 0
        else
            RETRY=$((RETRY+1))
            if [ $RETRY -eq 1 ]; then
                echo -e "${YELLOW}⚠️ 测速失败，尝试切换至清华镜像源...${RESET}"
                DOWNLOAD_URL="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ls-lR.gz"
            elif [ $RETRY -eq 2 ]; then
                echo -e "${YELLOW}⚠️ 再次失败，尝试切换至中科大镜像源...${RESET}"
                DOWNLOAD_URL="https://mirrors.ustc.edu.cn/ubuntu/ls-lR.gz"
            else
                echo -e "${RED}❌ 网络测速连续失败！请检查网络连接后重试。${RESET}"
                sleep 3
                clear
                exit 1
            fi
        fi
    done
}

# 开始切换至TMOE Linux
tmoe_start() {
    pretty_print "TMOE" " ⌛️ 正在切换中...."
    echo -e "${YELLOW}温馨提示:切换成功后将无法回退此脚本！切换之前，我们需要对你的网络进行测速，完成之后会删除，请您放心${RESET}"
    sudo apt update
    if wget https://mirrors.bfsu.edu.cn/ubuntu/ls-lR.gz; then
        echo -e "${GREEN}✅ 切换成功，欢迎您下次使用，再见${RESET}"
        rm -rf ./ls-lR.gz
        sleep 2
        clear
        bash -c "$(curl -L gitee.com/mo2/linux/raw/2/2)"
        exit
    else
        echo -e "${RED}❌ 切换失败，请检查网络连接是否正常。如有疑问，请联系开发者！${RESET}"
        sleep 3
        clear
    fi
}

# 开始切换至APT软件源管理
apt_start(){
    pretty_print APT "⌛️ 正在切换中...";
    sudo -v || { echo -e "${RED}❌ 请输入sudo密码授权${RESET}"; exit 1; };
    ping -c3 www.baidu.com &>/dev/null || { echo -e "${RED}❌ 网络不通${RESET}"; exit 1; };
    sudo bash -c "bash <(curl -sSL https://linuxmirrors.cn/main.sh)" && echo -e "${GREEN}✅ 执行完成${RESET}" || echo -e "${RED}❌ 执行失败${RESET}";
    sleep 3; clear;
}

# QQ ARM64安装
install_qqarm64() {
    pretty_print "QQ" "正在下载QQ安装包...（若无法打开，请在应用程序里添加 --no-sandbox）"
    wget -O /tmp/qq.deb "https://dldir1v6.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.18_250626_arm64_01.deb"
    if sudo apt install -y /tmp/qq.deb; then
        whiptail --title "完成" --msgbox "\nQQ 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nQQ 安装失败" 10 40
    fi
    rm -f /tmp/qq.deb
}

# QQ AMD64安装
install_qqamd64() {
    pretty_print "QQ" "正在下载QQ安装包...（若无法打开，请在应用程序里添加 --no-sandbox）"
    wget -O /tmp/qq.deb "https://dldir1v6.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.18_250626_amd64_01.deb"
    if sudo apt install -y /tmp/qq.deb; then
        whiptail --title "完成" --msgbox "\nQQ 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nQQ 安装失败" 10 40
    fi
    rm -f /tmp/qq.deb
}

# 微信 ARM64安装
install_wechatarm64() {
    pretty_print "WECHAT" "正在下载微信安装包...（可能不一定能打开，建议谨慎安装）"
    wget -O /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"
    if sudo apt install -y /tmp/wechat.deb; then
        whiptail --title "完成" --msgbox "\n微信 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n微信 安装失败" 10 40
    fi
    rm -f /tmp/wechat.deb
}

# 微信 AMD64安装
install_wechatamd64() {
    pretty_print "WECHAT" "正在下载微信安装包...（可能不一定能打开，建议谨慎安装）"
    wget -O /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"
    if sudo apt install -y /tmp/wechat.deb; then
        whiptail --title "完成" --msgbox "\n微信 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n微信 安装失败" 10 40
    fi
    rm -f /tmp/wechat.deb
}

# PyCharm安装
install_pycharm() {
    ver=$1
    pretty_print "PyCharm" "正在安装Java环境..."
    sudo apt install -y default-jdk default-jre libxext-dev libxi-dev libxtst-dev libxrender-dev
    sleep 3
    
    case $ver in
        "professional")
            url="https://download.jetbrains.com/python/pycharm-2025.1.tar.gz"
            ;;
        "community")
            url="https://download.jetbrains.com/python/pycharm-community-2025.1.tar.gz"
            ;;
    esac
    
    pretty_print "PyCharm" "正在下载安装包...（如无法下载或较慢，请使用魔法上网）"
    sudo apt install x11-apps -y
    wget -O /tmp/pycharm.tar.gz "$url"
    sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/
    sudo mv /opt/pycharm-* /opt/pycharm
    echo 'export PATH="/opt/pycharm/bin:$PATH"' >> ~/.bashrc
    rm -f /tmp/pycharm.tar.gz
    export DISPLAY=:3
    whiptail --title "完成" --msgbox "\nPyCharm 安装成功！\n请重新登录后生效！如果桌面上没有，请输入cd /opt/pycharm/bin/ \n再输入./pycharm.sh" 12 50
}

install_chromium() {
    clear
    local RED='\033[0;31m'
    local LIGHT_RED='\033[1;31m'
    local ORANGE='\033[0;33m'
    local YELLOW='\033[1;33m'
    local GREEN='\033[0;32m'
    local LIGHT_GREEN='\033[1;32m'
    local CYAN='\033[0;36m'
    local LIGHT_CYAN='\033[1;36m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local WHITE_BOLD='\033[1;37m'
    local RESET='\033[0m'

    pretty_print "chromium" "正在下载chromium...（proot用户请谨慎安装，chroot用户需要切换至普通用户才能启动，或者可以尝试--no-sandbox。同时安装过程中可能会存在依赖问题）"
    sleep 3
    
    local detected_system="Unknown"
    local dist_version=""
    local arch=$(dpkg --print-architecture 2>/dev/null)
    if command -v lsb_release &>/dev/null; then
        local dist=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
        dist_version=$(lsb_release -rs 2>/dev/null)
        if [ "$dist" = "ubuntu" ]; then
            detected_system="Ubuntu"
        elif [ "$dist" = "debian" ]; then
            detected_system="Debian"
        elif [ "$dist" = "kali" ]; then
            detected_system="Kali"
        fi
    fi
    
    if [ "$detected_system" = "Unknown" ] && ([ -f /etc/gxde-release ] || dpkg -s gxde-desktop 2>/dev/null | grep -q "Status: install"); then
        detected_system="GXDE"
    fi

    if [ "$detected_system" = "Ubuntu" ] && [ "$dist_version" = "22.04" ]; then
        echo -e "${YELLOW}检测到Ubuntu 22.04系统${RESET}"
        echo -e "${RED}注意：Ubuntu 22.04版本安装Chromium过程中可能会存在依赖问题${RESET}"
        echo -e "${RED}如有这个问题，请不要将此问题反馈给我们，请自行解决；建议谨慎考虑再操作${RESET}\n"

        local countdown=10
        local colors=("${RED}" "${LIGHT_RED}" "${ORANGE}" "${YELLOW}" "${GREEN}" "${LIGHT_GREEN}" "${CYAN}" "${LIGHT_CYAN}" "${BLUE}" "${PURPLE}")
        while [ $countdown -ge 1 ]; do
            local color_index=$((10 - countdown))
            echo -ne "${colors[$color_index]} ${countdown} 秒后继续 ${RESET}\r"
            sleep 1
            ((countdown--))
        done
        echo -ne "\033[K"
        echo -e "\n"

        read -p "$(echo -e ${WHITE_BOLD}请选择系统架构，如需返回输入任意即可（1=arm64，2=amd64）：${RESET}) " arch_choice
        case "$arch_choice" in
            1|arm64)
                selected_arch="arm64"
                ;;
            2|amd64)
                selected_arch="amd64"
                ;;
            *)
                echo -e "${RED}无效选择，3秒后返回...${RESET}"
                sleep 3
                return 0
                ;;
        esac

        clear

        local temp_dir="/tmp/.CHROMIUM_DEB_VAAPI_TEMP_FOLDER"
        mkdir -p "$temp_dir" || {
            echo -e "${RED}无法创建临时文件夹，安装终止${RESET}"
            return 1
        }

        if [ "$selected_arch" = "arm64" ]; then
            local debs=(
                "https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/chromium-browser_107.0.5304.62-0ubuntu1~ppa1~22.04.1_arm64.deb"
                "https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/chromium-browser-l10n_107.0.5304.62-0ubuntu1~ppa1~22.04.1_all.deb"
                "https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/chromium-codecs-ffmpeg-extra_107.0.5304.62-0ubuntu1~ppa1~22.04.1_arm64.deb"
            )
        else
            local debs=(
                "https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/chromium-browser_108.0.5359.40-0ubuntu1~ppa1~22.04.1_amd64.deb"
                "https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/chromium-codecs-ffmpeg-extra_108.0.5359.40-0ubuntu1~ppa1~22.04.1_amd64.deb"
                "https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/chromium-browser-l10n_107.0.5304.62-0ubuntu1~ppa1~22.04.1_all.deb"
            )
        fi

        local download_success=1
        for deb in "${debs[@]}"; do
            local deb_name=$(basename "$deb")
            echo -e "\n${BLUE}开始下载（${selected_arch}）：$deb_name${RESET}"
            if ! aria2c \
                --console-log-level=notice \
                --summary-interval=60 \
                --show-console-readout=true \
                --download-result=default \
                --max-tries=3 \
                --timeout=60 \
                --continue=true \
                -d "$temp_dir" \
                -o "$deb_name" \
                "$deb"; then
                echo -e "${RED}下载失败：$deb_name${RESET}"
                download_success=0
                rm -rf "$temp_dir"
                echo -e "${CYAN}已清理临时文件${RESET}"
                break
            fi
        done

        if [ $download_success -eq 1 ]; then
            echo -e "\n${YELLOW}取消相关软件包的保留设置...${RESET}"
            sudo apt-mark unhold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra 2>/dev/null

            echo -e "\n${YELLOW}检测libva2依赖...${RESET}"
            if ! dpkg -s libva2 &>/dev/null; then
                echo -e "${ORANGE}未检测到libva2，正在安装...${RESET}"
                if ! sudo apt install -y libva2; then
                    echo -e "${RED}libva2安装失败，可能影响Chromium功能${RESET}"
                fi
            else
                echo -e "${GREEN}libva2已安装，跳过安装${RESET}"
            fi

            echo -e "\n${GREEN}开始安装Chromium相关包（${selected_arch}）...${RESET}"
            sudo apt install "$temp_dir"/*.deb
            local install_exit_code=$?

            rm -rf "$temp_dir"
            echo -e "${CYAN}已清理临时文件${RESET}"

            echo -e "\n${YELLOW}设置相关软件包为保留状态...${RESET}"
            sudo apt-mark hold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra 2>/dev/null
            
            echo -e "\n${YELLOW}尝试检查Chromium...${RESET}"
            sudo aptitude update && sudo aptitude upgrade -y 2>/dev/null
            
            if [ $install_exit_code -eq 0 ]; then
                whiptail --title "安装成功" --msgbox "Chromium（${selected_arch}）已成功安装，相关软件包已设置为保留状态" 10 60
            else
                whiptail --title "安装失败" --msgbox "Chromium（${selected_arch}）安装过程中出现错误，请检查依赖问题" 10 60
            fi
        else
            whiptail --title "下载失败" --msgbox "部分安装包下载失败，无法继续安装" 10 60
        fi

        echo -e "\n${ORANGE}操作完成，相关软件包将不会被自动安装、升级或删除${RESET}"
        return 0
    fi
    
    case "$detected_system" in
        "Ubuntu")
            echo -e "${CYAN}检测到Ubuntu系统，使用PPA源安装...${RESET}"
            pkgs=("chromium" "chromium-l10n" "ungoogled-chromium")
            deps=("software-properties-common")
            ppa="ppa:xtradeb/apps"
            ;;
            
        "Debian")
            echo -e "${CYAN}检测到Debian系统，使用官方源安装...${RESET}"
            pkgs=("chromium" "chromium-l10n" "ungoogled-chromium")
            deps=()
            ;;
            
        "Kali")
            echo -e "${CYAN}检测到Kali Linux系统，使用官方源安装...${RESET}"
            echo -e "${YELLOW}提示：Kali官方源已包含Chromium，无需额外添加PPA${RESET}"
            pkgs=("chromium" "chromium-l10n" "ungoogled-chromium")
            deps=()
            ;;
            
        "GXDE")
            echo -e "${CYAN}检测到GXDE系统，使用适配安装方案...${RESET}"
            sudo apt install -y libgconf-2-4 libxtst6 libnss3
            pkgs=("chromium" "chromium-l10n")
            deps=()
            ;;
            
        *)
            echo -e "${RED}未识别的系统类型，使用通用安装方案...${RESET}"
            pkgs=("chromium" "chromium-browser" "ungoogled-chromium")
            deps=()
            ;;
    esac
    
    echo -e "${YELLOW}正在更新软件源...${RESET}"
    if ! sudo apt update; then
        whiptail --title "错误" --msgbox "软件源更新失败，请检查网络连接或源配置。" 10 60
        return 1
    fi
    
    if [ ${#deps[@]} -gt 0 ]; then
        echo -e "${GREEN}正在安装依赖...${RESET}"
        if ! sudo apt install -y "${deps[@]}"; then
            whiptail --title "依赖安装失败" --msgbox "无法安装必要依赖，Chromium安装终止。" 10 60
            return 1
        fi
    fi
    
    if [ "$detected_system" = "Ubuntu" ] && [ -n "$ppa" ]; then
        echo -e "${YELLOW}正在添加PPA源...${RESET}"
        if ! sudo add-apt-repository -y "$ppa"; then
            whiptail --title "源添加失败" --msgbox "添加PPA源失败，可能影响Chromium安装。\n建议手动检查源配置。" 10 60
        fi
        sudo apt update >/dev/null 2>&1
    fi
    
    echo -e "${GREEN}正在安装Chromium...${RESET}"
    local success_pkgs=()
    local missing_pkgs=()
    
    for pkg in "${pkgs[@]}"; do
        echo -e "${BLUE}尝试安装: ${pkg}${RESET}"
        if sudo apt install -y "$pkg"; then
            success_pkgs+=("$pkg")
        else
            missing_pkgs+=("$pkg")
            echo -e "${RED}警告: 无法定位软件包 ${pkg}${RESET}"
        fi
    done
    
    if [ -f /usr/share/applications/chromium.desktop ]; then
        sed -E '/^Exec/ s@(chromium )@\1--no-sandbox @' -i /usr/share/applications/chromium.desktop
    fi
    
    if [ ${#success_pkgs[@]} -gt 0 ]; then
        installed_msg="已成功安装: ${success_pkgs[*]}"
        if [ ${#missing_pkgs[@]} -gt 0 ]; then
            installed_msg+="\n\n未安装的包: ${missing_pkgs[*]}"
        fi
        whiptail --title "安装结果" --msgbox "$installed_msg" 12 60
    else
        error_msg="所有Chromium包均无法安装，可能原因：\n\n"
        if [ ${#missing_pkgs[@]} -gt 0 ]; then
            error_msg+="${RED}• 无法定位的软件包:${RESET} ${missing_pkgs[*]}\n\n"
        fi
        error_msg+="建议：\n1. 检查软件源是否配置正确\n2. 手动安装核心包（如 chromium）\n详细日志：/tmp/install.log"
        whiptail --title "安装失败" --msgbox "$error_msg" 14 60
        return 1
    fi
}

# 系统检测函数（使用lsb_release统一检测，支持Debian、Ubuntu、GXDE、Kali）
detect_system() {
    system="Unknown"
    # 基于当前用户家目录生成脚本路径（适配root和普通用户）
    local base_dir="$HOME/SakiSP"  
    local ORANGE_SCRIPT="$base_dir/hoshino.sh"  # 专属脚本路径（避免全局变量冲突）
    
    # 优先通过lsb_release检测系统
    if command -v lsb_release &>/dev/null; then
        dist=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')  # 系统名称转小写
        
        if [ "$dist" = "ubuntu" ]; then
            system="Ubuntu"
            return  # 识别为Ubuntu则返回
        elif [ "$dist" = "debian" ]; then
            system="Debian"
            return  # 识别为Debian则返回
        # 新增：Kali Linux 检测（lsb_release优先）
        elif [ "$dist" = "kali" ]; then
            system="Kali"
            return  # 识别为Kali则返回
        elif [ "$dist" = "arch" ] || [ "$dist" = "arch linux" ]; then
            system="Arch"  # 标记为Arch
        elif [ "$dist" = "manjaro" ] || [ "$dist" = "manjaro linux" ]; then
            system="Manjaro"  # 标记为Manjaro
        fi
    fi
    
    # 通过/etc/os-release补充检测
    if [ -f /etc/os-release ]; then
        . /etc/os-release  # 加载系统信息变量
        
        if [ "$ID" = "arch" ] && [ "$system" != "Arch" ]; then
            system="Arch"  # 补充标记Arch
        elif [ "$ID" = "manjaro" ] && [ "$system" != "Manjaro" ]; then
            system="Manjaro"  # 补充标记Manjaro
        elif [ "$ID" = "ubuntu" ] && [ "$system" = "Unknown" ]; then
            system="Ubuntu"
            return
        elif [ "$ID" = "debian" ] && [ "$system" = "Unknown" ]; then
            system="Debian"
            return
        elif [ "$ID" = "kali" ] && [ "$system" = "Unknown" ]; then
            system="Kali"
            return
        fi
    fi
    
    # 检测GXDE系统（通过特征文件或已安装包）
    if [ -f /etc/gxde-release ] || dpkg -s gxde-desktop 2>/dev/null | grep -q "Status: install"; then
        system="GXDE"
        return  # 识别为GXDE则返回
    fi
    
    # Arch系特征检测（通过pacman包管理器）
    if command -v pacman &>/dev/null && [ "$system" = "Unknown" ]; then
        if [ -f /etc/manjaro-release ]; then
            system="Manjaro"  # 有manjaro-release文件则为Manjaro
        else
            system="Arch"  # 否则为Arch
        fi
    fi
    
    # 处理Arch/Manjaro系统：检查权限并执行脚本，完成后退出原脚本
    if [ "$system" = "Arch" ] || [ "$system" = "Manjaro" ]; then
        # 确保基础目录存在（增强容错）
        if [ ! -d "$base_dir" ]; then
            echo -e "${YELLOW}警告: 未找到基础目录 $base_dir，尝试创建...${RESET}"
            mkdir -p "$base_dir" || {  # 创建目录，-p忽略已存在
                echo -e "${RED}错误: 无法创建基础目录 $base_dir，部分功能可能受限${RESET}"
                return 1  # 创建失败则终止
            }
        fi
        
        # 检查脚本是否存在
        if [ -f "$ORANGE_SCRIPT" ]; then
            # 授予执行权限（强制确保可执行）
            echo -e "${CYAN}检测到Arch/Manjaro系统，授予脚本权限: $ORANGE_SCRIPT${RESET}"
            chmod +x "$ORANGE_SCRIPT" || {
                echo -e "${RED}错误: 无法授予 $ORANGE_SCRIPT 执行权限${RESET}"
                return 1
            }
            
            # 执行专属脚本，完成后退出原脚本（防止重复）
            echo -e "${CYAN}执行专属脚本: $ORANGE_SCRIPT${RESET}"
            sleep 2
            if "$ORANGE_SCRIPT"; then
                echo -e "${GREEN}专属脚本执行完成，退出原脚本...${RESET}"
                exit 0  # 脚本执行成功，原脚本一同退出
            else
                echo -e "${RED}错误: 专属脚本执行失败${RESET}"
                exit 1  # 执行失败也退出原脚本，避免残留
            fi
        else
            # 脚本不存在时提示警告
            echo -e "${YELLOW}警告: 未找到Arch/Manjaro专属配置文件 $ORANGE_SCRIPT，部分功能可能受限${RESET}"
            return  # 不退出，继续执行原脚本后续逻辑
        fi
    fi
    
    # 未支持系统提醒（修改：加入Kali，排除支持列表）
    if ! [[ "$system" =~ ^(Debian|Ubuntu|GXDE|Kali)$ ]]; then
        system_warning  # 调用系统警告函数
    fi
}

# 未支持系统警告函数（保持不变）
system_warning() {
    clear
    pretty_print "WARNING" "检测到非支持的系统: $system"
    echo -e "\n${YELLOW}⚠ 警告: 此脚本主要针对以下系统优化：${RESET}"
    echo -e "  ${GREEN}• Debian${RESET} (如 Debian 10/11/12)"
    echo -e "  ${GREEN}• Ubuntu${RESET} (如 Ubuntu 20.04/22.04/24.04)"
    echo -e "  ${GREEN}• GXDE${RESET} (含此桌面环境的系统)"
    # 新增：在支持列表中显示Kali
    echo -e "  ${GREEN}• Kali${RESET} (如 Kali Linux 2023.x/2024.x)\n"
    
    echo -e "${CYAN}💡 提示:${RESET}"
    echo -e "  1. 脚本可能无法正常工作，建议在支持的系统中使用"
    echo -e "  2. 若需支持此系统，请联系开发者适配\n"
    sleep 3
    
    whiptail --title "系统提示" --msgbox "检测到未支持的系统: $system\n\n脚本将继续执行，但可能存在兼容性问题。" 12 60
}

# 主程序入口（无需修改，Kali会跳过二次确认）
main() {
    detect_system
    install_deps
    show_launch_animation
    # 安装到系统路径（首次运行或更新时执行）
    install_to_system_path
    
    # 对未支持系统增加二次确认（Kali属于支持系统，不会进入此逻辑）
    if [ "$system" != "Debian" ] && [ "$system" != "Ubuntu" ] && [ "$system" != "GXDE" ] && [ "$system" != "Kali" ]; then
        choice=$(whiptail --clear --title "系统兼容性提示" \
            --yesno "检测到未支持的系统: $system\n\n继续执行可能导致功能异常，不建议继续使用，是否继续?" 10 60)
        if [ $? -ne 0 ]; then
            echo -e "${RED}用户取消执行，脚本退出。${RESET}"
            exit 1
        fi
    fi
    
    main_menu
}

# 执行主程序
main
