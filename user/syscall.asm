
user/_syscall:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <pause_system_dem>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
  16:	8a2a                	mv	s4,a0
  18:	8b2e                	mv	s6,a1
  1a:	8932                	mv	s2,a2
    int pid = getpid();
  1c:	00000097          	auipc	ra,0x0
  20:	4ca080e7          	jalr	1226(ra) # 4e6 <getpid>
    for (int i = 0; i < loop_size; i++) {
  24:	05205b63          	blez	s2,7a <pause_system_dem+0x7a>
  28:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  2a:	01f9599b          	srliw	s3,s2,0x1f
  2e:	012989bb          	addw	s3,s3,s2
  32:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  36:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
  38:	00001b97          	auipc	s7,0x1
  3c:	960b8b93          	addi	s7,s7,-1696 # 998 <malloc+0xe4>
  40:	a031                	j	4c <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
  42:	02998663          	beq	s3,s1,6e <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
  46:	2485                	addiw	s1,s1,1
  48:	02990963          	beq	s2,s1,7a <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
  4c:	0344e7bb          	remw	a5,s1,s4
  50:	fbed                	bnez	a5,42 <pause_system_dem+0x42>
  52:	00000097          	auipc	ra,0x0
  56:	494080e7          	jalr	1172(ra) # 4e6 <getpid>
  5a:	ff5514e3          	bne	a0,s5,42 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
  5e:	864a                	mv	a2,s2
  60:	85a6                	mv	a1,s1
  62:	855e                	mv	a0,s7
  64:	00000097          	auipc	ra,0x0
  68:	792080e7          	jalr	1938(ra) # 7f6 <printf>
  6c:	bfd9                	j	42 <pause_system_dem+0x42>
            pause_system(pause_seconds);
  6e:	855a                	mv	a0,s6
  70:	00000097          	auipc	ra,0x0
  74:	496080e7          	jalr	1174(ra) # 506 <pause_system>
  78:	b7f9                	j	46 <pause_system_dem+0x46>
        }
    }
    printf("\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	93e50513          	addi	a0,a0,-1730 # 9b8 <malloc+0x104>
  82:	00000097          	auipc	ra,0x0
  86:	774080e7          	jalr	1908(ra) # 7f6 <printf>
}
  8a:	60a6                	ld	ra,72(sp)
  8c:	6406                	ld	s0,64(sp)
  8e:	74e2                	ld	s1,56(sp)
  90:	7942                	ld	s2,48(sp)
  92:	79a2                	ld	s3,40(sp)
  94:	7a02                	ld	s4,32(sp)
  96:	6ae2                	ld	s5,24(sp)
  98:	6b42                	ld	s6,16(sp)
  9a:	6ba2                	ld	s7,8(sp)
  9c:	6161                	addi	sp,sp,80
  9e:	8082                	ret

00000000000000a0 <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  a0:	7139                	addi	sp,sp,-64
  a2:	fc06                	sd	ra,56(sp)
  a4:	f822                	sd	s0,48(sp)
  a6:	f426                	sd	s1,40(sp)
  a8:	f04a                	sd	s2,32(sp)
  aa:	ec4e                	sd	s3,24(sp)
  ac:	e852                	sd	s4,16(sp)
  ae:	e456                	sd	s5,8(sp)
  b0:	e05a                	sd	s6,0(sp)
  b2:	0080                	addi	s0,sp,64
  b4:	8a2a                	mv	s4,a0
  b6:	892e                	mv	s2,a1
    int pid = getpid();
  b8:	00000097          	auipc	ra,0x0
  bc:	42e080e7          	jalr	1070(ra) # 4e6 <getpid>
    for (int i = 0; i < loop_size; i++) {
  c0:	05205a63          	blez	s2,114 <kill_system_dem+0x74>
  c4:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  c6:	01f9599b          	srliw	s3,s2,0x1f
  ca:	012989bb          	addw	s3,s3,s2
  ce:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  d2:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  d4:	00001b17          	auipc	s6,0x1
  d8:	8ecb0b13          	addi	s6,s6,-1812 # 9c0 <malloc+0x10c>
  dc:	a031                	j	e8 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  de:	02998663          	beq	s3,s1,10a <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  e2:	2485                	addiw	s1,s1,1
  e4:	02990863          	beq	s2,s1,114 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  e8:	0344e7bb          	remw	a5,s1,s4
  ec:	fbed                	bnez	a5,de <kill_system_dem+0x3e>
  ee:	00000097          	auipc	ra,0x0
  f2:	3f8080e7          	jalr	1016(ra) # 4e6 <getpid>
  f6:	ff5514e3          	bne	a0,s5,de <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  fa:	864a                	mv	a2,s2
  fc:	85a6                	mv	a1,s1
  fe:	855a                	mv	a0,s6
 100:	00000097          	auipc	ra,0x0
 104:	6f6080e7          	jalr	1782(ra) # 7f6 <printf>
 108:	bfd9                	j	de <kill_system_dem+0x3e>
            kill_system();
 10a:	00000097          	auipc	ra,0x0
 10e:	404080e7          	jalr	1028(ra) # 50e <kill_system>
 112:	bfc1                	j	e2 <kill_system_dem+0x42>
        }
    }
    printf("\n");
 114:	00001517          	auipc	a0,0x1
 118:	8a450513          	addi	a0,a0,-1884 # 9b8 <malloc+0x104>
 11c:	00000097          	auipc	ra,0x0
 120:	6da080e7          	jalr	1754(ra) # 7f6 <printf>
}
 124:	70e2                	ld	ra,56(sp)
 126:	7442                	ld	s0,48(sp)
 128:	74a2                	ld	s1,40(sp)
 12a:	7902                	ld	s2,32(sp)
 12c:	69e2                	ld	s3,24(sp)
 12e:	6a42                	ld	s4,16(sp)
 130:	6aa2                	ld	s5,8(sp)
 132:	6b02                	ld	s6,0(sp)
 134:	6121                	addi	sp,sp,64
 136:	8082                	ret

0000000000000138 <set_economic_mode_dem>:


