
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
  14:	3bc080e7          	jalr	956(ra) # 3cc <strlen>
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
  40:	390080e7          	jalr	912(ra) # 3cc <strlen>
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
  62:	36e080e7          	jalr	878(ra) # 3cc <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	b7298993          	addi	s3,s3,-1166 # bd8 <buf.1114>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	4ce080e7          	jalr	1230(ra) # 544 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	34c080e7          	jalr	844(ra) # 3cc <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	33e080e7          	jalr	830(ra) # 3cc <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	34e080e7          	jalr	846(ra) # 3f6 <memset>
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
  de:	560080e7          	jalr	1376(ra) # 63a <open>
  e2:	06054063          	bltz	a0,142 <ls+0x8e>
  e6:	84aa                	mv	s1,a0
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  e8:	d9840593          	addi	a1,s0,-616
  ec:	00000097          	auipc	ra,0x0
  f0:	566080e7          	jalr	1382(ra) # 652 <fstat>
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
 102:	0ce68163          	beq	a3,a4,1c4 <ls+0x110>
 106:	8736                	mv	a4,a3
 108:	4691                	li	a3,4
 10a:	06d70763          	beq	a4,a3,178 <ls+0xc4>
 10e:	87ba                	mv	a5,a4
 110:	4705                	li	a4,1
 112:	0ce78e63          	beq	a5,a4,1ee <ls+0x13a>
      }
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 116:	8526                	mv	a0,s1
 118:	00000097          	auipc	ra,0x0
 11c:	50a080e7          	jalr	1290(ra) # 622 <close>
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
 148:	9e458593          	addi	a1,a1,-1564 # b28 <malloc+0xe8>
 14c:	4509                	li	a0,2
 14e:	00001097          	auipc	ra,0x1
 152:	806080e7          	jalr	-2042(ra) # 954 <fprintf>
    return;
 156:	b7e9                	j	120 <ls+0x6c>
    fprintf(2, "ls: cannot stat %s\n", path);
 158:	864a                	mv	a2,s2
 15a:	00001597          	auipc	a1,0x1
 15e:	9e658593          	addi	a1,a1,-1562 # b40 <malloc+0x100>
 162:	4509                	li	a0,2
 164:	00000097          	auipc	ra,0x0
 168:	7f0080e7          	jalr	2032(ra) # 954 <fprintf>
    close(fd);
 16c:	8526                	mv	a0,s1
 16e:	00000097          	auipc	ra,0x0
 172:	4b4080e7          	jalr	1204(ra) # 622 <close>
    return;
 176:	b76d                	j	120 <ls+0x6c>
    readlink(path, buf, 512);
 178:	20000613          	li	a2,512
 17c:	dc040593          	addi	a1,s0,-576
 180:	854a                	mv	a0,s2
 182:	00000097          	auipc	ra,0x0
 186:	4e8080e7          	jalr	1256(ra) # 66a <readlink>
    stat(buf, &st_target);
 18a:	d8040593          	addi	a1,s0,-640
 18e:	dc040513          	addi	a0,s0,-576
 192:	00000097          	auipc	ra,0x0
 196:	322080e7          	jalr	802(ra) # 4b4 <stat>
    printf("%s -> %s %d %d 0\n", fmtname(path), buf, st.type,st.ino);
 19a:	854a                	mv	a0,s2
 19c:	00000097          	auipc	ra,0x0
 1a0:	e64080e7          	jalr	-412(ra) # 0 <fmtname>
 1a4:	85aa                	mv	a1,a0
 1a6:	d9c42703          	lw	a4,-612(s0)
 1aa:	da041683          	lh	a3,-608(s0)
 1ae:	dc040613          	addi	a2,s0,-576
 1b2:	00001517          	auipc	a0,0x1
 1b6:	9a650513          	addi	a0,a0,-1626 # b58 <malloc+0x118>
 1ba:	00000097          	auipc	ra,0x0
 1be:	7c8080e7          	jalr	1992(ra) # 982 <printf>
    break;
 1c2:	bf91                	j	116 <ls+0x62>
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 1c4:	854a                	mv	a0,s2
 1c6:	00000097          	auipc	ra,0x0
 1ca:	e3a080e7          	jalr	-454(ra) # 0 <fmtname>
 1ce:	85aa                	mv	a1,a0
 1d0:	da843703          	ld	a4,-600(s0)
 1d4:	d9c42683          	lw	a3,-612(s0)
 1d8:	da041603          	lh	a2,-608(s0)
 1dc:	00001517          	auipc	a0,0x1
 1e0:	99450513          	addi	a0,a0,-1644 # b70 <malloc+0x130>
 1e4:	00000097          	auipc	ra,0x0
 1e8:	79e080e7          	jalr	1950(ra) # 982 <printf>
    break;
 1ec:	b72d                	j	116 <ls+0x62>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 1ee:	854a                	mv	a0,s2
 1f0:	00000097          	auipc	ra,0x0
 1f4:	1dc080e7          	jalr	476(ra) # 3cc <strlen>
 1f8:	2541                	addiw	a0,a0,16
 1fa:	20000793          	li	a5,512
 1fe:	00a7fb63          	bgeu	a5,a0,214 <ls+0x160>
      printf("ls: path too long\n");
 202:	00001517          	auipc	a0,0x1
 206:	97e50513          	addi	a0,a0,-1666 # b80 <malloc+0x140>
 20a:	00000097          	auipc	ra,0x0
 20e:	778080e7          	jalr	1912(ra) # 982 <printf>
      break;
 212:	b711                	j	116 <ls+0x62>
    strcpy(buf, path);
 214:	85ca                	mv	a1,s2
 216:	dc040513          	addi	a0,s0,-576
 21a:	00000097          	auipc	ra,0x0
 21e:	16a080e7          	jalr	362(ra) # 384 <strcpy>
    p = buf+strlen(buf);
 222:	dc040513          	addi	a0,s0,-576
 226:	00000097          	auipc	ra,0x0
 22a:	1a6080e7          	jalr	422(ra) # 3cc <strlen>
 22e:	02051913          	slli	s2,a0,0x20
 232:	02095913          	srli	s2,s2,0x20
 236:	dc040793          	addi	a5,s0,-576
 23a:	993e                	add	s2,s2,a5
    *p++ = '/';
 23c:	00190993          	addi	s3,s2,1
 240:	02f00793          	li	a5,47
 244:	00f90023          	sb	a5,0(s2)
      if (st.type == T_SYMLINK){
 248:	4a91                	li	s5,4
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 24a:	00001a17          	auipc	s4,0x1
 24e:	94ea0a13          	addi	s4,s4,-1714 # b98 <malloc+0x158>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 252:	a835                	j	28e <ls+0x1da>
        printf("ls: cannot stat %s\n", buf);
 254:	dc040593          	addi	a1,s0,-576
 258:	00001517          	auipc	a0,0x1
 25c:	8e850513          	addi	a0,a0,-1816 # b40 <malloc+0x100>
 260:	00000097          	auipc	ra,0x0
 264:	722080e7          	jalr	1826(ra) # 982 <printf>
        continue;
 268:	a01d                	j	28e <ls+0x1da>
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 26a:	dc040513          	addi	a0,s0,-576
 26e:	00000097          	auipc	ra,0x0
 272:	d92080e7          	jalr	-622(ra) # 0 <fmtname>
 276:	85aa                	mv	a1,a0
 278:	da843703          	ld	a4,-600(s0)
 27c:	d9c42683          	lw	a3,-612(s0)
 280:	da041603          	lh	a2,-608(s0)
 284:	8552                	mv	a0,s4
 286:	00000097          	auipc	ra,0x0
 28a:	6fc080e7          	jalr	1788(ra) # 982 <printf>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 28e:	4641                	li	a2,16
 290:	db040593          	addi	a1,s0,-592
 294:	8526                	mv	a0,s1
 296:	00000097          	auipc	ra,0x0
 29a:	37c080e7          	jalr	892(ra) # 612 <read>
 29e:	47c1                	li	a5,16
 2a0:	e6f51be3          	bne	a0,a5,116 <ls+0x62>
      if(de.inum == 0)
 2a4:	db045783          	lhu	a5,-592(s0)
 2a8:	d3fd                	beqz	a5,28e <ls+0x1da>
      memmove(p, de.name, DIRSIZ);
 2aa:	4639                	li	a2,14
 2ac:	db240593          	addi	a1,s0,-590
 2b0:	854e                	mv	a0,s3
 2b2:	00000097          	auipc	ra,0x0
 2b6:	292080e7          	jalr	658(ra) # 544 <memmove>
      p[DIRSIZ] = 0;
 2ba:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 2be:	d9840593          	addi	a1,s0,-616
 2c2:	dc040513          	addi	a0,s0,-576
 2c6:	00000097          	auipc	ra,0x0
 2ca:	1ee080e7          	jalr	494(ra) # 4b4 <stat>
 2ce:	f80543e3          	bltz	a0,254 <ls+0x1a0>
      if (st.type == T_SYMLINK){
 2d2:	da041783          	lh	a5,-608(s0)
 2d6:	f9579ae3          	bne	a5,s5,26a <ls+0x1b6>
        readlink(buf, target, 256);
 2da:	10000613          	li	a2,256
 2de:	c8040593          	addi	a1,s0,-896
 2e2:	dc040513          	addi	a0,s0,-576
 2e6:	00000097          	auipc	ra,0x0
 2ea:	384080e7          	jalr	900(ra) # 66a <readlink>
        stat(target, &st_target);
 2ee:	d8040593          	addi	a1,s0,-640
 2f2:	c8040513          	addi	a0,s0,-896
 2f6:	00000097          	auipc	ra,0x0
 2fa:	1be080e7          	jalr	446(ra) # 4b4 <stat>
        printf("%s -> %s %d %d 0\n", fmtname(buf),target, st_target.type, st.ino);
 2fe:	dc040513          	addi	a0,s0,-576
 302:	00000097          	auipc	ra,0x0
 306:	cfe080e7          	jalr	-770(ra) # 0 <fmtname>
 30a:	85aa                	mv	a1,a0
 30c:	d9c42703          	lw	a4,-612(s0)
 310:	d8841683          	lh	a3,-632(s0)
 314:	c8040613          	addi	a2,s0,-896
 318:	00001517          	auipc	a0,0x1
 31c:	84050513          	addi	a0,a0,-1984 # b58 <malloc+0x118>
 320:	00000097          	auipc	ra,0x0
 324:	662080e7          	jalr	1634(ra) # 982 <printf>
 328:	b789                	j	26a <ls+0x1b6>

000000000000032a <main>:

int
main(int argc, char *argv[])
{
 32a:	1101                	addi	sp,sp,-32
 32c:	ec06                	sd	ra,24(sp)
 32e:	e822                	sd	s0,16(sp)
 330:	e426                	sd	s1,8(sp)
 332:	e04a                	sd	s2,0(sp)
 334:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
 336:	4785                	li	a5,1
 338:	02a7d963          	bge	a5,a0,36a <main+0x40>
 33c:	00858493          	addi	s1,a1,8
 340:	ffe5091b          	addiw	s2,a0,-2
 344:	1902                	slli	s2,s2,0x20
 346:	02095913          	srli	s2,s2,0x20
 34a:	090e                	slli	s2,s2,0x3
 34c:	05c1                	addi	a1,a1,16
 34e:	992e                	add	s2,s2,a1
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
 350:	6088                	ld	a0,0(s1)
 352:	00000097          	auipc	ra,0x0
 356:	d62080e7          	jalr	-670(ra) # b4 <ls>
  for(i=1; i<argc; i++)
 35a:	04a1                	addi	s1,s1,8
 35c:	ff249ae3          	bne	s1,s2,350 <main+0x26>
  exit(0);
 360:	4501                	li	a0,0
 362:	00000097          	auipc	ra,0x0
 366:	298080e7          	jalr	664(ra) # 5fa <exit>
    ls(".");
 36a:	00001517          	auipc	a0,0x1
 36e:	83e50513          	addi	a0,a0,-1986 # ba8 <malloc+0x168>
 372:	00000097          	auipc	ra,0x0
 376:	d42080e7          	jalr	-702(ra) # b4 <ls>
    exit(0);
 37a:	4501                	li	a0,0
 37c:	00000097          	auipc	ra,0x0
 380:	27e080e7          	jalr	638(ra) # 5fa <exit>

0000000000000384 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 384:	1141                	addi	sp,sp,-16
 386:	e422                	sd	s0,8(sp)
 388:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 38a:	87aa                	mv	a5,a0
 38c:	0585                	addi	a1,a1,1
 38e:	0785                	addi	a5,a5,1
 390:	fff5c703          	lbu	a4,-1(a1)
 394:	fee78fa3          	sb	a4,-1(a5)
 398:	fb75                	bnez	a4,38c <strcpy+0x8>
    ;
  return os;
}
 39a:	6422                	ld	s0,8(sp)
 39c:	0141                	addi	sp,sp,16
 39e:	8082                	ret

00000000000003a0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 3a0:	1141                	addi	sp,sp,-16
 3a2:	e422                	sd	s0,8(sp)
 3a4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 3a6:	00054783          	lbu	a5,0(a0)
 3aa:	cb91                	beqz	a5,3be <strcmp+0x1e>
 3ac:	0005c703          	lbu	a4,0(a1)
 3b0:	00f71763          	bne	a4,a5,3be <strcmp+0x1e>
    p++, q++;
 3b4:	0505                	addi	a0,a0,1
 3b6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 3b8:	00054783          	lbu	a5,0(a0)
 3bc:	fbe5                	bnez	a5,3ac <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 3be:	0005c503          	lbu	a0,0(a1)
}
 3c2:	40a7853b          	subw	a0,a5,a0
 3c6:	6422                	ld	s0,8(sp)
 3c8:	0141                	addi	sp,sp,16
 3ca:	8082                	ret

00000000000003cc <strlen>:

uint
strlen(const char *s)
{
 3cc:	1141                	addi	sp,sp,-16
 3ce:	e422                	sd	s0,8(sp)
 3d0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 3d2:	00054783          	lbu	a5,0(a0)
 3d6:	cf91                	beqz	a5,3f2 <strlen+0x26>
 3d8:	0505                	addi	a0,a0,1
 3da:	87aa                	mv	a5,a0
 3dc:	4685                	li	a3,1
 3de:	9e89                	subw	a3,a3,a0
 3e0:	00f6853b          	addw	a0,a3,a5
 3e4:	0785                	addi	a5,a5,1
 3e6:	fff7c703          	lbu	a4,-1(a5)
 3ea:	fb7d                	bnez	a4,3e0 <strlen+0x14>
    ;
  return n;
}
 3ec:	6422                	ld	s0,8(sp)
 3ee:	0141                	addi	sp,sp,16
 3f0:	8082                	ret
  for(n = 0; s[n]; n++)
 3f2:	4501                	li	a0,0
 3f4:	bfe5                	j	3ec <strlen+0x20>

00000000000003f6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3f6:	1141                	addi	sp,sp,-16
 3f8:	e422                	sd	s0,8(sp)
 3fa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3fc:	ce09                	beqz	a2,416 <memset+0x20>
 3fe:	87aa                	mv	a5,a0
 400:	fff6071b          	addiw	a4,a2,-1
 404:	1702                	slli	a4,a4,0x20
 406:	9301                	srli	a4,a4,0x20
 408:	0705                	addi	a4,a4,1
 40a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 40c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 410:	0785                	addi	a5,a5,1
 412:	fee79de3          	bne	a5,a4,40c <memset+0x16>
  }
  return dst;
}
 416:	6422                	ld	s0,8(sp)
 418:	0141                	addi	sp,sp,16
 41a:	8082                	ret

