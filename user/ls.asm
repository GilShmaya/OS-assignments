
user/_ls:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "kernel/fs.h"
#include "kernel/fcntl.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	3ba080e7          	jalr	954(ra) # 3ca <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	38e080e7          	jalr	910(ra) # 3ca <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	36c080e7          	jalr	876(ra) # 3ca <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	b7298993          	addi	s3,s3,-1166 # bd8 <buf.1114>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	4cc080e7          	jalr	1228(ra) # 542 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	34a080e7          	jalr	842(ra) # 3ca <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	33c080e7          	jalr	828(ra) # 3ca <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	34c080e7          	jalr	844(ra) # 3f4 <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <ls>:

void
ls(char *path)
{
  b4:	c8010113          	addi	sp,sp,-896
  b8:	36113c23          	sd	ra,888(sp)
  bc:	36813823          	sd	s0,880(sp)
  c0:	36913423          	sd	s1,872(sp)
  c4:	37213023          	sd	s2,864(sp)
  c8:	35313c23          	sd	s3,856(sp)
  cc:	35413823          	sd	s4,848(sp)
  d0:	35513423          	sd	s5,840(sp)
  d4:	0700                	addi	s0,sp,896
  d6:	892a                	mv	s2,a0
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  d8:	4581                	li	a1,0
  da:	00000097          	auipc	ra,0x0
  de:	55e080e7          	jalr	1374(ra) # 638 <open>
  e2:	06054063          	bltz	a0,142 <ls+0x8e>
  e6:	84aa                	mv	s1,a0
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  e8:	d9840593          	addi	a1,s0,-616
  ec:	00000097          	auipc	ra,0x0
  f0:	564080e7          	jalr	1380(ra) # 650 <fstat>
  f4:	06054263          	bltz	a0,158 <ls+0xa4>
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }
  struct stat st_target;
  switch(st.type){
  f8:	da041783          	lh	a5,-608(s0)
  fc:	0007869b          	sext.w	a3,a5
 100:	4709                	li	a4,2
 102:	0ce68063          	beq	a3,a4,1c2 <ls+0x10e>
 106:	8736                	mv	a4,a3
 108:	4691                	li	a3,4
 10a:	06d70763          	beq	a4,a3,178 <ls+0xc4>
 10e:	87ba                	mv	a5,a4
 110:	4705                	li	a4,1
 112:	0ce78d63          	beq	a5,a4,1ec <ls+0x138>
      }
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 116:	8526                	mv	a0,s1
 118:	00000097          	auipc	ra,0x0
 11c:	508080e7          	jalr	1288(ra) # 620 <close>
}
 120:	37813083          	ld	ra,888(sp)
 124:	37013403          	ld	s0,880(sp)
 128:	36813483          	ld	s1,872(sp)
 12c:	36013903          	ld	s2,864(sp)
 130:	35813983          	ld	s3,856(sp)
 134:	35013a03          	ld	s4,848(sp)
 138:	34813a83          	ld	s5,840(sp)
 13c:	38010113          	addi	sp,sp,896
 140:	8082                	ret
    fprintf(2, "ls: cannot open %s\n", path);
 142:	864a                	mv	a2,s2
 144:	00001597          	auipc	a1,0x1
 148:	9e458593          	addi	a1,a1,-1564 # b28 <malloc+0xea>
 14c:	4509                	li	a0,2
 14e:	00001097          	auipc	ra,0x1
 152:	804080e7          	jalr	-2044(ra) # 952 <fprintf>
    return;
 156:	b7e9                	j	120 <ls+0x6c>
    fprintf(2, "ls: cannot stat %s\n", path);
 158:	864a                	mv	a2,s2
 15a:	00001597          	auipc	a1,0x1
 15e:	9e658593          	addi	a1,a1,-1562 # b40 <malloc+0x102>
 162:	4509                	li	a0,2
 164:	00000097          	auipc	ra,0x0
 168:	7ee080e7          	jalr	2030(ra) # 952 <fprintf>
    close(fd);
 16c:	8526                	mv	a0,s1
 16e:	00000097          	auipc	ra,0x0
 172:	4b2080e7          	jalr	1202(ra) # 620 <close>
    return;
 176:	b76d                	j	120 <ls+0x6c>
    readlink(path, buf, 12);
 178:	4631                	li	a2,12
 17a:	dc040593          	addi	a1,s0,-576
 17e:	854a                	mv	a0,s2
 180:	00000097          	auipc	ra,0x0
 184:	4e8080e7          	jalr	1256(ra) # 668 <readlink>
    stat(buf, &st_target);
 188:	d8040593          	addi	a1,s0,-640
 18c:	dc040513          	addi	a0,s0,-576
 190:	00000097          	auipc	ra,0x0
 194:	322080e7          	jalr	802(ra) # 4b2 <stat>
    printf("%s -> %s %d %d 0\n", fmtname(path), buf, st_target.type,st.ino);
 198:	854a                	mv	a0,s2
 19a:	00000097          	auipc	ra,0x0
 19e:	e66080e7          	jalr	-410(ra) # 0 <fmtname>
 1a2:	85aa                	mv	a1,a0
 1a4:	d9c42703          	lw	a4,-612(s0)
 1a8:	d8841683          	lh	a3,-632(s0)
 1ac:	dc040613          	addi	a2,s0,-576
 1b0:	00001517          	auipc	a0,0x1
 1b4:	9a850513          	addi	a0,a0,-1624 # b58 <malloc+0x11a>
 1b8:	00000097          	auipc	ra,0x0
 1bc:	7c8080e7          	jalr	1992(ra) # 980 <printf>
    break;
 1c0:	bf99                	j	116 <ls+0x62>
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 1c2:	854a                	mv	a0,s2
 1c4:	00000097          	auipc	ra,0x0
 1c8:	e3c080e7          	jalr	-452(ra) # 0 <fmtname>
 1cc:	85aa                	mv	a1,a0
 1ce:	da843703          	ld	a4,-600(s0)
 1d2:	d9c42683          	lw	a3,-612(s0)
 1d6:	da041603          	lh	a2,-608(s0)
 1da:	00001517          	auipc	a0,0x1
 1de:	99650513          	addi	a0,a0,-1642 # b70 <malloc+0x132>
 1e2:	00000097          	auipc	ra,0x0
 1e6:	79e080e7          	jalr	1950(ra) # 980 <printf>
    break;
 1ea:	b735                	j	116 <ls+0x62>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 1ec:	854a                	mv	a0,s2
 1ee:	00000097          	auipc	ra,0x0
 1f2:	1dc080e7          	jalr	476(ra) # 3ca <strlen>
 1f6:	2541                	addiw	a0,a0,16
 1f8:	20000793          	li	a5,512
 1fc:	00a7fb63          	bgeu	a5,a0,212 <ls+0x15e>
      printf("ls: path too long\n");
 200:	00001517          	auipc	a0,0x1
 204:	98050513          	addi	a0,a0,-1664 # b80 <malloc+0x142>
 208:	00000097          	auipc	ra,0x0
 20c:	778080e7          	jalr	1912(ra) # 980 <printf>
      break;
 210:	b719                	j	116 <ls+0x62>
    strcpy(buf, path);
 212:	85ca                	mv	a1,s2
 214:	dc040513          	addi	a0,s0,-576
 218:	00000097          	auipc	ra,0x0
 21c:	16a080e7          	jalr	362(ra) # 382 <strcpy>
    p = buf+strlen(buf);
 220:	dc040513          	addi	a0,s0,-576
 224:	00000097          	auipc	ra,0x0
 228:	1a6080e7          	jalr	422(ra) # 3ca <strlen>
 22c:	02051913          	slli	s2,a0,0x20
 230:	02095913          	srli	s2,s2,0x20
 234:	dc040793          	addi	a5,s0,-576
 238:	993e                	add	s2,s2,a5
    *p++ = '/';
 23a:	00190993          	addi	s3,s2,1
 23e:	02f00793          	li	a5,47
 242:	00f90023          	sb	a5,0(s2)
      if (st.type == T_SYMLINK){
 246:	4a91                	li	s5,4
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 248:	00001a17          	auipc	s4,0x1
 24c:	950a0a13          	addi	s4,s4,-1712 # b98 <malloc+0x15a>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 250:	a835                	j	28c <ls+0x1d8>
        printf("ls: cannot stat %s\n", buf);
 252:	dc040593          	addi	a1,s0,-576
 256:	00001517          	auipc	a0,0x1
 25a:	8ea50513          	addi	a0,a0,-1814 # b40 <malloc+0x102>
 25e:	00000097          	auipc	ra,0x0
 262:	722080e7          	jalr	1826(ra) # 980 <printf>
        continue;
 266:	a01d                	j	28c <ls+0x1d8>
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 268:	dc040513          	addi	a0,s0,-576
 26c:	00000097          	auipc	ra,0x0
 270:	d94080e7          	jalr	-620(ra) # 0 <fmtname>
 274:	85aa                	mv	a1,a0
 276:	da843703          	ld	a4,-600(s0)
 27a:	d9c42683          	lw	a3,-612(s0)
 27e:	da041603          	lh	a2,-608(s0)
 282:	8552                	mv	a0,s4
 284:	00000097          	auipc	ra,0x0
 288:	6fc080e7          	jalr	1788(ra) # 980 <printf>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 28c:	4641                	li	a2,16
 28e:	db040593          	addi	a1,s0,-592
 292:	8526                	mv	a0,s1
 294:	00000097          	auipc	ra,0x0
 298:	37c080e7          	jalr	892(ra) # 610 <read>
 29c:	47c1                	li	a5,16
 29e:	e6f51ce3          	bne	a0,a5,116 <ls+0x62>
      if(de.inum == 0)
 2a2:	db045783          	lhu	a5,-592(s0)
 2a6:	d3fd                	beqz	a5,28c <ls+0x1d8>
      memmove(p, de.name, DIRSIZ);
 2a8:	4639                	li	a2,14
 2aa:	db240593          	addi	a1,s0,-590
 2ae:	854e                	mv	a0,s3
 2b0:	00000097          	auipc	ra,0x0
 2b4:	292080e7          	jalr	658(ra) # 542 <memmove>
      p[DIRSIZ] = 0;
 2b8:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 2bc:	d9840593          	addi	a1,s0,-616
 2c0:	dc040513          	addi	a0,s0,-576
 2c4:	00000097          	auipc	ra,0x0
 2c8:	1ee080e7          	jalr	494(ra) # 4b2 <stat>
 2cc:	f80543e3          	bltz	a0,252 <ls+0x19e>
      if (st.type == T_SYMLINK){
 2d0:	da041783          	lh	a5,-608(s0)
 2d4:	f9579ae3          	bne	a5,s5,268 <ls+0x1b4>
        readlink(buf, target, 256);
 2d8:	10000613          	li	a2,256
 2dc:	c8040593          	addi	a1,s0,-896
 2e0:	dc040513          	addi	a0,s0,-576
 2e4:	00000097          	auipc	ra,0x0
 2e8:	384080e7          	jalr	900(ra) # 668 <readlink>
        stat(target, &st_target);
 2ec:	d8040593          	addi	a1,s0,-640
 2f0:	c8040513          	addi	a0,s0,-896
 2f4:	00000097          	auipc	ra,0x0
 2f8:	1be080e7          	jalr	446(ra) # 4b2 <stat>
        printf("%s -> %s %d %d 0\n", fmtname(buf),target, st_target.type, st.ino);
 2fc:	dc040513          	addi	a0,s0,-576
 300:	00000097          	auipc	ra,0x0
 304:	d00080e7          	jalr	-768(ra) # 0 <fmtname>
 308:	85aa                	mv	a1,a0
 30a:	d9c42703          	lw	a4,-612(s0)
 30e:	d8841683          	lh	a3,-632(s0)
 312:	c8040613          	addi	a2,s0,-896
 316:	00001517          	auipc	a0,0x1
 31a:	84250513          	addi	a0,a0,-1982 # b58 <malloc+0x11a>
 31e:	00000097          	auipc	ra,0x0
 322:	662080e7          	jalr	1634(ra) # 980 <printf>
 326:	b789                	j	268 <ls+0x1b4>

0000000000000328 <main>:

int
main(int argc, char *argv[])
{
 328:	1101                	addi	sp,sp,-32
 32a:	ec06                	sd	ra,24(sp)
 32c:	e822                	sd	s0,16(sp)
 32e:	e426                	sd	s1,8(sp)
 330:	e04a                	sd	s2,0(sp)
 332:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
 334:	4785                	li	a5,1
 336:	02a7d963          	bge	a5,a0,368 <main+0x40>
 33a:	00858493          	addi	s1,a1,8
 33e:	ffe5091b          	addiw	s2,a0,-2
 342:	1902                	slli	s2,s2,0x20
 344:	02095913          	srli	s2,s2,0x20
 348:	090e                	slli	s2,s2,0x3
 34a:	05c1                	addi	a1,a1,16
 34c:	992e                	add	s2,s2,a1
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
 34e:	6088                	ld	a0,0(s1)
 350:	00000097          	auipc	ra,0x0
 354:	d64080e7          	jalr	-668(ra) # b4 <ls>
  for(i=1; i<argc; i++)
 358:	04a1                	addi	s1,s1,8
 35a:	ff249ae3          	bne	s1,s2,34e <main+0x26>
  exit(0);
 35e:	4501                	li	a0,0
 360:	00000097          	auipc	ra,0x0
 364:	298080e7          	jalr	664(ra) # 5f8 <exit>
    ls(".");
 368:	00001517          	auipc	a0,0x1
 36c:	84050513          	addi	a0,a0,-1984 # ba8 <malloc+0x16a>
 370:	00000097          	auipc	ra,0x0
 374:	d44080e7          	jalr	-700(ra) # b4 <ls>
    exit(0);
 378:	4501                	li	a0,0
 37a:	00000097          	auipc	ra,0x0
 37e:	27e080e7          	jalr	638(ra) # 5f8 <exit>

0000000000000382 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 382:	1141                	addi	sp,sp,-16
 384:	e422                	sd	s0,8(sp)
 386:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 388:	87aa                	mv	a5,a0
 38a:	0585                	addi	a1,a1,1
 38c:	0785                	addi	a5,a5,1
 38e:	fff5c703          	lbu	a4,-1(a1)
 392:	fee78fa3          	sb	a4,-1(a5)
 396:	fb75                	bnez	a4,38a <strcpy+0x8>
    ;
  return os;
}
 398:	6422                	ld	s0,8(sp)
 39a:	0141                	addi	sp,sp,16
 39c:	8082                	ret

000000000000039e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 39e:	1141                	addi	sp,sp,-16
 3a0:	e422                	sd	s0,8(sp)
 3a2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 3a4:	00054783          	lbu	a5,0(a0)
 3a8:	cb91                	beqz	a5,3bc <strcmp+0x1e>
 3aa:	0005c703          	lbu	a4,0(a1)
 3ae:	00f71763          	bne	a4,a5,3bc <strcmp+0x1e>
    p++, q++;
 3b2:	0505                	addi	a0,a0,1
 3b4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 3b6:	00054783          	lbu	a5,0(a0)
 3ba:	fbe5                	bnez	a5,3aa <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 3bc:	0005c503          	lbu	a0,0(a1)
}
 3c0:	40a7853b          	subw	a0,a5,a0
 3c4:	6422                	ld	s0,8(sp)
 3c6:	0141                	addi	sp,sp,16
 3c8:	8082                	ret

00000000000003ca <strlen>:

uint
strlen(const char *s)
{
 3ca:	1141                	addi	sp,sp,-16
 3cc:	e422                	sd	s0,8(sp)
 3ce:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 3d0:	00054783          	lbu	a5,0(a0)
 3d4:	cf91                	beqz	a5,3f0 <strlen+0x26>
 3d6:	0505                	addi	a0,a0,1
 3d8:	87aa                	mv	a5,a0
 3da:	4685                	li	a3,1
 3dc:	9e89                	subw	a3,a3,a0
 3de:	00f6853b          	addw	a0,a3,a5
 3e2:	0785                	addi	a5,a5,1
 3e4:	fff7c703          	lbu	a4,-1(a5)
 3e8:	fb7d                	bnez	a4,3de <strlen+0x14>
    ;
  return n;
}
 3ea:	6422                	ld	s0,8(sp)
 3ec:	0141                	addi	sp,sp,16
 3ee:	8082                	ret
  for(n = 0; s[n]; n++)
 3f0:	4501                	li	a0,0
 3f2:	bfe5                	j	3ea <strlen+0x20>

00000000000003f4 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3f4:	1141                	addi	sp,sp,-16
 3f6:	e422                	sd	s0,8(sp)
 3f8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3fa:	ce09                	beqz	a2,414 <memset+0x20>
 3fc:	87aa                	mv	a5,a0
 3fe:	fff6071b          	addiw	a4,a2,-1
 402:	1702                	slli	a4,a4,0x20
 404:	9301                	srli	a4,a4,0x20
 406:	0705                	addi	a4,a4,1
 408:	972a                	add	a4,a4,a0
    cdst[i] = c;
 40a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 40e:	0785                	addi	a5,a5,1
 410:	fee79de3          	bne	a5,a4,40a <memset+0x16>
  }
  return dst;
}
 414:	6422                	ld	s0,8(sp)
 416:	0141                	addi	sp,sp,16
 418:	8082                	ret

