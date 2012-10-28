DROP TABLE IF EXISTS `lala`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lala` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `value` varchar(1024) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lala`
--

LOCK TABLES `lala` WRITE;
/*!40000 ALTER TABLE `lala` DISABLE KEYS */;
INSERT INTO `lala` VALUES (1,'lala1','haha'),(2,'lala2','haha2');
/*!40000 ALTER TABLE `lala` ENABLE KEYS */;
UNLOCK TABLES;

