
user/_task2test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sanityCheckFirstPart>:
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void sanityCheckFirstPart(void)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  char *direct = malloc(1024 * 12);
  10:	650d                	lui	a0,0x3
  12:	00001097          	auipc	ra,0x1
  16:	84a080e7          	jalr	-1974(ra) # 85c <malloc>
  1a:	84aa                	mv	s1,a0
  char *single = malloc(268 * 1024);
  1c:	00043537          	lui	a0,0x43
  20:	00001097          	auipc	ra,0x1
  24:	83c080e7          	jalr	-1988(ra) # 85c <malloc>
  28:	89aa                	mv	s3,a0
  char *d_indirect = malloc(1024 * 1024);
  2a:	00100537          	lui	a0,0x100
  2e:	00001097          	auipc	ra,0x1
  32:	82e080e7          	jalr	-2002(ra) # 85c <malloc>
  36:	892a                	mv	s2,a0
  for (int i = 0; i < 1024 * 12; i++)
  38:	87a6                	mv	a5,s1
  3a:	670d                	lui	a4,0x3
  3c:	9726                	add	a4,a4,s1
  {
    direct[i] = 'a';
  3e:	06100693          	li	a3,97
  42:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < 1024 * 12; i++)
  46:	0785                	addi	a5,a5,1
  48:	fee79de3          	bne	a5,a4,42 <sanityCheckFirstPart+0x42>
  4c:	87ce                	mv	a5,s3
  4e:	00043737          	lui	a4,0x43
  52:	974e                	add	a4,a4,s3
  }
  for (int i = 0; i < 1024 * 268; i++)
  {
    single[i] = 'a';
  54:	06100693          	li	a3,97
  58:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < 1024 * 268; i++)
  5c:	0785                	addi	a5,a5,1
  5e:	fee79de3          	bne	a5,a4,58 <sanityCheckFirstPart+0x58>
  62:	87ca                	mv	a5,s2
  64:	00100737          	lui	a4,0x100
  68:	974a                	add	a4,a4,s2
  }
  for (int i = 0; i < 1024 * 1024; i++)
  {
    d_indirect[i] = 'a';
  6a:	06100693          	li	a3,97
  6e:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < 1024 * 1024; i++)
  72:	0785                	addi	a5,a5,1
  74:	fee79de3          	bne	a5,a4,6e <sanityCheckFirstPart+0x6e>
  }

  int fd = open("test", O_CREATE | O_RDWR);
  78:	20200593          	li	a1,514
  7c:	00001517          	auipc	a0,0x1
  80:	8c450513          	addi	a0,a0,-1852 # 940 <malloc+0xe4>
  84:	00000097          	auipc	ra,0x0
  88:	3d2080e7          	jalr	978(ra) # 456 <open>
  8c:	8a2a                	mv	s4,a0

  if (write(fd, direct, 1024 * 12) != 1024 * 12)
  8e:	660d                	lui	a2,0x3
  90:	85a6                	mv	a1,s1
  92:	00000097          	auipc	ra,0x0
  96:	3a4080e7          	jalr	932(ra) # 436 <write>
  9a:	678d                	lui	a5,0x3
  9c:	08f51e63          	bne	a0,a5,138 <sanityCheckFirstPart+0x138>
    printf("error: write to backup file failed\n");
    exit(0);
  }
  else
  {
    printf("Finished writing 12KB (direct)\n");
  a0:	00001517          	auipc	a0,0x1
  a4:	8d050513          	addi	a0,a0,-1840 # 970 <malloc+0x114>
  a8:	00000097          	auipc	ra,0x0
  ac:	6f6080e7          	jalr	1782(ra) # 79e <printf>
  }

  if (write(fd, single, 1024 * 268) != 1024 * 268)
  b0:	00043637          	lui	a2,0x43
  b4:	85ce                	mv	a1,s3
  b6:	8552                	mv	a0,s4
  b8:	00000097          	auipc	ra,0x0
  bc:	37e080e7          	jalr	894(ra) # 436 <write>
  c0:	000437b7          	lui	a5,0x43
  c4:	08f51763          	bne	a0,a5,152 <sanityCheckFirstPart+0x152>
    printf("error: write to backup file failed\n");
    exit(0);
  }
  else
  {
    printf("Finished writing 268KB (single indirect)\n");
  c8:	00001517          	auipc	a0,0x1
  cc:	8c850513          	addi	a0,a0,-1848 # 990 <malloc+0x134>
  d0:	00000097          	auipc	ra,0x0
  d4:	6ce080e7          	jalr	1742(ra) # 79e <printf>
  }

  if (write(fd, d_indirect, 1024 * 1024) != 1024 * 1024)
  d8:	00100637          	lui	a2,0x100
  dc:	85ca                	mv	a1,s2
  de:	8552                	mv	a0,s4
  e0:	00000097          	auipc	ra,0x0
  e4:	356080e7          	jalr	854(ra) # 436 <write>
  e8:	001007b7          	lui	a5,0x100
  ec:	08f51063          	bne	a0,a5,16c <sanityCheckFirstPart+0x16c>
    printf("error: write to backup file failed\n");
    exit(0);
  }
  else
  {
    printf("Finished writing 10MB (double indirect)\n");
  f0:	00001517          	auipc	a0,0x1
  f4:	8d050513          	addi	a0,a0,-1840 # 9c0 <malloc+0x164>
  f8:	00000097          	auipc	ra,0x0
  fc:	6a6080e7          	jalr	1702(ra) # 79e <printf>
  }

  close(fd);
 100:	8552                	mv	a0,s4
 102:	00000097          	auipc	ra,0x0
 106:	33c080e7          	jalr	828(ra) # 43e <close>

  free(direct);
 10a:	8526                	mv	a0,s1
 10c:	00000097          	auipc	ra,0x0
 110:	6c8080e7          	jalr	1736(ra) # 7d4 <free>
  free(single);
 114:	854e                	mv	a0,s3
 116:	00000097          	auipc	ra,0x0
 11a:	6be080e7          	jalr	1726(ra) # 7d4 <free>
  free(d_indirect);
 11e:	854a                	mv	a0,s2
 120:	00000097          	auipc	ra,0x0
 124:	6b4080e7          	jalr	1716(ra) # 7d4 <free>
} 
 128:	70a2                	ld	ra,40(sp)
 12a:	7402                	ld	s0,32(sp)
 12c:	64e2                	ld	s1,24(sp)
 12e:	6942                	ld	s2,16(sp)
 130:	69a2                	ld	s3,8(sp)
 132:	6a02                	ld	s4,0(sp)
 134:	6145                	addi	sp,sp,48
 136:	8082                	ret
    printf("error: write to backup file failed\n");
 138:	00001517          	auipc	a0,0x1
 13c:	81050513          	addi	a0,a0,-2032 # 948 <malloc+0xec>
 140:	00000097          	auipc	ra,0x0
 144:	65e080e7          	jalr	1630(ra) # 79e <printf>
    exit(0);
 148:	4501                	li	a0,0
 14a:	00000097          	auipc	ra,0x0
 14e:	2cc080e7          	jalr	716(ra) # 416 <exit>
    printf("error: write to backup file failed\n");
 152:	00000517          	auipc	a0,0x0
 156:	7f650513          	addi	a0,a0,2038 # 948 <malloc+0xec>
 15a:	00000097          	auipc	ra,0x0
 15e:	644080e7          	jalr	1604(ra) # 79e <printf>
    exit(0);
 162:	4501                	li	a0,0
 164:	00000097          	auipc	ra,0x0
 168:	2b2080e7          	jalr	690(ra) # 416 <exit>
    printf("error: write to backup file failed\n");
 16c:	00000517          	auipc	a0,0x0
 170:	7dc50513          	addi	a0,a0,2012 # 948 <malloc+0xec>
 174:	00000097          	auipc	ra,0x0
 178:	62a080e7          	jalr	1578(ra) # 79e <printf>
    exit(0);
 17c:	4501                	li	a0,0
 17e:	00000097          	auipc	ra,0x0
 182:	298080e7          	jalr	664(ra) # 416 <exit>