000000000000041a <strchr>:

char*
strchr(const char *s, char c)
{
 41a:	1141                	addi	sp,sp,-16
 41c:	e422                	sd	s0,8(sp)
 41e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 420:	00054783          	lbu	a5,0(a0)
 424:	cb99                	beqz	a5,43a <strchr+0x20>
    if(*s == c)
 426:	00f58763          	beq	a1,a5,434 <strchr+0x1a>
  for(; *s; s++)
 42a:	0505                	addi	a0,a0,1
 42c:	00054783          	lbu	a5,0(a0)
 430:	fbfd                	bnez	a5,426 <strchr+0xc>
      return (char*)s;
  return 0;
 432:	4501                	li	a0,0
}
 434:	6422                	ld	s0,8(sp)
 436:	0141                	addi	sp,sp,16
 438:	8082                	ret
  return 0;
 43a:	4501                	li	a0,0
 43c:	bfe5                	j	434 <strchr+0x1a>

000000000000043e <gets>:

char*
gets(char *buf, int max)
{
 43e:	711d                	addi	sp,sp,-96
 440:	ec86                	sd	ra,88(sp)
 442:	e8a2                	sd	s0,80(sp)
 444:	e4a6                	sd	s1,72(sp)
 446:	e0ca                	sd	s2,64(sp)
 448:	fc4e                	sd	s3,56(sp)
 44a:	f852                	sd	s4,48(sp)
 44c:	f456                	sd	s5,40(sp)
 44e:	f05a                	sd	s6,32(sp)
 450:	ec5e                	sd	s7,24(sp)
 452:	1080                	addi	s0,sp,96
 454:	8baa                	mv	s7,a0
 456:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 458:	892a                	mv	s2,a0
 45a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 45c:	4aa9                	li	s5,10
 45e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 460:	89a6                	mv	s3,s1
 462:	2485                	addiw	s1,s1,1
 464:	0344d863          	bge	s1,s4,494 <gets+0x56>
    cc = read(0, &c, 1);
 468:	4605                	li	a2,1
 46a:	faf40593          	addi	a1,s0,-81
 46e:	4501                	li	a0,0
 470:	00000097          	auipc	ra,0x0
 474:	1a0080e7          	jalr	416(ra) # 610 <read>
    if(cc < 1)
 478:	00a05e63          	blez	a0,494 <gets+0x56>
    buf[i++] = c;
 47c:	faf44783          	lbu	a5,-81(s0)
 480:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 484:	01578763          	beq	a5,s5,492 <gets+0x54>
 488:	0905                	addi	s2,s2,1
 48a:	fd679be3          	bne	a5,s6,460 <gets+0x22>
  for(i=0; i+1 < max; ){
 48e:	89a6                	mv	s3,s1
 490:	a011                	j	494 <gets+0x56>
 492:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 494:	99de                	add	s3,s3,s7
 496:	00098023          	sb	zero,0(s3)
  return buf;
}
 49a:	855e                	mv	a0,s7
 49c:	60e6                	ld	ra,88(sp)
 49e:	6446                	ld	s0,80(sp)
 4a0:	64a6                	ld	s1,72(sp)
 4a2:	6906                	ld	s2,64(sp)
 4a4:	79e2                	ld	s3,56(sp)
 4a6:	7a42                	ld	s4,48(sp)
 4a8:	7aa2                	ld	s5,40(sp)
 4aa:	7b02                	ld	s6,32(sp)
 4ac:	6be2                	ld	s7,24(sp)
 4ae:	6125                	addi	sp,sp,96
 4b0:	8082                	ret

00000000000004b2 <stat>:

int
stat(const char *n, struct stat *st)
{
 4b2:	1101                	addi	sp,sp,-32
 4b4:	ec06                	sd	ra,24(sp)
 4b6:	e822                	sd	s0,16(sp)
 4b8:	e426                	sd	s1,8(sp)
 4ba:	e04a                	sd	s2,0(sp)
 4bc:	1000                	addi	s0,sp,32
 4be:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 4c0:	4581                	li	a1,0
 4c2:	00000097          	auipc	ra,0x0
 4c6:	176080e7          	jalr	374(ra) # 638 <open>
  if(fd < 0)
 4ca:	02054563          	bltz	a0,4f4 <stat+0x42>
 4ce:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 4d0:	85ca                	mv	a1,s2
 4d2:	00000097          	auipc	ra,0x0
 4d6:	17e080e7          	jalr	382(ra) # 650 <fstat>
 4da:	892a                	mv	s2,a0
  close(fd);
 4dc:	8526                	mv	a0,s1
 4de:	00000097          	auipc	ra,0x0
 4e2:	142080e7          	jalr	322(ra) # 620 <close>
  return r;
}
 4e6:	854a                	mv	a0,s2
 4e8:	60e2                	ld	ra,24(sp)
 4ea:	6442                	ld	s0,16(sp)
 4ec:	64a2                	ld	s1,8(sp)
 4ee:	6902                	ld	s2,0(sp)
 4f0:	6105                	addi	sp,sp,32
 4f2:	8082                	ret
    return -1;
 4f4:	597d                	li	s2,-1
 4f6:	bfc5                	j	4e6 <stat+0x34>

00000000000004f8 <atoi>:

int
atoi(const char *s)
{
 4f8:	1141                	addi	sp,sp,-16
 4fa:	e422                	sd	s0,8(sp)
 4fc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4fe:	00054603          	lbu	a2,0(a0)
 502:	fd06079b          	addiw	a5,a2,-48
 506:	0ff7f793          	andi	a5,a5,255
 50a:	4725                	li	a4,9
 50c:	02f76963          	bltu	a4,a5,53e <atoi+0x46>
 510:	86aa                	mv	a3,a0
  n = 0;
 512:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 514:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 516:	0685                	addi	a3,a3,1
 518:	0025179b          	slliw	a5,a0,0x2
 51c:	9fa9                	addw	a5,a5,a0
 51e:	0017979b          	slliw	a5,a5,0x1
 522:	9fb1                	addw	a5,a5,a2
 524:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 528:	0006c603          	lbu	a2,0(a3)
 52c:	fd06071b          	addiw	a4,a2,-48
 530:	0ff77713          	andi	a4,a4,255
 534:	fee5f1e3          	bgeu	a1,a4,516 <atoi+0x1e>
  return n;
}
 538:	6422                	ld	s0,8(sp)
 53a:	0141                	addi	sp,sp,16
 53c:	8082                	ret
  n = 0;
 53e:	4501                	li	a0,0
 540:	bfe5                	j	538 <atoi+0x40>

0000000000000542 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 542:	1141                	addi	sp,sp,-16
 544:	e422                	sd	s0,8(sp)
 546:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 548:	02b57663          	bgeu	a0,a1,574 <memmove+0x32>
    while(n-- > 0)
 54c:	02c05163          	blez	a2,56e <memmove+0x2c>
 550:	fff6079b          	addiw	a5,a2,-1
 554:	1782                	slli	a5,a5,0x20
 556:	9381                	srli	a5,a5,0x20
 558:	0785                	addi	a5,a5,1
 55a:	97aa                	add	a5,a5,a0
  dst = vdst;
 55c:	872a                	mv	a4,a0
      *dst++ = *src++;
 55e:	0585                	addi	a1,a1,1
 560:	0705                	addi	a4,a4,1
 562:	fff5c683          	lbu	a3,-1(a1)
 566:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 56a:	fee79ae3          	bne	a5,a4,55e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 56e:	6422                	ld	s0,8(sp)
 570:	0141                	addi	sp,sp,16
 572:	8082                	ret
    dst += n;
 574:	00c50733          	add	a4,a0,a2
    src += n;
 578:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 57a:	fec05ae3          	blez	a2,56e <memmove+0x2c>
 57e:	fff6079b          	addiw	a5,a2,-1
 582:	1782                	slli	a5,a5,0x20
 584:	9381                	srli	a5,a5,0x20
 586:	fff7c793          	not	a5,a5
 58a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 58c:	15fd                	addi	a1,a1,-1
 58e:	177d                	addi	a4,a4,-1
 590:	0005c683          	lbu	a3,0(a1)
 594:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 598:	fee79ae3          	bne	a5,a4,58c <memmove+0x4a>
 59c:	bfc9                	j	56e <memmove+0x2c>

000000000000059e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 59e:	1141                	addi	sp,sp,-16
 5a0:	e422                	sd	s0,8(sp)
 5a2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 5a4:	ca05                	beqz	a2,5d4 <memcmp+0x36>
 5a6:	fff6069b          	addiw	a3,a2,-1
 5aa:	1682                	slli	a3,a3,0x20
 5ac:	9281                	srli	a3,a3,0x20
 5ae:	0685                	addi	a3,a3,1
 5b0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 5b2:	00054783          	lbu	a5,0(a0)
 5b6:	0005c703          	lbu	a4,0(a1)
 5ba:	00e79863          	bne	a5,a4,5ca <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 5be:	0505                	addi	a0,a0,1
    p2++;
 5c0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 5c2:	fed518e3          	bne	a0,a3,5b2 <memcmp+0x14>
  }
  return 0;
 5c6:	4501                	li	a0,0
 5c8:	a019                	j	5ce <memcmp+0x30>
      return *p1 - *p2;
 5ca:	40e7853b          	subw	a0,a5,a4
}
 5ce:	6422                	ld	s0,8(sp)
 5d0:	0141                	addi	sp,sp,16
 5d2:	8082                	ret
  return 0;
 5d4:	4501                	li	a0,0
 5d6:	bfe5                	j	5ce <memcmp+0x30>

