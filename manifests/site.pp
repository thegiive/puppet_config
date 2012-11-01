class apache{

	package{ 'apache2' :
		ensure => installed
	}
	service{ 'apache' : 
		name => 'apache2' , 
		     ensure => running,
		     enable => true,
	}
}
class php{
require apache
	package{ 'php5' :
		ensure => installed
	}
	package{ 'libapache2-mod-php5' :
		ensure => installed
	}
	file { '/var/www/info.php':
		content => "<?php phpinfo(); ?>" , 
	}

}


class mysql($user , $mysql_password , $name){
	package{ 'mysql-server' :
		ensure => installed
	}

	service { "mysql":
		enable => true,
		       ensure => running,
		       require => Package["mysql-server"],
	}



		exec { "set-mysql-password":
			unless => "mysqladmin -u$user -p$mysql_password status",
			       path => ["/bin", "/usr/bin"],
			       command => "mysqladmin -u$user password $mysql_password",
			       require => Service["mysql"],
		}
	exec { "create-myapp-db":
		unless => "/usr/bin/mysql -u$user -p$mysql_password ${name}",
		       command => "/usr/bin/mysql -u$user -p$mysql_password -e \"create database $name; grant all on $name.* to $user@localhost identified by '$mysql_password';\"",
		       require => Exec["set-mysql-password"],
	}

	file { "/tmp/a.sql":
		owner => "mysql", group => "mysql",
		      source => "puppet:///mysql/a.sql",
		       require => Exec["create-myapp-db"],
	}

	exec { "import-db" : 
		command => "/usr/bin/mysql myapp -u$user -p$mysql_password < /tmp/a.sql" , 
		       require => File["/tmp/a.sql"], 
	}

	notify {'other title':
		message => $mysql_password,
	}
}

class phpmyadmin{
require php 
require mysql 
	package{ 'phpmyadmin' :
		ensure => installed , 
		
	}
	exec { "copy config":
		command => "cp /etc/phpmyadmin/apache.conf /etc/apache2/conf.d",
			path    => "/usr/local/bin/:/bin/",
		       require => Package["phpmyadmin"], 
	}
	exec { "reload-apache2":
		command => "/etc/init.d/apache2 reload",
		       require => Exec["copy config"], 
	}
}

node default{
	include apache 
		include php 
class {'mysql':
      user  => 'root',
      mysql_password => 'lala123' , 
      name => 'myapp' , 
    }
		include phpmyadmin 

}
