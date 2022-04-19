
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
  3c:	958b8b93          	addi	s7,s7,-1704 # 990 <malloc+0xe4>
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
  68:	78a080e7          	jalr	1930(ra) # 7ee <printf>
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
  7e:	93650513          	addi	a0,a0,-1738 # 9b0 <malloc+0x104>
  82:	00000097          	auipc	ra,0x0
  86:	76c080e7          	jalr	1900(ra) # 7ee <printf>
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
  d8:	8e4b0b13          	addi	s6,s6,-1820 # 9b8 <malloc+0x10c>
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
 104:	6ee080e7          	jalr	1774(ra) # 7ee <printf>
 108:	bfd9                	j	de <kill_system_dem+0x3e>
            kill_system();
 10a:	00000097          	auipc	ra,0x0
 10e:	404080e7          	jalr	1028(ra) # 50e <kill_system>
 112:	bfc1                	j	e2 <kill_system_dem+0x42>
        }
    }
    printf("\n");
 114:	00001517          	auipc	a0,0x1
 118:	89c50513          	addi	a0,a0,-1892 # 9b0 <malloc+0x104>
 11c:	00000097          	auipc	ra,0x0
 120:	6d2080e7          	jalr	1746(ra) # 7ee <printf>
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
 162:	87aa8a93          	addi	s5,s5,-1926 # 9d8 <malloc+0x12c>
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
 18a:	668080e7          	jalr	1640(ra) # 7ee <printf>
 18e:	bfe9                	j	168 <set_economic_mode_dem+0x30>
        }
        if (i == loop_size / 2) {
            //set_economic_mode(0);
        }
    }
    printf("\n");
 190:	00001517          	auipc	a0,0x1
 194:	82050513          	addi	a0,a0,-2016 # 9b0 <malloc+0x104>
 198:	00000097          	auipc	ra,0x0
 19c:	656080e7          	jalr	1622(ra) # 7ee <printf>
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

0000000000000516 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 516:	1101                	addi	sp,sp,-32
 518:	ec06                	sd	ra,24(sp)
 51a:	e822                	sd	s0,16(sp)
 51c:	1000                	addi	s0,sp,32
 51e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 522:	4605                	li	a2,1
 524:	fef40593          	addi	a1,s0,-17
 528:	00000097          	auipc	ra,0x0
 52c:	f5e080e7          	jalr	-162(ra) # 486 <write>
}
 530:	60e2                	ld	ra,24(sp)
 532:	6442                	ld	s0,16(sp)
 534:	6105                	addi	sp,sp,32
 536:	8082                	ret