void set_economic_mode_dem(int interval, int loop_size) {
 138:	7139                	addi	sp,sp,-64
 13a:	fc06                	sd	ra,56(sp)
 13c:	f822                	sd	s0,48(sp)
 13e:	f426                	sd	s1,40(sp)
 140:	f04a                	sd	s2,32(sp)
 142:	ec4e                	sd	s3,24(sp)
 144:	e852                	sd	s4,16(sp)
 146:	e456                	sd	s5,8(sp)
 148:	0080                	addi	s0,sp,64
 14a:	89aa                	mv	s3,a0
 14c:	892e                	mv	s2,a1
    int pid = getpid();
 14e:	00000097          	auipc	ra,0x0
 152:	398080e7          	jalr	920(ra) # 4e6 <getpid>
    //set_economic_mode(1);
    for (int i = 0; i < loop_size; i++) {
 156:	03205d63          	blez	s2,190 <set_economic_mode_dem+0x58>
 15a:	8a2a                	mv	s4,a0
 15c:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("set economic mode %d/%d completed.\n", i, loop_size);
 15e:	00001a97          	auipc	s5,0x1
 162:	882a8a93          	addi	s5,s5,-1918 # 9e0 <malloc+0x12c>
 166:	a021                	j	16e <set_economic_mode_dem+0x36>
    for (int i = 0; i < loop_size; i++) {
 168:	2485                	addiw	s1,s1,1
 16a:	02990363          	beq	s2,s1,190 <set_economic_mode_dem+0x58>
        if (i % interval == 0 && pid == getpid()) {
 16e:	0334e7bb          	remw	a5,s1,s3
 172:	fbfd                	bnez	a5,168 <set_economic_mode_dem+0x30>
 174:	00000097          	auipc	ra,0x0
 178:	372080e7          	jalr	882(ra) # 4e6 <getpid>
 17c:	ff4516e3          	bne	a0,s4,168 <set_economic_mode_dem+0x30>
            printf("set economic mode %d/%d completed.\n", i, loop_size);
 180:	864a                	mv	a2,s2
 182:	85a6                	mv	a1,s1
 184:	8556                	mv	a0,s5
 186:	00000097          	auipc	ra,0x0
 18a:	670080e7          	jalr	1648(ra) # 7f6 <printf>
 18e:	bfe9                	j	168 <set_economic_mode_dem+0x30>
        }
        if (i == loop_size / 2) {
            //set_economic_mode(0);
        }
    }
    printf("\n");
 190:	00001517          	auipc	a0,0x1
 194:	82850513          	addi	a0,a0,-2008 # 9b8 <malloc+0x104>
 198:	00000097          	auipc	ra,0x0
 19c:	65e080e7          	jalr	1630(ra) # 7f6 <printf>
}
 1a0:	70e2                	ld	ra,56(sp)
 1a2:	7442                	ld	s0,48(sp)
 1a4:	74a2                	ld	s1,40(sp)
 1a6:	7902                	ld	s2,32(sp)
 1a8:	69e2                	ld	s3,24(sp)
 1aa:	6a42                	ld	s4,16(sp)
 1ac:	6aa2                	ld	s5,8(sp)
 1ae:	6121                	addi	sp,sp,64
 1b0:	8082                	ret

00000000000001b2 <main>:

int
main(int argc, char *argv[])
{
 1b2:	1141                	addi	sp,sp,-16
 1b4:	e406                	sd	ra,8(sp)
 1b6:	e022                	sd	s0,0(sp)
 1b8:	0800                	addi	s0,sp,16
    set_economic_mode_dem(10, 100);
 1ba:	06400593          	li	a1,100
 1be:	4529                	li	a0,10
 1c0:	00000097          	auipc	ra,0x0
 1c4:	f78080e7          	jalr	-136(ra) # 138 <set_economic_mode_dem>
    pause_system_dem(10, 10, 100);
 1c8:	06400613          	li	a2,100
 1cc:	45a9                	li	a1,10
 1ce:	4529                	li	a0,10
 1d0:	00000097          	auipc	ra,0x0
 1d4:	e30080e7          	jalr	-464(ra) # 0 <pause_system_dem>
    kill_system_dem(10, 100);
 1d8:	06400593          	li	a1,100
 1dc:	4529                	li	a0,10
 1de:	00000097          	auipc	ra,0x0
 1e2:	ec2080e7          	jalr	-318(ra) # a0 <kill_system_dem>
    exit(0);
 1e6:	4501                	li	a0,0
 1e8:	00000097          	auipc	ra,0x0
 1ec:	27e080e7          	jalr	638(ra) # 466 <exit>

00000000000001f0 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1f0:	1141                	addi	sp,sp,-16
 1f2:	e422                	sd	s0,8(sp)
 1f4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1f6:	87aa                	mv	a5,a0
 1f8:	0585                	addi	a1,a1,1
 1fa:	0785                	addi	a5,a5,1
 1fc:	fff5c703          	lbu	a4,-1(a1)
 200:	fee78fa3          	sb	a4,-1(a5)
 204:	fb75                	bnez	a4,1f8 <strcpy+0x8>
    ;
  return os;
}
 206:	6422                	ld	s0,8(sp)
 208:	0141                	addi	sp,sp,16
 20a:	8082                	ret

000000000000020c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 20c:	1141                	addi	sp,sp,-16
 20e:	e422                	sd	s0,8(sp)
 210:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 212:	00054783          	lbu	a5,0(a0)
 216:	cb91                	beqz	a5,22a <strcmp+0x1e>
 218:	0005c703          	lbu	a4,0(a1)
 21c:	00f71763          	bne	a4,a5,22a <strcmp+0x1e>
    p++, q++;
 220:	0505                	addi	a0,a0,1
 222:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 224:	00054783          	lbu	a5,0(a0)
 228:	fbe5                	bnez	a5,218 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 22a:	0005c503          	lbu	a0,0(a1)
}
 22e:	40a7853b          	subw	a0,a5,a0
 232:	6422                	ld	s0,8(sp)
 234:	0141                	addi	sp,sp,16
 236:	8082                	ret

0000000000000238 <strlen>:

uint
strlen(const char *s)
{
 238:	1141                	addi	sp,sp,-16
 23a:	e422                	sd	s0,8(sp)
 23c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 23e:	00054783          	lbu	a5,0(a0)
 242:	cf91                	beqz	a5,25e <strlen+0x26>
 244:	0505                	addi	a0,a0,1
 246:	87aa                	mv	a5,a0
 248:	4685                	li	a3,1
 24a:	9e89                	subw	a3,a3,a0
 24c:	00f6853b          	addw	a0,a3,a5
 250:	0785                	addi	a5,a5,1
 252:	fff7c703          	lbu	a4,-1(a5)
 256:	fb7d                	bnez	a4,24c <strlen+0x14>
    ;
  return n;
}
 258:	6422                	ld	s0,8(sp)
 25a:	0141                	addi	sp,sp,16
 25c:	8082                	ret
  for(n = 0; s[n]; n++)
 25e:	4501                	li	a0,0
 260:	bfe5                	j	258 <strlen+0x20>

0000000000000262 <memset>:

void*
memset(void *dst, int c, uint n)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 268:	ce09                	beqz	a2,282 <memset+0x20>
 26a:	87aa                	mv	a5,a0
 26c:	fff6071b          	addiw	a4,a2,-1
 270:	1702                	slli	a4,a4,0x20
 272:	9301                	srli	a4,a4,0x20
 274:	0705                	addi	a4,a4,1
 276:	972a                	add	a4,a4,a0
    cdst[i] = c;
 278:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 27c:	0785                	addi	a5,a5,1
 27e:	fee79de3          	bne	a5,a4,278 <memset+0x16>
  }
  return dst;
}
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret

0000000000000288 <strchr>:

char*
strchr(const char *s, char c)
{
 288:	1141                	addi	sp,sp,-16
 28a:	e422                	sd	s0,8(sp)
 28c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 28e:	00054783          	lbu	a5,0(a0)
 292:	cb99                	beqz	a5,2a8 <strchr+0x20>
    if(*s == c)
 294:	00f58763          	beq	a1,a5,2a2 <strchr+0x1a>
  for(; *s; s++)
 298:	0505                	addi	a0,a0,1
 29a:	00054783          	lbu	a5,0(a0)
 29e:	fbfd                	bnez	a5,294 <strchr+0xc>
      return (char*)s;
  return 0;
 2a0:	4501                	li	a0,0
}
 2a2:	6422                	ld	s0,8(sp)
 2a4:	0141                	addi	sp,sp,16
 2a6:	8082                	ret
  return 0;
 2a8:	4501                	li	a0,0
 2aa:	bfe5                	j	2a2 <strchr+0x1a>

00000000000002ac <gets>:

char*
gets(char *buf, int max)
{
 2ac:	711d                	addi	sp,sp,-96
 2ae:	ec86                	sd	ra,88(sp)
 2b0:	e8a2                	sd	s0,80(sp)
 2b2:	e4a6                	sd	s1,72(sp)
 2b4:	e0ca                	sd	s2,64(sp)
 2b6:	fc4e                	sd	s3,56(sp)
 2b8:	f852                	sd	s4,48(sp)
 2ba:	f456                	sd	s5,40(sp)
 2bc:	f05a                	sd	s6,32(sp)
 2be:	ec5e                	sd	s7,24(sp)
 2c0:	1080                	addi	s0,sp,96
 2c2:	8baa                	mv	s7,a0
 2c4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2c6:	892a                	mv	s2,a0
 2c8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2ca:	4aa9                	li	s5,10
 2cc:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2ce:	89a6                	mv	s3,s1
 2d0:	2485                	addiw	s1,s1,1
 2d2:	0344d863          	bge	s1,s4,302 <gets+0x56>
    cc = read(0, &c, 1);
 2d6:	4605                	li	a2,1
 2d8:	faf40593          	addi	a1,s0,-81
 2dc:	4501                	li	a0,0
 2de:	00000097          	auipc	ra,0x0
 2e2:	1a0080e7          	jalr	416(ra) # 47e <read>
    if(cc < 1)
 2e6:	00a05e63          	blez	a0,302 <gets+0x56>
    buf[i++] = c;
 2ea:	faf44783          	lbu	a5,-81(s0)
 2ee:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2f2:	01578763          	beq	a5,s5,300 <gets+0x54>
 2f6:	0905                	addi	s2,s2,1
 2f8:	fd679be3          	bne	a5,s6,2ce <gets+0x22>
  for(i=0; i+1 < max; ){
 2fc:	89a6                	mv	s3,s1
 2fe:	a011                	j	302 <gets+0x56>
 300:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 302:	99de                	add	s3,s3,s7
 304:	00098023          	sb	zero,0(s3)
  return buf;
}
 308:	855e                	mv	a0,s7
 30a:	60e6                	ld	ra,88(sp)
 30c:	6446                	ld	s0,80(sp)
 30e:	64a6                	ld	s1,72(sp)
 310:	6906                	ld	s2,64(sp)
 312:	79e2                	ld	s3,56(sp)
 314:	7a42                	ld	s4,48(sp)
 316:	7aa2                	ld	s5,40(sp)
 318:	7b02                	ld	s6,32(sp)
 31a:	6be2                	ld	s7,24(sp)
 31c:	6125                	addi	sp,sp,96
 31e:	8082                	ret

0000000000000320 <stat>:

int
stat(const char *n, struct stat *st)
{
 320:	1101                	addi	sp,sp,-32
 322:	ec06                	sd	ra,24(sp)
 324:	e822                	sd	s0,16(sp)
 326:	e426                	sd	s1,8(sp)
 328:	e04a                	sd	s2,0(sp)
 32a:	1000                	addi	s0,sp,32
 32c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 32e:	4581                	li	a1,0
 330:	00000097          	auipc	ra,0x0
 334:	176080e7          	jalr	374(ra) # 4a6 <open>
  if(fd < 0)
 338:	02054563          	bltz	a0,362 <stat+0x42>
 33c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 33e:	85ca                	mv	a1,s2
 340:	00000097          	auipc	ra,0x0
 344:	17e080e7          	jalr	382(ra) # 4be <fstat>
 348:	892a                	mv	s2,a0
  close(fd);
 34a:	8526                	mv	a0,s1
 34c:	00000097          	auipc	ra,0x0
 350:	142080e7          	jalr	322(ra) # 48e <close>
  return r;
}
 354:	854a                	mv	a0,s2
 356:	60e2                	ld	ra,24(sp)
 358:	6442                	ld	s0,16(sp)
 35a:	64a2                	ld	s1,8(sp)
 35c:	6902                	ld	s2,0(sp)
 35e:	6105                	addi	sp,sp,32
 360:	8082                	ret
    return -1;
 362:	597d                	li	s2,-1
 364:	bfc5                	j	354 <stat+0x34>

0000000000000366 <atoi>:

int
atoi(const char *s)
{
 366:	1141                	addi	sp,sp,-16
 368:	e422                	sd	s0,8(sp)
 36a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 36c:	00054603          	lbu	a2,0(a0)
 370:	fd06079b          	addiw	a5,a2,-48
 374:	0ff7f793          	andi	a5,a5,255
 378:	4725                	li	a4,9
 37a:	02f76963          	bltu	a4,a5,3ac <atoi+0x46>
 37e:	86aa                	mv	a3,a0
  n = 0;
 380:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 382:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 384:	0685                	addi	a3,a3,1
 386:	0025179b          	slliw	a5,a0,0x2
 38a:	9fa9                	addw	a5,a5,a0
 38c:	0017979b          	slliw	a5,a5,0x1
 390:	9fb1                	addw	a5,a5,a2
 392:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 396:	0006c603          	lbu	a2,0(a3)
 39a:	fd06071b          	addiw	a4,a2,-48
 39e:	0ff77713          	andi	a4,a4,255
 3a2:	fee5f1e3          	bgeu	a1,a4,384 <atoi+0x1e>
  return n;
}
 3a6:	6422                	ld	s0,8(sp)
 3a8:	0141                	addi	sp,sp,16
 3aa:	8082                	ret
  n = 0;
 3ac:	4501                	li	a0,0
 3ae:	bfe5                	j	3a6 <atoi+0x40>

00000000000003b0 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3b0:	1141                	addi	sp,sp,-16
 3b2:	e422                	sd	s0,8(sp)
 3b4:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3b6:	02b57663          	bgeu	a0,a1,3e2 <memmove+0x32>
    while(n-- > 0)
 3ba:	02c05163          	blez	a2,3dc <memmove+0x2c>
 3be:	fff6079b          	addiw	a5,a2,-1
 3c2:	1782                	slli	a5,a5,0x20
 3c4:	9381                	srli	a5,a5,0x20
 3c6:	0785                	addi	a5,a5,1
 3c8:	97aa                	add	a5,a5,a0
  dst = vdst;
 3ca:	872a                	mv	a4,a0
      *dst++ = *src++;
 3cc:	0585                	addi	a1,a1,1
 3ce:	0705                	addi	a4,a4,1
 3d0:	fff5c683          	lbu	a3,-1(a1)
 3d4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3d8:	fee79ae3          	bne	a5,a4,3cc <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3dc:	6422                	ld	s0,8(sp)
 3de:	0141                	addi	sp,sp,16
 3e0:	8082                	ret
    dst += n;
 3e2:	00c50733          	add	a4,a0,a2
    src += n;
 3e6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3e8:	fec05ae3          	blez	a2,3dc <memmove+0x2c>
 3ec:	fff6079b          	addiw	a5,a2,-1
 3f0:	1782                	slli	a5,a5,0x20
 3f2:	9381                	srli	a5,a5,0x20
 3f4:	fff7c793          	not	a5,a5
 3f8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3fa:	15fd                	addi	a1,a1,-1
 3fc:	177d                	addi	a4,a4,-1
 3fe:	0005c683          	lbu	a3,0(a1)
 402:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 406:	fee79ae3          	bne	a5,a4,3fa <memmove+0x4a>
 40a:	bfc9                	j	3dc <memmove+0x2c>

000000000000040c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 40c:	1141                	addi	sp,sp,-16
 40e:	e422                	sd	s0,8(sp)
 410:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 412:	ca05                	beqz	a2,442 <memcmp+0x36>
 414:	fff6069b          	addiw	a3,a2,-1
 418:	1682                	slli	a3,a3,0x20
 41a:	9281                	srli	a3,a3,0x20
 41c:	0685                	addi	a3,a3,1
 41e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 420:	00054783          	lbu	a5,0(a0)
 424:	0005c703          	lbu	a4,0(a1)
 428:	00e79863          	bne	a5,a4,438 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 42c:	0505                	addi	a0,a0,1
    p2++;
 42e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 430:	fed518e3          	bne	a0,a3,420 <memcmp+0x14>
  }
  return 0;
 434:	4501                	li	a0,0
 436:	a019                	j	43c <memcmp+0x30>
      return *p1 - *p2;
 438:	40e7853b          	subw	a0,a5,a4
}
 43c:	6422                	ld	s0,8(sp)
 43e:	0141                	addi	sp,sp,16
 440:	8082                	ret
  return 0;
 442:	4501                	li	a0,0
 444:	bfe5                	j	43c <memcmp+0x30>

0000000000000446 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 446:	1141                	addi	sp,sp,-16
 448:	e406                	sd	ra,8(sp)
 44a:	e022                	sd	s0,0(sp)
 44c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 44e:	00000097          	auipc	ra,0x0
 452:	f62080e7          	jalr	-158(ra) # 3b0 <memmove>
}
 456:	60a2                	ld	ra,8(sp)
 458:	6402                	ld	s0,0(sp)
 45a:	0141                	addi	sp,sp,16
 45c:	8082                	ret

000000000000045e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 45e:	4885                	li	a7,1
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <exit>:
.global exit
exit:
 li a7, SYS_exit
 466:	4889                	li	a7,2
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <wait>:
.global wait
wait:
 li a7, SYS_wait
 46e:	488d                	li	a7,3
 ecall
 470:	00000073          	ecall
 ret
 474:	8082                	ret

0000000000000476 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 476:	4891                	li	a7,4
 ecall
 478:	00000073          	ecall
 ret
 47c:	8082                	ret

000000000000047e <read>:
.global read
read:
 li a7, SYS_read
 47e:	4895                	li	a7,5
 ecall
 480:	00000073          	ecall
 ret
 484:	8082                	ret

0000000000000486 <write>:
.global write
write:
 li a7, SYS_write
 486:	48c1                	li	a7,16
 ecall
 488:	00000073          	ecall
 ret
 48c:	8082                	ret