000000000000041c <strchr>:

char*
strchr(const char *s, char c)
{
 41c:	1141                	addi	sp,sp,-16
 41e:	e422                	sd	s0,8(sp)
 420:	0800                	addi	s0,sp,16
  for(; *s; s++)
 422:	00054783          	lbu	a5,0(a0)
 426:	cb99                	beqz	a5,43c <strchr+0x20>
    if(*s == c)
 428:	00f58763          	beq	a1,a5,436 <strchr+0x1a>
  for(; *s; s++)
 42c:	0505                	addi	a0,a0,1
 42e:	00054783          	lbu	a5,0(a0)
 432:	fbfd                	bnez	a5,428 <strchr+0xc>
      return (char*)s;
  return 0;
 434:	4501                	li	a0,0
}
 436:	6422                	ld	s0,8(sp)
 438:	0141                	addi	sp,sp,16
 43a:	8082                	ret
  return 0;
 43c:	4501                	li	a0,0
 43e:	bfe5                	j	436 <strchr+0x1a>

0000000000000440 <gets>:

char*
gets(char *buf, int max)
{
 440:	711d                	addi	sp,sp,-96
 442:	ec86                	sd	ra,88(sp)
 444:	e8a2                	sd	s0,80(sp)
 446:	e4a6                	sd	s1,72(sp)
 448:	e0ca                	sd	s2,64(sp)
 44a:	fc4e                	sd	s3,56(sp)
 44c:	f852                	sd	s4,48(sp)
 44e:	f456                	sd	s5,40(sp)
 450:	f05a                	sd	s6,32(sp)
 452:	ec5e                	sd	s7,24(sp)
 454:	1080                	addi	s0,sp,96
 456:	8baa                	mv	s7,a0
 458:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 45a:	892a                	mv	s2,a0
 45c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 45e:	4aa9                	li	s5,10
 460:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 462:	89a6                	mv	s3,s1
 464:	2485                	addiw	s1,s1,1
 466:	0344d863          	bge	s1,s4,496 <gets+0x56>
    cc = read(0, &c, 1);
 46a:	4605                	li	a2,1
 46c:	faf40593          	addi	a1,s0,-81
 470:	4501                	li	a0,0
 472:	00000097          	auipc	ra,0x0
 476:	1a0080e7          	jalr	416(ra) # 612 <read>
    if(cc < 1)
 47a:	00a05e63          	blez	a0,496 <gets+0x56>
    buf[i++] = c;
 47e:	faf44783          	lbu	a5,-81(s0)
 482:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 486:	01578763          	beq	a5,s5,494 <gets+0x54>
 48a:	0905                	addi	s2,s2,1
 48c:	fd679be3          	bne	a5,s6,462 <gets+0x22>
  for(i=0; i+1 < max; ){
 490:	89a6                	mv	s3,s1
 492:	a011                	j	496 <gets+0x56>
 494:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 496:	99de                	add	s3,s3,s7
 498:	00098023          	sb	zero,0(s3)
  return buf;
}
 49c:	855e                	mv	a0,s7
 49e:	60e6                	ld	ra,88(sp)
 4a0:	6446                	ld	s0,80(sp)
 4a2:	64a6                	ld	s1,72(sp)
 4a4:	6906                	ld	s2,64(sp)
 4a6:	79e2                	ld	s3,56(sp)
 4a8:	7a42                	ld	s4,48(sp)
 4aa:	7aa2                	ld	s5,40(sp)
 4ac:	7b02                	ld	s6,32(sp)
 4ae:	6be2                	ld	s7,24(sp)
 4b0:	6125                	addi	sp,sp,96
 4b2:	8082                	ret

00000000000004b4 <stat>:

int
stat(const char *n, struct stat *st)
{
 4b4:	1101                	addi	sp,sp,-32
 4b6:	ec06                	sd	ra,24(sp)
 4b8:	e822                	sd	s0,16(sp)
 4ba:	e426                	sd	s1,8(sp)
 4bc:	e04a                	sd	s2,0(sp)
 4be:	1000                	addi	s0,sp,32
 4c0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_NOFOLLOW);
 4c2:	4591                	li	a1,4
 4c4:	00000097          	auipc	ra,0x0
 4c8:	176080e7          	jalr	374(ra) # 63a <open>
  if(fd < 0)
 4cc:	02054563          	bltz	a0,4f6 <stat+0x42>
 4d0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 4d2:	85ca                	mv	a1,s2
 4d4:	00000097          	auipc	ra,0x0
 4d8:	17e080e7          	jalr	382(ra) # 652 <fstat>
 4dc:	892a                	mv	s2,a0
  close(fd);
 4de:	8526                	mv	a0,s1
 4e0:	00000097          	auipc	ra,0x0
 4e4:	142080e7          	jalr	322(ra) # 622 <close>
  return r;
}
 4e8:	854a                	mv	a0,s2
 4ea:	60e2                	ld	ra,24(sp)
 4ec:	6442                	ld	s0,16(sp)
 4ee:	64a2                	ld	s1,8(sp)
 4f0:	6902                	ld	s2,0(sp)
 4f2:	6105                	addi	sp,sp,32
 4f4:	8082                	ret
    return -1;
 4f6:	597d                	li	s2,-1
 4f8:	bfc5                	j	4e8 <stat+0x34>

