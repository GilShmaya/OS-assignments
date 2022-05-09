
user/_usertests:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <copyinstr1>:
}

// what if you pass ridiculous string pointers to system calls?
void
copyinstr1(char *s)
{
       0:	1141                	addi	sp,sp,-16
       2:	e406                	sd	ra,8(sp)
       4:	e022                	sd	s0,0(sp)
       6:	0800                	addi	s0,sp,16
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };

  for(int ai = 0; ai < 2; ai++){
    uint64 addr = addrs[ai];

    int fd = open((char *)addr, O_CREATE|O_WRONLY);
       8:	20100593          	li	a1,513
       c:	4505                	li	a0,1
       e:	057e                	slli	a0,a0,0x1f
      10:	00006097          	auipc	ra,0x6
      14:	882080e7          	jalr	-1918(ra) # 5892 <open>
    if(fd >= 0){
      18:	02055063          	bgez	a0,38 <copyinstr1+0x38>
    int fd = open((char *)addr, O_CREATE|O_WRONLY);
      1c:	20100593          	li	a1,513
      20:	557d                	li	a0,-1
      22:	00006097          	auipc	ra,0x6
      26:	870080e7          	jalr	-1936(ra) # 5892 <open>
    uint64 addr = addrs[ai];
      2a:	55fd                	li	a1,-1
    if(fd >= 0){
      2c:	00055863          	bgez	a0,3c <copyinstr1+0x3c>
      printf("open(%p) returned %d, not -1\n", addr, fd);
      exit(1);
    }
  }
}
      30:	60a2                	ld	ra,8(sp)
      32:	6402                	ld	s0,0(sp)
      34:	0141                	addi	sp,sp,16
      36:	8082                	ret
    uint64 addr = addrs[ai];
      38:	4585                	li	a1,1
      3a:	05fe                	slli	a1,a1,0x1f
      printf("open(%p) returned %d, not -1\n", addr, fd);
      3c:	862a                	mv	a2,a0
      3e:	00006517          	auipc	a0,0x6
      42:	0ba50513          	addi	a0,a0,186 # 60f8 <malloc+0x458>
      46:	00006097          	auipc	ra,0x6
      4a:	b9c080e7          	jalr	-1124(ra) # 5be2 <printf>
      exit(1);
      4e:	4505                	li	a0,1
      50:	00006097          	auipc	ra,0x6
      54:	802080e7          	jalr	-2046(ra) # 5852 <exit>

0000000000000058 <bsstest>:
void
bsstest(char *s)
{
  int i;

  for(i = 0; i < sizeof(uninit); i++){
      58:	00009797          	auipc	a5,0x9
      5c:	67078793          	addi	a5,a5,1648 # 96c8 <uninit>
      60:	0000c697          	auipc	a3,0xc
      64:	d7868693          	addi	a3,a3,-648 # bdd8 <buf>
    if(uninit[i] != '\0'){
      68:	0007c703          	lbu	a4,0(a5)
      6c:	e709                	bnez	a4,76 <bsstest+0x1e>
  for(i = 0; i < sizeof(uninit); i++){
      6e:	0785                	addi	a5,a5,1
      70:	fed79ce3          	bne	a5,a3,68 <bsstest+0x10>
      74:	8082                	ret
{
      76:	1141                	addi	sp,sp,-16
      78:	e406                	sd	ra,8(sp)
      7a:	e022                	sd	s0,0(sp)
      7c:	0800                	addi	s0,sp,16
      printf("%s: bss test failed\n", s);
      7e:	85aa                	mv	a1,a0
      80:	00006517          	auipc	a0,0x6
      84:	09850513          	addi	a0,a0,152 # 6118 <malloc+0x478>
      88:	00006097          	auipc	ra,0x6
      8c:	b5a080e7          	jalr	-1190(ra) # 5be2 <printf>
      exit(1);
      90:	4505                	li	a0,1
      92:	00005097          	auipc	ra,0x5
      96:	7c0080e7          	jalr	1984(ra) # 5852 <exit>

000000000000009a <opentest>:
{
      9a:	1101                	addi	sp,sp,-32
      9c:	ec06                	sd	ra,24(sp)
      9e:	e822                	sd	s0,16(sp)
      a0:	e426                	sd	s1,8(sp)
      a2:	1000                	addi	s0,sp,32
      a4:	84aa                	mv	s1,a0
  fd = open("echo", 0);
      a6:	4581                	li	a1,0
      a8:	00006517          	auipc	a0,0x6
      ac:	08850513          	addi	a0,a0,136 # 6130 <malloc+0x490>
      b0:	00005097          	auipc	ra,0x5
      b4:	7e2080e7          	jalr	2018(ra) # 5892 <open>
  if(fd < 0){
      b8:	02054663          	bltz	a0,e4 <opentest+0x4a>
  close(fd);
      bc:	00005097          	auipc	ra,0x5
      c0:	7be080e7          	jalr	1982(ra) # 587a <close>
  fd = open("doesnotexist", 0);
      c4:	4581                	li	a1,0
      c6:	00006517          	auipc	a0,0x6
      ca:	08a50513          	addi	a0,a0,138 # 6150 <malloc+0x4b0>
      ce:	00005097          	auipc	ra,0x5
      d2:	7c4080e7          	jalr	1988(ra) # 5892 <open>
  if(fd >= 0){
      d6:	02055563          	bgez	a0,100 <opentest+0x66>
}
      da:	60e2                	ld	ra,24(sp)
      dc:	6442                	ld	s0,16(sp)
      de:	64a2                	ld	s1,8(sp)
      e0:	6105                	addi	sp,sp,32
      e2:	8082                	ret
    printf("%s: open echo failed!\n", s);
      e4:	85a6                	mv	a1,s1
      e6:	00006517          	auipc	a0,0x6
      ea:	05250513          	addi	a0,a0,82 # 6138 <malloc+0x498>
      ee:	00006097          	auipc	ra,0x6
      f2:	af4080e7          	jalr	-1292(ra) # 5be2 <printf>
    exit(1);
      f6:	4505                	li	a0,1
      f8:	00005097          	auipc	ra,0x5
      fc:	75a080e7          	jalr	1882(ra) # 5852 <exit>
    printf("%s: open doesnotexist succeeded!\n", s);
     100:	85a6                	mv	a1,s1
     102:	00006517          	auipc	a0,0x6
     106:	05e50513          	addi	a0,a0,94 # 6160 <malloc+0x4c0>
     10a:	00006097          	auipc	ra,0x6
     10e:	ad8080e7          	jalr	-1320(ra) # 5be2 <printf>
    exit(1);
     112:	4505                	li	a0,1
     114:	00005097          	auipc	ra,0x5
     118:	73e080e7          	jalr	1854(ra) # 5852 <exit>

000000000000011c <truncate2>:
{
     11c:	7179                	addi	sp,sp,-48
     11e:	f406                	sd	ra,40(sp)
     120:	f022                	sd	s0,32(sp)
     122:	ec26                	sd	s1,24(sp)
     124:	e84a                	sd	s2,16(sp)
     126:	e44e                	sd	s3,8(sp)
     128:	1800                	addi	s0,sp,48
     12a:	89aa                	mv	s3,a0
  unlink("truncfile");
     12c:	00006517          	auipc	a0,0x6
     130:	05c50513          	addi	a0,a0,92 # 6188 <malloc+0x4e8>
     134:	00005097          	auipc	ra,0x5
     138:	76e080e7          	jalr	1902(ra) # 58a2 <unlink>
  int fd1 = open("truncfile", O_CREATE|O_TRUNC|O_WRONLY);
     13c:	60100593          	li	a1,1537
     140:	00006517          	auipc	a0,0x6
     144:	04850513          	addi	a0,a0,72 # 6188 <malloc+0x4e8>
     148:	00005097          	auipc	ra,0x5
     14c:	74a080e7          	jalr	1866(ra) # 5892 <open>
     150:	84aa                	mv	s1,a0
  write(fd1, "abcd", 4);
     152:	4611                	li	a2,4
     154:	00006597          	auipc	a1,0x6
     158:	04458593          	addi	a1,a1,68 # 6198 <malloc+0x4f8>
     15c:	00005097          	auipc	ra,0x5
     160:	716080e7          	jalr	1814(ra) # 5872 <write>
  int fd2 = open("truncfile", O_TRUNC|O_WRONLY);
     164:	40100593          	li	a1,1025
     168:	00006517          	auipc	a0,0x6
     16c:	02050513          	addi	a0,a0,32 # 6188 <malloc+0x4e8>
     170:	00005097          	auipc	ra,0x5
     174:	722080e7          	jalr	1826(ra) # 5892 <open>
     178:	892a                	mv	s2,a0
  int n = write(fd1, "x", 1);
     17a:	4605                	li	a2,1
     17c:	00006597          	auipc	a1,0x6
     180:	02458593          	addi	a1,a1,36 # 61a0 <malloc+0x500>
     184:	8526                	mv	a0,s1
     186:	00005097          	auipc	ra,0x5
     18a:	6ec080e7          	jalr	1772(ra) # 5872 <write>
  if(n != -1){
     18e:	57fd                	li	a5,-1
     190:	02f51b63          	bne	a0,a5,1c6 <truncate2+0xaa>
  unlink("truncfile");
     194:	00006517          	auipc	a0,0x6
     198:	ff450513          	addi	a0,a0,-12 # 6188 <malloc+0x4e8>
     19c:	00005097          	auipc	ra,0x5
     1a0:	706080e7          	jalr	1798(ra) # 58a2 <unlink>
  close(fd1);
     1a4:	8526                	mv	a0,s1
     1a6:	00005097          	auipc	ra,0x5
     1aa:	6d4080e7          	jalr	1748(ra) # 587a <close>
  close(fd2);
     1ae:	854a                	mv	a0,s2
     1b0:	00005097          	auipc	ra,0x5
     1b4:	6ca080e7          	jalr	1738(ra) # 587a <close>
}
     1b8:	70a2                	ld	ra,40(sp)
     1ba:	7402                	ld	s0,32(sp)
     1bc:	64e2                	ld	s1,24(sp)
     1be:	6942                	ld	s2,16(sp)
     1c0:	69a2                	ld	s3,8(sp)
     1c2:	6145                	addi	sp,sp,48
     1c4:	8082                	ret
    printf("%s: write returned %d, expected -1\n", s, n);
     1c6:	862a                	mv	a2,a0
     1c8:	85ce                	mv	a1,s3
     1ca:	00006517          	auipc	a0,0x6
     1ce:	fde50513          	addi	a0,a0,-34 # 61a8 <malloc+0x508>
     1d2:	00006097          	auipc	ra,0x6
     1d6:	a10080e7          	jalr	-1520(ra) # 5be2 <printf>
    exit(1);
     1da:	4505                	li	a0,1
     1dc:	00005097          	auipc	ra,0x5
     1e0:	676080e7          	jalr	1654(ra) # 5852 <exit>

00000000000001e4 <createtest>:
{
     1e4:	7179                	addi	sp,sp,-48
     1e6:	f406                	sd	ra,40(sp)
     1e8:	f022                	sd	s0,32(sp)
     1ea:	ec26                	sd	s1,24(sp)
     1ec:	e84a                	sd	s2,16(sp)
     1ee:	1800                	addi	s0,sp,48
  name[0] = 'a';
     1f0:	06100793          	li	a5,97
     1f4:	fcf40c23          	sb	a5,-40(s0)
  name[2] = '\0';
     1f8:	fc040d23          	sb	zero,-38(s0)
     1fc:	03000493          	li	s1,48
  for(i = 0; i < N; i++){
     200:	06400913          	li	s2,100
    name[1] = '0' + i;
     204:	fc940ca3          	sb	s1,-39(s0)
    fd = open(name, O_CREATE|O_RDWR);
     208:	20200593          	li	a1,514
     20c:	fd840513          	addi	a0,s0,-40
     210:	00005097          	auipc	ra,0x5
     214:	682080e7          	jalr	1666(ra) # 5892 <open>
    close(fd);
     218:	00005097          	auipc	ra,0x5
     21c:	662080e7          	jalr	1634(ra) # 587a <close>
  for(i = 0; i < N; i++){
     220:	2485                	addiw	s1,s1,1
     222:	0ff4f493          	andi	s1,s1,255
     226:	fd249fe3          	bne	s1,s2,204 <createtest+0x20>
  name[0] = 'a';
     22a:	06100793          	li	a5,97
     22e:	fcf40c23          	sb	a5,-40(s0)
  name[2] = '\0';
     232:	fc040d23          	sb	zero,-38(s0)
     236:	03000493          	li	s1,48
  for(i = 0; i < N; i++){
     23a:	06400913          	li	s2,100
    name[1] = '0' + i;
     23e:	fc940ca3          	sb	s1,-39(s0)
    unlink(name);
     242:	fd840513          	addi	a0,s0,-40
     246:	00005097          	auipc	ra,0x5
     24a:	65c080e7          	jalr	1628(ra) # 58a2 <unlink>
  for(i = 0; i < N; i++){
     24e:	2485                	addiw	s1,s1,1
     250:	0ff4f493          	andi	s1,s1,255
     254:	ff2495e3          	bne	s1,s2,23e <createtest+0x5a>
}
     258:	70a2                	ld	ra,40(sp)
     25a:	7402                	ld	s0,32(sp)
     25c:	64e2                	ld	s1,24(sp)
     25e:	6942                	ld	s2,16(sp)
     260:	6145                	addi	sp,sp,48
     262:	8082                	ret

0000000000000264 <bigwrite>:
{
     264:	715d                	addi	sp,sp,-80
     266:	e486                	sd	ra,72(sp)
     268:	e0a2                	sd	s0,64(sp)
     26a:	fc26                	sd	s1,56(sp)
     26c:	f84a                	sd	s2,48(sp)
     26e:	f44e                	sd	s3,40(sp)
     270:	f052                	sd	s4,32(sp)
     272:	ec56                	sd	s5,24(sp)
     274:	e85a                	sd	s6,16(sp)
     276:	e45e                	sd	s7,8(sp)
     278:	0880                	addi	s0,sp,80
     27a:	8baa                	mv	s7,a0
  unlink("bigwrite");
     27c:	00006517          	auipc	a0,0x6
     280:	cfc50513          	addi	a0,a0,-772 # 5f78 <malloc+0x2d8>
     284:	00005097          	auipc	ra,0x5
     288:	61e080e7          	jalr	1566(ra) # 58a2 <unlink>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     28c:	1f300493          	li	s1,499
    fd = open("bigwrite", O_CREATE | O_RDWR);
     290:	00006a97          	auipc	s5,0x6
     294:	ce8a8a93          	addi	s5,s5,-792 # 5f78 <malloc+0x2d8>
      int cc = write(fd, buf, sz);
     298:	0000ca17          	auipc	s4,0xc
     29c:	b40a0a13          	addi	s4,s4,-1216 # bdd8 <buf>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     2a0:	6b0d                	lui	s6,0x3
     2a2:	1c9b0b13          	addi	s6,s6,457 # 31c9 <exitiputtest+0x67>
    fd = open("bigwrite", O_CREATE | O_RDWR);
     2a6:	20200593          	li	a1,514
     2aa:	8556                	mv	a0,s5
     2ac:	00005097          	auipc	ra,0x5
     2b0:	5e6080e7          	jalr	1510(ra) # 5892 <open>
     2b4:	892a                	mv	s2,a0
    if(fd < 0){
     2b6:	04054d63          	bltz	a0,310 <bigwrite+0xac>
      int cc = write(fd, buf, sz);
     2ba:	8626                	mv	a2,s1
     2bc:	85d2                	mv	a1,s4
     2be:	00005097          	auipc	ra,0x5
     2c2:	5b4080e7          	jalr	1460(ra) # 5872 <write>
     2c6:	89aa                	mv	s3,a0
      if(cc != sz){
     2c8:	06a49463          	bne	s1,a0,330 <bigwrite+0xcc>
      int cc = write(fd, buf, sz);
     2cc:	8626                	mv	a2,s1
     2ce:	85d2                	mv	a1,s4
     2d0:	854a                	mv	a0,s2
     2d2:	00005097          	auipc	ra,0x5
     2d6:	5a0080e7          	jalr	1440(ra) # 5872 <write>
      if(cc != sz){
     2da:	04951963          	bne	a0,s1,32c <bigwrite+0xc8>
    close(fd);
     2de:	854a                	mv	a0,s2
     2e0:	00005097          	auipc	ra,0x5
     2e4:	59a080e7          	jalr	1434(ra) # 587a <close>
    unlink("bigwrite");
     2e8:	8556                	mv	a0,s5
     2ea:	00005097          	auipc	ra,0x5
     2ee:	5b8080e7          	jalr	1464(ra) # 58a2 <unlink>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     2f2:	1d74849b          	addiw	s1,s1,471
     2f6:	fb6498e3          	bne	s1,s6,2a6 <bigwrite+0x42>
}
     2fa:	60a6                	ld	ra,72(sp)
     2fc:	6406                	ld	s0,64(sp)
     2fe:	74e2                	ld	s1,56(sp)
     300:	7942                	ld	s2,48(sp)
     302:	79a2                	ld	s3,40(sp)
     304:	7a02                	ld	s4,32(sp)
     306:	6ae2                	ld	s5,24(sp)
     308:	6b42                	ld	s6,16(sp)
     30a:	6ba2                	ld	s7,8(sp)
     30c:	6161                	addi	sp,sp,80
     30e:	8082                	ret
      printf("%s: cannot create bigwrite\n", s);
     310:	85de                	mv	a1,s7
     312:	00006517          	auipc	a0,0x6
     316:	ebe50513          	addi	a0,a0,-322 # 61d0 <malloc+0x530>
     31a:	00006097          	auipc	ra,0x6
     31e:	8c8080e7          	jalr	-1848(ra) # 5be2 <printf>
      exit(1);
     322:	4505                	li	a0,1
     324:	00005097          	auipc	ra,0x5
     328:	52e080e7          	jalr	1326(ra) # 5852 <exit>
     32c:	84ce                	mv	s1,s3
      int cc = write(fd, buf, sz);
     32e:	89aa                	mv	s3,a0
        printf("%s: write(%d) ret %d\n", s, sz, cc);
     330:	86ce                	mv	a3,s3
     332:	8626                	mv	a2,s1
     334:	85de                	mv	a1,s7
     336:	00006517          	auipc	a0,0x6
     33a:	eba50513          	addi	a0,a0,-326 # 61f0 <malloc+0x550>
     33e:	00006097          	auipc	ra,0x6
     342:	8a4080e7          	jalr	-1884(ra) # 5be2 <printf>
        exit(1);
     346:	4505                	li	a0,1
     348:	00005097          	auipc	ra,0x5
     34c:	50a080e7          	jalr	1290(ra) # 5852 <exit>

0000000000000350 <badwrite>:
// file is deleted? if the kernel has this bug, it will panic: balloc:
// out of blocks. assumed_free may need to be raised to be more than
// the number of free blocks. this test takes a long time.
void
badwrite(char *s)
{
     350:	7179                	addi	sp,sp,-48
     352:	f406                	sd	ra,40(sp)
     354:	f022                	sd	s0,32(sp)
     356:	ec26                	sd	s1,24(sp)
     358:	e84a                	sd	s2,16(sp)
     35a:	e44e                	sd	s3,8(sp)
     35c:	e052                	sd	s4,0(sp)
     35e:	1800                	addi	s0,sp,48
  int assumed_free = 600;
  
  unlink("junk");
     360:	00006517          	auipc	a0,0x6
     364:	ea850513          	addi	a0,a0,-344 # 6208 <malloc+0x568>
     368:	00005097          	auipc	ra,0x5
     36c:	53a080e7          	jalr	1338(ra) # 58a2 <unlink>
     370:	25800913          	li	s2,600
  for(int i = 0; i < assumed_free; i++){
    int fd = open("junk", O_CREATE|O_WRONLY);
     374:	00006997          	auipc	s3,0x6
     378:	e9498993          	addi	s3,s3,-364 # 6208 <malloc+0x568>
    if(fd < 0){
      printf("open junk failed\n");
      exit(1);
    }
    write(fd, (char*)0xffffffffffL, 1);
     37c:	5a7d                	li	s4,-1
     37e:	018a5a13          	srli	s4,s4,0x18
    int fd = open("junk", O_CREATE|O_WRONLY);
     382:	20100593          	li	a1,513
     386:	854e                	mv	a0,s3
     388:	00005097          	auipc	ra,0x5
     38c:	50a080e7          	jalr	1290(ra) # 5892 <open>
     390:	84aa                	mv	s1,a0
    if(fd < 0){
     392:	06054b63          	bltz	a0,408 <badwrite+0xb8>
    write(fd, (char*)0xffffffffffL, 1);
     396:	4605                	li	a2,1
     398:	85d2                	mv	a1,s4
     39a:	00005097          	auipc	ra,0x5
     39e:	4d8080e7          	jalr	1240(ra) # 5872 <write>
    close(fd);
     3a2:	8526                	mv	a0,s1
     3a4:	00005097          	auipc	ra,0x5
     3a8:	4d6080e7          	jalr	1238(ra) # 587a <close>
    unlink("junk");
     3ac:	854e                	mv	a0,s3
     3ae:	00005097          	auipc	ra,0x5
     3b2:	4f4080e7          	jalr	1268(ra) # 58a2 <unlink>
  for(int i = 0; i < assumed_free; i++){
     3b6:	397d                	addiw	s2,s2,-1
     3b8:	fc0915e3          	bnez	s2,382 <badwrite+0x32>
  }

  int fd = open("junk", O_CREATE|O_WRONLY);
     3bc:	20100593          	li	a1,513
     3c0:	00006517          	auipc	a0,0x6
     3c4:	e4850513          	addi	a0,a0,-440 # 6208 <malloc+0x568>
     3c8:	00005097          	auipc	ra,0x5
     3cc:	4ca080e7          	jalr	1226(ra) # 5892 <open>
     3d0:	84aa                	mv	s1,a0
  if(fd < 0){
     3d2:	04054863          	bltz	a0,422 <badwrite+0xd2>
    printf("open junk failed\n");
    exit(1);
  }
  if(write(fd, "x", 1) != 1){
     3d6:	4605                	li	a2,1
     3d8:	00006597          	auipc	a1,0x6
     3dc:	dc858593          	addi	a1,a1,-568 # 61a0 <malloc+0x500>
     3e0:	00005097          	auipc	ra,0x5
     3e4:	492080e7          	jalr	1170(ra) # 5872 <write>
     3e8:	4785                	li	a5,1
     3ea:	04f50963          	beq	a0,a5,43c <badwrite+0xec>
    printf("write failed\n");
     3ee:	00006517          	auipc	a0,0x6
     3f2:	e3a50513          	addi	a0,a0,-454 # 6228 <malloc+0x588>
     3f6:	00005097          	auipc	ra,0x5
     3fa:	7ec080e7          	jalr	2028(ra) # 5be2 <printf>
    exit(1);
     3fe:	4505                	li	a0,1
     400:	00005097          	auipc	ra,0x5
     404:	452080e7          	jalr	1106(ra) # 5852 <exit>
      printf("open junk failed\n");
     408:	00006517          	auipc	a0,0x6
     40c:	e0850513          	addi	a0,a0,-504 # 6210 <malloc+0x570>
     410:	00005097          	auipc	ra,0x5
     414:	7d2080e7          	jalr	2002(ra) # 5be2 <printf>
      exit(1);
     418:	4505                	li	a0,1
     41a:	00005097          	auipc	ra,0x5
     41e:	438080e7          	jalr	1080(ra) # 5852 <exit>
    printf("open junk failed\n");
     422:	00006517          	auipc	a0,0x6
     426:	dee50513          	addi	a0,a0,-530 # 6210 <malloc+0x570>
     42a:	00005097          	auipc	ra,0x5
     42e:	7b8080e7          	jalr	1976(ra) # 5be2 <printf>
    exit(1);
     432:	4505                	li	a0,1
     434:	00005097          	auipc	ra,0x5
     438:	41e080e7          	jalr	1054(ra) # 5852 <exit>
  }
  close(fd);
     43c:	8526                	mv	a0,s1
     43e:	00005097          	auipc	ra,0x5
     442:	43c080e7          	jalr	1084(ra) # 587a <close>
  unlink("junk");
     446:	00006517          	auipc	a0,0x6
     44a:	dc250513          	addi	a0,a0,-574 # 6208 <malloc+0x568>
     44e:	00005097          	auipc	ra,0x5
     452:	454080e7          	jalr	1108(ra) # 58a2 <unlink>

  exit(0);
     456:	4501                	li	a0,0
     458:	00005097          	auipc	ra,0x5
     45c:	3fa080e7          	jalr	1018(ra) # 5852 <exit>

0000000000000460 <copyin>:
{
     460:	715d                	addi	sp,sp,-80
     462:	e486                	sd	ra,72(sp)
     464:	e0a2                	sd	s0,64(sp)
     466:	fc26                	sd	s1,56(sp)
     468:	f84a                	sd	s2,48(sp)
     46a:	f44e                	sd	s3,40(sp)
     46c:	f052                	sd	s4,32(sp)
     46e:	0880                	addi	s0,sp,80
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };
     470:	4785                	li	a5,1
     472:	07fe                	slli	a5,a5,0x1f
     474:	fcf43023          	sd	a5,-64(s0)
     478:	57fd                	li	a5,-1
     47a:	fcf43423          	sd	a5,-56(s0)
  for(int ai = 0; ai < 2; ai++){
     47e:	fc040913          	addi	s2,s0,-64
    int fd = open("copyin1", O_CREATE|O_WRONLY);
     482:	00006a17          	auipc	s4,0x6
     486:	db6a0a13          	addi	s4,s4,-586 # 6238 <malloc+0x598>
    uint64 addr = addrs[ai];
     48a:	00093983          	ld	s3,0(s2)
    int fd = open("copyin1", O_CREATE|O_WRONLY);
     48e:	20100593          	li	a1,513
     492:	8552                	mv	a0,s4
     494:	00005097          	auipc	ra,0x5
     498:	3fe080e7          	jalr	1022(ra) # 5892 <open>
     49c:	84aa                	mv	s1,a0
    if(fd < 0){
     49e:	08054863          	bltz	a0,52e <copyin+0xce>
    int n = write(fd, (void*)addr, 8192);
     4a2:	6609                	lui	a2,0x2
     4a4:	85ce                	mv	a1,s3
     4a6:	00005097          	auipc	ra,0x5
     4aa:	3cc080e7          	jalr	972(ra) # 5872 <write>
    if(n >= 0){
     4ae:	08055d63          	bgez	a0,548 <copyin+0xe8>
    close(fd);
     4b2:	8526                	mv	a0,s1
     4b4:	00005097          	auipc	ra,0x5
     4b8:	3c6080e7          	jalr	966(ra) # 587a <close>
    unlink("copyin1");
     4bc:	8552                	mv	a0,s4
     4be:	00005097          	auipc	ra,0x5
     4c2:	3e4080e7          	jalr	996(ra) # 58a2 <unlink>
    n = write(1, (char*)addr, 8192);
     4c6:	6609                	lui	a2,0x2
     4c8:	85ce                	mv	a1,s3
     4ca:	4505                	li	a0,1
     4cc:	00005097          	auipc	ra,0x5
     4d0:	3a6080e7          	jalr	934(ra) # 5872 <write>
    if(n > 0){
     4d4:	08a04963          	bgtz	a0,566 <copyin+0x106>
    if(pipe(fds) < 0){
     4d8:	fb840513          	addi	a0,s0,-72
     4dc:	00005097          	auipc	ra,0x5
     4e0:	386080e7          	jalr	902(ra) # 5862 <pipe>
     4e4:	0a054063          	bltz	a0,584 <copyin+0x124>
    n = write(fds[1], (char*)addr, 8192);
     4e8:	6609                	lui	a2,0x2
     4ea:	85ce                	mv	a1,s3
     4ec:	fbc42503          	lw	a0,-68(s0)
     4f0:	00005097          	auipc	ra,0x5
     4f4:	382080e7          	jalr	898(ra) # 5872 <write>
    if(n > 0){
     4f8:	0aa04363          	bgtz	a0,59e <copyin+0x13e>
    close(fds[0]);
     4fc:	fb842503          	lw	a0,-72(s0)
     500:	00005097          	auipc	ra,0x5
     504:	37a080e7          	jalr	890(ra) # 587a <close>
    close(fds[1]);
     508:	fbc42503          	lw	a0,-68(s0)
     50c:	00005097          	auipc	ra,0x5
     510:	36e080e7          	jalr	878(ra) # 587a <close>
  for(int ai = 0; ai < 2; ai++){
     514:	0921                	addi	s2,s2,8
     516:	fd040793          	addi	a5,s0,-48
     51a:	f6f918e3          	bne	s2,a5,48a <copyin+0x2a>
}
     51e:	60a6                	ld	ra,72(sp)
     520:	6406                	ld	s0,64(sp)
     522:	74e2                	ld	s1,56(sp)
     524:	7942                	ld	s2,48(sp)
     526:	79a2                	ld	s3,40(sp)
     528:	7a02                	ld	s4,32(sp)
     52a:	6161                	addi	sp,sp,80
     52c:	8082                	ret
      printf("open(copyin1) failed\n");
     52e:	00006517          	auipc	a0,0x6
     532:	d1250513          	addi	a0,a0,-750 # 6240 <malloc+0x5a0>
     536:	00005097          	auipc	ra,0x5
     53a:	6ac080e7          	jalr	1708(ra) # 5be2 <printf>
      exit(1);
     53e:	4505                	li	a0,1
     540:	00005097          	auipc	ra,0x5
     544:	312080e7          	jalr	786(ra) # 5852 <exit>
      printf("write(fd, %p, 8192) returned %d, not -1\n", addr, n);
     548:	862a                	mv	a2,a0
     54a:	85ce                	mv	a1,s3
     54c:	00006517          	auipc	a0,0x6
     550:	d0c50513          	addi	a0,a0,-756 # 6258 <malloc+0x5b8>
     554:	00005097          	auipc	ra,0x5
     558:	68e080e7          	jalr	1678(ra) # 5be2 <printf>
      exit(1);
     55c:	4505                	li	a0,1
     55e:	00005097          	auipc	ra,0x5
     562:	2f4080e7          	jalr	756(ra) # 5852 <exit>
      printf("write(1, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     566:	862a                	mv	a2,a0
     568:	85ce                	mv	a1,s3
     56a:	00006517          	auipc	a0,0x6
     56e:	d1e50513          	addi	a0,a0,-738 # 6288 <malloc+0x5e8>
     572:	00005097          	auipc	ra,0x5
     576:	670080e7          	jalr	1648(ra) # 5be2 <printf>
      exit(1);
     57a:	4505                	li	a0,1
     57c:	00005097          	auipc	ra,0x5
     580:	2d6080e7          	jalr	726(ra) # 5852 <exit>
      printf("pipe() failed\n");
     584:	00006517          	auipc	a0,0x6
     588:	d3450513          	addi	a0,a0,-716 # 62b8 <malloc+0x618>
     58c:	00005097          	auipc	ra,0x5
     590:	656080e7          	jalr	1622(ra) # 5be2 <printf>
      exit(1);
     594:	4505                	li	a0,1
     596:	00005097          	auipc	ra,0x5
     59a:	2bc080e7          	jalr	700(ra) # 5852 <exit>
      printf("write(pipe, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     59e:	862a                	mv	a2,a0
     5a0:	85ce                	mv	a1,s3
     5a2:	00006517          	auipc	a0,0x6
     5a6:	d2650513          	addi	a0,a0,-730 # 62c8 <malloc+0x628>
     5aa:	00005097          	auipc	ra,0x5
     5ae:	638080e7          	jalr	1592(ra) # 5be2 <printf>
      exit(1);
     5b2:	4505                	li	a0,1
     5b4:	00005097          	auipc	ra,0x5
     5b8:	29e080e7          	jalr	670(ra) # 5852 <exit>

00000000000005bc <copyout>:
{
     5bc:	711d                	addi	sp,sp,-96
     5be:	ec86                	sd	ra,88(sp)
     5c0:	e8a2                	sd	s0,80(sp)
     5c2:	e4a6                	sd	s1,72(sp)
     5c4:	e0ca                	sd	s2,64(sp)
     5c6:	fc4e                	sd	s3,56(sp)
     5c8:	f852                	sd	s4,48(sp)
     5ca:	f456                	sd	s5,40(sp)
     5cc:	1080                	addi	s0,sp,96
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };
     5ce:	4785                	li	a5,1
     5d0:	07fe                	slli	a5,a5,0x1f
     5d2:	faf43823          	sd	a5,-80(s0)
     5d6:	57fd                	li	a5,-1
     5d8:	faf43c23          	sd	a5,-72(s0)
  for(int ai = 0; ai < 2; ai++){
     5dc:	fb040913          	addi	s2,s0,-80
    int fd = open("README", 0);
     5e0:	00006a17          	auipc	s4,0x6
     5e4:	d18a0a13          	addi	s4,s4,-744 # 62f8 <malloc+0x658>
    n = write(fds[1], "x", 1);
     5e8:	00006a97          	auipc	s5,0x6
     5ec:	bb8a8a93          	addi	s5,s5,-1096 # 61a0 <malloc+0x500>
    uint64 addr = addrs[ai];
     5f0:	00093983          	ld	s3,0(s2)
    int fd = open("README", 0);
     5f4:	4581                	li	a1,0
     5f6:	8552                	mv	a0,s4
     5f8:	00005097          	auipc	ra,0x5
     5fc:	29a080e7          	jalr	666(ra) # 5892 <open>
     600:	84aa                	mv	s1,a0
    if(fd < 0){
     602:	08054663          	bltz	a0,68e <copyout+0xd2>
    int n = read(fd, (void*)addr, 8192);
     606:	6609                	lui	a2,0x2
     608:	85ce                	mv	a1,s3
     60a:	00005097          	auipc	ra,0x5
     60e:	260080e7          	jalr	608(ra) # 586a <read>
    if(n > 0){
     612:	08a04b63          	bgtz	a0,6a8 <copyout+0xec>
    close(fd);
     616:	8526                	mv	a0,s1
     618:	00005097          	auipc	ra,0x5
     61c:	262080e7          	jalr	610(ra) # 587a <close>
    if(pipe(fds) < 0){
     620:	fa840513          	addi	a0,s0,-88
     624:	00005097          	auipc	ra,0x5
     628:	23e080e7          	jalr	574(ra) # 5862 <pipe>
     62c:	08054d63          	bltz	a0,6c6 <copyout+0x10a>
    n = write(fds[1], "x", 1);
     630:	4605                	li	a2,1
     632:	85d6                	mv	a1,s5
     634:	fac42503          	lw	a0,-84(s0)
     638:	00005097          	auipc	ra,0x5
     63c:	23a080e7          	jalr	570(ra) # 5872 <write>
    if(n != 1){
     640:	4785                	li	a5,1
     642:	08f51f63          	bne	a0,a5,6e0 <copyout+0x124>
    n = read(fds[0], (void*)addr, 8192);
     646:	6609                	lui	a2,0x2
     648:	85ce                	mv	a1,s3
     64a:	fa842503          	lw	a0,-88(s0)
     64e:	00005097          	auipc	ra,0x5
     652:	21c080e7          	jalr	540(ra) # 586a <read>
    if(n > 0){
     656:	0aa04263          	bgtz	a0,6fa <copyout+0x13e>
    close(fds[0]);
     65a:	fa842503          	lw	a0,-88(s0)
     65e:	00005097          	auipc	ra,0x5
     662:	21c080e7          	jalr	540(ra) # 587a <close>
    close(fds[1]);
     666:	fac42503          	lw	a0,-84(s0)
     66a:	00005097          	auipc	ra,0x5
     66e:	210080e7          	jalr	528(ra) # 587a <close>
  for(int ai = 0; ai < 2; ai++){
     672:	0921                	addi	s2,s2,8
     674:	fc040793          	addi	a5,s0,-64
     678:	f6f91ce3          	bne	s2,a5,5f0 <copyout+0x34>
}
     67c:	60e6                	ld	ra,88(sp)
     67e:	6446                	ld	s0,80(sp)
     680:	64a6                	ld	s1,72(sp)
     682:	6906                	ld	s2,64(sp)
     684:	79e2                	ld	s3,56(sp)
     686:	7a42                	ld	s4,48(sp)
     688:	7aa2                	ld	s5,40(sp)
     68a:	6125                	addi	sp,sp,96
     68c:	8082                	ret
      printf("open(README) failed\n");
     68e:	00006517          	auipc	a0,0x6
     692:	c7250513          	addi	a0,a0,-910 # 6300 <malloc+0x660>
     696:	00005097          	auipc	ra,0x5
     69a:	54c080e7          	jalr	1356(ra) # 5be2 <printf>
      exit(1);
     69e:	4505                	li	a0,1
     6a0:	00005097          	auipc	ra,0x5
     6a4:	1b2080e7          	jalr	434(ra) # 5852 <exit>
      printf("read(fd, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     6a8:	862a                	mv	a2,a0
     6aa:	85ce                	mv	a1,s3
     6ac:	00006517          	auipc	a0,0x6
     6b0:	c6c50513          	addi	a0,a0,-916 # 6318 <malloc+0x678>
     6b4:	00005097          	auipc	ra,0x5
     6b8:	52e080e7          	jalr	1326(ra) # 5be2 <printf>
      exit(1);
     6bc:	4505                	li	a0,1
     6be:	00005097          	auipc	ra,0x5
     6c2:	194080e7          	jalr	404(ra) # 5852 <exit>
      printf("pipe() failed\n");
     6c6:	00006517          	auipc	a0,0x6
     6ca:	bf250513          	addi	a0,a0,-1038 # 62b8 <malloc+0x618>
     6ce:	00005097          	auipc	ra,0x5
     6d2:	514080e7          	jalr	1300(ra) # 5be2 <printf>
      exit(1);
     6d6:	4505                	li	a0,1
     6d8:	00005097          	auipc	ra,0x5
     6dc:	17a080e7          	jalr	378(ra) # 5852 <exit>
      printf("pipe write failed\n");
     6e0:	00006517          	auipc	a0,0x6
     6e4:	c6850513          	addi	a0,a0,-920 # 6348 <malloc+0x6a8>
     6e8:	00005097          	auipc	ra,0x5
     6ec:	4fa080e7          	jalr	1274(ra) # 5be2 <printf>
      exit(1);
     6f0:	4505                	li	a0,1
     6f2:	00005097          	auipc	ra,0x5
     6f6:	160080e7          	jalr	352(ra) # 5852 <exit>
      printf("read(pipe, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     6fa:	862a                	mv	a2,a0
     6fc:	85ce                	mv	a1,s3
     6fe:	00006517          	auipc	a0,0x6
     702:	c6250513          	addi	a0,a0,-926 # 6360 <malloc+0x6c0>
     706:	00005097          	auipc	ra,0x5
     70a:	4dc080e7          	jalr	1244(ra) # 5be2 <printf>
      exit(1);
     70e:	4505                	li	a0,1
     710:	00005097          	auipc	ra,0x5
     714:	142080e7          	jalr	322(ra) # 5852 <exit>

0000000000000718 <truncate1>:
{
     718:	711d                	addi	sp,sp,-96
     71a:	ec86                	sd	ra,88(sp)
     71c:	e8a2                	sd	s0,80(sp)
     71e:	e4a6                	sd	s1,72(sp)
     720:	e0ca                	sd	s2,64(sp)
     722:	fc4e                	sd	s3,56(sp)
     724:	f852                	sd	s4,48(sp)
     726:	f456                	sd	s5,40(sp)
     728:	1080                	addi	s0,sp,96
     72a:	8aaa                	mv	s5,a0
  unlink("truncfile");
     72c:	00006517          	auipc	a0,0x6
     730:	a5c50513          	addi	a0,a0,-1444 # 6188 <malloc+0x4e8>
     734:	00005097          	auipc	ra,0x5
     738:	16e080e7          	jalr	366(ra) # 58a2 <unlink>
  int fd1 = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
     73c:	60100593          	li	a1,1537
     740:	00006517          	auipc	a0,0x6
     744:	a4850513          	addi	a0,a0,-1464 # 6188 <malloc+0x4e8>
     748:	00005097          	auipc	ra,0x5
     74c:	14a080e7          	jalr	330(ra) # 5892 <open>
     750:	84aa                	mv	s1,a0
  write(fd1, "abcd", 4);
     752:	4611                	li	a2,4
     754:	00006597          	auipc	a1,0x6
     758:	a4458593          	addi	a1,a1,-1468 # 6198 <malloc+0x4f8>
     75c:	00005097          	auipc	ra,0x5
     760:	116080e7          	jalr	278(ra) # 5872 <write>
  close(fd1);
     764:	8526                	mv	a0,s1
     766:	00005097          	auipc	ra,0x5
     76a:	114080e7          	jalr	276(ra) # 587a <close>
  int fd2 = open("truncfile", O_RDONLY);
     76e:	4581                	li	a1,0
     770:	00006517          	auipc	a0,0x6
     774:	a1850513          	addi	a0,a0,-1512 # 6188 <malloc+0x4e8>
     778:	00005097          	auipc	ra,0x5
     77c:	11a080e7          	jalr	282(ra) # 5892 <open>
     780:	84aa                	mv	s1,a0
  int n = read(fd2, buf, sizeof(buf));
     782:	02000613          	li	a2,32
     786:	fa040593          	addi	a1,s0,-96
     78a:	00005097          	auipc	ra,0x5
     78e:	0e0080e7          	jalr	224(ra) # 586a <read>
  if(n != 4){
     792:	4791                	li	a5,4
     794:	0cf51e63          	bne	a0,a5,870 <truncate1+0x158>
  fd1 = open("truncfile", O_WRONLY|O_TRUNC);
     798:	40100593          	li	a1,1025
     79c:	00006517          	auipc	a0,0x6
     7a0:	9ec50513          	addi	a0,a0,-1556 # 6188 <malloc+0x4e8>
     7a4:	00005097          	auipc	ra,0x5
     7a8:	0ee080e7          	jalr	238(ra) # 5892 <open>
     7ac:	89aa                	mv	s3,a0
  int fd3 = open("truncfile", O_RDONLY);
     7ae:	4581                	li	a1,0
     7b0:	00006517          	auipc	a0,0x6
     7b4:	9d850513          	addi	a0,a0,-1576 # 6188 <malloc+0x4e8>
     7b8:	00005097          	auipc	ra,0x5
     7bc:	0da080e7          	jalr	218(ra) # 5892 <open>
     7c0:	892a                	mv	s2,a0
  n = read(fd3, buf, sizeof(buf));
     7c2:	02000613          	li	a2,32
     7c6:	fa040593          	addi	a1,s0,-96
     7ca:	00005097          	auipc	ra,0x5
     7ce:	0a0080e7          	jalr	160(ra) # 586a <read>
     7d2:	8a2a                	mv	s4,a0
  if(n != 0){
     7d4:	ed4d                	bnez	a0,88e <truncate1+0x176>
  n = read(fd2, buf, sizeof(buf));
     7d6:	02000613          	li	a2,32
     7da:	fa040593          	addi	a1,s0,-96
     7de:	8526                	mv	a0,s1
     7e0:	00005097          	auipc	ra,0x5
     7e4:	08a080e7          	jalr	138(ra) # 586a <read>
     7e8:	8a2a                	mv	s4,a0
  if(n != 0){
     7ea:	e971                	bnez	a0,8be <truncate1+0x1a6>
  write(fd1, "abcdef", 6);
     7ec:	4619                	li	a2,6
     7ee:	00006597          	auipc	a1,0x6
     7f2:	c0258593          	addi	a1,a1,-1022 # 63f0 <malloc+0x750>
     7f6:	854e                	mv	a0,s3
     7f8:	00005097          	auipc	ra,0x5
     7fc:	07a080e7          	jalr	122(ra) # 5872 <write>
  n = read(fd3, buf, sizeof(buf));
     800:	02000613          	li	a2,32
     804:	fa040593          	addi	a1,s0,-96
     808:	854a                	mv	a0,s2
     80a:	00005097          	auipc	ra,0x5
     80e:	060080e7          	jalr	96(ra) # 586a <read>
  if(n != 6){
     812:	4799                	li	a5,6
     814:	0cf51d63          	bne	a0,a5,8ee <truncate1+0x1d6>
  n = read(fd2, buf, sizeof(buf));
     818:	02000613          	li	a2,32
     81c:	fa040593          	addi	a1,s0,-96
     820:	8526                	mv	a0,s1
     822:	00005097          	auipc	ra,0x5
     826:	048080e7          	jalr	72(ra) # 586a <read>
  if(n != 2){
     82a:	4789                	li	a5,2
     82c:	0ef51063          	bne	a0,a5,90c <truncate1+0x1f4>
  unlink("truncfile");
     830:	00006517          	auipc	a0,0x6
     834:	95850513          	addi	a0,a0,-1704 # 6188 <malloc+0x4e8>
     838:	00005097          	auipc	ra,0x5
     83c:	06a080e7          	jalr	106(ra) # 58a2 <unlink>
  close(fd1);
     840:	854e                	mv	a0,s3
     842:	00005097          	auipc	ra,0x5
     846:	038080e7          	jalr	56(ra) # 587a <close>
  close(fd2);
     84a:	8526                	mv	a0,s1
     84c:	00005097          	auipc	ra,0x5
     850:	02e080e7          	jalr	46(ra) # 587a <close>
  close(fd3);
     854:	854a                	mv	a0,s2
     856:	00005097          	auipc	ra,0x5
     85a:	024080e7          	jalr	36(ra) # 587a <close>
}
     85e:	60e6                	ld	ra,88(sp)
     860:	6446                	ld	s0,80(sp)
     862:	64a6                	ld	s1,72(sp)
     864:	6906                	ld	s2,64(sp)
     866:	79e2                	ld	s3,56(sp)
     868:	7a42                	ld	s4,48(sp)
     86a:	7aa2                	ld	s5,40(sp)
     86c:	6125                	addi	sp,sp,96
     86e:	8082                	ret
    printf("%s: read %d bytes, wanted 4\n", s, n);
     870:	862a                	mv	a2,a0
     872:	85d6                	mv	a1,s5
     874:	00006517          	auipc	a0,0x6
     878:	b1c50513          	addi	a0,a0,-1252 # 6390 <malloc+0x6f0>
     87c:	00005097          	auipc	ra,0x5
     880:	366080e7          	jalr	870(ra) # 5be2 <printf>
    exit(1);
     884:	4505                	li	a0,1
     886:	00005097          	auipc	ra,0x5
     88a:	fcc080e7          	jalr	-52(ra) # 5852 <exit>
    printf("aaa fd3=%d\n", fd3);
     88e:	85ca                	mv	a1,s2
     890:	00006517          	auipc	a0,0x6
     894:	b2050513          	addi	a0,a0,-1248 # 63b0 <malloc+0x710>
     898:	00005097          	auipc	ra,0x5
     89c:	34a080e7          	jalr	842(ra) # 5be2 <printf>
    printf("%s: read %d bytes, wanted 0\n", s, n);
     8a0:	8652                	mv	a2,s4
     8a2:	85d6                	mv	a1,s5
     8a4:	00006517          	auipc	a0,0x6
     8a8:	b1c50513          	addi	a0,a0,-1252 # 63c0 <malloc+0x720>
     8ac:	00005097          	auipc	ra,0x5
     8b0:	336080e7          	jalr	822(ra) # 5be2 <printf>
    exit(1);
     8b4:	4505                	li	a0,1
     8b6:	00005097          	auipc	ra,0x5
     8ba:	f9c080e7          	jalr	-100(ra) # 5852 <exit>
    printf("bbb fd2=%d\n", fd2);
     8be:	85a6                	mv	a1,s1
     8c0:	00006517          	auipc	a0,0x6
     8c4:	b2050513          	addi	a0,a0,-1248 # 63e0 <malloc+0x740>
     8c8:	00005097          	auipc	ra,0x5
     8cc:	31a080e7          	jalr	794(ra) # 5be2 <printf>
    printf("%s: read %d bytes, wanted 0\n", s, n);
     8d0:	8652                	mv	a2,s4
     8d2:	85d6                	mv	a1,s5
     8d4:	00006517          	auipc	a0,0x6
     8d8:	aec50513          	addi	a0,a0,-1300 # 63c0 <malloc+0x720>
     8dc:	00005097          	auipc	ra,0x5
     8e0:	306080e7          	jalr	774(ra) # 5be2 <printf>
    exit(1);
     8e4:	4505                	li	a0,1
     8e6:	00005097          	auipc	ra,0x5
     8ea:	f6c080e7          	jalr	-148(ra) # 5852 <exit>
    printf("%s: read %d bytes, wanted 6\n", s, n);
     8ee:	862a                	mv	a2,a0
     8f0:	85d6                	mv	a1,s5
     8f2:	00006517          	auipc	a0,0x6
     8f6:	b0650513          	addi	a0,a0,-1274 # 63f8 <malloc+0x758>
     8fa:	00005097          	auipc	ra,0x5
     8fe:	2e8080e7          	jalr	744(ra) # 5be2 <printf>
    exit(1);
     902:	4505                	li	a0,1
     904:	00005097          	auipc	ra,0x5
     908:	f4e080e7          	jalr	-178(ra) # 5852 <exit>
    printf("%s: read %d bytes, wanted 2\n", s, n);
     90c:	862a                	mv	a2,a0
     90e:	85d6                	mv	a1,s5
     910:	00006517          	auipc	a0,0x6
     914:	b0850513          	addi	a0,a0,-1272 # 6418 <malloc+0x778>
     918:	00005097          	auipc	ra,0x5
     91c:	2ca080e7          	jalr	714(ra) # 5be2 <printf>
    exit(1);
     920:	4505                	li	a0,1
     922:	00005097          	auipc	ra,0x5
     926:	f30080e7          	jalr	-208(ra) # 5852 <exit>

000000000000092a <writetest>:
{
     92a:	7139                	addi	sp,sp,-64
     92c:	fc06                	sd	ra,56(sp)
     92e:	f822                	sd	s0,48(sp)
     930:	f426                	sd	s1,40(sp)
     932:	f04a                	sd	s2,32(sp)
     934:	ec4e                	sd	s3,24(sp)
     936:	e852                	sd	s4,16(sp)
     938:	e456                	sd	s5,8(sp)
     93a:	e05a                	sd	s6,0(sp)
     93c:	0080                	addi	s0,sp,64
     93e:	8b2a                	mv	s6,a0
  fd = open("small", O_CREATE|O_RDWR);
     940:	20200593          	li	a1,514
     944:	00006517          	auipc	a0,0x6
     948:	af450513          	addi	a0,a0,-1292 # 6438 <malloc+0x798>
     94c:	00005097          	auipc	ra,0x5
     950:	f46080e7          	jalr	-186(ra) # 5892 <open>
  if(fd < 0){
     954:	0a054d63          	bltz	a0,a0e <writetest+0xe4>
     958:	892a                	mv	s2,a0
     95a:	4481                	li	s1,0
    if(write(fd, "aaaaaaaaaa", SZ) != SZ){
     95c:	00006997          	auipc	s3,0x6
     960:	b0498993          	addi	s3,s3,-1276 # 6460 <malloc+0x7c0>
    if(write(fd, "bbbbbbbbbb", SZ) != SZ){
     964:	00006a97          	auipc	s5,0x6
     968:	b34a8a93          	addi	s5,s5,-1228 # 6498 <malloc+0x7f8>
  for(i = 0; i < N; i++){
     96c:	06400a13          	li	s4,100
    if(write(fd, "aaaaaaaaaa", SZ) != SZ){
     970:	4629                	li	a2,10
     972:	85ce                	mv	a1,s3
     974:	854a                	mv	a0,s2
     976:	00005097          	auipc	ra,0x5
     97a:	efc080e7          	jalr	-260(ra) # 5872 <write>
     97e:	47a9                	li	a5,10
     980:	0af51563          	bne	a0,a5,a2a <writetest+0x100>
    if(write(fd, "bbbbbbbbbb", SZ) != SZ){
     984:	4629                	li	a2,10
     986:	85d6                	mv	a1,s5
     988:	854a                	mv	a0,s2
     98a:	00005097          	auipc	ra,0x5
     98e:	ee8080e7          	jalr	-280(ra) # 5872 <write>
     992:	47a9                	li	a5,10
     994:	0af51a63          	bne	a0,a5,a48 <writetest+0x11e>
  for(i = 0; i < N; i++){
     998:	2485                	addiw	s1,s1,1
     99a:	fd449be3          	bne	s1,s4,970 <writetest+0x46>
  close(fd);
     99e:	854a                	mv	a0,s2
     9a0:	00005097          	auipc	ra,0x5
     9a4:	eda080e7          	jalr	-294(ra) # 587a <close>
  fd = open("small", O_RDONLY);
     9a8:	4581                	li	a1,0
     9aa:	00006517          	auipc	a0,0x6
     9ae:	a8e50513          	addi	a0,a0,-1394 # 6438 <malloc+0x798>
     9b2:	00005097          	auipc	ra,0x5
     9b6:	ee0080e7          	jalr	-288(ra) # 5892 <open>
     9ba:	84aa                	mv	s1,a0
  if(fd < 0){
     9bc:	0a054563          	bltz	a0,a66 <writetest+0x13c>
  i = read(fd, buf, N*SZ*2);
     9c0:	7d000613          	li	a2,2000
     9c4:	0000b597          	auipc	a1,0xb
     9c8:	41458593          	addi	a1,a1,1044 # bdd8 <buf>
     9cc:	00005097          	auipc	ra,0x5
     9d0:	e9e080e7          	jalr	-354(ra) # 586a <read>
  if(i != N*SZ*2){
     9d4:	7d000793          	li	a5,2000
     9d8:	0af51563          	bne	a0,a5,a82 <writetest+0x158>
  close(fd);
     9dc:	8526                	mv	a0,s1
     9de:	00005097          	auipc	ra,0x5
     9e2:	e9c080e7          	jalr	-356(ra) # 587a <close>
  if(unlink("small") < 0){
     9e6:	00006517          	auipc	a0,0x6
     9ea:	a5250513          	addi	a0,a0,-1454 # 6438 <malloc+0x798>
     9ee:	00005097          	auipc	ra,0x5
     9f2:	eb4080e7          	jalr	-332(ra) # 58a2 <unlink>
     9f6:	0a054463          	bltz	a0,a9e <writetest+0x174>
}
     9fa:	70e2                	ld	ra,56(sp)
     9fc:	7442                	ld	s0,48(sp)
     9fe:	74a2                	ld	s1,40(sp)
     a00:	7902                	ld	s2,32(sp)
     a02:	69e2                	ld	s3,24(sp)
     a04:	6a42                	ld	s4,16(sp)
     a06:	6aa2                	ld	s5,8(sp)
     a08:	6b02                	ld	s6,0(sp)
     a0a:	6121                	addi	sp,sp,64
     a0c:	8082                	ret
    printf("%s: error: creat small failed!\n", s);
     a0e:	85da                	mv	a1,s6
     a10:	00006517          	auipc	a0,0x6
     a14:	a3050513          	addi	a0,a0,-1488 # 6440 <malloc+0x7a0>
     a18:	00005097          	auipc	ra,0x5
     a1c:	1ca080e7          	jalr	458(ra) # 5be2 <printf>
    exit(1);
     a20:	4505                	li	a0,1
     a22:	00005097          	auipc	ra,0x5
     a26:	e30080e7          	jalr	-464(ra) # 5852 <exit>
      printf("%s: error: write aa %d new file failed\n", s, i);
     a2a:	8626                	mv	a2,s1
     a2c:	85da                	mv	a1,s6
     a2e:	00006517          	auipc	a0,0x6
     a32:	a4250513          	addi	a0,a0,-1470 # 6470 <malloc+0x7d0>
     a36:	00005097          	auipc	ra,0x5
     a3a:	1ac080e7          	jalr	428(ra) # 5be2 <printf>
      exit(1);
     a3e:	4505                	li	a0,1
     a40:	00005097          	auipc	ra,0x5
     a44:	e12080e7          	jalr	-494(ra) # 5852 <exit>
      printf("%s: error: write bb %d new file failed\n", s, i);
     a48:	8626                	mv	a2,s1
     a4a:	85da                	mv	a1,s6
     a4c:	00006517          	auipc	a0,0x6
     a50:	a5c50513          	addi	a0,a0,-1444 # 64a8 <malloc+0x808>
     a54:	00005097          	auipc	ra,0x5
     a58:	18e080e7          	jalr	398(ra) # 5be2 <printf>
      exit(1);
     a5c:	4505                	li	a0,1
     a5e:	00005097          	auipc	ra,0x5
     a62:	df4080e7          	jalr	-524(ra) # 5852 <exit>
    printf("%s: error: open small failed!\n", s);
     a66:	85da                	mv	a1,s6
     a68:	00006517          	auipc	a0,0x6
     a6c:	a6850513          	addi	a0,a0,-1432 # 64d0 <malloc+0x830>
     a70:	00005097          	auipc	ra,0x5
     a74:	172080e7          	jalr	370(ra) # 5be2 <printf>
    exit(1);
     a78:	4505                	li	a0,1
     a7a:	00005097          	auipc	ra,0x5
     a7e:	dd8080e7          	jalr	-552(ra) # 5852 <exit>
    printf("%s: read failed\n", s);
     a82:	85da                	mv	a1,s6
     a84:	00006517          	auipc	a0,0x6
     a88:	a6c50513          	addi	a0,a0,-1428 # 64f0 <malloc+0x850>
     a8c:	00005097          	auipc	ra,0x5
     a90:	156080e7          	jalr	342(ra) # 5be2 <printf>
    exit(1);
     a94:	4505                	li	a0,1
     a96:	00005097          	auipc	ra,0x5
     a9a:	dbc080e7          	jalr	-580(ra) # 5852 <exit>
    printf("%s: unlink small failed\n", s);
     a9e:	85da                	mv	a1,s6
     aa0:	00006517          	auipc	a0,0x6
     aa4:	a6850513          	addi	a0,a0,-1432 # 6508 <malloc+0x868>
     aa8:	00005097          	auipc	ra,0x5
     aac:	13a080e7          	jalr	314(ra) # 5be2 <printf>
    exit(1);
     ab0:	4505                	li	a0,1
     ab2:	00005097          	auipc	ra,0x5
     ab6:	da0080e7          	jalr	-608(ra) # 5852 <exit>

0000000000000aba <writebig>:
{
     aba:	7139                	addi	sp,sp,-64
     abc:	fc06                	sd	ra,56(sp)
     abe:	f822                	sd	s0,48(sp)
     ac0:	f426                	sd	s1,40(sp)
     ac2:	f04a                	sd	s2,32(sp)
     ac4:	ec4e                	sd	s3,24(sp)
     ac6:	e852                	sd	s4,16(sp)
     ac8:	e456                	sd	s5,8(sp)
     aca:	0080                	addi	s0,sp,64
     acc:	8aaa                	mv	s5,a0
  fd = open("big", O_CREATE|O_RDWR);
     ace:	20200593          	li	a1,514
     ad2:	00006517          	auipc	a0,0x6
     ad6:	a5650513          	addi	a0,a0,-1450 # 6528 <malloc+0x888>
     ada:	00005097          	auipc	ra,0x5
     ade:	db8080e7          	jalr	-584(ra) # 5892 <open>
     ae2:	89aa                	mv	s3,a0
  for(i = 0; i < MAXFILE; i++){
     ae4:	4481                	li	s1,0
    ((int*)buf)[0] = i;
     ae6:	0000b917          	auipc	s2,0xb
     aea:	2f290913          	addi	s2,s2,754 # bdd8 <buf>
  for(i = 0; i < MAXFILE; i++){
     aee:	10c00a13          	li	s4,268
  if(fd < 0){
     af2:	06054c63          	bltz	a0,b6a <writebig+0xb0>
    ((int*)buf)[0] = i;
     af6:	00992023          	sw	s1,0(s2)
    if(write(fd, buf, BSIZE) != BSIZE){
     afa:	40000613          	li	a2,1024
     afe:	85ca                	mv	a1,s2
     b00:	854e                	mv	a0,s3
     b02:	00005097          	auipc	ra,0x5
     b06:	d70080e7          	jalr	-656(ra) # 5872 <write>
     b0a:	40000793          	li	a5,1024
     b0e:	06f51c63          	bne	a0,a5,b86 <writebig+0xcc>
  for(i = 0; i < MAXFILE; i++){
     b12:	2485                	addiw	s1,s1,1
     b14:	ff4491e3          	bne	s1,s4,af6 <writebig+0x3c>
  close(fd);
     b18:	854e                	mv	a0,s3
     b1a:	00005097          	auipc	ra,0x5
     b1e:	d60080e7          	jalr	-672(ra) # 587a <close>
  fd = open("big", O_RDONLY);
     b22:	4581                	li	a1,0
     b24:	00006517          	auipc	a0,0x6
     b28:	a0450513          	addi	a0,a0,-1532 # 6528 <malloc+0x888>
     b2c:	00005097          	auipc	ra,0x5
     b30:	d66080e7          	jalr	-666(ra) # 5892 <open>
     b34:	89aa                	mv	s3,a0
  n = 0;
     b36:	4481                	li	s1,0
    i = read(fd, buf, BSIZE);
     b38:	0000b917          	auipc	s2,0xb
     b3c:	2a090913          	addi	s2,s2,672 # bdd8 <buf>
  if(fd < 0){
     b40:	06054263          	bltz	a0,ba4 <writebig+0xea>
    i = read(fd, buf, BSIZE);
     b44:	40000613          	li	a2,1024
     b48:	85ca                	mv	a1,s2
     b4a:	854e                	mv	a0,s3
     b4c:	00005097          	auipc	ra,0x5
     b50:	d1e080e7          	jalr	-738(ra) # 586a <read>
    if(i == 0){
     b54:	c535                	beqz	a0,bc0 <writebig+0x106>
    } else if(i != BSIZE){
     b56:	40000793          	li	a5,1024
     b5a:	0af51f63          	bne	a0,a5,c18 <writebig+0x15e>
    if(((int*)buf)[0] != n){
     b5e:	00092683          	lw	a3,0(s2)
     b62:	0c969a63          	bne	a3,s1,c36 <writebig+0x17c>
    n++;
     b66:	2485                	addiw	s1,s1,1
    i = read(fd, buf, BSIZE);
     b68:	bff1                	j	b44 <writebig+0x8a>
    printf("%s: error: creat big failed!\n", s);
     b6a:	85d6                	mv	a1,s5
     b6c:	00006517          	auipc	a0,0x6
     b70:	9c450513          	addi	a0,a0,-1596 # 6530 <malloc+0x890>
     b74:	00005097          	auipc	ra,0x5
     b78:	06e080e7          	jalr	110(ra) # 5be2 <printf>
    exit(1);
     b7c:	4505                	li	a0,1
     b7e:	00005097          	auipc	ra,0x5
     b82:	cd4080e7          	jalr	-812(ra) # 5852 <exit>
      printf("%s: error: write big file failed\n", s, i);
     b86:	8626                	mv	a2,s1
     b88:	85d6                	mv	a1,s5
     b8a:	00006517          	auipc	a0,0x6
     b8e:	9c650513          	addi	a0,a0,-1594 # 6550 <malloc+0x8b0>
     b92:	00005097          	auipc	ra,0x5
     b96:	050080e7          	jalr	80(ra) # 5be2 <printf>
      exit(1);
     b9a:	4505                	li	a0,1
     b9c:	00005097          	auipc	ra,0x5
     ba0:	cb6080e7          	jalr	-842(ra) # 5852 <exit>
    printf("%s: error: open big failed!\n", s);
     ba4:	85d6                	mv	a1,s5
     ba6:	00006517          	auipc	a0,0x6
     baa:	9d250513          	addi	a0,a0,-1582 # 6578 <malloc+0x8d8>
     bae:	00005097          	auipc	ra,0x5
     bb2:	034080e7          	jalr	52(ra) # 5be2 <printf>
    exit(1);
     bb6:	4505                	li	a0,1
     bb8:	00005097          	auipc	ra,0x5
     bbc:	c9a080e7          	jalr	-870(ra) # 5852 <exit>
      if(n == MAXFILE - 1){
     bc0:	10b00793          	li	a5,267
     bc4:	02f48a63          	beq	s1,a5,bf8 <writebig+0x13e>
  close(fd);
     bc8:	854e                	mv	a0,s3
     bca:	00005097          	auipc	ra,0x5
     bce:	cb0080e7          	jalr	-848(ra) # 587a <close>
  if(unlink("big") < 0){
     bd2:	00006517          	auipc	a0,0x6
     bd6:	95650513          	addi	a0,a0,-1706 # 6528 <malloc+0x888>
     bda:	00005097          	auipc	ra,0x5
     bde:	cc8080e7          	jalr	-824(ra) # 58a2 <unlink>
     be2:	06054963          	bltz	a0,c54 <writebig+0x19a>
}
     be6:	70e2                	ld	ra,56(sp)
     be8:	7442                	ld	s0,48(sp)
     bea:	74a2                	ld	s1,40(sp)
     bec:	7902                	ld	s2,32(sp)
     bee:	69e2                	ld	s3,24(sp)
     bf0:	6a42                	ld	s4,16(sp)
     bf2:	6aa2                	ld	s5,8(sp)
     bf4:	6121                	addi	sp,sp,64
     bf6:	8082                	ret
        printf("%s: read only %d blocks from big", s, n);
     bf8:	10b00613          	li	a2,267
     bfc:	85d6                	mv	a1,s5
     bfe:	00006517          	auipc	a0,0x6
     c02:	99a50513          	addi	a0,a0,-1638 # 6598 <malloc+0x8f8>
     c06:	00005097          	auipc	ra,0x5
     c0a:	fdc080e7          	jalr	-36(ra) # 5be2 <printf>
        exit(1);
     c0e:	4505                	li	a0,1
     c10:	00005097          	auipc	ra,0x5
     c14:	c42080e7          	jalr	-958(ra) # 5852 <exit>
      printf("%s: read failed %d\n", s, i);
     c18:	862a                	mv	a2,a0
     c1a:	85d6                	mv	a1,s5
     c1c:	00006517          	auipc	a0,0x6
     c20:	9a450513          	addi	a0,a0,-1628 # 65c0 <malloc+0x920>
     c24:	00005097          	auipc	ra,0x5
     c28:	fbe080e7          	jalr	-66(ra) # 5be2 <printf>
      exit(1);
     c2c:	4505                	li	a0,1
     c2e:	00005097          	auipc	ra,0x5
     c32:	c24080e7          	jalr	-988(ra) # 5852 <exit>
      printf("%s: read content of block %d is %d\n", s,
     c36:	8626                	mv	a2,s1
     c38:	85d6                	mv	a1,s5
     c3a:	00006517          	auipc	a0,0x6
     c3e:	99e50513          	addi	a0,a0,-1634 # 65d8 <malloc+0x938>
     c42:	00005097          	auipc	ra,0x5
     c46:	fa0080e7          	jalr	-96(ra) # 5be2 <printf>
      exit(1);
     c4a:	4505                	li	a0,1
     c4c:	00005097          	auipc	ra,0x5
     c50:	c06080e7          	jalr	-1018(ra) # 5852 <exit>
    printf("%s: unlink big failed\n", s);
     c54:	85d6                	mv	a1,s5
     c56:	00006517          	auipc	a0,0x6
     c5a:	9aa50513          	addi	a0,a0,-1622 # 6600 <malloc+0x960>
     c5e:	00005097          	auipc	ra,0x5
     c62:	f84080e7          	jalr	-124(ra) # 5be2 <printf>
    exit(1);
     c66:	4505                	li	a0,1
     c68:	00005097          	auipc	ra,0x5
     c6c:	bea080e7          	jalr	-1046(ra) # 5852 <exit>

0000000000000c70 <unlinkread>:
{
     c70:	7179                	addi	sp,sp,-48
     c72:	f406                	sd	ra,40(sp)
     c74:	f022                	sd	s0,32(sp)
     c76:	ec26                	sd	s1,24(sp)
     c78:	e84a                	sd	s2,16(sp)
     c7a:	e44e                	sd	s3,8(sp)
     c7c:	1800                	addi	s0,sp,48
     c7e:	89aa                	mv	s3,a0
  fd = open("unlinkread", O_CREATE | O_RDWR);
     c80:	20200593          	li	a1,514
     c84:	00005517          	auipc	a0,0x5
     c88:	28450513          	addi	a0,a0,644 # 5f08 <malloc+0x268>
     c8c:	00005097          	auipc	ra,0x5
     c90:	c06080e7          	jalr	-1018(ra) # 5892 <open>
  if(fd < 0){
     c94:	0e054563          	bltz	a0,d7e <unlinkread+0x10e>
     c98:	84aa                	mv	s1,a0
  write(fd, "hello", SZ);
     c9a:	4615                	li	a2,5
     c9c:	00006597          	auipc	a1,0x6
     ca0:	99c58593          	addi	a1,a1,-1636 # 6638 <malloc+0x998>
     ca4:	00005097          	auipc	ra,0x5
     ca8:	bce080e7          	jalr	-1074(ra) # 5872 <write>
  close(fd);
     cac:	8526                	mv	a0,s1
     cae:	00005097          	auipc	ra,0x5
     cb2:	bcc080e7          	jalr	-1076(ra) # 587a <close>
  fd = open("unlinkread", O_RDWR);
     cb6:	4589                	li	a1,2
     cb8:	00005517          	auipc	a0,0x5
     cbc:	25050513          	addi	a0,a0,592 # 5f08 <malloc+0x268>
     cc0:	00005097          	auipc	ra,0x5
     cc4:	bd2080e7          	jalr	-1070(ra) # 5892 <open>
     cc8:	84aa                	mv	s1,a0
  if(fd < 0){
     cca:	0c054863          	bltz	a0,d9a <unlinkread+0x12a>
  if(unlink("unlinkread") != 0){
     cce:	00005517          	auipc	a0,0x5
     cd2:	23a50513          	addi	a0,a0,570 # 5f08 <malloc+0x268>
     cd6:	00005097          	auipc	ra,0x5
     cda:	bcc080e7          	jalr	-1076(ra) # 58a2 <unlink>
     cde:	ed61                	bnez	a0,db6 <unlinkread+0x146>
  fd1 = open("unlinkread", O_CREATE | O_RDWR);
     ce0:	20200593          	li	a1,514
     ce4:	00005517          	auipc	a0,0x5
     ce8:	22450513          	addi	a0,a0,548 # 5f08 <malloc+0x268>
     cec:	00005097          	auipc	ra,0x5
     cf0:	ba6080e7          	jalr	-1114(ra) # 5892 <open>
     cf4:	892a                	mv	s2,a0
  write(fd1, "yyy", 3);
     cf6:	460d                	li	a2,3
     cf8:	00006597          	auipc	a1,0x6
     cfc:	98858593          	addi	a1,a1,-1656 # 6680 <malloc+0x9e0>
     d00:	00005097          	auipc	ra,0x5
     d04:	b72080e7          	jalr	-1166(ra) # 5872 <write>
  close(fd1);
     d08:	854a                	mv	a0,s2
     d0a:	00005097          	auipc	ra,0x5
     d0e:	b70080e7          	jalr	-1168(ra) # 587a <close>
  if(read(fd, buf, sizeof(buf)) != SZ){
     d12:	660d                	lui	a2,0x3
     d14:	0000b597          	auipc	a1,0xb
     d18:	0c458593          	addi	a1,a1,196 # bdd8 <buf>
     d1c:	8526                	mv	a0,s1
     d1e:	00005097          	auipc	ra,0x5
     d22:	b4c080e7          	jalr	-1204(ra) # 586a <read>
     d26:	4795                	li	a5,5
     d28:	0af51563          	bne	a0,a5,dd2 <unlinkread+0x162>
  if(buf[0] != 'h'){
     d2c:	0000b717          	auipc	a4,0xb
     d30:	0ac74703          	lbu	a4,172(a4) # bdd8 <buf>
     d34:	06800793          	li	a5,104
     d38:	0af71b63          	bne	a4,a5,dee <unlinkread+0x17e>
  if(write(fd, buf, 10) != 10){
     d3c:	4629                	li	a2,10
     d3e:	0000b597          	auipc	a1,0xb
     d42:	09a58593          	addi	a1,a1,154 # bdd8 <buf>
     d46:	8526                	mv	a0,s1
     d48:	00005097          	auipc	ra,0x5
     d4c:	b2a080e7          	jalr	-1238(ra) # 5872 <write>
     d50:	47a9                	li	a5,10
     d52:	0af51c63          	bne	a0,a5,e0a <unlinkread+0x19a>
  close(fd);
     d56:	8526                	mv	a0,s1
     d58:	00005097          	auipc	ra,0x5
     d5c:	b22080e7          	jalr	-1246(ra) # 587a <close>
  unlink("unlinkread");
     d60:	00005517          	auipc	a0,0x5
     d64:	1a850513          	addi	a0,a0,424 # 5f08 <malloc+0x268>
     d68:	00005097          	auipc	ra,0x5
     d6c:	b3a080e7          	jalr	-1222(ra) # 58a2 <unlink>
}
     d70:	70a2                	ld	ra,40(sp)
     d72:	7402                	ld	s0,32(sp)
     d74:	64e2                	ld	s1,24(sp)
     d76:	6942                	ld	s2,16(sp)
     d78:	69a2                	ld	s3,8(sp)
     d7a:	6145                	addi	sp,sp,48
     d7c:	8082                	ret
    printf("%s: create unlinkread failed\n", s);
     d7e:	85ce                	mv	a1,s3
     d80:	00006517          	auipc	a0,0x6
     d84:	89850513          	addi	a0,a0,-1896 # 6618 <malloc+0x978>
     d88:	00005097          	auipc	ra,0x5
     d8c:	e5a080e7          	jalr	-422(ra) # 5be2 <printf>
    exit(1);
     d90:	4505                	li	a0,1
     d92:	00005097          	auipc	ra,0x5
     d96:	ac0080e7          	jalr	-1344(ra) # 5852 <exit>
    printf("%s: open unlinkread failed\n", s);
     d9a:	85ce                	mv	a1,s3
     d9c:	00006517          	auipc	a0,0x6
     da0:	8a450513          	addi	a0,a0,-1884 # 6640 <malloc+0x9a0>
     da4:	00005097          	auipc	ra,0x5
     da8:	e3e080e7          	jalr	-450(ra) # 5be2 <printf>
    exit(1);
     dac:	4505                	li	a0,1
     dae:	00005097          	auipc	ra,0x5
     db2:	aa4080e7          	jalr	-1372(ra) # 5852 <exit>
    printf("%s: unlink unlinkread failed\n", s);
     db6:	85ce                	mv	a1,s3
     db8:	00006517          	auipc	a0,0x6
     dbc:	8a850513          	addi	a0,a0,-1880 # 6660 <malloc+0x9c0>
     dc0:	00005097          	auipc	ra,0x5
     dc4:	e22080e7          	jalr	-478(ra) # 5be2 <printf>
    exit(1);
     dc8:	4505                	li	a0,1
     dca:	00005097          	auipc	ra,0x5
     dce:	a88080e7          	jalr	-1400(ra) # 5852 <exit>
    printf("%s: unlinkread read failed", s);
     dd2:	85ce                	mv	a1,s3
     dd4:	00006517          	auipc	a0,0x6
     dd8:	8b450513          	addi	a0,a0,-1868 # 6688 <malloc+0x9e8>
     ddc:	00005097          	auipc	ra,0x5
     de0:	e06080e7          	jalr	-506(ra) # 5be2 <printf>
    exit(1);
     de4:	4505                	li	a0,1
     de6:	00005097          	auipc	ra,0x5
     dea:	a6c080e7          	jalr	-1428(ra) # 5852 <exit>
    printf("%s: unlinkread wrong data\n", s);
     dee:	85ce                	mv	a1,s3
     df0:	00006517          	auipc	a0,0x6
     df4:	8b850513          	addi	a0,a0,-1864 # 66a8 <malloc+0xa08>
     df8:	00005097          	auipc	ra,0x5
     dfc:	dea080e7          	jalr	-534(ra) # 5be2 <printf>
    exit(1);
     e00:	4505                	li	a0,1
     e02:	00005097          	auipc	ra,0x5
     e06:	a50080e7          	jalr	-1456(ra) # 5852 <exit>
    printf("%s: unlinkread write failed\n", s);
     e0a:	85ce                	mv	a1,s3
     e0c:	00006517          	auipc	a0,0x6
     e10:	8bc50513          	addi	a0,a0,-1860 # 66c8 <malloc+0xa28>
     e14:	00005097          	auipc	ra,0x5
     e18:	dce080e7          	jalr	-562(ra) # 5be2 <printf>
    exit(1);
     e1c:	4505                	li	a0,1
     e1e:	00005097          	auipc	ra,0x5
     e22:	a34080e7          	jalr	-1484(ra) # 5852 <exit>

0000000000000e26 <linktest>:
{
     e26:	1101                	addi	sp,sp,-32
     e28:	ec06                	sd	ra,24(sp)
     e2a:	e822                	sd	s0,16(sp)
     e2c:	e426                	sd	s1,8(sp)
     e2e:	e04a                	sd	s2,0(sp)
     e30:	1000                	addi	s0,sp,32
     e32:	892a                	mv	s2,a0
  unlink("lf1");
     e34:	00006517          	auipc	a0,0x6
     e38:	8b450513          	addi	a0,a0,-1868 # 66e8 <malloc+0xa48>
     e3c:	00005097          	auipc	ra,0x5
     e40:	a66080e7          	jalr	-1434(ra) # 58a2 <unlink>
  unlink("lf2");
     e44:	00006517          	auipc	a0,0x6
     e48:	8ac50513          	addi	a0,a0,-1876 # 66f0 <malloc+0xa50>
     e4c:	00005097          	auipc	ra,0x5
     e50:	a56080e7          	jalr	-1450(ra) # 58a2 <unlink>
  fd = open("lf1", O_CREATE|O_RDWR);
     e54:	20200593          	li	a1,514
     e58:	00006517          	auipc	a0,0x6
     e5c:	89050513          	addi	a0,a0,-1904 # 66e8 <malloc+0xa48>
     e60:	00005097          	auipc	ra,0x5
     e64:	a32080e7          	jalr	-1486(ra) # 5892 <open>
  if(fd < 0){
     e68:	10054763          	bltz	a0,f76 <linktest+0x150>
     e6c:	84aa                	mv	s1,a0
  if(write(fd, "hello", SZ) != SZ){
     e6e:	4615                	li	a2,5
     e70:	00005597          	auipc	a1,0x5
     e74:	7c858593          	addi	a1,a1,1992 # 6638 <malloc+0x998>
     e78:	00005097          	auipc	ra,0x5
     e7c:	9fa080e7          	jalr	-1542(ra) # 5872 <write>
     e80:	4795                	li	a5,5
     e82:	10f51863          	bne	a0,a5,f92 <linktest+0x16c>
  close(fd);
     e86:	8526                	mv	a0,s1
     e88:	00005097          	auipc	ra,0x5
     e8c:	9f2080e7          	jalr	-1550(ra) # 587a <close>
  if(link("lf1", "lf2") < 0){
     e90:	00006597          	auipc	a1,0x6
     e94:	86058593          	addi	a1,a1,-1952 # 66f0 <malloc+0xa50>
     e98:	00006517          	auipc	a0,0x6
     e9c:	85050513          	addi	a0,a0,-1968 # 66e8 <malloc+0xa48>
     ea0:	00005097          	auipc	ra,0x5
     ea4:	a12080e7          	jalr	-1518(ra) # 58b2 <link>
     ea8:	10054363          	bltz	a0,fae <linktest+0x188>
  unlink("lf1");
     eac:	00006517          	auipc	a0,0x6
     eb0:	83c50513          	addi	a0,a0,-1988 # 66e8 <malloc+0xa48>
     eb4:	00005097          	auipc	ra,0x5
     eb8:	9ee080e7          	jalr	-1554(ra) # 58a2 <unlink>
  if(open("lf1", 0) >= 0){
     ebc:	4581                	li	a1,0
     ebe:	00006517          	auipc	a0,0x6
     ec2:	82a50513          	addi	a0,a0,-2006 # 66e8 <malloc+0xa48>
     ec6:	00005097          	auipc	ra,0x5
     eca:	9cc080e7          	jalr	-1588(ra) # 5892 <open>
     ece:	0e055e63          	bgez	a0,fca <linktest+0x1a4>
  fd = open("lf2", 0);
     ed2:	4581                	li	a1,0
     ed4:	00006517          	auipc	a0,0x6
     ed8:	81c50513          	addi	a0,a0,-2020 # 66f0 <malloc+0xa50>
     edc:	00005097          	auipc	ra,0x5
     ee0:	9b6080e7          	jalr	-1610(ra) # 5892 <open>
     ee4:	84aa                	mv	s1,a0
  if(fd < 0){
     ee6:	10054063          	bltz	a0,fe6 <linktest+0x1c0>
  if(read(fd, buf, sizeof(buf)) != SZ){
     eea:	660d                	lui	a2,0x3
     eec:	0000b597          	auipc	a1,0xb
     ef0:	eec58593          	addi	a1,a1,-276 # bdd8 <buf>
     ef4:	00005097          	auipc	ra,0x5
     ef8:	976080e7          	jalr	-1674(ra) # 586a <read>
     efc:	4795                	li	a5,5
     efe:	10f51263          	bne	a0,a5,1002 <linktest+0x1dc>
  close(fd);
     f02:	8526                	mv	a0,s1
     f04:	00005097          	auipc	ra,0x5
     f08:	976080e7          	jalr	-1674(ra) # 587a <close>
  if(link("lf2", "lf2") >= 0){
     f0c:	00005597          	auipc	a1,0x5
     f10:	7e458593          	addi	a1,a1,2020 # 66f0 <malloc+0xa50>
     f14:	852e                	mv	a0,a1
     f16:	00005097          	auipc	ra,0x5
     f1a:	99c080e7          	jalr	-1636(ra) # 58b2 <link>
     f1e:	10055063          	bgez	a0,101e <linktest+0x1f8>
  unlink("lf2");
     f22:	00005517          	auipc	a0,0x5
     f26:	7ce50513          	addi	a0,a0,1998 # 66f0 <malloc+0xa50>
     f2a:	00005097          	auipc	ra,0x5
     f2e:	978080e7          	jalr	-1672(ra) # 58a2 <unlink>
  if(link("lf2", "lf1") >= 0){
     f32:	00005597          	auipc	a1,0x5
     f36:	7b658593          	addi	a1,a1,1974 # 66e8 <malloc+0xa48>
     f3a:	00005517          	auipc	a0,0x5
     f3e:	7b650513          	addi	a0,a0,1974 # 66f0 <malloc+0xa50>
     f42:	00005097          	auipc	ra,0x5
     f46:	970080e7          	jalr	-1680(ra) # 58b2 <link>
     f4a:	0e055863          	bgez	a0,103a <linktest+0x214>
  if(link(".", "lf1") >= 0){
     f4e:	00005597          	auipc	a1,0x5
     f52:	79a58593          	addi	a1,a1,1946 # 66e8 <malloc+0xa48>
     f56:	00006517          	auipc	a0,0x6
     f5a:	8a250513          	addi	a0,a0,-1886 # 67f8 <malloc+0xb58>
     f5e:	00005097          	auipc	ra,0x5
     f62:	954080e7          	jalr	-1708(ra) # 58b2 <link>
     f66:	0e055863          	bgez	a0,1056 <linktest+0x230>
}
     f6a:	60e2                	ld	ra,24(sp)
     f6c:	6442                	ld	s0,16(sp)
     f6e:	64a2                	ld	s1,8(sp)
     f70:	6902                	ld	s2,0(sp)
     f72:	6105                	addi	sp,sp,32
     f74:	8082                	ret
    printf("%s: create lf1 failed\n", s);
     f76:	85ca                	mv	a1,s2
     f78:	00005517          	auipc	a0,0x5
     f7c:	78050513          	addi	a0,a0,1920 # 66f8 <malloc+0xa58>
     f80:	00005097          	auipc	ra,0x5
     f84:	c62080e7          	jalr	-926(ra) # 5be2 <printf>
    exit(1);
     f88:	4505                	li	a0,1
     f8a:	00005097          	auipc	ra,0x5
     f8e:	8c8080e7          	jalr	-1848(ra) # 5852 <exit>
    printf("%s: write lf1 failed\n", s);
     f92:	85ca                	mv	a1,s2
     f94:	00005517          	auipc	a0,0x5
     f98:	77c50513          	addi	a0,a0,1916 # 6710 <malloc+0xa70>
     f9c:	00005097          	auipc	ra,0x5
     fa0:	c46080e7          	jalr	-954(ra) # 5be2 <printf>
    exit(1);
     fa4:	4505                	li	a0,1
     fa6:	00005097          	auipc	ra,0x5
     faa:	8ac080e7          	jalr	-1876(ra) # 5852 <exit>
    printf("%s: link lf1 lf2 failed\n", s);
     fae:	85ca                	mv	a1,s2
     fb0:	00005517          	auipc	a0,0x5
     fb4:	77850513          	addi	a0,a0,1912 # 6728 <malloc+0xa88>
     fb8:	00005097          	auipc	ra,0x5
     fbc:	c2a080e7          	jalr	-982(ra) # 5be2 <printf>
    exit(1);
     fc0:	4505                	li	a0,1
     fc2:	00005097          	auipc	ra,0x5
     fc6:	890080e7          	jalr	-1904(ra) # 5852 <exit>
    printf("%s: unlinked lf1 but it is still there!\n", s);
     fca:	85ca                	mv	a1,s2
     fcc:	00005517          	auipc	a0,0x5
     fd0:	77c50513          	addi	a0,a0,1916 # 6748 <malloc+0xaa8>
     fd4:	00005097          	auipc	ra,0x5
     fd8:	c0e080e7          	jalr	-1010(ra) # 5be2 <printf>
    exit(1);
     fdc:	4505                	li	a0,1
     fde:	00005097          	auipc	ra,0x5
     fe2:	874080e7          	jalr	-1932(ra) # 5852 <exit>
    printf("%s: open lf2 failed\n", s);
     fe6:	85ca                	mv	a1,s2
     fe8:	00005517          	auipc	a0,0x5
     fec:	79050513          	addi	a0,a0,1936 # 6778 <malloc+0xad8>
     ff0:	00005097          	auipc	ra,0x5
     ff4:	bf2080e7          	jalr	-1038(ra) # 5be2 <printf>
    exit(1);
     ff8:	4505                	li	a0,1
     ffa:	00005097          	auipc	ra,0x5
     ffe:	858080e7          	jalr	-1960(ra) # 5852 <exit>
    printf("%s: read lf2 failed\n", s);
    1002:	85ca                	mv	a1,s2
    1004:	00005517          	auipc	a0,0x5
    1008:	78c50513          	addi	a0,a0,1932 # 6790 <malloc+0xaf0>
    100c:	00005097          	auipc	ra,0x5
    1010:	bd6080e7          	jalr	-1066(ra) # 5be2 <printf>
    exit(1);
    1014:	4505                	li	a0,1
    1016:	00005097          	auipc	ra,0x5
    101a:	83c080e7          	jalr	-1988(ra) # 5852 <exit>
    printf("%s: link lf2 lf2 succeeded! oops\n", s);
    101e:	85ca                	mv	a1,s2
    1020:	00005517          	auipc	a0,0x5
    1024:	78850513          	addi	a0,a0,1928 # 67a8 <malloc+0xb08>
    1028:	00005097          	auipc	ra,0x5
    102c:	bba080e7          	jalr	-1094(ra) # 5be2 <printf>
    exit(1);
    1030:	4505                	li	a0,1
    1032:	00005097          	auipc	ra,0x5
    1036:	820080e7          	jalr	-2016(ra) # 5852 <exit>
    printf("%s: link non-existent succeeded! oops\n", s);
    103a:	85ca                	mv	a1,s2
    103c:	00005517          	auipc	a0,0x5
    1040:	79450513          	addi	a0,a0,1940 # 67d0 <malloc+0xb30>
    1044:	00005097          	auipc	ra,0x5
    1048:	b9e080e7          	jalr	-1122(ra) # 5be2 <printf>
    exit(1);
    104c:	4505                	li	a0,1
    104e:	00005097          	auipc	ra,0x5
    1052:	804080e7          	jalr	-2044(ra) # 5852 <exit>
    printf("%s: link . lf1 succeeded! oops\n", s);
    1056:	85ca                	mv	a1,s2
    1058:	00005517          	auipc	a0,0x5
    105c:	7a850513          	addi	a0,a0,1960 # 6800 <malloc+0xb60>
    1060:	00005097          	auipc	ra,0x5
    1064:	b82080e7          	jalr	-1150(ra) # 5be2 <printf>
    exit(1);
    1068:	4505                	li	a0,1
    106a:	00004097          	auipc	ra,0x4
    106e:	7e8080e7          	jalr	2024(ra) # 5852 <exit>

0000000000001072 <bigdir>:
{
    1072:	715d                	addi	sp,sp,-80
    1074:	e486                	sd	ra,72(sp)
    1076:	e0a2                	sd	s0,64(sp)
    1078:	fc26                	sd	s1,56(sp)
    107a:	f84a                	sd	s2,48(sp)
    107c:	f44e                	sd	s3,40(sp)
    107e:	f052                	sd	s4,32(sp)
    1080:	ec56                	sd	s5,24(sp)
    1082:	e85a                	sd	s6,16(sp)
    1084:	0880                	addi	s0,sp,80
    1086:	89aa                	mv	s3,a0
  unlink("bd");
    1088:	00005517          	auipc	a0,0x5
    108c:	79850513          	addi	a0,a0,1944 # 6820 <malloc+0xb80>
    1090:	00005097          	auipc	ra,0x5
    1094:	812080e7          	jalr	-2030(ra) # 58a2 <unlink>
  fd = open("bd", O_CREATE);
    1098:	20000593          	li	a1,512
    109c:	00005517          	auipc	a0,0x5
    10a0:	78450513          	addi	a0,a0,1924 # 6820 <malloc+0xb80>
    10a4:	00004097          	auipc	ra,0x4
    10a8:	7ee080e7          	jalr	2030(ra) # 5892 <open>
  if(fd < 0){
    10ac:	0c054963          	bltz	a0,117e <bigdir+0x10c>
  close(fd);
    10b0:	00004097          	auipc	ra,0x4
    10b4:	7ca080e7          	jalr	1994(ra) # 587a <close>
  for(i = 0; i < N; i++){
    10b8:	4901                	li	s2,0
    name[0] = 'x';
    10ba:	07800a93          	li	s5,120
    if(link("bd", name) != 0){
    10be:	00005a17          	auipc	s4,0x5
    10c2:	762a0a13          	addi	s4,s4,1890 # 6820 <malloc+0xb80>
  for(i = 0; i < N; i++){
    10c6:	1f400b13          	li	s6,500
    name[0] = 'x';
    10ca:	fb540823          	sb	s5,-80(s0)
    name[1] = '0' + (i / 64);
    10ce:	41f9579b          	sraiw	a5,s2,0x1f
    10d2:	01a7d71b          	srliw	a4,a5,0x1a
    10d6:	012707bb          	addw	a5,a4,s2
    10da:	4067d69b          	sraiw	a3,a5,0x6
    10de:	0306869b          	addiw	a3,a3,48
    10e2:	fad408a3          	sb	a3,-79(s0)
    name[2] = '0' + (i % 64);
    10e6:	03f7f793          	andi	a5,a5,63
    10ea:	9f99                	subw	a5,a5,a4
    10ec:	0307879b          	addiw	a5,a5,48
    10f0:	faf40923          	sb	a5,-78(s0)
    name[3] = '\0';
    10f4:	fa0409a3          	sb	zero,-77(s0)
    if(link("bd", name) != 0){
    10f8:	fb040593          	addi	a1,s0,-80
    10fc:	8552                	mv	a0,s4
    10fe:	00004097          	auipc	ra,0x4
    1102:	7b4080e7          	jalr	1972(ra) # 58b2 <link>
    1106:	84aa                	mv	s1,a0
    1108:	e949                	bnez	a0,119a <bigdir+0x128>
  for(i = 0; i < N; i++){
    110a:	2905                	addiw	s2,s2,1
    110c:	fb691fe3          	bne	s2,s6,10ca <bigdir+0x58>
  unlink("bd");
    1110:	00005517          	auipc	a0,0x5
    1114:	71050513          	addi	a0,a0,1808 # 6820 <malloc+0xb80>
    1118:	00004097          	auipc	ra,0x4
    111c:	78a080e7          	jalr	1930(ra) # 58a2 <unlink>
    name[0] = 'x';
    1120:	07800913          	li	s2,120
  for(i = 0; i < N; i++){
    1124:	1f400a13          	li	s4,500
    name[0] = 'x';
    1128:	fb240823          	sb	s2,-80(s0)
    name[1] = '0' + (i / 64);
    112c:	41f4d79b          	sraiw	a5,s1,0x1f
    1130:	01a7d71b          	srliw	a4,a5,0x1a
    1134:	009707bb          	addw	a5,a4,s1
    1138:	4067d69b          	sraiw	a3,a5,0x6
    113c:	0306869b          	addiw	a3,a3,48
    1140:	fad408a3          	sb	a3,-79(s0)
    name[2] = '0' + (i % 64);
    1144:	03f7f793          	andi	a5,a5,63
    1148:	9f99                	subw	a5,a5,a4
    114a:	0307879b          	addiw	a5,a5,48
    114e:	faf40923          	sb	a5,-78(s0)
    name[3] = '\0';
    1152:	fa0409a3          	sb	zero,-77(s0)
    if(unlink(name) != 0){
    1156:	fb040513          	addi	a0,s0,-80
    115a:	00004097          	auipc	ra,0x4
    115e:	748080e7          	jalr	1864(ra) # 58a2 <unlink>
    1162:	ed21                	bnez	a0,11ba <bigdir+0x148>
  for(i = 0; i < N; i++){
    1164:	2485                	addiw	s1,s1,1
    1166:	fd4491e3          	bne	s1,s4,1128 <bigdir+0xb6>
}
    116a:	60a6                	ld	ra,72(sp)
    116c:	6406                	ld	s0,64(sp)
    116e:	74e2                	ld	s1,56(sp)
    1170:	7942                	ld	s2,48(sp)
    1172:	79a2                	ld	s3,40(sp)
    1174:	7a02                	ld	s4,32(sp)
    1176:	6ae2                	ld	s5,24(sp)
    1178:	6b42                	ld	s6,16(sp)
    117a:	6161                	addi	sp,sp,80
    117c:	8082                	ret
    printf("%s: bigdir create failed\n", s);
    117e:	85ce                	mv	a1,s3
    1180:	00005517          	auipc	a0,0x5
    1184:	6a850513          	addi	a0,a0,1704 # 6828 <malloc+0xb88>
    1188:	00005097          	auipc	ra,0x5
    118c:	a5a080e7          	jalr	-1446(ra) # 5be2 <printf>
    exit(1);
    1190:	4505                	li	a0,1
    1192:	00004097          	auipc	ra,0x4
    1196:	6c0080e7          	jalr	1728(ra) # 5852 <exit>
      printf("%s: bigdir link(bd, %s) failed\n", s, name);
    119a:	fb040613          	addi	a2,s0,-80
    119e:	85ce                	mv	a1,s3
    11a0:	00005517          	auipc	a0,0x5
    11a4:	6a850513          	addi	a0,a0,1704 # 6848 <malloc+0xba8>
    11a8:	00005097          	auipc	ra,0x5
    11ac:	a3a080e7          	jalr	-1478(ra) # 5be2 <printf>
      exit(1);
    11b0:	4505                	li	a0,1
    11b2:	00004097          	auipc	ra,0x4
    11b6:	6a0080e7          	jalr	1696(ra) # 5852 <exit>
      printf("%s: bigdir unlink failed", s);
    11ba:	85ce                	mv	a1,s3
    11bc:	00005517          	auipc	a0,0x5
    11c0:	6ac50513          	addi	a0,a0,1708 # 6868 <malloc+0xbc8>
    11c4:	00005097          	auipc	ra,0x5
    11c8:	a1e080e7          	jalr	-1506(ra) # 5be2 <printf>
      exit(1);
    11cc:	4505                	li	a0,1
    11ce:	00004097          	auipc	ra,0x4
    11d2:	684080e7          	jalr	1668(ra) # 5852 <exit>

00000000000011d6 <validatetest>:
{
    11d6:	7139                	addi	sp,sp,-64
    11d8:	fc06                	sd	ra,56(sp)
    11da:	f822                	sd	s0,48(sp)
    11dc:	f426                	sd	s1,40(sp)
    11de:	f04a                	sd	s2,32(sp)
    11e0:	ec4e                	sd	s3,24(sp)
    11e2:	e852                	sd	s4,16(sp)
    11e4:	e456                	sd	s5,8(sp)
    11e6:	e05a                	sd	s6,0(sp)
    11e8:	0080                	addi	s0,sp,64
    11ea:	8b2a                	mv	s6,a0
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    11ec:	4481                	li	s1,0
    if(link("nosuchfile", (char*)p) != -1){
    11ee:	00005997          	auipc	s3,0x5
    11f2:	69a98993          	addi	s3,s3,1690 # 6888 <malloc+0xbe8>
    11f6:	597d                	li	s2,-1
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    11f8:	6a85                	lui	s5,0x1
    11fa:	00114a37          	lui	s4,0x114
    if(link("nosuchfile", (char*)p) != -1){
    11fe:	85a6                	mv	a1,s1
    1200:	854e                	mv	a0,s3
    1202:	00004097          	auipc	ra,0x4
    1206:	6b0080e7          	jalr	1712(ra) # 58b2 <link>
    120a:	01251f63          	bne	a0,s2,1228 <validatetest+0x52>
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    120e:	94d6                	add	s1,s1,s5
    1210:	ff4497e3          	bne	s1,s4,11fe <validatetest+0x28>
}
    1214:	70e2                	ld	ra,56(sp)
    1216:	7442                	ld	s0,48(sp)
    1218:	74a2                	ld	s1,40(sp)
    121a:	7902                	ld	s2,32(sp)
    121c:	69e2                	ld	s3,24(sp)
    121e:	6a42                	ld	s4,16(sp)
    1220:	6aa2                	ld	s5,8(sp)
    1222:	6b02                	ld	s6,0(sp)
    1224:	6121                	addi	sp,sp,64
    1226:	8082                	ret
      printf("%s: link should not succeed\n", s);
    1228:	85da                	mv	a1,s6
    122a:	00005517          	auipc	a0,0x5
    122e:	66e50513          	addi	a0,a0,1646 # 6898 <malloc+0xbf8>
    1232:	00005097          	auipc	ra,0x5
    1236:	9b0080e7          	jalr	-1616(ra) # 5be2 <printf>
      exit(1);
    123a:	4505                	li	a0,1
    123c:	00004097          	auipc	ra,0x4
    1240:	616080e7          	jalr	1558(ra) # 5852 <exit>

0000000000001244 <pgbug>:
{
    1244:	7179                	addi	sp,sp,-48
    1246:	f406                	sd	ra,40(sp)
    1248:	f022                	sd	s0,32(sp)
    124a:	ec26                	sd	s1,24(sp)
    124c:	1800                	addi	s0,sp,48
  argv[0] = 0;
    124e:	fc043c23          	sd	zero,-40(s0)
  exec((char*)0xeaeb0b5b00002f5e, argv);
    1252:	00007497          	auipc	s1,0x7
    1256:	35e4b483          	ld	s1,862(s1) # 85b0 <__SDATA_BEGIN__>
    125a:	fd840593          	addi	a1,s0,-40
    125e:	8526                	mv	a0,s1
    1260:	00004097          	auipc	ra,0x4
    1264:	62a080e7          	jalr	1578(ra) # 588a <exec>
  pipe((int*)0xeaeb0b5b00002f5e);
    1268:	8526                	mv	a0,s1
    126a:	00004097          	auipc	ra,0x4
    126e:	5f8080e7          	jalr	1528(ra) # 5862 <pipe>
  exit(0);
    1272:	4501                	li	a0,0
    1274:	00004097          	auipc	ra,0x4
    1278:	5de080e7          	jalr	1502(ra) # 5852 <exit>

000000000000127c <badarg>:

// regression test. test whether exec() leaks memory if one of the
// arguments is invalid. the test passes if the kernel doesn't panic.
void
badarg(char *s)
{
    127c:	7139                	addi	sp,sp,-64
    127e:	fc06                	sd	ra,56(sp)
    1280:	f822                	sd	s0,48(sp)
    1282:	f426                	sd	s1,40(sp)
    1284:	f04a                	sd	s2,32(sp)
    1286:	ec4e                	sd	s3,24(sp)
    1288:	0080                	addi	s0,sp,64
    128a:	64b1                	lui	s1,0xc
    128c:	35048493          	addi	s1,s1,848 # c350 <buf+0x578>
  for(int i = 0; i < 50000; i++){
    char *argv[2];
    argv[0] = (char*)0xffffffff;
    1290:	597d                	li	s2,-1
    1292:	02095913          	srli	s2,s2,0x20
    argv[1] = 0;
    exec("echo", argv);
    1296:	00005997          	auipc	s3,0x5
    129a:	e9a98993          	addi	s3,s3,-358 # 6130 <malloc+0x490>
    argv[0] = (char*)0xffffffff;
    129e:	fd243023          	sd	s2,-64(s0)
    argv[1] = 0;
    12a2:	fc043423          	sd	zero,-56(s0)
    exec("echo", argv);
    12a6:	fc040593          	addi	a1,s0,-64
    12aa:	854e                	mv	a0,s3
    12ac:	00004097          	auipc	ra,0x4
    12b0:	5de080e7          	jalr	1502(ra) # 588a <exec>
  for(int i = 0; i < 50000; i++){
    12b4:	34fd                	addiw	s1,s1,-1
    12b6:	f4e5                	bnez	s1,129e <badarg+0x22>
  }
  
  exit(0);
    12b8:	4501                	li	a0,0
    12ba:	00004097          	auipc	ra,0x4
    12be:	598080e7          	jalr	1432(ra) # 5852 <exit>

00000000000012c2 <copyinstr2>:
{
    12c2:	7155                	addi	sp,sp,-208
    12c4:	e586                	sd	ra,200(sp)
    12c6:	e1a2                	sd	s0,192(sp)
    12c8:	0980                	addi	s0,sp,208
  for(int i = 0; i < MAXPATH; i++)
    12ca:	f6840793          	addi	a5,s0,-152
    12ce:	fe840693          	addi	a3,s0,-24
    b[i] = 'x';
    12d2:	07800713          	li	a4,120
    12d6:	00e78023          	sb	a4,0(a5)
  for(int i = 0; i < MAXPATH; i++)
    12da:	0785                	addi	a5,a5,1
    12dc:	fed79de3          	bne	a5,a3,12d6 <copyinstr2+0x14>
  b[MAXPATH] = '\0';
    12e0:	fe040423          	sb	zero,-24(s0)
  int ret = unlink(b);
    12e4:	f6840513          	addi	a0,s0,-152
    12e8:	00004097          	auipc	ra,0x4
    12ec:	5ba080e7          	jalr	1466(ra) # 58a2 <unlink>
  if(ret != -1){
    12f0:	57fd                	li	a5,-1
    12f2:	0ef51063          	bne	a0,a5,13d2 <copyinstr2+0x110>
  int fd = open(b, O_CREATE | O_WRONLY);
    12f6:	20100593          	li	a1,513
    12fa:	f6840513          	addi	a0,s0,-152
    12fe:	00004097          	auipc	ra,0x4
    1302:	594080e7          	jalr	1428(ra) # 5892 <open>
  if(fd != -1){
    1306:	57fd                	li	a5,-1
    1308:	0ef51563          	bne	a0,a5,13f2 <copyinstr2+0x130>
  ret = link(b, b);
    130c:	f6840593          	addi	a1,s0,-152
    1310:	852e                	mv	a0,a1
    1312:	00004097          	auipc	ra,0x4
    1316:	5a0080e7          	jalr	1440(ra) # 58b2 <link>
  if(ret != -1){
    131a:	57fd                	li	a5,-1
    131c:	0ef51b63          	bne	a0,a5,1412 <copyinstr2+0x150>
  char *args[] = { "xx", 0 };
    1320:	00006797          	auipc	a5,0x6
    1324:	76078793          	addi	a5,a5,1888 # 7a80 <malloc+0x1de0>
    1328:	f4f43c23          	sd	a5,-168(s0)
    132c:	f6043023          	sd	zero,-160(s0)
  ret = exec(b, args);
    1330:	f5840593          	addi	a1,s0,-168
    1334:	f6840513          	addi	a0,s0,-152
    1338:	00004097          	auipc	ra,0x4
    133c:	552080e7          	jalr	1362(ra) # 588a <exec>
  if(ret != -1){
    1340:	57fd                	li	a5,-1
    1342:	0ef51963          	bne	a0,a5,1434 <copyinstr2+0x172>
  int pid = fork();
    1346:	00004097          	auipc	ra,0x4
    134a:	504080e7          	jalr	1284(ra) # 584a <fork>
  if(pid < 0){
    134e:	10054363          	bltz	a0,1454 <copyinstr2+0x192>
  if(pid == 0){
    1352:	12051463          	bnez	a0,147a <copyinstr2+0x1b8>
    1356:	00007797          	auipc	a5,0x7
    135a:	36a78793          	addi	a5,a5,874 # 86c0 <big.1276>
    135e:	00008697          	auipc	a3,0x8
    1362:	36268693          	addi	a3,a3,866 # 96c0 <__global_pointer$+0x910>
      big[i] = 'x';
    1366:	07800713          	li	a4,120
    136a:	00e78023          	sb	a4,0(a5)
    for(int i = 0; i < PGSIZE; i++)
    136e:	0785                	addi	a5,a5,1
    1370:	fed79de3          	bne	a5,a3,136a <copyinstr2+0xa8>
    big[PGSIZE] = '\0';
    1374:	00008797          	auipc	a5,0x8
    1378:	34078623          	sb	zero,844(a5) # 96c0 <__global_pointer$+0x910>
    char *args2[] = { big, big, big, 0 };
    137c:	00007797          	auipc	a5,0x7
    1380:	df478793          	addi	a5,a5,-524 # 8170 <malloc+0x24d0>
    1384:	6390                	ld	a2,0(a5)
    1386:	6794                	ld	a3,8(a5)
    1388:	6b98                	ld	a4,16(a5)
    138a:	6f9c                	ld	a5,24(a5)
    138c:	f2c43823          	sd	a2,-208(s0)
    1390:	f2d43c23          	sd	a3,-200(s0)
    1394:	f4e43023          	sd	a4,-192(s0)
    1398:	f4f43423          	sd	a5,-184(s0)
    ret = exec("echo", args2);
    139c:	f3040593          	addi	a1,s0,-208
    13a0:	00005517          	auipc	a0,0x5
    13a4:	d9050513          	addi	a0,a0,-624 # 6130 <malloc+0x490>
    13a8:	00004097          	auipc	ra,0x4
    13ac:	4e2080e7          	jalr	1250(ra) # 588a <exec>
    if(ret != -1){
    13b0:	57fd                	li	a5,-1
    13b2:	0af50e63          	beq	a0,a5,146e <copyinstr2+0x1ac>
      printf("exec(echo, BIG) returned %d, not -1\n", fd);
    13b6:	55fd                	li	a1,-1
    13b8:	00005517          	auipc	a0,0x5
    13bc:	58850513          	addi	a0,a0,1416 # 6940 <malloc+0xca0>
    13c0:	00005097          	auipc	ra,0x5
    13c4:	822080e7          	jalr	-2014(ra) # 5be2 <printf>
      exit(1);
    13c8:	4505                	li	a0,1
    13ca:	00004097          	auipc	ra,0x4
    13ce:	488080e7          	jalr	1160(ra) # 5852 <exit>
    printf("unlink(%s) returned %d, not -1\n", b, ret);
    13d2:	862a                	mv	a2,a0
    13d4:	f6840593          	addi	a1,s0,-152
    13d8:	00005517          	auipc	a0,0x5
    13dc:	4e050513          	addi	a0,a0,1248 # 68b8 <malloc+0xc18>
    13e0:	00005097          	auipc	ra,0x5
    13e4:	802080e7          	jalr	-2046(ra) # 5be2 <printf>
    exit(1);
    13e8:	4505                	li	a0,1
    13ea:	00004097          	auipc	ra,0x4
    13ee:	468080e7          	jalr	1128(ra) # 5852 <exit>
    printf("open(%s) returned %d, not -1\n", b, fd);
    13f2:	862a                	mv	a2,a0
    13f4:	f6840593          	addi	a1,s0,-152
    13f8:	00005517          	auipc	a0,0x5
    13fc:	4e050513          	addi	a0,a0,1248 # 68d8 <malloc+0xc38>
    1400:	00004097          	auipc	ra,0x4
    1404:	7e2080e7          	jalr	2018(ra) # 5be2 <printf>
    exit(1);
    1408:	4505                	li	a0,1
    140a:	00004097          	auipc	ra,0x4
    140e:	448080e7          	jalr	1096(ra) # 5852 <exit>
    printf("link(%s, %s) returned %d, not -1\n", b, b, ret);
    1412:	86aa                	mv	a3,a0
    1414:	f6840613          	addi	a2,s0,-152
    1418:	85b2                	mv	a1,a2
    141a:	00005517          	auipc	a0,0x5
    141e:	4de50513          	addi	a0,a0,1246 # 68f8 <malloc+0xc58>
    1422:	00004097          	auipc	ra,0x4
    1426:	7c0080e7          	jalr	1984(ra) # 5be2 <printf>
    exit(1);
    142a:	4505                	li	a0,1
    142c:	00004097          	auipc	ra,0x4
    1430:	426080e7          	jalr	1062(ra) # 5852 <exit>
    printf("exec(%s) returned %d, not -1\n", b, fd);
    1434:	567d                	li	a2,-1
    1436:	f6840593          	addi	a1,s0,-152
    143a:	00005517          	auipc	a0,0x5
    143e:	4e650513          	addi	a0,a0,1254 # 6920 <malloc+0xc80>
    1442:	00004097          	auipc	ra,0x4
    1446:	7a0080e7          	jalr	1952(ra) # 5be2 <printf>
    exit(1);
    144a:	4505                	li	a0,1
    144c:	00004097          	auipc	ra,0x4
    1450:	406080e7          	jalr	1030(ra) # 5852 <exit>
    printf("fork failed\n");
    1454:	00006517          	auipc	a0,0x6
    1458:	96450513          	addi	a0,a0,-1692 # 6db8 <malloc+0x1118>
    145c:	00004097          	auipc	ra,0x4
    1460:	786080e7          	jalr	1926(ra) # 5be2 <printf>
    exit(1);
    1464:	4505                	li	a0,1
    1466:	00004097          	auipc	ra,0x4
    146a:	3ec080e7          	jalr	1004(ra) # 5852 <exit>
    exit(747); // OK
    146e:	2eb00513          	li	a0,747
    1472:	00004097          	auipc	ra,0x4
    1476:	3e0080e7          	jalr	992(ra) # 5852 <exit>
  int st = 0;
    147a:	f4042a23          	sw	zero,-172(s0)
  wait(&st);
    147e:	f5440513          	addi	a0,s0,-172
    1482:	00004097          	auipc	ra,0x4
    1486:	3d8080e7          	jalr	984(ra) # 585a <wait>
  if(st != 747){
    148a:	f5442703          	lw	a4,-172(s0)
    148e:	2eb00793          	li	a5,747
    1492:	00f71663          	bne	a4,a5,149e <copyinstr2+0x1dc>
}
    1496:	60ae                	ld	ra,200(sp)
    1498:	640e                	ld	s0,192(sp)
    149a:	6169                	addi	sp,sp,208
    149c:	8082                	ret
    printf("exec(echo, BIG) succeeded, should have failed\n");
    149e:	00005517          	auipc	a0,0x5
    14a2:	4ca50513          	addi	a0,a0,1226 # 6968 <malloc+0xcc8>
    14a6:	00004097          	auipc	ra,0x4
    14aa:	73c080e7          	jalr	1852(ra) # 5be2 <printf>
    exit(1);
    14ae:	4505                	li	a0,1
    14b0:	00004097          	auipc	ra,0x4
    14b4:	3a2080e7          	jalr	930(ra) # 5852 <exit>

00000000000014b8 <truncate3>:
{
    14b8:	7159                	addi	sp,sp,-112
    14ba:	f486                	sd	ra,104(sp)
    14bc:	f0a2                	sd	s0,96(sp)
    14be:	eca6                	sd	s1,88(sp)
    14c0:	e8ca                	sd	s2,80(sp)
    14c2:	e4ce                	sd	s3,72(sp)
    14c4:	e0d2                	sd	s4,64(sp)
    14c6:	fc56                	sd	s5,56(sp)
    14c8:	1880                	addi	s0,sp,112
    14ca:	892a                	mv	s2,a0
  close(open("truncfile", O_CREATE|O_TRUNC|O_WRONLY));
    14cc:	60100593          	li	a1,1537
    14d0:	00005517          	auipc	a0,0x5
    14d4:	cb850513          	addi	a0,a0,-840 # 6188 <malloc+0x4e8>
    14d8:	00004097          	auipc	ra,0x4
    14dc:	3ba080e7          	jalr	954(ra) # 5892 <open>
    14e0:	00004097          	auipc	ra,0x4
    14e4:	39a080e7          	jalr	922(ra) # 587a <close>
  pid = fork();
    14e8:	00004097          	auipc	ra,0x4
    14ec:	362080e7          	jalr	866(ra) # 584a <fork>
  if(pid < 0){
    14f0:	08054063          	bltz	a0,1570 <truncate3+0xb8>
  if(pid == 0){
    14f4:	e969                	bnez	a0,15c6 <truncate3+0x10e>
    14f6:	06400993          	li	s3,100
      int fd = open("truncfile", O_WRONLY);
    14fa:	00005a17          	auipc	s4,0x5
    14fe:	c8ea0a13          	addi	s4,s4,-882 # 6188 <malloc+0x4e8>
      int n = write(fd, "1234567890", 10);
    1502:	00005a97          	auipc	s5,0x5
    1506:	4c6a8a93          	addi	s5,s5,1222 # 69c8 <malloc+0xd28>
      int fd = open("truncfile", O_WRONLY);
    150a:	4585                	li	a1,1
    150c:	8552                	mv	a0,s4
    150e:	00004097          	auipc	ra,0x4
    1512:	384080e7          	jalr	900(ra) # 5892 <open>
    1516:	84aa                	mv	s1,a0
      if(fd < 0){
    1518:	06054a63          	bltz	a0,158c <truncate3+0xd4>
      int n = write(fd, "1234567890", 10);
    151c:	4629                	li	a2,10
    151e:	85d6                	mv	a1,s5
    1520:	00004097          	auipc	ra,0x4
    1524:	352080e7          	jalr	850(ra) # 5872 <write>
      if(n != 10){
    1528:	47a9                	li	a5,10
    152a:	06f51f63          	bne	a0,a5,15a8 <truncate3+0xf0>
      close(fd);
    152e:	8526                	mv	a0,s1
    1530:	00004097          	auipc	ra,0x4
    1534:	34a080e7          	jalr	842(ra) # 587a <close>
      fd = open("truncfile", O_RDONLY);
    1538:	4581                	li	a1,0
    153a:	8552                	mv	a0,s4
    153c:	00004097          	auipc	ra,0x4
    1540:	356080e7          	jalr	854(ra) # 5892 <open>
    1544:	84aa                	mv	s1,a0
      read(fd, buf, sizeof(buf));
    1546:	02000613          	li	a2,32
    154a:	f9840593          	addi	a1,s0,-104
    154e:	00004097          	auipc	ra,0x4
    1552:	31c080e7          	jalr	796(ra) # 586a <read>
      close(fd);
    1556:	8526                	mv	a0,s1
    1558:	00004097          	auipc	ra,0x4
    155c:	322080e7          	jalr	802(ra) # 587a <close>
    for(int i = 0; i < 100; i++){
    1560:	39fd                	addiw	s3,s3,-1
    1562:	fa0994e3          	bnez	s3,150a <truncate3+0x52>
    exit(0);
    1566:	4501                	li	a0,0
    1568:	00004097          	auipc	ra,0x4
    156c:	2ea080e7          	jalr	746(ra) # 5852 <exit>
    printf("%s: fork failed\n", s);
    1570:	85ca                	mv	a1,s2
    1572:	00005517          	auipc	a0,0x5
    1576:	42650513          	addi	a0,a0,1062 # 6998 <malloc+0xcf8>
    157a:	00004097          	auipc	ra,0x4
    157e:	668080e7          	jalr	1640(ra) # 5be2 <printf>
    exit(1);
    1582:	4505                	li	a0,1
    1584:	00004097          	auipc	ra,0x4
    1588:	2ce080e7          	jalr	718(ra) # 5852 <exit>
        printf("%s: open failed\n", s);
    158c:	85ca                	mv	a1,s2
    158e:	00005517          	auipc	a0,0x5
    1592:	42250513          	addi	a0,a0,1058 # 69b0 <malloc+0xd10>
    1596:	00004097          	auipc	ra,0x4
    159a:	64c080e7          	jalr	1612(ra) # 5be2 <printf>
        exit(1);
    159e:	4505                	li	a0,1
    15a0:	00004097          	auipc	ra,0x4
    15a4:	2b2080e7          	jalr	690(ra) # 5852 <exit>
        printf("%s: write got %d, expected 10\n", s, n);
    15a8:	862a                	mv	a2,a0
    15aa:	85ca                	mv	a1,s2
    15ac:	00005517          	auipc	a0,0x5
    15b0:	42c50513          	addi	a0,a0,1068 # 69d8 <malloc+0xd38>
    15b4:	00004097          	auipc	ra,0x4
    15b8:	62e080e7          	jalr	1582(ra) # 5be2 <printf>
        exit(1);
    15bc:	4505                	li	a0,1
    15be:	00004097          	auipc	ra,0x4
    15c2:	294080e7          	jalr	660(ra) # 5852 <exit>
    15c6:	09600993          	li	s3,150
    int fd = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
    15ca:	00005a17          	auipc	s4,0x5
    15ce:	bbea0a13          	addi	s4,s4,-1090 # 6188 <malloc+0x4e8>
    int n = write(fd, "xxx", 3);
    15d2:	00005a97          	auipc	s5,0x5
    15d6:	426a8a93          	addi	s5,s5,1062 # 69f8 <malloc+0xd58>
    int fd = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
    15da:	60100593          	li	a1,1537
    15de:	8552                	mv	a0,s4
    15e0:	00004097          	auipc	ra,0x4
    15e4:	2b2080e7          	jalr	690(ra) # 5892 <open>
    15e8:	84aa                	mv	s1,a0
    if(fd < 0){
    15ea:	04054763          	bltz	a0,1638 <truncate3+0x180>
    int n = write(fd, "xxx", 3);
    15ee:	460d                	li	a2,3
    15f0:	85d6                	mv	a1,s5
    15f2:	00004097          	auipc	ra,0x4
    15f6:	280080e7          	jalr	640(ra) # 5872 <write>
    if(n != 3){
    15fa:	478d                	li	a5,3
    15fc:	04f51c63          	bne	a0,a5,1654 <truncate3+0x19c>
    close(fd);
    1600:	8526                	mv	a0,s1
    1602:	00004097          	auipc	ra,0x4
    1606:	278080e7          	jalr	632(ra) # 587a <close>
  for(int i = 0; i < 150; i++){
    160a:	39fd                	addiw	s3,s3,-1
    160c:	fc0997e3          	bnez	s3,15da <truncate3+0x122>
  wait(&xstatus);
    1610:	fbc40513          	addi	a0,s0,-68
    1614:	00004097          	auipc	ra,0x4
    1618:	246080e7          	jalr	582(ra) # 585a <wait>
  unlink("truncfile");
    161c:	00005517          	auipc	a0,0x5
    1620:	b6c50513          	addi	a0,a0,-1172 # 6188 <malloc+0x4e8>
    1624:	00004097          	auipc	ra,0x4
    1628:	27e080e7          	jalr	638(ra) # 58a2 <unlink>
  exit(xstatus);
    162c:	fbc42503          	lw	a0,-68(s0)
    1630:	00004097          	auipc	ra,0x4
    1634:	222080e7          	jalr	546(ra) # 5852 <exit>
      printf("%s: open failed\n", s);
    1638:	85ca                	mv	a1,s2
    163a:	00005517          	auipc	a0,0x5
    163e:	37650513          	addi	a0,a0,886 # 69b0 <malloc+0xd10>
    1642:	00004097          	auipc	ra,0x4
    1646:	5a0080e7          	jalr	1440(ra) # 5be2 <printf>
      exit(1);
    164a:	4505                	li	a0,1
    164c:	00004097          	auipc	ra,0x4
    1650:	206080e7          	jalr	518(ra) # 5852 <exit>
      printf("%s: write got %d, expected 3\n", s, n);
    1654:	862a                	mv	a2,a0
    1656:	85ca                	mv	a1,s2
    1658:	00005517          	auipc	a0,0x5
    165c:	3a850513          	addi	a0,a0,936 # 6a00 <malloc+0xd60>
    1660:	00004097          	auipc	ra,0x4
    1664:	582080e7          	jalr	1410(ra) # 5be2 <printf>
      exit(1);
    1668:	4505                	li	a0,1
    166a:	00004097          	auipc	ra,0x4
    166e:	1e8080e7          	jalr	488(ra) # 5852 <exit>

0000000000001672 <exectest>:
{
    1672:	715d                	addi	sp,sp,-80
    1674:	e486                	sd	ra,72(sp)
    1676:	e0a2                	sd	s0,64(sp)
    1678:	fc26                	sd	s1,56(sp)
    167a:	f84a                	sd	s2,48(sp)
    167c:	0880                	addi	s0,sp,80
    167e:	892a                	mv	s2,a0
  char *echoargv[] = { "echo", "OK", 0 };
    1680:	00005797          	auipc	a5,0x5
    1684:	ab078793          	addi	a5,a5,-1360 # 6130 <malloc+0x490>
    1688:	fcf43023          	sd	a5,-64(s0)
    168c:	00005797          	auipc	a5,0x5
    1690:	39478793          	addi	a5,a5,916 # 6a20 <malloc+0xd80>
    1694:	fcf43423          	sd	a5,-56(s0)
    1698:	fc043823          	sd	zero,-48(s0)
  unlink("echo-ok");
    169c:	00005517          	auipc	a0,0x5
    16a0:	38c50513          	addi	a0,a0,908 # 6a28 <malloc+0xd88>
    16a4:	00004097          	auipc	ra,0x4
    16a8:	1fe080e7          	jalr	510(ra) # 58a2 <unlink>
  pid = fork();
    16ac:	00004097          	auipc	ra,0x4
    16b0:	19e080e7          	jalr	414(ra) # 584a <fork>
  if(pid < 0) {
    16b4:	04054663          	bltz	a0,1700 <exectest+0x8e>
    16b8:	84aa                	mv	s1,a0
  if(pid == 0) {
    16ba:	e959                	bnez	a0,1750 <exectest+0xde>
    close(1);
    16bc:	4505                	li	a0,1
    16be:	00004097          	auipc	ra,0x4
    16c2:	1bc080e7          	jalr	444(ra) # 587a <close>
    fd = open("echo-ok", O_CREATE|O_WRONLY);
    16c6:	20100593          	li	a1,513
    16ca:	00005517          	auipc	a0,0x5
    16ce:	35e50513          	addi	a0,a0,862 # 6a28 <malloc+0xd88>
    16d2:	00004097          	auipc	ra,0x4
    16d6:	1c0080e7          	jalr	448(ra) # 5892 <open>
    if(fd < 0) {
    16da:	04054163          	bltz	a0,171c <exectest+0xaa>
    if(fd != 1) {
    16de:	4785                	li	a5,1
    16e0:	04f50c63          	beq	a0,a5,1738 <exectest+0xc6>
      printf("%s: wrong fd\n", s);
    16e4:	85ca                	mv	a1,s2
    16e6:	00005517          	auipc	a0,0x5
    16ea:	36250513          	addi	a0,a0,866 # 6a48 <malloc+0xda8>
    16ee:	00004097          	auipc	ra,0x4
    16f2:	4f4080e7          	jalr	1268(ra) # 5be2 <printf>
      exit(1);
    16f6:	4505                	li	a0,1
    16f8:	00004097          	auipc	ra,0x4
    16fc:	15a080e7          	jalr	346(ra) # 5852 <exit>
     printf("%s: fork failed\n", s);
    1700:	85ca                	mv	a1,s2
    1702:	00005517          	auipc	a0,0x5
    1706:	29650513          	addi	a0,a0,662 # 6998 <malloc+0xcf8>
    170a:	00004097          	auipc	ra,0x4
    170e:	4d8080e7          	jalr	1240(ra) # 5be2 <printf>
     exit(1);
    1712:	4505                	li	a0,1
    1714:	00004097          	auipc	ra,0x4
    1718:	13e080e7          	jalr	318(ra) # 5852 <exit>
      printf("%s: create failed\n", s);
    171c:	85ca                	mv	a1,s2
    171e:	00005517          	auipc	a0,0x5
    1722:	31250513          	addi	a0,a0,786 # 6a30 <malloc+0xd90>
    1726:	00004097          	auipc	ra,0x4
    172a:	4bc080e7          	jalr	1212(ra) # 5be2 <printf>
      exit(1);
    172e:	4505                	li	a0,1
    1730:	00004097          	auipc	ra,0x4
    1734:	122080e7          	jalr	290(ra) # 5852 <exit>
    if(exec("echo", echoargv) < 0){
    1738:	fc040593          	addi	a1,s0,-64
    173c:	00005517          	auipc	a0,0x5
    1740:	9f450513          	addi	a0,a0,-1548 # 6130 <malloc+0x490>
    1744:	00004097          	auipc	ra,0x4
    1748:	146080e7          	jalr	326(ra) # 588a <exec>
    174c:	02054163          	bltz	a0,176e <exectest+0xfc>
  if (wait(&xstatus) != pid) {
    1750:	fdc40513          	addi	a0,s0,-36
    1754:	00004097          	auipc	ra,0x4
    1758:	106080e7          	jalr	262(ra) # 585a <wait>
    175c:	02951763          	bne	a0,s1,178a <exectest+0x118>
  if(xstatus != 0)
    1760:	fdc42503          	lw	a0,-36(s0)
    1764:	cd0d                	beqz	a0,179e <exectest+0x12c>
    exit(xstatus);
    1766:	00004097          	auipc	ra,0x4
    176a:	0ec080e7          	jalr	236(ra) # 5852 <exit>
      printf("%s: exec echo failed\n", s);
    176e:	85ca                	mv	a1,s2
    1770:	00005517          	auipc	a0,0x5
    1774:	2e850513          	addi	a0,a0,744 # 6a58 <malloc+0xdb8>
    1778:	00004097          	auipc	ra,0x4
    177c:	46a080e7          	jalr	1130(ra) # 5be2 <printf>
      exit(1);
    1780:	4505                	li	a0,1
    1782:	00004097          	auipc	ra,0x4
    1786:	0d0080e7          	jalr	208(ra) # 5852 <exit>
    printf("%s: wait failed!\n", s);
    178a:	85ca                	mv	a1,s2
    178c:	00005517          	auipc	a0,0x5
    1790:	2e450513          	addi	a0,a0,740 # 6a70 <malloc+0xdd0>
    1794:	00004097          	auipc	ra,0x4
    1798:	44e080e7          	jalr	1102(ra) # 5be2 <printf>
    179c:	b7d1                	j	1760 <exectest+0xee>
  fd = open("echo-ok", O_RDONLY);
    179e:	4581                	li	a1,0
    17a0:	00005517          	auipc	a0,0x5
    17a4:	28850513          	addi	a0,a0,648 # 6a28 <malloc+0xd88>
    17a8:	00004097          	auipc	ra,0x4
    17ac:	0ea080e7          	jalr	234(ra) # 5892 <open>
  if(fd < 0) {
    17b0:	02054a63          	bltz	a0,17e4 <exectest+0x172>
  if (read(fd, buf, 2) != 2) {
    17b4:	4609                	li	a2,2
    17b6:	fb840593          	addi	a1,s0,-72
    17ba:	00004097          	auipc	ra,0x4
    17be:	0b0080e7          	jalr	176(ra) # 586a <read>
    17c2:	4789                	li	a5,2
    17c4:	02f50e63          	beq	a0,a5,1800 <exectest+0x18e>
    printf("%s: read failed\n", s);
    17c8:	85ca                	mv	a1,s2
    17ca:	00005517          	auipc	a0,0x5
    17ce:	d2650513          	addi	a0,a0,-730 # 64f0 <malloc+0x850>
    17d2:	00004097          	auipc	ra,0x4
    17d6:	410080e7          	jalr	1040(ra) # 5be2 <printf>
    exit(1);
    17da:	4505                	li	a0,1
    17dc:	00004097          	auipc	ra,0x4
    17e0:	076080e7          	jalr	118(ra) # 5852 <exit>
    printf("%s: open failed\n", s);
    17e4:	85ca                	mv	a1,s2
    17e6:	00005517          	auipc	a0,0x5
    17ea:	1ca50513          	addi	a0,a0,458 # 69b0 <malloc+0xd10>
    17ee:	00004097          	auipc	ra,0x4
    17f2:	3f4080e7          	jalr	1012(ra) # 5be2 <printf>
    exit(1);
    17f6:	4505                	li	a0,1
    17f8:	00004097          	auipc	ra,0x4
    17fc:	05a080e7          	jalr	90(ra) # 5852 <exit>
  unlink("echo-ok");
    1800:	00005517          	auipc	a0,0x5
    1804:	22850513          	addi	a0,a0,552 # 6a28 <malloc+0xd88>
    1808:	00004097          	auipc	ra,0x4
    180c:	09a080e7          	jalr	154(ra) # 58a2 <unlink>
  if(buf[0] == 'O' && buf[1] == 'K')
    1810:	fb844703          	lbu	a4,-72(s0)
    1814:	04f00793          	li	a5,79
    1818:	00f71863          	bne	a4,a5,1828 <exectest+0x1b6>
    181c:	fb944703          	lbu	a4,-71(s0)
    1820:	04b00793          	li	a5,75
    1824:	02f70063          	beq	a4,a5,1844 <exectest+0x1d2>
    printf("%s: wrong output\n", s);
    1828:	85ca                	mv	a1,s2
    182a:	00005517          	auipc	a0,0x5
    182e:	25e50513          	addi	a0,a0,606 # 6a88 <malloc+0xde8>
    1832:	00004097          	auipc	ra,0x4
    1836:	3b0080e7          	jalr	944(ra) # 5be2 <printf>
    exit(1);
    183a:	4505                	li	a0,1
    183c:	00004097          	auipc	ra,0x4
    1840:	016080e7          	jalr	22(ra) # 5852 <exit>
    exit(0);
    1844:	4501                	li	a0,0
    1846:	00004097          	auipc	ra,0x4
    184a:	00c080e7          	jalr	12(ra) # 5852 <exit>

000000000000184e <pipe1>:
{
    184e:	711d                	addi	sp,sp,-96
    1850:	ec86                	sd	ra,88(sp)
    1852:	e8a2                	sd	s0,80(sp)
    1854:	e4a6                	sd	s1,72(sp)
    1856:	e0ca                	sd	s2,64(sp)
    1858:	fc4e                	sd	s3,56(sp)
    185a:	f852                	sd	s4,48(sp)
    185c:	f456                	sd	s5,40(sp)
    185e:	f05a                	sd	s6,32(sp)
    1860:	ec5e                	sd	s7,24(sp)
    1862:	1080                	addi	s0,sp,96
    1864:	892a                	mv	s2,a0
  if(pipe(fds) != 0){
    1866:	fa840513          	addi	a0,s0,-88
    186a:	00004097          	auipc	ra,0x4
    186e:	ff8080e7          	jalr	-8(ra) # 5862 <pipe>
    1872:	ed25                	bnez	a0,18ea <pipe1+0x9c>
    1874:	84aa                	mv	s1,a0
  pid = fork();
    1876:	00004097          	auipc	ra,0x4
    187a:	fd4080e7          	jalr	-44(ra) # 584a <fork>
    187e:	8a2a                	mv	s4,a0
  if(pid == 0){
    1880:	c159                	beqz	a0,1906 <pipe1+0xb8>
  } else if(pid > 0){
    1882:	16a05e63          	blez	a0,19fe <pipe1+0x1b0>
    close(fds[1]);
    1886:	fac42503          	lw	a0,-84(s0)
    188a:	00004097          	auipc	ra,0x4
    188e:	ff0080e7          	jalr	-16(ra) # 587a <close>
    total = 0;
    1892:	8a26                	mv	s4,s1
    cc = 1;
    1894:	4985                	li	s3,1
    while((n = read(fds[0], buf, cc)) > 0){
    1896:	0000aa97          	auipc	s5,0xa
    189a:	542a8a93          	addi	s5,s5,1346 # bdd8 <buf>
      if(cc > sizeof(buf))
    189e:	6b0d                	lui	s6,0x3
    while((n = read(fds[0], buf, cc)) > 0){
    18a0:	864e                	mv	a2,s3
    18a2:	85d6                	mv	a1,s5
    18a4:	fa842503          	lw	a0,-88(s0)
    18a8:	00004097          	auipc	ra,0x4
    18ac:	fc2080e7          	jalr	-62(ra) # 586a <read>
    18b0:	10a05263          	blez	a0,19b4 <pipe1+0x166>
      for(i = 0; i < n; i++){
    18b4:	0000a717          	auipc	a4,0xa
    18b8:	52470713          	addi	a4,a4,1316 # bdd8 <buf>
    18bc:	00a4863b          	addw	a2,s1,a0
        if((buf[i] & 0xff) != (seq++ & 0xff)){
    18c0:	00074683          	lbu	a3,0(a4)
    18c4:	0ff4f793          	andi	a5,s1,255
    18c8:	2485                	addiw	s1,s1,1
    18ca:	0cf69163          	bne	a3,a5,198c <pipe1+0x13e>
      for(i = 0; i < n; i++){
    18ce:	0705                	addi	a4,a4,1
    18d0:	fec498e3          	bne	s1,a2,18c0 <pipe1+0x72>
      total += n;
    18d4:	00aa0a3b          	addw	s4,s4,a0
      cc = cc * 2;
    18d8:	0019979b          	slliw	a5,s3,0x1
    18dc:	0007899b          	sext.w	s3,a5
      if(cc > sizeof(buf))
    18e0:	013b7363          	bgeu	s6,s3,18e6 <pipe1+0x98>
        cc = sizeof(buf);
    18e4:	89da                	mv	s3,s6
        if((buf[i] & 0xff) != (seq++ & 0xff)){
    18e6:	84b2                	mv	s1,a2
    18e8:	bf65                	j	18a0 <pipe1+0x52>
    printf("%s: pipe() failed\n", s);
    18ea:	85ca                	mv	a1,s2
    18ec:	00005517          	auipc	a0,0x5
    18f0:	1b450513          	addi	a0,a0,436 # 6aa0 <malloc+0xe00>
    18f4:	00004097          	auipc	ra,0x4
    18f8:	2ee080e7          	jalr	750(ra) # 5be2 <printf>
    exit(1);
    18fc:	4505                	li	a0,1
    18fe:	00004097          	auipc	ra,0x4
    1902:	f54080e7          	jalr	-172(ra) # 5852 <exit>
    close(fds[0]);
    1906:	fa842503          	lw	a0,-88(s0)
    190a:	00004097          	auipc	ra,0x4
    190e:	f70080e7          	jalr	-144(ra) # 587a <close>
    for(n = 0; n < N; n++){
    1912:	0000ab17          	auipc	s6,0xa
    1916:	4c6b0b13          	addi	s6,s6,1222 # bdd8 <buf>
    191a:	416004bb          	negw	s1,s6
    191e:	0ff4f493          	andi	s1,s1,255
    1922:	409b0993          	addi	s3,s6,1033
      if(write(fds[1], buf, SZ) != SZ){
    1926:	8bda                	mv	s7,s6
    for(n = 0; n < N; n++){
    1928:	6a85                	lui	s5,0x1
    192a:	42da8a93          	addi	s5,s5,1069 # 142d <copyinstr2+0x16b>
{
    192e:	87da                	mv	a5,s6
        buf[i] = seq++;
    1930:	0097873b          	addw	a4,a5,s1
    1934:	00e78023          	sb	a4,0(a5)
      for(i = 0; i < SZ; i++)
    1938:	0785                	addi	a5,a5,1
    193a:	fef99be3          	bne	s3,a5,1930 <pipe1+0xe2>
    193e:	409a0a1b          	addiw	s4,s4,1033
      if(write(fds[1], buf, SZ) != SZ){
    1942:	40900613          	li	a2,1033
    1946:	85de                	mv	a1,s7
    1948:	fac42503          	lw	a0,-84(s0)
    194c:	00004097          	auipc	ra,0x4
    1950:	f26080e7          	jalr	-218(ra) # 5872 <write>
    1954:	40900793          	li	a5,1033
    1958:	00f51c63          	bne	a0,a5,1970 <pipe1+0x122>
    for(n = 0; n < N; n++){
    195c:	24a5                	addiw	s1,s1,9
    195e:	0ff4f493          	andi	s1,s1,255
    1962:	fd5a16e3          	bne	s4,s5,192e <pipe1+0xe0>
    exit(0);
    1966:	4501                	li	a0,0
    1968:	00004097          	auipc	ra,0x4
    196c:	eea080e7          	jalr	-278(ra) # 5852 <exit>
        printf("%s: pipe1 oops 1\n", s);
    1970:	85ca                	mv	a1,s2
    1972:	00005517          	auipc	a0,0x5
    1976:	14650513          	addi	a0,a0,326 # 6ab8 <malloc+0xe18>
    197a:	00004097          	auipc	ra,0x4
    197e:	268080e7          	jalr	616(ra) # 5be2 <printf>
        exit(1);
    1982:	4505                	li	a0,1
    1984:	00004097          	auipc	ra,0x4
    1988:	ece080e7          	jalr	-306(ra) # 5852 <exit>
          printf("%s: pipe1 oops 2\n", s);
    198c:	85ca                	mv	a1,s2
    198e:	00005517          	auipc	a0,0x5
    1992:	14250513          	addi	a0,a0,322 # 6ad0 <malloc+0xe30>
    1996:	00004097          	auipc	ra,0x4
    199a:	24c080e7          	jalr	588(ra) # 5be2 <printf>
}
    199e:	60e6                	ld	ra,88(sp)
    19a0:	6446                	ld	s0,80(sp)
    19a2:	64a6                	ld	s1,72(sp)
    19a4:	6906                	ld	s2,64(sp)
    19a6:	79e2                	ld	s3,56(sp)
    19a8:	7a42                	ld	s4,48(sp)
    19aa:	7aa2                	ld	s5,40(sp)
    19ac:	7b02                	ld	s6,32(sp)
    19ae:	6be2                	ld	s7,24(sp)
    19b0:	6125                	addi	sp,sp,96
    19b2:	8082                	ret
    if(total != N * SZ){
    19b4:	6785                	lui	a5,0x1
    19b6:	42d78793          	addi	a5,a5,1069 # 142d <copyinstr2+0x16b>
    19ba:	02fa0063          	beq	s4,a5,19da <pipe1+0x18c>
      printf("%s: pipe1 oops 3 total %d\n", total);
    19be:	85d2                	mv	a1,s4
    19c0:	00005517          	auipc	a0,0x5
    19c4:	12850513          	addi	a0,a0,296 # 6ae8 <malloc+0xe48>
    19c8:	00004097          	auipc	ra,0x4
    19cc:	21a080e7          	jalr	538(ra) # 5be2 <printf>
      exit(1);
    19d0:	4505                	li	a0,1
    19d2:	00004097          	auipc	ra,0x4
    19d6:	e80080e7          	jalr	-384(ra) # 5852 <exit>
    close(fds[0]);
    19da:	fa842503          	lw	a0,-88(s0)
    19de:	00004097          	auipc	ra,0x4
    19e2:	e9c080e7          	jalr	-356(ra) # 587a <close>
    wait(&xstatus);
    19e6:	fa440513          	addi	a0,s0,-92
    19ea:	00004097          	auipc	ra,0x4
    19ee:	e70080e7          	jalr	-400(ra) # 585a <wait>
    exit(xstatus);
    19f2:	fa442503          	lw	a0,-92(s0)
    19f6:	00004097          	auipc	ra,0x4
    19fa:	e5c080e7          	jalr	-420(ra) # 5852 <exit>
    printf("%s: fork() failed\n", s);
    19fe:	85ca                	mv	a1,s2
    1a00:	00005517          	auipc	a0,0x5
    1a04:	10850513          	addi	a0,a0,264 # 6b08 <malloc+0xe68>
    1a08:	00004097          	auipc	ra,0x4
    1a0c:	1da080e7          	jalr	474(ra) # 5be2 <printf>
    exit(1);
    1a10:	4505                	li	a0,1
    1a12:	00004097          	auipc	ra,0x4
    1a16:	e40080e7          	jalr	-448(ra) # 5852 <exit>

0000000000001a1a <exitwait>:
{
    1a1a:	7139                	addi	sp,sp,-64
    1a1c:	fc06                	sd	ra,56(sp)
    1a1e:	f822                	sd	s0,48(sp)
    1a20:	f426                	sd	s1,40(sp)
    1a22:	f04a                	sd	s2,32(sp)
    1a24:	ec4e                	sd	s3,24(sp)
    1a26:	e852                	sd	s4,16(sp)
    1a28:	0080                	addi	s0,sp,64
    1a2a:	8a2a                	mv	s4,a0
  for(i = 0; i < 100; i++){
    1a2c:	4901                	li	s2,0
    1a2e:	06400993          	li	s3,100
    pid = fork();
    1a32:	00004097          	auipc	ra,0x4
    1a36:	e18080e7          	jalr	-488(ra) # 584a <fork>
    1a3a:	84aa                	mv	s1,a0
    if(pid < 0){
    1a3c:	02054a63          	bltz	a0,1a70 <exitwait+0x56>
    if(pid){
    1a40:	c151                	beqz	a0,1ac4 <exitwait+0xaa>
      if(wait(&xstate) != pid){
    1a42:	fcc40513          	addi	a0,s0,-52
    1a46:	00004097          	auipc	ra,0x4
    1a4a:	e14080e7          	jalr	-492(ra) # 585a <wait>
    1a4e:	02951f63          	bne	a0,s1,1a8c <exitwait+0x72>
      if(i != xstate) {
    1a52:	fcc42783          	lw	a5,-52(s0)
    1a56:	05279963          	bne	a5,s2,1aa8 <exitwait+0x8e>
  for(i = 0; i < 100; i++){
    1a5a:	2905                	addiw	s2,s2,1
    1a5c:	fd391be3          	bne	s2,s3,1a32 <exitwait+0x18>
}
    1a60:	70e2                	ld	ra,56(sp)
    1a62:	7442                	ld	s0,48(sp)
    1a64:	74a2                	ld	s1,40(sp)
    1a66:	7902                	ld	s2,32(sp)
    1a68:	69e2                	ld	s3,24(sp)
    1a6a:	6a42                	ld	s4,16(sp)
    1a6c:	6121                	addi	sp,sp,64
    1a6e:	8082                	ret
      printf("%s: fork failed\n", s);
    1a70:	85d2                	mv	a1,s4
    1a72:	00005517          	auipc	a0,0x5
    1a76:	f2650513          	addi	a0,a0,-218 # 6998 <malloc+0xcf8>
    1a7a:	00004097          	auipc	ra,0x4
    1a7e:	168080e7          	jalr	360(ra) # 5be2 <printf>
      exit(1);
    1a82:	4505                	li	a0,1
    1a84:	00004097          	auipc	ra,0x4
    1a88:	dce080e7          	jalr	-562(ra) # 5852 <exit>
        printf("%s: wait wrong pid\n", s);
    1a8c:	85d2                	mv	a1,s4
    1a8e:	00005517          	auipc	a0,0x5
    1a92:	09250513          	addi	a0,a0,146 # 6b20 <malloc+0xe80>
    1a96:	00004097          	auipc	ra,0x4
    1a9a:	14c080e7          	jalr	332(ra) # 5be2 <printf>
        exit(1);
    1a9e:	4505                	li	a0,1
    1aa0:	00004097          	auipc	ra,0x4
    1aa4:	db2080e7          	jalr	-590(ra) # 5852 <exit>
        printf("%s: wait wrong exit status\n", s);
    1aa8:	85d2                	mv	a1,s4
    1aaa:	00005517          	auipc	a0,0x5
    1aae:	08e50513          	addi	a0,a0,142 # 6b38 <malloc+0xe98>
    1ab2:	00004097          	auipc	ra,0x4
    1ab6:	130080e7          	jalr	304(ra) # 5be2 <printf>
        exit(1);
    1aba:	4505                	li	a0,1
    1abc:	00004097          	auipc	ra,0x4
    1ac0:	d96080e7          	jalr	-618(ra) # 5852 <exit>
      exit(i);
    1ac4:	854a                	mv	a0,s2
    1ac6:	00004097          	auipc	ra,0x4
    1aca:	d8c080e7          	jalr	-628(ra) # 5852 <exit>

0000000000001ace <twochildren>:
{
    1ace:	1101                	addi	sp,sp,-32
    1ad0:	ec06                	sd	ra,24(sp)
    1ad2:	e822                	sd	s0,16(sp)
    1ad4:	e426                	sd	s1,8(sp)
    1ad6:	e04a                	sd	s2,0(sp)
    1ad8:	1000                	addi	s0,sp,32
    1ada:	892a                	mv	s2,a0
    1adc:	3e800493          	li	s1,1000
    int pid1 = fork();
    1ae0:	00004097          	auipc	ra,0x4
    1ae4:	d6a080e7          	jalr	-662(ra) # 584a <fork>
    if(pid1 < 0){
    1ae8:	02054c63          	bltz	a0,1b20 <twochildren+0x52>
    if(pid1 == 0){
    1aec:	c921                	beqz	a0,1b3c <twochildren+0x6e>
      int pid2 = fork();
    1aee:	00004097          	auipc	ra,0x4
    1af2:	d5c080e7          	jalr	-676(ra) # 584a <fork>
      if(pid2 < 0){
    1af6:	04054763          	bltz	a0,1b44 <twochildren+0x76>
      if(pid2 == 0){
    1afa:	c13d                	beqz	a0,1b60 <twochildren+0x92>
        wait(0);
    1afc:	4501                	li	a0,0
    1afe:	00004097          	auipc	ra,0x4
    1b02:	d5c080e7          	jalr	-676(ra) # 585a <wait>
        wait(0);
    1b06:	4501                	li	a0,0
    1b08:	00004097          	auipc	ra,0x4
    1b0c:	d52080e7          	jalr	-686(ra) # 585a <wait>
  for(int i = 0; i < 1000; i++){
    1b10:	34fd                	addiw	s1,s1,-1
    1b12:	f4f9                	bnez	s1,1ae0 <twochildren+0x12>
}
    1b14:	60e2                	ld	ra,24(sp)
    1b16:	6442                	ld	s0,16(sp)
    1b18:	64a2                	ld	s1,8(sp)
    1b1a:	6902                	ld	s2,0(sp)
    1b1c:	6105                	addi	sp,sp,32
    1b1e:	8082                	ret
      printf("%s: fork failed\n", s);
    1b20:	85ca                	mv	a1,s2
    1b22:	00005517          	auipc	a0,0x5
    1b26:	e7650513          	addi	a0,a0,-394 # 6998 <malloc+0xcf8>
    1b2a:	00004097          	auipc	ra,0x4
    1b2e:	0b8080e7          	jalr	184(ra) # 5be2 <printf>
      exit(1);
    1b32:	4505                	li	a0,1
    1b34:	00004097          	auipc	ra,0x4
    1b38:	d1e080e7          	jalr	-738(ra) # 5852 <exit>
      exit(0);
    1b3c:	00004097          	auipc	ra,0x4
    1b40:	d16080e7          	jalr	-746(ra) # 5852 <exit>
        printf("%s: fork failed\n", s);
    1b44:	85ca                	mv	a1,s2
    1b46:	00005517          	auipc	a0,0x5
    1b4a:	e5250513          	addi	a0,a0,-430 # 6998 <malloc+0xcf8>
    1b4e:	00004097          	auipc	ra,0x4
    1b52:	094080e7          	jalr	148(ra) # 5be2 <printf>
        exit(1);
    1b56:	4505                	li	a0,1
    1b58:	00004097          	auipc	ra,0x4
    1b5c:	cfa080e7          	jalr	-774(ra) # 5852 <exit>
        exit(0);
    1b60:	00004097          	auipc	ra,0x4
    1b64:	cf2080e7          	jalr	-782(ra) # 5852 <exit>

0000000000001b68 <forkfork>:
{
    1b68:	7179                	addi	sp,sp,-48
    1b6a:	f406                	sd	ra,40(sp)
    1b6c:	f022                	sd	s0,32(sp)
    1b6e:	ec26                	sd	s1,24(sp)
    1b70:	1800                	addi	s0,sp,48
    1b72:	84aa                	mv	s1,a0
    int pid = fork();
    1b74:	00004097          	auipc	ra,0x4
    1b78:	cd6080e7          	jalr	-810(ra) # 584a <fork>
    if(pid < 0){
    1b7c:	04054163          	bltz	a0,1bbe <forkfork+0x56>
    if(pid == 0){
    1b80:	cd29                	beqz	a0,1bda <forkfork+0x72>
    int pid = fork();
    1b82:	00004097          	auipc	ra,0x4
    1b86:	cc8080e7          	jalr	-824(ra) # 584a <fork>
    if(pid < 0){
    1b8a:	02054a63          	bltz	a0,1bbe <forkfork+0x56>
    if(pid == 0){
    1b8e:	c531                	beqz	a0,1bda <forkfork+0x72>
    wait(&xstatus);
    1b90:	fdc40513          	addi	a0,s0,-36
    1b94:	00004097          	auipc	ra,0x4
    1b98:	cc6080e7          	jalr	-826(ra) # 585a <wait>
    if(xstatus != 0) {
    1b9c:	fdc42783          	lw	a5,-36(s0)
    1ba0:	ebbd                	bnez	a5,1c16 <forkfork+0xae>
    wait(&xstatus);
    1ba2:	fdc40513          	addi	a0,s0,-36
    1ba6:	00004097          	auipc	ra,0x4
    1baa:	cb4080e7          	jalr	-844(ra) # 585a <wait>
    if(xstatus != 0) {
    1bae:	fdc42783          	lw	a5,-36(s0)
    1bb2:	e3b5                	bnez	a5,1c16 <forkfork+0xae>
}
    1bb4:	70a2                	ld	ra,40(sp)
    1bb6:	7402                	ld	s0,32(sp)
    1bb8:	64e2                	ld	s1,24(sp)
    1bba:	6145                	addi	sp,sp,48
    1bbc:	8082                	ret
      printf("%s: fork failed", s);
    1bbe:	85a6                	mv	a1,s1
    1bc0:	00005517          	auipc	a0,0x5
    1bc4:	f9850513          	addi	a0,a0,-104 # 6b58 <malloc+0xeb8>
    1bc8:	00004097          	auipc	ra,0x4
    1bcc:	01a080e7          	jalr	26(ra) # 5be2 <printf>
      exit(1);
    1bd0:	4505                	li	a0,1
    1bd2:	00004097          	auipc	ra,0x4
    1bd6:	c80080e7          	jalr	-896(ra) # 5852 <exit>
{
    1bda:	0c800493          	li	s1,200
        int pid1 = fork();
    1bde:	00004097          	auipc	ra,0x4
    1be2:	c6c080e7          	jalr	-916(ra) # 584a <fork>
        if(pid1 < 0){
    1be6:	00054f63          	bltz	a0,1c04 <forkfork+0x9c>
        if(pid1 == 0){
    1bea:	c115                	beqz	a0,1c0e <forkfork+0xa6>
        wait(0);
    1bec:	4501                	li	a0,0
    1bee:	00004097          	auipc	ra,0x4
    1bf2:	c6c080e7          	jalr	-916(ra) # 585a <wait>
      for(int j = 0; j < 200; j++){
    1bf6:	34fd                	addiw	s1,s1,-1
    1bf8:	f0fd                	bnez	s1,1bde <forkfork+0x76>
      exit(0);
    1bfa:	4501                	li	a0,0
    1bfc:	00004097          	auipc	ra,0x4
    1c00:	c56080e7          	jalr	-938(ra) # 5852 <exit>
          exit(1);
    1c04:	4505                	li	a0,1
    1c06:	00004097          	auipc	ra,0x4
    1c0a:	c4c080e7          	jalr	-948(ra) # 5852 <exit>
          exit(0);
    1c0e:	00004097          	auipc	ra,0x4
    1c12:	c44080e7          	jalr	-956(ra) # 5852 <exit>
      printf("%s: fork in child failed", s);
    1c16:	85a6                	mv	a1,s1
    1c18:	00005517          	auipc	a0,0x5
    1c1c:	f5050513          	addi	a0,a0,-176 # 6b68 <malloc+0xec8>
    1c20:	00004097          	auipc	ra,0x4
    1c24:	fc2080e7          	jalr	-62(ra) # 5be2 <printf>
      exit(1);
    1c28:	4505                	li	a0,1
    1c2a:	00004097          	auipc	ra,0x4
    1c2e:	c28080e7          	jalr	-984(ra) # 5852 <exit>

0000000000001c32 <reparent2>:
{
    1c32:	1101                	addi	sp,sp,-32
    1c34:	ec06                	sd	ra,24(sp)
    1c36:	e822                	sd	s0,16(sp)
    1c38:	e426                	sd	s1,8(sp)
    1c3a:	1000                	addi	s0,sp,32
    1c3c:	32000493          	li	s1,800
    int pid1 = fork();
    1c40:	00004097          	auipc	ra,0x4
    1c44:	c0a080e7          	jalr	-1014(ra) # 584a <fork>
    if(pid1 < 0){
    1c48:	00054f63          	bltz	a0,1c66 <reparent2+0x34>
    if(pid1 == 0){
    1c4c:	c915                	beqz	a0,1c80 <reparent2+0x4e>
    wait(0);
    1c4e:	4501                	li	a0,0
    1c50:	00004097          	auipc	ra,0x4
    1c54:	c0a080e7          	jalr	-1014(ra) # 585a <wait>
  for(int i = 0; i < 800; i++){
    1c58:	34fd                	addiw	s1,s1,-1
    1c5a:	f0fd                	bnez	s1,1c40 <reparent2+0xe>
  exit(0);
    1c5c:	4501                	li	a0,0
    1c5e:	00004097          	auipc	ra,0x4
    1c62:	bf4080e7          	jalr	-1036(ra) # 5852 <exit>
      printf("fork failed\n");
    1c66:	00005517          	auipc	a0,0x5
    1c6a:	15250513          	addi	a0,a0,338 # 6db8 <malloc+0x1118>
    1c6e:	00004097          	auipc	ra,0x4
    1c72:	f74080e7          	jalr	-140(ra) # 5be2 <printf>
      exit(1);
    1c76:	4505                	li	a0,1
    1c78:	00004097          	auipc	ra,0x4
    1c7c:	bda080e7          	jalr	-1062(ra) # 5852 <exit>
      fork();
    1c80:	00004097          	auipc	ra,0x4
    1c84:	bca080e7          	jalr	-1078(ra) # 584a <fork>
      fork();
    1c88:	00004097          	auipc	ra,0x4
    1c8c:	bc2080e7          	jalr	-1086(ra) # 584a <fork>
      exit(0);
    1c90:	4501                	li	a0,0
    1c92:	00004097          	auipc	ra,0x4
    1c96:	bc0080e7          	jalr	-1088(ra) # 5852 <exit>

0000000000001c9a <createdelete>:
{
    1c9a:	7175                	addi	sp,sp,-144
    1c9c:	e506                	sd	ra,136(sp)
    1c9e:	e122                	sd	s0,128(sp)
    1ca0:	fca6                	sd	s1,120(sp)
    1ca2:	f8ca                	sd	s2,112(sp)
    1ca4:	f4ce                	sd	s3,104(sp)
    1ca6:	f0d2                	sd	s4,96(sp)
    1ca8:	ecd6                	sd	s5,88(sp)
    1caa:	e8da                	sd	s6,80(sp)
    1cac:	e4de                	sd	s7,72(sp)
    1cae:	e0e2                	sd	s8,64(sp)
    1cb0:	fc66                	sd	s9,56(sp)
    1cb2:	0900                	addi	s0,sp,144
    1cb4:	8caa                	mv	s9,a0
  for(pi = 0; pi < NCHILD; pi++){
    1cb6:	4901                	li	s2,0
    1cb8:	4991                	li	s3,4
    pid = fork();
    1cba:	00004097          	auipc	ra,0x4
    1cbe:	b90080e7          	jalr	-1136(ra) # 584a <fork>
    1cc2:	84aa                	mv	s1,a0
    if(pid < 0){
    1cc4:	02054f63          	bltz	a0,1d02 <createdelete+0x68>
    if(pid == 0){
    1cc8:	c939                	beqz	a0,1d1e <createdelete+0x84>
  for(pi = 0; pi < NCHILD; pi++){
    1cca:	2905                	addiw	s2,s2,1
    1ccc:	ff3917e3          	bne	s2,s3,1cba <createdelete+0x20>
    1cd0:	4491                	li	s1,4
    wait(&xstatus);
    1cd2:	f7c40513          	addi	a0,s0,-132
    1cd6:	00004097          	auipc	ra,0x4
    1cda:	b84080e7          	jalr	-1148(ra) # 585a <wait>
    if(xstatus != 0)
    1cde:	f7c42903          	lw	s2,-132(s0)
    1ce2:	0e091263          	bnez	s2,1dc6 <createdelete+0x12c>
  for(pi = 0; pi < NCHILD; pi++){
    1ce6:	34fd                	addiw	s1,s1,-1
    1ce8:	f4ed                	bnez	s1,1cd2 <createdelete+0x38>
  name[0] = name[1] = name[2] = 0;
    1cea:	f8040123          	sb	zero,-126(s0)
    1cee:	03000993          	li	s3,48
    1cf2:	5a7d                	li	s4,-1
    1cf4:	07000c13          	li	s8,112
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1cf8:	4b21                	li	s6,8
      if((i == 0 || i >= N/2) && fd < 0){
    1cfa:	4ba5                	li	s7,9
    for(pi = 0; pi < NCHILD; pi++){
    1cfc:	07400a93          	li	s5,116
    1d00:	a29d                	j	1e66 <createdelete+0x1cc>
      printf("fork failed\n", s);
    1d02:	85e6                	mv	a1,s9
    1d04:	00005517          	auipc	a0,0x5
    1d08:	0b450513          	addi	a0,a0,180 # 6db8 <malloc+0x1118>
    1d0c:	00004097          	auipc	ra,0x4
    1d10:	ed6080e7          	jalr	-298(ra) # 5be2 <printf>
      exit(1);
    1d14:	4505                	li	a0,1
    1d16:	00004097          	auipc	ra,0x4
    1d1a:	b3c080e7          	jalr	-1220(ra) # 5852 <exit>
      name[0] = 'p' + pi;
    1d1e:	0709091b          	addiw	s2,s2,112
    1d22:	f9240023          	sb	s2,-128(s0)
      name[2] = '\0';
    1d26:	f8040123          	sb	zero,-126(s0)
      for(i = 0; i < N; i++){
    1d2a:	4951                	li	s2,20
    1d2c:	a015                	j	1d50 <createdelete+0xb6>
          printf("%s: create failed\n", s);
    1d2e:	85e6                	mv	a1,s9
    1d30:	00005517          	auipc	a0,0x5
    1d34:	d0050513          	addi	a0,a0,-768 # 6a30 <malloc+0xd90>
    1d38:	00004097          	auipc	ra,0x4
    1d3c:	eaa080e7          	jalr	-342(ra) # 5be2 <printf>
          exit(1);
    1d40:	4505                	li	a0,1
    1d42:	00004097          	auipc	ra,0x4
    1d46:	b10080e7          	jalr	-1264(ra) # 5852 <exit>
      for(i = 0; i < N; i++){
    1d4a:	2485                	addiw	s1,s1,1
    1d4c:	07248863          	beq	s1,s2,1dbc <createdelete+0x122>
        name[1] = '0' + i;
    1d50:	0304879b          	addiw	a5,s1,48
    1d54:	f8f400a3          	sb	a5,-127(s0)
        fd = open(name, O_CREATE | O_RDWR);
    1d58:	20200593          	li	a1,514
    1d5c:	f8040513          	addi	a0,s0,-128
    1d60:	00004097          	auipc	ra,0x4
    1d64:	b32080e7          	jalr	-1230(ra) # 5892 <open>
        if(fd < 0){
    1d68:	fc0543e3          	bltz	a0,1d2e <createdelete+0x94>
        close(fd);
    1d6c:	00004097          	auipc	ra,0x4
    1d70:	b0e080e7          	jalr	-1266(ra) # 587a <close>
        if(i > 0 && (i % 2 ) == 0){
    1d74:	fc905be3          	blez	s1,1d4a <createdelete+0xb0>
    1d78:	0014f793          	andi	a5,s1,1
    1d7c:	f7f9                	bnez	a5,1d4a <createdelete+0xb0>
          name[1] = '0' + (i / 2);
    1d7e:	01f4d79b          	srliw	a5,s1,0x1f
    1d82:	9fa5                	addw	a5,a5,s1
    1d84:	4017d79b          	sraiw	a5,a5,0x1
    1d88:	0307879b          	addiw	a5,a5,48
    1d8c:	f8f400a3          	sb	a5,-127(s0)
          if(unlink(name) < 0){
    1d90:	f8040513          	addi	a0,s0,-128
    1d94:	00004097          	auipc	ra,0x4
    1d98:	b0e080e7          	jalr	-1266(ra) # 58a2 <unlink>
    1d9c:	fa0557e3          	bgez	a0,1d4a <createdelete+0xb0>
            printf("%s: unlink failed\n", s);
    1da0:	85e6                	mv	a1,s9
    1da2:	00005517          	auipc	a0,0x5
    1da6:	de650513          	addi	a0,a0,-538 # 6b88 <malloc+0xee8>
    1daa:	00004097          	auipc	ra,0x4
    1dae:	e38080e7          	jalr	-456(ra) # 5be2 <printf>
            exit(1);
    1db2:	4505                	li	a0,1
    1db4:	00004097          	auipc	ra,0x4
    1db8:	a9e080e7          	jalr	-1378(ra) # 5852 <exit>
      exit(0);
    1dbc:	4501                	li	a0,0
    1dbe:	00004097          	auipc	ra,0x4
    1dc2:	a94080e7          	jalr	-1388(ra) # 5852 <exit>
      exit(1);
    1dc6:	4505                	li	a0,1
    1dc8:	00004097          	auipc	ra,0x4
    1dcc:	a8a080e7          	jalr	-1398(ra) # 5852 <exit>
        printf("%s: oops createdelete %s didn't exist\n", s, name);
    1dd0:	f8040613          	addi	a2,s0,-128
    1dd4:	85e6                	mv	a1,s9
    1dd6:	00005517          	auipc	a0,0x5
    1dda:	dca50513          	addi	a0,a0,-566 # 6ba0 <malloc+0xf00>
    1dde:	00004097          	auipc	ra,0x4
    1de2:	e04080e7          	jalr	-508(ra) # 5be2 <printf>
        exit(1);
    1de6:	4505                	li	a0,1
    1de8:	00004097          	auipc	ra,0x4
    1dec:	a6a080e7          	jalr	-1430(ra) # 5852 <exit>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1df0:	054b7163          	bgeu	s6,s4,1e32 <createdelete+0x198>
      if(fd >= 0)
    1df4:	02055a63          	bgez	a0,1e28 <createdelete+0x18e>
    for(pi = 0; pi < NCHILD; pi++){
    1df8:	2485                	addiw	s1,s1,1
    1dfa:	0ff4f493          	andi	s1,s1,255
    1dfe:	05548c63          	beq	s1,s5,1e56 <createdelete+0x1bc>
      name[0] = 'p' + pi;
    1e02:	f8940023          	sb	s1,-128(s0)
      name[1] = '0' + i;
    1e06:	f93400a3          	sb	s3,-127(s0)
      fd = open(name, 0);
    1e0a:	4581                	li	a1,0
    1e0c:	f8040513          	addi	a0,s0,-128
    1e10:	00004097          	auipc	ra,0x4
    1e14:	a82080e7          	jalr	-1406(ra) # 5892 <open>
      if((i == 0 || i >= N/2) && fd < 0){
    1e18:	00090463          	beqz	s2,1e20 <createdelete+0x186>
    1e1c:	fd2bdae3          	bge	s7,s2,1df0 <createdelete+0x156>
    1e20:	fa0548e3          	bltz	a0,1dd0 <createdelete+0x136>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1e24:	014b7963          	bgeu	s6,s4,1e36 <createdelete+0x19c>
        close(fd);
    1e28:	00004097          	auipc	ra,0x4
    1e2c:	a52080e7          	jalr	-1454(ra) # 587a <close>
    1e30:	b7e1                	j	1df8 <createdelete+0x15e>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1e32:	fc0543e3          	bltz	a0,1df8 <createdelete+0x15e>
        printf("%s: oops createdelete %s did exist\n", s, name);
    1e36:	f8040613          	addi	a2,s0,-128
    1e3a:	85e6                	mv	a1,s9
    1e3c:	00005517          	auipc	a0,0x5
    1e40:	d8c50513          	addi	a0,a0,-628 # 6bc8 <malloc+0xf28>
    1e44:	00004097          	auipc	ra,0x4
    1e48:	d9e080e7          	jalr	-610(ra) # 5be2 <printf>
        exit(1);
    1e4c:	4505                	li	a0,1
    1e4e:	00004097          	auipc	ra,0x4
    1e52:	a04080e7          	jalr	-1532(ra) # 5852 <exit>
  for(i = 0; i < N; i++){
    1e56:	2905                	addiw	s2,s2,1
    1e58:	2a05                	addiw	s4,s4,1
    1e5a:	2985                	addiw	s3,s3,1
    1e5c:	0ff9f993          	andi	s3,s3,255
    1e60:	47d1                	li	a5,20
    1e62:	02f90a63          	beq	s2,a5,1e96 <createdelete+0x1fc>
    for(pi = 0; pi < NCHILD; pi++){
    1e66:	84e2                	mv	s1,s8
    1e68:	bf69                	j	1e02 <createdelete+0x168>
  for(i = 0; i < N; i++){
    1e6a:	2905                	addiw	s2,s2,1
    1e6c:	0ff97913          	andi	s2,s2,255
    1e70:	2985                	addiw	s3,s3,1
    1e72:	0ff9f993          	andi	s3,s3,255
    1e76:	03490863          	beq	s2,s4,1ea6 <createdelete+0x20c>
  name[0] = name[1] = name[2] = 0;
    1e7a:	84d6                	mv	s1,s5
      name[0] = 'p' + i;
    1e7c:	f9240023          	sb	s2,-128(s0)
      name[1] = '0' + i;
    1e80:	f93400a3          	sb	s3,-127(s0)
      unlink(name);
    1e84:	f8040513          	addi	a0,s0,-128
    1e88:	00004097          	auipc	ra,0x4
    1e8c:	a1a080e7          	jalr	-1510(ra) # 58a2 <unlink>
    for(pi = 0; pi < NCHILD; pi++){
    1e90:	34fd                	addiw	s1,s1,-1
    1e92:	f4ed                	bnez	s1,1e7c <createdelete+0x1e2>
    1e94:	bfd9                	j	1e6a <createdelete+0x1d0>
    1e96:	03000993          	li	s3,48
    1e9a:	07000913          	li	s2,112
  name[0] = name[1] = name[2] = 0;
    1e9e:	4a91                	li	s5,4
  for(i = 0; i < N; i++){
    1ea0:	08400a13          	li	s4,132
    1ea4:	bfd9                	j	1e7a <createdelete+0x1e0>
}
    1ea6:	60aa                	ld	ra,136(sp)
    1ea8:	640a                	ld	s0,128(sp)
    1eaa:	74e6                	ld	s1,120(sp)
    1eac:	7946                	ld	s2,112(sp)
    1eae:	79a6                	ld	s3,104(sp)
    1eb0:	7a06                	ld	s4,96(sp)
    1eb2:	6ae6                	ld	s5,88(sp)
    1eb4:	6b46                	ld	s6,80(sp)
    1eb6:	6ba6                	ld	s7,72(sp)
    1eb8:	6c06                	ld	s8,64(sp)
    1eba:	7ce2                	ld	s9,56(sp)
    1ebc:	6149                	addi	sp,sp,144
    1ebe:	8082                	ret

0000000000001ec0 <linkunlink>:
{
    1ec0:	711d                	addi	sp,sp,-96
    1ec2:	ec86                	sd	ra,88(sp)
    1ec4:	e8a2                	sd	s0,80(sp)
    1ec6:	e4a6                	sd	s1,72(sp)
    1ec8:	e0ca                	sd	s2,64(sp)
    1eca:	fc4e                	sd	s3,56(sp)
    1ecc:	f852                	sd	s4,48(sp)
    1ece:	f456                	sd	s5,40(sp)
    1ed0:	f05a                	sd	s6,32(sp)
    1ed2:	ec5e                	sd	s7,24(sp)
    1ed4:	e862                	sd	s8,16(sp)
    1ed6:	e466                	sd	s9,8(sp)
    1ed8:	1080                	addi	s0,sp,96
    1eda:	84aa                	mv	s1,a0
  unlink("x");
    1edc:	00004517          	auipc	a0,0x4
    1ee0:	2c450513          	addi	a0,a0,708 # 61a0 <malloc+0x500>
    1ee4:	00004097          	auipc	ra,0x4
    1ee8:	9be080e7          	jalr	-1602(ra) # 58a2 <unlink>
  pid = fork();
    1eec:	00004097          	auipc	ra,0x4
    1ef0:	95e080e7          	jalr	-1698(ra) # 584a <fork>
  if(pid < 0){
    1ef4:	02054b63          	bltz	a0,1f2a <linkunlink+0x6a>
    1ef8:	8c2a                	mv	s8,a0
  unsigned int x = (pid ? 1 : 97);
    1efa:	4c85                	li	s9,1
    1efc:	e119                	bnez	a0,1f02 <linkunlink+0x42>
    1efe:	06100c93          	li	s9,97
    1f02:	06400493          	li	s1,100
    x = x * 1103515245 + 12345;
    1f06:	41c659b7          	lui	s3,0x41c65
    1f0a:	e6d9899b          	addiw	s3,s3,-403
    1f0e:	690d                	lui	s2,0x3
    1f10:	0399091b          	addiw	s2,s2,57
    if((x % 3) == 0){
    1f14:	4a0d                	li	s4,3
    } else if((x % 3) == 1){
    1f16:	4b05                	li	s6,1
      unlink("x");
    1f18:	00004a97          	auipc	s5,0x4
    1f1c:	288a8a93          	addi	s5,s5,648 # 61a0 <malloc+0x500>
      link("cat", "x");
    1f20:	00005b97          	auipc	s7,0x5
    1f24:	cd0b8b93          	addi	s7,s7,-816 # 6bf0 <malloc+0xf50>
    1f28:	a091                	j	1f6c <linkunlink+0xac>
    printf("%s: fork failed\n", s);
    1f2a:	85a6                	mv	a1,s1
    1f2c:	00005517          	auipc	a0,0x5
    1f30:	a6c50513          	addi	a0,a0,-1428 # 6998 <malloc+0xcf8>
    1f34:	00004097          	auipc	ra,0x4
    1f38:	cae080e7          	jalr	-850(ra) # 5be2 <printf>
    exit(1);
    1f3c:	4505                	li	a0,1
    1f3e:	00004097          	auipc	ra,0x4
    1f42:	914080e7          	jalr	-1772(ra) # 5852 <exit>
      close(open("x", O_RDWR | O_CREATE));
    1f46:	20200593          	li	a1,514
    1f4a:	8556                	mv	a0,s5
    1f4c:	00004097          	auipc	ra,0x4
    1f50:	946080e7          	jalr	-1722(ra) # 5892 <open>
    1f54:	00004097          	auipc	ra,0x4
    1f58:	926080e7          	jalr	-1754(ra) # 587a <close>
    1f5c:	a031                	j	1f68 <linkunlink+0xa8>
      unlink("x");
    1f5e:	8556                	mv	a0,s5
    1f60:	00004097          	auipc	ra,0x4
    1f64:	942080e7          	jalr	-1726(ra) # 58a2 <unlink>
  for(i = 0; i < 100; i++){
    1f68:	34fd                	addiw	s1,s1,-1
    1f6a:	c09d                	beqz	s1,1f90 <linkunlink+0xd0>
    x = x * 1103515245 + 12345;
    1f6c:	033c87bb          	mulw	a5,s9,s3
    1f70:	012787bb          	addw	a5,a5,s2
    1f74:	00078c9b          	sext.w	s9,a5
    if((x % 3) == 0){
    1f78:	0347f7bb          	remuw	a5,a5,s4
    1f7c:	d7e9                	beqz	a5,1f46 <linkunlink+0x86>
    } else if((x % 3) == 1){
    1f7e:	ff6790e3          	bne	a5,s6,1f5e <linkunlink+0x9e>
      link("cat", "x");
    1f82:	85d6                	mv	a1,s5
    1f84:	855e                	mv	a0,s7
    1f86:	00004097          	auipc	ra,0x4
    1f8a:	92c080e7          	jalr	-1748(ra) # 58b2 <link>
    1f8e:	bfe9                	j	1f68 <linkunlink+0xa8>
  if(pid)
    1f90:	020c0463          	beqz	s8,1fb8 <linkunlink+0xf8>
    wait(0);
    1f94:	4501                	li	a0,0
    1f96:	00004097          	auipc	ra,0x4
    1f9a:	8c4080e7          	jalr	-1852(ra) # 585a <wait>
}
    1f9e:	60e6                	ld	ra,88(sp)
    1fa0:	6446                	ld	s0,80(sp)
    1fa2:	64a6                	ld	s1,72(sp)
    1fa4:	6906                	ld	s2,64(sp)
    1fa6:	79e2                	ld	s3,56(sp)
    1fa8:	7a42                	ld	s4,48(sp)
    1faa:	7aa2                	ld	s5,40(sp)
    1fac:	7b02                	ld	s6,32(sp)
    1fae:	6be2                	ld	s7,24(sp)
    1fb0:	6c42                	ld	s8,16(sp)
    1fb2:	6ca2                	ld	s9,8(sp)
    1fb4:	6125                	addi	sp,sp,96
    1fb6:	8082                	ret
    exit(0);
    1fb8:	4501                	li	a0,0
    1fba:	00004097          	auipc	ra,0x4
    1fbe:	898080e7          	jalr	-1896(ra) # 5852 <exit>

0000000000001fc2 <manywrites>:
{
    1fc2:	711d                	addi	sp,sp,-96
    1fc4:	ec86                	sd	ra,88(sp)
    1fc6:	e8a2                	sd	s0,80(sp)
    1fc8:	e4a6                	sd	s1,72(sp)
    1fca:	e0ca                	sd	s2,64(sp)
    1fcc:	fc4e                	sd	s3,56(sp)
    1fce:	f852                	sd	s4,48(sp)
    1fd0:	f456                	sd	s5,40(sp)
    1fd2:	f05a                	sd	s6,32(sp)
    1fd4:	ec5e                	sd	s7,24(sp)
    1fd6:	1080                	addi	s0,sp,96
    1fd8:	8aaa                	mv	s5,a0
  for(int ci = 0; ci < nchildren; ci++){
    1fda:	4901                	li	s2,0
    1fdc:	4991                	li	s3,4
    int pid = fork();
    1fde:	00004097          	auipc	ra,0x4
    1fe2:	86c080e7          	jalr	-1940(ra) # 584a <fork>
    1fe6:	84aa                	mv	s1,a0
    if(pid < 0){
    1fe8:	02054963          	bltz	a0,201a <manywrites+0x58>
    if(pid == 0){
    1fec:	c521                	beqz	a0,2034 <manywrites+0x72>
  for(int ci = 0; ci < nchildren; ci++){
    1fee:	2905                	addiw	s2,s2,1
    1ff0:	ff3917e3          	bne	s2,s3,1fde <manywrites+0x1c>
    1ff4:	4491                	li	s1,4
    int st = 0;
    1ff6:	fa042423          	sw	zero,-88(s0)
    wait(&st);
    1ffa:	fa840513          	addi	a0,s0,-88
    1ffe:	00004097          	auipc	ra,0x4
    2002:	85c080e7          	jalr	-1956(ra) # 585a <wait>
    if(st != 0)
    2006:	fa842503          	lw	a0,-88(s0)
    200a:	ed6d                	bnez	a0,2104 <manywrites+0x142>
  for(int ci = 0; ci < nchildren; ci++){
    200c:	34fd                	addiw	s1,s1,-1
    200e:	f4e5                	bnez	s1,1ff6 <manywrites+0x34>
  exit(0);
    2010:	4501                	li	a0,0
    2012:	00004097          	auipc	ra,0x4
    2016:	840080e7          	jalr	-1984(ra) # 5852 <exit>
      printf("fork failed\n");
    201a:	00005517          	auipc	a0,0x5
    201e:	d9e50513          	addi	a0,a0,-610 # 6db8 <malloc+0x1118>
    2022:	00004097          	auipc	ra,0x4
    2026:	bc0080e7          	jalr	-1088(ra) # 5be2 <printf>
      exit(1);
    202a:	4505                	li	a0,1
    202c:	00004097          	auipc	ra,0x4
    2030:	826080e7          	jalr	-2010(ra) # 5852 <exit>
      name[0] = 'b';
    2034:	06200793          	li	a5,98
    2038:	faf40423          	sb	a5,-88(s0)
      name[1] = 'a' + ci;
    203c:	0619079b          	addiw	a5,s2,97
    2040:	faf404a3          	sb	a5,-87(s0)
      name[2] = '\0';
    2044:	fa040523          	sb	zero,-86(s0)
      unlink(name);
    2048:	fa840513          	addi	a0,s0,-88
    204c:	00004097          	auipc	ra,0x4
    2050:	856080e7          	jalr	-1962(ra) # 58a2 <unlink>
    2054:	4b79                	li	s6,30
          int cc = write(fd, buf, sz);
    2056:	0000ab97          	auipc	s7,0xa
    205a:	d82b8b93          	addi	s7,s7,-638 # bdd8 <buf>
        for(int i = 0; i < ci+1; i++){
    205e:	8a26                	mv	s4,s1
    2060:	02094e63          	bltz	s2,209c <manywrites+0xda>
          int fd = open(name, O_CREATE | O_RDWR);
    2064:	20200593          	li	a1,514
    2068:	fa840513          	addi	a0,s0,-88
    206c:	00004097          	auipc	ra,0x4
    2070:	826080e7          	jalr	-2010(ra) # 5892 <open>
    2074:	89aa                	mv	s3,a0
          if(fd < 0){
    2076:	04054763          	bltz	a0,20c4 <manywrites+0x102>
          int cc = write(fd, buf, sz);
    207a:	660d                	lui	a2,0x3
    207c:	85de                	mv	a1,s7
    207e:	00003097          	auipc	ra,0x3
    2082:	7f4080e7          	jalr	2036(ra) # 5872 <write>
          if(cc != sz){
    2086:	678d                	lui	a5,0x3
    2088:	04f51e63          	bne	a0,a5,20e4 <manywrites+0x122>
          close(fd);
    208c:	854e                	mv	a0,s3
    208e:	00003097          	auipc	ra,0x3
    2092:	7ec080e7          	jalr	2028(ra) # 587a <close>
        for(int i = 0; i < ci+1; i++){
    2096:	2a05                	addiw	s4,s4,1
    2098:	fd4956e3          	bge	s2,s4,2064 <manywrites+0xa2>
        unlink(name);
    209c:	fa840513          	addi	a0,s0,-88
    20a0:	00004097          	auipc	ra,0x4
    20a4:	802080e7          	jalr	-2046(ra) # 58a2 <unlink>
      for(int iters = 0; iters < howmany; iters++){
    20a8:	3b7d                	addiw	s6,s6,-1
    20aa:	fa0b1ae3          	bnez	s6,205e <manywrites+0x9c>
      unlink(name);
    20ae:	fa840513          	addi	a0,s0,-88
    20b2:	00003097          	auipc	ra,0x3
    20b6:	7f0080e7          	jalr	2032(ra) # 58a2 <unlink>
      exit(0);
    20ba:	4501                	li	a0,0
    20bc:	00003097          	auipc	ra,0x3
    20c0:	796080e7          	jalr	1942(ra) # 5852 <exit>
            printf("%s: cannot create %s\n", s, name);
    20c4:	fa840613          	addi	a2,s0,-88
    20c8:	85d6                	mv	a1,s5
    20ca:	00005517          	auipc	a0,0x5
    20ce:	b2e50513          	addi	a0,a0,-1234 # 6bf8 <malloc+0xf58>
    20d2:	00004097          	auipc	ra,0x4
    20d6:	b10080e7          	jalr	-1264(ra) # 5be2 <printf>
            exit(1);
    20da:	4505                	li	a0,1
    20dc:	00003097          	auipc	ra,0x3
    20e0:	776080e7          	jalr	1910(ra) # 5852 <exit>
            printf("%s: write(%d) ret %d\n", s, sz, cc);
    20e4:	86aa                	mv	a3,a0
    20e6:	660d                	lui	a2,0x3
    20e8:	85d6                	mv	a1,s5
    20ea:	00004517          	auipc	a0,0x4
    20ee:	10650513          	addi	a0,a0,262 # 61f0 <malloc+0x550>
    20f2:	00004097          	auipc	ra,0x4
    20f6:	af0080e7          	jalr	-1296(ra) # 5be2 <printf>
            exit(1);
    20fa:	4505                	li	a0,1
    20fc:	00003097          	auipc	ra,0x3
    2100:	756080e7          	jalr	1878(ra) # 5852 <exit>
      exit(st);
    2104:	00003097          	auipc	ra,0x3
    2108:	74e080e7          	jalr	1870(ra) # 5852 <exit>

000000000000210c <forktest>:
{
    210c:	7179                	addi	sp,sp,-48
    210e:	f406                	sd	ra,40(sp)
    2110:	f022                	sd	s0,32(sp)
    2112:	ec26                	sd	s1,24(sp)
    2114:	e84a                	sd	s2,16(sp)
    2116:	e44e                	sd	s3,8(sp)
    2118:	1800                	addi	s0,sp,48
    211a:	89aa                	mv	s3,a0
  for(n=0; n<N; n++){
    211c:	4481                	li	s1,0
    211e:	3e800913          	li	s2,1000
    pid = fork();
    2122:	00003097          	auipc	ra,0x3
    2126:	728080e7          	jalr	1832(ra) # 584a <fork>
    if(pid < 0)
    212a:	02054863          	bltz	a0,215a <forktest+0x4e>
    if(pid == 0)
    212e:	c115                	beqz	a0,2152 <forktest+0x46>
  for(n=0; n<N; n++){
    2130:	2485                	addiw	s1,s1,1
    2132:	ff2498e3          	bne	s1,s2,2122 <forktest+0x16>
    printf("%s: fork claimed to work 1000 times!\n", s);
    2136:	85ce                	mv	a1,s3
    2138:	00005517          	auipc	a0,0x5
    213c:	af050513          	addi	a0,a0,-1296 # 6c28 <malloc+0xf88>
    2140:	00004097          	auipc	ra,0x4
    2144:	aa2080e7          	jalr	-1374(ra) # 5be2 <printf>
    exit(1);
    2148:	4505                	li	a0,1
    214a:	00003097          	auipc	ra,0x3
    214e:	708080e7          	jalr	1800(ra) # 5852 <exit>
      exit(0);
    2152:	00003097          	auipc	ra,0x3
    2156:	700080e7          	jalr	1792(ra) # 5852 <exit>
  if (n == 0) {
    215a:	cc9d                	beqz	s1,2198 <forktest+0x8c>
  if(n == N){
    215c:	3e800793          	li	a5,1000
    2160:	fcf48be3          	beq	s1,a5,2136 <forktest+0x2a>
  for(; n > 0; n--){
    2164:	00905b63          	blez	s1,217a <forktest+0x6e>
    if(wait(0) < 0){
    2168:	4501                	li	a0,0
    216a:	00003097          	auipc	ra,0x3
    216e:	6f0080e7          	jalr	1776(ra) # 585a <wait>
    2172:	04054163          	bltz	a0,21b4 <forktest+0xa8>
  for(; n > 0; n--){
    2176:	34fd                	addiw	s1,s1,-1
    2178:	f8e5                	bnez	s1,2168 <forktest+0x5c>
  if(wait(0) != -1){
    217a:	4501                	li	a0,0
    217c:	00003097          	auipc	ra,0x3
    2180:	6de080e7          	jalr	1758(ra) # 585a <wait>
    2184:	57fd                	li	a5,-1
    2186:	04f51563          	bne	a0,a5,21d0 <forktest+0xc4>
}
    218a:	70a2                	ld	ra,40(sp)
    218c:	7402                	ld	s0,32(sp)
    218e:	64e2                	ld	s1,24(sp)
    2190:	6942                	ld	s2,16(sp)
    2192:	69a2                	ld	s3,8(sp)
    2194:	6145                	addi	sp,sp,48
    2196:	8082                	ret
    printf("%s: no fork at all!\n", s);
    2198:	85ce                	mv	a1,s3
    219a:	00005517          	auipc	a0,0x5
    219e:	a7650513          	addi	a0,a0,-1418 # 6c10 <malloc+0xf70>
    21a2:	00004097          	auipc	ra,0x4
    21a6:	a40080e7          	jalr	-1472(ra) # 5be2 <printf>
    exit(1);
    21aa:	4505                	li	a0,1
    21ac:	00003097          	auipc	ra,0x3
    21b0:	6a6080e7          	jalr	1702(ra) # 5852 <exit>
      printf("%s: wait stopped early\n", s);
    21b4:	85ce                	mv	a1,s3
    21b6:	00005517          	auipc	a0,0x5
    21ba:	a9a50513          	addi	a0,a0,-1382 # 6c50 <malloc+0xfb0>
    21be:	00004097          	auipc	ra,0x4
    21c2:	a24080e7          	jalr	-1500(ra) # 5be2 <printf>
      exit(1);
    21c6:	4505                	li	a0,1
    21c8:	00003097          	auipc	ra,0x3
    21cc:	68a080e7          	jalr	1674(ra) # 5852 <exit>
    printf("%s: wait got too many\n", s);
    21d0:	85ce                	mv	a1,s3
    21d2:	00005517          	auipc	a0,0x5
    21d6:	a9650513          	addi	a0,a0,-1386 # 6c68 <malloc+0xfc8>
    21da:	00004097          	auipc	ra,0x4
    21de:	a08080e7          	jalr	-1528(ra) # 5be2 <printf>
    exit(1);
    21e2:	4505                	li	a0,1
    21e4:	00003097          	auipc	ra,0x3
    21e8:	66e080e7          	jalr	1646(ra) # 5852 <exit>

00000000000021ec <kernmem>:
{
    21ec:	715d                	addi	sp,sp,-80
    21ee:	e486                	sd	ra,72(sp)
    21f0:	e0a2                	sd	s0,64(sp)
    21f2:	fc26                	sd	s1,56(sp)
    21f4:	f84a                	sd	s2,48(sp)
    21f6:	f44e                	sd	s3,40(sp)
    21f8:	f052                	sd	s4,32(sp)
    21fa:	ec56                	sd	s5,24(sp)
    21fc:	0880                	addi	s0,sp,80
    21fe:	8a2a                	mv	s4,a0
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    2200:	4485                	li	s1,1
    2202:	04fe                	slli	s1,s1,0x1f
    if(xstatus != -1)  // did kernel kill child?
    2204:	5afd                	li	s5,-1
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    2206:	69b1                	lui	s3,0xc
    2208:	35098993          	addi	s3,s3,848 # c350 <buf+0x578>
    220c:	1003d937          	lui	s2,0x1003d
    2210:	090e                	slli	s2,s2,0x3
    2212:	48090913          	addi	s2,s2,1152 # 1003d480 <__BSS_END__+0x1002e698>
    pid = fork();
    2216:	00003097          	auipc	ra,0x3
    221a:	634080e7          	jalr	1588(ra) # 584a <fork>
    if(pid < 0){
    221e:	02054963          	bltz	a0,2250 <kernmem+0x64>
    if(pid == 0){
    2222:	c529                	beqz	a0,226c <kernmem+0x80>
    wait(&xstatus);
    2224:	fbc40513          	addi	a0,s0,-68
    2228:	00003097          	auipc	ra,0x3
    222c:	632080e7          	jalr	1586(ra) # 585a <wait>
    if(xstatus != -1)  // did kernel kill child?
    2230:	fbc42783          	lw	a5,-68(s0)
    2234:	05579d63          	bne	a5,s5,228e <kernmem+0xa2>
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    2238:	94ce                	add	s1,s1,s3
    223a:	fd249ee3          	bne	s1,s2,2216 <kernmem+0x2a>
}
    223e:	60a6                	ld	ra,72(sp)
    2240:	6406                	ld	s0,64(sp)
    2242:	74e2                	ld	s1,56(sp)
    2244:	7942                	ld	s2,48(sp)
    2246:	79a2                	ld	s3,40(sp)
    2248:	7a02                	ld	s4,32(sp)
    224a:	6ae2                	ld	s5,24(sp)
    224c:	6161                	addi	sp,sp,80
    224e:	8082                	ret
      printf("%s: fork failed\n", s);
    2250:	85d2                	mv	a1,s4
    2252:	00004517          	auipc	a0,0x4
    2256:	74650513          	addi	a0,a0,1862 # 6998 <malloc+0xcf8>
    225a:	00004097          	auipc	ra,0x4
    225e:	988080e7          	jalr	-1656(ra) # 5be2 <printf>
      exit(1);
    2262:	4505                	li	a0,1
    2264:	00003097          	auipc	ra,0x3
    2268:	5ee080e7          	jalr	1518(ra) # 5852 <exit>
      printf("%s: oops could read %x = %x\n", s, a, *a);
    226c:	0004c683          	lbu	a3,0(s1)
    2270:	8626                	mv	a2,s1
    2272:	85d2                	mv	a1,s4
    2274:	00005517          	auipc	a0,0x5
    2278:	a0c50513          	addi	a0,a0,-1524 # 6c80 <malloc+0xfe0>
    227c:	00004097          	auipc	ra,0x4
    2280:	966080e7          	jalr	-1690(ra) # 5be2 <printf>
      exit(1);
    2284:	4505                	li	a0,1
    2286:	00003097          	auipc	ra,0x3
    228a:	5cc080e7          	jalr	1484(ra) # 5852 <exit>
      exit(1);
    228e:	4505                	li	a0,1
    2290:	00003097          	auipc	ra,0x3
    2294:	5c2080e7          	jalr	1474(ra) # 5852 <exit>

0000000000002298 <MAXVAplus>:
{
    2298:	7179                	addi	sp,sp,-48
    229a:	f406                	sd	ra,40(sp)
    229c:	f022                	sd	s0,32(sp)
    229e:	ec26                	sd	s1,24(sp)
    22a0:	e84a                	sd	s2,16(sp)
    22a2:	1800                	addi	s0,sp,48
  volatile uint64 a = MAXVA;
    22a4:	4785                	li	a5,1
    22a6:	179a                	slli	a5,a5,0x26
    22a8:	fcf43c23          	sd	a5,-40(s0)
  for( ; a != 0; a <<= 1){
    22ac:	fd843783          	ld	a5,-40(s0)
    22b0:	cf85                	beqz	a5,22e8 <MAXVAplus+0x50>
    22b2:	892a                	mv	s2,a0
    if(xstatus != -1)  // did kernel kill child?
    22b4:	54fd                	li	s1,-1
    pid = fork();
    22b6:	00003097          	auipc	ra,0x3
    22ba:	594080e7          	jalr	1428(ra) # 584a <fork>
    if(pid < 0){
    22be:	02054b63          	bltz	a0,22f4 <MAXVAplus+0x5c>
    if(pid == 0){
    22c2:	c539                	beqz	a0,2310 <MAXVAplus+0x78>
    wait(&xstatus);
    22c4:	fd440513          	addi	a0,s0,-44
    22c8:	00003097          	auipc	ra,0x3
    22cc:	592080e7          	jalr	1426(ra) # 585a <wait>
    if(xstatus != -1)  // did kernel kill child?
    22d0:	fd442783          	lw	a5,-44(s0)
    22d4:	06979463          	bne	a5,s1,233c <MAXVAplus+0xa4>
  for( ; a != 0; a <<= 1){
    22d8:	fd843783          	ld	a5,-40(s0)
    22dc:	0786                	slli	a5,a5,0x1
    22de:	fcf43c23          	sd	a5,-40(s0)
    22e2:	fd843783          	ld	a5,-40(s0)
    22e6:	fbe1                	bnez	a5,22b6 <MAXVAplus+0x1e>
}
    22e8:	70a2                	ld	ra,40(sp)
    22ea:	7402                	ld	s0,32(sp)
    22ec:	64e2                	ld	s1,24(sp)
    22ee:	6942                	ld	s2,16(sp)
    22f0:	6145                	addi	sp,sp,48
    22f2:	8082                	ret
      printf("%s: fork failed\n", s);
    22f4:	85ca                	mv	a1,s2
    22f6:	00004517          	auipc	a0,0x4
    22fa:	6a250513          	addi	a0,a0,1698 # 6998 <malloc+0xcf8>
    22fe:	00004097          	auipc	ra,0x4
    2302:	8e4080e7          	jalr	-1820(ra) # 5be2 <printf>
      exit(1);
    2306:	4505                	li	a0,1
    2308:	00003097          	auipc	ra,0x3
    230c:	54a080e7          	jalr	1354(ra) # 5852 <exit>
      *(char*)a = 99;
    2310:	fd843783          	ld	a5,-40(s0)
    2314:	06300713          	li	a4,99
    2318:	00e78023          	sb	a4,0(a5) # 3000 <fourteen+0x118>
      printf("%s: oops wrote %x\n", s, a);
    231c:	fd843603          	ld	a2,-40(s0)
    2320:	85ca                	mv	a1,s2
    2322:	00005517          	auipc	a0,0x5
    2326:	97e50513          	addi	a0,a0,-1666 # 6ca0 <malloc+0x1000>
    232a:	00004097          	auipc	ra,0x4
    232e:	8b8080e7          	jalr	-1864(ra) # 5be2 <printf>
      exit(1);
    2332:	4505                	li	a0,1
    2334:	00003097          	auipc	ra,0x3
    2338:	51e080e7          	jalr	1310(ra) # 5852 <exit>
      exit(1);
    233c:	4505                	li	a0,1
    233e:	00003097          	auipc	ra,0x3
    2342:	514080e7          	jalr	1300(ra) # 5852 <exit>

0000000000002346 <bigargtest>:
{
    2346:	7179                	addi	sp,sp,-48
    2348:	f406                	sd	ra,40(sp)
    234a:	f022                	sd	s0,32(sp)
    234c:	ec26                	sd	s1,24(sp)
    234e:	1800                	addi	s0,sp,48
    2350:	84aa                	mv	s1,a0
  unlink("bigarg-ok");
    2352:	00005517          	auipc	a0,0x5
    2356:	96650513          	addi	a0,a0,-1690 # 6cb8 <malloc+0x1018>
    235a:	00003097          	auipc	ra,0x3
    235e:	548080e7          	jalr	1352(ra) # 58a2 <unlink>
  pid = fork();
    2362:	00003097          	auipc	ra,0x3
    2366:	4e8080e7          	jalr	1256(ra) # 584a <fork>
  if(pid == 0){
    236a:	c121                	beqz	a0,23aa <bigargtest+0x64>
  } else if(pid < 0){
    236c:	0a054063          	bltz	a0,240c <bigargtest+0xc6>
  wait(&xstatus);
    2370:	fdc40513          	addi	a0,s0,-36
    2374:	00003097          	auipc	ra,0x3
    2378:	4e6080e7          	jalr	1254(ra) # 585a <wait>
  if(xstatus != 0)
    237c:	fdc42503          	lw	a0,-36(s0)
    2380:	e545                	bnez	a0,2428 <bigargtest+0xe2>
  fd = open("bigarg-ok", 0);
    2382:	4581                	li	a1,0
    2384:	00005517          	auipc	a0,0x5
    2388:	93450513          	addi	a0,a0,-1740 # 6cb8 <malloc+0x1018>
    238c:	00003097          	auipc	ra,0x3
    2390:	506080e7          	jalr	1286(ra) # 5892 <open>
  if(fd < 0){
    2394:	08054e63          	bltz	a0,2430 <bigargtest+0xea>
  close(fd);
    2398:	00003097          	auipc	ra,0x3
    239c:	4e2080e7          	jalr	1250(ra) # 587a <close>
}
    23a0:	70a2                	ld	ra,40(sp)
    23a2:	7402                	ld	s0,32(sp)
    23a4:	64e2                	ld	s1,24(sp)
    23a6:	6145                	addi	sp,sp,48
    23a8:	8082                	ret
    23aa:	00006797          	auipc	a5,0x6
    23ae:	21678793          	addi	a5,a5,534 # 85c0 <args.1865>
    23b2:	00006697          	auipc	a3,0x6
    23b6:	30668693          	addi	a3,a3,774 # 86b8 <args.1865+0xf8>
      args[i] = "bigargs test: failed\n                                                                                                                                                                                                       ";
    23ba:	00005717          	auipc	a4,0x5
    23be:	90e70713          	addi	a4,a4,-1778 # 6cc8 <malloc+0x1028>
    23c2:	e398                	sd	a4,0(a5)
    for(i = 0; i < MAXARG-1; i++)
    23c4:	07a1                	addi	a5,a5,8
    23c6:	fed79ee3          	bne	a5,a3,23c2 <bigargtest+0x7c>
    args[MAXARG-1] = 0;
    23ca:	00006597          	auipc	a1,0x6
    23ce:	1f658593          	addi	a1,a1,502 # 85c0 <args.1865>
    23d2:	0e05bc23          	sd	zero,248(a1)
    exec("echo", args);
    23d6:	00004517          	auipc	a0,0x4
    23da:	d5a50513          	addi	a0,a0,-678 # 6130 <malloc+0x490>
    23de:	00003097          	auipc	ra,0x3
    23e2:	4ac080e7          	jalr	1196(ra) # 588a <exec>
    fd = open("bigarg-ok", O_CREATE);
    23e6:	20000593          	li	a1,512
    23ea:	00005517          	auipc	a0,0x5
    23ee:	8ce50513          	addi	a0,a0,-1842 # 6cb8 <malloc+0x1018>
    23f2:	00003097          	auipc	ra,0x3
    23f6:	4a0080e7          	jalr	1184(ra) # 5892 <open>
    close(fd);
    23fa:	00003097          	auipc	ra,0x3
    23fe:	480080e7          	jalr	1152(ra) # 587a <close>
    exit(0);
    2402:	4501                	li	a0,0
    2404:	00003097          	auipc	ra,0x3
    2408:	44e080e7          	jalr	1102(ra) # 5852 <exit>
    printf("%s: bigargtest: fork failed\n", s);
    240c:	85a6                	mv	a1,s1
    240e:	00005517          	auipc	a0,0x5
    2412:	99a50513          	addi	a0,a0,-1638 # 6da8 <malloc+0x1108>
    2416:	00003097          	auipc	ra,0x3
    241a:	7cc080e7          	jalr	1996(ra) # 5be2 <printf>
    exit(1);
    241e:	4505                	li	a0,1
    2420:	00003097          	auipc	ra,0x3
    2424:	432080e7          	jalr	1074(ra) # 5852 <exit>
    exit(xstatus);
    2428:	00003097          	auipc	ra,0x3
    242c:	42a080e7          	jalr	1066(ra) # 5852 <exit>
    printf("%s: bigarg test failed!\n", s);
    2430:	85a6                	mv	a1,s1
    2432:	00005517          	auipc	a0,0x5
    2436:	99650513          	addi	a0,a0,-1642 # 6dc8 <malloc+0x1128>
    243a:	00003097          	auipc	ra,0x3
    243e:	7a8080e7          	jalr	1960(ra) # 5be2 <printf>
    exit(1);
    2442:	4505                	li	a0,1
    2444:	00003097          	auipc	ra,0x3
    2448:	40e080e7          	jalr	1038(ra) # 5852 <exit>

000000000000244c <stacktest>:
{
    244c:	7179                	addi	sp,sp,-48
    244e:	f406                	sd	ra,40(sp)
    2450:	f022                	sd	s0,32(sp)
    2452:	ec26                	sd	s1,24(sp)
    2454:	1800                	addi	s0,sp,48
    2456:	84aa                	mv	s1,a0
  pid = fork();
    2458:	00003097          	auipc	ra,0x3
    245c:	3f2080e7          	jalr	1010(ra) # 584a <fork>
  if(pid == 0) {
    2460:	c115                	beqz	a0,2484 <stacktest+0x38>
  } else if(pid < 0){
    2462:	04054463          	bltz	a0,24aa <stacktest+0x5e>
  wait(&xstatus);
    2466:	fdc40513          	addi	a0,s0,-36
    246a:	00003097          	auipc	ra,0x3
    246e:	3f0080e7          	jalr	1008(ra) # 585a <wait>
  if(xstatus == -1)  // kernel killed child?
    2472:	fdc42503          	lw	a0,-36(s0)
    2476:	57fd                	li	a5,-1
    2478:	04f50763          	beq	a0,a5,24c6 <stacktest+0x7a>
    exit(xstatus);
    247c:	00003097          	auipc	ra,0x3
    2480:	3d6080e7          	jalr	982(ra) # 5852 <exit>

static inline uint64
r_sp()
{
  uint64 x;
  asm volatile("mv %0, sp" : "=r" (x) );
    2484:	870a                	mv	a4,sp
    printf("%s: stacktest: read below stack %p\n", s, *sp);
    2486:	77fd                	lui	a5,0xfffff
    2488:	97ba                	add	a5,a5,a4
    248a:	0007c603          	lbu	a2,0(a5) # fffffffffffff000 <__BSS_END__+0xffffffffffff0218>
    248e:	85a6                	mv	a1,s1
    2490:	00005517          	auipc	a0,0x5
    2494:	95850513          	addi	a0,a0,-1704 # 6de8 <malloc+0x1148>
    2498:	00003097          	auipc	ra,0x3
    249c:	74a080e7          	jalr	1866(ra) # 5be2 <printf>
    exit(1);
    24a0:	4505                	li	a0,1
    24a2:	00003097          	auipc	ra,0x3
    24a6:	3b0080e7          	jalr	944(ra) # 5852 <exit>
    printf("%s: fork failed\n", s);
    24aa:	85a6                	mv	a1,s1
    24ac:	00004517          	auipc	a0,0x4
    24b0:	4ec50513          	addi	a0,a0,1260 # 6998 <malloc+0xcf8>
    24b4:	00003097          	auipc	ra,0x3
    24b8:	72e080e7          	jalr	1838(ra) # 5be2 <printf>
    exit(1);
    24bc:	4505                	li	a0,1
    24be:	00003097          	auipc	ra,0x3
    24c2:	394080e7          	jalr	916(ra) # 5852 <exit>
    exit(0);
    24c6:	4501                	li	a0,0
    24c8:	00003097          	auipc	ra,0x3
    24cc:	38a080e7          	jalr	906(ra) # 5852 <exit>

00000000000024d0 <copyinstr3>:
{
    24d0:	7179                	addi	sp,sp,-48
    24d2:	f406                	sd	ra,40(sp)
    24d4:	f022                	sd	s0,32(sp)
    24d6:	ec26                	sd	s1,24(sp)
    24d8:	1800                	addi	s0,sp,48
  sbrk(8192);
    24da:	6509                	lui	a0,0x2
    24dc:	00003097          	auipc	ra,0x3
    24e0:	3fe080e7          	jalr	1022(ra) # 58da <sbrk>
  uint64 top = (uint64) sbrk(0);
    24e4:	4501                	li	a0,0
    24e6:	00003097          	auipc	ra,0x3
    24ea:	3f4080e7          	jalr	1012(ra) # 58da <sbrk>
  if((top % PGSIZE) != 0){
    24ee:	03451793          	slli	a5,a0,0x34
    24f2:	e3c9                	bnez	a5,2574 <copyinstr3+0xa4>
  top = (uint64) sbrk(0);
    24f4:	4501                	li	a0,0
    24f6:	00003097          	auipc	ra,0x3
    24fa:	3e4080e7          	jalr	996(ra) # 58da <sbrk>
  if(top % PGSIZE){
    24fe:	03451793          	slli	a5,a0,0x34
    2502:	e3d9                	bnez	a5,2588 <copyinstr3+0xb8>
  char *b = (char *) (top - 1);
    2504:	fff50493          	addi	s1,a0,-1 # 1fff <manywrites+0x3d>
  *b = 'x';
    2508:	07800793          	li	a5,120
    250c:	fef50fa3          	sb	a5,-1(a0)
  int ret = unlink(b);
    2510:	8526                	mv	a0,s1
    2512:	00003097          	auipc	ra,0x3
    2516:	390080e7          	jalr	912(ra) # 58a2 <unlink>
  if(ret != -1){
    251a:	57fd                	li	a5,-1
    251c:	08f51363          	bne	a0,a5,25a2 <copyinstr3+0xd2>
  int fd = open(b, O_CREATE | O_WRONLY);
    2520:	20100593          	li	a1,513
    2524:	8526                	mv	a0,s1
    2526:	00003097          	auipc	ra,0x3
    252a:	36c080e7          	jalr	876(ra) # 5892 <open>
  if(fd != -1){
    252e:	57fd                	li	a5,-1
    2530:	08f51863          	bne	a0,a5,25c0 <copyinstr3+0xf0>
  ret = link(b, b);
    2534:	85a6                	mv	a1,s1
    2536:	8526                	mv	a0,s1
    2538:	00003097          	auipc	ra,0x3
    253c:	37a080e7          	jalr	890(ra) # 58b2 <link>
  if(ret != -1){
    2540:	57fd                	li	a5,-1
    2542:	08f51e63          	bne	a0,a5,25de <copyinstr3+0x10e>
  char *args[] = { "xx", 0 };
    2546:	00005797          	auipc	a5,0x5
    254a:	53a78793          	addi	a5,a5,1338 # 7a80 <malloc+0x1de0>
    254e:	fcf43823          	sd	a5,-48(s0)
    2552:	fc043c23          	sd	zero,-40(s0)
  ret = exec(b, args);
    2556:	fd040593          	addi	a1,s0,-48
    255a:	8526                	mv	a0,s1
    255c:	00003097          	auipc	ra,0x3
    2560:	32e080e7          	jalr	814(ra) # 588a <exec>
  if(ret != -1){
    2564:	57fd                	li	a5,-1
    2566:	08f51c63          	bne	a0,a5,25fe <copyinstr3+0x12e>
}
    256a:	70a2                	ld	ra,40(sp)
    256c:	7402                	ld	s0,32(sp)
    256e:	64e2                	ld	s1,24(sp)
    2570:	6145                	addi	sp,sp,48
    2572:	8082                	ret
    sbrk(PGSIZE - (top % PGSIZE));
    2574:	0347d513          	srli	a0,a5,0x34
    2578:	6785                	lui	a5,0x1
    257a:	40a7853b          	subw	a0,a5,a0
    257e:	00003097          	auipc	ra,0x3
    2582:	35c080e7          	jalr	860(ra) # 58da <sbrk>
    2586:	b7bd                	j	24f4 <copyinstr3+0x24>
    printf("oops\n");
    2588:	00005517          	auipc	a0,0x5
    258c:	88850513          	addi	a0,a0,-1912 # 6e10 <malloc+0x1170>
    2590:	00003097          	auipc	ra,0x3
    2594:	652080e7          	jalr	1618(ra) # 5be2 <printf>
    exit(1);
    2598:	4505                	li	a0,1
    259a:	00003097          	auipc	ra,0x3
    259e:	2b8080e7          	jalr	696(ra) # 5852 <exit>
    printf("unlink(%s) returned %d, not -1\n", b, ret);
    25a2:	862a                	mv	a2,a0
    25a4:	85a6                	mv	a1,s1
    25a6:	00004517          	auipc	a0,0x4
    25aa:	31250513          	addi	a0,a0,786 # 68b8 <malloc+0xc18>
    25ae:	00003097          	auipc	ra,0x3
    25b2:	634080e7          	jalr	1588(ra) # 5be2 <printf>
    exit(1);
    25b6:	4505                	li	a0,1
    25b8:	00003097          	auipc	ra,0x3
    25bc:	29a080e7          	jalr	666(ra) # 5852 <exit>
    printf("open(%s) returned %d, not -1\n", b, fd);
    25c0:	862a                	mv	a2,a0
    25c2:	85a6                	mv	a1,s1
    25c4:	00004517          	auipc	a0,0x4
    25c8:	31450513          	addi	a0,a0,788 # 68d8 <malloc+0xc38>
    25cc:	00003097          	auipc	ra,0x3
    25d0:	616080e7          	jalr	1558(ra) # 5be2 <printf>
    exit(1);
    25d4:	4505                	li	a0,1
    25d6:	00003097          	auipc	ra,0x3
    25da:	27c080e7          	jalr	636(ra) # 5852 <exit>
    printf("link(%s, %s) returned %d, not -1\n", b, b, ret);
    25de:	86aa                	mv	a3,a0
    25e0:	8626                	mv	a2,s1
    25e2:	85a6                	mv	a1,s1
    25e4:	00004517          	auipc	a0,0x4
    25e8:	31450513          	addi	a0,a0,788 # 68f8 <malloc+0xc58>
    25ec:	00003097          	auipc	ra,0x3
    25f0:	5f6080e7          	jalr	1526(ra) # 5be2 <printf>
    exit(1);
    25f4:	4505                	li	a0,1
    25f6:	00003097          	auipc	ra,0x3
    25fa:	25c080e7          	jalr	604(ra) # 5852 <exit>
    printf("exec(%s) returned %d, not -1\n", b, fd);
    25fe:	567d                	li	a2,-1
    2600:	85a6                	mv	a1,s1
    2602:	00004517          	auipc	a0,0x4
    2606:	31e50513          	addi	a0,a0,798 # 6920 <malloc+0xc80>
    260a:	00003097          	auipc	ra,0x3
    260e:	5d8080e7          	jalr	1496(ra) # 5be2 <printf>
    exit(1);
    2612:	4505                	li	a0,1
    2614:	00003097          	auipc	ra,0x3
    2618:	23e080e7          	jalr	574(ra) # 5852 <exit>

000000000000261c <rwsbrk>:
{
    261c:	1101                	addi	sp,sp,-32
    261e:	ec06                	sd	ra,24(sp)
    2620:	e822                	sd	s0,16(sp)
    2622:	e426                	sd	s1,8(sp)
    2624:	e04a                	sd	s2,0(sp)
    2626:	1000                	addi	s0,sp,32
  uint64 a = (uint64) sbrk(8192);
    2628:	6509                	lui	a0,0x2
    262a:	00003097          	auipc	ra,0x3
    262e:	2b0080e7          	jalr	688(ra) # 58da <sbrk>
  if(a == 0xffffffffffffffffLL) {
    2632:	57fd                	li	a5,-1
    2634:	06f50363          	beq	a0,a5,269a <rwsbrk+0x7e>
    2638:	84aa                	mv	s1,a0
  if ((uint64) sbrk(-8192) ==  0xffffffffffffffffLL) {
    263a:	7579                	lui	a0,0xffffe
    263c:	00003097          	auipc	ra,0x3
    2640:	29e080e7          	jalr	670(ra) # 58da <sbrk>
    2644:	57fd                	li	a5,-1
    2646:	06f50763          	beq	a0,a5,26b4 <rwsbrk+0x98>
  fd = open("rwsbrk", O_CREATE|O_WRONLY);
    264a:	20100593          	li	a1,513
    264e:	00003517          	auipc	a0,0x3
    2652:	7c250513          	addi	a0,a0,1986 # 5e10 <malloc+0x170>
    2656:	00003097          	auipc	ra,0x3
    265a:	23c080e7          	jalr	572(ra) # 5892 <open>
    265e:	892a                	mv	s2,a0
  if(fd < 0){
    2660:	06054763          	bltz	a0,26ce <rwsbrk+0xb2>
  n = write(fd, (void*)(a+4096), 1024);
    2664:	6505                	lui	a0,0x1
    2666:	94aa                	add	s1,s1,a0
    2668:	40000613          	li	a2,1024
    266c:	85a6                	mv	a1,s1
    266e:	854a                	mv	a0,s2
    2670:	00003097          	auipc	ra,0x3
    2674:	202080e7          	jalr	514(ra) # 5872 <write>
    2678:	862a                	mv	a2,a0
  if(n >= 0){
    267a:	06054763          	bltz	a0,26e8 <rwsbrk+0xcc>
    printf("write(fd, %p, 1024) returned %d, not -1\n", a+4096, n);
    267e:	85a6                	mv	a1,s1
    2680:	00004517          	auipc	a0,0x4
    2684:	7e850513          	addi	a0,a0,2024 # 6e68 <malloc+0x11c8>
    2688:	00003097          	auipc	ra,0x3
    268c:	55a080e7          	jalr	1370(ra) # 5be2 <printf>
    exit(1);
    2690:	4505                	li	a0,1
    2692:	00003097          	auipc	ra,0x3
    2696:	1c0080e7          	jalr	448(ra) # 5852 <exit>
    printf("sbrk(rwsbrk) failed\n");
    269a:	00004517          	auipc	a0,0x4
    269e:	77e50513          	addi	a0,a0,1918 # 6e18 <malloc+0x1178>
    26a2:	00003097          	auipc	ra,0x3
    26a6:	540080e7          	jalr	1344(ra) # 5be2 <printf>
    exit(1);
    26aa:	4505                	li	a0,1
    26ac:	00003097          	auipc	ra,0x3
    26b0:	1a6080e7          	jalr	422(ra) # 5852 <exit>
    printf("sbrk(rwsbrk) shrink failed\n");
    26b4:	00004517          	auipc	a0,0x4
    26b8:	77c50513          	addi	a0,a0,1916 # 6e30 <malloc+0x1190>
    26bc:	00003097          	auipc	ra,0x3
    26c0:	526080e7          	jalr	1318(ra) # 5be2 <printf>
    exit(1);
    26c4:	4505                	li	a0,1
    26c6:	00003097          	auipc	ra,0x3
    26ca:	18c080e7          	jalr	396(ra) # 5852 <exit>
    printf("open(rwsbrk) failed\n");
    26ce:	00004517          	auipc	a0,0x4
    26d2:	78250513          	addi	a0,a0,1922 # 6e50 <malloc+0x11b0>
    26d6:	00003097          	auipc	ra,0x3
    26da:	50c080e7          	jalr	1292(ra) # 5be2 <printf>
    exit(1);
    26de:	4505                	li	a0,1
    26e0:	00003097          	auipc	ra,0x3
    26e4:	172080e7          	jalr	370(ra) # 5852 <exit>
  close(fd);
    26e8:	854a                	mv	a0,s2
    26ea:	00003097          	auipc	ra,0x3
    26ee:	190080e7          	jalr	400(ra) # 587a <close>
  unlink("rwsbrk");
    26f2:	00003517          	auipc	a0,0x3
    26f6:	71e50513          	addi	a0,a0,1822 # 5e10 <malloc+0x170>
    26fa:	00003097          	auipc	ra,0x3
    26fe:	1a8080e7          	jalr	424(ra) # 58a2 <unlink>
  fd = open("README", O_RDONLY);
    2702:	4581                	li	a1,0
    2704:	00004517          	auipc	a0,0x4
    2708:	bf450513          	addi	a0,a0,-1036 # 62f8 <malloc+0x658>
    270c:	00003097          	auipc	ra,0x3
    2710:	186080e7          	jalr	390(ra) # 5892 <open>
    2714:	892a                	mv	s2,a0
  if(fd < 0){
    2716:	02054963          	bltz	a0,2748 <rwsbrk+0x12c>
  n = read(fd, (void*)(a+4096), 10);
    271a:	4629                	li	a2,10
    271c:	85a6                	mv	a1,s1
    271e:	00003097          	auipc	ra,0x3
    2722:	14c080e7          	jalr	332(ra) # 586a <read>
    2726:	862a                	mv	a2,a0
  if(n >= 0){
    2728:	02054d63          	bltz	a0,2762 <rwsbrk+0x146>
    printf("read(fd, %p, 10) returned %d, not -1\n", a+4096, n);
    272c:	85a6                	mv	a1,s1
    272e:	00004517          	auipc	a0,0x4
    2732:	76a50513          	addi	a0,a0,1898 # 6e98 <malloc+0x11f8>
    2736:	00003097          	auipc	ra,0x3
    273a:	4ac080e7          	jalr	1196(ra) # 5be2 <printf>
    exit(1);
    273e:	4505                	li	a0,1
    2740:	00003097          	auipc	ra,0x3
    2744:	112080e7          	jalr	274(ra) # 5852 <exit>
    printf("open(rwsbrk) failed\n");
    2748:	00004517          	auipc	a0,0x4
    274c:	70850513          	addi	a0,a0,1800 # 6e50 <malloc+0x11b0>
    2750:	00003097          	auipc	ra,0x3
    2754:	492080e7          	jalr	1170(ra) # 5be2 <printf>
    exit(1);
    2758:	4505                	li	a0,1
    275a:	00003097          	auipc	ra,0x3
    275e:	0f8080e7          	jalr	248(ra) # 5852 <exit>
  close(fd);
    2762:	854a                	mv	a0,s2
    2764:	00003097          	auipc	ra,0x3
    2768:	116080e7          	jalr	278(ra) # 587a <close>
  exit(0);
    276c:	4501                	li	a0,0
    276e:	00003097          	auipc	ra,0x3
    2772:	0e4080e7          	jalr	228(ra) # 5852 <exit>

0000000000002776 <sbrkbasic>:
{
    2776:	715d                	addi	sp,sp,-80
    2778:	e486                	sd	ra,72(sp)
    277a:	e0a2                	sd	s0,64(sp)
    277c:	fc26                	sd	s1,56(sp)
    277e:	f84a                	sd	s2,48(sp)
    2780:	f44e                	sd	s3,40(sp)
    2782:	f052                	sd	s4,32(sp)
    2784:	ec56                	sd	s5,24(sp)
    2786:	0880                	addi	s0,sp,80
    2788:	8a2a                	mv	s4,a0
  pid = fork();
    278a:	00003097          	auipc	ra,0x3
    278e:	0c0080e7          	jalr	192(ra) # 584a <fork>
  if(pid < 0){
    2792:	02054c63          	bltz	a0,27ca <sbrkbasic+0x54>
  if(pid == 0){
    2796:	ed21                	bnez	a0,27ee <sbrkbasic+0x78>
    a = sbrk(TOOMUCH);
    2798:	40000537          	lui	a0,0x40000
    279c:	00003097          	auipc	ra,0x3
    27a0:	13e080e7          	jalr	318(ra) # 58da <sbrk>
    if(a == (char*)0xffffffffffffffffL){
    27a4:	57fd                	li	a5,-1
    27a6:	02f50f63          	beq	a0,a5,27e4 <sbrkbasic+0x6e>
    for(b = a; b < a+TOOMUCH; b += 4096){
    27aa:	400007b7          	lui	a5,0x40000
    27ae:	97aa                	add	a5,a5,a0
      *b = 99;
    27b0:	06300693          	li	a3,99
    for(b = a; b < a+TOOMUCH; b += 4096){
    27b4:	6705                	lui	a4,0x1
      *b = 99;
    27b6:	00d50023          	sb	a3,0(a0) # 40000000 <__BSS_END__+0x3fff1218>
    for(b = a; b < a+TOOMUCH; b += 4096){
    27ba:	953a                	add	a0,a0,a4
    27bc:	fef51de3          	bne	a0,a5,27b6 <sbrkbasic+0x40>
    exit(1);
    27c0:	4505                	li	a0,1
    27c2:	00003097          	auipc	ra,0x3
    27c6:	090080e7          	jalr	144(ra) # 5852 <exit>
    printf("fork failed in sbrkbasic\n");
    27ca:	00004517          	auipc	a0,0x4
    27ce:	6f650513          	addi	a0,a0,1782 # 6ec0 <malloc+0x1220>
    27d2:	00003097          	auipc	ra,0x3
    27d6:	410080e7          	jalr	1040(ra) # 5be2 <printf>
    exit(1);
    27da:	4505                	li	a0,1
    27dc:	00003097          	auipc	ra,0x3
    27e0:	076080e7          	jalr	118(ra) # 5852 <exit>
      exit(0);
    27e4:	4501                	li	a0,0
    27e6:	00003097          	auipc	ra,0x3
    27ea:	06c080e7          	jalr	108(ra) # 5852 <exit>
  wait(&xstatus);
    27ee:	fbc40513          	addi	a0,s0,-68
    27f2:	00003097          	auipc	ra,0x3
    27f6:	068080e7          	jalr	104(ra) # 585a <wait>
  if(xstatus == 1){
    27fa:	fbc42703          	lw	a4,-68(s0)
    27fe:	4785                	li	a5,1
    2800:	00f70e63          	beq	a4,a5,281c <sbrkbasic+0xa6>
  a = sbrk(0);
    2804:	4501                	li	a0,0
    2806:	00003097          	auipc	ra,0x3
    280a:	0d4080e7          	jalr	212(ra) # 58da <sbrk>
    280e:	84aa                	mv	s1,a0
  for(i = 0; i < 5000; i++){
    2810:	4901                	li	s2,0
    *b = 1;
    2812:	4a85                	li	s5,1
  for(i = 0; i < 5000; i++){
    2814:	6985                	lui	s3,0x1
    2816:	38898993          	addi	s3,s3,904 # 1388 <copyinstr2+0xc6>
    281a:	a005                	j	283a <sbrkbasic+0xc4>
    printf("%s: too much memory allocated!\n", s);
    281c:	85d2                	mv	a1,s4
    281e:	00004517          	auipc	a0,0x4
    2822:	6c250513          	addi	a0,a0,1730 # 6ee0 <malloc+0x1240>
    2826:	00003097          	auipc	ra,0x3
    282a:	3bc080e7          	jalr	956(ra) # 5be2 <printf>
    exit(1);
    282e:	4505                	li	a0,1
    2830:	00003097          	auipc	ra,0x3
    2834:	022080e7          	jalr	34(ra) # 5852 <exit>
    a = b + 1;
    2838:	84be                	mv	s1,a5
    b = sbrk(1);
    283a:	4505                	li	a0,1
    283c:	00003097          	auipc	ra,0x3
    2840:	09e080e7          	jalr	158(ra) # 58da <sbrk>
    if(b != a){
    2844:	04951b63          	bne	a0,s1,289a <sbrkbasic+0x124>
    *b = 1;
    2848:	01548023          	sb	s5,0(s1)
    a = b + 1;
    284c:	00148793          	addi	a5,s1,1
  for(i = 0; i < 5000; i++){
    2850:	2905                	addiw	s2,s2,1
    2852:	ff3913e3          	bne	s2,s3,2838 <sbrkbasic+0xc2>
  pid = fork();
    2856:	00003097          	auipc	ra,0x3
    285a:	ff4080e7          	jalr	-12(ra) # 584a <fork>
    285e:	892a                	mv	s2,a0
  if(pid < 0){
    2860:	04054e63          	bltz	a0,28bc <sbrkbasic+0x146>
  c = sbrk(1);
    2864:	4505                	li	a0,1
    2866:	00003097          	auipc	ra,0x3
    286a:	074080e7          	jalr	116(ra) # 58da <sbrk>
  c = sbrk(1);
    286e:	4505                	li	a0,1
    2870:	00003097          	auipc	ra,0x3
    2874:	06a080e7          	jalr	106(ra) # 58da <sbrk>
  if(c != a + 1){
    2878:	0489                	addi	s1,s1,2
    287a:	04a48f63          	beq	s1,a0,28d8 <sbrkbasic+0x162>
    printf("%s: sbrk test failed post-fork\n", s);
    287e:	85d2                	mv	a1,s4
    2880:	00004517          	auipc	a0,0x4
    2884:	6c050513          	addi	a0,a0,1728 # 6f40 <malloc+0x12a0>
    2888:	00003097          	auipc	ra,0x3
    288c:	35a080e7          	jalr	858(ra) # 5be2 <printf>
    exit(1);
    2890:	4505                	li	a0,1
    2892:	00003097          	auipc	ra,0x3
    2896:	fc0080e7          	jalr	-64(ra) # 5852 <exit>
      printf("%s: sbrk test failed %d %x %x\n", s, i, a, b);
    289a:	872a                	mv	a4,a0
    289c:	86a6                	mv	a3,s1
    289e:	864a                	mv	a2,s2
    28a0:	85d2                	mv	a1,s4
    28a2:	00004517          	auipc	a0,0x4
    28a6:	65e50513          	addi	a0,a0,1630 # 6f00 <malloc+0x1260>
    28aa:	00003097          	auipc	ra,0x3
    28ae:	338080e7          	jalr	824(ra) # 5be2 <printf>
      exit(1);
    28b2:	4505                	li	a0,1
    28b4:	00003097          	auipc	ra,0x3
    28b8:	f9e080e7          	jalr	-98(ra) # 5852 <exit>
    printf("%s: sbrk test fork failed\n", s);
    28bc:	85d2                	mv	a1,s4
    28be:	00004517          	auipc	a0,0x4
    28c2:	66250513          	addi	a0,a0,1634 # 6f20 <malloc+0x1280>
    28c6:	00003097          	auipc	ra,0x3
    28ca:	31c080e7          	jalr	796(ra) # 5be2 <printf>
    exit(1);
    28ce:	4505                	li	a0,1
    28d0:	00003097          	auipc	ra,0x3
    28d4:	f82080e7          	jalr	-126(ra) # 5852 <exit>
  if(pid == 0)
    28d8:	00091763          	bnez	s2,28e6 <sbrkbasic+0x170>
    exit(0);
    28dc:	4501                	li	a0,0
    28de:	00003097          	auipc	ra,0x3
    28e2:	f74080e7          	jalr	-140(ra) # 5852 <exit>
  wait(&xstatus);
    28e6:	fbc40513          	addi	a0,s0,-68
    28ea:	00003097          	auipc	ra,0x3
    28ee:	f70080e7          	jalr	-144(ra) # 585a <wait>
  exit(xstatus);
    28f2:	fbc42503          	lw	a0,-68(s0)
    28f6:	00003097          	auipc	ra,0x3
    28fa:	f5c080e7          	jalr	-164(ra) # 5852 <exit>

00000000000028fe <sbrkmuch>:
{
    28fe:	7179                	addi	sp,sp,-48
    2900:	f406                	sd	ra,40(sp)
    2902:	f022                	sd	s0,32(sp)
    2904:	ec26                	sd	s1,24(sp)
    2906:	e84a                	sd	s2,16(sp)
    2908:	e44e                	sd	s3,8(sp)
    290a:	e052                	sd	s4,0(sp)
    290c:	1800                	addi	s0,sp,48
    290e:	89aa                	mv	s3,a0
  oldbrk = sbrk(0);
    2910:	4501                	li	a0,0
    2912:	00003097          	auipc	ra,0x3
    2916:	fc8080e7          	jalr	-56(ra) # 58da <sbrk>
    291a:	892a                	mv	s2,a0
  a = sbrk(0);
    291c:	4501                	li	a0,0
    291e:	00003097          	auipc	ra,0x3
    2922:	fbc080e7          	jalr	-68(ra) # 58da <sbrk>
    2926:	84aa                	mv	s1,a0
  p = sbrk(amt);
    2928:	06400537          	lui	a0,0x6400
    292c:	9d05                	subw	a0,a0,s1
    292e:	00003097          	auipc	ra,0x3
    2932:	fac080e7          	jalr	-84(ra) # 58da <sbrk>
  if (p != a) {
    2936:	0ca49863          	bne	s1,a0,2a06 <sbrkmuch+0x108>
  char *eee = sbrk(0);
    293a:	4501                	li	a0,0
    293c:	00003097          	auipc	ra,0x3
    2940:	f9e080e7          	jalr	-98(ra) # 58da <sbrk>
    2944:	87aa                	mv	a5,a0
  for(char *pp = a; pp < eee; pp += 4096)
    2946:	00a4f963          	bgeu	s1,a0,2958 <sbrkmuch+0x5a>
    *pp = 1;
    294a:	4685                	li	a3,1
  for(char *pp = a; pp < eee; pp += 4096)
    294c:	6705                	lui	a4,0x1
    *pp = 1;
    294e:	00d48023          	sb	a3,0(s1)
  for(char *pp = a; pp < eee; pp += 4096)
    2952:	94ba                	add	s1,s1,a4
    2954:	fef4ede3          	bltu	s1,a5,294e <sbrkmuch+0x50>
  *lastaddr = 99;
    2958:	064007b7          	lui	a5,0x6400
    295c:	06300713          	li	a4,99
    2960:	fee78fa3          	sb	a4,-1(a5) # 63fffff <__BSS_END__+0x63f1217>
  a = sbrk(0);
    2964:	4501                	li	a0,0
    2966:	00003097          	auipc	ra,0x3
    296a:	f74080e7          	jalr	-140(ra) # 58da <sbrk>
    296e:	84aa                	mv	s1,a0
  c = sbrk(-PGSIZE);
    2970:	757d                	lui	a0,0xfffff
    2972:	00003097          	auipc	ra,0x3
    2976:	f68080e7          	jalr	-152(ra) # 58da <sbrk>
  if(c == (char*)0xffffffffffffffffL){
    297a:	57fd                	li	a5,-1
    297c:	0af50363          	beq	a0,a5,2a22 <sbrkmuch+0x124>
  c = sbrk(0);
    2980:	4501                	li	a0,0
    2982:	00003097          	auipc	ra,0x3
    2986:	f58080e7          	jalr	-168(ra) # 58da <sbrk>
  if(c != a - PGSIZE){
    298a:	77fd                	lui	a5,0xfffff
    298c:	97a6                	add	a5,a5,s1
    298e:	0af51863          	bne	a0,a5,2a3e <sbrkmuch+0x140>
  a = sbrk(0);
    2992:	4501                	li	a0,0
    2994:	00003097          	auipc	ra,0x3
    2998:	f46080e7          	jalr	-186(ra) # 58da <sbrk>
    299c:	84aa                	mv	s1,a0
  c = sbrk(PGSIZE);
    299e:	6505                	lui	a0,0x1
    29a0:	00003097          	auipc	ra,0x3
    29a4:	f3a080e7          	jalr	-198(ra) # 58da <sbrk>
    29a8:	8a2a                	mv	s4,a0
  if(c != a || sbrk(0) != a + PGSIZE){
    29aa:	0aa49a63          	bne	s1,a0,2a5e <sbrkmuch+0x160>
    29ae:	4501                	li	a0,0
    29b0:	00003097          	auipc	ra,0x3
    29b4:	f2a080e7          	jalr	-214(ra) # 58da <sbrk>
    29b8:	6785                	lui	a5,0x1
    29ba:	97a6                	add	a5,a5,s1
    29bc:	0af51163          	bne	a0,a5,2a5e <sbrkmuch+0x160>
  if(*lastaddr == 99){
    29c0:	064007b7          	lui	a5,0x6400
    29c4:	fff7c703          	lbu	a4,-1(a5) # 63fffff <__BSS_END__+0x63f1217>
    29c8:	06300793          	li	a5,99
    29cc:	0af70963          	beq	a4,a5,2a7e <sbrkmuch+0x180>
  a = sbrk(0);
    29d0:	4501                	li	a0,0
    29d2:	00003097          	auipc	ra,0x3
    29d6:	f08080e7          	jalr	-248(ra) # 58da <sbrk>
    29da:	84aa                	mv	s1,a0
  c = sbrk(-(sbrk(0) - oldbrk));
    29dc:	4501                	li	a0,0
    29de:	00003097          	auipc	ra,0x3
    29e2:	efc080e7          	jalr	-260(ra) # 58da <sbrk>
    29e6:	40a9053b          	subw	a0,s2,a0
    29ea:	00003097          	auipc	ra,0x3
    29ee:	ef0080e7          	jalr	-272(ra) # 58da <sbrk>
  if(c != a){
    29f2:	0aa49463          	bne	s1,a0,2a9a <sbrkmuch+0x19c>
}
    29f6:	70a2                	ld	ra,40(sp)
    29f8:	7402                	ld	s0,32(sp)
    29fa:	64e2                	ld	s1,24(sp)
    29fc:	6942                	ld	s2,16(sp)
    29fe:	69a2                	ld	s3,8(sp)
    2a00:	6a02                	ld	s4,0(sp)
    2a02:	6145                	addi	sp,sp,48
    2a04:	8082                	ret
    printf("%s: sbrk test failed to grow big address space; enough phys mem?\n", s);
    2a06:	85ce                	mv	a1,s3
    2a08:	00004517          	auipc	a0,0x4
    2a0c:	55850513          	addi	a0,a0,1368 # 6f60 <malloc+0x12c0>
    2a10:	00003097          	auipc	ra,0x3
    2a14:	1d2080e7          	jalr	466(ra) # 5be2 <printf>
    exit(1);
    2a18:	4505                	li	a0,1
    2a1a:	00003097          	auipc	ra,0x3
    2a1e:	e38080e7          	jalr	-456(ra) # 5852 <exit>
    printf("%s: sbrk could not deallocate\n", s);
    2a22:	85ce                	mv	a1,s3
    2a24:	00004517          	auipc	a0,0x4
    2a28:	58450513          	addi	a0,a0,1412 # 6fa8 <malloc+0x1308>
    2a2c:	00003097          	auipc	ra,0x3
    2a30:	1b6080e7          	jalr	438(ra) # 5be2 <printf>
    exit(1);
    2a34:	4505                	li	a0,1
    2a36:	00003097          	auipc	ra,0x3
    2a3a:	e1c080e7          	jalr	-484(ra) # 5852 <exit>
    printf("%s: sbrk deallocation produced wrong address, a %x c %x\n", s, a, c);
    2a3e:	86aa                	mv	a3,a0
    2a40:	8626                	mv	a2,s1
    2a42:	85ce                	mv	a1,s3
    2a44:	00004517          	auipc	a0,0x4
    2a48:	58450513          	addi	a0,a0,1412 # 6fc8 <malloc+0x1328>
    2a4c:	00003097          	auipc	ra,0x3
    2a50:	196080e7          	jalr	406(ra) # 5be2 <printf>
    exit(1);
    2a54:	4505                	li	a0,1
    2a56:	00003097          	auipc	ra,0x3
    2a5a:	dfc080e7          	jalr	-516(ra) # 5852 <exit>
    printf("%s: sbrk re-allocation failed, a %x c %x\n", s, a, c);
    2a5e:	86d2                	mv	a3,s4
    2a60:	8626                	mv	a2,s1
    2a62:	85ce                	mv	a1,s3
    2a64:	00004517          	auipc	a0,0x4
    2a68:	5a450513          	addi	a0,a0,1444 # 7008 <malloc+0x1368>
    2a6c:	00003097          	auipc	ra,0x3
    2a70:	176080e7          	jalr	374(ra) # 5be2 <printf>
    exit(1);
    2a74:	4505                	li	a0,1
    2a76:	00003097          	auipc	ra,0x3
    2a7a:	ddc080e7          	jalr	-548(ra) # 5852 <exit>
    printf("%s: sbrk de-allocation didn't really deallocate\n", s);
    2a7e:	85ce                	mv	a1,s3
    2a80:	00004517          	auipc	a0,0x4
    2a84:	5b850513          	addi	a0,a0,1464 # 7038 <malloc+0x1398>
    2a88:	00003097          	auipc	ra,0x3
    2a8c:	15a080e7          	jalr	346(ra) # 5be2 <printf>
    exit(1);
    2a90:	4505                	li	a0,1
    2a92:	00003097          	auipc	ra,0x3
    2a96:	dc0080e7          	jalr	-576(ra) # 5852 <exit>
    printf("%s: sbrk downsize failed, a %x c %x\n", s, a, c);
    2a9a:	86aa                	mv	a3,a0
    2a9c:	8626                	mv	a2,s1
    2a9e:	85ce                	mv	a1,s3
    2aa0:	00004517          	auipc	a0,0x4
    2aa4:	5d050513          	addi	a0,a0,1488 # 7070 <malloc+0x13d0>
    2aa8:	00003097          	auipc	ra,0x3
    2aac:	13a080e7          	jalr	314(ra) # 5be2 <printf>
    exit(1);
    2ab0:	4505                	li	a0,1
    2ab2:	00003097          	auipc	ra,0x3
    2ab6:	da0080e7          	jalr	-608(ra) # 5852 <exit>

0000000000002aba <sbrkarg>:
{
    2aba:	7179                	addi	sp,sp,-48
    2abc:	f406                	sd	ra,40(sp)
    2abe:	f022                	sd	s0,32(sp)
    2ac0:	ec26                	sd	s1,24(sp)
    2ac2:	e84a                	sd	s2,16(sp)
    2ac4:	e44e                	sd	s3,8(sp)
    2ac6:	1800                	addi	s0,sp,48
    2ac8:	89aa                	mv	s3,a0
  a = sbrk(PGSIZE);
    2aca:	6505                	lui	a0,0x1
    2acc:	00003097          	auipc	ra,0x3
    2ad0:	e0e080e7          	jalr	-498(ra) # 58da <sbrk>
    2ad4:	892a                	mv	s2,a0
  fd = open("sbrk", O_CREATE|O_WRONLY);
    2ad6:	20100593          	li	a1,513
    2ada:	00004517          	auipc	a0,0x4
    2ade:	5be50513          	addi	a0,a0,1470 # 7098 <malloc+0x13f8>
    2ae2:	00003097          	auipc	ra,0x3
    2ae6:	db0080e7          	jalr	-592(ra) # 5892 <open>
    2aea:	84aa                	mv	s1,a0
  unlink("sbrk");
    2aec:	00004517          	auipc	a0,0x4
    2af0:	5ac50513          	addi	a0,a0,1452 # 7098 <malloc+0x13f8>
    2af4:	00003097          	auipc	ra,0x3
    2af8:	dae080e7          	jalr	-594(ra) # 58a2 <unlink>
  if(fd < 0)  {
    2afc:	0404c163          	bltz	s1,2b3e <sbrkarg+0x84>
  if ((n = write(fd, a, PGSIZE)) < 0) {
    2b00:	6605                	lui	a2,0x1
    2b02:	85ca                	mv	a1,s2
    2b04:	8526                	mv	a0,s1
    2b06:	00003097          	auipc	ra,0x3
    2b0a:	d6c080e7          	jalr	-660(ra) # 5872 <write>
    2b0e:	04054663          	bltz	a0,2b5a <sbrkarg+0xa0>
  close(fd);
    2b12:	8526                	mv	a0,s1
    2b14:	00003097          	auipc	ra,0x3
    2b18:	d66080e7          	jalr	-666(ra) # 587a <close>
  a = sbrk(PGSIZE);
    2b1c:	6505                	lui	a0,0x1
    2b1e:	00003097          	auipc	ra,0x3
    2b22:	dbc080e7          	jalr	-580(ra) # 58da <sbrk>
  if(pipe((int *) a) != 0){
    2b26:	00003097          	auipc	ra,0x3
    2b2a:	d3c080e7          	jalr	-708(ra) # 5862 <pipe>
    2b2e:	e521                	bnez	a0,2b76 <sbrkarg+0xbc>
}
    2b30:	70a2                	ld	ra,40(sp)
    2b32:	7402                	ld	s0,32(sp)
    2b34:	64e2                	ld	s1,24(sp)
    2b36:	6942                	ld	s2,16(sp)
    2b38:	69a2                	ld	s3,8(sp)
    2b3a:	6145                	addi	sp,sp,48
    2b3c:	8082                	ret
    printf("%s: open sbrk failed\n", s);
    2b3e:	85ce                	mv	a1,s3
    2b40:	00004517          	auipc	a0,0x4
    2b44:	56050513          	addi	a0,a0,1376 # 70a0 <malloc+0x1400>
    2b48:	00003097          	auipc	ra,0x3
    2b4c:	09a080e7          	jalr	154(ra) # 5be2 <printf>
    exit(1);
    2b50:	4505                	li	a0,1
    2b52:	00003097          	auipc	ra,0x3
    2b56:	d00080e7          	jalr	-768(ra) # 5852 <exit>
    printf("%s: write sbrk failed\n", s);
    2b5a:	85ce                	mv	a1,s3
    2b5c:	00004517          	auipc	a0,0x4
    2b60:	55c50513          	addi	a0,a0,1372 # 70b8 <malloc+0x1418>
    2b64:	00003097          	auipc	ra,0x3
    2b68:	07e080e7          	jalr	126(ra) # 5be2 <printf>
    exit(1);
    2b6c:	4505                	li	a0,1
    2b6e:	00003097          	auipc	ra,0x3
    2b72:	ce4080e7          	jalr	-796(ra) # 5852 <exit>
    printf("%s: pipe() failed\n", s);
    2b76:	85ce                	mv	a1,s3
    2b78:	00004517          	auipc	a0,0x4
    2b7c:	f2850513          	addi	a0,a0,-216 # 6aa0 <malloc+0xe00>
    2b80:	00003097          	auipc	ra,0x3
    2b84:	062080e7          	jalr	98(ra) # 5be2 <printf>
    exit(1);
    2b88:	4505                	li	a0,1
    2b8a:	00003097          	auipc	ra,0x3
    2b8e:	cc8080e7          	jalr	-824(ra) # 5852 <exit>

0000000000002b92 <argptest>:
{
    2b92:	1101                	addi	sp,sp,-32
    2b94:	ec06                	sd	ra,24(sp)
    2b96:	e822                	sd	s0,16(sp)
    2b98:	e426                	sd	s1,8(sp)
    2b9a:	e04a                	sd	s2,0(sp)
    2b9c:	1000                	addi	s0,sp,32
    2b9e:	892a                	mv	s2,a0
  fd = open("init", O_RDONLY);
    2ba0:	4581                	li	a1,0
    2ba2:	00004517          	auipc	a0,0x4
    2ba6:	52e50513          	addi	a0,a0,1326 # 70d0 <malloc+0x1430>
    2baa:	00003097          	auipc	ra,0x3
    2bae:	ce8080e7          	jalr	-792(ra) # 5892 <open>
  if (fd < 0) {
    2bb2:	02054b63          	bltz	a0,2be8 <argptest+0x56>
    2bb6:	84aa                	mv	s1,a0
  read(fd, sbrk(0) - 1, -1);
    2bb8:	4501                	li	a0,0
    2bba:	00003097          	auipc	ra,0x3
    2bbe:	d20080e7          	jalr	-736(ra) # 58da <sbrk>
    2bc2:	567d                	li	a2,-1
    2bc4:	fff50593          	addi	a1,a0,-1
    2bc8:	8526                	mv	a0,s1
    2bca:	00003097          	auipc	ra,0x3
    2bce:	ca0080e7          	jalr	-864(ra) # 586a <read>
  close(fd);
    2bd2:	8526                	mv	a0,s1
    2bd4:	00003097          	auipc	ra,0x3
    2bd8:	ca6080e7          	jalr	-858(ra) # 587a <close>
}
    2bdc:	60e2                	ld	ra,24(sp)
    2bde:	6442                	ld	s0,16(sp)
    2be0:	64a2                	ld	s1,8(sp)
    2be2:	6902                	ld	s2,0(sp)
    2be4:	6105                	addi	sp,sp,32
    2be6:	8082                	ret
    printf("%s: open failed\n", s);
    2be8:	85ca                	mv	a1,s2
    2bea:	00004517          	auipc	a0,0x4
    2bee:	dc650513          	addi	a0,a0,-570 # 69b0 <malloc+0xd10>
    2bf2:	00003097          	auipc	ra,0x3
    2bf6:	ff0080e7          	jalr	-16(ra) # 5be2 <printf>
    exit(1);
    2bfa:	4505                	li	a0,1
    2bfc:	00003097          	auipc	ra,0x3
    2c00:	c56080e7          	jalr	-938(ra) # 5852 <exit>

0000000000002c04 <sbrkbugs>:
{
    2c04:	1141                	addi	sp,sp,-16
    2c06:	e406                	sd	ra,8(sp)
    2c08:	e022                	sd	s0,0(sp)
    2c0a:	0800                	addi	s0,sp,16
  int pid = fork();
    2c0c:	00003097          	auipc	ra,0x3
    2c10:	c3e080e7          	jalr	-962(ra) # 584a <fork>
  if(pid < 0){
    2c14:	02054263          	bltz	a0,2c38 <sbrkbugs+0x34>
  if(pid == 0){
    2c18:	ed0d                	bnez	a0,2c52 <sbrkbugs+0x4e>
    int sz = (uint64) sbrk(0);
    2c1a:	00003097          	auipc	ra,0x3
    2c1e:	cc0080e7          	jalr	-832(ra) # 58da <sbrk>
    sbrk(-sz);
    2c22:	40a0053b          	negw	a0,a0
    2c26:	00003097          	auipc	ra,0x3
    2c2a:	cb4080e7          	jalr	-844(ra) # 58da <sbrk>
    exit(0);
    2c2e:	4501                	li	a0,0
    2c30:	00003097          	auipc	ra,0x3
    2c34:	c22080e7          	jalr	-990(ra) # 5852 <exit>
    printf("fork failed\n");
    2c38:	00004517          	auipc	a0,0x4
    2c3c:	18050513          	addi	a0,a0,384 # 6db8 <malloc+0x1118>
    2c40:	00003097          	auipc	ra,0x3
    2c44:	fa2080e7          	jalr	-94(ra) # 5be2 <printf>
    exit(1);
    2c48:	4505                	li	a0,1
    2c4a:	00003097          	auipc	ra,0x3
    2c4e:	c08080e7          	jalr	-1016(ra) # 5852 <exit>
  wait(0);
    2c52:	4501                	li	a0,0
    2c54:	00003097          	auipc	ra,0x3
    2c58:	c06080e7          	jalr	-1018(ra) # 585a <wait>
  pid = fork();
    2c5c:	00003097          	auipc	ra,0x3
    2c60:	bee080e7          	jalr	-1042(ra) # 584a <fork>
  if(pid < 0){
    2c64:	02054563          	bltz	a0,2c8e <sbrkbugs+0x8a>
  if(pid == 0){
    2c68:	e121                	bnez	a0,2ca8 <sbrkbugs+0xa4>
    int sz = (uint64) sbrk(0);
    2c6a:	00003097          	auipc	ra,0x3
    2c6e:	c70080e7          	jalr	-912(ra) # 58da <sbrk>
    sbrk(-(sz - 3500));
    2c72:	6785                	lui	a5,0x1
    2c74:	dac7879b          	addiw	a5,a5,-596
    2c78:	40a7853b          	subw	a0,a5,a0
    2c7c:	00003097          	auipc	ra,0x3
    2c80:	c5e080e7          	jalr	-930(ra) # 58da <sbrk>
    exit(0);
    2c84:	4501                	li	a0,0
    2c86:	00003097          	auipc	ra,0x3
    2c8a:	bcc080e7          	jalr	-1076(ra) # 5852 <exit>
    printf("fork failed\n");
    2c8e:	00004517          	auipc	a0,0x4
    2c92:	12a50513          	addi	a0,a0,298 # 6db8 <malloc+0x1118>
    2c96:	00003097          	auipc	ra,0x3
    2c9a:	f4c080e7          	jalr	-180(ra) # 5be2 <printf>
    exit(1);
    2c9e:	4505                	li	a0,1
    2ca0:	00003097          	auipc	ra,0x3
    2ca4:	bb2080e7          	jalr	-1102(ra) # 5852 <exit>
  wait(0);
    2ca8:	4501                	li	a0,0
    2caa:	00003097          	auipc	ra,0x3
    2cae:	bb0080e7          	jalr	-1104(ra) # 585a <wait>
  pid = fork();
    2cb2:	00003097          	auipc	ra,0x3
    2cb6:	b98080e7          	jalr	-1128(ra) # 584a <fork>
  if(pid < 0){
    2cba:	02054a63          	bltz	a0,2cee <sbrkbugs+0xea>
  if(pid == 0){
    2cbe:	e529                	bnez	a0,2d08 <sbrkbugs+0x104>
    sbrk((10*4096 + 2048) - (uint64)sbrk(0));
    2cc0:	00003097          	auipc	ra,0x3
    2cc4:	c1a080e7          	jalr	-998(ra) # 58da <sbrk>
    2cc8:	67ad                	lui	a5,0xb
    2cca:	8007879b          	addiw	a5,a5,-2048
    2cce:	40a7853b          	subw	a0,a5,a0
    2cd2:	00003097          	auipc	ra,0x3
    2cd6:	c08080e7          	jalr	-1016(ra) # 58da <sbrk>
    sbrk(-10);
    2cda:	5559                	li	a0,-10
    2cdc:	00003097          	auipc	ra,0x3
    2ce0:	bfe080e7          	jalr	-1026(ra) # 58da <sbrk>
    exit(0);
    2ce4:	4501                	li	a0,0
    2ce6:	00003097          	auipc	ra,0x3
    2cea:	b6c080e7          	jalr	-1172(ra) # 5852 <exit>
    printf("fork failed\n");
    2cee:	00004517          	auipc	a0,0x4
    2cf2:	0ca50513          	addi	a0,a0,202 # 6db8 <malloc+0x1118>
    2cf6:	00003097          	auipc	ra,0x3
    2cfa:	eec080e7          	jalr	-276(ra) # 5be2 <printf>
    exit(1);
    2cfe:	4505                	li	a0,1
    2d00:	00003097          	auipc	ra,0x3
    2d04:	b52080e7          	jalr	-1198(ra) # 5852 <exit>
  wait(0);
    2d08:	4501                	li	a0,0
    2d0a:	00003097          	auipc	ra,0x3
    2d0e:	b50080e7          	jalr	-1200(ra) # 585a <wait>
  exit(0);
    2d12:	4501                	li	a0,0
    2d14:	00003097          	auipc	ra,0x3
    2d18:	b3e080e7          	jalr	-1218(ra) # 5852 <exit>

0000000000002d1c <sbrklast>:
{
    2d1c:	7179                	addi	sp,sp,-48
    2d1e:	f406                	sd	ra,40(sp)
    2d20:	f022                	sd	s0,32(sp)
    2d22:	ec26                	sd	s1,24(sp)
    2d24:	e84a                	sd	s2,16(sp)
    2d26:	e44e                	sd	s3,8(sp)
    2d28:	1800                	addi	s0,sp,48
  uint64 top = (uint64) sbrk(0);
    2d2a:	4501                	li	a0,0
    2d2c:	00003097          	auipc	ra,0x3
    2d30:	bae080e7          	jalr	-1106(ra) # 58da <sbrk>
  if((top % 4096) != 0)
    2d34:	03451793          	slli	a5,a0,0x34
    2d38:	efc1                	bnez	a5,2dd0 <sbrklast+0xb4>
  sbrk(4096);
    2d3a:	6505                	lui	a0,0x1
    2d3c:	00003097          	auipc	ra,0x3
    2d40:	b9e080e7          	jalr	-1122(ra) # 58da <sbrk>
  sbrk(10);
    2d44:	4529                	li	a0,10
    2d46:	00003097          	auipc	ra,0x3
    2d4a:	b94080e7          	jalr	-1132(ra) # 58da <sbrk>
  sbrk(-20);
    2d4e:	5531                	li	a0,-20
    2d50:	00003097          	auipc	ra,0x3
    2d54:	b8a080e7          	jalr	-1142(ra) # 58da <sbrk>
  top = (uint64) sbrk(0);
    2d58:	4501                	li	a0,0
    2d5a:	00003097          	auipc	ra,0x3
    2d5e:	b80080e7          	jalr	-1152(ra) # 58da <sbrk>
    2d62:	84aa                	mv	s1,a0
  char *p = (char *) (top - 64);
    2d64:	fc050913          	addi	s2,a0,-64 # fc0 <linktest+0x19a>
  p[0] = 'x';
    2d68:	07800793          	li	a5,120
    2d6c:	fcf50023          	sb	a5,-64(a0)
  p[1] = '\0';
    2d70:	fc0500a3          	sb	zero,-63(a0)
  int fd = open(p, O_RDWR|O_CREATE);
    2d74:	20200593          	li	a1,514
    2d78:	854a                	mv	a0,s2
    2d7a:	00003097          	auipc	ra,0x3
    2d7e:	b18080e7          	jalr	-1256(ra) # 5892 <open>
    2d82:	89aa                	mv	s3,a0
  write(fd, p, 1);
    2d84:	4605                	li	a2,1
    2d86:	85ca                	mv	a1,s2
    2d88:	00003097          	auipc	ra,0x3
    2d8c:	aea080e7          	jalr	-1302(ra) # 5872 <write>
  close(fd);
    2d90:	854e                	mv	a0,s3
    2d92:	00003097          	auipc	ra,0x3
    2d96:	ae8080e7          	jalr	-1304(ra) # 587a <close>
  fd = open(p, O_RDWR);
    2d9a:	4589                	li	a1,2
    2d9c:	854a                	mv	a0,s2
    2d9e:	00003097          	auipc	ra,0x3
    2da2:	af4080e7          	jalr	-1292(ra) # 5892 <open>
  p[0] = '\0';
    2da6:	fc048023          	sb	zero,-64(s1)
  read(fd, p, 1);
    2daa:	4605                	li	a2,1
    2dac:	85ca                	mv	a1,s2
    2dae:	00003097          	auipc	ra,0x3
    2db2:	abc080e7          	jalr	-1348(ra) # 586a <read>
  if(p[0] != 'x')
    2db6:	fc04c703          	lbu	a4,-64(s1)
    2dba:	07800793          	li	a5,120
    2dbe:	02f71363          	bne	a4,a5,2de4 <sbrklast+0xc8>
}
    2dc2:	70a2                	ld	ra,40(sp)
    2dc4:	7402                	ld	s0,32(sp)
    2dc6:	64e2                	ld	s1,24(sp)
    2dc8:	6942                	ld	s2,16(sp)
    2dca:	69a2                	ld	s3,8(sp)
    2dcc:	6145                	addi	sp,sp,48
    2dce:	8082                	ret
    sbrk(4096 - (top % 4096));
    2dd0:	0347d513          	srli	a0,a5,0x34
    2dd4:	6785                	lui	a5,0x1
    2dd6:	40a7853b          	subw	a0,a5,a0
    2dda:	00003097          	auipc	ra,0x3
    2dde:	b00080e7          	jalr	-1280(ra) # 58da <sbrk>
    2de2:	bfa1                	j	2d3a <sbrklast+0x1e>
    exit(1);
    2de4:	4505                	li	a0,1
    2de6:	00003097          	auipc	ra,0x3
    2dea:	a6c080e7          	jalr	-1428(ra) # 5852 <exit>

0000000000002dee <sbrk8000>:
{
    2dee:	1141                	addi	sp,sp,-16
    2df0:	e406                	sd	ra,8(sp)
    2df2:	e022                	sd	s0,0(sp)
    2df4:	0800                	addi	s0,sp,16
  sbrk(0x80000004);
    2df6:	80000537          	lui	a0,0x80000
    2dfa:	0511                	addi	a0,a0,4
    2dfc:	00003097          	auipc	ra,0x3
    2e00:	ade080e7          	jalr	-1314(ra) # 58da <sbrk>
  volatile char *top = sbrk(0);
    2e04:	4501                	li	a0,0
    2e06:	00003097          	auipc	ra,0x3
    2e0a:	ad4080e7          	jalr	-1324(ra) # 58da <sbrk>
  *(top-1) = *(top-1) + 1;
    2e0e:	fff54783          	lbu	a5,-1(a0) # ffffffff7fffffff <__BSS_END__+0xffffffff7fff1217>
    2e12:	0785                	addi	a5,a5,1
    2e14:	0ff7f793          	andi	a5,a5,255
    2e18:	fef50fa3          	sb	a5,-1(a0)
}
    2e1c:	60a2                	ld	ra,8(sp)
    2e1e:	6402                	ld	s0,0(sp)
    2e20:	0141                	addi	sp,sp,16
    2e22:	8082                	ret

0000000000002e24 <execout>:
// test the exec() code that cleans up if it runs out
// of memory. it's really a test that such a condition
// doesn't cause a panic.
void
execout(char *s)
{
    2e24:	715d                	addi	sp,sp,-80
    2e26:	e486                	sd	ra,72(sp)
    2e28:	e0a2                	sd	s0,64(sp)
    2e2a:	fc26                	sd	s1,56(sp)
    2e2c:	f84a                	sd	s2,48(sp)
    2e2e:	f44e                	sd	s3,40(sp)
    2e30:	f052                	sd	s4,32(sp)
    2e32:	0880                	addi	s0,sp,80
  for(int avail = 0; avail < 15; avail++){
    2e34:	4901                	li	s2,0
    2e36:	49bd                	li	s3,15
    int pid = fork();
    2e38:	00003097          	auipc	ra,0x3
    2e3c:	a12080e7          	jalr	-1518(ra) # 584a <fork>
    2e40:	84aa                	mv	s1,a0
    if(pid < 0){
    2e42:	02054063          	bltz	a0,2e62 <execout+0x3e>
      printf("fork failed\n");
      exit(1);
    } else if(pid == 0){
    2e46:	c91d                	beqz	a0,2e7c <execout+0x58>
      close(1);
      char *args[] = { "echo", "x", 0 };
      exec("echo", args);
      exit(0);
    } else {
      wait((int*)0);
    2e48:	4501                	li	a0,0
    2e4a:	00003097          	auipc	ra,0x3
    2e4e:	a10080e7          	jalr	-1520(ra) # 585a <wait>
  for(int avail = 0; avail < 15; avail++){
    2e52:	2905                	addiw	s2,s2,1
    2e54:	ff3912e3          	bne	s2,s3,2e38 <execout+0x14>
    }
  }

  exit(0);
    2e58:	4501                	li	a0,0
    2e5a:	00003097          	auipc	ra,0x3
    2e5e:	9f8080e7          	jalr	-1544(ra) # 5852 <exit>
      printf("fork failed\n");
    2e62:	00004517          	auipc	a0,0x4
    2e66:	f5650513          	addi	a0,a0,-170 # 6db8 <malloc+0x1118>
    2e6a:	00003097          	auipc	ra,0x3
    2e6e:	d78080e7          	jalr	-648(ra) # 5be2 <printf>
      exit(1);
    2e72:	4505                	li	a0,1
    2e74:	00003097          	auipc	ra,0x3
    2e78:	9de080e7          	jalr	-1570(ra) # 5852 <exit>
        if(a == 0xffffffffffffffffLL)
    2e7c:	59fd                	li	s3,-1
        *(char*)(a + 4096 - 1) = 1;
    2e7e:	4a05                	li	s4,1
        uint64 a = (uint64) sbrk(4096);
    2e80:	6505                	lui	a0,0x1
    2e82:	00003097          	auipc	ra,0x3
    2e86:	a58080e7          	jalr	-1448(ra) # 58da <sbrk>
        if(a == 0xffffffffffffffffLL)
    2e8a:	01350763          	beq	a0,s3,2e98 <execout+0x74>
        *(char*)(a + 4096 - 1) = 1;
    2e8e:	6785                	lui	a5,0x1
    2e90:	953e                	add	a0,a0,a5
    2e92:	ff450fa3          	sb	s4,-1(a0) # fff <linktest+0x1d9>
      while(1){
    2e96:	b7ed                	j	2e80 <execout+0x5c>
      for(int i = 0; i < avail; i++)
    2e98:	01205a63          	blez	s2,2eac <execout+0x88>
        sbrk(-4096);
    2e9c:	757d                	lui	a0,0xfffff
    2e9e:	00003097          	auipc	ra,0x3
    2ea2:	a3c080e7          	jalr	-1476(ra) # 58da <sbrk>
      for(int i = 0; i < avail; i++)
    2ea6:	2485                	addiw	s1,s1,1
    2ea8:	ff249ae3          	bne	s1,s2,2e9c <execout+0x78>
      close(1);
    2eac:	4505                	li	a0,1
    2eae:	00003097          	auipc	ra,0x3
    2eb2:	9cc080e7          	jalr	-1588(ra) # 587a <close>
      char *args[] = { "echo", "x", 0 };
    2eb6:	00003517          	auipc	a0,0x3
    2eba:	27a50513          	addi	a0,a0,634 # 6130 <malloc+0x490>
    2ebe:	faa43c23          	sd	a0,-72(s0)
    2ec2:	00003797          	auipc	a5,0x3
    2ec6:	2de78793          	addi	a5,a5,734 # 61a0 <malloc+0x500>
    2eca:	fcf43023          	sd	a5,-64(s0)
    2ece:	fc043423          	sd	zero,-56(s0)
      exec("echo", args);
    2ed2:	fb840593          	addi	a1,s0,-72
    2ed6:	00003097          	auipc	ra,0x3
    2eda:	9b4080e7          	jalr	-1612(ra) # 588a <exec>
      exit(0);
    2ede:	4501                	li	a0,0
    2ee0:	00003097          	auipc	ra,0x3
    2ee4:	972080e7          	jalr	-1678(ra) # 5852 <exit>

0000000000002ee8 <fourteen>:
{
    2ee8:	1101                	addi	sp,sp,-32
    2eea:	ec06                	sd	ra,24(sp)
    2eec:	e822                	sd	s0,16(sp)
    2eee:	e426                	sd	s1,8(sp)
    2ef0:	1000                	addi	s0,sp,32
    2ef2:	84aa                	mv	s1,a0
  if(mkdir("12345678901234") != 0){
    2ef4:	00004517          	auipc	a0,0x4
    2ef8:	3b450513          	addi	a0,a0,948 # 72a8 <malloc+0x1608>
    2efc:	00003097          	auipc	ra,0x3
    2f00:	9be080e7          	jalr	-1602(ra) # 58ba <mkdir>
    2f04:	e165                	bnez	a0,2fe4 <fourteen+0xfc>
  if(mkdir("12345678901234/123456789012345") != 0){
    2f06:	00004517          	auipc	a0,0x4
    2f0a:	1fa50513          	addi	a0,a0,506 # 7100 <malloc+0x1460>
    2f0e:	00003097          	auipc	ra,0x3
    2f12:	9ac080e7          	jalr	-1620(ra) # 58ba <mkdir>
    2f16:	e56d                	bnez	a0,3000 <fourteen+0x118>
  fd = open("123456789012345/123456789012345/123456789012345", O_CREATE);
    2f18:	20000593          	li	a1,512
    2f1c:	00004517          	auipc	a0,0x4
    2f20:	23c50513          	addi	a0,a0,572 # 7158 <malloc+0x14b8>
    2f24:	00003097          	auipc	ra,0x3
    2f28:	96e080e7          	jalr	-1682(ra) # 5892 <open>
  if(fd < 0){
    2f2c:	0e054863          	bltz	a0,301c <fourteen+0x134>
  close(fd);
    2f30:	00003097          	auipc	ra,0x3
    2f34:	94a080e7          	jalr	-1718(ra) # 587a <close>
  fd = open("12345678901234/12345678901234/12345678901234", 0);
    2f38:	4581                	li	a1,0
    2f3a:	00004517          	auipc	a0,0x4
    2f3e:	29650513          	addi	a0,a0,662 # 71d0 <malloc+0x1530>
    2f42:	00003097          	auipc	ra,0x3
    2f46:	950080e7          	jalr	-1712(ra) # 5892 <open>
  if(fd < 0){
    2f4a:	0e054763          	bltz	a0,3038 <fourteen+0x150>
  close(fd);
    2f4e:	00003097          	auipc	ra,0x3
    2f52:	92c080e7          	jalr	-1748(ra) # 587a <close>
  if(mkdir("12345678901234/12345678901234") == 0){
    2f56:	00004517          	auipc	a0,0x4
    2f5a:	2ea50513          	addi	a0,a0,746 # 7240 <malloc+0x15a0>
    2f5e:	00003097          	auipc	ra,0x3
    2f62:	95c080e7          	jalr	-1700(ra) # 58ba <mkdir>
    2f66:	c57d                	beqz	a0,3054 <fourteen+0x16c>
  if(mkdir("123456789012345/12345678901234") == 0){
    2f68:	00004517          	auipc	a0,0x4
    2f6c:	33050513          	addi	a0,a0,816 # 7298 <malloc+0x15f8>
    2f70:	00003097          	auipc	ra,0x3
    2f74:	94a080e7          	jalr	-1718(ra) # 58ba <mkdir>
    2f78:	cd65                	beqz	a0,3070 <fourteen+0x188>
  unlink("123456789012345/12345678901234");
    2f7a:	00004517          	auipc	a0,0x4
    2f7e:	31e50513          	addi	a0,a0,798 # 7298 <malloc+0x15f8>
    2f82:	00003097          	auipc	ra,0x3
    2f86:	920080e7          	jalr	-1760(ra) # 58a2 <unlink>
  unlink("12345678901234/12345678901234");
    2f8a:	00004517          	auipc	a0,0x4
    2f8e:	2b650513          	addi	a0,a0,694 # 7240 <malloc+0x15a0>
    2f92:	00003097          	auipc	ra,0x3
    2f96:	910080e7          	jalr	-1776(ra) # 58a2 <unlink>
  unlink("12345678901234/12345678901234/12345678901234");
    2f9a:	00004517          	auipc	a0,0x4
    2f9e:	23650513          	addi	a0,a0,566 # 71d0 <malloc+0x1530>
    2fa2:	00003097          	auipc	ra,0x3
    2fa6:	900080e7          	jalr	-1792(ra) # 58a2 <unlink>
  unlink("123456789012345/123456789012345/123456789012345");
    2faa:	00004517          	auipc	a0,0x4
    2fae:	1ae50513          	addi	a0,a0,430 # 7158 <malloc+0x14b8>
    2fb2:	00003097          	auipc	ra,0x3
    2fb6:	8f0080e7          	jalr	-1808(ra) # 58a2 <unlink>
  unlink("12345678901234/123456789012345");
    2fba:	00004517          	auipc	a0,0x4
    2fbe:	14650513          	addi	a0,a0,326 # 7100 <malloc+0x1460>
    2fc2:	00003097          	auipc	ra,0x3
    2fc6:	8e0080e7          	jalr	-1824(ra) # 58a2 <unlink>
  unlink("12345678901234");
    2fca:	00004517          	auipc	a0,0x4
    2fce:	2de50513          	addi	a0,a0,734 # 72a8 <malloc+0x1608>
    2fd2:	00003097          	auipc	ra,0x3
    2fd6:	8d0080e7          	jalr	-1840(ra) # 58a2 <unlink>
}
    2fda:	60e2                	ld	ra,24(sp)
    2fdc:	6442                	ld	s0,16(sp)
    2fde:	64a2                	ld	s1,8(sp)
    2fe0:	6105                	addi	sp,sp,32
    2fe2:	8082                	ret
    printf("%s: mkdir 12345678901234 failed\n", s);
    2fe4:	85a6                	mv	a1,s1
    2fe6:	00004517          	auipc	a0,0x4
    2fea:	0f250513          	addi	a0,a0,242 # 70d8 <malloc+0x1438>
    2fee:	00003097          	auipc	ra,0x3
    2ff2:	bf4080e7          	jalr	-1036(ra) # 5be2 <printf>
    exit(1);
    2ff6:	4505                	li	a0,1
    2ff8:	00003097          	auipc	ra,0x3
    2ffc:	85a080e7          	jalr	-1958(ra) # 5852 <exit>
    printf("%s: mkdir 12345678901234/123456789012345 failed\n", s);
    3000:	85a6                	mv	a1,s1
    3002:	00004517          	auipc	a0,0x4
    3006:	11e50513          	addi	a0,a0,286 # 7120 <malloc+0x1480>
    300a:	00003097          	auipc	ra,0x3
    300e:	bd8080e7          	jalr	-1064(ra) # 5be2 <printf>
    exit(1);
    3012:	4505                	li	a0,1
    3014:	00003097          	auipc	ra,0x3
    3018:	83e080e7          	jalr	-1986(ra) # 5852 <exit>
    printf("%s: create 123456789012345/123456789012345/123456789012345 failed\n", s);
    301c:	85a6                	mv	a1,s1
    301e:	00004517          	auipc	a0,0x4
    3022:	16a50513          	addi	a0,a0,362 # 7188 <malloc+0x14e8>
    3026:	00003097          	auipc	ra,0x3
    302a:	bbc080e7          	jalr	-1092(ra) # 5be2 <printf>
    exit(1);
    302e:	4505                	li	a0,1
    3030:	00003097          	auipc	ra,0x3
    3034:	822080e7          	jalr	-2014(ra) # 5852 <exit>
    printf("%s: open 12345678901234/12345678901234/12345678901234 failed\n", s);
    3038:	85a6                	mv	a1,s1
    303a:	00004517          	auipc	a0,0x4
    303e:	1c650513          	addi	a0,a0,454 # 7200 <malloc+0x1560>
    3042:	00003097          	auipc	ra,0x3
    3046:	ba0080e7          	jalr	-1120(ra) # 5be2 <printf>
    exit(1);
    304a:	4505                	li	a0,1
    304c:	00003097          	auipc	ra,0x3
    3050:	806080e7          	jalr	-2042(ra) # 5852 <exit>
    printf("%s: mkdir 12345678901234/12345678901234 succeeded!\n", s);
    3054:	85a6                	mv	a1,s1
    3056:	00004517          	auipc	a0,0x4
    305a:	20a50513          	addi	a0,a0,522 # 7260 <malloc+0x15c0>
    305e:	00003097          	auipc	ra,0x3
    3062:	b84080e7          	jalr	-1148(ra) # 5be2 <printf>
    exit(1);
    3066:	4505                	li	a0,1
    3068:	00002097          	auipc	ra,0x2
    306c:	7ea080e7          	jalr	2026(ra) # 5852 <exit>
    printf("%s: mkdir 12345678901234/123456789012345 succeeded!\n", s);
    3070:	85a6                	mv	a1,s1
    3072:	00004517          	auipc	a0,0x4
    3076:	24650513          	addi	a0,a0,582 # 72b8 <malloc+0x1618>
    307a:	00003097          	auipc	ra,0x3
    307e:	b68080e7          	jalr	-1176(ra) # 5be2 <printf>
    exit(1);
    3082:	4505                	li	a0,1
    3084:	00002097          	auipc	ra,0x2
    3088:	7ce080e7          	jalr	1998(ra) # 5852 <exit>

000000000000308c <iputtest>:
{
    308c:	1101                	addi	sp,sp,-32
    308e:	ec06                	sd	ra,24(sp)
    3090:	e822                	sd	s0,16(sp)
    3092:	e426                	sd	s1,8(sp)
    3094:	1000                	addi	s0,sp,32
    3096:	84aa                	mv	s1,a0
  if(mkdir("iputdir") < 0){
    3098:	00004517          	auipc	a0,0x4
    309c:	25850513          	addi	a0,a0,600 # 72f0 <malloc+0x1650>
    30a0:	00003097          	auipc	ra,0x3
    30a4:	81a080e7          	jalr	-2022(ra) # 58ba <mkdir>
    30a8:	04054563          	bltz	a0,30f2 <iputtest+0x66>
  if(chdir("iputdir") < 0){
    30ac:	00004517          	auipc	a0,0x4
    30b0:	24450513          	addi	a0,a0,580 # 72f0 <malloc+0x1650>
    30b4:	00003097          	auipc	ra,0x3
    30b8:	80e080e7          	jalr	-2034(ra) # 58c2 <chdir>
    30bc:	04054963          	bltz	a0,310e <iputtest+0x82>
  if(unlink("../iputdir") < 0){
    30c0:	00004517          	auipc	a0,0x4
    30c4:	27050513          	addi	a0,a0,624 # 7330 <malloc+0x1690>
    30c8:	00002097          	auipc	ra,0x2
    30cc:	7da080e7          	jalr	2010(ra) # 58a2 <unlink>
    30d0:	04054d63          	bltz	a0,312a <iputtest+0x9e>
  if(chdir("/") < 0){
    30d4:	00004517          	auipc	a0,0x4
    30d8:	28c50513          	addi	a0,a0,652 # 7360 <malloc+0x16c0>
    30dc:	00002097          	auipc	ra,0x2
    30e0:	7e6080e7          	jalr	2022(ra) # 58c2 <chdir>
    30e4:	06054163          	bltz	a0,3146 <iputtest+0xba>
}
    30e8:	60e2                	ld	ra,24(sp)
    30ea:	6442                	ld	s0,16(sp)
    30ec:	64a2                	ld	s1,8(sp)
    30ee:	6105                	addi	sp,sp,32
    30f0:	8082                	ret
    printf("%s: mkdir failed\n", s);
    30f2:	85a6                	mv	a1,s1
    30f4:	00004517          	auipc	a0,0x4
    30f8:	20450513          	addi	a0,a0,516 # 72f8 <malloc+0x1658>
    30fc:	00003097          	auipc	ra,0x3
    3100:	ae6080e7          	jalr	-1306(ra) # 5be2 <printf>
    exit(1);
    3104:	4505                	li	a0,1
    3106:	00002097          	auipc	ra,0x2
    310a:	74c080e7          	jalr	1868(ra) # 5852 <exit>
    printf("%s: chdir iputdir failed\n", s);
    310e:	85a6                	mv	a1,s1
    3110:	00004517          	auipc	a0,0x4
    3114:	20050513          	addi	a0,a0,512 # 7310 <malloc+0x1670>
    3118:	00003097          	auipc	ra,0x3
    311c:	aca080e7          	jalr	-1334(ra) # 5be2 <printf>
    exit(1);
    3120:	4505                	li	a0,1
    3122:	00002097          	auipc	ra,0x2
    3126:	730080e7          	jalr	1840(ra) # 5852 <exit>
    printf("%s: unlink ../iputdir failed\n", s);
    312a:	85a6                	mv	a1,s1
    312c:	00004517          	auipc	a0,0x4
    3130:	21450513          	addi	a0,a0,532 # 7340 <malloc+0x16a0>
    3134:	00003097          	auipc	ra,0x3
    3138:	aae080e7          	jalr	-1362(ra) # 5be2 <printf>
    exit(1);
    313c:	4505                	li	a0,1
    313e:	00002097          	auipc	ra,0x2
    3142:	714080e7          	jalr	1812(ra) # 5852 <exit>
    printf("%s: chdir / failed\n", s);
    3146:	85a6                	mv	a1,s1
    3148:	00004517          	auipc	a0,0x4
    314c:	22050513          	addi	a0,a0,544 # 7368 <malloc+0x16c8>
    3150:	00003097          	auipc	ra,0x3
    3154:	a92080e7          	jalr	-1390(ra) # 5be2 <printf>
    exit(1);
    3158:	4505                	li	a0,1
    315a:	00002097          	auipc	ra,0x2
    315e:	6f8080e7          	jalr	1784(ra) # 5852 <exit>

0000000000003162 <exitiputtest>:
{
    3162:	7179                	addi	sp,sp,-48
    3164:	f406                	sd	ra,40(sp)
    3166:	f022                	sd	s0,32(sp)
    3168:	ec26                	sd	s1,24(sp)
    316a:	1800                	addi	s0,sp,48
    316c:	84aa                	mv	s1,a0
  pid = fork();
    316e:	00002097          	auipc	ra,0x2
    3172:	6dc080e7          	jalr	1756(ra) # 584a <fork>
  if(pid < 0){
    3176:	04054663          	bltz	a0,31c2 <exitiputtest+0x60>
  if(pid == 0){
    317a:	ed45                	bnez	a0,3232 <exitiputtest+0xd0>
    if(mkdir("iputdir") < 0){
    317c:	00004517          	auipc	a0,0x4
    3180:	17450513          	addi	a0,a0,372 # 72f0 <malloc+0x1650>
    3184:	00002097          	auipc	ra,0x2
    3188:	736080e7          	jalr	1846(ra) # 58ba <mkdir>
    318c:	04054963          	bltz	a0,31de <exitiputtest+0x7c>
    if(chdir("iputdir") < 0){
    3190:	00004517          	auipc	a0,0x4
    3194:	16050513          	addi	a0,a0,352 # 72f0 <malloc+0x1650>
    3198:	00002097          	auipc	ra,0x2
    319c:	72a080e7          	jalr	1834(ra) # 58c2 <chdir>
    31a0:	04054d63          	bltz	a0,31fa <exitiputtest+0x98>
    if(unlink("../iputdir") < 0){
    31a4:	00004517          	auipc	a0,0x4
    31a8:	18c50513          	addi	a0,a0,396 # 7330 <malloc+0x1690>
    31ac:	00002097          	auipc	ra,0x2
    31b0:	6f6080e7          	jalr	1782(ra) # 58a2 <unlink>
    31b4:	06054163          	bltz	a0,3216 <exitiputtest+0xb4>
    exit(0);
    31b8:	4501                	li	a0,0
    31ba:	00002097          	auipc	ra,0x2
    31be:	698080e7          	jalr	1688(ra) # 5852 <exit>
    printf("%s: fork failed\n", s);
    31c2:	85a6                	mv	a1,s1
    31c4:	00003517          	auipc	a0,0x3
    31c8:	7d450513          	addi	a0,a0,2004 # 6998 <malloc+0xcf8>
    31cc:	00003097          	auipc	ra,0x3
    31d0:	a16080e7          	jalr	-1514(ra) # 5be2 <printf>
    exit(1);
    31d4:	4505                	li	a0,1
    31d6:	00002097          	auipc	ra,0x2
    31da:	67c080e7          	jalr	1660(ra) # 5852 <exit>
      printf("%s: mkdir failed\n", s);
    31de:	85a6                	mv	a1,s1
    31e0:	00004517          	auipc	a0,0x4
    31e4:	11850513          	addi	a0,a0,280 # 72f8 <malloc+0x1658>
    31e8:	00003097          	auipc	ra,0x3
    31ec:	9fa080e7          	jalr	-1542(ra) # 5be2 <printf>
      exit(1);
    31f0:	4505                	li	a0,1
    31f2:	00002097          	auipc	ra,0x2
    31f6:	660080e7          	jalr	1632(ra) # 5852 <exit>
      printf("%s: child chdir failed\n", s);
    31fa:	85a6                	mv	a1,s1
    31fc:	00004517          	auipc	a0,0x4
    3200:	18450513          	addi	a0,a0,388 # 7380 <malloc+0x16e0>
    3204:	00003097          	auipc	ra,0x3
    3208:	9de080e7          	jalr	-1570(ra) # 5be2 <printf>
      exit(1);
    320c:	4505                	li	a0,1
    320e:	00002097          	auipc	ra,0x2
    3212:	644080e7          	jalr	1604(ra) # 5852 <exit>
      printf("%s: unlink ../iputdir failed\n", s);
    3216:	85a6                	mv	a1,s1
    3218:	00004517          	auipc	a0,0x4
    321c:	12850513          	addi	a0,a0,296 # 7340 <malloc+0x16a0>
    3220:	00003097          	auipc	ra,0x3
    3224:	9c2080e7          	jalr	-1598(ra) # 5be2 <printf>
      exit(1);
    3228:	4505                	li	a0,1
    322a:	00002097          	auipc	ra,0x2
    322e:	628080e7          	jalr	1576(ra) # 5852 <exit>
  wait(&xstatus);
    3232:	fdc40513          	addi	a0,s0,-36
    3236:	00002097          	auipc	ra,0x2
    323a:	624080e7          	jalr	1572(ra) # 585a <wait>
  exit(xstatus);
    323e:	fdc42503          	lw	a0,-36(s0)
    3242:	00002097          	auipc	ra,0x2
    3246:	610080e7          	jalr	1552(ra) # 5852 <exit>

000000000000324a <dirtest>:
{
    324a:	1101                	addi	sp,sp,-32
    324c:	ec06                	sd	ra,24(sp)
    324e:	e822                	sd	s0,16(sp)
    3250:	e426                	sd	s1,8(sp)
    3252:	1000                	addi	s0,sp,32
    3254:	84aa                	mv	s1,a0
  if(mkdir("dir0") < 0){
    3256:	00004517          	auipc	a0,0x4
    325a:	14250513          	addi	a0,a0,322 # 7398 <malloc+0x16f8>
    325e:	00002097          	auipc	ra,0x2
    3262:	65c080e7          	jalr	1628(ra) # 58ba <mkdir>
    3266:	04054563          	bltz	a0,32b0 <dirtest+0x66>
  if(chdir("dir0") < 0){
    326a:	00004517          	auipc	a0,0x4
    326e:	12e50513          	addi	a0,a0,302 # 7398 <malloc+0x16f8>
    3272:	00002097          	auipc	ra,0x2
    3276:	650080e7          	jalr	1616(ra) # 58c2 <chdir>
    327a:	04054963          	bltz	a0,32cc <dirtest+0x82>
  if(chdir("..") < 0){
    327e:	00004517          	auipc	a0,0x4
    3282:	13a50513          	addi	a0,a0,314 # 73b8 <malloc+0x1718>
    3286:	00002097          	auipc	ra,0x2
    328a:	63c080e7          	jalr	1596(ra) # 58c2 <chdir>
    328e:	04054d63          	bltz	a0,32e8 <dirtest+0x9e>
  if(unlink("dir0") < 0){
    3292:	00004517          	auipc	a0,0x4
    3296:	10650513          	addi	a0,a0,262 # 7398 <malloc+0x16f8>
    329a:	00002097          	auipc	ra,0x2
    329e:	608080e7          	jalr	1544(ra) # 58a2 <unlink>
    32a2:	06054163          	bltz	a0,3304 <dirtest+0xba>
}
    32a6:	60e2                	ld	ra,24(sp)
    32a8:	6442                	ld	s0,16(sp)
    32aa:	64a2                	ld	s1,8(sp)
    32ac:	6105                	addi	sp,sp,32
    32ae:	8082                	ret
    printf("%s: mkdir failed\n", s);
    32b0:	85a6                	mv	a1,s1
    32b2:	00004517          	auipc	a0,0x4
    32b6:	04650513          	addi	a0,a0,70 # 72f8 <malloc+0x1658>
    32ba:	00003097          	auipc	ra,0x3
    32be:	928080e7          	jalr	-1752(ra) # 5be2 <printf>
    exit(1);
    32c2:	4505                	li	a0,1
    32c4:	00002097          	auipc	ra,0x2
    32c8:	58e080e7          	jalr	1422(ra) # 5852 <exit>
    printf("%s: chdir dir0 failed\n", s);
    32cc:	85a6                	mv	a1,s1
    32ce:	00004517          	auipc	a0,0x4
    32d2:	0d250513          	addi	a0,a0,210 # 73a0 <malloc+0x1700>
    32d6:	00003097          	auipc	ra,0x3
    32da:	90c080e7          	jalr	-1780(ra) # 5be2 <printf>
    exit(1);
    32de:	4505                	li	a0,1
    32e0:	00002097          	auipc	ra,0x2
    32e4:	572080e7          	jalr	1394(ra) # 5852 <exit>
    printf("%s: chdir .. failed\n", s);
    32e8:	85a6                	mv	a1,s1
    32ea:	00004517          	auipc	a0,0x4
    32ee:	0d650513          	addi	a0,a0,214 # 73c0 <malloc+0x1720>
    32f2:	00003097          	auipc	ra,0x3
    32f6:	8f0080e7          	jalr	-1808(ra) # 5be2 <printf>
    exit(1);
    32fa:	4505                	li	a0,1
    32fc:	00002097          	auipc	ra,0x2
    3300:	556080e7          	jalr	1366(ra) # 5852 <exit>
    printf("%s: unlink dir0 failed\n", s);
    3304:	85a6                	mv	a1,s1
    3306:	00004517          	auipc	a0,0x4
    330a:	0d250513          	addi	a0,a0,210 # 73d8 <malloc+0x1738>
    330e:	00003097          	auipc	ra,0x3
    3312:	8d4080e7          	jalr	-1836(ra) # 5be2 <printf>
    exit(1);
    3316:	4505                	li	a0,1
    3318:	00002097          	auipc	ra,0x2
    331c:	53a080e7          	jalr	1338(ra) # 5852 <exit>

0000000000003320 <subdir>:
{
    3320:	1101                	addi	sp,sp,-32
    3322:	ec06                	sd	ra,24(sp)
    3324:	e822                	sd	s0,16(sp)
    3326:	e426                	sd	s1,8(sp)
    3328:	e04a                	sd	s2,0(sp)
    332a:	1000                	addi	s0,sp,32
    332c:	892a                	mv	s2,a0
  unlink("ff");
    332e:	00004517          	auipc	a0,0x4
    3332:	1f250513          	addi	a0,a0,498 # 7520 <malloc+0x1880>
    3336:	00002097          	auipc	ra,0x2
    333a:	56c080e7          	jalr	1388(ra) # 58a2 <unlink>
  if(mkdir("dd") != 0){
    333e:	00004517          	auipc	a0,0x4
    3342:	0b250513          	addi	a0,a0,178 # 73f0 <malloc+0x1750>
    3346:	00002097          	auipc	ra,0x2
    334a:	574080e7          	jalr	1396(ra) # 58ba <mkdir>
    334e:	38051663          	bnez	a0,36da <subdir+0x3ba>
  fd = open("dd/ff", O_CREATE | O_RDWR);
    3352:	20200593          	li	a1,514
    3356:	00004517          	auipc	a0,0x4
    335a:	0ba50513          	addi	a0,a0,186 # 7410 <malloc+0x1770>
    335e:	00002097          	auipc	ra,0x2
    3362:	534080e7          	jalr	1332(ra) # 5892 <open>
    3366:	84aa                	mv	s1,a0
  if(fd < 0){
    3368:	38054763          	bltz	a0,36f6 <subdir+0x3d6>
  write(fd, "ff", 2);
    336c:	4609                	li	a2,2
    336e:	00004597          	auipc	a1,0x4
    3372:	1b258593          	addi	a1,a1,434 # 7520 <malloc+0x1880>
    3376:	00002097          	auipc	ra,0x2
    337a:	4fc080e7          	jalr	1276(ra) # 5872 <write>
  close(fd);
    337e:	8526                	mv	a0,s1
    3380:	00002097          	auipc	ra,0x2
    3384:	4fa080e7          	jalr	1274(ra) # 587a <close>
  if(unlink("dd") >= 0){
    3388:	00004517          	auipc	a0,0x4
    338c:	06850513          	addi	a0,a0,104 # 73f0 <malloc+0x1750>
    3390:	00002097          	auipc	ra,0x2
    3394:	512080e7          	jalr	1298(ra) # 58a2 <unlink>
    3398:	36055d63          	bgez	a0,3712 <subdir+0x3f2>
  if(mkdir("/dd/dd") != 0){
    339c:	00004517          	auipc	a0,0x4
    33a0:	0cc50513          	addi	a0,a0,204 # 7468 <malloc+0x17c8>
    33a4:	00002097          	auipc	ra,0x2
    33a8:	516080e7          	jalr	1302(ra) # 58ba <mkdir>
    33ac:	38051163          	bnez	a0,372e <subdir+0x40e>
  fd = open("dd/dd/ff", O_CREATE | O_RDWR);
    33b0:	20200593          	li	a1,514
    33b4:	00004517          	auipc	a0,0x4
    33b8:	0dc50513          	addi	a0,a0,220 # 7490 <malloc+0x17f0>
    33bc:	00002097          	auipc	ra,0x2
    33c0:	4d6080e7          	jalr	1238(ra) # 5892 <open>
    33c4:	84aa                	mv	s1,a0
  if(fd < 0){
    33c6:	38054263          	bltz	a0,374a <subdir+0x42a>
  write(fd, "FF", 2);
    33ca:	4609                	li	a2,2
    33cc:	00004597          	auipc	a1,0x4
    33d0:	0f458593          	addi	a1,a1,244 # 74c0 <malloc+0x1820>
    33d4:	00002097          	auipc	ra,0x2
    33d8:	49e080e7          	jalr	1182(ra) # 5872 <write>
  close(fd);
    33dc:	8526                	mv	a0,s1
    33de:	00002097          	auipc	ra,0x2
    33e2:	49c080e7          	jalr	1180(ra) # 587a <close>
  fd = open("dd/dd/../ff", 0);
    33e6:	4581                	li	a1,0
    33e8:	00004517          	auipc	a0,0x4
    33ec:	0e050513          	addi	a0,a0,224 # 74c8 <malloc+0x1828>
    33f0:	00002097          	auipc	ra,0x2
    33f4:	4a2080e7          	jalr	1186(ra) # 5892 <open>
    33f8:	84aa                	mv	s1,a0
  if(fd < 0){
    33fa:	36054663          	bltz	a0,3766 <subdir+0x446>
  cc = read(fd, buf, sizeof(buf));
    33fe:	660d                	lui	a2,0x3
    3400:	00009597          	auipc	a1,0x9
    3404:	9d858593          	addi	a1,a1,-1576 # bdd8 <buf>
    3408:	00002097          	auipc	ra,0x2
    340c:	462080e7          	jalr	1122(ra) # 586a <read>
  if(cc != 2 || buf[0] != 'f'){
    3410:	4789                	li	a5,2
    3412:	36f51863          	bne	a0,a5,3782 <subdir+0x462>
    3416:	00009717          	auipc	a4,0x9
    341a:	9c274703          	lbu	a4,-1598(a4) # bdd8 <buf>
    341e:	06600793          	li	a5,102
    3422:	36f71063          	bne	a4,a5,3782 <subdir+0x462>
  close(fd);
    3426:	8526                	mv	a0,s1
    3428:	00002097          	auipc	ra,0x2
    342c:	452080e7          	jalr	1106(ra) # 587a <close>
  if(link("dd/dd/ff", "dd/dd/ffff") != 0){
    3430:	00004597          	auipc	a1,0x4
    3434:	0e858593          	addi	a1,a1,232 # 7518 <malloc+0x1878>
    3438:	00004517          	auipc	a0,0x4
    343c:	05850513          	addi	a0,a0,88 # 7490 <malloc+0x17f0>
    3440:	00002097          	auipc	ra,0x2
    3444:	472080e7          	jalr	1138(ra) # 58b2 <link>
    3448:	34051b63          	bnez	a0,379e <subdir+0x47e>
  if(unlink("dd/dd/ff") != 0){
    344c:	00004517          	auipc	a0,0x4
    3450:	04450513          	addi	a0,a0,68 # 7490 <malloc+0x17f0>
    3454:	00002097          	auipc	ra,0x2
    3458:	44e080e7          	jalr	1102(ra) # 58a2 <unlink>
    345c:	34051f63          	bnez	a0,37ba <subdir+0x49a>
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    3460:	4581                	li	a1,0
    3462:	00004517          	auipc	a0,0x4
    3466:	02e50513          	addi	a0,a0,46 # 7490 <malloc+0x17f0>
    346a:	00002097          	auipc	ra,0x2
    346e:	428080e7          	jalr	1064(ra) # 5892 <open>
    3472:	36055263          	bgez	a0,37d6 <subdir+0x4b6>
  if(chdir("dd") != 0){
    3476:	00004517          	auipc	a0,0x4
    347a:	f7a50513          	addi	a0,a0,-134 # 73f0 <malloc+0x1750>
    347e:	00002097          	auipc	ra,0x2
    3482:	444080e7          	jalr	1092(ra) # 58c2 <chdir>
    3486:	36051663          	bnez	a0,37f2 <subdir+0x4d2>
  if(chdir("dd/../../dd") != 0){
    348a:	00004517          	auipc	a0,0x4
    348e:	12650513          	addi	a0,a0,294 # 75b0 <malloc+0x1910>
    3492:	00002097          	auipc	ra,0x2
    3496:	430080e7          	jalr	1072(ra) # 58c2 <chdir>
    349a:	36051a63          	bnez	a0,380e <subdir+0x4ee>
  if(chdir("dd/../../../dd") != 0){
    349e:	00004517          	auipc	a0,0x4
    34a2:	14250513          	addi	a0,a0,322 # 75e0 <malloc+0x1940>
    34a6:	00002097          	auipc	ra,0x2
    34aa:	41c080e7          	jalr	1052(ra) # 58c2 <chdir>
    34ae:	36051e63          	bnez	a0,382a <subdir+0x50a>
  if(chdir("./..") != 0){
    34b2:	00004517          	auipc	a0,0x4
    34b6:	15e50513          	addi	a0,a0,350 # 7610 <malloc+0x1970>
    34ba:	00002097          	auipc	ra,0x2
    34be:	408080e7          	jalr	1032(ra) # 58c2 <chdir>
    34c2:	38051263          	bnez	a0,3846 <subdir+0x526>
  fd = open("dd/dd/ffff", 0);
    34c6:	4581                	li	a1,0
    34c8:	00004517          	auipc	a0,0x4
    34cc:	05050513          	addi	a0,a0,80 # 7518 <malloc+0x1878>
    34d0:	00002097          	auipc	ra,0x2
    34d4:	3c2080e7          	jalr	962(ra) # 5892 <open>
    34d8:	84aa                	mv	s1,a0
  if(fd < 0){
    34da:	38054463          	bltz	a0,3862 <subdir+0x542>
  if(read(fd, buf, sizeof(buf)) != 2){
    34de:	660d                	lui	a2,0x3
    34e0:	00009597          	auipc	a1,0x9
    34e4:	8f858593          	addi	a1,a1,-1800 # bdd8 <buf>
    34e8:	00002097          	auipc	ra,0x2
    34ec:	382080e7          	jalr	898(ra) # 586a <read>
    34f0:	4789                	li	a5,2
    34f2:	38f51663          	bne	a0,a5,387e <subdir+0x55e>
  close(fd);
    34f6:	8526                	mv	a0,s1
    34f8:	00002097          	auipc	ra,0x2
    34fc:	382080e7          	jalr	898(ra) # 587a <close>
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    3500:	4581                	li	a1,0
    3502:	00004517          	auipc	a0,0x4
    3506:	f8e50513          	addi	a0,a0,-114 # 7490 <malloc+0x17f0>
    350a:	00002097          	auipc	ra,0x2
    350e:	388080e7          	jalr	904(ra) # 5892 <open>
    3512:	38055463          	bgez	a0,389a <subdir+0x57a>
  if(open("dd/ff/ff", O_CREATE|O_RDWR) >= 0){
    3516:	20200593          	li	a1,514
    351a:	00004517          	auipc	a0,0x4
    351e:	18650513          	addi	a0,a0,390 # 76a0 <malloc+0x1a00>
    3522:	00002097          	auipc	ra,0x2
    3526:	370080e7          	jalr	880(ra) # 5892 <open>
    352a:	38055663          	bgez	a0,38b6 <subdir+0x596>
  if(open("dd/xx/ff", O_CREATE|O_RDWR) >= 0){
    352e:	20200593          	li	a1,514
    3532:	00004517          	auipc	a0,0x4
    3536:	19e50513          	addi	a0,a0,414 # 76d0 <malloc+0x1a30>
    353a:	00002097          	auipc	ra,0x2
    353e:	358080e7          	jalr	856(ra) # 5892 <open>
    3542:	38055863          	bgez	a0,38d2 <subdir+0x5b2>
  if(open("dd", O_CREATE) >= 0){
    3546:	20000593          	li	a1,512
    354a:	00004517          	auipc	a0,0x4
    354e:	ea650513          	addi	a0,a0,-346 # 73f0 <malloc+0x1750>
    3552:	00002097          	auipc	ra,0x2
    3556:	340080e7          	jalr	832(ra) # 5892 <open>
    355a:	38055a63          	bgez	a0,38ee <subdir+0x5ce>
  if(open("dd", O_RDWR) >= 0){
    355e:	4589                	li	a1,2
    3560:	00004517          	auipc	a0,0x4
    3564:	e9050513          	addi	a0,a0,-368 # 73f0 <malloc+0x1750>
    3568:	00002097          	auipc	ra,0x2
    356c:	32a080e7          	jalr	810(ra) # 5892 <open>
    3570:	38055d63          	bgez	a0,390a <subdir+0x5ea>
  if(open("dd", O_WRONLY) >= 0){
    3574:	4585                	li	a1,1
    3576:	00004517          	auipc	a0,0x4
    357a:	e7a50513          	addi	a0,a0,-390 # 73f0 <malloc+0x1750>
    357e:	00002097          	auipc	ra,0x2
    3582:	314080e7          	jalr	788(ra) # 5892 <open>
    3586:	3a055063          	bgez	a0,3926 <subdir+0x606>
  if(link("dd/ff/ff", "dd/dd/xx") == 0){
    358a:	00004597          	auipc	a1,0x4
    358e:	1d658593          	addi	a1,a1,470 # 7760 <malloc+0x1ac0>
    3592:	00004517          	auipc	a0,0x4
    3596:	10e50513          	addi	a0,a0,270 # 76a0 <malloc+0x1a00>
    359a:	00002097          	auipc	ra,0x2
    359e:	318080e7          	jalr	792(ra) # 58b2 <link>
    35a2:	3a050063          	beqz	a0,3942 <subdir+0x622>
  if(link("dd/xx/ff", "dd/dd/xx") == 0){
    35a6:	00004597          	auipc	a1,0x4
    35aa:	1ba58593          	addi	a1,a1,442 # 7760 <malloc+0x1ac0>
    35ae:	00004517          	auipc	a0,0x4
    35b2:	12250513          	addi	a0,a0,290 # 76d0 <malloc+0x1a30>
    35b6:	00002097          	auipc	ra,0x2
    35ba:	2fc080e7          	jalr	764(ra) # 58b2 <link>
    35be:	3a050063          	beqz	a0,395e <subdir+0x63e>
  if(link("dd/ff", "dd/dd/ffff") == 0){
    35c2:	00004597          	auipc	a1,0x4
    35c6:	f5658593          	addi	a1,a1,-170 # 7518 <malloc+0x1878>
    35ca:	00004517          	auipc	a0,0x4
    35ce:	e4650513          	addi	a0,a0,-442 # 7410 <malloc+0x1770>
    35d2:	00002097          	auipc	ra,0x2
    35d6:	2e0080e7          	jalr	736(ra) # 58b2 <link>
    35da:	3a050063          	beqz	a0,397a <subdir+0x65a>
  if(mkdir("dd/ff/ff") == 0){
    35de:	00004517          	auipc	a0,0x4
    35e2:	0c250513          	addi	a0,a0,194 # 76a0 <malloc+0x1a00>
    35e6:	00002097          	auipc	ra,0x2
    35ea:	2d4080e7          	jalr	724(ra) # 58ba <mkdir>
    35ee:	3a050463          	beqz	a0,3996 <subdir+0x676>
  if(mkdir("dd/xx/ff") == 0){
    35f2:	00004517          	auipc	a0,0x4
    35f6:	0de50513          	addi	a0,a0,222 # 76d0 <malloc+0x1a30>
    35fa:	00002097          	auipc	ra,0x2
    35fe:	2c0080e7          	jalr	704(ra) # 58ba <mkdir>
    3602:	3a050863          	beqz	a0,39b2 <subdir+0x692>
  if(mkdir("dd/dd/ffff") == 0){
    3606:	00004517          	auipc	a0,0x4
    360a:	f1250513          	addi	a0,a0,-238 # 7518 <malloc+0x1878>
    360e:	00002097          	auipc	ra,0x2
    3612:	2ac080e7          	jalr	684(ra) # 58ba <mkdir>
    3616:	3a050c63          	beqz	a0,39ce <subdir+0x6ae>
  if(unlink("dd/xx/ff") == 0){
    361a:	00004517          	auipc	a0,0x4
    361e:	0b650513          	addi	a0,a0,182 # 76d0 <malloc+0x1a30>
    3622:	00002097          	auipc	ra,0x2
    3626:	280080e7          	jalr	640(ra) # 58a2 <unlink>
    362a:	3c050063          	beqz	a0,39ea <subdir+0x6ca>
  if(unlink("dd/ff/ff") == 0){
    362e:	00004517          	auipc	a0,0x4
    3632:	07250513          	addi	a0,a0,114 # 76a0 <malloc+0x1a00>
    3636:	00002097          	auipc	ra,0x2
    363a:	26c080e7          	jalr	620(ra) # 58a2 <unlink>
    363e:	3c050463          	beqz	a0,3a06 <subdir+0x6e6>
  if(chdir("dd/ff") == 0){
    3642:	00004517          	auipc	a0,0x4
    3646:	dce50513          	addi	a0,a0,-562 # 7410 <malloc+0x1770>
    364a:	00002097          	auipc	ra,0x2
    364e:	278080e7          	jalr	632(ra) # 58c2 <chdir>
    3652:	3c050863          	beqz	a0,3a22 <subdir+0x702>
  if(chdir("dd/xx") == 0){
    3656:	00004517          	auipc	a0,0x4
    365a:	25a50513          	addi	a0,a0,602 # 78b0 <malloc+0x1c10>
    365e:	00002097          	auipc	ra,0x2
    3662:	264080e7          	jalr	612(ra) # 58c2 <chdir>
    3666:	3c050c63          	beqz	a0,3a3e <subdir+0x71e>
  if(unlink("dd/dd/ffff") != 0){
    366a:	00004517          	auipc	a0,0x4
    366e:	eae50513          	addi	a0,a0,-338 # 7518 <malloc+0x1878>
    3672:	00002097          	auipc	ra,0x2
    3676:	230080e7          	jalr	560(ra) # 58a2 <unlink>
    367a:	3e051063          	bnez	a0,3a5a <subdir+0x73a>
  if(unlink("dd/ff") != 0){
    367e:	00004517          	auipc	a0,0x4
    3682:	d9250513          	addi	a0,a0,-622 # 7410 <malloc+0x1770>
    3686:	00002097          	auipc	ra,0x2
    368a:	21c080e7          	jalr	540(ra) # 58a2 <unlink>
    368e:	3e051463          	bnez	a0,3a76 <subdir+0x756>
  if(unlink("dd") == 0){
    3692:	00004517          	auipc	a0,0x4
    3696:	d5e50513          	addi	a0,a0,-674 # 73f0 <malloc+0x1750>
    369a:	00002097          	auipc	ra,0x2
    369e:	208080e7          	jalr	520(ra) # 58a2 <unlink>
    36a2:	3e050863          	beqz	a0,3a92 <subdir+0x772>
  if(unlink("dd/dd") < 0){
    36a6:	00004517          	auipc	a0,0x4
    36aa:	27a50513          	addi	a0,a0,634 # 7920 <malloc+0x1c80>
    36ae:	00002097          	auipc	ra,0x2
    36b2:	1f4080e7          	jalr	500(ra) # 58a2 <unlink>
    36b6:	3e054c63          	bltz	a0,3aae <subdir+0x78e>
  if(unlink("dd") < 0){
    36ba:	00004517          	auipc	a0,0x4
    36be:	d3650513          	addi	a0,a0,-714 # 73f0 <malloc+0x1750>
    36c2:	00002097          	auipc	ra,0x2
    36c6:	1e0080e7          	jalr	480(ra) # 58a2 <unlink>
    36ca:	40054063          	bltz	a0,3aca <subdir+0x7aa>
}
    36ce:	60e2                	ld	ra,24(sp)
    36d0:	6442                	ld	s0,16(sp)
    36d2:	64a2                	ld	s1,8(sp)
    36d4:	6902                	ld	s2,0(sp)
    36d6:	6105                	addi	sp,sp,32
    36d8:	8082                	ret
    printf("%s: mkdir dd failed\n", s);
    36da:	85ca                	mv	a1,s2
    36dc:	00004517          	auipc	a0,0x4
    36e0:	d1c50513          	addi	a0,a0,-740 # 73f8 <malloc+0x1758>
    36e4:	00002097          	auipc	ra,0x2
    36e8:	4fe080e7          	jalr	1278(ra) # 5be2 <printf>
    exit(1);
    36ec:	4505                	li	a0,1
    36ee:	00002097          	auipc	ra,0x2
    36f2:	164080e7          	jalr	356(ra) # 5852 <exit>
    printf("%s: create dd/ff failed\n", s);
    36f6:	85ca                	mv	a1,s2
    36f8:	00004517          	auipc	a0,0x4
    36fc:	d2050513          	addi	a0,a0,-736 # 7418 <malloc+0x1778>
    3700:	00002097          	auipc	ra,0x2
    3704:	4e2080e7          	jalr	1250(ra) # 5be2 <printf>
    exit(1);
    3708:	4505                	li	a0,1
    370a:	00002097          	auipc	ra,0x2
    370e:	148080e7          	jalr	328(ra) # 5852 <exit>
    printf("%s: unlink dd (non-empty dir) succeeded!\n", s);
    3712:	85ca                	mv	a1,s2
    3714:	00004517          	auipc	a0,0x4
    3718:	d2450513          	addi	a0,a0,-732 # 7438 <malloc+0x1798>
    371c:	00002097          	auipc	ra,0x2
    3720:	4c6080e7          	jalr	1222(ra) # 5be2 <printf>
    exit(1);
    3724:	4505                	li	a0,1
    3726:	00002097          	auipc	ra,0x2
    372a:	12c080e7          	jalr	300(ra) # 5852 <exit>
    printf("subdir mkdir dd/dd failed\n", s);
    372e:	85ca                	mv	a1,s2
    3730:	00004517          	auipc	a0,0x4
    3734:	d4050513          	addi	a0,a0,-704 # 7470 <malloc+0x17d0>
    3738:	00002097          	auipc	ra,0x2
    373c:	4aa080e7          	jalr	1194(ra) # 5be2 <printf>
    exit(1);
    3740:	4505                	li	a0,1
    3742:	00002097          	auipc	ra,0x2
    3746:	110080e7          	jalr	272(ra) # 5852 <exit>
    printf("%s: create dd/dd/ff failed\n", s);
    374a:	85ca                	mv	a1,s2
    374c:	00004517          	auipc	a0,0x4
    3750:	d5450513          	addi	a0,a0,-684 # 74a0 <malloc+0x1800>
    3754:	00002097          	auipc	ra,0x2
    3758:	48e080e7          	jalr	1166(ra) # 5be2 <printf>
    exit(1);
    375c:	4505                	li	a0,1
    375e:	00002097          	auipc	ra,0x2
    3762:	0f4080e7          	jalr	244(ra) # 5852 <exit>
    printf("%s: open dd/dd/../ff failed\n", s);
    3766:	85ca                	mv	a1,s2
    3768:	00004517          	auipc	a0,0x4
    376c:	d7050513          	addi	a0,a0,-656 # 74d8 <malloc+0x1838>
    3770:	00002097          	auipc	ra,0x2
    3774:	472080e7          	jalr	1138(ra) # 5be2 <printf>
    exit(1);
    3778:	4505                	li	a0,1
    377a:	00002097          	auipc	ra,0x2
    377e:	0d8080e7          	jalr	216(ra) # 5852 <exit>
    printf("%s: dd/dd/../ff wrong content\n", s);
    3782:	85ca                	mv	a1,s2
    3784:	00004517          	auipc	a0,0x4
    3788:	d7450513          	addi	a0,a0,-652 # 74f8 <malloc+0x1858>
    378c:	00002097          	auipc	ra,0x2
    3790:	456080e7          	jalr	1110(ra) # 5be2 <printf>
    exit(1);
    3794:	4505                	li	a0,1
    3796:	00002097          	auipc	ra,0x2
    379a:	0bc080e7          	jalr	188(ra) # 5852 <exit>
    printf("link dd/dd/ff dd/dd/ffff failed\n", s);
    379e:	85ca                	mv	a1,s2
    37a0:	00004517          	auipc	a0,0x4
    37a4:	d8850513          	addi	a0,a0,-632 # 7528 <malloc+0x1888>
    37a8:	00002097          	auipc	ra,0x2
    37ac:	43a080e7          	jalr	1082(ra) # 5be2 <printf>
    exit(1);
    37b0:	4505                	li	a0,1
    37b2:	00002097          	auipc	ra,0x2
    37b6:	0a0080e7          	jalr	160(ra) # 5852 <exit>
    printf("%s: unlink dd/dd/ff failed\n", s);
    37ba:	85ca                	mv	a1,s2
    37bc:	00004517          	auipc	a0,0x4
    37c0:	d9450513          	addi	a0,a0,-620 # 7550 <malloc+0x18b0>
    37c4:	00002097          	auipc	ra,0x2
    37c8:	41e080e7          	jalr	1054(ra) # 5be2 <printf>
    exit(1);
    37cc:	4505                	li	a0,1
    37ce:	00002097          	auipc	ra,0x2
    37d2:	084080e7          	jalr	132(ra) # 5852 <exit>
    printf("%s: open (unlinked) dd/dd/ff succeeded\n", s);
    37d6:	85ca                	mv	a1,s2
    37d8:	00004517          	auipc	a0,0x4
    37dc:	d9850513          	addi	a0,a0,-616 # 7570 <malloc+0x18d0>
    37e0:	00002097          	auipc	ra,0x2
    37e4:	402080e7          	jalr	1026(ra) # 5be2 <printf>
    exit(1);
    37e8:	4505                	li	a0,1
    37ea:	00002097          	auipc	ra,0x2
    37ee:	068080e7          	jalr	104(ra) # 5852 <exit>
    printf("%s: chdir dd failed\n", s);
    37f2:	85ca                	mv	a1,s2
    37f4:	00004517          	auipc	a0,0x4
    37f8:	da450513          	addi	a0,a0,-604 # 7598 <malloc+0x18f8>
    37fc:	00002097          	auipc	ra,0x2
    3800:	3e6080e7          	jalr	998(ra) # 5be2 <printf>
    exit(1);
    3804:	4505                	li	a0,1
    3806:	00002097          	auipc	ra,0x2
    380a:	04c080e7          	jalr	76(ra) # 5852 <exit>
    printf("%s: chdir dd/../../dd failed\n", s);
    380e:	85ca                	mv	a1,s2
    3810:	00004517          	auipc	a0,0x4
    3814:	db050513          	addi	a0,a0,-592 # 75c0 <malloc+0x1920>
    3818:	00002097          	auipc	ra,0x2
    381c:	3ca080e7          	jalr	970(ra) # 5be2 <printf>
    exit(1);
    3820:	4505                	li	a0,1
    3822:	00002097          	auipc	ra,0x2
    3826:	030080e7          	jalr	48(ra) # 5852 <exit>
    printf("chdir dd/../../dd failed\n", s);
    382a:	85ca                	mv	a1,s2
    382c:	00004517          	auipc	a0,0x4
    3830:	dc450513          	addi	a0,a0,-572 # 75f0 <malloc+0x1950>
    3834:	00002097          	auipc	ra,0x2
    3838:	3ae080e7          	jalr	942(ra) # 5be2 <printf>
    exit(1);
    383c:	4505                	li	a0,1
    383e:	00002097          	auipc	ra,0x2
    3842:	014080e7          	jalr	20(ra) # 5852 <exit>
    printf("%s: chdir ./.. failed\n", s);
    3846:	85ca                	mv	a1,s2
    3848:	00004517          	auipc	a0,0x4
    384c:	dd050513          	addi	a0,a0,-560 # 7618 <malloc+0x1978>
    3850:	00002097          	auipc	ra,0x2
    3854:	392080e7          	jalr	914(ra) # 5be2 <printf>
    exit(1);
    3858:	4505                	li	a0,1
    385a:	00002097          	auipc	ra,0x2
    385e:	ff8080e7          	jalr	-8(ra) # 5852 <exit>
    printf("%s: open dd/dd/ffff failed\n", s);
    3862:	85ca                	mv	a1,s2
    3864:	00004517          	auipc	a0,0x4
    3868:	dcc50513          	addi	a0,a0,-564 # 7630 <malloc+0x1990>
    386c:	00002097          	auipc	ra,0x2
    3870:	376080e7          	jalr	886(ra) # 5be2 <printf>
    exit(1);
    3874:	4505                	li	a0,1
    3876:	00002097          	auipc	ra,0x2
    387a:	fdc080e7          	jalr	-36(ra) # 5852 <exit>
    printf("%s: read dd/dd/ffff wrong len\n", s);
    387e:	85ca                	mv	a1,s2
    3880:	00004517          	auipc	a0,0x4
    3884:	dd050513          	addi	a0,a0,-560 # 7650 <malloc+0x19b0>
    3888:	00002097          	auipc	ra,0x2
    388c:	35a080e7          	jalr	858(ra) # 5be2 <printf>
    exit(1);
    3890:	4505                	li	a0,1
    3892:	00002097          	auipc	ra,0x2
    3896:	fc0080e7          	jalr	-64(ra) # 5852 <exit>
    printf("%s: open (unlinked) dd/dd/ff succeeded!\n", s);
    389a:	85ca                	mv	a1,s2
    389c:	00004517          	auipc	a0,0x4
    38a0:	dd450513          	addi	a0,a0,-556 # 7670 <malloc+0x19d0>
    38a4:	00002097          	auipc	ra,0x2
    38a8:	33e080e7          	jalr	830(ra) # 5be2 <printf>
    exit(1);
    38ac:	4505                	li	a0,1
    38ae:	00002097          	auipc	ra,0x2
    38b2:	fa4080e7          	jalr	-92(ra) # 5852 <exit>
    printf("%s: create dd/ff/ff succeeded!\n", s);
    38b6:	85ca                	mv	a1,s2
    38b8:	00004517          	auipc	a0,0x4
    38bc:	df850513          	addi	a0,a0,-520 # 76b0 <malloc+0x1a10>
    38c0:	00002097          	auipc	ra,0x2
    38c4:	322080e7          	jalr	802(ra) # 5be2 <printf>
    exit(1);
    38c8:	4505                	li	a0,1
    38ca:	00002097          	auipc	ra,0x2
    38ce:	f88080e7          	jalr	-120(ra) # 5852 <exit>
    printf("%s: create dd/xx/ff succeeded!\n", s);
    38d2:	85ca                	mv	a1,s2
    38d4:	00004517          	auipc	a0,0x4
    38d8:	e0c50513          	addi	a0,a0,-500 # 76e0 <malloc+0x1a40>
    38dc:	00002097          	auipc	ra,0x2
    38e0:	306080e7          	jalr	774(ra) # 5be2 <printf>
    exit(1);
    38e4:	4505                	li	a0,1
    38e6:	00002097          	auipc	ra,0x2
    38ea:	f6c080e7          	jalr	-148(ra) # 5852 <exit>
    printf("%s: create dd succeeded!\n", s);
    38ee:	85ca                	mv	a1,s2
    38f0:	00004517          	auipc	a0,0x4
    38f4:	e1050513          	addi	a0,a0,-496 # 7700 <malloc+0x1a60>
    38f8:	00002097          	auipc	ra,0x2
    38fc:	2ea080e7          	jalr	746(ra) # 5be2 <printf>
    exit(1);
    3900:	4505                	li	a0,1
    3902:	00002097          	auipc	ra,0x2
    3906:	f50080e7          	jalr	-176(ra) # 5852 <exit>
    printf("%s: open dd rdwr succeeded!\n", s);
    390a:	85ca                	mv	a1,s2
    390c:	00004517          	auipc	a0,0x4
    3910:	e1450513          	addi	a0,a0,-492 # 7720 <malloc+0x1a80>
    3914:	00002097          	auipc	ra,0x2
    3918:	2ce080e7          	jalr	718(ra) # 5be2 <printf>
    exit(1);
    391c:	4505                	li	a0,1
    391e:	00002097          	auipc	ra,0x2
    3922:	f34080e7          	jalr	-204(ra) # 5852 <exit>
    printf("%s: open dd wronly succeeded!\n", s);
    3926:	85ca                	mv	a1,s2
    3928:	00004517          	auipc	a0,0x4
    392c:	e1850513          	addi	a0,a0,-488 # 7740 <malloc+0x1aa0>
    3930:	00002097          	auipc	ra,0x2
    3934:	2b2080e7          	jalr	690(ra) # 5be2 <printf>
    exit(1);
    3938:	4505                	li	a0,1
    393a:	00002097          	auipc	ra,0x2
    393e:	f18080e7          	jalr	-232(ra) # 5852 <exit>
    printf("%s: link dd/ff/ff dd/dd/xx succeeded!\n", s);
    3942:	85ca                	mv	a1,s2
    3944:	00004517          	auipc	a0,0x4
    3948:	e2c50513          	addi	a0,a0,-468 # 7770 <malloc+0x1ad0>
    394c:	00002097          	auipc	ra,0x2
    3950:	296080e7          	jalr	662(ra) # 5be2 <printf>
    exit(1);
    3954:	4505                	li	a0,1
    3956:	00002097          	auipc	ra,0x2
    395a:	efc080e7          	jalr	-260(ra) # 5852 <exit>
    printf("%s: link dd/xx/ff dd/dd/xx succeeded!\n", s);
    395e:	85ca                	mv	a1,s2
    3960:	00004517          	auipc	a0,0x4
    3964:	e3850513          	addi	a0,a0,-456 # 7798 <malloc+0x1af8>
    3968:	00002097          	auipc	ra,0x2
    396c:	27a080e7          	jalr	634(ra) # 5be2 <printf>
    exit(1);
    3970:	4505                	li	a0,1
    3972:	00002097          	auipc	ra,0x2
    3976:	ee0080e7          	jalr	-288(ra) # 5852 <exit>
    printf("%s: link dd/ff dd/dd/ffff succeeded!\n", s);
    397a:	85ca                	mv	a1,s2
    397c:	00004517          	auipc	a0,0x4
    3980:	e4450513          	addi	a0,a0,-444 # 77c0 <malloc+0x1b20>
    3984:	00002097          	auipc	ra,0x2
    3988:	25e080e7          	jalr	606(ra) # 5be2 <printf>
    exit(1);
    398c:	4505                	li	a0,1
    398e:	00002097          	auipc	ra,0x2
    3992:	ec4080e7          	jalr	-316(ra) # 5852 <exit>
    printf("%s: mkdir dd/ff/ff succeeded!\n", s);
    3996:	85ca                	mv	a1,s2
    3998:	00004517          	auipc	a0,0x4
    399c:	e5050513          	addi	a0,a0,-432 # 77e8 <malloc+0x1b48>
    39a0:	00002097          	auipc	ra,0x2
    39a4:	242080e7          	jalr	578(ra) # 5be2 <printf>
    exit(1);
    39a8:	4505                	li	a0,1
    39aa:	00002097          	auipc	ra,0x2
    39ae:	ea8080e7          	jalr	-344(ra) # 5852 <exit>
    printf("%s: mkdir dd/xx/ff succeeded!\n", s);
    39b2:	85ca                	mv	a1,s2
    39b4:	00004517          	auipc	a0,0x4
    39b8:	e5450513          	addi	a0,a0,-428 # 7808 <malloc+0x1b68>
    39bc:	00002097          	auipc	ra,0x2
    39c0:	226080e7          	jalr	550(ra) # 5be2 <printf>
    exit(1);
    39c4:	4505                	li	a0,1
    39c6:	00002097          	auipc	ra,0x2
    39ca:	e8c080e7          	jalr	-372(ra) # 5852 <exit>
    printf("%s: mkdir dd/dd/ffff succeeded!\n", s);
    39ce:	85ca                	mv	a1,s2
    39d0:	00004517          	auipc	a0,0x4
    39d4:	e5850513          	addi	a0,a0,-424 # 7828 <malloc+0x1b88>
    39d8:	00002097          	auipc	ra,0x2
    39dc:	20a080e7          	jalr	522(ra) # 5be2 <printf>
    exit(1);
    39e0:	4505                	li	a0,1
    39e2:	00002097          	auipc	ra,0x2
    39e6:	e70080e7          	jalr	-400(ra) # 5852 <exit>
    printf("%s: unlink dd/xx/ff succeeded!\n", s);
    39ea:	85ca                	mv	a1,s2
    39ec:	00004517          	auipc	a0,0x4
    39f0:	e6450513          	addi	a0,a0,-412 # 7850 <malloc+0x1bb0>
    39f4:	00002097          	auipc	ra,0x2
    39f8:	1ee080e7          	jalr	494(ra) # 5be2 <printf>
    exit(1);
    39fc:	4505                	li	a0,1
    39fe:	00002097          	auipc	ra,0x2
    3a02:	e54080e7          	jalr	-428(ra) # 5852 <exit>
    printf("%s: unlink dd/ff/ff succeeded!\n", s);
    3a06:	85ca                	mv	a1,s2
    3a08:	00004517          	auipc	a0,0x4
    3a0c:	e6850513          	addi	a0,a0,-408 # 7870 <malloc+0x1bd0>
    3a10:	00002097          	auipc	ra,0x2
    3a14:	1d2080e7          	jalr	466(ra) # 5be2 <printf>
    exit(1);
    3a18:	4505                	li	a0,1
    3a1a:	00002097          	auipc	ra,0x2
    3a1e:	e38080e7          	jalr	-456(ra) # 5852 <exit>
    printf("%s: chdir dd/ff succeeded!\n", s);
    3a22:	85ca                	mv	a1,s2
    3a24:	00004517          	auipc	a0,0x4
    3a28:	e6c50513          	addi	a0,a0,-404 # 7890 <malloc+0x1bf0>
    3a2c:	00002097          	auipc	ra,0x2
    3a30:	1b6080e7          	jalr	438(ra) # 5be2 <printf>
    exit(1);
    3a34:	4505                	li	a0,1
    3a36:	00002097          	auipc	ra,0x2
    3a3a:	e1c080e7          	jalr	-484(ra) # 5852 <exit>
    printf("%s: chdir dd/xx succeeded!\n", s);
    3a3e:	85ca                	mv	a1,s2
    3a40:	00004517          	auipc	a0,0x4
    3a44:	e7850513          	addi	a0,a0,-392 # 78b8 <malloc+0x1c18>
    3a48:	00002097          	auipc	ra,0x2
    3a4c:	19a080e7          	jalr	410(ra) # 5be2 <printf>
    exit(1);
    3a50:	4505                	li	a0,1
    3a52:	00002097          	auipc	ra,0x2
    3a56:	e00080e7          	jalr	-512(ra) # 5852 <exit>
    printf("%s: unlink dd/dd/ff failed\n", s);
    3a5a:	85ca                	mv	a1,s2
    3a5c:	00004517          	auipc	a0,0x4
    3a60:	af450513          	addi	a0,a0,-1292 # 7550 <malloc+0x18b0>
    3a64:	00002097          	auipc	ra,0x2
    3a68:	17e080e7          	jalr	382(ra) # 5be2 <printf>
    exit(1);
    3a6c:	4505                	li	a0,1
    3a6e:	00002097          	auipc	ra,0x2
    3a72:	de4080e7          	jalr	-540(ra) # 5852 <exit>
    printf("%s: unlink dd/ff failed\n", s);
    3a76:	85ca                	mv	a1,s2
    3a78:	00004517          	auipc	a0,0x4
    3a7c:	e6050513          	addi	a0,a0,-416 # 78d8 <malloc+0x1c38>
    3a80:	00002097          	auipc	ra,0x2
    3a84:	162080e7          	jalr	354(ra) # 5be2 <printf>
    exit(1);
    3a88:	4505                	li	a0,1
    3a8a:	00002097          	auipc	ra,0x2
    3a8e:	dc8080e7          	jalr	-568(ra) # 5852 <exit>
    printf("%s: unlink non-empty dd succeeded!\n", s);
    3a92:	85ca                	mv	a1,s2
    3a94:	00004517          	auipc	a0,0x4
    3a98:	e6450513          	addi	a0,a0,-412 # 78f8 <malloc+0x1c58>
    3a9c:	00002097          	auipc	ra,0x2
    3aa0:	146080e7          	jalr	326(ra) # 5be2 <printf>
    exit(1);
    3aa4:	4505                	li	a0,1
    3aa6:	00002097          	auipc	ra,0x2
    3aaa:	dac080e7          	jalr	-596(ra) # 5852 <exit>
    printf("%s: unlink dd/dd failed\n", s);
    3aae:	85ca                	mv	a1,s2
    3ab0:	00004517          	auipc	a0,0x4
    3ab4:	e7850513          	addi	a0,a0,-392 # 7928 <malloc+0x1c88>
    3ab8:	00002097          	auipc	ra,0x2
    3abc:	12a080e7          	jalr	298(ra) # 5be2 <printf>
    exit(1);
    3ac0:	4505                	li	a0,1
    3ac2:	00002097          	auipc	ra,0x2
    3ac6:	d90080e7          	jalr	-624(ra) # 5852 <exit>
    printf("%s: unlink dd failed\n", s);
    3aca:	85ca                	mv	a1,s2
    3acc:	00004517          	auipc	a0,0x4
    3ad0:	e7c50513          	addi	a0,a0,-388 # 7948 <malloc+0x1ca8>
    3ad4:	00002097          	auipc	ra,0x2
    3ad8:	10e080e7          	jalr	270(ra) # 5be2 <printf>
    exit(1);
    3adc:	4505                	li	a0,1
    3ade:	00002097          	auipc	ra,0x2
    3ae2:	d74080e7          	jalr	-652(ra) # 5852 <exit>

0000000000003ae6 <rmdot>:
{
    3ae6:	1101                	addi	sp,sp,-32
    3ae8:	ec06                	sd	ra,24(sp)
    3aea:	e822                	sd	s0,16(sp)
    3aec:	e426                	sd	s1,8(sp)
    3aee:	1000                	addi	s0,sp,32
    3af0:	84aa                	mv	s1,a0
  if(mkdir("dots") != 0){
    3af2:	00004517          	auipc	a0,0x4
    3af6:	e6e50513          	addi	a0,a0,-402 # 7960 <malloc+0x1cc0>
    3afa:	00002097          	auipc	ra,0x2
    3afe:	dc0080e7          	jalr	-576(ra) # 58ba <mkdir>
    3b02:	e549                	bnez	a0,3b8c <rmdot+0xa6>
  if(chdir("dots") != 0){
    3b04:	00004517          	auipc	a0,0x4
    3b08:	e5c50513          	addi	a0,a0,-420 # 7960 <malloc+0x1cc0>
    3b0c:	00002097          	auipc	ra,0x2
    3b10:	db6080e7          	jalr	-586(ra) # 58c2 <chdir>
    3b14:	e951                	bnez	a0,3ba8 <rmdot+0xc2>
  if(unlink(".") == 0){
    3b16:	00003517          	auipc	a0,0x3
    3b1a:	ce250513          	addi	a0,a0,-798 # 67f8 <malloc+0xb58>
    3b1e:	00002097          	auipc	ra,0x2
    3b22:	d84080e7          	jalr	-636(ra) # 58a2 <unlink>
    3b26:	cd59                	beqz	a0,3bc4 <rmdot+0xde>
  if(unlink("..") == 0){
    3b28:	00004517          	auipc	a0,0x4
    3b2c:	89050513          	addi	a0,a0,-1904 # 73b8 <malloc+0x1718>
    3b30:	00002097          	auipc	ra,0x2
    3b34:	d72080e7          	jalr	-654(ra) # 58a2 <unlink>
    3b38:	c545                	beqz	a0,3be0 <rmdot+0xfa>
  if(chdir("/") != 0){
    3b3a:	00004517          	auipc	a0,0x4
    3b3e:	82650513          	addi	a0,a0,-2010 # 7360 <malloc+0x16c0>
    3b42:	00002097          	auipc	ra,0x2
    3b46:	d80080e7          	jalr	-640(ra) # 58c2 <chdir>
    3b4a:	e94d                	bnez	a0,3bfc <rmdot+0x116>
  if(unlink("dots/.") == 0){
    3b4c:	00004517          	auipc	a0,0x4
    3b50:	e7c50513          	addi	a0,a0,-388 # 79c8 <malloc+0x1d28>
    3b54:	00002097          	auipc	ra,0x2
    3b58:	d4e080e7          	jalr	-690(ra) # 58a2 <unlink>
    3b5c:	cd55                	beqz	a0,3c18 <rmdot+0x132>
  if(unlink("dots/..") == 0){
    3b5e:	00004517          	auipc	a0,0x4
    3b62:	e9250513          	addi	a0,a0,-366 # 79f0 <malloc+0x1d50>
    3b66:	00002097          	auipc	ra,0x2
    3b6a:	d3c080e7          	jalr	-708(ra) # 58a2 <unlink>
    3b6e:	c179                	beqz	a0,3c34 <rmdot+0x14e>
  if(unlink("dots") != 0){
    3b70:	00004517          	auipc	a0,0x4
    3b74:	df050513          	addi	a0,a0,-528 # 7960 <malloc+0x1cc0>
    3b78:	00002097          	auipc	ra,0x2
    3b7c:	d2a080e7          	jalr	-726(ra) # 58a2 <unlink>
    3b80:	e961                	bnez	a0,3c50 <rmdot+0x16a>
}
    3b82:	60e2                	ld	ra,24(sp)
    3b84:	6442                	ld	s0,16(sp)
    3b86:	64a2                	ld	s1,8(sp)
    3b88:	6105                	addi	sp,sp,32
    3b8a:	8082                	ret
    printf("%s: mkdir dots failed\n", s);
    3b8c:	85a6                	mv	a1,s1
    3b8e:	00004517          	auipc	a0,0x4
    3b92:	dda50513          	addi	a0,a0,-550 # 7968 <malloc+0x1cc8>
    3b96:	00002097          	auipc	ra,0x2
    3b9a:	04c080e7          	jalr	76(ra) # 5be2 <printf>
    exit(1);
    3b9e:	4505                	li	a0,1
    3ba0:	00002097          	auipc	ra,0x2
    3ba4:	cb2080e7          	jalr	-846(ra) # 5852 <exit>
    printf("%s: chdir dots failed\n", s);
    3ba8:	85a6                	mv	a1,s1
    3baa:	00004517          	auipc	a0,0x4
    3bae:	dd650513          	addi	a0,a0,-554 # 7980 <malloc+0x1ce0>
    3bb2:	00002097          	auipc	ra,0x2
    3bb6:	030080e7          	jalr	48(ra) # 5be2 <printf>
    exit(1);
    3bba:	4505                	li	a0,1
    3bbc:	00002097          	auipc	ra,0x2
    3bc0:	c96080e7          	jalr	-874(ra) # 5852 <exit>
    printf("%s: rm . worked!\n", s);
    3bc4:	85a6                	mv	a1,s1
    3bc6:	00004517          	auipc	a0,0x4
    3bca:	dd250513          	addi	a0,a0,-558 # 7998 <malloc+0x1cf8>
    3bce:	00002097          	auipc	ra,0x2
    3bd2:	014080e7          	jalr	20(ra) # 5be2 <printf>
    exit(1);
    3bd6:	4505                	li	a0,1
    3bd8:	00002097          	auipc	ra,0x2
    3bdc:	c7a080e7          	jalr	-902(ra) # 5852 <exit>
    printf("%s: rm .. worked!\n", s);
    3be0:	85a6                	mv	a1,s1
    3be2:	00004517          	auipc	a0,0x4
    3be6:	dce50513          	addi	a0,a0,-562 # 79b0 <malloc+0x1d10>
    3bea:	00002097          	auipc	ra,0x2
    3bee:	ff8080e7          	jalr	-8(ra) # 5be2 <printf>
    exit(1);
    3bf2:	4505                	li	a0,1
    3bf4:	00002097          	auipc	ra,0x2
    3bf8:	c5e080e7          	jalr	-930(ra) # 5852 <exit>
    printf("%s: chdir / failed\n", s);
    3bfc:	85a6                	mv	a1,s1
    3bfe:	00003517          	auipc	a0,0x3
    3c02:	76a50513          	addi	a0,a0,1898 # 7368 <malloc+0x16c8>
    3c06:	00002097          	auipc	ra,0x2
    3c0a:	fdc080e7          	jalr	-36(ra) # 5be2 <printf>
    exit(1);
    3c0e:	4505                	li	a0,1
    3c10:	00002097          	auipc	ra,0x2
    3c14:	c42080e7          	jalr	-958(ra) # 5852 <exit>
    printf("%s: unlink dots/. worked!\n", s);
    3c18:	85a6                	mv	a1,s1
    3c1a:	00004517          	auipc	a0,0x4
    3c1e:	db650513          	addi	a0,a0,-586 # 79d0 <malloc+0x1d30>
    3c22:	00002097          	auipc	ra,0x2
    3c26:	fc0080e7          	jalr	-64(ra) # 5be2 <printf>
    exit(1);
    3c2a:	4505                	li	a0,1
    3c2c:	00002097          	auipc	ra,0x2
    3c30:	c26080e7          	jalr	-986(ra) # 5852 <exit>
    printf("%s: unlink dots/.. worked!\n", s);
    3c34:	85a6                	mv	a1,s1
    3c36:	00004517          	auipc	a0,0x4
    3c3a:	dc250513          	addi	a0,a0,-574 # 79f8 <malloc+0x1d58>
    3c3e:	00002097          	auipc	ra,0x2
    3c42:	fa4080e7          	jalr	-92(ra) # 5be2 <printf>
    exit(1);
    3c46:	4505                	li	a0,1
    3c48:	00002097          	auipc	ra,0x2
    3c4c:	c0a080e7          	jalr	-1014(ra) # 5852 <exit>
    printf("%s: unlink dots failed!\n", s);
    3c50:	85a6                	mv	a1,s1
    3c52:	00004517          	auipc	a0,0x4
    3c56:	dc650513          	addi	a0,a0,-570 # 7a18 <malloc+0x1d78>
    3c5a:	00002097          	auipc	ra,0x2
    3c5e:	f88080e7          	jalr	-120(ra) # 5be2 <printf>
    exit(1);
    3c62:	4505                	li	a0,1
    3c64:	00002097          	auipc	ra,0x2
    3c68:	bee080e7          	jalr	-1042(ra) # 5852 <exit>

0000000000003c6c <dirfile>:
{
    3c6c:	1101                	addi	sp,sp,-32
    3c6e:	ec06                	sd	ra,24(sp)
    3c70:	e822                	sd	s0,16(sp)
    3c72:	e426                	sd	s1,8(sp)
    3c74:	e04a                	sd	s2,0(sp)
    3c76:	1000                	addi	s0,sp,32
    3c78:	892a                	mv	s2,a0
  fd = open("dirfile", O_CREATE);
    3c7a:	20000593          	li	a1,512
    3c7e:	00002517          	auipc	a0,0x2
    3c82:	45250513          	addi	a0,a0,1106 # 60d0 <malloc+0x430>
    3c86:	00002097          	auipc	ra,0x2
    3c8a:	c0c080e7          	jalr	-1012(ra) # 5892 <open>
  if(fd < 0){
    3c8e:	0e054d63          	bltz	a0,3d88 <dirfile+0x11c>
  close(fd);
    3c92:	00002097          	auipc	ra,0x2
    3c96:	be8080e7          	jalr	-1048(ra) # 587a <close>
  if(chdir("dirfile") == 0){
    3c9a:	00002517          	auipc	a0,0x2
    3c9e:	43650513          	addi	a0,a0,1078 # 60d0 <malloc+0x430>
    3ca2:	00002097          	auipc	ra,0x2
    3ca6:	c20080e7          	jalr	-992(ra) # 58c2 <chdir>
    3caa:	cd6d                	beqz	a0,3da4 <dirfile+0x138>
  fd = open("dirfile/xx", 0);
    3cac:	4581                	li	a1,0
    3cae:	00004517          	auipc	a0,0x4
    3cb2:	dca50513          	addi	a0,a0,-566 # 7a78 <malloc+0x1dd8>
    3cb6:	00002097          	auipc	ra,0x2
    3cba:	bdc080e7          	jalr	-1060(ra) # 5892 <open>
  if(fd >= 0){
    3cbe:	10055163          	bgez	a0,3dc0 <dirfile+0x154>
  fd = open("dirfile/xx", O_CREATE);
    3cc2:	20000593          	li	a1,512
    3cc6:	00004517          	auipc	a0,0x4
    3cca:	db250513          	addi	a0,a0,-590 # 7a78 <malloc+0x1dd8>
    3cce:	00002097          	auipc	ra,0x2
    3cd2:	bc4080e7          	jalr	-1084(ra) # 5892 <open>
  if(fd >= 0){
    3cd6:	10055363          	bgez	a0,3ddc <dirfile+0x170>
  if(mkdir("dirfile/xx") == 0){
    3cda:	00004517          	auipc	a0,0x4
    3cde:	d9e50513          	addi	a0,a0,-610 # 7a78 <malloc+0x1dd8>
    3ce2:	00002097          	auipc	ra,0x2
    3ce6:	bd8080e7          	jalr	-1064(ra) # 58ba <mkdir>
    3cea:	10050763          	beqz	a0,3df8 <dirfile+0x18c>
  if(unlink("dirfile/xx") == 0){
    3cee:	00004517          	auipc	a0,0x4
    3cf2:	d8a50513          	addi	a0,a0,-630 # 7a78 <malloc+0x1dd8>
    3cf6:	00002097          	auipc	ra,0x2
    3cfa:	bac080e7          	jalr	-1108(ra) # 58a2 <unlink>
    3cfe:	10050b63          	beqz	a0,3e14 <dirfile+0x1a8>
  if(link("README", "dirfile/xx") == 0){
    3d02:	00004597          	auipc	a1,0x4
    3d06:	d7658593          	addi	a1,a1,-650 # 7a78 <malloc+0x1dd8>
    3d0a:	00002517          	auipc	a0,0x2
    3d0e:	5ee50513          	addi	a0,a0,1518 # 62f8 <malloc+0x658>
    3d12:	00002097          	auipc	ra,0x2
    3d16:	ba0080e7          	jalr	-1120(ra) # 58b2 <link>
    3d1a:	10050b63          	beqz	a0,3e30 <dirfile+0x1c4>
  if(unlink("dirfile") != 0){
    3d1e:	00002517          	auipc	a0,0x2
    3d22:	3b250513          	addi	a0,a0,946 # 60d0 <malloc+0x430>
    3d26:	00002097          	auipc	ra,0x2
    3d2a:	b7c080e7          	jalr	-1156(ra) # 58a2 <unlink>
    3d2e:	10051f63          	bnez	a0,3e4c <dirfile+0x1e0>
  fd = open(".", O_RDWR);
    3d32:	4589                	li	a1,2
    3d34:	00003517          	auipc	a0,0x3
    3d38:	ac450513          	addi	a0,a0,-1340 # 67f8 <malloc+0xb58>
    3d3c:	00002097          	auipc	ra,0x2
    3d40:	b56080e7          	jalr	-1194(ra) # 5892 <open>
  if(fd >= 0){
    3d44:	12055263          	bgez	a0,3e68 <dirfile+0x1fc>
  fd = open(".", 0);
    3d48:	4581                	li	a1,0
    3d4a:	00003517          	auipc	a0,0x3
    3d4e:	aae50513          	addi	a0,a0,-1362 # 67f8 <malloc+0xb58>
    3d52:	00002097          	auipc	ra,0x2
    3d56:	b40080e7          	jalr	-1216(ra) # 5892 <open>
    3d5a:	84aa                	mv	s1,a0
  if(write(fd, "x", 1) > 0){
    3d5c:	4605                	li	a2,1
    3d5e:	00002597          	auipc	a1,0x2
    3d62:	44258593          	addi	a1,a1,1090 # 61a0 <malloc+0x500>
    3d66:	00002097          	auipc	ra,0x2
    3d6a:	b0c080e7          	jalr	-1268(ra) # 5872 <write>
    3d6e:	10a04b63          	bgtz	a0,3e84 <dirfile+0x218>
  close(fd);
    3d72:	8526                	mv	a0,s1
    3d74:	00002097          	auipc	ra,0x2
    3d78:	b06080e7          	jalr	-1274(ra) # 587a <close>
}
    3d7c:	60e2                	ld	ra,24(sp)
    3d7e:	6442                	ld	s0,16(sp)
    3d80:	64a2                	ld	s1,8(sp)
    3d82:	6902                	ld	s2,0(sp)
    3d84:	6105                	addi	sp,sp,32
    3d86:	8082                	ret
    printf("%s: create dirfile failed\n", s);
    3d88:	85ca                	mv	a1,s2
    3d8a:	00004517          	auipc	a0,0x4
    3d8e:	cae50513          	addi	a0,a0,-850 # 7a38 <malloc+0x1d98>
    3d92:	00002097          	auipc	ra,0x2
    3d96:	e50080e7          	jalr	-432(ra) # 5be2 <printf>
    exit(1);
    3d9a:	4505                	li	a0,1
    3d9c:	00002097          	auipc	ra,0x2
    3da0:	ab6080e7          	jalr	-1354(ra) # 5852 <exit>
    printf("%s: chdir dirfile succeeded!\n", s);
    3da4:	85ca                	mv	a1,s2
    3da6:	00004517          	auipc	a0,0x4
    3daa:	cb250513          	addi	a0,a0,-846 # 7a58 <malloc+0x1db8>
    3dae:	00002097          	auipc	ra,0x2
    3db2:	e34080e7          	jalr	-460(ra) # 5be2 <printf>
    exit(1);
    3db6:	4505                	li	a0,1
    3db8:	00002097          	auipc	ra,0x2
    3dbc:	a9a080e7          	jalr	-1382(ra) # 5852 <exit>
    printf("%s: create dirfile/xx succeeded!\n", s);
    3dc0:	85ca                	mv	a1,s2
    3dc2:	00004517          	auipc	a0,0x4
    3dc6:	cc650513          	addi	a0,a0,-826 # 7a88 <malloc+0x1de8>
    3dca:	00002097          	auipc	ra,0x2
    3dce:	e18080e7          	jalr	-488(ra) # 5be2 <printf>
    exit(1);
    3dd2:	4505                	li	a0,1
    3dd4:	00002097          	auipc	ra,0x2
    3dd8:	a7e080e7          	jalr	-1410(ra) # 5852 <exit>
    printf("%s: create dirfile/xx succeeded!\n", s);
    3ddc:	85ca                	mv	a1,s2
    3dde:	00004517          	auipc	a0,0x4
    3de2:	caa50513          	addi	a0,a0,-854 # 7a88 <malloc+0x1de8>
    3de6:	00002097          	auipc	ra,0x2
    3dea:	dfc080e7          	jalr	-516(ra) # 5be2 <printf>
    exit(1);
    3dee:	4505                	li	a0,1
    3df0:	00002097          	auipc	ra,0x2
    3df4:	a62080e7          	jalr	-1438(ra) # 5852 <exit>
    printf("%s: mkdir dirfile/xx succeeded!\n", s);
    3df8:	85ca                	mv	a1,s2
    3dfa:	00004517          	auipc	a0,0x4
    3dfe:	cb650513          	addi	a0,a0,-842 # 7ab0 <malloc+0x1e10>
    3e02:	00002097          	auipc	ra,0x2
    3e06:	de0080e7          	jalr	-544(ra) # 5be2 <printf>
    exit(1);
    3e0a:	4505                	li	a0,1
    3e0c:	00002097          	auipc	ra,0x2
    3e10:	a46080e7          	jalr	-1466(ra) # 5852 <exit>
    printf("%s: unlink dirfile/xx succeeded!\n", s);
    3e14:	85ca                	mv	a1,s2
    3e16:	00004517          	auipc	a0,0x4
    3e1a:	cc250513          	addi	a0,a0,-830 # 7ad8 <malloc+0x1e38>
    3e1e:	00002097          	auipc	ra,0x2
    3e22:	dc4080e7          	jalr	-572(ra) # 5be2 <printf>
    exit(1);
    3e26:	4505                	li	a0,1
    3e28:	00002097          	auipc	ra,0x2
    3e2c:	a2a080e7          	jalr	-1494(ra) # 5852 <exit>
    printf("%s: link to dirfile/xx succeeded!\n", s);
    3e30:	85ca                	mv	a1,s2
    3e32:	00004517          	auipc	a0,0x4
    3e36:	cce50513          	addi	a0,a0,-818 # 7b00 <malloc+0x1e60>
    3e3a:	00002097          	auipc	ra,0x2
    3e3e:	da8080e7          	jalr	-600(ra) # 5be2 <printf>
    exit(1);
    3e42:	4505                	li	a0,1
    3e44:	00002097          	auipc	ra,0x2
    3e48:	a0e080e7          	jalr	-1522(ra) # 5852 <exit>
    printf("%s: unlink dirfile failed!\n", s);
    3e4c:	85ca                	mv	a1,s2
    3e4e:	00004517          	auipc	a0,0x4
    3e52:	cda50513          	addi	a0,a0,-806 # 7b28 <malloc+0x1e88>
    3e56:	00002097          	auipc	ra,0x2
    3e5a:	d8c080e7          	jalr	-628(ra) # 5be2 <printf>
    exit(1);
    3e5e:	4505                	li	a0,1
    3e60:	00002097          	auipc	ra,0x2
    3e64:	9f2080e7          	jalr	-1550(ra) # 5852 <exit>
    printf("%s: open . for writing succeeded!\n", s);
    3e68:	85ca                	mv	a1,s2
    3e6a:	00004517          	auipc	a0,0x4
    3e6e:	cde50513          	addi	a0,a0,-802 # 7b48 <malloc+0x1ea8>
    3e72:	00002097          	auipc	ra,0x2
    3e76:	d70080e7          	jalr	-656(ra) # 5be2 <printf>
    exit(1);
    3e7a:	4505                	li	a0,1
    3e7c:	00002097          	auipc	ra,0x2
    3e80:	9d6080e7          	jalr	-1578(ra) # 5852 <exit>
    printf("%s: write . succeeded!\n", s);
    3e84:	85ca                	mv	a1,s2
    3e86:	00004517          	auipc	a0,0x4
    3e8a:	cea50513          	addi	a0,a0,-790 # 7b70 <malloc+0x1ed0>
    3e8e:	00002097          	auipc	ra,0x2
    3e92:	d54080e7          	jalr	-684(ra) # 5be2 <printf>
    exit(1);
    3e96:	4505                	li	a0,1
    3e98:	00002097          	auipc	ra,0x2
    3e9c:	9ba080e7          	jalr	-1606(ra) # 5852 <exit>

0000000000003ea0 <iref>:
{
    3ea0:	7139                	addi	sp,sp,-64
    3ea2:	fc06                	sd	ra,56(sp)
    3ea4:	f822                	sd	s0,48(sp)
    3ea6:	f426                	sd	s1,40(sp)
    3ea8:	f04a                	sd	s2,32(sp)
    3eaa:	ec4e                	sd	s3,24(sp)
    3eac:	e852                	sd	s4,16(sp)
    3eae:	e456                	sd	s5,8(sp)
    3eb0:	e05a                	sd	s6,0(sp)
    3eb2:	0080                	addi	s0,sp,64
    3eb4:	8b2a                	mv	s6,a0
    3eb6:	03300913          	li	s2,51
    if(mkdir("irefd") != 0){
    3eba:	00004a17          	auipc	s4,0x4
    3ebe:	ccea0a13          	addi	s4,s4,-818 # 7b88 <malloc+0x1ee8>
    mkdir("");
    3ec2:	00003497          	auipc	s1,0x3
    3ec6:	7d648493          	addi	s1,s1,2006 # 7698 <malloc+0x19f8>
    link("README", "");
    3eca:	00002a97          	auipc	s5,0x2
    3ece:	42ea8a93          	addi	s5,s5,1070 # 62f8 <malloc+0x658>
    fd = open("xx", O_CREATE);
    3ed2:	00004997          	auipc	s3,0x4
    3ed6:	bae98993          	addi	s3,s3,-1106 # 7a80 <malloc+0x1de0>
    3eda:	a891                	j	3f2e <iref+0x8e>
      printf("%s: mkdir irefd failed\n", s);
    3edc:	85da                	mv	a1,s6
    3ede:	00004517          	auipc	a0,0x4
    3ee2:	cb250513          	addi	a0,a0,-846 # 7b90 <malloc+0x1ef0>
    3ee6:	00002097          	auipc	ra,0x2
    3eea:	cfc080e7          	jalr	-772(ra) # 5be2 <printf>
      exit(1);
    3eee:	4505                	li	a0,1
    3ef0:	00002097          	auipc	ra,0x2
    3ef4:	962080e7          	jalr	-1694(ra) # 5852 <exit>
      printf("%s: chdir irefd failed\n", s);
    3ef8:	85da                	mv	a1,s6
    3efa:	00004517          	auipc	a0,0x4
    3efe:	cae50513          	addi	a0,a0,-850 # 7ba8 <malloc+0x1f08>
    3f02:	00002097          	auipc	ra,0x2
    3f06:	ce0080e7          	jalr	-800(ra) # 5be2 <printf>
      exit(1);
    3f0a:	4505                	li	a0,1
    3f0c:	00002097          	auipc	ra,0x2
    3f10:	946080e7          	jalr	-1722(ra) # 5852 <exit>
      close(fd);
    3f14:	00002097          	auipc	ra,0x2
    3f18:	966080e7          	jalr	-1690(ra) # 587a <close>
    3f1c:	a889                	j	3f6e <iref+0xce>
    unlink("xx");
    3f1e:	854e                	mv	a0,s3
    3f20:	00002097          	auipc	ra,0x2
    3f24:	982080e7          	jalr	-1662(ra) # 58a2 <unlink>
  for(i = 0; i < NINODE + 1; i++){
    3f28:	397d                	addiw	s2,s2,-1
    3f2a:	06090063          	beqz	s2,3f8a <iref+0xea>
    if(mkdir("irefd") != 0){
    3f2e:	8552                	mv	a0,s4
    3f30:	00002097          	auipc	ra,0x2
    3f34:	98a080e7          	jalr	-1654(ra) # 58ba <mkdir>
    3f38:	f155                	bnez	a0,3edc <iref+0x3c>
    if(chdir("irefd") != 0){
    3f3a:	8552                	mv	a0,s4
    3f3c:	00002097          	auipc	ra,0x2
    3f40:	986080e7          	jalr	-1658(ra) # 58c2 <chdir>
    3f44:	f955                	bnez	a0,3ef8 <iref+0x58>
    mkdir("");
    3f46:	8526                	mv	a0,s1
    3f48:	00002097          	auipc	ra,0x2
    3f4c:	972080e7          	jalr	-1678(ra) # 58ba <mkdir>
    link("README", "");
    3f50:	85a6                	mv	a1,s1
    3f52:	8556                	mv	a0,s5
    3f54:	00002097          	auipc	ra,0x2
    3f58:	95e080e7          	jalr	-1698(ra) # 58b2 <link>
    fd = open("", O_CREATE);
    3f5c:	20000593          	li	a1,512
    3f60:	8526                	mv	a0,s1
    3f62:	00002097          	auipc	ra,0x2
    3f66:	930080e7          	jalr	-1744(ra) # 5892 <open>
    if(fd >= 0)
    3f6a:	fa0555e3          	bgez	a0,3f14 <iref+0x74>
    fd = open("xx", O_CREATE);
    3f6e:	20000593          	li	a1,512
    3f72:	854e                	mv	a0,s3
    3f74:	00002097          	auipc	ra,0x2
    3f78:	91e080e7          	jalr	-1762(ra) # 5892 <open>
    if(fd >= 0)
    3f7c:	fa0541e3          	bltz	a0,3f1e <iref+0x7e>
      close(fd);
    3f80:	00002097          	auipc	ra,0x2
    3f84:	8fa080e7          	jalr	-1798(ra) # 587a <close>
    3f88:	bf59                	j	3f1e <iref+0x7e>
    3f8a:	03300493          	li	s1,51
    chdir("..");
    3f8e:	00003997          	auipc	s3,0x3
    3f92:	42a98993          	addi	s3,s3,1066 # 73b8 <malloc+0x1718>
    unlink("irefd");
    3f96:	00004917          	auipc	s2,0x4
    3f9a:	bf290913          	addi	s2,s2,-1038 # 7b88 <malloc+0x1ee8>
    chdir("..");
    3f9e:	854e                	mv	a0,s3
    3fa0:	00002097          	auipc	ra,0x2
    3fa4:	922080e7          	jalr	-1758(ra) # 58c2 <chdir>
    unlink("irefd");
    3fa8:	854a                	mv	a0,s2
    3faa:	00002097          	auipc	ra,0x2
    3fae:	8f8080e7          	jalr	-1800(ra) # 58a2 <unlink>
  for(i = 0; i < NINODE + 1; i++){
    3fb2:	34fd                	addiw	s1,s1,-1
    3fb4:	f4ed                	bnez	s1,3f9e <iref+0xfe>
  chdir("/");
    3fb6:	00003517          	auipc	a0,0x3
    3fba:	3aa50513          	addi	a0,a0,938 # 7360 <malloc+0x16c0>
    3fbe:	00002097          	auipc	ra,0x2
    3fc2:	904080e7          	jalr	-1788(ra) # 58c2 <chdir>
}
    3fc6:	70e2                	ld	ra,56(sp)
    3fc8:	7442                	ld	s0,48(sp)
    3fca:	74a2                	ld	s1,40(sp)
    3fcc:	7902                	ld	s2,32(sp)
    3fce:	69e2                	ld	s3,24(sp)
    3fd0:	6a42                	ld	s4,16(sp)
    3fd2:	6aa2                	ld	s5,8(sp)
    3fd4:	6b02                	ld	s6,0(sp)
    3fd6:	6121                	addi	sp,sp,64
    3fd8:	8082                	ret

0000000000003fda <openiputtest>:
{
    3fda:	7179                	addi	sp,sp,-48
    3fdc:	f406                	sd	ra,40(sp)
    3fde:	f022                	sd	s0,32(sp)
    3fe0:	ec26                	sd	s1,24(sp)
    3fe2:	1800                	addi	s0,sp,48
    3fe4:	84aa                	mv	s1,a0
  if(mkdir("oidir") < 0){
    3fe6:	00004517          	auipc	a0,0x4
    3fea:	bda50513          	addi	a0,a0,-1062 # 7bc0 <malloc+0x1f20>
    3fee:	00002097          	auipc	ra,0x2
    3ff2:	8cc080e7          	jalr	-1844(ra) # 58ba <mkdir>
    3ff6:	04054263          	bltz	a0,403a <openiputtest+0x60>
  pid = fork();
    3ffa:	00002097          	auipc	ra,0x2
    3ffe:	850080e7          	jalr	-1968(ra) # 584a <fork>
  if(pid < 0){
    4002:	04054a63          	bltz	a0,4056 <openiputtest+0x7c>
  if(pid == 0){
    4006:	e93d                	bnez	a0,407c <openiputtest+0xa2>
    int fd = open("oidir", O_RDWR);
    4008:	4589                	li	a1,2
    400a:	00004517          	auipc	a0,0x4
    400e:	bb650513          	addi	a0,a0,-1098 # 7bc0 <malloc+0x1f20>
    4012:	00002097          	auipc	ra,0x2
    4016:	880080e7          	jalr	-1920(ra) # 5892 <open>
    if(fd >= 0){
    401a:	04054c63          	bltz	a0,4072 <openiputtest+0x98>
      printf("%s: open directory for write succeeded\n", s);
    401e:	85a6                	mv	a1,s1
    4020:	00004517          	auipc	a0,0x4
    4024:	bc050513          	addi	a0,a0,-1088 # 7be0 <malloc+0x1f40>
    4028:	00002097          	auipc	ra,0x2
    402c:	bba080e7          	jalr	-1094(ra) # 5be2 <printf>
      exit(1);
    4030:	4505                	li	a0,1
    4032:	00002097          	auipc	ra,0x2
    4036:	820080e7          	jalr	-2016(ra) # 5852 <exit>
    printf("%s: mkdir oidir failed\n", s);
    403a:	85a6                	mv	a1,s1
    403c:	00004517          	auipc	a0,0x4
    4040:	b8c50513          	addi	a0,a0,-1140 # 7bc8 <malloc+0x1f28>
    4044:	00002097          	auipc	ra,0x2
    4048:	b9e080e7          	jalr	-1122(ra) # 5be2 <printf>
    exit(1);
    404c:	4505                	li	a0,1
    404e:	00002097          	auipc	ra,0x2
    4052:	804080e7          	jalr	-2044(ra) # 5852 <exit>
    printf("%s: fork failed\n", s);
    4056:	85a6                	mv	a1,s1
    4058:	00003517          	auipc	a0,0x3
    405c:	94050513          	addi	a0,a0,-1728 # 6998 <malloc+0xcf8>
    4060:	00002097          	auipc	ra,0x2
    4064:	b82080e7          	jalr	-1150(ra) # 5be2 <printf>
    exit(1);
    4068:	4505                	li	a0,1
    406a:	00001097          	auipc	ra,0x1
    406e:	7e8080e7          	jalr	2024(ra) # 5852 <exit>
    exit(0);
    4072:	4501                	li	a0,0
    4074:	00001097          	auipc	ra,0x1
    4078:	7de080e7          	jalr	2014(ra) # 5852 <exit>
  sleep(1);
    407c:	4505                	li	a0,1
    407e:	00002097          	auipc	ra,0x2
    4082:	864080e7          	jalr	-1948(ra) # 58e2 <sleep>
  if(unlink("oidir") != 0){
    4086:	00004517          	auipc	a0,0x4
    408a:	b3a50513          	addi	a0,a0,-1222 # 7bc0 <malloc+0x1f20>
    408e:	00002097          	auipc	ra,0x2
    4092:	814080e7          	jalr	-2028(ra) # 58a2 <unlink>
    4096:	cd19                	beqz	a0,40b4 <openiputtest+0xda>
    printf("%s: unlink failed\n", s);
    4098:	85a6                	mv	a1,s1
    409a:	00003517          	auipc	a0,0x3
    409e:	aee50513          	addi	a0,a0,-1298 # 6b88 <malloc+0xee8>
    40a2:	00002097          	auipc	ra,0x2
    40a6:	b40080e7          	jalr	-1216(ra) # 5be2 <printf>
    exit(1);
    40aa:	4505                	li	a0,1
    40ac:	00001097          	auipc	ra,0x1
    40b0:	7a6080e7          	jalr	1958(ra) # 5852 <exit>
  wait(&xstatus);
    40b4:	fdc40513          	addi	a0,s0,-36
    40b8:	00001097          	auipc	ra,0x1
    40bc:	7a2080e7          	jalr	1954(ra) # 585a <wait>
  exit(xstatus);
    40c0:	fdc42503          	lw	a0,-36(s0)
    40c4:	00001097          	auipc	ra,0x1
    40c8:	78e080e7          	jalr	1934(ra) # 5852 <exit>

00000000000040cc <forkforkfork>:
{
    40cc:	1101                	addi	sp,sp,-32
    40ce:	ec06                	sd	ra,24(sp)
    40d0:	e822                	sd	s0,16(sp)
    40d2:	e426                	sd	s1,8(sp)
    40d4:	1000                	addi	s0,sp,32
    40d6:	84aa                	mv	s1,a0
  unlink("stopforking");
    40d8:	00004517          	auipc	a0,0x4
    40dc:	b3050513          	addi	a0,a0,-1232 # 7c08 <malloc+0x1f68>
    40e0:	00001097          	auipc	ra,0x1
    40e4:	7c2080e7          	jalr	1986(ra) # 58a2 <unlink>
  int pid = fork();
    40e8:	00001097          	auipc	ra,0x1
    40ec:	762080e7          	jalr	1890(ra) # 584a <fork>
  if(pid < 0){
    40f0:	04054563          	bltz	a0,413a <forkforkfork+0x6e>
  if(pid == 0){
    40f4:	c12d                	beqz	a0,4156 <forkforkfork+0x8a>
  sleep(20); // two seconds
    40f6:	4551                	li	a0,20
    40f8:	00001097          	auipc	ra,0x1
    40fc:	7ea080e7          	jalr	2026(ra) # 58e2 <sleep>
  close(open("stopforking", O_CREATE|O_RDWR));
    4100:	20200593          	li	a1,514
    4104:	00004517          	auipc	a0,0x4
    4108:	b0450513          	addi	a0,a0,-1276 # 7c08 <malloc+0x1f68>
    410c:	00001097          	auipc	ra,0x1
    4110:	786080e7          	jalr	1926(ra) # 5892 <open>
    4114:	00001097          	auipc	ra,0x1
    4118:	766080e7          	jalr	1894(ra) # 587a <close>
  wait(0);
    411c:	4501                	li	a0,0
    411e:	00001097          	auipc	ra,0x1
    4122:	73c080e7          	jalr	1852(ra) # 585a <wait>
  sleep(10); // one second
    4126:	4529                	li	a0,10
    4128:	00001097          	auipc	ra,0x1
    412c:	7ba080e7          	jalr	1978(ra) # 58e2 <sleep>
}
    4130:	60e2                	ld	ra,24(sp)
    4132:	6442                	ld	s0,16(sp)
    4134:	64a2                	ld	s1,8(sp)
    4136:	6105                	addi	sp,sp,32
    4138:	8082                	ret
    printf("%s: fork failed", s);
    413a:	85a6                	mv	a1,s1
    413c:	00003517          	auipc	a0,0x3
    4140:	a1c50513          	addi	a0,a0,-1508 # 6b58 <malloc+0xeb8>
    4144:	00002097          	auipc	ra,0x2
    4148:	a9e080e7          	jalr	-1378(ra) # 5be2 <printf>
    exit(1);
    414c:	4505                	li	a0,1
    414e:	00001097          	auipc	ra,0x1
    4152:	704080e7          	jalr	1796(ra) # 5852 <exit>
      int fd = open("stopforking", 0);
    4156:	00004497          	auipc	s1,0x4
    415a:	ab248493          	addi	s1,s1,-1358 # 7c08 <malloc+0x1f68>
    415e:	4581                	li	a1,0
    4160:	8526                	mv	a0,s1
    4162:	00001097          	auipc	ra,0x1
    4166:	730080e7          	jalr	1840(ra) # 5892 <open>
      if(fd >= 0){
    416a:	02055463          	bgez	a0,4192 <forkforkfork+0xc6>
      if(fork() < 0){
    416e:	00001097          	auipc	ra,0x1
    4172:	6dc080e7          	jalr	1756(ra) # 584a <fork>
    4176:	fe0554e3          	bgez	a0,415e <forkforkfork+0x92>
        close(open("stopforking", O_CREATE|O_RDWR));
    417a:	20200593          	li	a1,514
    417e:	8526                	mv	a0,s1
    4180:	00001097          	auipc	ra,0x1
    4184:	712080e7          	jalr	1810(ra) # 5892 <open>
    4188:	00001097          	auipc	ra,0x1
    418c:	6f2080e7          	jalr	1778(ra) # 587a <close>
    4190:	b7f9                	j	415e <forkforkfork+0x92>
        exit(0);
    4192:	4501                	li	a0,0
    4194:	00001097          	auipc	ra,0x1
    4198:	6be080e7          	jalr	1726(ra) # 5852 <exit>

000000000000419c <killstatus>:
{
    419c:	7139                	addi	sp,sp,-64
    419e:	fc06                	sd	ra,56(sp)
    41a0:	f822                	sd	s0,48(sp)
    41a2:	f426                	sd	s1,40(sp)
    41a4:	f04a                	sd	s2,32(sp)
    41a6:	ec4e                	sd	s3,24(sp)
    41a8:	e852                	sd	s4,16(sp)
    41aa:	0080                	addi	s0,sp,64
    41ac:	8a2a                	mv	s4,a0
    41ae:	06400913          	li	s2,100
    if(xst != -1) {
    41b2:	59fd                	li	s3,-1
    int pid1 = fork();
    41b4:	00001097          	auipc	ra,0x1
    41b8:	696080e7          	jalr	1686(ra) # 584a <fork>
    41bc:	84aa                	mv	s1,a0
    if(pid1 < 0){
    41be:	02054f63          	bltz	a0,41fc <killstatus+0x60>
    if(pid1 == 0){
    41c2:	c939                	beqz	a0,4218 <killstatus+0x7c>
    sleep(1);
    41c4:	4505                	li	a0,1
    41c6:	00001097          	auipc	ra,0x1
    41ca:	71c080e7          	jalr	1820(ra) # 58e2 <sleep>
    kill(pid1);
    41ce:	8526                	mv	a0,s1
    41d0:	00001097          	auipc	ra,0x1
    41d4:	6b2080e7          	jalr	1714(ra) # 5882 <kill>
    wait(&xst);
    41d8:	fcc40513          	addi	a0,s0,-52
    41dc:	00001097          	auipc	ra,0x1
    41e0:	67e080e7          	jalr	1662(ra) # 585a <wait>
    if(xst != -1) {
    41e4:	fcc42783          	lw	a5,-52(s0)
    41e8:	03379d63          	bne	a5,s3,4222 <killstatus+0x86>
  for(int i = 0; i < 100; i++){
    41ec:	397d                	addiw	s2,s2,-1
    41ee:	fc0913e3          	bnez	s2,41b4 <killstatus+0x18>
  exit(0);
    41f2:	4501                	li	a0,0
    41f4:	00001097          	auipc	ra,0x1
    41f8:	65e080e7          	jalr	1630(ra) # 5852 <exit>
      printf("%s: fork failed\n", s);
    41fc:	85d2                	mv	a1,s4
    41fe:	00002517          	auipc	a0,0x2
    4202:	79a50513          	addi	a0,a0,1946 # 6998 <malloc+0xcf8>
    4206:	00002097          	auipc	ra,0x2
    420a:	9dc080e7          	jalr	-1572(ra) # 5be2 <printf>
      exit(1);
    420e:	4505                	li	a0,1
    4210:	00001097          	auipc	ra,0x1
    4214:	642080e7          	jalr	1602(ra) # 5852 <exit>
        getpid();
    4218:	00001097          	auipc	ra,0x1
    421c:	6ba080e7          	jalr	1722(ra) # 58d2 <getpid>
      while(1) {
    4220:	bfe5                	j	4218 <killstatus+0x7c>
       printf("%s: status should be -1\n", s);
    4222:	85d2                	mv	a1,s4
    4224:	00004517          	auipc	a0,0x4
    4228:	9f450513          	addi	a0,a0,-1548 # 7c18 <malloc+0x1f78>
    422c:	00002097          	auipc	ra,0x2
    4230:	9b6080e7          	jalr	-1610(ra) # 5be2 <printf>
       exit(1);
    4234:	4505                	li	a0,1
    4236:	00001097          	auipc	ra,0x1
    423a:	61c080e7          	jalr	1564(ra) # 5852 <exit>

000000000000423e <preempt>:
{
    423e:	7139                	addi	sp,sp,-64
    4240:	fc06                	sd	ra,56(sp)
    4242:	f822                	sd	s0,48(sp)
    4244:	f426                	sd	s1,40(sp)
    4246:	f04a                	sd	s2,32(sp)
    4248:	ec4e                	sd	s3,24(sp)
    424a:	e852                	sd	s4,16(sp)
    424c:	0080                	addi	s0,sp,64
    424e:	84aa                	mv	s1,a0
  pid1 = fork();
    4250:	00001097          	auipc	ra,0x1
    4254:	5fa080e7          	jalr	1530(ra) # 584a <fork>
  if(pid1 < 0) {
    4258:	00054563          	bltz	a0,4262 <preempt+0x24>
    425c:	8a2a                	mv	s4,a0
  if(pid1 == 0)
    425e:	e105                	bnez	a0,427e <preempt+0x40>
    for(;;)
    4260:	a001                	j	4260 <preempt+0x22>
    printf("%s: fork failed", s);
    4262:	85a6                	mv	a1,s1
    4264:	00003517          	auipc	a0,0x3
    4268:	8f450513          	addi	a0,a0,-1804 # 6b58 <malloc+0xeb8>
    426c:	00002097          	auipc	ra,0x2
    4270:	976080e7          	jalr	-1674(ra) # 5be2 <printf>
    exit(1);
    4274:	4505                	li	a0,1
    4276:	00001097          	auipc	ra,0x1
    427a:	5dc080e7          	jalr	1500(ra) # 5852 <exit>
  pid2 = fork();
    427e:	00001097          	auipc	ra,0x1
    4282:	5cc080e7          	jalr	1484(ra) # 584a <fork>
    4286:	89aa                	mv	s3,a0
  if(pid2 < 0) {
    4288:	00054463          	bltz	a0,4290 <preempt+0x52>
  if(pid2 == 0)
    428c:	e105                	bnez	a0,42ac <preempt+0x6e>
    for(;;)
    428e:	a001                	j	428e <preempt+0x50>
    printf("%s: fork failed\n", s);
    4290:	85a6                	mv	a1,s1
    4292:	00002517          	auipc	a0,0x2
    4296:	70650513          	addi	a0,a0,1798 # 6998 <malloc+0xcf8>
    429a:	00002097          	auipc	ra,0x2
    429e:	948080e7          	jalr	-1720(ra) # 5be2 <printf>
    exit(1);
    42a2:	4505                	li	a0,1
    42a4:	00001097          	auipc	ra,0x1
    42a8:	5ae080e7          	jalr	1454(ra) # 5852 <exit>
  pipe(pfds);
    42ac:	fc840513          	addi	a0,s0,-56
    42b0:	00001097          	auipc	ra,0x1
    42b4:	5b2080e7          	jalr	1458(ra) # 5862 <pipe>
  pid3 = fork();
    42b8:	00001097          	auipc	ra,0x1
    42bc:	592080e7          	jalr	1426(ra) # 584a <fork>
    42c0:	892a                	mv	s2,a0
  if(pid3 < 0) {
    42c2:	02054e63          	bltz	a0,42fe <preempt+0xc0>
  if(pid3 == 0){
    42c6:	e525                	bnez	a0,432e <preempt+0xf0>
    close(pfds[0]);
    42c8:	fc842503          	lw	a0,-56(s0)
    42cc:	00001097          	auipc	ra,0x1
    42d0:	5ae080e7          	jalr	1454(ra) # 587a <close>
    if(write(pfds[1], "x", 1) != 1)
    42d4:	4605                	li	a2,1
    42d6:	00002597          	auipc	a1,0x2
    42da:	eca58593          	addi	a1,a1,-310 # 61a0 <malloc+0x500>
    42de:	fcc42503          	lw	a0,-52(s0)
    42e2:	00001097          	auipc	ra,0x1
    42e6:	590080e7          	jalr	1424(ra) # 5872 <write>
    42ea:	4785                	li	a5,1
    42ec:	02f51763          	bne	a0,a5,431a <preempt+0xdc>
    close(pfds[1]);
    42f0:	fcc42503          	lw	a0,-52(s0)
    42f4:	00001097          	auipc	ra,0x1
    42f8:	586080e7          	jalr	1414(ra) # 587a <close>
    for(;;)
    42fc:	a001                	j	42fc <preempt+0xbe>
     printf("%s: fork failed\n", s);
    42fe:	85a6                	mv	a1,s1
    4300:	00002517          	auipc	a0,0x2
    4304:	69850513          	addi	a0,a0,1688 # 6998 <malloc+0xcf8>
    4308:	00002097          	auipc	ra,0x2
    430c:	8da080e7          	jalr	-1830(ra) # 5be2 <printf>
     exit(1);
    4310:	4505                	li	a0,1
    4312:	00001097          	auipc	ra,0x1
    4316:	540080e7          	jalr	1344(ra) # 5852 <exit>
      printf("%s: preempt write error", s);
    431a:	85a6                	mv	a1,s1
    431c:	00004517          	auipc	a0,0x4
    4320:	91c50513          	addi	a0,a0,-1764 # 7c38 <malloc+0x1f98>
    4324:	00002097          	auipc	ra,0x2
    4328:	8be080e7          	jalr	-1858(ra) # 5be2 <printf>
    432c:	b7d1                	j	42f0 <preempt+0xb2>
  close(pfds[1]);
    432e:	fcc42503          	lw	a0,-52(s0)
    4332:	00001097          	auipc	ra,0x1
    4336:	548080e7          	jalr	1352(ra) # 587a <close>
  if(read(pfds[0], buf, sizeof(buf)) != 1){
    433a:	660d                	lui	a2,0x3
    433c:	00008597          	auipc	a1,0x8
    4340:	a9c58593          	addi	a1,a1,-1380 # bdd8 <buf>
    4344:	fc842503          	lw	a0,-56(s0)
    4348:	00001097          	auipc	ra,0x1
    434c:	522080e7          	jalr	1314(ra) # 586a <read>
    4350:	4785                	li	a5,1
    4352:	02f50363          	beq	a0,a5,4378 <preempt+0x13a>
    printf("%s: preempt read error", s);
    4356:	85a6                	mv	a1,s1
    4358:	00004517          	auipc	a0,0x4
    435c:	8f850513          	addi	a0,a0,-1800 # 7c50 <malloc+0x1fb0>
    4360:	00002097          	auipc	ra,0x2
    4364:	882080e7          	jalr	-1918(ra) # 5be2 <printf>
}
    4368:	70e2                	ld	ra,56(sp)
    436a:	7442                	ld	s0,48(sp)
    436c:	74a2                	ld	s1,40(sp)
    436e:	7902                	ld	s2,32(sp)
    4370:	69e2                	ld	s3,24(sp)
    4372:	6a42                	ld	s4,16(sp)
    4374:	6121                	addi	sp,sp,64
    4376:	8082                	ret
  close(pfds[0]);
    4378:	fc842503          	lw	a0,-56(s0)
    437c:	00001097          	auipc	ra,0x1
    4380:	4fe080e7          	jalr	1278(ra) # 587a <close>
  printf("kill... ");
    4384:	00004517          	auipc	a0,0x4
    4388:	8e450513          	addi	a0,a0,-1820 # 7c68 <malloc+0x1fc8>
    438c:	00002097          	auipc	ra,0x2
    4390:	856080e7          	jalr	-1962(ra) # 5be2 <printf>
  kill(pid1);
    4394:	8552                	mv	a0,s4
    4396:	00001097          	auipc	ra,0x1
    439a:	4ec080e7          	jalr	1260(ra) # 5882 <kill>
  kill(pid2);
    439e:	854e                	mv	a0,s3
    43a0:	00001097          	auipc	ra,0x1
    43a4:	4e2080e7          	jalr	1250(ra) # 5882 <kill>
  kill(pid3);
    43a8:	854a                	mv	a0,s2
    43aa:	00001097          	auipc	ra,0x1
    43ae:	4d8080e7          	jalr	1240(ra) # 5882 <kill>
  printf("wait... ");
    43b2:	00004517          	auipc	a0,0x4
    43b6:	8c650513          	addi	a0,a0,-1850 # 7c78 <malloc+0x1fd8>
    43ba:	00002097          	auipc	ra,0x2
    43be:	828080e7          	jalr	-2008(ra) # 5be2 <printf>
  wait(0);
    43c2:	4501                	li	a0,0
    43c4:	00001097          	auipc	ra,0x1
    43c8:	496080e7          	jalr	1174(ra) # 585a <wait>
  wait(0);
    43cc:	4501                	li	a0,0
    43ce:	00001097          	auipc	ra,0x1
    43d2:	48c080e7          	jalr	1164(ra) # 585a <wait>
  wait(0);
    43d6:	4501                	li	a0,0
    43d8:	00001097          	auipc	ra,0x1
    43dc:	482080e7          	jalr	1154(ra) # 585a <wait>
    43e0:	b761                	j	4368 <preempt+0x12a>

00000000000043e2 <reparent>:
{
    43e2:	7179                	addi	sp,sp,-48
    43e4:	f406                	sd	ra,40(sp)
    43e6:	f022                	sd	s0,32(sp)
    43e8:	ec26                	sd	s1,24(sp)
    43ea:	e84a                	sd	s2,16(sp)
    43ec:	e44e                	sd	s3,8(sp)
    43ee:	e052                	sd	s4,0(sp)
    43f0:	1800                	addi	s0,sp,48
    43f2:	89aa                	mv	s3,a0
  int master_pid = getpid();
    43f4:	00001097          	auipc	ra,0x1
    43f8:	4de080e7          	jalr	1246(ra) # 58d2 <getpid>
    43fc:	8a2a                	mv	s4,a0
    43fe:	0c800913          	li	s2,200
    int pid = fork();
    4402:	00001097          	auipc	ra,0x1
    4406:	448080e7          	jalr	1096(ra) # 584a <fork>
    440a:	84aa                	mv	s1,a0
    if(pid < 0){
    440c:	02054263          	bltz	a0,4430 <reparent+0x4e>
    if(pid){
    4410:	cd21                	beqz	a0,4468 <reparent+0x86>
      if(wait(0) != pid){
    4412:	4501                	li	a0,0
    4414:	00001097          	auipc	ra,0x1
    4418:	446080e7          	jalr	1094(ra) # 585a <wait>
    441c:	02951863          	bne	a0,s1,444c <reparent+0x6a>
  for(int i = 0; i < 200; i++){
    4420:	397d                	addiw	s2,s2,-1
    4422:	fe0910e3          	bnez	s2,4402 <reparent+0x20>
  exit(0);
    4426:	4501                	li	a0,0
    4428:	00001097          	auipc	ra,0x1
    442c:	42a080e7          	jalr	1066(ra) # 5852 <exit>
      printf("%s: fork failed\n", s);
    4430:	85ce                	mv	a1,s3
    4432:	00002517          	auipc	a0,0x2
    4436:	56650513          	addi	a0,a0,1382 # 6998 <malloc+0xcf8>
    443a:	00001097          	auipc	ra,0x1
    443e:	7a8080e7          	jalr	1960(ra) # 5be2 <printf>
      exit(1);
    4442:	4505                	li	a0,1
    4444:	00001097          	auipc	ra,0x1
    4448:	40e080e7          	jalr	1038(ra) # 5852 <exit>
        printf("%s: wait wrong pid\n", s);
    444c:	85ce                	mv	a1,s3
    444e:	00002517          	auipc	a0,0x2
    4452:	6d250513          	addi	a0,a0,1746 # 6b20 <malloc+0xe80>
    4456:	00001097          	auipc	ra,0x1
    445a:	78c080e7          	jalr	1932(ra) # 5be2 <printf>
        exit(1);
    445e:	4505                	li	a0,1
    4460:	00001097          	auipc	ra,0x1
    4464:	3f2080e7          	jalr	1010(ra) # 5852 <exit>
      int pid2 = fork();
    4468:	00001097          	auipc	ra,0x1
    446c:	3e2080e7          	jalr	994(ra) # 584a <fork>
      if(pid2 < 0){
    4470:	00054763          	bltz	a0,447e <reparent+0x9c>
      exit(0);
    4474:	4501                	li	a0,0
    4476:	00001097          	auipc	ra,0x1
    447a:	3dc080e7          	jalr	988(ra) # 5852 <exit>
        kill(master_pid);
    447e:	8552                	mv	a0,s4
    4480:	00001097          	auipc	ra,0x1
    4484:	402080e7          	jalr	1026(ra) # 5882 <kill>
        exit(1);
    4488:	4505                	li	a0,1
    448a:	00001097          	auipc	ra,0x1
    448e:	3c8080e7          	jalr	968(ra) # 5852 <exit>

0000000000004492 <sbrkfail>:
{
    4492:	7119                	addi	sp,sp,-128
    4494:	fc86                	sd	ra,120(sp)
    4496:	f8a2                	sd	s0,112(sp)
    4498:	f4a6                	sd	s1,104(sp)
    449a:	f0ca                	sd	s2,96(sp)
    449c:	ecce                	sd	s3,88(sp)
    449e:	e8d2                	sd	s4,80(sp)
    44a0:	e4d6                	sd	s5,72(sp)
    44a2:	0100                	addi	s0,sp,128
    44a4:	892a                	mv	s2,a0
  if(pipe(fds) != 0){
    44a6:	fb040513          	addi	a0,s0,-80
    44aa:	00001097          	auipc	ra,0x1
    44ae:	3b8080e7          	jalr	952(ra) # 5862 <pipe>
    44b2:	e901                	bnez	a0,44c2 <sbrkfail+0x30>
    44b4:	f8040493          	addi	s1,s0,-128
    44b8:	fa840a13          	addi	s4,s0,-88
    44bc:	89a6                	mv	s3,s1
    if(pids[i] != -1)
    44be:	5afd                	li	s5,-1
    44c0:	a08d                	j	4522 <sbrkfail+0x90>
    printf("%s: pipe() failed\n", s);
    44c2:	85ca                	mv	a1,s2
    44c4:	00002517          	auipc	a0,0x2
    44c8:	5dc50513          	addi	a0,a0,1500 # 6aa0 <malloc+0xe00>
    44cc:	00001097          	auipc	ra,0x1
    44d0:	716080e7          	jalr	1814(ra) # 5be2 <printf>
    exit(1);
    44d4:	4505                	li	a0,1
    44d6:	00001097          	auipc	ra,0x1
    44da:	37c080e7          	jalr	892(ra) # 5852 <exit>
      sbrk(BIG - (uint64)sbrk(0));
    44de:	4501                	li	a0,0
    44e0:	00001097          	auipc	ra,0x1
    44e4:	3fa080e7          	jalr	1018(ra) # 58da <sbrk>
    44e8:	064007b7          	lui	a5,0x6400
    44ec:	40a7853b          	subw	a0,a5,a0
    44f0:	00001097          	auipc	ra,0x1
    44f4:	3ea080e7          	jalr	1002(ra) # 58da <sbrk>
      write(fds[1], "x", 1);
    44f8:	4605                	li	a2,1
    44fa:	00002597          	auipc	a1,0x2
    44fe:	ca658593          	addi	a1,a1,-858 # 61a0 <malloc+0x500>
    4502:	fb442503          	lw	a0,-76(s0)
    4506:	00001097          	auipc	ra,0x1
    450a:	36c080e7          	jalr	876(ra) # 5872 <write>
      for(;;) sleep(1000);
    450e:	3e800513          	li	a0,1000
    4512:	00001097          	auipc	ra,0x1
    4516:	3d0080e7          	jalr	976(ra) # 58e2 <sleep>
    451a:	bfd5                	j	450e <sbrkfail+0x7c>
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    451c:	0991                	addi	s3,s3,4
    451e:	03498563          	beq	s3,s4,4548 <sbrkfail+0xb6>
    if((pids[i] = fork()) == 0){
    4522:	00001097          	auipc	ra,0x1
    4526:	328080e7          	jalr	808(ra) # 584a <fork>
    452a:	00a9a023          	sw	a0,0(s3)
    452e:	d945                	beqz	a0,44de <sbrkfail+0x4c>
    if(pids[i] != -1)
    4530:	ff5506e3          	beq	a0,s5,451c <sbrkfail+0x8a>
      read(fds[0], &scratch, 1);
    4534:	4605                	li	a2,1
    4536:	faf40593          	addi	a1,s0,-81
    453a:	fb042503          	lw	a0,-80(s0)
    453e:	00001097          	auipc	ra,0x1
    4542:	32c080e7          	jalr	812(ra) # 586a <read>
    4546:	bfd9                	j	451c <sbrkfail+0x8a>
  c = sbrk(PGSIZE);
    4548:	6505                	lui	a0,0x1
    454a:	00001097          	auipc	ra,0x1
    454e:	390080e7          	jalr	912(ra) # 58da <sbrk>
    4552:	89aa                	mv	s3,a0
    if(pids[i] == -1)
    4554:	5afd                	li	s5,-1
    4556:	a021                	j	455e <sbrkfail+0xcc>
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    4558:	0491                	addi	s1,s1,4
    455a:	01448f63          	beq	s1,s4,4578 <sbrkfail+0xe6>
    if(pids[i] == -1)
    455e:	4088                	lw	a0,0(s1)
    4560:	ff550ce3          	beq	a0,s5,4558 <sbrkfail+0xc6>
    kill(pids[i]);
    4564:	00001097          	auipc	ra,0x1
    4568:	31e080e7          	jalr	798(ra) # 5882 <kill>
    wait(0);
    456c:	4501                	li	a0,0
    456e:	00001097          	auipc	ra,0x1
    4572:	2ec080e7          	jalr	748(ra) # 585a <wait>
    4576:	b7cd                	j	4558 <sbrkfail+0xc6>
  if(c == (char*)0xffffffffffffffffL){
    4578:	57fd                	li	a5,-1
    457a:	04f98963          	beq	s3,a5,45cc <sbrkfail+0x13a>
  pid = fork();
    457e:	00001097          	auipc	ra,0x1
    4582:	2cc080e7          	jalr	716(ra) # 584a <fork>
    4586:	84aa                	mv	s1,a0
  if(pid < 0){
    4588:	06054063          	bltz	a0,45e8 <sbrkfail+0x156>
  if(pid == 0){
    458c:	cd25                	beqz	a0,4604 <sbrkfail+0x172>
  wait(&xstatus);
    458e:	fbc40513          	addi	a0,s0,-68
    4592:	00001097          	auipc	ra,0x1
    4596:	2c8080e7          	jalr	712(ra) # 585a <wait>
  if(xstatus != -1 && xstatus != 2){
    459a:	fbc42783          	lw	a5,-68(s0)
    459e:	577d                	li	a4,-1
    45a0:	00e78563          	beq	a5,a4,45aa <sbrkfail+0x118>
    45a4:	4709                	li	a4,2
    45a6:	0ae79563          	bne	a5,a4,4650 <sbrkfail+0x1be>
  printf("done sbrkfail");
    45aa:	00003517          	auipc	a0,0x3
    45ae:	72e50513          	addi	a0,a0,1838 # 7cd8 <malloc+0x2038>
    45b2:	00001097          	auipc	ra,0x1
    45b6:	630080e7          	jalr	1584(ra) # 5be2 <printf>
}
    45ba:	70e6                	ld	ra,120(sp)
    45bc:	7446                	ld	s0,112(sp)
    45be:	74a6                	ld	s1,104(sp)
    45c0:	7906                	ld	s2,96(sp)
    45c2:	69e6                	ld	s3,88(sp)
    45c4:	6a46                	ld	s4,80(sp)
    45c6:	6aa6                	ld	s5,72(sp)
    45c8:	6109                	addi	sp,sp,128
    45ca:	8082                	ret
    printf("%s: failed sbrk leaked memory\n", s);
    45cc:	85ca                	mv	a1,s2
    45ce:	00003517          	auipc	a0,0x3
    45d2:	6ba50513          	addi	a0,a0,1722 # 7c88 <malloc+0x1fe8>
    45d6:	00001097          	auipc	ra,0x1
    45da:	60c080e7          	jalr	1548(ra) # 5be2 <printf>
    exit(1);
    45de:	4505                	li	a0,1
    45e0:	00001097          	auipc	ra,0x1
    45e4:	272080e7          	jalr	626(ra) # 5852 <exit>
    printf("%s: fork failed\n", s);
    45e8:	85ca                	mv	a1,s2
    45ea:	00002517          	auipc	a0,0x2
    45ee:	3ae50513          	addi	a0,a0,942 # 6998 <malloc+0xcf8>
    45f2:	00001097          	auipc	ra,0x1
    45f6:	5f0080e7          	jalr	1520(ra) # 5be2 <printf>
    exit(1);
    45fa:	4505                	li	a0,1
    45fc:	00001097          	auipc	ra,0x1
    4600:	256080e7          	jalr	598(ra) # 5852 <exit>
    a = sbrk(0);
    4604:	4501                	li	a0,0
    4606:	00001097          	auipc	ra,0x1
    460a:	2d4080e7          	jalr	724(ra) # 58da <sbrk>
    460e:	89aa                	mv	s3,a0
    sbrk(10*BIG);
    4610:	3e800537          	lui	a0,0x3e800
    4614:	00001097          	auipc	ra,0x1
    4618:	2c6080e7          	jalr	710(ra) # 58da <sbrk>
    for (i = 0; i < 10*BIG; i += PGSIZE) {
    461c:	874e                	mv	a4,s3
    461e:	3e8007b7          	lui	a5,0x3e800
    4622:	97ce                	add	a5,a5,s3
    4624:	6685                	lui	a3,0x1
      n += *(a+i);
    4626:	00074603          	lbu	a2,0(a4)
    462a:	9cb1                	addw	s1,s1,a2
    for (i = 0; i < 10*BIG; i += PGSIZE) {
    462c:	9736                	add	a4,a4,a3
    462e:	fef71ce3          	bne	a4,a5,4626 <sbrkfail+0x194>
    printf("%s: allocate a lot of memory succeeded %d\n", s, n);
    4632:	8626                	mv	a2,s1
    4634:	85ca                	mv	a1,s2
    4636:	00003517          	auipc	a0,0x3
    463a:	67250513          	addi	a0,a0,1650 # 7ca8 <malloc+0x2008>
    463e:	00001097          	auipc	ra,0x1
    4642:	5a4080e7          	jalr	1444(ra) # 5be2 <printf>
    exit(1);
    4646:	4505                	li	a0,1
    4648:	00001097          	auipc	ra,0x1
    464c:	20a080e7          	jalr	522(ra) # 5852 <exit>
    printf("done sbrkfail");
    4650:	00003517          	auipc	a0,0x3
    4654:	68850513          	addi	a0,a0,1672 # 7cd8 <malloc+0x2038>
    4658:	00001097          	auipc	ra,0x1
    465c:	58a080e7          	jalr	1418(ra) # 5be2 <printf>
    exit(1);
    4660:	4505                	li	a0,1
    4662:	00001097          	auipc	ra,0x1
    4666:	1f0080e7          	jalr	496(ra) # 5852 <exit>

000000000000466a <mem>:
{
    466a:	7139                	addi	sp,sp,-64
    466c:	fc06                	sd	ra,56(sp)
    466e:	f822                	sd	s0,48(sp)
    4670:	f426                	sd	s1,40(sp)
    4672:	f04a                	sd	s2,32(sp)
    4674:	ec4e                	sd	s3,24(sp)
    4676:	0080                	addi	s0,sp,64
    4678:	89aa                	mv	s3,a0
  if((pid = fork()) == 0){
    467a:	00001097          	auipc	ra,0x1
    467e:	1d0080e7          	jalr	464(ra) # 584a <fork>
    m1 = 0;
    4682:	4481                	li	s1,0
    while((m2 = malloc(10001)) != 0){
    4684:	6909                	lui	s2,0x2
    4686:	71190913          	addi	s2,s2,1809 # 2711 <rwsbrk+0xf5>
  if((pid = fork()) == 0){
    468a:	ed39                	bnez	a0,46e8 <mem+0x7e>
    while((m2 = malloc(10001)) != 0){
    468c:	854a                	mv	a0,s2
    468e:	00001097          	auipc	ra,0x1
    4692:	612080e7          	jalr	1554(ra) # 5ca0 <malloc>
    4696:	c501                	beqz	a0,469e <mem+0x34>
      *(char**)m2 = m1;
    4698:	e104                	sd	s1,0(a0)
      m1 = m2;
    469a:	84aa                	mv	s1,a0
    469c:	bfc5                	j	468c <mem+0x22>
    while(m1){
    469e:	c881                	beqz	s1,46ae <mem+0x44>
      m2 = *(char**)m1;
    46a0:	8526                	mv	a0,s1
    46a2:	6084                	ld	s1,0(s1)
      free(m1);
    46a4:	00001097          	auipc	ra,0x1
    46a8:	574080e7          	jalr	1396(ra) # 5c18 <free>
    while(m1){
    46ac:	f8f5                	bnez	s1,46a0 <mem+0x36>
    m1 = malloc(1024*20);
    46ae:	6515                	lui	a0,0x5
    46b0:	00001097          	auipc	ra,0x1
    46b4:	5f0080e7          	jalr	1520(ra) # 5ca0 <malloc>
    if(m1 == 0){
    46b8:	c911                	beqz	a0,46cc <mem+0x62>
    free(m1);
    46ba:	00001097          	auipc	ra,0x1
    46be:	55e080e7          	jalr	1374(ra) # 5c18 <free>
    exit(0);
    46c2:	4501                	li	a0,0
    46c4:	00001097          	auipc	ra,0x1
    46c8:	18e080e7          	jalr	398(ra) # 5852 <exit>
      printf("couldn't allocate mem?!!\n", s);
    46cc:	85ce                	mv	a1,s3
    46ce:	00003517          	auipc	a0,0x3
    46d2:	61a50513          	addi	a0,a0,1562 # 7ce8 <malloc+0x2048>
    46d6:	00001097          	auipc	ra,0x1
    46da:	50c080e7          	jalr	1292(ra) # 5be2 <printf>
      exit(1);
    46de:	4505                	li	a0,1
    46e0:	00001097          	auipc	ra,0x1
    46e4:	172080e7          	jalr	370(ra) # 5852 <exit>
    wait(&xstatus);
    46e8:	fcc40513          	addi	a0,s0,-52
    46ec:	00001097          	auipc	ra,0x1
    46f0:	16e080e7          	jalr	366(ra) # 585a <wait>
    if(xstatus == -1){
    46f4:	fcc42503          	lw	a0,-52(s0)
    46f8:	57fd                	li	a5,-1
    46fa:	00f50663          	beq	a0,a5,4706 <mem+0x9c>
    exit(xstatus);
    46fe:	00001097          	auipc	ra,0x1
    4702:	154080e7          	jalr	340(ra) # 5852 <exit>
      exit(0);
    4706:	4501                	li	a0,0
    4708:	00001097          	auipc	ra,0x1
    470c:	14a080e7          	jalr	330(ra) # 5852 <exit>

0000000000004710 <sharedfd>:
{
    4710:	7159                	addi	sp,sp,-112
    4712:	f486                	sd	ra,104(sp)
    4714:	f0a2                	sd	s0,96(sp)
    4716:	eca6                	sd	s1,88(sp)
    4718:	e8ca                	sd	s2,80(sp)
    471a:	e4ce                	sd	s3,72(sp)
    471c:	e0d2                	sd	s4,64(sp)
    471e:	fc56                	sd	s5,56(sp)
    4720:	f85a                	sd	s6,48(sp)
    4722:	f45e                	sd	s7,40(sp)
    4724:	1880                	addi	s0,sp,112
    4726:	8a2a                	mv	s4,a0
  unlink("sharedfd");
    4728:	00002517          	auipc	a0,0x2
    472c:	81850513          	addi	a0,a0,-2024 # 5f40 <malloc+0x2a0>
    4730:	00001097          	auipc	ra,0x1
    4734:	172080e7          	jalr	370(ra) # 58a2 <unlink>
  fd = open("sharedfd", O_CREATE|O_RDWR);
    4738:	20200593          	li	a1,514
    473c:	00002517          	auipc	a0,0x2
    4740:	80450513          	addi	a0,a0,-2044 # 5f40 <malloc+0x2a0>
    4744:	00001097          	auipc	ra,0x1
    4748:	14e080e7          	jalr	334(ra) # 5892 <open>
  if(fd < 0){
    474c:	04054a63          	bltz	a0,47a0 <sharedfd+0x90>
    4750:	892a                	mv	s2,a0
  pid = fork();
    4752:	00001097          	auipc	ra,0x1
    4756:	0f8080e7          	jalr	248(ra) # 584a <fork>
    475a:	89aa                	mv	s3,a0
  memset(buf, pid==0?'c':'p', sizeof(buf));
    475c:	06300593          	li	a1,99
    4760:	c119                	beqz	a0,4766 <sharedfd+0x56>
    4762:	07000593          	li	a1,112
    4766:	4629                	li	a2,10
    4768:	fa040513          	addi	a0,s0,-96
    476c:	00001097          	auipc	ra,0x1
    4770:	ee2080e7          	jalr	-286(ra) # 564e <memset>
    4774:	3e800493          	li	s1,1000
    if(write(fd, buf, sizeof(buf)) != sizeof(buf)){
    4778:	4629                	li	a2,10
    477a:	fa040593          	addi	a1,s0,-96
    477e:	854a                	mv	a0,s2
    4780:	00001097          	auipc	ra,0x1
    4784:	0f2080e7          	jalr	242(ra) # 5872 <write>
    4788:	47a9                	li	a5,10
    478a:	02f51963          	bne	a0,a5,47bc <sharedfd+0xac>
  for(i = 0; i < N; i++){
    478e:	34fd                	addiw	s1,s1,-1
    4790:	f4e5                	bnez	s1,4778 <sharedfd+0x68>
  if(pid == 0) {
    4792:	04099363          	bnez	s3,47d8 <sharedfd+0xc8>
    exit(0);
    4796:	4501                	li	a0,0
    4798:	00001097          	auipc	ra,0x1
    479c:	0ba080e7          	jalr	186(ra) # 5852 <exit>
    printf("%s: cannot open sharedfd for writing", s);
    47a0:	85d2                	mv	a1,s4
    47a2:	00003517          	auipc	a0,0x3
    47a6:	56650513          	addi	a0,a0,1382 # 7d08 <malloc+0x2068>
    47aa:	00001097          	auipc	ra,0x1
    47ae:	438080e7          	jalr	1080(ra) # 5be2 <printf>
    exit(1);
    47b2:	4505                	li	a0,1
    47b4:	00001097          	auipc	ra,0x1
    47b8:	09e080e7          	jalr	158(ra) # 5852 <exit>
      printf("%s: write sharedfd failed\n", s);
    47bc:	85d2                	mv	a1,s4
    47be:	00003517          	auipc	a0,0x3
    47c2:	57250513          	addi	a0,a0,1394 # 7d30 <malloc+0x2090>
    47c6:	00001097          	auipc	ra,0x1
    47ca:	41c080e7          	jalr	1052(ra) # 5be2 <printf>
      exit(1);
    47ce:	4505                	li	a0,1
    47d0:	00001097          	auipc	ra,0x1
    47d4:	082080e7          	jalr	130(ra) # 5852 <exit>
    wait(&xstatus);
    47d8:	f9c40513          	addi	a0,s0,-100
    47dc:	00001097          	auipc	ra,0x1
    47e0:	07e080e7          	jalr	126(ra) # 585a <wait>
    if(xstatus != 0)
    47e4:	f9c42983          	lw	s3,-100(s0)
    47e8:	00098763          	beqz	s3,47f6 <sharedfd+0xe6>
      exit(xstatus);
    47ec:	854e                	mv	a0,s3
    47ee:	00001097          	auipc	ra,0x1
    47f2:	064080e7          	jalr	100(ra) # 5852 <exit>
  close(fd);
    47f6:	854a                	mv	a0,s2
    47f8:	00001097          	auipc	ra,0x1
    47fc:	082080e7          	jalr	130(ra) # 587a <close>
  fd = open("sharedfd", 0);
    4800:	4581                	li	a1,0
    4802:	00001517          	auipc	a0,0x1
    4806:	73e50513          	addi	a0,a0,1854 # 5f40 <malloc+0x2a0>
    480a:	00001097          	auipc	ra,0x1
    480e:	088080e7          	jalr	136(ra) # 5892 <open>
    4812:	8baa                	mv	s7,a0
  nc = np = 0;
    4814:	8ace                	mv	s5,s3
  if(fd < 0){
    4816:	02054563          	bltz	a0,4840 <sharedfd+0x130>
    481a:	faa40913          	addi	s2,s0,-86
      if(buf[i] == 'c')
    481e:	06300493          	li	s1,99
      if(buf[i] == 'p')
    4822:	07000b13          	li	s6,112
  while((n = read(fd, buf, sizeof(buf))) > 0){
    4826:	4629                	li	a2,10
    4828:	fa040593          	addi	a1,s0,-96
    482c:	855e                	mv	a0,s7
    482e:	00001097          	auipc	ra,0x1
    4832:	03c080e7          	jalr	60(ra) # 586a <read>
    4836:	02a05f63          	blez	a0,4874 <sharedfd+0x164>
    483a:	fa040793          	addi	a5,s0,-96
    483e:	a01d                	j	4864 <sharedfd+0x154>
    printf("%s: cannot open sharedfd for reading\n", s);
    4840:	85d2                	mv	a1,s4
    4842:	00003517          	auipc	a0,0x3
    4846:	50e50513          	addi	a0,a0,1294 # 7d50 <malloc+0x20b0>
    484a:	00001097          	auipc	ra,0x1
    484e:	398080e7          	jalr	920(ra) # 5be2 <printf>
    exit(1);
    4852:	4505                	li	a0,1
    4854:	00001097          	auipc	ra,0x1
    4858:	ffe080e7          	jalr	-2(ra) # 5852 <exit>
        nc++;
    485c:	2985                	addiw	s3,s3,1
    for(i = 0; i < sizeof(buf); i++){
    485e:	0785                	addi	a5,a5,1
    4860:	fd2783e3          	beq	a5,s2,4826 <sharedfd+0x116>
      if(buf[i] == 'c')
    4864:	0007c703          	lbu	a4,0(a5) # 3e800000 <__BSS_END__+0x3e7f1218>
    4868:	fe970ae3          	beq	a4,s1,485c <sharedfd+0x14c>
      if(buf[i] == 'p')
    486c:	ff6719e3          	bne	a4,s6,485e <sharedfd+0x14e>
        np++;
    4870:	2a85                	addiw	s5,s5,1
    4872:	b7f5                	j	485e <sharedfd+0x14e>
  close(fd);
    4874:	855e                	mv	a0,s7
    4876:	00001097          	auipc	ra,0x1
    487a:	004080e7          	jalr	4(ra) # 587a <close>
  unlink("sharedfd");
    487e:	00001517          	auipc	a0,0x1
    4882:	6c250513          	addi	a0,a0,1730 # 5f40 <malloc+0x2a0>
    4886:	00001097          	auipc	ra,0x1
    488a:	01c080e7          	jalr	28(ra) # 58a2 <unlink>
  if(nc == N*SZ && np == N*SZ){
    488e:	6789                	lui	a5,0x2
    4890:	71078793          	addi	a5,a5,1808 # 2710 <rwsbrk+0xf4>
    4894:	00f99763          	bne	s3,a5,48a2 <sharedfd+0x192>
    4898:	6789                	lui	a5,0x2
    489a:	71078793          	addi	a5,a5,1808 # 2710 <rwsbrk+0xf4>
    489e:	02fa8063          	beq	s5,a5,48be <sharedfd+0x1ae>
    printf("%s: nc/np test fails\n", s);
    48a2:	85d2                	mv	a1,s4
    48a4:	00003517          	auipc	a0,0x3
    48a8:	4d450513          	addi	a0,a0,1236 # 7d78 <malloc+0x20d8>
    48ac:	00001097          	auipc	ra,0x1
    48b0:	336080e7          	jalr	822(ra) # 5be2 <printf>
    exit(1);
    48b4:	4505                	li	a0,1
    48b6:	00001097          	auipc	ra,0x1
    48ba:	f9c080e7          	jalr	-100(ra) # 5852 <exit>
    exit(0);
    48be:	4501                	li	a0,0
    48c0:	00001097          	auipc	ra,0x1
    48c4:	f92080e7          	jalr	-110(ra) # 5852 <exit>

00000000000048c8 <fourfiles>:
{
    48c8:	7171                	addi	sp,sp,-176
    48ca:	f506                	sd	ra,168(sp)
    48cc:	f122                	sd	s0,160(sp)
    48ce:	ed26                	sd	s1,152(sp)
    48d0:	e94a                	sd	s2,144(sp)
    48d2:	e54e                	sd	s3,136(sp)
    48d4:	e152                	sd	s4,128(sp)
    48d6:	fcd6                	sd	s5,120(sp)
    48d8:	f8da                	sd	s6,112(sp)
    48da:	f4de                	sd	s7,104(sp)
    48dc:	f0e2                	sd	s8,96(sp)
    48de:	ece6                	sd	s9,88(sp)
    48e0:	e8ea                	sd	s10,80(sp)
    48e2:	e4ee                	sd	s11,72(sp)
    48e4:	1900                	addi	s0,sp,176
    48e6:	8caa                	mv	s9,a0
  char *names[] = { "f0", "f1", "f2", "f3" };
    48e8:	00001797          	auipc	a5,0x1
    48ec:	4a078793          	addi	a5,a5,1184 # 5d88 <malloc+0xe8>
    48f0:	f6f43823          	sd	a5,-144(s0)
    48f4:	00001797          	auipc	a5,0x1
    48f8:	49c78793          	addi	a5,a5,1180 # 5d90 <malloc+0xf0>
    48fc:	f6f43c23          	sd	a5,-136(s0)
    4900:	00001797          	auipc	a5,0x1
    4904:	49878793          	addi	a5,a5,1176 # 5d98 <malloc+0xf8>
    4908:	f8f43023          	sd	a5,-128(s0)
    490c:	00001797          	auipc	a5,0x1
    4910:	49478793          	addi	a5,a5,1172 # 5da0 <malloc+0x100>
    4914:	f8f43423          	sd	a5,-120(s0)
  for(pi = 0; pi < NCHILD; pi++){
    4918:	f7040b93          	addi	s7,s0,-144
  char *names[] = { "f0", "f1", "f2", "f3" };
    491c:	895e                	mv	s2,s7
  for(pi = 0; pi < NCHILD; pi++){
    491e:	4481                	li	s1,0
    4920:	4a11                	li	s4,4
    fname = names[pi];
    4922:	00093983          	ld	s3,0(s2)
    unlink(fname);
    4926:	854e                	mv	a0,s3
    4928:	00001097          	auipc	ra,0x1
    492c:	f7a080e7          	jalr	-134(ra) # 58a2 <unlink>
    pid = fork();
    4930:	00001097          	auipc	ra,0x1
    4934:	f1a080e7          	jalr	-230(ra) # 584a <fork>
    if(pid < 0){
    4938:	04054563          	bltz	a0,4982 <fourfiles+0xba>
    if(pid == 0){
    493c:	c12d                	beqz	a0,499e <fourfiles+0xd6>
  for(pi = 0; pi < NCHILD; pi++){
    493e:	2485                	addiw	s1,s1,1
    4940:	0921                	addi	s2,s2,8
    4942:	ff4490e3          	bne	s1,s4,4922 <fourfiles+0x5a>
    4946:	4491                	li	s1,4
    wait(&xstatus);
    4948:	f6c40513          	addi	a0,s0,-148
    494c:	00001097          	auipc	ra,0x1
    4950:	f0e080e7          	jalr	-242(ra) # 585a <wait>
    if(xstatus != 0)
    4954:	f6c42503          	lw	a0,-148(s0)
    4958:	ed69                	bnez	a0,4a32 <fourfiles+0x16a>
  for(pi = 0; pi < NCHILD; pi++){
    495a:	34fd                	addiw	s1,s1,-1
    495c:	f4f5                	bnez	s1,4948 <fourfiles+0x80>
    495e:	03000b13          	li	s6,48
    total = 0;
    4962:	f4a43c23          	sd	a0,-168(s0)
    while((n = read(fd, buf, sizeof(buf))) > 0){
    4966:	00007a17          	auipc	s4,0x7
    496a:	472a0a13          	addi	s4,s4,1138 # bdd8 <buf>
    496e:	00007a97          	auipc	s5,0x7
    4972:	46ba8a93          	addi	s5,s5,1131 # bdd9 <buf+0x1>
    if(total != N*SZ){
    4976:	6d05                	lui	s10,0x1
    4978:	770d0d13          	addi	s10,s10,1904 # 1770 <exectest+0xfe>
  for(i = 0; i < NCHILD; i++){
    497c:	03400d93          	li	s11,52
    4980:	a23d                	j	4aae <fourfiles+0x1e6>
      printf("fork failed\n", s);
    4982:	85e6                	mv	a1,s9
    4984:	00002517          	auipc	a0,0x2
    4988:	43450513          	addi	a0,a0,1076 # 6db8 <malloc+0x1118>
    498c:	00001097          	auipc	ra,0x1
    4990:	256080e7          	jalr	598(ra) # 5be2 <printf>
      exit(1);
    4994:	4505                	li	a0,1
    4996:	00001097          	auipc	ra,0x1
    499a:	ebc080e7          	jalr	-324(ra) # 5852 <exit>
      fd = open(fname, O_CREATE | O_RDWR);
    499e:	20200593          	li	a1,514
    49a2:	854e                	mv	a0,s3
    49a4:	00001097          	auipc	ra,0x1
    49a8:	eee080e7          	jalr	-274(ra) # 5892 <open>
    49ac:	892a                	mv	s2,a0
      if(fd < 0){
    49ae:	04054763          	bltz	a0,49fc <fourfiles+0x134>
      memset(buf, '0'+pi, SZ);
    49b2:	1f400613          	li	a2,500
    49b6:	0304859b          	addiw	a1,s1,48
    49ba:	00007517          	auipc	a0,0x7
    49be:	41e50513          	addi	a0,a0,1054 # bdd8 <buf>
    49c2:	00001097          	auipc	ra,0x1
    49c6:	c8c080e7          	jalr	-884(ra) # 564e <memset>
    49ca:	44b1                	li	s1,12
        if((n = write(fd, buf, SZ)) != SZ){
    49cc:	00007997          	auipc	s3,0x7
    49d0:	40c98993          	addi	s3,s3,1036 # bdd8 <buf>
    49d4:	1f400613          	li	a2,500
    49d8:	85ce                	mv	a1,s3
    49da:	854a                	mv	a0,s2
    49dc:	00001097          	auipc	ra,0x1
    49e0:	e96080e7          	jalr	-362(ra) # 5872 <write>
    49e4:	85aa                	mv	a1,a0
    49e6:	1f400793          	li	a5,500
    49ea:	02f51763          	bne	a0,a5,4a18 <fourfiles+0x150>
      for(i = 0; i < N; i++){
    49ee:	34fd                	addiw	s1,s1,-1
    49f0:	f0f5                	bnez	s1,49d4 <fourfiles+0x10c>
      exit(0);
    49f2:	4501                	li	a0,0
    49f4:	00001097          	auipc	ra,0x1
    49f8:	e5e080e7          	jalr	-418(ra) # 5852 <exit>
        printf("create failed\n", s);
    49fc:	85e6                	mv	a1,s9
    49fe:	00003517          	auipc	a0,0x3
    4a02:	39250513          	addi	a0,a0,914 # 7d90 <malloc+0x20f0>
    4a06:	00001097          	auipc	ra,0x1
    4a0a:	1dc080e7          	jalr	476(ra) # 5be2 <printf>
        exit(1);
    4a0e:	4505                	li	a0,1
    4a10:	00001097          	auipc	ra,0x1
    4a14:	e42080e7          	jalr	-446(ra) # 5852 <exit>
          printf("write failed %d\n", n);
    4a18:	00003517          	auipc	a0,0x3
    4a1c:	38850513          	addi	a0,a0,904 # 7da0 <malloc+0x2100>
    4a20:	00001097          	auipc	ra,0x1
    4a24:	1c2080e7          	jalr	450(ra) # 5be2 <printf>
          exit(1);
    4a28:	4505                	li	a0,1
    4a2a:	00001097          	auipc	ra,0x1
    4a2e:	e28080e7          	jalr	-472(ra) # 5852 <exit>
      exit(xstatus);
    4a32:	00001097          	auipc	ra,0x1
    4a36:	e20080e7          	jalr	-480(ra) # 5852 <exit>
          printf("wrong char\n", s);
    4a3a:	85e6                	mv	a1,s9
    4a3c:	00003517          	auipc	a0,0x3
    4a40:	37c50513          	addi	a0,a0,892 # 7db8 <malloc+0x2118>
    4a44:	00001097          	auipc	ra,0x1
    4a48:	19e080e7          	jalr	414(ra) # 5be2 <printf>
          exit(1);
    4a4c:	4505                	li	a0,1
    4a4e:	00001097          	auipc	ra,0x1
    4a52:	e04080e7          	jalr	-508(ra) # 5852 <exit>
      total += n;
    4a56:	00a9093b          	addw	s2,s2,a0
    while((n = read(fd, buf, sizeof(buf))) > 0){
    4a5a:	660d                	lui	a2,0x3
    4a5c:	85d2                	mv	a1,s4
    4a5e:	854e                	mv	a0,s3
    4a60:	00001097          	auipc	ra,0x1
    4a64:	e0a080e7          	jalr	-502(ra) # 586a <read>
    4a68:	02a05363          	blez	a0,4a8e <fourfiles+0x1c6>
    4a6c:	00007797          	auipc	a5,0x7
    4a70:	36c78793          	addi	a5,a5,876 # bdd8 <buf>
    4a74:	fff5069b          	addiw	a3,a0,-1
    4a78:	1682                	slli	a3,a3,0x20
    4a7a:	9281                	srli	a3,a3,0x20
    4a7c:	96d6                	add	a3,a3,s5
        if(buf[j] != '0'+i){
    4a7e:	0007c703          	lbu	a4,0(a5)
    4a82:	fa971ce3          	bne	a4,s1,4a3a <fourfiles+0x172>
      for(j = 0; j < n; j++){
    4a86:	0785                	addi	a5,a5,1
    4a88:	fed79be3          	bne	a5,a3,4a7e <fourfiles+0x1b6>
    4a8c:	b7e9                	j	4a56 <fourfiles+0x18e>
    close(fd);
    4a8e:	854e                	mv	a0,s3
    4a90:	00001097          	auipc	ra,0x1
    4a94:	dea080e7          	jalr	-534(ra) # 587a <close>
    if(total != N*SZ){
    4a98:	03a91963          	bne	s2,s10,4aca <fourfiles+0x202>
    unlink(fname);
    4a9c:	8562                	mv	a0,s8
    4a9e:	00001097          	auipc	ra,0x1
    4aa2:	e04080e7          	jalr	-508(ra) # 58a2 <unlink>
  for(i = 0; i < NCHILD; i++){
    4aa6:	0ba1                	addi	s7,s7,8
    4aa8:	2b05                	addiw	s6,s6,1
    4aaa:	03bb0e63          	beq	s6,s11,4ae6 <fourfiles+0x21e>
    fname = names[i];
    4aae:	000bbc03          	ld	s8,0(s7)
    fd = open(fname, 0);
    4ab2:	4581                	li	a1,0
    4ab4:	8562                	mv	a0,s8
    4ab6:	00001097          	auipc	ra,0x1
    4aba:	ddc080e7          	jalr	-548(ra) # 5892 <open>
    4abe:	89aa                	mv	s3,a0
    total = 0;
    4ac0:	f5843903          	ld	s2,-168(s0)
        if(buf[j] != '0'+i){
    4ac4:	000b049b          	sext.w	s1,s6
    while((n = read(fd, buf, sizeof(buf))) > 0){
    4ac8:	bf49                	j	4a5a <fourfiles+0x192>
      printf("wrong length %d\n", total);
    4aca:	85ca                	mv	a1,s2
    4acc:	00003517          	auipc	a0,0x3
    4ad0:	2fc50513          	addi	a0,a0,764 # 7dc8 <malloc+0x2128>
    4ad4:	00001097          	auipc	ra,0x1
    4ad8:	10e080e7          	jalr	270(ra) # 5be2 <printf>
      exit(1);
    4adc:	4505                	li	a0,1
    4ade:	00001097          	auipc	ra,0x1
    4ae2:	d74080e7          	jalr	-652(ra) # 5852 <exit>
}
    4ae6:	70aa                	ld	ra,168(sp)
    4ae8:	740a                	ld	s0,160(sp)
    4aea:	64ea                	ld	s1,152(sp)
    4aec:	694a                	ld	s2,144(sp)
    4aee:	69aa                	ld	s3,136(sp)
    4af0:	6a0a                	ld	s4,128(sp)
    4af2:	7ae6                	ld	s5,120(sp)
    4af4:	7b46                	ld	s6,112(sp)
    4af6:	7ba6                	ld	s7,104(sp)
    4af8:	7c06                	ld	s8,96(sp)
    4afa:	6ce6                	ld	s9,88(sp)
    4afc:	6d46                	ld	s10,80(sp)
    4afe:	6da6                	ld	s11,72(sp)
    4b00:	614d                	addi	sp,sp,176
    4b02:	8082                	ret

0000000000004b04 <concreate>:
{
    4b04:	7135                	addi	sp,sp,-160
    4b06:	ed06                	sd	ra,152(sp)
    4b08:	e922                	sd	s0,144(sp)
    4b0a:	e526                	sd	s1,136(sp)
    4b0c:	e14a                	sd	s2,128(sp)
    4b0e:	fcce                	sd	s3,120(sp)
    4b10:	f8d2                	sd	s4,112(sp)
    4b12:	f4d6                	sd	s5,104(sp)
    4b14:	f0da                	sd	s6,96(sp)
    4b16:	ecde                	sd	s7,88(sp)
    4b18:	1100                	addi	s0,sp,160
    4b1a:	89aa                	mv	s3,a0
  file[0] = 'C';
    4b1c:	04300793          	li	a5,67
    4b20:	faf40423          	sb	a5,-88(s0)
  file[2] = '\0';
    4b24:	fa040523          	sb	zero,-86(s0)
  for(i = 0; i < N; i++){
    4b28:	4901                	li	s2,0
    if(pid && (i % 3) == 1){
    4b2a:	4b0d                	li	s6,3
    4b2c:	4a85                	li	s5,1
      link("C0", file);
    4b2e:	00003b97          	auipc	s7,0x3
    4b32:	2b2b8b93          	addi	s7,s7,690 # 7de0 <malloc+0x2140>
  for(i = 0; i < N; i++){
    4b36:	02800a13          	li	s4,40
    4b3a:	acc1                	j	4e0a <concreate+0x306>
      link("C0", file);
    4b3c:	fa840593          	addi	a1,s0,-88
    4b40:	855e                	mv	a0,s7
    4b42:	00001097          	auipc	ra,0x1
    4b46:	d70080e7          	jalr	-656(ra) # 58b2 <link>
    if(pid == 0) {
    4b4a:	a45d                	j	4df0 <concreate+0x2ec>
    } else if(pid == 0 && (i % 5) == 1){
    4b4c:	4795                	li	a5,5
    4b4e:	02f9693b          	remw	s2,s2,a5
    4b52:	4785                	li	a5,1
    4b54:	02f90b63          	beq	s2,a5,4b8a <concreate+0x86>
      fd = open(file, O_CREATE | O_RDWR);
    4b58:	20200593          	li	a1,514
    4b5c:	fa840513          	addi	a0,s0,-88
    4b60:	00001097          	auipc	ra,0x1
    4b64:	d32080e7          	jalr	-718(ra) # 5892 <open>
      if(fd < 0){
    4b68:	26055b63          	bgez	a0,4dde <concreate+0x2da>
        printf("concreate create %s failed\n", file);
    4b6c:	fa840593          	addi	a1,s0,-88
    4b70:	00003517          	auipc	a0,0x3
    4b74:	27850513          	addi	a0,a0,632 # 7de8 <malloc+0x2148>
    4b78:	00001097          	auipc	ra,0x1
    4b7c:	06a080e7          	jalr	106(ra) # 5be2 <printf>
        exit(1);
    4b80:	4505                	li	a0,1
    4b82:	00001097          	auipc	ra,0x1
    4b86:	cd0080e7          	jalr	-816(ra) # 5852 <exit>
      link("C0", file);
    4b8a:	fa840593          	addi	a1,s0,-88
    4b8e:	00003517          	auipc	a0,0x3
    4b92:	25250513          	addi	a0,a0,594 # 7de0 <malloc+0x2140>
    4b96:	00001097          	auipc	ra,0x1
    4b9a:	d1c080e7          	jalr	-740(ra) # 58b2 <link>
      exit(0);
    4b9e:	4501                	li	a0,0
    4ba0:	00001097          	auipc	ra,0x1
    4ba4:	cb2080e7          	jalr	-846(ra) # 5852 <exit>
        exit(1);
    4ba8:	4505                	li	a0,1
    4baa:	00001097          	auipc	ra,0x1
    4bae:	ca8080e7          	jalr	-856(ra) # 5852 <exit>
  memset(fa, 0, sizeof(fa));
    4bb2:	02800613          	li	a2,40
    4bb6:	4581                	li	a1,0
    4bb8:	f8040513          	addi	a0,s0,-128
    4bbc:	00001097          	auipc	ra,0x1
    4bc0:	a92080e7          	jalr	-1390(ra) # 564e <memset>
  fd = open(".", 0);
    4bc4:	4581                	li	a1,0
    4bc6:	00002517          	auipc	a0,0x2
    4bca:	c3250513          	addi	a0,a0,-974 # 67f8 <malloc+0xb58>
    4bce:	00001097          	auipc	ra,0x1
    4bd2:	cc4080e7          	jalr	-828(ra) # 5892 <open>
    4bd6:	892a                	mv	s2,a0
  n = 0;
    4bd8:	8aa6                	mv	s5,s1
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    4bda:	04300a13          	li	s4,67
      if(i < 0 || i >= sizeof(fa)){
    4bde:	02700b13          	li	s6,39
      fa[i] = 1;
    4be2:	4b85                	li	s7,1
  while(read(fd, &de, sizeof(de)) > 0){
    4be4:	a03d                	j	4c12 <concreate+0x10e>
        printf("%s: concreate weird file %s\n", s, de.name);
    4be6:	f7240613          	addi	a2,s0,-142
    4bea:	85ce                	mv	a1,s3
    4bec:	00003517          	auipc	a0,0x3
    4bf0:	21c50513          	addi	a0,a0,540 # 7e08 <malloc+0x2168>
    4bf4:	00001097          	auipc	ra,0x1
    4bf8:	fee080e7          	jalr	-18(ra) # 5be2 <printf>
        exit(1);
    4bfc:	4505                	li	a0,1
    4bfe:	00001097          	auipc	ra,0x1
    4c02:	c54080e7          	jalr	-940(ra) # 5852 <exit>
      fa[i] = 1;
    4c06:	fb040793          	addi	a5,s0,-80
    4c0a:	973e                	add	a4,a4,a5
    4c0c:	fd770823          	sb	s7,-48(a4)
      n++;
    4c10:	2a85                	addiw	s5,s5,1
  while(read(fd, &de, sizeof(de)) > 0){
    4c12:	4641                	li	a2,16
    4c14:	f7040593          	addi	a1,s0,-144
    4c18:	854a                	mv	a0,s2
    4c1a:	00001097          	auipc	ra,0x1
    4c1e:	c50080e7          	jalr	-944(ra) # 586a <read>
    4c22:	04a05a63          	blez	a0,4c76 <concreate+0x172>
    if(de.inum == 0)
    4c26:	f7045783          	lhu	a5,-144(s0)
    4c2a:	d7e5                	beqz	a5,4c12 <concreate+0x10e>
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    4c2c:	f7244783          	lbu	a5,-142(s0)
    4c30:	ff4791e3          	bne	a5,s4,4c12 <concreate+0x10e>
    4c34:	f7444783          	lbu	a5,-140(s0)
    4c38:	ffe9                	bnez	a5,4c12 <concreate+0x10e>
      i = de.name[1] - '0';
    4c3a:	f7344783          	lbu	a5,-141(s0)
    4c3e:	fd07879b          	addiw	a5,a5,-48
    4c42:	0007871b          	sext.w	a4,a5
      if(i < 0 || i >= sizeof(fa)){
    4c46:	faeb60e3          	bltu	s6,a4,4be6 <concreate+0xe2>
      if(fa[i]){
    4c4a:	fb040793          	addi	a5,s0,-80
    4c4e:	97ba                	add	a5,a5,a4
    4c50:	fd07c783          	lbu	a5,-48(a5)
    4c54:	dbcd                	beqz	a5,4c06 <concreate+0x102>
        printf("%s: concreate duplicate file %s\n", s, de.name);
    4c56:	f7240613          	addi	a2,s0,-142
    4c5a:	85ce                	mv	a1,s3
    4c5c:	00003517          	auipc	a0,0x3
    4c60:	1cc50513          	addi	a0,a0,460 # 7e28 <malloc+0x2188>
    4c64:	00001097          	auipc	ra,0x1
    4c68:	f7e080e7          	jalr	-130(ra) # 5be2 <printf>
        exit(1);
    4c6c:	4505                	li	a0,1
    4c6e:	00001097          	auipc	ra,0x1
    4c72:	be4080e7          	jalr	-1052(ra) # 5852 <exit>
  close(fd);
    4c76:	854a                	mv	a0,s2
    4c78:	00001097          	auipc	ra,0x1
    4c7c:	c02080e7          	jalr	-1022(ra) # 587a <close>
  if(n != N){
    4c80:	02800793          	li	a5,40
    4c84:	00fa9763          	bne	s5,a5,4c92 <concreate+0x18e>
    if(((i % 3) == 0 && pid == 0) ||
    4c88:	4a8d                	li	s5,3
    4c8a:	4b05                	li	s6,1
  for(i = 0; i < N; i++){
    4c8c:	02800a13          	li	s4,40
    4c90:	a8c9                	j	4d62 <concreate+0x25e>
    printf("%s: concreate not enough files in directory listing\n", s);
    4c92:	85ce                	mv	a1,s3
    4c94:	00003517          	auipc	a0,0x3
    4c98:	1bc50513          	addi	a0,a0,444 # 7e50 <malloc+0x21b0>
    4c9c:	00001097          	auipc	ra,0x1
    4ca0:	f46080e7          	jalr	-186(ra) # 5be2 <printf>
    exit(1);
    4ca4:	4505                	li	a0,1
    4ca6:	00001097          	auipc	ra,0x1
    4caa:	bac080e7          	jalr	-1108(ra) # 5852 <exit>
      printf("%s: fork failed\n", s);
    4cae:	85ce                	mv	a1,s3
    4cb0:	00002517          	auipc	a0,0x2
    4cb4:	ce850513          	addi	a0,a0,-792 # 6998 <malloc+0xcf8>
    4cb8:	00001097          	auipc	ra,0x1
    4cbc:	f2a080e7          	jalr	-214(ra) # 5be2 <printf>
      exit(1);
    4cc0:	4505                	li	a0,1
    4cc2:	00001097          	auipc	ra,0x1
    4cc6:	b90080e7          	jalr	-1136(ra) # 5852 <exit>
      close(open(file, 0));
    4cca:	4581                	li	a1,0
    4ccc:	fa840513          	addi	a0,s0,-88
    4cd0:	00001097          	auipc	ra,0x1
    4cd4:	bc2080e7          	jalr	-1086(ra) # 5892 <open>
    4cd8:	00001097          	auipc	ra,0x1
    4cdc:	ba2080e7          	jalr	-1118(ra) # 587a <close>
      close(open(file, 0));
    4ce0:	4581                	li	a1,0
    4ce2:	fa840513          	addi	a0,s0,-88
    4ce6:	00001097          	auipc	ra,0x1
    4cea:	bac080e7          	jalr	-1108(ra) # 5892 <open>
    4cee:	00001097          	auipc	ra,0x1
    4cf2:	b8c080e7          	jalr	-1140(ra) # 587a <close>
      close(open(file, 0));
    4cf6:	4581                	li	a1,0
    4cf8:	fa840513          	addi	a0,s0,-88
    4cfc:	00001097          	auipc	ra,0x1
    4d00:	b96080e7          	jalr	-1130(ra) # 5892 <open>
    4d04:	00001097          	auipc	ra,0x1
    4d08:	b76080e7          	jalr	-1162(ra) # 587a <close>
      close(open(file, 0));
    4d0c:	4581                	li	a1,0
    4d0e:	fa840513          	addi	a0,s0,-88
    4d12:	00001097          	auipc	ra,0x1
    4d16:	b80080e7          	jalr	-1152(ra) # 5892 <open>
    4d1a:	00001097          	auipc	ra,0x1
    4d1e:	b60080e7          	jalr	-1184(ra) # 587a <close>
      close(open(file, 0));
    4d22:	4581                	li	a1,0
    4d24:	fa840513          	addi	a0,s0,-88
    4d28:	00001097          	auipc	ra,0x1
    4d2c:	b6a080e7          	jalr	-1174(ra) # 5892 <open>
    4d30:	00001097          	auipc	ra,0x1
    4d34:	b4a080e7          	jalr	-1206(ra) # 587a <close>
      close(open(file, 0));
    4d38:	4581                	li	a1,0
    4d3a:	fa840513          	addi	a0,s0,-88
    4d3e:	00001097          	auipc	ra,0x1
    4d42:	b54080e7          	jalr	-1196(ra) # 5892 <open>
    4d46:	00001097          	auipc	ra,0x1
    4d4a:	b34080e7          	jalr	-1228(ra) # 587a <close>
    if(pid == 0)
    4d4e:	08090363          	beqz	s2,4dd4 <concreate+0x2d0>
      wait(0);
    4d52:	4501                	li	a0,0
    4d54:	00001097          	auipc	ra,0x1
    4d58:	b06080e7          	jalr	-1274(ra) # 585a <wait>
  for(i = 0; i < N; i++){
    4d5c:	2485                	addiw	s1,s1,1
    4d5e:	0f448563          	beq	s1,s4,4e48 <concreate+0x344>
    file[1] = '0' + i;
    4d62:	0304879b          	addiw	a5,s1,48
    4d66:	faf404a3          	sb	a5,-87(s0)
    pid = fork();
    4d6a:	00001097          	auipc	ra,0x1
    4d6e:	ae0080e7          	jalr	-1312(ra) # 584a <fork>
    4d72:	892a                	mv	s2,a0
    if(pid < 0){
    4d74:	f2054de3          	bltz	a0,4cae <concreate+0x1aa>
    if(((i % 3) == 0 && pid == 0) ||
    4d78:	0354e73b          	remw	a4,s1,s5
    4d7c:	00a767b3          	or	a5,a4,a0
    4d80:	2781                	sext.w	a5,a5
    4d82:	d7a1                	beqz	a5,4cca <concreate+0x1c6>
    4d84:	01671363          	bne	a4,s6,4d8a <concreate+0x286>
       ((i % 3) == 1 && pid != 0)){
    4d88:	f129                	bnez	a0,4cca <concreate+0x1c6>
      unlink(file);
    4d8a:	fa840513          	addi	a0,s0,-88
    4d8e:	00001097          	auipc	ra,0x1
    4d92:	b14080e7          	jalr	-1260(ra) # 58a2 <unlink>
      unlink(file);
    4d96:	fa840513          	addi	a0,s0,-88
    4d9a:	00001097          	auipc	ra,0x1
    4d9e:	b08080e7          	jalr	-1272(ra) # 58a2 <unlink>
      unlink(file);
    4da2:	fa840513          	addi	a0,s0,-88
    4da6:	00001097          	auipc	ra,0x1
    4daa:	afc080e7          	jalr	-1284(ra) # 58a2 <unlink>
      unlink(file);
    4dae:	fa840513          	addi	a0,s0,-88
    4db2:	00001097          	auipc	ra,0x1
    4db6:	af0080e7          	jalr	-1296(ra) # 58a2 <unlink>
      unlink(file);
    4dba:	fa840513          	addi	a0,s0,-88
    4dbe:	00001097          	auipc	ra,0x1
    4dc2:	ae4080e7          	jalr	-1308(ra) # 58a2 <unlink>
      unlink(file);
    4dc6:	fa840513          	addi	a0,s0,-88
    4dca:	00001097          	auipc	ra,0x1
    4dce:	ad8080e7          	jalr	-1320(ra) # 58a2 <unlink>
    4dd2:	bfb5                	j	4d4e <concreate+0x24a>
      exit(0);
    4dd4:	4501                	li	a0,0
    4dd6:	00001097          	auipc	ra,0x1
    4dda:	a7c080e7          	jalr	-1412(ra) # 5852 <exit>
      close(fd);
    4dde:	00001097          	auipc	ra,0x1
    4de2:	a9c080e7          	jalr	-1380(ra) # 587a <close>
    if(pid == 0) {
    4de6:	bb65                	j	4b9e <concreate+0x9a>
      close(fd);
    4de8:	00001097          	auipc	ra,0x1
    4dec:	a92080e7          	jalr	-1390(ra) # 587a <close>
      wait(&xstatus);
    4df0:	f6c40513          	addi	a0,s0,-148
    4df4:	00001097          	auipc	ra,0x1
    4df8:	a66080e7          	jalr	-1434(ra) # 585a <wait>
      if(xstatus != 0)
    4dfc:	f6c42483          	lw	s1,-148(s0)
    4e00:	da0494e3          	bnez	s1,4ba8 <concreate+0xa4>
  for(i = 0; i < N; i++){
    4e04:	2905                	addiw	s2,s2,1
    4e06:	db4906e3          	beq	s2,s4,4bb2 <concreate+0xae>
    file[1] = '0' + i;
    4e0a:	0309079b          	addiw	a5,s2,48
    4e0e:	faf404a3          	sb	a5,-87(s0)
    unlink(file);
    4e12:	fa840513          	addi	a0,s0,-88
    4e16:	00001097          	auipc	ra,0x1
    4e1a:	a8c080e7          	jalr	-1396(ra) # 58a2 <unlink>
    pid = fork();
    4e1e:	00001097          	auipc	ra,0x1
    4e22:	a2c080e7          	jalr	-1492(ra) # 584a <fork>
    if(pid && (i % 3) == 1){
    4e26:	d20503e3          	beqz	a0,4b4c <concreate+0x48>
    4e2a:	036967bb          	remw	a5,s2,s6
    4e2e:	d15787e3          	beq	a5,s5,4b3c <concreate+0x38>
      fd = open(file, O_CREATE | O_RDWR);
    4e32:	20200593          	li	a1,514
    4e36:	fa840513          	addi	a0,s0,-88
    4e3a:	00001097          	auipc	ra,0x1
    4e3e:	a58080e7          	jalr	-1448(ra) # 5892 <open>
      if(fd < 0){
    4e42:	fa0553e3          	bgez	a0,4de8 <concreate+0x2e4>
    4e46:	b31d                	j	4b6c <concreate+0x68>
}
    4e48:	60ea                	ld	ra,152(sp)
    4e4a:	644a                	ld	s0,144(sp)
    4e4c:	64aa                	ld	s1,136(sp)
    4e4e:	690a                	ld	s2,128(sp)
    4e50:	79e6                	ld	s3,120(sp)
    4e52:	7a46                	ld	s4,112(sp)
    4e54:	7aa6                	ld	s5,104(sp)
    4e56:	7b06                	ld	s6,96(sp)
    4e58:	6be6                	ld	s7,88(sp)
    4e5a:	610d                	addi	sp,sp,160
    4e5c:	8082                	ret

0000000000004e5e <bigfile>:
{
    4e5e:	7139                	addi	sp,sp,-64
    4e60:	fc06                	sd	ra,56(sp)
    4e62:	f822                	sd	s0,48(sp)
    4e64:	f426                	sd	s1,40(sp)
    4e66:	f04a                	sd	s2,32(sp)
    4e68:	ec4e                	sd	s3,24(sp)
    4e6a:	e852                	sd	s4,16(sp)
    4e6c:	e456                	sd	s5,8(sp)
    4e6e:	0080                	addi	s0,sp,64
    4e70:	8aaa                	mv	s5,a0
  unlink("bigfile.dat");
    4e72:	00003517          	auipc	a0,0x3
    4e76:	01650513          	addi	a0,a0,22 # 7e88 <malloc+0x21e8>
    4e7a:	00001097          	auipc	ra,0x1
    4e7e:	a28080e7          	jalr	-1496(ra) # 58a2 <unlink>
  fd = open("bigfile.dat", O_CREATE | O_RDWR);
    4e82:	20200593          	li	a1,514
    4e86:	00003517          	auipc	a0,0x3
    4e8a:	00250513          	addi	a0,a0,2 # 7e88 <malloc+0x21e8>
    4e8e:	00001097          	auipc	ra,0x1
    4e92:	a04080e7          	jalr	-1532(ra) # 5892 <open>
    4e96:	89aa                	mv	s3,a0
  for(i = 0; i < N; i++){
    4e98:	4481                	li	s1,0
    memset(buf, i, SZ);
    4e9a:	00007917          	auipc	s2,0x7
    4e9e:	f3e90913          	addi	s2,s2,-194 # bdd8 <buf>
  for(i = 0; i < N; i++){
    4ea2:	4a51                	li	s4,20
  if(fd < 0){
    4ea4:	0a054063          	bltz	a0,4f44 <bigfile+0xe6>
    memset(buf, i, SZ);
    4ea8:	25800613          	li	a2,600
    4eac:	85a6                	mv	a1,s1
    4eae:	854a                	mv	a0,s2
    4eb0:	00000097          	auipc	ra,0x0
    4eb4:	79e080e7          	jalr	1950(ra) # 564e <memset>
    if(write(fd, buf, SZ) != SZ){
    4eb8:	25800613          	li	a2,600
    4ebc:	85ca                	mv	a1,s2
    4ebe:	854e                	mv	a0,s3
    4ec0:	00001097          	auipc	ra,0x1
    4ec4:	9b2080e7          	jalr	-1614(ra) # 5872 <write>
    4ec8:	25800793          	li	a5,600
    4ecc:	08f51a63          	bne	a0,a5,4f60 <bigfile+0x102>
  for(i = 0; i < N; i++){
    4ed0:	2485                	addiw	s1,s1,1
    4ed2:	fd449be3          	bne	s1,s4,4ea8 <bigfile+0x4a>
  close(fd);
    4ed6:	854e                	mv	a0,s3
    4ed8:	00001097          	auipc	ra,0x1
    4edc:	9a2080e7          	jalr	-1630(ra) # 587a <close>
  fd = open("bigfile.dat", 0);
    4ee0:	4581                	li	a1,0
    4ee2:	00003517          	auipc	a0,0x3
    4ee6:	fa650513          	addi	a0,a0,-90 # 7e88 <malloc+0x21e8>
    4eea:	00001097          	auipc	ra,0x1
    4eee:	9a8080e7          	jalr	-1624(ra) # 5892 <open>
    4ef2:	8a2a                	mv	s4,a0
  total = 0;
    4ef4:	4981                	li	s3,0
  for(i = 0; ; i++){
    4ef6:	4481                	li	s1,0
    cc = read(fd, buf, SZ/2);
    4ef8:	00007917          	auipc	s2,0x7
    4efc:	ee090913          	addi	s2,s2,-288 # bdd8 <buf>
  if(fd < 0){
    4f00:	06054e63          	bltz	a0,4f7c <bigfile+0x11e>
    cc = read(fd, buf, SZ/2);
    4f04:	12c00613          	li	a2,300
    4f08:	85ca                	mv	a1,s2
    4f0a:	8552                	mv	a0,s4
    4f0c:	00001097          	auipc	ra,0x1
    4f10:	95e080e7          	jalr	-1698(ra) # 586a <read>
    if(cc < 0){
    4f14:	08054263          	bltz	a0,4f98 <bigfile+0x13a>
    if(cc == 0)
    4f18:	c971                	beqz	a0,4fec <bigfile+0x18e>
    if(cc != SZ/2){
    4f1a:	12c00793          	li	a5,300
    4f1e:	08f51b63          	bne	a0,a5,4fb4 <bigfile+0x156>
    if(buf[0] != i/2 || buf[SZ/2-1] != i/2){
    4f22:	01f4d79b          	srliw	a5,s1,0x1f
    4f26:	9fa5                	addw	a5,a5,s1
    4f28:	4017d79b          	sraiw	a5,a5,0x1
    4f2c:	00094703          	lbu	a4,0(s2)
    4f30:	0af71063          	bne	a4,a5,4fd0 <bigfile+0x172>
    4f34:	12b94703          	lbu	a4,299(s2)
    4f38:	08f71c63          	bne	a4,a5,4fd0 <bigfile+0x172>
    total += cc;
    4f3c:	12c9899b          	addiw	s3,s3,300
  for(i = 0; ; i++){
    4f40:	2485                	addiw	s1,s1,1
    cc = read(fd, buf, SZ/2);
    4f42:	b7c9                	j	4f04 <bigfile+0xa6>
    printf("%s: cannot create bigfile", s);
    4f44:	85d6                	mv	a1,s5
    4f46:	00003517          	auipc	a0,0x3
    4f4a:	f5250513          	addi	a0,a0,-174 # 7e98 <malloc+0x21f8>
    4f4e:	00001097          	auipc	ra,0x1
    4f52:	c94080e7          	jalr	-876(ra) # 5be2 <printf>
    exit(1);
    4f56:	4505                	li	a0,1
    4f58:	00001097          	auipc	ra,0x1
    4f5c:	8fa080e7          	jalr	-1798(ra) # 5852 <exit>
      printf("%s: write bigfile failed\n", s);
    4f60:	85d6                	mv	a1,s5
    4f62:	00003517          	auipc	a0,0x3
    4f66:	f5650513          	addi	a0,a0,-170 # 7eb8 <malloc+0x2218>
    4f6a:	00001097          	auipc	ra,0x1
    4f6e:	c78080e7          	jalr	-904(ra) # 5be2 <printf>
      exit(1);
    4f72:	4505                	li	a0,1
    4f74:	00001097          	auipc	ra,0x1
    4f78:	8de080e7          	jalr	-1826(ra) # 5852 <exit>
    printf("%s: cannot open bigfile\n", s);
    4f7c:	85d6                	mv	a1,s5
    4f7e:	00003517          	auipc	a0,0x3
    4f82:	f5a50513          	addi	a0,a0,-166 # 7ed8 <malloc+0x2238>
    4f86:	00001097          	auipc	ra,0x1
    4f8a:	c5c080e7          	jalr	-932(ra) # 5be2 <printf>
    exit(1);
    4f8e:	4505                	li	a0,1
    4f90:	00001097          	auipc	ra,0x1
    4f94:	8c2080e7          	jalr	-1854(ra) # 5852 <exit>
      printf("%s: read bigfile failed\n", s);
    4f98:	85d6                	mv	a1,s5
    4f9a:	00003517          	auipc	a0,0x3
    4f9e:	f5e50513          	addi	a0,a0,-162 # 7ef8 <malloc+0x2258>
    4fa2:	00001097          	auipc	ra,0x1
    4fa6:	c40080e7          	jalr	-960(ra) # 5be2 <printf>
      exit(1);
    4faa:	4505                	li	a0,1
    4fac:	00001097          	auipc	ra,0x1
    4fb0:	8a6080e7          	jalr	-1882(ra) # 5852 <exit>
      printf("%s: short read bigfile\n", s);
    4fb4:	85d6                	mv	a1,s5
    4fb6:	00003517          	auipc	a0,0x3
    4fba:	f6250513          	addi	a0,a0,-158 # 7f18 <malloc+0x2278>
    4fbe:	00001097          	auipc	ra,0x1
    4fc2:	c24080e7          	jalr	-988(ra) # 5be2 <printf>
      exit(1);
    4fc6:	4505                	li	a0,1
    4fc8:	00001097          	auipc	ra,0x1
    4fcc:	88a080e7          	jalr	-1910(ra) # 5852 <exit>
      printf("%s: read bigfile wrong data\n", s);
    4fd0:	85d6                	mv	a1,s5
    4fd2:	00003517          	auipc	a0,0x3
    4fd6:	f5e50513          	addi	a0,a0,-162 # 7f30 <malloc+0x2290>
    4fda:	00001097          	auipc	ra,0x1
    4fde:	c08080e7          	jalr	-1016(ra) # 5be2 <printf>
      exit(1);
    4fe2:	4505                	li	a0,1
    4fe4:	00001097          	auipc	ra,0x1
    4fe8:	86e080e7          	jalr	-1938(ra) # 5852 <exit>
  close(fd);
    4fec:	8552                	mv	a0,s4
    4fee:	00001097          	auipc	ra,0x1
    4ff2:	88c080e7          	jalr	-1908(ra) # 587a <close>
  if(total != N*SZ){
    4ff6:	678d                	lui	a5,0x3
    4ff8:	ee078793          	addi	a5,a5,-288 # 2ee0 <execout+0xbc>
    4ffc:	02f99363          	bne	s3,a5,5022 <bigfile+0x1c4>
  unlink("bigfile.dat");
    5000:	00003517          	auipc	a0,0x3
    5004:	e8850513          	addi	a0,a0,-376 # 7e88 <malloc+0x21e8>
    5008:	00001097          	auipc	ra,0x1
    500c:	89a080e7          	jalr	-1894(ra) # 58a2 <unlink>
}
    5010:	70e2                	ld	ra,56(sp)
    5012:	7442                	ld	s0,48(sp)
    5014:	74a2                	ld	s1,40(sp)
    5016:	7902                	ld	s2,32(sp)
    5018:	69e2                	ld	s3,24(sp)
    501a:	6a42                	ld	s4,16(sp)
    501c:	6aa2                	ld	s5,8(sp)
    501e:	6121                	addi	sp,sp,64
    5020:	8082                	ret
    printf("%s: read bigfile wrong total\n", s);
    5022:	85d6                	mv	a1,s5
    5024:	00003517          	auipc	a0,0x3
    5028:	f2c50513          	addi	a0,a0,-212 # 7f50 <malloc+0x22b0>
    502c:	00001097          	auipc	ra,0x1
    5030:	bb6080e7          	jalr	-1098(ra) # 5be2 <printf>
    exit(1);
    5034:	4505                	li	a0,1
    5036:	00001097          	auipc	ra,0x1
    503a:	81c080e7          	jalr	-2020(ra) # 5852 <exit>

000000000000503e <fsfull>:
{
    503e:	7171                	addi	sp,sp,-176
    5040:	f506                	sd	ra,168(sp)
    5042:	f122                	sd	s0,160(sp)
    5044:	ed26                	sd	s1,152(sp)
    5046:	e94a                	sd	s2,144(sp)
    5048:	e54e                	sd	s3,136(sp)
    504a:	e152                	sd	s4,128(sp)
    504c:	fcd6                	sd	s5,120(sp)
    504e:	f8da                	sd	s6,112(sp)
    5050:	f4de                	sd	s7,104(sp)
    5052:	f0e2                	sd	s8,96(sp)
    5054:	ece6                	sd	s9,88(sp)
    5056:	e8ea                	sd	s10,80(sp)
    5058:	e4ee                	sd	s11,72(sp)
    505a:	1900                	addi	s0,sp,176
  printf("fsfull test\n");
    505c:	00003517          	auipc	a0,0x3
    5060:	f1450513          	addi	a0,a0,-236 # 7f70 <malloc+0x22d0>
    5064:	00001097          	auipc	ra,0x1
    5068:	b7e080e7          	jalr	-1154(ra) # 5be2 <printf>
  for(nfiles = 0; ; nfiles++){
    506c:	4481                	li	s1,0
    name[0] = 'f';
    506e:	06600d13          	li	s10,102
    name[1] = '0' + nfiles / 1000;
    5072:	3e800c13          	li	s8,1000
    name[2] = '0' + (nfiles % 1000) / 100;
    5076:	06400b93          	li	s7,100
    name[3] = '0' + (nfiles % 100) / 10;
    507a:	4b29                	li	s6,10
    printf("writing %s\n", name);
    507c:	00003c97          	auipc	s9,0x3
    5080:	f04c8c93          	addi	s9,s9,-252 # 7f80 <malloc+0x22e0>
    int total = 0;
    5084:	4d81                	li	s11,0
      int cc = write(fd, buf, BSIZE);
    5086:	00007a17          	auipc	s4,0x7
    508a:	d52a0a13          	addi	s4,s4,-686 # bdd8 <buf>
    name[0] = 'f';
    508e:	f5a40823          	sb	s10,-176(s0)
    name[1] = '0' + nfiles / 1000;
    5092:	0384c7bb          	divw	a5,s1,s8
    5096:	0307879b          	addiw	a5,a5,48
    509a:	f4f408a3          	sb	a5,-175(s0)
    name[2] = '0' + (nfiles % 1000) / 100;
    509e:	0384e7bb          	remw	a5,s1,s8
    50a2:	0377c7bb          	divw	a5,a5,s7
    50a6:	0307879b          	addiw	a5,a5,48
    50aa:	f4f40923          	sb	a5,-174(s0)
    name[3] = '0' + (nfiles % 100) / 10;
    50ae:	0374e7bb          	remw	a5,s1,s7
    50b2:	0367c7bb          	divw	a5,a5,s6
    50b6:	0307879b          	addiw	a5,a5,48
    50ba:	f4f409a3          	sb	a5,-173(s0)
    name[4] = '0' + (nfiles % 10);
    50be:	0364e7bb          	remw	a5,s1,s6
    50c2:	0307879b          	addiw	a5,a5,48
    50c6:	f4f40a23          	sb	a5,-172(s0)
    name[5] = '\0';
    50ca:	f4040aa3          	sb	zero,-171(s0)
    printf("writing %s\n", name);
    50ce:	f5040593          	addi	a1,s0,-176
    50d2:	8566                	mv	a0,s9
    50d4:	00001097          	auipc	ra,0x1
    50d8:	b0e080e7          	jalr	-1266(ra) # 5be2 <printf>
    int fd = open(name, O_CREATE|O_RDWR);
    50dc:	20200593          	li	a1,514
    50e0:	f5040513          	addi	a0,s0,-176
    50e4:	00000097          	auipc	ra,0x0
    50e8:	7ae080e7          	jalr	1966(ra) # 5892 <open>
    50ec:	892a                	mv	s2,a0
    if(fd < 0){
    50ee:	0a055663          	bgez	a0,519a <fsfull+0x15c>
      printf("open %s failed\n", name);
    50f2:	f5040593          	addi	a1,s0,-176
    50f6:	00003517          	auipc	a0,0x3
    50fa:	e9a50513          	addi	a0,a0,-358 # 7f90 <malloc+0x22f0>
    50fe:	00001097          	auipc	ra,0x1
    5102:	ae4080e7          	jalr	-1308(ra) # 5be2 <printf>
  while(nfiles >= 0){
    5106:	0604c363          	bltz	s1,516c <fsfull+0x12e>
    name[0] = 'f';
    510a:	06600b13          	li	s6,102
    name[1] = '0' + nfiles / 1000;
    510e:	3e800a13          	li	s4,1000
    name[2] = '0' + (nfiles % 1000) / 100;
    5112:	06400993          	li	s3,100
    name[3] = '0' + (nfiles % 100) / 10;
    5116:	4929                	li	s2,10
  while(nfiles >= 0){
    5118:	5afd                	li	s5,-1
    name[0] = 'f';
    511a:	f5640823          	sb	s6,-176(s0)
    name[1] = '0' + nfiles / 1000;
    511e:	0344c7bb          	divw	a5,s1,s4
    5122:	0307879b          	addiw	a5,a5,48
    5126:	f4f408a3          	sb	a5,-175(s0)
    name[2] = '0' + (nfiles % 1000) / 100;
    512a:	0344e7bb          	remw	a5,s1,s4
    512e:	0337c7bb          	divw	a5,a5,s3
    5132:	0307879b          	addiw	a5,a5,48
    5136:	f4f40923          	sb	a5,-174(s0)
    name[3] = '0' + (nfiles % 100) / 10;
    513a:	0334e7bb          	remw	a5,s1,s3
    513e:	0327c7bb          	divw	a5,a5,s2
    5142:	0307879b          	addiw	a5,a5,48
    5146:	f4f409a3          	sb	a5,-173(s0)
    name[4] = '0' + (nfiles % 10);
    514a:	0324e7bb          	remw	a5,s1,s2
    514e:	0307879b          	addiw	a5,a5,48
    5152:	f4f40a23          	sb	a5,-172(s0)
    name[5] = '\0';
    5156:	f4040aa3          	sb	zero,-171(s0)
    unlink(name);
    515a:	f5040513          	addi	a0,s0,-176
    515e:	00000097          	auipc	ra,0x0
    5162:	744080e7          	jalr	1860(ra) # 58a2 <unlink>
    nfiles--;
    5166:	34fd                	addiw	s1,s1,-1
  while(nfiles >= 0){
    5168:	fb5499e3          	bne	s1,s5,511a <fsfull+0xdc>
  printf("fsfull test finished\n");
    516c:	00003517          	auipc	a0,0x3
    5170:	e4450513          	addi	a0,a0,-444 # 7fb0 <malloc+0x2310>
    5174:	00001097          	auipc	ra,0x1
    5178:	a6e080e7          	jalr	-1426(ra) # 5be2 <printf>
}
    517c:	70aa                	ld	ra,168(sp)
    517e:	740a                	ld	s0,160(sp)
    5180:	64ea                	ld	s1,152(sp)
    5182:	694a                	ld	s2,144(sp)
    5184:	69aa                	ld	s3,136(sp)
    5186:	6a0a                	ld	s4,128(sp)
    5188:	7ae6                	ld	s5,120(sp)
    518a:	7b46                	ld	s6,112(sp)
    518c:	7ba6                	ld	s7,104(sp)
    518e:	7c06                	ld	s8,96(sp)
    5190:	6ce6                	ld	s9,88(sp)
    5192:	6d46                	ld	s10,80(sp)
    5194:	6da6                	ld	s11,72(sp)
    5196:	614d                	addi	sp,sp,176
    5198:	8082                	ret
    int total = 0;
    519a:	89ee                	mv	s3,s11
      if(cc < BSIZE)
    519c:	3ff00a93          	li	s5,1023
      int cc = write(fd, buf, BSIZE);
    51a0:	40000613          	li	a2,1024
    51a4:	85d2                	mv	a1,s4
    51a6:	854a                	mv	a0,s2
    51a8:	00000097          	auipc	ra,0x0
    51ac:	6ca080e7          	jalr	1738(ra) # 5872 <write>
      if(cc < BSIZE)
    51b0:	00aad563          	bge	s5,a0,51ba <fsfull+0x17c>
      total += cc;
    51b4:	00a989bb          	addw	s3,s3,a0
    while(1){
    51b8:	b7e5                	j	51a0 <fsfull+0x162>
    printf("wrote %d bytes\n", total);
    51ba:	85ce                	mv	a1,s3
    51bc:	00003517          	auipc	a0,0x3
    51c0:	de450513          	addi	a0,a0,-540 # 7fa0 <malloc+0x2300>
    51c4:	00001097          	auipc	ra,0x1
    51c8:	a1e080e7          	jalr	-1506(ra) # 5be2 <printf>
    close(fd);
    51cc:	854a                	mv	a0,s2
    51ce:	00000097          	auipc	ra,0x0
    51d2:	6ac080e7          	jalr	1708(ra) # 587a <close>
    if(total == 0)
    51d6:	f20988e3          	beqz	s3,5106 <fsfull+0xc8>
  for(nfiles = 0; ; nfiles++){
    51da:	2485                	addiw	s1,s1,1
    51dc:	bd4d                	j	508e <fsfull+0x50>

00000000000051de <countfree>:
// because out of memory with lazy allocation results in the process
// taking a fault and being killed, fork and report back.
//
int
countfree()
{
    51de:	7139                	addi	sp,sp,-64
    51e0:	fc06                	sd	ra,56(sp)
    51e2:	f822                	sd	s0,48(sp)
    51e4:	f426                	sd	s1,40(sp)
    51e6:	f04a                	sd	s2,32(sp)
    51e8:	ec4e                	sd	s3,24(sp)
    51ea:	0080                	addi	s0,sp,64
  int fds[2];

  if(pipe(fds) < 0){
    51ec:	fc840513          	addi	a0,s0,-56
    51f0:	00000097          	auipc	ra,0x0
    51f4:	672080e7          	jalr	1650(ra) # 5862 <pipe>
    51f8:	06054863          	bltz	a0,5268 <countfree+0x8a>
    printf("pipe() failed in countfree()\n");
    exit(1);
  }
  
  int pid = fork();
    51fc:	00000097          	auipc	ra,0x0
    5200:	64e080e7          	jalr	1614(ra) # 584a <fork>

  if(pid < 0){
    5204:	06054f63          	bltz	a0,5282 <countfree+0xa4>
    printf("fork failed in countfree()\n");
    exit(1);
  }

  if(pid == 0){
    5208:	ed59                	bnez	a0,52a6 <countfree+0xc8>
    close(fds[0]);
    520a:	fc842503          	lw	a0,-56(s0)
    520e:	00000097          	auipc	ra,0x0
    5212:	66c080e7          	jalr	1644(ra) # 587a <close>
    
    while(1){
      uint64 a = (uint64) sbrk(4096);
      if(a == 0xffffffffffffffff){
    5216:	54fd                	li	s1,-1
        break;
      }

      // modify the memory to make sure it's really allocated.
      *(char *)(a + 4096 - 1) = 1;
    5218:	4985                	li	s3,1

      // report back one more page.
      if(write(fds[1], "x", 1) != 1){
    521a:	00001917          	auipc	s2,0x1
    521e:	f8690913          	addi	s2,s2,-122 # 61a0 <malloc+0x500>
      uint64 a = (uint64) sbrk(4096);
    5222:	6505                	lui	a0,0x1
    5224:	00000097          	auipc	ra,0x0
    5228:	6b6080e7          	jalr	1718(ra) # 58da <sbrk>
      if(a == 0xffffffffffffffff){
    522c:	06950863          	beq	a0,s1,529c <countfree+0xbe>
      *(char *)(a + 4096 - 1) = 1;
    5230:	6785                	lui	a5,0x1
    5232:	953e                	add	a0,a0,a5
    5234:	ff350fa3          	sb	s3,-1(a0) # fff <linktest+0x1d9>
      if(write(fds[1], "x", 1) != 1){
    5238:	4605                	li	a2,1
    523a:	85ca                	mv	a1,s2
    523c:	fcc42503          	lw	a0,-52(s0)
    5240:	00000097          	auipc	ra,0x0
    5244:	632080e7          	jalr	1586(ra) # 5872 <write>
    5248:	4785                	li	a5,1
    524a:	fcf50ce3          	beq	a0,a5,5222 <countfree+0x44>
        printf("write() failed in countfree()\n");
    524e:	00003517          	auipc	a0,0x3
    5252:	dba50513          	addi	a0,a0,-582 # 8008 <malloc+0x2368>
    5256:	00001097          	auipc	ra,0x1
    525a:	98c080e7          	jalr	-1652(ra) # 5be2 <printf>
        exit(1);
    525e:	4505                	li	a0,1
    5260:	00000097          	auipc	ra,0x0
    5264:	5f2080e7          	jalr	1522(ra) # 5852 <exit>
    printf("pipe() failed in countfree()\n");
    5268:	00003517          	auipc	a0,0x3
    526c:	d6050513          	addi	a0,a0,-672 # 7fc8 <malloc+0x2328>
    5270:	00001097          	auipc	ra,0x1
    5274:	972080e7          	jalr	-1678(ra) # 5be2 <printf>
    exit(1);
    5278:	4505                	li	a0,1
    527a:	00000097          	auipc	ra,0x0
    527e:	5d8080e7          	jalr	1496(ra) # 5852 <exit>
    printf("fork failed in countfree()\n");
    5282:	00003517          	auipc	a0,0x3
    5286:	d6650513          	addi	a0,a0,-666 # 7fe8 <malloc+0x2348>
    528a:	00001097          	auipc	ra,0x1
    528e:	958080e7          	jalr	-1704(ra) # 5be2 <printf>
    exit(1);
    5292:	4505                	li	a0,1
    5294:	00000097          	auipc	ra,0x0
    5298:	5be080e7          	jalr	1470(ra) # 5852 <exit>
      }
    }

    exit(0);
    529c:	4501                	li	a0,0
    529e:	00000097          	auipc	ra,0x0
    52a2:	5b4080e7          	jalr	1460(ra) # 5852 <exit>
  }

  close(fds[1]);
    52a6:	fcc42503          	lw	a0,-52(s0)
    52aa:	00000097          	auipc	ra,0x0
    52ae:	5d0080e7          	jalr	1488(ra) # 587a <close>

  int n = 0;
    52b2:	4481                	li	s1,0
  while(1){
    char c;
    int cc = read(fds[0], &c, 1);
    52b4:	4605                	li	a2,1
    52b6:	fc740593          	addi	a1,s0,-57
    52ba:	fc842503          	lw	a0,-56(s0)
    52be:	00000097          	auipc	ra,0x0
    52c2:	5ac080e7          	jalr	1452(ra) # 586a <read>
    if(cc < 0){
    52c6:	00054563          	bltz	a0,52d0 <countfree+0xf2>
      printf("read() failed in countfree()\n");
      exit(1);
    }
    if(cc == 0)
    52ca:	c105                	beqz	a0,52ea <countfree+0x10c>
      break;
    n += 1;
    52cc:	2485                	addiw	s1,s1,1
  while(1){
    52ce:	b7dd                	j	52b4 <countfree+0xd6>
      printf("read() failed in countfree()\n");
    52d0:	00003517          	auipc	a0,0x3
    52d4:	d5850513          	addi	a0,a0,-680 # 8028 <malloc+0x2388>
    52d8:	00001097          	auipc	ra,0x1
    52dc:	90a080e7          	jalr	-1782(ra) # 5be2 <printf>
      exit(1);
    52e0:	4505                	li	a0,1
    52e2:	00000097          	auipc	ra,0x0
    52e6:	570080e7          	jalr	1392(ra) # 5852 <exit>
  }

  close(fds[0]);
    52ea:	fc842503          	lw	a0,-56(s0)
    52ee:	00000097          	auipc	ra,0x0
    52f2:	58c080e7          	jalr	1420(ra) # 587a <close>
  wait((int*)0);
    52f6:	4501                	li	a0,0
    52f8:	00000097          	auipc	ra,0x0
    52fc:	562080e7          	jalr	1378(ra) # 585a <wait>
  
  return n;
}
    5300:	8526                	mv	a0,s1
    5302:	70e2                	ld	ra,56(sp)
    5304:	7442                	ld	s0,48(sp)
    5306:	74a2                	ld	s1,40(sp)
    5308:	7902                	ld	s2,32(sp)
    530a:	69e2                	ld	s3,24(sp)
    530c:	6121                	addi	sp,sp,64
    530e:	8082                	ret

0000000000005310 <run>:

// run each test in its own process. run returns 1 if child's exit()
// indicates success.
int
run(void f(char *), char *s) {
    5310:	7179                	addi	sp,sp,-48
    5312:	f406                	sd	ra,40(sp)
    5314:	f022                	sd	s0,32(sp)
    5316:	ec26                	sd	s1,24(sp)
    5318:	e84a                	sd	s2,16(sp)
    531a:	1800                	addi	s0,sp,48
    531c:	84aa                	mv	s1,a0
    531e:	892e                	mv	s2,a1
  int pid;
  int xstatus;

  printf("test %s: ", s);
    5320:	00003517          	auipc	a0,0x3
    5324:	d2850513          	addi	a0,a0,-728 # 8048 <malloc+0x23a8>
    5328:	00001097          	auipc	ra,0x1
    532c:	8ba080e7          	jalr	-1862(ra) # 5be2 <printf>
  if((pid = fork()) < 0) {
    5330:	00000097          	auipc	ra,0x0
    5334:	51a080e7          	jalr	1306(ra) # 584a <fork>
    5338:	02054e63          	bltz	a0,5374 <run+0x64>
    printf("runtest: fork error\n");
    exit(1);
  }
  if(pid == 0) {
    533c:	c929                	beqz	a0,538e <run+0x7e>
    f(s);
    exit(0);
  } else {
    wait(&xstatus);
    533e:	fdc40513          	addi	a0,s0,-36
    5342:	00000097          	auipc	ra,0x0
    5346:	518080e7          	jalr	1304(ra) # 585a <wait>
    if(xstatus != 0) 
    534a:	fdc42783          	lw	a5,-36(s0)
    534e:	c7b9                	beqz	a5,539c <run+0x8c>
      printf("FAILED\n");
    5350:	00003517          	auipc	a0,0x3
    5354:	d2050513          	addi	a0,a0,-736 # 8070 <malloc+0x23d0>
    5358:	00001097          	auipc	ra,0x1
    535c:	88a080e7          	jalr	-1910(ra) # 5be2 <printf>
    else
      printf("OK\n");
    return xstatus == 0;
    5360:	fdc42503          	lw	a0,-36(s0)
  }
}
    5364:	00153513          	seqz	a0,a0
    5368:	70a2                	ld	ra,40(sp)
    536a:	7402                	ld	s0,32(sp)
    536c:	64e2                	ld	s1,24(sp)
    536e:	6942                	ld	s2,16(sp)
    5370:	6145                	addi	sp,sp,48
    5372:	8082                	ret
    printf("runtest: fork error\n");
    5374:	00003517          	auipc	a0,0x3
    5378:	ce450513          	addi	a0,a0,-796 # 8058 <malloc+0x23b8>
    537c:	00001097          	auipc	ra,0x1
    5380:	866080e7          	jalr	-1946(ra) # 5be2 <printf>
    exit(1);
    5384:	4505                	li	a0,1
    5386:	00000097          	auipc	ra,0x0
    538a:	4cc080e7          	jalr	1228(ra) # 5852 <exit>
    f(s);
    538e:	854a                	mv	a0,s2
    5390:	9482                	jalr	s1
    exit(0);
    5392:	4501                	li	a0,0
    5394:	00000097          	auipc	ra,0x0
    5398:	4be080e7          	jalr	1214(ra) # 5852 <exit>
      printf("OK\n");
    539c:	00003517          	auipc	a0,0x3
    53a0:	cdc50513          	addi	a0,a0,-804 # 8078 <malloc+0x23d8>
    53a4:	00001097          	auipc	ra,0x1
    53a8:	83e080e7          	jalr	-1986(ra) # 5be2 <printf>
    53ac:	bf55                	j	5360 <run+0x50>

00000000000053ae <main>:

int
main(int argc, char *argv[])
{
    53ae:	bc010113          	addi	sp,sp,-1088
    53b2:	42113c23          	sd	ra,1080(sp)
    53b6:	42813823          	sd	s0,1072(sp)
    53ba:	42913423          	sd	s1,1064(sp)
    53be:	43213023          	sd	s2,1056(sp)
    53c2:	41313c23          	sd	s3,1048(sp)
    53c6:	41413823          	sd	s4,1040(sp)
    53ca:	41513423          	sd	s5,1032(sp)
    53ce:	41613023          	sd	s6,1024(sp)
    53d2:	44010413          	addi	s0,sp,1088
    53d6:	89aa                	mv	s3,a0
  int continuous = 0;
  char *justone = 0;

  if(argc == 2 && strcmp(argv[1], "-c") == 0){
    53d8:	4789                	li	a5,2
    53da:	08f50763          	beq	a0,a5,5468 <main+0xba>
    continuous = 1;
  } else if(argc == 2 && strcmp(argv[1], "-C") == 0){
    continuous = 2;
  } else if(argc == 2 && argv[1][0] != '-'){
    justone = argv[1];
  } else if(argc > 1){
    53de:	4785                	li	a5,1
  char *justone = 0;
    53e0:	4901                	li	s2,0
  } else if(argc > 1){
    53e2:	0ca7c163          	blt	a5,a0,54a4 <main+0xf6>
  }
  
  struct test {
    void (*f)(char *);
    char *s;
  } tests[] = {
    53e6:	00003797          	auipc	a5,0x3
    53ea:	daa78793          	addi	a5,a5,-598 # 8190 <malloc+0x24f0>
    53ee:	bc040713          	addi	a4,s0,-1088
    53f2:	00003817          	auipc	a6,0x3
    53f6:	19e80813          	addi	a6,a6,414 # 8590 <malloc+0x28f0>
    53fa:	6388                	ld	a0,0(a5)
    53fc:	678c                	ld	a1,8(a5)
    53fe:	6b90                	ld	a2,16(a5)
    5400:	6f94                	ld	a3,24(a5)
    5402:	e308                	sd	a0,0(a4)
    5404:	e70c                	sd	a1,8(a4)
    5406:	eb10                	sd	a2,16(a4)
    5408:	ef14                	sd	a3,24(a4)
    540a:	02078793          	addi	a5,a5,32
    540e:	02070713          	addi	a4,a4,32
    5412:	ff0794e3          	bne	a5,a6,53fa <main+0x4c>
          exit(1);
      }
    }
  }

  printf("usertests starting\n");
    5416:	00003517          	auipc	a0,0x3
    541a:	d1a50513          	addi	a0,a0,-742 # 8130 <malloc+0x2490>
    541e:	00000097          	auipc	ra,0x0
    5422:	7c4080e7          	jalr	1988(ra) # 5be2 <printf>
  int free0 = countfree();
    5426:	00000097          	auipc	ra,0x0
    542a:	db8080e7          	jalr	-584(ra) # 51de <countfree>
    542e:	8a2a                	mv	s4,a0
  int free1 = 0;
  int fail = 0;
  for (struct test *t = tests; t->s != 0; t++) {
    5430:	bc843503          	ld	a0,-1080(s0)
    5434:	bc040493          	addi	s1,s0,-1088
  int fail = 0;
    5438:	4981                	li	s3,0
    if((justone == 0) || strcmp(t->s, justone) == 0) {
      if(!run(t->f, t->s))
        fail = 1;
    543a:	4a85                	li	s5,1
  for (struct test *t = tests; t->s != 0; t++) {
    543c:	e55d                	bnez	a0,54ea <main+0x13c>
  }

  if(fail){
    printf("SOME TESTS FAILED\n");
    exit(1);
  } else if((free1 = countfree()) < free0){
    543e:	00000097          	auipc	ra,0x0
    5442:	da0080e7          	jalr	-608(ra) # 51de <countfree>
    5446:	85aa                	mv	a1,a0
    5448:	0f455163          	bge	a0,s4,552a <main+0x17c>
    printf("FAILED -- lost some free pages %d (out of %d)\n", free1, free0);
    544c:	8652                	mv	a2,s4
    544e:	00003517          	auipc	a0,0x3
    5452:	c9a50513          	addi	a0,a0,-870 # 80e8 <malloc+0x2448>
    5456:	00000097          	auipc	ra,0x0
    545a:	78c080e7          	jalr	1932(ra) # 5be2 <printf>
    exit(1);
    545e:	4505                	li	a0,1
    5460:	00000097          	auipc	ra,0x0
    5464:	3f2080e7          	jalr	1010(ra) # 5852 <exit>
    5468:	84ae                	mv	s1,a1
  if(argc == 2 && strcmp(argv[1], "-c") == 0){
    546a:	00003597          	auipc	a1,0x3
    546e:	c1658593          	addi	a1,a1,-1002 # 8080 <malloc+0x23e0>
    5472:	6488                	ld	a0,8(s1)
    5474:	00000097          	auipc	ra,0x0
    5478:	184080e7          	jalr	388(ra) # 55f8 <strcmp>
    547c:	10050563          	beqz	a0,5586 <main+0x1d8>
  } else if(argc == 2 && strcmp(argv[1], "-C") == 0){
    5480:	00003597          	auipc	a1,0x3
    5484:	ce858593          	addi	a1,a1,-792 # 8168 <malloc+0x24c8>
    5488:	6488                	ld	a0,8(s1)
    548a:	00000097          	auipc	ra,0x0
    548e:	16e080e7          	jalr	366(ra) # 55f8 <strcmp>
    5492:	c97d                	beqz	a0,5588 <main+0x1da>
  } else if(argc == 2 && argv[1][0] != '-'){
    5494:	0084b903          	ld	s2,8(s1)
    5498:	00094703          	lbu	a4,0(s2)
    549c:	02d00793          	li	a5,45
    54a0:	f4f713e3          	bne	a4,a5,53e6 <main+0x38>
    printf("Usage: usertests [-c] [testname]\n");
    54a4:	00003517          	auipc	a0,0x3
    54a8:	be450513          	addi	a0,a0,-1052 # 8088 <malloc+0x23e8>
    54ac:	00000097          	auipc	ra,0x0
    54b0:	736080e7          	jalr	1846(ra) # 5be2 <printf>
    exit(1);
    54b4:	4505                	li	a0,1
    54b6:	00000097          	auipc	ra,0x0
    54ba:	39c080e7          	jalr	924(ra) # 5852 <exit>
          exit(1);
    54be:	4505                	li	a0,1
    54c0:	00000097          	auipc	ra,0x0
    54c4:	392080e7          	jalr	914(ra) # 5852 <exit>
        printf("FAILED -- lost %d free pages\n", free0 - free1);
    54c8:	40a905bb          	subw	a1,s2,a0
    54cc:	855a                	mv	a0,s6
    54ce:	00000097          	auipc	ra,0x0
    54d2:	714080e7          	jalr	1812(ra) # 5be2 <printf>
        if(continuous != 2)
    54d6:	09498463          	beq	s3,s4,555e <main+0x1b0>
          exit(1);
    54da:	4505                	li	a0,1
    54dc:	00000097          	auipc	ra,0x0
    54e0:	376080e7          	jalr	886(ra) # 5852 <exit>
  for (struct test *t = tests; t->s != 0; t++) {
    54e4:	04c1                	addi	s1,s1,16
    54e6:	6488                	ld	a0,8(s1)
    54e8:	c115                	beqz	a0,550c <main+0x15e>
    if((justone == 0) || strcmp(t->s, justone) == 0) {
    54ea:	00090863          	beqz	s2,54fa <main+0x14c>
    54ee:	85ca                	mv	a1,s2
    54f0:	00000097          	auipc	ra,0x0
    54f4:	108080e7          	jalr	264(ra) # 55f8 <strcmp>
    54f8:	f575                	bnez	a0,54e4 <main+0x136>
      if(!run(t->f, t->s))
    54fa:	648c                	ld	a1,8(s1)
    54fc:	6088                	ld	a0,0(s1)
    54fe:	00000097          	auipc	ra,0x0
    5502:	e12080e7          	jalr	-494(ra) # 5310 <run>
    5506:	fd79                	bnez	a0,54e4 <main+0x136>
        fail = 1;
    5508:	89d6                	mv	s3,s5
    550a:	bfe9                	j	54e4 <main+0x136>
  if(fail){
    550c:	f20989e3          	beqz	s3,543e <main+0x90>
    printf("SOME TESTS FAILED\n");
    5510:	00003517          	auipc	a0,0x3
    5514:	bc050513          	addi	a0,a0,-1088 # 80d0 <malloc+0x2430>
    5518:	00000097          	auipc	ra,0x0
    551c:	6ca080e7          	jalr	1738(ra) # 5be2 <printf>
    exit(1);
    5520:	4505                	li	a0,1
    5522:	00000097          	auipc	ra,0x0
    5526:	330080e7          	jalr	816(ra) # 5852 <exit>
  } else {
    printf("ALL TESTS PASSED\n");
    552a:	00003517          	auipc	a0,0x3
    552e:	bee50513          	addi	a0,a0,-1042 # 8118 <malloc+0x2478>
    5532:	00000097          	auipc	ra,0x0
    5536:	6b0080e7          	jalr	1712(ra) # 5be2 <printf>
    exit(0);
    553a:	4501                	li	a0,0
    553c:	00000097          	auipc	ra,0x0
    5540:	316080e7          	jalr	790(ra) # 5852 <exit>
        printf("SOME TESTS FAILED\n");
    5544:	8556                	mv	a0,s5
    5546:	00000097          	auipc	ra,0x0
    554a:	69c080e7          	jalr	1692(ra) # 5be2 <printf>
        if(continuous != 2)
    554e:	f74998e3          	bne	s3,s4,54be <main+0x110>
      int free1 = countfree();
    5552:	00000097          	auipc	ra,0x0
    5556:	c8c080e7          	jalr	-884(ra) # 51de <countfree>
      if(free1 < free0){
    555a:	f72547e3          	blt	a0,s2,54c8 <main+0x11a>
      int free0 = countfree();
    555e:	00000097          	auipc	ra,0x0
    5562:	c80080e7          	jalr	-896(ra) # 51de <countfree>
    5566:	892a                	mv	s2,a0
      for (struct test *t = tests; t->s != 0; t++) {
    5568:	bc843583          	ld	a1,-1080(s0)
    556c:	d1fd                	beqz	a1,5552 <main+0x1a4>
    556e:	bc040493          	addi	s1,s0,-1088
        if(!run(t->f, t->s)){
    5572:	6088                	ld	a0,0(s1)
    5574:	00000097          	auipc	ra,0x0
    5578:	d9c080e7          	jalr	-612(ra) # 5310 <run>
    557c:	d561                	beqz	a0,5544 <main+0x196>
      for (struct test *t = tests; t->s != 0; t++) {
    557e:	04c1                	addi	s1,s1,16
    5580:	648c                	ld	a1,8(s1)
    5582:	f9e5                	bnez	a1,5572 <main+0x1c4>
    5584:	b7f9                	j	5552 <main+0x1a4>
    continuous = 1;
    5586:	4985                	li	s3,1
  } tests[] = {
    5588:	00003797          	auipc	a5,0x3
    558c:	c0878793          	addi	a5,a5,-1016 # 8190 <malloc+0x24f0>
    5590:	bc040713          	addi	a4,s0,-1088
    5594:	00003817          	auipc	a6,0x3
    5598:	ffc80813          	addi	a6,a6,-4 # 8590 <malloc+0x28f0>
    559c:	6388                	ld	a0,0(a5)
    559e:	678c                	ld	a1,8(a5)
    55a0:	6b90                	ld	a2,16(a5)
    55a2:	6f94                	ld	a3,24(a5)
    55a4:	e308                	sd	a0,0(a4)
    55a6:	e70c                	sd	a1,8(a4)
    55a8:	eb10                	sd	a2,16(a4)
    55aa:	ef14                	sd	a3,24(a4)
    55ac:	02078793          	addi	a5,a5,32
    55b0:	02070713          	addi	a4,a4,32
    55b4:	ff0794e3          	bne	a5,a6,559c <main+0x1ee>
    printf("continuous usertests starting\n");
    55b8:	00003517          	auipc	a0,0x3
    55bc:	b9050513          	addi	a0,a0,-1136 # 8148 <malloc+0x24a8>
    55c0:	00000097          	auipc	ra,0x0
    55c4:	622080e7          	jalr	1570(ra) # 5be2 <printf>
        printf("SOME TESTS FAILED\n");
    55c8:	00003a97          	auipc	s5,0x3
    55cc:	b08a8a93          	addi	s5,s5,-1272 # 80d0 <malloc+0x2430>
        if(continuous != 2)
    55d0:	4a09                	li	s4,2
        printf("FAILED -- lost %d free pages\n", free0 - free1);
    55d2:	00003b17          	auipc	s6,0x3
    55d6:	adeb0b13          	addi	s6,s6,-1314 # 80b0 <malloc+0x2410>
    55da:	b751                	j	555e <main+0x1b0>

00000000000055dc <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
    55dc:	1141                	addi	sp,sp,-16
    55de:	e422                	sd	s0,8(sp)
    55e0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
    55e2:	87aa                	mv	a5,a0
    55e4:	0585                	addi	a1,a1,1
    55e6:	0785                	addi	a5,a5,1
    55e8:	fff5c703          	lbu	a4,-1(a1)
    55ec:	fee78fa3          	sb	a4,-1(a5)
    55f0:	fb75                	bnez	a4,55e4 <strcpy+0x8>
    ;
  return os;
}
    55f2:	6422                	ld	s0,8(sp)
    55f4:	0141                	addi	sp,sp,16
    55f6:	8082                	ret

00000000000055f8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
    55f8:	1141                	addi	sp,sp,-16
    55fa:	e422                	sd	s0,8(sp)
    55fc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
    55fe:	00054783          	lbu	a5,0(a0)
    5602:	cb91                	beqz	a5,5616 <strcmp+0x1e>
    5604:	0005c703          	lbu	a4,0(a1)
    5608:	00f71763          	bne	a4,a5,5616 <strcmp+0x1e>
    p++, q++;
    560c:	0505                	addi	a0,a0,1
    560e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
    5610:	00054783          	lbu	a5,0(a0)
    5614:	fbe5                	bnez	a5,5604 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
    5616:	0005c503          	lbu	a0,0(a1)
}
    561a:	40a7853b          	subw	a0,a5,a0
    561e:	6422                	ld	s0,8(sp)
    5620:	0141                	addi	sp,sp,16
    5622:	8082                	ret

0000000000005624 <strlen>:

uint
strlen(const char *s)
{
    5624:	1141                	addi	sp,sp,-16
    5626:	e422                	sd	s0,8(sp)
    5628:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    562a:	00054783          	lbu	a5,0(a0)
    562e:	cf91                	beqz	a5,564a <strlen+0x26>
    5630:	0505                	addi	a0,a0,1
    5632:	87aa                	mv	a5,a0
    5634:	4685                	li	a3,1
    5636:	9e89                	subw	a3,a3,a0
    5638:	00f6853b          	addw	a0,a3,a5
    563c:	0785                	addi	a5,a5,1
    563e:	fff7c703          	lbu	a4,-1(a5)
    5642:	fb7d                	bnez	a4,5638 <strlen+0x14>
    ;
  return n;
}
    5644:	6422                	ld	s0,8(sp)
    5646:	0141                	addi	sp,sp,16
    5648:	8082                	ret
  for(n = 0; s[n]; n++)
    564a:	4501                	li	a0,0
    564c:	bfe5                	j	5644 <strlen+0x20>

000000000000564e <memset>:

void*
memset(void *dst, int c, uint n)
{
    564e:	1141                	addi	sp,sp,-16
    5650:	e422                	sd	s0,8(sp)
    5652:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    5654:	ce09                	beqz	a2,566e <memset+0x20>
    5656:	87aa                	mv	a5,a0
    5658:	fff6071b          	addiw	a4,a2,-1
    565c:	1702                	slli	a4,a4,0x20
    565e:	9301                	srli	a4,a4,0x20
    5660:	0705                	addi	a4,a4,1
    5662:	972a                	add	a4,a4,a0
    cdst[i] = c;
    5664:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    5668:	0785                	addi	a5,a5,1
    566a:	fee79de3          	bne	a5,a4,5664 <memset+0x16>
  }
  return dst;
}
    566e:	6422                	ld	s0,8(sp)
    5670:	0141                	addi	sp,sp,16
    5672:	8082                	ret

0000000000005674 <strchr>:

char*
strchr(const char *s, char c)
{
    5674:	1141                	addi	sp,sp,-16
    5676:	e422                	sd	s0,8(sp)
    5678:	0800                	addi	s0,sp,16
  for(; *s; s++)
    567a:	00054783          	lbu	a5,0(a0)
    567e:	cb99                	beqz	a5,5694 <strchr+0x20>
    if(*s == c)
    5680:	00f58763          	beq	a1,a5,568e <strchr+0x1a>
  for(; *s; s++)
    5684:	0505                	addi	a0,a0,1
    5686:	00054783          	lbu	a5,0(a0)
    568a:	fbfd                	bnez	a5,5680 <strchr+0xc>
      return (char*)s;
  return 0;
    568c:	4501                	li	a0,0
}
    568e:	6422                	ld	s0,8(sp)
    5690:	0141                	addi	sp,sp,16
    5692:	8082                	ret
  return 0;
    5694:	4501                	li	a0,0
    5696:	bfe5                	j	568e <strchr+0x1a>

0000000000005698 <gets>:

char*
gets(char *buf, int max)
{
    5698:	711d                	addi	sp,sp,-96
    569a:	ec86                	sd	ra,88(sp)
    569c:	e8a2                	sd	s0,80(sp)
    569e:	e4a6                	sd	s1,72(sp)
    56a0:	e0ca                	sd	s2,64(sp)
    56a2:	fc4e                	sd	s3,56(sp)
    56a4:	f852                	sd	s4,48(sp)
    56a6:	f456                	sd	s5,40(sp)
    56a8:	f05a                	sd	s6,32(sp)
    56aa:	ec5e                	sd	s7,24(sp)
    56ac:	1080                	addi	s0,sp,96
    56ae:	8baa                	mv	s7,a0
    56b0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
    56b2:	892a                	mv	s2,a0
    56b4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
    56b6:	4aa9                	li	s5,10
    56b8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
    56ba:	89a6                	mv	s3,s1
    56bc:	2485                	addiw	s1,s1,1
    56be:	0344d863          	bge	s1,s4,56ee <gets+0x56>
    cc = read(0, &c, 1);
    56c2:	4605                	li	a2,1
    56c4:	faf40593          	addi	a1,s0,-81
    56c8:	4501                	li	a0,0
    56ca:	00000097          	auipc	ra,0x0
    56ce:	1a0080e7          	jalr	416(ra) # 586a <read>
    if(cc < 1)
    56d2:	00a05e63          	blez	a0,56ee <gets+0x56>
    buf[i++] = c;
    56d6:	faf44783          	lbu	a5,-81(s0)
    56da:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
    56de:	01578763          	beq	a5,s5,56ec <gets+0x54>
    56e2:	0905                	addi	s2,s2,1
    56e4:	fd679be3          	bne	a5,s6,56ba <gets+0x22>
  for(i=0; i+1 < max; ){
    56e8:	89a6                	mv	s3,s1
    56ea:	a011                	j	56ee <gets+0x56>
    56ec:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
    56ee:	99de                	add	s3,s3,s7
    56f0:	00098023          	sb	zero,0(s3)
  return buf;
}
    56f4:	855e                	mv	a0,s7
    56f6:	60e6                	ld	ra,88(sp)
    56f8:	6446                	ld	s0,80(sp)
    56fa:	64a6                	ld	s1,72(sp)
    56fc:	6906                	ld	s2,64(sp)
    56fe:	79e2                	ld	s3,56(sp)
    5700:	7a42                	ld	s4,48(sp)
    5702:	7aa2                	ld	s5,40(sp)
    5704:	7b02                	ld	s6,32(sp)
    5706:	6be2                	ld	s7,24(sp)
    5708:	6125                	addi	sp,sp,96
    570a:	8082                	ret

000000000000570c <stat>:

int
stat(const char *n, struct stat *st)
{
    570c:	1101                	addi	sp,sp,-32
    570e:	ec06                	sd	ra,24(sp)
    5710:	e822                	sd	s0,16(sp)
    5712:	e426                	sd	s1,8(sp)
    5714:	e04a                	sd	s2,0(sp)
    5716:	1000                	addi	s0,sp,32
    5718:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
    571a:	4581                	li	a1,0
    571c:	00000097          	auipc	ra,0x0
    5720:	176080e7          	jalr	374(ra) # 5892 <open>
  if(fd < 0)
    5724:	02054563          	bltz	a0,574e <stat+0x42>
    5728:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
    572a:	85ca                	mv	a1,s2
    572c:	00000097          	auipc	ra,0x0
    5730:	17e080e7          	jalr	382(ra) # 58aa <fstat>
    5734:	892a                	mv	s2,a0
  close(fd);
    5736:	8526                	mv	a0,s1
    5738:	00000097          	auipc	ra,0x0
    573c:	142080e7          	jalr	322(ra) # 587a <close>
  return r;
}
    5740:	854a                	mv	a0,s2
    5742:	60e2                	ld	ra,24(sp)
    5744:	6442                	ld	s0,16(sp)
    5746:	64a2                	ld	s1,8(sp)
    5748:	6902                	ld	s2,0(sp)
    574a:	6105                	addi	sp,sp,32
    574c:	8082                	ret
    return -1;
    574e:	597d                	li	s2,-1
    5750:	bfc5                	j	5740 <stat+0x34>

0000000000005752 <atoi>:

int
atoi(const char *s)
{
    5752:	1141                	addi	sp,sp,-16
    5754:	e422                	sd	s0,8(sp)
    5756:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
    5758:	00054603          	lbu	a2,0(a0)
    575c:	fd06079b          	addiw	a5,a2,-48
    5760:	0ff7f793          	andi	a5,a5,255
    5764:	4725                	li	a4,9
    5766:	02f76963          	bltu	a4,a5,5798 <atoi+0x46>
    576a:	86aa                	mv	a3,a0
  n = 0;
    576c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
    576e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
    5770:	0685                	addi	a3,a3,1
    5772:	0025179b          	slliw	a5,a0,0x2
    5776:	9fa9                	addw	a5,a5,a0
    5778:	0017979b          	slliw	a5,a5,0x1
    577c:	9fb1                	addw	a5,a5,a2
    577e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
    5782:	0006c603          	lbu	a2,0(a3) # 1000 <linktest+0x1da>
    5786:	fd06071b          	addiw	a4,a2,-48
    578a:	0ff77713          	andi	a4,a4,255
    578e:	fee5f1e3          	bgeu	a1,a4,5770 <atoi+0x1e>
  return n;
}
    5792:	6422                	ld	s0,8(sp)
    5794:	0141                	addi	sp,sp,16
    5796:	8082                	ret
  n = 0;
    5798:	4501                	li	a0,0
    579a:	bfe5                	j	5792 <atoi+0x40>

000000000000579c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
    579c:	1141                	addi	sp,sp,-16
    579e:	e422                	sd	s0,8(sp)
    57a0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
    57a2:	02b57663          	bgeu	a0,a1,57ce <memmove+0x32>
    while(n-- > 0)
    57a6:	02c05163          	blez	a2,57c8 <memmove+0x2c>
    57aa:	fff6079b          	addiw	a5,a2,-1
    57ae:	1782                	slli	a5,a5,0x20
    57b0:	9381                	srli	a5,a5,0x20
    57b2:	0785                	addi	a5,a5,1
    57b4:	97aa                	add	a5,a5,a0
  dst = vdst;
    57b6:	872a                	mv	a4,a0
      *dst++ = *src++;
    57b8:	0585                	addi	a1,a1,1
    57ba:	0705                	addi	a4,a4,1
    57bc:	fff5c683          	lbu	a3,-1(a1)
    57c0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    57c4:	fee79ae3          	bne	a5,a4,57b8 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
    57c8:	6422                	ld	s0,8(sp)
    57ca:	0141                	addi	sp,sp,16
    57cc:	8082                	ret
    dst += n;
    57ce:	00c50733          	add	a4,a0,a2
    src += n;
    57d2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
    57d4:	fec05ae3          	blez	a2,57c8 <memmove+0x2c>
    57d8:	fff6079b          	addiw	a5,a2,-1
    57dc:	1782                	slli	a5,a5,0x20
    57de:	9381                	srli	a5,a5,0x20
    57e0:	fff7c793          	not	a5,a5
    57e4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
    57e6:	15fd                	addi	a1,a1,-1
    57e8:	177d                	addi	a4,a4,-1
    57ea:	0005c683          	lbu	a3,0(a1)
    57ee:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    57f2:	fee79ae3          	bne	a5,a4,57e6 <memmove+0x4a>
    57f6:	bfc9                	j	57c8 <memmove+0x2c>

00000000000057f8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
    57f8:	1141                	addi	sp,sp,-16
    57fa:	e422                	sd	s0,8(sp)
    57fc:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
    57fe:	ca05                	beqz	a2,582e <memcmp+0x36>
    5800:	fff6069b          	addiw	a3,a2,-1
    5804:	1682                	slli	a3,a3,0x20
    5806:	9281                	srli	a3,a3,0x20
    5808:	0685                	addi	a3,a3,1
    580a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
    580c:	00054783          	lbu	a5,0(a0)
    5810:	0005c703          	lbu	a4,0(a1)
    5814:	00e79863          	bne	a5,a4,5824 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
    5818:	0505                	addi	a0,a0,1
    p2++;
    581a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
    581c:	fed518e3          	bne	a0,a3,580c <memcmp+0x14>
  }
  return 0;
    5820:	4501                	li	a0,0
    5822:	a019                	j	5828 <memcmp+0x30>
      return *p1 - *p2;
    5824:	40e7853b          	subw	a0,a5,a4
}
    5828:	6422                	ld	s0,8(sp)
    582a:	0141                	addi	sp,sp,16
    582c:	8082                	ret
  return 0;
    582e:	4501                	li	a0,0
    5830:	bfe5                	j	5828 <memcmp+0x30>

0000000000005832 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
    5832:	1141                	addi	sp,sp,-16
    5834:	e406                	sd	ra,8(sp)
    5836:	e022                	sd	s0,0(sp)
    5838:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    583a:	00000097          	auipc	ra,0x0
    583e:	f62080e7          	jalr	-158(ra) # 579c <memmove>
}
    5842:	60a2                	ld	ra,8(sp)
    5844:	6402                	ld	s0,0(sp)
    5846:	0141                	addi	sp,sp,16
    5848:	8082                	ret

000000000000584a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
    584a:	4885                	li	a7,1
 ecall
    584c:	00000073          	ecall
 ret
    5850:	8082                	ret

0000000000005852 <exit>:
.global exit
exit:
 li a7, SYS_exit
    5852:	4889                	li	a7,2
 ecall
    5854:	00000073          	ecall
 ret
    5858:	8082                	ret

000000000000585a <wait>:
.global wait
wait:
 li a7, SYS_wait
    585a:	488d                	li	a7,3
 ecall
    585c:	00000073          	ecall
 ret
    5860:	8082                	ret

0000000000005862 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
    5862:	4891                	li	a7,4
 ecall
    5864:	00000073          	ecall
 ret
    5868:	8082                	ret

000000000000586a <read>:
.global read
read:
 li a7, SYS_read
    586a:	4895                	li	a7,5
 ecall
    586c:	00000073          	ecall
 ret
    5870:	8082                	ret

0000000000005872 <write>:
.global write
write:
 li a7, SYS_write
    5872:	48c1                	li	a7,16
 ecall
    5874:	00000073          	ecall
 ret
    5878:	8082                	ret

000000000000587a <close>:
.global close
close:
 li a7, SYS_close
    587a:	48d5                	li	a7,21
 ecall
    587c:	00000073          	ecall
 ret
    5880:	8082                	ret

0000000000005882 <kill>:
.global kill
kill:
 li a7, SYS_kill
    5882:	4899                	li	a7,6
 ecall
    5884:	00000073          	ecall
 ret
    5888:	8082                	ret

000000000000588a <exec>:
.global exec
exec:
 li a7, SYS_exec
    588a:	489d                	li	a7,7
 ecall
    588c:	00000073          	ecall
 ret
    5890:	8082                	ret

0000000000005892 <open>:
.global open
open:
 li a7, SYS_open
    5892:	48bd                	li	a7,15
 ecall
    5894:	00000073          	ecall
 ret
    5898:	8082                	ret

000000000000589a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
    589a:	48c5                	li	a7,17
 ecall
    589c:	00000073          	ecall
 ret
    58a0:	8082                	ret

00000000000058a2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
    58a2:	48c9                	li	a7,18
 ecall
    58a4:	00000073          	ecall
 ret
    58a8:	8082                	ret

00000000000058aa <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
    58aa:	48a1                	li	a7,8
 ecall
    58ac:	00000073          	ecall
 ret
    58b0:	8082                	ret

00000000000058b2 <link>:
.global link
link:
 li a7, SYS_link
    58b2:	48cd                	li	a7,19
 ecall
    58b4:	00000073          	ecall
 ret
    58b8:	8082                	ret

00000000000058ba <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
    58ba:	48d1                	li	a7,20
 ecall
    58bc:	00000073          	ecall
 ret
    58c0:	8082                	ret

00000000000058c2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
    58c2:	48a5                	li	a7,9
 ecall
    58c4:	00000073          	ecall
 ret
    58c8:	8082                	ret

00000000000058ca <dup>:
.global dup
dup:
 li a7, SYS_dup
    58ca:	48a9                	li	a7,10
 ecall
    58cc:	00000073          	ecall
 ret
    58d0:	8082                	ret

00000000000058d2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
    58d2:	48ad                	li	a7,11
 ecall
    58d4:	00000073          	ecall
 ret
    58d8:	8082                	ret

00000000000058da <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
    58da:	48b1                	li	a7,12
 ecall
    58dc:	00000073          	ecall
 ret
    58e0:	8082                	ret

00000000000058e2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
    58e2:	48b5                	li	a7,13
 ecall
    58e4:	00000073          	ecall
 ret
    58e8:	8082                	ret

00000000000058ea <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
    58ea:	48b9                	li	a7,14
 ecall
    58ec:	00000073          	ecall
 ret
    58f0:	8082                	ret

00000000000058f2 <set_cpu>:
.global set_cpu
set_cpu:
 li a7, SYS_set_cpu
    58f2:	48d9                	li	a7,22
 ecall
    58f4:	00000073          	ecall
 ret
    58f8:	8082                	ret

00000000000058fa <get_cpu>:
.global get_cpu
get_cpu:
 li a7, SYS_get_cpu
    58fa:	48dd                	li	a7,23
 ecall
    58fc:	00000073          	ecall
 ret
    5900:	8082                	ret

0000000000005902 <cpu_process_count>:
.global cpu_process_count
cpu_process_count:
 li a7, SYS_cpu_process_count
    5902:	48e1                	li	a7,24
 ecall
    5904:	00000073          	ecall
 ret
    5908:	8082                	ret

000000000000590a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
    590a:	1101                	addi	sp,sp,-32
    590c:	ec06                	sd	ra,24(sp)
    590e:	e822                	sd	s0,16(sp)
    5910:	1000                	addi	s0,sp,32
    5912:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
    5916:	4605                	li	a2,1
    5918:	fef40593          	addi	a1,s0,-17
    591c:	00000097          	auipc	ra,0x0
    5920:	f56080e7          	jalr	-170(ra) # 5872 <write>
}
    5924:	60e2                	ld	ra,24(sp)
    5926:	6442                	ld	s0,16(sp)
    5928:	6105                	addi	sp,sp,32
    592a:	8082                	ret

000000000000592c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
    592c:	7139                	addi	sp,sp,-64
    592e:	fc06                	sd	ra,56(sp)
    5930:	f822                	sd	s0,48(sp)
    5932:	f426                	sd	s1,40(sp)
    5934:	f04a                	sd	s2,32(sp)
    5936:	ec4e                	sd	s3,24(sp)
    5938:	0080                	addi	s0,sp,64
    593a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
    593c:	c299                	beqz	a3,5942 <printint+0x16>
    593e:	0805c863          	bltz	a1,59ce <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
    5942:	2581                	sext.w	a1,a1
  neg = 0;
    5944:	4881                	li	a7,0
    5946:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
    594a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
    594c:	2601                	sext.w	a2,a2
    594e:	00003517          	auipc	a0,0x3
    5952:	c4a50513          	addi	a0,a0,-950 # 8598 <digits>
    5956:	883a                	mv	a6,a4
    5958:	2705                	addiw	a4,a4,1
    595a:	02c5f7bb          	remuw	a5,a1,a2
    595e:	1782                	slli	a5,a5,0x20
    5960:	9381                	srli	a5,a5,0x20
    5962:	97aa                	add	a5,a5,a0
    5964:	0007c783          	lbu	a5,0(a5)
    5968:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
    596c:	0005879b          	sext.w	a5,a1
    5970:	02c5d5bb          	divuw	a1,a1,a2
    5974:	0685                	addi	a3,a3,1
    5976:	fec7f0e3          	bgeu	a5,a2,5956 <printint+0x2a>
  if(neg)
    597a:	00088b63          	beqz	a7,5990 <printint+0x64>
    buf[i++] = '-';
    597e:	fd040793          	addi	a5,s0,-48
    5982:	973e                	add	a4,a4,a5
    5984:	02d00793          	li	a5,45
    5988:	fef70823          	sb	a5,-16(a4)
    598c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    5990:	02e05863          	blez	a4,59c0 <printint+0x94>
    5994:	fc040793          	addi	a5,s0,-64
    5998:	00e78933          	add	s2,a5,a4
    599c:	fff78993          	addi	s3,a5,-1
    59a0:	99ba                	add	s3,s3,a4
    59a2:	377d                	addiw	a4,a4,-1
    59a4:	1702                	slli	a4,a4,0x20
    59a6:	9301                	srli	a4,a4,0x20
    59a8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
    59ac:	fff94583          	lbu	a1,-1(s2)
    59b0:	8526                	mv	a0,s1
    59b2:	00000097          	auipc	ra,0x0
    59b6:	f58080e7          	jalr	-168(ra) # 590a <putc>
  while(--i >= 0)
    59ba:	197d                	addi	s2,s2,-1
    59bc:	ff3918e3          	bne	s2,s3,59ac <printint+0x80>
}
    59c0:	70e2                	ld	ra,56(sp)
    59c2:	7442                	ld	s0,48(sp)
    59c4:	74a2                	ld	s1,40(sp)
    59c6:	7902                	ld	s2,32(sp)
    59c8:	69e2                	ld	s3,24(sp)
    59ca:	6121                	addi	sp,sp,64
    59cc:	8082                	ret
    x = -xx;
    59ce:	40b005bb          	negw	a1,a1
    neg = 1;
    59d2:	4885                	li	a7,1
    x = -xx;
    59d4:	bf8d                	j	5946 <printint+0x1a>

00000000000059d6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    59d6:	7119                	addi	sp,sp,-128
    59d8:	fc86                	sd	ra,120(sp)
    59da:	f8a2                	sd	s0,112(sp)
    59dc:	f4a6                	sd	s1,104(sp)
    59de:	f0ca                	sd	s2,96(sp)
    59e0:	ecce                	sd	s3,88(sp)
    59e2:	e8d2                	sd	s4,80(sp)
    59e4:	e4d6                	sd	s5,72(sp)
    59e6:	e0da                	sd	s6,64(sp)
    59e8:	fc5e                	sd	s7,56(sp)
    59ea:	f862                	sd	s8,48(sp)
    59ec:	f466                	sd	s9,40(sp)
    59ee:	f06a                	sd	s10,32(sp)
    59f0:	ec6e                	sd	s11,24(sp)
    59f2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    59f4:	0005c903          	lbu	s2,0(a1)
    59f8:	18090f63          	beqz	s2,5b96 <vprintf+0x1c0>
    59fc:	8aaa                	mv	s5,a0
    59fe:	8b32                	mv	s6,a2
    5a00:	00158493          	addi	s1,a1,1
  state = 0;
    5a04:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    5a06:	02500a13          	li	s4,37
      if(c == 'd'){
    5a0a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    5a0e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    5a12:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    5a16:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    5a1a:	00003b97          	auipc	s7,0x3
    5a1e:	b7eb8b93          	addi	s7,s7,-1154 # 8598 <digits>
    5a22:	a839                	j	5a40 <vprintf+0x6a>
        putc(fd, c);
    5a24:	85ca                	mv	a1,s2
    5a26:	8556                	mv	a0,s5
    5a28:	00000097          	auipc	ra,0x0
    5a2c:	ee2080e7          	jalr	-286(ra) # 590a <putc>
    5a30:	a019                	j	5a36 <vprintf+0x60>
    } else if(state == '%'){
    5a32:	01498f63          	beq	s3,s4,5a50 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    5a36:	0485                	addi	s1,s1,1
    5a38:	fff4c903          	lbu	s2,-1(s1)
    5a3c:	14090d63          	beqz	s2,5b96 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    5a40:	0009079b          	sext.w	a5,s2
    if(state == 0){
    5a44:	fe0997e3          	bnez	s3,5a32 <vprintf+0x5c>
      if(c == '%'){
    5a48:	fd479ee3          	bne	a5,s4,5a24 <vprintf+0x4e>
        state = '%';
    5a4c:	89be                	mv	s3,a5
    5a4e:	b7e5                	j	5a36 <vprintf+0x60>
      if(c == 'd'){
    5a50:	05878063          	beq	a5,s8,5a90 <vprintf+0xba>
      } else if(c == 'l') {
    5a54:	05978c63          	beq	a5,s9,5aac <vprintf+0xd6>
      } else if(c == 'x') {
    5a58:	07a78863          	beq	a5,s10,5ac8 <vprintf+0xf2>
      } else if(c == 'p') {
    5a5c:	09b78463          	beq	a5,s11,5ae4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    5a60:	07300713          	li	a4,115
    5a64:	0ce78663          	beq	a5,a4,5b30 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    5a68:	06300713          	li	a4,99
    5a6c:	0ee78e63          	beq	a5,a4,5b68 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    5a70:	11478863          	beq	a5,s4,5b80 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    5a74:	85d2                	mv	a1,s4
    5a76:	8556                	mv	a0,s5
    5a78:	00000097          	auipc	ra,0x0
    5a7c:	e92080e7          	jalr	-366(ra) # 590a <putc>
        putc(fd, c);
    5a80:	85ca                	mv	a1,s2
    5a82:	8556                	mv	a0,s5
    5a84:	00000097          	auipc	ra,0x0
    5a88:	e86080e7          	jalr	-378(ra) # 590a <putc>
      }
      state = 0;
    5a8c:	4981                	li	s3,0
    5a8e:	b765                	j	5a36 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    5a90:	008b0913          	addi	s2,s6,8
    5a94:	4685                	li	a3,1
    5a96:	4629                	li	a2,10
    5a98:	000b2583          	lw	a1,0(s6)
    5a9c:	8556                	mv	a0,s5
    5a9e:	00000097          	auipc	ra,0x0
    5aa2:	e8e080e7          	jalr	-370(ra) # 592c <printint>
    5aa6:	8b4a                	mv	s6,s2
      state = 0;
    5aa8:	4981                	li	s3,0
    5aaa:	b771                	j	5a36 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    5aac:	008b0913          	addi	s2,s6,8
    5ab0:	4681                	li	a3,0
    5ab2:	4629                	li	a2,10
    5ab4:	000b2583          	lw	a1,0(s6)
    5ab8:	8556                	mv	a0,s5
    5aba:	00000097          	auipc	ra,0x0
    5abe:	e72080e7          	jalr	-398(ra) # 592c <printint>
    5ac2:	8b4a                	mv	s6,s2
      state = 0;
    5ac4:	4981                	li	s3,0
    5ac6:	bf85                	j	5a36 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    5ac8:	008b0913          	addi	s2,s6,8
    5acc:	4681                	li	a3,0
    5ace:	4641                	li	a2,16
    5ad0:	000b2583          	lw	a1,0(s6)
    5ad4:	8556                	mv	a0,s5
    5ad6:	00000097          	auipc	ra,0x0
    5ada:	e56080e7          	jalr	-426(ra) # 592c <printint>
    5ade:	8b4a                	mv	s6,s2
      state = 0;
    5ae0:	4981                	li	s3,0
    5ae2:	bf91                	j	5a36 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    5ae4:	008b0793          	addi	a5,s6,8
    5ae8:	f8f43423          	sd	a5,-120(s0)
    5aec:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    5af0:	03000593          	li	a1,48
    5af4:	8556                	mv	a0,s5
    5af6:	00000097          	auipc	ra,0x0
    5afa:	e14080e7          	jalr	-492(ra) # 590a <putc>
  putc(fd, 'x');
    5afe:	85ea                	mv	a1,s10
    5b00:	8556                	mv	a0,s5
    5b02:	00000097          	auipc	ra,0x0
    5b06:	e08080e7          	jalr	-504(ra) # 590a <putc>
    5b0a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    5b0c:	03c9d793          	srli	a5,s3,0x3c
    5b10:	97de                	add	a5,a5,s7
    5b12:	0007c583          	lbu	a1,0(a5)
    5b16:	8556                	mv	a0,s5
    5b18:	00000097          	auipc	ra,0x0
    5b1c:	df2080e7          	jalr	-526(ra) # 590a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    5b20:	0992                	slli	s3,s3,0x4
    5b22:	397d                	addiw	s2,s2,-1
    5b24:	fe0914e3          	bnez	s2,5b0c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    5b28:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    5b2c:	4981                	li	s3,0
    5b2e:	b721                	j	5a36 <vprintf+0x60>
        s = va_arg(ap, char*);
    5b30:	008b0993          	addi	s3,s6,8
    5b34:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    5b38:	02090163          	beqz	s2,5b5a <vprintf+0x184>
        while(*s != 0){
    5b3c:	00094583          	lbu	a1,0(s2)
    5b40:	c9a1                	beqz	a1,5b90 <vprintf+0x1ba>
          putc(fd, *s);
    5b42:	8556                	mv	a0,s5
    5b44:	00000097          	auipc	ra,0x0
    5b48:	dc6080e7          	jalr	-570(ra) # 590a <putc>
          s++;
    5b4c:	0905                	addi	s2,s2,1
        while(*s != 0){
    5b4e:	00094583          	lbu	a1,0(s2)
    5b52:	f9e5                	bnez	a1,5b42 <vprintf+0x16c>
        s = va_arg(ap, char*);
    5b54:	8b4e                	mv	s6,s3
      state = 0;
    5b56:	4981                	li	s3,0
    5b58:	bdf9                	j	5a36 <vprintf+0x60>
          s = "(null)";
    5b5a:	00003917          	auipc	s2,0x3
    5b5e:	a3690913          	addi	s2,s2,-1482 # 8590 <malloc+0x28f0>
        while(*s != 0){
    5b62:	02800593          	li	a1,40
    5b66:	bff1                	j	5b42 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    5b68:	008b0913          	addi	s2,s6,8
    5b6c:	000b4583          	lbu	a1,0(s6)
    5b70:	8556                	mv	a0,s5
    5b72:	00000097          	auipc	ra,0x0
    5b76:	d98080e7          	jalr	-616(ra) # 590a <putc>
    5b7a:	8b4a                	mv	s6,s2
      state = 0;
    5b7c:	4981                	li	s3,0
    5b7e:	bd65                	j	5a36 <vprintf+0x60>
        putc(fd, c);
    5b80:	85d2                	mv	a1,s4
    5b82:	8556                	mv	a0,s5
    5b84:	00000097          	auipc	ra,0x0
    5b88:	d86080e7          	jalr	-634(ra) # 590a <putc>
      state = 0;
    5b8c:	4981                	li	s3,0
    5b8e:	b565                	j	5a36 <vprintf+0x60>
        s = va_arg(ap, char*);
    5b90:	8b4e                	mv	s6,s3
      state = 0;
    5b92:	4981                	li	s3,0
    5b94:	b54d                	j	5a36 <vprintf+0x60>
    }
  }
}
    5b96:	70e6                	ld	ra,120(sp)
    5b98:	7446                	ld	s0,112(sp)
    5b9a:	74a6                	ld	s1,104(sp)
    5b9c:	7906                	ld	s2,96(sp)
    5b9e:	69e6                	ld	s3,88(sp)
    5ba0:	6a46                	ld	s4,80(sp)
    5ba2:	6aa6                	ld	s5,72(sp)
    5ba4:	6b06                	ld	s6,64(sp)
    5ba6:	7be2                	ld	s7,56(sp)
    5ba8:	7c42                	ld	s8,48(sp)
    5baa:	7ca2                	ld	s9,40(sp)
    5bac:	7d02                	ld	s10,32(sp)
    5bae:	6de2                	ld	s11,24(sp)
    5bb0:	6109                	addi	sp,sp,128
    5bb2:	8082                	ret

0000000000005bb4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    5bb4:	715d                	addi	sp,sp,-80
    5bb6:	ec06                	sd	ra,24(sp)
    5bb8:	e822                	sd	s0,16(sp)
    5bba:	1000                	addi	s0,sp,32
    5bbc:	e010                	sd	a2,0(s0)
    5bbe:	e414                	sd	a3,8(s0)
    5bc0:	e818                	sd	a4,16(s0)
    5bc2:	ec1c                	sd	a5,24(s0)
    5bc4:	03043023          	sd	a6,32(s0)
    5bc8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    5bcc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    5bd0:	8622                	mv	a2,s0
    5bd2:	00000097          	auipc	ra,0x0
    5bd6:	e04080e7          	jalr	-508(ra) # 59d6 <vprintf>
}
    5bda:	60e2                	ld	ra,24(sp)
    5bdc:	6442                	ld	s0,16(sp)
    5bde:	6161                	addi	sp,sp,80
    5be0:	8082                	ret

0000000000005be2 <printf>:

void
printf(const char *fmt, ...)
{
    5be2:	711d                	addi	sp,sp,-96
    5be4:	ec06                	sd	ra,24(sp)
    5be6:	e822                	sd	s0,16(sp)
    5be8:	1000                	addi	s0,sp,32
    5bea:	e40c                	sd	a1,8(s0)
    5bec:	e810                	sd	a2,16(s0)
    5bee:	ec14                	sd	a3,24(s0)
    5bf0:	f018                	sd	a4,32(s0)
    5bf2:	f41c                	sd	a5,40(s0)
    5bf4:	03043823          	sd	a6,48(s0)
    5bf8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    5bfc:	00840613          	addi	a2,s0,8
    5c00:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    5c04:	85aa                	mv	a1,a0
    5c06:	4505                	li	a0,1
    5c08:	00000097          	auipc	ra,0x0
    5c0c:	dce080e7          	jalr	-562(ra) # 59d6 <vprintf>
}
    5c10:	60e2                	ld	ra,24(sp)
    5c12:	6442                	ld	s0,16(sp)
    5c14:	6125                	addi	sp,sp,96
    5c16:	8082                	ret

0000000000005c18 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    5c18:	1141                	addi	sp,sp,-16
    5c1a:	e422                	sd	s0,8(sp)
    5c1c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    5c1e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    5c22:	00003797          	auipc	a5,0x3
    5c26:	9967b783          	ld	a5,-1642(a5) # 85b8 <freep>
    5c2a:	a805                	j	5c5a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    5c2c:	4618                	lw	a4,8(a2)
    5c2e:	9db9                	addw	a1,a1,a4
    5c30:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    5c34:	6398                	ld	a4,0(a5)
    5c36:	6318                	ld	a4,0(a4)
    5c38:	fee53823          	sd	a4,-16(a0)
    5c3c:	a091                	j	5c80 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    5c3e:	ff852703          	lw	a4,-8(a0)
    5c42:	9e39                	addw	a2,a2,a4
    5c44:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    5c46:	ff053703          	ld	a4,-16(a0)
    5c4a:	e398                	sd	a4,0(a5)
    5c4c:	a099                	j	5c92 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    5c4e:	6398                	ld	a4,0(a5)
    5c50:	00e7e463          	bltu	a5,a4,5c58 <free+0x40>
    5c54:	00e6ea63          	bltu	a3,a4,5c68 <free+0x50>
{
    5c58:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    5c5a:	fed7fae3          	bgeu	a5,a3,5c4e <free+0x36>
    5c5e:	6398                	ld	a4,0(a5)
    5c60:	00e6e463          	bltu	a3,a4,5c68 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    5c64:	fee7eae3          	bltu	a5,a4,5c58 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    5c68:	ff852583          	lw	a1,-8(a0)
    5c6c:	6390                	ld	a2,0(a5)
    5c6e:	02059713          	slli	a4,a1,0x20
    5c72:	9301                	srli	a4,a4,0x20
    5c74:	0712                	slli	a4,a4,0x4
    5c76:	9736                	add	a4,a4,a3
    5c78:	fae60ae3          	beq	a2,a4,5c2c <free+0x14>
    bp->s.ptr = p->s.ptr;
    5c7c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    5c80:	4790                	lw	a2,8(a5)
    5c82:	02061713          	slli	a4,a2,0x20
    5c86:	9301                	srli	a4,a4,0x20
    5c88:	0712                	slli	a4,a4,0x4
    5c8a:	973e                	add	a4,a4,a5
    5c8c:	fae689e3          	beq	a3,a4,5c3e <free+0x26>
  } else
    p->s.ptr = bp;
    5c90:	e394                	sd	a3,0(a5)
  freep = p;
    5c92:	00003717          	auipc	a4,0x3
    5c96:	92f73323          	sd	a5,-1754(a4) # 85b8 <freep>
}
    5c9a:	6422                	ld	s0,8(sp)
    5c9c:	0141                	addi	sp,sp,16
    5c9e:	8082                	ret

0000000000005ca0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    5ca0:	7139                	addi	sp,sp,-64
    5ca2:	fc06                	sd	ra,56(sp)
    5ca4:	f822                	sd	s0,48(sp)
    5ca6:	f426                	sd	s1,40(sp)
    5ca8:	f04a                	sd	s2,32(sp)
    5caa:	ec4e                	sd	s3,24(sp)
    5cac:	e852                	sd	s4,16(sp)
    5cae:	e456                	sd	s5,8(sp)
    5cb0:	e05a                	sd	s6,0(sp)
    5cb2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    5cb4:	02051493          	slli	s1,a0,0x20
    5cb8:	9081                	srli	s1,s1,0x20
    5cba:	04bd                	addi	s1,s1,15
    5cbc:	8091                	srli	s1,s1,0x4
    5cbe:	0014899b          	addiw	s3,s1,1
    5cc2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    5cc4:	00003517          	auipc	a0,0x3
    5cc8:	8f453503          	ld	a0,-1804(a0) # 85b8 <freep>
    5ccc:	c515                	beqz	a0,5cf8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    5cce:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    5cd0:	4798                	lw	a4,8(a5)
    5cd2:	02977f63          	bgeu	a4,s1,5d10 <malloc+0x70>
    5cd6:	8a4e                	mv	s4,s3
    5cd8:	0009871b          	sext.w	a4,s3
    5cdc:	6685                	lui	a3,0x1
    5cde:	00d77363          	bgeu	a4,a3,5ce4 <malloc+0x44>
    5ce2:	6a05                	lui	s4,0x1
    5ce4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    5ce8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    5cec:	00003917          	auipc	s2,0x3
    5cf0:	8cc90913          	addi	s2,s2,-1844 # 85b8 <freep>
  if(p == (char*)-1)
    5cf4:	5afd                	li	s5,-1
    5cf6:	a88d                	j	5d68 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
    5cf8:	00009797          	auipc	a5,0x9
    5cfc:	0e078793          	addi	a5,a5,224 # edd8 <base>
    5d00:	00003717          	auipc	a4,0x3
    5d04:	8af73c23          	sd	a5,-1864(a4) # 85b8 <freep>
    5d08:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    5d0a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    5d0e:	b7e1                	j	5cd6 <malloc+0x36>
      if(p->s.size == nunits)
    5d10:	02e48b63          	beq	s1,a4,5d46 <malloc+0xa6>
        p->s.size -= nunits;
    5d14:	4137073b          	subw	a4,a4,s3
    5d18:	c798                	sw	a4,8(a5)
        p += p->s.size;
    5d1a:	1702                	slli	a4,a4,0x20
    5d1c:	9301                	srli	a4,a4,0x20
    5d1e:	0712                	slli	a4,a4,0x4
    5d20:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    5d22:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    5d26:	00003717          	auipc	a4,0x3
    5d2a:	88a73923          	sd	a0,-1902(a4) # 85b8 <freep>
      return (void*)(p + 1);
    5d2e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    5d32:	70e2                	ld	ra,56(sp)
    5d34:	7442                	ld	s0,48(sp)
    5d36:	74a2                	ld	s1,40(sp)
    5d38:	7902                	ld	s2,32(sp)
    5d3a:	69e2                	ld	s3,24(sp)
    5d3c:	6a42                	ld	s4,16(sp)
    5d3e:	6aa2                	ld	s5,8(sp)
    5d40:	6b02                	ld	s6,0(sp)
    5d42:	6121                	addi	sp,sp,64
    5d44:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    5d46:	6398                	ld	a4,0(a5)
    5d48:	e118                	sd	a4,0(a0)
    5d4a:	bff1                	j	5d26 <malloc+0x86>
  hp->s.size = nu;
    5d4c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    5d50:	0541                	addi	a0,a0,16
    5d52:	00000097          	auipc	ra,0x0
    5d56:	ec6080e7          	jalr	-314(ra) # 5c18 <free>
  return freep;
    5d5a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    5d5e:	d971                	beqz	a0,5d32 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    5d60:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    5d62:	4798                	lw	a4,8(a5)
    5d64:	fa9776e3          	bgeu	a4,s1,5d10 <malloc+0x70>
    if(p == freep)
    5d68:	00093703          	ld	a4,0(s2)
    5d6c:	853e                	mv	a0,a5
    5d6e:	fef719e3          	bne	a4,a5,5d60 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
    5d72:	8552                	mv	a0,s4
    5d74:	00000097          	auipc	ra,0x0
    5d78:	b66080e7          	jalr	-1178(ra) # 58da <sbrk>
  if(p == (char*)-1)
    5d7c:	fd5518e3          	bne	a0,s5,5d4c <malloc+0xac>
        return 0;
    5d80:	4501                	li	a0,0
    5d82:	bf45                	j	5d32 <malloc+0x92>
