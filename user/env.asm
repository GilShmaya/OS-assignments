
user/_env:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test_cas>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void test_cas(int size, int interval, char* env_name) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
       pid = fork();
   8:	00000097          	auipc	ra,0x0
   c:	338080e7          	jalr	824(ra) # 340 <fork>
       if (pid != 0){
  10:	e911                	bnez	a0,24 <test_cas+0x24>
       pid = fork();
  12:	00000097          	auipc	ra,0x0
  16:	32e080e7          	jalr	814(ra) # 340 <fork>
       if (pid != 0){
  1a:	ed0d                	bnez	a0,54 <test_cas+0x54>
           pid = fork();
           if (pid != 0)
            printf("PID: %d\n", pid);
       }
    }
}
  1c:	60a2                	ld	ra,8(sp)
  1e:	6402                	ld	s0,0(sp)
  20:	0141                	addi	sp,sp,16
  22:	8082                	ret
           printf("PID: %d\n", pid);
  24:	85aa                	mv	a1,a0
  26:	00001517          	auipc	a0,0x1
  2a:	85a50513          	addi	a0,a0,-1958 # 880 <malloc+0xea>
  2e:	00000097          	auipc	ra,0x0
  32:	6aa080e7          	jalr	1706(ra) # 6d8 <printf>
           pid = fork();
  36:	00000097          	auipc	ra,0x0
  3a:	30a080e7          	jalr	778(ra) # 340 <fork>
           if (pid != 0)
  3e:	d971                	beqz	a0,12 <test_cas+0x12>
            printf("PID: %d\n", pid);
  40:	85aa                	mv	a1,a0
  42:	00001517          	auipc	a0,0x1
  46:	83e50513          	addi	a0,a0,-1986 # 880 <malloc+0xea>
  4a:	00000097          	auipc	ra,0x0
  4e:	68e080e7          	jalr	1678(ra) # 6d8 <printf>
  52:	b7c1                	j	12 <test_cas+0x12>
           printf("PID: %d\n", pid);
  54:	85aa                	mv	a1,a0
  56:	00001517          	auipc	a0,0x1
  5a:	82a50513          	addi	a0,a0,-2006 # 880 <malloc+0xea>
  5e:	00000097          	auipc	ra,0x0
  62:	67a080e7          	jalr	1658(ra) # 6d8 <printf>
           pid = fork();
  66:	00000097          	auipc	ra,0x0
  6a:	2da080e7          	jalr	730(ra) # 340 <fork>
           if (pid != 0)
  6e:	d55d                	beqz	a0,1c <test_cas+0x1c>
            printf("PID: %d\n", pid);
  70:	85aa                	mv	a1,a0
  72:	00001517          	auipc	a0,0x1
  76:	80e50513          	addi	a0,a0,-2034 # 880 <malloc+0xea>
  7a:	00000097          	auipc	ra,0x0
  7e:	65e080e7          	jalr	1630(ra) # 6d8 <printf>
}
  82:	bf69                	j	1c <test_cas+0x1c>

0000000000000084 <env>:

void env() {
  84:	1101                	addi	sp,sp,-32
  86:	ec06                	sd	ra,24(sp)
  88:	e822                	sd	s0,16(sp)
  8a:	e426                	sd	s1,8(sp)
  8c:	1000                	addi	s0,sp,32
  8e:	44d1                	li	s1,20
    int n_forks = 20;
    for (int i = 0; i < n_forks; i++) {
       fork();
  90:	00000097          	auipc	ra,0x0
  94:	2b0080e7          	jalr	688(ra) # 340 <fork>
    for (int i = 0; i < n_forks; i++) {
  98:	34fd                	addiw	s1,s1,-1
  9a:	f8fd                	bnez	s1,90 <env+0xc>
    }
}
  9c:	60e2                	ld	ra,24(sp)
  9e:	6442                	ld	s0,16(sp)
  a0:	64a2                	ld	s1,8(sp)
  a2:	6105                	addi	sp,sp,32
  a4:	8082                	ret

00000000000000a6 <main>:
    env(10e1, 10e1, "env_freq");
} 
*/

int
main(int argc, char *argv[]){
  a6:	1141                	addi	sp,sp,-16
  a8:	e406                	sd	ra,8(sp)
  aa:	e022                	sd	s0,0(sp)
  ac:	0800                	addi	s0,sp,16
    test_cas(10e6, 10e6, "env_large");
  ae:	00000617          	auipc	a2,0x0
  b2:	7e260613          	addi	a2,a2,2018 # 890 <malloc+0xfa>
  b6:	009895b7          	lui	a1,0x989
  ba:	68058593          	addi	a1,a1,1664 # 989680 <__global_pointer$+0x9885c7>
  be:	852e                	mv	a0,a1
  c0:	00000097          	auipc	ra,0x0
  c4:	f40080e7          	jalr	-192(ra) # 0 <test_cas>
    //env();
    //test_list(10e6, 10e6, "env_large");
    exit(0);
  c8:	4501                	li	a0,0
  ca:	00000097          	auipc	ra,0x0
  ce:	27e080e7          	jalr	638(ra) # 348 <exit>

00000000000000d2 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  d2:	1141                	addi	sp,sp,-16
  d4:	e422                	sd	s0,8(sp)
  d6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  d8:	87aa                	mv	a5,a0
  da:	0585                	addi	a1,a1,1
  dc:	0785                	addi	a5,a5,1
  de:	fff5c703          	lbu	a4,-1(a1)
  e2:	fee78fa3          	sb	a4,-1(a5)
  e6:	fb75                	bnez	a4,da <strcpy+0x8>
    ;
  return os;
}
  e8:	6422                	ld	s0,8(sp)
  ea:	0141                	addi	sp,sp,16
  ec:	8082                	ret