00000000000004fa <atoi>:

int
atoi(const char *s)
{
 4fa:	1141                	addi	sp,sp,-16
 4fc:	e422                	sd	s0,8(sp)
 4fe:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 500:	00054603          	lbu	a2,0(a0)
 504:	fd06079b          	addiw	a5,a2,-48
 508:	0ff7f793          	andi	a5,a5,255
 50c:	4725                	li	a4,9
 50e:	02f76963          	bltu	a4,a5,540 <atoi+0x46>
 512:	86aa                	mv	a3,a0
  n = 0;
 514:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 516:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 518:	0685                	addi	a3,a3,1
 51a:	0025179b          	slliw	a5,a0,0x2
 51e:	9fa9                	addw	a5,a5,a0
 520:	0017979b          	slliw	a5,a5,0x1
 524:	9fb1                	addw	a5,a5,a2
 526:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 52a:	0006c603          	lbu	a2,0(a3)
 52e:	fd06071b          	addiw	a4,a2,-48
 532:	0ff77713          	andi	a4,a4,255
 536:	fee5f1e3          	bgeu	a1,a4,518 <atoi+0x1e>
  return n;
}
 53a:	6422                	ld	s0,8(sp)
 53c:	0141                	addi	sp,sp,16
 53e:	8082                	ret
  n = 0;
 540:	4501                	li	a0,0
 542:	bfe5                	j	53a <atoi+0x40>

