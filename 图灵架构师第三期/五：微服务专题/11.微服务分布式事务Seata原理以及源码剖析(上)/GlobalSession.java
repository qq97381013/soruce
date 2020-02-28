package com.tuling.testlock;

import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Created by smlz on 2020/2/26.
 */
@Slf4j
public class GlobalSession {

    private GlobalSessionLock globalSessionLock = new GlobalSessionLock();


    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    private boolean active =true;



    public GlobalSessionLock getGlobalSessionLock() {
        return globalSessionLock;
    }

    public void setGlobalSessionLock(GlobalSessionLock globalSessionLock) {
        this.globalSessionLock = globalSessionLock;
    }

    public void lock() throws InterruptedException {
        globalSessionLock.lock();
    }

    public void unlock() {
        globalSessionLock.unlock();
    }



    private static class GlobalSessionLock{

        private Lock globalSessionLock = new ReentrantLock();

        public Lock getGlobalSessionLock() {
            return globalSessionLock;
        }

        public void setGlobalSessionLock(Lock globalSessionLock) {
            this.globalSessionLock = globalSessionLock;
        }

        private static final int GLOBAL_SESSION_LOCK_TIME_OUT_MILLS = 2 * 1000;

        public void lock() throws InterruptedException {
            try {
                if (globalSessionLock.tryLock(GLOBAL_SESSION_LOCK_TIME_OUT_MILLS, TimeUnit.MILLISECONDS)) {
                    return;
                }
            } catch (InterruptedException e) {
                log.error("Interrupted error", e);
            }
            throw new RuntimeException("锁超时");
        }

        public void unlock() {
            globalSessionLock.unlock();
        }
    }

}