00000000000005d8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 5d8:	1141                	addi	sp,sp,-16
 5da:	e406                	sd	ra,8(sp)
 5dc:	e022                	sd	s0,0(sp)
 5de:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5e0:	00000097          	auipc	ra,0x0
 5e4:	f62080e7          	jalr	-158(ra) # 542 <memmove>
}
 5e8:	60a2                	ld	ra,8(sp)
 5ea:	6402                	ld	s0,0(sp)
 5ec:	0141                	addi	sp,sp,16
 5ee:	8082                	ret

00000000000005f0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5f0:	4885                	li	a7,1
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5f8:	4889                	li	a7,2
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <wait>:
.global wait
wait:
 li a7, SYS_wait
 600:	488d                	li	a7,3
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 608:	4891                	li	a7,4
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <read>:
.global read
read:
 li a7, SYS_read
 610:	4895                	li	a7,5
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <write>:
.global write
write:
 li a7, SYS_write
 618:	48c1                	li	a7,16
 ecall
 61a:	00000073          	ecall
 ret
 61e:	8082                	ret

0000000000000620 <close>:
.global close
close:
 li a7, SYS_close
 620:	48d5                	li	a7,21
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <kill>:
.global kill
kill:
 li a7, SYS_kill
 628:	4899                	li	a7,6
 ecall
 62a:	00000073          	ecall
 ret
 62e:	8082                	ret

