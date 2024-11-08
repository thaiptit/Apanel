#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Thêm một số hàm cơ bản
function LOGD() {
    echo -e "${yellow}[DEBUG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[LỖI] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[THÔNG TIN] $* ${plain}"
}

# Kiểm tra quyền root
[[ $EUID -ne 0 ]] && LOGE "LỖI: Bạn phải có quyền root để chạy script này! \n" && exit 1

# Kiểm tra hệ điều hành và gán giá trị biến release
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Không thể kiểm tra hệ điều hành, vui lòng liên hệ tác giả!" >&2
    exit 1
fi

echo "Hệ điều hành hiện tại là: $release"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

# Xác định hệ điều hành
if [[ "${release}" == "arch" ]]; then
    echo "Hệ điều hành của bạn là Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "Hệ điều hành của bạn là Parch Linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Hệ điều hành của bạn là Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Hệ điều hành của bạn là Armbian"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "Hệ điều hành của bạn là OpenSUSE Tumbleweed"
elif [[ "${release}" == "openEuler" ]]; then
    if [[ ${os_version} -lt 2203 ]]; then
        echo -e "${red} Vui lòng sử dụng OpenEuler 22.03 hoặc cao hơn ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Vui lòng sử dụng CentOS 8 hoặc cao hơn ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 2004 ]]; then
        echo -e "${red} Vui lòng sử dụng Ubuntu 20 hoặc phiên bản cao hơn!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Vui lòng sử dụng Fedora 36 hoặc cao hơn!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "amzn" ]]; then
    if [[ ${os_version} != "2023" ]]; then
        echo -e "${red} Vui lòng sử dụng Amazon Linux 2023!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Vui lòng sử dụng Debian 11 hoặc cao hơn ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 80 ]]; then
        echo -e "${red} Vui lòng sử dụng AlmaLinux 8.0 hoặc cao hơn ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Vui lòng sử dụng Rocky Linux 8 hoặc cao hơn ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ol" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Vui lòng sử dụng Oracle Linux 8 hoặc cao hơn ${plain}\n" && exit 1
    fi
else
    echo -e "${red}Hệ điều hành của bạn không được hỗ trợ bởi script này.${plain}\n"
    echo "Vui lòng đảm bảo bạn đang sử dụng một trong các hệ điều hành được hỗ trợ sau:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- OpenEuler 22.03+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 8.0+"
    echo "- Rocky Linux 8+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    echo "- Amazon Linux 2023"
    exit 1
fi

# Khai báo các biến
log_folder="${XUI_LOG_FOLDER:=/var/log}"
iplimit_log_path="${log_folder}/3xipl.log"
iplimit_banned_log_path="${log_folder}/3xipl-banned.log"

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Mặc định $2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ "${temp}" == "y" || "${temp}" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Khởi động lại bảng điều khiển, Lưu ý: Khởi động lại bảng điều khiển sẽ khởi động lại xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhấn Enter để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Chức năng này sẽ cài đặt lại phiên bản mới nhất, dữ liệu sẽ không bị mất. Bạn có muốn tiếp tục không?" "y"
    if [[ $? != 0 ]]; then
        LOGE "Đã hủy"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/thaiptit/Apanel//main/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Cập nhật hoàn tất, Bảng điều khiển đã tự động khởi động lại"
        exit 0
    fi
}

update_menu() {
    echo -e "${yellow}Cập nhật Menu${plain}"
    confirm "Chức năng này sẽ cập nhật menu với các thay đổi mới nhất." "y"
    if [[ $? != 0 ]]; then
        LOGE "Đã hủy"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi

    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/thaiptit/Apanel//main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui

    if [[ $? == 0 ]]; then
        echo -e "${green}Cập nhật thành công. Bảng điều khiển đã tự động khởi động lại.${plain}"
        exit 0
    else
        echo -e "${red}Cập nhật menu thất bại.${plain}"
        return 1
    fi
}

