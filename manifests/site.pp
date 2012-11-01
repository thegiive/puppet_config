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



	#exec { "set-mysql-password":
	#	unless => "mysqladmin -u$user -p$mysql_password status",
	#	       path => ["/bin", "/usr/bin"],
	#	       command => "mysqladmin -u$user password $mysql_password",
	#	       require => Service["mysql"],
	#}
	#exec { "create-myapp-db":
	#	unless => "/usr/bin/mysql -u$user -p$mysql_password ${name}",
	#	       command => "/usr/bin/mysql -u$user -p$mysql_password -e \"create database $name; grant all on $name.* to $user@localhost identified by '$mysql_password';\"",
	#	       require => Exec["set-mysql-password"],
	#}

	#file { "/tmp/drupal.sql":
	#	owner => "mysql", group => "mysql",
	#	      source => "puppet:///mysql/drupal2.sql",
	#	      require => Exec["create-myapp-db"],
	#}

	#exec { "import-db" : 
	#	command => "/usr/bin/mysql $name -u$user -p$mysql_password < /tmp/drupal.sql" , 
	#		require => File["/tmp/drupal.sql"], 
	#}

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


class drupal{
	require php 
		require mysql 
		package{ 'drupal7' :
			ensure => installed , 
		}
	exec { "copy drupla config" : 
		command => '/bin/cp /etc/drupal/7/apache2.conf /etc/apache2/mods-enabled/drupal.conf',
			require => Package['drupal7'] 
	}
	exec { "reload-apache":
		command => "/etc/init.d/apache2 reload",
			require => Exec['copy drupla config'] 
	}
}

node default { 
	$mysql_user = 'root'
		$mysql_password = 'lala123'
		$mysql_host = 'localhost'
		$drupal_db = 'drupal7'
		include apache 
		include php 
		class {'mysql':
			user  => $mysql_user, 
			      mysql_password => $mysql_password , 
			      name => $drupal_db , 
		}
	include phpmyadmin 
		include drupal
		file{ "dbconfig.php" :
			path => "/usr/share/drupal7/sites/default/dbconfig.php",
			     require => Class['drupal'] , 
			     content => template("mysql/dbconfig.php.erb"),
		}

	exec { "rm sql tmp file" : 
		command => "/bin/rm /tmp/drupal.sql" ,
		onlyif => "/usr/bin/test -f /tmp/drupal.sql" , 
	}
	file { "/tmp/drupal.sql":
		owner => "mysql", group => "mysql",
		      source => "puppet:///mysql/drupal2.sql",
			require => Exec["rm sql tmp file"] , 
	}

	exec { "import-db" : 
		command => "/usr/bin/mysql $drupal_db -u$mysql_user -p$mysql_password < /tmp/drupal.sql" , 
			require => File["/tmp/drupal.sql"], 
	}



}