0000000000000630 <exec>:
.global exec
exec:
 li a7, SYS_exec
 630:	489d                	li	a7,7
 ecall
 632:	00000073          	ecall
 ret
 636:	8082                	ret

0000000000000638 <open>:
.global open
open:
 li a7, SYS_open
 638:	48bd                	li	a7,15
 ecall
 63a:	00000073          	ecall
 ret
 63e:	8082                	ret

0000000000000640 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 640:	48c5                	li	a7,17
 ecall
 642:	00000073          	ecall
 ret
 646:	8082                	ret

0000000000000648 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 648:	48c9                	li	a7,18
 ecall
 64a:	00000073          	ecall
 ret
 64e:	8082                	ret

0000000000000650 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 650:	48a1                	li	a7,8
 ecall
 652:	00000073          	ecall
 ret
 656:	8082                	ret

0000000000000658 <link>:
.global link
link:
 li a7, SYS_link
 658:	48cd                	li	a7,19
 ecall
 65a:	00000073          	ecall
 ret
 65e:	8082                	ret

0000000000000660 <symlink>:
.global symlink
symlink:
 li a7, SYS_symlink
 660:	48d9                	li	a7,22
 ecall
 662:	00000073          	ecall
 ret
 666:	8082                	ret

0000000000000668 <readlink>:
.global readlink
readlink:
 li a7, SYS_readlink
 668:	48dd                	li	a7,23
 ecall
 66a:	00000073          	ecall
 ret
 66e:	8082                	ret