00000000000000ee <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ee:	1141                	addi	sp,sp,-16
  f0:	e422                	sd	s0,8(sp)
  f2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  f4:	00054783          	lbu	a5,0(a0)
  f8:	cb91                	beqz	a5,10c <strcmp+0x1e>
  fa:	0005c703          	lbu	a4,0(a1)
  fe:	00f71763          	bne	a4,a5,10c <strcmp+0x1e>
    p++, q++;
 102:	0505                	addi	a0,a0,1
 104:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 106:	00054783          	lbu	a5,0(a0)
 10a:	fbe5                	bnez	a5,fa <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 10c:	0005c503          	lbu	a0,0(a1)
}
 110:	40a7853b          	subw	a0,a5,a0
 114:	6422                	ld	s0,8(sp)
 116:	0141                	addi	sp,sp,16
 118:	8082                	ret

000000000000011a <strlen>:

uint
strlen(const char *s)
{
 11a:	1141                	addi	sp,sp,-16
 11c:	e422                	sd	s0,8(sp)
 11e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 120:	00054783          	lbu	a5,0(a0)
 124:	cf91                	beqz	a5,140 <strlen+0x26>
 126:	0505                	addi	a0,a0,1
 128:	87aa                	mv	a5,a0
 12a:	4685                	li	a3,1
 12c:	9e89                	subw	a3,a3,a0
 12e:	00f6853b          	addw	a0,a3,a5
 132:	0785                	addi	a5,a5,1
 134:	fff7c703          	lbu	a4,-1(a5)
 138:	fb7d                	bnez	a4,12e <strlen+0x14>
    ;
  return n;
}
 13a:	6422                	ld	s0,8(sp)
 13c:	0141                	addi	sp,sp,16
 13e:	8082                	ret
  for(n = 0; s[n]; n++)
 140:	4501                	li	a0,0
 142:	bfe5                	j	13a <strlen+0x20>

0000000000000144 <memset>:

void*
memset(void *dst, int c, uint n)
{
 144:	1141                	addi	sp,sp,-16
 146:	e422                	sd	s0,8(sp)
 148:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 14a:	ce09                	beqz	a2,164 <memset+0x20>
 14c:	87aa                	mv	a5,a0
 14e:	fff6071b          	addiw	a4,a2,-1
 152:	1702                	slli	a4,a4,0x20
 154:	9301                	srli	a4,a4,0x20
 156:	0705                	addi	a4,a4,1
 158:	972a                	add	a4,a4,a0
    cdst[i] = c;
 15a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 15e:	0785                	addi	a5,a5,1
 160:	fee79de3          	bne	a5,a4,15a <memset+0x16>
  }
  return dst;
}
 164:	6422                	ld	s0,8(sp)
 166:	0141                	addi	sp,sp,16
 168:	8082                	ret

000000000000016a <strchr>:

char*
strchr(const char *s, char c)
{
 16a:	1141                	addi	sp,sp,-16
 16c:	e422                	sd	s0,8(sp)
 16e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 170:	00054783          	lbu	a5,0(a0)
 174:	cb99                	beqz	a5,18a <strchr+0x20>
    if(*s == c)
 176:	00f58763          	beq	a1,a5,184 <strchr+0x1a>
  for(; *s; s++)
 17a:	0505                	addi	a0,a0,1
 17c:	00054783          	lbu	a5,0(a0)
 180:	fbfd                	bnez	a5,176 <strchr+0xc>
      return (char*)s;
  return 0;
 182:	4501                	li	a0,0
}
 184:	6422                	ld	s0,8(sp)
 186:	0141                	addi	sp,sp,16
 188:	8082                	ret
  return 0;
 18a:	4501                	li	a0,0
 18c:	bfe5                	j	184 <strchr+0x1a>

000000000000018e <gets>:

