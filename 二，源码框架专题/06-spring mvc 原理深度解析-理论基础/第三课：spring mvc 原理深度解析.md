**主讲：**图灵鲁班
**时间：**2018/08/30


**课程概要**
1. spring mvc 设计思想与体系结构组成
2. mvc 执行流程解析
3. 注解配置
## 一、spring mvc 设计思想与体系结构组成

---
### **知识点**
1. jsp 执行过程回顾
2. spring mvc执行流程解析
3. mvc 体系结构
### 1、回顾servlet 与jsp 执行过程
![图片](https://images-cdn.shimo.im/4yigtQOE8nMbrSlM/image.png!thumbnail)

**流程说明：**
1. 请求Servlet
2. 处理业务逻辑
3. 设置业务Model
4. forward jsp Servlet
5.  jsp Servlet 解析封装html 返回

提问：这个是一个MVC应用场景吗？

spring mvc本质上还是在使用Servlet处理，并在其基础上进行了封装简化了开发流程，提高易用性、并使用程序逻辑结构变得更清晰
  1. 基于注解的URL映谢
  2. http表单参数转换
  3. 全局统一异常处理
  4. 拦截器的实现
### **2、spring mvc 执行流程：**
![图片](https://images-cdn.shimo.im/ZtHZCJJg5Lg7QU49/image.png!thumbnail)

**整个过程是如何实现的？**
1. dispatchServlet 如何找到对应的Control？
2. 如何执行调用Control 当中的业务方法？

回答这些问题之前我们先来认识一下spring mvc 体系结构
### 3、spring mvc 体系结构
* **HandlerMapping** 'hændlə  'mæpɪŋ
  * url与控制器的映谢
* **HandlerAdapter **** **'hændlə  ə'dæptə
  * 控制器执行适配器
* **ViewResolver **vjuː  riː'zɒlvə
  *  视图仓库
* **view**
  * 具体解析视图
* **HandlerExceptionResolver  **'hændlə  ɪk'sepʃ(ə)n  riː'zɒlvə
  * 异常捕捕捉器
* **HandlerInterceptor**  'hændlə  ɪntə'septə
  * 拦截器

**配置一个spring mvc 示例演示 验证上述流程 **
    - [x] 创建一个Controller 类
    - [x] 配置DispatchServlet
    - [x] 创建spring-mvc.xml 文件
    - [x] 配置SimpleUrlHandlerMapping
    - [x] 配置InternalResourceViewResolver

**体系结构UML**
![图片](https://images-cdn.shimo.im/KgRjG50ru80SpIQD/image.png!thumbnail)



## 二、mvc 执行流程解析

---
### 知识点：
1. mvc 具体执行流程
2. HandlerMapping详解
3. HandlerAdapter 详解
4. ViewResolver与View详解
5. HandlerExceptionResolver详解
6. HandlerInterceptor 详解

1. mvc 各组件执行流程

![图片](https://images-cdn.shimo.im/amwSsViboTYhHk2P/image.png!thumbnail)
### **2、HandlerMapping 详解**
其为mvc 中url路径与Control对像的映射，DispatcherServlet 就是基于此组件来寻找对应的Control，如果找不到就会报Not Found mapping 的异常。

HandlerMapping 接口方法
![图片](https://images-cdn.shimo.im/N8nq4z4x6wc3Ie93/image.png!thumbnail)

HandlerMapping 接口结构
![图片](https://images-cdn.shimo.im/03GGNdm0nUAeEIIP/image.png!thumbnail)

目前主流的三种mapping 如下：
BeanNameUrlHandlerMapping:  基于ioc name 中已 "/" 开头的Bean时行 注册至映谢.
SimpleUrlHandlerMapping：基于手动配置 url 与control 映谢
RequestMappingHandlerMapping：基于@RequestMapping注解配置对应映谢

- [ ] 演示基于 BeanNameUrlHandlerMapping  配置映谢。

编写mvc 文件
```
<!--简单控制器-->
<bean id="/user.do" class="com.tuling.mvc.control.BeanNameControl"/>
```

```
// beanname control 控制器
public class BeanNameControl implements HttpRequestHandler {
    @Override
    public void handleRequest(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException {
        request.getRequestDispatcher("/WEB-INF/page/userView.jsp").forward(request, response);
    }
}
```

当IOC 中实例化这些类之后 DispatcherServlet 就会通过org.springframework.web.servlet.DispatcherServlet#getHandler() 方法基于request查找对应Handler。 但找到对应的Handler之后我们发现他是一个Object类型，并没有实现特定接口。如何调用Handler呢？

### **3、HandlerAdapter详解**
这里spring mvc 采用适配器模式来适配调用指定Handler，根据Handler的不同种类采用不同的Adapter,其Handler与 HandlerAdapter 对应关系如下:
| Handler类别   | 对应适配器   | 描述   | 
|:----|:----|:----|
| Controller   | SimpleControllerHandlerAdapter   | 标准控制器，返回ModelAndView   | 
| HttpRequestHandler   | HttpRequestHandlerAdapter   | 业务自行处理 请求，不需要通过modelAndView 转到视图   | 
| Servlet   | SimpleServletHandlerAdapter   | 基于标准的servlet 处理   | 
| HandlerMethod   | RequestMappingHandlerAdapter   | 基于@requestMapping对应方法处理   | 

HandlerAdapter  接口方法
![图片](https://images-cdn.shimo.im/IZdWTPapXBYQzaRx/image.png!thumbnail)

HandlerAdapter  接口结构图
![图片](https://images-cdn.shimo.im/tNKGltBfhoEqCEsi/image.png!thumbnail)

- [ ] 演示基于Servlet 处理  SimpleServletHandlerAdapter
```
<!-- 配置控制器 -->
<bean id="/hello.do" class="com.tuling.mvc.control.HelloServlet"/>

<!-- 配置适配器 -->
<bean class="org.springframework.web.servlet.handler.SimpleServletHandlerAdapter"/>
```

```
// 标准Servlet
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().println("hello luban ");
    }
}
```
上述例子中当IOC 中实例化这些类之后 DispatcherServlet 就会通过
org.springframework.web.servlet.DispatcherServlet#getHandlerAdapter() 方法查找对应handler的适配器 ，如果找不到就会报 No adapter for handler 。

### **4、ViewResolver 与View 详解**
找到应的Adapter 之后就会基于适配器调用业务处理，处理完之后业务方会返回一个ModelAndView ，在去查找对应的视图进行处理。其在org.springframework.web.servlet.DispatcherServlet#resolveViewName() 中遍历 viewResolvers 列表查找，如果找不到就会报一个 Could not resolve view with name 异常。

![图片](https://images-cdn.shimo.im/2GnBrLuWvSwdR40e/image.png!thumbnail)

在下一步就是基于ViewResolver**.**resolveViewName() 获取对应View来解析生成Html并返回 。对应VIEW结构如下：
![图片](https://images-cdn.shimo.im/OF1ug8QGCTET8R61/image.png!thumbnail)

至此整个正向流程就已经走完了，如果此时程序处理异常 MVC 该如何处理呢？
### 5、HandlerExceptionResolver详解
该组件用于指示 当出现异常时 mvc 该如何处理。 dispatcherServlet 会调用org.springframework.web.servlet.DispatcherServlet#processHandlerException() 方法，遍历 handlerExceptionResolvers 处理异常，处理完成之后返回errorView 跳转到异常视图。
    - [ ] 演示自定义异常捕捉
```
public class SimpleExceptionHandle implements HandlerExceptionResolver {
    @Override
    public ModelAndView resolveException(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        return new ModelAndView("error");
    }
}
```

```
<!-- 演示异常配置 -->
<bean class="com.tuling.mvc.control.SimpleExceptionHandle"/>
```

HandlerExceptionResolver 结构
![图片](https://images-cdn.shimo.im/QRKFJmKFrSM5oORP/image.png!thumbnail)

除了上述组件之外 spring 中还引入了  我Interceptor 拦截器 机制，类似于Filter。
### 6、HandlerInterceptor 详解
- [ ] 演示HandlerInterceptor 
```
public class SimpleHandlerInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        System.out.println("preHandle");
        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
        System.out.println("postHandle");
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        System.out.println("afterCompletion");
    }
}
```

```
<!--配置interceptor 组件-->
<bean class="com.tuling.mvc.control.SimpleHandlerInterceptor"></bean>
```
其实现机制是基于 HandlerExecutionChain 分别在 doDispatch 方法中执行以下方法：
* preHandle ：业务处理前执行
* postHandle：业务处理后（异常则不执行）
* afterCompletion：视图处理后

具体逻辑源码参见：org.springframework.web.servlet.DispatcherServlet#doDispatch 方法。

### 三、注解配置

---
- [ ] 演示基于注解配置mvc mapping 
```
<context:component-scan base-package="com.tuling.mvc.control" />
<!-- 注解驱动 -->
<mvc:annotation-driven/>

<!-- 视图仓库 -->
<bean  class="org.springframework.web.servlet.view.InternalResourceViewResolver">
   <property name="prefix" value="/WEB-INF/page/" />
   <property name="suffix" value=".jsp" />
   <property name="viewClass"
      value="org.springframework.web.servlet.view.JstlView" />
      </bean>
```

```
// 注解方法
@RequestMapping("/hello.do")
public ModelAndView hello() {
    ModelAndView mv = new ModelAndView("userView");
    mv.addObject("name", "luban");
    return mv;
}
```

提问 为什么基于 <mvc:annotation-driven/> 配置就能实现mvc 的整个配置了，之前所提到的 handlerMapping 、与handlerAdapter 组件都不适用了？
只要查看以类的源就可以知晓其中原因：
- [ ] 认识 NamespaceHandler 接口
- [ ] 查看 MvcNamespaceHandler
- [ ] 查看AnnotationDrivenBeanDefinitionParser

**结论**：
在<mvc:annotation-driven />  对应的解析器，自动向ioc  里面注册了两个BeanDefinition。分别是：RequestMappingHandlerMapping与BeanNameUrlHandlerMapping
 



