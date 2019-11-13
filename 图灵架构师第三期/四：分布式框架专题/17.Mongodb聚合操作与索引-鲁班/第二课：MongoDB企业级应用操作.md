 1、mongoDB的聚合操作

2、mongoDB的索引特性

## 一、mongoDB的聚合操作

---
知识点：

1. pipeline 聚合
2. mapRedurce 聚合
### pipeline 与mapRedurce 比较
pipeline 速度快，但只能运行在单机上，适合数据量小的实时聚合操作。

mapRedurce 可以运行在分布式节点，适适大数量并且复杂的聚合分析操作

1. pipeline 聚合

pipeline 聚合其特性是运行速度快，只能运行在单机上，并且对资源的使用有一定限制如下：

* 单个的聚合操作耗费的内存不能超过20%
* 返回的结果集大小在16M以内

**语法说明**

aggredate 方法接收任意多个参数，每个参数都是一个具体类别的聚合操作，通过参数的顺序组成一个执行链。每个操作执行完后将返回结果交给下一个操作。值到最后产出结果。

db.collection.aggregate(match,project,group,  ...)

* **pipeline相关运算符：**
* $match ：匹配过滤聚合的数据
* $project：返回需要聚合的字段
* $group：统计聚合数据 ，必须指定_id 列.
  * $max:求出最大值
  * $sum:求和
  * $avg：求平均值
  * $push: 将结果插入至一个数组当中
  * $addToSet：将结果插入至一个数组当中，并去重
  * $first:取第一个值
  * $last:取最后一个值
* $limit：用来限制MongoDB聚合管道返回的文档数。
* $skip：在聚合管道中跳过指定数量的文档，并返回余下的文档。
* $unwind：（flatmap）将文档中的某一个数组类型字段拆分成多条，每条包含数组中的一个值。
* $sort：将输入文档排序后输出。
* **示例：**

$match 条件过滤 

```
db.emp.aggregate({$match:{"job":"讲师"}})
```
$project 指定列返回

```
#返回指定例,_id 自动带上
db.emp.aggregate({$match:{"job":"讲师"}},{$project:{"job":1,"salary":1}})
#返回指定列，并修改列名
db.emp.aggregate({$match:{"job":"讲师"}},{$project:{"工作":"$job","薪水":"$salary"}})
```
$group 操作 ( 必须指定_id 列)  

```
#基于工作分组，并求出薪水总和
db.emp.aggregate({$group:{_id:"$job",total:{$sum:"$salary"}}})
#求出薪水最大值
db.emp.aggregate({$group:{_id:"$job",total:{$max:"$salary"}}})
# 将所有薪水添加列表
db.emp.aggregate({$group:{_id:"$job",total:{$push:"$salary"}}})
# 将所有薪水添加列表 并去重
db.emp.aggregate({$group:{_id:"$job",total:{$addToSet:"$salary"}}})
```
聚合操作可以任意个数和顺序的组合

```
# 二次过滤
db.emp.aggregate({$match:{"job":"讲师"}},{$project:{"工作":"$job","薪水":"$salary"}},{$match:{"薪水":{$gt:8000}}})
```
 $skip 与 $limit 跳转 并限制返回数量   

```
 db.emp.aggregate({$group:{_id:"$job",total:{$push:"$salary"}}},{$limit:4},{$skip:2});
```
#sort 排序 

```
db.emp.aggregate( {$project:{"工作":"$job","salary":1}},{$sort:{"salary":1,"工作":1}});
```
#unwind 操作，将数组拆分成多条记录

```
db.emp.aggregate({$group:{_id:"$job",total:{$push:"$salary"}}},{$unwind:"$total"});
```
1. mapRedurce 聚合

mapRedurce  非常适合实现非常复杂 并且数量大的聚合计算，其可运行在多台节点上实行分布式计算。

* 关于mapRedurce 概念

MapReduce 现大量运用于hadoop大数据计算当中，其最早来自于google 的一遍论，解决大PageRank搜索结果排序的问题。其大至原理如下:

* mongodb中mapRedurce的使用流程
1. 创建Map函数，
2. 创建Redurce函数
3. 将map、Redurce 函数添加至集合中，并返回新的结果集
4. 查询新的结果集
* 示列

基础示例