custom_version() {
    echo "Nhập phiên bản bảng điều khiển (ví dụ 2.4.0):"
    read tag_version

    if [ -z "$tag_version" ]; then
        echo "Phiên bản bảng điều khiển không thể để trống. Thoát."
        exit 1
    fi

    min_version="2.3.5"
    if [[ "$(printf '%s\n' "$tag_version" "$min_version" | sort -V | head -n1)" == "$tag_version" && "$tag_version" != "$min_version" ]]; then
        echo "Vui lòng sử dụng phiên bản mới hơn (ít nhất là 2.3.5). Thoát."
        exit 1
    fi

    download_link="https://raw.githubusercontent.com/thaiptit/Apanel/master/install.sh"

    # Sử dụng phiên bản bảng điều khiển đã nhập vào liên kết tải xuống
    install_command="bash <(curl -Ls $download_link) v$tag_version"

    echo "Đang tải xuống và cài đặt phiên bản bảng điều khiển $tag_version..."
    eval $install_command
}

delete_script() {
    rm "$0" # Xóa file script
    exit 1
}

uninstall() {
    confirm "Bạn có chắc chắn muốn gỡ cài đặt bảng điều khiển? xray cũng sẽ bị gỡ cài đặt!" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Đã gỡ cài đặt thành công.\n"
    echo "Nếu bạn cần cài đặt lại bảng điều khiển này, bạn có thể sử dụng lệnh dưới đây:"
    echo -e "${green}bash <(curl -Ls https://raw.githubusercontent.com/thaiptit/Apanel/master/install.sh)${plain}"
    echo ""
    trap delete_script SIGTERM
    delete_script
}

reset_user() {
    confirm "Bạn có chắc chắn muốn đặt lại tên đăng nhập và mật khẩu của bảng điều khiển không?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    read -rp "Vui lòng đặt tên đăng nhập [mặc định là tên ngẫu nhiên]: " config_account
    [[ -z $config_account ]] && config_account=$(date +%s%N | md5sum | cut -c 1-8)
    read -rp "Vui lòng đặt mật khẩu [mặc định là mật khẩu ngẫu nhiên]: " config_password
    [[ -z $config_password ]] && config_password=$(date +%s%N | md5sum | cut -c 1-8)
    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password} >/dev/null 2>&1
    /usr/local/x-ui/x-ui setting -remove_secret >/dev/null 2>&1
    echo -e "Tên đăng nhập đã được đặt lại: ${green} ${config_account} ${plain}"
    echo -e "Mật khẩu đã được đặt lại: ${green} ${config_password} ${plain}"
    echo -e "${yellow} Mã bí mật của bảng điều khiển đã bị vô hiệu hóa ${plain}"
    echo -e "${green} Vui lòng sử dụng tên đăng nhập và mật khẩu mới để truy cập bảng điều khiển X-UI. Hãy nhớ chúng! ${plain}"
    confirm_restart
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

reset_webbasepath() {
    echo -e "${yellow}Đặt lại đường dẫn cơ sở Web${plain}"

    read -rp "Bạn có chắc chắn muốn đặt lại đường dẫn cơ sở web không? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${yellow}Hủy bỏ thao tác.${plain}"
        return
    fi

    config_webBasePath=$(gen_random_string 10)

    # Áp dụng cài đặt mới cho đường dẫn cơ sở web
    /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}" >/dev/null 2>&1
    
    echo -e "Đường dẫn cơ sở web đã được đặt lại thành: ${green}${config_webBasePath}${plain}"
    echo -e "${green}Vui lòng sử dụng đường dẫn cơ sở web mới để truy cập bảng điều khiển.${plain}"
    restart
}

reset_config() {
    confirm "Bạn có chắc chắn muốn đặt lại tất cả cài đặt bảng điều khiển không? Dữ liệu tài khoản sẽ không bị mất, Tên đăng nhập và mật khẩu sẽ không thay đổi" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Tất cả cài đặt bảng điều khiển đã được đặt lại về mặc định. Vui lòng khởi động lại bảng điều khiển ngay bây giờ và sử dụng cổng ${green}2053${plain} để truy cập bảng điều khiển web"
    confirm_restart
}