char*
gets(char *buf, int max)
{
 18e:	711d                	addi	sp,sp,-96
 190:	ec86                	sd	ra,88(sp)
 192:	e8a2                	sd	s0,80(sp)
 194:	e4a6                	sd	s1,72(sp)
 196:	e0ca                	sd	s2,64(sp)
 198:	fc4e                	sd	s3,56(sp)
 19a:	f852                	sd	s4,48(sp)
 19c:	f456                	sd	s5,40(sp)
 19e:	f05a                	sd	s6,32(sp)
 1a0:	ec5e                	sd	s7,24(sp)
 1a2:	1080                	addi	s0,sp,96
 1a4:	8baa                	mv	s7,a0
 1a6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1a8:	892a                	mv	s2,a0
 1aa:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1ac:	4aa9                	li	s5,10
 1ae:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1b0:	89a6                	mv	s3,s1
 1b2:	2485                	addiw	s1,s1,1
 1b4:	0344d863          	bge	s1,s4,1e4 <gets+0x56>
    cc = read(0, &c, 1);
 1b8:	4605                	li	a2,1
 1ba:	faf40593          	addi	a1,s0,-81
 1be:	4501                	li	a0,0
 1c0:	00000097          	auipc	ra,0x0
 1c4:	1a0080e7          	jalr	416(ra) # 360 <read>
    if(cc < 1)
 1c8:	00a05e63          	blez	a0,1e4 <gets+0x56>
    buf[i++] = c;
 1cc:	faf44783          	lbu	a5,-81(s0)
 1d0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1d4:	01578763          	beq	a5,s5,1e2 <gets+0x54>
 1d8:	0905                	addi	s2,s2,1
 1da:	fd679be3          	bne	a5,s6,1b0 <gets+0x22>
  for(i=0; i+1 < max; ){
 1de:	89a6                	mv	s3,s1
 1e0:	a011                	j	1e4 <gets+0x56>
 1e2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1e4:	99de                	add	s3,s3,s7
 1e6:	00098023          	sb	zero,0(s3)
  return buf;
}
 1ea:	855e                	mv	a0,s7
 1ec:	60e6                	ld	ra,88(sp)
 1ee:	6446                	ld	s0,80(sp)
 1f0:	64a6                	ld	s1,72(sp)
 1f2:	6906                	ld	s2,64(sp)
 1f4:	79e2                	ld	s3,56(sp)
 1f6:	7a42                	ld	s4,48(sp)
 1f8:	7aa2                	ld	s5,40(sp)
 1fa:	7b02                	ld	s6,32(sp)
 1fc:	6be2                	ld	s7,24(sp)
 1fe:	6125                	addi	sp,sp,96
 200:	8082                	ret

0000000000000202 <stat>:

int
stat(const char *n, struct stat *st)
{
 202:	1101                	addi	sp,sp,-32
 204:	ec06                	sd	ra,24(sp)
 206:	e822                	sd	s0,16(sp)
 208:	e426                	sd	s1,8(sp)
 20a:	e04a                	sd	s2,0(sp)
 20c:	1000                	addi	s0,sp,32
 20e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 210:	4581                	li	a1,0
 212:	00000097          	auipc	ra,0x0
 216:	176080e7          	jalr	374(ra) # 388 <open>
  if(fd < 0)
 21a:	02054563          	bltz	a0,244 <stat+0x42>
 21e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 220:	85ca                	mv	a1,s2
 222:	00000097          	auipc	ra,0x0
 226:	17e080e7          	jalr	382(ra) # 3a0 <fstat>
 22a:	892a                	mv	s2,a0
  close(fd);
 22c:	8526                	mv	a0,s1
 22e:	00000097          	auipc	ra,0x0
 232:	142080e7          	jalr	322(ra) # 370 <close>
  return r;
}
 236:	854a                	mv	a0,s2
 238:	60e2                	ld	ra,24(sp)
 23a:	6442                	ld	s0,16(sp)
 23c:	64a2                	ld	s1,8(sp)
 23e:	6902                	ld	s2,0(sp)
 240:	6105                	addi	sp,sp,32
 242:	8082                	ret
    return -1;
 244:	597d                	li	s2,-1
 246:	bfc5                	j	236 <stat+0x34>

0000000000000248 <atoi>:

int
atoi(const char *s)
{
 248:	1141                	addi	sp,sp,-16
 24a:	e422                	sd	s0,8(sp)
 24c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 24e:	00054603          	lbu	a2,0(a0)
 252:	fd06079b          	addiw	a5,a2,-48
 256:	0ff7f793          	andi	a5,a5,255
 25a:	4725                	li	a4,9
 25c:	02f76963          	bltu	a4,a5,28e <atoi+0x46>
 260:	86aa                	mv	a3,a0
  n = 0;
 262:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 264:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 266:	0685                	addi	a3,a3,1
 268:	0025179b          	slliw	a5,a0,0x2
 26c:	9fa9                	addw	a5,a5,a0
 26e:	0017979b          	slliw	a5,a5,0x1
 272:	9fb1                	addw	a5,a5,a2
 274:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 278:	0006c603          	lbu	a2,0(a3)
 27c:	fd06071b          	addiw	a4,a2,-48
 280:	0ff77713          	andi	a4,a4,255
 284:	fee5f1e3          	bgeu	a1,a4,266 <atoi+0x1e>
  return n;
}
 288:	6422                	ld	s0,8(sp)
 28a:	0141                	addi	sp,sp,16
 28c:	8082                	ret
  n = 0;
 28e:	4501                	li	a0,0
 290:	bfe5                	j	288 <atoi+0x40>

0000000000000292 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 292:	1141                	addi	sp,sp,-16
 294:	e422                	sd	s0,8(sp)
 296:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 298:	02b57663          	bgeu	a0,a1,2c4 <memmove+0x32>
    while(n-- > 0)
 29c:	02c05163          	blez	a2,2be <memmove+0x2c>
 2a0:	fff6079b          	addiw	a5,a2,-1
 2a4:	1782                	slli	a5,a5,0x20
 2a6:	9381                	srli	a5,a5,0x20
 2a8:	0785                	addi	a5,a5,1
 2aa:	97aa                	add	a5,a5,a0
  dst = vdst;
 2ac:	872a                	mv	a4,a0
      *dst++ = *src++;
 2ae:	0585                	addi	a1,a1,1
 2b0:	0705                	addi	a4,a4,1
 2b2:	fff5c683          	lbu	a3,-1(a1)
 2b6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2ba:	fee79ae3          	bne	a5,a4,2ae <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2be:	6422                	ld	s0,8(sp)
 2c0:	0141                	addi	sp,sp,16
 2c2:	8082                	ret
    dst += n;
 2c4:	00c50733          	add	a4,a0,a2
    src += n;
 2c8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ca:	fec05ae3          	blez	a2,2be <memmove+0x2c>
 2ce:	fff6079b          	addiw	a5,a2,-1
 2d2:	1782                	slli	a5,a5,0x20
 2d4:	9381                	srli	a5,a5,0x20
 2d6:	fff7c793          	not	a5,a5
 2da:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2dc:	15fd                	addi	a1,a1,-1
 2de:	177d                	addi	a4,a4,-1
 2e0:	0005c683          	lbu	a3,0(a1)
 2e4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2e8:	fee79ae3          	bne	a5,a4,2dc <memmove+0x4a>
 2ec:	bfc9                	j	2be <memmove+0x2c>

00000000000002ee <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2f4:	ca05                	beqz	a2,324 <memcmp+0x36>
 2f6:	fff6069b          	addiw	a3,a2,-1
 2fa:	1682                	slli	a3,a3,0x20
 2fc:	9281                	srli	a3,a3,0x20
 2fe:	0685                	addi	a3,a3,1
 300:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 302:	00054783          	lbu	a5,0(a0)
 306:	0005c703          	lbu	a4,0(a1)
 30a:	00e79863          	bne	a5,a4,31a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 30e:	0505                	addi	a0,a0,1
    p2++;
 310:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 312:	fed518e3          	bne	a0,a3,302 <memcmp+0x14>
  }
  return 0;
 316:	4501                	li	a0,0
 318:	a019                	j	31e <memcmp+0x30>
      return *p1 - *p2;
 31a:	40e7853b          	subw	a0,a5,a4
}
 31e:	6422                	ld	s0,8(sp)
 320:	0141                	addi	sp,sp,16
 322:	8082                	ret
  return 0;
 324:	4501                	li	a0,0
 326:	bfe5                	j	31e <memcmp+0x30>

