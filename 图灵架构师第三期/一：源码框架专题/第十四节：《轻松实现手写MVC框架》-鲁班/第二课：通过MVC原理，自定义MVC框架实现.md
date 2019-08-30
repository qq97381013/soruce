概要：
1.  MVC拦截处理
2. RequestMapping注解的使用与原理
3. 自定义MVC的框架实现



## 一、 MVC拦截处理

---
**知识点：**
HandlerExceptionResolver 异常处理
HandlerInterceptor 拦截器处理
dispatchServlet 初始化流程
### HandlerExceptionResolver 异常处理
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

ResponseStatusExceptionResolver(默认):
用于解析带@ResponseStatus的自定义异常
DefaultHandlerExceptionResolver(默认)：
spring mvc 默认异常处理。
SimpleMappingExceptionResolver：
异常映射，将指定异常与错误页面相对应

SimpleMappingExceptionResolver 示例：
```
<bean class="org.springframework.web.servlet.handler.SimpleMappingExceptionResolver">
    <property name="defaultErrorView" value="error"/>
    <property name="defaultStatusCode" value="500"/>
    <property name="exceptionMappings">
        <map>
            <entry key="java.lang.RuntimeException" value="error"/>
            <entry key="java.lang.IllegalArgumentException" value="argumentError"/>
        </map>
    </property>
</bean>
```
[argumentError.jsp](https://uploader.shimo.im/f/ftlgoyptrpQHNsjO.jsp)

[error.jsp](https://uploader.shimo.im/f/sds0S2qWWdIloHUv.jsp)


提问：
IllegalArgumentException 是 RuntimeException子类，如果IllegalArgumentException  异常同时满足映射的两个条件，这时会怎么选择跳转的视图？

### HandlerInterceptor  调用拦截
HandlerInterceptor   用于对请求拦截，与原生Filter区别在于 Filter只能在业务执行前拦截，而HandlerInterceptor 可以在业务处理前、中、后进行处理。
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

### dispatchServlet 初始化流程
初始化流程：
1. 创建WebApplicationContext
2. 基于策略模型加载各组件：

创建WebApplicationContext 源码解析
>>org.springframework.web.servlet.HttpServletBean#init
>>org.springframework.web.servlet.FrameworkServlet#initServletBean
>>org.springframework.web.servlet.FrameworkServlet#initWebApplicationContext
>// 基于当前存在的Spring 上下文做为Root 创建Mvc上下文。 
>>org.springframework.web.servlet.FrameworkServlet#createWebApplicationContext(org.springframework.context.ApplicationContext)
>>org.springframework.web.servlet.FrameworkServlet#configureAndRefreshWebApplicationContext
>>org.springframework.context.support.AbstractApplicationContext#refresh

基于策略模型加载各组件源码解析

## 二、RequestMapping注解的使用与原理

---
### 核心使用：
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
### 
### 实现组成结构：
![图片](https://uploader.shimo.im/f/14v98kRt6I02Ezt1.png!thumbnail)


1. RequestMappingHandlerMapping :URL 映射器
2. RequestMappingHandlerAdapter：执行适配器
3. InvocableHandlerMethod：Control目标对象，包含了control Bean 及对应的method 对像，及调用方法
  1.  HandlerMethodArgumentResolverComposite：参数处理器
  2.  ParameterNameDiscoverer：参数名称处理器
  3.  HandlerMethodReturnValueHandlerComposite：返回结构处理器


调用执行源码解析：

查找mapping源码解析
>// 基于注解查找 mapping
>org.springframework.web.servlet.DispatcherServlet#getHandler
>>org.springframework.web.servlet.handler.AbstractHandlerMapping#getHandler
> >org.springframework.web.servlet.handler.AbstractHandlerMethodMapping#lookupHandlerMethod
> >org.springframework.web.servlet.handler.AbstractHandlerMethodMapping.MappingRegistry#getMappingsByUrl

调用执行过程源码解析
>>org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter#handle
> >org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter#handleInternal 
> >org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter#invokeHandlerMethod
>   >org.springframework.web.method.support.InvocableHandlerMethod#invokeForRequest
>    >org.springframework.web.method.support.InvocableHandlerMethod#doInvoke

 


## 三、自定义MVC的框架实现

---
### 框架需求与目标
**框架需求：**
框架的需求包含功能性需求 和非功能性需求，功能性需求框架本身所提供的功能，而非功能性需求通常也指定体验性需求，即该框架对于开发者而言，是否易上手，是否需要较多的学习成本，以及在开发时需要过多的配置。
有个时候两者是互相矛盾冲突的，比如当我们想让框架支持更的功能时，那么它的结构设计将会更复杂，抽像的层次将会越多，带来的负面影响时对框架使用者的学习成本增加了。

 ![图片](https://images-cdn.shimo.im/zY3bbNnlOL82ikkW/image.png!thumbnail)

到底该选择更多的功能，还是更好的体验？这就需要框架作者要作出准确的定位与范围。
定位是该框架要完成什么目标？范围是实现该目标需实现哪些功能？两者清晰之后 自然知道哪些是必须做的，哪些是可以做的。而体验则是在保证必须功能的情况越高越好，甚至可以为了提供体验可以牺牲部分功能的完整性。


**功能性需求用例图：**
![图片](https://images-cdn.shimo.im/Vcl18rMcmqYxz9N1/image.png!thumbnail)

1. URL映射
  1. 基于注解自动匹配调用方法
2.  
  1. Form表单参数自动转换成一般对像和复杂对像
3. 请求调用
  1. 基于反射调用目标方法
4. 视图支持
  1. 基于返回结果跳转至对应视图处理
  2. 支持的有jsp 视图，freemarke视图，Json视图
5. 异常统一处理
  1. 出现异常统一处理，并跳转到异常页面

**非功能性需求与目标：**
1. 接近于零的配置
2. 更少的学习成本
  1. 尽可能使用用户之前习惯
  2. 概念性的东西要少一些
3. 2
4. 支持开发模式：动态装载配置
### 框架设计与编码实现

框架环境依赖：
框架名称：tuling-mvc
jdk:1.6 以上 
依赖包：spring、freemarker、java-servlet-api

**框架流程分解：**
![图片](https://images-cdn.shimo.im/wj0iUgFHnfIBt7o5/image.png!thumbnail)

**实现组件：**
1. **FreemarkeView**
  1. freemarke视图
2. **HandlerServlet**
  1. 请求参数封装，请求转发
3. **MvcBeanFactory**
  1. Mvc bean 工厂 ，从spring ioc 中扫描类装载MVC Bean
4. **MvcBean**
  1. MVC 业务执行
5. **MvcMapping**
  1. MVC注解，用于注解MVC Bean，并配置url 路径

**UML类图：** 
![图片](https://images-cdn.shimo.im/IhYMewYJZnwITFdT/image.png!thumbnail)


**MvcBean 装载时序图：**

![图片](https://images-cdn.shimo.im/7XhJbdrz8yQFyjPZ/image.png!thumbnail)

**1、httpServelt init**
**2、从ioc 容器中获取 mvcBeanFactory**
**3、构造Factory**
**4、遍历ioc beans**
**5、封装保存Mvc Beans**



**请求时序图：**
![图片](https://images-cdn.shimo.im/zw2Fro6EH7sIJgte/image.png!thumbnail)
 