0000000000000186 <main>:
  
int
main(int argc, char *argv[]){
 186:	1141                	addi	sp,sp,-16
 188:	e406                	sd	ra,8(sp)
 18a:	e022                	sd	s0,0(sp)
 18c:	0800                	addi	s0,sp,16
  sanityCheckFirstPart();
 18e:	00000097          	auipc	ra,0x0
 192:	e72080e7          	jalr	-398(ra) # 0 <sanityCheckFirstPart>
  exit(0);
 196:	4501                	li	a0,0
 198:	00000097          	auipc	ra,0x0
 19c:	27e080e7          	jalr	638(ra) # 416 <exit>

00000000000001a0 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1a0:	1141                	addi	sp,sp,-16
 1a2:	e422                	sd	s0,8(sp)
 1a4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1a6:	87aa                	mv	a5,a0
 1a8:	0585                	addi	a1,a1,1
 1aa:	0785                	addi	a5,a5,1
 1ac:	fff5c703          	lbu	a4,-1(a1)
 1b0:	fee78fa3          	sb	a4,-1(a5) # fffff <__global_pointer$+0xfedf6>
 1b4:	fb75                	bnez	a4,1a8 <strcpy+0x8>
    ;
  return os;
}
 1b6:	6422                	ld	s0,8(sp)
 1b8:	0141                	addi	sp,sp,16
 1ba:	8082                	ret

00000000000001bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1bc:	1141                	addi	sp,sp,-16
 1be:	e422                	sd	s0,8(sp)
 1c0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1c2:	00054783          	lbu	a5,0(a0)
 1c6:	cb91                	beqz	a5,1da <strcmp+0x1e>
 1c8:	0005c703          	lbu	a4,0(a1)
 1cc:	00f71763          	bne	a4,a5,1da <strcmp+0x1e>
    p++, q++;
 1d0:	0505                	addi	a0,a0,1
 1d2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1d4:	00054783          	lbu	a5,0(a0)
 1d8:	fbe5                	bnez	a5,1c8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1da:	0005c503          	lbu	a0,0(a1)
}
 1de:	40a7853b          	subw	a0,a5,a0
 1e2:	6422                	ld	s0,8(sp)
 1e4:	0141                	addi	sp,sp,16
 1e6:	8082                	ret

00000000000001e8 <strlen>:

uint
strlen(const char *s)
{
 1e8:	1141                	addi	sp,sp,-16
 1ea:	e422                	sd	s0,8(sp)
 1ec:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1ee:	00054783          	lbu	a5,0(a0)
 1f2:	cf91                	beqz	a5,20e <strlen+0x26>
 1f4:	0505                	addi	a0,a0,1
 1f6:	87aa                	mv	a5,a0
 1f8:	4685                	li	a3,1
 1fa:	9e89                	subw	a3,a3,a0
 1fc:	00f6853b          	addw	a0,a3,a5
 200:	0785                	addi	a5,a5,1
 202:	fff7c703          	lbu	a4,-1(a5)
 206:	fb7d                	bnez	a4,1fc <strlen+0x14>
    ;
  return n;
}
 208:	6422                	ld	s0,8(sp)
 20a:	0141                	addi	sp,sp,16
 20c:	8082                	ret
  for(n = 0; s[n]; n++)
 20e:	4501                	li	a0,0
 210:	bfe5                	j	208 <strlen+0x20>

0000000000000212 <memset>:

void*
memset(void *dst, int c, uint n)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 218:	ce09                	beqz	a2,232 <memset+0x20>
 21a:	87aa                	mv	a5,a0
 21c:	fff6071b          	addiw	a4,a2,-1
 220:	1702                	slli	a4,a4,0x20
 222:	9301                	srli	a4,a4,0x20
 224:	0705                	addi	a4,a4,1
 226:	972a                	add	a4,a4,a0
    cdst[i] = c;
 228:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 22c:	0785                	addi	a5,a5,1
 22e:	fee79de3          	bne	a5,a4,228 <memset+0x16>
  }
  return dst;
}
 232:	6422                	ld	s0,8(sp)
 234:	0141                	addi	sp,sp,16
 236:	8082                	ret

0000000000000238 <strchr>:

char*
strchr(const char *s, char c)
{
 238:	1141                	addi	sp,sp,-16
 23a:	e422                	sd	s0,8(sp)
 23c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 23e:	00054783          	lbu	a5,0(a0)
 242:	cb99                	beqz	a5,258 <strchr+0x20>
    if(*s == c)
 244:	00f58763          	beq	a1,a5,252 <strchr+0x1a>
  for(; *s; s++)
 248:	0505                	addi	a0,a0,1
 24a:	00054783          	lbu	a5,0(a0)
 24e:	fbfd                	bnez	a5,244 <strchr+0xc>
      return (char*)s;
  return 0;
 250:	4501                	li	a0,0
}
 252:	6422                	ld	s0,8(sp)
 254:	0141                	addi	sp,sp,16
 256:	8082                	ret
  return 0;
 258:	4501                	li	a0,0
 25a:	bfe5                	j	252 <strchr+0x1a>

000000000000025c <gets>:

char*
gets(char *buf, int max)
{
 25c:	711d                	addi	sp,sp,-96
 25e:	ec86                	sd	ra,88(sp)
 260:	e8a2                	sd	s0,80(sp)
 262:	e4a6                	sd	s1,72(sp)
 264:	e0ca                	sd	s2,64(sp)
 266:	fc4e                	sd	s3,56(sp)
 268:	f852                	sd	s4,48(sp)
 26a:	f456                	sd	s5,40(sp)
 26c:	f05a                	sd	s6,32(sp)
 26e:	ec5e                	sd	s7,24(sp)
 270:	1080                	addi	s0,sp,96
 272:	8baa                	mv	s7,a0
 274:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 276:	892a                	mv	s2,a0
 278:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 27a:	4aa9                	li	s5,10
 27c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 27e:	89a6                	mv	s3,s1
 280:	2485                	addiw	s1,s1,1
 282:	0344d863          	bge	s1,s4,2b2 <gets+0x56>
    cc = read(0, &c, 1);
 286:	4605                	li	a2,1
 288:	faf40593          	addi	a1,s0,-81
 28c:	4501                	li	a0,0
 28e:	00000097          	auipc	ra,0x0
 292:	1a0080e7          	jalr	416(ra) # 42e <read>
    if(cc < 1)
 296:	00a05e63          	blez	a0,2b2 <gets+0x56>
    buf[i++] = c;
 29a:	faf44783          	lbu	a5,-81(s0)
 29e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2a2:	01578763          	beq	a5,s5,2b0 <gets+0x54>
 2a6:	0905                	addi	s2,s2,1
 2a8:	fd679be3          	bne	a5,s6,27e <gets+0x22>
  for(i=0; i+1 < max; ){
 2ac:	89a6                	mv	s3,s1
 2ae:	a011                	j	2b2 <gets+0x56>
 2b0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2b2:	99de                	add	s3,s3,s7
 2b4:	00098023          	sb	zero,0(s3)
  return buf;
}
 2b8:	855e                	mv	a0,s7
 2ba:	60e6                	ld	ra,88(sp)
 2bc:	6446                	ld	s0,80(sp)
 2be:	64a6                	ld	s1,72(sp)
 2c0:	6906                	ld	s2,64(sp)
 2c2:	79e2                	ld	s3,56(sp)
 2c4:	7a42                	ld	s4,48(sp)
 2c6:	7aa2                	ld	s5,40(sp)
 2c8:	7b02                	ld	s6,32(sp)
 2ca:	6be2                	ld	s7,24(sp)
 2cc:	6125                	addi	sp,sp,96
 2ce:	8082                	ret

00000000000002d0 <stat>:

int
stat(const char *n, struct stat *st)
{
 2d0:	1101                	addi	sp,sp,-32
 2d2:	ec06                	sd	ra,24(sp)
 2d4:	e822                	sd	s0,16(sp)
 2d6:	e426                	sd	s1,8(sp)
 2d8:	e04a                	sd	s2,0(sp)
 2da:	1000                	addi	s0,sp,32
 2dc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2de:	4581                	li	a1,0
 2e0:	00000097          	auipc	ra,0x0
 2e4:	176080e7          	jalr	374(ra) # 456 <open>
  if(fd < 0)
 2e8:	02054563          	bltz	a0,312 <stat+0x42>
 2ec:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2ee:	85ca                	mv	a1,s2
 2f0:	00000097          	auipc	ra,0x0
 2f4:	17e080e7          	jalr	382(ra) # 46e <fstat>
 2f8:	892a                	mv	s2,a0
  close(fd);
 2fa:	8526                	mv	a0,s1
 2fc:	00000097          	auipc	ra,0x0
 300:	142080e7          	jalr	322(ra) # 43e <close>
  return r;
}
 304:	854a                	mv	a0,s2
 306:	60e2                	ld	ra,24(sp)
 308:	6442                	ld	s0,16(sp)
 30a:	64a2                	ld	s1,8(sp)
 30c:	6902                	ld	s2,0(sp)
 30e:	6105                	addi	sp,sp,32
 310:	8082                	ret
    return -1;
 312:	597d                	li	s2,-1
 314:	bfc5                	j	304 <stat+0x34>

0000000000000316 <atoi>:

int
atoi(const char *s)
{
 316:	1141                	addi	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 31c:	00054603          	lbu	a2,0(a0)
 320:	fd06079b          	addiw	a5,a2,-48
 324:	0ff7f793          	andi	a5,a5,255
 328:	4725                	li	a4,9
 32a:	02f76963          	bltu	a4,a5,35c <atoi+0x46>
 32e:	86aa                	mv	a3,a0
  n = 0;
 330:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 332:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 334:	0685                	addi	a3,a3,1
 336:	0025179b          	slliw	a5,a0,0x2
 33a:	9fa9                	addw	a5,a5,a0
 33c:	0017979b          	slliw	a5,a5,0x1
 340:	9fb1                	addw	a5,a5,a2
 342:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 346:	0006c603          	lbu	a2,0(a3)
 34a:	fd06071b          	addiw	a4,a2,-48
 34e:	0ff77713          	andi	a4,a4,255
 352:	fee5f1e3          	bgeu	a1,a4,334 <atoi+0x1e>
  return n;
}
 356:	6422                	ld	s0,8(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret
  n = 0;
 35c:	4501                	li	a0,0
 35e:	bfe5                	j	356 <atoi+0x40>

0000000000000360 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 360:	1141                	addi	sp,sp,-16
 362:	e422                	sd	s0,8(sp)
 364:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 366:	02b57663          	bgeu	a0,a1,392 <memmove+0x32>
    while(n-- > 0)
 36a:	02c05163          	blez	a2,38c <memmove+0x2c>
 36e:	fff6079b          	addiw	a5,a2,-1
 372:	1782                	slli	a5,a5,0x20
 374:	9381                	srli	a5,a5,0x20
 376:	0785                	addi	a5,a5,1
 378:	97aa                	add	a5,a5,a0
  dst = vdst;
 37a:	872a                	mv	a4,a0
      *dst++ = *src++;
 37c:	0585                	addi	a1,a1,1
 37e:	0705                	addi	a4,a4,1
 380:	fff5c683          	lbu	a3,-1(a1)
 384:	fed70fa3          	sb	a3,-1(a4) # fffff <__global_pointer$+0xfedf6>
    while(n-- > 0)
 388:	fee79ae3          	bne	a5,a4,37c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 38c:	6422                	ld	s0,8(sp)
 38e:	0141                	addi	sp,sp,16
 390:	8082                	ret
    dst += n;
 392:	00c50733          	add	a4,a0,a2
    src += n;
 396:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 398:	fec05ae3          	blez	a2,38c <memmove+0x2c>
 39c:	fff6079b          	addiw	a5,a2,-1
 3a0:	1782                	slli	a5,a5,0x20
 3a2:	9381                	srli	a5,a5,0x20
 3a4:	fff7c793          	not	a5,a5
 3a8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3aa:	15fd                	addi	a1,a1,-1
 3ac:	177d                	addi	a4,a4,-1
 3ae:	0005c683          	lbu	a3,0(a1)
 3b2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3b6:	fee79ae3          	bne	a5,a4,3aa <memmove+0x4a>
 3ba:	bfc9                	j	38c <memmove+0x2c>

00000000000003bc <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3bc:	1141                	addi	sp,sp,-16
 3be:	e422                	sd	s0,8(sp)
 3c0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3c2:	ca05                	beqz	a2,3f2 <memcmp+0x36>
 3c4:	fff6069b          	addiw	a3,a2,-1
 3c8:	1682                	slli	a3,a3,0x20
 3ca:	9281                	srli	a3,a3,0x20
 3cc:	0685                	addi	a3,a3,1
 3ce:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3d0:	00054783          	lbu	a5,0(a0)
 3d4:	0005c703          	lbu	a4,0(a1)
 3d8:	00e79863          	bne	a5,a4,3e8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3dc:	0505                	addi	a0,a0,1
    p2++;
 3de:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3e0:	fed518e3          	bne	a0,a3,3d0 <memcmp+0x14>
  }
  return 0;
 3e4:	4501                	li	a0,0
 3e6:	a019                	j	3ec <memcmp+0x30>
      return *p1 - *p2;
 3e8:	40e7853b          	subw	a0,a5,a4
}
 3ec:	6422                	ld	s0,8(sp)
 3ee:	0141                	addi	sp,sp,16
 3f0:	8082                	ret
  return 0;
 3f2:	4501                	li	a0,0
 3f4:	bfe5                	j	3ec <memcmp+0x30>