0000000000000544 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 544:	1141                	addi	sp,sp,-16
 546:	e422                	sd	s0,8(sp)
 548:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 54a:	02b57663          	bgeu	a0,a1,576 <memmove+0x32>
    while(n-- > 0)
 54e:	02c05163          	blez	a2,570 <memmove+0x2c>
 552:	fff6079b          	addiw	a5,a2,-1
 556:	1782                	slli	a5,a5,0x20
 558:	9381                	srli	a5,a5,0x20
 55a:	0785                	addi	a5,a5,1
 55c:	97aa                	add	a5,a5,a0
  dst = vdst;
 55e:	872a                	mv	a4,a0
      *dst++ = *src++;
 560:	0585                	addi	a1,a1,1
 562:	0705                	addi	a4,a4,1
 564:	fff5c683          	lbu	a3,-1(a1)
 568:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 56c:	fee79ae3          	bne	a5,a4,560 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 570:	6422                	ld	s0,8(sp)
 572:	0141                	addi	sp,sp,16
 574:	8082                	ret
    dst += n;
 576:	00c50733          	add	a4,a0,a2
    src += n;
 57a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 57c:	fec05ae3          	blez	a2,570 <memmove+0x2c>
 580:	fff6079b          	addiw	a5,a2,-1
 584:	1782                	slli	a5,a5,0x20
 586:	9381                	srli	a5,a5,0x20
 588:	fff7c793          	not	a5,a5
 58c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 58e:	15fd                	addi	a1,a1,-1
 590:	177d                	addi	a4,a4,-1
 592:	0005c683          	lbu	a3,0(a1)
 596:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 59a:	fee79ae3          	bne	a5,a4,58e <memmove+0x4a>
 59e:	bfc9                	j	570 <memmove+0x2c>

00000000000005a0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 5a0:	1141                	addi	sp,sp,-16
 5a2:	e422                	sd	s0,8(sp)
 5a4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 5a6:	ca05                	beqz	a2,5d6 <memcmp+0x36>
 5a8:	fff6069b          	addiw	a3,a2,-1
 5ac:	1682                	slli	a3,a3,0x20
 5ae:	9281                	srli	a3,a3,0x20
 5b0:	0685                	addi	a3,a3,1
 5b2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 5b4:	00054783          	lbu	a5,0(a0)
 5b8:	0005c703          	lbu	a4,0(a1)
 5bc:	00e79863          	bne	a5,a4,5cc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 5c0:	0505                	addi	a0,a0,1
    p2++;
 5c2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 5c4:	fed518e3          	bne	a0,a3,5b4 <memcmp+0x14>
  }
  return 0;
 5c8:	4501                	li	a0,0
 5ca:	a019                	j	5d0 <memcmp+0x30>
      return *p1 - *p2;
 5cc:	40e7853b          	subw	a0,a5,a4
}
 5d0:	6422                	ld	s0,8(sp)
 5d2:	0141                	addi	sp,sp,16
 5d4:	8082                	ret
  return 0;
 5d6:	4501                	li	a0,0
 5d8:	bfe5                	j	5d0 <memcmp+0x30>

00000000000005da <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 5da:	1141                	addi	sp,sp,-16
 5dc:	e406                	sd	ra,8(sp)
 5de:	e022                	sd	s0,0(sp)
 5e0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5e2:	00000097          	auipc	ra,0x0
 5e6:	f62080e7          	jalr	-158(ra) # 544 <memmove>
}
 5ea:	60a2                	ld	ra,8(sp)
 5ec:	6402                	ld	s0,0(sp)
 5ee:	0141                	addi	sp,sp,16
 5f0:	8082                	ret