check_config() {
    info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "Lỗi khi lấy cài đặt hiện tại, vui lòng kiểm tra nhật ký"
        show_menu
    fi
    LOGI "${info}"
}

set_port() {
    echo && echo -n -e "Nhập số cổng [1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "Đã hủy"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Cổng đã được đặt, Vui lòng khởi động lại bảng điều khiển ngay bây giờ và sử dụng cổng mới ${green}${port}${plain} để truy cập bảng điều khiển web"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "Bảng điều khiển đang chạy, Không cần khởi động lại, Nếu bạn cần khởi động lại, vui lòng chọn khởi động lại"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "X-UI đã khởi động thành công"
        else
            LOGE "Bảng điều khiển không thể khởi động, Có thể mất nhiều hơn hai giây để khởi động, Vui lòng kiểm tra thông tin nhật ký sau"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "Bảng điều khiển đã dừng, Không cần dừng lại nữa!"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "X-UI và xray đã dừng thành công"
        else
            LOGE "Bảng điều khiển không thể dừng lại, Có thể thời gian dừng vượt quá hai giây, Vui lòng kiểm tra thông tin nhật ký sau"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "X-UI và Xray đã khởi động lại thành công"
    else
        LOGE "Bảng điều khiển không thể khởi động lại, Có thể mất nhiều hơn hai giây để khởi động, Vui lòng kiểm tra thông tin nhật ký sau"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "X-UI đã được đặt để tự động khởi động khi khởi động hệ điều hành"
    else
        LOGE "X-UI không thể đặt tự động khởi động"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "X-UI đã hủy tự động khởi động thành công"
    else
        LOGE "X-UI không thể hủy tự động khởi động"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_banlog() {
    if test -f "${iplimit_banned_log_path}"; then
        if [[ -s "${iplimit_banned_log_path}" ]]; then
            cat ${iplimit_banned_log_path}
        else
            echo -e "${red}File nhật ký trống.${plain}\n"
        fi
    else
        echo -e "${red}Không tìm thấy file nhật ký. Vui lòng cài đặt Fail2ban và giới hạn IP trước.${plain}\n"
    fi
}

bbr_menu() {
    echo -e "${green}\t1.${plain} Bật BBR"
    echo -e "${green}\t2.${plain} Tắt BBR"
    echo -e "${green}\t0.${plain} Quay lại Menu chính"
    read -p "Chọn một tùy chọn: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        enable_bbr
        ;;
    2)
        disable_bbr
        ;;
    *) echo "Lựa chọn không hợp lệ" ;;
    esac
}

disable_bbr() {
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${yellow}BBR hiện không được bật.${plain}"
        exit 0
    fi

    # Thay thế cấu hình BBR bằng CUBIC
    sed -i 's/net.core.default_qdisc=fq/net.core.default_qdisc=pfifo_fast/' /etc/sysctl.conf
    sed -i 's/net.ipv4.tcp_congestion_control=bbr/net.ipv4.tcp_congestion_control=cubic/' /etc/sysctl.conf

    # Áp dụng thay đổi
    sysctl -p

    # Xác minh rằng BBR đã được thay thế bởi CUBIC
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "cubic" ]]; then
        echo -e "${green}BBR đã được thay thế bởi CUBIC thành công.${plain}"
    else
        echo -e "${red}Không thể thay thế BBR bằng CUBIC. Vui lòng kiểm tra cấu hình hệ thống của bạn.${plain}"
    fi
}

