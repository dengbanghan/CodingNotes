1. 删除原来的`MySQL`数据库版本  
使用`rpm -qa | grep mysql`命令查询，如果系统有安装`MySQL`数据库，使用命令删除：`rpm -e --nodeps mysql-8.0.12-linux-glibc2.12-x86_64`

2. 安装`mumactl`    
`yum -y install numactl`（没有安装mysql 初始化会缺少libnuma.so.1） 

3. 解压文件 
```
tar -xvf mysql-8.0.12-linux-glibc2.12-x86_64.tar
```

4. 移动解压后的数据库文件
```
mv  mysql-8.0.12-linux-glibc2.12-x86_64  /usr/local/mysql
```

5. 创建mysql组
```
groupadd mysql
```

6. 创建mysql用户并添加到mysql组
```
useradd -g mysql mysql
```

7. 创建data目录
```
mkdir –p /data/mysql
```

8. 修改目录权限
```
chown -R mysql:mysql /usr/local/mysql
chown -R mysql:mysql /data
```

9. 创建my.cnf文件(etc目录下已有my.cnf，可先删除)
```
vim /etc/my.cnf
[client]
port = 3306
socket = /tmp/mysql.sock
default-character-set = utf8

[mysqld]
port = 3306
socket = /tmp/mysql.sock

basedir = /usr/local/mysql
datadir = /data/mysql
pid-file = /data/mysql/mysql.pid
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
```

10. 初始化数据库:   
```
/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf --user=mysql --initialize-insecure
```

11. 启动数据库
```
/usr/local/mysql/bin/mysqld_safe --defaults-file=/etc/my.cnf --user=mysql &
```

12. 查看mysql是否自启动成功     
查看mysql服务进程:
```
ps –ef | grep mysqld
```

13. 修改密码及远程登陆
```
./usr/local/bin/mysql
```

14. 更新用户的密码
<br>version: 5.7.24
```
alter user root@localhost identified by 'Admin@kds';
```
version: 8.0.12
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Admin@kds';
```

15. 允许远程访问
```
use mysql;
update user set host = '%' where user = 'root';
```

16. 刷新权限
```
FLUSH PRIVILEGES;
```

17. 将mysql服务加到系统服务中
```
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
```

18. 配置环境变量
```
vi /etc/profile

PATH=/usr/local/mysql/bin:/usr/local/mysql/lib:$PATH

source /etc/profile
```

# 一键部署数据库的脚本
```sh
#!/bin/sh

fun_need_root()
{
	[[ root == $LOGNAME ]] && return 0
	return 1
}

if ! fun_need_root ;then
			echo 必须以root用户进行登录后,再操作!
			echo 而不是用其它普通用户登录再切换到root进行操作!
			exit 1
		fi

MYSQL='/opt/mysql'
MYSQL_DATA=$MYSQL/data
MYSQL_BIN=$MYSQL/bin
MYSQL_LOG=$MYSQL/log
MYSQL_LIB=$MYSQL/lib
MYSQL_CNF='/etc/my.cnf'
INSTALL_PACKAGE='mysql-8.0.12-linux-glibc2.12-x86_64.tar.xz'
#INSTALL_PACKAGE='mysql-5.7.24-linux-glibc2.12-x86_64.tar.gz'

# 如果包的格式是.tar.xz则UNTARTYPE="-xvf"，如果包的格式是.tar.gz则UNTARTYPE="-zxvf"
UNTARTYPE="-xvf"
MYSQL_PACKAGE_PATH=$(ls $INSTALL_PACKAGE |awk -F .tar '{print $1}')

echo "添加mysql的用户和组:"
groupadd mysql && useradd -g mysql mysql

#初始化会缺少libnuma.so.1,需要安装mumactl
echo "安装mumactl:"
yum -y install numactl > /dev/null

#解压文件,安装包的格式是tar.gz的话，使用-zxvf，若安装包的格式是tar.xz的话，使用-xvf
echo "解压安装包"$INSTALL_PACKAGE":"
tar $UNTARTYPE $INSTALL_PACKAGE > /dev/null

#移动解压后的数据库文件
mv  $MYSQL_PACKAGE_PATH $MYSQL

#创建软链接
ln -s $MYSQL_BIN/mysql /usr/bin

#创建data和log目录
mkdir -p $MYSQL_DATA
mkdir -p $MYSQL_LOG

#修改目录权限
chown -R mysql:mysql $MYSQL

#创建my.cnf文件(etc目录下已有my.cnf，可先删除)
cat>"${MYSQL_CNF}"<<EOF
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

echo "初始化数据库:"
$MYSQL_BIN/mysqld --defaults-file=$MYSQL_CNF --user=mysql --initialize-insecure


#将mysql服务加到系统服务中
cp $MYSQL/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld

#配置环境变量 
cat >> /etc/profile <<EOF
PATH=$MYSQL_BIN:$MYSQL_LIB:\$PATH
EOF
source /etc/profile

echo "启动数据库..."
service mysqld start

echo "查看mysql是否自启动成功,查看mysql服务进程:"
ps -fC mysqld

PASSWORD='Admin@kds'

#echo "MySQL版本V5.7.24 更新root用户的密码:"
#mysql -e "alter user root@localhost identified by '$PASSWORD';"

echo "MySQL版本V8.0.12 更新root用户的密码:"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSWORD';"

echo "允许远程访问:"
mysql -uroot -p$PASSWORD -e "update user set host = '%' where user = 'root';" mysql

echo "刷新权限:"
mysql -uroot -p$PASSWORD -e "FLUSH PRIVILEGES;" mysql
```