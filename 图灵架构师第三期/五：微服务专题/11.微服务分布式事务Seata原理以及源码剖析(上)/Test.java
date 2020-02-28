package com.tuling.testlock;

/**
 * Created by smlz on 2020/2/26.
 */
public class Test {


    public static void main(String[] args) {

        Thread commitThread = new Thread(new Runnable() {
            public void run() {
                commit();
            }
        });
        commitThread.setName("commitThread");

        Thread branchRegThread = new Thread(new Runnable() {
            public void run() {
                branchReg();
            }
        });
        branchRegThread.setName("branchRegThread");

        commitThread.start();

        branchRegThread.start();

    }

    public static void commit() {
        //模拟从数据库查询出来的
        GlobalSession globalSession = new GlobalSession();
        try {
            globalSession.lock();
            globalSession.setActive(false);
            System.out.println("模拟执行业务方法");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }finally {
            globalSession.unlock();
        }
    }

    public static void branchReg() {
        //从数据库拿出来的
        GlobalSession globalSession = new GlobalSession();
        try {
            globalSession.lock();
            if(!globalSession.isActive()){
                throw new RuntimeException("全局事务关闭 无法注册分支事务");
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }finally {
            globalSession.unlock();
        }
    }
}