```
// 创建map 对象 
var map1=function (){
	emit(this.job,this.name); // 内置函数 key,value
 }
// 创建reduce 对象 
 var reduce1=function(job,count){
 return Array.sum(count);
 }
 // 执行mapReduce 任务 并将结果放到新的集合 result 当中
db.emp.mapReduce(map1,reduce1,{out:"result"}).find()
// 查询新的集合
db.result.find()
```
 使用复合对象作为key

```
# 使用复合对象作为key
 var map2=function (){
	emit({"job":this.job,"dep":this.dep},{"name":this.name,"dep":this.dep});
 }
 var reduce2=function(key,values){
	return values.length;
 }
 
db.emp.mapReduce(map2,reduce2,{out:"result2"}).find()
```
**调式 mapReduce 执行**

```
var emit=function(key,value){
  print(key+":"+value);
}
```
## 二、mongoDB的索引特性

---
### **知识点：**
1. 索引的基础概念
2. 单键索引
3. 多键索引
4. 复合索引
5. 过期索引
6. 全文索引
1. 索引的基础概念

查看执行计划：

```
db.emp.find({"salary":{$gt:500}}).explain()
```
创建简单索引

```
#创建索引
db.emp.createIndex({salary:1})
#查看索引
db.emp.getIndexes()
#查看执行计划
db.emp.find({"salary":{$gt:500}}).explain()
```

1. 单键索引

单个例上创建索引：

```
db.subject.createIndex({"name":1})
```
# 嵌套文档中的列创建索引

```
db.subject.createIndex({"grade.redis":1})
```
#整个文档创建索引

```
db.subject.createIndex({"grade":1})
```
1. 多键索引

创建多键索引

```
db.subject.createIndex({"subjects":1})
```
### 3.复合索引（组合索引）
创建复合索引

```
db.emp.createIndex( { "job":1,"salary":-1   }  )
```
查看执行计划：

```
db.emp.find({"job":"讲师", "salary":{$gt:500}}).explain()
```
```
db.emp.find({"job":"讲师"}).explain()
```
```
db.emp.find({"salary":{$gt:500}}).explain()
```
复合索引在排序中的应用：

```
db.emp.find({}).sort({"job":1, "salary":-1}).explain()
```
```
db.emp.find({}).sort({"job":-1, "salary":1}).explain()
```
```
db.emp.find({}).sort({"job":-1, "salary":-1}).explain()
```
```
db.emp.find({}).sort({"job":1, "salary":1}).explain()
```
job_1_salary_-1

```
db.emp.find({"job":"讲师","salary":{$gt:5000}}).explain() // 走索引
db.emp.find({"salary":{$gt:5000},"job":"讲师"}).explain()  // 走索引
db.emp.find({"job":"讲师"}).explain()    // 走索引
db.emp.find({"salary":{$gt:5000}}).explain()//
```
排序 场景

```
db.emp.find({}).sort({"job":1,"salary":-1}).explain()// 完全匹配  ==>走索引
db.emp.find({}).sort({"job":-1,"salary":1}).explain()//完全不匹配 ==>走索引
db.emp.find({}).sort({"job":1,"salary":1}).explain()// 一半匹配 ==>不走索引
db.emp.find({}).sort({"job":-1,"salary":-1}).explain()// 一半匹配 ==>不走索引
db.emp.find({}).sort({"job":-1}).explain()	 //  ==>走索引
db.emp.find({}).sort({"salary":-1}).explain()      // ==>不走索引
```
### 4.过期索引
过期索引存在一个过期的时间，如果时间过期，相应的数据会被自动删除

* 示例
```
#插入数据
db.log.insert({"title":"this is logger info","createTime":new Date()})
#创建过期索引
db.log.createIndex({"createTime":1},{expireAfterSeconds:10})
```
1. 全文索引

创建全文索引

```
db.project.createIndex( {"name":"text","description":"text"})
```
使用全文索引进行查询

```
db.project.find({$text:{$search:"java dubbo"}})
```
-用于屏蔽关键字 
```
db.project.find({$text:{$search:"java -dubbo"}})
```
短语查询,\" 包含即可

```
db.project.find({$text:{$search:"\"Apache Dubbo\""}})
```
中文查询

```
db.project.find({$text:{$search:"阿里 开源"}})
```

## 


