#!/bin/bash

# 版本号定义（仅用于显示）
CURRENT_VERSION="V14.0.5"
GITEE_REPO="https://github.com/YingLi606/MikuOne"

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
    SYSTEM_INSTALL_PATH="/usr/games/hoshino"
else
    # 普通用户使用主目录路径
    SYSTEM_INSTALL_PATH="$HOME/.local/bin/hoshino"
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

print_banner() {
  clear
  
  # MIKU艺术字（零间隔颜色前缀）
  echo -e "\n${BLUE}███╗   ${GREEN}██╗  ${YELLOW}█████╗ ${MAGENTA}█████╗"
  echo -e "${BLUE}████╗  ${GREEN}██║  ${YELLOW}██╔══██╗${MAGENTA}██╔══██╗"
  echo -e "${BLUE}██╔██╗ ${GREEN}██║  ${YELLOW}███████║${MAGENTA}██║  ██║"
  echo -e "${BLUE}██║╚██╗${GREEN}██║  ${YELLOW}██╔══██║${MAGENTA}██║  ██║"
  echo -e "${BLUE}██║ ╚████║${YELLOW}██║  ██║${MAGENTA}██████╔╝"
  echo -e "${BLUE}╚═╝  ╚═══╝${YELLOW}╚═╝  ╚═╝${MAGENTA}╚═════╝${RESET}"
  
  # 边框与标题（保持零间隔风格）
  echo -e "${GREEN}■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■${RESET}"
  echo -e "${RED}▶${YELLOW}▶${GREEN}▶${CYAN}      Hoshino v14.0.5      ${GREEN}◀${YELLOW}◀${RED}◀${RESET}"
  echo -e "${GREEN}■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■${RESET}\n"
}

show_launch_animation() {
  # 阶段1：MIKU艺术字
  print_banner
  
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

    echo -e "        ${WHITE}即将进入Miku管理中心...${RESET}"
    sleep 1.2
    clear
}

