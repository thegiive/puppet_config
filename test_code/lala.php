<?php
$con = mysql_connect("localhost","root","lala123");
if (!$con)
  {
  die('Could not connect: ' . mysql_error());
  }

// some code
@mysql_select_db('myapp') or die( "Unable to select database");
$query = "SELECT * FROM  `lala` LIMIT 0 , 30 " ;
$result=  mysql_query($query);
$num=mysql_numrows($result);

mysql_close();

echo "<font size='20'><b>db result</b><br />" ;

$i=0;
while ($i < $num) {
$name =mysql_result($result,$i,"name");
$value =mysql_result($result,$i,"value");
echo $name."=".$value."<br />";
$i ++ ;
}
echo '</font>';

?>