0000000000000538 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 538:	7139                	addi	sp,sp,-64
 53a:	fc06                	sd	ra,56(sp)
 53c:	f822                	sd	s0,48(sp)
 53e:	f426                	sd	s1,40(sp)
 540:	f04a                	sd	s2,32(sp)
 542:	ec4e                	sd	s3,24(sp)
 544:	0080                	addi	s0,sp,64
 546:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 548:	c299                	beqz	a3,54e <printint+0x16>
 54a:	0805c863          	bltz	a1,5da <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 54e:	2581                	sext.w	a1,a1
  neg = 0;
 550:	4881                	li	a7,0
 552:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 556:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 558:	2601                	sext.w	a2,a2
 55a:	00000517          	auipc	a0,0x0
 55e:	4ae50513          	addi	a0,a0,1198 # a08 <digits>
 562:	883a                	mv	a6,a4
 564:	2705                	addiw	a4,a4,1
 566:	02c5f7bb          	remuw	a5,a1,a2
 56a:	1782                	slli	a5,a5,0x20
 56c:	9381                	srli	a5,a5,0x20
 56e:	97aa                	add	a5,a5,a0
 570:	0007c783          	lbu	a5,0(a5)
 574:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 578:	0005879b          	sext.w	a5,a1
 57c:	02c5d5bb          	divuw	a1,a1,a2
 580:	0685                	addi	a3,a3,1
 582:	fec7f0e3          	bgeu	a5,a2,562 <printint+0x2a>
  if(neg)
 586:	00088b63          	beqz	a7,59c <printint+0x64>
    buf[i++] = '-';
 58a:	fd040793          	addi	a5,s0,-48
 58e:	973e                	add	a4,a4,a5
 590:	02d00793          	li	a5,45
 594:	fef70823          	sb	a5,-16(a4)
 598:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 59c:	02e05863          	blez	a4,5cc <printint+0x94>
 5a0:	fc040793          	addi	a5,s0,-64
 5a4:	00e78933          	add	s2,a5,a4
 5a8:	fff78993          	addi	s3,a5,-1
 5ac:	99ba                	add	s3,s3,a4
 5ae:	377d                	addiw	a4,a4,-1
 5b0:	1702                	slli	a4,a4,0x20
 5b2:	9301                	srli	a4,a4,0x20
 5b4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5b8:	fff94583          	lbu	a1,-1(s2)
 5bc:	8526                	mv	a0,s1
 5be:	00000097          	auipc	ra,0x0
 5c2:	f58080e7          	jalr	-168(ra) # 516 <putc>
  while(--i >= 0)
 5c6:	197d                	addi	s2,s2,-1
 5c8:	ff3918e3          	bne	s2,s3,5b8 <printint+0x80>
}
 5cc:	70e2                	ld	ra,56(sp)
 5ce:	7442                	ld	s0,48(sp)
 5d0:	74a2                	ld	s1,40(sp)
 5d2:	7902                	ld	s2,32(sp)
 5d4:	69e2                	ld	s3,24(sp)
 5d6:	6121                	addi	sp,sp,64
 5d8:	8082                	ret
    x = -xx;
 5da:	40b005bb          	negw	a1,a1
    neg = 1;
 5de:	4885                	li	a7,1
    x = -xx;
 5e0:	bf8d                	j	552 <printint+0x1a>