00000000000005f2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5f2:	4885                	li	a7,1
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <exit>:
.global exit
exit:
 li a7, SYS_exit
 5fa:	4889                	li	a7,2
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <wait>:
.global wait
wait:
 li a7, SYS_wait
 602:	488d                	li	a7,3
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 60a:	4891                	li	a7,4
 ecall
 60c:	00000073          	ecall
 ret
 610:	8082                	ret

0000000000000612 <read>:
.global read
read:
 li a7, SYS_read
 612:	4895                	li	a7,5
 ecall
 614:	00000073          	ecall
 ret
 618:	8082                	ret

000000000000061a <write>:
.global write
write:
 li a7, SYS_write
 61a:	48c1                	li	a7,16
 ecall
 61c:	00000073          	ecall
 ret
 620:	8082                	ret

0000000000000622 <close>:
.global close
close:
 li a7, SYS_close
 622:	48d5                	li	a7,21
 ecall
 624:	00000073          	ecall
 ret
 628:	8082                	ret

000000000000062a <kill>:
.global kill
kill:
 li a7, SYS_kill
 62a:	4899                	li	a7,6
 ecall
 62c:	00000073          	ecall
 ret
 630:	8082                	ret

0000000000000632 <exec>:
.global exec
exec:
 li a7, SYS_exec
 632:	489d                	li	a7,7
 ecall
 634:	00000073          	ecall
 ret
 638:	8082                	ret

000000000000063a <open>:
.global open
open:
 li a7, SYS_open
 63a:	48bd                	li	a7,15
 ecall
 63c:	00000073          	ecall
 ret
 640:	8082                	ret

0000000000000642 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 642:	48c5                	li	a7,17
 ecall
 644:	00000073          	ecall
 ret
 648:	8082                	ret

000000000000064a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 64a:	48c9                	li	a7,18
 ecall
 64c:	00000073          	ecall
 ret
 650:	8082                	ret

0000000000000652 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 652:	48a1                	li	a7,8
 ecall
 654:	00000073          	ecall
 ret
 658:	8082                	ret

000000000000065a <link>:
.global link
link:
 li a7, SYS_link
 65a:	48cd                	li	a7,19
 ecall
 65c:	00000073          	ecall
 ret
 660:	8082                	ret

0000000000000662 <symlink>:
.global symlink
symlink:
 li a7, SYS_symlink
 662:	48d9                	li	a7,22
 ecall
 664:	00000073          	ecall
 ret
 668:	8082                	ret

000000000000066a <readlink>:
.global readlink
readlink:
 li a7, SYS_readlink
 66a:	48dd                	li	a7,23
 ecall
 66c:	00000073          	ecall
 ret
 670:	8082                	ret

0000000000000672 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 672:	48d1                	li	a7,20
 ecall
 674:	00000073          	ecall
 ret
 678:	8082                	ret

000000000000067a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 67a:	48a5                	li	a7,9
 ecall
 67c:	00000073          	ecall
 ret
 680:	8082                	ret

0000000000000682 <dup>:
.global dup
dup:
 li a7, SYS_dup
 682:	48a9                	li	a7,10
 ecall
 684:	00000073          	ecall
 ret
 688:	8082                	ret

000000000000068a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 68a:	48ad                	li	a7,11
 ecall
 68c:	00000073          	ecall
 ret
 690:	8082                	ret

0000000000000692 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 692:	48b1                	li	a7,12
 ecall
 694:	00000073          	ecall
 ret
 698:	8082                	ret

000000000000069a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 69a:	48b5                	li	a7,13
 ecall
 69c:	00000073          	ecall
 ret
 6a0:	8082                	ret

00000000000006a2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 6a2:	48b9                	li	a7,14
 ecall
 6a4:	00000073          	ecall
 ret
 6a8:	8082                	ret

00000000000006aa <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 6aa:	1101                	addi	sp,sp,-32
 6ac:	ec06                	sd	ra,24(sp)
 6ae:	e822                	sd	s0,16(sp)
 6b0:	1000                	addi	s0,sp,32
 6b2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 6b6:	4605                	li	a2,1
 6b8:	fef40593          	addi	a1,s0,-17
 6bc:	00000097          	auipc	ra,0x0
 6c0:	f5e080e7          	jalr	-162(ra) # 61a <write>
}
 6c4:	60e2                	ld	ra,24(sp)
 6c6:	6442                	ld	s0,16(sp)
 6c8:	6105                	addi	sp,sp,32
 6ca:	8082                	ret

00000000000006cc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 6cc:	7139                	addi	sp,sp,-64
 6ce:	fc06                	sd	ra,56(sp)
 6d0:	f822                	sd	s0,48(sp)
 6d2:	f426                	sd	s1,40(sp)
 6d4:	f04a                	sd	s2,32(sp)
 6d6:	ec4e                	sd	s3,24(sp)
 6d8:	0080                	addi	s0,sp,64
 6da:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 6dc:	c299                	beqz	a3,6e2 <printint+0x16>
 6de:	0805c863          	bltz	a1,76e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6e2:	2581                	sext.w	a1,a1
  neg = 0;
 6e4:	4881                	li	a7,0
 6e6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6ea:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6ec:	2601                	sext.w	a2,a2
 6ee:	00000517          	auipc	a0,0x0
 6f2:	4ca50513          	addi	a0,a0,1226 # bb8 <digits>
 6f6:	883a                	mv	a6,a4
 6f8:	2705                	addiw	a4,a4,1
 6fa:	02c5f7bb          	remuw	a5,a1,a2
 6fe:	1782                	slli	a5,a5,0x20
 700:	9381                	srli	a5,a5,0x20
 702:	97aa                	add	a5,a5,a0
 704:	0007c783          	lbu	a5,0(a5)
 708:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 70c:	0005879b          	sext.w	a5,a1
 710:	02c5d5bb          	divuw	a1,a1,a2
 714:	0685                	addi	a3,a3,1
 716:	fec7f0e3          	bgeu	a5,a2,6f6 <printint+0x2a>
  if(neg)
 71a:	00088b63          	beqz	a7,730 <printint+0x64>
    buf[i++] = '-';
 71e:	fd040793          	addi	a5,s0,-48
 722:	973e                	add	a4,a4,a5
 724:	02d00793          	li	a5,45
 728:	fef70823          	sb	a5,-16(a4)
 72c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 730:	02e05863          	blez	a4,760 <printint+0x94>
 734:	fc040793          	addi	a5,s0,-64
 738:	00e78933          	add	s2,a5,a4
 73c:	fff78993          	addi	s3,a5,-1
 740:	99ba                	add	s3,s3,a4
 742:	377d                	addiw	a4,a4,-1
 744:	1702                	slli	a4,a4,0x20
 746:	9301                	srli	a4,a4,0x20
 748:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 74c:	fff94583          	lbu	a1,-1(s2)
 750:	8526                	mv	a0,s1
 752:	00000097          	auipc	ra,0x0
 756:	f58080e7          	jalr	-168(ra) # 6aa <putc>
  while(--i >= 0)
 75a:	197d                	addi	s2,s2,-1
 75c:	ff3918e3          	bne	s2,s3,74c <printint+0x80>
}
 760:	70e2                	ld	ra,56(sp)
 762:	7442                	ld	s0,48(sp)
 764:	74a2                	ld	s1,40(sp)
 766:	7902                	ld	s2,32(sp)
 768:	69e2                	ld	s3,24(sp)
 76a:	6121                	addi	sp,sp,64
 76c:	8082                	ret
    x = -xx;
 76e:	40b005bb          	negw	a1,a1
    neg = 1;
 772:	4885                	li	a7,1
    x = -xx;
 774:	bf8d                	j	6e6 <printint+0x1a>

