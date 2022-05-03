#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void cas_test(int size, int interval, char* env_name) {
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
       pid = fork();
       if (pid != 0){
           printf("PID: %d\n", pid);
           pid = fork();
           if (pid != 0)
            printf("PID: %d\n", pid);
       }
    }
}

void test_list(int size, int interval, char* env_name) {
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
       pid = fork();
       if (pid != 0){
           pid = fork();
       }
    }
  
}

/*
void env_large() {
    env(10e6, 10e6, "env_large");
}

void env_freq() {
    env(10e1, 10e1, "env_freq");
} */;


int
main(int argc, char *argv[]){
    //test_cas(10e6, 10e6, "env_large");
    test_list(10e6, 10e6, "env_large");
    exit(0);

}