00000000000003f6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3f6:	1141                	addi	sp,sp,-16
 3f8:	e406                	sd	ra,8(sp)
 3fa:	e022                	sd	s0,0(sp)
 3fc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3fe:	00000097          	auipc	ra,0x0
 402:	f62080e7          	jalr	-158(ra) # 360 <memmove>
}
 406:	60a2                	ld	ra,8(sp)
 408:	6402                	ld	s0,0(sp)
 40a:	0141                	addi	sp,sp,16
 40c:	8082                	ret

000000000000040e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 40e:	4885                	li	a7,1
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <exit>:
.global exit
exit:
 li a7, SYS_exit
 416:	4889                	li	a7,2
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <wait>:
.global wait
wait:
 li a7, SYS_wait
 41e:	488d                	li	a7,3
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 426:	4891                	li	a7,4
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <read>:
.global read
read:
 li a7, SYS_read
 42e:	4895                	li	a7,5
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <write>:
.global write
write:
 li a7, SYS_write
 436:	48c1                	li	a7,16
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <close>:
.global close
close:
 li a7, SYS_close
 43e:	48d5                	li	a7,21
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <kill>:
.global kill
kill:
 li a7, SYS_kill
 446:	4899                	li	a7,6
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <exec>:
.global exec
exec:
 li a7, SYS_exec
 44e:	489d                	li	a7,7
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <open>:
.global open
open:
 li a7, SYS_open
 456:	48bd                	li	a7,15
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 45e:	48c5                	li	a7,17
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 466:	48c9                	li	a7,18
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 46e:	48a1                	li	a7,8
 ecall
 470:	00000073          	ecall
 ret
 474:	8082                	ret

