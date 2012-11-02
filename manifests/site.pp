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

	file { "/etc/mysql/my.cnf" :
		source => "puppet:///mysql/my.cnf",
		require => Package['mysql-server'] ,
	}

	service { "mysql":
		enable => true,
		       ensure => running,
		       require => File["/etc/mysql/my.cnf"],
	}
	


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


class drupal( $mysql_user , $mysql_password , $mysql_host , $drupal_db ) {
	require php 
	#	require mysql 
		package{ 'drupal7' :
			ensure => installed , 
		}
	exec { "copy drupla config" : 
		command => '/bin/cp /etc/drupal/7/apache2.conf /etc/apache2/mods-enabled/drupal.conf',
			require => Package['drupal7'] 
	}
	file{ "dbconfig.php" :
		path => "/usr/share/drupal7/sites/default/dbconfig.php",
		     content => template("mysql/dbconfig.php.erb"),
	}
	exec { "reload-apache":
		command => "/etc/init.d/apache2 reload",
			require => Exec['copy drupla config'] 
	}
}

node drupal_node { 
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
		      source => "puppet:///mysql/drupal3.sql",
			require => Exec["rm sql tmp file"] , 
	}

	exec { "import-db" : 
		command => "/usr/bin/mysql $drupal_db -u$mysql_user -p$mysql_password < /tmp/drupal.sql" , 
			require => File["/tmp/drupal.sql"], 
	}



}
class haproxy( $haproxy_ip , $server_id_array ){
	package{ 'haproxy' :
		ensure => installed
	}
	file{ "haproxy.cfg" :
		path => "/etc/haproxy/haproxy.cfg" , 
		     require => Package['haproxy'] , 
		     content => template("mysql/haproxy.cfg.erb"),
	}
	file { "/etc/default/haproxy" : 
		content => 'ENABLED=1' ,
			require => Package['haproxy'] , 
	}
	service{ 'haproxy' : 
		name => 'haproxy' , 
		     ensure => running,
		     enable => true,
		     require => File["/etc/default/haproxy"] , 
	}
}

node ip-10-150-189-15{
	$haproxy_ip = '10.150.189.15'
	$server_id_array = [ '10.152.87.92' , '10.161.7.25' ] 
	class {'haproxy':
		haproxy_ip  => $haproxy_ip, 
		      server_id_array => $server_id_array , 
	} 

}

node ip-10-152-87-92{
	# drupal node
	$mysql_user = 'root'
		$mysql_password = 'lala123'
		$mysql_host = '10.152.11.127'
		$drupal_db = 'drupal7'
	class { 'drupal' : 
		mysql_user => $mysql_user , 
		mysql_password => $mysql_password , 
		mysql_host => $mysql_host , 
		drupal_db => $drupal_db , 
	}
		
}

node ip-10-152-11-127{
	#db 
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

	exec { "rm sql tmp file" : 
		command => "/bin/rm /tmp/drupal.sql" ,
		onlyif => "/usr/bin/test -f /tmp/drupal.sql" , 
		require => Class['phpmyadmin'] 
	}
	file { "/tmp/drupal.sql":
		owner => "mysql", group => "mysql",
		      source => "puppet:///mysql/drupal4.sql",
			require => Exec["rm sql tmp file"] , 
	}

	exec { "import-db" : 
		command => "/usr/bin/mysql $drupal_db -u$mysql_user -p$mysql_password < /tmp/drupal.sql" , 
			require => File["/tmp/drupal.sql"], 
	}

}