0000000000000776 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 776:	7119                	addi	sp,sp,-128
 778:	fc86                	sd	ra,120(sp)
 77a:	f8a2                	sd	s0,112(sp)
 77c:	f4a6                	sd	s1,104(sp)
 77e:	f0ca                	sd	s2,96(sp)
 780:	ecce                	sd	s3,88(sp)
 782:	e8d2                	sd	s4,80(sp)
 784:	e4d6                	sd	s5,72(sp)
 786:	e0da                	sd	s6,64(sp)
 788:	fc5e                	sd	s7,56(sp)
 78a:	f862                	sd	s8,48(sp)
 78c:	f466                	sd	s9,40(sp)
 78e:	f06a                	sd	s10,32(sp)
 790:	ec6e                	sd	s11,24(sp)
 792:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 794:	0005c903          	lbu	s2,0(a1)
 798:	18090f63          	beqz	s2,936 <vprintf+0x1c0>
 79c:	8aaa                	mv	s5,a0
 79e:	8b32                	mv	s6,a2
 7a0:	00158493          	addi	s1,a1,1
  state = 0;
 7a4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 7a6:	02500a13          	li	s4,37
      if(c == 'd'){
 7aa:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 7ae:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 7b2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 7b6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7ba:	00000b97          	auipc	s7,0x0
 7be:	3feb8b93          	addi	s7,s7,1022 # bb8 <digits>
 7c2:	a839                	j	7e0 <vprintf+0x6a>
        putc(fd, c);
 7c4:	85ca                	mv	a1,s2
 7c6:	8556                	mv	a0,s5
 7c8:	00000097          	auipc	ra,0x0
 7cc:	ee2080e7          	jalr	-286(ra) # 6aa <putc>
 7d0:	a019                	j	7d6 <vprintf+0x60>
    } else if(state == '%'){
 7d2:	01498f63          	beq	s3,s4,7f0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 7d6:	0485                	addi	s1,s1,1
 7d8:	fff4c903          	lbu	s2,-1(s1)
 7dc:	14090d63          	beqz	s2,936 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 7e0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7e4:	fe0997e3          	bnez	s3,7d2 <vprintf+0x5c>
      if(c == '%'){
 7e8:	fd479ee3          	bne	a5,s4,7c4 <vprintf+0x4e>
        state = '%';
 7ec:	89be                	mv	s3,a5
 7ee:	b7e5                	j	7d6 <vprintf+0x60>
      if(c == 'd'){
 7f0:	05878063          	beq	a5,s8,830 <vprintf+0xba>
      } else if(c == 'l') {
 7f4:	05978c63          	beq	a5,s9,84c <vprintf+0xd6>
      } else if(c == 'x') {
 7f8:	07a78863          	beq	a5,s10,868 <vprintf+0xf2>
      } else if(c == 'p') {
 7fc:	09b78463          	beq	a5,s11,884 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 800:	07300713          	li	a4,115
 804:	0ce78663          	beq	a5,a4,8d0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 808:	06300713          	li	a4,99
 80c:	0ee78e63          	beq	a5,a4,908 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 810:	11478863          	beq	a5,s4,920 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 814:	85d2                	mv	a1,s4
 816:	8556                	mv	a0,s5
 818:	00000097          	auipc	ra,0x0
 81c:	e92080e7          	jalr	-366(ra) # 6aa <putc>
        putc(fd, c);
 820:	85ca                	mv	a1,s2
 822:	8556                	mv	a0,s5
 824:	00000097          	auipc	ra,0x0
 828:	e86080e7          	jalr	-378(ra) # 6aa <putc>
      }
      state = 0;
 82c:	4981                	li	s3,0
 82e:	b765                	j	7d6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 830:	008b0913          	addi	s2,s6,8
 834:	4685                	li	a3,1
 836:	4629                	li	a2,10
 838:	000b2583          	lw	a1,0(s6)
 83c:	8556                	mv	a0,s5
 83e:	00000097          	auipc	ra,0x0
 842:	e8e080e7          	jalr	-370(ra) # 6cc <printint>
 846:	8b4a                	mv	s6,s2
      state = 0;
 848:	4981                	li	s3,0
 84a:	b771                	j	7d6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 84c:	008b0913          	addi	s2,s6,8
 850:	4681                	li	a3,0
 852:	4629                	li	a2,10
 854:	000b2583          	lw	a1,0(s6)
 858:	8556                	mv	a0,s5
 85a:	00000097          	auipc	ra,0x0
 85e:	e72080e7          	jalr	-398(ra) # 6cc <printint>
 862:	8b4a                	mv	s6,s2
      state = 0;
 864:	4981                	li	s3,0
 866:	bf85                	j	7d6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 868:	008b0913          	addi	s2,s6,8
 86c:	4681                	li	a3,0
 86e:	4641                	li	a2,16
 870:	000b2583          	lw	a1,0(s6)
 874:	8556                	mv	a0,s5
 876:	00000097          	auipc	ra,0x0
 87a:	e56080e7          	jalr	-426(ra) # 6cc <printint>
 87e:	8b4a                	mv	s6,s2
      state = 0;
 880:	4981                	li	s3,0
 882:	bf91                	j	7d6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 884:	008b0793          	addi	a5,s6,8
 888:	f8f43423          	sd	a5,-120(s0)
 88c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 890:	03000593          	li	a1,48
 894:	8556                	mv	a0,s5
 896:	00000097          	auipc	ra,0x0
 89a:	e14080e7          	jalr	-492(ra) # 6aa <putc>
  putc(fd, 'x');
 89e:	85ea                	mv	a1,s10
 8a0:	8556                	mv	a0,s5
 8a2:	00000097          	auipc	ra,0x0
 8a6:	e08080e7          	jalr	-504(ra) # 6aa <putc>
 8aa:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 8ac:	03c9d793          	srli	a5,s3,0x3c
 8b0:	97de                	add	a5,a5,s7
 8b2:	0007c583          	lbu	a1,0(a5)
 8b6:	8556                	mv	a0,s5
 8b8:	00000097          	auipc	ra,0x0
 8bc:	df2080e7          	jalr	-526(ra) # 6aa <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 8c0:	0992                	slli	s3,s3,0x4
 8c2:	397d                	addiw	s2,s2,-1
 8c4:	fe0914e3          	bnez	s2,8ac <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 8c8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 8cc:	4981                	li	s3,0
 8ce:	b721                	j	7d6 <vprintf+0x60>
        s = va_arg(ap, char*);
 8d0:	008b0993          	addi	s3,s6,8
 8d4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 8d8:	02090163          	beqz	s2,8fa <vprintf+0x184>
        while(*s != 0){
 8dc:	00094583          	lbu	a1,0(s2)
 8e0:	c9a1                	beqz	a1,930 <vprintf+0x1ba>
          putc(fd, *s);
 8e2:	8556                	mv	a0,s5
 8e4:	00000097          	auipc	ra,0x0
 8e8:	dc6080e7          	jalr	-570(ra) # 6aa <putc>
          s++;
 8ec:	0905                	addi	s2,s2,1
        while(*s != 0){
 8ee:	00094583          	lbu	a1,0(s2)
 8f2:	f9e5                	bnez	a1,8e2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 8f4:	8b4e                	mv	s6,s3
      state = 0;
 8f6:	4981                	li	s3,0
 8f8:	bdf9                	j	7d6 <vprintf+0x60>
          s = "(null)";
 8fa:	00000917          	auipc	s2,0x0
 8fe:	2b690913          	addi	s2,s2,694 # bb0 <malloc+0x170>
        while(*s != 0){
 902:	02800593          	li	a1,40
 906:	bff1                	j	8e2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 908:	008b0913          	addi	s2,s6,8
 90c:	000b4583          	lbu	a1,0(s6)
 910:	8556                	mv	a0,s5
 912:	00000097          	auipc	ra,0x0
 916:	d98080e7          	jalr	-616(ra) # 6aa <putc>
 91a:	8b4a                	mv	s6,s2
      state = 0;
 91c:	4981                	li	s3,0
 91e:	bd65                	j	7d6 <vprintf+0x60>
        putc(fd, c);
 920:	85d2                	mv	a1,s4
 922:	8556                	mv	a0,s5
 924:	00000097          	auipc	ra,0x0
 928:	d86080e7          	jalr	-634(ra) # 6aa <putc>
      state = 0;
 92c:	4981                	li	s3,0
 92e:	b565                	j	7d6 <vprintf+0x60>
        s = va_arg(ap, char*);
 930:	8b4e                	mv	s6,s3
      state = 0;
 932:	4981                	li	s3,0
 934:	b54d                	j	7d6 <vprintf+0x60>
    }
  }
}
 936:	70e6                	ld	ra,120(sp)
 938:	7446                	ld	s0,112(sp)
 93a:	74a6                	ld	s1,104(sp)
 93c:	7906                	ld	s2,96(sp)
 93e:	69e6                	ld	s3,88(sp)
 940:	6a46                	ld	s4,80(sp)
 942:	6aa6                	ld	s5,72(sp)
 944:	6b06                	ld	s6,64(sp)
 946:	7be2                	ld	s7,56(sp)
 948:	7c42                	ld	s8,48(sp)
 94a:	7ca2                	ld	s9,40(sp)
 94c:	7d02                	ld	s10,32(sp)
 94e:	6de2                	ld	s11,24(sp)
 950:	6109                	addi	sp,sp,128
 952:	8082                	ret

0000000000000954 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 954:	715d                	addi	sp,sp,-80
 956:	ec06                	sd	ra,24(sp)
 958:	e822                	sd	s0,16(sp)
 95a:	1000                	addi	s0,sp,32
 95c:	e010                	sd	a2,0(s0)
 95e:	e414                	sd	a3,8(s0)
 960:	e818                	sd	a4,16(s0)
 962:	ec1c                	sd	a5,24(s0)
 964:	03043023          	sd	a6,32(s0)
 968:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 96c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 970:	8622                	mv	a2,s0
 972:	00000097          	auipc	ra,0x0
 976:	e04080e7          	jalr	-508(ra) # 776 <vprintf>
}
 97a:	60e2                	ld	ra,24(sp)
 97c:	6442                	ld	s0,16(sp)
 97e:	6161                	addi	sp,sp,80
 980:	8082                	ret

0000000000000982 <printf>:

void
printf(const char *fmt, ...)
{
 982:	711d                	addi	sp,sp,-96
 984:	ec06                	sd	ra,24(sp)
 986:	e822                	sd	s0,16(sp)
 988:	1000                	addi	s0,sp,32
 98a:	e40c                	sd	a1,8(s0)
 98c:	e810                	sd	a2,16(s0)
 98e:	ec14                	sd	a3,24(s0)
 990:	f018                	sd	a4,32(s0)
 992:	f41c                	sd	a5,40(s0)
 994:	03043823          	sd	a6,48(s0)
 998:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 99c:	00840613          	addi	a2,s0,8
 9a0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 9a4:	85aa                	mv	a1,a0
 9a6:	4505                	li	a0,1
 9a8:	00000097          	auipc	ra,0x0
 9ac:	dce080e7          	jalr	-562(ra) # 776 <vprintf>
}
 9b0:	60e2                	ld	ra,24(sp)
 9b2:	6442                	ld	s0,16(sp)
 9b4:	6125                	addi	sp,sp,96
 9b6:	8082                	ret

00000000000009b8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 9b8:	1141                	addi	sp,sp,-16
 9ba:	e422                	sd	s0,8(sp)
 9bc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 9be:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9c2:	00000797          	auipc	a5,0x0
 9c6:	20e7b783          	ld	a5,526(a5) # bd0 <freep>
 9ca:	a805                	j	9fa <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 9cc:	4618                	lw	a4,8(a2)
 9ce:	9db9                	addw	a1,a1,a4
 9d0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 9d4:	6398                	ld	a4,0(a5)
 9d6:	6318                	ld	a4,0(a4)
 9d8:	fee53823          	sd	a4,-16(a0)
 9dc:	a091                	j	a20 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 9de:	ff852703          	lw	a4,-8(a0)
 9e2:	9e39                	addw	a2,a2,a4
 9e4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9e6:	ff053703          	ld	a4,-16(a0)
 9ea:	e398                	sd	a4,0(a5)
 9ec:	a099                	j	a32 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9ee:	6398                	ld	a4,0(a5)
 9f0:	00e7e463          	bltu	a5,a4,9f8 <free+0x40>
 9f4:	00e6ea63          	bltu	a3,a4,a08 <free+0x50>
{
 9f8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9fa:	fed7fae3          	bgeu	a5,a3,9ee <free+0x36>
 9fe:	6398                	ld	a4,0(a5)
 a00:	00e6e463          	bltu	a3,a4,a08 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a04:	fee7eae3          	bltu	a5,a4,9f8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 a08:	ff852583          	lw	a1,-8(a0)
 a0c:	6390                	ld	a2,0(a5)
 a0e:	02059713          	slli	a4,a1,0x20
 a12:	9301                	srli	a4,a4,0x20
 a14:	0712                	slli	a4,a4,0x4
 a16:	9736                	add	a4,a4,a3
 a18:	fae60ae3          	beq	a2,a4,9cc <free+0x14>
    bp->s.ptr = p->s.ptr;
 a1c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 a20:	4790                	lw	a2,8(a5)
 a22:	02061713          	slli	a4,a2,0x20
 a26:	9301                	srli	a4,a4,0x20
 a28:	0712                	slli	a4,a4,0x4
 a2a:	973e                	add	a4,a4,a5
 a2c:	fae689e3          	beq	a3,a4,9de <free+0x26>
  } else
    p->s.ptr = bp;
 a30:	e394                	sd	a3,0(a5)
  freep = p;
 a32:	00000717          	auipc	a4,0x0
 a36:	18f73f23          	sd	a5,414(a4) # bd0 <freep>
}
 a3a:	6422                	ld	s0,8(sp)
 a3c:	0141                	addi	sp,sp,16
 a3e:	8082                	ret