0000000000000476 <link>:
.global link
link:
 li a7, SYS_link
 476:	48cd                	li	a7,19
 ecall
 478:	00000073          	ecall
 ret
 47c:	8082                	ret

000000000000047e <symlink>:
.global symlink
symlink:
 li a7, SYS_symlink
 47e:	48d9                	li	a7,22
 ecall
 480:	00000073          	ecall
 ret
 484:	8082                	ret

0000000000000486 <readlink>:
.global readlink
readlink:
 li a7, SYS_readlink
 486:	48dd                	li	a7,23
 ecall
 488:	00000073          	ecall
 ret
 48c:	8082                	ret

000000000000048e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 48e:	48d1                	li	a7,20
 ecall
 490:	00000073          	ecall
 ret
 494:	8082                	ret

0000000000000496 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 496:	48a5                	li	a7,9
 ecall
 498:	00000073          	ecall
 ret
 49c:	8082                	ret

000000000000049e <dup>:
.global dup
dup:
 li a7, SYS_dup
 49e:	48a9                	li	a7,10
 ecall
 4a0:	00000073          	ecall
 ret
 4a4:	8082                	ret

00000000000004a6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4a6:	48ad                	li	a7,11
 ecall
 4a8:	00000073          	ecall
 ret
 4ac:	8082                	ret

00000000000004ae <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4ae:	48b1                	li	a7,12
 ecall
 4b0:	00000073          	ecall
 ret
 4b4:	8082                	ret

00000000000004b6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4b6:	48b5                	li	a7,13
 ecall
 4b8:	00000073          	ecall
 ret
 4bc:	8082                	ret

00000000000004be <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4be:	48b9                	li	a7,14
 ecall
 4c0:	00000073          	ecall
 ret
 4c4:	8082                	ret

00000000000004c6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4c6:	1101                	addi	sp,sp,-32
 4c8:	ec06                	sd	ra,24(sp)
 4ca:	e822                	sd	s0,16(sp)
 4cc:	1000                	addi	s0,sp,32
 4ce:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4d2:	4605                	li	a2,1
 4d4:	fef40593          	addi	a1,s0,-17
 4d8:	00000097          	auipc	ra,0x0
 4dc:	f5e080e7          	jalr	-162(ra) # 436 <write>
}
 4e0:	60e2                	ld	ra,24(sp)
 4e2:	6442                	ld	s0,16(sp)
 4e4:	6105                	addi	sp,sp,32
 4e6:	8082                	ret

00000000000004e8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4e8:	7139                	addi	sp,sp,-64
 4ea:	fc06                	sd	ra,56(sp)
 4ec:	f822                	sd	s0,48(sp)
 4ee:	f426                	sd	s1,40(sp)
 4f0:	f04a                	sd	s2,32(sp)
 4f2:	ec4e                	sd	s3,24(sp)
 4f4:	0080                	addi	s0,sp,64
 4f6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4f8:	c299                	beqz	a3,4fe <printint+0x16>
 4fa:	0805c863          	bltz	a1,58a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4fe:	2581                	sext.w	a1,a1
  neg = 0;
 500:	4881                	li	a7,0
 502:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 506:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 508:	2601                	sext.w	a2,a2
 50a:	00000517          	auipc	a0,0x0
 50e:	4ee50513          	addi	a0,a0,1262 # 9f8 <digits>
 512:	883a                	mv	a6,a4
 514:	2705                	addiw	a4,a4,1
 516:	02c5f7bb          	remuw	a5,a1,a2
 51a:	1782                	slli	a5,a5,0x20
 51c:	9381                	srli	a5,a5,0x20
 51e:	97aa                	add	a5,a5,a0
 520:	0007c783          	lbu	a5,0(a5)
 524:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 528:	0005879b          	sext.w	a5,a1
 52c:	02c5d5bb          	divuw	a1,a1,a2
 530:	0685                	addi	a3,a3,1
 532:	fec7f0e3          	bgeu	a5,a2,512 <printint+0x2a>
  if(neg)
 536:	00088b63          	beqz	a7,54c <printint+0x64>
    buf[i++] = '-';
 53a:	fd040793          	addi	a5,s0,-48
 53e:	973e                	add	a4,a4,a5
 540:	02d00793          	li	a5,45
 544:	fef70823          	sb	a5,-16(a4)
 548:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 54c:	02e05863          	blez	a4,57c <printint+0x94>
 550:	fc040793          	addi	a5,s0,-64
 554:	00e78933          	add	s2,a5,a4
 558:	fff78993          	addi	s3,a5,-1
 55c:	99ba                	add	s3,s3,a4
 55e:	377d                	addiw	a4,a4,-1
 560:	1702                	slli	a4,a4,0x20
 562:	9301                	srli	a4,a4,0x20
 564:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 568:	fff94583          	lbu	a1,-1(s2)
 56c:	8526                	mv	a0,s1
 56e:	00000097          	auipc	ra,0x0
 572:	f58080e7          	jalr	-168(ra) # 4c6 <putc>
  while(--i >= 0)
 576:	197d                	addi	s2,s2,-1
 578:	ff3918e3          	bne	s2,s3,568 <printint+0x80>
}
 57c:	70e2                	ld	ra,56(sp)
 57e:	7442                	ld	s0,48(sp)
 580:	74a2                	ld	s1,40(sp)
 582:	7902                	ld	s2,32(sp)
 584:	69e2                	ld	s3,24(sp)
 586:	6121                	addi	sp,sp,64
 588:	8082                	ret
    x = -xx;
 58a:	40b005bb          	negw	a1,a1
    neg = 1;
 58e:	4885                	li	a7,1
    x = -xx;
 590:	bf8d                	j	502 <printint+0x1a>