# 安装依赖（适配Arch/Manjaro，优化yay安装方式）
install_deps() {
    # 依赖分类：官方仓库包（pacman可直接安装）
    local official_deps=("libnewt" "wget" "figlet" "jq" "unzip" "curl")
    local aur_deps=("lolcat")  # AUR包，需yay辅助安装
    local missing_official=()
    local missing_aur=()

    # 检查官方依赖
    for dep in "${official_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_official+=("$dep")
        fi
    done

    # 检查AUR依赖
    for dep in "${aur_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_aur+=("$dep")
        fi
    done

    if [ ${#missing_official[@]} -gt 0 ] || [ ${#missing_aur[@]} -gt 0 ]; then
        echo -e "${RED}⚠ 正在安装缺失的依赖: ${missing_official[*]} ${missing_aur[*]} ${RESET}"
        
        # 确保aria2安装
        if ! command -v aria2c &> /dev/null; then
            echo -e "${YELLOW}安装aria2...${RESET}"
            sleep 2
            if ! sudo pacman -S aria2 --noconfirm; then
                whiptail --title "错误" --msgbox "aria2安装失败，请检查网络。" 10 60
                exit 1
            fi
        fi     
        
        # 更新仓库索引
        if ! sudo pacman -Sy; then
            whiptail --title "错误" --msgbox "pacman仓库更新失败，请检查网络。" 10 60
            exit 1
        fi

        # 安装官方依赖
        if [ ${#missing_official[@]} -gt 0 ]; then
            echo -e "${YELLOW}安装官方依赖: ${missing_official[*]}${RESET}"
            if ! sudo pacman -S "${missing_official[@]}" --noconfirm; then
                whiptail --title "错误" --msgbox "官方依赖安装失败。" 10 60
                exit 1
            fi
        fi

        # 处理AUR依赖（需yay）
        if [ ${#missing_aur[@]} -gt 0 ]; then
            # 安装yay（优先Manjaro社区仓库，用pacman）
            if ! command -v yay &> /dev/null; then
                echo -e "${YELLOW}安装AUR助手yay...${RESET}"
                sleep 3
                # 检测系统是否为Manjaro（Manjaro的community仓库有yay）
                if grep -q "Manjaro" /etc/os-release; then
                    # Manjaro用pacman安装yay（社区仓库）
                    if ! sudo pacman -S yay --noconfirm; then
                        whiptail --title "错误" --msgbox "Manjaro安装yay失败，请确保启用community仓库。" 10 60
                        exit 1
                    fi
                else
                    # Arch Linux：官方仓库无yay，需提示用户（因用户要求不用编译）
                    whiptail --title "提示" --msgbox "Arch Linux官方仓库无yay，需手动安装AUR助手（如yay）。\n\n可参考: 启用AUR后，用其他AUR助手安装yay。" 12 60
                    exit 1
                fi
            fi

            # 用yay安装AUR依赖
            echo -e "${YELLOW}安装AUR依赖: ${missing_aur[*]}${RESET}"
            if ! yay -S "${missing_aur[@]}" --noconfirm; then
                whiptail --title "错误" --msgbox "AUR依赖安装失败。" 10 60
                exit 1
            fi
        fi
    fi
}

# 安装到系统路径函数（适配Arch/Manjaro，带错误处理）
install_to_system_path() {
    # 检查源文件是否存在
    if [ ! -f "$LOCAL_SCRIPT_PATH" ]; then
        echo -e "${RED}❌ 错误：源脚本文件不存在 - $LOCAL_SCRIPT_PATH${RESET}"
        return 1
    fi
    
    # 检查是否需要安装或更新（源文件新于系统文件则更新）
    if [ ! -f "$SYSTEM_INSTALL_PATH" ] || [ "$LOCAL_SCRIPT_PATH" -nt "$SYSTEM_INSTALL_PATH" ]; then
        pretty_print "INSTALLING" "正在将脚本安装到系统路径..."
        
        # 确保目标目录存在（Arch系推荐/usr/local/bin作为用户程序安装路径）
        sudo mkdir -p "$(dirname "$SYSTEM_INSTALL_PATH")"
        
        # 复制脚本到系统路径（带详细错误提示）
        if sudo cp "$LOCAL_SCRIPT_PATH" "$SYSTEM_INSTALL_PATH"; then
            # 设置执行权限
            sudo chmod +x "$SYSTEM_INSTALL_PATH"
            
            # 添加到PATH环境变量（Arch系默认包含/usr/local/bin，按需处理）
            target_dir="$(dirname "$SYSTEM_INSTALL_PATH")"
            # 检查目标目录是否已在PATH中
            if ! echo "$PATH" | grep -q "$target_dir"; then
                # 适配bash和zsh（Manjaro默认用zsh）
                for shell_rc in ~/.bashrc ~/.zshrc; do
                    if [ -f "$shell_rc" ]; then
                        echo "export PATH=\"$target_dir:\$PATH\"" >> "$shell_rc"
                        echo -e "${GREEN}已添加$target_dir到$shell_rc的PATH环境变量${RESET}"
                    fi
                done
                # 立即生效环境变量
                source ~/.bashrc 2>/dev/null
                source ~/.zshrc 2>/dev/null
            fi
            
            echo -e "${GREEN}✅ 脚本已成功安装${RESET}"
            echo -e "${GREEN}下次可直接使用 'hoshino' 命令启动${RESET}"
            sleep 2
        else
            echo -e "${RED}❌ 安装到系统路径失败，可能原因：${RESET}"
            echo -e "  1. 缺少sudo权限（请确保用户在sudoers中）"
            echo -e "  2. $target_dir 目录不可写（建议检查目录权限）"
            echo -e "${YELLOW}如需帮助，可前往项目仓库提交issue说明问题${RESET}"
            sleep 3
        fi
    else
        echo -e "${CYAN}✔ 系统路径已存在最新版本，无需安装${RESET}"
    fi
}

# 美化输出（保持不变，无系统差异）
pretty_print() {
    clear
    figlet -f slant "$1"
    echo -e "\n${CYAN}$2${RESET}"
}

# 通用安装函数（适配pacman）
install_pkg() {
    pretty_print "INSTALLING" "正在安装 $1 ..."
    # Arch系用pacman安装，--noconfirm自动确认，-S为安装指令
    sudo pacman -S --noconfirm "$1" 2>&1 | tee /tmp/install.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "$1 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n${RED}$1 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# 通用卸载函数（适配pacman）
remove_pkg() {
    pretty_print "REMOVING" "正在卸载 $1 ..."
    # -Rns：移除包+依赖+配置文件（Arch系常规卸载方式），--noconfirm自动确认
    sudo pacman -Rns --noconfirm "$1" 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\n$1 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n$1 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# QQ软件管理对话框（无系统差异，保持不变）
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

# QQ软件选择架构管理框（无系统差异，保持不变）
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

# QQ卸载函数（适配pacman）
remove_qq() {
    pretty_print "REMOVING" "正在卸载 QQ..."
    # pacman移除QQ相关包，-Rns清理依赖和配置
    sudo pacman -Rns --noconfirm linuxqq* 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nQQ 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nQQ 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# 微信软件管理对话框（无系统差异，保持不变）
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

# 微信软件选择架构管理框（无系统差异，保持不变）
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

# 微信卸载函数（适配pacman）
remove_wechat() {
    pretty_print "REMOVING" "正在卸载 微信..."
    # Arch系用pacman彻底卸载并清理配置，--noconfirm自动确认
    sudo pacman -Rns --noconfirm wechat 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\n微信 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n微信 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# Pycharm卸载函数（适配Arch路径习惯，无包管理差异）
remove_pycharm() {
    pretty_print "REMOVING" "正在卸载 $1 ..."
    sleep 3
    # Arch系Pycharm通常也安装在/opt目录，路径逻辑不变
    rm -rf /opt/pycharm 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nPycharm 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nPycharm 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# Chromium软件管理对话框（无系统差异，保持不变）
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

# Chromium卸载函数（适配pacman）
remove_chromium() {
    pretty_print "REMOVING" "正在卸载 Chromium..."
    # Arch系Chromium相关包卸载，--noconfirm自动确认
    sudo pacman -Rns --noconfirm chromium 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nChromium 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nChromium 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# fcitx5管理对话框（无系统差异，保持不变）
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

# fcitx5卸载函数（适配pacman）
remove_fcitx5() {
    pretty_print "REMOVING" "正在卸载 fcitx5 ..."
    # Arch系fcitx5相关包名与Debian系基本一致，直接替换卸载命令
    sudo pacman -Rns --noconfirm fcitx5-chinese-addons fcitx5 kde-config-fcitx5 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nfcitx5 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nfcitx5 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# 基础功能函数（无系统差异，保持不变）
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

# Firefox版本选择菜单（保持交互逻辑不变）
firefox_version_choice() {
    local choice=$(whiptail --clear --backtitle "Firefox安装" \
        --title " 📦 版本选择 " \
        --menu "请选择要安装的Firefox版本：" 12 40 2 \
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
    local version_name
    local pkg_name
    
    # 定义版本对应信息
    if [ "$version" = "regular" ]; then
        version_name="Firefox 常规版"
        pkg_name="firefox"
    else
        version_name="Firefox ESR"
        pkg_name="firefox-esr"
    fi
    
    clear_terminal
    echo -e "${CYAN}===== 重新安装 $version_name =====${RESET}"
    echo -e "${YELLOW}流程：卸载现有版本 → 清理残留依赖 → 全新安装${RESET}\n"
    
    echo -e "${BLUE}→ 第一步：卸载当前${version_name}...${RESET}"
    remove_firefox "$version"
    
    echo -e "\n${BLUE}→ 第二步：清理残留依赖包...${RESET}"
    sudo pacman -Rsns --noconfirm $(pacman -Qtdq) 2>/dev/null || true  # 清理孤立依赖
    
    echo -e "\n${BLUE}→ 第三步：开始全新安装${version_name}...${RESET}"
    install_firefox "$version"
    
    echo -e "\n${GREEN}✅ ${version_name} 重新安装流程已完成！${RESET}"
    delay
}

install_firefox() {
    local version=$1
    local version_name
    local pkg_name
    local lang_pkg
    local system="Unknown"
    
    # 基础信息配置
    if [ "$version" = "regular" ]; then
        version_name="Firefox 常规版"
        pkg_name="firefox"
        lang_pkg="firefox-i18n-zh-cn firefox-i18n-zh-tw"  # Arch中文语言包
    else
        version_name="Firefox ESR"
        pkg_name="firefox-esr"
        lang_pkg="firefox-esr-i18n-zh-cn firefox-esr-i18n-zh-tw"  # ESR中文包
    fi
    
    # 检测系统（Arch/Manjaro）
    if grep -q "Arch" /etc/os-release; then
        system="Arch"
    elif grep -q "Manjaro" /etc/os-release; then
        system="Manjaro"
    fi
    
    # 检查是否已安装
    if pacman -Qs "$pkg_name" &> /dev/null; then
        clear_terminal
        echo -e "${YELLOW}检测到已安装 $version_name，操作选项：(Y/m/n)${RESET}"
        echo -e "${YELLOW}Y: 重新安装 | m: 管理菜单 | n: 取消${RESET}"
        read -r choice
        
        case "$choice" in
            [Yy]) ;;  # 继续安装（覆盖）
            [Mm]) firefox_operation_menu "$version" "$version_name"; return 1 ;;
            *) echo -e "${YELLOW}已取消操作，返回主菜单${RESET}"; delay; return 1 ;;
        esac
    fi
    
    clear_terminal
    echo -e "${CYAN}===== $version_name 安装流程 =====${RESET}"
    echo -e "${CYAN}检测到系统: $system | 语言包: ${lang_pkg}${RESET}"
    echo -e "${CYAN}================================${RESET}"
    delay 1
    
    # Arch/Manjaro无需添加PPA，直接从官方仓库或AUR安装
    echo -e "${BLUE}更新系统包数据库...${RESET}"
    sudo pacman -Sy --noconfirm || { 
        echo -e "${RED}包数据库更新失败，请检查网络${RESET}"; delay; return 1; 
    }
    
    clear_terminal
    echo -e "${CYAN}正在安装 $version_name 及中文包...${RESET}"
    echo -e "${YELLOW}安装包列表:${RESET}"
    echo -e "  - $pkg_name (本体)"
    echo -e "  - ${lang_pkg} (中文语言包)"
    echo -e "  - ffmpeg (多媒体支持)${RESET}"
    delay 1
    
    # 安装主程序+语言包+依赖（优先用pacman，如需AUR包自动切换yay）
    install_cmd="sudo pacman -S --noconfirm"
    if ! $install_cmd "$pkg_name" "$lang_pkg" ffmpeg; then
        echo -e "${YELLOW}官方仓库安装失败，尝试AUR安装...${RESET}"
        install_cmd="yay -S --noconfirm"  # 切换到yay（处理AUR包）
        if ! $install_cmd "$pkg_name" "$lang_pkg" ffmpeg; then
            echo -e "${RED}安装失败，是否重试? (Y/n)${RESET}"
            read -r choice
            if [[ $choice =~ ^[Yy]$ ]]; then
                $install_cmd "$pkg_name" "$lang_pkg" ffmpeg || {
                    echo -e "${RED}二次安装失败，请手动检查依赖${RESET}"; delay; return 1
                }
            else
                echo -e "${YELLOW}已取消安装${RESET}"; delay; return 1
            fi
        fi
    fi
    
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
    
    # 基础信息配置
    if [ "$version" = "regular" ]; then
        version_name="Firefox 常规版"
        pkg_name="firefox"
        config_dir=".mozilla/firefox"
    else
        version_name="Firefox ESR"
        pkg_name="firefox-esr"
        config_dir=".mozilla/firefox-esr"
    fi

    clear_terminal
    echo -e "${YELLOW}确定要卸载 $version_name 吗?（Y/n）${RESET}"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在卸载 $version_name 及相关组件...${RESET}"
        
        # 卸载主程序（包括配置文件和冗余依赖）
        sudo pacman -Rns --noconfirm "$pkg_name" || {
            echo -e "${YELLOW}主程序卸载失败，尝试强制清理...${RESET}"
            yay -Rns --noconfirm "$pkg_name"  # 用yay处理残留
        }
        
        # 卸载中文语言包（匹配所有相关语言包）
        lang_pkgs=$(pacman -Qq | grep -E "^${pkg_name}-i18n-zh.*$")
        if [ -n "$lang_pkgs" ]; then
            sudo pacman -Rns --noconfirm $lang_pkgs || true
            echo -e "${GREEN}已卸载中文语言包: $lang_pkgs${RESET}"
        fi
        
        # 清理孤立依赖
        sudo pacman -Rsns --noconfirm $(pacman -Qtdq) 2>/dev/null || true
        
        # 清理用户配置
        if [ -d "$HOME/$config_dir" ]; then
            rm -rf "$HOME/$config_dir"
            echo -e "${GREEN}已删除用户配置: $HOME/$config_dir${RESET}"
        else
            echo -e "${YELLOW}未找到用户配置目录${RESET}"
        fi
        
        echo -e "${GREEN}$version_name 已完全卸载${RESET}"
    else
        echo -e "${YELLOW}已取消卸载操作${RESET}"
    fi
    delay
}

# KDE-GAMES软件管理对话框（保持交互逻辑不变）
kdegames_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 KDE-Games 的操作：" 12 40 3 \
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

# KDE-GAMES安装函数（适配pacman）
install_kdegames() {
    pretty_print "GAMES" "正在安装 KDE-Games..."
    # Arch系KDE游戏包名与功能和Debian系一致，直接替换安装命令
    sudo pacman -S --noconfirm \
    kdegames-meta \  # KDE游戏元包（包含大部分游戏）
    bomber bovo granatier kapman katomic kblackbox kblocks kbounce kbreakout \
    kdiamond kfourinline kgoldrunner kigo killbots kiriki kjumpingcube klickety \
    klines kmahjongg kmines knavalbattle knetwalk knights kolf kollision konquest \
    kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick \
    lskat palapeli picmi kajongg 2>&1 | tee /tmp/install.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nKDE-Games 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nKDE-Games 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# KDE-GAMES卸载函数
remove_kdegames() {
    pretty_print "REMOVING" "正在卸载 KDE-Games..."
    # 彻底卸载并清理配置文件和依赖
    sudo pacman -Rns --noconfirm \
    kdegames-meta \
    bomber bovo granatier kapman katomic kblackbox kblocks kbounce kbreakout \
    kdiamond kfourinline kgoldrunner kigo killbots kiriki kjumpingcube klickety \
    klines kmahjongg kmines knavalbattle knetwalk knights kolf kollision konquest \
    kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick \
    lskat palapeli picmi kajongg 2>&1 | tee /tmp/uninstall.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nKDE-Games 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nKDE-Games 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

# GNOME-GAMES软件管理对话
gnomegames_manage() {
    pkg=$1
    choice=$(whiptail --clear --backtitle "软件管理" \
    --title " 📦 操作选择 " \
    --menu "请选择对 GNOME-Games 的操作：" 12 40 3 \
    "1" "📥 安装" \
    "2" "🗑️ 卸载" \
    "0" "🔙 返回" \
    3>&1 1>&2 2>&3)

    case $choice in
        1) install_gnomegames ;;
        2) remove_gnomegames ;;
        0) ;;
    esac
}

# GNOME-GAMES安装函数
install_gnomegames() {
    pretty_print "GAMES" "正在安装 GNOME-Games..."
    # Arch系GNOME游戏包名与Debian系一致，直接替换安装命令
    sudo pacman -S --noconfirm \
    gnome-games \  # GNOME游戏集合元包
    phosh-games gnustep-games five-or-more four-in-a-row gnome-chess gnome-klotski \
    gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin \
    gnome-tetravex hitori iagno lightsoff quadrapassel swell-foop tali 2>&1 | tee /tmp/install.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nGNOME-Games 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nGNOME-Games 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# GNOME-GAMES卸载函数
remove_gnomegames() {
    pretty_print "REMOVING" "正在卸载 GNOME-Games..."
    # 彻底卸载并清理配置文件和依赖
    sudo pacman -Rns --noconfirm \
    gnome-games \
    phosh-games gnustep-games five-or-more four-in-a-row gnome-chess gnome-klotski \
    gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin \
    gnome-tetravex hitori iagno lightsoff quadrapassel swell-foop tali 2>&1 | tee /tmp/uninstall.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nGNOME-Games 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nGNOME-Games 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
    fi
}

check_update() {
    # 定义颜色常量
    local RED="\033[1;31m"
    local GREEN="\033[1;32m"
    local YELLOW="\033[1;33m"
    local BLUE="\033[1;34m"
    local PURPLE="\033[1;35m"
    local RESET="\033[0m"

    # 禁止自动更新的路径
    local SYSTEM_PATH="/usr/games/hoshino"
    local USER_PATH="$HOME/.local/bin/hoshino"
    local CURRENT_SCRIPT=$(readlink -f "$0")

    # 系统路径保护提示
    if [[ "$CURRENT_SCRIPT" == "$SYSTEM_PATH" || "$CURRENT_SCRIPT" == "$USER_PATH" ]]; then
        echo -e "\n${YELLOW}⚠️  警告：该路径禁止自动更新${RESET}"
        echo -e "请手动克隆仓库更新："
        echo -e "  ${BLUE}git clone https://github.com/YingLi606/MikuOne.git${RESET}\n"
        echo -e "${GREEN}按 Enter 键返回主菜单...${RESET}"
        read -r
        clear
        return 1
    fi

    # 基础变量定义
    local repo_url="https://github.com/YingLi606/MikuOne.git"
    local local_repo="$HOME/.hoshino_update"
    local script_path=$(readlink -f "$0")
    local script_name=$(basename "$script_path")
    local need_restart=0

    # 清屏并显示标题
    clear
    echo -e "${PURPLE}🔄 检查更新${RESET}"
    echo -e "──────────────"
    echo -e " ${BLUE}当前脚本：${RESET}$script_name"
    echo -e " ${BLUE}仓库地址：${RESET}$repo_url"
    echo -e "──────────────\n"

    # 检查git是否安装
    if ! command -v git &>/dev/null; then
        echo -e "${RED}❌ 错误：未安装git工具${RESET}"
        echo -e "请先执行安装命令："
        echo -e "  ${GREEN}sudo pacman -S git${RESET}\n"
        echo -e "${YELLOW}按任意键返回...${RESET}"
        read -n 1
        return 1
    fi

    # 初始化本地仓库（首次克隆/拉取）
    echo -e "${BLUE}【1/4】准备仓库...${RESET}"
    if [ ! -d "$local_repo" ]; then
        echo -e "  ${YELLOW}首次更新，正在克隆仓库...${RESET}"
        if git clone --depth 1 "$repo_url" "$local_repo"; then
            echo -e "  ${GREEN}✅ 仓库克隆成功${RESET}"
        else
            echo -e "${RED}❌ 错误：仓库克隆失败${RESET}\n"
            echo -e "${YELLOW}按任意键返回...${RESET}"
            read -n 1
            return 1
        fi
    else
        echo -e "  ${YELLOW}已有仓库，正在拉取最新代码...${RESET}"
        if cd "$local_repo" && git pull origin master; then
            echo -e "  ${GREEN}✅ 代码拉取成功${RESET}"
        else
            echo -e "${RED}❌ 错误：拉取更新失败${RESET}\n"
            echo -e "${YELLOW}按任意键返回...${RESET}"
            read -n 1
            return 1
        fi
    fi

    # 检查仓库中是否存在目标脚本
    local repo_script="$local_repo/$script_name"
    echo -e "\n${BLUE}【2/4】验证脚本...${RESET}"
    if [ ! -f "$repo_script" ]; then
        echo -e "${RED}❌ 错误：未找到脚本 $script_name${RESET}\n"
        echo -e "${YELLOW}按任意键返回...${RESET}"
        read -n 1
        return 1
    else
        echo -e "  ${GREEN}✅ 脚本验证通过${RESET}"
    fi

    # 比较版本差异（哈希校验）
    echo -e "\n${BLUE}【3/4】检查版本...${RESET}"
    local local_hash=$(sha256sum "$script_path" | awk '{print $1}')
    local repo_hash=$(sha256sum "$repo_script" | awk '{print $1}')

    if [ "$local_hash" = "$repo_hash" ]; then
        echo -e "${GREEN}✅ 当前已是最新版本${RESET}\n"
        echo -e "${YELLOW}按任意键返回...${RESET}"
        read -n 1
        return 0
    fi

    # 覆盖更新并重启
    echo -e "\n${BLUE}【4/4】执行更新...${RESET}"
    if cp -f "$repo_script" "$script_path" && chmod +x "$script_path"; then
        need_restart=1
        echo -e "  ${GREEN}✅ 脚本覆盖成功${RESET}"
    else
        echo -e "${RED}❌ 错误：更新失败${RESET}\n"
        echo -e "${YELLOW}按任意键返回...${RESET}"
        read -n 1
        return 1
    fi

    # 重启脚本
    if [ $need_restart -eq 1 ]; then
        echo -e "\n${GREEN}✅ 更新完成！即将重启${RESET}"
        echo -e "  ${YELLOW}3秒后自动重启...${RESET}"
        sleep 3
        exec "$script_path" "$@"
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
                        # 重装流程（卸载+安装+美化）
                        echo -e "${YELLOW}[!] 正在卸载Xfce终端...${RESET}"  
                        sudo pacman -Rns --noconfirm xfce4-terminal || {  # 替换apt为pacman
                            echo -e "${RED}[×] 卸载失败，尝试强制删除...${RESET}"  
                            sudo pacman -Rdd --noconfirm xfce4-terminal 2>/dev/null || {  # 强制卸载（忽略依赖）
                                echo -e "${RED}[×] 请手动卸载软件包${RESET}"; delay 1; return 1  
                            }  
                        }  

                        echo -e "${YELLOW}[!] 重新安装Xfce终端...${RESET}"  
                        sudo pacman -Sy --noconfirm || {  # pacman更新数据库
                            echo -e "${RED}[×] pacman更新失败，请检查网络${RESET}"; delay 1; return 1  
                        }  
                        sudo pacman -S --noconfirm xfce4-terminal || {  # 安装命令
                            echo -e "${RED}[×] 安装失败，请手动安装${RESET}"; delay 1; return 1  
                        }  

                        echo -e "${GREEN}[√] 终端重装完成，开始美化...${RESET}"; delay 1  
                        run_xfce_terminal_beautify  
                        ;;  

                    2)  
                        # 卸载流程（终端+配置彻底删除）
                        echo -e "${YELLOW}[!] 正在卸载Xfce终端...${RESET}"  
                        sudo pacman -Rns --noconfirm xfce4-terminal || {  # 彻底卸载
                            echo -e "${RED}[×] 卸载失败，尝试强制删除...${RESET}"  
                            sudo pacman -Rdd --noconfirm xfce4-terminal 2>/dev/null || {  
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
        # 首次安装场景（安装后美化）
        echo -e "${YELLOW}[!] 未检测到Xfce终端，开始安装...${RESET}"  
        sudo pacman -Sy --noconfirm || {  # 更新数据库
            echo -e "${RED}[×] pacman更新失败，请检查网络${RESET}"; delay 1; return 1  
        }  
        sudo pacman -S --noconfirm xfce4-terminal || {  # 安装
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
    sudo mkdir -p "$dir" && sudo chmod 755 "$dir"  # 目录路径在Arch中一致，无需修改  
    echo -e "${GREEN}[√] 目录准备完成: $dir${RESET}"  
    delay 0.5  

    # 进入配置目录（权限处理与原逻辑一致）  
    cd "$dir" || {  
        echo -e "${RED}[×] 无法进入目录: $dir${RESET}"; delay 1; return 1  
    }  

    # 1. 下载Xfce官方配色方案（文件操作与包管理器无关，逻辑不变）  
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
    sudo tar -Jxvf "$xfce_scheme" > /dev/null 2>&1  # 解压逻辑不变  
    echo -e "${GREEN}[√] 解压完成${RESET}"  
    delay 0.5  

    # 2. 下载iTerm2配色方案（文件操作逻辑不变）
    echo -e "${YELLOW}[→] 下载iTerm2配色方案...${RESET}"  
    local iterm_archive="iterm-colors.tar.gz"  
    if ! sudo curl -Lo "$iterm_archive" "https://gh-proxy.com/https://github.com/mbadolato/iTerm2-Color-Schemes/archive/refs/heads/master.tar.gz"; then  
        if ! sudo curl -Lo "$iterm_archive" "https://github.com/mbadolato/iTerm2-Color-Schemes/archive/refs/heads/master.tar.gz"; then  
            echo -e "${RED}[×] 所有链接失败，请手动下载:${RESET}"  
            echo -e "${YELLOW}https://github.com/mbadolato/iTerm2-Color-Schemes/archive/refs/heads/master.tar.gz${RESET}"  
            delay 1; return 1  
        fi  
    fi  
    echo -e "${GREEN}[√] iTerm2配色压缩包下载完成${RESET}"  
    sudo tar -xf "$iterm_archive" > /dev/null 2>&1  # 解压逻辑不变  
    echo -e "${YELLOW}[→] 复制配色到Xfce终端...${RESET}"  
    local iterm_dir="iTerm2-Color-Schemes-master/xfce4terminal"  
    if [ -d "$iterm_dir" ]; then  
        sudo cp -a "$iterm_dir/." "colorschemes"  # 复制逻辑不变  
        echo -e "${GREEN}[√] iTerm2配色方案导入完成${RESET}"  
        sleep 2  
    else  
        echo -e "${YELLOW}[!] 未找到iTerm2配色目录，跳过导入${RESET}"  
        sleep 2  
    fi  
    delay 0.5  

    # 3. 清理临时文件（逻辑不变）  
    echo -e "${CYAN}[*] 清理临时文件...${RESET}"  
    sudo rm -f "$xfce_scheme" "$iterm_archive"  
    sudo rm -rf "iTerm2-Color-Schemes-master"  
    echo -e "${GREEN}[√] 临时文件清理完成${RESET}"  
    sleep 2  
    delay 0.5  

    # 完成提示（保持一致）  
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
            --title "Hoshino ${CURRENT_VERSION} - oo~ee~oo" \
            --menu "✨ 请选择类别： \n
未被定义的，那一刻，在代码与现实间闪烁... \n
🔧 提示：使用 ↓↑ 键导航，按 Enter 确认；Hoshino 12.5，简化带来自由" \
            0 60 0 \
            "1" "💼 软件中心 —— 应用宝库" \
            "2" "🗄 工具箱 —— 一些有用的工具" \
            "3" "🚙 网速测试 —— 实时网络性能检测" \
            "4" "🔁 切换脚本管理 —— 进入切换脚本管理" \
            "5" "🔍 检查更新 —— 检测工具集更新" \
            "0" "🚪 退出工具" \
            3>&1 1>&2 2>&3)

        case $choice in
            "1") software_center ;;
            "2") tools_manage ;;
            "3") speed_test ;;
            "4") switch_manage ;;
            "5") check_update ;;
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
                    sudo pacman -Syu &> /dev/null
                    sudo pacman -S neofetch &> /dev/null
                    
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
                            sudo pacman -S fastfetch &> /dev/null
                            
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
                uninstall_mikuone
                ;;

            "0") 
                clear
                break
                ;;
        esac
    done
}

uninstall_mikuone() {
    while true; do
        whiptail --title "卸载确认" --yesno "你确定要卸载此脚本吗？" 10 60
        if [ $? -eq 0 ]; then
            clear
            echo -e "\033[1;31m开始执行 Hoshino 脚本卸载流程...\033[0m"
            sleep 1
            
            cd ~ || {
                echo -e "\033[1;31m错误：无法切换到主目录！\033[0m"
                sleep 2
                clear
                return 1
            }
            echo -e "\033[1;34m已切换到主目录：$(pwd)\033[0m"
            sleep 0.5
            
            local SYSTEM_PATH="/usr/games/hoshino"  
            local USER_PATH="$HOME/.local/bin/hoshino"  
            local KALI_PATH="/usr/local/bin/hoshino"  

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
            
            if [ -d "mikuone" ]; then
                sudo rm -rf "MikuOne"
                echo -e "\033[1;32m→ 已删除 mikuone 文件夹\033[0m"
            else
                echo -e "\033[1;33m→ mikuone 文件夹不存在，跳过删除\033[0m"
            fi
            
            if [ -d ".hoshino_update" ]; then
                sudo rm -rf ".hoshino_update"
                echo -e "\033[1;32m→ 已删除 .hoshino_update 文件夹\033[0m"
            else
                echo -e "\033[1;33m→ .hoshino_update 文件夹不存在，跳过删除\033[0m"
            fi
            sleep 0.5
            
            echo -e "\n\033[1;35m=================================================\033[0m"
            echo -e "\033[1;32m✅ Hoshino 脚本已成功卸载完毕！（如在文件夹内,输入cd即可退出该文件夹，然后使用ls检查）\033[0m"
            echo -e "\033[1;34m感谢您曾与 Hoshino 相伴，期待未来再次相遇～\033[0m"
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

speed_test() {
    clear
    echo -e "${BLUE}══════════════════════════════════════"
    echo -e "  ${CYAN}${system} 镜像站测速工具 v2.1.5          "
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
               --summary-interval=20 \
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
            echo -e "\n${RED}✗ 连接超时！${RESET}"
            sleep 3
        fi
    done

    echo -e "\n${BLUE}════════════════ 重要提示 ════════════════"
    echo -e "${CYAN}💡 提示：下载速度 ≠ 镜像更新频率！同时我们已自动清理临时文件"
    echo -e "${YELLOW}✨ 推荐访问镜像站官网确认同步策略${RESET}\n"

    read -p "⏎ 按回车键返回主菜单..." 
    clear
}

switch_manage() {
    while true; do
        choice=$(whiptail --clear --backtitle "" \
        --title " 🔁 切换脚本管理 " \
        --menu "请选择你需要切换的脚本：" 18 60 10 \
        "1" "🍭 切换至TMOE Linux" \
        "2" "🐱 切换至云崽（仅支持Ubuntu 22.04）" \
        "3" "🐰 切换至APT软件源管理脚本" \
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

# 办公软件菜单（适配Arch包名，保持交互逻辑）
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

# 影音菜单（适配Arch包名）
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

# 社交软件菜单（保持调用适配后的管理函数）
social_menu() {
    while true; do
        choice=$(whiptail --clear --backtitle "社交软件" \
        --title " 👥 社交软件 " \
        --menu "选择操作：" 15 50 5 \
        "1" "🐧 QQ" \
        "2" "🐸 微信" \
        "0" "🔙 返回" \
        3>&1 1>&2 2>&3)

        case $choice in
            "1") qq_manage ;;  
            "2") wechat_manage ;;  
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

# 卸载Xfce终端及美化配置（适配Arch/Manjaro）
uninstall_xfce_terminal() {  
    clear_terminal  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    echo -e "${RED}            确认卸载Xfce终端            ${RESET}"  
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"  
    echo -e "${YELLOW}[!] 此操作将删除Xfce终端及所有美化配置!${RESET}"  
    echo -e "${YELLOW}[?] 确定要卸载吗? (Y/n)${RESET}"  
    read -r confirm  

    if [[ $confirm =~ ^[Yy]$ ]]; then  
        # 卸载软件包（Arch系使用pacman）
        echo -e "${CYAN}[*] 卸载Xfce终端软件包...${RESET}"  
        sudo pacman -Rns --noconfirm xfce4-terminal || {  
            echo -e "${RED}[×] 软件包卸载失败，尝试强制删除...${RESET}"  
            sudo pacman -Rdd --noconfirm xfce4-terminal 2> /dev/null  # 强制卸载（忽略依赖）
        }  
        echo -e "${GREEN}[√] 软件包卸载完成${RESET}"  

        # 删除用户配置（修正路径：Xfce终端用户配置实际路径）
        echo -e "${CYAN}[*] 删除用户配置...${RESET}"  
        local user_config="$HOME/.config/xfce4/terminal"  # 正确的用户配置路径
        if [ -d "$user_config" ]; then  
            rm -rf "$user_config"  # 用户配置无需sudo，直接删除
            echo -e "${GREEN}[√] 用户配置目录 $user_config 已删除${RESET}"  
        else  
            echo -e "${YELLOW}[!] 未检测到用户配置目录，跳过删除${RESET}"  
        fi  

        # 删除系统级美化配置（如果存在）
        local sys_config="/usr/share/xfce4/terminal/colorschemes"  
        if [ -d "$sys_config" ]; then  
            sudo rm -rf "$sys_config"  
            echo -e "${GREEN}[√] 系统美化配置 $sys_config 已删除${RESET}"  
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

# LibreOffice安装函数（适配Arch/Manjaro）
install_libreoffice() {
    pretty_print "INSTALLING" "正在安装 LibreOffice..."
    # Arch仓库中LibreOffice有两个版本：fresh（最新）和still（稳定），此处用fresh
    # 中文包为libreoffice-fresh-zh-CN，GTK3支持包为libreoffice-gtk3
    sudo pacman -S --noconfirm libreoffice-fresh libreoffice-fresh-zh-CN libreoffice-gtk3 2>&1 | tee /tmp/install.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nLibreOffice 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nLibreOffice 安装失败，请检查日志：/tmp/install.log" 12 50
    fi
}

# LibreOffice卸载函数（适配Arch/Manjaro）
remove_libreoffice() {
    pretty_print "REMOVING" "正在卸载 LibreOffice..."
    # 彻底卸载所有LibreOffice相关包（包括组件和语言包）
    sudo pacman -Rns --noconfirm $(pacman -Qq | grep -E '^libreoffice-(fresh|still|gtk3|.*-zh)') 2>&1 | tee /tmp/uninstall.log
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        whiptail --title "完成" --msgbox "\nLibreOffice 卸载成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nLibreOffice 卸载失败，请检查日志：/tmp/uninstall.log" 12 50
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
    choice=$(whiptail --clear --backtitle "即将切换至APT软件源管理脚本" \
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
    sudo pacman -Syu --noconfirm
    
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
        if ! bash <(curl -sL https://gitee.com/paimon114514/termux-yunzai-cv-script/raw/master/miao-menu.sh); then
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
    sudo pacman -Syu --noconfirm
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
    ping -c3 www.bing.com &>/dev/null || { echo -e "${RED}❌ 网络不通${RESET}"; exit 1; };
    sudo bash -c "bash <(curl -sSL https://linuxmirrors.cn/main.sh)" && echo -e "${GREEN}✅ 执行完成${RESET}" || echo -e "${RED}❌ 执行失败${RESET}";
    sleep 3; clear;
}

# QQ ARM64安装（AUR包，适配arm64架构）
install_qqarm64() {
    pretty_print "QQ" "正在通过AUR安装QQ (ARM64)...（若无法打开，尝试添加 --no-sandbox 启动参数）"
    
    # AUR中ARM64架构QQ包通常为linuxqq
    if yay -S --noconfirm linuxqq; then
        whiptail --title "完成" --msgbox "\nQQ (ARM64) 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nQQ (ARM64) 安装失败，可能AUR包不存在或架构不匹配" 10 40
    fi
}

# QQ AMD64安装（AUR包，适配x86_64架构）
install_qqamd64() {
    pretty_print "QQ" "正在通过AUR安装QQ (AMD64)...（若无法打开，尝试添加 --no-sandbox 启动参数）"
    
    # AUR中x86_64架构QQ包通常为linuxqq
    if yay -S --noconfirm linuxqq; then
        whiptail --title "完成" --msgbox "\nQQ (AMD64) 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\nQQ (AMD64) 安装失败，可能AUR包不存在或依赖冲突" 10 40
    fi
}

# 微信 ARM64安装（AUR包，适配arm64架构）
install_wechatarm64() {
    pretty_print "WECHAT" "正在通过AUR安装微信 (ARM64)...（可能存在兼容性问题，建议谨慎使用）"
    
    # AUR中ARM64架构微信包通常为wechat
    if yay -S --noconfirm wechat; then
        whiptail --title "完成" --msgbox "\n微信 (ARM64) 安装成功！" 10 40
    else
        whiptail --title "错误" --msgbox "\n微信 (ARM64) 安装失败，AUR包可能暂不支持该架构" 10 40
    fi
}

# 微信 AMD64安装（AUR包，适配x86_64架构）
install_wechatamd64() {
    pretty_print "WECHAT" "正在通过AUR安装微信 (AMD64)...（可能存在兼容性问题，建议谨慎使用）"
    
    # AUR中x86_64架构微信包通常为wechat-uos或electronic-wechat
    if yay -S --noconfirm wechat; then
        whiptail --title "完成" --msgbox "\n微信 (AMD64) 安装成功！" 10 40
    else
        # 备选包：若wechat-uos安装失败，尝试electronic-wechat
        echo -e "${YELLOW}尝试备选包安装...${RESET}"
        if yay -S --noconfirm electronic-wechat; then
            whiptail --title "完成" --msgbox "\n微信 (AMD64) 备选包安装成功！" 10 40
        else
            whiptail --title "错误" --msgbox "\n微信 (AMD64) 安装失败，建议检查AUR依赖" 10 40
        fi
    fi
}

# PyCharm安装（区分专业版/社区版，适配Arch系）
install_pycharm() {
    ver=$1
    pretty_print "PyCharm" "正在安装Java环境依赖..."
    
    # Arch系Java环境包名
    sudo pacman -S --noconfirm jdk-openjdk jre-openjdk \
        libxext libxi libxtst libxrender xorg-xauth \
        xorg-server-xvfb  
    sleep 3
    
    # 定义下载地址（使用2024.2.5版本，最新版可更新版本号）
    case $ver in
        "professional")
            url="https://download.jetbrains.com/python/pycharm-2025.1.tar.gz"
            ;;
        "community")
            url="https://download.jetbrains.com/python/pycharm-community-2025.1.tar.gz"
            ;;
    esac
    
    pretty_print "PyCharm" "正在下载安装包..."
    
    # 安装基础X11工具（Arch包名不同）
    sudo pacman -S --noconfirm xorg-xeyes 
    
    # 下载并解压
    wget -O /tmp/pycharm.tar.gz "$url" || {
        whiptail --title "错误" --msgbox "下载失败，请检查网络或URL" 10 40
        return 1
    }
    sudo mkdir -p /opt
    sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/
    sudo mv /opt/pycharm-* /opt/pycharm  # 统一目录名
    
    # 添加环境变量（适配bash和zsh，Arch默认可能用zsh）
    for shell_rc in ~/.bashrc ~/.zshrc; do
        if [ -f "$shell_rc" ]; then
            echo 'export PATH="/opt/pycharm/bin:$PATH"' >> "$shell_rc"
        fi
    done
    rm -f /tmp/pycharm.tar.gz
    
    # 提示信息优化（符合Arch用户习惯）
    whiptail --title "完成" --msgbox "\nPyCharm 安装成功！\n• 终端启动：source ~/.bashrc 或 ~/.zshrc 后输入 pycharm.sh\n• 图形界面：/opt/pycharm/bin/pycharm.sh 创建快捷方式" 12 60
}

install_chromium() {
    clear
    pretty_print "chromium" "正在准备安装Chromium...（proot用户建议添加--no-sandbox启动）"
    sleep 3
    
    # 检测系统（简化检测，Arch/Manjaro统一处理）
    if grep -q "Arch" /etc/os-release; then
        detected_system="Arch"
    elif grep -q "Manjaro" /etc/os-release; then
        detected_system="Manjaro"
    else
        detected_system="Unknown"
    fi
    
    # Arch系包名定义（官方仓库+AUR）
    # 核心包：chromium（官方）；增强包：ungoogled-chromium（AUR）
    pkgs=("chromium")  # 官方仓库包
    aur_pkgs=("ungoogled-chromium")    # AUR包
    deps=("libxss" "nss" "alsa-lib")   # 基础依赖（Arch包名更简洁）
    
    # 更新系统包数据库
    echo -e "${YELLOW}正在更新包数据库...${RESET}"
    sudo pacman -Sy --noconfirm || {
        whiptail --title "错误" --msgbox "包数据库更新失败，请检查网络" 10 40
        return 1
    }
    
    # 安装基础依赖
    if [ ${#deps[@]} -gt 0 ]; then
        echo -e "${GREEN}正在安装依赖...${RESET}"
        sudo pacman -S --noconfirm "${deps[@]}" || {
            whiptail --title "依赖失败" --msgbox "基础依赖安装失败" 10 40
            return 1
        }
    fi
    
    # 安装官方仓库包
    local success_pkgs=()
    local missing_pkgs=()
    echo -e "${GREEN}安装官方仓库包...${RESET}"
    for pkg in "${pkgs[@]}"; do
        echo -e "${BLUE}尝试安装: $pkg${RESET}"
        if sudo pacman -S --noconfirm "$pkg"; then
            success_pkgs+=("$pkg")
        else
            missing_pkgs+=("$pkg")
            echo -e "${YELLOW}警告: 包 $pkg 安装失败${RESET}"
        fi
    done
    
    # 安装AUR包（使用yay）
    echo -e "${GREEN}安装AUR包...${RESET}"
    for aur_pkg in "${aur_pkgs[@]}"; do
        echo -e "${BLUE}尝试安装AUR包: $aur_pkg${RESET}"
        if yay -S --noconfirm "$aur_pkg"; then
            success_pkgs+=("$aur_pkg")
        else
            missing_pkgs+=("$aur_pkg")
            echo -e "${YELLOW}警告: AUR包 $aur_pkg 安装失败${RESET}"
        fi
    done
    
    # 修改启动参数（添加--no-sandbox，适配非root用户）
    local desktop_files=(
        "/usr/share/applications/chromium.desktop"
        "/usr/share/applications/ungoogled-chromium.desktop"
    )
    for df in "${desktop_files[@]}"; do
        if [ -f "$df" ]; then
            sudo sed -E '/^Exec/ s@(chromium.*)@\1 --no-sandbox@' -i "$df"
        fi
    done
    
    # 结果反馈
    if [ ${#success_pkgs[@]} -gt 0 ]; then
        installed_msg="已成功安装:\n${success_pkgs[*]}"
        if [ ${#missing_pkgs[@]} -gt 0 ]; then
            installed_msg+="\n\n未安装的包:\n${missing_pkgs[*]}"
        fi
        whiptail --title "安装结果" --msgbox "$installed_msg" 12 60
    else
        whiptail --title "失败" --msgbox "所有Chromium相关包安装失败" 10 40
        return 1
    fi
}

# fcitx5安装（适配Arch/Manjaro）
install_fcitx5() {
    pretty_print "Fctix5" "正在安装Fcitx5输入法..."
    sleep 3
    echo -e "${GREEN}小提示：安装完成后，需在系统设置→区域和语言中添加fcitx5输入法${RESET}"
    
    # Arch系fcitx5相关包名（包含中文支持和KDE配置工具）
    local fcitx_pkgs=(
        "fcitx5"                  # 主程序
        "fcitx5-chinese-addons"   # 中文扩展（拼音/五笔等）
        "fcitx5-configtool"       # 图形配置工具（替代kde-config-fcitx5）
        "fcitx5-qt"               # QT程序支持
        "fcitx5-gtk"              # GTK程序支持
        "kcm-fcitx5"              
        "mozc-addon-fcitx5"       # 可选：日文支持（按需添加）
    )
    
    if sudo pacman -S --noconfirm "${fcitx_pkgs[@]}"; then
        # 配置环境变量（确保输入法正常启动）
        local env_file="/etc/environment"
        if ! grep -q "GTK_IM_MODULE=fcitx" "$env_file"; then
            echo "GTK_IM_MODULE=fcitx" | sudo tee -a "$env_file" >/dev/null
            echo "QT_IM_MODULE=fcitx" | sudo tee -a "$env_file" >/dev/null
            echo "XMODIFIERS=@im=fcitx" | sudo tee -a "$env_file" >/dev/null
            echo -e "${CYAN}已添加输入法环境变量，重启后生效${RESET}"
        fi
        whiptail --title "完成" --msgbox "\nFcitx5 安装成功！\n建议重启系统后配置输入法。" 12 40
    else
        whiptail --title "错误" --msgbox "\nFcitx5 安装失败，请检查网络或包依赖" 10 40
    fi
}

# 系统检测函数（适配Arch/Manjaro）
detect_system() {
    system="Unknown"
    
    # 通过/etc/os-release检测系统（Arch系标准方式）
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release  # 加载系统信息变量
        
        # 检测Arch Linux
        if [ "$ID" = "arch" ] || [ "$ID_LIKE" = "arch" ]; then
            system="Arch"
            return
        fi
        
        # 检测Manjaro
        if [ "$ID" = "manjaro" ]; then
            system="Manjaro"
            return
        fi
    fi
    
    # 未检测到支持的系统
    system="Unknown"
}

# 未支持系统警告函数（适配Arch系）
system_warning() {
    clear
    pretty_print "WARNING" "检测到非支持的系统: $system"
    echo -e "\n${YELLOW}⚠ 警告: 此脚本主要针对以下系统优化：${RESET}"
    echo -e "  ${GREEN}• Arch Linux${RESET}"
    echo -e "  ${GREEN}• Manjaro Linux${RESET}\n"
    
    echo -e "${CYAN}💡 提示:${RESET}"
    echo -e "  1. 脚本可能无法正常工作，建议在支持的系统中使用"
    echo -e "  2. 若需支持此系统，请联系开发者适配\n"
    sleep 3
    
    whiptail --title "系统提示" --msgbox "检测到未支持的系统: $system\n\n脚本将继续执行，但可能存在兼容性问题。" 12 60
}

# 主程序入口
main() {
    detect_system
    check_whiptail  
    install_deps    
    show_launch_animation  
    install_to_system_path 
    
    # 对未支持系统增加二次确认
    if [ "$system" != "Arch" ] && [ "$system" != "Manjaro" ]; then
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