0000000000000670 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 670:	48d1                	li	a7,20
 ecall
 672:	00000073          	ecall
 ret
 676:	8082                	ret

0000000000000678 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 678:	48a5                	li	a7,9
 ecall
 67a:	00000073          	ecall
 ret
 67e:	8082                	ret

0000000000000680 <dup>:
.global dup
dup:
 li a7, SYS_dup
 680:	48a9                	li	a7,10
 ecall
 682:	00000073          	ecall
 ret
 686:	8082                	ret

0000000000000688 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 688:	48ad                	li	a7,11
 ecall
 68a:	00000073          	ecall
 ret
 68e:	8082                	ret

0000000000000690 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 690:	48b1                	li	a7,12
 ecall
 692:	00000073          	ecall
 ret
 696:	8082                	ret

0000000000000698 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 698:	48b5                	li	a7,13
 ecall
 69a:	00000073          	ecall
 ret
 69e:	8082                	ret

00000000000006a0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 6a0:	48b9                	li	a7,14
 ecall
 6a2:	00000073          	ecall
 ret
 6a6:	8082                	ret

00000000000006a8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 6a8:	1101                	addi	sp,sp,-32
 6aa:	ec06                	sd	ra,24(sp)
 6ac:	e822                	sd	s0,16(sp)
 6ae:	1000                	addi	s0,sp,32
 6b0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 6b4:	4605                	li	a2,1
 6b6:	fef40593          	addi	a1,s0,-17
 6ba:	00000097          	auipc	ra,0x0
 6be:	f5e080e7          	jalr	-162(ra) # 618 <write>
}
 6c2:	60e2                	ld	ra,24(sp)
 6c4:	6442                	ld	s0,16(sp)
 6c6:	6105                	addi	sp,sp,32
 6c8:	8082                	ret

00000000000006ca <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 6ca:	7139                	addi	sp,sp,-64
 6cc:	fc06                	sd	ra,56(sp)
 6ce:	f822                	sd	s0,48(sp)
 6d0:	f426                	sd	s1,40(sp)
 6d2:	f04a                	sd	s2,32(sp)
 6d4:	ec4e                	sd	s3,24(sp)
 6d6:	0080                	addi	s0,sp,64
 6d8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 6da:	c299                	beqz	a3,6e0 <printint+0x16>
 6dc:	0805c863          	bltz	a1,76c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6e0:	2581                	sext.w	a1,a1
  neg = 0;
 6e2:	4881                	li	a7,0
 6e4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6e8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6ea:	2601                	sext.w	a2,a2
 6ec:	00000517          	auipc	a0,0x0
 6f0:	4cc50513          	addi	a0,a0,1228 # bb8 <digits>
 6f4:	883a                	mv	a6,a4
 6f6:	2705                	addiw	a4,a4,1
 6f8:	02c5f7bb          	remuw	a5,a1,a2
 6fc:	1782                	slli	a5,a5,0x20
 6fe:	9381                	srli	a5,a5,0x20
 700:	97aa                	add	a5,a5,a0
 702:	0007c783          	lbu	a5,0(a5)
 706:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 70a:	0005879b          	sext.w	a5,a1
 70e:	02c5d5bb          	divuw	a1,a1,a2
 712:	0685                	addi	a3,a3,1
 714:	fec7f0e3          	bgeu	a5,a2,6f4 <printint+0x2a>
  if(neg)
 718:	00088b63          	beqz	a7,72e <printint+0x64>
    buf[i++] = '-';
 71c:	fd040793          	addi	a5,s0,-48
 720:	973e                	add	a4,a4,a5
 722:	02d00793          	li	a5,45
 726:	fef70823          	sb	a5,-16(a4)
 72a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 72e:	02e05863          	blez	a4,75e <printint+0x94>
 732:	fc040793          	addi	a5,s0,-64
 736:	00e78933          	add	s2,a5,a4
 73a:	fff78993          	addi	s3,a5,-1
 73e:	99ba                	add	s3,s3,a4
 740:	377d                	addiw	a4,a4,-1
 742:	1702                	slli	a4,a4,0x20
 744:	9301                	srli	a4,a4,0x20
 746:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 74a:	fff94583          	lbu	a1,-1(s2)
 74e:	8526                	mv	a0,s1
 750:	00000097          	auipc	ra,0x0
 754:	f58080e7          	jalr	-168(ra) # 6a8 <putc>
  while(--i >= 0)
 758:	197d                	addi	s2,s2,-1
 75a:	ff3918e3          	bne	s2,s3,74a <printint+0x80>
}
 75e:	70e2                	ld	ra,56(sp)
 760:	7442                	ld	s0,48(sp)
 762:	74a2                	ld	s1,40(sp)
 764:	7902                	ld	s2,32(sp)
 766:	69e2                	ld	s3,24(sp)
 768:	6121                	addi	sp,sp,64
 76a:	8082                	ret
    x = -xx;
 76c:	40b005bb          	negw	a1,a1
    neg = 1;
 770:	4885                	li	a7,1
    x = -xx;
 772:	bf8d                	j	6e4 <printint+0x1a>