enable_bbr() {
    if grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf && grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${green}BBR đã được bật!${plain}"
        exit 0
    fi

    # Kiểm tra hệ điều hành và cài đặt các gói cần thiết
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -yqq --no-install-recommends ca-certificates
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum -y install ca-certificates
        ;;
    fedora | amzn)
        dnf -y update && dnf -y install ca-certificates
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm ca-certificates
        ;;
    *)
        echo -e "${red}Hệ điều hành không được hỗ trợ. Vui lòng kiểm tra script và cài đặt các gói cần thiết thủ công.${plain}\n"
        exit 1
        ;;
    esac

    # Bật BBR
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf

    # Áp dụng thay đổi
    sysctl -p

    # Xác minh rằng BBR đã được bật
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${green}BBR đã được bật thành công.${plain}"
    else
        echo -e "${red}Không thể bật BBR. Vui lòng kiểm tra cấu hình hệ thống của bạn.${plain}"
    fi
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/MHSanaei/3x-ui/raw/main/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Không thể tải xuống script, Vui lòng kiểm tra xem máy có thể kết nối với Github không"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "Nâng cấp script thành công, Vui lòng chạy lại script" && exit 0
    fi
}

# 0: đang chạy, 1: không chạy, 2: chưa cài đặt
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "${temp}" == "running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ "${temp}" == "enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Bảng điều khiển đã được cài đặt, Vui lòng không cài đặt lại"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Vui lòng cài đặt bảng điều khiển trước"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "Trạng thái bảng điều khiển: ${green}Đang chạy${plain}"
        show_enable_status
        ;;
    1)
        echo -e "Trạng thái bảng điều khiển: ${yellow}Không chạy${plain}"
        show_enable_status
        ;;
    2)
        echo -e "Trạng thái bảng điều khiển: ${red}Chưa cài đặt${plain}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Tự động khởi động: ${green}Có${plain}"
    else
        echo -e "Tự động khởi động: ${red}Không${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "Trạng thái xray: ${green}Đang chạy${plain}"
    else
        echo -e "Trạng thái xray: ${red}Không chạy${plain}"
    fi
}

firewall_menu() {
    echo -e "${green}\t1.${plain} Cài đặt tường lửa & mở cổng"
    echo -e "${green}\t2.${plain} Danh sách cho phép"
    echo -e "${green}\t3.${plain} Xóa cổng khỏi danh sách"
    echo -e "${green}\t4.${plain} Tắt tường lửa"
    echo -e "${green}\t0.${plain} Quay lại Menu chính"
    read -p "Chọn một tùy chọn: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        open_ports
        ;;
    2)
        sudo ufw status
        ;;
    3)
        delete_ports
        ;;
    4)
        sudo ufw disable
        ;;
    *) echo "Lựa chọn không hợp lệ" ;;
    esac
}

open_ports() {
    if ! command -v ufw &>/dev/null; then
        echo "Tường lửa ufw chưa được cài đặt. Đang cài đặt..."
        apt-get update
        apt-get install -y ufw
    else
        echo "Tường lửa ufw đã được cài đặt"
    fi

    # Kiểm tra nếu tường lửa đang hoạt động
    if ufw status | grep -q "Trạng thái: đang hoạt động"; then
        echo "Tường lửa đã hoạt động"
    else
        echo "Kích hoạt tường lửa..."
        # Mở các cổng cần thiết
        ufw allow ssh
        ufw allow http
        ufw allow https
        ufw allow 2053/tcp

        # Bật tường lửa
        ufw --force enable
    fi

    # Yêu cầu người dùng nhập danh sách các cổng
    read -p "Nhập các cổng bạn muốn mở (ví dụ: 80,443,2053 hoặc phạm vi 400-500): " ports

    # Kiểm tra đầu vào hợp lệ
    if ! [[ $ports =~ ^([0-9]+|[0-9]+-[0-9]+)(,([0-9]+|[0-9]+-[0-9]+))*$ ]]; then
        echo "Lỗi: Đầu vào không hợp lệ. Vui lòng nhập danh sách các cổng phân tách bằng dấu phẩy hoặc một phạm vi cổng (ví dụ: 80,443,2053 hoặc 400-500)." >&2
        exit 1
    fi

    # Mở các cổng đã chỉ định bằng ufw
    IFS=',' read -ra PORT_LIST <<<"$ports"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            # Tách phạm vi thành cổng bắt đầu và cổng kết thúc
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            ufw allow $start_port:$end_port/tcp
            ufw allow $start_port:$end_port/udp
        else
            ufw allow "$port"
        fi
    done

    # Xác nhận rằng các cổng đã được mở
    echo "Các cổng sau đã được mở:"
    ufw status | grep "ALLOW" | grep -Eo "[0-9]+(/[a-z]+)?"

    echo "Trạng thái tường lửa:"
    ufw status verbose
}

