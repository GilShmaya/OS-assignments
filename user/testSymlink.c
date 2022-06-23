#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/fs.h"

int
main(){
    const char* oldpath = "/cat";
    const char* newpath = "/newcat";
    symlink(oldpath, newpath);
    struct stat st;
    char buf[256];
    readlink(newpath, buf, 256);
    int fd = open(newpath, O_RDONLY | O_NOFOLLOW);
    fstat(fd, &st);
    printf("%s %d %d %d\n", newpath, st.type, st.ino, st.size);

    exit(0);
}