000000000000048e <close>:
.global close
close:
 li a7, SYS_close
 48e:	48d5                	li	a7,21
 ecall
 490:	00000073          	ecall
 ret
 494:	8082                	ret

0000000000000496 <kill>:
.global kill
kill:
 li a7, SYS_kill
 496:	4899                	li	a7,6
 ecall
 498:	00000073          	ecall
 ret
 49c:	8082                	ret

000000000000049e <exec>:
.global exec
exec:
 li a7, SYS_exec
 49e:	489d                	li	a7,7
 ecall
 4a0:	00000073          	ecall
 ret
 4a4:	8082                	ret

00000000000004a6 <open>:
.global open
open:
 li a7, SYS_open
 4a6:	48bd                	li	a7,15
 ecall
 4a8:	00000073          	ecall
 ret
 4ac:	8082                	ret

00000000000004ae <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4ae:	48c5                	li	a7,17
 ecall
 4b0:	00000073          	ecall
 ret
 4b4:	8082                	ret

00000000000004b6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4b6:	48c9                	li	a7,18
 ecall
 4b8:	00000073          	ecall
 ret
 4bc:	8082                	ret

00000000000004be <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4be:	48a1                	li	a7,8
 ecall
 4c0:	00000073          	ecall
 ret
 4c4:	8082                	ret

00000000000004c6 <link>:
.global link
link:
 li a7, SYS_link
 4c6:	48cd                	li	a7,19
 ecall
 4c8:	00000073          	ecall
 ret
 4cc:	8082                	ret

00000000000004ce <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4ce:	48d1                	li	a7,20
 ecall
 4d0:	00000073          	ecall
 ret
 4d4:	8082                	ret

00000000000004d6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4d6:	48a5                	li	a7,9
 ecall
 4d8:	00000073          	ecall
 ret
 4dc:	8082                	ret

00000000000004de <dup>:
.global dup
dup:
 li a7, SYS_dup
 4de:	48a9                	li	a7,10
 ecall
 4e0:	00000073          	ecall
 ret
 4e4:	8082                	ret

00000000000004e6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4e6:	48ad                	li	a7,11
 ecall
 4e8:	00000073          	ecall
 ret
 4ec:	8082                	ret

00000000000004ee <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4ee:	48b1                	li	a7,12
 ecall
 4f0:	00000073          	ecall
 ret
 4f4:	8082                	ret

00000000000004f6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4f6:	48b5                	li	a7,13
 ecall
 4f8:	00000073          	ecall
 ret
 4fc:	8082                	ret

00000000000004fe <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4fe:	48b9                	li	a7,14
 ecall
 500:	00000073          	ecall
 ret
 504:	8082                	ret

0000000000000506 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 506:	48d9                	li	a7,22
 ecall
 508:	00000073          	ecall
 ret
 50c:	8082                	ret

000000000000050e <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 50e:	48dd                	li	a7,23
 ecall
 510:	00000073          	ecall
 ret
 514:	8082                	ret

0000000000000516 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 516:	48e1                	li	a7,24
 ecall
 518:	00000073          	ecall
 ret
 51c:	8082                	ret

000000000000051e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 51e:	1101                	addi	sp,sp,-32
 520:	ec06                	sd	ra,24(sp)
 522:	e822                	sd	s0,16(sp)
 524:	1000                	addi	s0,sp,32
 526:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 52a:	4605                	li	a2,1
 52c:	fef40593          	addi	a1,s0,-17
 530:	00000097          	auipc	ra,0x0
 534:	f56080e7          	jalr	-170(ra) # 486 <write>
}
 538:	60e2                	ld	ra,24(sp)
 53a:	6442                	ld	s0,16(sp)
 53c:	6105                	addi	sp,sp,32
 53e:	8082                	ret

0000000000000540 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 540:	7139                	addi	sp,sp,-64
 542:	fc06                	sd	ra,56(sp)
 544:	f822                	sd	s0,48(sp)
 546:	f426                	sd	s1,40(sp)
 548:	f04a                	sd	s2,32(sp)
 54a:	ec4e                	sd	s3,24(sp)
 54c:	0080                	addi	s0,sp,64
 54e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 550:	c299                	beqz	a3,556 <printint+0x16>
 552:	0805c863          	bltz	a1,5e2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 556:	2581                	sext.w	a1,a1
  neg = 0;
 558:	4881                	li	a7,0
 55a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 55e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 560:	2601                	sext.w	a2,a2
 562:	00000517          	auipc	a0,0x0
 566:	4ae50513          	addi	a0,a0,1198 # a10 <digits>
 56a:	883a                	mv	a6,a4
 56c:	2705                	addiw	a4,a4,1
 56e:	02c5f7bb          	remuw	a5,a1,a2
 572:	1782                	slli	a5,a5,0x20
 574:	9381                	srli	a5,a5,0x20
 576:	97aa                	add	a5,a5,a0
 578:	0007c783          	lbu	a5,0(a5)
 57c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 580:	0005879b          	sext.w	a5,a1
 584:	02c5d5bb          	divuw	a1,a1,a2
 588:	0685                	addi	a3,a3,1
 58a:	fec7f0e3          	bgeu	a5,a2,56a <printint+0x2a>
  if(neg)
 58e:	00088b63          	beqz	a7,5a4 <printint+0x64>
    buf[i++] = '-';
 592:	fd040793          	addi	a5,s0,-48
 596:	973e                	add	a4,a4,a5
 598:	02d00793          	li	a5,45
 59c:	fef70823          	sb	a5,-16(a4)
 5a0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5a4:	02e05863          	blez	a4,5d4 <printint+0x94>
 5a8:	fc040793          	addi	a5,s0,-64
 5ac:	00e78933          	add	s2,a5,a4
 5b0:	fff78993          	addi	s3,a5,-1
 5b4:	99ba                	add	s3,s3,a4
 5b6:	377d                	addiw	a4,a4,-1
 5b8:	1702                	slli	a4,a4,0x20
 5ba:	9301                	srli	a4,a4,0x20
 5bc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5c0:	fff94583          	lbu	a1,-1(s2)
 5c4:	8526                	mv	a0,s1
 5c6:	00000097          	auipc	ra,0x0
 5ca:	f58080e7          	jalr	-168(ra) # 51e <putc>
  while(--i >= 0)
 5ce:	197d                	addi	s2,s2,-1
 5d0:	ff3918e3          	bne	s2,s3,5c0 <printint+0x80>
}
 5d4:	70e2                	ld	ra,56(sp)
 5d6:	7442                	ld	s0,48(sp)
 5d8:	74a2                	ld	s1,40(sp)
 5da:	7902                	ld	s2,32(sp)
 5dc:	69e2                	ld	s3,24(sp)
 5de:	6121                	addi	sp,sp,64
 5e0:	8082                	ret
    x = -xx;
 5e2:	40b005bb          	negw	a1,a1
    neg = 1;
 5e6:	4885                	li	a7,1
    x = -xx;
 5e8:	bf8d                	j	55a <printint+0x1a>

