/*
Navicat MySQL Data Transfer

Source Server         : 本地mysql
Source Server Version : 50726
Source Host           : localhost:3306
Source Database       : tuling-mq

Target Server Type    : MYSQL
Target Server Version : 50726
File Encoding         : 65001

Date: 2019-10-30 16:21:18
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for message_content
-- ----------------------------
DROP TABLE IF EXISTS `message_content`;
CREATE TABLE `message_content` (
  `msg_id` varchar(50) NOT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `msg_status` int(10) DEFAULT NULL COMMENT '(0,"发送中"),(1,"mq的broker确认接受到消息"),(2,"没有对应交换机"),(3,"没有对应的路由"),(4,"消费端成功消费消息")',
  `exchange` varchar(50) DEFAULT NULL,
  `routing_key` varchar(50) DEFAULT NULL,
  `err_cause` varchar(1000) DEFAULT NULL,
  `order_no` bigint(32) DEFAULT NULL,
  `max_retry` int(10) DEFAULT NULL,
  `current_retry` int(10) DEFAULT NULL,
  `product_no` int(10) DEFAULT NULL,
  PRIMARY KEY (`msg_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of message_content
-- ----------------------------
INSERT INTO `message_content` VALUES ('0679d710-3fdf-41db-9bd8-a59f80b03a47', '2019-10-27 17:13:42', '2019-10-27 17:14:43', '1', 'order-to-product.exchange', 'order-to-product.queue', null, '1572167621669', '5', '5', '1');
INSERT INTO `message_content` VALUES ('c79ab11b-38c2-4a5a-a3c6-60a2502c15d3', '2019-10-16 13:38:27', '2019-10-16 13:38:27', '3', 'order-to-product.exchange', 'product_to_callback_key', null, '1571204306681', '5', '0', '1');
INSERT INTO `message_content` VALUES ('e87edd3b-a599-40f8-aa6a-f87bcd5eb08b', '2019-10-27 17:16:41', '2019-10-27 17:17:52', '4', 'order-to-product.exchange', 'order-to-product.queue', null, '1572167801311', '5', '5', '1');

-- ----------------------------
-- Table structure for order_info
-- ----------------------------
DROP TABLE IF EXISTS `order_info`;
CREATE TABLE `order_info` (
  `order_no` bigint(32) NOT NULL AUTO_INCREMENT,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `user_name` varchar(50) DEFAULT NULL,
  `money` double(10,2) DEFAULT NULL,
  `product_no` int(10) DEFAULT NULL,
  `order_status` int(10) DEFAULT NULL,
  PRIMARY KEY (`order_no`)
) ENGINE=InnoDB AUTO_INCREMENT=1572167801312 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of order_info
-- ----------------------------
INSERT INTO `order_info` VALUES ('1571204306681', '2019-10-16 13:38:27', '2019-10-16 13:38:27', 'smlz', '10000.00', '1', '0');
INSERT INTO `order_info` VALUES ('1571204408554', '2019-10-16 13:40:09', '2019-10-16 13:40:09', 'smlz', '10000.00', '1', '0');
INSERT INTO `order_info` VALUES ('1571207172279', '2019-10-16 14:26:12', '2019-10-16 14:26:12', 'smlz', '10000.00', '1', '0');
INSERT INTO `order_info` VALUES ('1572167621669', '2019-10-27 17:13:42', '2019-10-27 17:13:42', 'smlz', '10000.00', '1', null);
INSERT INTO `order_info` VALUES ('1572167801311', '2019-10-27 17:16:41', '2019-10-27 17:16:41', 'smlz', '10000.00', '1', null);

-- ----------------------------
-- Table structure for product_info
-- ----------------------------
DROP TABLE IF EXISTS `product_info`;
CREATE TABLE `product_info` (
  `product_no` int(32) NOT NULL,
  `product_name` varchar(50) DEFAULT NULL,
  `product_num` int(10) DEFAULT NULL,
  PRIMARY KEY (`product_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of product_info
-- ----------------------------
INSERT INTO `product_info` VALUES ('1', '华为meta30', '61');
