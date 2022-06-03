
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c8c78793          	addi	a5,a5,-884 # 80005cf0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffb87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	edc78793          	addi	a5,a5,-292 # 80000f8a <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	440080e7          	jalr	1088(ra) # 8000256c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	b4c080e7          	jalr	-1204(ra) # 80000ce0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8f2080e7          	jalr	-1806(ra) # 80001ab6 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f9e080e7          	jalr	-98(ra) # 80002172 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	306080e7          	jalr	774(ra) # 80002516 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	b68080e7          	jalr	-1176(ra) # 80000d94 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	b52080e7          	jalr	-1198(ra) # 80000d94 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a0c080e7          	jalr	-1524(ra) # 80000ce0 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2d0080e7          	jalr	720(ra) # 800025c2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a92080e7          	jalr	-1390(ra) # 80000d94 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	eb8080e7          	jalr	-328(ra) # 800022fe <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	7e8080e7          	jalr	2024(ra) # 80000c50 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00041797          	auipc	a5,0x41
    8000047c:	ea078793          	addi	a5,a5,-352 # 80041318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	6e0080e7          	jalr	1760(ra) # 80000ce0 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	630080e7          	jalr	1584(ra) # 80000d94 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	4c6080e7          	jalr	1222(ra) # 80000c50 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	470080e7          	jalr	1136(ra) # 80000c50 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	498080e7          	jalr	1176(ra) # 80000c94 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	506080e7          	jalr	1286(ra) # 80000d34 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a5e080e7          	jalr	-1442(ra) # 800022fe <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	3fc080e7          	jalr	1020(ra) # 80000ce0 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	846080e7          	jalr	-1978(ra) # 80002172 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	42c080e7          	jalr	1068(ra) # 80000d94 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	30c080e7          	jalr	780(ra) # 80000ce0 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	3ae080e7          	jalr	942(ra) # 80000d94 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <get_reference_index>:

  return (void*)r;
}

uint64
get_reference_index(uint64 pa){
    800009f8:	1141                	addi	sp,sp,-16
    800009fa:	e422                	sd	s0,8(sp)
    800009fc:	0800                	addi	s0,sp,16
  return (pa - KERNBASE) / PGSIZE;
    800009fe:	800007b7          	lui	a5,0x80000
    80000a02:	953e                	add	a0,a0,a5
}
    80000a04:	8131                	srli	a0,a0,0xc
    80000a06:	6422                	ld	s0,8(sp)
    80000a08:	0141                	addi	sp,sp,16
    80000a0a:	8082                	ret

0000000080000a0c <decrease_reference>:

int
decrease_reference(uint64 pa)
{
    80000a0c:	7179                	addi	sp,sp,-48
    80000a0e:	f406                	sd	ra,40(sp)
    80000a10:	f022                	sd	s0,32(sp)
    80000a12:	ec26                	sd	s1,24(sp)
    80000a14:	e84a                	sd	s2,16(sp)
    80000a16:	e44e                	sd	s3,8(sp)
    80000a18:	1800                	addi	s0,sp,48
  return (pa - KERNBASE) / PGSIZE;
    80000a1a:	80000937          	lui	s2,0x80000
    80000a1e:	992a                	add	s2,s2,a0
    80000a20:	00c95913          	srli	s2,s2,0xc
  int reference;
  do {
    reference = references[get_reference_index((uint64)pa)];
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference - 1));
    80000a24:	00291993          	slli	s3,s2,0x2
    80000a28:	00011797          	auipc	a5,0x11
    80000a2c:	87878793          	addi	a5,a5,-1928 # 800112a0 <references>
    80000a30:	99be                	add	s3,s3,a5
    reference = references[get_reference_index((uint64)pa)];
    80000a32:	894e                	mv	s2,s3
    80000a34:	00092583          	lw	a1,0(s2) # ffffffff80000000 <end+0xfffffffefffba000>
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference - 1));
    80000a38:	fff5849b          	addiw	s1,a1,-1
    80000a3c:	8626                	mv	a2,s1
    80000a3e:	854e                	mv	a0,s3
    80000a40:	00006097          	auipc	ra,0x6
    80000a44:	8f6080e7          	jalr	-1802(ra) # 80006336 <cas>
    80000a48:	2501                	sext.w	a0,a0
    80000a4a:	f56d                	bnez	a0,80000a34 <decrease_reference+0x28>
  return reference - 1;
}
    80000a4c:	8526                	mv	a0,s1
    80000a4e:	70a2                	ld	ra,40(sp)
    80000a50:	7402                	ld	s0,32(sp)
    80000a52:	64e2                	ld	s1,24(sp)
    80000a54:	6942                	ld	s2,16(sp)
    80000a56:	69a2                	ld	s3,8(sp)
    80000a58:	6145                	addi	sp,sp,48
    80000a5a:	8082                	ret

0000000080000a5c <kfree>:
{
    80000a5c:	1101                	addi	sp,sp,-32
    80000a5e:	ec06                	sd	ra,24(sp)
    80000a60:	e822                	sd	s0,16(sp)
    80000a62:	e426                	sd	s1,8(sp)
    80000a64:	e04a                	sd	s2,0(sp)
    80000a66:	1000                	addi	s0,sp,32
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a68:	03451793          	slli	a5,a0,0x34
    80000a6c:	eb85                	bnez	a5,80000a9c <kfree+0x40>
    80000a6e:	84aa                	mv	s1,a0
    80000a70:	00045797          	auipc	a5,0x45
    80000a74:	59078793          	addi	a5,a5,1424 # 80046000 <end>
    80000a78:	02f56263          	bltu	a0,a5,80000a9c <kfree+0x40>
    80000a7c:	47c5                	li	a5,17
    80000a7e:	07ee                	slli	a5,a5,0x1b
    80000a80:	00f57e63          	bgeu	a0,a5,80000a9c <kfree+0x40>
  if(decrease_reference((uint64)pa) > 0) // check if there are still references to the page after removing one. Continue if there are.
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	f88080e7          	jalr	-120(ra) # 80000a0c <decrease_reference>
    80000a8c:	02a05063          	blez	a0,80000aac <kfree+0x50>
}
    80000a90:	60e2                	ld	ra,24(sp)
    80000a92:	6442                	ld	s0,16(sp)
    80000a94:	64a2                	ld	s1,8(sp)
    80000a96:	6902                	ld	s2,0(sp)
    80000a98:	6105                	addi	sp,sp,32
    80000a9a:	8082                	ret
    panic("kfree");
    80000a9c:	00007517          	auipc	a0,0x7
    80000aa0:	5c450513          	addi	a0,a0,1476 # 80008060 <digits+0x20>
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>
  return (pa - KERNBASE) / PGSIZE;
    80000aac:	800007b7          	lui	a5,0x80000
    80000ab0:	97a6                	add	a5,a5,s1
    80000ab2:	83b1                	srli	a5,a5,0xc
  references[get_reference_index((uint64)pa)] = 0; // initialize references of the page address
    80000ab4:	078a                	slli	a5,a5,0x2
    80000ab6:	00010717          	auipc	a4,0x10
    80000aba:	7ea70713          	addi	a4,a4,2026 # 800112a0 <references>
    80000abe:	97ba                	add	a5,a5,a4
    80000ac0:	0007a023          	sw	zero,0(a5) # ffffffff80000000 <end+0xfffffffefffba000>
  memset(pa, 1, PGSIZE);
    80000ac4:	6605                	lui	a2,0x1
    80000ac6:	4585                	li	a1,1
    80000ac8:	8526                	mv	a0,s1
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	312080e7          	jalr	786(ra) # 80000ddc <memset>
  acquire(&kmem.lock);
    80000ad2:	00010917          	auipc	s2,0x10
    80000ad6:	7ae90913          	addi	s2,s2,1966 # 80011280 <kmem>
    80000ada:	854a                	mv	a0,s2
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	204080e7          	jalr	516(ra) # 80000ce0 <acquire>
  r->next = kmem.freelist;
    80000ae4:	01893783          	ld	a5,24(s2)
    80000ae8:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aea:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aee:	854a                	mv	a0,s2
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	2a4080e7          	jalr	676(ra) # 80000d94 <release>
    80000af8:	bf61                	j	80000a90 <kfree+0x34>

0000000080000afa <freerange>:
{
    80000afa:	7179                	addi	sp,sp,-48
    80000afc:	f406                	sd	ra,40(sp)
    80000afe:	f022                	sd	s0,32(sp)
    80000b00:	ec26                	sd	s1,24(sp)
    80000b02:	e84a                	sd	s2,16(sp)
    80000b04:	e44e                	sd	s3,8(sp)
    80000b06:	e052                	sd	s4,0(sp)
    80000b08:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b0a:	6785                	lui	a5,0x1
    80000b0c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b10:	94aa                	add	s1,s1,a0
    80000b12:	757d                	lui	a0,0xfffff
    80000b14:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b16:	94be                	add	s1,s1,a5
    80000b18:	0095ee63          	bltu	a1,s1,80000b34 <freerange+0x3a>
    80000b1c:	892e                	mv	s2,a1
    kfree(p);
    80000b1e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b20:	6985                	lui	s3,0x1
    kfree(p);
    80000b22:	01448533          	add	a0,s1,s4
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	f36080e7          	jalr	-202(ra) # 80000a5c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2e:	94ce                	add	s1,s1,s3
    80000b30:	fe9979e3          	bgeu	s2,s1,80000b22 <freerange+0x28>
}
    80000b34:	70a2                	ld	ra,40(sp)
    80000b36:	7402                	ld	s0,32(sp)
    80000b38:	64e2                	ld	s1,24(sp)
    80000b3a:	6942                	ld	s2,16(sp)
    80000b3c:	69a2                	ld	s3,8(sp)
    80000b3e:	6a02                	ld	s4,0(sp)
    80000b40:	6145                	addi	sp,sp,48
    80000b42:	8082                	ret

0000000080000b44 <kinit>:
{
    80000b44:	1141                	addi	sp,sp,-16
    80000b46:	e406                	sd	ra,8(sp)
    80000b48:	e022                	sd	s0,0(sp)
    80000b4a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b4c:	00007597          	auipc	a1,0x7
    80000b50:	51c58593          	addi	a1,a1,1308 # 80008068 <digits+0x28>
    80000b54:	00010517          	auipc	a0,0x10
    80000b58:	72c50513          	addi	a0,a0,1836 # 80011280 <kmem>
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0f4080e7          	jalr	244(ra) # 80000c50 <initlock>
  memset(references, 0, sizeof(int)*NUM_PYS_PAGES);
    80000b64:	00020637          	lui	a2,0x20
    80000b68:	4581                	li	a1,0
    80000b6a:	00010517          	auipc	a0,0x10
    80000b6e:	73650513          	addi	a0,a0,1846 # 800112a0 <references>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	26a080e7          	jalr	618(ra) # 80000ddc <memset>
  freerange(end, (void*)PHYSTOP);
    80000b7a:	45c5                	li	a1,17
    80000b7c:	05ee                	slli	a1,a1,0x1b
    80000b7e:	00045517          	auipc	a0,0x45
    80000b82:	48250513          	addi	a0,a0,1154 # 80046000 <end>
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	f74080e7          	jalr	-140(ra) # 80000afa <freerange>
}
    80000b8e:	60a2                	ld	ra,8(sp)
    80000b90:	6402                	ld	s0,0(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <increase_reference>:

int
increase_reference(uint64 pa)
{
    80000b96:	7179                	addi	sp,sp,-48
    80000b98:	f406                	sd	ra,40(sp)
    80000b9a:	f022                	sd	s0,32(sp)
    80000b9c:	ec26                	sd	s1,24(sp)
    80000b9e:	e84a                	sd	s2,16(sp)
    80000ba0:	e44e                	sd	s3,8(sp)
    80000ba2:	1800                	addi	s0,sp,48
  return (pa - KERNBASE) / PGSIZE;
    80000ba4:	80000937          	lui	s2,0x80000
    80000ba8:	992a                	add	s2,s2,a0
    80000baa:	00c95913          	srli	s2,s2,0xc
  int reference;
  do {
    reference = references[get_reference_index((uint64)pa)];
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference + 1));
    80000bae:	00291993          	slli	s3,s2,0x2
    80000bb2:	00010797          	auipc	a5,0x10
    80000bb6:	6ee78793          	addi	a5,a5,1774 # 800112a0 <references>
    80000bba:	99be                	add	s3,s3,a5
    reference = references[get_reference_index((uint64)pa)];
    80000bbc:	894e                	mv	s2,s3
    80000bbe:	00092583          	lw	a1,0(s2) # ffffffff80000000 <end+0xfffffffefffba000>
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference + 1));
    80000bc2:	0015849b          	addiw	s1,a1,1
    80000bc6:	8626                	mv	a2,s1
    80000bc8:	854e                	mv	a0,s3
    80000bca:	00005097          	auipc	ra,0x5
    80000bce:	76c080e7          	jalr	1900(ra) # 80006336 <cas>
    80000bd2:	2501                	sext.w	a0,a0
    80000bd4:	f56d                	bnez	a0,80000bbe <increase_reference+0x28>
  return reference + 1;
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	70a2                	ld	ra,40(sp)
    80000bda:	7402                	ld	s0,32(sp)
    80000bdc:	64e2                	ld	s1,24(sp)
    80000bde:	6942                	ld	s2,16(sp)
    80000be0:	69a2                	ld	s3,8(sp)
    80000be2:	6145                	addi	sp,sp,48
    80000be4:	8082                	ret

0000000080000be6 <kalloc>:
{
    80000be6:	1101                	addi	sp,sp,-32
    80000be8:	ec06                	sd	ra,24(sp)
    80000bea:	e822                	sd	s0,16(sp)
    80000bec:	e426                	sd	s1,8(sp)
    80000bee:	1000                	addi	s0,sp,32
  acquire(&kmem.lock);
    80000bf0:	00010497          	auipc	s1,0x10
    80000bf4:	69048493          	addi	s1,s1,1680 # 80011280 <kmem>
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	0e6080e7          	jalr	230(ra) # 80000ce0 <acquire>
  r = kmem.freelist;
    80000c02:	6c84                	ld	s1,24(s1)
  if(r)
    80000c04:	cc8d                	beqz	s1,80000c3e <kalloc+0x58>
    kmem.freelist = r->next;
    80000c06:	609c                	ld	a5,0(s1)
    80000c08:	00010517          	auipc	a0,0x10
    80000c0c:	67850513          	addi	a0,a0,1656 # 80011280 <kmem>
    80000c10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	182080e7          	jalr	386(ra) # 80000d94 <release>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c1a:	6605                	lui	a2,0x1
    80000c1c:	4595                	li	a1,5
    80000c1e:	8526                	mv	a0,s1
    80000c20:	00000097          	auipc	ra,0x0
    80000c24:	1bc080e7          	jalr	444(ra) # 80000ddc <memset>
    increase_reference((uint64)r); // references[index of r] = 1
    80000c28:	8526                	mv	a0,s1
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	f6c080e7          	jalr	-148(ra) # 80000b96 <increase_reference>
}
    80000c32:	8526                	mv	a0,s1
    80000c34:	60e2                	ld	ra,24(sp)
    80000c36:	6442                	ld	s0,16(sp)
    80000c38:	64a2                	ld	s1,8(sp)
    80000c3a:	6105                	addi	sp,sp,32
    80000c3c:	8082                	ret
  release(&kmem.lock);
    80000c3e:	00010517          	auipc	a0,0x10
    80000c42:	64250513          	addi	a0,a0,1602 # 80011280 <kmem>
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	14e080e7          	jalr	334(ra) # 80000d94 <release>
  if(r)
    80000c4e:	b7d5                	j	80000c32 <kalloc+0x4c>

0000000080000c50 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c50:	1141                	addi	sp,sp,-16
    80000c52:	e422                	sd	s0,8(sp)
    80000c54:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c56:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c58:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c5c:	00053823          	sd	zero,16(a0)
}
    80000c60:	6422                	ld	s0,8(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret

0000000080000c66 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c66:	411c                	lw	a5,0(a0)
    80000c68:	e399                	bnez	a5,80000c6e <holding+0x8>
    80000c6a:	4501                	li	a0,0
  return r;
}
    80000c6c:	8082                	ret
{
    80000c6e:	1101                	addi	sp,sp,-32
    80000c70:	ec06                	sd	ra,24(sp)
    80000c72:	e822                	sd	s0,16(sp)
    80000c74:	e426                	sd	s1,8(sp)
    80000c76:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c78:	6904                	ld	s1,16(a0)
    80000c7a:	00001097          	auipc	ra,0x1
    80000c7e:	e20080e7          	jalr	-480(ra) # 80001a9a <mycpu>
    80000c82:	40a48533          	sub	a0,s1,a0
    80000c86:	00153513          	seqz	a0,a0
}
    80000c8a:	60e2                	ld	ra,24(sp)
    80000c8c:	6442                	ld	s0,16(sp)
    80000c8e:	64a2                	ld	s1,8(sp)
    80000c90:	6105                	addi	sp,sp,32
    80000c92:	8082                	ret

0000000080000c94 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c94:	1101                	addi	sp,sp,-32
    80000c96:	ec06                	sd	ra,24(sp)
    80000c98:	e822                	sd	s0,16(sp)
    80000c9a:	e426                	sd	s1,8(sp)
    80000c9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9e:	100024f3          	csrr	s1,sstatus
    80000ca2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ca6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cac:	00001097          	auipc	ra,0x1
    80000cb0:	dee080e7          	jalr	-530(ra) # 80001a9a <mycpu>
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	cf89                	beqz	a5,80000cd0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cb8:	00001097          	auipc	ra,0x1
    80000cbc:	de2080e7          	jalr	-542(ra) # 80001a9a <mycpu>
    80000cc0:	5d3c                	lw	a5,120(a0)
    80000cc2:	2785                	addiw	a5,a5,1
    80000cc4:	dd3c                	sw	a5,120(a0)
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    mycpu()->intena = old;
    80000cd0:	00001097          	auipc	ra,0x1
    80000cd4:	dca080e7          	jalr	-566(ra) # 80001a9a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cd8:	8085                	srli	s1,s1,0x1
    80000cda:	8885                	andi	s1,s1,1
    80000cdc:	dd64                	sw	s1,124(a0)
    80000cde:	bfe9                	j	80000cb8 <push_off+0x24>

0000000080000ce0 <acquire>:
{
    80000ce0:	1101                	addi	sp,sp,-32
    80000ce2:	ec06                	sd	ra,24(sp)
    80000ce4:	e822                	sd	s0,16(sp)
    80000ce6:	e426                	sd	s1,8(sp)
    80000ce8:	1000                	addi	s0,sp,32
    80000cea:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	fa8080e7          	jalr	-88(ra) # 80000c94 <push_off>
  if(holding(lk))
    80000cf4:	8526                	mv	a0,s1
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	f70080e7          	jalr	-144(ra) # 80000c66 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cfe:	4705                	li	a4,1
  if(holding(lk))
    80000d00:	e115                	bnez	a0,80000d24 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d02:	87ba                	mv	a5,a4
    80000d04:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d08:	2781                	sext.w	a5,a5
    80000d0a:	ffe5                	bnez	a5,80000d02 <acquire+0x22>
  __sync_synchronize();
    80000d0c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d10:	00001097          	auipc	ra,0x1
    80000d14:	d8a080e7          	jalr	-630(ra) # 80001a9a <mycpu>
    80000d18:	e888                	sd	a0,16(s1)
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	addi	sp,sp,32
    80000d22:	8082                	ret
    panic("acquire");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	34c50513          	addi	a0,a0,844 # 80008070 <digits+0x30>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	812080e7          	jalr	-2030(ra) # 8000053e <panic>

0000000080000d34 <pop_off>:

void
pop_off(void)
{
    80000d34:	1141                	addi	sp,sp,-16
    80000d36:	e406                	sd	ra,8(sp)
    80000d38:	e022                	sd	s0,0(sp)
    80000d3a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d3c:	00001097          	auipc	ra,0x1
    80000d40:	d5e080e7          	jalr	-674(ra) # 80001a9a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d44:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d48:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d4a:	e78d                	bnez	a5,80000d74 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d4c:	5d3c                	lw	a5,120(a0)
    80000d4e:	02f05b63          	blez	a5,80000d84 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d52:	37fd                	addiw	a5,a5,-1
    80000d54:	0007871b          	sext.w	a4,a5
    80000d58:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d5a:	eb09                	bnez	a4,80000d6c <pop_off+0x38>
    80000d5c:	5d7c                	lw	a5,124(a0)
    80000d5e:	c799                	beqz	a5,80000d6c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d68:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d6c:	60a2                	ld	ra,8(sp)
    80000d6e:	6402                	ld	s0,0(sp)
    80000d70:	0141                	addi	sp,sp,16
    80000d72:	8082                	ret
    panic("pop_off - interruptible");
    80000d74:	00007517          	auipc	a0,0x7
    80000d78:	30450513          	addi	a0,a0,772 # 80008078 <digits+0x38>
    80000d7c:	fffff097          	auipc	ra,0xfffff
    80000d80:	7c2080e7          	jalr	1986(ra) # 8000053e <panic>
    panic("pop_off");
    80000d84:	00007517          	auipc	a0,0x7
    80000d88:	30c50513          	addi	a0,a0,780 # 80008090 <digits+0x50>
    80000d8c:	fffff097          	auipc	ra,0xfffff
    80000d90:	7b2080e7          	jalr	1970(ra) # 8000053e <panic>

0000000080000d94 <release>:
{
    80000d94:	1101                	addi	sp,sp,-32
    80000d96:	ec06                	sd	ra,24(sp)
    80000d98:	e822                	sd	s0,16(sp)
    80000d9a:	e426                	sd	s1,8(sp)
    80000d9c:	1000                	addi	s0,sp,32
    80000d9e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000da0:	00000097          	auipc	ra,0x0
    80000da4:	ec6080e7          	jalr	-314(ra) # 80000c66 <holding>
    80000da8:	c115                	beqz	a0,80000dcc <release+0x38>
  lk->cpu = 0;
    80000daa:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dae:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000db2:	0f50000f          	fence	iorw,ow
    80000db6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dba:	00000097          	auipc	ra,0x0
    80000dbe:	f7a080e7          	jalr	-134(ra) # 80000d34 <pop_off>
}
    80000dc2:	60e2                	ld	ra,24(sp)
    80000dc4:	6442                	ld	s0,16(sp)
    80000dc6:	64a2                	ld	s1,8(sp)
    80000dc8:	6105                	addi	sp,sp,32
    80000dca:	8082                	ret
    panic("release");
    80000dcc:	00007517          	auipc	a0,0x7
    80000dd0:	2cc50513          	addi	a0,a0,716 # 80008098 <digits+0x58>
    80000dd4:	fffff097          	auipc	ra,0xfffff
    80000dd8:	76a080e7          	jalr	1898(ra) # 8000053e <panic>

0000000080000ddc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ddc:	1141                	addi	sp,sp,-16
    80000dde:	e422                	sd	s0,8(sp)
    80000de0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000de2:	ce09                	beqz	a2,80000dfc <memset+0x20>
    80000de4:	87aa                	mv	a5,a0
    80000de6:	fff6071b          	addiw	a4,a2,-1
    80000dea:	1702                	slli	a4,a4,0x20
    80000dec:	9301                	srli	a4,a4,0x20
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000df2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000df6:	0785                	addi	a5,a5,1
    80000df8:	fee79de3          	bne	a5,a4,80000df2 <memset+0x16>
  }
  return dst;
}
    80000dfc:	6422                	ld	s0,8(sp)
    80000dfe:	0141                	addi	sp,sp,16
    80000e00:	8082                	ret

0000000080000e02 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e422                	sd	s0,8(sp)
    80000e06:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e08:	ca05                	beqz	a2,80000e38 <memcmp+0x36>
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	1682                	slli	a3,a3,0x20
    80000e10:	9281                	srli	a3,a3,0x20
    80000e12:	0685                	addi	a3,a3,1
    80000e14:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e16:	00054783          	lbu	a5,0(a0)
    80000e1a:	0005c703          	lbu	a4,0(a1)
    80000e1e:	00e79863          	bne	a5,a4,80000e2e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e22:	0505                	addi	a0,a0,1
    80000e24:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e26:	fed518e3          	bne	a0,a3,80000e16 <memcmp+0x14>
  }

  return 0;
    80000e2a:	4501                	li	a0,0
    80000e2c:	a019                	j	80000e32 <memcmp+0x30>
      return *s1 - *s2;
    80000e2e:	40e7853b          	subw	a0,a5,a4
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  return 0;
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <memcmp+0x30>

0000000080000e3c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e422                	sd	s0,8(sp)
    80000e40:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e42:	ca0d                	beqz	a2,80000e74 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e44:	00a5f963          	bgeu	a1,a0,80000e56 <memmove+0x1a>
    80000e48:	02061693          	slli	a3,a2,0x20
    80000e4c:	9281                	srli	a3,a3,0x20
    80000e4e:	00d58733          	add	a4,a1,a3
    80000e52:	02e56463          	bltu	a0,a4,80000e7a <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e56:	fff6079b          	addiw	a5,a2,-1
    80000e5a:	1782                	slli	a5,a5,0x20
    80000e5c:	9381                	srli	a5,a5,0x20
    80000e5e:	0785                	addi	a5,a5,1
    80000e60:	97ae                	add	a5,a5,a1
    80000e62:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e64:	0585                	addi	a1,a1,1
    80000e66:	0705                	addi	a4,a4,1
    80000e68:	fff5c683          	lbu	a3,-1(a1)
    80000e6c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e70:	fef59ae3          	bne	a1,a5,80000e64 <memmove+0x28>

  return dst;
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	addi	sp,sp,16
    80000e78:	8082                	ret
    d += n;
    80000e7a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e7c:	fff6079b          	addiw	a5,a2,-1
    80000e80:	1782                	slli	a5,a5,0x20
    80000e82:	9381                	srli	a5,a5,0x20
    80000e84:	fff7c793          	not	a5,a5
    80000e88:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e8a:	177d                	addi	a4,a4,-1
    80000e8c:	16fd                	addi	a3,a3,-1
    80000e8e:	00074603          	lbu	a2,0(a4)
    80000e92:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e96:	fef71ae3          	bne	a4,a5,80000e8a <memmove+0x4e>
    80000e9a:	bfe9                	j	80000e74 <memmove+0x38>

0000000080000e9c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e406                	sd	ra,8(sp)
    80000ea0:	e022                	sd	s0,0(sp)
    80000ea2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ea4:	00000097          	auipc	ra,0x0
    80000ea8:	f98080e7          	jalr	-104(ra) # 80000e3c <memmove>
}
    80000eac:	60a2                	ld	ra,8(sp)
    80000eae:	6402                	ld	s0,0(sp)
    80000eb0:	0141                	addi	sp,sp,16
    80000eb2:	8082                	ret

0000000080000eb4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eb4:	1141                	addi	sp,sp,-16
    80000eb6:	e422                	sd	s0,8(sp)
    80000eb8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eba:	ce11                	beqz	a2,80000ed6 <strncmp+0x22>
    80000ebc:	00054783          	lbu	a5,0(a0)
    80000ec0:	cf89                	beqz	a5,80000eda <strncmp+0x26>
    80000ec2:	0005c703          	lbu	a4,0(a1)
    80000ec6:	00f71a63          	bne	a4,a5,80000eda <strncmp+0x26>
    n--, p++, q++;
    80000eca:	367d                	addiw	a2,a2,-1
    80000ecc:	0505                	addi	a0,a0,1
    80000ece:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ed0:	f675                	bnez	a2,80000ebc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ed2:	4501                	li	a0,0
    80000ed4:	a809                	j	80000ee6 <strncmp+0x32>
    80000ed6:	4501                	li	a0,0
    80000ed8:	a039                	j	80000ee6 <strncmp+0x32>
  if(n == 0)
    80000eda:	ca09                	beqz	a2,80000eec <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000edc:	00054503          	lbu	a0,0(a0)
    80000ee0:	0005c783          	lbu	a5,0(a1)
    80000ee4:	9d1d                	subw	a0,a0,a5
}
    80000ee6:	6422                	ld	s0,8(sp)
    80000ee8:	0141                	addi	sp,sp,16
    80000eea:	8082                	ret
    return 0;
    80000eec:	4501                	li	a0,0
    80000eee:	bfe5                	j	80000ee6 <strncmp+0x32>

0000000080000ef0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ef0:	1141                	addi	sp,sp,-16
    80000ef2:	e422                	sd	s0,8(sp)
    80000ef4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ef6:	872a                	mv	a4,a0
    80000ef8:	8832                	mv	a6,a2
    80000efa:	367d                	addiw	a2,a2,-1
    80000efc:	01005963          	blez	a6,80000f0e <strncpy+0x1e>
    80000f00:	0705                	addi	a4,a4,1
    80000f02:	0005c783          	lbu	a5,0(a1)
    80000f06:	fef70fa3          	sb	a5,-1(a4)
    80000f0a:	0585                	addi	a1,a1,1
    80000f0c:	f7f5                	bnez	a5,80000ef8 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f0e:	00c05d63          	blez	a2,80000f28 <strncpy+0x38>
    80000f12:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f14:	0685                	addi	a3,a3,1
    80000f16:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f1a:	fff6c793          	not	a5,a3
    80000f1e:	9fb9                	addw	a5,a5,a4
    80000f20:	010787bb          	addw	a5,a5,a6
    80000f24:	fef048e3          	bgtz	a5,80000f14 <strncpy+0x24>
  return os;
}
    80000f28:	6422                	ld	s0,8(sp)
    80000f2a:	0141                	addi	sp,sp,16
    80000f2c:	8082                	ret

0000000080000f2e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f2e:	1141                	addi	sp,sp,-16
    80000f30:	e422                	sd	s0,8(sp)
    80000f32:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f34:	02c05363          	blez	a2,80000f5a <safestrcpy+0x2c>
    80000f38:	fff6069b          	addiw	a3,a2,-1
    80000f3c:	1682                	slli	a3,a3,0x20
    80000f3e:	9281                	srli	a3,a3,0x20
    80000f40:	96ae                	add	a3,a3,a1
    80000f42:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f44:	00d58963          	beq	a1,a3,80000f56 <safestrcpy+0x28>
    80000f48:	0585                	addi	a1,a1,1
    80000f4a:	0785                	addi	a5,a5,1
    80000f4c:	fff5c703          	lbu	a4,-1(a1)
    80000f50:	fee78fa3          	sb	a4,-1(a5)
    80000f54:	fb65                	bnez	a4,80000f44 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f56:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f5a:	6422                	ld	s0,8(sp)
    80000f5c:	0141                	addi	sp,sp,16
    80000f5e:	8082                	ret

0000000080000f60 <strlen>:

int
strlen(const char *s)
{
    80000f60:	1141                	addi	sp,sp,-16
    80000f62:	e422                	sd	s0,8(sp)
    80000f64:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f66:	00054783          	lbu	a5,0(a0)
    80000f6a:	cf91                	beqz	a5,80000f86 <strlen+0x26>
    80000f6c:	0505                	addi	a0,a0,1
    80000f6e:	87aa                	mv	a5,a0
    80000f70:	4685                	li	a3,1
    80000f72:	9e89                	subw	a3,a3,a0
    80000f74:	00f6853b          	addw	a0,a3,a5
    80000f78:	0785                	addi	a5,a5,1
    80000f7a:	fff7c703          	lbu	a4,-1(a5)
    80000f7e:	fb7d                	bnez	a4,80000f74 <strlen+0x14>
    ;
  return n;
}
    80000f80:	6422                	ld	s0,8(sp)
    80000f82:	0141                	addi	sp,sp,16
    80000f84:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f86:	4501                	li	a0,0
    80000f88:	bfe5                	j	80000f80 <strlen+0x20>

0000000080000f8a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f8a:	1141                	addi	sp,sp,-16
    80000f8c:	e406                	sd	ra,8(sp)
    80000f8e:	e022                	sd	s0,0(sp)
    80000f90:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	af8080e7          	jalr	-1288(ra) # 80001a8a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	07e70713          	addi	a4,a4,126 # 80009018 <started>
  if(cpuid() == 0){
    80000fa2:	c139                	beqz	a0,80000fe8 <main+0x5e>
    while(started == 0)
    80000fa4:	431c                	lw	a5,0(a4)
    80000fa6:	2781                	sext.w	a5,a5
    80000fa8:	dff5                	beqz	a5,80000fa4 <main+0x1a>
      ;
    __sync_synchronize();
    80000faa:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	adc080e7          	jalr	-1316(ra) # 80001a8a <cpuid>
    80000fb6:	85aa                	mv	a1,a0
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	10050513          	addi	a0,a0,256 # 800080b8 <digits+0x78>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5c8080e7          	jalr	1480(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	0d8080e7          	jalr	216(ra) # 800010a0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	732080e7          	jalr	1842(ra) # 80002702 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fd8:	00005097          	auipc	ra,0x5
    80000fdc:	d58080e7          	jalr	-680(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	fe0080e7          	jalr	-32(ra) # 80001fc0 <scheduler>
    consoleinit();
    80000fe8:	fffff097          	auipc	ra,0xfffff
    80000fec:	468080e7          	jalr	1128(ra) # 80000450 <consoleinit>
    printfinit();
    80000ff0:	fffff097          	auipc	ra,0xfffff
    80000ff4:	77e080e7          	jalr	1918(ra) # 8000076e <printfinit>
    printf("\n");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d050513          	addi	a0,a0,208 # 800080c8 <digits+0x88>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	588080e7          	jalr	1416(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	09850513          	addi	a0,a0,152 # 800080a0 <digits+0x60>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	578080e7          	jalr	1400(ra) # 80000588 <printf>
    printf("\n");
    80001018:	00007517          	auipc	a0,0x7
    8000101c:	0b050513          	addi	a0,a0,176 # 800080c8 <digits+0x88>
    80001020:	fffff097          	auipc	ra,0xfffff
    80001024:	568080e7          	jalr	1384(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001028:	00000097          	auipc	ra,0x0
    8000102c:	b1c080e7          	jalr	-1252(ra) # 80000b44 <kinit>
    kvminit();       // create kernel page table
    80001030:	00000097          	auipc	ra,0x0
    80001034:	322080e7          	jalr	802(ra) # 80001352 <kvminit>
    kvminithart();   // turn on paging
    80001038:	00000097          	auipc	ra,0x0
    8000103c:	068080e7          	jalr	104(ra) # 800010a0 <kvminithart>
    procinit();      // process table
    80001040:	00001097          	auipc	ra,0x1
    80001044:	99a080e7          	jalr	-1638(ra) # 800019da <procinit>
    trapinit();      // trap vectors
    80001048:	00001097          	auipc	ra,0x1
    8000104c:	692080e7          	jalr	1682(ra) # 800026da <trapinit>
    trapinithart();  // install kernel trap vector
    80001050:	00001097          	auipc	ra,0x1
    80001054:	6b2080e7          	jalr	1714(ra) # 80002702 <trapinithart>
    plicinit();      // set up interrupt controller
    80001058:	00005097          	auipc	ra,0x5
    8000105c:	cc2080e7          	jalr	-830(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001060:	00005097          	auipc	ra,0x5
    80001064:	cd0080e7          	jalr	-816(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80001068:	00002097          	auipc	ra,0x2
    8000106c:	eae080e7          	jalr	-338(ra) # 80002f16 <binit>
    iinit();         // inode table
    80001070:	00002097          	auipc	ra,0x2
    80001074:	53e080e7          	jalr	1342(ra) # 800035ae <iinit>
    fileinit();      // file table
    80001078:	00003097          	auipc	ra,0x3
    8000107c:	4e8080e7          	jalr	1256(ra) # 80004560 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001080:	00005097          	auipc	ra,0x5
    80001084:	dd2080e7          	jalr	-558(ra) # 80005e52 <virtio_disk_init>
    userinit();      // first user process
    80001088:	00001097          	auipc	ra,0x1
    8000108c:	d06080e7          	jalr	-762(ra) # 80001d8e <userinit>
    __sync_synchronize();
    80001090:	0ff0000f          	fence
    started = 1;
    80001094:	4785                	li	a5,1
    80001096:	00008717          	auipc	a4,0x8
    8000109a:	f8f72123          	sw	a5,-126(a4) # 80009018 <started>
    8000109e:	b789                	j	80000fe0 <main+0x56>

00000000800010a0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010a0:	1141                	addi	sp,sp,-16
    800010a2:	e422                	sd	s0,8(sp)
    800010a4:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010a6:	00008797          	auipc	a5,0x8
    800010aa:	f7a7b783          	ld	a5,-134(a5) # 80009020 <kernel_pagetable>
    800010ae:	83b1                	srli	a5,a5,0xc
    800010b0:	577d                	li	a4,-1
    800010b2:	177e                	slli	a4,a4,0x3f
    800010b4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b6:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ba:	12000073          	sfence.vma
  sfence_vma();
}
    800010be:	6422                	ld	s0,8(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret

00000000800010c4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010c4:	7139                	addi	sp,sp,-64
    800010c6:	fc06                	sd	ra,56(sp)
    800010c8:	f822                	sd	s0,48(sp)
    800010ca:	f426                	sd	s1,40(sp)
    800010cc:	f04a                	sd	s2,32(sp)
    800010ce:	ec4e                	sd	s3,24(sp)
    800010d0:	e852                	sd	s4,16(sp)
    800010d2:	e456                	sd	s5,8(sp)
    800010d4:	e05a                	sd	s6,0(sp)
    800010d6:	0080                	addi	s0,sp,64
    800010d8:	84aa                	mv	s1,a0
    800010da:	89ae                	mv	s3,a1
    800010dc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010de:	57fd                	li	a5,-1
    800010e0:	83e9                	srli	a5,a5,0x1a
    800010e2:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010e4:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010e6:	04b7f263          	bgeu	a5,a1,8000112a <walk+0x66>
    panic("walk");
    800010ea:	00007517          	auipc	a0,0x7
    800010ee:	fe650513          	addi	a0,a0,-26 # 800080d0 <digits+0x90>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010fa:	060a8663          	beqz	s5,80001166 <walk+0xa2>
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	ae8080e7          	jalr	-1304(ra) # 80000be6 <kalloc>
    80001106:	84aa                	mv	s1,a0
    80001108:	c529                	beqz	a0,80001152 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000110a:	6605                	lui	a2,0x1
    8000110c:	4581                	li	a1,0
    8000110e:	00000097          	auipc	ra,0x0
    80001112:	cce080e7          	jalr	-818(ra) # 80000ddc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001116:	00c4d793          	srli	a5,s1,0xc
    8000111a:	07aa                	slli	a5,a5,0xa
    8000111c:	0017e793          	ori	a5,a5,1
    80001120:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001124:	3a5d                	addiw	s4,s4,-9
    80001126:	036a0063          	beq	s4,s6,80001146 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000112a:	0149d933          	srl	s2,s3,s4
    8000112e:	1ff97913          	andi	s2,s2,511
    80001132:	090e                	slli	s2,s2,0x3
    80001134:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001136:	00093483          	ld	s1,0(s2)
    8000113a:	0014f793          	andi	a5,s1,1
    8000113e:	dfd5                	beqz	a5,800010fa <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001140:	80a9                	srli	s1,s1,0xa
    80001142:	04b2                	slli	s1,s1,0xc
    80001144:	b7c5                	j	80001124 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001146:	00c9d513          	srli	a0,s3,0xc
    8000114a:	1ff57513          	andi	a0,a0,511
    8000114e:	050e                	slli	a0,a0,0x3
    80001150:	9526                	add	a0,a0,s1
}
    80001152:	70e2                	ld	ra,56(sp)
    80001154:	7442                	ld	s0,48(sp)
    80001156:	74a2                	ld	s1,40(sp)
    80001158:	7902                	ld	s2,32(sp)
    8000115a:	69e2                	ld	s3,24(sp)
    8000115c:	6a42                	ld	s4,16(sp)
    8000115e:	6aa2                	ld	s5,8(sp)
    80001160:	6b02                	ld	s6,0(sp)
    80001162:	6121                	addi	sp,sp,64
    80001164:	8082                	ret
        return 0;
    80001166:	4501                	li	a0,0
    80001168:	b7ed                	j	80001152 <walk+0x8e>

000000008000116a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000116a:	57fd                	li	a5,-1
    8000116c:	83e9                	srli	a5,a5,0x1a
    8000116e:	00b7f463          	bgeu	a5,a1,80001176 <walkaddr+0xc>
    return 0;
    80001172:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001174:	8082                	ret
{
    80001176:	1141                	addi	sp,sp,-16
    80001178:	e406                	sd	ra,8(sp)
    8000117a:	e022                	sd	s0,0(sp)
    8000117c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000117e:	4601                	li	a2,0
    80001180:	00000097          	auipc	ra,0x0
    80001184:	f44080e7          	jalr	-188(ra) # 800010c4 <walk>
  if(pte == 0)
    80001188:	c105                	beqz	a0,800011a8 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000118a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000118c:	0117f693          	andi	a3,a5,17
    80001190:	4745                	li	a4,17
    return 0;
    80001192:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001194:	00e68663          	beq	a3,a4,800011a0 <walkaddr+0x36>
}
    80001198:	60a2                	ld	ra,8(sp)
    8000119a:	6402                	ld	s0,0(sp)
    8000119c:	0141                	addi	sp,sp,16
    8000119e:	8082                	ret
  pa = PTE2PA(*pte);
    800011a0:	00a7d513          	srli	a0,a5,0xa
    800011a4:	0532                	slli	a0,a0,0xc
  return pa;
    800011a6:	bfcd                	j	80001198 <walkaddr+0x2e>
    return 0;
    800011a8:	4501                	li	a0,0
    800011aa:	b7fd                	j	80001198 <walkaddr+0x2e>

00000000800011ac <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ac:	715d                	addi	sp,sp,-80
    800011ae:	e486                	sd	ra,72(sp)
    800011b0:	e0a2                	sd	s0,64(sp)
    800011b2:	fc26                	sd	s1,56(sp)
    800011b4:	f84a                	sd	s2,48(sp)
    800011b6:	f44e                	sd	s3,40(sp)
    800011b8:	f052                	sd	s4,32(sp)
    800011ba:	ec56                	sd	s5,24(sp)
    800011bc:	e85a                	sd	s6,16(sp)
    800011be:	e45e                	sd	s7,8(sp)
    800011c0:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011c2:	c205                	beqz	a2,800011e2 <mappages+0x36>
    800011c4:	8aaa                	mv	s5,a0
    800011c6:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011c8:	77fd                	lui	a5,0xfffff
    800011ca:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011ce:	15fd                	addi	a1,a1,-1
    800011d0:	00c589b3          	add	s3,a1,a2
    800011d4:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011d8:	8952                	mv	s2,s4
    800011da:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011de:	6b85                	lui	s7,0x1
    800011e0:	a015                	j	80001204 <mappages+0x58>
    panic("mappages: size");
    800011e2:	00007517          	auipc	a0,0x7
    800011e6:	ef650513          	addi	a0,a0,-266 # 800080d8 <digits+0x98>
    800011ea:	fffff097          	auipc	ra,0xfffff
    800011ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011f2:	00007517          	auipc	a0,0x7
    800011f6:	ef650513          	addi	a0,a0,-266 # 800080e8 <digits+0xa8>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	344080e7          	jalr	836(ra) # 8000053e <panic>
    a += PGSIZE;
    80001202:	995e                	add	s2,s2,s7
  for(;;){
    80001204:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001208:	4605                	li	a2,1
    8000120a:	85ca                	mv	a1,s2
    8000120c:	8556                	mv	a0,s5
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	eb6080e7          	jalr	-330(ra) # 800010c4 <walk>
    80001216:	cd19                	beqz	a0,80001234 <mappages+0x88>
    if(*pte & PTE_V)
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	8b85                	andi	a5,a5,1
    8000121c:	fbf9                	bnez	a5,800011f2 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000121e:	80b1                	srli	s1,s1,0xc
    80001220:	04aa                	slli	s1,s1,0xa
    80001222:	0164e4b3          	or	s1,s1,s6
    80001226:	0014e493          	ori	s1,s1,1
    8000122a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000122c:	fd391be3          	bne	s2,s3,80001202 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001230:	4501                	li	a0,0
    80001232:	a011                	j	80001236 <mappages+0x8a>
      return -1;
    80001234:	557d                	li	a0,-1
}
    80001236:	60a6                	ld	ra,72(sp)
    80001238:	6406                	ld	s0,64(sp)
    8000123a:	74e2                	ld	s1,56(sp)
    8000123c:	7942                	ld	s2,48(sp)
    8000123e:	79a2                	ld	s3,40(sp)
    80001240:	7a02                	ld	s4,32(sp)
    80001242:	6ae2                	ld	s5,24(sp)
    80001244:	6b42                	ld	s6,16(sp)
    80001246:	6ba2                	ld	s7,8(sp)
    80001248:	6161                	addi	sp,sp,80
    8000124a:	8082                	ret

000000008000124c <kvmmap>:
{
    8000124c:	1141                	addi	sp,sp,-16
    8000124e:	e406                	sd	ra,8(sp)
    80001250:	e022                	sd	s0,0(sp)
    80001252:	0800                	addi	s0,sp,16
    80001254:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001256:	86b2                	mv	a3,a2
    80001258:	863e                	mv	a2,a5
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f52080e7          	jalr	-174(ra) # 800011ac <mappages>
    80001262:	e509                	bnez	a0,8000126c <kvmmap+0x20>
}
    80001264:	60a2                	ld	ra,8(sp)
    80001266:	6402                	ld	s0,0(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret
    panic("kvmmap");
    8000126c:	00007517          	auipc	a0,0x7
    80001270:	e8c50513          	addi	a0,a0,-372 # 800080f8 <digits+0xb8>
    80001274:	fffff097          	auipc	ra,0xfffff
    80001278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>

000000008000127c <kvmmake>:
{
    8000127c:	1101                	addi	sp,sp,-32
    8000127e:	ec06                	sd	ra,24(sp)
    80001280:	e822                	sd	s0,16(sp)
    80001282:	e426                	sd	s1,8(sp)
    80001284:	e04a                	sd	s2,0(sp)
    80001286:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	95e080e7          	jalr	-1698(ra) # 80000be6 <kalloc>
    80001290:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001292:	6605                	lui	a2,0x1
    80001294:	4581                	li	a1,0
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	b46080e7          	jalr	-1210(ra) # 80000ddc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000129e:	4719                	li	a4,6
    800012a0:	6685                	lui	a3,0x1
    800012a2:	10000637          	lui	a2,0x10000
    800012a6:	100005b7          	lui	a1,0x10000
    800012aa:	8526                	mv	a0,s1
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	fa0080e7          	jalr	-96(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b4:	4719                	li	a4,6
    800012b6:	6685                	lui	a3,0x1
    800012b8:	10001637          	lui	a2,0x10001
    800012bc:	100015b7          	lui	a1,0x10001
    800012c0:	8526                	mv	a0,s1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f8a080e7          	jalr	-118(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ca:	4719                	li	a4,6
    800012cc:	004006b7          	lui	a3,0x400
    800012d0:	0c000637          	lui	a2,0xc000
    800012d4:	0c0005b7          	lui	a1,0xc000
    800012d8:	8526                	mv	a0,s1
    800012da:	00000097          	auipc	ra,0x0
    800012de:	f72080e7          	jalr	-142(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e2:	00007917          	auipc	s2,0x7
    800012e6:	d1e90913          	addi	s2,s2,-738 # 80008000 <etext>
    800012ea:	4729                	li	a4,10
    800012ec:	80007697          	auipc	a3,0x80007
    800012f0:	d1468693          	addi	a3,a3,-748 # 8000 <_entry-0x7fff8000>
    800012f4:	4605                	li	a2,1
    800012f6:	067e                	slli	a2,a2,0x1f
    800012f8:	85b2                	mv	a1,a2
    800012fa:	8526                	mv	a0,s1
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f50080e7          	jalr	-176(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001304:	4719                	li	a4,6
    80001306:	46c5                	li	a3,17
    80001308:	06ee                	slli	a3,a3,0x1b
    8000130a:	412686b3          	sub	a3,a3,s2
    8000130e:	864a                	mv	a2,s2
    80001310:	85ca                	mv	a1,s2
    80001312:	8526                	mv	a0,s1
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f38080e7          	jalr	-200(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000131c:	4729                	li	a4,10
    8000131e:	6685                	lui	a3,0x1
    80001320:	00006617          	auipc	a2,0x6
    80001324:	ce060613          	addi	a2,a2,-800 # 80007000 <_trampoline>
    80001328:	040005b7          	lui	a1,0x4000
    8000132c:	15fd                	addi	a1,a1,-1
    8000132e:	05b2                	slli	a1,a1,0xc
    80001330:	8526                	mv	a0,s1
    80001332:	00000097          	auipc	ra,0x0
    80001336:	f1a080e7          	jalr	-230(ra) # 8000124c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	608080e7          	jalr	1544(ra) # 80001944 <proc_mapstacks>
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6902                	ld	s2,0(sp)
    8000134e:	6105                	addi	sp,sp,32
    80001350:	8082                	ret

0000000080001352 <kvminit>:
{
    80001352:	1141                	addi	sp,sp,-16
    80001354:	e406                	sd	ra,8(sp)
    80001356:	e022                	sd	s0,0(sp)
    80001358:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f22080e7          	jalr	-222(ra) # 8000127c <kvmmake>
    80001362:	00008797          	auipc	a5,0x8
    80001366:	caa7bf23          	sd	a0,-834(a5) # 80009020 <kernel_pagetable>
}
    8000136a:	60a2                	ld	ra,8(sp)
    8000136c:	6402                	ld	s0,0(sp)
    8000136e:	0141                	addi	sp,sp,16
    80001370:	8082                	ret

0000000080001372 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001372:	715d                	addi	sp,sp,-80
    80001374:	e486                	sd	ra,72(sp)
    80001376:	e0a2                	sd	s0,64(sp)
    80001378:	fc26                	sd	s1,56(sp)
    8000137a:	f84a                	sd	s2,48(sp)
    8000137c:	f44e                	sd	s3,40(sp)
    8000137e:	f052                	sd	s4,32(sp)
    80001380:	ec56                	sd	s5,24(sp)
    80001382:	e85a                	sd	s6,16(sp)
    80001384:	e45e                	sd	s7,8(sp)
    80001386:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001388:	03459793          	slli	a5,a1,0x34
    8000138c:	e795                	bnez	a5,800013b8 <uvmunmap+0x46>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	892e                	mv	s2,a1
    80001392:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001394:	0632                	slli	a2,a2,0xc
    80001396:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139c:	6b05                	lui	s6,0x1
    8000139e:	0735e863          	bltu	a1,s3,8000140e <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013a2:	60a6                	ld	ra,72(sp)
    800013a4:	6406                	ld	s0,64(sp)
    800013a6:	74e2                	ld	s1,56(sp)
    800013a8:	7942                	ld	s2,48(sp)
    800013aa:	79a2                	ld	s3,40(sp)
    800013ac:	7a02                	ld	s4,32(sp)
    800013ae:	6ae2                	ld	s5,24(sp)
    800013b0:	6b42                	ld	s6,16(sp)
    800013b2:	6ba2                	ld	s7,8(sp)
    800013b4:	6161                	addi	sp,sp,80
    800013b6:	8082                	ret
    panic("uvmunmap: not aligned");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d4850513          	addi	a0,a0,-696 # 80008100 <digits+0xc0>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d5050513          	addi	a0,a0,-688 # 80008118 <digits+0xd8>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d5050513          	addi	a0,a0,-688 # 80008128 <digits+0xe8>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	15e080e7          	jalr	350(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800013e8:	00007517          	auipc	a0,0x7
    800013ec:	d5850513          	addi	a0,a0,-680 # 80008140 <digits+0x100>
    800013f0:	fffff097          	auipc	ra,0xfffff
    800013f4:	14e080e7          	jalr	334(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800013f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013fa:	0532                	slli	a0,a0,0xc
    800013fc:	fffff097          	auipc	ra,0xfffff
    80001400:	660080e7          	jalr	1632(ra) # 80000a5c <kfree>
    *pte = 0;
    80001404:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001408:	995a                	add	s2,s2,s6
    8000140a:	f9397ce3          	bgeu	s2,s3,800013a2 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000140e:	4601                	li	a2,0
    80001410:	85ca                	mv	a1,s2
    80001412:	8552                	mv	a0,s4
    80001414:	00000097          	auipc	ra,0x0
    80001418:	cb0080e7          	jalr	-848(ra) # 800010c4 <walk>
    8000141c:	84aa                	mv	s1,a0
    8000141e:	d54d                	beqz	a0,800013c8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001420:	6108                	ld	a0,0(a0)
    80001422:	00157793          	andi	a5,a0,1
    80001426:	dbcd                	beqz	a5,800013d8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001428:	3ff57793          	andi	a5,a0,1023
    8000142c:	fb778ee3          	beq	a5,s7,800013e8 <uvmunmap+0x76>
    if(do_free){
    80001430:	fc0a8ae3          	beqz	s5,80001404 <uvmunmap+0x92>
    80001434:	b7d1                	j	800013f8 <uvmunmap+0x86>

0000000080001436 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001436:	1101                	addi	sp,sp,-32
    80001438:	ec06                	sd	ra,24(sp)
    8000143a:	e822                	sd	s0,16(sp)
    8000143c:	e426                	sd	s1,8(sp)
    8000143e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	7a6080e7          	jalr	1958(ra) # 80000be6 <kalloc>
    80001448:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000144a:	c519                	beqz	a0,80001458 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000144c:	6605                	lui	a2,0x1
    8000144e:	4581                	li	a1,0
    80001450:	00000097          	auipc	ra,0x0
    80001454:	98c080e7          	jalr	-1652(ra) # 80000ddc <memset>
  return pagetable;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret

0000000080001464 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001464:	7179                	addi	sp,sp,-48
    80001466:	f406                	sd	ra,40(sp)
    80001468:	f022                	sd	s0,32(sp)
    8000146a:	ec26                	sd	s1,24(sp)
    8000146c:	e84a                	sd	s2,16(sp)
    8000146e:	e44e                	sd	s3,8(sp)
    80001470:	e052                	sd	s4,0(sp)
    80001472:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001474:	6785                	lui	a5,0x1
    80001476:	04f67863          	bgeu	a2,a5,800014c6 <uvminit+0x62>
    8000147a:	8a2a                	mv	s4,a0
    8000147c:	89ae                	mv	s3,a1
    8000147e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	766080e7          	jalr	1894(ra) # 80000be6 <kalloc>
    80001488:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000148a:	6605                	lui	a2,0x1
    8000148c:	4581                	li	a1,0
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	94e080e7          	jalr	-1714(ra) # 80000ddc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001496:	4779                	li	a4,30
    80001498:	86ca                	mv	a3,s2
    8000149a:	6605                	lui	a2,0x1
    8000149c:	4581                	li	a1,0
    8000149e:	8552                	mv	a0,s4
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	d0c080e7          	jalr	-756(ra) # 800011ac <mappages>
  memmove(mem, src, sz);
    800014a8:	8626                	mv	a2,s1
    800014aa:	85ce                	mv	a1,s3
    800014ac:	854a                	mv	a0,s2
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	98e080e7          	jalr	-1650(ra) # 80000e3c <memmove>
}
    800014b6:	70a2                	ld	ra,40(sp)
    800014b8:	7402                	ld	s0,32(sp)
    800014ba:	64e2                	ld	s1,24(sp)
    800014bc:	6942                	ld	s2,16(sp)
    800014be:	69a2                	ld	s3,8(sp)
    800014c0:	6a02                	ld	s4,0(sp)
    800014c2:	6145                	addi	sp,sp,48
    800014c4:	8082                	ret
    panic("inituvm: more than a page");
    800014c6:	00007517          	auipc	a0,0x7
    800014ca:	c9250513          	addi	a0,a0,-878 # 80008158 <digits+0x118>
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	070080e7          	jalr	112(ra) # 8000053e <panic>

00000000800014d6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d6:	1101                	addi	sp,sp,-32
    800014d8:	ec06                	sd	ra,24(sp)
    800014da:	e822                	sd	s0,16(sp)
    800014dc:	e426                	sd	s1,8(sp)
    800014de:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014e0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014e2:	00b67d63          	bgeu	a2,a1,800014fc <uvmdealloc+0x26>
    800014e6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014e8:	6785                	lui	a5,0x1
    800014ea:	17fd                	addi	a5,a5,-1
    800014ec:	00f60733          	add	a4,a2,a5
    800014f0:	767d                	lui	a2,0xfffff
    800014f2:	8f71                	and	a4,a4,a2
    800014f4:	97ae                	add	a5,a5,a1
    800014f6:	8ff1                	and	a5,a5,a2
    800014f8:	00f76863          	bltu	a4,a5,80001508 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014fc:	8526                	mv	a0,s1
    800014fe:	60e2                	ld	ra,24(sp)
    80001500:	6442                	ld	s0,16(sp)
    80001502:	64a2                	ld	s1,8(sp)
    80001504:	6105                	addi	sp,sp,32
    80001506:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001508:	8f99                	sub	a5,a5,a4
    8000150a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000150c:	4685                	li	a3,1
    8000150e:	0007861b          	sext.w	a2,a5
    80001512:	85ba                	mv	a1,a4
    80001514:	00000097          	auipc	ra,0x0
    80001518:	e5e080e7          	jalr	-418(ra) # 80001372 <uvmunmap>
    8000151c:	b7c5                	j	800014fc <uvmdealloc+0x26>

000000008000151e <uvmalloc>:
  if(newsz < oldsz)
    8000151e:	0ab66163          	bltu	a2,a1,800015c0 <uvmalloc+0xa2>
{
    80001522:	7139                	addi	sp,sp,-64
    80001524:	fc06                	sd	ra,56(sp)
    80001526:	f822                	sd	s0,48(sp)
    80001528:	f426                	sd	s1,40(sp)
    8000152a:	f04a                	sd	s2,32(sp)
    8000152c:	ec4e                	sd	s3,24(sp)
    8000152e:	e852                	sd	s4,16(sp)
    80001530:	e456                	sd	s5,8(sp)
    80001532:	0080                	addi	s0,sp,64
    80001534:	8aaa                	mv	s5,a0
    80001536:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001538:	6985                	lui	s3,0x1
    8000153a:	19fd                	addi	s3,s3,-1
    8000153c:	95ce                	add	a1,a1,s3
    8000153e:	79fd                	lui	s3,0xfffff
    80001540:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001544:	08c9f063          	bgeu	s3,a2,800015c4 <uvmalloc+0xa6>
    80001548:	894e                	mv	s2,s3
    mem = kalloc();
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	69c080e7          	jalr	1692(ra) # 80000be6 <kalloc>
    80001552:	84aa                	mv	s1,a0
    if(mem == 0){
    80001554:	c51d                	beqz	a0,80001582 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001556:	6605                	lui	a2,0x1
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	882080e7          	jalr	-1918(ra) # 80000ddc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001562:	4779                	li	a4,30
    80001564:	86a6                	mv	a3,s1
    80001566:	6605                	lui	a2,0x1
    80001568:	85ca                	mv	a1,s2
    8000156a:	8556                	mv	a0,s5
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	c40080e7          	jalr	-960(ra) # 800011ac <mappages>
    80001574:	e905                	bnez	a0,800015a4 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	993e                	add	s2,s2,a5
    8000157a:	fd4968e3          	bltu	s2,s4,8000154a <uvmalloc+0x2c>
  return newsz;
    8000157e:	8552                	mv	a0,s4
    80001580:	a809                	j	80001592 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001582:	864e                	mv	a2,s3
    80001584:	85ca                	mv	a1,s2
    80001586:	8556                	mv	a0,s5
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f4e080e7          	jalr	-178(ra) # 800014d6 <uvmdealloc>
      return 0;
    80001590:	4501                	li	a0,0
}
    80001592:	70e2                	ld	ra,56(sp)
    80001594:	7442                	ld	s0,48(sp)
    80001596:	74a2                	ld	s1,40(sp)
    80001598:	7902                	ld	s2,32(sp)
    8000159a:	69e2                	ld	s3,24(sp)
    8000159c:	6a42                	ld	s4,16(sp)
    8000159e:	6aa2                	ld	s5,8(sp)
    800015a0:	6121                	addi	sp,sp,64
    800015a2:	8082                	ret
      kfree(mem);
    800015a4:	8526                	mv	a0,s1
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	4b6080e7          	jalr	1206(ra) # 80000a5c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015ae:	864e                	mv	a2,s3
    800015b0:	85ca                	mv	a1,s2
    800015b2:	8556                	mv	a0,s5
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f22080e7          	jalr	-222(ra) # 800014d6 <uvmdealloc>
      return 0;
    800015bc:	4501                	li	a0,0
    800015be:	bfd1                	j	80001592 <uvmalloc+0x74>
    return oldsz;
    800015c0:	852e                	mv	a0,a1
}
    800015c2:	8082                	ret
  return newsz;
    800015c4:	8532                	mv	a0,a2
    800015c6:	b7f1                	j	80001592 <uvmalloc+0x74>

00000000800015c8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015c8:	7179                	addi	sp,sp,-48
    800015ca:	f406                	sd	ra,40(sp)
    800015cc:	f022                	sd	s0,32(sp)
    800015ce:	ec26                	sd	s1,24(sp)
    800015d0:	e84a                	sd	s2,16(sp)
    800015d2:	e44e                	sd	s3,8(sp)
    800015d4:	e052                	sd	s4,0(sp)
    800015d6:	1800                	addi	s0,sp,48
    800015d8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015da:	84aa                	mv	s1,a0
    800015dc:	6905                	lui	s2,0x1
    800015de:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e0:	4985                	li	s3,1
    800015e2:	a821                	j	800015fa <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e6:	0532                	slli	a0,a0,0xc
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	fe0080e7          	jalr	-32(ra) # 800015c8 <freewalk>
      pagetable[i] = 0;
    800015f0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015f4:	04a1                	addi	s1,s1,8
    800015f6:	03248163          	beq	s1,s2,80001618 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015fa:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015fc:	00f57793          	andi	a5,a0,15
    80001600:	ff3782e3          	beq	a5,s3,800015e4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001604:	8905                	andi	a0,a0,1
    80001606:	d57d                	beqz	a0,800015f4 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001608:	00007517          	auipc	a0,0x7
    8000160c:	b7050513          	addi	a0,a0,-1168 # 80008178 <digits+0x138>
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001618:	8552                	mv	a0,s4
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	442080e7          	jalr	1090(ra) # 80000a5c <kfree>
}
    80001622:	70a2                	ld	ra,40(sp)
    80001624:	7402                	ld	s0,32(sp)
    80001626:	64e2                	ld	s1,24(sp)
    80001628:	6942                	ld	s2,16(sp)
    8000162a:	69a2                	ld	s3,8(sp)
    8000162c:	6a02                	ld	s4,0(sp)
    8000162e:	6145                	addi	sp,sp,48
    80001630:	8082                	ret

0000000080001632 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001632:	1101                	addi	sp,sp,-32
    80001634:	ec06                	sd	ra,24(sp)
    80001636:	e822                	sd	s0,16(sp)
    80001638:	e426                	sd	s1,8(sp)
    8000163a:	1000                	addi	s0,sp,32
    8000163c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000163e:	e999                	bnez	a1,80001654 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001640:	8526                	mv	a0,s1
    80001642:	00000097          	auipc	ra,0x0
    80001646:	f86080e7          	jalr	-122(ra) # 800015c8 <freewalk>
}
    8000164a:	60e2                	ld	ra,24(sp)
    8000164c:	6442                	ld	s0,16(sp)
    8000164e:	64a2                	ld	s1,8(sp)
    80001650:	6105                	addi	sp,sp,32
    80001652:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001654:	6605                	lui	a2,0x1
    80001656:	167d                	addi	a2,a2,-1
    80001658:	962e                	add	a2,a2,a1
    8000165a:	4685                	li	a3,1
    8000165c:	8231                	srli	a2,a2,0xc
    8000165e:	4581                	li	a1,0
    80001660:	00000097          	auipc	ra,0x0
    80001664:	d12080e7          	jalr	-750(ra) # 80001372 <uvmunmap>
    80001668:	bfe1                	j	80001640 <uvmfree+0xe>

000000008000166a <uvmcopy>:
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;

  for(i = 0; i < sz; i += PGSIZE){
    8000166a:	c271                	beqz	a2,8000172e <uvmcopy+0xc4>
{
    8000166c:	7139                	addi	sp,sp,-64
    8000166e:	fc06                	sd	ra,56(sp)
    80001670:	f822                	sd	s0,48(sp)
    80001672:	f426                	sd	s1,40(sp)
    80001674:	f04a                	sd	s2,32(sp)
    80001676:	ec4e                	sd	s3,24(sp)
    80001678:	e852                	sd	s4,16(sp)
    8000167a:	e456                	sd	s5,8(sp)
    8000167c:	0080                	addi	s0,sp,64
    8000167e:	8aaa                	mv	s5,a0
    80001680:	8a2e                	mv	s4,a1
    80001682:	89b2                	mv	s3,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001684:	4481                	li	s1,0
    80001686:	a0b9                	j	800016d4 <uvmcopy+0x6a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001688:	00007517          	auipc	a0,0x7
    8000168c:	b0050513          	addi	a0,a0,-1280 # 80008188 <digits+0x148>
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	eae080e7          	jalr	-338(ra) # 8000053e <panic>
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    80001698:	00007517          	auipc	a0,0x7
    8000169c:	b1050513          	addi	a0,a0,-1264 # 800081a8 <digits+0x168>
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	e9e080e7          	jalr	-354(ra) # 8000053e <panic>
    pa = PTE2PA(*pte);

    if(*pte & PTE_W)
      *pte = (((*pte) & (~PTE_W)) | PTE_COW); // change parent's page to be unwritable
    
    if(mappages(new, i, PGSIZE, (uint64)pa, (uint)PTE_FLAGS(*pte)) < 0){ // msp child's page with unwritable page
    800016a8:	6118                	ld	a4,0(a0)
    800016aa:	3ff77713          	andi	a4,a4,1023
    800016ae:	86ca                	mv	a3,s2
    800016b0:	6605                	lui	a2,0x1
    800016b2:	85a6                	mv	a1,s1
    800016b4:	8552                	mv	a0,s4
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	af6080e7          	jalr	-1290(ra) # 800011ac <mappages>
    800016be:	04054363          	bltz	a0,80001704 <uvmcopy+0x9a>
      goto err;
    }
    increase_reference(pa);
    800016c2:	854a                	mv	a0,s2
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	4d2080e7          	jalr	1234(ra) # 80000b96 <increase_reference>
  for(i = 0; i < sz; i += PGSIZE){
    800016cc:	6785                	lui	a5,0x1
    800016ce:	94be                	add	s1,s1,a5
    800016d0:	0534fd63          	bgeu	s1,s3,8000172a <uvmcopy+0xc0>
    if((pte = walk(old, i, 0)) == 0)
    800016d4:	4601                	li	a2,0
    800016d6:	85a6                	mv	a1,s1
    800016d8:	8556                	mv	a0,s5
    800016da:	00000097          	auipc	ra,0x0
    800016de:	9ea080e7          	jalr	-1558(ra) # 800010c4 <walk>
    800016e2:	d15d                	beqz	a0,80001688 <uvmcopy+0x1e>
    if((*pte & PTE_V) == 0)
    800016e4:	611c                	ld	a5,0(a0)
    800016e6:	0017f713          	andi	a4,a5,1
    800016ea:	d75d                	beqz	a4,80001698 <uvmcopy+0x2e>
    pa = PTE2PA(*pte);
    800016ec:	00a7d913          	srli	s2,a5,0xa
    800016f0:	0932                	slli	s2,s2,0xc
    if(*pte & PTE_W)
    800016f2:	0047f713          	andi	a4,a5,4
    800016f6:	db4d                	beqz	a4,800016a8 <uvmcopy+0x3e>
      *pte = (((*pte) & (~PTE_W)) | PTE_COW); // change parent's page to be unwritable
    800016f8:	dfb7f793          	andi	a5,a5,-517
    800016fc:	2007e793          	ori	a5,a5,512
    80001700:	e11c                	sd	a5,0(a0)
    80001702:	b75d                	j	800016a8 <uvmcopy+0x3e>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001704:	4685                	li	a3,1
    80001706:	00c4d613          	srli	a2,s1,0xc
    8000170a:	4581                	li	a1,0
    8000170c:	8552                	mv	a0,s4
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	c64080e7          	jalr	-924(ra) # 80001372 <uvmunmap>
  return -1;
    80001716:	557d                	li	a0,-1
}
    80001718:	70e2                	ld	ra,56(sp)
    8000171a:	7442                	ld	s0,48(sp)
    8000171c:	74a2                	ld	s1,40(sp)
    8000171e:	7902                	ld	s2,32(sp)
    80001720:	69e2                	ld	s3,24(sp)
    80001722:	6a42                	ld	s4,16(sp)
    80001724:	6aa2                	ld	s5,8(sp)
    80001726:	6121                	addi	sp,sp,64
    80001728:	8082                	ret
  return 0;
    8000172a:	4501                	li	a0,0
    8000172c:	b7f5                	j	80001718 <uvmcopy+0xae>
    8000172e:	4501                	li	a0,0
}
    80001730:	8082                	ret

0000000080001732 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001732:	1141                	addi	sp,sp,-16
    80001734:	e406                	sd	ra,8(sp)
    80001736:	e022                	sd	s0,0(sp)
    80001738:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000173a:	4601                	li	a2,0
    8000173c:	00000097          	auipc	ra,0x0
    80001740:	988080e7          	jalr	-1656(ra) # 800010c4 <walk>
  if(pte == 0)
    80001744:	c901                	beqz	a0,80001754 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001746:	611c                	ld	a5,0(a0)
    80001748:	9bbd                	andi	a5,a5,-17
    8000174a:	e11c                	sd	a5,0(a0)
}
    8000174c:	60a2                	ld	ra,8(sp)
    8000174e:	6402                	ld	s0,0(sp)
    80001750:	0141                	addi	sp,sp,16
    80001752:	8082                	ret
    panic("uvmclear");
    80001754:	00007517          	auipc	a0,0x7
    80001758:	a7450513          	addi	a0,a0,-1420 # 800081c8 <digits+0x188>
    8000175c:	fffff097          	auipc	ra,0xfffff
    80001760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>

0000000080001764 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001764:	cebd                	beqz	a3,800017e2 <copyout+0x7e>
{
    80001766:	715d                	addi	sp,sp,-80
    80001768:	e486                	sd	ra,72(sp)
    8000176a:	e0a2                	sd	s0,64(sp)
    8000176c:	fc26                	sd	s1,56(sp)
    8000176e:	f84a                	sd	s2,48(sp)
    80001770:	f44e                	sd	s3,40(sp)
    80001772:	f052                	sd	s4,32(sp)
    80001774:	ec56                	sd	s5,24(sp)
    80001776:	e85a                	sd	s6,16(sp)
    80001778:	e45e                	sd	s7,8(sp)
    8000177a:	e062                	sd	s8,0(sp)
    8000177c:	0880                	addi	s0,sp,80
    8000177e:	8b2a                	mv	s6,a0
    80001780:	892e                	mv	s2,a1
    80001782:	8ab2                	mv	s5,a2
    80001784:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001786:	7c7d                	lui	s8,0xfffff
      return -1;

    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001788:	6b85                	lui	s7,0x1
    8000178a:	a015                	j	800017ae <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000178c:	41390933          	sub	s2,s2,s3
    80001790:	0004861b          	sext.w	a2,s1
    80001794:	85d6                	mv	a1,s5
    80001796:	954a                	add	a0,a0,s2
    80001798:	fffff097          	auipc	ra,0xfffff
    8000179c:	6a4080e7          	jalr	1700(ra) # 80000e3c <memmove>

    len -= n;
    800017a0:	409a0a33          	sub	s4,s4,s1
    src += n;
    800017a4:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    800017a6:	01798933          	add	s2,s3,s7
  while(len > 0){
    800017aa:	020a0a63          	beqz	s4,800017de <copyout+0x7a>
    va0 = PGROUNDDOWN(dstva);
    800017ae:	018979b3          	and	s3,s2,s8
    if(cow(pagetable, va0) < 0) // return -1 if the cow failed
    800017b2:	85ce                	mv	a1,s3
    800017b4:	855a                	mv	a0,s6
    800017b6:	00001097          	auipc	ra,0x1
    800017ba:	1b6080e7          	jalr	438(ra) # 8000296c <cow>
    800017be:	02054463          	bltz	a0,800017e6 <copyout+0x82>
    pa0 = walkaddr(pagetable, va0);
    800017c2:	85ce                	mv	a1,s3
    800017c4:	855a                	mv	a0,s6
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	9a4080e7          	jalr	-1628(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    800017ce:	c90d                	beqz	a0,80001800 <copyout+0x9c>
    n = PGSIZE - (dstva - va0);
    800017d0:	412984b3          	sub	s1,s3,s2
    800017d4:	94de                	add	s1,s1,s7
    if(n > len)
    800017d6:	fa9a7be3          	bgeu	s4,s1,8000178c <copyout+0x28>
    800017da:	84d2                	mv	s1,s4
    800017dc:	bf45                	j	8000178c <copyout+0x28>
  }
  return 0;
    800017de:	4501                	li	a0,0
    800017e0:	a021                	j	800017e8 <copyout+0x84>
    800017e2:	4501                	li	a0,0
}
    800017e4:	8082                	ret
      return -1;
    800017e6:	557d                	li	a0,-1
}
    800017e8:	60a6                	ld	ra,72(sp)
    800017ea:	6406                	ld	s0,64(sp)
    800017ec:	74e2                	ld	s1,56(sp)
    800017ee:	7942                	ld	s2,48(sp)
    800017f0:	79a2                	ld	s3,40(sp)
    800017f2:	7a02                	ld	s4,32(sp)
    800017f4:	6ae2                	ld	s5,24(sp)
    800017f6:	6b42                	ld	s6,16(sp)
    800017f8:	6ba2                	ld	s7,8(sp)
    800017fa:	6c02                	ld	s8,0(sp)
    800017fc:	6161                	addi	sp,sp,80
    800017fe:	8082                	ret
      return -1;
    80001800:	557d                	li	a0,-1
    80001802:	b7dd                	j	800017e8 <copyout+0x84>

0000000080001804 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001804:	c6bd                	beqz	a3,80001872 <copyin+0x6e>
{
    80001806:	715d                	addi	sp,sp,-80
    80001808:	e486                	sd	ra,72(sp)
    8000180a:	e0a2                	sd	s0,64(sp)
    8000180c:	fc26                	sd	s1,56(sp)
    8000180e:	f84a                	sd	s2,48(sp)
    80001810:	f44e                	sd	s3,40(sp)
    80001812:	f052                	sd	s4,32(sp)
    80001814:	ec56                	sd	s5,24(sp)
    80001816:	e85a                	sd	s6,16(sp)
    80001818:	e45e                	sd	s7,8(sp)
    8000181a:	e062                	sd	s8,0(sp)
    8000181c:	0880                	addi	s0,sp,80
    8000181e:	8b2a                	mv	s6,a0
    80001820:	8a2e                	mv	s4,a1
    80001822:	8c32                	mv	s8,a2
    80001824:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001826:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001828:	6a85                	lui	s5,0x1
    8000182a:	a015                	j	8000184e <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000182c:	9562                	add	a0,a0,s8
    8000182e:	0004861b          	sext.w	a2,s1
    80001832:	412505b3          	sub	a1,a0,s2
    80001836:	8552                	mv	a0,s4
    80001838:	fffff097          	auipc	ra,0xfffff
    8000183c:	604080e7          	jalr	1540(ra) # 80000e3c <memmove>

    len -= n;
    80001840:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001844:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001846:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000184a:	02098263          	beqz	s3,8000186e <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000184e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001852:	85ca                	mv	a1,s2
    80001854:	855a                	mv	a0,s6
    80001856:	00000097          	auipc	ra,0x0
    8000185a:	914080e7          	jalr	-1772(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    8000185e:	cd01                	beqz	a0,80001876 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001860:	418904b3          	sub	s1,s2,s8
    80001864:	94d6                	add	s1,s1,s5
    if(n > len)
    80001866:	fc99f3e3          	bgeu	s3,s1,8000182c <copyin+0x28>
    8000186a:	84ce                	mv	s1,s3
    8000186c:	b7c1                	j	8000182c <copyin+0x28>
  }
  return 0;
    8000186e:	4501                	li	a0,0
    80001870:	a021                	j	80001878 <copyin+0x74>
    80001872:	4501                	li	a0,0
}
    80001874:	8082                	ret
      return -1;
    80001876:	557d                	li	a0,-1
}
    80001878:	60a6                	ld	ra,72(sp)
    8000187a:	6406                	ld	s0,64(sp)
    8000187c:	74e2                	ld	s1,56(sp)
    8000187e:	7942                	ld	s2,48(sp)
    80001880:	79a2                	ld	s3,40(sp)
    80001882:	7a02                	ld	s4,32(sp)
    80001884:	6ae2                	ld	s5,24(sp)
    80001886:	6b42                	ld	s6,16(sp)
    80001888:	6ba2                	ld	s7,8(sp)
    8000188a:	6c02                	ld	s8,0(sp)
    8000188c:	6161                	addi	sp,sp,80
    8000188e:	8082                	ret

0000000080001890 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001890:	c6c5                	beqz	a3,80001938 <copyinstr+0xa8>
{
    80001892:	715d                	addi	sp,sp,-80
    80001894:	e486                	sd	ra,72(sp)
    80001896:	e0a2                	sd	s0,64(sp)
    80001898:	fc26                	sd	s1,56(sp)
    8000189a:	f84a                	sd	s2,48(sp)
    8000189c:	f44e                	sd	s3,40(sp)
    8000189e:	f052                	sd	s4,32(sp)
    800018a0:	ec56                	sd	s5,24(sp)
    800018a2:	e85a                	sd	s6,16(sp)
    800018a4:	e45e                	sd	s7,8(sp)
    800018a6:	0880                	addi	s0,sp,80
    800018a8:	8a2a                	mv	s4,a0
    800018aa:	8b2e                	mv	s6,a1
    800018ac:	8bb2                	mv	s7,a2
    800018ae:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018b0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018b2:	6985                	lui	s3,0x1
    800018b4:	a035                	j	800018e0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018b6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018ba:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018bc:	0017b793          	seqz	a5,a5
    800018c0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018c4:	60a6                	ld	ra,72(sp)
    800018c6:	6406                	ld	s0,64(sp)
    800018c8:	74e2                	ld	s1,56(sp)
    800018ca:	7942                	ld	s2,48(sp)
    800018cc:	79a2                	ld	s3,40(sp)
    800018ce:	7a02                	ld	s4,32(sp)
    800018d0:	6ae2                	ld	s5,24(sp)
    800018d2:	6b42                	ld	s6,16(sp)
    800018d4:	6ba2                	ld	s7,8(sp)
    800018d6:	6161                	addi	sp,sp,80
    800018d8:	8082                	ret
    srcva = va0 + PGSIZE;
    800018da:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018de:	c8a9                	beqz	s1,80001930 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018e0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018e4:	85ca                	mv	a1,s2
    800018e6:	8552                	mv	a0,s4
    800018e8:	00000097          	auipc	ra,0x0
    800018ec:	882080e7          	jalr	-1918(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    800018f0:	c131                	beqz	a0,80001934 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018f2:	41790833          	sub	a6,s2,s7
    800018f6:	984e                	add	a6,a6,s3
    if(n > max)
    800018f8:	0104f363          	bgeu	s1,a6,800018fe <copyinstr+0x6e>
    800018fc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018fe:	955e                	add	a0,a0,s7
    80001900:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001904:	fc080be3          	beqz	a6,800018da <copyinstr+0x4a>
    80001908:	985a                	add	a6,a6,s6
    8000190a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000190c:	41650633          	sub	a2,a0,s6
    80001910:	14fd                	addi	s1,s1,-1
    80001912:	9b26                	add	s6,s6,s1
    80001914:	00f60733          	add	a4,a2,a5
    80001918:	00074703          	lbu	a4,0(a4)
    8000191c:	df49                	beqz	a4,800018b6 <copyinstr+0x26>
        *dst = *p;
    8000191e:	00e78023          	sb	a4,0(a5)
      --max;
    80001922:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001926:	0785                	addi	a5,a5,1
    while(n > 0){
    80001928:	ff0796e3          	bne	a5,a6,80001914 <copyinstr+0x84>
      dst++;
    8000192c:	8b42                	mv	s6,a6
    8000192e:	b775                	j	800018da <copyinstr+0x4a>
    80001930:	4781                	li	a5,0
    80001932:	b769                	j	800018bc <copyinstr+0x2c>
      return -1;
    80001934:	557d                	li	a0,-1
    80001936:	b779                	j	800018c4 <copyinstr+0x34>
  int got_null = 0;
    80001938:	4781                	li	a5,0
  if(got_null){
    8000193a:	0017b793          	seqz	a5,a5
    8000193e:	40f00533          	neg	a0,a5
}
    80001942:	8082                	ret

0000000080001944 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
    80001958:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00030497          	auipc	s1,0x30
    8000195e:	d7648493          	addi	s1,s1,-650 # 800316d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001962:	8b26                	mv	s6,s1
    80001964:	00006a97          	auipc	s5,0x6
    80001968:	69ca8a93          	addi	s5,s5,1692 # 80008000 <etext>
    8000196c:	04000937          	lui	s2,0x4000
    80001970:	197d                	addi	s2,s2,-1
    80001972:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001974:	00035a17          	auipc	s4,0x35
    80001978:	75ca0a13          	addi	s4,s4,1884 # 800370d0 <tickslock>
    char *pa = kalloc();
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	26a080e7          	jalr	618(ra) # 80000be6 <kalloc>
    80001984:	862a                	mv	a2,a0
    if(pa == 0)
    80001986:	c131                	beqz	a0,800019ca <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001988:	416485b3          	sub	a1,s1,s6
    8000198c:	858d                	srai	a1,a1,0x3
    8000198e:	000ab783          	ld	a5,0(s5)
    80001992:	02f585b3          	mul	a1,a1,a5
    80001996:	2585                	addiw	a1,a1,1
    80001998:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000199c:	4719                	li	a4,6
    8000199e:	6685                	lui	a3,0x1
    800019a0:	40b905b3          	sub	a1,s2,a1
    800019a4:	854e                	mv	a0,s3
    800019a6:	00000097          	auipc	ra,0x0
    800019aa:	8a6080e7          	jalr	-1882(ra) # 8000124c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ae:	16848493          	addi	s1,s1,360
    800019b2:	fd4495e3          	bne	s1,s4,8000197c <proc_mapstacks+0x38>
  }
}
    800019b6:	70e2                	ld	ra,56(sp)
    800019b8:	7442                	ld	s0,48(sp)
    800019ba:	74a2                	ld	s1,40(sp)
    800019bc:	7902                	ld	s2,32(sp)
    800019be:	69e2                	ld	s3,24(sp)
    800019c0:	6a42                	ld	s4,16(sp)
    800019c2:	6aa2                	ld	s5,8(sp)
    800019c4:	6b02                	ld	s6,0(sp)
    800019c6:	6121                	addi	sp,sp,64
    800019c8:	8082                	ret
      panic("kalloc");
    800019ca:	00007517          	auipc	a0,0x7
    800019ce:	80e50513          	addi	a0,a0,-2034 # 800081d8 <digits+0x198>
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	b6c080e7          	jalr	-1172(ra) # 8000053e <panic>

00000000800019da <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019da:	7139                	addi	sp,sp,-64
    800019dc:	fc06                	sd	ra,56(sp)
    800019de:	f822                	sd	s0,48(sp)
    800019e0:	f426                	sd	s1,40(sp)
    800019e2:	f04a                	sd	s2,32(sp)
    800019e4:	ec4e                	sd	s3,24(sp)
    800019e6:	e852                	sd	s4,16(sp)
    800019e8:	e456                	sd	s5,8(sp)
    800019ea:	e05a                	sd	s6,0(sp)
    800019ec:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019ee:	00006597          	auipc	a1,0x6
    800019f2:	7f258593          	addi	a1,a1,2034 # 800081e0 <digits+0x1a0>
    800019f6:	00030517          	auipc	a0,0x30
    800019fa:	8aa50513          	addi	a0,a0,-1878 # 800312a0 <pid_lock>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	252080e7          	jalr	594(ra) # 80000c50 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a06:	00006597          	auipc	a1,0x6
    80001a0a:	7e258593          	addi	a1,a1,2018 # 800081e8 <digits+0x1a8>
    80001a0e:	00030517          	auipc	a0,0x30
    80001a12:	8aa50513          	addi	a0,a0,-1878 # 800312b8 <wait_lock>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	23a080e7          	jalr	570(ra) # 80000c50 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a1e:	00030497          	auipc	s1,0x30
    80001a22:	cb248493          	addi	s1,s1,-846 # 800316d0 <proc>
      initlock(&p->lock, "proc");
    80001a26:	00006b17          	auipc	s6,0x6
    80001a2a:	7d2b0b13          	addi	s6,s6,2002 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001a2e:	8aa6                	mv	s5,s1
    80001a30:	00006a17          	auipc	s4,0x6
    80001a34:	5d0a0a13          	addi	s4,s4,1488 # 80008000 <etext>
    80001a38:	04000937          	lui	s2,0x4000
    80001a3c:	197d                	addi	s2,s2,-1
    80001a3e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a40:	00035997          	auipc	s3,0x35
    80001a44:	69098993          	addi	s3,s3,1680 # 800370d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a48:	85da                	mv	a1,s6
    80001a4a:	8526                	mv	a0,s1
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	204080e7          	jalr	516(ra) # 80000c50 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a54:	415487b3          	sub	a5,s1,s5
    80001a58:	878d                	srai	a5,a5,0x3
    80001a5a:	000a3703          	ld	a4,0(s4)
    80001a5e:	02e787b3          	mul	a5,a5,a4
    80001a62:	2785                	addiw	a5,a5,1
    80001a64:	00d7979b          	slliw	a5,a5,0xd
    80001a68:	40f907b3          	sub	a5,s2,a5
    80001a6c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6e:	16848493          	addi	s1,s1,360
    80001a72:	fd349be3          	bne	s1,s3,80001a48 <procinit+0x6e>
  }
}
    80001a76:	70e2                	ld	ra,56(sp)
    80001a78:	7442                	ld	s0,48(sp)
    80001a7a:	74a2                	ld	s1,40(sp)
    80001a7c:	7902                	ld	s2,32(sp)
    80001a7e:	69e2                	ld	s3,24(sp)
    80001a80:	6a42                	ld	s4,16(sp)
    80001a82:	6aa2                	ld	s5,8(sp)
    80001a84:	6b02                	ld	s6,0(sp)
    80001a86:	6121                	addi	sp,sp,64
    80001a88:	8082                	ret

0000000080001a8a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a8a:	1141                	addi	sp,sp,-16
    80001a8c:	e422                	sd	s0,8(sp)
    80001a8e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a90:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a92:	2501                	sext.w	a0,a0
    80001a94:	6422                	ld	s0,8(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret

0000000080001a9a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a9a:	1141                	addi	sp,sp,-16
    80001a9c:	e422                	sd	s0,8(sp)
    80001a9e:	0800                	addi	s0,sp,16
    80001aa0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aa2:	2781                	sext.w	a5,a5
    80001aa4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aa6:	00030517          	auipc	a0,0x30
    80001aaa:	82a50513          	addi	a0,a0,-2006 # 800312d0 <cpus>
    80001aae:	953e                	add	a0,a0,a5
    80001ab0:	6422                	ld	s0,8(sp)
    80001ab2:	0141                	addi	sp,sp,16
    80001ab4:	8082                	ret

0000000080001ab6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ab6:	1101                	addi	sp,sp,-32
    80001ab8:	ec06                	sd	ra,24(sp)
    80001aba:	e822                	sd	s0,16(sp)
    80001abc:	e426                	sd	s1,8(sp)
    80001abe:	1000                	addi	s0,sp,32
  push_off();
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	1d4080e7          	jalr	468(ra) # 80000c94 <push_off>
    80001ac8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aca:	2781                	sext.w	a5,a5
    80001acc:	079e                	slli	a5,a5,0x7
    80001ace:	0002f717          	auipc	a4,0x2f
    80001ad2:	7d270713          	addi	a4,a4,2002 # 800312a0 <pid_lock>
    80001ad6:	97ba                	add	a5,a5,a4
    80001ad8:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	25a080e7          	jalr	602(ra) # 80000d34 <pop_off>
  return p;
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6105                	addi	sp,sp,32
    80001aec:	8082                	ret

0000000080001aee <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001aee:	1141                	addi	sp,sp,-16
    80001af0:	e406                	sd	ra,8(sp)
    80001af2:	e022                	sd	s0,0(sp)
    80001af4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	fc0080e7          	jalr	-64(ra) # 80001ab6 <myproc>
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	296080e7          	jalr	662(ra) # 80000d94 <release>

  if (first) {
    80001b06:	00007797          	auipc	a5,0x7
    80001b0a:	d0a7a783          	lw	a5,-758(a5) # 80008810 <first.1685>
    80001b0e:	eb89                	bnez	a5,80001b20 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b10:	00001097          	auipc	ra,0x1
    80001b14:	c0a080e7          	jalr	-1014(ra) # 8000271a <usertrapret>
}
    80001b18:	60a2                	ld	ra,8(sp)
    80001b1a:	6402                	ld	s0,0(sp)
    80001b1c:	0141                	addi	sp,sp,16
    80001b1e:	8082                	ret
    first = 0;
    80001b20:	00007797          	auipc	a5,0x7
    80001b24:	ce07a823          	sw	zero,-784(a5) # 80008810 <first.1685>
    fsinit(ROOTDEV);
    80001b28:	4505                	li	a0,1
    80001b2a:	00002097          	auipc	ra,0x2
    80001b2e:	a04080e7          	jalr	-1532(ra) # 8000352e <fsinit>
    80001b32:	bff9                	j	80001b10 <forkret+0x22>

0000000080001b34 <allocpid>:
allocpid() {
    80001b34:	1101                	addi	sp,sp,-32
    80001b36:	ec06                	sd	ra,24(sp)
    80001b38:	e822                	sd	s0,16(sp)
    80001b3a:	e426                	sd	s1,8(sp)
    80001b3c:	e04a                	sd	s2,0(sp)
    80001b3e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b40:	0002f917          	auipc	s2,0x2f
    80001b44:	76090913          	addi	s2,s2,1888 # 800312a0 <pid_lock>
    80001b48:	854a                	mv	a0,s2
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	196080e7          	jalr	406(ra) # 80000ce0 <acquire>
  pid = nextpid;
    80001b52:	00007797          	auipc	a5,0x7
    80001b56:	cc278793          	addi	a5,a5,-830 # 80008814 <nextpid>
    80001b5a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b5c:	0014871b          	addiw	a4,s1,1
    80001b60:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b62:	854a                	mv	a0,s2
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	230080e7          	jalr	560(ra) # 80000d94 <release>
}
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	60e2                	ld	ra,24(sp)
    80001b70:	6442                	ld	s0,16(sp)
    80001b72:	64a2                	ld	s1,8(sp)
    80001b74:	6902                	ld	s2,0(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret

0000000080001b7a <proc_pagetable>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	e04a                	sd	s2,0(sp)
    80001b84:	1000                	addi	s0,sp,32
    80001b86:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b88:	00000097          	auipc	ra,0x0
    80001b8c:	8ae080e7          	jalr	-1874(ra) # 80001436 <uvmcreate>
    80001b90:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b92:	c121                	beqz	a0,80001bd2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b94:	4729                	li	a4,10
    80001b96:	00005697          	auipc	a3,0x5
    80001b9a:	46a68693          	addi	a3,a3,1130 # 80007000 <_trampoline>
    80001b9e:	6605                	lui	a2,0x1
    80001ba0:	040005b7          	lui	a1,0x4000
    80001ba4:	15fd                	addi	a1,a1,-1
    80001ba6:	05b2                	slli	a1,a1,0xc
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	604080e7          	jalr	1540(ra) # 800011ac <mappages>
    80001bb0:	02054863          	bltz	a0,80001be0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bb4:	4719                	li	a4,6
    80001bb6:	05893683          	ld	a3,88(s2)
    80001bba:	6605                	lui	a2,0x1
    80001bbc:	020005b7          	lui	a1,0x2000
    80001bc0:	15fd                	addi	a1,a1,-1
    80001bc2:	05b6                	slli	a1,a1,0xd
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	5e6080e7          	jalr	1510(ra) # 800011ac <mappages>
    80001bce:	02054163          	bltz	a0,80001bf0 <proc_pagetable+0x76>
}
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6902                	ld	s2,0(sp)
    80001bdc:	6105                	addi	sp,sp,32
    80001bde:	8082                	ret
    uvmfree(pagetable, 0);
    80001be0:	4581                	li	a1,0
    80001be2:	8526                	mv	a0,s1
    80001be4:	00000097          	auipc	ra,0x0
    80001be8:	a4e080e7          	jalr	-1458(ra) # 80001632 <uvmfree>
    return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	b7d5                	j	80001bd2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf0:	4681                	li	a3,0
    80001bf2:	4605                	li	a2,1
    80001bf4:	040005b7          	lui	a1,0x4000
    80001bf8:	15fd                	addi	a1,a1,-1
    80001bfa:	05b2                	slli	a1,a1,0xc
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	774080e7          	jalr	1908(ra) # 80001372 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c06:	4581                	li	a1,0
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	a28080e7          	jalr	-1496(ra) # 80001632 <uvmfree>
    return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	bf7d                	j	80001bd2 <proc_pagetable+0x58>

0000000080001c16 <proc_freepagetable>:
{
    80001c16:	1101                	addi	sp,sp,-32
    80001c18:	ec06                	sd	ra,24(sp)
    80001c1a:	e822                	sd	s0,16(sp)
    80001c1c:	e426                	sd	s1,8(sp)
    80001c1e:	e04a                	sd	s2,0(sp)
    80001c20:	1000                	addi	s0,sp,32
    80001c22:	84aa                	mv	s1,a0
    80001c24:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c26:	4681                	li	a3,0
    80001c28:	4605                	li	a2,1
    80001c2a:	040005b7          	lui	a1,0x4000
    80001c2e:	15fd                	addi	a1,a1,-1
    80001c30:	05b2                	slli	a1,a1,0xc
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	740080e7          	jalr	1856(ra) # 80001372 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c3a:	4681                	li	a3,0
    80001c3c:	4605                	li	a2,1
    80001c3e:	020005b7          	lui	a1,0x2000
    80001c42:	15fd                	addi	a1,a1,-1
    80001c44:	05b6                	slli	a1,a1,0xd
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	72a080e7          	jalr	1834(ra) # 80001372 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c50:	85ca                	mv	a1,s2
    80001c52:	8526                	mv	a0,s1
    80001c54:	00000097          	auipc	ra,0x0
    80001c58:	9de080e7          	jalr	-1570(ra) # 80001632 <uvmfree>
}
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret

0000000080001c68 <freeproc>:
{
    80001c68:	1101                	addi	sp,sp,-32
    80001c6a:	ec06                	sd	ra,24(sp)
    80001c6c:	e822                	sd	s0,16(sp)
    80001c6e:	e426                	sd	s1,8(sp)
    80001c70:	1000                	addi	s0,sp,32
    80001c72:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c74:	6d28                	ld	a0,88(a0)
    80001c76:	c509                	beqz	a0,80001c80 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	de4080e7          	jalr	-540(ra) # 80000a5c <kfree>
  p->trapframe = 0;
    80001c80:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c84:	68a8                	ld	a0,80(s1)
    80001c86:	c511                	beqz	a0,80001c92 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c88:	64ac                	ld	a1,72(s1)
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	f8c080e7          	jalr	-116(ra) # 80001c16 <proc_freepagetable>
  p->pagetable = 0;
    80001c92:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c96:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c9a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c9e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ca2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ca6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001caa:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cae:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cb2:	0004ac23          	sw	zero,24(s1)
}
    80001cb6:	60e2                	ld	ra,24(sp)
    80001cb8:	6442                	ld	s0,16(sp)
    80001cba:	64a2                	ld	s1,8(sp)
    80001cbc:	6105                	addi	sp,sp,32
    80001cbe:	8082                	ret

0000000080001cc0 <allocproc>:
{
    80001cc0:	1101                	addi	sp,sp,-32
    80001cc2:	ec06                	sd	ra,24(sp)
    80001cc4:	e822                	sd	s0,16(sp)
    80001cc6:	e426                	sd	s1,8(sp)
    80001cc8:	e04a                	sd	s2,0(sp)
    80001cca:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ccc:	00030497          	auipc	s1,0x30
    80001cd0:	a0448493          	addi	s1,s1,-1532 # 800316d0 <proc>
    80001cd4:	00035917          	auipc	s2,0x35
    80001cd8:	3fc90913          	addi	s2,s2,1020 # 800370d0 <tickslock>
    acquire(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	002080e7          	jalr	2(ra) # 80000ce0 <acquire>
    if(p->state == UNUSED) {
    80001ce6:	4c9c                	lw	a5,24(s1)
    80001ce8:	cf81                	beqz	a5,80001d00 <allocproc+0x40>
      release(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	0a8080e7          	jalr	168(ra) # 80000d94 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf4:	16848493          	addi	s1,s1,360
    80001cf8:	ff2492e3          	bne	s1,s2,80001cdc <allocproc+0x1c>
  return 0;
    80001cfc:	4481                	li	s1,0
    80001cfe:	a889                	j	80001d50 <allocproc+0x90>
  p->pid = allocpid();
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	e34080e7          	jalr	-460(ra) # 80001b34 <allocpid>
    80001d08:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d0a:	4785                	li	a5,1
    80001d0c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	ed8080e7          	jalr	-296(ra) # 80000be6 <kalloc>
    80001d16:	892a                	mv	s2,a0
    80001d18:	eca8                	sd	a0,88(s1)
    80001d1a:	c131                	beqz	a0,80001d5e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	e5c080e7          	jalr	-420(ra) # 80001b7a <proc_pagetable>
    80001d26:	892a                	mv	s2,a0
    80001d28:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d2a:	c531                	beqz	a0,80001d76 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d2c:	07000613          	li	a2,112
    80001d30:	4581                	li	a1,0
    80001d32:	06048513          	addi	a0,s1,96
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	0a6080e7          	jalr	166(ra) # 80000ddc <memset>
  p->context.ra = (uint64)forkret;
    80001d3e:	00000797          	auipc	a5,0x0
    80001d42:	db078793          	addi	a5,a5,-592 # 80001aee <forkret>
    80001d46:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d48:	60bc                	ld	a5,64(s1)
    80001d4a:	6705                	lui	a4,0x1
    80001d4c:	97ba                	add	a5,a5,a4
    80001d4e:	f4bc                	sd	a5,104(s1)
}
    80001d50:	8526                	mv	a0,s1
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6902                	ld	s2,0(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret
    freeproc(p);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	f08080e7          	jalr	-248(ra) # 80001c68 <freeproc>
    release(&p->lock);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	02a080e7          	jalr	42(ra) # 80000d94 <release>
    return 0;
    80001d72:	84ca                	mv	s1,s2
    80001d74:	bff1                	j	80001d50 <allocproc+0x90>
    freeproc(p);
    80001d76:	8526                	mv	a0,s1
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	ef0080e7          	jalr	-272(ra) # 80001c68 <freeproc>
    release(&p->lock);
    80001d80:	8526                	mv	a0,s1
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	012080e7          	jalr	18(ra) # 80000d94 <release>
    return 0;
    80001d8a:	84ca                	mv	s1,s2
    80001d8c:	b7d1                	j	80001d50 <allocproc+0x90>

0000000080001d8e <userinit>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	f28080e7          	jalr	-216(ra) # 80001cc0 <allocproc>
    80001da0:	84aa                	mv	s1,a0
  initproc = p;
    80001da2:	00007797          	auipc	a5,0x7
    80001da6:	28a7b323          	sd	a0,646(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001daa:	03400613          	li	a2,52
    80001dae:	00007597          	auipc	a1,0x7
    80001db2:	a7258593          	addi	a1,a1,-1422 # 80008820 <initcode>
    80001db6:	6928                	ld	a0,80(a0)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	6ac080e7          	jalr	1708(ra) # 80001464 <uvminit>
  p->sz = PGSIZE;
    80001dc0:	6785                	lui	a5,0x1
    80001dc2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dc4:	6cb8                	ld	a4,88(s1)
    80001dc6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dca:	6cb8                	ld	a4,88(s1)
    80001dcc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dce:	4641                	li	a2,16
    80001dd0:	00006597          	auipc	a1,0x6
    80001dd4:	43058593          	addi	a1,a1,1072 # 80008200 <digits+0x1c0>
    80001dd8:	15848513          	addi	a0,s1,344
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	152080e7          	jalr	338(ra) # 80000f2e <safestrcpy>
  p->cwd = namei("/");
    80001de4:	00006517          	auipc	a0,0x6
    80001de8:	42c50513          	addi	a0,a0,1068 # 80008210 <digits+0x1d0>
    80001dec:	00002097          	auipc	ra,0x2
    80001df0:	170080e7          	jalr	368(ra) # 80003f5c <namei>
    80001df4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df8:	478d                	li	a5,3
    80001dfa:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	f96080e7          	jalr	-106(ra) # 80000d94 <release>
}
    80001e06:	60e2                	ld	ra,24(sp)
    80001e08:	6442                	ld	s0,16(sp)
    80001e0a:	64a2                	ld	s1,8(sp)
    80001e0c:	6105                	addi	sp,sp,32
    80001e0e:	8082                	ret

0000000080001e10 <growproc>:
{
    80001e10:	1101                	addi	sp,sp,-32
    80001e12:	ec06                	sd	ra,24(sp)
    80001e14:	e822                	sd	s0,16(sp)
    80001e16:	e426                	sd	s1,8(sp)
    80001e18:	e04a                	sd	s2,0(sp)
    80001e1a:	1000                	addi	s0,sp,32
    80001e1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	c98080e7          	jalr	-872(ra) # 80001ab6 <myproc>
    80001e26:	892a                	mv	s2,a0
  sz = p->sz;
    80001e28:	652c                	ld	a1,72(a0)
    80001e2a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e2e:	00904f63          	bgtz	s1,80001e4c <growproc+0x3c>
  } else if(n < 0){
    80001e32:	0204cc63          	bltz	s1,80001e6a <growproc+0x5a>
  p->sz = sz;
    80001e36:	1602                	slli	a2,a2,0x20
    80001e38:	9201                	srli	a2,a2,0x20
    80001e3a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e3e:	4501                	li	a0,0
}
    80001e40:	60e2                	ld	ra,24(sp)
    80001e42:	6442                	ld	s0,16(sp)
    80001e44:	64a2                	ld	s1,8(sp)
    80001e46:	6902                	ld	s2,0(sp)
    80001e48:	6105                	addi	sp,sp,32
    80001e4a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e4c:	9e25                	addw	a2,a2,s1
    80001e4e:	1602                	slli	a2,a2,0x20
    80001e50:	9201                	srli	a2,a2,0x20
    80001e52:	1582                	slli	a1,a1,0x20
    80001e54:	9181                	srli	a1,a1,0x20
    80001e56:	6928                	ld	a0,80(a0)
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	6c6080e7          	jalr	1734(ra) # 8000151e <uvmalloc>
    80001e60:	0005061b          	sext.w	a2,a0
    80001e64:	fa69                	bnez	a2,80001e36 <growproc+0x26>
      return -1;
    80001e66:	557d                	li	a0,-1
    80001e68:	bfe1                	j	80001e40 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e6a:	9e25                	addw	a2,a2,s1
    80001e6c:	1602                	slli	a2,a2,0x20
    80001e6e:	9201                	srli	a2,a2,0x20
    80001e70:	1582                	slli	a1,a1,0x20
    80001e72:	9181                	srli	a1,a1,0x20
    80001e74:	6928                	ld	a0,80(a0)
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	660080e7          	jalr	1632(ra) # 800014d6 <uvmdealloc>
    80001e7e:	0005061b          	sext.w	a2,a0
    80001e82:	bf55                	j	80001e36 <growproc+0x26>

0000000080001e84 <fork>:
{
    80001e84:	7179                	addi	sp,sp,-48
    80001e86:	f406                	sd	ra,40(sp)
    80001e88:	f022                	sd	s0,32(sp)
    80001e8a:	ec26                	sd	s1,24(sp)
    80001e8c:	e84a                	sd	s2,16(sp)
    80001e8e:	e44e                	sd	s3,8(sp)
    80001e90:	e052                	sd	s4,0(sp)
    80001e92:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	c22080e7          	jalr	-990(ra) # 80001ab6 <myproc>
    80001e9c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	e22080e7          	jalr	-478(ra) # 80001cc0 <allocproc>
    80001ea6:	10050b63          	beqz	a0,80001fbc <fork+0x138>
    80001eaa:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eac:	04893603          	ld	a2,72(s2)
    80001eb0:	692c                	ld	a1,80(a0)
    80001eb2:	05093503          	ld	a0,80(s2)
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	7b4080e7          	jalr	1972(ra) # 8000166a <uvmcopy>
    80001ebe:	04054663          	bltz	a0,80001f0a <fork+0x86>
  np->sz = p->sz;
    80001ec2:	04893783          	ld	a5,72(s2)
    80001ec6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001eca:	05893683          	ld	a3,88(s2)
    80001ece:	87b6                	mv	a5,a3
    80001ed0:	0589b703          	ld	a4,88(s3)
    80001ed4:	12068693          	addi	a3,a3,288
    80001ed8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001edc:	6788                	ld	a0,8(a5)
    80001ede:	6b8c                	ld	a1,16(a5)
    80001ee0:	6f90                	ld	a2,24(a5)
    80001ee2:	01073023          	sd	a6,0(a4)
    80001ee6:	e708                	sd	a0,8(a4)
    80001ee8:	eb0c                	sd	a1,16(a4)
    80001eea:	ef10                	sd	a2,24(a4)
    80001eec:	02078793          	addi	a5,a5,32
    80001ef0:	02070713          	addi	a4,a4,32
    80001ef4:	fed792e3          	bne	a5,a3,80001ed8 <fork+0x54>
  np->trapframe->a0 = 0;
    80001ef8:	0589b783          	ld	a5,88(s3)
    80001efc:	0607b823          	sd	zero,112(a5)
    80001f00:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f04:	15000a13          	li	s4,336
    80001f08:	a03d                	j	80001f36 <fork+0xb2>
    freeproc(np);
    80001f0a:	854e                	mv	a0,s3
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	d5c080e7          	jalr	-676(ra) # 80001c68 <freeproc>
    release(&np->lock);
    80001f14:	854e                	mv	a0,s3
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	e7e080e7          	jalr	-386(ra) # 80000d94 <release>
    return -1;
    80001f1e:	5a7d                	li	s4,-1
    80001f20:	a069                	j	80001faa <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f22:	00002097          	auipc	ra,0x2
    80001f26:	6d0080e7          	jalr	1744(ra) # 800045f2 <filedup>
    80001f2a:	009987b3          	add	a5,s3,s1
    80001f2e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f30:	04a1                	addi	s1,s1,8
    80001f32:	01448763          	beq	s1,s4,80001f40 <fork+0xbc>
    if(p->ofile[i])
    80001f36:	009907b3          	add	a5,s2,s1
    80001f3a:	6388                	ld	a0,0(a5)
    80001f3c:	f17d                	bnez	a0,80001f22 <fork+0x9e>
    80001f3e:	bfcd                	j	80001f30 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f40:	15093503          	ld	a0,336(s2)
    80001f44:	00002097          	auipc	ra,0x2
    80001f48:	824080e7          	jalr	-2012(ra) # 80003768 <idup>
    80001f4c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f50:	4641                	li	a2,16
    80001f52:	15890593          	addi	a1,s2,344
    80001f56:	15898513          	addi	a0,s3,344
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	fd4080e7          	jalr	-44(ra) # 80000f2e <safestrcpy>
  pid = np->pid;
    80001f62:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f66:	854e                	mv	a0,s3
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	e2c080e7          	jalr	-468(ra) # 80000d94 <release>
  acquire(&wait_lock);
    80001f70:	0002f497          	auipc	s1,0x2f
    80001f74:	34848493          	addi	s1,s1,840 # 800312b8 <wait_lock>
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d66080e7          	jalr	-666(ra) # 80000ce0 <acquire>
  np->parent = p;
    80001f82:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	e0c080e7          	jalr	-500(ra) # 80000d94 <release>
  acquire(&np->lock);
    80001f90:	854e                	mv	a0,s3
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	d4e080e7          	jalr	-690(ra) # 80000ce0 <acquire>
  np->state = RUNNABLE;
    80001f9a:	478d                	li	a5,3
    80001f9c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fa0:	854e                	mv	a0,s3
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	df2080e7          	jalr	-526(ra) # 80000d94 <release>
}
    80001faa:	8552                	mv	a0,s4
    80001fac:	70a2                	ld	ra,40(sp)
    80001fae:	7402                	ld	s0,32(sp)
    80001fb0:	64e2                	ld	s1,24(sp)
    80001fb2:	6942                	ld	s2,16(sp)
    80001fb4:	69a2                	ld	s3,8(sp)
    80001fb6:	6a02                	ld	s4,0(sp)
    80001fb8:	6145                	addi	sp,sp,48
    80001fba:	8082                	ret
    return -1;
    80001fbc:	5a7d                	li	s4,-1
    80001fbe:	b7f5                	j	80001faa <fork+0x126>

0000000080001fc0 <scheduler>:
{
    80001fc0:	7139                	addi	sp,sp,-64
    80001fc2:	fc06                	sd	ra,56(sp)
    80001fc4:	f822                	sd	s0,48(sp)
    80001fc6:	f426                	sd	s1,40(sp)
    80001fc8:	f04a                	sd	s2,32(sp)
    80001fca:	ec4e                	sd	s3,24(sp)
    80001fcc:	e852                	sd	s4,16(sp)
    80001fce:	e456                	sd	s5,8(sp)
    80001fd0:	e05a                	sd	s6,0(sp)
    80001fd2:	0080                	addi	s0,sp,64
    80001fd4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fd6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fd8:	00779a93          	slli	s5,a5,0x7
    80001fdc:	0002f717          	auipc	a4,0x2f
    80001fe0:	2c470713          	addi	a4,a4,708 # 800312a0 <pid_lock>
    80001fe4:	9756                	add	a4,a4,s5
    80001fe6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fea:	0002f717          	auipc	a4,0x2f
    80001fee:	2ee70713          	addi	a4,a4,750 # 800312d8 <cpus+0x8>
    80001ff2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ff4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ff6:	4b11                	li	s6,4
        c->proc = p;
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0002fa17          	auipc	s4,0x2f
    80001ffe:	2a6a0a13          	addi	s4,s4,678 # 800312a0 <pid_lock>
    80002002:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002004:	00035917          	auipc	s2,0x35
    80002008:	0cc90913          	addi	s2,s2,204 # 800370d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002010:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002014:	10079073          	csrw	sstatus,a5
    80002018:	0002f497          	auipc	s1,0x2f
    8000201c:	6b848493          	addi	s1,s1,1720 # 800316d0 <proc>
    80002020:	a03d                	j	8000204e <scheduler+0x8e>
        p->state = RUNNING;
    80002022:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002026:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000202a:	06048593          	addi	a1,s1,96
    8000202e:	8556                	mv	a0,s5
    80002030:	00000097          	auipc	ra,0x0
    80002034:	640080e7          	jalr	1600(ra) # 80002670 <swtch>
        c->proc = 0;
    80002038:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	d56080e7          	jalr	-682(ra) # 80000d94 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002046:	16848493          	addi	s1,s1,360
    8000204a:	fd2481e3          	beq	s1,s2,8000200c <scheduler+0x4c>
      acquire(&p->lock);
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	c90080e7          	jalr	-880(ra) # 80000ce0 <acquire>
      if(p->state == RUNNABLE) {
    80002058:	4c9c                	lw	a5,24(s1)
    8000205a:	ff3791e3          	bne	a5,s3,8000203c <scheduler+0x7c>
    8000205e:	b7d1                	j	80002022 <scheduler+0x62>

0000000080002060 <sched>:
{
    80002060:	7179                	addi	sp,sp,-48
    80002062:	f406                	sd	ra,40(sp)
    80002064:	f022                	sd	s0,32(sp)
    80002066:	ec26                	sd	s1,24(sp)
    80002068:	e84a                	sd	s2,16(sp)
    8000206a:	e44e                	sd	s3,8(sp)
    8000206c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	a48080e7          	jalr	-1464(ra) # 80001ab6 <myproc>
    80002076:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	bee080e7          	jalr	-1042(ra) # 80000c66 <holding>
    80002080:	c93d                	beqz	a0,800020f6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002082:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	0002f717          	auipc	a4,0x2f
    8000208c:	21870713          	addi	a4,a4,536 # 800312a0 <pid_lock>
    80002090:	97ba                	add	a5,a5,a4
    80002092:	0a87a703          	lw	a4,168(a5)
    80002096:	4785                	li	a5,1
    80002098:	06f71763          	bne	a4,a5,80002106 <sched+0xa6>
  if(p->state == RUNNING)
    8000209c:	4c98                	lw	a4,24(s1)
    8000209e:	4791                	li	a5,4
    800020a0:	06f70b63          	beq	a4,a5,80002116 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020a8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020aa:	efb5                	bnez	a5,80002126 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ae:	0002f917          	auipc	s2,0x2f
    800020b2:	1f290913          	addi	s2,s2,498 # 800312a0 <pid_lock>
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	97ca                	add	a5,a5,s2
    800020bc:	0ac7a983          	lw	s3,172(a5)
    800020c0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	0002f597          	auipc	a1,0x2f
    800020ca:	21258593          	addi	a1,a1,530 # 800312d8 <cpus+0x8>
    800020ce:	95be                	add	a1,a1,a5
    800020d0:	06048513          	addi	a0,s1,96
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	59c080e7          	jalr	1436(ra) # 80002670 <swtch>
    800020dc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020de:	2781                	sext.w	a5,a5
    800020e0:	079e                	slli	a5,a5,0x7
    800020e2:	97ca                	add	a5,a5,s2
    800020e4:	0b37a623          	sw	s3,172(a5)
}
    800020e8:	70a2                	ld	ra,40(sp)
    800020ea:	7402                	ld	s0,32(sp)
    800020ec:	64e2                	ld	s1,24(sp)
    800020ee:	6942                	ld	s2,16(sp)
    800020f0:	69a2                	ld	s3,8(sp)
    800020f2:	6145                	addi	sp,sp,48
    800020f4:	8082                	ret
    panic("sched p->lock");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	12250513          	addi	a0,a0,290 # 80008218 <digits+0x1d8>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("sched locks");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	12250513          	addi	a0,a0,290 # 80008228 <digits+0x1e8>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
    panic("sched running");
    80002116:	00006517          	auipc	a0,0x6
    8000211a:	12250513          	addi	a0,a0,290 # 80008238 <digits+0x1f8>
    8000211e:	ffffe097          	auipc	ra,0xffffe
    80002122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	12250513          	addi	a0,a0,290 # 80008248 <digits+0x208>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	410080e7          	jalr	1040(ra) # 8000053e <panic>

0000000080002136 <yield>:
{
    80002136:	1101                	addi	sp,sp,-32
    80002138:	ec06                	sd	ra,24(sp)
    8000213a:	e822                	sd	s0,16(sp)
    8000213c:	e426                	sd	s1,8(sp)
    8000213e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002140:	00000097          	auipc	ra,0x0
    80002144:	976080e7          	jalr	-1674(ra) # 80001ab6 <myproc>
    80002148:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b96080e7          	jalr	-1130(ra) # 80000ce0 <acquire>
  p->state = RUNNABLE;
    80002152:	478d                	li	a5,3
    80002154:	cc9c                	sw	a5,24(s1)
  sched();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	f0a080e7          	jalr	-246(ra) # 80002060 <sched>
  release(&p->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	c34080e7          	jalr	-972(ra) # 80000d94 <release>
}
    80002168:	60e2                	ld	ra,24(sp)
    8000216a:	6442                	ld	s0,16(sp)
    8000216c:	64a2                	ld	s1,8(sp)
    8000216e:	6105                	addi	sp,sp,32
    80002170:	8082                	ret

0000000080002172 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002172:	7179                	addi	sp,sp,-48
    80002174:	f406                	sd	ra,40(sp)
    80002176:	f022                	sd	s0,32(sp)
    80002178:	ec26                	sd	s1,24(sp)
    8000217a:	e84a                	sd	s2,16(sp)
    8000217c:	e44e                	sd	s3,8(sp)
    8000217e:	1800                	addi	s0,sp,48
    80002180:	89aa                	mv	s3,a0
    80002182:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	932080e7          	jalr	-1742(ra) # 80001ab6 <myproc>
    8000218c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	b52080e7          	jalr	-1198(ra) # 80000ce0 <acquire>
  release(lk);
    80002196:	854a                	mv	a0,s2
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	bfc080e7          	jalr	-1028(ra) # 80000d94 <release>

  // Go to sleep.
  p->chan = chan;
    800021a0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021a4:	4789                	li	a5,2
    800021a6:	cc9c                	sw	a5,24(s1)

  sched();
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	eb8080e7          	jalr	-328(ra) # 80002060 <sched>

  // Tidy up.
  p->chan = 0;
    800021b0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	bde080e7          	jalr	-1058(ra) # 80000d94 <release>
  acquire(lk);
    800021be:	854a                	mv	a0,s2
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	b20080e7          	jalr	-1248(ra) # 80000ce0 <acquire>
}
    800021c8:	70a2                	ld	ra,40(sp)
    800021ca:	7402                	ld	s0,32(sp)
    800021cc:	64e2                	ld	s1,24(sp)
    800021ce:	6942                	ld	s2,16(sp)
    800021d0:	69a2                	ld	s3,8(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret

00000000800021d6 <wait>:
{
    800021d6:	715d                	addi	sp,sp,-80
    800021d8:	e486                	sd	ra,72(sp)
    800021da:	e0a2                	sd	s0,64(sp)
    800021dc:	fc26                	sd	s1,56(sp)
    800021de:	f84a                	sd	s2,48(sp)
    800021e0:	f44e                	sd	s3,40(sp)
    800021e2:	f052                	sd	s4,32(sp)
    800021e4:	ec56                	sd	s5,24(sp)
    800021e6:	e85a                	sd	s6,16(sp)
    800021e8:	e45e                	sd	s7,8(sp)
    800021ea:	e062                	sd	s8,0(sp)
    800021ec:	0880                	addi	s0,sp,80
    800021ee:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	8c6080e7          	jalr	-1850(ra) # 80001ab6 <myproc>
    800021f8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021fa:	0002f517          	auipc	a0,0x2f
    800021fe:	0be50513          	addi	a0,a0,190 # 800312b8 <wait_lock>
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	ade080e7          	jalr	-1314(ra) # 80000ce0 <acquire>
    havekids = 0;
    8000220a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000220c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000220e:	00035997          	auipc	s3,0x35
    80002212:	ec298993          	addi	s3,s3,-318 # 800370d0 <tickslock>
        havekids = 1;
    80002216:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002218:	0002fc17          	auipc	s8,0x2f
    8000221c:	0a0c0c13          	addi	s8,s8,160 # 800312b8 <wait_lock>
    havekids = 0;
    80002220:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002222:	0002f497          	auipc	s1,0x2f
    80002226:	4ae48493          	addi	s1,s1,1198 # 800316d0 <proc>
    8000222a:	a0bd                	j	80002298 <wait+0xc2>
          pid = np->pid;
    8000222c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002230:	000b0e63          	beqz	s6,8000224c <wait+0x76>
    80002234:	4691                	li	a3,4
    80002236:	02c48613          	addi	a2,s1,44
    8000223a:	85da                	mv	a1,s6
    8000223c:	05093503          	ld	a0,80(s2)
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	524080e7          	jalr	1316(ra) # 80001764 <copyout>
    80002248:	02054563          	bltz	a0,80002272 <wait+0x9c>
          freeproc(np);
    8000224c:	8526                	mv	a0,s1
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	a1a080e7          	jalr	-1510(ra) # 80001c68 <freeproc>
          release(&np->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	b3c080e7          	jalr	-1220(ra) # 80000d94 <release>
          release(&wait_lock);
    80002260:	0002f517          	auipc	a0,0x2f
    80002264:	05850513          	addi	a0,a0,88 # 800312b8 <wait_lock>
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	b2c080e7          	jalr	-1236(ra) # 80000d94 <release>
          return pid;
    80002270:	a09d                	j	800022d6 <wait+0x100>
            release(&np->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	b20080e7          	jalr	-1248(ra) # 80000d94 <release>
            release(&wait_lock);
    8000227c:	0002f517          	auipc	a0,0x2f
    80002280:	03c50513          	addi	a0,a0,60 # 800312b8 <wait_lock>
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	b10080e7          	jalr	-1264(ra) # 80000d94 <release>
            return -1;
    8000228c:	59fd                	li	s3,-1
    8000228e:	a0a1                	j	800022d6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002290:	16848493          	addi	s1,s1,360
    80002294:	03348463          	beq	s1,s3,800022bc <wait+0xe6>
      if(np->parent == p){
    80002298:	7c9c                	ld	a5,56(s1)
    8000229a:	ff279be3          	bne	a5,s2,80002290 <wait+0xba>
        acquire(&np->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	a40080e7          	jalr	-1472(ra) # 80000ce0 <acquire>
        if(np->state == ZOMBIE){
    800022a8:	4c9c                	lw	a5,24(s1)
    800022aa:	f94781e3          	beq	a5,s4,8000222c <wait+0x56>
        release(&np->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	ae4080e7          	jalr	-1308(ra) # 80000d94 <release>
        havekids = 1;
    800022b8:	8756                	mv	a4,s5
    800022ba:	bfd9                	j	80002290 <wait+0xba>
    if(!havekids || p->killed){
    800022bc:	c701                	beqz	a4,800022c4 <wait+0xee>
    800022be:	02892783          	lw	a5,40(s2)
    800022c2:	c79d                	beqz	a5,800022f0 <wait+0x11a>
      release(&wait_lock);
    800022c4:	0002f517          	auipc	a0,0x2f
    800022c8:	ff450513          	addi	a0,a0,-12 # 800312b8 <wait_lock>
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	ac8080e7          	jalr	-1336(ra) # 80000d94 <release>
      return -1;
    800022d4:	59fd                	li	s3,-1
}
    800022d6:	854e                	mv	a0,s3
    800022d8:	60a6                	ld	ra,72(sp)
    800022da:	6406                	ld	s0,64(sp)
    800022dc:	74e2                	ld	s1,56(sp)
    800022de:	7942                	ld	s2,48(sp)
    800022e0:	79a2                	ld	s3,40(sp)
    800022e2:	7a02                	ld	s4,32(sp)
    800022e4:	6ae2                	ld	s5,24(sp)
    800022e6:	6b42                	ld	s6,16(sp)
    800022e8:	6ba2                	ld	s7,8(sp)
    800022ea:	6c02                	ld	s8,0(sp)
    800022ec:	6161                	addi	sp,sp,80
    800022ee:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f0:	85e2                	mv	a1,s8
    800022f2:	854a                	mv	a0,s2
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	e7e080e7          	jalr	-386(ra) # 80002172 <sleep>
    havekids = 0;
    800022fc:	b715                	j	80002220 <wait+0x4a>

00000000800022fe <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022fe:	7139                	addi	sp,sp,-64
    80002300:	fc06                	sd	ra,56(sp)
    80002302:	f822                	sd	s0,48(sp)
    80002304:	f426                	sd	s1,40(sp)
    80002306:	f04a                	sd	s2,32(sp)
    80002308:	ec4e                	sd	s3,24(sp)
    8000230a:	e852                	sd	s4,16(sp)
    8000230c:	e456                	sd	s5,8(sp)
    8000230e:	0080                	addi	s0,sp,64
    80002310:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002312:	0002f497          	auipc	s1,0x2f
    80002316:	3be48493          	addi	s1,s1,958 # 800316d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000231a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000231c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000231e:	00035917          	auipc	s2,0x35
    80002322:	db290913          	addi	s2,s2,-590 # 800370d0 <tickslock>
    80002326:	a821                	j	8000233e <wakeup+0x40>
        p->state = RUNNABLE;
    80002328:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	a66080e7          	jalr	-1434(ra) # 80000d94 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002336:	16848493          	addi	s1,s1,360
    8000233a:	03248463          	beq	s1,s2,80002362 <wakeup+0x64>
    if(p != myproc()){
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	778080e7          	jalr	1912(ra) # 80001ab6 <myproc>
    80002346:	fea488e3          	beq	s1,a0,80002336 <wakeup+0x38>
      acquire(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	994080e7          	jalr	-1644(ra) # 80000ce0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002354:	4c9c                	lw	a5,24(s1)
    80002356:	fd379be3          	bne	a5,s3,8000232c <wakeup+0x2e>
    8000235a:	709c                	ld	a5,32(s1)
    8000235c:	fd4798e3          	bne	a5,s4,8000232c <wakeup+0x2e>
    80002360:	b7e1                	j	80002328 <wakeup+0x2a>
    }
  }
}
    80002362:	70e2                	ld	ra,56(sp)
    80002364:	7442                	ld	s0,48(sp)
    80002366:	74a2                	ld	s1,40(sp)
    80002368:	7902                	ld	s2,32(sp)
    8000236a:	69e2                	ld	s3,24(sp)
    8000236c:	6a42                	ld	s4,16(sp)
    8000236e:	6aa2                	ld	s5,8(sp)
    80002370:	6121                	addi	sp,sp,64
    80002372:	8082                	ret

0000000080002374 <reparent>:
{
    80002374:	7179                	addi	sp,sp,-48
    80002376:	f406                	sd	ra,40(sp)
    80002378:	f022                	sd	s0,32(sp)
    8000237a:	ec26                	sd	s1,24(sp)
    8000237c:	e84a                	sd	s2,16(sp)
    8000237e:	e44e                	sd	s3,8(sp)
    80002380:	e052                	sd	s4,0(sp)
    80002382:	1800                	addi	s0,sp,48
    80002384:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002386:	0002f497          	auipc	s1,0x2f
    8000238a:	34a48493          	addi	s1,s1,842 # 800316d0 <proc>
      pp->parent = initproc;
    8000238e:	00007a17          	auipc	s4,0x7
    80002392:	c9aa0a13          	addi	s4,s4,-870 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002396:	00035997          	auipc	s3,0x35
    8000239a:	d3a98993          	addi	s3,s3,-710 # 800370d0 <tickslock>
    8000239e:	a029                	j	800023a8 <reparent+0x34>
    800023a0:	16848493          	addi	s1,s1,360
    800023a4:	01348d63          	beq	s1,s3,800023be <reparent+0x4a>
    if(pp->parent == p){
    800023a8:	7c9c                	ld	a5,56(s1)
    800023aa:	ff279be3          	bne	a5,s2,800023a0 <reparent+0x2c>
      pp->parent = initproc;
    800023ae:	000a3503          	ld	a0,0(s4)
    800023b2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	f4a080e7          	jalr	-182(ra) # 800022fe <wakeup>
    800023bc:	b7d5                	j	800023a0 <reparent+0x2c>
}
    800023be:	70a2                	ld	ra,40(sp)
    800023c0:	7402                	ld	s0,32(sp)
    800023c2:	64e2                	ld	s1,24(sp)
    800023c4:	6942                	ld	s2,16(sp)
    800023c6:	69a2                	ld	s3,8(sp)
    800023c8:	6a02                	ld	s4,0(sp)
    800023ca:	6145                	addi	sp,sp,48
    800023cc:	8082                	ret

00000000800023ce <exit>:
{
    800023ce:	7179                	addi	sp,sp,-48
    800023d0:	f406                	sd	ra,40(sp)
    800023d2:	f022                	sd	s0,32(sp)
    800023d4:	ec26                	sd	s1,24(sp)
    800023d6:	e84a                	sd	s2,16(sp)
    800023d8:	e44e                	sd	s3,8(sp)
    800023da:	e052                	sd	s4,0(sp)
    800023dc:	1800                	addi	s0,sp,48
    800023de:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	6d6080e7          	jalr	1750(ra) # 80001ab6 <myproc>
    800023e8:	89aa                	mv	s3,a0
  if(p == initproc)
    800023ea:	00007797          	auipc	a5,0x7
    800023ee:	c3e7b783          	ld	a5,-962(a5) # 80009028 <initproc>
    800023f2:	0d050493          	addi	s1,a0,208
    800023f6:	15050913          	addi	s2,a0,336
    800023fa:	02a79363          	bne	a5,a0,80002420 <exit+0x52>
    panic("init exiting");
    800023fe:	00006517          	auipc	a0,0x6
    80002402:	e6250513          	addi	a0,a0,-414 # 80008260 <digits+0x220>
    80002406:	ffffe097          	auipc	ra,0xffffe
    8000240a:	138080e7          	jalr	312(ra) # 8000053e <panic>
      fileclose(f);
    8000240e:	00002097          	auipc	ra,0x2
    80002412:	236080e7          	jalr	566(ra) # 80004644 <fileclose>
      p->ofile[fd] = 0;
    80002416:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000241a:	04a1                	addi	s1,s1,8
    8000241c:	01248563          	beq	s1,s2,80002426 <exit+0x58>
    if(p->ofile[fd]){
    80002420:	6088                	ld	a0,0(s1)
    80002422:	f575                	bnez	a0,8000240e <exit+0x40>
    80002424:	bfdd                	j	8000241a <exit+0x4c>
  begin_op();
    80002426:	00002097          	auipc	ra,0x2
    8000242a:	d52080e7          	jalr	-686(ra) # 80004178 <begin_op>
  iput(p->cwd);
    8000242e:	1509b503          	ld	a0,336(s3)
    80002432:	00001097          	auipc	ra,0x1
    80002436:	52e080e7          	jalr	1326(ra) # 80003960 <iput>
  end_op();
    8000243a:	00002097          	auipc	ra,0x2
    8000243e:	dbe080e7          	jalr	-578(ra) # 800041f8 <end_op>
  p->cwd = 0;
    80002442:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002446:	0002f497          	auipc	s1,0x2f
    8000244a:	e7248493          	addi	s1,s1,-398 # 800312b8 <wait_lock>
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	890080e7          	jalr	-1904(ra) # 80000ce0 <acquire>
  reparent(p);
    80002458:	854e                	mv	a0,s3
    8000245a:	00000097          	auipc	ra,0x0
    8000245e:	f1a080e7          	jalr	-230(ra) # 80002374 <reparent>
  wakeup(p->parent);
    80002462:	0389b503          	ld	a0,56(s3)
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	e98080e7          	jalr	-360(ra) # 800022fe <wakeup>
  acquire(&p->lock);
    8000246e:	854e                	mv	a0,s3
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	870080e7          	jalr	-1936(ra) # 80000ce0 <acquire>
  p->xstate = status;
    80002478:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000247c:	4795                	li	a5,5
    8000247e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	910080e7          	jalr	-1776(ra) # 80000d94 <release>
  sched();
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	bd4080e7          	jalr	-1068(ra) # 80002060 <sched>
  panic("zombie exit");
    80002494:	00006517          	auipc	a0,0x6
    80002498:	ddc50513          	addi	a0,a0,-548 # 80008270 <digits+0x230>
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>

00000000800024a4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a4:	7179                	addi	sp,sp,-48
    800024a6:	f406                	sd	ra,40(sp)
    800024a8:	f022                	sd	s0,32(sp)
    800024aa:	ec26                	sd	s1,24(sp)
    800024ac:	e84a                	sd	s2,16(sp)
    800024ae:	e44e                	sd	s3,8(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b4:	0002f497          	auipc	s1,0x2f
    800024b8:	21c48493          	addi	s1,s1,540 # 800316d0 <proc>
    800024bc:	00035997          	auipc	s3,0x35
    800024c0:	c1498993          	addi	s3,s3,-1004 # 800370d0 <tickslock>
    acquire(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	81a080e7          	jalr	-2022(ra) # 80000ce0 <acquire>
    if(p->pid == pid){
    800024ce:	589c                	lw	a5,48(s1)
    800024d0:	01278d63          	beq	a5,s2,800024ea <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d4:	8526                	mv	a0,s1
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	8be080e7          	jalr	-1858(ra) # 80000d94 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024de:	16848493          	addi	s1,s1,360
    800024e2:	ff3491e3          	bne	s1,s3,800024c4 <kill+0x20>
  }
  return -1;
    800024e6:	557d                	li	a0,-1
    800024e8:	a829                	j	80002502 <kill+0x5e>
      p->killed = 1;
    800024ea:	4785                	li	a5,1
    800024ec:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024ee:	4c98                	lw	a4,24(s1)
    800024f0:	4789                	li	a5,2
    800024f2:	00f70f63          	beq	a4,a5,80002510 <kill+0x6c>
      release(&p->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	89c080e7          	jalr	-1892(ra) # 80000d94 <release>
      return 0;
    80002500:	4501                	li	a0,0
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6145                	addi	sp,sp,48
    8000250e:	8082                	ret
        p->state = RUNNABLE;
    80002510:	478d                	li	a5,3
    80002512:	cc9c                	sw	a5,24(s1)
    80002514:	b7cd                	j	800024f6 <kill+0x52>

0000000080002516 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002516:	7179                	addi	sp,sp,-48
    80002518:	f406                	sd	ra,40(sp)
    8000251a:	f022                	sd	s0,32(sp)
    8000251c:	ec26                	sd	s1,24(sp)
    8000251e:	e84a                	sd	s2,16(sp)
    80002520:	e44e                	sd	s3,8(sp)
    80002522:	e052                	sd	s4,0(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	84aa                	mv	s1,a0
    80002528:	892e                	mv	s2,a1
    8000252a:	89b2                	mv	s3,a2
    8000252c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	588080e7          	jalr	1416(ra) # 80001ab6 <myproc>
  if(user_dst){
    80002536:	c08d                	beqz	s1,80002558 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002538:	86d2                	mv	a3,s4
    8000253a:	864e                	mv	a2,s3
    8000253c:	85ca                	mv	a1,s2
    8000253e:	6928                	ld	a0,80(a0)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	224080e7          	jalr	548(ra) # 80001764 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6a02                	ld	s4,0(sp)
    80002554:	6145                	addi	sp,sp,48
    80002556:	8082                	ret
    memmove((char *)dst, src, len);
    80002558:	000a061b          	sext.w	a2,s4
    8000255c:	85ce                	mv	a1,s3
    8000255e:	854a                	mv	a0,s2
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	8dc080e7          	jalr	-1828(ra) # 80000e3c <memmove>
    return 0;
    80002568:	8526                	mv	a0,s1
    8000256a:	bff9                	j	80002548 <either_copyout+0x32>

000000008000256c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000256c:	7179                	addi	sp,sp,-48
    8000256e:	f406                	sd	ra,40(sp)
    80002570:	f022                	sd	s0,32(sp)
    80002572:	ec26                	sd	s1,24(sp)
    80002574:	e84a                	sd	s2,16(sp)
    80002576:	e44e                	sd	s3,8(sp)
    80002578:	e052                	sd	s4,0(sp)
    8000257a:	1800                	addi	s0,sp,48
    8000257c:	892a                	mv	s2,a0
    8000257e:	84ae                	mv	s1,a1
    80002580:	89b2                	mv	s3,a2
    80002582:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	532080e7          	jalr	1330(ra) # 80001ab6 <myproc>
  if(user_src){
    8000258c:	c08d                	beqz	s1,800025ae <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000258e:	86d2                	mv	a3,s4
    80002590:	864e                	mv	a2,s3
    80002592:	85ca                	mv	a1,s2
    80002594:	6928                	ld	a0,80(a0)
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	26e080e7          	jalr	622(ra) # 80001804 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000259e:	70a2                	ld	ra,40(sp)
    800025a0:	7402                	ld	s0,32(sp)
    800025a2:	64e2                	ld	s1,24(sp)
    800025a4:	6942                	ld	s2,16(sp)
    800025a6:	69a2                	ld	s3,8(sp)
    800025a8:	6a02                	ld	s4,0(sp)
    800025aa:	6145                	addi	sp,sp,48
    800025ac:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ae:	000a061b          	sext.w	a2,s4
    800025b2:	85ce                	mv	a1,s3
    800025b4:	854a                	mv	a0,s2
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	886080e7          	jalr	-1914(ra) # 80000e3c <memmove>
    return 0;
    800025be:	8526                	mv	a0,s1
    800025c0:	bff9                	j	8000259e <either_copyin+0x32>

00000000800025c2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025c2:	715d                	addi	sp,sp,-80
    800025c4:	e486                	sd	ra,72(sp)
    800025c6:	e0a2                	sd	s0,64(sp)
    800025c8:	fc26                	sd	s1,56(sp)
    800025ca:	f84a                	sd	s2,48(sp)
    800025cc:	f44e                	sd	s3,40(sp)
    800025ce:	f052                	sd	s4,32(sp)
    800025d0:	ec56                	sd	s5,24(sp)
    800025d2:	e85a                	sd	s6,16(sp)
    800025d4:	e45e                	sd	s7,8(sp)
    800025d6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025d8:	00006517          	auipc	a0,0x6
    800025dc:	af050513          	addi	a0,a0,-1296 # 800080c8 <digits+0x88>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	fa8080e7          	jalr	-88(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e8:	0002f497          	auipc	s1,0x2f
    800025ec:	24048493          	addi	s1,s1,576 # 80031828 <proc+0x158>
    800025f0:	00035917          	auipc	s2,0x35
    800025f4:	c3890913          	addi	s2,s2,-968 # 80037228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025fa:	00006997          	auipc	s3,0x6
    800025fe:	c8698993          	addi	s3,s3,-890 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002602:	00006a97          	auipc	s5,0x6
    80002606:	c86a8a93          	addi	s5,s5,-890 # 80008288 <digits+0x248>
    printf("\n");
    8000260a:	00006a17          	auipc	s4,0x6
    8000260e:	abea0a13          	addi	s4,s4,-1346 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002612:	00006b97          	auipc	s7,0x6
    80002616:	caeb8b93          	addi	s7,s7,-850 # 800082c0 <states.1722>
    8000261a:	a00d                	j	8000263c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000261c:	ed86a583          	lw	a1,-296(a3)
    80002620:	8556                	mv	a0,s5
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f66080e7          	jalr	-154(ra) # 80000588 <printf>
    printf("\n");
    8000262a:	8552                	mv	a0,s4
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	f5c080e7          	jalr	-164(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002634:	16848493          	addi	s1,s1,360
    80002638:	03248163          	beq	s1,s2,8000265a <procdump+0x98>
    if(p->state == UNUSED)
    8000263c:	86a6                	mv	a3,s1
    8000263e:	ec04a783          	lw	a5,-320(s1)
    80002642:	dbed                	beqz	a5,80002634 <procdump+0x72>
      state = "???";
    80002644:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002646:	fcfb6be3          	bltu	s6,a5,8000261c <procdump+0x5a>
    8000264a:	1782                	slli	a5,a5,0x20
    8000264c:	9381                	srli	a5,a5,0x20
    8000264e:	078e                	slli	a5,a5,0x3
    80002650:	97de                	add	a5,a5,s7
    80002652:	6390                	ld	a2,0(a5)
    80002654:	f661                	bnez	a2,8000261c <procdump+0x5a>
      state = "???";
    80002656:	864e                	mv	a2,s3
    80002658:	b7d1                	j	8000261c <procdump+0x5a>
  }
}
    8000265a:	60a6                	ld	ra,72(sp)
    8000265c:	6406                	ld	s0,64(sp)
    8000265e:	74e2                	ld	s1,56(sp)
    80002660:	7942                	ld	s2,48(sp)
    80002662:	79a2                	ld	s3,40(sp)
    80002664:	7a02                	ld	s4,32(sp)
    80002666:	6ae2                	ld	s5,24(sp)
    80002668:	6b42                	ld	s6,16(sp)
    8000266a:	6ba2                	ld	s7,8(sp)
    8000266c:	6161                	addi	sp,sp,80
    8000266e:	8082                	ret

0000000080002670 <swtch>:
    80002670:	00153023          	sd	ra,0(a0)
    80002674:	00253423          	sd	sp,8(a0)
    80002678:	e900                	sd	s0,16(a0)
    8000267a:	ed04                	sd	s1,24(a0)
    8000267c:	03253023          	sd	s2,32(a0)
    80002680:	03353423          	sd	s3,40(a0)
    80002684:	03453823          	sd	s4,48(a0)
    80002688:	03553c23          	sd	s5,56(a0)
    8000268c:	05653023          	sd	s6,64(a0)
    80002690:	05753423          	sd	s7,72(a0)
    80002694:	05853823          	sd	s8,80(a0)
    80002698:	05953c23          	sd	s9,88(a0)
    8000269c:	07a53023          	sd	s10,96(a0)
    800026a0:	07b53423          	sd	s11,104(a0)
    800026a4:	0005b083          	ld	ra,0(a1)
    800026a8:	0085b103          	ld	sp,8(a1)
    800026ac:	6980                	ld	s0,16(a1)
    800026ae:	6d84                	ld	s1,24(a1)
    800026b0:	0205b903          	ld	s2,32(a1)
    800026b4:	0285b983          	ld	s3,40(a1)
    800026b8:	0305ba03          	ld	s4,48(a1)
    800026bc:	0385ba83          	ld	s5,56(a1)
    800026c0:	0405bb03          	ld	s6,64(a1)
    800026c4:	0485bb83          	ld	s7,72(a1)
    800026c8:	0505bc03          	ld	s8,80(a1)
    800026cc:	0585bc83          	ld	s9,88(a1)
    800026d0:	0605bd03          	ld	s10,96(a1)
    800026d4:	0685bd83          	ld	s11,104(a1)
    800026d8:	8082                	ret

00000000800026da <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026da:	1141                	addi	sp,sp,-16
    800026dc:	e406                	sd	ra,8(sp)
    800026de:	e022                	sd	s0,0(sp)
    800026e0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026e2:	00006597          	auipc	a1,0x6
    800026e6:	c0e58593          	addi	a1,a1,-1010 # 800082f0 <states.1722+0x30>
    800026ea:	00035517          	auipc	a0,0x35
    800026ee:	9e650513          	addi	a0,a0,-1562 # 800370d0 <tickslock>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	55e080e7          	jalr	1374(ra) # 80000c50 <initlock>
}
    800026fa:	60a2                	ld	ra,8(sp)
    800026fc:	6402                	ld	s0,0(sp)
    800026fe:	0141                	addi	sp,sp,16
    80002700:	8082                	ret

0000000080002702 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002702:	1141                	addi	sp,sp,-16
    80002704:	e422                	sd	s0,8(sp)
    80002706:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002708:	00003797          	auipc	a5,0x3
    8000270c:	55878793          	addi	a5,a5,1368 # 80005c60 <kernelvec>
    80002710:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002714:	6422                	ld	s0,8(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e406                	sd	ra,8(sp)
    8000271e:	e022                	sd	s0,0(sp)
    80002720:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	394080e7          	jalr	916(ra) # 80001ab6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000272e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002730:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002734:	00005617          	auipc	a2,0x5
    80002738:	8cc60613          	addi	a2,a2,-1844 # 80007000 <_trampoline>
    8000273c:	00005697          	auipc	a3,0x5
    80002740:	8c468693          	addi	a3,a3,-1852 # 80007000 <_trampoline>
    80002744:	8e91                	sub	a3,a3,a2
    80002746:	040007b7          	lui	a5,0x4000
    8000274a:	17fd                	addi	a5,a5,-1
    8000274c:	07b2                	slli	a5,a5,0xc
    8000274e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002750:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002754:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002756:	180026f3          	csrr	a3,satp
    8000275a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000275c:	6d38                	ld	a4,88(a0)
    8000275e:	6134                	ld	a3,64(a0)
    80002760:	6585                	lui	a1,0x1
    80002762:	96ae                	add	a3,a3,a1
    80002764:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002766:	6d38                	ld	a4,88(a0)
    80002768:	00000697          	auipc	a3,0x0
    8000276c:	2a268693          	addi	a3,a3,674 # 80002a0a <usertrap>
    80002770:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002772:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002774:	8692                	mv	a3,tp
    80002776:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002778:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000277c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002780:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002784:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002788:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000278a:	6f18                	ld	a4,24(a4)
    8000278c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002790:	692c                	ld	a1,80(a0)
    80002792:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002794:	00005717          	auipc	a4,0x5
    80002798:	8fc70713          	addi	a4,a4,-1796 # 80007090 <userret>
    8000279c:	8f11                	sub	a4,a4,a2
    8000279e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027a0:	577d                	li	a4,-1
    800027a2:	177e                	slli	a4,a4,0x3f
    800027a4:	8dd9                	or	a1,a1,a4
    800027a6:	02000537          	lui	a0,0x2000
    800027aa:	157d                	addi	a0,a0,-1
    800027ac:	0536                	slli	a0,a0,0xd
    800027ae:	9782                	jalr	a5
}
    800027b0:	60a2                	ld	ra,8(sp)
    800027b2:	6402                	ld	s0,0(sp)
    800027b4:	0141                	addi	sp,sp,16
    800027b6:	8082                	ret

00000000800027b8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027b8:	1101                	addi	sp,sp,-32
    800027ba:	ec06                	sd	ra,24(sp)
    800027bc:	e822                	sd	s0,16(sp)
    800027be:	e426                	sd	s1,8(sp)
    800027c0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027c2:	00035497          	auipc	s1,0x35
    800027c6:	90e48493          	addi	s1,s1,-1778 # 800370d0 <tickslock>
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	514080e7          	jalr	1300(ra) # 80000ce0 <acquire>
  ticks++;
    800027d4:	00007517          	auipc	a0,0x7
    800027d8:	85c50513          	addi	a0,a0,-1956 # 80009030 <ticks>
    800027dc:	411c                	lw	a5,0(a0)
    800027de:	2785                	addiw	a5,a5,1
    800027e0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	b1c080e7          	jalr	-1252(ra) # 800022fe <wakeup>
  release(&tickslock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	5a8080e7          	jalr	1448(ra) # 80000d94 <release>
}
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6105                	addi	sp,sp,32
    800027fc:	8082                	ret

00000000800027fe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027fe:	1101                	addi	sp,sp,-32
    80002800:	ec06                	sd	ra,24(sp)
    80002802:	e822                	sd	s0,16(sp)
    80002804:	e426                	sd	s1,8(sp)
    80002806:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002808:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000280c:	00074d63          	bltz	a4,80002826 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002810:	57fd                	li	a5,-1
    80002812:	17fe                	slli	a5,a5,0x3f
    80002814:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002816:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002818:	06f70363          	beq	a4,a5,8000287e <devintr+0x80>
  }
}
    8000281c:	60e2                	ld	ra,24(sp)
    8000281e:	6442                	ld	s0,16(sp)
    80002820:	64a2                	ld	s1,8(sp)
    80002822:	6105                	addi	sp,sp,32
    80002824:	8082                	ret
     (scause & 0xff) == 9){
    80002826:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000282a:	46a5                	li	a3,9
    8000282c:	fed792e3          	bne	a5,a3,80002810 <devintr+0x12>
    int irq = plic_claim();
    80002830:	00003097          	auipc	ra,0x3
    80002834:	538080e7          	jalr	1336(ra) # 80005d68 <plic_claim>
    80002838:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000283a:	47a9                	li	a5,10
    8000283c:	02f50763          	beq	a0,a5,8000286a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002840:	4785                	li	a5,1
    80002842:	02f50963          	beq	a0,a5,80002874 <devintr+0x76>
    return 1;
    80002846:	4505                	li	a0,1
    } else if(irq){
    80002848:	d8f1                	beqz	s1,8000281c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000284a:	85a6                	mv	a1,s1
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	aac50513          	addi	a0,a0,-1364 # 800082f8 <states.1722+0x38>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	d34080e7          	jalr	-716(ra) # 80000588 <printf>
      plic_complete(irq);
    8000285c:	8526                	mv	a0,s1
    8000285e:	00003097          	auipc	ra,0x3
    80002862:	52e080e7          	jalr	1326(ra) # 80005d8c <plic_complete>
    return 1;
    80002866:	4505                	li	a0,1
    80002868:	bf55                	j	8000281c <devintr+0x1e>
      uartintr();
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	13e080e7          	jalr	318(ra) # 800009a8 <uartintr>
    80002872:	b7ed                	j	8000285c <devintr+0x5e>
      virtio_disk_intr();
    80002874:	00004097          	auipc	ra,0x4
    80002878:	9f8080e7          	jalr	-1544(ra) # 8000626c <virtio_disk_intr>
    8000287c:	b7c5                	j	8000285c <devintr+0x5e>
    if(cpuid() == 0){
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	20c080e7          	jalr	524(ra) # 80001a8a <cpuid>
    80002886:	c901                	beqz	a0,80002896 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002888:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000288c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000288e:	14479073          	csrw	sip,a5
    return 2;
    80002892:	4509                	li	a0,2
    80002894:	b761                	j	8000281c <devintr+0x1e>
      clockintr();
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	f22080e7          	jalr	-222(ra) # 800027b8 <clockintr>
    8000289e:	b7ed                	j	80002888 <devintr+0x8a>

00000000800028a0 <kerneltrap>:
{
    800028a0:	7179                	addi	sp,sp,-48
    800028a2:	f406                	sd	ra,40(sp)
    800028a4:	f022                	sd	s0,32(sp)
    800028a6:	ec26                	sd	s1,24(sp)
    800028a8:	e84a                	sd	s2,16(sp)
    800028aa:	e44e                	sd	s3,8(sp)
    800028ac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ba:	1004f793          	andi	a5,s1,256
    800028be:	cb85                	beqz	a5,800028ee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028c4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028c6:	ef85                	bnez	a5,800028fe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	f36080e7          	jalr	-202(ra) # 800027fe <devintr>
    800028d0:	cd1d                	beqz	a0,8000290e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028d2:	4789                	li	a5,2
    800028d4:	06f50a63          	beq	a0,a5,80002948 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028d8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028dc:	10049073          	csrw	sstatus,s1
}
    800028e0:	70a2                	ld	ra,40(sp)
    800028e2:	7402                	ld	s0,32(sp)
    800028e4:	64e2                	ld	s1,24(sp)
    800028e6:	6942                	ld	s2,16(sp)
    800028e8:	69a2                	ld	s3,8(sp)
    800028ea:	6145                	addi	sp,sp,48
    800028ec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	a2a50513          	addi	a0,a0,-1494 # 80008318 <states.1722+0x58>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	c48080e7          	jalr	-952(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	a4250513          	addi	a0,a0,-1470 # 80008340 <states.1722+0x80>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c38080e7          	jalr	-968(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000290e:	85ce                	mv	a1,s3
    80002910:	00006517          	auipc	a0,0x6
    80002914:	a5050513          	addi	a0,a0,-1456 # 80008360 <states.1722+0xa0>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c70080e7          	jalr	-912(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002924:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	a4850513          	addi	a0,a0,-1464 # 80008370 <states.1722+0xb0>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c58080e7          	jalr	-936(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	a5050513          	addi	a0,a0,-1456 # 80008388 <states.1722+0xc8>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	bfe080e7          	jalr	-1026(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	16e080e7          	jalr	366(ra) # 80001ab6 <myproc>
    80002950:	d541                	beqz	a0,800028d8 <kerneltrap+0x38>
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	164080e7          	jalr	356(ra) # 80001ab6 <myproc>
    8000295a:	4d18                	lw	a4,24(a0)
    8000295c:	4791                	li	a5,4
    8000295e:	f6f71de3          	bne	a4,a5,800028d8 <kerneltrap+0x38>
    yield();
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	7d4080e7          	jalr	2004(ra) # 80002136 <yield>
    8000296a:	b7bd                	j	800028d8 <kerneltrap+0x38>

000000008000296c <cow>:
cow(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  char *pa_num;

  va = PGROUNDDOWN(va); // normelize the virtual address page
    8000296c:	77fd                	lui	a5,0xfffff
    8000296e:	8dfd                	and	a1,a1,a5

  if(va >= MAXVA) // check if va is invalid
    80002970:	57fd                	li	a5,-1
    80002972:	83e9                	srli	a5,a5,0x1a
    80002974:	00b7f463          	bgeu	a5,a1,8000297c <cow+0x10>
    return -1;
    80002978:	557d                	li	a0,-1

    return 0;
  } else {
    return -1;
  }
}
    8000297a:	8082                	ret
{
    8000297c:	7179                	addi	sp,sp,-48
    8000297e:	f406                	sd	ra,40(sp)
    80002980:	f022                	sd	s0,32(sp)
    80002982:	ec26                	sd	s1,24(sp)
    80002984:	e84a                	sd	s2,16(sp)
    80002986:	e44e                	sd	s3,8(sp)
    80002988:	1800                	addi	s0,sp,48
  pte = walk(pagetable, va, 0); // walk returns the address of the pte in the page table of the virtual address
    8000298a:	4601                	li	a2,0
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	738080e7          	jalr	1848(ra) # 800010c4 <walk>
    80002994:	84aa                	mv	s1,a0
  if(pte == 0)
    80002996:	c925                	beqz	a0,80002a06 <cow+0x9a>
  if ((*pte & PTE_V) == 0) // check if the bit of the valid flag is on (0)
    80002998:	611c                	ld	a5,0(a0)
    8000299a:	0017f713          	andi	a4,a5,1
    return -1;
    8000299e:	557d                	li	a0,-1
  if ((*pte & PTE_V) == 0) // check if the bit of the valid flag is on (0)
    800029a0:	c709                	beqz	a4,800029aa <cow+0x3e>
  if ((*pte & PTE_COW) == 0) // check if the bit of the copy on write flag is on (9).
    800029a2:	2007f793          	andi	a5,a5,512
    return 1;
    800029a6:	4505                	li	a0,1
  if ((*pte & PTE_COW) == 0) // check if the bit of the copy on write flag is on (9).
    800029a8:	eb81                	bnez	a5,800029b8 <cow+0x4c>
}
    800029aa:	70a2                	ld	ra,40(sp)
    800029ac:	7402                	ld	s0,32(sp)
    800029ae:	64e2                	ld	s1,24(sp)
    800029b0:	6942                	ld	s2,16(sp)
    800029b2:	69a2                	ld	s3,8(sp)
    800029b4:	6145                	addi	sp,sp,48
    800029b6:	8082                	ret
  if ((pa_num = kalloc()) != 0) { // Allocate one 4096-byte page of physical memory. pa_num is a pointer that the kernel can use.
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	22e080e7          	jalr	558(ra) # 80000be6 <kalloc>
    800029c0:	892a                	mv	s2,a0
    return -1;
    800029c2:	557d                	li	a0,-1
  if ((pa_num = kalloc()) != 0) { // Allocate one 4096-byte page of physical memory. pa_num is a pointer that the kernel can use.
    800029c4:	fe0903e3          	beqz	s2,800029aa <cow+0x3e>
    uint64 pa = PTE2PA(*pte);
    800029c8:	0004b983          	ld	s3,0(s1)
    800029cc:	00a9d993          	srli	s3,s3,0xa
    800029d0:	09b2                	slli	s3,s3,0xc
    memmove(pa_num, (char*)pa, PGSIZE);
    800029d2:	6605                	lui	a2,0x1
    800029d4:	85ce                	mv	a1,s3
    800029d6:	854a                	mv	a0,s2
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	464080e7          	jalr	1124(ra) # 80000e3c <memmove>
    *pte = PA2PTE(pa_num) | ((PTE_FLAGS(*pte) & ~PTE_COW) | PTE_W);
    800029e0:	00c95793          	srli	a5,s2,0xc
    800029e4:	07aa                	slli	a5,a5,0xa
    800029e6:	0004b903          	ld	s2,0(s1)
    800029ea:	1fb97913          	andi	s2,s2,507
    800029ee:	0127e7b3          	or	a5,a5,s2
    800029f2:	0047e793          	ori	a5,a5,4
    800029f6:	e09c                	sd	a5,0(s1)
    kfree((void*)pa);
    800029f8:	854e                	mv	a0,s3
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	062080e7          	jalr	98(ra) # 80000a5c <kfree>
    return 0;
    80002a02:	4501                	li	a0,0
    80002a04:	b75d                	j	800029aa <cow+0x3e>
    return -1;
    80002a06:	557d                	li	a0,-1
    80002a08:	b74d                	j	800029aa <cow+0x3e>

0000000080002a0a <usertrap>:
{
    80002a0a:	1101                	addi	sp,sp,-32
    80002a0c:	ec06                	sd	ra,24(sp)
    80002a0e:	e822                	sd	s0,16(sp)
    80002a10:	e426                	sd	s1,8(sp)
    80002a12:	e04a                	sd	s2,0(sp)
    80002a14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a16:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a1a:	1007f793          	andi	a5,a5,256
    80002a1e:	e7a5                	bnez	a5,80002a86 <usertrap+0x7c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a20:	00003797          	auipc	a5,0x3
    80002a24:	24078793          	addi	a5,a5,576 # 80005c60 <kernelvec>
    80002a28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	08a080e7          	jalr	138(ra) # 80001ab6 <myproc>
    80002a34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a36:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a38:	14102773          	csrr	a4,sepc
    80002a3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a42:	47a1                	li	a5,8
    80002a44:	04f70963          	beq	a4,a5,80002a96 <usertrap+0x8c>
    80002a48:	14202773          	csrr	a4,scause
  } else if (r_scause() == 13 || r_scause() == 15) { // user trap in the case of a page fault
    80002a4c:	47b5                	li	a5,13
    80002a4e:	00f70763          	beq	a4,a5,80002a5c <usertrap+0x52>
    80002a52:	14202773          	csrr	a4,scause
    80002a56:	47bd                	li	a5,15
    80002a58:	08f71863          	bne	a4,a5,80002ae8 <usertrap+0xde>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a5c:	143025f3          	csrr	a1,stval
    if (va >= p->sz || cow(p->pagetable, va) != 0) { // check if the va is higher than the size of memory or cow failed. kill in case it is
    80002a60:	64bc                	ld	a5,72(s1)
    80002a62:	06f5ec63          	bltu	a1,a5,80002ada <usertrap+0xd0>
      p->killed = 1;
    80002a66:	4785                	li	a5,1
    80002a68:	d49c                	sw	a5,40(s1)
{
    80002a6a:	4901                	li	s2,0
    exit(-1);
    80002a6c:	557d                	li	a0,-1
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	960080e7          	jalr	-1696(ra) # 800023ce <exit>
  if(which_dev == 2)
    80002a76:	4789                	li	a5,2
    80002a78:	04f91163          	bne	s2,a5,80002aba <usertrap+0xb0>
    yield();
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	6ba080e7          	jalr	1722(ra) # 80002136 <yield>
    80002a84:	a81d                	j	80002aba <usertrap+0xb0>
    panic("usertrap: not from user mode");
    80002a86:	00006517          	auipc	a0,0x6
    80002a8a:	91250513          	addi	a0,a0,-1774 # 80008398 <states.1722+0xd8>
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
    if(p->killed)
    80002a96:	551c                	lw	a5,40(a0)
    80002a98:	eb9d                	bnez	a5,80002ace <usertrap+0xc4>
    p->trapframe->epc += 4;
    80002a9a:	6cb8                	ld	a4,88(s1)
    80002a9c:	6f1c                	ld	a5,24(a4)
    80002a9e:	0791                	addi	a5,a5,4
    80002aa0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aa6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aaa:	10079073          	csrw	sstatus,a5
    syscall();
    80002aae:	00000097          	auipc	ra,0x0
    80002ab2:	1fa080e7          	jalr	506(ra) # 80002ca8 <syscall>
  if(p->killed)
    80002ab6:	549c                	lw	a5,40(s1)
    80002ab8:	ebbd                	bnez	a5,80002b2e <usertrap+0x124>
  usertrapret();
    80002aba:	00000097          	auipc	ra,0x0
    80002abe:	c60080e7          	jalr	-928(ra) # 8000271a <usertrapret>
}
    80002ac2:	60e2                	ld	ra,24(sp)
    80002ac4:	6442                	ld	s0,16(sp)
    80002ac6:	64a2                	ld	s1,8(sp)
    80002ac8:	6902                	ld	s2,0(sp)
    80002aca:	6105                	addi	sp,sp,32
    80002acc:	8082                	ret
      exit(-1);
    80002ace:	557d                	li	a0,-1
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	8fe080e7          	jalr	-1794(ra) # 800023ce <exit>
    80002ad8:	b7c9                	j	80002a9a <usertrap+0x90>
    if (va >= p->sz || cow(p->pagetable, va) != 0) { // check if the va is higher than the size of memory or cow failed. kill in case it is
    80002ada:	68a8                	ld	a0,80(s1)
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	e90080e7          	jalr	-368(ra) # 8000296c <cow>
    80002ae4:	d969                	beqz	a0,80002ab6 <usertrap+0xac>
    80002ae6:	b741                	j	80002a66 <usertrap+0x5c>
  } else if((which_dev = devintr()) != 0){
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	d16080e7          	jalr	-746(ra) # 800027fe <devintr>
    80002af0:	892a                	mv	s2,a0
    80002af2:	c501                	beqz	a0,80002afa <usertrap+0xf0>
  if(p->killed)
    80002af4:	549c                	lw	a5,40(s1)
    80002af6:	d3c1                	beqz	a5,80002a76 <usertrap+0x6c>
    80002af8:	bf95                	j	80002a6c <usertrap+0x62>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002afe:	5890                	lw	a2,48(s1)
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	8b850513          	addi	a0,a0,-1864 # 800083b8 <states.1722+0xf8>
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a80080e7          	jalr	-1408(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b14:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	8d050513          	addi	a0,a0,-1840 # 800083e8 <states.1722+0x128>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a68080e7          	jalr	-1432(ra) # 80000588 <printf>
    p->killed = 1;
    80002b28:	4785                	li	a5,1
    80002b2a:	d49c                	sw	a5,40(s1)
    80002b2c:	bf3d                	j	80002a6a <usertrap+0x60>
  if(p->killed)
    80002b2e:	4901                	li	s2,0
    80002b30:	bf35                	j	80002a6c <usertrap+0x62>

0000000080002b32 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	1000                	addi	s0,sp,32
    80002b3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	f78080e7          	jalr	-136(ra) # 80001ab6 <myproc>
  switch (n) {
    80002b46:	4795                	li	a5,5
    80002b48:	0497e163          	bltu	a5,s1,80002b8a <argraw+0x58>
    80002b4c:	048a                	slli	s1,s1,0x2
    80002b4e:	00006717          	auipc	a4,0x6
    80002b52:	8e270713          	addi	a4,a4,-1822 # 80008430 <states.1722+0x170>
    80002b56:	94ba                	add	s1,s1,a4
    80002b58:	409c                	lw	a5,0(s1)
    80002b5a:	97ba                	add	a5,a5,a4
    80002b5c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b5e:	6d3c                	ld	a5,88(a0)
    80002b60:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6105                	addi	sp,sp,32
    80002b6a:	8082                	ret
    return p->trapframe->a1;
    80002b6c:	6d3c                	ld	a5,88(a0)
    80002b6e:	7fa8                	ld	a0,120(a5)
    80002b70:	bfcd                	j	80002b62 <argraw+0x30>
    return p->trapframe->a2;
    80002b72:	6d3c                	ld	a5,88(a0)
    80002b74:	63c8                	ld	a0,128(a5)
    80002b76:	b7f5                	j	80002b62 <argraw+0x30>
    return p->trapframe->a3;
    80002b78:	6d3c                	ld	a5,88(a0)
    80002b7a:	67c8                	ld	a0,136(a5)
    80002b7c:	b7dd                	j	80002b62 <argraw+0x30>
    return p->trapframe->a4;
    80002b7e:	6d3c                	ld	a5,88(a0)
    80002b80:	6bc8                	ld	a0,144(a5)
    80002b82:	b7c5                	j	80002b62 <argraw+0x30>
    return p->trapframe->a5;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	6fc8                	ld	a0,152(a5)
    80002b88:	bfe9                	j	80002b62 <argraw+0x30>
  panic("argraw");
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	87e50513          	addi	a0,a0,-1922 # 80008408 <states.1722+0x148>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9ac080e7          	jalr	-1620(ra) # 8000053e <panic>

0000000080002b9a <fetchaddr>:
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	e426                	sd	s1,8(sp)
    80002ba2:	e04a                	sd	s2,0(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84aa                	mv	s1,a0
    80002ba8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	f0c080e7          	jalr	-244(ra) # 80001ab6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bb2:	653c                	ld	a5,72(a0)
    80002bb4:	02f4f863          	bgeu	s1,a5,80002be4 <fetchaddr+0x4a>
    80002bb8:	00848713          	addi	a4,s1,8
    80002bbc:	02e7e663          	bltu	a5,a4,80002be8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bc0:	46a1                	li	a3,8
    80002bc2:	8626                	mv	a2,s1
    80002bc4:	85ca                	mv	a1,s2
    80002bc6:	6928                	ld	a0,80(a0)
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	c3c080e7          	jalr	-964(ra) # 80001804 <copyin>
    80002bd0:	00a03533          	snez	a0,a0
    80002bd4:	40a00533          	neg	a0,a0
}
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6902                	ld	s2,0(sp)
    80002be0:	6105                	addi	sp,sp,32
    80002be2:	8082                	ret
    return -1;
    80002be4:	557d                	li	a0,-1
    80002be6:	bfcd                	j	80002bd8 <fetchaddr+0x3e>
    80002be8:	557d                	li	a0,-1
    80002bea:	b7fd                	j	80002bd8 <fetchaddr+0x3e>

0000000080002bec <fetchstr>:
{
    80002bec:	7179                	addi	sp,sp,-48
    80002bee:	f406                	sd	ra,40(sp)
    80002bf0:	f022                	sd	s0,32(sp)
    80002bf2:	ec26                	sd	s1,24(sp)
    80002bf4:	e84a                	sd	s2,16(sp)
    80002bf6:	e44e                	sd	s3,8(sp)
    80002bf8:	1800                	addi	s0,sp,48
    80002bfa:	892a                	mv	s2,a0
    80002bfc:	84ae                	mv	s1,a1
    80002bfe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	eb6080e7          	jalr	-330(ra) # 80001ab6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c08:	86ce                	mv	a3,s3
    80002c0a:	864a                	mv	a2,s2
    80002c0c:	85a6                	mv	a1,s1
    80002c0e:	6928                	ld	a0,80(a0)
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	c80080e7          	jalr	-896(ra) # 80001890 <copyinstr>
  if(err < 0)
    80002c18:	00054763          	bltz	a0,80002c26 <fetchstr+0x3a>
  return strlen(buf);
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	342080e7          	jalr	834(ra) # 80000f60 <strlen>
}
    80002c26:	70a2                	ld	ra,40(sp)
    80002c28:	7402                	ld	s0,32(sp)
    80002c2a:	64e2                	ld	s1,24(sp)
    80002c2c:	6942                	ld	s2,16(sp)
    80002c2e:	69a2                	ld	s3,8(sp)
    80002c30:	6145                	addi	sp,sp,48
    80002c32:	8082                	ret

0000000080002c34 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c34:	1101                	addi	sp,sp,-32
    80002c36:	ec06                	sd	ra,24(sp)
    80002c38:	e822                	sd	s0,16(sp)
    80002c3a:	e426                	sd	s1,8(sp)
    80002c3c:	1000                	addi	s0,sp,32
    80002c3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	ef2080e7          	jalr	-270(ra) # 80002b32 <argraw>
    80002c48:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c4a:	4501                	li	a0,0
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	64a2                	ld	s1,8(sp)
    80002c52:	6105                	addi	sp,sp,32
    80002c54:	8082                	ret

0000000080002c56 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
    80002c60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	ed0080e7          	jalr	-304(ra) # 80002b32 <argraw>
    80002c6a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c6c:	4501                	li	a0,0
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	e426                	sd	s1,8(sp)
    80002c80:	e04a                	sd	s2,0(sp)
    80002c82:	1000                	addi	s0,sp,32
    80002c84:	84ae                	mv	s1,a1
    80002c86:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	eaa080e7          	jalr	-342(ra) # 80002b32 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c90:	864a                	mv	a2,s2
    80002c92:	85a6                	mv	a1,s1
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	f58080e7          	jalr	-168(ra) # 80002bec <fetchstr>
}
    80002c9c:	60e2                	ld	ra,24(sp)
    80002c9e:	6442                	ld	s0,16(sp)
    80002ca0:	64a2                	ld	s1,8(sp)
    80002ca2:	6902                	ld	s2,0(sp)
    80002ca4:	6105                	addi	sp,sp,32
    80002ca6:	8082                	ret

0000000080002ca8 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	e04a                	sd	s2,0(sp)
    80002cb2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	e02080e7          	jalr	-510(ra) # 80001ab6 <myproc>
    80002cbc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cbe:	05853903          	ld	s2,88(a0)
    80002cc2:	0a893783          	ld	a5,168(s2)
    80002cc6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cca:	37fd                	addiw	a5,a5,-1
    80002ccc:	4751                	li	a4,20
    80002cce:	00f76f63          	bltu	a4,a5,80002cec <syscall+0x44>
    80002cd2:	00369713          	slli	a4,a3,0x3
    80002cd6:	00005797          	auipc	a5,0x5
    80002cda:	77278793          	addi	a5,a5,1906 # 80008448 <syscalls>
    80002cde:	97ba                	add	a5,a5,a4
    80002ce0:	639c                	ld	a5,0(a5)
    80002ce2:	c789                	beqz	a5,80002cec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ce4:	9782                	jalr	a5
    80002ce6:	06a93823          	sd	a0,112(s2)
    80002cea:	a839                	j	80002d08 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cec:	15848613          	addi	a2,s1,344
    80002cf0:	588c                	lw	a1,48(s1)
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	71e50513          	addi	a0,a0,1822 # 80008410 <states.1722+0x150>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	88e080e7          	jalr	-1906(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d02:	6cbc                	ld	a5,88(s1)
    80002d04:	577d                	li	a4,-1
    80002d06:	fbb8                	sd	a4,112(a5)
  }
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	64a2                	ld	s1,8(sp)
    80002d0e:	6902                	ld	s2,0(sp)
    80002d10:	6105                	addi	sp,sp,32
    80002d12:	8082                	ret

0000000080002d14 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d1c:	fec40593          	addi	a1,s0,-20
    80002d20:	4501                	li	a0,0
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	f12080e7          	jalr	-238(ra) # 80002c34 <argint>
    return -1;
    80002d2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d2c:	00054963          	bltz	a0,80002d3e <sys_exit+0x2a>
  exit(n);
    80002d30:	fec42503          	lw	a0,-20(s0)
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	69a080e7          	jalr	1690(ra) # 800023ce <exit>
  return 0;  // not reached
    80002d3c:	4781                	li	a5,0
}
    80002d3e:	853e                	mv	a0,a5
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	6105                	addi	sp,sp,32
    80002d46:	8082                	ret

0000000080002d48 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d48:	1141                	addi	sp,sp,-16
    80002d4a:	e406                	sd	ra,8(sp)
    80002d4c:	e022                	sd	s0,0(sp)
    80002d4e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	d66080e7          	jalr	-666(ra) # 80001ab6 <myproc>
}
    80002d58:	5908                	lw	a0,48(a0)
    80002d5a:	60a2                	ld	ra,8(sp)
    80002d5c:	6402                	ld	s0,0(sp)
    80002d5e:	0141                	addi	sp,sp,16
    80002d60:	8082                	ret

0000000080002d62 <sys_fork>:

uint64
sys_fork(void)
{
    80002d62:	1141                	addi	sp,sp,-16
    80002d64:	e406                	sd	ra,8(sp)
    80002d66:	e022                	sd	s0,0(sp)
    80002d68:	0800                	addi	s0,sp,16
  return fork();
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	11a080e7          	jalr	282(ra) # 80001e84 <fork>
}
    80002d72:	60a2                	ld	ra,8(sp)
    80002d74:	6402                	ld	s0,0(sp)
    80002d76:	0141                	addi	sp,sp,16
    80002d78:	8082                	ret

0000000080002d7a <sys_wait>:

uint64
sys_wait(void)
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d82:	fe840593          	addi	a1,s0,-24
    80002d86:	4501                	li	a0,0
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	ece080e7          	jalr	-306(ra) # 80002c56 <argaddr>
    80002d90:	87aa                	mv	a5,a0
    return -1;
    80002d92:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d94:	0007c863          	bltz	a5,80002da4 <sys_wait+0x2a>
  return wait(p);
    80002d98:	fe843503          	ld	a0,-24(s0)
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	43a080e7          	jalr	1082(ra) # 800021d6 <wait>
}
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret

0000000080002dac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dac:	7179                	addi	sp,sp,-48
    80002dae:	f406                	sd	ra,40(sp)
    80002db0:	f022                	sd	s0,32(sp)
    80002db2:	ec26                	sd	s1,24(sp)
    80002db4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002db6:	fdc40593          	addi	a1,s0,-36
    80002dba:	4501                	li	a0,0
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	e78080e7          	jalr	-392(ra) # 80002c34 <argint>
    80002dc4:	87aa                	mv	a5,a0
    return -1;
    80002dc6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dc8:	0207c063          	bltz	a5,80002de8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	cea080e7          	jalr	-790(ra) # 80001ab6 <myproc>
    80002dd4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dd6:	fdc42503          	lw	a0,-36(s0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	036080e7          	jalr	54(ra) # 80001e10 <growproc>
    80002de2:	00054863          	bltz	a0,80002df2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002de6:	8526                	mv	a0,s1
}
    80002de8:	70a2                	ld	ra,40(sp)
    80002dea:	7402                	ld	s0,32(sp)
    80002dec:	64e2                	ld	s1,24(sp)
    80002dee:	6145                	addi	sp,sp,48
    80002df0:	8082                	ret
    return -1;
    80002df2:	557d                	li	a0,-1
    80002df4:	bfd5                	j	80002de8 <sys_sbrk+0x3c>

0000000080002df6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002df6:	7139                	addi	sp,sp,-64
    80002df8:	fc06                	sd	ra,56(sp)
    80002dfa:	f822                	sd	s0,48(sp)
    80002dfc:	f426                	sd	s1,40(sp)
    80002dfe:	f04a                	sd	s2,32(sp)
    80002e00:	ec4e                	sd	s3,24(sp)
    80002e02:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e04:	fcc40593          	addi	a1,s0,-52
    80002e08:	4501                	li	a0,0
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	e2a080e7          	jalr	-470(ra) # 80002c34 <argint>
    return -1;
    80002e12:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e14:	06054563          	bltz	a0,80002e7e <sys_sleep+0x88>
  acquire(&tickslock);
    80002e18:	00034517          	auipc	a0,0x34
    80002e1c:	2b850513          	addi	a0,a0,696 # 800370d0 <tickslock>
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	ec0080e7          	jalr	-320(ra) # 80000ce0 <acquire>
  ticks0 = ticks;
    80002e28:	00006917          	auipc	s2,0x6
    80002e2c:	20892903          	lw	s2,520(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e30:	fcc42783          	lw	a5,-52(s0)
    80002e34:	cf85                	beqz	a5,80002e6c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e36:	00034997          	auipc	s3,0x34
    80002e3a:	29a98993          	addi	s3,s3,666 # 800370d0 <tickslock>
    80002e3e:	00006497          	auipc	s1,0x6
    80002e42:	1f248493          	addi	s1,s1,498 # 80009030 <ticks>
    if(myproc()->killed){
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	c70080e7          	jalr	-912(ra) # 80001ab6 <myproc>
    80002e4e:	551c                	lw	a5,40(a0)
    80002e50:	ef9d                	bnez	a5,80002e8e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e52:	85ce                	mv	a1,s3
    80002e54:	8526                	mv	a0,s1
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	31c080e7          	jalr	796(ra) # 80002172 <sleep>
  while(ticks - ticks0 < n){
    80002e5e:	409c                	lw	a5,0(s1)
    80002e60:	412787bb          	subw	a5,a5,s2
    80002e64:	fcc42703          	lw	a4,-52(s0)
    80002e68:	fce7efe3          	bltu	a5,a4,80002e46 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e6c:	00034517          	auipc	a0,0x34
    80002e70:	26450513          	addi	a0,a0,612 # 800370d0 <tickslock>
    80002e74:	ffffe097          	auipc	ra,0xffffe
    80002e78:	f20080e7          	jalr	-224(ra) # 80000d94 <release>
  return 0;
    80002e7c:	4781                	li	a5,0
}
    80002e7e:	853e                	mv	a0,a5
    80002e80:	70e2                	ld	ra,56(sp)
    80002e82:	7442                	ld	s0,48(sp)
    80002e84:	74a2                	ld	s1,40(sp)
    80002e86:	7902                	ld	s2,32(sp)
    80002e88:	69e2                	ld	s3,24(sp)
    80002e8a:	6121                	addi	sp,sp,64
    80002e8c:	8082                	ret
      release(&tickslock);
    80002e8e:	00034517          	auipc	a0,0x34
    80002e92:	24250513          	addi	a0,a0,578 # 800370d0 <tickslock>
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	efe080e7          	jalr	-258(ra) # 80000d94 <release>
      return -1;
    80002e9e:	57fd                	li	a5,-1
    80002ea0:	bff9                	j	80002e7e <sys_sleep+0x88>

0000000080002ea2 <sys_kill>:

uint64
sys_kill(void)
{
    80002ea2:	1101                	addi	sp,sp,-32
    80002ea4:	ec06                	sd	ra,24(sp)
    80002ea6:	e822                	sd	s0,16(sp)
    80002ea8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002eaa:	fec40593          	addi	a1,s0,-20
    80002eae:	4501                	li	a0,0
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	d84080e7          	jalr	-636(ra) # 80002c34 <argint>
    80002eb8:	87aa                	mv	a5,a0
    return -1;
    80002eba:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ebc:	0007c863          	bltz	a5,80002ecc <sys_kill+0x2a>
  return kill(pid);
    80002ec0:	fec42503          	lw	a0,-20(s0)
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	5e0080e7          	jalr	1504(ra) # 800024a4 <kill>
}
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	6105                	addi	sp,sp,32
    80002ed2:	8082                	ret

0000000080002ed4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	e426                	sd	s1,8(sp)
    80002edc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ede:	00034517          	auipc	a0,0x34
    80002ee2:	1f250513          	addi	a0,a0,498 # 800370d0 <tickslock>
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	dfa080e7          	jalr	-518(ra) # 80000ce0 <acquire>
  xticks = ticks;
    80002eee:	00006497          	auipc	s1,0x6
    80002ef2:	1424a483          	lw	s1,322(s1) # 80009030 <ticks>
  release(&tickslock);
    80002ef6:	00034517          	auipc	a0,0x34
    80002efa:	1da50513          	addi	a0,a0,474 # 800370d0 <tickslock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	e96080e7          	jalr	-362(ra) # 80000d94 <release>
  return xticks;
}
    80002f06:	02049513          	slli	a0,s1,0x20
    80002f0a:	9101                	srli	a0,a0,0x20
    80002f0c:	60e2                	ld	ra,24(sp)
    80002f0e:	6442                	ld	s0,16(sp)
    80002f10:	64a2                	ld	s1,8(sp)
    80002f12:	6105                	addi	sp,sp,32
    80002f14:	8082                	ret

0000000080002f16 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f16:	7179                	addi	sp,sp,-48
    80002f18:	f406                	sd	ra,40(sp)
    80002f1a:	f022                	sd	s0,32(sp)
    80002f1c:	ec26                	sd	s1,24(sp)
    80002f1e:	e84a                	sd	s2,16(sp)
    80002f20:	e44e                	sd	s3,8(sp)
    80002f22:	e052                	sd	s4,0(sp)
    80002f24:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f26:	00005597          	auipc	a1,0x5
    80002f2a:	5d258593          	addi	a1,a1,1490 # 800084f8 <syscalls+0xb0>
    80002f2e:	00034517          	auipc	a0,0x34
    80002f32:	1ba50513          	addi	a0,a0,442 # 800370e8 <bcache>
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	d1a080e7          	jalr	-742(ra) # 80000c50 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f3e:	0003c797          	auipc	a5,0x3c
    80002f42:	1aa78793          	addi	a5,a5,426 # 8003f0e8 <bcache+0x8000>
    80002f46:	0003c717          	auipc	a4,0x3c
    80002f4a:	40a70713          	addi	a4,a4,1034 # 8003f350 <bcache+0x8268>
    80002f4e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f52:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f56:	00034497          	auipc	s1,0x34
    80002f5a:	1aa48493          	addi	s1,s1,426 # 80037100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f5e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f60:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f62:	00005a17          	auipc	s4,0x5
    80002f66:	59ea0a13          	addi	s4,s4,1438 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f6a:	2b893783          	ld	a5,696(s2)
    80002f6e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f70:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f74:	85d2                	mv	a1,s4
    80002f76:	01048513          	addi	a0,s1,16
    80002f7a:	00001097          	auipc	ra,0x1
    80002f7e:	4bc080e7          	jalr	1212(ra) # 80004436 <initsleeplock>
    bcache.head.next->prev = b;
    80002f82:	2b893783          	ld	a5,696(s2)
    80002f86:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f88:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f8c:	45848493          	addi	s1,s1,1112
    80002f90:	fd349de3          	bne	s1,s3,80002f6a <binit+0x54>
  }
}
    80002f94:	70a2                	ld	ra,40(sp)
    80002f96:	7402                	ld	s0,32(sp)
    80002f98:	64e2                	ld	s1,24(sp)
    80002f9a:	6942                	ld	s2,16(sp)
    80002f9c:	69a2                	ld	s3,8(sp)
    80002f9e:	6a02                	ld	s4,0(sp)
    80002fa0:	6145                	addi	sp,sp,48
    80002fa2:	8082                	ret

0000000080002fa4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fa4:	7179                	addi	sp,sp,-48
    80002fa6:	f406                	sd	ra,40(sp)
    80002fa8:	f022                	sd	s0,32(sp)
    80002faa:	ec26                	sd	s1,24(sp)
    80002fac:	e84a                	sd	s2,16(sp)
    80002fae:	e44e                	sd	s3,8(sp)
    80002fb0:	1800                	addi	s0,sp,48
    80002fb2:	89aa                	mv	s3,a0
    80002fb4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fb6:	00034517          	auipc	a0,0x34
    80002fba:	13250513          	addi	a0,a0,306 # 800370e8 <bcache>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	d22080e7          	jalr	-734(ra) # 80000ce0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fc6:	0003c497          	auipc	s1,0x3c
    80002fca:	3da4b483          	ld	s1,986(s1) # 8003f3a0 <bcache+0x82b8>
    80002fce:	0003c797          	auipc	a5,0x3c
    80002fd2:	38278793          	addi	a5,a5,898 # 8003f350 <bcache+0x8268>
    80002fd6:	02f48f63          	beq	s1,a5,80003014 <bread+0x70>
    80002fda:	873e                	mv	a4,a5
    80002fdc:	a021                	j	80002fe4 <bread+0x40>
    80002fde:	68a4                	ld	s1,80(s1)
    80002fe0:	02e48a63          	beq	s1,a4,80003014 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fe4:	449c                	lw	a5,8(s1)
    80002fe6:	ff379ce3          	bne	a5,s3,80002fde <bread+0x3a>
    80002fea:	44dc                	lw	a5,12(s1)
    80002fec:	ff2799e3          	bne	a5,s2,80002fde <bread+0x3a>
      b->refcnt++;
    80002ff0:	40bc                	lw	a5,64(s1)
    80002ff2:	2785                	addiw	a5,a5,1
    80002ff4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ff6:	00034517          	auipc	a0,0x34
    80002ffa:	0f250513          	addi	a0,a0,242 # 800370e8 <bcache>
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	d96080e7          	jalr	-618(ra) # 80000d94 <release>
      acquiresleep(&b->lock);
    80003006:	01048513          	addi	a0,s1,16
    8000300a:	00001097          	auipc	ra,0x1
    8000300e:	466080e7          	jalr	1126(ra) # 80004470 <acquiresleep>
      return b;
    80003012:	a8b9                	j	80003070 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003014:	0003c497          	auipc	s1,0x3c
    80003018:	3844b483          	ld	s1,900(s1) # 8003f398 <bcache+0x82b0>
    8000301c:	0003c797          	auipc	a5,0x3c
    80003020:	33478793          	addi	a5,a5,820 # 8003f350 <bcache+0x8268>
    80003024:	00f48863          	beq	s1,a5,80003034 <bread+0x90>
    80003028:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000302a:	40bc                	lw	a5,64(s1)
    8000302c:	cf81                	beqz	a5,80003044 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302e:	64a4                	ld	s1,72(s1)
    80003030:	fee49de3          	bne	s1,a4,8000302a <bread+0x86>
  panic("bget: no buffers");
    80003034:	00005517          	auipc	a0,0x5
    80003038:	4d450513          	addi	a0,a0,1236 # 80008508 <syscalls+0xc0>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	502080e7          	jalr	1282(ra) # 8000053e <panic>
      b->dev = dev;
    80003044:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003048:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000304c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003050:	4785                	li	a5,1
    80003052:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003054:	00034517          	auipc	a0,0x34
    80003058:	09450513          	addi	a0,a0,148 # 800370e8 <bcache>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	d38080e7          	jalr	-712(ra) # 80000d94 <release>
      acquiresleep(&b->lock);
    80003064:	01048513          	addi	a0,s1,16
    80003068:	00001097          	auipc	ra,0x1
    8000306c:	408080e7          	jalr	1032(ra) # 80004470 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003070:	409c                	lw	a5,0(s1)
    80003072:	cb89                	beqz	a5,80003084 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003074:	8526                	mv	a0,s1
    80003076:	70a2                	ld	ra,40(sp)
    80003078:	7402                	ld	s0,32(sp)
    8000307a:	64e2                	ld	s1,24(sp)
    8000307c:	6942                	ld	s2,16(sp)
    8000307e:	69a2                	ld	s3,8(sp)
    80003080:	6145                	addi	sp,sp,48
    80003082:	8082                	ret
    virtio_disk_rw(b, 0);
    80003084:	4581                	li	a1,0
    80003086:	8526                	mv	a0,s1
    80003088:	00003097          	auipc	ra,0x3
    8000308c:	f0e080e7          	jalr	-242(ra) # 80005f96 <virtio_disk_rw>
    b->valid = 1;
    80003090:	4785                	li	a5,1
    80003092:	c09c                	sw	a5,0(s1)
  return b;
    80003094:	b7c5                	j	80003074 <bread+0xd0>

0000000080003096 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a2:	0541                	addi	a0,a0,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	466080e7          	jalr	1126(ra) # 8000450a <holdingsleep>
    800030ac:	cd01                	beqz	a0,800030c4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030ae:	4585                	li	a1,1
    800030b0:	8526                	mv	a0,s1
    800030b2:	00003097          	auipc	ra,0x3
    800030b6:	ee4080e7          	jalr	-284(ra) # 80005f96 <virtio_disk_rw>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6105                	addi	sp,sp,32
    800030c2:	8082                	ret
    panic("bwrite");
    800030c4:	00005517          	auipc	a0,0x5
    800030c8:	45c50513          	addi	a0,a0,1116 # 80008520 <syscalls+0xd8>
    800030cc:	ffffd097          	auipc	ra,0xffffd
    800030d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>

00000000800030d4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	e426                	sd	s1,8(sp)
    800030dc:	e04a                	sd	s2,0(sp)
    800030de:	1000                	addi	s0,sp,32
    800030e0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e2:	01050913          	addi	s2,a0,16
    800030e6:	854a                	mv	a0,s2
    800030e8:	00001097          	auipc	ra,0x1
    800030ec:	422080e7          	jalr	1058(ra) # 8000450a <holdingsleep>
    800030f0:	c92d                	beqz	a0,80003162 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030f2:	854a                	mv	a0,s2
    800030f4:	00001097          	auipc	ra,0x1
    800030f8:	3d2080e7          	jalr	978(ra) # 800044c6 <releasesleep>

  acquire(&bcache.lock);
    800030fc:	00034517          	auipc	a0,0x34
    80003100:	fec50513          	addi	a0,a0,-20 # 800370e8 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	bdc080e7          	jalr	-1060(ra) # 80000ce0 <acquire>
  b->refcnt--;
    8000310c:	40bc                	lw	a5,64(s1)
    8000310e:	37fd                	addiw	a5,a5,-1
    80003110:	0007871b          	sext.w	a4,a5
    80003114:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003116:	eb05                	bnez	a4,80003146 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003118:	68bc                	ld	a5,80(s1)
    8000311a:	64b8                	ld	a4,72(s1)
    8000311c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000311e:	64bc                	ld	a5,72(s1)
    80003120:	68b8                	ld	a4,80(s1)
    80003122:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003124:	0003c797          	auipc	a5,0x3c
    80003128:	fc478793          	addi	a5,a5,-60 # 8003f0e8 <bcache+0x8000>
    8000312c:	2b87b703          	ld	a4,696(a5)
    80003130:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003132:	0003c717          	auipc	a4,0x3c
    80003136:	21e70713          	addi	a4,a4,542 # 8003f350 <bcache+0x8268>
    8000313a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000313c:	2b87b703          	ld	a4,696(a5)
    80003140:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003142:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003146:	00034517          	auipc	a0,0x34
    8000314a:	fa250513          	addi	a0,a0,-94 # 800370e8 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	c46080e7          	jalr	-954(ra) # 80000d94 <release>
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	64a2                	ld	s1,8(sp)
    8000315c:	6902                	ld	s2,0(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret
    panic("brelse");
    80003162:	00005517          	auipc	a0,0x5
    80003166:	3c650513          	addi	a0,a0,966 # 80008528 <syscalls+0xe0>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>

0000000080003172 <bpin>:

void
bpin(struct buf *b) {
    80003172:	1101                	addi	sp,sp,-32
    80003174:	ec06                	sd	ra,24(sp)
    80003176:	e822                	sd	s0,16(sp)
    80003178:	e426                	sd	s1,8(sp)
    8000317a:	1000                	addi	s0,sp,32
    8000317c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000317e:	00034517          	auipc	a0,0x34
    80003182:	f6a50513          	addi	a0,a0,-150 # 800370e8 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b5a080e7          	jalr	-1190(ra) # 80000ce0 <acquire>
  b->refcnt++;
    8000318e:	40bc                	lw	a5,64(s1)
    80003190:	2785                	addiw	a5,a5,1
    80003192:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003194:	00034517          	auipc	a0,0x34
    80003198:	f5450513          	addi	a0,a0,-172 # 800370e8 <bcache>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	bf8080e7          	jalr	-1032(ra) # 80000d94 <release>
}
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	64a2                	ld	s1,8(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret

00000000800031ae <bunpin>:

void
bunpin(struct buf *b) {
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ba:	00034517          	auipc	a0,0x34
    800031be:	f2e50513          	addi	a0,a0,-210 # 800370e8 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b1e080e7          	jalr	-1250(ra) # 80000ce0 <acquire>
  b->refcnt--;
    800031ca:	40bc                	lw	a5,64(s1)
    800031cc:	37fd                	addiw	a5,a5,-1
    800031ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d0:	00034517          	auipc	a0,0x34
    800031d4:	f1850513          	addi	a0,a0,-232 # 800370e8 <bcache>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	bbc080e7          	jalr	-1092(ra) # 80000d94 <release>
}
    800031e0:	60e2                	ld	ra,24(sp)
    800031e2:	6442                	ld	s0,16(sp)
    800031e4:	64a2                	ld	s1,8(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret

00000000800031ea <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	e04a                	sd	s2,0(sp)
    800031f4:	1000                	addi	s0,sp,32
    800031f6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031f8:	00d5d59b          	srliw	a1,a1,0xd
    800031fc:	0003c797          	auipc	a5,0x3c
    80003200:	5c87a783          	lw	a5,1480(a5) # 8003f7c4 <sb+0x1c>
    80003204:	9dbd                	addw	a1,a1,a5
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	d9e080e7          	jalr	-610(ra) # 80002fa4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000320e:	0074f713          	andi	a4,s1,7
    80003212:	4785                	li	a5,1
    80003214:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003218:	14ce                	slli	s1,s1,0x33
    8000321a:	90d9                	srli	s1,s1,0x36
    8000321c:	00950733          	add	a4,a0,s1
    80003220:	05874703          	lbu	a4,88(a4)
    80003224:	00e7f6b3          	and	a3,a5,a4
    80003228:	c69d                	beqz	a3,80003256 <bfree+0x6c>
    8000322a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000322c:	94aa                	add	s1,s1,a0
    8000322e:	fff7c793          	not	a5,a5
    80003232:	8ff9                	and	a5,a5,a4
    80003234:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	118080e7          	jalr	280(ra) # 80004350 <log_write>
  brelse(bp);
    80003240:	854a                	mv	a0,s2
    80003242:	00000097          	auipc	ra,0x0
    80003246:	e92080e7          	jalr	-366(ra) # 800030d4 <brelse>
}
    8000324a:	60e2                	ld	ra,24(sp)
    8000324c:	6442                	ld	s0,16(sp)
    8000324e:	64a2                	ld	s1,8(sp)
    80003250:	6902                	ld	s2,0(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret
    panic("freeing free block");
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	2da50513          	addi	a0,a0,730 # 80008530 <syscalls+0xe8>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>

0000000080003266 <balloc>:
{
    80003266:	711d                	addi	sp,sp,-96
    80003268:	ec86                	sd	ra,88(sp)
    8000326a:	e8a2                	sd	s0,80(sp)
    8000326c:	e4a6                	sd	s1,72(sp)
    8000326e:	e0ca                	sd	s2,64(sp)
    80003270:	fc4e                	sd	s3,56(sp)
    80003272:	f852                	sd	s4,48(sp)
    80003274:	f456                	sd	s5,40(sp)
    80003276:	f05a                	sd	s6,32(sp)
    80003278:	ec5e                	sd	s7,24(sp)
    8000327a:	e862                	sd	s8,16(sp)
    8000327c:	e466                	sd	s9,8(sp)
    8000327e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003280:	0003c797          	auipc	a5,0x3c
    80003284:	52c7a783          	lw	a5,1324(a5) # 8003f7ac <sb+0x4>
    80003288:	cbd1                	beqz	a5,8000331c <balloc+0xb6>
    8000328a:	8baa                	mv	s7,a0
    8000328c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000328e:	0003cb17          	auipc	s6,0x3c
    80003292:	51ab0b13          	addi	s6,s6,1306 # 8003f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003296:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003298:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000329a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000329c:	6c89                	lui	s9,0x2
    8000329e:	a831                	j	800032ba <balloc+0x54>
    brelse(bp);
    800032a0:	854a                	mv	a0,s2
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	e32080e7          	jalr	-462(ra) # 800030d4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032aa:	015c87bb          	addw	a5,s9,s5
    800032ae:	00078a9b          	sext.w	s5,a5
    800032b2:	004b2703          	lw	a4,4(s6)
    800032b6:	06eaf363          	bgeu	s5,a4,8000331c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032ba:	41fad79b          	sraiw	a5,s5,0x1f
    800032be:	0137d79b          	srliw	a5,a5,0x13
    800032c2:	015787bb          	addw	a5,a5,s5
    800032c6:	40d7d79b          	sraiw	a5,a5,0xd
    800032ca:	01cb2583          	lw	a1,28(s6)
    800032ce:	9dbd                	addw	a1,a1,a5
    800032d0:	855e                	mv	a0,s7
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	cd2080e7          	jalr	-814(ra) # 80002fa4 <bread>
    800032da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032dc:	004b2503          	lw	a0,4(s6)
    800032e0:	000a849b          	sext.w	s1,s5
    800032e4:	8662                	mv	a2,s8
    800032e6:	faa4fde3          	bgeu	s1,a0,800032a0 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032ea:	41f6579b          	sraiw	a5,a2,0x1f
    800032ee:	01d7d69b          	srliw	a3,a5,0x1d
    800032f2:	00c6873b          	addw	a4,a3,a2
    800032f6:	00777793          	andi	a5,a4,7
    800032fa:	9f95                	subw	a5,a5,a3
    800032fc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003300:	4037571b          	sraiw	a4,a4,0x3
    80003304:	00e906b3          	add	a3,s2,a4
    80003308:	0586c683          	lbu	a3,88(a3)
    8000330c:	00d7f5b3          	and	a1,a5,a3
    80003310:	cd91                	beqz	a1,8000332c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003312:	2605                	addiw	a2,a2,1
    80003314:	2485                	addiw	s1,s1,1
    80003316:	fd4618e3          	bne	a2,s4,800032e6 <balloc+0x80>
    8000331a:	b759                	j	800032a0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000331c:	00005517          	auipc	a0,0x5
    80003320:	22c50513          	addi	a0,a0,556 # 80008548 <syscalls+0x100>
    80003324:	ffffd097          	auipc	ra,0xffffd
    80003328:	21a080e7          	jalr	538(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000332c:	974a                	add	a4,a4,s2
    8000332e:	8fd5                	or	a5,a5,a3
    80003330:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003334:	854a                	mv	a0,s2
    80003336:	00001097          	auipc	ra,0x1
    8000333a:	01a080e7          	jalr	26(ra) # 80004350 <log_write>
        brelse(bp);
    8000333e:	854a                	mv	a0,s2
    80003340:	00000097          	auipc	ra,0x0
    80003344:	d94080e7          	jalr	-620(ra) # 800030d4 <brelse>
  bp = bread(dev, bno);
    80003348:	85a6                	mv	a1,s1
    8000334a:	855e                	mv	a0,s7
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	c58080e7          	jalr	-936(ra) # 80002fa4 <bread>
    80003354:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003356:	40000613          	li	a2,1024
    8000335a:	4581                	li	a1,0
    8000335c:	05850513          	addi	a0,a0,88
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	a7c080e7          	jalr	-1412(ra) # 80000ddc <memset>
  log_write(bp);
    80003368:	854a                	mv	a0,s2
    8000336a:	00001097          	auipc	ra,0x1
    8000336e:	fe6080e7          	jalr	-26(ra) # 80004350 <log_write>
  brelse(bp);
    80003372:	854a                	mv	a0,s2
    80003374:	00000097          	auipc	ra,0x0
    80003378:	d60080e7          	jalr	-672(ra) # 800030d4 <brelse>
}
    8000337c:	8526                	mv	a0,s1
    8000337e:	60e6                	ld	ra,88(sp)
    80003380:	6446                	ld	s0,80(sp)
    80003382:	64a6                	ld	s1,72(sp)
    80003384:	6906                	ld	s2,64(sp)
    80003386:	79e2                	ld	s3,56(sp)
    80003388:	7a42                	ld	s4,48(sp)
    8000338a:	7aa2                	ld	s5,40(sp)
    8000338c:	7b02                	ld	s6,32(sp)
    8000338e:	6be2                	ld	s7,24(sp)
    80003390:	6c42                	ld	s8,16(sp)
    80003392:	6ca2                	ld	s9,8(sp)
    80003394:	6125                	addi	sp,sp,96
    80003396:	8082                	ret

0000000080003398 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003398:	7179                	addi	sp,sp,-48
    8000339a:	f406                	sd	ra,40(sp)
    8000339c:	f022                	sd	s0,32(sp)
    8000339e:	ec26                	sd	s1,24(sp)
    800033a0:	e84a                	sd	s2,16(sp)
    800033a2:	e44e                	sd	s3,8(sp)
    800033a4:	e052                	sd	s4,0(sp)
    800033a6:	1800                	addi	s0,sp,48
    800033a8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033aa:	47ad                	li	a5,11
    800033ac:	04b7fe63          	bgeu	a5,a1,80003408 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033b0:	ff45849b          	addiw	s1,a1,-12
    800033b4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033b8:	0ff00793          	li	a5,255
    800033bc:	0ae7e363          	bltu	a5,a4,80003462 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033c0:	08052583          	lw	a1,128(a0)
    800033c4:	c5ad                	beqz	a1,8000342e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033c6:	00092503          	lw	a0,0(s2)
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	bda080e7          	jalr	-1062(ra) # 80002fa4 <bread>
    800033d2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033d4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033d8:	02049593          	slli	a1,s1,0x20
    800033dc:	9181                	srli	a1,a1,0x20
    800033de:	058a                	slli	a1,a1,0x2
    800033e0:	00b784b3          	add	s1,a5,a1
    800033e4:	0004a983          	lw	s3,0(s1)
    800033e8:	04098d63          	beqz	s3,80003442 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033ec:	8552                	mv	a0,s4
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	ce6080e7          	jalr	-794(ra) # 800030d4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033f6:	854e                	mv	a0,s3
    800033f8:	70a2                	ld	ra,40(sp)
    800033fa:	7402                	ld	s0,32(sp)
    800033fc:	64e2                	ld	s1,24(sp)
    800033fe:	6942                	ld	s2,16(sp)
    80003400:	69a2                	ld	s3,8(sp)
    80003402:	6a02                	ld	s4,0(sp)
    80003404:	6145                	addi	sp,sp,48
    80003406:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003408:	02059493          	slli	s1,a1,0x20
    8000340c:	9081                	srli	s1,s1,0x20
    8000340e:	048a                	slli	s1,s1,0x2
    80003410:	94aa                	add	s1,s1,a0
    80003412:	0504a983          	lw	s3,80(s1)
    80003416:	fe0990e3          	bnez	s3,800033f6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000341a:	4108                	lw	a0,0(a0)
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	e4a080e7          	jalr	-438(ra) # 80003266 <balloc>
    80003424:	0005099b          	sext.w	s3,a0
    80003428:	0534a823          	sw	s3,80(s1)
    8000342c:	b7e9                	j	800033f6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000342e:	4108                	lw	a0,0(a0)
    80003430:	00000097          	auipc	ra,0x0
    80003434:	e36080e7          	jalr	-458(ra) # 80003266 <balloc>
    80003438:	0005059b          	sext.w	a1,a0
    8000343c:	08b92023          	sw	a1,128(s2)
    80003440:	b759                	j	800033c6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003442:	00092503          	lw	a0,0(s2)
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	e20080e7          	jalr	-480(ra) # 80003266 <balloc>
    8000344e:	0005099b          	sext.w	s3,a0
    80003452:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003456:	8552                	mv	a0,s4
    80003458:	00001097          	auipc	ra,0x1
    8000345c:	ef8080e7          	jalr	-264(ra) # 80004350 <log_write>
    80003460:	b771                	j	800033ec <bmap+0x54>
  panic("bmap: out of range");
    80003462:	00005517          	auipc	a0,0x5
    80003466:	0fe50513          	addi	a0,a0,254 # 80008560 <syscalls+0x118>
    8000346a:	ffffd097          	auipc	ra,0xffffd
    8000346e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>

0000000080003472 <iget>:
{
    80003472:	7179                	addi	sp,sp,-48
    80003474:	f406                	sd	ra,40(sp)
    80003476:	f022                	sd	s0,32(sp)
    80003478:	ec26                	sd	s1,24(sp)
    8000347a:	e84a                	sd	s2,16(sp)
    8000347c:	e44e                	sd	s3,8(sp)
    8000347e:	e052                	sd	s4,0(sp)
    80003480:	1800                	addi	s0,sp,48
    80003482:	89aa                	mv	s3,a0
    80003484:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003486:	0003c517          	auipc	a0,0x3c
    8000348a:	34250513          	addi	a0,a0,834 # 8003f7c8 <itable>
    8000348e:	ffffe097          	auipc	ra,0xffffe
    80003492:	852080e7          	jalr	-1966(ra) # 80000ce0 <acquire>
  empty = 0;
    80003496:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003498:	0003c497          	auipc	s1,0x3c
    8000349c:	34848493          	addi	s1,s1,840 # 8003f7e0 <itable+0x18>
    800034a0:	0003e697          	auipc	a3,0x3e
    800034a4:	dd068693          	addi	a3,a3,-560 # 80041270 <log>
    800034a8:	a039                	j	800034b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034aa:	02090b63          	beqz	s2,800034e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034ae:	08848493          	addi	s1,s1,136
    800034b2:	02d48a63          	beq	s1,a3,800034e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034b6:	449c                	lw	a5,8(s1)
    800034b8:	fef059e3          	blez	a5,800034aa <iget+0x38>
    800034bc:	4098                	lw	a4,0(s1)
    800034be:	ff3716e3          	bne	a4,s3,800034aa <iget+0x38>
    800034c2:	40d8                	lw	a4,4(s1)
    800034c4:	ff4713e3          	bne	a4,s4,800034aa <iget+0x38>
      ip->ref++;
    800034c8:	2785                	addiw	a5,a5,1
    800034ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034cc:	0003c517          	auipc	a0,0x3c
    800034d0:	2fc50513          	addi	a0,a0,764 # 8003f7c8 <itable>
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	8c0080e7          	jalr	-1856(ra) # 80000d94 <release>
      return ip;
    800034dc:	8926                	mv	s2,s1
    800034de:	a03d                	j	8000350c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e0:	f7f9                	bnez	a5,800034ae <iget+0x3c>
    800034e2:	8926                	mv	s2,s1
    800034e4:	b7e9                	j	800034ae <iget+0x3c>
  if(empty == 0)
    800034e6:	02090c63          	beqz	s2,8000351e <iget+0xac>
  ip->dev = dev;
    800034ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f2:	4785                	li	a5,1
    800034f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034fc:	0003c517          	auipc	a0,0x3c
    80003500:	2cc50513          	addi	a0,a0,716 # 8003f7c8 <itable>
    80003504:	ffffe097          	auipc	ra,0xffffe
    80003508:	890080e7          	jalr	-1904(ra) # 80000d94 <release>
}
    8000350c:	854a                	mv	a0,s2
    8000350e:	70a2                	ld	ra,40(sp)
    80003510:	7402                	ld	s0,32(sp)
    80003512:	64e2                	ld	s1,24(sp)
    80003514:	6942                	ld	s2,16(sp)
    80003516:	69a2                	ld	s3,8(sp)
    80003518:	6a02                	ld	s4,0(sp)
    8000351a:	6145                	addi	sp,sp,48
    8000351c:	8082                	ret
    panic("iget: no inodes");
    8000351e:	00005517          	auipc	a0,0x5
    80003522:	05a50513          	addi	a0,a0,90 # 80008578 <syscalls+0x130>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	018080e7          	jalr	24(ra) # 8000053e <panic>

000000008000352e <fsinit>:
fsinit(int dev) {
    8000352e:	7179                	addi	sp,sp,-48
    80003530:	f406                	sd	ra,40(sp)
    80003532:	f022                	sd	s0,32(sp)
    80003534:	ec26                	sd	s1,24(sp)
    80003536:	e84a                	sd	s2,16(sp)
    80003538:	e44e                	sd	s3,8(sp)
    8000353a:	1800                	addi	s0,sp,48
    8000353c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000353e:	4585                	li	a1,1
    80003540:	00000097          	auipc	ra,0x0
    80003544:	a64080e7          	jalr	-1436(ra) # 80002fa4 <bread>
    80003548:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000354a:	0003c997          	auipc	s3,0x3c
    8000354e:	25e98993          	addi	s3,s3,606 # 8003f7a8 <sb>
    80003552:	02000613          	li	a2,32
    80003556:	05850593          	addi	a1,a0,88
    8000355a:	854e                	mv	a0,s3
    8000355c:	ffffe097          	auipc	ra,0xffffe
    80003560:	8e0080e7          	jalr	-1824(ra) # 80000e3c <memmove>
  brelse(bp);
    80003564:	8526                	mv	a0,s1
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	b6e080e7          	jalr	-1170(ra) # 800030d4 <brelse>
  if(sb.magic != FSMAGIC)
    8000356e:	0009a703          	lw	a4,0(s3)
    80003572:	102037b7          	lui	a5,0x10203
    80003576:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000357a:	02f71263          	bne	a4,a5,8000359e <fsinit+0x70>
  initlog(dev, &sb);
    8000357e:	0003c597          	auipc	a1,0x3c
    80003582:	22a58593          	addi	a1,a1,554 # 8003f7a8 <sb>
    80003586:	854a                	mv	a0,s2
    80003588:	00001097          	auipc	ra,0x1
    8000358c:	b4c080e7          	jalr	-1204(ra) # 800040d4 <initlog>
}
    80003590:	70a2                	ld	ra,40(sp)
    80003592:	7402                	ld	s0,32(sp)
    80003594:	64e2                	ld	s1,24(sp)
    80003596:	6942                	ld	s2,16(sp)
    80003598:	69a2                	ld	s3,8(sp)
    8000359a:	6145                	addi	sp,sp,48
    8000359c:	8082                	ret
    panic("invalid file system");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	fea50513          	addi	a0,a0,-22 # 80008588 <syscalls+0x140>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>

00000000800035ae <iinit>:
{
    800035ae:	7179                	addi	sp,sp,-48
    800035b0:	f406                	sd	ra,40(sp)
    800035b2:	f022                	sd	s0,32(sp)
    800035b4:	ec26                	sd	s1,24(sp)
    800035b6:	e84a                	sd	s2,16(sp)
    800035b8:	e44e                	sd	s3,8(sp)
    800035ba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035bc:	00005597          	auipc	a1,0x5
    800035c0:	fe458593          	addi	a1,a1,-28 # 800085a0 <syscalls+0x158>
    800035c4:	0003c517          	auipc	a0,0x3c
    800035c8:	20450513          	addi	a0,a0,516 # 8003f7c8 <itable>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	684080e7          	jalr	1668(ra) # 80000c50 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035d4:	0003c497          	auipc	s1,0x3c
    800035d8:	21c48493          	addi	s1,s1,540 # 8003f7f0 <itable+0x28>
    800035dc:	0003e997          	auipc	s3,0x3e
    800035e0:	ca498993          	addi	s3,s3,-860 # 80041280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035e4:	00005917          	auipc	s2,0x5
    800035e8:	fc490913          	addi	s2,s2,-60 # 800085a8 <syscalls+0x160>
    800035ec:	85ca                	mv	a1,s2
    800035ee:	8526                	mv	a0,s1
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	e46080e7          	jalr	-442(ra) # 80004436 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035f8:	08848493          	addi	s1,s1,136
    800035fc:	ff3498e3          	bne	s1,s3,800035ec <iinit+0x3e>
}
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6942                	ld	s2,16(sp)
    80003608:	69a2                	ld	s3,8(sp)
    8000360a:	6145                	addi	sp,sp,48
    8000360c:	8082                	ret

000000008000360e <ialloc>:
{
    8000360e:	715d                	addi	sp,sp,-80
    80003610:	e486                	sd	ra,72(sp)
    80003612:	e0a2                	sd	s0,64(sp)
    80003614:	fc26                	sd	s1,56(sp)
    80003616:	f84a                	sd	s2,48(sp)
    80003618:	f44e                	sd	s3,40(sp)
    8000361a:	f052                	sd	s4,32(sp)
    8000361c:	ec56                	sd	s5,24(sp)
    8000361e:	e85a                	sd	s6,16(sp)
    80003620:	e45e                	sd	s7,8(sp)
    80003622:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003624:	0003c717          	auipc	a4,0x3c
    80003628:	19072703          	lw	a4,400(a4) # 8003f7b4 <sb+0xc>
    8000362c:	4785                	li	a5,1
    8000362e:	04e7fa63          	bgeu	a5,a4,80003682 <ialloc+0x74>
    80003632:	8aaa                	mv	s5,a0
    80003634:	8bae                	mv	s7,a1
    80003636:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003638:	0003ca17          	auipc	s4,0x3c
    8000363c:	170a0a13          	addi	s4,s4,368 # 8003f7a8 <sb>
    80003640:	00048b1b          	sext.w	s6,s1
    80003644:	0044d593          	srli	a1,s1,0x4
    80003648:	018a2783          	lw	a5,24(s4)
    8000364c:	9dbd                	addw	a1,a1,a5
    8000364e:	8556                	mv	a0,s5
    80003650:	00000097          	auipc	ra,0x0
    80003654:	954080e7          	jalr	-1708(ra) # 80002fa4 <bread>
    80003658:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000365a:	05850993          	addi	s3,a0,88
    8000365e:	00f4f793          	andi	a5,s1,15
    80003662:	079a                	slli	a5,a5,0x6
    80003664:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003666:	00099783          	lh	a5,0(s3)
    8000366a:	c785                	beqz	a5,80003692 <ialloc+0x84>
    brelse(bp);
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	a68080e7          	jalr	-1432(ra) # 800030d4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003674:	0485                	addi	s1,s1,1
    80003676:	00ca2703          	lw	a4,12(s4)
    8000367a:	0004879b          	sext.w	a5,s1
    8000367e:	fce7e1e3          	bltu	a5,a4,80003640 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003682:	00005517          	auipc	a0,0x5
    80003686:	f2e50513          	addi	a0,a0,-210 # 800085b0 <syscalls+0x168>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	eb4080e7          	jalr	-332(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003692:	04000613          	li	a2,64
    80003696:	4581                	li	a1,0
    80003698:	854e                	mv	a0,s3
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	742080e7          	jalr	1858(ra) # 80000ddc <memset>
      dip->type = type;
    800036a2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036a6:	854a                	mv	a0,s2
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	ca8080e7          	jalr	-856(ra) # 80004350 <log_write>
      brelse(bp);
    800036b0:	854a                	mv	a0,s2
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	a22080e7          	jalr	-1502(ra) # 800030d4 <brelse>
      return iget(dev, inum);
    800036ba:	85da                	mv	a1,s6
    800036bc:	8556                	mv	a0,s5
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	db4080e7          	jalr	-588(ra) # 80003472 <iget>
}
    800036c6:	60a6                	ld	ra,72(sp)
    800036c8:	6406                	ld	s0,64(sp)
    800036ca:	74e2                	ld	s1,56(sp)
    800036cc:	7942                	ld	s2,48(sp)
    800036ce:	79a2                	ld	s3,40(sp)
    800036d0:	7a02                	ld	s4,32(sp)
    800036d2:	6ae2                	ld	s5,24(sp)
    800036d4:	6b42                	ld	s6,16(sp)
    800036d6:	6ba2                	ld	s7,8(sp)
    800036d8:	6161                	addi	sp,sp,80
    800036da:	8082                	ret

00000000800036dc <iupdate>:
{
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	e04a                	sd	s2,0(sp)
    800036e6:	1000                	addi	s0,sp,32
    800036e8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ea:	415c                	lw	a5,4(a0)
    800036ec:	0047d79b          	srliw	a5,a5,0x4
    800036f0:	0003c597          	auipc	a1,0x3c
    800036f4:	0d05a583          	lw	a1,208(a1) # 8003f7c0 <sb+0x18>
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	4108                	lw	a0,0(a0)
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	8a8080e7          	jalr	-1880(ra) # 80002fa4 <bread>
    80003704:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003706:	05850793          	addi	a5,a0,88
    8000370a:	40c8                	lw	a0,4(s1)
    8000370c:	893d                	andi	a0,a0,15
    8000370e:	051a                	slli	a0,a0,0x6
    80003710:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003712:	04449703          	lh	a4,68(s1)
    80003716:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000371a:	04649703          	lh	a4,70(s1)
    8000371e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003722:	04849703          	lh	a4,72(s1)
    80003726:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000372a:	04a49703          	lh	a4,74(s1)
    8000372e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003732:	44f8                	lw	a4,76(s1)
    80003734:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003736:	03400613          	li	a2,52
    8000373a:	05048593          	addi	a1,s1,80
    8000373e:	0531                	addi	a0,a0,12
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	6fc080e7          	jalr	1788(ra) # 80000e3c <memmove>
  log_write(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	c06080e7          	jalr	-1018(ra) # 80004350 <log_write>
  brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00000097          	auipc	ra,0x0
    80003758:	980080e7          	jalr	-1664(ra) # 800030d4 <brelse>
}
    8000375c:	60e2                	ld	ra,24(sp)
    8000375e:	6442                	ld	s0,16(sp)
    80003760:	64a2                	ld	s1,8(sp)
    80003762:	6902                	ld	s2,0(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <idup>:
{
    80003768:	1101                	addi	sp,sp,-32
    8000376a:	ec06                	sd	ra,24(sp)
    8000376c:	e822                	sd	s0,16(sp)
    8000376e:	e426                	sd	s1,8(sp)
    80003770:	1000                	addi	s0,sp,32
    80003772:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003774:	0003c517          	auipc	a0,0x3c
    80003778:	05450513          	addi	a0,a0,84 # 8003f7c8 <itable>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	564080e7          	jalr	1380(ra) # 80000ce0 <acquire>
  ip->ref++;
    80003784:	449c                	lw	a5,8(s1)
    80003786:	2785                	addiw	a5,a5,1
    80003788:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000378a:	0003c517          	auipc	a0,0x3c
    8000378e:	03e50513          	addi	a0,a0,62 # 8003f7c8 <itable>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	602080e7          	jalr	1538(ra) # 80000d94 <release>
}
    8000379a:	8526                	mv	a0,s1
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret

00000000800037a6 <ilock>:
{
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	e04a                	sd	s2,0(sp)
    800037b0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037b2:	c115                	beqz	a0,800037d6 <ilock+0x30>
    800037b4:	84aa                	mv	s1,a0
    800037b6:	451c                	lw	a5,8(a0)
    800037b8:	00f05f63          	blez	a5,800037d6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037bc:	0541                	addi	a0,a0,16
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	cb2080e7          	jalr	-846(ra) # 80004470 <acquiresleep>
  if(ip->valid == 0){
    800037c6:	40bc                	lw	a5,64(s1)
    800037c8:	cf99                	beqz	a5,800037e6 <ilock+0x40>
}
    800037ca:	60e2                	ld	ra,24(sp)
    800037cc:	6442                	ld	s0,16(sp)
    800037ce:	64a2                	ld	s1,8(sp)
    800037d0:	6902                	ld	s2,0(sp)
    800037d2:	6105                	addi	sp,sp,32
    800037d4:	8082                	ret
    panic("ilock");
    800037d6:	00005517          	auipc	a0,0x5
    800037da:	df250513          	addi	a0,a0,-526 # 800085c8 <syscalls+0x180>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e6:	40dc                	lw	a5,4(s1)
    800037e8:	0047d79b          	srliw	a5,a5,0x4
    800037ec:	0003c597          	auipc	a1,0x3c
    800037f0:	fd45a583          	lw	a1,-44(a1) # 8003f7c0 <sb+0x18>
    800037f4:	9dbd                	addw	a1,a1,a5
    800037f6:	4088                	lw	a0,0(s1)
    800037f8:	fffff097          	auipc	ra,0xfffff
    800037fc:	7ac080e7          	jalr	1964(ra) # 80002fa4 <bread>
    80003800:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003802:	05850593          	addi	a1,a0,88
    80003806:	40dc                	lw	a5,4(s1)
    80003808:	8bbd                	andi	a5,a5,15
    8000380a:	079a                	slli	a5,a5,0x6
    8000380c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000380e:	00059783          	lh	a5,0(a1)
    80003812:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003816:	00259783          	lh	a5,2(a1)
    8000381a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000381e:	00459783          	lh	a5,4(a1)
    80003822:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003826:	00659783          	lh	a5,6(a1)
    8000382a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000382e:	459c                	lw	a5,8(a1)
    80003830:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003832:	03400613          	li	a2,52
    80003836:	05b1                	addi	a1,a1,12
    80003838:	05048513          	addi	a0,s1,80
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	600080e7          	jalr	1536(ra) # 80000e3c <memmove>
    brelse(bp);
    80003844:	854a                	mv	a0,s2
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	88e080e7          	jalr	-1906(ra) # 800030d4 <brelse>
    ip->valid = 1;
    8000384e:	4785                	li	a5,1
    80003850:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003852:	04449783          	lh	a5,68(s1)
    80003856:	fbb5                	bnez	a5,800037ca <ilock+0x24>
      panic("ilock: no type");
    80003858:	00005517          	auipc	a0,0x5
    8000385c:	d7850513          	addi	a0,a0,-648 # 800085d0 <syscalls+0x188>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	cde080e7          	jalr	-802(ra) # 8000053e <panic>

0000000080003868 <iunlock>:
{
    80003868:	1101                	addi	sp,sp,-32
    8000386a:	ec06                	sd	ra,24(sp)
    8000386c:	e822                	sd	s0,16(sp)
    8000386e:	e426                	sd	s1,8(sp)
    80003870:	e04a                	sd	s2,0(sp)
    80003872:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003874:	c905                	beqz	a0,800038a4 <iunlock+0x3c>
    80003876:	84aa                	mv	s1,a0
    80003878:	01050913          	addi	s2,a0,16
    8000387c:	854a                	mv	a0,s2
    8000387e:	00001097          	auipc	ra,0x1
    80003882:	c8c080e7          	jalr	-884(ra) # 8000450a <holdingsleep>
    80003886:	cd19                	beqz	a0,800038a4 <iunlock+0x3c>
    80003888:	449c                	lw	a5,8(s1)
    8000388a:	00f05d63          	blez	a5,800038a4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	c36080e7          	jalr	-970(ra) # 800044c6 <releasesleep>
}
    80003898:	60e2                	ld	ra,24(sp)
    8000389a:	6442                	ld	s0,16(sp)
    8000389c:	64a2                	ld	s1,8(sp)
    8000389e:	6902                	ld	s2,0(sp)
    800038a0:	6105                	addi	sp,sp,32
    800038a2:	8082                	ret
    panic("iunlock");
    800038a4:	00005517          	auipc	a0,0x5
    800038a8:	d3c50513          	addi	a0,a0,-708 # 800085e0 <syscalls+0x198>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	c92080e7          	jalr	-878(ra) # 8000053e <panic>

00000000800038b4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038b4:	7179                	addi	sp,sp,-48
    800038b6:	f406                	sd	ra,40(sp)
    800038b8:	f022                	sd	s0,32(sp)
    800038ba:	ec26                	sd	s1,24(sp)
    800038bc:	e84a                	sd	s2,16(sp)
    800038be:	e44e                	sd	s3,8(sp)
    800038c0:	e052                	sd	s4,0(sp)
    800038c2:	1800                	addi	s0,sp,48
    800038c4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038c6:	05050493          	addi	s1,a0,80
    800038ca:	08050913          	addi	s2,a0,128
    800038ce:	a021                	j	800038d6 <itrunc+0x22>
    800038d0:	0491                	addi	s1,s1,4
    800038d2:	01248d63          	beq	s1,s2,800038ec <itrunc+0x38>
    if(ip->addrs[i]){
    800038d6:	408c                	lw	a1,0(s1)
    800038d8:	dde5                	beqz	a1,800038d0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038da:	0009a503          	lw	a0,0(s3)
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	90c080e7          	jalr	-1780(ra) # 800031ea <bfree>
      ip->addrs[i] = 0;
    800038e6:	0004a023          	sw	zero,0(s1)
    800038ea:	b7dd                	j	800038d0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ec:	0809a583          	lw	a1,128(s3)
    800038f0:	e185                	bnez	a1,80003910 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038f2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038f6:	854e                	mv	a0,s3
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	de4080e7          	jalr	-540(ra) # 800036dc <iupdate>
}
    80003900:	70a2                	ld	ra,40(sp)
    80003902:	7402                	ld	s0,32(sp)
    80003904:	64e2                	ld	s1,24(sp)
    80003906:	6942                	ld	s2,16(sp)
    80003908:	69a2                	ld	s3,8(sp)
    8000390a:	6a02                	ld	s4,0(sp)
    8000390c:	6145                	addi	sp,sp,48
    8000390e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003910:	0009a503          	lw	a0,0(s3)
    80003914:	fffff097          	auipc	ra,0xfffff
    80003918:	690080e7          	jalr	1680(ra) # 80002fa4 <bread>
    8000391c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000391e:	05850493          	addi	s1,a0,88
    80003922:	45850913          	addi	s2,a0,1112
    80003926:	a811                	j	8000393a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003928:	0009a503          	lw	a0,0(s3)
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	8be080e7          	jalr	-1858(ra) # 800031ea <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003934:	0491                	addi	s1,s1,4
    80003936:	01248563          	beq	s1,s2,80003940 <itrunc+0x8c>
      if(a[j])
    8000393a:	408c                	lw	a1,0(s1)
    8000393c:	dde5                	beqz	a1,80003934 <itrunc+0x80>
    8000393e:	b7ed                	j	80003928 <itrunc+0x74>
    brelse(bp);
    80003940:	8552                	mv	a0,s4
    80003942:	fffff097          	auipc	ra,0xfffff
    80003946:	792080e7          	jalr	1938(ra) # 800030d4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000394a:	0809a583          	lw	a1,128(s3)
    8000394e:	0009a503          	lw	a0,0(s3)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	898080e7          	jalr	-1896(ra) # 800031ea <bfree>
    ip->addrs[NDIRECT] = 0;
    8000395a:	0809a023          	sw	zero,128(s3)
    8000395e:	bf51                	j	800038f2 <itrunc+0x3e>

0000000080003960 <iput>:
{
    80003960:	1101                	addi	sp,sp,-32
    80003962:	ec06                	sd	ra,24(sp)
    80003964:	e822                	sd	s0,16(sp)
    80003966:	e426                	sd	s1,8(sp)
    80003968:	e04a                	sd	s2,0(sp)
    8000396a:	1000                	addi	s0,sp,32
    8000396c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000396e:	0003c517          	auipc	a0,0x3c
    80003972:	e5a50513          	addi	a0,a0,-422 # 8003f7c8 <itable>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	36a080e7          	jalr	874(ra) # 80000ce0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000397e:	4498                	lw	a4,8(s1)
    80003980:	4785                	li	a5,1
    80003982:	02f70363          	beq	a4,a5,800039a8 <iput+0x48>
  ip->ref--;
    80003986:	449c                	lw	a5,8(s1)
    80003988:	37fd                	addiw	a5,a5,-1
    8000398a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000398c:	0003c517          	auipc	a0,0x3c
    80003990:	e3c50513          	addi	a0,a0,-452 # 8003f7c8 <itable>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	400080e7          	jalr	1024(ra) # 80000d94 <release>
}
    8000399c:	60e2                	ld	ra,24(sp)
    8000399e:	6442                	ld	s0,16(sp)
    800039a0:	64a2                	ld	s1,8(sp)
    800039a2:	6902                	ld	s2,0(sp)
    800039a4:	6105                	addi	sp,sp,32
    800039a6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a8:	40bc                	lw	a5,64(s1)
    800039aa:	dff1                	beqz	a5,80003986 <iput+0x26>
    800039ac:	04a49783          	lh	a5,74(s1)
    800039b0:	fbf9                	bnez	a5,80003986 <iput+0x26>
    acquiresleep(&ip->lock);
    800039b2:	01048913          	addi	s2,s1,16
    800039b6:	854a                	mv	a0,s2
    800039b8:	00001097          	auipc	ra,0x1
    800039bc:	ab8080e7          	jalr	-1352(ra) # 80004470 <acquiresleep>
    release(&itable.lock);
    800039c0:	0003c517          	auipc	a0,0x3c
    800039c4:	e0850513          	addi	a0,a0,-504 # 8003f7c8 <itable>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	3cc080e7          	jalr	972(ra) # 80000d94 <release>
    itrunc(ip);
    800039d0:	8526                	mv	a0,s1
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	ee2080e7          	jalr	-286(ra) # 800038b4 <itrunc>
    ip->type = 0;
    800039da:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039de:	8526                	mv	a0,s1
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	cfc080e7          	jalr	-772(ra) # 800036dc <iupdate>
    ip->valid = 0;
    800039e8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ec:	854a                	mv	a0,s2
    800039ee:	00001097          	auipc	ra,0x1
    800039f2:	ad8080e7          	jalr	-1320(ra) # 800044c6 <releasesleep>
    acquire(&itable.lock);
    800039f6:	0003c517          	auipc	a0,0x3c
    800039fa:	dd250513          	addi	a0,a0,-558 # 8003f7c8 <itable>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	2e2080e7          	jalr	738(ra) # 80000ce0 <acquire>
    80003a06:	b741                	j	80003986 <iput+0x26>

0000000080003a08 <iunlockput>:
{
    80003a08:	1101                	addi	sp,sp,-32
    80003a0a:	ec06                	sd	ra,24(sp)
    80003a0c:	e822                	sd	s0,16(sp)
    80003a0e:	e426                	sd	s1,8(sp)
    80003a10:	1000                	addi	s0,sp,32
    80003a12:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	e54080e7          	jalr	-428(ra) # 80003868 <iunlock>
  iput(ip);
    80003a1c:	8526                	mv	a0,s1
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	f42080e7          	jalr	-190(ra) # 80003960 <iput>
}
    80003a26:	60e2                	ld	ra,24(sp)
    80003a28:	6442                	ld	s0,16(sp)
    80003a2a:	64a2                	ld	s1,8(sp)
    80003a2c:	6105                	addi	sp,sp,32
    80003a2e:	8082                	ret

0000000080003a30 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a30:	1141                	addi	sp,sp,-16
    80003a32:	e422                	sd	s0,8(sp)
    80003a34:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a36:	411c                	lw	a5,0(a0)
    80003a38:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a3a:	415c                	lw	a5,4(a0)
    80003a3c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a3e:	04451783          	lh	a5,68(a0)
    80003a42:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a46:	04a51783          	lh	a5,74(a0)
    80003a4a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a4e:	04c56783          	lwu	a5,76(a0)
    80003a52:	e99c                	sd	a5,16(a1)
}
    80003a54:	6422                	ld	s0,8(sp)
    80003a56:	0141                	addi	sp,sp,16
    80003a58:	8082                	ret

0000000080003a5a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a5a:	457c                	lw	a5,76(a0)
    80003a5c:	0ed7e963          	bltu	a5,a3,80003b4e <readi+0xf4>
{
    80003a60:	7159                	addi	sp,sp,-112
    80003a62:	f486                	sd	ra,104(sp)
    80003a64:	f0a2                	sd	s0,96(sp)
    80003a66:	eca6                	sd	s1,88(sp)
    80003a68:	e8ca                	sd	s2,80(sp)
    80003a6a:	e4ce                	sd	s3,72(sp)
    80003a6c:	e0d2                	sd	s4,64(sp)
    80003a6e:	fc56                	sd	s5,56(sp)
    80003a70:	f85a                	sd	s6,48(sp)
    80003a72:	f45e                	sd	s7,40(sp)
    80003a74:	f062                	sd	s8,32(sp)
    80003a76:	ec66                	sd	s9,24(sp)
    80003a78:	e86a                	sd	s10,16(sp)
    80003a7a:	e46e                	sd	s11,8(sp)
    80003a7c:	1880                	addi	s0,sp,112
    80003a7e:	8baa                	mv	s7,a0
    80003a80:	8c2e                	mv	s8,a1
    80003a82:	8ab2                	mv	s5,a2
    80003a84:	84b6                	mv	s1,a3
    80003a86:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a88:	9f35                	addw	a4,a4,a3
    return 0;
    80003a8a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a8c:	0ad76063          	bltu	a4,a3,80003b2c <readi+0xd2>
  if(off + n > ip->size)
    80003a90:	00e7f463          	bgeu	a5,a4,80003a98 <readi+0x3e>
    n = ip->size - off;
    80003a94:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a98:	0a0b0963          	beqz	s6,80003b4a <readi+0xf0>
    80003a9c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a9e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aa2:	5cfd                	li	s9,-1
    80003aa4:	a82d                	j	80003ade <readi+0x84>
    80003aa6:	020a1d93          	slli	s11,s4,0x20
    80003aaa:	020ddd93          	srli	s11,s11,0x20
    80003aae:	05890613          	addi	a2,s2,88
    80003ab2:	86ee                	mv	a3,s11
    80003ab4:	963a                	add	a2,a2,a4
    80003ab6:	85d6                	mv	a1,s5
    80003ab8:	8562                	mv	a0,s8
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	a5c080e7          	jalr	-1444(ra) # 80002516 <either_copyout>
    80003ac2:	05950d63          	beq	a0,s9,80003b1c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	60c080e7          	jalr	1548(ra) # 800030d4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad0:	013a09bb          	addw	s3,s4,s3
    80003ad4:	009a04bb          	addw	s1,s4,s1
    80003ad8:	9aee                	add	s5,s5,s11
    80003ada:	0569f763          	bgeu	s3,s6,80003b28 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ade:	000ba903          	lw	s2,0(s7)
    80003ae2:	00a4d59b          	srliw	a1,s1,0xa
    80003ae6:	855e                	mv	a0,s7
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	8b0080e7          	jalr	-1872(ra) # 80003398 <bmap>
    80003af0:	0005059b          	sext.w	a1,a0
    80003af4:	854a                	mv	a0,s2
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	4ae080e7          	jalr	1198(ra) # 80002fa4 <bread>
    80003afe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b00:	3ff4f713          	andi	a4,s1,1023
    80003b04:	40ed07bb          	subw	a5,s10,a4
    80003b08:	413b06bb          	subw	a3,s6,s3
    80003b0c:	8a3e                	mv	s4,a5
    80003b0e:	2781                	sext.w	a5,a5
    80003b10:	0006861b          	sext.w	a2,a3
    80003b14:	f8f679e3          	bgeu	a2,a5,80003aa6 <readi+0x4c>
    80003b18:	8a36                	mv	s4,a3
    80003b1a:	b771                	j	80003aa6 <readi+0x4c>
      brelse(bp);
    80003b1c:	854a                	mv	a0,s2
    80003b1e:	fffff097          	auipc	ra,0xfffff
    80003b22:	5b6080e7          	jalr	1462(ra) # 800030d4 <brelse>
      tot = -1;
    80003b26:	59fd                	li	s3,-1
  }
  return tot;
    80003b28:	0009851b          	sext.w	a0,s3
}
    80003b2c:	70a6                	ld	ra,104(sp)
    80003b2e:	7406                	ld	s0,96(sp)
    80003b30:	64e6                	ld	s1,88(sp)
    80003b32:	6946                	ld	s2,80(sp)
    80003b34:	69a6                	ld	s3,72(sp)
    80003b36:	6a06                	ld	s4,64(sp)
    80003b38:	7ae2                	ld	s5,56(sp)
    80003b3a:	7b42                	ld	s6,48(sp)
    80003b3c:	7ba2                	ld	s7,40(sp)
    80003b3e:	7c02                	ld	s8,32(sp)
    80003b40:	6ce2                	ld	s9,24(sp)
    80003b42:	6d42                	ld	s10,16(sp)
    80003b44:	6da2                	ld	s11,8(sp)
    80003b46:	6165                	addi	sp,sp,112
    80003b48:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b4a:	89da                	mv	s3,s6
    80003b4c:	bff1                	j	80003b28 <readi+0xce>
    return 0;
    80003b4e:	4501                	li	a0,0
}
    80003b50:	8082                	ret

0000000080003b52 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b52:	457c                	lw	a5,76(a0)
    80003b54:	10d7e863          	bltu	a5,a3,80003c64 <writei+0x112>
{
    80003b58:	7159                	addi	sp,sp,-112
    80003b5a:	f486                	sd	ra,104(sp)
    80003b5c:	f0a2                	sd	s0,96(sp)
    80003b5e:	eca6                	sd	s1,88(sp)
    80003b60:	e8ca                	sd	s2,80(sp)
    80003b62:	e4ce                	sd	s3,72(sp)
    80003b64:	e0d2                	sd	s4,64(sp)
    80003b66:	fc56                	sd	s5,56(sp)
    80003b68:	f85a                	sd	s6,48(sp)
    80003b6a:	f45e                	sd	s7,40(sp)
    80003b6c:	f062                	sd	s8,32(sp)
    80003b6e:	ec66                	sd	s9,24(sp)
    80003b70:	e86a                	sd	s10,16(sp)
    80003b72:	e46e                	sd	s11,8(sp)
    80003b74:	1880                	addi	s0,sp,112
    80003b76:	8b2a                	mv	s6,a0
    80003b78:	8c2e                	mv	s8,a1
    80003b7a:	8ab2                	mv	s5,a2
    80003b7c:	8936                	mv	s2,a3
    80003b7e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b80:	00e687bb          	addw	a5,a3,a4
    80003b84:	0ed7e263          	bltu	a5,a3,80003c68 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b88:	00043737          	lui	a4,0x43
    80003b8c:	0ef76063          	bltu	a4,a5,80003c6c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b90:	0c0b8863          	beqz	s7,80003c60 <writei+0x10e>
    80003b94:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b96:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b9a:	5cfd                	li	s9,-1
    80003b9c:	a091                	j	80003be0 <writei+0x8e>
    80003b9e:	02099d93          	slli	s11,s3,0x20
    80003ba2:	020ddd93          	srli	s11,s11,0x20
    80003ba6:	05848513          	addi	a0,s1,88
    80003baa:	86ee                	mv	a3,s11
    80003bac:	8656                	mv	a2,s5
    80003bae:	85e2                	mv	a1,s8
    80003bb0:	953a                	add	a0,a0,a4
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	9ba080e7          	jalr	-1606(ra) # 8000256c <either_copyin>
    80003bba:	07950263          	beq	a0,s9,80003c1e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bbe:	8526                	mv	a0,s1
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	790080e7          	jalr	1936(ra) # 80004350 <log_write>
    brelse(bp);
    80003bc8:	8526                	mv	a0,s1
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	50a080e7          	jalr	1290(ra) # 800030d4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd2:	01498a3b          	addw	s4,s3,s4
    80003bd6:	0129893b          	addw	s2,s3,s2
    80003bda:	9aee                	add	s5,s5,s11
    80003bdc:	057a7663          	bgeu	s4,s7,80003c28 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003be0:	000b2483          	lw	s1,0(s6)
    80003be4:	00a9559b          	srliw	a1,s2,0xa
    80003be8:	855a                	mv	a0,s6
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	7ae080e7          	jalr	1966(ra) # 80003398 <bmap>
    80003bf2:	0005059b          	sext.w	a1,a0
    80003bf6:	8526                	mv	a0,s1
    80003bf8:	fffff097          	auipc	ra,0xfffff
    80003bfc:	3ac080e7          	jalr	940(ra) # 80002fa4 <bread>
    80003c00:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c02:	3ff97713          	andi	a4,s2,1023
    80003c06:	40ed07bb          	subw	a5,s10,a4
    80003c0a:	414b86bb          	subw	a3,s7,s4
    80003c0e:	89be                	mv	s3,a5
    80003c10:	2781                	sext.w	a5,a5
    80003c12:	0006861b          	sext.w	a2,a3
    80003c16:	f8f674e3          	bgeu	a2,a5,80003b9e <writei+0x4c>
    80003c1a:	89b6                	mv	s3,a3
    80003c1c:	b749                	j	80003b9e <writei+0x4c>
      brelse(bp);
    80003c1e:	8526                	mv	a0,s1
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	4b4080e7          	jalr	1204(ra) # 800030d4 <brelse>
  }

  if(off > ip->size)
    80003c28:	04cb2783          	lw	a5,76(s6)
    80003c2c:	0127f463          	bgeu	a5,s2,80003c34 <writei+0xe2>
    ip->size = off;
    80003c30:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c34:	855a                	mv	a0,s6
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	aa6080e7          	jalr	-1370(ra) # 800036dc <iupdate>

  return tot;
    80003c3e:	000a051b          	sext.w	a0,s4
}
    80003c42:	70a6                	ld	ra,104(sp)
    80003c44:	7406                	ld	s0,96(sp)
    80003c46:	64e6                	ld	s1,88(sp)
    80003c48:	6946                	ld	s2,80(sp)
    80003c4a:	69a6                	ld	s3,72(sp)
    80003c4c:	6a06                	ld	s4,64(sp)
    80003c4e:	7ae2                	ld	s5,56(sp)
    80003c50:	7b42                	ld	s6,48(sp)
    80003c52:	7ba2                	ld	s7,40(sp)
    80003c54:	7c02                	ld	s8,32(sp)
    80003c56:	6ce2                	ld	s9,24(sp)
    80003c58:	6d42                	ld	s10,16(sp)
    80003c5a:	6da2                	ld	s11,8(sp)
    80003c5c:	6165                	addi	sp,sp,112
    80003c5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c60:	8a5e                	mv	s4,s7
    80003c62:	bfc9                	j	80003c34 <writei+0xe2>
    return -1;
    80003c64:	557d                	li	a0,-1
}
    80003c66:	8082                	ret
    return -1;
    80003c68:	557d                	li	a0,-1
    80003c6a:	bfe1                	j	80003c42 <writei+0xf0>
    return -1;
    80003c6c:	557d                	li	a0,-1
    80003c6e:	bfd1                	j	80003c42 <writei+0xf0>

0000000080003c70 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c70:	1141                	addi	sp,sp,-16
    80003c72:	e406                	sd	ra,8(sp)
    80003c74:	e022                	sd	s0,0(sp)
    80003c76:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c78:	4639                	li	a2,14
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	23a080e7          	jalr	570(ra) # 80000eb4 <strncmp>
}
    80003c82:	60a2                	ld	ra,8(sp)
    80003c84:	6402                	ld	s0,0(sp)
    80003c86:	0141                	addi	sp,sp,16
    80003c88:	8082                	ret

0000000080003c8a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c8a:	7139                	addi	sp,sp,-64
    80003c8c:	fc06                	sd	ra,56(sp)
    80003c8e:	f822                	sd	s0,48(sp)
    80003c90:	f426                	sd	s1,40(sp)
    80003c92:	f04a                	sd	s2,32(sp)
    80003c94:	ec4e                	sd	s3,24(sp)
    80003c96:	e852                	sd	s4,16(sp)
    80003c98:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c9a:	04451703          	lh	a4,68(a0)
    80003c9e:	4785                	li	a5,1
    80003ca0:	00f71a63          	bne	a4,a5,80003cb4 <dirlookup+0x2a>
    80003ca4:	892a                	mv	s2,a0
    80003ca6:	89ae                	mv	s3,a1
    80003ca8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003caa:	457c                	lw	a5,76(a0)
    80003cac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb0:	e79d                	bnez	a5,80003cde <dirlookup+0x54>
    80003cb2:	a8a5                	j	80003d2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cb4:	00005517          	auipc	a0,0x5
    80003cb8:	93450513          	addi	a0,a0,-1740 # 800085e8 <syscalls+0x1a0>
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	93c50513          	addi	a0,a0,-1732 # 80008600 <syscalls+0x1b8>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd4:	24c1                	addiw	s1,s1,16
    80003cd6:	04c92783          	lw	a5,76(s2)
    80003cda:	04f4f763          	bgeu	s1,a5,80003d28 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cde:	4741                	li	a4,16
    80003ce0:	86a6                	mv	a3,s1
    80003ce2:	fc040613          	addi	a2,s0,-64
    80003ce6:	4581                	li	a1,0
    80003ce8:	854a                	mv	a0,s2
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	d70080e7          	jalr	-656(ra) # 80003a5a <readi>
    80003cf2:	47c1                	li	a5,16
    80003cf4:	fcf518e3          	bne	a0,a5,80003cc4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cf8:	fc045783          	lhu	a5,-64(s0)
    80003cfc:	dfe1                	beqz	a5,80003cd4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cfe:	fc240593          	addi	a1,s0,-62
    80003d02:	854e                	mv	a0,s3
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	f6c080e7          	jalr	-148(ra) # 80003c70 <namecmp>
    80003d0c:	f561                	bnez	a0,80003cd4 <dirlookup+0x4a>
      if(poff)
    80003d0e:	000a0463          	beqz	s4,80003d16 <dirlookup+0x8c>
        *poff = off;
    80003d12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d16:	fc045583          	lhu	a1,-64(s0)
    80003d1a:	00092503          	lw	a0,0(s2)
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	754080e7          	jalr	1876(ra) # 80003472 <iget>
    80003d26:	a011                	j	80003d2a <dirlookup+0xa0>
  return 0;
    80003d28:	4501                	li	a0,0
}
    80003d2a:	70e2                	ld	ra,56(sp)
    80003d2c:	7442                	ld	s0,48(sp)
    80003d2e:	74a2                	ld	s1,40(sp)
    80003d30:	7902                	ld	s2,32(sp)
    80003d32:	69e2                	ld	s3,24(sp)
    80003d34:	6a42                	ld	s4,16(sp)
    80003d36:	6121                	addi	sp,sp,64
    80003d38:	8082                	ret

0000000080003d3a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d3a:	711d                	addi	sp,sp,-96
    80003d3c:	ec86                	sd	ra,88(sp)
    80003d3e:	e8a2                	sd	s0,80(sp)
    80003d40:	e4a6                	sd	s1,72(sp)
    80003d42:	e0ca                	sd	s2,64(sp)
    80003d44:	fc4e                	sd	s3,56(sp)
    80003d46:	f852                	sd	s4,48(sp)
    80003d48:	f456                	sd	s5,40(sp)
    80003d4a:	f05a                	sd	s6,32(sp)
    80003d4c:	ec5e                	sd	s7,24(sp)
    80003d4e:	e862                	sd	s8,16(sp)
    80003d50:	e466                	sd	s9,8(sp)
    80003d52:	1080                	addi	s0,sp,96
    80003d54:	84aa                	mv	s1,a0
    80003d56:	8b2e                	mv	s6,a1
    80003d58:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d5a:	00054703          	lbu	a4,0(a0)
    80003d5e:	02f00793          	li	a5,47
    80003d62:	02f70363          	beq	a4,a5,80003d88 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d66:	ffffe097          	auipc	ra,0xffffe
    80003d6a:	d50080e7          	jalr	-688(ra) # 80001ab6 <myproc>
    80003d6e:	15053503          	ld	a0,336(a0)
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	9f6080e7          	jalr	-1546(ra) # 80003768 <idup>
    80003d7a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d7c:	02f00913          	li	s2,47
  len = path - s;
    80003d80:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d82:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d84:	4c05                	li	s8,1
    80003d86:	a865                	j	80003e3e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d88:	4585                	li	a1,1
    80003d8a:	4505                	li	a0,1
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	6e6080e7          	jalr	1766(ra) # 80003472 <iget>
    80003d94:	89aa                	mv	s3,a0
    80003d96:	b7dd                	j	80003d7c <namex+0x42>
      iunlockput(ip);
    80003d98:	854e                	mv	a0,s3
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	c6e080e7          	jalr	-914(ra) # 80003a08 <iunlockput>
      return 0;
    80003da2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003da4:	854e                	mv	a0,s3
    80003da6:	60e6                	ld	ra,88(sp)
    80003da8:	6446                	ld	s0,80(sp)
    80003daa:	64a6                	ld	s1,72(sp)
    80003dac:	6906                	ld	s2,64(sp)
    80003dae:	79e2                	ld	s3,56(sp)
    80003db0:	7a42                	ld	s4,48(sp)
    80003db2:	7aa2                	ld	s5,40(sp)
    80003db4:	7b02                	ld	s6,32(sp)
    80003db6:	6be2                	ld	s7,24(sp)
    80003db8:	6c42                	ld	s8,16(sp)
    80003dba:	6ca2                	ld	s9,8(sp)
    80003dbc:	6125                	addi	sp,sp,96
    80003dbe:	8082                	ret
      iunlock(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	aa6080e7          	jalr	-1370(ra) # 80003868 <iunlock>
      return ip;
    80003dca:	bfe9                	j	80003da4 <namex+0x6a>
      iunlockput(ip);
    80003dcc:	854e                	mv	a0,s3
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	c3a080e7          	jalr	-966(ra) # 80003a08 <iunlockput>
      return 0;
    80003dd6:	89d2                	mv	s3,s4
    80003dd8:	b7f1                	j	80003da4 <namex+0x6a>
  len = path - s;
    80003dda:	40b48633          	sub	a2,s1,a1
    80003dde:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003de2:	094cd463          	bge	s9,s4,80003e6a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003de6:	4639                	li	a2,14
    80003de8:	8556                	mv	a0,s5
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	052080e7          	jalr	82(ra) # 80000e3c <memmove>
  while(*path == '/')
    80003df2:	0004c783          	lbu	a5,0(s1)
    80003df6:	01279763          	bne	a5,s2,80003e04 <namex+0xca>
    path++;
    80003dfa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	ff278de3          	beq	a5,s2,80003dfa <namex+0xc0>
    ilock(ip);
    80003e04:	854e                	mv	a0,s3
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	9a0080e7          	jalr	-1632(ra) # 800037a6 <ilock>
    if(ip->type != T_DIR){
    80003e0e:	04499783          	lh	a5,68(s3)
    80003e12:	f98793e3          	bne	a5,s8,80003d98 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e16:	000b0563          	beqz	s6,80003e20 <namex+0xe6>
    80003e1a:	0004c783          	lbu	a5,0(s1)
    80003e1e:	d3cd                	beqz	a5,80003dc0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e20:	865e                	mv	a2,s7
    80003e22:	85d6                	mv	a1,s5
    80003e24:	854e                	mv	a0,s3
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	e64080e7          	jalr	-412(ra) # 80003c8a <dirlookup>
    80003e2e:	8a2a                	mv	s4,a0
    80003e30:	dd51                	beqz	a0,80003dcc <namex+0x92>
    iunlockput(ip);
    80003e32:	854e                	mv	a0,s3
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	bd4080e7          	jalr	-1068(ra) # 80003a08 <iunlockput>
    ip = next;
    80003e3c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e3e:	0004c783          	lbu	a5,0(s1)
    80003e42:	05279763          	bne	a5,s2,80003e90 <namex+0x156>
    path++;
    80003e46:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e48:	0004c783          	lbu	a5,0(s1)
    80003e4c:	ff278de3          	beq	a5,s2,80003e46 <namex+0x10c>
  if(*path == 0)
    80003e50:	c79d                	beqz	a5,80003e7e <namex+0x144>
    path++;
    80003e52:	85a6                	mv	a1,s1
  len = path - s;
    80003e54:	8a5e                	mv	s4,s7
    80003e56:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e58:	01278963          	beq	a5,s2,80003e6a <namex+0x130>
    80003e5c:	dfbd                	beqz	a5,80003dda <namex+0xa0>
    path++;
    80003e5e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e60:	0004c783          	lbu	a5,0(s1)
    80003e64:	ff279ce3          	bne	a5,s2,80003e5c <namex+0x122>
    80003e68:	bf8d                	j	80003dda <namex+0xa0>
    memmove(name, s, len);
    80003e6a:	2601                	sext.w	a2,a2
    80003e6c:	8556                	mv	a0,s5
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	fce080e7          	jalr	-50(ra) # 80000e3c <memmove>
    name[len] = 0;
    80003e76:	9a56                	add	s4,s4,s5
    80003e78:	000a0023          	sb	zero,0(s4)
    80003e7c:	bf9d                	j	80003df2 <namex+0xb8>
  if(nameiparent){
    80003e7e:	f20b03e3          	beqz	s6,80003da4 <namex+0x6a>
    iput(ip);
    80003e82:	854e                	mv	a0,s3
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	adc080e7          	jalr	-1316(ra) # 80003960 <iput>
    return 0;
    80003e8c:	4981                	li	s3,0
    80003e8e:	bf19                	j	80003da4 <namex+0x6a>
  if(*path == 0)
    80003e90:	d7fd                	beqz	a5,80003e7e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e92:	0004c783          	lbu	a5,0(s1)
    80003e96:	85a6                	mv	a1,s1
    80003e98:	b7d1                	j	80003e5c <namex+0x122>

0000000080003e9a <dirlink>:
{
    80003e9a:	7139                	addi	sp,sp,-64
    80003e9c:	fc06                	sd	ra,56(sp)
    80003e9e:	f822                	sd	s0,48(sp)
    80003ea0:	f426                	sd	s1,40(sp)
    80003ea2:	f04a                	sd	s2,32(sp)
    80003ea4:	ec4e                	sd	s3,24(sp)
    80003ea6:	e852                	sd	s4,16(sp)
    80003ea8:	0080                	addi	s0,sp,64
    80003eaa:	892a                	mv	s2,a0
    80003eac:	8a2e                	mv	s4,a1
    80003eae:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eb0:	4601                	li	a2,0
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	dd8080e7          	jalr	-552(ra) # 80003c8a <dirlookup>
    80003eba:	e93d                	bnez	a0,80003f30 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebc:	04c92483          	lw	s1,76(s2)
    80003ec0:	c49d                	beqz	s1,80003eee <dirlink+0x54>
    80003ec2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec4:	4741                	li	a4,16
    80003ec6:	86a6                	mv	a3,s1
    80003ec8:	fc040613          	addi	a2,s0,-64
    80003ecc:	4581                	li	a1,0
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	b8a080e7          	jalr	-1142(ra) # 80003a5a <readi>
    80003ed8:	47c1                	li	a5,16
    80003eda:	06f51163          	bne	a0,a5,80003f3c <dirlink+0xa2>
    if(de.inum == 0)
    80003ede:	fc045783          	lhu	a5,-64(s0)
    80003ee2:	c791                	beqz	a5,80003eee <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee4:	24c1                	addiw	s1,s1,16
    80003ee6:	04c92783          	lw	a5,76(s2)
    80003eea:	fcf4ede3          	bltu	s1,a5,80003ec4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eee:	4639                	li	a2,14
    80003ef0:	85d2                	mv	a1,s4
    80003ef2:	fc240513          	addi	a0,s0,-62
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	ffa080e7          	jalr	-6(ra) # 80000ef0 <strncpy>
  de.inum = inum;
    80003efe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f02:	4741                	li	a4,16
    80003f04:	86a6                	mv	a3,s1
    80003f06:	fc040613          	addi	a2,s0,-64
    80003f0a:	4581                	li	a1,0
    80003f0c:	854a                	mv	a0,s2
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	c44080e7          	jalr	-956(ra) # 80003b52 <writei>
    80003f16:	872a                	mv	a4,a0
    80003f18:	47c1                	li	a5,16
  return 0;
    80003f1a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f1c:	02f71863          	bne	a4,a5,80003f4c <dirlink+0xb2>
}
    80003f20:	70e2                	ld	ra,56(sp)
    80003f22:	7442                	ld	s0,48(sp)
    80003f24:	74a2                	ld	s1,40(sp)
    80003f26:	7902                	ld	s2,32(sp)
    80003f28:	69e2                	ld	s3,24(sp)
    80003f2a:	6a42                	ld	s4,16(sp)
    80003f2c:	6121                	addi	sp,sp,64
    80003f2e:	8082                	ret
    iput(ip);
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	a30080e7          	jalr	-1488(ra) # 80003960 <iput>
    return -1;
    80003f38:	557d                	li	a0,-1
    80003f3a:	b7dd                	j	80003f20 <dirlink+0x86>
      panic("dirlink read");
    80003f3c:	00004517          	auipc	a0,0x4
    80003f40:	6d450513          	addi	a0,a0,1748 # 80008610 <syscalls+0x1c8>
    80003f44:	ffffc097          	auipc	ra,0xffffc
    80003f48:	5fa080e7          	jalr	1530(ra) # 8000053e <panic>
    panic("dirlink");
    80003f4c:	00004517          	auipc	a0,0x4
    80003f50:	7d450513          	addi	a0,a0,2004 # 80008720 <syscalls+0x2d8>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>

0000000080003f5c <namei>:

struct inode*
namei(char *path)
{
    80003f5c:	1101                	addi	sp,sp,-32
    80003f5e:	ec06                	sd	ra,24(sp)
    80003f60:	e822                	sd	s0,16(sp)
    80003f62:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f64:	fe040613          	addi	a2,s0,-32
    80003f68:	4581                	li	a1,0
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	dd0080e7          	jalr	-560(ra) # 80003d3a <namex>
}
    80003f72:	60e2                	ld	ra,24(sp)
    80003f74:	6442                	ld	s0,16(sp)
    80003f76:	6105                	addi	sp,sp,32
    80003f78:	8082                	ret

0000000080003f7a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f7a:	1141                	addi	sp,sp,-16
    80003f7c:	e406                	sd	ra,8(sp)
    80003f7e:	e022                	sd	s0,0(sp)
    80003f80:	0800                	addi	s0,sp,16
    80003f82:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f84:	4585                	li	a1,1
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	db4080e7          	jalr	-588(ra) # 80003d3a <namex>
}
    80003f8e:	60a2                	ld	ra,8(sp)
    80003f90:	6402                	ld	s0,0(sp)
    80003f92:	0141                	addi	sp,sp,16
    80003f94:	8082                	ret

0000000080003f96 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f96:	1101                	addi	sp,sp,-32
    80003f98:	ec06                	sd	ra,24(sp)
    80003f9a:	e822                	sd	s0,16(sp)
    80003f9c:	e426                	sd	s1,8(sp)
    80003f9e:	e04a                	sd	s2,0(sp)
    80003fa0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fa2:	0003d917          	auipc	s2,0x3d
    80003fa6:	2ce90913          	addi	s2,s2,718 # 80041270 <log>
    80003faa:	01892583          	lw	a1,24(s2)
    80003fae:	02892503          	lw	a0,40(s2)
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	ff2080e7          	jalr	-14(ra) # 80002fa4 <bread>
    80003fba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fbc:	02c92683          	lw	a3,44(s2)
    80003fc0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fc2:	02d05763          	blez	a3,80003ff0 <write_head+0x5a>
    80003fc6:	0003d797          	auipc	a5,0x3d
    80003fca:	2da78793          	addi	a5,a5,730 # 800412a0 <log+0x30>
    80003fce:	05c50713          	addi	a4,a0,92
    80003fd2:	36fd                	addiw	a3,a3,-1
    80003fd4:	1682                	slli	a3,a3,0x20
    80003fd6:	9281                	srli	a3,a3,0x20
    80003fd8:	068a                	slli	a3,a3,0x2
    80003fda:	0003d617          	auipc	a2,0x3d
    80003fde:	2ca60613          	addi	a2,a2,714 # 800412a4 <log+0x34>
    80003fe2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fe4:	4390                	lw	a2,0(a5)
    80003fe6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe8:	0791                	addi	a5,a5,4
    80003fea:	0711                	addi	a4,a4,4
    80003fec:	fed79ce3          	bne	a5,a3,80003fe4 <write_head+0x4e>
  }
  bwrite(buf);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	0a4080e7          	jalr	164(ra) # 80003096 <bwrite>
  brelse(buf);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	0d8080e7          	jalr	216(ra) # 800030d4 <brelse>
}
    80004004:	60e2                	ld	ra,24(sp)
    80004006:	6442                	ld	s0,16(sp)
    80004008:	64a2                	ld	s1,8(sp)
    8000400a:	6902                	ld	s2,0(sp)
    8000400c:	6105                	addi	sp,sp,32
    8000400e:	8082                	ret

0000000080004010 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004010:	0003d797          	auipc	a5,0x3d
    80004014:	28c7a783          	lw	a5,652(a5) # 8004129c <log+0x2c>
    80004018:	0af05d63          	blez	a5,800040d2 <install_trans+0xc2>
{
    8000401c:	7139                	addi	sp,sp,-64
    8000401e:	fc06                	sd	ra,56(sp)
    80004020:	f822                	sd	s0,48(sp)
    80004022:	f426                	sd	s1,40(sp)
    80004024:	f04a                	sd	s2,32(sp)
    80004026:	ec4e                	sd	s3,24(sp)
    80004028:	e852                	sd	s4,16(sp)
    8000402a:	e456                	sd	s5,8(sp)
    8000402c:	e05a                	sd	s6,0(sp)
    8000402e:	0080                	addi	s0,sp,64
    80004030:	8b2a                	mv	s6,a0
    80004032:	0003da97          	auipc	s5,0x3d
    80004036:	26ea8a93          	addi	s5,s5,622 # 800412a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000403c:	0003d997          	auipc	s3,0x3d
    80004040:	23498993          	addi	s3,s3,564 # 80041270 <log>
    80004044:	a035                	j	80004070 <install_trans+0x60>
      bunpin(dbuf);
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	166080e7          	jalr	358(ra) # 800031ae <bunpin>
    brelse(lbuf);
    80004050:	854a                	mv	a0,s2
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	082080e7          	jalr	130(ra) # 800030d4 <brelse>
    brelse(dbuf);
    8000405a:	8526                	mv	a0,s1
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	078080e7          	jalr	120(ra) # 800030d4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004064:	2a05                	addiw	s4,s4,1
    80004066:	0a91                	addi	s5,s5,4
    80004068:	02c9a783          	lw	a5,44(s3)
    8000406c:	04fa5963          	bge	s4,a5,800040be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004070:	0189a583          	lw	a1,24(s3)
    80004074:	014585bb          	addw	a1,a1,s4
    80004078:	2585                	addiw	a1,a1,1
    8000407a:	0289a503          	lw	a0,40(s3)
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	f26080e7          	jalr	-218(ra) # 80002fa4 <bread>
    80004086:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004088:	000aa583          	lw	a1,0(s5)
    8000408c:	0289a503          	lw	a0,40(s3)
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	f14080e7          	jalr	-236(ra) # 80002fa4 <bread>
    80004098:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000409a:	40000613          	li	a2,1024
    8000409e:	05890593          	addi	a1,s2,88
    800040a2:	05850513          	addi	a0,a0,88
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	d96080e7          	jalr	-618(ra) # 80000e3c <memmove>
    bwrite(dbuf);  // write dst to disk
    800040ae:	8526                	mv	a0,s1
    800040b0:	fffff097          	auipc	ra,0xfffff
    800040b4:	fe6080e7          	jalr	-26(ra) # 80003096 <bwrite>
    if(recovering == 0)
    800040b8:	f80b1ce3          	bnez	s6,80004050 <install_trans+0x40>
    800040bc:	b769                	j	80004046 <install_trans+0x36>
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6aa2                	ld	s5,8(sp)
    800040cc:	6b02                	ld	s6,0(sp)
    800040ce:	6121                	addi	sp,sp,64
    800040d0:	8082                	ret
    800040d2:	8082                	ret

00000000800040d4 <initlog>:
{
    800040d4:	7179                	addi	sp,sp,-48
    800040d6:	f406                	sd	ra,40(sp)
    800040d8:	f022                	sd	s0,32(sp)
    800040da:	ec26                	sd	s1,24(sp)
    800040dc:	e84a                	sd	s2,16(sp)
    800040de:	e44e                	sd	s3,8(sp)
    800040e0:	1800                	addi	s0,sp,48
    800040e2:	892a                	mv	s2,a0
    800040e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e6:	0003d497          	auipc	s1,0x3d
    800040ea:	18a48493          	addi	s1,s1,394 # 80041270 <log>
    800040ee:	00004597          	auipc	a1,0x4
    800040f2:	53258593          	addi	a1,a1,1330 # 80008620 <syscalls+0x1d8>
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	b58080e7          	jalr	-1192(ra) # 80000c50 <initlock>
  log.start = sb->logstart;
    80004100:	0149a583          	lw	a1,20(s3)
    80004104:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004106:	0109a783          	lw	a5,16(s3)
    8000410a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000410c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004110:	854a                	mv	a0,s2
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	e92080e7          	jalr	-366(ra) # 80002fa4 <bread>
  log.lh.n = lh->n;
    8000411a:	4d3c                	lw	a5,88(a0)
    8000411c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000411e:	02f05563          	blez	a5,80004148 <initlog+0x74>
    80004122:	05c50713          	addi	a4,a0,92
    80004126:	0003d697          	auipc	a3,0x3d
    8000412a:	17a68693          	addi	a3,a3,378 # 800412a0 <log+0x30>
    8000412e:	37fd                	addiw	a5,a5,-1
    80004130:	1782                	slli	a5,a5,0x20
    80004132:	9381                	srli	a5,a5,0x20
    80004134:	078a                	slli	a5,a5,0x2
    80004136:	06050613          	addi	a2,a0,96
    8000413a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000413c:	4310                	lw	a2,0(a4)
    8000413e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004140:	0711                	addi	a4,a4,4
    80004142:	0691                	addi	a3,a3,4
    80004144:	fef71ce3          	bne	a4,a5,8000413c <initlog+0x68>
  brelse(buf);
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	f8c080e7          	jalr	-116(ra) # 800030d4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004150:	4505                	li	a0,1
    80004152:	00000097          	auipc	ra,0x0
    80004156:	ebe080e7          	jalr	-322(ra) # 80004010 <install_trans>
  log.lh.n = 0;
    8000415a:	0003d797          	auipc	a5,0x3d
    8000415e:	1407a123          	sw	zero,322(a5) # 8004129c <log+0x2c>
  write_head(); // clear the log
    80004162:	00000097          	auipc	ra,0x0
    80004166:	e34080e7          	jalr	-460(ra) # 80003f96 <write_head>
}
    8000416a:	70a2                	ld	ra,40(sp)
    8000416c:	7402                	ld	s0,32(sp)
    8000416e:	64e2                	ld	s1,24(sp)
    80004170:	6942                	ld	s2,16(sp)
    80004172:	69a2                	ld	s3,8(sp)
    80004174:	6145                	addi	sp,sp,48
    80004176:	8082                	ret

0000000080004178 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004178:	1101                	addi	sp,sp,-32
    8000417a:	ec06                	sd	ra,24(sp)
    8000417c:	e822                	sd	s0,16(sp)
    8000417e:	e426                	sd	s1,8(sp)
    80004180:	e04a                	sd	s2,0(sp)
    80004182:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004184:	0003d517          	auipc	a0,0x3d
    80004188:	0ec50513          	addi	a0,a0,236 # 80041270 <log>
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	b54080e7          	jalr	-1196(ra) # 80000ce0 <acquire>
  while(1){
    if(log.committing){
    80004194:	0003d497          	auipc	s1,0x3d
    80004198:	0dc48493          	addi	s1,s1,220 # 80041270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419c:	4979                	li	s2,30
    8000419e:	a039                	j	800041ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a0:	85a6                	mv	a1,s1
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffe097          	auipc	ra,0xffffe
    800041a8:	fce080e7          	jalr	-50(ra) # 80002172 <sleep>
    if(log.committing){
    800041ac:	50dc                	lw	a5,36(s1)
    800041ae:	fbed                	bnez	a5,800041a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	0017871b          	addiw	a4,a5,1
    800041b6:	0007069b          	sext.w	a3,a4
    800041ba:	0027179b          	slliw	a5,a4,0x2
    800041be:	9fb9                	addw	a5,a5,a4
    800041c0:	0017979b          	slliw	a5,a5,0x1
    800041c4:	54d8                	lw	a4,44(s1)
    800041c6:	9fb9                	addw	a5,a5,a4
    800041c8:	00f95963          	bge	s2,a5,800041da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041cc:	85a6                	mv	a1,s1
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	fa2080e7          	jalr	-94(ra) # 80002172 <sleep>
    800041d8:	bfd1                	j	800041ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041da:	0003d517          	auipc	a0,0x3d
    800041de:	09650513          	addi	a0,a0,150 # 80041270 <log>
    800041e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	bb0080e7          	jalr	-1104(ra) # 80000d94 <release>
      break;
    }
  }
}
    800041ec:	60e2                	ld	ra,24(sp)
    800041ee:	6442                	ld	s0,16(sp)
    800041f0:	64a2                	ld	s1,8(sp)
    800041f2:	6902                	ld	s2,0(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	e456                	sd	s5,8(sp)
    80004208:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000420a:	0003d497          	auipc	s1,0x3d
    8000420e:	06648493          	addi	s1,s1,102 # 80041270 <log>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	acc080e7          	jalr	-1332(ra) # 80000ce0 <acquire>
  log.outstanding -= 1;
    8000421c:	509c                	lw	a5,32(s1)
    8000421e:	37fd                	addiw	a5,a5,-1
    80004220:	0007891b          	sext.w	s2,a5
    80004224:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004226:	50dc                	lw	a5,36(s1)
    80004228:	efb9                	bnez	a5,80004286 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000422a:	06091663          	bnez	s2,80004296 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000422e:	0003d497          	auipc	s1,0x3d
    80004232:	04248493          	addi	s1,s1,66 # 80041270 <log>
    80004236:	4785                	li	a5,1
    80004238:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	b58080e7          	jalr	-1192(ra) # 80000d94 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004244:	54dc                	lw	a5,44(s1)
    80004246:	06f04763          	bgtz	a5,800042b4 <end_op+0xbc>
    acquire(&log.lock);
    8000424a:	0003d497          	auipc	s1,0x3d
    8000424e:	02648493          	addi	s1,s1,38 # 80041270 <log>
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	a8c080e7          	jalr	-1396(ra) # 80000ce0 <acquire>
    log.committing = 0;
    8000425c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	09c080e7          	jalr	156(ra) # 800022fe <wakeup>
    release(&log.lock);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	b28080e7          	jalr	-1240(ra) # 80000d94 <release>
}
    80004274:	70e2                	ld	ra,56(sp)
    80004276:	7442                	ld	s0,48(sp)
    80004278:	74a2                	ld	s1,40(sp)
    8000427a:	7902                	ld	s2,32(sp)
    8000427c:	69e2                	ld	s3,24(sp)
    8000427e:	6a42                	ld	s4,16(sp)
    80004280:	6aa2                	ld	s5,8(sp)
    80004282:	6121                	addi	sp,sp,64
    80004284:	8082                	ret
    panic("log.committing");
    80004286:	00004517          	auipc	a0,0x4
    8000428a:	3a250513          	addi	a0,a0,930 # 80008628 <syscalls+0x1e0>
    8000428e:	ffffc097          	auipc	ra,0xffffc
    80004292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
    wakeup(&log);
    80004296:	0003d497          	auipc	s1,0x3d
    8000429a:	fda48493          	addi	s1,s1,-38 # 80041270 <log>
    8000429e:	8526                	mv	a0,s1
    800042a0:	ffffe097          	auipc	ra,0xffffe
    800042a4:	05e080e7          	jalr	94(ra) # 800022fe <wakeup>
  release(&log.lock);
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	aea080e7          	jalr	-1302(ra) # 80000d94 <release>
  if(do_commit){
    800042b2:	b7c9                	j	80004274 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	0003da97          	auipc	s5,0x3d
    800042b8:	feca8a93          	addi	s5,s5,-20 # 800412a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042bc:	0003da17          	auipc	s4,0x3d
    800042c0:	fb4a0a13          	addi	s4,s4,-76 # 80041270 <log>
    800042c4:	018a2583          	lw	a1,24(s4)
    800042c8:	012585bb          	addw	a1,a1,s2
    800042cc:	2585                	addiw	a1,a1,1
    800042ce:	028a2503          	lw	a0,40(s4)
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	cd2080e7          	jalr	-814(ra) # 80002fa4 <bread>
    800042da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042dc:	000aa583          	lw	a1,0(s5)
    800042e0:	028a2503          	lw	a0,40(s4)
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	cc0080e7          	jalr	-832(ra) # 80002fa4 <bread>
    800042ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042ee:	40000613          	li	a2,1024
    800042f2:	05850593          	addi	a1,a0,88
    800042f6:	05848513          	addi	a0,s1,88
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	b42080e7          	jalr	-1214(ra) # 80000e3c <memmove>
    bwrite(to);  // write the log
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	d92080e7          	jalr	-622(ra) # 80003096 <bwrite>
    brelse(from);
    8000430c:	854e                	mv	a0,s3
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	dc6080e7          	jalr	-570(ra) # 800030d4 <brelse>
    brelse(to);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	dbc080e7          	jalr	-580(ra) # 800030d4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004320:	2905                	addiw	s2,s2,1
    80004322:	0a91                	addi	s5,s5,4
    80004324:	02ca2783          	lw	a5,44(s4)
    80004328:	f8f94ee3          	blt	s2,a5,800042c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	c6a080e7          	jalr	-918(ra) # 80003f96 <write_head>
    install_trans(0); // Now install writes to home locations
    80004334:	4501                	li	a0,0
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	cda080e7          	jalr	-806(ra) # 80004010 <install_trans>
    log.lh.n = 0;
    8000433e:	0003d797          	auipc	a5,0x3d
    80004342:	f407af23          	sw	zero,-162(a5) # 8004129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c50080e7          	jalr	-944(ra) # 80003f96 <write_head>
    8000434e:	bdf5                	j	8000424a <end_op+0x52>

0000000080004350 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004350:	1101                	addi	sp,sp,-32
    80004352:	ec06                	sd	ra,24(sp)
    80004354:	e822                	sd	s0,16(sp)
    80004356:	e426                	sd	s1,8(sp)
    80004358:	e04a                	sd	s2,0(sp)
    8000435a:	1000                	addi	s0,sp,32
    8000435c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000435e:	0003d917          	auipc	s2,0x3d
    80004362:	f1290913          	addi	s2,s2,-238 # 80041270 <log>
    80004366:	854a                	mv	a0,s2
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	978080e7          	jalr	-1672(ra) # 80000ce0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004370:	02c92603          	lw	a2,44(s2)
    80004374:	47f5                	li	a5,29
    80004376:	06c7c563          	blt	a5,a2,800043e0 <log_write+0x90>
    8000437a:	0003d797          	auipc	a5,0x3d
    8000437e:	f127a783          	lw	a5,-238(a5) # 8004128c <log+0x1c>
    80004382:	37fd                	addiw	a5,a5,-1
    80004384:	04f65e63          	bge	a2,a5,800043e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004388:	0003d797          	auipc	a5,0x3d
    8000438c:	f087a783          	lw	a5,-248(a5) # 80041290 <log+0x20>
    80004390:	06f05063          	blez	a5,800043f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004394:	4781                	li	a5,0
    80004396:	06c05563          	blez	a2,80004400 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000439a:	44cc                	lw	a1,12(s1)
    8000439c:	0003d717          	auipc	a4,0x3d
    800043a0:	f0470713          	addi	a4,a4,-252 # 800412a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a6:	4314                	lw	a3,0(a4)
    800043a8:	04b68c63          	beq	a3,a1,80004400 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043ac:	2785                	addiw	a5,a5,1
    800043ae:	0711                	addi	a4,a4,4
    800043b0:	fef61be3          	bne	a2,a5,800043a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b4:	0621                	addi	a2,a2,8
    800043b6:	060a                	slli	a2,a2,0x2
    800043b8:	0003d797          	auipc	a5,0x3d
    800043bc:	eb878793          	addi	a5,a5,-328 # 80041270 <log>
    800043c0:	963e                	add	a2,a2,a5
    800043c2:	44dc                	lw	a5,12(s1)
    800043c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	daa080e7          	jalr	-598(ra) # 80003172 <bpin>
    log.lh.n++;
    800043d0:	0003d717          	auipc	a4,0x3d
    800043d4:	ea070713          	addi	a4,a4,-352 # 80041270 <log>
    800043d8:	575c                	lw	a5,44(a4)
    800043da:	2785                	addiw	a5,a5,1
    800043dc:	d75c                	sw	a5,44(a4)
    800043de:	a835                	j	8000441a <log_write+0xca>
    panic("too big a transaction");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	25850513          	addi	a0,a0,600 # 80008638 <syscalls+0x1f0>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	156080e7          	jalr	342(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	26050513          	addi	a0,a0,608 # 80008650 <syscalls+0x208>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004400:	00878713          	addi	a4,a5,8
    80004404:	00271693          	slli	a3,a4,0x2
    80004408:	0003d717          	auipc	a4,0x3d
    8000440c:	e6870713          	addi	a4,a4,-408 # 80041270 <log>
    80004410:	9736                	add	a4,a4,a3
    80004412:	44d4                	lw	a3,12(s1)
    80004414:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004416:	faf608e3          	beq	a2,a5,800043c6 <log_write+0x76>
  }
  release(&log.lock);
    8000441a:	0003d517          	auipc	a0,0x3d
    8000441e:	e5650513          	addi	a0,a0,-426 # 80041270 <log>
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	972080e7          	jalr	-1678(ra) # 80000d94 <release>
}
    8000442a:	60e2                	ld	ra,24(sp)
    8000442c:	6442                	ld	s0,16(sp)
    8000442e:	64a2                	ld	s1,8(sp)
    80004430:	6902                	ld	s2,0(sp)
    80004432:	6105                	addi	sp,sp,32
    80004434:	8082                	ret

0000000080004436 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004436:	1101                	addi	sp,sp,-32
    80004438:	ec06                	sd	ra,24(sp)
    8000443a:	e822                	sd	s0,16(sp)
    8000443c:	e426                	sd	s1,8(sp)
    8000443e:	e04a                	sd	s2,0(sp)
    80004440:	1000                	addi	s0,sp,32
    80004442:	84aa                	mv	s1,a0
    80004444:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004446:	00004597          	auipc	a1,0x4
    8000444a:	22a58593          	addi	a1,a1,554 # 80008670 <syscalls+0x228>
    8000444e:	0521                	addi	a0,a0,8
    80004450:	ffffd097          	auipc	ra,0xffffd
    80004454:	800080e7          	jalr	-2048(ra) # 80000c50 <initlock>
  lk->name = name;
    80004458:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000445c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004460:	0204a423          	sw	zero,40(s1)
}
    80004464:	60e2                	ld	ra,24(sp)
    80004466:	6442                	ld	s0,16(sp)
    80004468:	64a2                	ld	s1,8(sp)
    8000446a:	6902                	ld	s2,0(sp)
    8000446c:	6105                	addi	sp,sp,32
    8000446e:	8082                	ret

0000000080004470 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004470:	1101                	addi	sp,sp,-32
    80004472:	ec06                	sd	ra,24(sp)
    80004474:	e822                	sd	s0,16(sp)
    80004476:	e426                	sd	s1,8(sp)
    80004478:	e04a                	sd	s2,0(sp)
    8000447a:	1000                	addi	s0,sp,32
    8000447c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000447e:	00850913          	addi	s2,a0,8
    80004482:	854a                	mv	a0,s2
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	85c080e7          	jalr	-1956(ra) # 80000ce0 <acquire>
  while (lk->locked) {
    8000448c:	409c                	lw	a5,0(s1)
    8000448e:	cb89                	beqz	a5,800044a0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004490:	85ca                	mv	a1,s2
    80004492:	8526                	mv	a0,s1
    80004494:	ffffe097          	auipc	ra,0xffffe
    80004498:	cde080e7          	jalr	-802(ra) # 80002172 <sleep>
  while (lk->locked) {
    8000449c:	409c                	lw	a5,0(s1)
    8000449e:	fbed                	bnez	a5,80004490 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044a0:	4785                	li	a5,1
    800044a2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	612080e7          	jalr	1554(ra) # 80001ab6 <myproc>
    800044ac:	591c                	lw	a5,48(a0)
    800044ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b0:	854a                	mv	a0,s2
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	8e2080e7          	jalr	-1822(ra) # 80000d94 <release>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	64a2                	ld	s1,8(sp)
    800044c0:	6902                	ld	s2,0(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044c6:	1101                	addi	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	e426                	sd	s1,8(sp)
    800044ce:	e04a                	sd	s2,0(sp)
    800044d0:	1000                	addi	s0,sp,32
    800044d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d4:	00850913          	addi	s2,a0,8
    800044d8:	854a                	mv	a0,s2
    800044da:	ffffd097          	auipc	ra,0xffffd
    800044de:	806080e7          	jalr	-2042(ra) # 80000ce0 <acquire>
  lk->locked = 0;
    800044e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffe097          	auipc	ra,0xffffe
    800044f0:	e12080e7          	jalr	-494(ra) # 800022fe <wakeup>
  release(&lk->lk);
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffd097          	auipc	ra,0xffffd
    800044fa:	89e080e7          	jalr	-1890(ra) # 80000d94 <release>
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000450a:	7179                	addi	sp,sp,-48
    8000450c:	f406                	sd	ra,40(sp)
    8000450e:	f022                	sd	s0,32(sp)
    80004510:	ec26                	sd	s1,24(sp)
    80004512:	e84a                	sd	s2,16(sp)
    80004514:	e44e                	sd	s3,8(sp)
    80004516:	1800                	addi	s0,sp,48
    80004518:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000451a:	00850913          	addi	s2,a0,8
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	7c0080e7          	jalr	1984(ra) # 80000ce0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004528:	409c                	lw	a5,0(s1)
    8000452a:	ef99                	bnez	a5,80004548 <holdingsleep+0x3e>
    8000452c:	4481                	li	s1,0
  release(&lk->lk);
    8000452e:	854a                	mv	a0,s2
    80004530:	ffffd097          	auipc	ra,0xffffd
    80004534:	864080e7          	jalr	-1948(ra) # 80000d94 <release>
  return r;
}
    80004538:	8526                	mv	a0,s1
    8000453a:	70a2                	ld	ra,40(sp)
    8000453c:	7402                	ld	s0,32(sp)
    8000453e:	64e2                	ld	s1,24(sp)
    80004540:	6942                	ld	s2,16(sp)
    80004542:	69a2                	ld	s3,8(sp)
    80004544:	6145                	addi	sp,sp,48
    80004546:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004548:	0284a983          	lw	s3,40(s1)
    8000454c:	ffffd097          	auipc	ra,0xffffd
    80004550:	56a080e7          	jalr	1386(ra) # 80001ab6 <myproc>
    80004554:	5904                	lw	s1,48(a0)
    80004556:	413484b3          	sub	s1,s1,s3
    8000455a:	0014b493          	seqz	s1,s1
    8000455e:	bfc1                	j	8000452e <holdingsleep+0x24>

0000000080004560 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004560:	1141                	addi	sp,sp,-16
    80004562:	e406                	sd	ra,8(sp)
    80004564:	e022                	sd	s0,0(sp)
    80004566:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004568:	00004597          	auipc	a1,0x4
    8000456c:	11858593          	addi	a1,a1,280 # 80008680 <syscalls+0x238>
    80004570:	0003d517          	auipc	a0,0x3d
    80004574:	e4850513          	addi	a0,a0,-440 # 800413b8 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	6d8080e7          	jalr	1752(ra) # 80000c50 <initlock>
}
    80004580:	60a2                	ld	ra,8(sp)
    80004582:	6402                	ld	s0,0(sp)
    80004584:	0141                	addi	sp,sp,16
    80004586:	8082                	ret

0000000080004588 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004588:	1101                	addi	sp,sp,-32
    8000458a:	ec06                	sd	ra,24(sp)
    8000458c:	e822                	sd	s0,16(sp)
    8000458e:	e426                	sd	s1,8(sp)
    80004590:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004592:	0003d517          	auipc	a0,0x3d
    80004596:	e2650513          	addi	a0,a0,-474 # 800413b8 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	746080e7          	jalr	1862(ra) # 80000ce0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a2:	0003d497          	auipc	s1,0x3d
    800045a6:	e2e48493          	addi	s1,s1,-466 # 800413d0 <ftable+0x18>
    800045aa:	0003e717          	auipc	a4,0x3e
    800045ae:	dc670713          	addi	a4,a4,-570 # 80042370 <ftable+0xfb8>
    if(f->ref == 0){
    800045b2:	40dc                	lw	a5,4(s1)
    800045b4:	cf99                	beqz	a5,800045d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b6:	02848493          	addi	s1,s1,40
    800045ba:	fee49ce3          	bne	s1,a4,800045b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045be:	0003d517          	auipc	a0,0x3d
    800045c2:	dfa50513          	addi	a0,a0,-518 # 800413b8 <ftable>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	7ce080e7          	jalr	1998(ra) # 80000d94 <release>
  return 0;
    800045ce:	4481                	li	s1,0
    800045d0:	a819                	j	800045e6 <filealloc+0x5e>
      f->ref = 1;
    800045d2:	4785                	li	a5,1
    800045d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045d6:	0003d517          	auipc	a0,0x3d
    800045da:	de250513          	addi	a0,a0,-542 # 800413b8 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	7b6080e7          	jalr	1974(ra) # 80000d94 <release>
}
    800045e6:	8526                	mv	a0,s1
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6105                	addi	sp,sp,32
    800045f0:	8082                	ret

00000000800045f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f2:	1101                	addi	sp,sp,-32
    800045f4:	ec06                	sd	ra,24(sp)
    800045f6:	e822                	sd	s0,16(sp)
    800045f8:	e426                	sd	s1,8(sp)
    800045fa:	1000                	addi	s0,sp,32
    800045fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045fe:	0003d517          	auipc	a0,0x3d
    80004602:	dba50513          	addi	a0,a0,-582 # 800413b8 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	6da080e7          	jalr	1754(ra) # 80000ce0 <acquire>
  if(f->ref < 1)
    8000460e:	40dc                	lw	a5,4(s1)
    80004610:	02f05263          	blez	a5,80004634 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004614:	2785                	addiw	a5,a5,1
    80004616:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004618:	0003d517          	auipc	a0,0x3d
    8000461c:	da050513          	addi	a0,a0,-608 # 800413b8 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	774080e7          	jalr	1908(ra) # 80000d94 <release>
  return f;
}
    80004628:	8526                	mv	a0,s1
    8000462a:	60e2                	ld	ra,24(sp)
    8000462c:	6442                	ld	s0,16(sp)
    8000462e:	64a2                	ld	s1,8(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret
    panic("filedup");
    80004634:	00004517          	auipc	a0,0x4
    80004638:	05450513          	addi	a0,a0,84 # 80008688 <syscalls+0x240>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>

0000000080004644 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004644:	7139                	addi	sp,sp,-64
    80004646:	fc06                	sd	ra,56(sp)
    80004648:	f822                	sd	s0,48(sp)
    8000464a:	f426                	sd	s1,40(sp)
    8000464c:	f04a                	sd	s2,32(sp)
    8000464e:	ec4e                	sd	s3,24(sp)
    80004650:	e852                	sd	s4,16(sp)
    80004652:	e456                	sd	s5,8(sp)
    80004654:	0080                	addi	s0,sp,64
    80004656:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004658:	0003d517          	auipc	a0,0x3d
    8000465c:	d6050513          	addi	a0,a0,-672 # 800413b8 <ftable>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	680080e7          	jalr	1664(ra) # 80000ce0 <acquire>
  if(f->ref < 1)
    80004668:	40dc                	lw	a5,4(s1)
    8000466a:	06f05163          	blez	a5,800046cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000466e:	37fd                	addiw	a5,a5,-1
    80004670:	0007871b          	sext.w	a4,a5
    80004674:	c0dc                	sw	a5,4(s1)
    80004676:	06e04363          	bgtz	a4,800046dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000467a:	0004a903          	lw	s2,0(s1)
    8000467e:	0094ca83          	lbu	s5,9(s1)
    80004682:	0104ba03          	ld	s4,16(s1)
    80004686:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000468a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000468e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004692:	0003d517          	auipc	a0,0x3d
    80004696:	d2650513          	addi	a0,a0,-730 # 800413b8 <ftable>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	6fa080e7          	jalr	1786(ra) # 80000d94 <release>

  if(ff.type == FD_PIPE){
    800046a2:	4785                	li	a5,1
    800046a4:	04f90d63          	beq	s2,a5,800046fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a8:	3979                	addiw	s2,s2,-2
    800046aa:	4785                	li	a5,1
    800046ac:	0527e063          	bltu	a5,s2,800046ec <fileclose+0xa8>
    begin_op();
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	ac8080e7          	jalr	-1336(ra) # 80004178 <begin_op>
    iput(ff.ip);
    800046b8:	854e                	mv	a0,s3
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	2a6080e7          	jalr	678(ra) # 80003960 <iput>
    end_op();
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	b36080e7          	jalr	-1226(ra) # 800041f8 <end_op>
    800046ca:	a00d                	j	800046ec <fileclose+0xa8>
    panic("fileclose");
    800046cc:	00004517          	auipc	a0,0x4
    800046d0:	fc450513          	addi	a0,a0,-60 # 80008690 <syscalls+0x248>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046dc:	0003d517          	auipc	a0,0x3d
    800046e0:	cdc50513          	addi	a0,a0,-804 # 800413b8 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	6b0080e7          	jalr	1712(ra) # 80000d94 <release>
  }
}
    800046ec:	70e2                	ld	ra,56(sp)
    800046ee:	7442                	ld	s0,48(sp)
    800046f0:	74a2                	ld	s1,40(sp)
    800046f2:	7902                	ld	s2,32(sp)
    800046f4:	69e2                	ld	s3,24(sp)
    800046f6:	6a42                	ld	s4,16(sp)
    800046f8:	6aa2                	ld	s5,8(sp)
    800046fa:	6121                	addi	sp,sp,64
    800046fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046fe:	85d6                	mv	a1,s5
    80004700:	8552                	mv	a0,s4
    80004702:	00000097          	auipc	ra,0x0
    80004706:	34c080e7          	jalr	844(ra) # 80004a4e <pipeclose>
    8000470a:	b7cd                	j	800046ec <fileclose+0xa8>

000000008000470c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000470c:	715d                	addi	sp,sp,-80
    8000470e:	e486                	sd	ra,72(sp)
    80004710:	e0a2                	sd	s0,64(sp)
    80004712:	fc26                	sd	s1,56(sp)
    80004714:	f84a                	sd	s2,48(sp)
    80004716:	f44e                	sd	s3,40(sp)
    80004718:	0880                	addi	s0,sp,80
    8000471a:	84aa                	mv	s1,a0
    8000471c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000471e:	ffffd097          	auipc	ra,0xffffd
    80004722:	398080e7          	jalr	920(ra) # 80001ab6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004726:	409c                	lw	a5,0(s1)
    80004728:	37f9                	addiw	a5,a5,-2
    8000472a:	4705                	li	a4,1
    8000472c:	04f76763          	bltu	a4,a5,8000477a <filestat+0x6e>
    80004730:	892a                	mv	s2,a0
    ilock(f->ip);
    80004732:	6c88                	ld	a0,24(s1)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	072080e7          	jalr	114(ra) # 800037a6 <ilock>
    stati(f->ip, &st);
    8000473c:	fb840593          	addi	a1,s0,-72
    80004740:	6c88                	ld	a0,24(s1)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	2ee080e7          	jalr	750(ra) # 80003a30 <stati>
    iunlock(f->ip);
    8000474a:	6c88                	ld	a0,24(s1)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	11c080e7          	jalr	284(ra) # 80003868 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004754:	46e1                	li	a3,24
    80004756:	fb840613          	addi	a2,s0,-72
    8000475a:	85ce                	mv	a1,s3
    8000475c:	05093503          	ld	a0,80(s2)
    80004760:	ffffd097          	auipc	ra,0xffffd
    80004764:	004080e7          	jalr	4(ra) # 80001764 <copyout>
    80004768:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000476c:	60a6                	ld	ra,72(sp)
    8000476e:	6406                	ld	s0,64(sp)
    80004770:	74e2                	ld	s1,56(sp)
    80004772:	7942                	ld	s2,48(sp)
    80004774:	79a2                	ld	s3,40(sp)
    80004776:	6161                	addi	sp,sp,80
    80004778:	8082                	ret
  return -1;
    8000477a:	557d                	li	a0,-1
    8000477c:	bfc5                	j	8000476c <filestat+0x60>

000000008000477e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000477e:	7179                	addi	sp,sp,-48
    80004780:	f406                	sd	ra,40(sp)
    80004782:	f022                	sd	s0,32(sp)
    80004784:	ec26                	sd	s1,24(sp)
    80004786:	e84a                	sd	s2,16(sp)
    80004788:	e44e                	sd	s3,8(sp)
    8000478a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000478c:	00854783          	lbu	a5,8(a0)
    80004790:	c3d5                	beqz	a5,80004834 <fileread+0xb6>
    80004792:	84aa                	mv	s1,a0
    80004794:	89ae                	mv	s3,a1
    80004796:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004798:	411c                	lw	a5,0(a0)
    8000479a:	4705                	li	a4,1
    8000479c:	04e78963          	beq	a5,a4,800047ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a0:	470d                	li	a4,3
    800047a2:	04e78d63          	beq	a5,a4,800047fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a6:	4709                	li	a4,2
    800047a8:	06e79e63          	bne	a5,a4,80004824 <fileread+0xa6>
    ilock(f->ip);
    800047ac:	6d08                	ld	a0,24(a0)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	ff8080e7          	jalr	-8(ra) # 800037a6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047b6:	874a                	mv	a4,s2
    800047b8:	5094                	lw	a3,32(s1)
    800047ba:	864e                	mv	a2,s3
    800047bc:	4585                	li	a1,1
    800047be:	6c88                	ld	a0,24(s1)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	29a080e7          	jalr	666(ra) # 80003a5a <readi>
    800047c8:	892a                	mv	s2,a0
    800047ca:	00a05563          	blez	a0,800047d4 <fileread+0x56>
      f->off += r;
    800047ce:	509c                	lw	a5,32(s1)
    800047d0:	9fa9                	addw	a5,a5,a0
    800047d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047d4:	6c88                	ld	a0,24(s1)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	092080e7          	jalr	146(ra) # 80003868 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047de:	854a                	mv	a0,s2
    800047e0:	70a2                	ld	ra,40(sp)
    800047e2:	7402                	ld	s0,32(sp)
    800047e4:	64e2                	ld	s1,24(sp)
    800047e6:	6942                	ld	s2,16(sp)
    800047e8:	69a2                	ld	s3,8(sp)
    800047ea:	6145                	addi	sp,sp,48
    800047ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047ee:	6908                	ld	a0,16(a0)
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	3c8080e7          	jalr	968(ra) # 80004bb8 <piperead>
    800047f8:	892a                	mv	s2,a0
    800047fa:	b7d5                	j	800047de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047fc:	02451783          	lh	a5,36(a0)
    80004800:	03079693          	slli	a3,a5,0x30
    80004804:	92c1                	srli	a3,a3,0x30
    80004806:	4725                	li	a4,9
    80004808:	02d76863          	bltu	a4,a3,80004838 <fileread+0xba>
    8000480c:	0792                	slli	a5,a5,0x4
    8000480e:	0003d717          	auipc	a4,0x3d
    80004812:	b0a70713          	addi	a4,a4,-1270 # 80041318 <devsw>
    80004816:	97ba                	add	a5,a5,a4
    80004818:	639c                	ld	a5,0(a5)
    8000481a:	c38d                	beqz	a5,8000483c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000481c:	4505                	li	a0,1
    8000481e:	9782                	jalr	a5
    80004820:	892a                	mv	s2,a0
    80004822:	bf75                	j	800047de <fileread+0x60>
    panic("fileread");
    80004824:	00004517          	auipc	a0,0x4
    80004828:	e7c50513          	addi	a0,a0,-388 # 800086a0 <syscalls+0x258>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>
    return -1;
    80004834:	597d                	li	s2,-1
    80004836:	b765                	j	800047de <fileread+0x60>
      return -1;
    80004838:	597d                	li	s2,-1
    8000483a:	b755                	j	800047de <fileread+0x60>
    8000483c:	597d                	li	s2,-1
    8000483e:	b745                	j	800047de <fileread+0x60>

0000000080004840 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004840:	715d                	addi	sp,sp,-80
    80004842:	e486                	sd	ra,72(sp)
    80004844:	e0a2                	sd	s0,64(sp)
    80004846:	fc26                	sd	s1,56(sp)
    80004848:	f84a                	sd	s2,48(sp)
    8000484a:	f44e                	sd	s3,40(sp)
    8000484c:	f052                	sd	s4,32(sp)
    8000484e:	ec56                	sd	s5,24(sp)
    80004850:	e85a                	sd	s6,16(sp)
    80004852:	e45e                	sd	s7,8(sp)
    80004854:	e062                	sd	s8,0(sp)
    80004856:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004858:	00954783          	lbu	a5,9(a0)
    8000485c:	10078663          	beqz	a5,80004968 <filewrite+0x128>
    80004860:	892a                	mv	s2,a0
    80004862:	8aae                	mv	s5,a1
    80004864:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004866:	411c                	lw	a5,0(a0)
    80004868:	4705                	li	a4,1
    8000486a:	02e78263          	beq	a5,a4,8000488e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000486e:	470d                	li	a4,3
    80004870:	02e78663          	beq	a5,a4,8000489c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004874:	4709                	li	a4,2
    80004876:	0ee79163          	bne	a5,a4,80004958 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000487a:	0ac05d63          	blez	a2,80004934 <filewrite+0xf4>
    int i = 0;
    8000487e:	4981                	li	s3,0
    80004880:	6b05                	lui	s6,0x1
    80004882:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004886:	6b85                	lui	s7,0x1
    80004888:	c00b8b9b          	addiw	s7,s7,-1024
    8000488c:	a861                	j	80004924 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000488e:	6908                	ld	a0,16(a0)
    80004890:	00000097          	auipc	ra,0x0
    80004894:	22e080e7          	jalr	558(ra) # 80004abe <pipewrite>
    80004898:	8a2a                	mv	s4,a0
    8000489a:	a045                	j	8000493a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000489c:	02451783          	lh	a5,36(a0)
    800048a0:	03079693          	slli	a3,a5,0x30
    800048a4:	92c1                	srli	a3,a3,0x30
    800048a6:	4725                	li	a4,9
    800048a8:	0cd76263          	bltu	a4,a3,8000496c <filewrite+0x12c>
    800048ac:	0792                	slli	a5,a5,0x4
    800048ae:	0003d717          	auipc	a4,0x3d
    800048b2:	a6a70713          	addi	a4,a4,-1430 # 80041318 <devsw>
    800048b6:	97ba                	add	a5,a5,a4
    800048b8:	679c                	ld	a5,8(a5)
    800048ba:	cbdd                	beqz	a5,80004970 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048bc:	4505                	li	a0,1
    800048be:	9782                	jalr	a5
    800048c0:	8a2a                	mv	s4,a0
    800048c2:	a8a5                	j	8000493a <filewrite+0xfa>
    800048c4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	8b0080e7          	jalr	-1872(ra) # 80004178 <begin_op>
      ilock(f->ip);
    800048d0:	01893503          	ld	a0,24(s2)
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	ed2080e7          	jalr	-302(ra) # 800037a6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048dc:	8762                	mv	a4,s8
    800048de:	02092683          	lw	a3,32(s2)
    800048e2:	01598633          	add	a2,s3,s5
    800048e6:	4585                	li	a1,1
    800048e8:	01893503          	ld	a0,24(s2)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	266080e7          	jalr	614(ra) # 80003b52 <writei>
    800048f4:	84aa                	mv	s1,a0
    800048f6:	00a05763          	blez	a0,80004904 <filewrite+0xc4>
        f->off += r;
    800048fa:	02092783          	lw	a5,32(s2)
    800048fe:	9fa9                	addw	a5,a5,a0
    80004900:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004904:	01893503          	ld	a0,24(s2)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	f60080e7          	jalr	-160(ra) # 80003868 <iunlock>
      end_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	8e8080e7          	jalr	-1816(ra) # 800041f8 <end_op>

      if(r != n1){
    80004918:	009c1f63          	bne	s8,s1,80004936 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000491c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004920:	0149db63          	bge	s3,s4,80004936 <filewrite+0xf6>
      int n1 = n - i;
    80004924:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004928:	84be                	mv	s1,a5
    8000492a:	2781                	sext.w	a5,a5
    8000492c:	f8fb5ce3          	bge	s6,a5,800048c4 <filewrite+0x84>
    80004930:	84de                	mv	s1,s7
    80004932:	bf49                	j	800048c4 <filewrite+0x84>
    int i = 0;
    80004934:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004936:	013a1f63          	bne	s4,s3,80004954 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000493a:	8552                	mv	a0,s4
    8000493c:	60a6                	ld	ra,72(sp)
    8000493e:	6406                	ld	s0,64(sp)
    80004940:	74e2                	ld	s1,56(sp)
    80004942:	7942                	ld	s2,48(sp)
    80004944:	79a2                	ld	s3,40(sp)
    80004946:	7a02                	ld	s4,32(sp)
    80004948:	6ae2                	ld	s5,24(sp)
    8000494a:	6b42                	ld	s6,16(sp)
    8000494c:	6ba2                	ld	s7,8(sp)
    8000494e:	6c02                	ld	s8,0(sp)
    80004950:	6161                	addi	sp,sp,80
    80004952:	8082                	ret
    ret = (i == n ? n : -1);
    80004954:	5a7d                	li	s4,-1
    80004956:	b7d5                	j	8000493a <filewrite+0xfa>
    panic("filewrite");
    80004958:	00004517          	auipc	a0,0x4
    8000495c:	d5850513          	addi	a0,a0,-680 # 800086b0 <syscalls+0x268>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    return -1;
    80004968:	5a7d                	li	s4,-1
    8000496a:	bfc1                	j	8000493a <filewrite+0xfa>
      return -1;
    8000496c:	5a7d                	li	s4,-1
    8000496e:	b7f1                	j	8000493a <filewrite+0xfa>
    80004970:	5a7d                	li	s4,-1
    80004972:	b7e1                	j	8000493a <filewrite+0xfa>

0000000080004974 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004974:	7179                	addi	sp,sp,-48
    80004976:	f406                	sd	ra,40(sp)
    80004978:	f022                	sd	s0,32(sp)
    8000497a:	ec26                	sd	s1,24(sp)
    8000497c:	e84a                	sd	s2,16(sp)
    8000497e:	e44e                	sd	s3,8(sp)
    80004980:	e052                	sd	s4,0(sp)
    80004982:	1800                	addi	s0,sp,48
    80004984:	84aa                	mv	s1,a0
    80004986:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004988:	0005b023          	sd	zero,0(a1)
    8000498c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004990:	00000097          	auipc	ra,0x0
    80004994:	bf8080e7          	jalr	-1032(ra) # 80004588 <filealloc>
    80004998:	e088                	sd	a0,0(s1)
    8000499a:	c551                	beqz	a0,80004a26 <pipealloc+0xb2>
    8000499c:	00000097          	auipc	ra,0x0
    800049a0:	bec080e7          	jalr	-1044(ra) # 80004588 <filealloc>
    800049a4:	00aa3023          	sd	a0,0(s4)
    800049a8:	c92d                	beqz	a0,80004a1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	23c080e7          	jalr	572(ra) # 80000be6 <kalloc>
    800049b2:	892a                	mv	s2,a0
    800049b4:	c125                	beqz	a0,80004a14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b6:	4985                	li	s3,1
    800049b8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049bc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049c0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049c4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c8:	00004597          	auipc	a1,0x4
    800049cc:	cf858593          	addi	a1,a1,-776 # 800086c0 <syscalls+0x278>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	280080e7          	jalr	640(ra) # 80000c50 <initlock>
  (*f0)->type = FD_PIPE;
    800049d8:	609c                	ld	a5,0(s1)
    800049da:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049de:	609c                	ld	a5,0(s1)
    800049e0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ea:	609c                	ld	a5,0(s1)
    800049ec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a08:	000a3783          	ld	a5,0(s4)
    80004a0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a10:	4501                	li	a0,0
    80004a12:	a025                	j	80004a3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a14:	6088                	ld	a0,0(s1)
    80004a16:	e501                	bnez	a0,80004a1e <pipealloc+0xaa>
    80004a18:	a039                	j	80004a26 <pipealloc+0xb2>
    80004a1a:	6088                	ld	a0,0(s1)
    80004a1c:	c51d                	beqz	a0,80004a4a <pipealloc+0xd6>
    fileclose(*f0);
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	c26080e7          	jalr	-986(ra) # 80004644 <fileclose>
  if(*f1)
    80004a26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a2a:	557d                	li	a0,-1
  if(*f1)
    80004a2c:	c799                	beqz	a5,80004a3a <pipealloc+0xc6>
    fileclose(*f1);
    80004a2e:	853e                	mv	a0,a5
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	c14080e7          	jalr	-1004(ra) # 80004644 <fileclose>
  return -1;
    80004a38:	557d                	li	a0,-1
}
    80004a3a:	70a2                	ld	ra,40(sp)
    80004a3c:	7402                	ld	s0,32(sp)
    80004a3e:	64e2                	ld	s1,24(sp)
    80004a40:	6942                	ld	s2,16(sp)
    80004a42:	69a2                	ld	s3,8(sp)
    80004a44:	6a02                	ld	s4,0(sp)
    80004a46:	6145                	addi	sp,sp,48
    80004a48:	8082                	ret
  return -1;
    80004a4a:	557d                	li	a0,-1
    80004a4c:	b7fd                	j	80004a3a <pipealloc+0xc6>

0000000080004a4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a4e:	1101                	addi	sp,sp,-32
    80004a50:	ec06                	sd	ra,24(sp)
    80004a52:	e822                	sd	s0,16(sp)
    80004a54:	e426                	sd	s1,8(sp)
    80004a56:	e04a                	sd	s2,0(sp)
    80004a58:	1000                	addi	s0,sp,32
    80004a5a:	84aa                	mv	s1,a0
    80004a5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	282080e7          	jalr	642(ra) # 80000ce0 <acquire>
  if(writable){
    80004a66:	02090d63          	beqz	s2,80004aa0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a6e:	21848513          	addi	a0,s1,536
    80004a72:	ffffe097          	auipc	ra,0xffffe
    80004a76:	88c080e7          	jalr	-1908(ra) # 800022fe <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a7a:	2204b783          	ld	a5,544(s1)
    80004a7e:	eb95                	bnez	a5,80004ab2 <pipeclose+0x64>
    release(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	312080e7          	jalr	786(ra) # 80000d94 <release>
    kfree((char*)pi);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	fd0080e7          	jalr	-48(ra) # 80000a5c <kfree>
  } else
    release(&pi->lock);
}
    80004a94:	60e2                	ld	ra,24(sp)
    80004a96:	6442                	ld	s0,16(sp)
    80004a98:	64a2                	ld	s1,8(sp)
    80004a9a:	6902                	ld	s2,0(sp)
    80004a9c:	6105                	addi	sp,sp,32
    80004a9e:	8082                	ret
    pi->readopen = 0;
    80004aa0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aa4:	21c48513          	addi	a0,s1,540
    80004aa8:	ffffe097          	auipc	ra,0xffffe
    80004aac:	856080e7          	jalr	-1962(ra) # 800022fe <wakeup>
    80004ab0:	b7e9                	j	80004a7a <pipeclose+0x2c>
    release(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	2e0080e7          	jalr	736(ra) # 80000d94 <release>
}
    80004abc:	bfe1                	j	80004a94 <pipeclose+0x46>

0000000080004abe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004abe:	7159                	addi	sp,sp,-112
    80004ac0:	f486                	sd	ra,104(sp)
    80004ac2:	f0a2                	sd	s0,96(sp)
    80004ac4:	eca6                	sd	s1,88(sp)
    80004ac6:	e8ca                	sd	s2,80(sp)
    80004ac8:	e4ce                	sd	s3,72(sp)
    80004aca:	e0d2                	sd	s4,64(sp)
    80004acc:	fc56                	sd	s5,56(sp)
    80004ace:	f85a                	sd	s6,48(sp)
    80004ad0:	f45e                	sd	s7,40(sp)
    80004ad2:	f062                	sd	s8,32(sp)
    80004ad4:	ec66                	sd	s9,24(sp)
    80004ad6:	1880                	addi	s0,sp,112
    80004ad8:	84aa                	mv	s1,a0
    80004ada:	8aae                	mv	s5,a1
    80004adc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	fd8080e7          	jalr	-40(ra) # 80001ab6 <myproc>
    80004ae6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ae8:	8526                	mv	a0,s1
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	1f6080e7          	jalr	502(ra) # 80000ce0 <acquire>
  while(i < n){
    80004af2:	0d405163          	blez	s4,80004bb4 <pipewrite+0xf6>
    80004af6:	8ba6                	mv	s7,s1
  int i = 0;
    80004af8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004afa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004afc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b00:	21c48c13          	addi	s8,s1,540
    80004b04:	a08d                	j	80004b66 <pipewrite+0xa8>
      release(&pi->lock);
    80004b06:	8526                	mv	a0,s1
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	28c080e7          	jalr	652(ra) # 80000d94 <release>
      return -1;
    80004b10:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b12:	854a                	mv	a0,s2
    80004b14:	70a6                	ld	ra,104(sp)
    80004b16:	7406                	ld	s0,96(sp)
    80004b18:	64e6                	ld	s1,88(sp)
    80004b1a:	6946                	ld	s2,80(sp)
    80004b1c:	69a6                	ld	s3,72(sp)
    80004b1e:	6a06                	ld	s4,64(sp)
    80004b20:	7ae2                	ld	s5,56(sp)
    80004b22:	7b42                	ld	s6,48(sp)
    80004b24:	7ba2                	ld	s7,40(sp)
    80004b26:	7c02                	ld	s8,32(sp)
    80004b28:	6ce2                	ld	s9,24(sp)
    80004b2a:	6165                	addi	sp,sp,112
    80004b2c:	8082                	ret
      wakeup(&pi->nread);
    80004b2e:	8566                	mv	a0,s9
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	7ce080e7          	jalr	1998(ra) # 800022fe <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b38:	85de                	mv	a1,s7
    80004b3a:	8562                	mv	a0,s8
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	636080e7          	jalr	1590(ra) # 80002172 <sleep>
    80004b44:	a839                	j	80004b62 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b46:	21c4a783          	lw	a5,540(s1)
    80004b4a:	0017871b          	addiw	a4,a5,1
    80004b4e:	20e4ae23          	sw	a4,540(s1)
    80004b52:	1ff7f793          	andi	a5,a5,511
    80004b56:	97a6                	add	a5,a5,s1
    80004b58:	f9f44703          	lbu	a4,-97(s0)
    80004b5c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b60:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b62:	03495d63          	bge	s2,s4,80004b9c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b66:	2204a783          	lw	a5,544(s1)
    80004b6a:	dfd1                	beqz	a5,80004b06 <pipewrite+0x48>
    80004b6c:	0289a783          	lw	a5,40(s3)
    80004b70:	fbd9                	bnez	a5,80004b06 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b72:	2184a783          	lw	a5,536(s1)
    80004b76:	21c4a703          	lw	a4,540(s1)
    80004b7a:	2007879b          	addiw	a5,a5,512
    80004b7e:	faf708e3          	beq	a4,a5,80004b2e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b82:	4685                	li	a3,1
    80004b84:	01590633          	add	a2,s2,s5
    80004b88:	f9f40593          	addi	a1,s0,-97
    80004b8c:	0509b503          	ld	a0,80(s3)
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	c74080e7          	jalr	-908(ra) # 80001804 <copyin>
    80004b98:	fb6517e3          	bne	a0,s6,80004b46 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b9c:	21848513          	addi	a0,s1,536
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	75e080e7          	jalr	1886(ra) # 800022fe <wakeup>
  release(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	1ea080e7          	jalr	490(ra) # 80000d94 <release>
  return i;
    80004bb2:	b785                	j	80004b12 <pipewrite+0x54>
  int i = 0;
    80004bb4:	4901                	li	s2,0
    80004bb6:	b7dd                	j	80004b9c <pipewrite+0xde>

0000000080004bb8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb8:	715d                	addi	sp,sp,-80
    80004bba:	e486                	sd	ra,72(sp)
    80004bbc:	e0a2                	sd	s0,64(sp)
    80004bbe:	fc26                	sd	s1,56(sp)
    80004bc0:	f84a                	sd	s2,48(sp)
    80004bc2:	f44e                	sd	s3,40(sp)
    80004bc4:	f052                	sd	s4,32(sp)
    80004bc6:	ec56                	sd	s5,24(sp)
    80004bc8:	e85a                	sd	s6,16(sp)
    80004bca:	0880                	addi	s0,sp,80
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	892e                	mv	s2,a1
    80004bd0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	ee4080e7          	jalr	-284(ra) # 80001ab6 <myproc>
    80004bda:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bdc:	8b26                	mv	s6,s1
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	100080e7          	jalr	256(ra) # 80000ce0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be8:	2184a703          	lw	a4,536(s1)
    80004bec:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf4:	02f71463          	bne	a4,a5,80004c1c <piperead+0x64>
    80004bf8:	2244a783          	lw	a5,548(s1)
    80004bfc:	c385                	beqz	a5,80004c1c <piperead+0x64>
    if(pr->killed){
    80004bfe:	028a2783          	lw	a5,40(s4)
    80004c02:	ebc1                	bnez	a5,80004c92 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c04:	85da                	mv	a1,s6
    80004c06:	854e                	mv	a0,s3
    80004c08:	ffffd097          	auipc	ra,0xffffd
    80004c0c:	56a080e7          	jalr	1386(ra) # 80002172 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c10:	2184a703          	lw	a4,536(s1)
    80004c14:	21c4a783          	lw	a5,540(s1)
    80004c18:	fef700e3          	beq	a4,a5,80004bf8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1c:	09505263          	blez	s5,80004ca0 <piperead+0xe8>
    80004c20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c22:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c24:	2184a783          	lw	a5,536(s1)
    80004c28:	21c4a703          	lw	a4,540(s1)
    80004c2c:	02f70d63          	beq	a4,a5,80004c66 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c30:	0017871b          	addiw	a4,a5,1
    80004c34:	20e4ac23          	sw	a4,536(s1)
    80004c38:	1ff7f793          	andi	a5,a5,511
    80004c3c:	97a6                	add	a5,a5,s1
    80004c3e:	0187c783          	lbu	a5,24(a5)
    80004c42:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c46:	4685                	li	a3,1
    80004c48:	fbf40613          	addi	a2,s0,-65
    80004c4c:	85ca                	mv	a1,s2
    80004c4e:	050a3503          	ld	a0,80(s4)
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	b12080e7          	jalr	-1262(ra) # 80001764 <copyout>
    80004c5a:	01650663          	beq	a0,s6,80004c66 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c5e:	2985                	addiw	s3,s3,1
    80004c60:	0905                	addi	s2,s2,1
    80004c62:	fd3a91e3          	bne	s5,s3,80004c24 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c66:	21c48513          	addi	a0,s1,540
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	694080e7          	jalr	1684(ra) # 800022fe <wakeup>
  release(&pi->lock);
    80004c72:	8526                	mv	a0,s1
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	120080e7          	jalr	288(ra) # 80000d94 <release>
  return i;
}
    80004c7c:	854e                	mv	a0,s3
    80004c7e:	60a6                	ld	ra,72(sp)
    80004c80:	6406                	ld	s0,64(sp)
    80004c82:	74e2                	ld	s1,56(sp)
    80004c84:	7942                	ld	s2,48(sp)
    80004c86:	79a2                	ld	s3,40(sp)
    80004c88:	7a02                	ld	s4,32(sp)
    80004c8a:	6ae2                	ld	s5,24(sp)
    80004c8c:	6b42                	ld	s6,16(sp)
    80004c8e:	6161                	addi	sp,sp,80
    80004c90:	8082                	ret
      release(&pi->lock);
    80004c92:	8526                	mv	a0,s1
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	100080e7          	jalr	256(ra) # 80000d94 <release>
      return -1;
    80004c9c:	59fd                	li	s3,-1
    80004c9e:	bff9                	j	80004c7c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca0:	4981                	li	s3,0
    80004ca2:	b7d1                	j	80004c66 <piperead+0xae>

0000000080004ca4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ca4:	df010113          	addi	sp,sp,-528
    80004ca8:	20113423          	sd	ra,520(sp)
    80004cac:	20813023          	sd	s0,512(sp)
    80004cb0:	ffa6                	sd	s1,504(sp)
    80004cb2:	fbca                	sd	s2,496(sp)
    80004cb4:	f7ce                	sd	s3,488(sp)
    80004cb6:	f3d2                	sd	s4,480(sp)
    80004cb8:	efd6                	sd	s5,472(sp)
    80004cba:	ebda                	sd	s6,464(sp)
    80004cbc:	e7de                	sd	s7,456(sp)
    80004cbe:	e3e2                	sd	s8,448(sp)
    80004cc0:	ff66                	sd	s9,440(sp)
    80004cc2:	fb6a                	sd	s10,432(sp)
    80004cc4:	f76e                	sd	s11,424(sp)
    80004cc6:	0c00                	addi	s0,sp,528
    80004cc8:	84aa                	mv	s1,a0
    80004cca:	dea43c23          	sd	a0,-520(s0)
    80004cce:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	de4080e7          	jalr	-540(ra) # 80001ab6 <myproc>
    80004cda:	892a                	mv	s2,a0

  begin_op();
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	49c080e7          	jalr	1180(ra) # 80004178 <begin_op>

  if((ip = namei(path)) == 0){
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	276080e7          	jalr	630(ra) # 80003f5c <namei>
    80004cee:	c92d                	beqz	a0,80004d60 <exec+0xbc>
    80004cf0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	ab4080e7          	jalr	-1356(ra) # 800037a6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cfa:	04000713          	li	a4,64
    80004cfe:	4681                	li	a3,0
    80004d00:	e5040613          	addi	a2,s0,-432
    80004d04:	4581                	li	a1,0
    80004d06:	8526                	mv	a0,s1
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	d52080e7          	jalr	-686(ra) # 80003a5a <readi>
    80004d10:	04000793          	li	a5,64
    80004d14:	00f51a63          	bne	a0,a5,80004d28 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d18:	e5042703          	lw	a4,-432(s0)
    80004d1c:	464c47b7          	lui	a5,0x464c4
    80004d20:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d24:	04f70463          	beq	a4,a5,80004d6c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d28:	8526                	mv	a0,s1
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	cde080e7          	jalr	-802(ra) # 80003a08 <iunlockput>
    end_op();
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	4c6080e7          	jalr	1222(ra) # 800041f8 <end_op>
  }
  return -1;
    80004d3a:	557d                	li	a0,-1
}
    80004d3c:	20813083          	ld	ra,520(sp)
    80004d40:	20013403          	ld	s0,512(sp)
    80004d44:	74fe                	ld	s1,504(sp)
    80004d46:	795e                	ld	s2,496(sp)
    80004d48:	79be                	ld	s3,488(sp)
    80004d4a:	7a1e                	ld	s4,480(sp)
    80004d4c:	6afe                	ld	s5,472(sp)
    80004d4e:	6b5e                	ld	s6,464(sp)
    80004d50:	6bbe                	ld	s7,456(sp)
    80004d52:	6c1e                	ld	s8,448(sp)
    80004d54:	7cfa                	ld	s9,440(sp)
    80004d56:	7d5a                	ld	s10,432(sp)
    80004d58:	7dba                	ld	s11,424(sp)
    80004d5a:	21010113          	addi	sp,sp,528
    80004d5e:	8082                	ret
    end_op();
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	498080e7          	jalr	1176(ra) # 800041f8 <end_op>
    return -1;
    80004d68:	557d                	li	a0,-1
    80004d6a:	bfc9                	j	80004d3c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d6c:	854a                	mv	a0,s2
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	e0c080e7          	jalr	-500(ra) # 80001b7a <proc_pagetable>
    80004d76:	8baa                	mv	s7,a0
    80004d78:	d945                	beqz	a0,80004d28 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7a:	e7042983          	lw	s3,-400(s0)
    80004d7e:	e8845783          	lhu	a5,-376(s0)
    80004d82:	c7ad                	beqz	a5,80004dec <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d84:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d86:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d88:	6c85                	lui	s9,0x1
    80004d8a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d8e:	def43823          	sd	a5,-528(s0)
    80004d92:	a42d                	j	80004fbc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d94:	00004517          	auipc	a0,0x4
    80004d98:	93450513          	addi	a0,a0,-1740 # 800086c8 <syscalls+0x280>
    80004d9c:	ffffb097          	auipc	ra,0xffffb
    80004da0:	7a2080e7          	jalr	1954(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004da4:	8756                	mv	a4,s5
    80004da6:	012d86bb          	addw	a3,s11,s2
    80004daa:	4581                	li	a1,0
    80004dac:	8526                	mv	a0,s1
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	cac080e7          	jalr	-852(ra) # 80003a5a <readi>
    80004db6:	2501                	sext.w	a0,a0
    80004db8:	1aaa9963          	bne	s5,a0,80004f6a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dbc:	6785                	lui	a5,0x1
    80004dbe:	0127893b          	addw	s2,a5,s2
    80004dc2:	77fd                	lui	a5,0xfffff
    80004dc4:	01478a3b          	addw	s4,a5,s4
    80004dc8:	1f897163          	bgeu	s2,s8,80004faa <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dcc:	02091593          	slli	a1,s2,0x20
    80004dd0:	9181                	srli	a1,a1,0x20
    80004dd2:	95ea                	add	a1,a1,s10
    80004dd4:	855e                	mv	a0,s7
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	394080e7          	jalr	916(ra) # 8000116a <walkaddr>
    80004dde:	862a                	mv	a2,a0
    if(pa == 0)
    80004de0:	d955                	beqz	a0,80004d94 <exec+0xf0>
      n = PGSIZE;
    80004de2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004de4:	fd9a70e3          	bgeu	s4,s9,80004da4 <exec+0x100>
      n = sz - i;
    80004de8:	8ad2                	mv	s5,s4
    80004dea:	bf6d                	j	80004da4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dec:	4901                	li	s2,0
  iunlockput(ip);
    80004dee:	8526                	mv	a0,s1
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	c18080e7          	jalr	-1000(ra) # 80003a08 <iunlockput>
  end_op();
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	400080e7          	jalr	1024(ra) # 800041f8 <end_op>
  p = myproc();
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	cb6080e7          	jalr	-842(ra) # 80001ab6 <myproc>
    80004e08:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e0a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e0e:	6785                	lui	a5,0x1
    80004e10:	17fd                	addi	a5,a5,-1
    80004e12:	993e                	add	s2,s2,a5
    80004e14:	757d                	lui	a0,0xfffff
    80004e16:	00a977b3          	and	a5,s2,a0
    80004e1a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e1e:	6609                	lui	a2,0x2
    80004e20:	963e                	add	a2,a2,a5
    80004e22:	85be                	mv	a1,a5
    80004e24:	855e                	mv	a0,s7
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	6f8080e7          	jalr	1784(ra) # 8000151e <uvmalloc>
    80004e2e:	8b2a                	mv	s6,a0
  ip = 0;
    80004e30:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e32:	12050c63          	beqz	a0,80004f6a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e36:	75f9                	lui	a1,0xffffe
    80004e38:	95aa                	add	a1,a1,a0
    80004e3a:	855e                	mv	a0,s7
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	8f6080e7          	jalr	-1802(ra) # 80001732 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e44:	7c7d                	lui	s8,0xfffff
    80004e46:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e48:	e0043783          	ld	a5,-512(s0)
    80004e4c:	6388                	ld	a0,0(a5)
    80004e4e:	c535                	beqz	a0,80004eba <exec+0x216>
    80004e50:	e9040993          	addi	s3,s0,-368
    80004e54:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e58:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	106080e7          	jalr	262(ra) # 80000f60 <strlen>
    80004e62:	2505                	addiw	a0,a0,1
    80004e64:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e68:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e6c:	13896363          	bltu	s2,s8,80004f92 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e70:	e0043d83          	ld	s11,-512(s0)
    80004e74:	000dba03          	ld	s4,0(s11)
    80004e78:	8552                	mv	a0,s4
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	0e6080e7          	jalr	230(ra) # 80000f60 <strlen>
    80004e82:	0015069b          	addiw	a3,a0,1
    80004e86:	8652                	mv	a2,s4
    80004e88:	85ca                	mv	a1,s2
    80004e8a:	855e                	mv	a0,s7
    80004e8c:	ffffd097          	auipc	ra,0xffffd
    80004e90:	8d8080e7          	jalr	-1832(ra) # 80001764 <copyout>
    80004e94:	10054363          	bltz	a0,80004f9a <exec+0x2f6>
    ustack[argc] = sp;
    80004e98:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e9c:	0485                	addi	s1,s1,1
    80004e9e:	008d8793          	addi	a5,s11,8
    80004ea2:	e0f43023          	sd	a5,-512(s0)
    80004ea6:	008db503          	ld	a0,8(s11)
    80004eaa:	c911                	beqz	a0,80004ebe <exec+0x21a>
    if(argc >= MAXARG)
    80004eac:	09a1                	addi	s3,s3,8
    80004eae:	fb3c96e3          	bne	s9,s3,80004e5a <exec+0x1b6>
  sz = sz1;
    80004eb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eb6:	4481                	li	s1,0
    80004eb8:	a84d                	j	80004f6a <exec+0x2c6>
  sp = sz;
    80004eba:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ebc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ebe:	00349793          	slli	a5,s1,0x3
    80004ec2:	f9040713          	addi	a4,s0,-112
    80004ec6:	97ba                	add	a5,a5,a4
    80004ec8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ecc:	00148693          	addi	a3,s1,1
    80004ed0:	068e                	slli	a3,a3,0x3
    80004ed2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ed6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eda:	01897663          	bgeu	s2,s8,80004ee6 <exec+0x242>
  sz = sz1;
    80004ede:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee2:	4481                	li	s1,0
    80004ee4:	a059                	j	80004f6a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ee6:	e9040613          	addi	a2,s0,-368
    80004eea:	85ca                	mv	a1,s2
    80004eec:	855e                	mv	a0,s7
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	876080e7          	jalr	-1930(ra) # 80001764 <copyout>
    80004ef6:	0a054663          	bltz	a0,80004fa2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004efa:	058ab783          	ld	a5,88(s5)
    80004efe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f02:	df843783          	ld	a5,-520(s0)
    80004f06:	0007c703          	lbu	a4,0(a5)
    80004f0a:	cf11                	beqz	a4,80004f26 <exec+0x282>
    80004f0c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f0e:	02f00693          	li	a3,47
    80004f12:	a039                	j	80004f20 <exec+0x27c>
      last = s+1;
    80004f14:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f18:	0785                	addi	a5,a5,1
    80004f1a:	fff7c703          	lbu	a4,-1(a5)
    80004f1e:	c701                	beqz	a4,80004f26 <exec+0x282>
    if(*s == '/')
    80004f20:	fed71ce3          	bne	a4,a3,80004f18 <exec+0x274>
    80004f24:	bfc5                	j	80004f14 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f26:	4641                	li	a2,16
    80004f28:	df843583          	ld	a1,-520(s0)
    80004f2c:	158a8513          	addi	a0,s5,344
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	ffe080e7          	jalr	-2(ra) # 80000f2e <safestrcpy>
  oldpagetable = p->pagetable;
    80004f38:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f3c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f40:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f44:	058ab783          	ld	a5,88(s5)
    80004f48:	e6843703          	ld	a4,-408(s0)
    80004f4c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f4e:	058ab783          	ld	a5,88(s5)
    80004f52:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f56:	85ea                	mv	a1,s10
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	cbe080e7          	jalr	-834(ra) # 80001c16 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f60:	0004851b          	sext.w	a0,s1
    80004f64:	bbe1                	j	80004d3c <exec+0x98>
    80004f66:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f6a:	e0843583          	ld	a1,-504(s0)
    80004f6e:	855e                	mv	a0,s7
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	ca6080e7          	jalr	-858(ra) # 80001c16 <proc_freepagetable>
  if(ip){
    80004f78:	da0498e3          	bnez	s1,80004d28 <exec+0x84>
  return -1;
    80004f7c:	557d                	li	a0,-1
    80004f7e:	bb7d                	j	80004d3c <exec+0x98>
    80004f80:	e1243423          	sd	s2,-504(s0)
    80004f84:	b7dd                	j	80004f6a <exec+0x2c6>
    80004f86:	e1243423          	sd	s2,-504(s0)
    80004f8a:	b7c5                	j	80004f6a <exec+0x2c6>
    80004f8c:	e1243423          	sd	s2,-504(s0)
    80004f90:	bfe9                	j	80004f6a <exec+0x2c6>
  sz = sz1;
    80004f92:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f96:	4481                	li	s1,0
    80004f98:	bfc9                	j	80004f6a <exec+0x2c6>
  sz = sz1;
    80004f9a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f9e:	4481                	li	s1,0
    80004fa0:	b7e9                	j	80004f6a <exec+0x2c6>
  sz = sz1;
    80004fa2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa6:	4481                	li	s1,0
    80004fa8:	b7c9                	j	80004f6a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004faa:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fae:	2b05                	addiw	s6,s6,1
    80004fb0:	0389899b          	addiw	s3,s3,56
    80004fb4:	e8845783          	lhu	a5,-376(s0)
    80004fb8:	e2fb5be3          	bge	s6,a5,80004dee <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fbc:	2981                	sext.w	s3,s3
    80004fbe:	03800713          	li	a4,56
    80004fc2:	86ce                	mv	a3,s3
    80004fc4:	e1840613          	addi	a2,s0,-488
    80004fc8:	4581                	li	a1,0
    80004fca:	8526                	mv	a0,s1
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	a8e080e7          	jalr	-1394(ra) # 80003a5a <readi>
    80004fd4:	03800793          	li	a5,56
    80004fd8:	f8f517e3          	bne	a0,a5,80004f66 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fdc:	e1842783          	lw	a5,-488(s0)
    80004fe0:	4705                	li	a4,1
    80004fe2:	fce796e3          	bne	a5,a4,80004fae <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fe6:	e4043603          	ld	a2,-448(s0)
    80004fea:	e3843783          	ld	a5,-456(s0)
    80004fee:	f8f669e3          	bltu	a2,a5,80004f80 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ff2:	e2843783          	ld	a5,-472(s0)
    80004ff6:	963e                	add	a2,a2,a5
    80004ff8:	f8f667e3          	bltu	a2,a5,80004f86 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ffc:	85ca                	mv	a1,s2
    80004ffe:	855e                	mv	a0,s7
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	51e080e7          	jalr	1310(ra) # 8000151e <uvmalloc>
    80005008:	e0a43423          	sd	a0,-504(s0)
    8000500c:	d141                	beqz	a0,80004f8c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000500e:	e2843d03          	ld	s10,-472(s0)
    80005012:	df043783          	ld	a5,-528(s0)
    80005016:	00fd77b3          	and	a5,s10,a5
    8000501a:	fba1                	bnez	a5,80004f6a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000501c:	e2042d83          	lw	s11,-480(s0)
    80005020:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005024:	f80c03e3          	beqz	s8,80004faa <exec+0x306>
    80005028:	8a62                	mv	s4,s8
    8000502a:	4901                	li	s2,0
    8000502c:	b345                	j	80004dcc <exec+0x128>

000000008000502e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000502e:	7179                	addi	sp,sp,-48
    80005030:	f406                	sd	ra,40(sp)
    80005032:	f022                	sd	s0,32(sp)
    80005034:	ec26                	sd	s1,24(sp)
    80005036:	e84a                	sd	s2,16(sp)
    80005038:	1800                	addi	s0,sp,48
    8000503a:	892e                	mv	s2,a1
    8000503c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000503e:	fdc40593          	addi	a1,s0,-36
    80005042:	ffffe097          	auipc	ra,0xffffe
    80005046:	bf2080e7          	jalr	-1038(ra) # 80002c34 <argint>
    8000504a:	04054063          	bltz	a0,8000508a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000504e:	fdc42703          	lw	a4,-36(s0)
    80005052:	47bd                	li	a5,15
    80005054:	02e7ed63          	bltu	a5,a4,8000508e <argfd+0x60>
    80005058:	ffffd097          	auipc	ra,0xffffd
    8000505c:	a5e080e7          	jalr	-1442(ra) # 80001ab6 <myproc>
    80005060:	fdc42703          	lw	a4,-36(s0)
    80005064:	01a70793          	addi	a5,a4,26
    80005068:	078e                	slli	a5,a5,0x3
    8000506a:	953e                	add	a0,a0,a5
    8000506c:	611c                	ld	a5,0(a0)
    8000506e:	c395                	beqz	a5,80005092 <argfd+0x64>
    return -1;
  if(pfd)
    80005070:	00090463          	beqz	s2,80005078 <argfd+0x4a>
    *pfd = fd;
    80005074:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005078:	4501                	li	a0,0
  if(pf)
    8000507a:	c091                	beqz	s1,8000507e <argfd+0x50>
    *pf = f;
    8000507c:	e09c                	sd	a5,0(s1)
}
    8000507e:	70a2                	ld	ra,40(sp)
    80005080:	7402                	ld	s0,32(sp)
    80005082:	64e2                	ld	s1,24(sp)
    80005084:	6942                	ld	s2,16(sp)
    80005086:	6145                	addi	sp,sp,48
    80005088:	8082                	ret
    return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	bfcd                	j	8000507e <argfd+0x50>
    return -1;
    8000508e:	557d                	li	a0,-1
    80005090:	b7fd                	j	8000507e <argfd+0x50>
    80005092:	557d                	li	a0,-1
    80005094:	b7ed                	j	8000507e <argfd+0x50>

0000000080005096 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005096:	1101                	addi	sp,sp,-32
    80005098:	ec06                	sd	ra,24(sp)
    8000509a:	e822                	sd	s0,16(sp)
    8000509c:	e426                	sd	s1,8(sp)
    8000509e:	1000                	addi	s0,sp,32
    800050a0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050a2:	ffffd097          	auipc	ra,0xffffd
    800050a6:	a14080e7          	jalr	-1516(ra) # 80001ab6 <myproc>
    800050aa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ac:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffb90d0>
    800050b0:	4501                	li	a0,0
    800050b2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050b4:	6398                	ld	a4,0(a5)
    800050b6:	cb19                	beqz	a4,800050cc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050b8:	2505                	addiw	a0,a0,1
    800050ba:	07a1                	addi	a5,a5,8
    800050bc:	fed51ce3          	bne	a0,a3,800050b4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050c0:	557d                	li	a0,-1
}
    800050c2:	60e2                	ld	ra,24(sp)
    800050c4:	6442                	ld	s0,16(sp)
    800050c6:	64a2                	ld	s1,8(sp)
    800050c8:	6105                	addi	sp,sp,32
    800050ca:	8082                	ret
      p->ofile[fd] = f;
    800050cc:	01a50793          	addi	a5,a0,26
    800050d0:	078e                	slli	a5,a5,0x3
    800050d2:	963e                	add	a2,a2,a5
    800050d4:	e204                	sd	s1,0(a2)
      return fd;
    800050d6:	b7f5                	j	800050c2 <fdalloc+0x2c>

00000000800050d8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050d8:	715d                	addi	sp,sp,-80
    800050da:	e486                	sd	ra,72(sp)
    800050dc:	e0a2                	sd	s0,64(sp)
    800050de:	fc26                	sd	s1,56(sp)
    800050e0:	f84a                	sd	s2,48(sp)
    800050e2:	f44e                	sd	s3,40(sp)
    800050e4:	f052                	sd	s4,32(sp)
    800050e6:	ec56                	sd	s5,24(sp)
    800050e8:	0880                	addi	s0,sp,80
    800050ea:	89ae                	mv	s3,a1
    800050ec:	8ab2                	mv	s5,a2
    800050ee:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050f0:	fb040593          	addi	a1,s0,-80
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	e86080e7          	jalr	-378(ra) # 80003f7a <nameiparent>
    800050fc:	892a                	mv	s2,a0
    800050fe:	12050f63          	beqz	a0,8000523c <create+0x164>
    return 0;

  ilock(dp);
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	6a4080e7          	jalr	1700(ra) # 800037a6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000510a:	4601                	li	a2,0
    8000510c:	fb040593          	addi	a1,s0,-80
    80005110:	854a                	mv	a0,s2
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	b78080e7          	jalr	-1160(ra) # 80003c8a <dirlookup>
    8000511a:	84aa                	mv	s1,a0
    8000511c:	c921                	beqz	a0,8000516c <create+0x94>
    iunlockput(dp);
    8000511e:	854a                	mv	a0,s2
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	8e8080e7          	jalr	-1816(ra) # 80003a08 <iunlockput>
    ilock(ip);
    80005128:	8526                	mv	a0,s1
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	67c080e7          	jalr	1660(ra) # 800037a6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005132:	2981                	sext.w	s3,s3
    80005134:	4789                	li	a5,2
    80005136:	02f99463          	bne	s3,a5,8000515e <create+0x86>
    8000513a:	0444d783          	lhu	a5,68(s1)
    8000513e:	37f9                	addiw	a5,a5,-2
    80005140:	17c2                	slli	a5,a5,0x30
    80005142:	93c1                	srli	a5,a5,0x30
    80005144:	4705                	li	a4,1
    80005146:	00f76c63          	bltu	a4,a5,8000515e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000514a:	8526                	mv	a0,s1
    8000514c:	60a6                	ld	ra,72(sp)
    8000514e:	6406                	ld	s0,64(sp)
    80005150:	74e2                	ld	s1,56(sp)
    80005152:	7942                	ld	s2,48(sp)
    80005154:	79a2                	ld	s3,40(sp)
    80005156:	7a02                	ld	s4,32(sp)
    80005158:	6ae2                	ld	s5,24(sp)
    8000515a:	6161                	addi	sp,sp,80
    8000515c:	8082                	ret
    iunlockput(ip);
    8000515e:	8526                	mv	a0,s1
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	8a8080e7          	jalr	-1880(ra) # 80003a08 <iunlockput>
    return 0;
    80005168:	4481                	li	s1,0
    8000516a:	b7c5                	j	8000514a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000516c:	85ce                	mv	a1,s3
    8000516e:	00092503          	lw	a0,0(s2)
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	49c080e7          	jalr	1180(ra) # 8000360e <ialloc>
    8000517a:	84aa                	mv	s1,a0
    8000517c:	c529                	beqz	a0,800051c6 <create+0xee>
  ilock(ip);
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	628080e7          	jalr	1576(ra) # 800037a6 <ilock>
  ip->major = major;
    80005186:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000518a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000518e:	4785                	li	a5,1
    80005190:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005194:	8526                	mv	a0,s1
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	546080e7          	jalr	1350(ra) # 800036dc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000519e:	2981                	sext.w	s3,s3
    800051a0:	4785                	li	a5,1
    800051a2:	02f98a63          	beq	s3,a5,800051d6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051a6:	40d0                	lw	a2,4(s1)
    800051a8:	fb040593          	addi	a1,s0,-80
    800051ac:	854a                	mv	a0,s2
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	cec080e7          	jalr	-788(ra) # 80003e9a <dirlink>
    800051b6:	06054b63          	bltz	a0,8000522c <create+0x154>
  iunlockput(dp);
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	84c080e7          	jalr	-1972(ra) # 80003a08 <iunlockput>
  return ip;
    800051c4:	b759                	j	8000514a <create+0x72>
    panic("create: ialloc");
    800051c6:	00003517          	auipc	a0,0x3
    800051ca:	52250513          	addi	a0,a0,1314 # 800086e8 <syscalls+0x2a0>
    800051ce:	ffffb097          	auipc	ra,0xffffb
    800051d2:	370080e7          	jalr	880(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051d6:	04a95783          	lhu	a5,74(s2)
    800051da:	2785                	addiw	a5,a5,1
    800051dc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051e0:	854a                	mv	a0,s2
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	4fa080e7          	jalr	1274(ra) # 800036dc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051ea:	40d0                	lw	a2,4(s1)
    800051ec:	00003597          	auipc	a1,0x3
    800051f0:	50c58593          	addi	a1,a1,1292 # 800086f8 <syscalls+0x2b0>
    800051f4:	8526                	mv	a0,s1
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	ca4080e7          	jalr	-860(ra) # 80003e9a <dirlink>
    800051fe:	00054f63          	bltz	a0,8000521c <create+0x144>
    80005202:	00492603          	lw	a2,4(s2)
    80005206:	00003597          	auipc	a1,0x3
    8000520a:	4fa58593          	addi	a1,a1,1274 # 80008700 <syscalls+0x2b8>
    8000520e:	8526                	mv	a0,s1
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	c8a080e7          	jalr	-886(ra) # 80003e9a <dirlink>
    80005218:	f80557e3          	bgez	a0,800051a6 <create+0xce>
      panic("create dots");
    8000521c:	00003517          	auipc	a0,0x3
    80005220:	4ec50513          	addi	a0,a0,1260 # 80008708 <syscalls+0x2c0>
    80005224:	ffffb097          	auipc	ra,0xffffb
    80005228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000522c:	00003517          	auipc	a0,0x3
    80005230:	4ec50513          	addi	a0,a0,1260 # 80008718 <syscalls+0x2d0>
    80005234:	ffffb097          	auipc	ra,0xffffb
    80005238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
    return 0;
    8000523c:	84aa                	mv	s1,a0
    8000523e:	b731                	j	8000514a <create+0x72>

0000000080005240 <sys_dup>:
{
    80005240:	7179                	addi	sp,sp,-48
    80005242:	f406                	sd	ra,40(sp)
    80005244:	f022                	sd	s0,32(sp)
    80005246:	ec26                	sd	s1,24(sp)
    80005248:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000524a:	fd840613          	addi	a2,s0,-40
    8000524e:	4581                	li	a1,0
    80005250:	4501                	li	a0,0
    80005252:	00000097          	auipc	ra,0x0
    80005256:	ddc080e7          	jalr	-548(ra) # 8000502e <argfd>
    return -1;
    8000525a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000525c:	02054363          	bltz	a0,80005282 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005260:	fd843503          	ld	a0,-40(s0)
    80005264:	00000097          	auipc	ra,0x0
    80005268:	e32080e7          	jalr	-462(ra) # 80005096 <fdalloc>
    8000526c:	84aa                	mv	s1,a0
    return -1;
    8000526e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005270:	00054963          	bltz	a0,80005282 <sys_dup+0x42>
  filedup(f);
    80005274:	fd843503          	ld	a0,-40(s0)
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	37a080e7          	jalr	890(ra) # 800045f2 <filedup>
  return fd;
    80005280:	87a6                	mv	a5,s1
}
    80005282:	853e                	mv	a0,a5
    80005284:	70a2                	ld	ra,40(sp)
    80005286:	7402                	ld	s0,32(sp)
    80005288:	64e2                	ld	s1,24(sp)
    8000528a:	6145                	addi	sp,sp,48
    8000528c:	8082                	ret

000000008000528e <sys_read>:
{
    8000528e:	7179                	addi	sp,sp,-48
    80005290:	f406                	sd	ra,40(sp)
    80005292:	f022                	sd	s0,32(sp)
    80005294:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005296:	fe840613          	addi	a2,s0,-24
    8000529a:	4581                	li	a1,0
    8000529c:	4501                	li	a0,0
    8000529e:	00000097          	auipc	ra,0x0
    800052a2:	d90080e7          	jalr	-624(ra) # 8000502e <argfd>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	04054163          	bltz	a0,800052ea <sys_read+0x5c>
    800052ac:	fe440593          	addi	a1,s0,-28
    800052b0:	4509                	li	a0,2
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	982080e7          	jalr	-1662(ra) # 80002c34 <argint>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	02054763          	bltz	a0,800052ea <sys_read+0x5c>
    800052c0:	fd840593          	addi	a1,s0,-40
    800052c4:	4505                	li	a0,1
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	990080e7          	jalr	-1648(ra) # 80002c56 <argaddr>
    return -1;
    800052ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d0:	00054d63          	bltz	a0,800052ea <sys_read+0x5c>
  return fileread(f, p, n);
    800052d4:	fe442603          	lw	a2,-28(s0)
    800052d8:	fd843583          	ld	a1,-40(s0)
    800052dc:	fe843503          	ld	a0,-24(s0)
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	49e080e7          	jalr	1182(ra) # 8000477e <fileread>
    800052e8:	87aa                	mv	a5,a0
}
    800052ea:	853e                	mv	a0,a5
    800052ec:	70a2                	ld	ra,40(sp)
    800052ee:	7402                	ld	s0,32(sp)
    800052f0:	6145                	addi	sp,sp,48
    800052f2:	8082                	ret

00000000800052f4 <sys_write>:
{
    800052f4:	7179                	addi	sp,sp,-48
    800052f6:	f406                	sd	ra,40(sp)
    800052f8:	f022                	sd	s0,32(sp)
    800052fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fc:	fe840613          	addi	a2,s0,-24
    80005300:	4581                	li	a1,0
    80005302:	4501                	li	a0,0
    80005304:	00000097          	auipc	ra,0x0
    80005308:	d2a080e7          	jalr	-726(ra) # 8000502e <argfd>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	04054163          	bltz	a0,80005350 <sys_write+0x5c>
    80005312:	fe440593          	addi	a1,s0,-28
    80005316:	4509                	li	a0,2
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	91c080e7          	jalr	-1764(ra) # 80002c34 <argint>
    return -1;
    80005320:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005322:	02054763          	bltz	a0,80005350 <sys_write+0x5c>
    80005326:	fd840593          	addi	a1,s0,-40
    8000532a:	4505                	li	a0,1
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	92a080e7          	jalr	-1750(ra) # 80002c56 <argaddr>
    return -1;
    80005334:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005336:	00054d63          	bltz	a0,80005350 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000533a:	fe442603          	lw	a2,-28(s0)
    8000533e:	fd843583          	ld	a1,-40(s0)
    80005342:	fe843503          	ld	a0,-24(s0)
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	4fa080e7          	jalr	1274(ra) # 80004840 <filewrite>
    8000534e:	87aa                	mv	a5,a0
}
    80005350:	853e                	mv	a0,a5
    80005352:	70a2                	ld	ra,40(sp)
    80005354:	7402                	ld	s0,32(sp)
    80005356:	6145                	addi	sp,sp,48
    80005358:	8082                	ret

000000008000535a <sys_close>:
{
    8000535a:	1101                	addi	sp,sp,-32
    8000535c:	ec06                	sd	ra,24(sp)
    8000535e:	e822                	sd	s0,16(sp)
    80005360:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005362:	fe040613          	addi	a2,s0,-32
    80005366:	fec40593          	addi	a1,s0,-20
    8000536a:	4501                	li	a0,0
    8000536c:	00000097          	auipc	ra,0x0
    80005370:	cc2080e7          	jalr	-830(ra) # 8000502e <argfd>
    return -1;
    80005374:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005376:	02054463          	bltz	a0,8000539e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	73c080e7          	jalr	1852(ra) # 80001ab6 <myproc>
    80005382:	fec42783          	lw	a5,-20(s0)
    80005386:	07e9                	addi	a5,a5,26
    80005388:	078e                	slli	a5,a5,0x3
    8000538a:	97aa                	add	a5,a5,a0
    8000538c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005390:	fe043503          	ld	a0,-32(s0)
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	2b0080e7          	jalr	688(ra) # 80004644 <fileclose>
  return 0;
    8000539c:	4781                	li	a5,0
}
    8000539e:	853e                	mv	a0,a5
    800053a0:	60e2                	ld	ra,24(sp)
    800053a2:	6442                	ld	s0,16(sp)
    800053a4:	6105                	addi	sp,sp,32
    800053a6:	8082                	ret

00000000800053a8 <sys_fstat>:
{
    800053a8:	1101                	addi	sp,sp,-32
    800053aa:	ec06                	sd	ra,24(sp)
    800053ac:	e822                	sd	s0,16(sp)
    800053ae:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b0:	fe840613          	addi	a2,s0,-24
    800053b4:	4581                	li	a1,0
    800053b6:	4501                	li	a0,0
    800053b8:	00000097          	auipc	ra,0x0
    800053bc:	c76080e7          	jalr	-906(ra) # 8000502e <argfd>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c2:	02054563          	bltz	a0,800053ec <sys_fstat+0x44>
    800053c6:	fe040593          	addi	a1,s0,-32
    800053ca:	4505                	li	a0,1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	88a080e7          	jalr	-1910(ra) # 80002c56 <argaddr>
    return -1;
    800053d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d6:	00054b63          	bltz	a0,800053ec <sys_fstat+0x44>
  return filestat(f, st);
    800053da:	fe043583          	ld	a1,-32(s0)
    800053de:	fe843503          	ld	a0,-24(s0)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	32a080e7          	jalr	810(ra) # 8000470c <filestat>
    800053ea:	87aa                	mv	a5,a0
}
    800053ec:	853e                	mv	a0,a5
    800053ee:	60e2                	ld	ra,24(sp)
    800053f0:	6442                	ld	s0,16(sp)
    800053f2:	6105                	addi	sp,sp,32
    800053f4:	8082                	ret

00000000800053f6 <sys_link>:
{
    800053f6:	7169                	addi	sp,sp,-304
    800053f8:	f606                	sd	ra,296(sp)
    800053fa:	f222                	sd	s0,288(sp)
    800053fc:	ee26                	sd	s1,280(sp)
    800053fe:	ea4a                	sd	s2,272(sp)
    80005400:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	08000613          	li	a2,128
    80005406:	ed040593          	addi	a1,s0,-304
    8000540a:	4501                	li	a0,0
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	86c080e7          	jalr	-1940(ra) # 80002c78 <argstr>
    return -1;
    80005414:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005416:	10054e63          	bltz	a0,80005532 <sys_link+0x13c>
    8000541a:	08000613          	li	a2,128
    8000541e:	f5040593          	addi	a1,s0,-176
    80005422:	4505                	li	a0,1
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	854080e7          	jalr	-1964(ra) # 80002c78 <argstr>
    return -1;
    8000542c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542e:	10054263          	bltz	a0,80005532 <sys_link+0x13c>
  begin_op();
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	d46080e7          	jalr	-698(ra) # 80004178 <begin_op>
  if((ip = namei(old)) == 0){
    8000543a:	ed040513          	addi	a0,s0,-304
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	b1e080e7          	jalr	-1250(ra) # 80003f5c <namei>
    80005446:	84aa                	mv	s1,a0
    80005448:	c551                	beqz	a0,800054d4 <sys_link+0xde>
  ilock(ip);
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	35c080e7          	jalr	860(ra) # 800037a6 <ilock>
  if(ip->type == T_DIR){
    80005452:	04449703          	lh	a4,68(s1)
    80005456:	4785                	li	a5,1
    80005458:	08f70463          	beq	a4,a5,800054e0 <sys_link+0xea>
  ip->nlink++;
    8000545c:	04a4d783          	lhu	a5,74(s1)
    80005460:	2785                	addiw	a5,a5,1
    80005462:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005466:	8526                	mv	a0,s1
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	274080e7          	jalr	628(ra) # 800036dc <iupdate>
  iunlock(ip);
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	3f6080e7          	jalr	1014(ra) # 80003868 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000547a:	fd040593          	addi	a1,s0,-48
    8000547e:	f5040513          	addi	a0,s0,-176
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	af8080e7          	jalr	-1288(ra) # 80003f7a <nameiparent>
    8000548a:	892a                	mv	s2,a0
    8000548c:	c935                	beqz	a0,80005500 <sys_link+0x10a>
  ilock(dp);
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	318080e7          	jalr	792(ra) # 800037a6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005496:	00092703          	lw	a4,0(s2)
    8000549a:	409c                	lw	a5,0(s1)
    8000549c:	04f71d63          	bne	a4,a5,800054f6 <sys_link+0x100>
    800054a0:	40d0                	lw	a2,4(s1)
    800054a2:	fd040593          	addi	a1,s0,-48
    800054a6:	854a                	mv	a0,s2
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	9f2080e7          	jalr	-1550(ra) # 80003e9a <dirlink>
    800054b0:	04054363          	bltz	a0,800054f6 <sys_link+0x100>
  iunlockput(dp);
    800054b4:	854a                	mv	a0,s2
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	552080e7          	jalr	1362(ra) # 80003a08 <iunlockput>
  iput(ip);
    800054be:	8526                	mv	a0,s1
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	4a0080e7          	jalr	1184(ra) # 80003960 <iput>
  end_op();
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	d30080e7          	jalr	-720(ra) # 800041f8 <end_op>
  return 0;
    800054d0:	4781                	li	a5,0
    800054d2:	a085                	j	80005532 <sys_link+0x13c>
    end_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	d24080e7          	jalr	-732(ra) # 800041f8 <end_op>
    return -1;
    800054dc:	57fd                	li	a5,-1
    800054de:	a891                	j	80005532 <sys_link+0x13c>
    iunlockput(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	526080e7          	jalr	1318(ra) # 80003a08 <iunlockput>
    end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	d0e080e7          	jalr	-754(ra) # 800041f8 <end_op>
    return -1;
    800054f2:	57fd                	li	a5,-1
    800054f4:	a83d                	j	80005532 <sys_link+0x13c>
    iunlockput(dp);
    800054f6:	854a                	mv	a0,s2
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	510080e7          	jalr	1296(ra) # 80003a08 <iunlockput>
  ilock(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	2a4080e7          	jalr	676(ra) # 800037a6 <ilock>
  ip->nlink--;
    8000550a:	04a4d783          	lhu	a5,74(s1)
    8000550e:	37fd                	addiw	a5,a5,-1
    80005510:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	1c6080e7          	jalr	454(ra) # 800036dc <iupdate>
  iunlockput(ip);
    8000551e:	8526                	mv	a0,s1
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	4e8080e7          	jalr	1256(ra) # 80003a08 <iunlockput>
  end_op();
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	cd0080e7          	jalr	-816(ra) # 800041f8 <end_op>
  return -1;
    80005530:	57fd                	li	a5,-1
}
    80005532:	853e                	mv	a0,a5
    80005534:	70b2                	ld	ra,296(sp)
    80005536:	7412                	ld	s0,288(sp)
    80005538:	64f2                	ld	s1,280(sp)
    8000553a:	6952                	ld	s2,272(sp)
    8000553c:	6155                	addi	sp,sp,304
    8000553e:	8082                	ret

0000000080005540 <sys_unlink>:
{
    80005540:	7151                	addi	sp,sp,-240
    80005542:	f586                	sd	ra,232(sp)
    80005544:	f1a2                	sd	s0,224(sp)
    80005546:	eda6                	sd	s1,216(sp)
    80005548:	e9ca                	sd	s2,208(sp)
    8000554a:	e5ce                	sd	s3,200(sp)
    8000554c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000554e:	08000613          	li	a2,128
    80005552:	f3040593          	addi	a1,s0,-208
    80005556:	4501                	li	a0,0
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	720080e7          	jalr	1824(ra) # 80002c78 <argstr>
    80005560:	18054163          	bltz	a0,800056e2 <sys_unlink+0x1a2>
  begin_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	c14080e7          	jalr	-1004(ra) # 80004178 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000556c:	fb040593          	addi	a1,s0,-80
    80005570:	f3040513          	addi	a0,s0,-208
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	a06080e7          	jalr	-1530(ra) # 80003f7a <nameiparent>
    8000557c:	84aa                	mv	s1,a0
    8000557e:	c979                	beqz	a0,80005654 <sys_unlink+0x114>
  ilock(dp);
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	226080e7          	jalr	550(ra) # 800037a6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005588:	00003597          	auipc	a1,0x3
    8000558c:	17058593          	addi	a1,a1,368 # 800086f8 <syscalls+0x2b0>
    80005590:	fb040513          	addi	a0,s0,-80
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	6dc080e7          	jalr	1756(ra) # 80003c70 <namecmp>
    8000559c:	14050a63          	beqz	a0,800056f0 <sys_unlink+0x1b0>
    800055a0:	00003597          	auipc	a1,0x3
    800055a4:	16058593          	addi	a1,a1,352 # 80008700 <syscalls+0x2b8>
    800055a8:	fb040513          	addi	a0,s0,-80
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	6c4080e7          	jalr	1732(ra) # 80003c70 <namecmp>
    800055b4:	12050e63          	beqz	a0,800056f0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055b8:	f2c40613          	addi	a2,s0,-212
    800055bc:	fb040593          	addi	a1,s0,-80
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	6c8080e7          	jalr	1736(ra) # 80003c8a <dirlookup>
    800055ca:	892a                	mv	s2,a0
    800055cc:	12050263          	beqz	a0,800056f0 <sys_unlink+0x1b0>
  ilock(ip);
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	1d6080e7          	jalr	470(ra) # 800037a6 <ilock>
  if(ip->nlink < 1)
    800055d8:	04a91783          	lh	a5,74(s2)
    800055dc:	08f05263          	blez	a5,80005660 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055e0:	04491703          	lh	a4,68(s2)
    800055e4:	4785                	li	a5,1
    800055e6:	08f70563          	beq	a4,a5,80005670 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055ea:	4641                	li	a2,16
    800055ec:	4581                	li	a1,0
    800055ee:	fc040513          	addi	a0,s0,-64
    800055f2:	ffffb097          	auipc	ra,0xffffb
    800055f6:	7ea080e7          	jalr	2026(ra) # 80000ddc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055fa:	4741                	li	a4,16
    800055fc:	f2c42683          	lw	a3,-212(s0)
    80005600:	fc040613          	addi	a2,s0,-64
    80005604:	4581                	li	a1,0
    80005606:	8526                	mv	a0,s1
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	54a080e7          	jalr	1354(ra) # 80003b52 <writei>
    80005610:	47c1                	li	a5,16
    80005612:	0af51563          	bne	a0,a5,800056bc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005616:	04491703          	lh	a4,68(s2)
    8000561a:	4785                	li	a5,1
    8000561c:	0af70863          	beq	a4,a5,800056cc <sys_unlink+0x18c>
  iunlockput(dp);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	3e6080e7          	jalr	998(ra) # 80003a08 <iunlockput>
  ip->nlink--;
    8000562a:	04a95783          	lhu	a5,74(s2)
    8000562e:	37fd                	addiw	a5,a5,-1
    80005630:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005634:	854a                	mv	a0,s2
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	0a6080e7          	jalr	166(ra) # 800036dc <iupdate>
  iunlockput(ip);
    8000563e:	854a                	mv	a0,s2
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	3c8080e7          	jalr	968(ra) # 80003a08 <iunlockput>
  end_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	bb0080e7          	jalr	-1104(ra) # 800041f8 <end_op>
  return 0;
    80005650:	4501                	li	a0,0
    80005652:	a84d                	j	80005704 <sys_unlink+0x1c4>
    end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	ba4080e7          	jalr	-1116(ra) # 800041f8 <end_op>
    return -1;
    8000565c:	557d                	li	a0,-1
    8000565e:	a05d                	j	80005704 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005660:	00003517          	auipc	a0,0x3
    80005664:	0c850513          	addi	a0,a0,200 # 80008728 <syscalls+0x2e0>
    80005668:	ffffb097          	auipc	ra,0xffffb
    8000566c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005670:	04c92703          	lw	a4,76(s2)
    80005674:	02000793          	li	a5,32
    80005678:	f6e7f9e3          	bgeu	a5,a4,800055ea <sys_unlink+0xaa>
    8000567c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005680:	4741                	li	a4,16
    80005682:	86ce                	mv	a3,s3
    80005684:	f1840613          	addi	a2,s0,-232
    80005688:	4581                	li	a1,0
    8000568a:	854a                	mv	a0,s2
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	3ce080e7          	jalr	974(ra) # 80003a5a <readi>
    80005694:	47c1                	li	a5,16
    80005696:	00f51b63          	bne	a0,a5,800056ac <sys_unlink+0x16c>
    if(de.inum != 0)
    8000569a:	f1845783          	lhu	a5,-232(s0)
    8000569e:	e7a1                	bnez	a5,800056e6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a0:	29c1                	addiw	s3,s3,16
    800056a2:	04c92783          	lw	a5,76(s2)
    800056a6:	fcf9ede3          	bltu	s3,a5,80005680 <sys_unlink+0x140>
    800056aa:	b781                	j	800055ea <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ac:	00003517          	auipc	a0,0x3
    800056b0:	09450513          	addi	a0,a0,148 # 80008740 <syscalls+0x2f8>
    800056b4:	ffffb097          	auipc	ra,0xffffb
    800056b8:	e8a080e7          	jalr	-374(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056bc:	00003517          	auipc	a0,0x3
    800056c0:	09c50513          	addi	a0,a0,156 # 80008758 <syscalls+0x310>
    800056c4:	ffffb097          	auipc	ra,0xffffb
    800056c8:	e7a080e7          	jalr	-390(ra) # 8000053e <panic>
    dp->nlink--;
    800056cc:	04a4d783          	lhu	a5,74(s1)
    800056d0:	37fd                	addiw	a5,a5,-1
    800056d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	004080e7          	jalr	4(ra) # 800036dc <iupdate>
    800056e0:	b781                	j	80005620 <sys_unlink+0xe0>
    return -1;
    800056e2:	557d                	li	a0,-1
    800056e4:	a005                	j	80005704 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	320080e7          	jalr	800(ra) # 80003a08 <iunlockput>
  iunlockput(dp);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	316080e7          	jalr	790(ra) # 80003a08 <iunlockput>
  end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	afe080e7          	jalr	-1282(ra) # 800041f8 <end_op>
  return -1;
    80005702:	557d                	li	a0,-1
}
    80005704:	70ae                	ld	ra,232(sp)
    80005706:	740e                	ld	s0,224(sp)
    80005708:	64ee                	ld	s1,216(sp)
    8000570a:	694e                	ld	s2,208(sp)
    8000570c:	69ae                	ld	s3,200(sp)
    8000570e:	616d                	addi	sp,sp,240
    80005710:	8082                	ret

0000000080005712 <sys_open>:

uint64
sys_open(void)
{
    80005712:	7131                	addi	sp,sp,-192
    80005714:	fd06                	sd	ra,184(sp)
    80005716:	f922                	sd	s0,176(sp)
    80005718:	f526                	sd	s1,168(sp)
    8000571a:	f14a                	sd	s2,160(sp)
    8000571c:	ed4e                	sd	s3,152(sp)
    8000571e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005720:	08000613          	li	a2,128
    80005724:	f5040593          	addi	a1,s0,-176
    80005728:	4501                	li	a0,0
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	54e080e7          	jalr	1358(ra) # 80002c78 <argstr>
    return -1;
    80005732:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005734:	0c054163          	bltz	a0,800057f6 <sys_open+0xe4>
    80005738:	f4c40593          	addi	a1,s0,-180
    8000573c:	4505                	li	a0,1
    8000573e:	ffffd097          	auipc	ra,0xffffd
    80005742:	4f6080e7          	jalr	1270(ra) # 80002c34 <argint>
    80005746:	0a054863          	bltz	a0,800057f6 <sys_open+0xe4>

  begin_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	a2e080e7          	jalr	-1490(ra) # 80004178 <begin_op>

  if(omode & O_CREATE){
    80005752:	f4c42783          	lw	a5,-180(s0)
    80005756:	2007f793          	andi	a5,a5,512
    8000575a:	cbdd                	beqz	a5,80005810 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000575c:	4681                	li	a3,0
    8000575e:	4601                	li	a2,0
    80005760:	4589                	li	a1,2
    80005762:	f5040513          	addi	a0,s0,-176
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	972080e7          	jalr	-1678(ra) # 800050d8 <create>
    8000576e:	892a                	mv	s2,a0
    if(ip == 0){
    80005770:	c959                	beqz	a0,80005806 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005772:	04491703          	lh	a4,68(s2)
    80005776:	478d                	li	a5,3
    80005778:	00f71763          	bne	a4,a5,80005786 <sys_open+0x74>
    8000577c:	04695703          	lhu	a4,70(s2)
    80005780:	47a5                	li	a5,9
    80005782:	0ce7ec63          	bltu	a5,a4,8000585a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	e02080e7          	jalr	-510(ra) # 80004588 <filealloc>
    8000578e:	89aa                	mv	s3,a0
    80005790:	10050263          	beqz	a0,80005894 <sys_open+0x182>
    80005794:	00000097          	auipc	ra,0x0
    80005798:	902080e7          	jalr	-1790(ra) # 80005096 <fdalloc>
    8000579c:	84aa                	mv	s1,a0
    8000579e:	0e054663          	bltz	a0,8000588a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057a2:	04491703          	lh	a4,68(s2)
    800057a6:	478d                	li	a5,3
    800057a8:	0cf70463          	beq	a4,a5,80005870 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ac:	4789                	li	a5,2
    800057ae:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057b2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057b6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057ba:	f4c42783          	lw	a5,-180(s0)
    800057be:	0017c713          	xori	a4,a5,1
    800057c2:	8b05                	andi	a4,a4,1
    800057c4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057c8:	0037f713          	andi	a4,a5,3
    800057cc:	00e03733          	snez	a4,a4
    800057d0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057d4:	4007f793          	andi	a5,a5,1024
    800057d8:	c791                	beqz	a5,800057e4 <sys_open+0xd2>
    800057da:	04491703          	lh	a4,68(s2)
    800057de:	4789                	li	a5,2
    800057e0:	08f70f63          	beq	a4,a5,8000587e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057e4:	854a                	mv	a0,s2
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	082080e7          	jalr	130(ra) # 80003868 <iunlock>
  end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	a0a080e7          	jalr	-1526(ra) # 800041f8 <end_op>

  return fd;
}
    800057f6:	8526                	mv	a0,s1
    800057f8:	70ea                	ld	ra,184(sp)
    800057fa:	744a                	ld	s0,176(sp)
    800057fc:	74aa                	ld	s1,168(sp)
    800057fe:	790a                	ld	s2,160(sp)
    80005800:	69ea                	ld	s3,152(sp)
    80005802:	6129                	addi	sp,sp,192
    80005804:	8082                	ret
      end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	9f2080e7          	jalr	-1550(ra) # 800041f8 <end_op>
      return -1;
    8000580e:	b7e5                	j	800057f6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005810:	f5040513          	addi	a0,s0,-176
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	748080e7          	jalr	1864(ra) # 80003f5c <namei>
    8000581c:	892a                	mv	s2,a0
    8000581e:	c905                	beqz	a0,8000584e <sys_open+0x13c>
    ilock(ip);
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	f86080e7          	jalr	-122(ra) # 800037a6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005828:	04491703          	lh	a4,68(s2)
    8000582c:	4785                	li	a5,1
    8000582e:	f4f712e3          	bne	a4,a5,80005772 <sys_open+0x60>
    80005832:	f4c42783          	lw	a5,-180(s0)
    80005836:	dba1                	beqz	a5,80005786 <sys_open+0x74>
      iunlockput(ip);
    80005838:	854a                	mv	a0,s2
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	1ce080e7          	jalr	462(ra) # 80003a08 <iunlockput>
      end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	9b6080e7          	jalr	-1610(ra) # 800041f8 <end_op>
      return -1;
    8000584a:	54fd                	li	s1,-1
    8000584c:	b76d                	j	800057f6 <sys_open+0xe4>
      end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	9aa080e7          	jalr	-1622(ra) # 800041f8 <end_op>
      return -1;
    80005856:	54fd                	li	s1,-1
    80005858:	bf79                	j	800057f6 <sys_open+0xe4>
    iunlockput(ip);
    8000585a:	854a                	mv	a0,s2
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	1ac080e7          	jalr	428(ra) # 80003a08 <iunlockput>
    end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	994080e7          	jalr	-1644(ra) # 800041f8 <end_op>
    return -1;
    8000586c:	54fd                	li	s1,-1
    8000586e:	b761                	j	800057f6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005870:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005874:	04691783          	lh	a5,70(s2)
    80005878:	02f99223          	sh	a5,36(s3)
    8000587c:	bf2d                	j	800057b6 <sys_open+0xa4>
    itrunc(ip);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	034080e7          	jalr	52(ra) # 800038b4 <itrunc>
    80005888:	bfb1                	j	800057e4 <sys_open+0xd2>
      fileclose(f);
    8000588a:	854e                	mv	a0,s3
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	db8080e7          	jalr	-584(ra) # 80004644 <fileclose>
    iunlockput(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	172080e7          	jalr	370(ra) # 80003a08 <iunlockput>
    end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	95a080e7          	jalr	-1702(ra) # 800041f8 <end_op>
    return -1;
    800058a6:	54fd                	li	s1,-1
    800058a8:	b7b9                	j	800057f6 <sys_open+0xe4>

00000000800058aa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058aa:	7175                	addi	sp,sp,-144
    800058ac:	e506                	sd	ra,136(sp)
    800058ae:	e122                	sd	s0,128(sp)
    800058b0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	8c6080e7          	jalr	-1850(ra) # 80004178 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058ba:	08000613          	li	a2,128
    800058be:	f7040593          	addi	a1,s0,-144
    800058c2:	4501                	li	a0,0
    800058c4:	ffffd097          	auipc	ra,0xffffd
    800058c8:	3b4080e7          	jalr	948(ra) # 80002c78 <argstr>
    800058cc:	02054963          	bltz	a0,800058fe <sys_mkdir+0x54>
    800058d0:	4681                	li	a3,0
    800058d2:	4601                	li	a2,0
    800058d4:	4585                	li	a1,1
    800058d6:	f7040513          	addi	a0,s0,-144
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	7fe080e7          	jalr	2046(ra) # 800050d8 <create>
    800058e2:	cd11                	beqz	a0,800058fe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	124080e7          	jalr	292(ra) # 80003a08 <iunlockput>
  end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	90c080e7          	jalr	-1780(ra) # 800041f8 <end_op>
  return 0;
    800058f4:	4501                	li	a0,0
}
    800058f6:	60aa                	ld	ra,136(sp)
    800058f8:	640a                	ld	s0,128(sp)
    800058fa:	6149                	addi	sp,sp,144
    800058fc:	8082                	ret
    end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	8fa080e7          	jalr	-1798(ra) # 800041f8 <end_op>
    return -1;
    80005906:	557d                	li	a0,-1
    80005908:	b7fd                	j	800058f6 <sys_mkdir+0x4c>

000000008000590a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000590a:	7135                	addi	sp,sp,-160
    8000590c:	ed06                	sd	ra,152(sp)
    8000590e:	e922                	sd	s0,144(sp)
    80005910:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	866080e7          	jalr	-1946(ra) # 80004178 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000591a:	08000613          	li	a2,128
    8000591e:	f7040593          	addi	a1,s0,-144
    80005922:	4501                	li	a0,0
    80005924:	ffffd097          	auipc	ra,0xffffd
    80005928:	354080e7          	jalr	852(ra) # 80002c78 <argstr>
    8000592c:	04054a63          	bltz	a0,80005980 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005930:	f6c40593          	addi	a1,s0,-148
    80005934:	4505                	li	a0,1
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	2fe080e7          	jalr	766(ra) # 80002c34 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000593e:	04054163          	bltz	a0,80005980 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005942:	f6840593          	addi	a1,s0,-152
    80005946:	4509                	li	a0,2
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	2ec080e7          	jalr	748(ra) # 80002c34 <argint>
     argint(1, &major) < 0 ||
    80005950:	02054863          	bltz	a0,80005980 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005954:	f6841683          	lh	a3,-152(s0)
    80005958:	f6c41603          	lh	a2,-148(s0)
    8000595c:	458d                	li	a1,3
    8000595e:	f7040513          	addi	a0,s0,-144
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	776080e7          	jalr	1910(ra) # 800050d8 <create>
     argint(2, &minor) < 0 ||
    8000596a:	c919                	beqz	a0,80005980 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	09c080e7          	jalr	156(ra) # 80003a08 <iunlockput>
  end_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	884080e7          	jalr	-1916(ra) # 800041f8 <end_op>
  return 0;
    8000597c:	4501                	li	a0,0
    8000597e:	a031                	j	8000598a <sys_mknod+0x80>
    end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	878080e7          	jalr	-1928(ra) # 800041f8 <end_op>
    return -1;
    80005988:	557d                	li	a0,-1
}
    8000598a:	60ea                	ld	ra,152(sp)
    8000598c:	644a                	ld	s0,144(sp)
    8000598e:	610d                	addi	sp,sp,160
    80005990:	8082                	ret

0000000080005992 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005992:	7135                	addi	sp,sp,-160
    80005994:	ed06                	sd	ra,152(sp)
    80005996:	e922                	sd	s0,144(sp)
    80005998:	e526                	sd	s1,136(sp)
    8000599a:	e14a                	sd	s2,128(sp)
    8000599c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000599e:	ffffc097          	auipc	ra,0xffffc
    800059a2:	118080e7          	jalr	280(ra) # 80001ab6 <myproc>
    800059a6:	892a                	mv	s2,a0
  
  begin_op();
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	7d0080e7          	jalr	2000(ra) # 80004178 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059b0:	08000613          	li	a2,128
    800059b4:	f6040593          	addi	a1,s0,-160
    800059b8:	4501                	li	a0,0
    800059ba:	ffffd097          	auipc	ra,0xffffd
    800059be:	2be080e7          	jalr	702(ra) # 80002c78 <argstr>
    800059c2:	04054b63          	bltz	a0,80005a18 <sys_chdir+0x86>
    800059c6:	f6040513          	addi	a0,s0,-160
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	592080e7          	jalr	1426(ra) # 80003f5c <namei>
    800059d2:	84aa                	mv	s1,a0
    800059d4:	c131                	beqz	a0,80005a18 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	dd0080e7          	jalr	-560(ra) # 800037a6 <ilock>
  if(ip->type != T_DIR){
    800059de:	04449703          	lh	a4,68(s1)
    800059e2:	4785                	li	a5,1
    800059e4:	04f71063          	bne	a4,a5,80005a24 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	e7e080e7          	jalr	-386(ra) # 80003868 <iunlock>
  iput(p->cwd);
    800059f2:	15093503          	ld	a0,336(s2)
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	f6a080e7          	jalr	-150(ra) # 80003960 <iput>
  end_op();
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	7fa080e7          	jalr	2042(ra) # 800041f8 <end_op>
  p->cwd = ip;
    80005a06:	14993823          	sd	s1,336(s2)
  return 0;
    80005a0a:	4501                	li	a0,0
}
    80005a0c:	60ea                	ld	ra,152(sp)
    80005a0e:	644a                	ld	s0,144(sp)
    80005a10:	64aa                	ld	s1,136(sp)
    80005a12:	690a                	ld	s2,128(sp)
    80005a14:	610d                	addi	sp,sp,160
    80005a16:	8082                	ret
    end_op();
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	7e0080e7          	jalr	2016(ra) # 800041f8 <end_op>
    return -1;
    80005a20:	557d                	li	a0,-1
    80005a22:	b7ed                	j	80005a0c <sys_chdir+0x7a>
    iunlockput(ip);
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	fe2080e7          	jalr	-30(ra) # 80003a08 <iunlockput>
    end_op();
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	7ca080e7          	jalr	1994(ra) # 800041f8 <end_op>
    return -1;
    80005a36:	557d                	li	a0,-1
    80005a38:	bfd1                	j	80005a0c <sys_chdir+0x7a>

0000000080005a3a <sys_exec>:

uint64
sys_exec(void)
{
    80005a3a:	7145                	addi	sp,sp,-464
    80005a3c:	e786                	sd	ra,456(sp)
    80005a3e:	e3a2                	sd	s0,448(sp)
    80005a40:	ff26                	sd	s1,440(sp)
    80005a42:	fb4a                	sd	s2,432(sp)
    80005a44:	f74e                	sd	s3,424(sp)
    80005a46:	f352                	sd	s4,416(sp)
    80005a48:	ef56                	sd	s5,408(sp)
    80005a4a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a4c:	08000613          	li	a2,128
    80005a50:	f4040593          	addi	a1,s0,-192
    80005a54:	4501                	li	a0,0
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	222080e7          	jalr	546(ra) # 80002c78 <argstr>
    return -1;
    80005a5e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a60:	0c054a63          	bltz	a0,80005b34 <sys_exec+0xfa>
    80005a64:	e3840593          	addi	a1,s0,-456
    80005a68:	4505                	li	a0,1
    80005a6a:	ffffd097          	auipc	ra,0xffffd
    80005a6e:	1ec080e7          	jalr	492(ra) # 80002c56 <argaddr>
    80005a72:	0c054163          	bltz	a0,80005b34 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a76:	10000613          	li	a2,256
    80005a7a:	4581                	li	a1,0
    80005a7c:	e4040513          	addi	a0,s0,-448
    80005a80:	ffffb097          	auipc	ra,0xffffb
    80005a84:	35c080e7          	jalr	860(ra) # 80000ddc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a88:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a8c:	89a6                	mv	s3,s1
    80005a8e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a90:	02000a13          	li	s4,32
    80005a94:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a98:	00391513          	slli	a0,s2,0x3
    80005a9c:	e3040593          	addi	a1,s0,-464
    80005aa0:	e3843783          	ld	a5,-456(s0)
    80005aa4:	953e                	add	a0,a0,a5
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	0f4080e7          	jalr	244(ra) # 80002b9a <fetchaddr>
    80005aae:	02054a63          	bltz	a0,80005ae2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ab2:	e3043783          	ld	a5,-464(s0)
    80005ab6:	c3b9                	beqz	a5,80005afc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ab8:	ffffb097          	auipc	ra,0xffffb
    80005abc:	12e080e7          	jalr	302(ra) # 80000be6 <kalloc>
    80005ac0:	85aa                	mv	a1,a0
    80005ac2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ac6:	cd11                	beqz	a0,80005ae2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ac8:	6605                	lui	a2,0x1
    80005aca:	e3043503          	ld	a0,-464(s0)
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	11e080e7          	jalr	286(ra) # 80002bec <fetchstr>
    80005ad6:	00054663          	bltz	a0,80005ae2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ada:	0905                	addi	s2,s2,1
    80005adc:	09a1                	addi	s3,s3,8
    80005ade:	fb491be3          	bne	s2,s4,80005a94 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae2:	10048913          	addi	s2,s1,256
    80005ae6:	6088                	ld	a0,0(s1)
    80005ae8:	c529                	beqz	a0,80005b32 <sys_exec+0xf8>
    kfree(argv[i]);
    80005aea:	ffffb097          	auipc	ra,0xffffb
    80005aee:	f72080e7          	jalr	-142(ra) # 80000a5c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af2:	04a1                	addi	s1,s1,8
    80005af4:	ff2499e3          	bne	s1,s2,80005ae6 <sys_exec+0xac>
  return -1;
    80005af8:	597d                	li	s2,-1
    80005afa:	a82d                	j	80005b34 <sys_exec+0xfa>
      argv[i] = 0;
    80005afc:	0a8e                	slli	s5,s5,0x3
    80005afe:	fc040793          	addi	a5,s0,-64
    80005b02:	9abe                	add	s5,s5,a5
    80005b04:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b08:	e4040593          	addi	a1,s0,-448
    80005b0c:	f4040513          	addi	a0,s0,-192
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	194080e7          	jalr	404(ra) # 80004ca4 <exec>
    80005b18:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1a:	10048993          	addi	s3,s1,256
    80005b1e:	6088                	ld	a0,0(s1)
    80005b20:	c911                	beqz	a0,80005b34 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b22:	ffffb097          	auipc	ra,0xffffb
    80005b26:	f3a080e7          	jalr	-198(ra) # 80000a5c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	04a1                	addi	s1,s1,8
    80005b2c:	ff3499e3          	bne	s1,s3,80005b1e <sys_exec+0xe4>
    80005b30:	a011                	j	80005b34 <sys_exec+0xfa>
  return -1;
    80005b32:	597d                	li	s2,-1
}
    80005b34:	854a                	mv	a0,s2
    80005b36:	60be                	ld	ra,456(sp)
    80005b38:	641e                	ld	s0,448(sp)
    80005b3a:	74fa                	ld	s1,440(sp)
    80005b3c:	795a                	ld	s2,432(sp)
    80005b3e:	79ba                	ld	s3,424(sp)
    80005b40:	7a1a                	ld	s4,416(sp)
    80005b42:	6afa                	ld	s5,408(sp)
    80005b44:	6179                	addi	sp,sp,464
    80005b46:	8082                	ret

0000000080005b48 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b48:	7139                	addi	sp,sp,-64
    80005b4a:	fc06                	sd	ra,56(sp)
    80005b4c:	f822                	sd	s0,48(sp)
    80005b4e:	f426                	sd	s1,40(sp)
    80005b50:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b52:	ffffc097          	auipc	ra,0xffffc
    80005b56:	f64080e7          	jalr	-156(ra) # 80001ab6 <myproc>
    80005b5a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b5c:	fd840593          	addi	a1,s0,-40
    80005b60:	4501                	li	a0,0
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	0f4080e7          	jalr	244(ra) # 80002c56 <argaddr>
    return -1;
    80005b6a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b6c:	0e054063          	bltz	a0,80005c4c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b70:	fc840593          	addi	a1,s0,-56
    80005b74:	fd040513          	addi	a0,s0,-48
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	dfc080e7          	jalr	-516(ra) # 80004974 <pipealloc>
    return -1;
    80005b80:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b82:	0c054563          	bltz	a0,80005c4c <sys_pipe+0x104>
  fd0 = -1;
    80005b86:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b8a:	fd043503          	ld	a0,-48(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	508080e7          	jalr	1288(ra) # 80005096 <fdalloc>
    80005b96:	fca42223          	sw	a0,-60(s0)
    80005b9a:	08054c63          	bltz	a0,80005c32 <sys_pipe+0xea>
    80005b9e:	fc843503          	ld	a0,-56(s0)
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	4f4080e7          	jalr	1268(ra) # 80005096 <fdalloc>
    80005baa:	fca42023          	sw	a0,-64(s0)
    80005bae:	06054863          	bltz	a0,80005c1e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb2:	4691                	li	a3,4
    80005bb4:	fc440613          	addi	a2,s0,-60
    80005bb8:	fd843583          	ld	a1,-40(s0)
    80005bbc:	68a8                	ld	a0,80(s1)
    80005bbe:	ffffc097          	auipc	ra,0xffffc
    80005bc2:	ba6080e7          	jalr	-1114(ra) # 80001764 <copyout>
    80005bc6:	02054063          	bltz	a0,80005be6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bca:	4691                	li	a3,4
    80005bcc:	fc040613          	addi	a2,s0,-64
    80005bd0:	fd843583          	ld	a1,-40(s0)
    80005bd4:	0591                	addi	a1,a1,4
    80005bd6:	68a8                	ld	a0,80(s1)
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	b8c080e7          	jalr	-1140(ra) # 80001764 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005be0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be2:	06055563          	bgez	a0,80005c4c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005be6:	fc442783          	lw	a5,-60(s0)
    80005bea:	07e9                	addi	a5,a5,26
    80005bec:	078e                	slli	a5,a5,0x3
    80005bee:	97a6                	add	a5,a5,s1
    80005bf0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bf4:	fc042503          	lw	a0,-64(s0)
    80005bf8:	0569                	addi	a0,a0,26
    80005bfa:	050e                	slli	a0,a0,0x3
    80005bfc:	9526                	add	a0,a0,s1
    80005bfe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c02:	fd043503          	ld	a0,-48(s0)
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	a3e080e7          	jalr	-1474(ra) # 80004644 <fileclose>
    fileclose(wf);
    80005c0e:	fc843503          	ld	a0,-56(s0)
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	a32080e7          	jalr	-1486(ra) # 80004644 <fileclose>
    return -1;
    80005c1a:	57fd                	li	a5,-1
    80005c1c:	a805                	j	80005c4c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c1e:	fc442783          	lw	a5,-60(s0)
    80005c22:	0007c863          	bltz	a5,80005c32 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c26:	01a78513          	addi	a0,a5,26
    80005c2a:	050e                	slli	a0,a0,0x3
    80005c2c:	9526                	add	a0,a0,s1
    80005c2e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c32:	fd043503          	ld	a0,-48(s0)
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	a0e080e7          	jalr	-1522(ra) # 80004644 <fileclose>
    fileclose(wf);
    80005c3e:	fc843503          	ld	a0,-56(s0)
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	a02080e7          	jalr	-1534(ra) # 80004644 <fileclose>
    return -1;
    80005c4a:	57fd                	li	a5,-1
}
    80005c4c:	853e                	mv	a0,a5
    80005c4e:	70e2                	ld	ra,56(sp)
    80005c50:	7442                	ld	s0,48(sp)
    80005c52:	74a2                	ld	s1,40(sp)
    80005c54:	6121                	addi	sp,sp,64
    80005c56:	8082                	ret
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	c01fc0ef          	jal	ra,800028a0 <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	d52080e7          	jalr	-686(ra) # 80001a8a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	953e                	add	a0,a0,a5
    80005d5c:	00052023          	sw	zero,0(a0)
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	d1a080e7          	jalr	-742(ra) # 80001a8a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5179b          	slliw	a5,a0,0xd
    80005d7c:	0c201537          	lui	a0,0xc201
    80005d80:	953e                	add	a0,a0,a5
  return irq;
}
    80005d82:	4148                	lw	a0,4(a0)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	cf2080e7          	jalr	-782(ra) # 80001a8a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	06a7c963          	blt	a5,a0,80005e32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0003d797          	auipc	a5,0x3d
    80005dc8:	23c78793          	addi	a5,a5,572 # 80043000 <disk>
    80005dcc:	00a78733          	add	a4,a5,a0
    80005dd0:	6789                	lui	a5,0x2
    80005dd2:	97ba                	add	a5,a5,a4
    80005dd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dd8:	e7ad                	bnez	a5,80005e42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dda:	00451793          	slli	a5,a0,0x4
    80005dde:	0003f717          	auipc	a4,0x3f
    80005de2:	22270713          	addi	a4,a4,546 # 80045000 <disk+0x2000>
    80005de6:	6314                	ld	a3,0(a4)
    80005de8:	96be                	add	a3,a3,a5
    80005dea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dee:	6314                	ld	a3,0(a4)
    80005df0:	96be                	add	a3,a3,a5
    80005df2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005df6:	6314                	ld	a3,0(a4)
    80005df8:	96be                	add	a3,a3,a5
    80005dfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dfe:	6318                	ld	a4,0(a4)
    80005e00:	97ba                	add	a5,a5,a4
    80005e02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e06:	0003d797          	auipc	a5,0x3d
    80005e0a:	1fa78793          	addi	a5,a5,506 # 80043000 <disk>
    80005e0e:	97aa                	add	a5,a5,a0
    80005e10:	6509                	lui	a0,0x2
    80005e12:	953e                	add	a0,a0,a5
    80005e14:	4785                	li	a5,1
    80005e16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e1a:	0003f517          	auipc	a0,0x3f
    80005e1e:	1fe50513          	addi	a0,a0,510 # 80045018 <disk+0x2018>
    80005e22:	ffffc097          	auipc	ra,0xffffc
    80005e26:	4dc080e7          	jalr	1244(ra) # 800022fe <wakeup>
}
    80005e2a:	60a2                	ld	ra,8(sp)
    80005e2c:	6402                	ld	s0,0(sp)
    80005e2e:	0141                	addi	sp,sp,16
    80005e30:	8082                	ret
    panic("free_desc 1");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	93650513          	addi	a0,a0,-1738 # 80008768 <syscalls+0x320>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	704080e7          	jalr	1796(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	93650513          	addi	a0,a0,-1738 # 80008778 <syscalls+0x330>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>

0000000080005e52 <virtio_disk_init>:
{
    80005e52:	1101                	addi	sp,sp,-32
    80005e54:	ec06                	sd	ra,24(sp)
    80005e56:	e822                	sd	s0,16(sp)
    80005e58:	e426                	sd	s1,8(sp)
    80005e5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e5c:	00003597          	auipc	a1,0x3
    80005e60:	92c58593          	addi	a1,a1,-1748 # 80008788 <syscalls+0x340>
    80005e64:	0003f517          	auipc	a0,0x3f
    80005e68:	2c450513          	addi	a0,a0,708 # 80045128 <disk+0x2128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	de4080e7          	jalr	-540(ra) # 80000c50 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e74:	100017b7          	lui	a5,0x10001
    80005e78:	4398                	lw	a4,0(a5)
    80005e7a:	2701                	sext.w	a4,a4
    80005e7c:	747277b7          	lui	a5,0x74727
    80005e80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e84:	0ef71163          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e88:	100017b7          	lui	a5,0x10001
    80005e8c:	43dc                	lw	a5,4(a5)
    80005e8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e90:	4705                	li	a4,1
    80005e92:	0ce79a63          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	479c                	lw	a5,8(a5)
    80005e9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e9e:	4709                	li	a4,2
    80005ea0:	0ce79363          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ea4:	100017b7          	lui	a5,0x10001
    80005ea8:	47d8                	lw	a4,12(a5)
    80005eaa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eac:	554d47b7          	lui	a5,0x554d4
    80005eb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eb4:	0af71963          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb8:	100017b7          	lui	a5,0x10001
    80005ebc:	4705                	li	a4,1
    80005ebe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec0:	470d                	li	a4,3
    80005ec2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ec4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ec6:	c7ffe737          	lui	a4,0xc7ffe
    80005eca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb875f>
    80005ece:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed0:	2701                	sext.w	a4,a4
    80005ed2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed4:	472d                	li	a4,11
    80005ed6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	473d                	li	a4,15
    80005eda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005edc:	6705                	lui	a4,0x1
    80005ede:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ee0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ee4:	5bdc                	lw	a5,52(a5)
    80005ee6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee8:	c7d9                	beqz	a5,80005f76 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eea:	471d                	li	a4,7
    80005eec:	08f77d63          	bgeu	a4,a5,80005f86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ef0:	100014b7          	lui	s1,0x10001
    80005ef4:	47a1                	li	a5,8
    80005ef6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ef8:	6609                	lui	a2,0x2
    80005efa:	4581                	li	a1,0
    80005efc:	0003d517          	auipc	a0,0x3d
    80005f00:	10450513          	addi	a0,a0,260 # 80043000 <disk>
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	ed8080e7          	jalr	-296(ra) # 80000ddc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f0c:	0003d717          	auipc	a4,0x3d
    80005f10:	0f470713          	addi	a4,a4,244 # 80043000 <disk>
    80005f14:	00c75793          	srli	a5,a4,0xc
    80005f18:	2781                	sext.w	a5,a5
    80005f1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f1c:	0003f797          	auipc	a5,0x3f
    80005f20:	0e478793          	addi	a5,a5,228 # 80045000 <disk+0x2000>
    80005f24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f26:	0003d717          	auipc	a4,0x3d
    80005f2a:	15a70713          	addi	a4,a4,346 # 80043080 <disk+0x80>
    80005f2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f30:	0003e717          	auipc	a4,0x3e
    80005f34:	0d070713          	addi	a4,a4,208 # 80044000 <disk+0x1000>
    80005f38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f3a:	4705                	li	a4,1
    80005f3c:	00e78c23          	sb	a4,24(a5)
    80005f40:	00e78ca3          	sb	a4,25(a5)
    80005f44:	00e78d23          	sb	a4,26(a5)
    80005f48:	00e78da3          	sb	a4,27(a5)
    80005f4c:	00e78e23          	sb	a4,28(a5)
    80005f50:	00e78ea3          	sb	a4,29(a5)
    80005f54:	00e78f23          	sb	a4,30(a5)
    80005f58:	00e78fa3          	sb	a4,31(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret
    panic("could not find virtio disk");
    80005f66:	00003517          	auipc	a0,0x3
    80005f6a:	83250513          	addi	a0,a0,-1998 # 80008798 <syscalls+0x350>
    80005f6e:	ffffa097          	auipc	ra,0xffffa
    80005f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	84250513          	addi	a0,a0,-1982 # 800087b8 <syscalls+0x370>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	85250513          	addi	a0,a0,-1966 # 800087d8 <syscalls+0x390>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>

0000000080005f96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f96:	7159                	addi	sp,sp,-112
    80005f98:	f486                	sd	ra,104(sp)
    80005f9a:	f0a2                	sd	s0,96(sp)
    80005f9c:	eca6                	sd	s1,88(sp)
    80005f9e:	e8ca                	sd	s2,80(sp)
    80005fa0:	e4ce                	sd	s3,72(sp)
    80005fa2:	e0d2                	sd	s4,64(sp)
    80005fa4:	fc56                	sd	s5,56(sp)
    80005fa6:	f85a                	sd	s6,48(sp)
    80005fa8:	f45e                	sd	s7,40(sp)
    80005faa:	f062                	sd	s8,32(sp)
    80005fac:	ec66                	sd	s9,24(sp)
    80005fae:	e86a                	sd	s10,16(sp)
    80005fb0:	1880                	addi	s0,sp,112
    80005fb2:	892a                	mv	s2,a0
    80005fb4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fb6:	00c52c83          	lw	s9,12(a0)
    80005fba:	001c9c9b          	slliw	s9,s9,0x1
    80005fbe:	1c82                	slli	s9,s9,0x20
    80005fc0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fc4:	0003f517          	auipc	a0,0x3f
    80005fc8:	16450513          	addi	a0,a0,356 # 80045128 <disk+0x2128>
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	d14080e7          	jalr	-748(ra) # 80000ce0 <acquire>
  for(int i = 0; i < 3; i++){
    80005fd4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fd6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fd8:	0003db97          	auipc	s7,0x3d
    80005fdc:	028b8b93          	addi	s7,s7,40 # 80043000 <disk>
    80005fe0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fe2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fe4:	8a4e                	mv	s4,s3
    80005fe6:	a051                	j	8000606a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fe8:	00fb86b3          	add	a3,s7,a5
    80005fec:	96da                	add	a3,a3,s6
    80005fee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ff2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ff4:	0207c563          	bltz	a5,8000601e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ff8:	2485                	addiw	s1,s1,1
    80005ffa:	0711                	addi	a4,a4,4
    80005ffc:	25548063          	beq	s1,s5,8000623c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006000:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006002:	0003f697          	auipc	a3,0x3f
    80006006:	01668693          	addi	a3,a3,22 # 80045018 <disk+0x2018>
    8000600a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000600c:	0006c583          	lbu	a1,0(a3)
    80006010:	fde1                	bnez	a1,80005fe8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006012:	2785                	addiw	a5,a5,1
    80006014:	0685                	addi	a3,a3,1
    80006016:	ff879be3          	bne	a5,s8,8000600c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000601a:	57fd                	li	a5,-1
    8000601c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000601e:	02905a63          	blez	s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006022:	f9042503          	lw	a0,-112(s0)
    80006026:	00000097          	auipc	ra,0x0
    8000602a:	d90080e7          	jalr	-624(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    8000602e:	4785                	li	a5,1
    80006030:	0297d163          	bge	a5,s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006034:	f9442503          	lw	a0,-108(s0)
    80006038:	00000097          	auipc	ra,0x0
    8000603c:	d7e080e7          	jalr	-642(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006040:	4789                	li	a5,2
    80006042:	0097d863          	bge	a5,s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006046:	f9842503          	lw	a0,-104(s0)
    8000604a:	00000097          	auipc	ra,0x0
    8000604e:	d6c080e7          	jalr	-660(ra) # 80005db6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006052:	0003f597          	auipc	a1,0x3f
    80006056:	0d658593          	addi	a1,a1,214 # 80045128 <disk+0x2128>
    8000605a:	0003f517          	auipc	a0,0x3f
    8000605e:	fbe50513          	addi	a0,a0,-66 # 80045018 <disk+0x2018>
    80006062:	ffffc097          	auipc	ra,0xffffc
    80006066:	110080e7          	jalr	272(ra) # 80002172 <sleep>
  for(int i = 0; i < 3; i++){
    8000606a:	f9040713          	addi	a4,s0,-112
    8000606e:	84ce                	mv	s1,s3
    80006070:	bf41                	j	80006000 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006072:	20058713          	addi	a4,a1,512
    80006076:	00471693          	slli	a3,a4,0x4
    8000607a:	0003d717          	auipc	a4,0x3d
    8000607e:	f8670713          	addi	a4,a4,-122 # 80043000 <disk>
    80006082:	9736                	add	a4,a4,a3
    80006084:	4685                	li	a3,1
    80006086:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000608a:	20058713          	addi	a4,a1,512
    8000608e:	00471693          	slli	a3,a4,0x4
    80006092:	0003d717          	auipc	a4,0x3d
    80006096:	f6e70713          	addi	a4,a4,-146 # 80043000 <disk>
    8000609a:	9736                	add	a4,a4,a3
    8000609c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060a0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060a4:	7679                	lui	a2,0xffffe
    800060a6:	963e                	add	a2,a2,a5
    800060a8:	0003f697          	auipc	a3,0x3f
    800060ac:	f5868693          	addi	a3,a3,-168 # 80045000 <disk+0x2000>
    800060b0:	6298                	ld	a4,0(a3)
    800060b2:	9732                	add	a4,a4,a2
    800060b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060b6:	6298                	ld	a4,0(a3)
    800060b8:	9732                	add	a4,a4,a2
    800060ba:	4541                	li	a0,16
    800060bc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060be:	6298                	ld	a4,0(a3)
    800060c0:	9732                	add	a4,a4,a2
    800060c2:	4505                	li	a0,1
    800060c4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060c8:	f9442703          	lw	a4,-108(s0)
    800060cc:	6288                	ld	a0,0(a3)
    800060ce:	962a                	add	a2,a2,a0
    800060d0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffb800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060d4:	0712                	slli	a4,a4,0x4
    800060d6:	6290                	ld	a2,0(a3)
    800060d8:	963a                	add	a2,a2,a4
    800060da:	05890513          	addi	a0,s2,88
    800060de:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060e0:	6294                	ld	a3,0(a3)
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	40000613          	li	a2,1024
    800060e8:	c690                	sw	a2,8(a3)
  if(write)
    800060ea:	140d0063          	beqz	s10,8000622a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ee:	0003f697          	auipc	a3,0x3f
    800060f2:	f126b683          	ld	a3,-238(a3) # 80045000 <disk+0x2000>
    800060f6:	96ba                	add	a3,a3,a4
    800060f8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060fc:	0003d817          	auipc	a6,0x3d
    80006100:	f0480813          	addi	a6,a6,-252 # 80043000 <disk>
    80006104:	0003f517          	auipc	a0,0x3f
    80006108:	efc50513          	addi	a0,a0,-260 # 80045000 <disk+0x2000>
    8000610c:	6114                	ld	a3,0(a0)
    8000610e:	96ba                	add	a3,a3,a4
    80006110:	00c6d603          	lhu	a2,12(a3)
    80006114:	00166613          	ori	a2,a2,1
    80006118:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000611c:	f9842683          	lw	a3,-104(s0)
    80006120:	6110                	ld	a2,0(a0)
    80006122:	9732                	add	a4,a4,a2
    80006124:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006128:	20058613          	addi	a2,a1,512
    8000612c:	0612                	slli	a2,a2,0x4
    8000612e:	9642                	add	a2,a2,a6
    80006130:	577d                	li	a4,-1
    80006132:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006136:	00469713          	slli	a4,a3,0x4
    8000613a:	6114                	ld	a3,0(a0)
    8000613c:	96ba                	add	a3,a3,a4
    8000613e:	03078793          	addi	a5,a5,48
    80006142:	97c2                	add	a5,a5,a6
    80006144:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006146:	611c                	ld	a5,0(a0)
    80006148:	97ba                	add	a5,a5,a4
    8000614a:	4685                	li	a3,1
    8000614c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000614e:	611c                	ld	a5,0(a0)
    80006150:	97ba                	add	a5,a5,a4
    80006152:	4809                	li	a6,2
    80006154:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006158:	611c                	ld	a5,0(a0)
    8000615a:	973e                	add	a4,a4,a5
    8000615c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006160:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006164:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006168:	6518                	ld	a4,8(a0)
    8000616a:	00275783          	lhu	a5,2(a4)
    8000616e:	8b9d                	andi	a5,a5,7
    80006170:	0786                	slli	a5,a5,0x1
    80006172:	97ba                	add	a5,a5,a4
    80006174:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006178:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000617c:	6518                	ld	a4,8(a0)
    8000617e:	00275783          	lhu	a5,2(a4)
    80006182:	2785                	addiw	a5,a5,1
    80006184:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006188:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000618c:	100017b7          	lui	a5,0x10001
    80006190:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006194:	00492703          	lw	a4,4(s2)
    80006198:	4785                	li	a5,1
    8000619a:	02f71163          	bne	a4,a5,800061bc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000619e:	0003f997          	auipc	s3,0x3f
    800061a2:	f8a98993          	addi	s3,s3,-118 # 80045128 <disk+0x2128>
  while(b->disk == 1) {
    800061a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061a8:	85ce                	mv	a1,s3
    800061aa:	854a                	mv	a0,s2
    800061ac:	ffffc097          	auipc	ra,0xffffc
    800061b0:	fc6080e7          	jalr	-58(ra) # 80002172 <sleep>
  while(b->disk == 1) {
    800061b4:	00492783          	lw	a5,4(s2)
    800061b8:	fe9788e3          	beq	a5,s1,800061a8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061bc:	f9042903          	lw	s2,-112(s0)
    800061c0:	20090793          	addi	a5,s2,512
    800061c4:	00479713          	slli	a4,a5,0x4
    800061c8:	0003d797          	auipc	a5,0x3d
    800061cc:	e3878793          	addi	a5,a5,-456 # 80043000 <disk>
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061d6:	0003f997          	auipc	s3,0x3f
    800061da:	e2a98993          	addi	s3,s3,-470 # 80045000 <disk+0x2000>
    800061de:	00491713          	slli	a4,s2,0x4
    800061e2:	0009b783          	ld	a5,0(s3)
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061ec:	854a                	mv	a0,s2
    800061ee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061f2:	00000097          	auipc	ra,0x0
    800061f6:	bc4080e7          	jalr	-1084(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061fa:	8885                	andi	s1,s1,1
    800061fc:	f0ed                	bnez	s1,800061de <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061fe:	0003f517          	auipc	a0,0x3f
    80006202:	f2a50513          	addi	a0,a0,-214 # 80045128 <disk+0x2128>
    80006206:	ffffb097          	auipc	ra,0xffffb
    8000620a:	b8e080e7          	jalr	-1138(ra) # 80000d94 <release>
}
    8000620e:	70a6                	ld	ra,104(sp)
    80006210:	7406                	ld	s0,96(sp)
    80006212:	64e6                	ld	s1,88(sp)
    80006214:	6946                	ld	s2,80(sp)
    80006216:	69a6                	ld	s3,72(sp)
    80006218:	6a06                	ld	s4,64(sp)
    8000621a:	7ae2                	ld	s5,56(sp)
    8000621c:	7b42                	ld	s6,48(sp)
    8000621e:	7ba2                	ld	s7,40(sp)
    80006220:	7c02                	ld	s8,32(sp)
    80006222:	6ce2                	ld	s9,24(sp)
    80006224:	6d42                	ld	s10,16(sp)
    80006226:	6165                	addi	sp,sp,112
    80006228:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000622a:	0003f697          	auipc	a3,0x3f
    8000622e:	dd66b683          	ld	a3,-554(a3) # 80045000 <disk+0x2000>
    80006232:	96ba                	add	a3,a3,a4
    80006234:	4609                	li	a2,2
    80006236:	00c69623          	sh	a2,12(a3)
    8000623a:	b5c9                	j	800060fc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000623c:	f9042583          	lw	a1,-112(s0)
    80006240:	20058793          	addi	a5,a1,512
    80006244:	0792                	slli	a5,a5,0x4
    80006246:	0003d517          	auipc	a0,0x3d
    8000624a:	e6250513          	addi	a0,a0,-414 # 800430a8 <disk+0xa8>
    8000624e:	953e                	add	a0,a0,a5
  if(write)
    80006250:	e20d11e3          	bnez	s10,80006072 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006254:	20058713          	addi	a4,a1,512
    80006258:	00471693          	slli	a3,a4,0x4
    8000625c:	0003d717          	auipc	a4,0x3d
    80006260:	da470713          	addi	a4,a4,-604 # 80043000 <disk>
    80006264:	9736                	add	a4,a4,a3
    80006266:	0a072423          	sw	zero,168(a4)
    8000626a:	b505                	j	8000608a <virtio_disk_rw+0xf4>

000000008000626c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	e04a                	sd	s2,0(sp)
    80006276:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006278:	0003f517          	auipc	a0,0x3f
    8000627c:	eb050513          	addi	a0,a0,-336 # 80045128 <disk+0x2128>
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	a60080e7          	jalr	-1440(ra) # 80000ce0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006288:	10001737          	lui	a4,0x10001
    8000628c:	533c                	lw	a5,96(a4)
    8000628e:	8b8d                	andi	a5,a5,3
    80006290:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006292:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006296:	0003f797          	auipc	a5,0x3f
    8000629a:	d6a78793          	addi	a5,a5,-662 # 80045000 <disk+0x2000>
    8000629e:	6b94                	ld	a3,16(a5)
    800062a0:	0207d703          	lhu	a4,32(a5)
    800062a4:	0026d783          	lhu	a5,2(a3)
    800062a8:	06f70163          	beq	a4,a5,8000630a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ac:	0003d917          	auipc	s2,0x3d
    800062b0:	d5490913          	addi	s2,s2,-684 # 80043000 <disk>
    800062b4:	0003f497          	auipc	s1,0x3f
    800062b8:	d4c48493          	addi	s1,s1,-692 # 80045000 <disk+0x2000>
    __sync_synchronize();
    800062bc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062c0:	6898                	ld	a4,16(s1)
    800062c2:	0204d783          	lhu	a5,32(s1)
    800062c6:	8b9d                	andi	a5,a5,7
    800062c8:	078e                	slli	a5,a5,0x3
    800062ca:	97ba                	add	a5,a5,a4
    800062cc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062ce:	20078713          	addi	a4,a5,512
    800062d2:	0712                	slli	a4,a4,0x4
    800062d4:	974a                	add	a4,a4,s2
    800062d6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062da:	e731                	bnez	a4,80006326 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062dc:	20078793          	addi	a5,a5,512
    800062e0:	0792                	slli	a5,a5,0x4
    800062e2:	97ca                	add	a5,a5,s2
    800062e4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062e6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ea:	ffffc097          	auipc	ra,0xffffc
    800062ee:	014080e7          	jalr	20(ra) # 800022fe <wakeup>

    disk.used_idx += 1;
    800062f2:	0204d783          	lhu	a5,32(s1)
    800062f6:	2785                	addiw	a5,a5,1
    800062f8:	17c2                	slli	a5,a5,0x30
    800062fa:	93c1                	srli	a5,a5,0x30
    800062fc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006300:	6898                	ld	a4,16(s1)
    80006302:	00275703          	lhu	a4,2(a4)
    80006306:	faf71be3          	bne	a4,a5,800062bc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000630a:	0003f517          	auipc	a0,0x3f
    8000630e:	e1e50513          	addi	a0,a0,-482 # 80045128 <disk+0x2128>
    80006312:	ffffb097          	auipc	ra,0xffffb
    80006316:	a82080e7          	jalr	-1406(ra) # 80000d94 <release>
}
    8000631a:	60e2                	ld	ra,24(sp)
    8000631c:	6442                	ld	s0,16(sp)
    8000631e:	64a2                	ld	s1,8(sp)
    80006320:	6902                	ld	s2,0(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret
      panic("virtio_disk_intr status");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	4d250513          	addi	a0,a0,1234 # 800087f8 <syscalls+0x3b0>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	210080e7          	jalr	528(ra) # 8000053e <panic>

0000000080006336 <cas>:
    80006336:	100522af          	lr.w	t0,(a0)
    8000633a:	00b29563          	bne	t0,a1,80006344 <fail>
    8000633e:	18c5252f          	sc.w	a0,a2,(a0)
    80006342:	8082                	ret

0000000080006344 <fail>:
    80006344:	4505                	li	a0,1
    80006346:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