00000000000005ea <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5ea:	7119                	addi	sp,sp,-128
 5ec:	fc86                	sd	ra,120(sp)
 5ee:	f8a2                	sd	s0,112(sp)
 5f0:	f4a6                	sd	s1,104(sp)
 5f2:	f0ca                	sd	s2,96(sp)
 5f4:	ecce                	sd	s3,88(sp)
 5f6:	e8d2                	sd	s4,80(sp)
 5f8:	e4d6                	sd	s5,72(sp)
 5fa:	e0da                	sd	s6,64(sp)
 5fc:	fc5e                	sd	s7,56(sp)
 5fe:	f862                	sd	s8,48(sp)
 600:	f466                	sd	s9,40(sp)
 602:	f06a                	sd	s10,32(sp)
 604:	ec6e                	sd	s11,24(sp)
 606:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 608:	0005c903          	lbu	s2,0(a1)
 60c:	18090f63          	beqz	s2,7aa <vprintf+0x1c0>
 610:	8aaa                	mv	s5,a0
 612:	8b32                	mv	s6,a2
 614:	00158493          	addi	s1,a1,1
  state = 0;
 618:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 61a:	02500a13          	li	s4,37
      if(c == 'd'){
 61e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 622:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 626:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 62a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 62e:	00000b97          	auipc	s7,0x0
 632:	3e2b8b93          	addi	s7,s7,994 # a10 <digits>
 636:	a839                	j	654 <vprintf+0x6a>
        putc(fd, c);
 638:	85ca                	mv	a1,s2
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	ee2080e7          	jalr	-286(ra) # 51e <putc>
 644:	a019                	j	64a <vprintf+0x60>
    } else if(state == '%'){
 646:	01498f63          	beq	s3,s4,664 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 64a:	0485                	addi	s1,s1,1
 64c:	fff4c903          	lbu	s2,-1(s1)
 650:	14090d63          	beqz	s2,7aa <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 654:	0009079b          	sext.w	a5,s2
    if(state == 0){
 658:	fe0997e3          	bnez	s3,646 <vprintf+0x5c>
      if(c == '%'){
 65c:	fd479ee3          	bne	a5,s4,638 <vprintf+0x4e>
        state = '%';
 660:	89be                	mv	s3,a5
 662:	b7e5                	j	64a <vprintf+0x60>
      if(c == 'd'){
 664:	05878063          	beq	a5,s8,6a4 <vprintf+0xba>
      } else if(c == 'l') {
 668:	05978c63          	beq	a5,s9,6c0 <vprintf+0xd6>
      } else if(c == 'x') {
 66c:	07a78863          	beq	a5,s10,6dc <vprintf+0xf2>
      } else if(c == 'p') {
 670:	09b78463          	beq	a5,s11,6f8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 674:	07300713          	li	a4,115
 678:	0ce78663          	beq	a5,a4,744 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 67c:	06300713          	li	a4,99
 680:	0ee78e63          	beq	a5,a4,77c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 684:	11478863          	beq	a5,s4,794 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 688:	85d2                	mv	a1,s4
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	e92080e7          	jalr	-366(ra) # 51e <putc>
        putc(fd, c);
 694:	85ca                	mv	a1,s2
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	e86080e7          	jalr	-378(ra) # 51e <putc>
      }
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	b765                	j	64a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6a4:	008b0913          	addi	s2,s6,8
 6a8:	4685                	li	a3,1
 6aa:	4629                	li	a2,10
 6ac:	000b2583          	lw	a1,0(s6)
 6b0:	8556                	mv	a0,s5
 6b2:	00000097          	auipc	ra,0x0
 6b6:	e8e080e7          	jalr	-370(ra) # 540 <printint>
 6ba:	8b4a                	mv	s6,s2
      state = 0;
 6bc:	4981                	li	s3,0
 6be:	b771                	j	64a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6c0:	008b0913          	addi	s2,s6,8
 6c4:	4681                	li	a3,0
 6c6:	4629                	li	a2,10
 6c8:	000b2583          	lw	a1,0(s6)
 6cc:	8556                	mv	a0,s5
 6ce:	00000097          	auipc	ra,0x0
 6d2:	e72080e7          	jalr	-398(ra) # 540 <printint>
 6d6:	8b4a                	mv	s6,s2
      state = 0;
 6d8:	4981                	li	s3,0
 6da:	bf85                	j	64a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6dc:	008b0913          	addi	s2,s6,8
 6e0:	4681                	li	a3,0
 6e2:	4641                	li	a2,16
 6e4:	000b2583          	lw	a1,0(s6)
 6e8:	8556                	mv	a0,s5
 6ea:	00000097          	auipc	ra,0x0
 6ee:	e56080e7          	jalr	-426(ra) # 540 <printint>
 6f2:	8b4a                	mv	s6,s2
      state = 0;
 6f4:	4981                	li	s3,0
 6f6:	bf91                	j	64a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6f8:	008b0793          	addi	a5,s6,8
 6fc:	f8f43423          	sd	a5,-120(s0)
 700:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 704:	03000593          	li	a1,48
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	e14080e7          	jalr	-492(ra) # 51e <putc>
  putc(fd, 'x');
 712:	85ea                	mv	a1,s10
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	e08080e7          	jalr	-504(ra) # 51e <putc>
 71e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 720:	03c9d793          	srli	a5,s3,0x3c
 724:	97de                	add	a5,a5,s7
 726:	0007c583          	lbu	a1,0(a5)
 72a:	8556                	mv	a0,s5
 72c:	00000097          	auipc	ra,0x0
 730:	df2080e7          	jalr	-526(ra) # 51e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 734:	0992                	slli	s3,s3,0x4
 736:	397d                	addiw	s2,s2,-1
 738:	fe0914e3          	bnez	s2,720 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 73c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 740:	4981                	li	s3,0
 742:	b721                	j	64a <vprintf+0x60>
        s = va_arg(ap, char*);
 744:	008b0993          	addi	s3,s6,8
 748:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 74c:	02090163          	beqz	s2,76e <vprintf+0x184>
        while(*s != 0){
 750:	00094583          	lbu	a1,0(s2)
 754:	c9a1                	beqz	a1,7a4 <vprintf+0x1ba>
          putc(fd, *s);
 756:	8556                	mv	a0,s5
 758:	00000097          	auipc	ra,0x0
 75c:	dc6080e7          	jalr	-570(ra) # 51e <putc>
          s++;
 760:	0905                	addi	s2,s2,1
        while(*s != 0){
 762:	00094583          	lbu	a1,0(s2)
 766:	f9e5                	bnez	a1,756 <vprintf+0x16c>
        s = va_arg(ap, char*);
 768:	8b4e                	mv	s6,s3
      state = 0;
 76a:	4981                	li	s3,0
 76c:	bdf9                	j	64a <vprintf+0x60>
          s = "(null)";
 76e:	00000917          	auipc	s2,0x0
 772:	29a90913          	addi	s2,s2,666 # a08 <malloc+0x154>
        while(*s != 0){
 776:	02800593          	li	a1,40
 77a:	bff1                	j	756 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 77c:	008b0913          	addi	s2,s6,8
 780:	000b4583          	lbu	a1,0(s6)
 784:	8556                	mv	a0,s5
 786:	00000097          	auipc	ra,0x0
 78a:	d98080e7          	jalr	-616(ra) # 51e <putc>
 78e:	8b4a                	mv	s6,s2
      state = 0;
 790:	4981                	li	s3,0
 792:	bd65                	j	64a <vprintf+0x60>
        putc(fd, c);
 794:	85d2                	mv	a1,s4
 796:	8556                	mv	a0,s5
 798:	00000097          	auipc	ra,0x0
 79c:	d86080e7          	jalr	-634(ra) # 51e <putc>
      state = 0;
 7a0:	4981                	li	s3,0
 7a2:	b565                	j	64a <vprintf+0x60>
        s = va_arg(ap, char*);
 7a4:	8b4e                	mv	s6,s3
      state = 0;
 7a6:	4981                	li	s3,0
 7a8:	b54d                	j	64a <vprintf+0x60>
    }
  }
}
 7aa:	70e6                	ld	ra,120(sp)
 7ac:	7446                	ld	s0,112(sp)
 7ae:	74a6                	ld	s1,104(sp)
 7b0:	7906                	ld	s2,96(sp)
 7b2:	69e6                	ld	s3,88(sp)
 7b4:	6a46                	ld	s4,80(sp)
 7b6:	6aa6                	ld	s5,72(sp)
 7b8:	6b06                	ld	s6,64(sp)
 7ba:	7be2                	ld	s7,56(sp)
 7bc:	7c42                	ld	s8,48(sp)
 7be:	7ca2                	ld	s9,40(sp)
 7c0:	7d02                	ld	s10,32(sp)
 7c2:	6de2                	ld	s11,24(sp)
 7c4:	6109                	addi	sp,sp,128
 7c6:	8082                	ret

00000000000007c8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7c8:	715d                	addi	sp,sp,-80
 7ca:	ec06                	sd	ra,24(sp)
 7cc:	e822                	sd	s0,16(sp)
 7ce:	1000                	addi	s0,sp,32
 7d0:	e010                	sd	a2,0(s0)
 7d2:	e414                	sd	a3,8(s0)
 7d4:	e818                	sd	a4,16(s0)
 7d6:	ec1c                	sd	a5,24(s0)
 7d8:	03043023          	sd	a6,32(s0)
 7dc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7e0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7e4:	8622                	mv	a2,s0
 7e6:	00000097          	auipc	ra,0x0
 7ea:	e04080e7          	jalr	-508(ra) # 5ea <vprintf>
}
 7ee:	60e2                	ld	ra,24(sp)
 7f0:	6442                	ld	s0,16(sp)
 7f2:	6161                	addi	sp,sp,80
 7f4:	8082                	ret

00000000000007f6 <printf>:

void
printf(const char *fmt, ...)
{
 7f6:	711d                	addi	sp,sp,-96
 7f8:	ec06                	sd	ra,24(sp)
 7fa:	e822                	sd	s0,16(sp)
 7fc:	1000                	addi	s0,sp,32
 7fe:	e40c                	sd	a1,8(s0)
 800:	e810                	sd	a2,16(s0)
 802:	ec14                	sd	a3,24(s0)
 804:	f018                	sd	a4,32(s0)
 806:	f41c                	sd	a5,40(s0)
 808:	03043823          	sd	a6,48(s0)
 80c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 810:	00840613          	addi	a2,s0,8
 814:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 818:	85aa                	mv	a1,a0
 81a:	4505                	li	a0,1
 81c:	00000097          	auipc	ra,0x0
 820:	dce080e7          	jalr	-562(ra) # 5ea <vprintf>
}
 824:	60e2                	ld	ra,24(sp)
 826:	6442                	ld	s0,16(sp)
 828:	6125                	addi	sp,sp,96
 82a:	8082                	ret

000000000000082c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 82c:	1141                	addi	sp,sp,-16
 82e:	e422                	sd	s0,8(sp)
 830:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 832:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 836:	00000797          	auipc	a5,0x0
 83a:	1f27b783          	ld	a5,498(a5) # a28 <freep>
 83e:	a805                	j	86e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 840:	4618                	lw	a4,8(a2)
 842:	9db9                	addw	a1,a1,a4
 844:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 848:	6398                	ld	a4,0(a5)
 84a:	6318                	ld	a4,0(a4)
 84c:	fee53823          	sd	a4,-16(a0)
 850:	a091                	j	894 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 852:	ff852703          	lw	a4,-8(a0)
 856:	9e39                	addw	a2,a2,a4
 858:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 85a:	ff053703          	ld	a4,-16(a0)
 85e:	e398                	sd	a4,0(a5)
 860:	a099                	j	8a6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 862:	6398                	ld	a4,0(a5)
 864:	00e7e463          	bltu	a5,a4,86c <free+0x40>
 868:	00e6ea63          	bltu	a3,a4,87c <free+0x50>
{
 86c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 86e:	fed7fae3          	bgeu	a5,a3,862 <free+0x36>
 872:	6398                	ld	a4,0(a5)
 874:	00e6e463          	bltu	a3,a4,87c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 878:	fee7eae3          	bltu	a5,a4,86c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 87c:	ff852583          	lw	a1,-8(a0)
 880:	6390                	ld	a2,0(a5)
 882:	02059713          	slli	a4,a1,0x20
 886:	9301                	srli	a4,a4,0x20
 888:	0712                	slli	a4,a4,0x4
 88a:	9736                	add	a4,a4,a3
 88c:	fae60ae3          	beq	a2,a4,840 <free+0x14>
    bp->s.ptr = p->s.ptr;
 890:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 894:	4790                	lw	a2,8(a5)
 896:	02061713          	slli	a4,a2,0x20
 89a:	9301                	srli	a4,a4,0x20
 89c:	0712                	slli	a4,a4,0x4
 89e:	973e                	add	a4,a4,a5
 8a0:	fae689e3          	beq	a3,a4,852 <free+0x26>
  } else
    p->s.ptr = bp;
 8a4:	e394                	sd	a3,0(a5)
  freep = p;
 8a6:	00000717          	auipc	a4,0x0
 8aa:	18f73123          	sd	a5,386(a4) # a28 <freep>
}
 8ae:	6422                	ld	s0,8(sp)
 8b0:	0141                	addi	sp,sp,16
 8b2:	8082                	ret

00000000000008b4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8b4:	7139                	addi	sp,sp,-64
 8b6:	fc06                	sd	ra,56(sp)
 8b8:	f822                	sd	s0,48(sp)
 8ba:	f426                	sd	s1,40(sp)
 8bc:	f04a                	sd	s2,32(sp)
 8be:	ec4e                	sd	s3,24(sp)
 8c0:	e852                	sd	s4,16(sp)
 8c2:	e456                	sd	s5,8(sp)
 8c4:	e05a                	sd	s6,0(sp)
 8c6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8c8:	02051493          	slli	s1,a0,0x20
 8cc:	9081                	srli	s1,s1,0x20
 8ce:	04bd                	addi	s1,s1,15
 8d0:	8091                	srli	s1,s1,0x4
 8d2:	0014899b          	addiw	s3,s1,1
 8d6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8d8:	00000517          	auipc	a0,0x0
 8dc:	15053503          	ld	a0,336(a0) # a28 <freep>
 8e0:	c515                	beqz	a0,90c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8e2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8e4:	4798                	lw	a4,8(a5)
 8e6:	02977f63          	bgeu	a4,s1,924 <malloc+0x70>
 8ea:	8a4e                	mv	s4,s3
 8ec:	0009871b          	sext.w	a4,s3
 8f0:	6685                	lui	a3,0x1
 8f2:	00d77363          	bgeu	a4,a3,8f8 <malloc+0x44>
 8f6:	6a05                	lui	s4,0x1
 8f8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8fc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 900:	00000917          	auipc	s2,0x0
 904:	12890913          	addi	s2,s2,296 # a28 <freep>
  if(p == (char*)-1)
 908:	5afd                	li	s5,-1
 90a:	a88d                	j	97c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 90c:	00000797          	auipc	a5,0x0
 910:	12478793          	addi	a5,a5,292 # a30 <base>
 914:	00000717          	auipc	a4,0x0
 918:	10f73a23          	sd	a5,276(a4) # a28 <freep>
 91c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 91e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 922:	b7e1                	j	8ea <malloc+0x36>
      if(p->s.size == nunits)
 924:	02e48b63          	beq	s1,a4,95a <malloc+0xa6>
        p->s.size -= nunits;
 928:	4137073b          	subw	a4,a4,s3
 92c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 92e:	1702                	slli	a4,a4,0x20
 930:	9301                	srli	a4,a4,0x20
 932:	0712                	slli	a4,a4,0x4
 934:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 936:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 93a:	00000717          	auipc	a4,0x0
 93e:	0ea73723          	sd	a0,238(a4) # a28 <freep>
      return (void*)(p + 1);
 942:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 946:	70e2                	ld	ra,56(sp)
 948:	7442                	ld	s0,48(sp)
 94a:	74a2                	ld	s1,40(sp)
 94c:	7902                	ld	s2,32(sp)
 94e:	69e2                	ld	s3,24(sp)
 950:	6a42                	ld	s4,16(sp)
 952:	6aa2                	ld	s5,8(sp)
 954:	6b02                	ld	s6,0(sp)
 956:	6121                	addi	sp,sp,64
 958:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 95a:	6398                	ld	a4,0(a5)
 95c:	e118                	sd	a4,0(a0)
 95e:	bff1                	j	93a <malloc+0x86>
  hp->s.size = nu;
 960:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 964:	0541                	addi	a0,a0,16
 966:	00000097          	auipc	ra,0x0
 96a:	ec6080e7          	jalr	-314(ra) # 82c <free>
  return freep;
 96e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 972:	d971                	beqz	a0,946 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 974:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 976:	4798                	lw	a4,8(a5)
 978:	fa9776e3          	bgeu	a4,s1,924 <malloc+0x70>
    if(p == freep)
 97c:	00093703          	ld	a4,0(s2)
 980:	853e                	mv	a0,a5
 982:	fef719e3          	bne	a4,a5,974 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 986:	8552                	mv	a0,s4
 988:	00000097          	auipc	ra,0x0
 98c:	b66080e7          	jalr	-1178(ra) # 4ee <sbrk>
  if(p == (char*)-1)
 990:	fd5518e3          	bne	a0,s5,960 <malloc+0xac>
        return 0;
 994:	4501                	li	a0,0
 996:	bf45                	j	946 <malloc+0x92>