delete_ports() {
    # Yêu cầu người dùng nhập các cổng họ muốn xóa
    read -p "Nhập các cổng bạn muốn xóa (ví dụ: 80,443,2053 hoặc phạm vi 400-500): " ports

    # Kiểm tra đầu vào hợp lệ
    if ! [[ $ports =~ ^([0-9]+|[0-9]+-[0-9]+)(,([0-9]+|[0-9]+-[0-9]+))*$ ]]; then
        echo "Lỗi: Đầu vào không hợp lệ. Vui lòng nhập danh sách các cổng phân tách bằng dấu phẩy hoặc một phạm vi cổng (ví dụ: 80,443,2053 hoặc 400-500)." >&2
        exit 1
    fi

    # Xóa các cổng đã chỉ định bằng ufw
    IFS=',' read -ra PORT_LIST <<<"$ports"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            # Tách phạm vi thành cổng bắt đầu và cổng kết thúc
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            # Xóa phạm vi cổng
            ufw delete allow $start_port:$end_port/tcp
            ufw delete allow $start_port:$end_port/udp
        else
            ufw delete allow "$port"
        fi
    done

    # Xác nhận rằng các cổng đã được xóa
    echo "Đã xóa các cổng chỉ định:"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            # Kiểm tra nếu phạm vi cổng đã được xóa thành công
            (ufw status | grep -q "$start_port:$end_port") || echo "$start_port-$end_port"
        else
            # Kiểm tra nếu cổng đã được xóa thành công
            (ufw status | grep -q "$port") || echo "$port"
        fi
    done
}

run_speedtest() {
    # Kiểm tra nếu Speedtest đã được cài đặt
    if ! command -v speedtest &>/dev/null; then
        # Nếu chưa cài đặt, hãy cài đặt nó
        local pkg_manager=""
        local speedtest_install_script=""

        if command -v dnf &>/dev/null; then
            pkg_manager="dnf"
            speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
        elif command -v yum &>/dev/null; then
            pkg_manager="yum"
            speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
        elif command -v apt-get &>/dev/null; then
            pkg_manager="apt-get"
            speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
        elif command -v apt &>/dev/null; then
            pkg_manager="apt"
            speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
        fi

        if [[ -z $pkg_manager ]]; then
            echo "Lỗi: Không tìm thấy trình quản lý gói. Bạn có thể cần cài đặt Speedtest thủ công."
            return 1
        else
            curl -s $speedtest_install_script | bash
            $pkg_manager install -y speedtest
        fi
    fi

    # Chạy Speedtest
    speedtest
}