00000000000005e2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5e2:	7119                	addi	sp,sp,-128
 5e4:	fc86                	sd	ra,120(sp)
 5e6:	f8a2                	sd	s0,112(sp)
 5e8:	f4a6                	sd	s1,104(sp)
 5ea:	f0ca                	sd	s2,96(sp)
 5ec:	ecce                	sd	s3,88(sp)
 5ee:	e8d2                	sd	s4,80(sp)
 5f0:	e4d6                	sd	s5,72(sp)
 5f2:	e0da                	sd	s6,64(sp)
 5f4:	fc5e                	sd	s7,56(sp)
 5f6:	f862                	sd	s8,48(sp)
 5f8:	f466                	sd	s9,40(sp)
 5fa:	f06a                	sd	s10,32(sp)
 5fc:	ec6e                	sd	s11,24(sp)
 5fe:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 600:	0005c903          	lbu	s2,0(a1)
 604:	18090f63          	beqz	s2,7a2 <vprintf+0x1c0>
 608:	8aaa                	mv	s5,a0
 60a:	8b32                	mv	s6,a2
 60c:	00158493          	addi	s1,a1,1
  state = 0;
 610:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 612:	02500a13          	li	s4,37
      if(c == 'd'){
 616:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 61a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 61e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 622:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 626:	00000b97          	auipc	s7,0x0
 62a:	3e2b8b93          	addi	s7,s7,994 # a08 <digits>
 62e:	a839                	j	64c <vprintf+0x6a>
        putc(fd, c);
 630:	85ca                	mv	a1,s2
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	ee2080e7          	jalr	-286(ra) # 516 <putc>
 63c:	a019                	j	642 <vprintf+0x60>
    } else if(state == '%'){
 63e:	01498f63          	beq	s3,s4,65c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 642:	0485                	addi	s1,s1,1
 644:	fff4c903          	lbu	s2,-1(s1)
 648:	14090d63          	beqz	s2,7a2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 64c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 650:	fe0997e3          	bnez	s3,63e <vprintf+0x5c>
      if(c == '%'){
 654:	fd479ee3          	bne	a5,s4,630 <vprintf+0x4e>
        state = '%';
 658:	89be                	mv	s3,a5
 65a:	b7e5                	j	642 <vprintf+0x60>
      if(c == 'd'){
 65c:	05878063          	beq	a5,s8,69c <vprintf+0xba>
      } else if(c == 'l') {
 660:	05978c63          	beq	a5,s9,6b8 <vprintf+0xd6>
      } else if(c == 'x') {
 664:	07a78863          	beq	a5,s10,6d4 <vprintf+0xf2>
      } else if(c == 'p') {
 668:	09b78463          	beq	a5,s11,6f0 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 66c:	07300713          	li	a4,115
 670:	0ce78663          	beq	a5,a4,73c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 674:	06300713          	li	a4,99
 678:	0ee78e63          	beq	a5,a4,774 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 67c:	11478863          	beq	a5,s4,78c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 680:	85d2                	mv	a1,s4
 682:	8556                	mv	a0,s5
 684:	00000097          	auipc	ra,0x0
 688:	e92080e7          	jalr	-366(ra) # 516 <putc>
        putc(fd, c);
 68c:	85ca                	mv	a1,s2
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	e86080e7          	jalr	-378(ra) # 516 <putc>
      }
      state = 0;
 698:	4981                	li	s3,0
 69a:	b765                	j	642 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 69c:	008b0913          	addi	s2,s6,8
 6a0:	4685                	li	a3,1
 6a2:	4629                	li	a2,10
 6a4:	000b2583          	lw	a1,0(s6)
 6a8:	8556                	mv	a0,s5
 6aa:	00000097          	auipc	ra,0x0
 6ae:	e8e080e7          	jalr	-370(ra) # 538 <printint>
 6b2:	8b4a                	mv	s6,s2
      state = 0;
 6b4:	4981                	li	s3,0
 6b6:	b771                	j	642 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6b8:	008b0913          	addi	s2,s6,8
 6bc:	4681                	li	a3,0
 6be:	4629                	li	a2,10
 6c0:	000b2583          	lw	a1,0(s6)
 6c4:	8556                	mv	a0,s5
 6c6:	00000097          	auipc	ra,0x0
 6ca:	e72080e7          	jalr	-398(ra) # 538 <printint>
 6ce:	8b4a                	mv	s6,s2
      state = 0;
 6d0:	4981                	li	s3,0
 6d2:	bf85                	j	642 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6d4:	008b0913          	addi	s2,s6,8
 6d8:	4681                	li	a3,0
 6da:	4641                	li	a2,16
 6dc:	000b2583          	lw	a1,0(s6)
 6e0:	8556                	mv	a0,s5
 6e2:	00000097          	auipc	ra,0x0
 6e6:	e56080e7          	jalr	-426(ra) # 538 <printint>
 6ea:	8b4a                	mv	s6,s2
      state = 0;
 6ec:	4981                	li	s3,0
 6ee:	bf91                	j	642 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6f0:	008b0793          	addi	a5,s6,8
 6f4:	f8f43423          	sd	a5,-120(s0)
 6f8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6fc:	03000593          	li	a1,48
 700:	8556                	mv	a0,s5
 702:	00000097          	auipc	ra,0x0
 706:	e14080e7          	jalr	-492(ra) # 516 <putc>
  putc(fd, 'x');
 70a:	85ea                	mv	a1,s10
 70c:	8556                	mv	a0,s5
 70e:	00000097          	auipc	ra,0x0
 712:	e08080e7          	jalr	-504(ra) # 516 <putc>
 716:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 718:	03c9d793          	srli	a5,s3,0x3c
 71c:	97de                	add	a5,a5,s7
 71e:	0007c583          	lbu	a1,0(a5)
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	df2080e7          	jalr	-526(ra) # 516 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 72c:	0992                	slli	s3,s3,0x4
 72e:	397d                	addiw	s2,s2,-1
 730:	fe0914e3          	bnez	s2,718 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 734:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 738:	4981                	li	s3,0
 73a:	b721                	j	642 <vprintf+0x60>
        s = va_arg(ap, char*);
 73c:	008b0993          	addi	s3,s6,8
 740:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 744:	02090163          	beqz	s2,766 <vprintf+0x184>
        while(*s != 0){
 748:	00094583          	lbu	a1,0(s2)
 74c:	c9a1                	beqz	a1,79c <vprintf+0x1ba>
          putc(fd, *s);
 74e:	8556                	mv	a0,s5
 750:	00000097          	auipc	ra,0x0
 754:	dc6080e7          	jalr	-570(ra) # 516 <putc>
          s++;
 758:	0905                	addi	s2,s2,1
        while(*s != 0){
 75a:	00094583          	lbu	a1,0(s2)
 75e:	f9e5                	bnez	a1,74e <vprintf+0x16c>
        s = va_arg(ap, char*);
 760:	8b4e                	mv	s6,s3
      state = 0;
 762:	4981                	li	s3,0
 764:	bdf9                	j	642 <vprintf+0x60>
          s = "(null)";
 766:	00000917          	auipc	s2,0x0
 76a:	29a90913          	addi	s2,s2,666 # a00 <malloc+0x154>
        while(*s != 0){
 76e:	02800593          	li	a1,40
 772:	bff1                	j	74e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 774:	008b0913          	addi	s2,s6,8
 778:	000b4583          	lbu	a1,0(s6)
 77c:	8556                	mv	a0,s5
 77e:	00000097          	auipc	ra,0x0
 782:	d98080e7          	jalr	-616(ra) # 516 <putc>
 786:	8b4a                	mv	s6,s2
      state = 0;
 788:	4981                	li	s3,0
 78a:	bd65                	j	642 <vprintf+0x60>
        putc(fd, c);
 78c:	85d2                	mv	a1,s4
 78e:	8556                	mv	a0,s5
 790:	00000097          	auipc	ra,0x0
 794:	d86080e7          	jalr	-634(ra) # 516 <putc>
      state = 0;
 798:	4981                	li	s3,0
 79a:	b565                	j	642 <vprintf+0x60>
        s = va_arg(ap, char*);
 79c:	8b4e                	mv	s6,s3
      state = 0;
 79e:	4981                	li	s3,0
 7a0:	b54d                	j	642 <vprintf+0x60>
    }
  }
}
 7a2:	70e6                	ld	ra,120(sp)
 7a4:	7446                	ld	s0,112(sp)
 7a6:	74a6                	ld	s1,104(sp)
 7a8:	7906                	ld	s2,96(sp)
 7aa:	69e6                	ld	s3,88(sp)
 7ac:	6a46                	ld	s4,80(sp)
 7ae:	6aa6                	ld	s5,72(sp)
 7b0:	6b06                	ld	s6,64(sp)
 7b2:	7be2                	ld	s7,56(sp)
 7b4:	7c42                	ld	s8,48(sp)
 7b6:	7ca2                	ld	s9,40(sp)
 7b8:	7d02                	ld	s10,32(sp)
 7ba:	6de2                	ld	s11,24(sp)
 7bc:	6109                	addi	sp,sp,128
 7be:	8082                	ret

00000000000007c0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7c0:	715d                	addi	sp,sp,-80
 7c2:	ec06                	sd	ra,24(sp)
 7c4:	e822                	sd	s0,16(sp)
 7c6:	1000                	addi	s0,sp,32
 7c8:	e010                	sd	a2,0(s0)
 7ca:	e414                	sd	a3,8(s0)
 7cc:	e818                	sd	a4,16(s0)
 7ce:	ec1c                	sd	a5,24(s0)
 7d0:	03043023          	sd	a6,32(s0)
 7d4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7d8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7dc:	8622                	mv	a2,s0
 7de:	00000097          	auipc	ra,0x0
 7e2:	e04080e7          	jalr	-508(ra) # 5e2 <vprintf>
}
 7e6:	60e2                	ld	ra,24(sp)
 7e8:	6442                	ld	s0,16(sp)
 7ea:	6161                	addi	sp,sp,80
 7ec:	8082                	ret

00000000000007ee <printf>:

void
printf(const char *fmt, ...)
{
 7ee:	711d                	addi	sp,sp,-96
 7f0:	ec06                	sd	ra,24(sp)
 7f2:	e822                	sd	s0,16(sp)
 7f4:	1000                	addi	s0,sp,32
 7f6:	e40c                	sd	a1,8(s0)
 7f8:	e810                	sd	a2,16(s0)
 7fa:	ec14                	sd	a3,24(s0)
 7fc:	f018                	sd	a4,32(s0)
 7fe:	f41c                	sd	a5,40(s0)
 800:	03043823          	sd	a6,48(s0)
 804:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 808:	00840613          	addi	a2,s0,8
 80c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 810:	85aa                	mv	a1,a0
 812:	4505                	li	a0,1
 814:	00000097          	auipc	ra,0x0
 818:	dce080e7          	jalr	-562(ra) # 5e2 <vprintf>
}
 81c:	60e2                	ld	ra,24(sp)
 81e:	6442                	ld	s0,16(sp)
 820:	6125                	addi	sp,sp,96
 822:	8082                	ret

0000000000000824 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 824:	1141                	addi	sp,sp,-16
 826:	e422                	sd	s0,8(sp)
 828:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 82a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 82e:	00000797          	auipc	a5,0x0
 832:	1f27b783          	ld	a5,498(a5) # a20 <freep>
 836:	a805                	j	866 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 838:	4618                	lw	a4,8(a2)
 83a:	9db9                	addw	a1,a1,a4
 83c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 840:	6398                	ld	a4,0(a5)
 842:	6318                	ld	a4,0(a4)
 844:	fee53823          	sd	a4,-16(a0)
 848:	a091                	j	88c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 84a:	ff852703          	lw	a4,-8(a0)
 84e:	9e39                	addw	a2,a2,a4
 850:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 852:	ff053703          	ld	a4,-16(a0)
 856:	e398                	sd	a4,0(a5)
 858:	a099                	j	89e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 85a:	6398                	ld	a4,0(a5)
 85c:	00e7e463          	bltu	a5,a4,864 <free+0x40>
 860:	00e6ea63          	bltu	a3,a4,874 <free+0x50>
{
 864:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 866:	fed7fae3          	bgeu	a5,a3,85a <free+0x36>
 86a:	6398                	ld	a4,0(a5)
 86c:	00e6e463          	bltu	a3,a4,874 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 870:	fee7eae3          	bltu	a5,a4,864 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 874:	ff852583          	lw	a1,-8(a0)
 878:	6390                	ld	a2,0(a5)
 87a:	02059713          	slli	a4,a1,0x20
 87e:	9301                	srli	a4,a4,0x20
 880:	0712                	slli	a4,a4,0x4
 882:	9736                	add	a4,a4,a3
 884:	fae60ae3          	beq	a2,a4,838 <free+0x14>
    bp->s.ptr = p->s.ptr;
 888:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 88c:	4790                	lw	a2,8(a5)
 88e:	02061713          	slli	a4,a2,0x20
 892:	9301                	srli	a4,a4,0x20
 894:	0712                	slli	a4,a4,0x4
 896:	973e                	add	a4,a4,a5
 898:	fae689e3          	beq	a3,a4,84a <free+0x26>
  } else
    p->s.ptr = bp;
 89c:	e394                	sd	a3,0(a5)
  freep = p;
 89e:	00000717          	auipc	a4,0x0
 8a2:	18f73123          	sd	a5,386(a4) # a20 <freep>
}
 8a6:	6422                	ld	s0,8(sp)
 8a8:	0141                	addi	sp,sp,16
 8aa:	8082                	ret