0000000000000774 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 774:	7119                	addi	sp,sp,-128
 776:	fc86                	sd	ra,120(sp)
 778:	f8a2                	sd	s0,112(sp)
 77a:	f4a6                	sd	s1,104(sp)
 77c:	f0ca                	sd	s2,96(sp)
 77e:	ecce                	sd	s3,88(sp)
 780:	e8d2                	sd	s4,80(sp)
 782:	e4d6                	sd	s5,72(sp)
 784:	e0da                	sd	s6,64(sp)
 786:	fc5e                	sd	s7,56(sp)
 788:	f862                	sd	s8,48(sp)
 78a:	f466                	sd	s9,40(sp)
 78c:	f06a                	sd	s10,32(sp)
 78e:	ec6e                	sd	s11,24(sp)
 790:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 792:	0005c903          	lbu	s2,0(a1)
 796:	18090f63          	beqz	s2,934 <vprintf+0x1c0>
 79a:	8aaa                	mv	s5,a0
 79c:	8b32                	mv	s6,a2
 79e:	00158493          	addi	s1,a1,1
  state = 0;
 7a2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 7a4:	02500a13          	li	s4,37
      if(c == 'd'){
 7a8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 7ac:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 7b0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 7b4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7b8:	00000b97          	auipc	s7,0x0
 7bc:	400b8b93          	addi	s7,s7,1024 # bb8 <digits>
 7c0:	a839                	j	7de <vprintf+0x6a>
        putc(fd, c);
 7c2:	85ca                	mv	a1,s2
 7c4:	8556                	mv	a0,s5
 7c6:	00000097          	auipc	ra,0x0
 7ca:	ee2080e7          	jalr	-286(ra) # 6a8 <putc>
 7ce:	a019                	j	7d4 <vprintf+0x60>
    } else if(state == '%'){
 7d0:	01498f63          	beq	s3,s4,7ee <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 7d4:	0485                	addi	s1,s1,1
 7d6:	fff4c903          	lbu	s2,-1(s1)
 7da:	14090d63          	beqz	s2,934 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 7de:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7e2:	fe0997e3          	bnez	s3,7d0 <vprintf+0x5c>
      if(c == '%'){
 7e6:	fd479ee3          	bne	a5,s4,7c2 <vprintf+0x4e>
        state = '%';
 7ea:	89be                	mv	s3,a5
 7ec:	b7e5                	j	7d4 <vprintf+0x60>
      if(c == 'd'){
 7ee:	05878063          	beq	a5,s8,82e <vprintf+0xba>
      } else if(c == 'l') {
 7f2:	05978c63          	beq	a5,s9,84a <vprintf+0xd6>
      } else if(c == 'x') {
 7f6:	07a78863          	beq	a5,s10,866 <vprintf+0xf2>
      } else if(c == 'p') {
 7fa:	09b78463          	beq	a5,s11,882 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 7fe:	07300713          	li	a4,115
 802:	0ce78663          	beq	a5,a4,8ce <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 806:	06300713          	li	a4,99
 80a:	0ee78e63          	beq	a5,a4,906 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 80e:	11478863          	beq	a5,s4,91e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 812:	85d2                	mv	a1,s4
 814:	8556                	mv	a0,s5
 816:	00000097          	auipc	ra,0x0
 81a:	e92080e7          	jalr	-366(ra) # 6a8 <putc>
        putc(fd, c);
 81e:	85ca                	mv	a1,s2
 820:	8556                	mv	a0,s5
 822:	00000097          	auipc	ra,0x0
 826:	e86080e7          	jalr	-378(ra) # 6a8 <putc>
      }
      state = 0;
 82a:	4981                	li	s3,0
 82c:	b765                	j	7d4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 82e:	008b0913          	addi	s2,s6,8
 832:	4685                	li	a3,1
 834:	4629                	li	a2,10
 836:	000b2583          	lw	a1,0(s6)
 83a:	8556                	mv	a0,s5
 83c:	00000097          	auipc	ra,0x0
 840:	e8e080e7          	jalr	-370(ra) # 6ca <printint>
 844:	8b4a                	mv	s6,s2
      state = 0;
 846:	4981                	li	s3,0
 848:	b771                	j	7d4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 84a:	008b0913          	addi	s2,s6,8
 84e:	4681                	li	a3,0
 850:	4629                	li	a2,10
 852:	000b2583          	lw	a1,0(s6)
 856:	8556                	mv	a0,s5
 858:	00000097          	auipc	ra,0x0
 85c:	e72080e7          	jalr	-398(ra) # 6ca <printint>
 860:	8b4a                	mv	s6,s2
      state = 0;
 862:	4981                	li	s3,0
 864:	bf85                	j	7d4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 866:	008b0913          	addi	s2,s6,8
 86a:	4681                	li	a3,0
 86c:	4641                	li	a2,16
 86e:	000b2583          	lw	a1,0(s6)
 872:	8556                	mv	a0,s5
 874:	00000097          	auipc	ra,0x0
 878:	e56080e7          	jalr	-426(ra) # 6ca <printint>
 87c:	8b4a                	mv	s6,s2
      state = 0;
 87e:	4981                	li	s3,0
 880:	bf91                	j	7d4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 882:	008b0793          	addi	a5,s6,8
 886:	f8f43423          	sd	a5,-120(s0)
 88a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 88e:	03000593          	li	a1,48
 892:	8556                	mv	a0,s5
 894:	00000097          	auipc	ra,0x0
 898:	e14080e7          	jalr	-492(ra) # 6a8 <putc>
  putc(fd, 'x');
 89c:	85ea                	mv	a1,s10
 89e:	8556                	mv	a0,s5
 8a0:	00000097          	auipc	ra,0x0
 8a4:	e08080e7          	jalr	-504(ra) # 6a8 <putc>
 8a8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 8aa:	03c9d793          	srli	a5,s3,0x3c
 8ae:	97de                	add	a5,a5,s7
 8b0:	0007c583          	lbu	a1,0(a5)
 8b4:	8556                	mv	a0,s5
 8b6:	00000097          	auipc	ra,0x0
 8ba:	df2080e7          	jalr	-526(ra) # 6a8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 8be:	0992                	slli	s3,s3,0x4
 8c0:	397d                	addiw	s2,s2,-1
 8c2:	fe0914e3          	bnez	s2,8aa <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 8c6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 8ca:	4981                	li	s3,0
 8cc:	b721                	j	7d4 <vprintf+0x60>
        s = va_arg(ap, char*);
 8ce:	008b0993          	addi	s3,s6,8
 8d2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 8d6:	02090163          	beqz	s2,8f8 <vprintf+0x184>
        while(*s != 0){
 8da:	00094583          	lbu	a1,0(s2)
 8de:	c9a1                	beqz	a1,92e <vprintf+0x1ba>
          putc(fd, *s);
 8e0:	8556                	mv	a0,s5
 8e2:	00000097          	auipc	ra,0x0
 8e6:	dc6080e7          	jalr	-570(ra) # 6a8 <putc>
          s++;
 8ea:	0905                	addi	s2,s2,1
        while(*s != 0){
 8ec:	00094583          	lbu	a1,0(s2)
 8f0:	f9e5                	bnez	a1,8e0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 8f2:	8b4e                	mv	s6,s3
      state = 0;
 8f4:	4981                	li	s3,0
 8f6:	bdf9                	j	7d4 <vprintf+0x60>
          s = "(null)";
 8f8:	00000917          	auipc	s2,0x0
 8fc:	2b890913          	addi	s2,s2,696 # bb0 <malloc+0x172>
        while(*s != 0){
 900:	02800593          	li	a1,40
 904:	bff1                	j	8e0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 906:	008b0913          	addi	s2,s6,8
 90a:	000b4583          	lbu	a1,0(s6)
 90e:	8556                	mv	a0,s5
 910:	00000097          	auipc	ra,0x0
 914:	d98080e7          	jalr	-616(ra) # 6a8 <putc>
 918:	8b4a                	mv	s6,s2
      state = 0;
 91a:	4981                	li	s3,0
 91c:	bd65                	j	7d4 <vprintf+0x60>
        putc(fd, c);
 91e:	85d2                	mv	a1,s4
 920:	8556                	mv	a0,s5
 922:	00000097          	auipc	ra,0x0
 926:	d86080e7          	jalr	-634(ra) # 6a8 <putc>
      state = 0;
 92a:	4981                	li	s3,0
 92c:	b565                	j	7d4 <vprintf+0x60>
        s = va_arg(ap, char*);
 92e:	8b4e                	mv	s6,s3
      state = 0;
 930:	4981                	li	s3,0
 932:	b54d                	j	7d4 <vprintf+0x60>
    }
  }
}
 934:	70e6                	ld	ra,120(sp)
 936:	7446                	ld	s0,112(sp)
 938:	74a6                	ld	s1,104(sp)
 93a:	7906                	ld	s2,96(sp)
 93c:	69e6                	ld	s3,88(sp)
 93e:	6a46                	ld	s4,80(sp)
 940:	6aa6                	ld	s5,72(sp)
 942:	6b06                	ld	s6,64(sp)
 944:	7be2                	ld	s7,56(sp)
 946:	7c42                	ld	s8,48(sp)
 948:	7ca2                	ld	s9,40(sp)
 94a:	7d02                	ld	s10,32(sp)
 94c:	6de2                	ld	s11,24(sp)
 94e:	6109                	addi	sp,sp,128
 950:	8082                	ret

0000000000000952 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 952:	715d                	addi	sp,sp,-80
 954:	ec06                	sd	ra,24(sp)
 956:	e822                	sd	s0,16(sp)
 958:	1000                	addi	s0,sp,32
 95a:	e010                	sd	a2,0(s0)
 95c:	e414                	sd	a3,8(s0)
 95e:	e818                	sd	a4,16(s0)
 960:	ec1c                	sd	a5,24(s0)
 962:	03043023          	sd	a6,32(s0)
 966:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 96a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 96e:	8622                	mv	a2,s0
 970:	00000097          	auipc	ra,0x0
 974:	e04080e7          	jalr	-508(ra) # 774 <vprintf>
}
 978:	60e2                	ld	ra,24(sp)
 97a:	6442                	ld	s0,16(sp)
 97c:	6161                	addi	sp,sp,80
 97e:	8082                	ret

0000000000000980 <printf>:

void
printf(const char *fmt, ...)
{
 980:	711d                	addi	sp,sp,-96
 982:	ec06                	sd	ra,24(sp)
 984:	e822                	sd	s0,16(sp)
 986:	1000                	addi	s0,sp,32
 988:	e40c                	sd	a1,8(s0)
 98a:	e810                	sd	a2,16(s0)
 98c:	ec14                	sd	a3,24(s0)
 98e:	f018                	sd	a4,32(s0)
 990:	f41c                	sd	a5,40(s0)
 992:	03043823          	sd	a6,48(s0)
 996:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 99a:	00840613          	addi	a2,s0,8
 99e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 9a2:	85aa                	mv	a1,a0
 9a4:	4505                	li	a0,1
 9a6:	00000097          	auipc	ra,0x0
 9aa:	dce080e7          	jalr	-562(ra) # 774 <vprintf>
}
 9ae:	60e2                	ld	ra,24(sp)
 9b0:	6442                	ld	s0,16(sp)
 9b2:	6125                	addi	sp,sp,96
 9b4:	8082                	ret

00000000000009b6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 9b6:	1141                	addi	sp,sp,-16
 9b8:	e422                	sd	s0,8(sp)
 9ba:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 9bc:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9c0:	00000797          	auipc	a5,0x0
 9c4:	2107b783          	ld	a5,528(a5) # bd0 <freep>
 9c8:	a805                	j	9f8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 9ca:	4618                	lw	a4,8(a2)
 9cc:	9db9                	addw	a1,a1,a4
 9ce:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 9d2:	6398                	ld	a4,0(a5)
 9d4:	6318                	ld	a4,0(a4)
 9d6:	fee53823          	sd	a4,-16(a0)
 9da:	a091                	j	a1e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 9dc:	ff852703          	lw	a4,-8(a0)
 9e0:	9e39                	addw	a2,a2,a4
 9e2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9e4:	ff053703          	ld	a4,-16(a0)
 9e8:	e398                	sd	a4,0(a5)
 9ea:	a099                	j	a30 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9ec:	6398                	ld	a4,0(a5)
 9ee:	00e7e463          	bltu	a5,a4,9f6 <free+0x40>
 9f2:	00e6ea63          	bltu	a3,a4,a06 <free+0x50>
{
 9f6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9f8:	fed7fae3          	bgeu	a5,a3,9ec <free+0x36>
 9fc:	6398                	ld	a4,0(a5)
 9fe:	00e6e463          	bltu	a3,a4,a06 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a02:	fee7eae3          	bltu	a5,a4,9f6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 a06:	ff852583          	lw	a1,-8(a0)
 a0a:	6390                	ld	a2,0(a5)
 a0c:	02059713          	slli	a4,a1,0x20
 a10:	9301                	srli	a4,a4,0x20
 a12:	0712                	slli	a4,a4,0x4
 a14:	9736                	add	a4,a4,a3
 a16:	fae60ae3          	beq	a2,a4,9ca <free+0x14>
    bp->s.ptr = p->s.ptr;
 a1a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 a1e:	4790                	lw	a2,8(a5)
 a20:	02061713          	slli	a4,a2,0x20
 a24:	9301                	srli	a4,a4,0x20
 a26:	0712                	slli	a4,a4,0x4
 a28:	973e                	add	a4,a4,a5
 a2a:	fae689e3          	beq	a3,a4,9dc <free+0x26>
  } else
    p->s.ptr = bp;
 a2e:	e394                	sd	a3,0(a5)
  freep = p;
 a30:	00000717          	auipc	a4,0x0
 a34:	1af73023          	sd	a5,416(a4) # bd0 <freep>
}
 a38:	6422                	ld	s0,8(sp)
 a3a:	0141                	addi	sp,sp,16
 a3c:	8082                	ret

