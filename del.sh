#!/bin/bash


# 安全的使用rm,避免在生产环境中删库危险
# 1. 阻止类似 rm -rf /* 等删库指令执行
# 2. 使用备份机制防止误删
# 3. 一层路径删除需要进一步确认
# 4. 使用延时和输出尽可能给操作员反应时间
# 参数:     -rf/-fr 删除目录时使用
#           -c 清理备份(当前用户),当有该参数时,忽略其他输入参数
#           --unsafe 不执行备份机制
# 安装  
##      cp del.sh /usr/bin/del
##      chmod +x /usr/bin/del
## 也可以用 alias 替换 rm 无感使用(不建议)
# 使用  
##      del 1.txt
##      del -rf /root/1
##      del -c

# 定义保护目录列表
dangers=(
    "/bin"
    "/usr"
    "/opt"
    "/etc"
    "/home"
    "/root"
    "/tmp"
    "/var"
    "/boot"
)



# 初始化删除参数和保护目录标志
delete_params=()
delete_flag=false
un_bak=false

# 处理输入参数，将 . 和 ~ 转为完整路径
for i in "$@"; do
    if [[ "$i" == "-c" ]]; then
        echo '即将清理备份...'
        echo '备份有以下内容...'
        ls -al ~/.del/files/
        sleep 3
        /usr/bin/rm -rf ~/.del/files/
        exit 0
    fi
    if [[ "$i" == "--unsafe" ]]; then
        echo -e '\033[31m !!!关闭备份!!! \033[0m'
        un_bak=true
        sleep 1
    fi
    if [[ "$i" == "-rf" || "$i" == "-fr" ]]; then
        delete_flag=true
        echo '递归强制删除开启...'
        sleep 1
    else
        expanded_path=$(realpath "$i")
        echo 'delete path:' + $expanded_path
        # rm -rf /* 保护
        if [[ "$expanded_path" == "/" || "$expanded_path" == "/*" || "$expanded_path" =~ ^/bin[^/]*$ || "$expanded_path" =~ ^/a[^/]*$ || "$expanded_path" =~ ^/usr/bin[^/]*$ ]];then
            echo -e '\033[31m 触发了危险保护,操作取消 \033[0m'
            exit 1
        fi

        # / 一层路径保护
        if [[ "$expanded_path" =~ ^/[^/]+/$ || "$expanded_path" =~ ^/[^/]+$ ]];then
            echo -e '\033[31m 涉及危险操作,请确认要删除的目录: \033[0m' $expanded_path
            read -p "(y/n) " response
            if [ "$response" != "y" ]; then
                echo "删除操作已取消"
                exit 1
            fi
            sleep 3
        fi

        delete_params+=("$expanded_path")
    fi
done



# 路径备份保护
if [[ "$un_bak" == false ]]; then
    for i in "${delete_params[@]}"; do
        for danger in "${dangers[@]}"; do
            if [[ "$i" == "$danger"* ]]; then
                echo -e "\033[34m 删除目录在 '$danger'下,执行备份保护 \033[0m"
                mkdir -p ~/.del/files/
                echo "cp -rf $i ~/.del/files/"
                cp -rf $i ~/.del/files/
                sleep 1
            fi
        done
    done
fi




# 执行rm命令，如果不是保护目录中的文件
if [[ "$delete_flag" == false ]]; then
    /usr/bin/rm "${delete_params[@]}"
else
    /usr/bin/rm -rf "${delete_params[@]}"
fi