00000000000008ac <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8ac:	7139                	addi	sp,sp,-64
 8ae:	fc06                	sd	ra,56(sp)
 8b0:	f822                	sd	s0,48(sp)
 8b2:	f426                	sd	s1,40(sp)
 8b4:	f04a                	sd	s2,32(sp)
 8b6:	ec4e                	sd	s3,24(sp)
 8b8:	e852                	sd	s4,16(sp)
 8ba:	e456                	sd	s5,8(sp)
 8bc:	e05a                	sd	s6,0(sp)
 8be:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8c0:	02051493          	slli	s1,a0,0x20
 8c4:	9081                	srli	s1,s1,0x20
 8c6:	04bd                	addi	s1,s1,15
 8c8:	8091                	srli	s1,s1,0x4
 8ca:	0014899b          	addiw	s3,s1,1
 8ce:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8d0:	00000517          	auipc	a0,0x0
 8d4:	15053503          	ld	a0,336(a0) # a20 <freep>
 8d8:	c515                	beqz	a0,904 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8da:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8dc:	4798                	lw	a4,8(a5)
 8de:	02977f63          	bgeu	a4,s1,91c <malloc+0x70>
 8e2:	8a4e                	mv	s4,s3
 8e4:	0009871b          	sext.w	a4,s3
 8e8:	6685                	lui	a3,0x1
 8ea:	00d77363          	bgeu	a4,a3,8f0 <malloc+0x44>
 8ee:	6a05                	lui	s4,0x1
 8f0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8f4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8f8:	00000917          	auipc	s2,0x0
 8fc:	12890913          	addi	s2,s2,296 # a20 <freep>
  if(p == (char*)-1)
 900:	5afd                	li	s5,-1
 902:	a88d                	j	974 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 904:	00000797          	auipc	a5,0x0
 908:	12478793          	addi	a5,a5,292 # a28 <base>
 90c:	00000717          	auipc	a4,0x0
 910:	10f73a23          	sd	a5,276(a4) # a20 <freep>
 914:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 916:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 91a:	b7e1                	j	8e2 <malloc+0x36>
      if(p->s.size == nunits)
 91c:	02e48b63          	beq	s1,a4,952 <malloc+0xa6>
        p->s.size -= nunits;
 920:	4137073b          	subw	a4,a4,s3
 924:	c798                	sw	a4,8(a5)
        p += p->s.size;
 926:	1702                	slli	a4,a4,0x20
 928:	9301                	srli	a4,a4,0x20
 92a:	0712                	slli	a4,a4,0x4
 92c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 92e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 932:	00000717          	auipc	a4,0x0
 936:	0ea73723          	sd	a0,238(a4) # a20 <freep>
      return (void*)(p + 1);
 93a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 93e:	70e2                	ld	ra,56(sp)
 940:	7442                	ld	s0,48(sp)
 942:	74a2                	ld	s1,40(sp)
 944:	7902                	ld	s2,32(sp)
 946:	69e2                	ld	s3,24(sp)
 948:	6a42                	ld	s4,16(sp)
 94a:	6aa2                	ld	s5,8(sp)
 94c:	6b02                	ld	s6,0(sp)
 94e:	6121                	addi	sp,sp,64
 950:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 952:	6398                	ld	a4,0(a5)
 954:	e118                	sd	a4,0(a0)
 956:	bff1                	j	932 <malloc+0x86>
  hp->s.size = nu;
 958:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 95c:	0541                	addi	a0,a0,16
 95e:	00000097          	auipc	ra,0x0
 962:	ec6080e7          	jalr	-314(ra) # 824 <free>
  return freep;
 966:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 96a:	d971                	beqz	a0,93e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 96c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 96e:	4798                	lw	a4,8(a5)
 970:	fa9776e3          	bgeu	a4,s1,91c <malloc+0x70>
    if(p == freep)
 974:	00093703          	ld	a4,0(s2)
 978:	853e                	mv	a0,a5
 97a:	fef719e3          	bne	a4,a5,96c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 97e:	8552                	mv	a0,s4
 980:	00000097          	auipc	ra,0x0
 984:	b6e080e7          	jalr	-1170(ra) # 4ee <sbrk>
  if(p == (char*)-1)
 988:	fd5518e3          	bne	a0,s5,958 <malloc+0xac>
        return 0;
 98c:	4501                	li	a0,0
 98e:	bf45                	j	93e <malloc+0x92>