0000000000000592 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 592:	7119                	addi	sp,sp,-128
 594:	fc86                	sd	ra,120(sp)
 596:	f8a2                	sd	s0,112(sp)
 598:	f4a6                	sd	s1,104(sp)
 59a:	f0ca                	sd	s2,96(sp)
 59c:	ecce                	sd	s3,88(sp)
 59e:	e8d2                	sd	s4,80(sp)
 5a0:	e4d6                	sd	s5,72(sp)
 5a2:	e0da                	sd	s6,64(sp)
 5a4:	fc5e                	sd	s7,56(sp)
 5a6:	f862                	sd	s8,48(sp)
 5a8:	f466                	sd	s9,40(sp)
 5aa:	f06a                	sd	s10,32(sp)
 5ac:	ec6e                	sd	s11,24(sp)
 5ae:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5b0:	0005c903          	lbu	s2,0(a1)
 5b4:	18090f63          	beqz	s2,752 <vprintf+0x1c0>
 5b8:	8aaa                	mv	s5,a0
 5ba:	8b32                	mv	s6,a2
 5bc:	00158493          	addi	s1,a1,1
  state = 0;
 5c0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5c2:	02500a13          	li	s4,37
      if(c == 'd'){
 5c6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5ca:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5ce:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5d2:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5d6:	00000b97          	auipc	s7,0x0
 5da:	422b8b93          	addi	s7,s7,1058 # 9f8 <digits>
 5de:	a839                	j	5fc <vprintf+0x6a>
        putc(fd, c);
 5e0:	85ca                	mv	a1,s2
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	ee2080e7          	jalr	-286(ra) # 4c6 <putc>
 5ec:	a019                	j	5f2 <vprintf+0x60>
    } else if(state == '%'){
 5ee:	01498f63          	beq	s3,s4,60c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5f2:	0485                	addi	s1,s1,1
 5f4:	fff4c903          	lbu	s2,-1(s1)
 5f8:	14090d63          	beqz	s2,752 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5fc:	0009079b          	sext.w	a5,s2
    if(state == 0){
 600:	fe0997e3          	bnez	s3,5ee <vprintf+0x5c>
      if(c == '%'){
 604:	fd479ee3          	bne	a5,s4,5e0 <vprintf+0x4e>
        state = '%';
 608:	89be                	mv	s3,a5
 60a:	b7e5                	j	5f2 <vprintf+0x60>
      if(c == 'd'){
 60c:	05878063          	beq	a5,s8,64c <vprintf+0xba>
      } else if(c == 'l') {
 610:	05978c63          	beq	a5,s9,668 <vprintf+0xd6>
      } else if(c == 'x') {
 614:	07a78863          	beq	a5,s10,684 <vprintf+0xf2>
      } else if(c == 'p') {
 618:	09b78463          	beq	a5,s11,6a0 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 61c:	07300713          	li	a4,115
 620:	0ce78663          	beq	a5,a4,6ec <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 624:	06300713          	li	a4,99
 628:	0ee78e63          	beq	a5,a4,724 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 62c:	11478863          	beq	a5,s4,73c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 630:	85d2                	mv	a1,s4
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	e92080e7          	jalr	-366(ra) # 4c6 <putc>
        putc(fd, c);
 63c:	85ca                	mv	a1,s2
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	e86080e7          	jalr	-378(ra) # 4c6 <putc>
      }
      state = 0;
 648:	4981                	li	s3,0
 64a:	b765                	j	5f2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 64c:	008b0913          	addi	s2,s6,8
 650:	4685                	li	a3,1
 652:	4629                	li	a2,10
 654:	000b2583          	lw	a1,0(s6)
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	e8e080e7          	jalr	-370(ra) # 4e8 <printint>
 662:	8b4a                	mv	s6,s2
      state = 0;
 664:	4981                	li	s3,0
 666:	b771                	j	5f2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 668:	008b0913          	addi	s2,s6,8
 66c:	4681                	li	a3,0
 66e:	4629                	li	a2,10
 670:	000b2583          	lw	a1,0(s6)
 674:	8556                	mv	a0,s5
 676:	00000097          	auipc	ra,0x0
 67a:	e72080e7          	jalr	-398(ra) # 4e8 <printint>
 67e:	8b4a                	mv	s6,s2
      state = 0;
 680:	4981                	li	s3,0
 682:	bf85                	j	5f2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 684:	008b0913          	addi	s2,s6,8
 688:	4681                	li	a3,0
 68a:	4641                	li	a2,16
 68c:	000b2583          	lw	a1,0(s6)
 690:	8556                	mv	a0,s5
 692:	00000097          	auipc	ra,0x0
 696:	e56080e7          	jalr	-426(ra) # 4e8 <printint>
 69a:	8b4a                	mv	s6,s2
      state = 0;
 69c:	4981                	li	s3,0
 69e:	bf91                	j	5f2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6a0:	008b0793          	addi	a5,s6,8
 6a4:	f8f43423          	sd	a5,-120(s0)
 6a8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6ac:	03000593          	li	a1,48
 6b0:	8556                	mv	a0,s5
 6b2:	00000097          	auipc	ra,0x0
 6b6:	e14080e7          	jalr	-492(ra) # 4c6 <putc>
  putc(fd, 'x');
 6ba:	85ea                	mv	a1,s10
 6bc:	8556                	mv	a0,s5
 6be:	00000097          	auipc	ra,0x0
 6c2:	e08080e7          	jalr	-504(ra) # 4c6 <putc>
 6c6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6c8:	03c9d793          	srli	a5,s3,0x3c
 6cc:	97de                	add	a5,a5,s7
 6ce:	0007c583          	lbu	a1,0(a5)
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	df2080e7          	jalr	-526(ra) # 4c6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6dc:	0992                	slli	s3,s3,0x4
 6de:	397d                	addiw	s2,s2,-1
 6e0:	fe0914e3          	bnez	s2,6c8 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6e4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6e8:	4981                	li	s3,0
 6ea:	b721                	j	5f2 <vprintf+0x60>
        s = va_arg(ap, char*);
 6ec:	008b0993          	addi	s3,s6,8
 6f0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6f4:	02090163          	beqz	s2,716 <vprintf+0x184>
        while(*s != 0){
 6f8:	00094583          	lbu	a1,0(s2)
 6fc:	c9a1                	beqz	a1,74c <vprintf+0x1ba>
          putc(fd, *s);
 6fe:	8556                	mv	a0,s5
 700:	00000097          	auipc	ra,0x0
 704:	dc6080e7          	jalr	-570(ra) # 4c6 <putc>
          s++;
 708:	0905                	addi	s2,s2,1
        while(*s != 0){
 70a:	00094583          	lbu	a1,0(s2)
 70e:	f9e5                	bnez	a1,6fe <vprintf+0x16c>
        s = va_arg(ap, char*);
 710:	8b4e                	mv	s6,s3
      state = 0;
 712:	4981                	li	s3,0
 714:	bdf9                	j	5f2 <vprintf+0x60>
          s = "(null)";
 716:	00000917          	auipc	s2,0x0
 71a:	2da90913          	addi	s2,s2,730 # 9f0 <malloc+0x194>
        while(*s != 0){
 71e:	02800593          	li	a1,40
 722:	bff1                	j	6fe <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 724:	008b0913          	addi	s2,s6,8
 728:	000b4583          	lbu	a1,0(s6)
 72c:	8556                	mv	a0,s5
 72e:	00000097          	auipc	ra,0x0
 732:	d98080e7          	jalr	-616(ra) # 4c6 <putc>
 736:	8b4a                	mv	s6,s2
      state = 0;
 738:	4981                	li	s3,0
 73a:	bd65                	j	5f2 <vprintf+0x60>
        putc(fd, c);
 73c:	85d2                	mv	a1,s4
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	d86080e7          	jalr	-634(ra) # 4c6 <putc>
      state = 0;
 748:	4981                	li	s3,0
 74a:	b565                	j	5f2 <vprintf+0x60>
        s = va_arg(ap, char*);
 74c:	8b4e                	mv	s6,s3
      state = 0;
 74e:	4981                	li	s3,0
 750:	b54d                	j	5f2 <vprintf+0x60>
    }
  }
}
 752:	70e6                	ld	ra,120(sp)
 754:	7446                	ld	s0,112(sp)
 756:	74a6                	ld	s1,104(sp)
 758:	7906                	ld	s2,96(sp)
 75a:	69e6                	ld	s3,88(sp)
 75c:	6a46                	ld	s4,80(sp)
 75e:	6aa6                	ld	s5,72(sp)
 760:	6b06                	ld	s6,64(sp)
 762:	7be2                	ld	s7,56(sp)
 764:	7c42                	ld	s8,48(sp)
 766:	7ca2                	ld	s9,40(sp)
 768:	7d02                	ld	s10,32(sp)
 76a:	6de2                	ld	s11,24(sp)
 76c:	6109                	addi	sp,sp,128
 76e:	8082                	ret

0000000000000770 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 770:	715d                	addi	sp,sp,-80
 772:	ec06                	sd	ra,24(sp)
 774:	e822                	sd	s0,16(sp)
 776:	1000                	addi	s0,sp,32
 778:	e010                	sd	a2,0(s0)
 77a:	e414                	sd	a3,8(s0)
 77c:	e818                	sd	a4,16(s0)
 77e:	ec1c                	sd	a5,24(s0)
 780:	03043023          	sd	a6,32(s0)
 784:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 788:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 78c:	8622                	mv	a2,s0
 78e:	00000097          	auipc	ra,0x0
 792:	e04080e7          	jalr	-508(ra) # 592 <vprintf>
}
 796:	60e2                	ld	ra,24(sp)
 798:	6442                	ld	s0,16(sp)
 79a:	6161                	addi	sp,sp,80
 79c:	8082                	ret

000000000000079e <printf>:

void
printf(const char *fmt, ...)
{
 79e:	711d                	addi	sp,sp,-96
 7a0:	ec06                	sd	ra,24(sp)
 7a2:	e822                	sd	s0,16(sp)
 7a4:	1000                	addi	s0,sp,32
 7a6:	e40c                	sd	a1,8(s0)
 7a8:	e810                	sd	a2,16(s0)
 7aa:	ec14                	sd	a3,24(s0)
 7ac:	f018                	sd	a4,32(s0)
 7ae:	f41c                	sd	a5,40(s0)
 7b0:	03043823          	sd	a6,48(s0)
 7b4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7b8:	00840613          	addi	a2,s0,8
 7bc:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7c0:	85aa                	mv	a1,a0
 7c2:	4505                	li	a0,1
 7c4:	00000097          	auipc	ra,0x0
 7c8:	dce080e7          	jalr	-562(ra) # 592 <vprintf>
}
 7cc:	60e2                	ld	ra,24(sp)
 7ce:	6442                	ld	s0,16(sp)
 7d0:	6125                	addi	sp,sp,96
 7d2:	8082                	ret

00000000000007d4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7d4:	1141                	addi	sp,sp,-16
 7d6:	e422                	sd	s0,8(sp)
 7d8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7da:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7de:	00000797          	auipc	a5,0x0
 7e2:	2327b783          	ld	a5,562(a5) # a10 <freep>
 7e6:	a805                	j	816 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7e8:	4618                	lw	a4,8(a2)
 7ea:	9db9                	addw	a1,a1,a4
 7ec:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7f0:	6398                	ld	a4,0(a5)
 7f2:	6318                	ld	a4,0(a4)
 7f4:	fee53823          	sd	a4,-16(a0)
 7f8:	a091                	j	83c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7fa:	ff852703          	lw	a4,-8(a0)
 7fe:	9e39                	addw	a2,a2,a4
 800:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 802:	ff053703          	ld	a4,-16(a0)
 806:	e398                	sd	a4,0(a5)
 808:	a099                	j	84e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 80a:	6398                	ld	a4,0(a5)
 80c:	00e7e463          	bltu	a5,a4,814 <free+0x40>
 810:	00e6ea63          	bltu	a3,a4,824 <free+0x50>
{
 814:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 816:	fed7fae3          	bgeu	a5,a3,80a <free+0x36>
 81a:	6398                	ld	a4,0(a5)
 81c:	00e6e463          	bltu	a3,a4,824 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 820:	fee7eae3          	bltu	a5,a4,814 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 824:	ff852583          	lw	a1,-8(a0)
 828:	6390                	ld	a2,0(a5)
 82a:	02059713          	slli	a4,a1,0x20
 82e:	9301                	srli	a4,a4,0x20
 830:	0712                	slli	a4,a4,0x4
 832:	9736                	add	a4,a4,a3
 834:	fae60ae3          	beq	a2,a4,7e8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 838:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 83c:	4790                	lw	a2,8(a5)
 83e:	02061713          	slli	a4,a2,0x20
 842:	9301                	srli	a4,a4,0x20
 844:	0712                	slli	a4,a4,0x4
 846:	973e                	add	a4,a4,a5
 848:	fae689e3          	beq	a3,a4,7fa <free+0x26>
  } else
    p->s.ptr = bp;
 84c:	e394                	sd	a3,0(a5)
  freep = p;
 84e:	00000717          	auipc	a4,0x0
 852:	1cf73123          	sd	a5,450(a4) # a10 <freep>
}
 856:	6422                	ld	s0,8(sp)
 858:	0141                	addi	sp,sp,16
 85a:	8082                	ret

000000000000085c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 85c:	7139                	addi	sp,sp,-64
 85e:	fc06                	sd	ra,56(sp)
 860:	f822                	sd	s0,48(sp)
 862:	f426                	sd	s1,40(sp)
 864:	f04a                	sd	s2,32(sp)
 866:	ec4e                	sd	s3,24(sp)
 868:	e852                	sd	s4,16(sp)
 86a:	e456                	sd	s5,8(sp)
 86c:	e05a                	sd	s6,0(sp)
 86e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 870:	02051493          	slli	s1,a0,0x20
 874:	9081                	srli	s1,s1,0x20
 876:	04bd                	addi	s1,s1,15
 878:	8091                	srli	s1,s1,0x4
 87a:	0014899b          	addiw	s3,s1,1
 87e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 880:	00000517          	auipc	a0,0x0
 884:	19053503          	ld	a0,400(a0) # a10 <freep>
 888:	c515                	beqz	a0,8b4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 88a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 88c:	4798                	lw	a4,8(a5)
 88e:	02977f63          	bgeu	a4,s1,8cc <malloc+0x70>
 892:	8a4e                	mv	s4,s3
 894:	0009871b          	sext.w	a4,s3
 898:	6685                	lui	a3,0x1
 89a:	00d77363          	bgeu	a4,a3,8a0 <malloc+0x44>
 89e:	6a05                	lui	s4,0x1
 8a0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8a4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8a8:	00000917          	auipc	s2,0x0
 8ac:	16890913          	addi	s2,s2,360 # a10 <freep>
  if(p == (char*)-1)
 8b0:	5afd                	li	s5,-1
 8b2:	a88d                	j	924 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8b4:	00000797          	auipc	a5,0x0
 8b8:	16478793          	addi	a5,a5,356 # a18 <base>
 8bc:	00000717          	auipc	a4,0x0
 8c0:	14f73a23          	sd	a5,340(a4) # a10 <freep>
 8c4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8c6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8ca:	b7e1                	j	892 <malloc+0x36>
      if(p->s.size == nunits)
 8cc:	02e48b63          	beq	s1,a4,902 <malloc+0xa6>
        p->s.size -= nunits;
 8d0:	4137073b          	subw	a4,a4,s3
 8d4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8d6:	1702                	slli	a4,a4,0x20
 8d8:	9301                	srli	a4,a4,0x20
 8da:	0712                	slli	a4,a4,0x4
 8dc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8de:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8e2:	00000717          	auipc	a4,0x0
 8e6:	12a73723          	sd	a0,302(a4) # a10 <freep>
      return (void*)(p + 1);
 8ea:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8ee:	70e2                	ld	ra,56(sp)
 8f0:	7442                	ld	s0,48(sp)
 8f2:	74a2                	ld	s1,40(sp)
 8f4:	7902                	ld	s2,32(sp)
 8f6:	69e2                	ld	s3,24(sp)
 8f8:	6a42                	ld	s4,16(sp)
 8fa:	6aa2                	ld	s5,8(sp)
 8fc:	6b02                	ld	s6,0(sp)
 8fe:	6121                	addi	sp,sp,64
 900:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 902:	6398                	ld	a4,0(a5)
 904:	e118                	sd	a4,0(a0)
 906:	bff1                	j	8e2 <malloc+0x86>
  hp->s.size = nu;
 908:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 90c:	0541                	addi	a0,a0,16
 90e:	00000097          	auipc	ra,0x0
 912:	ec6080e7          	jalr	-314(ra) # 7d4 <free>
  return freep;
 916:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 91a:	d971                	beqz	a0,8ee <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 91c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 91e:	4798                	lw	a4,8(a5)
 920:	fa9776e3          	bgeu	a4,s1,8cc <malloc+0x70>
    if(p == freep)
 924:	00093703          	ld	a4,0(s2)
 928:	853e                	mv	a0,a5
 92a:	fef719e3          	bne	a4,a5,91c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 92e:	8552                	mv	a0,s4
 930:	00000097          	auipc	ra,0x0
 934:	b7e080e7          	jalr	-1154(ra) # 4ae <sbrk>
  if(p == (char*)-1)
 938:	fd5518e3          	bne	a0,s5,908 <malloc+0xac>
        return 0;
 93c:	4501                	li	a0,0
 93e:	bf45                	j	8ee <malloc+0x92>