0000000000000328 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 328:	1141                	addi	sp,sp,-16
 32a:	e406                	sd	ra,8(sp)
 32c:	e022                	sd	s0,0(sp)
 32e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 330:	00000097          	auipc	ra,0x0
 334:	f62080e7          	jalr	-158(ra) # 292 <memmove>
}
 338:	60a2                	ld	ra,8(sp)
 33a:	6402                	ld	s0,0(sp)
 33c:	0141                	addi	sp,sp,16
 33e:	8082                	ret

0000000000000340 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 340:	4885                	li	a7,1
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <exit>:
.global exit
exit:
 li a7, SYS_exit
 348:	4889                	li	a7,2
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <wait>:
.global wait
wait:
 li a7, SYS_wait
 350:	488d                	li	a7,3
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 358:	4891                	li	a7,4
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <read>:
.global read
read:
 li a7, SYS_read
 360:	4895                	li	a7,5
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <write>:
.global write
write:
 li a7, SYS_write
 368:	48c1                	li	a7,16
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <close>:
.global close
close:
 li a7, SYS_close
 370:	48d5                	li	a7,21
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <kill>:
.global kill
kill:
 li a7, SYS_kill
 378:	4899                	li	a7,6
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <exec>:
.global exec
exec:
 li a7, SYS_exec
 380:	489d                	li	a7,7
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <open>:
.global open
open:
 li a7, SYS_open
 388:	48bd                	li	a7,15
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 390:	48c5                	li	a7,17
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 398:	48c9                	li	a7,18
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3a0:	48a1                	li	a7,8
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <link>:
.global link
link:
 li a7, SYS_link
 3a8:	48cd                	li	a7,19
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3b0:	48d1                	li	a7,20
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3b8:	48a5                	li	a7,9
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3c0:	48a9                	li	a7,10
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3c8:	48ad                	li	a7,11
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3d0:	48b1                	li	a7,12
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3d8:	48b5                	li	a7,13
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3e0:	48b9                	li	a7,14
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <set_cpu>:
.global set_cpu
set_cpu:
 li a7, SYS_set_cpu
 3e8:	48d9                	li	a7,22
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <get_cpu>:
.global get_cpu
get_cpu:
 li a7, SYS_get_cpu
 3f0:	48dd                	li	a7,23
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <cpu_process_count>:
.global cpu_process_count
cpu_process_count:
 li a7, SYS_cpu_process_count
 3f8:	48e1                	li	a7,24
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 400:	1101                	addi	sp,sp,-32
 402:	ec06                	sd	ra,24(sp)
 404:	e822                	sd	s0,16(sp)
 406:	1000                	addi	s0,sp,32
 408:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 40c:	4605                	li	a2,1
 40e:	fef40593          	addi	a1,s0,-17
 412:	00000097          	auipc	ra,0x0
 416:	f56080e7          	jalr	-170(ra) # 368 <write>
}
 41a:	60e2                	ld	ra,24(sp)
 41c:	6442                	ld	s0,16(sp)
 41e:	6105                	addi	sp,sp,32
 420:	8082                	ret

