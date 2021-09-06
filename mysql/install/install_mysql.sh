#!/bin/sh

INSTALL_PACKAGE=$1

# 错误日志输出函数
err()
{
    echo -e "[ERROR $(date +"%Y-%m-%d %H:%M:%S")]$@" >>$LOG_DIR/install_mysql.log >&2
}

# 常规日志输出函数
info()
{
    echo -e "[INFO $(date +"%Y-%m-%d %H:%M:%S")]$@" >>$LOG_DIR/install_mysql.log >&2
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

# 新增 MySQL 用户和组
fun_add_user()
{
    if [ "`grep mysql /etc/group | wc -l`" = "0" ]; then
        info "添加MySQL的用户和组..."
        groupadd mysql && useradd -g mysql mysql
        if [ "`grep mysql /etc/group | wc -l`" = "0" ]; then
            err "添加MySQL用户组失败,请检查原因，退出安装！"
            exit 1
        elif [ "`grep mysql /etc/group | wc -l`" = "1" ]; then
            info "添加MySQL用户组成功!"	
        fi
    elif [ "`grep mysql /etc/group | wc -l`" = "1" ]; then    
        info "已经存在MySQL用户组，不需要再创建，继续安装..."
    fi
}

#初始化会缺少libnuma.so.1,需要安装mumactl
fun_install_numactl()
{
    if [ `rpm -qa | grep numactl | wc -l` -eq 0 ];then
        info "缺少 libnuma.so.1 ,需要在线安装 mumactl..."
        yum -y install numactl
        NUMACTL=`rpm -qa | grep numactl`
        if [ `rpm -qa | grep numactl | wc -l` -gt 0 ];then
            info "在线安装 "$NUMACTL" 成功！"
            info "继续安装MySQL..."
        else
            info "在线安装 Numactl 失败！"
            info "开始离线安装 Numactl..."
	    if [ -d $RPM_NUMACTL ];then
                if [ `ls $RPM_NUMACTL | wc -l` -eq 0 ];then
                    err "$RPM_NUMACTL 目录下没有 numactl 的离线包！"
                    err "请在 $RPM_NUMACTL 目录下放置 numactl 的离线包后再进行安装！"
                    err "退出安装！"
                    exit 1
                else
                    rpm -Uvh --force $RPM_NUMACTL/*.rpm
                fi
                NUMACTL=`rpm -qa | grep numactl`
                if [ `rpm -qa | grep numactl | wc -l` -gt 0 ];then
                    info "离线安装"$NUMACTL"成功！"
                    info "继续安装MySQL..."
                fi
            else
                err "不存在 $RPM_NUMACTL 目录,请创建目录并放置 numactl 的离线包后再进行安装！"
                err "退出安装！"
                exit 1
            fi
        fi
    elif [ `rpm -qa | grep numactl | wc -l` -gt 0 ];then
        info "已经存在"$NUMACTL",不需要再安装！"
        info "继续安装MySQL..."
    fi
}

# 解压安装包
fun_untar()
{
    TARTYPE=`echo $INSTALL_PACKAGE | awk -F "tar"  '{print $2}'`
    #解压文件,安装包的格式是tar.gz的话，使用-zxvf，若安装包的格式是tar.xz的话，使用-xvf
    if [ $TARTYPE = ".gz" ];then
        info "解压安装包"$INSTALL_PACKAGE"..."
        tar -zxvf $INSTALL_PACKAGE -C $MYSQL
    elif [ $TARTYPE = ".xz" ];then
        info "解压安装包"$INSTALL_PACKAGE"..."
        tar -xvf $INSTALL_PACKAGE -C $MYSQL
    fi
}

fun_create_link()
{
    #创建软链接
    ln -s $MYSQL_BIN/mysql /usr/bin
}

fun_create_dir()
{
    #创建data和log目录
    mkdir -p $MYSQL_DATA
    mkdir -p $MYSQL_LOG
}

fun_create_conf() 
{
    #创建my.cnf文件(etc目录下已有my.cnf，可先删除)
    cat>"${MY_CNF}"<<EOF
[client]
port = 3306
socket = /tmp/mysql.sock
default-character-set = utf8

[mysqld]
port = 3306
socket = /tmp/mysql.sock

basedir = $MYSQL
datadir = $MYSQL_DATA
pid-file = $MYSQL_DATA/mysql.pid
user = mysql
#bind-address = 0.0.0.0
server-id = 1

init-connect = 'SET NAMES utf8'
character-set-server = utf8

skip-name-resolve
#skip-networking
back_log = 300

max_connections = 1000
max_connect_errors = 6000
open_files_limit = 65535
table_open_cache = 128
max_allowed_packet = 4M
binlog_cache_size = 1M
max_heap_table_size = 8M
tmp_table_size = 16M

read_buffer_size = 2M
read_rnd_buffer_size = 8M
EOF
}
fun_init_mysql()
{
    info "初始化数据库:"
    $MYSQL_BIN/mysqld --defaults-file=$MY_CNF --user=mysql --initialize-insecure
	
    #将mysql服务加到系统服务中
    cp $MYSQL/support-files/mysql.server $MYSQL_INIT
    chkconfig --add mysqld
}

fun_set_env()
{
    #配置环境变量 
    cat >> /etc/profile <<EOF
PATH=$MYSQL_BIN:$MYSQL_LIB:\$PATH
EOF
    source /etc/profile
}

fun_start_mysql()
{
    info "启动数据库..."
    service mysqld start
    
    info "查看mysql是否自启动成功,查看mysql服务进程:"
    ps -fC mysqld
}

fun_setting_mysql()
{
    MYSQL_VERSION=`echo $INSTALL_PACKAGE | awk -F "."  '{print $1}' | awk -F "-"  '{print $2}'`
    if [ $MYSQL_VERSION -eq 5 ];then
        info "更新root用户的密码..."
        #MySQL版本 V5.7.24 更新root用户的密码
        mysql -e "alter user root@localhost identified by '$PASSWORD';"
    elif [ $MYSQL_VERSION -eq 8 ];then
        info "更新root用户的密码..."
        #MySQL版本 8.0.12 更新root用户的密码
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSWORD';"
    fi
    
    info "允许远程访问:"
    mysql -uroot -p$PASSWORD -e "update user set host = '%' where user = 'root';" mysql
    
    info "刷新权限:"
    mysql -uroot -p$PASSWORD -e "FLUSH PRIVILEGES;" mysql
}

main()
{
    if [ -z $INSTALL_PACKAGE ];then
        err "该脚本需要带安装包名称参数"
        err "例如：install_mysql.sh mysql-5.7.24-linux-glibc2.12-x86_64.tar.gz"
        exit 0
    fi
    
    if ! fun_need_root ;then
        err "必须以root用户进行登录后,再操作!"
        err "而不是用其它普通用户登录再切换到root进行操作!"
        exit 1
    fi
    
    MYSQL_CONF=$PWD/mysql.conf
    [[ -f $MYSQL_CONF ]] || { err $MYSQL_CONF 不存在 ; exit 1; }
    . $MYSQL_CONF
	
    [[ ! -d $LOG_DIR ]] && mkdir $LOG_DIR
    
    fun_stop_mysql
    fun_add_user
    fun_install_numactl

    UNTAR_MYSQL_PACKAGE_PATH=$MYSQL/`echo $INSTALL_PACKAGE |awk -F .tar '{print $1}'`
    
    if [ -d $MYSQL ];then
        info "已经存在安装目录 $MYSQL "
        fun_untar

        #移动解压后的数据库文件
        mv  $UNTAR_MYSQL_PACKAGE_PATH/* $MYSQL
        rm  $UNTAR_MYSQL_PACKAGE_PATH -rf
    else
        info "不存在安装目录 $MYSQL"
        info "正在新建安装目录 $MYSQL"
        mkdir $MYSQL
		
        if [ -d $MYSQL ];then
            info "新建安装目录 $MYSQL 成功"
        else
            err "新建安装目录 $MYSQL 失败"
            exit 1
        fi
		
        fun_untar
		
        if [ -d $UNTAR_MYSQL_PACKAGE_PATH ];then
            info "解压安装包 $UNTAR_MYSQL_PACKAGE_PATH 成功"
            #移动解压后的数据库文件
            mv  $UNTAR_MYSQL_PACKAGE_PATH/* $MYSQL
            rm  $UNTAR_MYSQL_PACKAGE_PATH -rf
        else
            err "解压安装包 $UNTAR_MYSQL_PACKAGE_PATH 失败"
            exit 1
        fi
    fi
    
    fun_create_link
    fun_create_dir
    #修改目录权限
    chown -R mysql:mysql $MYSQL
    fun_create_conf
    fun_init_mysql
    fun_set_env
    fun_start_mysql
    fun_setting_mysql
}

main