create_iplimit_jails() {
    # Sử dụng thời gian cấm mặc định nếu không có giá trị được truyền vào => 15 phút
    local bantime="${1:-15}"

    # Bỏ chú thích 'allowipv6 = auto' trong fail2ban.conf
    sed -i 's/#allowipv6 = auto/allowipv6 = auto/g' /etc/fail2ban/fail2ban.conf

    # Trên Debian 12+, backend mặc định của fail2ban nên được thay đổi thành systemd
    if [[  "${release}" == "debian" && ${os_version} -ge 12 ]]; then
        sed -i '0,/action =/s/backend = auto/backend = systemd/' /etc/fail2ban/jail.conf
    fi

    cat << EOF > /etc/fail2ban/jail.d/3x-ipl.conf
[3x-ipl]
enabled=true
backend=auto
filter=3x-ipl
action=3x-ipl
logpath=${iplimit_log_path}
maxretry=2
findtime=32
bantime=${bantime}m
EOF

    cat << EOF > /etc/fail2ban/filter.d/3x-ipl.conf
[Definition]
datepattern = ^%%Y/%%m/%%d %%H:%%M:%%S
failregex   = \[LIMIT_IP\]\s*Email\s*=\s*<F-USER>.+</F-USER>\s*\|\|\s*SRC\s*=\s*<ADDR>
ignoreregex =
EOF

    cat << EOF > /etc/fail2ban/action.d/3x-ipl.conf
[INCLUDES]
before = iptables-allports.conf

[Definition]
actionstart = <iptables> -N f2b-<name>
              <iptables> -A f2b-<name> -j <returntype>
              <iptables> -I <chain> -p <protocol> -j f2b-<name>

actionstop = <iptables> -D <chain> -p <protocol> -j f2b-<name>
             <actionflush>
             <iptables> -X f2b-<name>

actioncheck = <iptables> -n -L <chain> | grep -q 'f2b-<name>[ \t]'

actionban = <iptables> -I f2b-<name> 1 -s <ip> -j <blocktype>
            echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   BAN   [Email] = <F-USER> [IP] = <ip> đã bị cấm trong <bantime> giây." >> ${iplimit_banned_log_path}

actionunban = <iptables> -D f2b-<name> -s <ip> -j <blocktype>
              echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   UNBAN   [Email] = <F-USER> [IP] = <ip> đã được gỡ cấm." >> ${iplimit_banned_log_path}

[Init]
EOF

    echo -e "${green}Các file jail Giới hạn IP đã được tạo với thời gian cấm là ${bantime} phút.${plain}"
}

iplimit_remove_conflicts() {
    local jail_files=(
        /etc/fail2ban/jail.conf
        /etc/fail2ban/jail.local
    )

    for file in "${jail_files[@]}"; do
        # Kiểm tra sự tồn tại của cấu hình [3x-ipl] trong file jail và xóa nó
        if test -f "${file}" && grep -qw '3x-ipl' ${file}; then
            sed -i "/\[3x-ipl\]/,/^$/d" ${file}
            echo -e "${yellow}Đang xóa xung đột của [3x-ipl] trong jail (${file})!${plain}\n"
        fi
    done
}

iplimit_main() {
    echo -e "\n${green}\t1.${plain} Cài đặt Fail2ban và cấu hình Giới hạn IP"
    echo -e "${green}\t2.${plain} Thay đổi Thời gian Cấm"
    echo -e "${green}\t3.${plain} Kiểm tra Nhật ký"
    echo -e "${green}\t0.${plain} Quay lại Menu chính"
    read -p "Chọn một tùy chọn: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        install_fail2ban
        create_iplimit_jails 15
        start_fail2ban
        ;;
    2)
        read -p "Nhập thời gian cấm (phút, mặc định là 15): " bantime
        bantime=${bantime:-15}
        create_iplimit_jails $bantime
        start_fail2ban
        ;;
    3)
        show_banlog
        ;;
    *) echo "Lựa chọn không hợp lệ" ;;
    esac
}

install_fail2ban() {
    if ! command -v fail2ban &>/dev/null; then
        case "${release}" in
        ubuntu | debian)
            apt-get update
            apt-get install -y fail2ban
            ;;
        centos | almalinux | rocky | ol)
            yum install -y fail2ban
            ;;
        fedora | amzn)
            dnf install -y fail2ban
            ;;
        arch | manjaro | parch)
            pacman -S --noconfirm fail2ban
            ;;
        *)
            echo -e "${red}Hệ điều hành không được hỗ trợ.${plain}"
            exit 1
            ;;
        esac
        echo -e "${green}Fail2ban đã được cài đặt thành công.${plain}"
    else
        echo -e "${yellow}Fail2ban đã được cài đặt.${plain}"
    fi
}

start_fail2ban() {
    systemctl start fail2ban
    systemctl enable fail2ban
    echo -e "${green}Fail2ban đã được khởi động và đặt tự động khởi động.${plain}"
}