0000000000000422 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 422:	7139                	addi	sp,sp,-64
 424:	fc06                	sd	ra,56(sp)
 426:	f822                	sd	s0,48(sp)
 428:	f426                	sd	s1,40(sp)
 42a:	f04a                	sd	s2,32(sp)
 42c:	ec4e                	sd	s3,24(sp)
 42e:	0080                	addi	s0,sp,64
 430:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 432:	c299                	beqz	a3,438 <printint+0x16>
 434:	0805c863          	bltz	a1,4c4 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 438:	2581                	sext.w	a1,a1
  neg = 0;
 43a:	4881                	li	a7,0
 43c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 440:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 442:	2601                	sext.w	a2,a2
 444:	00000517          	auipc	a0,0x0
 448:	46450513          	addi	a0,a0,1124 # 8a8 <digits>
 44c:	883a                	mv	a6,a4
 44e:	2705                	addiw	a4,a4,1
 450:	02c5f7bb          	remuw	a5,a1,a2
 454:	1782                	slli	a5,a5,0x20
 456:	9381                	srli	a5,a5,0x20
 458:	97aa                	add	a5,a5,a0
 45a:	0007c783          	lbu	a5,0(a5)
 45e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 462:	0005879b          	sext.w	a5,a1
 466:	02c5d5bb          	divuw	a1,a1,a2
 46a:	0685                	addi	a3,a3,1
 46c:	fec7f0e3          	bgeu	a5,a2,44c <printint+0x2a>
  if(neg)
 470:	00088b63          	beqz	a7,486 <printint+0x64>
    buf[i++] = '-';
 474:	fd040793          	addi	a5,s0,-48
 478:	973e                	add	a4,a4,a5
 47a:	02d00793          	li	a5,45
 47e:	fef70823          	sb	a5,-16(a4)
 482:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 486:	02e05863          	blez	a4,4b6 <printint+0x94>
 48a:	fc040793          	addi	a5,s0,-64
 48e:	00e78933          	add	s2,a5,a4
 492:	fff78993          	addi	s3,a5,-1
 496:	99ba                	add	s3,s3,a4
 498:	377d                	addiw	a4,a4,-1
 49a:	1702                	slli	a4,a4,0x20
 49c:	9301                	srli	a4,a4,0x20
 49e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4a2:	fff94583          	lbu	a1,-1(s2)
 4a6:	8526                	mv	a0,s1
 4a8:	00000097          	auipc	ra,0x0
 4ac:	f58080e7          	jalr	-168(ra) # 400 <putc>
  while(--i >= 0)
 4b0:	197d                	addi	s2,s2,-1
 4b2:	ff3918e3          	bne	s2,s3,4a2 <printint+0x80>
}
 4b6:	70e2                	ld	ra,56(sp)
 4b8:	7442                	ld	s0,48(sp)
 4ba:	74a2                	ld	s1,40(sp)
 4bc:	7902                	ld	s2,32(sp)
 4be:	69e2                	ld	s3,24(sp)
 4c0:	6121                	addi	sp,sp,64
 4c2:	8082                	ret
    x = -xx;
 4c4:	40b005bb          	negw	a1,a1
    neg = 1;
 4c8:	4885                	li	a7,1
    x = -xx;
 4ca:	bf8d                	j	43c <printint+0x1a>

