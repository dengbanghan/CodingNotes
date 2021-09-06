#!/bin/sh

# 错误日志输出函数
err()
{
    echo -e "[ERROR $(date +"%Y-%m-%d %H:%M:%S")]$@" >>$LOG_DIR/uninstall_mysql.log >&2
}

# 常规日志输出函数
info()
{
    echo -e "[INFO $(date +"%Y-%m-%d %H:%M:%S")]$@" >>$LOG_DIR/uninstall_mysql.log >&2
}


# 判断用户为root则返回正确
fun_need_root()
{
    [[ root == $LOGNAME ]] && return 0
    return 1
}

# 停止数据库
fun_stop_mysql()
{
    info "检查 MySQL 进程的运行状态..."
    if [ -z `ps -fC mysqld --no-heading | awk '{print $2}'` ];then
        info "MySQL 没有在运行!!!"
    else
        info "检查到有 MySQL 进程在运行！"
        info "详情如下：\\n`ps -fC mysqld`"
        info "准备关闭MySQL..."
        service mysqld stop 
        if [ -z `ps -fC mysqld --no-heading | awk '{print $2}'` ];then
            info "MySQL 停止成功！"
        else
            err "MySQL 停止失败！"
            info "强行杀死 MySQL 进程！"
            kill -9 `ps -fC mysqld --no-heading | awk '{print $2}'`
            sleep 1
            if [ -z `ps -fC mysqld --no-heading | awk '{print $2}'` ];then
                info "成功杀死 MySQL 进程！"
            else
                err "杀死 MySQL 进程失败！"
                exit 1
            fi
        fi
    fi
}

# 删除文件夹
fun_delete_folder()
{
    if [ -d $1 ]; then
        rm -rf $1
        if [ ! -d $1 ]; then
            info "删除 $1 成功!"
        else
            err "删除 $1 失败!" 
            exit 1
        fi
    else
        info "$1 已经不存在！"
    fi
}

# 删除文件
fun_delete_file()
{
    if [ -f $1 ]; then
        info "正在删除 $1 ..."
        rm -rf $1
        if [ ! -f $1 ]; then
            info "删除 $1 成功!"
        else
            err "删除 $1 失败!"
            exit 1 
        fi
    else
        info "$1 已经不存在！"
    fi
}

# 卸载numactl的函数
fun_uninstall_numactl()
{
    NUMACTL=`rpm -qa | grep numactl`
	
    if [ `rpm -qa | grep numactl | wc -l` -eq 0 ];then
	    info "numactl已经不存在，不需要卸载!"
    elif [ `rpm -qa | grep numactl | wc -l` -gt 0 ];then
        info "正在卸载 $NUMACTL ..."

        for i in $NUMACTL
        do
            rpm -e --nodeps $i
        done
	    
        if [ `rpm -qa | grep numactl | wc -l` -eq 0 ];then
            info "numactl卸载成功!"
        elif [ `rpm -qa | grep numactl | wc -l` -gt 0 ];then
            err "numactl卸载失败!"
            exit 1
        fi
    fi
}

# 删除MySQL用户组的函数
fun_delete_user()
{
    GROUPSTATUS=`grep mysql /etc/group | wc -l`
    if [ $GROUPSTATUS -eq 0 ]; then
        info "MySQL用户组已经不存在!"
    elif [ $GROUPSTATUS -eq 1 ]; then
        userdel -r -f mysql
        GROUPSTATUS=`grep mysql /etc/group | wc -l`
        if [ $GROUPSTATUS -eq 0  ]; then
            info "删除MySQL用户组成功!"
        elif [ $GROUPSTATUS -eq 1 ]; then
            err "删除MySQL用户组失败!"
            exit 1
        fi
    fi
}

main()
{
    if ! fun_need_root ;then
        err "必须以root用户进行登录后,再操作!"
        err "而不是用其它普通用户登录再切换到root进行操作!"
        exit 1
    fi

    MYSQL_CONF=$PWD/mysql.conf
    [[ -f $MYSQL_CONF ]] || { err $MYSQL_CONF 不存在 ; exit 1; }
    . $MYSQL_CONF

    [[ ! -d $LOG_DIR ]] && mkdir $LOG_DIR

    # 停止数据库
    fun_stop_mysql
    
    # 卸载numactl
    fun_uninstall_numactl
    
    # 删除/usr/bin目录下的mysql软链接
    fun_delete_file $MYSQL_LINK
    
    # 删除mysql的安装目录
    fun_delete_folder $MYSQL
    
    # 删除my.cnf文件
    fun_delete_file $MY_CNF
    
    # 将系统服务中的mysqld删除
    fun_delete_file $MYSQL_INIT
    
    # 删除mysql的用户和组
    fun_delete_user
    
    source /etc/profile

    info "卸载 MySQL 成功！！！"
}

main