0000000000000a3e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a3e:	7139                	addi	sp,sp,-64
 a40:	fc06                	sd	ra,56(sp)
 a42:	f822                	sd	s0,48(sp)
 a44:	f426                	sd	s1,40(sp)
 a46:	f04a                	sd	s2,32(sp)
 a48:	ec4e                	sd	s3,24(sp)
 a4a:	e852                	sd	s4,16(sp)
 a4c:	e456                	sd	s5,8(sp)
 a4e:	e05a                	sd	s6,0(sp)
 a50:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a52:	02051493          	slli	s1,a0,0x20
 a56:	9081                	srli	s1,s1,0x20
 a58:	04bd                	addi	s1,s1,15
 a5a:	8091                	srli	s1,s1,0x4
 a5c:	0014899b          	addiw	s3,s1,1
 a60:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a62:	00000517          	auipc	a0,0x0
 a66:	16e53503          	ld	a0,366(a0) # bd0 <freep>
 a6a:	c515                	beqz	a0,a96 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a6c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a6e:	4798                	lw	a4,8(a5)
 a70:	02977f63          	bgeu	a4,s1,aae <malloc+0x70>
 a74:	8a4e                	mv	s4,s3
 a76:	0009871b          	sext.w	a4,s3
 a7a:	6685                	lui	a3,0x1
 a7c:	00d77363          	bgeu	a4,a3,a82 <malloc+0x44>
 a80:	6a05                	lui	s4,0x1
 a82:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a86:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a8a:	00000917          	auipc	s2,0x0
 a8e:	14690913          	addi	s2,s2,326 # bd0 <freep>
  if(p == (char*)-1)
 a92:	5afd                	li	s5,-1
 a94:	a88d                	j	b06 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a96:	00000797          	auipc	a5,0x0
 a9a:	15278793          	addi	a5,a5,338 # be8 <base>
 a9e:	00000717          	auipc	a4,0x0
 aa2:	12f73923          	sd	a5,306(a4) # bd0 <freep>
 aa6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 aa8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 aac:	b7e1                	j	a74 <malloc+0x36>
      if(p->s.size == nunits)
 aae:	02e48b63          	beq	s1,a4,ae4 <malloc+0xa6>
        p->s.size -= nunits;
 ab2:	4137073b          	subw	a4,a4,s3
 ab6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 ab8:	1702                	slli	a4,a4,0x20
 aba:	9301                	srli	a4,a4,0x20
 abc:	0712                	slli	a4,a4,0x4
 abe:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 ac0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 ac4:	00000717          	auipc	a4,0x0
 ac8:	10a73623          	sd	a0,268(a4) # bd0 <freep>
      return (void*)(p + 1);
 acc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 ad0:	70e2                	ld	ra,56(sp)
 ad2:	7442                	ld	s0,48(sp)
 ad4:	74a2                	ld	s1,40(sp)
 ad6:	7902                	ld	s2,32(sp)
 ad8:	69e2                	ld	s3,24(sp)
 ada:	6a42                	ld	s4,16(sp)
 adc:	6aa2                	ld	s5,8(sp)
 ade:	6b02                	ld	s6,0(sp)
 ae0:	6121                	addi	sp,sp,64
 ae2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ae4:	6398                	ld	a4,0(a5)
 ae6:	e118                	sd	a4,0(a0)
 ae8:	bff1                	j	ac4 <malloc+0x86>
  hp->s.size = nu;
 aea:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 aee:	0541                	addi	a0,a0,16
 af0:	00000097          	auipc	ra,0x0
 af4:	ec6080e7          	jalr	-314(ra) # 9b6 <free>
  return freep;
 af8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 afc:	d971                	beqz	a0,ad0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 afe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b00:	4798                	lw	a4,8(a5)
 b02:	fa9776e3          	bgeu	a4,s1,aae <malloc+0x70>
    if(p == freep)
 b06:	00093703          	ld	a4,0(s2)
 b0a:	853e                	mv	a0,a5
 b0c:	fef719e3          	bne	a4,a5,afe <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 b10:	8552                	mv	a0,s4
 b12:	00000097          	auipc	ra,0x0
 b16:	b7e080e7          	jalr	-1154(ra) # 690 <sbrk>
  if(p == (char*)-1)
 b1a:	fd5518e3          	bne	a0,s5,aea <malloc+0xac>
        return 0;
 b1e:	4501                	li	a0,0
 b20:	bf45                	j	ad0 <malloc+0x92>