00000000000004cc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4cc:	7119                	addi	sp,sp,-128
 4ce:	fc86                	sd	ra,120(sp)
 4d0:	f8a2                	sd	s0,112(sp)
 4d2:	f4a6                	sd	s1,104(sp)
 4d4:	f0ca                	sd	s2,96(sp)
 4d6:	ecce                	sd	s3,88(sp)
 4d8:	e8d2                	sd	s4,80(sp)
 4da:	e4d6                	sd	s5,72(sp)
 4dc:	e0da                	sd	s6,64(sp)
 4de:	fc5e                	sd	s7,56(sp)
 4e0:	f862                	sd	s8,48(sp)
 4e2:	f466                	sd	s9,40(sp)
 4e4:	f06a                	sd	s10,32(sp)
 4e6:	ec6e                	sd	s11,24(sp)
 4e8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ea:	0005c903          	lbu	s2,0(a1)
 4ee:	18090f63          	beqz	s2,68c <vprintf+0x1c0>
 4f2:	8aaa                	mv	s5,a0
 4f4:	8b32                	mv	s6,a2
 4f6:	00158493          	addi	s1,a1,1
  state = 0;
 4fa:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4fc:	02500a13          	li	s4,37
      if(c == 'd'){
 500:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 504:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 508:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 50c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 510:	00000b97          	auipc	s7,0x0
 514:	398b8b93          	addi	s7,s7,920 # 8a8 <digits>
 518:	a839                	j	536 <vprintf+0x6a>
        putc(fd, c);
 51a:	85ca                	mv	a1,s2
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	ee2080e7          	jalr	-286(ra) # 400 <putc>
 526:	a019                	j	52c <vprintf+0x60>
    } else if(state == '%'){
 528:	01498f63          	beq	s3,s4,546 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 52c:	0485                	addi	s1,s1,1
 52e:	fff4c903          	lbu	s2,-1(s1)
 532:	14090d63          	beqz	s2,68c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 536:	0009079b          	sext.w	a5,s2
    if(state == 0){
 53a:	fe0997e3          	bnez	s3,528 <vprintf+0x5c>
      if(c == '%'){
 53e:	fd479ee3          	bne	a5,s4,51a <vprintf+0x4e>
        state = '%';
 542:	89be                	mv	s3,a5
 544:	b7e5                	j	52c <vprintf+0x60>
      if(c == 'd'){
 546:	05878063          	beq	a5,s8,586 <vprintf+0xba>
      } else if(c == 'l') {
 54a:	05978c63          	beq	a5,s9,5a2 <vprintf+0xd6>
      } else if(c == 'x') {
 54e:	07a78863          	beq	a5,s10,5be <vprintf+0xf2>
      } else if(c == 'p') {
 552:	09b78463          	beq	a5,s11,5da <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 556:	07300713          	li	a4,115
 55a:	0ce78663          	beq	a5,a4,626 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 55e:	06300713          	li	a4,99
 562:	0ee78e63          	beq	a5,a4,65e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 566:	11478863          	beq	a5,s4,676 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 56a:	85d2                	mv	a1,s4
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	e92080e7          	jalr	-366(ra) # 400 <putc>
        putc(fd, c);
 576:	85ca                	mv	a1,s2
 578:	8556                	mv	a0,s5
 57a:	00000097          	auipc	ra,0x0
 57e:	e86080e7          	jalr	-378(ra) # 400 <putc>
      }
      state = 0;
 582:	4981                	li	s3,0
 584:	b765                	j	52c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 586:	008b0913          	addi	s2,s6,8
 58a:	4685                	li	a3,1
 58c:	4629                	li	a2,10
 58e:	000b2583          	lw	a1,0(s6)
 592:	8556                	mv	a0,s5
 594:	00000097          	auipc	ra,0x0
 598:	e8e080e7          	jalr	-370(ra) # 422 <printint>
 59c:	8b4a                	mv	s6,s2
      state = 0;
 59e:	4981                	li	s3,0
 5a0:	b771                	j	52c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5a2:	008b0913          	addi	s2,s6,8
 5a6:	4681                	li	a3,0
 5a8:	4629                	li	a2,10
 5aa:	000b2583          	lw	a1,0(s6)
 5ae:	8556                	mv	a0,s5
 5b0:	00000097          	auipc	ra,0x0
 5b4:	e72080e7          	jalr	-398(ra) # 422 <printint>
 5b8:	8b4a                	mv	s6,s2
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	bf85                	j	52c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5be:	008b0913          	addi	s2,s6,8
 5c2:	4681                	li	a3,0
 5c4:	4641                	li	a2,16
 5c6:	000b2583          	lw	a1,0(s6)
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	e56080e7          	jalr	-426(ra) # 422 <printint>
 5d4:	8b4a                	mv	s6,s2
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	bf91                	j	52c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5da:	008b0793          	addi	a5,s6,8
 5de:	f8f43423          	sd	a5,-120(s0)
 5e2:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5e6:	03000593          	li	a1,48
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e14080e7          	jalr	-492(ra) # 400 <putc>
  putc(fd, 'x');
 5f4:	85ea                	mv	a1,s10
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	e08080e7          	jalr	-504(ra) # 400 <putc>
 600:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 602:	03c9d793          	srli	a5,s3,0x3c
 606:	97de                	add	a5,a5,s7
 608:	0007c583          	lbu	a1,0(a5)
 60c:	8556                	mv	a0,s5
 60e:	00000097          	auipc	ra,0x0
 612:	df2080e7          	jalr	-526(ra) # 400 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 616:	0992                	slli	s3,s3,0x4
 618:	397d                	addiw	s2,s2,-1
 61a:	fe0914e3          	bnez	s2,602 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 61e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 622:	4981                	li	s3,0
 624:	b721                	j	52c <vprintf+0x60>
        s = va_arg(ap, char*);
 626:	008b0993          	addi	s3,s6,8
 62a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 62e:	02090163          	beqz	s2,650 <vprintf+0x184>
        while(*s != 0){
 632:	00094583          	lbu	a1,0(s2)
 636:	c9a1                	beqz	a1,686 <vprintf+0x1ba>
          putc(fd, *s);
 638:	8556                	mv	a0,s5
 63a:	00000097          	auipc	ra,0x0
 63e:	dc6080e7          	jalr	-570(ra) # 400 <putc>
          s++;
 642:	0905                	addi	s2,s2,1
        while(*s != 0){
 644:	00094583          	lbu	a1,0(s2)
 648:	f9e5                	bnez	a1,638 <vprintf+0x16c>
        s = va_arg(ap, char*);
 64a:	8b4e                	mv	s6,s3
      state = 0;
 64c:	4981                	li	s3,0
 64e:	bdf9                	j	52c <vprintf+0x60>
          s = "(null)";
 650:	00000917          	auipc	s2,0x0
 654:	25090913          	addi	s2,s2,592 # 8a0 <malloc+0x10a>
        while(*s != 0){
 658:	02800593          	li	a1,40
 65c:	bff1                	j	638 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 65e:	008b0913          	addi	s2,s6,8
 662:	000b4583          	lbu	a1,0(s6)
 666:	8556                	mv	a0,s5
 668:	00000097          	auipc	ra,0x0
 66c:	d98080e7          	jalr	-616(ra) # 400 <putc>
 670:	8b4a                	mv	s6,s2
      state = 0;
 672:	4981                	li	s3,0
 674:	bd65                	j	52c <vprintf+0x60>
        putc(fd, c);
 676:	85d2                	mv	a1,s4
 678:	8556                	mv	a0,s5
 67a:	00000097          	auipc	ra,0x0
 67e:	d86080e7          	jalr	-634(ra) # 400 <putc>
      state = 0;
 682:	4981                	li	s3,0
 684:	b565                	j	52c <vprintf+0x60>
        s = va_arg(ap, char*);
 686:	8b4e                	mv	s6,s3
      state = 0;
 688:	4981                	li	s3,0
 68a:	b54d                	j	52c <vprintf+0x60>
    }
  }
}
 68c:	70e6                	ld	ra,120(sp)
 68e:	7446                	ld	s0,112(sp)
 690:	74a6                	ld	s1,104(sp)
 692:	7906                	ld	s2,96(sp)
 694:	69e6                	ld	s3,88(sp)
 696:	6a46                	ld	s4,80(sp)
 698:	6aa6                	ld	s5,72(sp)
 69a:	6b06                	ld	s6,64(sp)
 69c:	7be2                	ld	s7,56(sp)
 69e:	7c42                	ld	s8,48(sp)
 6a0:	7ca2                	ld	s9,40(sp)
 6a2:	7d02                	ld	s10,32(sp)
 6a4:	6de2                	ld	s11,24(sp)
 6a6:	6109                	addi	sp,sp,128
 6a8:	8082                	ret

00000000000006aa <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6aa:	715d                	addi	sp,sp,-80
 6ac:	ec06                	sd	ra,24(sp)
 6ae:	e822                	sd	s0,16(sp)
 6b0:	1000                	addi	s0,sp,32
 6b2:	e010                	sd	a2,0(s0)
 6b4:	e414                	sd	a3,8(s0)
 6b6:	e818                	sd	a4,16(s0)
 6b8:	ec1c                	sd	a5,24(s0)
 6ba:	03043023          	sd	a6,32(s0)
 6be:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6c2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6c6:	8622                	mv	a2,s0
 6c8:	00000097          	auipc	ra,0x0
 6cc:	e04080e7          	jalr	-508(ra) # 4cc <vprintf>
}
 6d0:	60e2                	ld	ra,24(sp)
 6d2:	6442                	ld	s0,16(sp)
 6d4:	6161                	addi	sp,sp,80
 6d6:	8082                	ret

00000000000006d8 <printf>:

void
printf(const char *fmt, ...)
{
 6d8:	711d                	addi	sp,sp,-96
 6da:	ec06                	sd	ra,24(sp)
 6dc:	e822                	sd	s0,16(sp)
 6de:	1000                	addi	s0,sp,32
 6e0:	e40c                	sd	a1,8(s0)
 6e2:	e810                	sd	a2,16(s0)
 6e4:	ec14                	sd	a3,24(s0)
 6e6:	f018                	sd	a4,32(s0)
 6e8:	f41c                	sd	a5,40(s0)
 6ea:	03043823          	sd	a6,48(s0)
 6ee:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6f2:	00840613          	addi	a2,s0,8
 6f6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6fa:	85aa                	mv	a1,a0
 6fc:	4505                	li	a0,1
 6fe:	00000097          	auipc	ra,0x0
 702:	dce080e7          	jalr	-562(ra) # 4cc <vprintf>
}
 706:	60e2                	ld	ra,24(sp)
 708:	6442                	ld	s0,16(sp)
 70a:	6125                	addi	sp,sp,96
 70c:	8082                	ret

000000000000070e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 70e:	1141                	addi	sp,sp,-16
 710:	e422                	sd	s0,8(sp)
 712:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 714:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 718:	00000797          	auipc	a5,0x0
 71c:	1a87b783          	ld	a5,424(a5) # 8c0 <freep>
 720:	a805                	j	750 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 722:	4618                	lw	a4,8(a2)
 724:	9db9                	addw	a1,a1,a4
 726:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 72a:	6398                	ld	a4,0(a5)
 72c:	6318                	ld	a4,0(a4)
 72e:	fee53823          	sd	a4,-16(a0)
 732:	a091                	j	776 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 734:	ff852703          	lw	a4,-8(a0)
 738:	9e39                	addw	a2,a2,a4
 73a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 73c:	ff053703          	ld	a4,-16(a0)
 740:	e398                	sd	a4,0(a5)
 742:	a099                	j	788 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 744:	6398                	ld	a4,0(a5)
 746:	00e7e463          	bltu	a5,a4,74e <free+0x40>
 74a:	00e6ea63          	bltu	a3,a4,75e <free+0x50>
{
 74e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 750:	fed7fae3          	bgeu	a5,a3,744 <free+0x36>
 754:	6398                	ld	a4,0(a5)
 756:	00e6e463          	bltu	a3,a4,75e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 75a:	fee7eae3          	bltu	a5,a4,74e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 75e:	ff852583          	lw	a1,-8(a0)
 762:	6390                	ld	a2,0(a5)
 764:	02059713          	slli	a4,a1,0x20
 768:	9301                	srli	a4,a4,0x20
 76a:	0712                	slli	a4,a4,0x4
 76c:	9736                	add	a4,a4,a3
 76e:	fae60ae3          	beq	a2,a4,722 <free+0x14>
    bp->s.ptr = p->s.ptr;
 772:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 776:	4790                	lw	a2,8(a5)
 778:	02061713          	slli	a4,a2,0x20
 77c:	9301                	srli	a4,a4,0x20
 77e:	0712                	slli	a4,a4,0x4
 780:	973e                	add	a4,a4,a5
 782:	fae689e3          	beq	a3,a4,734 <free+0x26>
  } else
    p->s.ptr = bp;
 786:	e394                	sd	a3,0(a5)
  freep = p;
 788:	00000717          	auipc	a4,0x0
 78c:	12f73c23          	sd	a5,312(a4) # 8c0 <freep>
}
 790:	6422                	ld	s0,8(sp)
 792:	0141                	addi	sp,sp,16
 794:	8082                	ret

0000000000000796 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 796:	7139                	addi	sp,sp,-64
 798:	fc06                	sd	ra,56(sp)
 79a:	f822                	sd	s0,48(sp)
 79c:	f426                	sd	s1,40(sp)
 79e:	f04a                	sd	s2,32(sp)
 7a0:	ec4e                	sd	s3,24(sp)
 7a2:	e852                	sd	s4,16(sp)
 7a4:	e456                	sd	s5,8(sp)
 7a6:	e05a                	sd	s6,0(sp)
 7a8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7aa:	02051493          	slli	s1,a0,0x20
 7ae:	9081                	srli	s1,s1,0x20
 7b0:	04bd                	addi	s1,s1,15
 7b2:	8091                	srli	s1,s1,0x4
 7b4:	0014899b          	addiw	s3,s1,1
 7b8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ba:	00000517          	auipc	a0,0x0
 7be:	10653503          	ld	a0,262(a0) # 8c0 <freep>
 7c2:	c515                	beqz	a0,7ee <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7c4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7c6:	4798                	lw	a4,8(a5)
 7c8:	02977f63          	bgeu	a4,s1,806 <malloc+0x70>
 7cc:	8a4e                	mv	s4,s3
 7ce:	0009871b          	sext.w	a4,s3
 7d2:	6685                	lui	a3,0x1
 7d4:	00d77363          	bgeu	a4,a3,7da <malloc+0x44>
 7d8:	6a05                	lui	s4,0x1
 7da:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7de:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7e2:	00000917          	auipc	s2,0x0
 7e6:	0de90913          	addi	s2,s2,222 # 8c0 <freep>
  if(p == (char*)-1)
 7ea:	5afd                	li	s5,-1
 7ec:	a88d                	j	85e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7ee:	00000797          	auipc	a5,0x0
 7f2:	0da78793          	addi	a5,a5,218 # 8c8 <base>
 7f6:	00000717          	auipc	a4,0x0
 7fa:	0cf73523          	sd	a5,202(a4) # 8c0 <freep>
 7fe:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 800:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 804:	b7e1                	j	7cc <malloc+0x36>
      if(p->s.size == nunits)
 806:	02e48b63          	beq	s1,a4,83c <malloc+0xa6>
        p->s.size -= nunits;
 80a:	4137073b          	subw	a4,a4,s3
 80e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 810:	1702                	slli	a4,a4,0x20
 812:	9301                	srli	a4,a4,0x20
 814:	0712                	slli	a4,a4,0x4
 816:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 818:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 81c:	00000717          	auipc	a4,0x0
 820:	0aa73223          	sd	a0,164(a4) # 8c0 <freep>
      return (void*)(p + 1);
 824:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 828:	70e2                	ld	ra,56(sp)
 82a:	7442                	ld	s0,48(sp)
 82c:	74a2                	ld	s1,40(sp)
 82e:	7902                	ld	s2,32(sp)
 830:	69e2                	ld	s3,24(sp)
 832:	6a42                	ld	s4,16(sp)
 834:	6aa2                	ld	s5,8(sp)
 836:	6b02                	ld	s6,0(sp)
 838:	6121                	addi	sp,sp,64
 83a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 83c:	6398                	ld	a4,0(a5)
 83e:	e118                	sd	a4,0(a0)
 840:	bff1                	j	81c <malloc+0x86>
  hp->s.size = nu;
 842:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 846:	0541                	addi	a0,a0,16
 848:	00000097          	auipc	ra,0x0
 84c:	ec6080e7          	jalr	-314(ra) # 70e <free>
  return freep;
 850:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 854:	d971                	beqz	a0,828 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 856:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 858:	4798                	lw	a4,8(a5)
 85a:	fa9776e3          	bgeu	a4,s1,806 <malloc+0x70>
    if(p == freep)
 85e:	00093703          	ld	a4,0(s2)
 862:	853e                	mv	a0,a5
 864:	fef719e3          	bne	a4,a5,856 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 868:	8552                	mv	a0,s4
 86a:	00000097          	auipc	ra,0x0
 86e:	b66080e7          	jalr	-1178(ra) # 3d0 <sbrk>
  if(p == (char*)-1)
 872:	fd5518e3          	bne	a0,s5,842 <malloc+0xac>
        return 0;
 876:	4501                	li	a0,0
 878:	bf45                	j	828 <malloc+0x92>