# Hiển thị cách sử dụng
show_usage() {
    echo "Sử dụng menu điều khiển x-ui:"
    echo "------------------------------------------"
    echo -e "CÁC LỆNH CON:"
    echo -e "x-ui              - Script quản lý bảng điều khiển"
    echo -e "x-ui start        - Khởi động"
    echo -e "x-ui stop         - Dừng"
    echo -e "x-ui restart      - Khởi động lại"
    echo -e "x-ui status       - Trạng thái hiện tại"
    echo -e "x-ui settings     - Cài đặt hiện tại"
    echo -e "x-ui enable       - Bật tự khởi động khi OS khởi động"
    echo -e "x-ui disable      - Tắt tự khởi động khi OS khởi động"
    echo -e "x-ui log          - Kiểm tra nhật ký"
    echo -e "x-ui banlog       - Kiểm tra nhật ký cấm Fail2ban"
    echo -e "x-ui update       - Cập nhật"
    echo -e "x-ui custom       - Phiên bản tùy chỉnh"
    echo -e "x-ui install      - Cài đặt"
    echo -e "x-ui uninstall    - Gỡ cài đặt"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}Script Quản Lý Bảng Điều Khiển 3X-UI${plain}
  ${green}0.${plain} Thoát Script
————————————————
  ${green}1.${plain} Cài đặt
  ${green}2.${plain} Cập nhật
  ${green}3.${plain} Cập nhật Menu
  ${green}4.${plain} Phiên bản Tùy chỉnh
  ${green}5.${plain} Gỡ cài đặt
————————————————
  ${green}6.${plain} Đặt lại Tên đăng nhập & Mật khẩu & Mã bí mật
  ${green}7.${plain} Đặt lại Đường dẫn Cơ sở Web
  ${green}8.${plain} Đặt lại Cài đặt
  ${green}9.${plain} Thay đổi Cổng
  ${green}10.${plain} Xem Cài đặt Hiện tại
————————————————
  ${green}11.${plain} Khởi động
  ${green}12.${plain} Dừng
  ${green}13.${plain} Khởi động lại
  ${green}14.${plain} Kiểm tra Trạng thái
  ${green}15.${plain} Kiểm tra Nhật ký
————————————————
  ${green}16.${plain} Bật Tự khởi động
  ${green}17.${plain} Tắt Tự khởi động
————————————————
  ${green}18.${plain} Quản lý Chứng chỉ SSL
  ${green}19.${plain} Chứng chỉ Cloudflare SSL
  ${green}20.${plain} Quản lý Giới hạn IP
  ${green}21.${plain} Quản lý Tường lửa
————————————————
  ${green}22.${plain} Bật BBR
  ${green}23.${plain} Cập nhật Tệp Geo
  ${green}24.${plain} Speedtest của Ookla
"
    show_status
    echo && read -p "Vui lòng nhập lựa chọn của bạn [0-24]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && update_menu
        ;;
    4)
        check_install && custom_version
        ;;
    5)
        check_install && uninstall
        ;;
    6)
        check_install && reset_user
        ;;
    7)
        check_install && reset_webbasepath
        ;;
    8)
        check_install && reset_config
        ;;
    9)
        check_install && set_port
        ;;
    10)
        check_install && check_config
        ;;
    11)
        check_install && start
        ;;
    12)
        check_install && stop
        ;;
    13)
        check_install && restart
        ;;
    14)
        check_install && status
        ;;
    15)
        check_install && show_log
        ;;
    16)
        check_install && enable
        ;;
    17)
        check_install && disable
        ;;
    18)
        check_install && ssl_menu
        ;;
    19)
        check_install && cloudflare_menu
        ;;
    20)
        iplimit_main
        ;;
    21)
        firewall_menu
        ;;
    22)
        bbr_menu
        ;;
    23)
        run_geo_update
        ;;
    24)
        run_speedtest
        ;;
    *) echo "Lựa chọn không hợp lệ" ;;
    esac
}

# Chạy menu chính
show_menu