0000000000000a40 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a40:	7139                	addi	sp,sp,-64
 a42:	fc06                	sd	ra,56(sp)
 a44:	f822                	sd	s0,48(sp)
 a46:	f426                	sd	s1,40(sp)
 a48:	f04a                	sd	s2,32(sp)
 a4a:	ec4e                	sd	s3,24(sp)
 a4c:	e852                	sd	s4,16(sp)
 a4e:	e456                	sd	s5,8(sp)
 a50:	e05a                	sd	s6,0(sp)
 a52:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a54:	02051493          	slli	s1,a0,0x20
 a58:	9081                	srli	s1,s1,0x20
 a5a:	04bd                	addi	s1,s1,15
 a5c:	8091                	srli	s1,s1,0x4
 a5e:	0014899b          	addiw	s3,s1,1
 a62:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a64:	00000517          	auipc	a0,0x0
 a68:	16c53503          	ld	a0,364(a0) # bd0 <freep>
 a6c:	c515                	beqz	a0,a98 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a6e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a70:	4798                	lw	a4,8(a5)
 a72:	02977f63          	bgeu	a4,s1,ab0 <malloc+0x70>
 a76:	8a4e                	mv	s4,s3
 a78:	0009871b          	sext.w	a4,s3
 a7c:	6685                	lui	a3,0x1
 a7e:	00d77363          	bgeu	a4,a3,a84 <malloc+0x44>
 a82:	6a05                	lui	s4,0x1
 a84:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a88:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a8c:	00000917          	auipc	s2,0x0
 a90:	14490913          	addi	s2,s2,324 # bd0 <freep>
  if(p == (char*)-1)
 a94:	5afd                	li	s5,-1
 a96:	a88d                	j	b08 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a98:	00000797          	auipc	a5,0x0
 a9c:	15078793          	addi	a5,a5,336 # be8 <base>
 aa0:	00000717          	auipc	a4,0x0
 aa4:	12f73823          	sd	a5,304(a4) # bd0 <freep>
 aa8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 aaa:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 aae:	b7e1                	j	a76 <malloc+0x36>
      if(p->s.size == nunits)
 ab0:	02e48b63          	beq	s1,a4,ae6 <malloc+0xa6>
        p->s.size -= nunits;
 ab4:	4137073b          	subw	a4,a4,s3
 ab8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 aba:	1702                	slli	a4,a4,0x20
 abc:	9301                	srli	a4,a4,0x20
 abe:	0712                	slli	a4,a4,0x4
 ac0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 ac2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 ac6:	00000717          	auipc	a4,0x0
 aca:	10a73523          	sd	a0,266(a4) # bd0 <freep>
      return (void*)(p + 1);
 ace:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 ad2:	70e2                	ld	ra,56(sp)
 ad4:	7442                	ld	s0,48(sp)
 ad6:	74a2                	ld	s1,40(sp)
 ad8:	7902                	ld	s2,32(sp)
 ada:	69e2                	ld	s3,24(sp)
 adc:	6a42                	ld	s4,16(sp)
 ade:	6aa2                	ld	s5,8(sp)
 ae0:	6b02                	ld	s6,0(sp)
 ae2:	6121                	addi	sp,sp,64
 ae4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ae6:	6398                	ld	a4,0(a5)
 ae8:	e118                	sd	a4,0(a0)
 aea:	bff1                	j	ac6 <malloc+0x86>
  hp->s.size = nu;
 aec:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 af0:	0541                	addi	a0,a0,16
 af2:	00000097          	auipc	ra,0x0
 af6:	ec6080e7          	jalr	-314(ra) # 9b8 <free>
  return freep;
 afa:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 afe:	d971                	beqz	a0,ad2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b00:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b02:	4798                	lw	a4,8(a5)
 b04:	fa9776e3          	bgeu	a4,s1,ab0 <malloc+0x70>
    if(p == freep)
 b08:	00093703          	ld	a4,0(s2)
 b0c:	853e                	mv	a0,a5
 b0e:	fef719e3          	bne	a4,a5,b00 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 b12:	8552                	mv	a0,s4
 b14:	00000097          	auipc	ra,0x0
 b18:	b7e080e7          	jalr	-1154(ra) # 692 <sbrk>
  if(p == (char*)-1)
 b1c:	fd5518e3          	bne	a0,s5,aec <malloc+0xac>
        return 0;
 b20:	4501                	li	a0,0
 b22:	bf45                	j	ad2 <malloc+0x92>
